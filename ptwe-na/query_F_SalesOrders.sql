Declare @LastUpdate Date = GETDATE();
-- Declare @LastUpdate Date = GETDATE();
-- RAVM ADD INSTALLER 2020-04-21 (1)
-- RAVM ADD CONSULTANT 2020-11-06 (2)
-- RAVM change interco (3)

SET DATEFIRST 7;
-- Sunday because we need to push the Exchange Rate date (EX.EFT) to the next Saturday

With
    ExRate
    as
    (
        SELECT RATE_TYPE_CODE, BASE_CURRENCY, TARGET_CURRENCY,
            isNull(DateAdd(d,1,LAG(END_DATE) OVER(Partition By RATE_TYPE_CODE, BASE_CURRENCY, TARGET_CURRENCY Order By END_DATE)),'1900-01-01') as BEGIN_DATE,
            END_DATE, RATE_DIVISOR, RATE_MULTIPLICATOR, LOAD_DATE, UPDATED_DATE
        FROM
            (
		SELECT EX.RTTY as RATE_TYPE_CODE,
                EX.CRDC as BASE_CURRENCY,
                EX.CRCD as TARGET_CURRENCY,
                EX.LOAD_DATE,
                EX.UPDATED_DATE,
                -- We need to extend the last (current) rate to 2999-12-31 until the newest rate is entered in JDE.  Whenever that will happens, sales transactions
                -- are going to be recalculated because the LOAD_DATE of the new record will be changed
                Case
				When ROW_NUMBER() OVER(Partition By EX.RTTY, EX.CRDC, EX.CRCD Order By EX.EFT DESC) = 1 Then '2999-12-31'
				Else DateAdd(d,7-DatePart(dw,EX.EFT),EX.EFT)
			End as END_DATE,
                Cast(EX.CRRD as Decimal(18,6)) as RATE_DIVISOR,
                Cast(EX.CRR as Decimal(18,6)) as RATE_MULTIPLICATOR
            FROM RDL00002_00002_Landing.JDE.F1113 EX
            WHERE	EX.RTTY = 'A' -- (A) Average monthly rate
	) X
    ),
    AddressOverrides
    as
    (
        SELECT AO.ANTY,
            AO.KCOO,
            AO.DCTO,
            AO.DOCO,
            Upper(Left(Replace(isNull(AO.ADDZ,''),' ',''),30)) as POSTAL_CODE,
            Upper(isNull(AO.CTY1,'')) as CITY_NAME,
            Upper(isNull(AO.COUN,'')) as COUNTY_NAME,
            Upper(isNull(AO.ADDS,'')) as STATE_CODE,
            Upper(isNull(ST.DL01,'')) as STATE_NAME,
            Upper(isNull(AO.CTR,'')) as COUNTRY_CODE,
            Upper(isNull(CY.DL01,'')) as COUNTRY_NAME,
            Upper(isNull(RG.KY,'')) as REGION_CODE,
            Upper(isNull(RG.DL01,'')) as REGION_NAME,
            AO.LOAD_DATE, AO.UPDATED_DATE,
            CN.LOAD_DATE as COUNTY_LOAD_DATE, CN.UPDATED_DATE as COUNTY_UPDATED_DATE,
            RG.LOAD_DATE as REGION_LOAD_DATE, RG.UPDATED_DATE as REGION_UPDATED_DATE,
            CY.LOAD_DATE as COUNTRY_LOAD_DATE, CY.UPDATED_DATE as COUNTRY_UPDATED_DATE,
            ST.LOAD_DATE as STATE_LOAD_DATE, ST.UPDATED_DATE as STATE_UPDATED_DATE
        FROM RDL00002_00002_Landing.JDE.F4006 AO
            LEFT JOIN RDL00002_00002_Landing.JDE.F0005 CN on CN.SY = '00' and CN.RT = 'CT' and AO.COUN = CN.DL01 and CN.DL02 LIKE '%ADM. REGION%'
            LEFT JOIN RDL00002_00002_Landing.JDE.F0005 RG on RG.SY = '01' and RG.RT = '15' and RG.KY = RTRIM(LTRIM(RIGHT(CN.DL02,3)))
            LEFT JOIN RDL00002_00002_Landing.JDE.F0005 CY on CY.SY = '00' and CY.RT = 'CN' and CY.KY = AO.CTR
            LEFT JOIN RDL00002_00002_Landing.JDE.F0005 ST on ST.SY = '00' and ST.RT = 'S' and ST.KY = AO.ADDS
    ),
    PriceHistory
    as
    (
        SELECT sum ([BSDVAL]*[UPRC])  as PHTotal  , [DOCO], LNID
        FROM RDL00002_00002_Landing.[JDE].[F4074]
        where GLC is not null
        group by [DOCO],LNID
    ),
    Customers
    as
    (
        SELECT *
        FROM
            (
		SELECT ROW_NUMBER() OVER(
			Partition By CM.AN8 
			Order By Case 
					When CM.CO = '00002' Then 1
					When CM.CO = '00009' Then 2
					When CM.CO = '09064' Then 3
					When CM.CO = '09065' Then 4					
					When CM.CO = '00000' Then 5
					Else 999
				End 
			) as RN,
                CM.CO,
                CM.AN8 as CUSTOMER_CODE,
                CM.LOAD_DATE as CM_LOAD_DATE, CM.UPDATED_DATE as CM_UPDATED_DATE,
                AD.LOAD_DATE as AD_LOAD_DATE, AD.UPDATED_DATE as AD_UPDATED_DATE,
                ADB.LOAD_DATE as ADBOOK_LOAD_DATE, ADB.UPDATED_DATE as ADBOOK_UPDATED_DATE,
                RE.LOAD_DATE as REGION_LOAD_DATE, RE.UPDATED_DATE as REGION_UPDATED_DATE,
                CT.LOAD_DATE as COUNTRY_LOAD_DATE, CT.UPDATED_DATE as COUNTRY_UPDATED_DATE,
                ST.LOAD_DATE as STATE_LOAD_DATE, ST.UPDATED_DATE as STATE_UPDATED_DATE
            FROM RDL00002_00002_Landing.JDE.F03012 CM
                INNER JOIN RDL00002_00002_Landing.JDE.F0101 AD on CM.AN8 = AD.AN8
                INNER JOIN RDL00002_00002_Landing.JDE.F0116 ADB on CM.AN8 = ADB.AN8
                LEFT JOIN RDL00002_00002_Landing.JDE.F0005 RE on RE.SY = '01' and RE.RT = '15' and RE.KY = CM.AC15 --Region
                LEFT JOIN RDL00002_00002_Landing.JDE.F0005 ST on ST.SY = '00' and ST.RT = 'S' and ST.KY = ADB.ADDS --State
                LEFT JOIN RDL00002_00002_Landing.JDE.F0005 CT on CT.SY = '00' and CT.RT = 'CN' and CT.KY = ADB.CTR	--Country
	) X
        WHERE	RN = 1
    ),
    -- (1) START
    EquipmentInstaller
    as
    (
        SELECT
            Cast(DOCO as nvarchar(30)) as DOCO,
            DCTO,
            KCOO,
            Cast(Max(AN8DL) as nvarchar(30)) as AN8DL 
		, Cast(Max(AN8AS) as nvarchar(30)) as AN8AS
        --(2)
        FROM RDL00002_00002_Landing.JDE.F1217
        WHERE DOCO > 0 and PRODF = 'ECOFLO' and AN8DL <> '336331'
        GROUP BY DOCO, DCTO, KCOO
    ) -- (1) END
-- (2) START
,
    Consultant
    as
    (
        SELECT
            Cast(DOCO as nvarchar(30)) as DOCO,
            DCTO,
            KCOO,
            Cast(Max(AN8AS) as nvarchar(30)) as AN8AS
        --(2)
        FROM RDL00002_00002_Landing.JDE.F1217
        WHERE DOCO > 0
        GROUP BY DOCO, DCTO, KCOO
    )
-- (2) END

SELECT SO.EMCU as COST_CENTER_CODE,
    SO.KCOO as DOCUMENT_COMPANY,
    isNull(SO.DCTO,'') as ORDER_TYPE,
    Cast(SO.DOCO as NVarchar(30)) as DOCUMENT_NUMBER,
    SO.DOCUMENT_DATE,
    Cast(SO.LNID as Decimal(9,3)) as LINE_NUMBER,
    Case -- Specific rule for one customer in Nebraska which needs to be Iowa.
		When C.AN8 IS NULL Then SO.AN8				-- Invalid customer specified in Sales Order, we overwrite with SoldTo
		When SO.SHAN = N'906155' Then N'552954' 
		Else SO.SHAN
	End as SHIPTO_CUSTOMER_CODE,
    SO.AN8 as SOLDTO_CUSTOMER_CODE,
    SO.TRDJ as ORDER_DATE,
    SO.CNDJ as CANCEL_DATE,
    SO.IVD as INVOICE_DATE,
    SO.ITM as PRODUCT_CODE,
    --Cast(Case When SO.EMCU In ('10010') Then 1 Else 0 End as Bit) as INTERCOMPANY_IND,(3)
    Cast(Case when SO.AN8 IN ('00002', '00009', '09064', '09065', '00109', '00102') or SO.EMCU In ('10010') Then 1 Else 0 End as Bit) as INTERCOMPANY_IND,--(3)
    Cast(Case When SO.CNDJ IS NOT NULL Then 1 Else 0 End as Bit) as CANCELLED_IND,
    Case When SO.CNDJ IS NOT NULL Then ISNULL(SO.UORG,0) Else 0 End as CANCELLED_QTY,
    isNull(SO.UORG,0) as SALES_ORDERED_QTY,
    isNull(SO.SOQS,0) as SALES_QTY,
    SO.CRCD as CURRENCY_CODE,
    Case
		When SO.KCOO IN ('00002','09064') Then SO.AEXP
		When SO.KCOO IN ('00009','09065') Then (SO.AEXP ) * E.RATE_MULTIPLICATOR
	End as ORIGINAL_SALES_CAD_AMT,
    Case
		When SO.KCOO IN ('00002','09064') Then SO.AEXP - isNull(PH.PHTotal,0)
		When SO.KCOO IN ('00009','09065') Then (SO.AEXP - isNull(PH.PHTotal,0)) * E.RATE_MULTIPLICATOR
	End as SALES_CAD_AMT,
    Case 
		When SO.KCOO IN ('00009','09065') Then SO.AEXP - isNull(PH.PHTotal,0)
		When SO.KCOO IN ('00002','09064') and SO.CRCD = 'CAD' Then (SO.AEXP - isNull(PH.PHTotal,0)) * E.RATE_DIVISOR
		When SO.KCOO IN ('00002','09064') and SO.CRCD = 'USD' and isNull(SO.CRR,0) <> 0 Then (SO.AEXP - isNull(PH.PHTotal,0)) / SO.CRR
		When SO.KCOO IN ('00002','09064') and SO.CRCD = 'USD' and isNull(SO.CRR,0) = 0 Then (SO.AEXP - isNull(PH.PHTotal,0)) * E.RATE_DIVISOR
		When SO.KCOO IN ('00002','09064') and SO.CRCD <> 'CAD' Then (SO.AEXP - isNull(PH.PHTotal,0)) * E.RATE_DIVISOR
	End as SALES_USD_AMT,
    Case 
		When SO.KCOO IN ('00009','09065') Then SO.AEXP 
		When SO.KCOO IN ('00002','09064') and SO.CRCD = 'CAD' Then SO.AEXP * E.RATE_DIVISOR
		When SO.KCOO IN ('00002','09064') and SO.CRCD = 'USD' and isNull(SO.CRR,0) <> 0 Then SO.AEXP  / SO.CRR
		When SO.KCOO IN ('00002','09064') and SO.CRCD = 'USD' and isNull(SO.CRR,0) = 0 Then SO.AEXP  * E.RATE_DIVISOR
		When SO.KCOO IN ('00002','09064') and SO.CRCD <> 'CAD' Then SO.AEXP  * E.RATE_DIVISOR
	End as ORIGINAL_SALES_USD_AMT,
    -- Address Overrides
    Cast(Case When SOLD_AO.ANTY IS NOT NULL Then 1 Else 0 End as Bit) as isSoldToOverride,
    SOLD_AO.POSTAL_CODE as SOLDTO_POSTAL_CODE,
    SOLD_AO.CITY_NAME as SOLDTO_CITY_NAME,
    SOLD_AO.COUNTY_NAME as SOLDTO_COUNTY_NAME,
    SOLD_AO.STATE_CODE as SOLDTO_STATE_CODE,
    SOLD_AO.STATE_NAME as SOLDTO_STATE_NAME,
    SOLD_AO.COUNTRY_CODE as SOLDTO_COUNTRY_CODE,
    SOLD_AO.COUNTRY_NAME as SOLDTO_COUNTRY_NAME,
    SOLD_AO.REGION_CODE as SOLDTO_REGION_CODE,
    Cast(Case When SHIP_AO.ANTY IS NOT NULL Then 1 Else 0 End as Bit) as isShipToOverride,
    SHIP_AO.POSTAL_CODE as SHIPTO_POSTAL_CODE,
    SHIP_AO.CITY_NAME as SHIPTO_CITY_NAME,
    SHIP_AO.COUNTY_NAME as SHIPTO_COUNTY_NAME,
    SHIP_AO.STATE_CODE as SHIPTO_STATE_CODE,
    SHIP_AO.STATE_NAME as SHIPTO_STATE_NAME,
    SHIP_AO.COUNTRY_CODE as SHIPTO_COUNTRY_CODE,
    SHIP_AO.COUNTRY_NAME as SHIPTO_COUNTRY_NAME,
    SHIP_AO.REGION_CODE as SHIPTO_REGION_CODE,
    Case When BU.RP04 = 'E01' Then EI.AN8DL End as INSTALLER_CODE, -- //(1)////////////////////////////////////////////////////////////////////////////////
    CO.AN8AS AS CONSULTANT_CODE
-- //(2)///////////////////////////////////////////////////////////
FROM
    (	
	                        SELECT EMCU, KCOO, DCTO, DOCO, LNID, SHAN, AN8, CRCD, TRDJ, CNDJ, IVD, ITM, CO, UORG, AEXP, CRR, SOQS, TRDJ as DOCUMENT_DATE, LOAD_DATE, UPDATED_DATE
        FROM RDL00002_00002_Landing.JDE.F4211
    UNION ALL
        SELECT EMCU, KCOO, DCTO, DOCO, LNID, SHAN, AN8, CRCD, TRDJ, CNDJ, IVD, ITM, CO, UORG, AEXP, CRR, SOQS, isNull(IVD,TRDJ) as DOCUMENT_DATE, LOAD_DATE, UPDATED_DATE
        FROM RDL00002_00002_Landing.JDE.F42119 

) SO
    LEFT JOIN
    (
	-- This is to fix a problem in JDE where Sales Orders are assigned to invalid customer #!!!
	SELECT DISTINCT AN8
    From RDL00002_00002_Landing.JDE.F03012 
) C on SO.SHAN = C.AN8
    LEFT JOIN AddressOverrides SOLD_AO on SO.KCOO = SOLD_AO.KCOO and SO.DCTO = SOLD_AO.DCTO and SO.DOCO = SOLD_AO.DOCO and SOLD_AO.ANTY = 1
    LEFT JOIN AddressOverrides SHIP_AO on SO.KCOO = SHIP_AO.KCOO and SO.DCTO = SHIP_AO.DCTO and SO.DOCO = SHIP_AO.DOCO and SHIP_AO.ANTY = 2
    LEFT JOIN ExRate E on E.BASE_CURRENCY = 'CAD' and E.TARGET_CURRENCY = 'USD' and SO.DOCUMENT_DATE BETWEEN E.BEGIN_DATE and E.END_DATE
    LEFT JOIN Customers SHIP_C on Case -- Specific rule for one customer in Nebraska which needs to be Iowa.
								When Cast(SO.SHAN as NVarchar(30)) = N'906155' Then N'552954' 
								Else Cast(SO.SHAN as NVarchar(30))
							  End = SHIP_C.CUSTOMER_CODE
    LEFT JOIN Customers SOLD_C on SO.AN8 = SOLD_C.CUSTOMER_CODE
    LEFT JOIN PriceHistory PH on SO.DOCO = PH.DOCO AND SO.LNID = PH.LNID
    LEFT JOIN RDL00002_00002_Landing.JDE.F0006 BU on SO.EMCU = BU.MCU --//(1)////////////////////////////////////////////////////////////
    LEFT JOIN EquipmentInstaller EI on SO.DOCO = EI.DOCO AND SO.DCTO = EI.DCTO and SO.KCOO = EI.KCOO -- //(1)///////////////////////////////////////////////////////////
    LEFT JOIN Consultant co on SO.DOCO = CO.DOCO AND SO.DCTO = CO.DCTO and SO.KCOO = CO.KCOO
-- //(2)///////////////////////////////////////////////////////////
WHERE  	SO.DCTO Not In ('SB','S4','ST','SK') and
    (SO.UORG <> 0 or SO.AEXP <> 0) AND
    (
		SO.LOAD_DATE >= @LastUpdate or
    SO.UPDATED_DATE >= @LastUpdate or
    E.LOAD_DATE >= @LastUpdate or
    E.UPDATED_DATE >= @LastUpdate or

    SOLD_AO.LOAD_DATE >= @LastUpdate or
    SOLD_AO.UPDATED_DATE >= @LastUpdate or
    SOLD_AO.COUNTY_LOAD_DATE >= @LastUpdate or
    SOLD_AO.COUNTY_UPDATED_DATE >= @LastUpdate or
    SOLD_AO.REGION_LOAD_DATE >= @LastUpdate or
    SOLD_AO.REGION_UPDATED_DATE >= @LastUpdate or
    SOLD_AO.COUNTRY_LOAD_DATE >= @LastUpdate or
    SOLD_AO.COUNTRY_UPDATED_DATE >= @LastUpdate or
    SOLD_AO.STATE_LOAD_DATE >= @LastUpdate or
    SOLD_AO.STATE_UPDATED_DATE >= @LastUpdate or

    SHIP_AO.LOAD_DATE >= @LastUpdate or
    SHIP_AO.UPDATED_DATE >= @LastUpdate or
    SHIP_AO.COUNTY_LOAD_DATE >= @LastUpdate or
    SHIP_AO.COUNTY_UPDATED_DATE >= @LastUpdate or
    SHIP_AO.REGION_LOAD_DATE >= @LastUpdate or
    SHIP_AO.REGION_UPDATED_DATE >= @LastUpdate or
    SHIP_AO.COUNTRY_LOAD_DATE >= @LastUpdate or
    SHIP_AO.COUNTRY_UPDATED_DATE >= @LastUpdate or
    SHIP_AO.STATE_LOAD_DATE >= @LastUpdate or
    SHIP_AO.STATE_UPDATED_DATE >= @LastUpdate or

    SHIP_C.CM_LOAD_DATE >= @LastUpdate or
    SHIP_C.CM_UPDATED_DATE >= @LastUpdate or
    SHIP_C.AD_LOAD_DATE >= @LastUpdate or
    SHIP_C.AD_UPDATED_DATE >= @LastUpdate or
    SHIP_C.ADBOOK_LOAD_DATE >= @LastUpdate or
    SHIP_C.ADBOOK_UPDATED_DATE >= @LastUpdate or
    SHIP_C.REGION_LOAD_DATE >= @LastUpdate or
    SHIP_C.REGION_UPDATED_DATE >= @LastUpdate or
    SHIP_C.COUNTRY_LOAD_DATE >= @LastUpdate or
    SHIP_C.COUNTRY_UPDATED_DATE >= @LastUpdate or
    SHIP_C.STATE_LOAD_DATE >= @LastUpdate or
    SHIP_C.STATE_UPDATED_DATE >= @LastUpdate or

    SOLD_C.CM_LOAD_DATE >= @LastUpdate or
    SOLD_C.CM_UPDATED_DATE >= @LastUpdate or
    SOLD_C.AD_LOAD_DATE >= @LastUpdate or
    SOLD_C.AD_UPDATED_DATE >= @LastUpdate or
    SOLD_C.ADBOOK_LOAD_DATE >= @LastUpdate or
    SOLD_C.ADBOOK_UPDATED_DATE >= @LastUpdate or
    SOLD_C.REGION_LOAD_DATE >= @LastUpdate or
    SOLD_C.REGION_UPDATED_DATE >= @LastUpdate or
    SOLD_C.COUNTRY_LOAD_DATE >= @LastUpdate or
    SOLD_C.COUNTRY_UPDATED_DATE >= @LastUpdate or
    SOLD_C.STATE_LOAD_DATE >= @LastUpdate or
    SOLD_C.STATE_UPDATED_DATE >= @LastUpdate
	)