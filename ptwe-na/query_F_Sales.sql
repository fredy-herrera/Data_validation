SET DATEFIRST 7;
-- Sunday because we need to push the Exchange Rate date (EX.EFT) to the next Saturday
DROP TABLE IF EXISTS ##testF_Sales;

With
    ExRate
    as
    (
        SELECT RATE_TYPE_CODE, BASE_CURRENCY, TARGET_CURRENCY,
            isNull(DateAdd(d,1,LAG(END_DATE) OVER(Partition By RATE_TYPE_CODE, BASE_CURRENCY, TARGET_CURRENCY Order By END_DATE)),'1900-01-01') as BEGIN_DATE,
            END_DATE, RATE_DIVISOR, RATE_MULTIPLICATOR
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
            Upper(isNull(RG.DL01,'')) as REGION_NAME
        FROM RDL00002_00002_Landing.JDE.F4006 AO
            LEFT JOIN RDL00002_00002_Landing.JDE.F0005 CN on CN.SY = '00' and CN.RT = 'CT' and AO.COUN = CN.DL01 and CN.DL02 LIKE '%ADM. REGION%'
            LEFT JOIN RDL00002_00002_Landing.JDE.F0005 RG on RG.SY = '01' and RG.RT = '15' and RG.KY = RTRIM(LTRIM(RIGHT(CN.DL02,3)))
            LEFT JOIN RDL00002_00002_Landing.JDE.F0005 CY on CY.SY = '00' and CY.RT = 'CN' and CY.KY = AO.CTR
            LEFT JOIN RDL00002_00002_Landing.JDE.F0005 ST on ST.SY = '00' and ST.RT = 'S' and ST.KY = AO.ADDS
    ),
    EquipmentInstaller
    as
    (
        SELECT
            Cast(DOCO as nvarchar(30)) as DOCO,
            DCTO,
            KCOO,
            Cast(Max(AN8DL) as nvarchar(30)) as AN8DL
        FROM RDL00002_00002_Landing.JDE.F1217
        WHERE DOCO > 0 and PRODF = 'ECOFLO' and AN8DL <> '336331'
        GROUP BY DOCO, DCTO, KCOO
    )

SELECT
    Cast(Case When SO.DCTO IS NOT NULL Then 'SALESORDER' Else 'GL' End as NVarchar(30)) as ORIGIN_CODE,
    Coalesce(SO.DCT,GL.DCT,'') as DOCUMENT_TYPE,
    Coalesce(SO.DCTO,GL.DCTO,'') as ORDER_TYPE,
    Cast(isNull(SO.DOCO,GL.DOC) as NVarchar(30)) as DOCUMENT_NUMBER,
    isNull(SO.KCOO,GL.KCO) as DOCUMENT_COMPANY,
    isNull(SO.TRDJ,GL.DGJ) as DOCUMENT_DATE,
    Case When SO.DCTO IS NOT NULL Then '' Else GL.LT End as DOCUMENT_LEDGER_TYPE,
    Cast(isNull(SO.LNID,GL.JELN) as Decimal(9,3)) as LINE_NUMBER,
    Case When SO.DCTO IS NOT NULL Then '' Else GL.EXTL End as LINE_EXTENSION_CODE,
    GL.MCU as COST_CENTER_CODE,
    Case -- Specific rule for one customer in Nebraska which needs to be Iowa.
		When Cast(Coalesce(SO.SHAN,GL.AN8,BU.AN8) as NVarchar(30)) = N'906155' Then N'552954' 
		Else Cast(Coalesce(SO.SHAN,GL.AN8,BU.AN8) as NVarchar(30))
	End as SHIPTO_CUSTOMER_CODE,
    Cast(Coalesce(SO.AN8,GL.AN8,BU.AN8) as NVarchar(30)) as SOLDTO_CUSTOMER_CODE,
    Cast(Coalesce(SO.ITM,GL.ITM) as NVarchar(30)) as PRODUCT_CODE,
    --Cast(Case When GL.MCU In ('10010','10330') Then 1 Else 0 End as Bit) as INTERCOMPANY_IND,
    Cast(Case when SO.AN8 IN ('00002', '00009', '09064', '09065', '00109', '00102') or GL.MCU In ('10010','10330')   Then 1 Else 0 End as Bit) as INTERCOMPANY_IND,--(3)
    GL.DGJ as GL_DATE,
    GL.CO,
    isNull(SO.TRDJ,GL.DGJ) as ORDER_DATE,
    GL.CRCD as CURRENCY_CODE,
    isNull(SO.SOQS,0) as SALES_QTY,
    GL.AA as SALES_DOC_CURRENCY,
    isNull(SO.MCU,'N/A') as BRANCH_CODE,
    Case
		When GL.CO IN ('00002','09064') Then -GL.AA
		When GL.CO IN ('00009','09065') Then -GL.AA * E.RATE_MULTIPLICATOR
	End as SALES_CAD_AMT,
    Case
		When GL.CO IN ('00009','09065') Then -GL.AA
		When GL.CO IN ('00002','09064') and GL.CRCD = 'USD' and GL.CRR <> 0 Then -GL.AA / GL.CRR
		When GL.CO IN ('00002','09064') and GL.CRCD = 'USD' and GL.CRR = 0 Then -GL.AA * isNull(E.RATE_DIVISOR,0)
		When GL.CO IN ('00002','09064') and GL.CRCD <> 'USD' Then -GL.AA * isNull(E.RATE_DIVISOR,0)
		When GL.CO IN ('00002','09064') and GL.CRCD = 'CAD' Then -GL.AA * isNull(E.RATE_DIVISOR,0)
	End as SALES_USD_AMT,

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
    --EI.AN8DL as INSTALLER_CODE,
    Case When BU.RP04 = 'E01' Then EI.AN8DL End as INSTALLER_CODE
into ##testF_Sales
FROM RDL00002_00002_Landing.JDE.F0911 GL
    LEFT JOIN RDL00002_00002_Landing.JDE.F42119 as SO on GL.KCO = SO.KCOO and GL.DCT = SO.DCT and GL.DOC = SO.DOC and GL.LNID = SO.LNID
    LEFT JOIN ExRate E on E.BASE_CURRENCY = 'CAD' and E.TARGET_CURRENCY = 'USD' and GL.DGJ BETWEEN E.BEGIN_DATE and E.END_DATE
    LEFT JOIN RDL00002_00002_Landing.JDE.F0006 BU on GL.MCU = BU.MCU
    LEFT JOIN AddressOverrides SOLD_AO on SO.KCOO = SOLD_AO.KCOO and SO.DCTO = SOLD_AO.DCTO and SO.DOCO = SOLD_AO.DOCO and SOLD_AO.ANTY = 1
    LEFT JOIN AddressOverrides SHIP_AO on SO.KCOO = SHIP_AO.KCOO and SO.DCTO = SHIP_AO.DCTO and SO.DOCO = SHIP_AO.DOCO and SHIP_AO.ANTY = 2
    LEFT JOIN EquipmentInstaller EI on SO.DOCO = EI.DOCO AND SO.DCTO = EI.DCTO and SO.KCOO = EI.KCOO
WHERE	
	(
		GL.POST = 'P' and
    GL.CO In ('00002','00009','09064','09065') and
    GL.OBJ BETWEEN '30000' and '39999' and
    isNull(GL.DCT,'') Not In ('PD','PG') and
    isNull(GL.DCTO,'') <> 'ST' and
    GL.LT = 'AA'
	) OR
    -- Two exceptions to consider.  If this number increase, we have to find another way to include the exceptions (or educate people to make verification at month end)
    (
		(GL.DCT = 'PD' and GL.DOC = 4136 and GL.LT = 'AA' and GL.OBJ BETWEEN 30000 and 39999 and GL.DGJ = '20150227') OR
    (GL.R2 = '14205943' and GL.OBJ BETWEEN 30000 and 39999 and GL.DGJ = '20140924')
	)



-------#########
--select from temp
--###########

select COUNT(*)
from ##testF_Sales
select top 10
    *
from ##testF_Sales 
   