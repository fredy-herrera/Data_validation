USE [RDL00002_00002_Datawarehouse]
GO

/****** Object:  StoredProcedure [dbo].[uspRptOrder]    Script Date: 2025-06-16 3:06:47 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO







--CREATE Procedure [dbo].[uspRptOrder]
--	@CalendarType NVarchar(30),
--	@AsOfDate Date,
--	@State NVarchar(Max),
--	@User NVarchar(60)

--WITH RECOMPILE
--as
--Begin -- RAVM 2021-02-19 HAJO training

/****** Script for SelectTopNRows command from SSMS  ******/
-- RAVM 20200902 updates : 
-- exclude all cost center J%
-- exclude amount = 0
-- in the first select from salesorders, exclude the combination family2_code = E01 / type1_code = E03, otherwise the diuv KIT will be duplicated.

-- Test Variables

DECLARE @CalendarType NVarchar(30),
	@AsOfDate Date,
	@State NVarchar(Max),
	@User NVarchar(60);

SET @CalendarType = 'FISCAL ADJUSTED';
SET @AsOfDate = '2025-06-22';
SET @State = 'ON,QC';
SET @User = 'TECHNT\700130';


DROP TABLE if exists #Dates;
DROP TABLE if exists #Orders;

SET NOCOUNT ON
	Create Table #Dates (
		DATE_ID Int Primary Key ,
		DATE_CODE Date INDEX IX_DateTemp NONCLUSTERED,
		[YEAR] Smallint ,
		YEAR_DESCRIPTION NVarchar(30),
		MONTH_NUMBER Tinyint ,
		MONTH_DESCRIPTION_ENGLISH NVarchar(30) ,
		MONTH_DESCRIPTION_FRENCH NVarchar(30) ,
		DAY_POSITION_IN_YEAR Smallint ,
		WEEK_NUMBER Tinyint ,
		WEEK_DESCRIPTION_ENGLISH NVarchar(30) ,
		WEEK_DESCRIPTION_FRENCH NVarchar(30) ,
		WEEK_POSITION_IN_MONTH Tinyint ,
		DAY_POSITION_IN_WEEK Tinyint ,
		DAY_POSITION_IN_MONTH Tinyint ,
		MONTH_MIN_WEEK_NUMBER Tinyint 
	)
	
	Create Table #Orders (
		BUSINESSSTRUCTURE_ID Int Not Null,
		PRODUCT_ID Int Not Null,
		BUDGET_CAD_AMT Decimal(18,2) Not Null,
		SALES_CAD_AMT Decimal(18,2) Not Null,
		BUDGET_ORDERED_QTY Decimal(12,5) Null,
		SALES_ORDERED_QTY Decimal(12,5) Null,
		CANCELLED_IND INT Not Null,
		ORDER_DATE_ID Int Not Null,
		CANCEL_DATE_ID Int Not Null,
		DOCUMENT_ID bigint not null,
		SOLDTO_CUSTOMER_ID int not null,
		SHIPTO_GEOGRAPHY_ID int not null,
		INTERCOMPANY_IND int not NULL,
		TRANSACTION_TYPE_ID int not NULL
	)
	Create Index IX_SalesTemp on #Orders(BUSINESSSTRUCTURE_ID, PRODUCT_ID)

	INSERT INTO #Dates
	SELECT	DATE_ID,
		DATE_CODE,
		Case 
			When @CalendarType = 'FISCAL ADJUSTED' Then NA_FISCAL_ADJ_YR
			When @CalendarType = 'FISCAL' Then NA_FISCAL_YR
			When @CalendarType = 'CIVIL' Then NA_CIVIL_YR
		End as [Year],
		Case 
			When @CalendarType = 'FISCAL ADJUSTED' Then NA_FISCAL_ADJ_YR_DESC
			When @CalendarType = 'FISCAL' Then NA_FISCAL_YR_DESC
			When @CalendarType = 'CIVIL' Then NA_CIVIL_YR_DESC
		End as YEAR_DESCRIPTION,
		Case 
			When @CalendarType = 'FISCAL ADJUSTED' Then NA_FISCAL_ADJ_MONTH_NUM
			When @CalendarType = 'FISCAL' Then NA_FISCAL_MONTH_NUM
			When @CalendarType = 'CIVIL' Then NA_CIVIL_MONTH_NUM
		End as MONTH_NUMBER,
		Case 
			When @CalendarType = 'FISCAL ADJUSTED' Then NA_FISCAL_ADJ_MONTH_DESC_EN
			When @CalendarType = 'FISCAL' Then NA_FISCAL_MONTH_DESC_EN
			When @CalendarType = 'CIVIL' Then NA_CIVIL_MONTH_DESC_EN
		End as MONTH_DESCRIPTION_ENGLISH,
		Case 
			When @CalendarType = 'FISCAL ADJUSTED' Then NA_FISCAL_ADJ_MONTH_DESC_FR
			When @CalendarType = 'FISCAL' Then NA_FISCAL_MONTH_DESC_FR
			When @CalendarType = 'CIVIL' Then NA_CIVIL_MONTH_DESC_FR
		End as MONTH_DESCRIPTION_FRENCH,
		Case 
			When @CalendarType = 'FISCAL ADJUSTED' Then NA_FISCAL_ADJ_YR_DAY_POSITION
			When @CalendarType = 'FISCAL' Then NA_FISCAL_YR_DAY_POSITION
			When @CalendarType = 'CIVIL' Then NA_CIVIL_YR_DAY_POSITION
		End as DAY_POSITION_IN_YEAR,
		Case 
			When @CalendarType = 'FISCAL ADJUSTED' Then NA_FISCAL_ADJ_WEEK_NUM
			When @CalendarType = 'FISCAL' Then NA_FISCAL_WEEK_NUM
			When @CalendarType = 'CIVIL' Then NA_CIVIL_WEEK_NUM
		End as WEEK_NUMBER,
		Case 
			When @CalendarType = 'FISCAL ADJUSTED' Then NA_FISCAL_ADJ_WEEK_DESC_EN
			When @CalendarType = 'FISCAL' Then NA_FISCAL_WEEK_DESC_EN
			When @CalendarType = 'CIVIL' Then NA_CIVIL_WEEK_DESC_EN
		End as WEEK_DESCRIPTION_ENGLISH,
		Case 
			When @CalendarType = 'FISCAL ADJUSTED' Then NA_FISCAL_ADJ_WEEK_DESC_FR
			When @CalendarType = 'FISCAL' Then NA_FISCAL_WEEK_DESC_FR
			When @CalendarType = 'CIVIL' Then NA_CIVIL_WEEK_DESC_FR
		End as WEEK_DESCRIPTION_FRENCH,
		Case
			When @CalendarType = 'FISCAL ADJUSTED' Then NA_FISCAL_ADJ_MONTH_WEEK_POSITION
			When @CalendarType = 'FISCAL' Then NA_FISCAL_MONTH_WEEK_POSITION
			When @CalendarType = 'CIVIL' Then NA_CIVIL_MONTH_WEEK_POSITION
		End as WEEK_POSITION_IN_MONTH,
		Case
			When @CalendarType = 'FISCAL ADJUSTED' Then NA_FISCAL_WEEK_DAY_POSITION
			When @CalendarType = 'FISCAL' Then NA_FISCAL_WEEK_DAY_POSITION
			When @CalendarType = 'CIVIL' Then NA_CIVIL_WEEK_DAY_POSITION
		End as DAY_POSITION_IN_WEEK,
		Case
			When @CalendarType = 'FISCAL ADJUSTED' Then NA_FISCAL_MONTH_DAY_POSITION
			When @CalendarType = 'FISCAL' Then NA_FISCAL_MONTH_DAY_POSITION
			When @CalendarType = 'CIVIL' Then NA_CIVIL_MONTH_DAY_POSITION
		End as DAY_POSITION_IN_MONTH,
		MIN(Case
			When @CalendarType = 'FISCAL ADJUSTED' Then NA_FISCAL_ADJ_WEEK_NUM
			When @CalendarType = 'FISCAL' Then NA_FISCAL_WEEK_NUM
			When @CalendarType = 'CIVIL' Then NA_CIVIL_WEEK_NUM 
		End) OVER (PARTITION BY Case 
			When @CalendarType = 'FISCAL ADJUSTED' Then NA_FISCAL_ADJ_YR
			When @CalendarType = 'FISCAL' Then NA_FISCAL_YR
			When @CalendarType = 'CIVIL' Then NA_CIVIL_YR
		End, Case 
			When @CalendarType = 'FISCAL ADJUSTED' Then NA_FISCAL_ADJ_MONTH_NUM
			When @CalendarType = 'FISCAL' Then NA_FISCAL_MONTH_NUM
			When @CalendarType = 'CIVIL' Then NA_CIVIL_MONTH_NUM
		End) as MONTH_MIN_WEEK_NUMBER
	FROM dbo.D_DATES

	-- ******************************************************************************************************************
	-- Prepare Sales / Budget table
	-- ******************************************************************************************************************
	INSERT INTO #Orders (BUSINESSSTRUCTURE_ID, PRODUCT_ID, BUDGET_CAD_AMT, SALES_CAD_AMT, BUDGET_ORDERED_QTY, SALES_ORDERED_QTY, CANCELLED_IND, ORDER_DATE_ID, CANCEL_DATE_ID, DOCUMENT_ID, SOLDTO_CUSTOMER_ID, SHIPTO_GEOGRAPHY_ID, INTERCOMPANY_IND, TRANSACTION_TYPE_ID)
	SELECT	S.BUSINESSSTRUCTURE_ID,
			S.PRODUCT_ID,
			0 as BUDGET_CAD_AMT,
			S.SALES_CAD_AMT,
			0 as BUDGET_ORDERED_QTY,
			S.SALES_ORDERED_QTY,
			S.CANCELLED_IND,
			S.ORDER_DATE_ID,
			S.CANCEL_DATE_ID,
			S.DOCUMENT_ID,
			S.SOLDTO_CUSTOMER_ID,
			S.SHIPTO_GEOGRAPHY_ID,
			S.INTERCOMPANY_IND,
			0 as TRANSACTION_TYPE_ID
	FROM dbo.F_SALESORDERS S
	INNER JOIN dbo.D_BUSINESSSTRUCTURE BS on S.BUSINESSSTRUCTURE_ID = BS.BUSINESSSTRUCTURE_ID
	INNER JOIN dbo.D_PRODUCTS P on s.PRODUCT_ID = P.PRODUCT_ID -- RAVM 20200901
	--WHERE	S.INTERCOMPANY_IND = 0 	and	BS.COST_CENTER_CODE Not In ('J01121','J01122','J01123') /*ravm 2020901 */ --and (P.FAMILY2_CODE <> 'E01' and P.TYPE1_CODE <> 'E03')
	WHERE	S.INTERCOMPANY_IND = 0 	and	(BS.COST_CENTER_CODE Not like ('J%') OR BS.[BUSINESS_CENTER_CODE] = 'E33')
			and S.PRODUCT_ID Not in (Select distinct P. PRODUCT_ID from dbo.D_PRODUCTS P where P.FAMILY2_CODE = 'E01' and P.TYPE1_CODE = 'E03') -- ravm 20200901
	UNION ALL
	SELECT	B.BUSINESSSTRUCTURE_ID,
			B.PRODUCT_ID,
			B.BUDGET_CAD_AMT,
			0 as SALES_CAD_AMT,
			B.BUDGET_QTY as BUDGET_ORDERED_QTY,
			0 as SALES_ORDERED_QTY,
			0 as CANCELLED_IND,
			B.DATE_ID,
			-1 as CANCEL_DATE_ID,
			0 as DOCUMENT_ID,
			0 as SOLDTO_CUSTOMER_ID,
			B.GEOGRAPHY_ID as SHIPTO_GEOGRAPHY_ID,
			0 as INTERCOMPANY_IND,
			1 as TRANSACTION_TYPE_ID
	FROM dbo.F_BUDGETS B
	INNER JOIN dbo.D_BUSINESSSTRUCTURE BS on B.BUSINESSSTRUCTURE_ID = BS.BUSINESSSTRUCTURE_ID
	--WHERE BS.COST_CENTER_CODE Not In ('J01121','J01122','J01123')
	WHERE	(BS.COST_CENTER_CODE Not like ('J%') OR BS.[BUSINESS_CENTER_CODE] = 'E33') -- ravm 20200901
			and B.PRODUCT_ID Not in (Select distinct P. PRODUCT_ID from dbo.D_PRODUCTS P where P.FAMILY2_CODE = 'E01' and P.TYPE1_CODE = 'E03')
	UNION ALL 
	SELECT	S.BUSINESSSTRUCTURE_ID,
			S.PRODUCT_ID,
			0 as BUDGET_CAD_AMT,
			0 as SALES_CAD_AMT,
			0 as BUDGET_ORDERED_QTY,
			S.SALES_ORDERED_QTY,
			S.CANCELLED_IND,
			S.ORDER_DATE_ID,
			S.CANCEL_DATE_ID,
			S.DOCUMENT_ID,
			S.SOLDTO_CUSTOMER_ID,
			S.SHIPTO_GEOGRAPHY_ID,
			S.INTERCOMPANY_IND,
			2 as TRANSACTION_TYPE_ID
	FROM dbo.F_SALESORDERS S
	INNER JOIN dbo.D_BUSINESSSTRUCTURE BS on S.BUSINESSSTRUCTURE_ID = BS.BUSINESSSTRUCTURE_ID
	INNER JOIN dbo.D_PRODUCTS P on s.PRODUCT_ID = P.PRODUCT_ID
	--WHERE	S.INTERCOMPANY_IND = 0 	and	BS.COST_CENTER_CODE Not In ('J01121','J01122','J01123')  AND P.TYPE1_CODE IN ('E03','E04')
	WHERE	S.INTERCOMPANY_IND = 0 	and	(BS.COST_CENTER_CODE Not like ('J%') OR BS.[BUSINESS_CENTER_CODE] = 'E33')
	AND P.TYPE1_CODE IN ('E03','E04') -- ravm 20200901
	UNION ALL
	-- RAVM 2020-06-12 ADD section to distinct DIUV IN ECOFLO --
	SELECT	B.BUSINESSSTRUCTURE_ID,
			B.PRODUCT_ID,
			B.BUDGET_CAD_AMT,
			0 as SALES_CAD_AMT,
			B.BUDGET_QTY as BUDGET_ORDERED_QTY,
			0 as SALES_ORDERED_QTY,
			0 as CANCELLED_IND,
			B.DATE_ID,
			-1 as CANCEL_DATE_ID,
			0 as DOCUMENT_ID,
			0 as SOLDTO_CUSTOMER_ID,
			B.GEOGRAPHY_ID as SHIPTO_GEOGRAPHY_ID,
			0 as INTERCOMPANY_IND,
			3 as TRANSACTION_TYPE_ID
	FROM dbo.F_BUDGETS B
	INNER JOIN dbo.D_BUSINESSSTRUCTURE BS on B.BUSINESSSTRUCTURE_ID = BS.BUSINESSSTRUCTURE_ID
	INNER JOIN dbo.D_PRODUCTS P on B.PRODUCT_ID = P.PRODUCT_ID
	--WHERE	BS.COST_CENTER_CODE Not In ('J01121','J01122','J01123') AND P.TYPE1_CODE IN ('E03','E04')
	WHERE	(BS.COST_CENTER_CODE Not like ('J%') OR BS.[BUSINESS_CENTER_CODE] = 'E33')
	AND P.TYPE1_CODE IN ('E03','E04') -- ravm 20200901; 
	-- END RAVM 2020-06-12 --
	-- 700130 2022-02-01 ADD section to distinct ND IN ECOFLO --
	UNION ALL 
	SELECT	S.BUSINESSSTRUCTURE_ID,
			S.PRODUCT_ID,
			0 as BUDGET_CAD_AMT,
			0 as SALES_CAD_AMT,
			0 as BUDGET_ORDERED_QTY,
			S.SALES_ORDERED_QTY,
			S.CANCELLED_IND,
			S.ORDER_DATE_ID,
			S.CANCEL_DATE_ID,
			S.DOCUMENT_ID,
			S.SOLDTO_CUSTOMER_ID,
			S.SHIPTO_GEOGRAPHY_ID,
			S.INTERCOMPANY_IND,
			4 as TRANSACTION_TYPE_ID
	FROM dbo.F_SALESORDERS S
	INNER JOIN dbo.D_BUSINESSSTRUCTURE BS on S.BUSINESSSTRUCTURE_ID = BS.BUSINESSSTRUCTURE_ID
	INNER JOIN dbo.D_PRODUCTS P on s.PRODUCT_ID = P.PRODUCT_ID
	--WHERE	S.INTERCOMPANY_IND = 0 	and	BS.COST_CENTER_CODE Not In ('J01121','J01122','J01123')  AND P.TYPE1_CODE IN ('E03','E04')
	WHERE	S.INTERCOMPANY_IND = 0 	and	(BS.COST_CENTER_CODE Not like ('J%') OR BS.[BUSINESS_CENTER_CODE] = 'E33')
	AND P.TYPE1_CODE IN ('E05') AND P.FAMILY3_CODE <> 'E04' -- ravm 20200901
	UNION ALL
	-- 700130 2022-02-01 ADD section to distinct ND IN ECOFLO --
	SELECT	B.BUSINESSSTRUCTURE_ID,
			B.PRODUCT_ID,
			B.BUDGET_CAD_AMT,
			0 as SALES_CAD_AMT,
			B.BUDGET_QTY as BUDGET_ORDERED_QTY,
			0 as SALES_ORDERED_QTY,
			0 as CANCELLED_IND,
			B.DATE_ID,
			-1 as CANCEL_DATE_ID,
			0 as DOCUMENT_ID,
			0 as SOLDTO_CUSTOMER_ID,
			B.GEOGRAPHY_ID as SHIPTO_GEOGRAPHY_ID,
			0 as INTERCOMPANY_IND,
			5 as TRANSACTION_TYPE_ID
	FROM dbo.F_BUDGETS B
	INNER JOIN dbo.D_BUSINESSSTRUCTURE BS on B.BUSINESSSTRUCTURE_ID = BS.BUSINESSSTRUCTURE_ID
	INNER JOIN dbo.D_PRODUCTS P on B.PRODUCT_ID = P.PRODUCT_ID
	--WHERE	BS.COST_CENTER_CODE Not In ('J01121','J01122','J01123') AND P.TYPE1_CODE IN ('E03','E04')
	WHERE	(BS.COST_CENTER_CODE Not like ('J%') OR BS.[BUSINESS_CENTER_CODE] = 'E33')
	AND P.TYPE1_CODE IN ('E05') AND P.FAMILY3_CODE <> 'E04'; 
	-- END RAVM 2020-06-12 --





	-- ******************************************************************************************************************
	-- Main Query
	-- ******************************************************************************************************************
		SELECT 
		/* test ravm 20200901 */
		--DOC.DOCUMENT_NUMBER,
		--DOC.ORDER_TYPE,
		/* end test */
		S.TRANSACTION_TYPE_ID as TRANSACTION_TYPE_ID,
		P.FAMILY2_NAME AS PRODUCT_FAMILY2_NAME,
		P.FAMILY2_CODE AS PRODUCT_FAMILY2_CODE,
		P.FAMILY3_CODE AS PRODUCT_FAMILY3_CODE,
		P.TYPE1_CODE AS PRODUCT_TYPE1_CODE,
		
		Case 
			--When TRANSACTION_TYPE_ID = 2  Then 'Tertiary'
			When TRANSACTION_TYPE_ID in ('2','3','4','5')  Then 'Tertiary' -- RAVM 2020-06-12
			WHEN P.FAMILY1_CODE='R01' Then 'Rain Water' -- HAJO 2021-03-22
			WHEN P.FAMILY3_CODE='E18' AND P.TYPE1_CODE = 'E07' Then 'Linear Module'-- 622776 2023-05-02
		Else P.FAMILY2_NAME
		End as FAMILY2_NAME,
		-- RAVM 2020-04-28
		Case 
			--When TRANSACTION_TYPE_ID = 2  Then 'E01'
			When TRANSACTION_TYPE_ID in ('2','3','4','5')  Then 'E01' -- RAVM 2020-06-12
			WHEN P.FAMILY1_CODE='R01' Then 'R01' -- HAJO 2021-03-22
		Else P.FAMILY2_CODE
		End as FAMILY2_CODE,
		Case 
			--When TRANSACTION_TYPE_ID = 2  Then 'DiUV in Ecoflo'
			When TRANSACTION_TYPE_ID in ('2','3')  Then 'DiUV in Ecoflo' -- RAVM 2020-06-12
			When TRANSACTION_TYPE_ID in ('4','5')  Then 'DN in Ecoflo' -- 700130 2022-02-01
			--When P.FAMILY3_NAME in ('DN') THEN 'DN Kit' -- 700130 2022-02-01
			When P.FAMILY3_CODE='E09' AND CHARINDEX('Plastic',P.CATEGORY2_NAME,1)>0 then 'Ecoflo Plastic'
			When P.FAMILY3_CODE='E09' AND CHARINDEX('Fiberglass',P.CATEGORY2_NAME,1)>0 then 'Ecoflo Fiberglass'
			When P.FAMILY3_CODE='E09' AND CHARINDEX('Concrete',P.CATEGORY2_NAME,1)>0 then 'Ecoflo Concrete'
			WHEN P.FAMILY3_CODE='E18' AND P.TYPE1_CODE = 'E07' Then ''-- 622776 2023-05-02
		Else P.FAMILY3_NAME
		End as FAMILY3_NAME,
		Case 
			--When P.FAMILY3_CODE in ('DIUV-Classic','DIUV Self-Cleaning') or TRANSACTION_TYPE_ID = 2  Then 'DIUV'
			When P.FAMILY3_CODE in ('DIUV-Classic','DIUV Self-Cleaning') or TRANSACTION_TYPE_ID in ('2','3')  Then 'DIUV' -- RAVM 2020-06-12
			When TRANSACTION_TYPE_ID in ('4','5')  Then 'DN' -- 700130 2022-02-01
			When P.FAMILY3_NAME in ('DN') THEN 'DN Kit' -- 700130 2022-02-01
			When P.FAMILY3_CODE='E09' AND CHARINDEX('Plastic',P.CATEGORY2_NAME,1)>0 then 'Ecoflo Plastic'
			When P.FAMILY3_CODE='E09' AND CHARINDEX('Fiberglass',P.CATEGORY2_NAME,1)>0 then 'Ecoflo Fiberglass'
			When P.FAMILY3_CODE='E09' AND CHARINDEX('Concrete',P.CATEGORY2_NAME,1)>0 then 'Ecoflo Concrete'
			Else P.FAMILY3_NAME
		End as FAMILY3_NAME_ADJUSTED,
		Case 
			--When TRANSACTION_TYPE_ID = 2  Then 'Tertiary'
			When TRANSACTION_TYPE_ID in ('2','3','4','5') Then 'Tertiary' -- RAVM 2020-06-12
			When P.FAMILY3_CODE not in ('E09','E06','E07','E08','E05','E02','E04','E10','E03','E13','E15','E14','E18') Then 'Other' 
			WHEN P.FAMILY1_CODE='R01' Then 'Rain Water' -- HAJO 2021-03-22
			Else P.FAMILY2_NAME
		End as FAMILY2_NAME_ADJUSTED,
			Case 
			When P.FAMILY3_CODE not in ('E09','E06','E07','E08','E05','E02','E04','E10','E03','E13','E15','E14','E18') Then 99 
			Else P.FAMILY2_SORT
		End as FAMILY2_SORT_ADJUSTED,

		-- **** 622776 2022-02-10 ***
		--P.FAMILY2_SORT, 
		Case 
			--When TRANSACTION_TYPE_ID = 2  Then 'Tertiary'
			When TRANSACTION_TYPE_ID in ('2','3','4','5')  Then 2 -- RAVM 2020-06-12
			WHEN P.FAMILY1_CODE='R01' Then 4 -- HAJO 2021-03-22
			WHEN P.FAMILY3_CODE='E18' AND P.TYPE1_CODE = 'E07' Then 5 -- 622776 2023-05-02
		Else P.FAMILY2_SORT
		End as FAMILY2_SORT,
		-- **** 622776 2022-02-10 ***

		SHIPGEO.COUNTRY_NAME,
		SHIPGEO.STATE_NAME,
		REPLACE(P.MEDIA_NAME,' MEDIA','') as MEDIA_NAME ,
		REPLACE(P.DIMENSION_NAME,'PTA ','') as DIMENSION_NAME, 
		P.PRODUCT_NAME,
		P.TYPE1_CODE,  --RAVM 2019-10-02
		P.TYPE1_NAME,
		P.UNITS_IND,
		CASE WHEN P.FAMILY3_CODE='E18' AND P.TYPE1_CODE = 'E07' THEN 1 ELSE 0 END AS DISPLAY_QTY_IND,
		P.PRODUCT_INTERNAL_CODE,
		
		--------------------------------------------------------------- DAILY --------------------------------------------------------------------------------
		Sum(Case When (D.[Year] = DC.[Year] and D.WEEK_NUMBER = DC.WEEK_NUMBER and D.DAY_POSITION_IN_WEEK in (1,2) and D.DATE_CODE <= @AsOfDate)  Then S.SALES_ORDERED_QTY else 0 end) -
			Sum(case when (DCAN.[Year] = DC.[Year] and DCAN.WEEK_NUMBER = DC.WEEK_NUMBER and DCAN.DAY_POSITION_IN_WEEK in(1,2)and D.DATE_CODE <= @AsOfDate)   then S.SALES_ORDERED_QTY else 0 end) as SALES_QTY_MONDAY,
		Sum(Case When (D.[Year] = DC.[Year]  and D.WEEK_NUMBER = DC.WEEK_NUMBER and D.DAY_POSITION_IN_WEEK =3 and D.DATE_CODE <= @AsOfDate)   Then S.SALES_ORDERED_QTY else 0 end) -
			Sum(case when (DCAN.[Year] = DC.[Year] and DCAN.WEEK_NUMBER = DC.WEEK_NUMBER and DCAN.DAY_POSITION_IN_WEEK =3 and D.DATE_CODE <= @AsOfDate) then S.SALES_ORDERED_QTY else 0 end) as SALES_QTY_TUESDAY,
		Sum(Case When (D.[Year] = DC.[Year]  and D.WEEK_NUMBER = DC.WEEK_NUMBER and D.DAY_POSITION_IN_WEEK =4 and D.DATE_CODE <= @AsOfDate) Then S.SALES_ORDERED_QTY else 0 end) -
			Sum(case when (DCAN.[Year] = DC.[Year] and DCAN.WEEK_NUMBER = DC.WEEK_NUMBER and DCAN.DAY_POSITION_IN_WEEK =4 and D.DATE_CODE <= @AsOfDate) then S.SALES_ORDERED_QTY else 0 end) as SALES_QTY_WEDNESDAY,
		Sum(Case When (D.[Year] = DC.[Year]  and D.WEEK_NUMBER = DC.WEEK_NUMBER and D.DAY_POSITION_IN_WEEK =5 and D.DATE_CODE <= @AsOfDate) Then S.SALES_ORDERED_QTY else 0 end) -
			Sum(case when (DCAN.[Year] = DC.[Year] and DCAN.WEEK_NUMBER = DC.WEEK_NUMBER and DCAN.DAY_POSITION_IN_WEEK =5 and D.DATE_CODE <= @AsOfDate) then S.SALES_ORDERED_QTY else 0  end) as SALES_QTY_THURSDAY,
		Sum(Case When (D.[Year] = DC.[Year] and D.WEEK_NUMBER = DC.WEEK_NUMBER and D.DAY_POSITION_IN_WEEK in (6,7) and D.DATE_CODE <= @AsOfDate) Then S.SALES_ORDERED_QTY else 0	end) -
			Sum(case when (DCAN.[Year] = DC.[Year] and DCAN.WEEK_NUMBER = DC.WEEK_NUMBER and DCAN.DAY_POSITION_IN_WEEK in(6,7) and D.DATE_CODE <= @AsOfDate) then S.SALES_ORDERED_QTY else 0 end) as SALES_QTY_FRIDAY,
		--------------------------------------------------------------- WEEK --------------------------------------------------------------------------------
		--Sum(Case When (D.[Year] = DC.[Year] and D.MONTH_NUMBER = DC.MONTH_NUMBER  AND D.WEEK_POSITION_IN_MONTH = 1  and D.DATE_CODE <= @AsOfDate) Then S.SALES_ORDERED_QTY else 0	end)-
		--	Sum(case when (DCAN.[Year] = DC.[Year] and DCAN.MONTH_NUMBER = DC.MONTH_NUMBER AND DCAN.WEEK_POSITION_IN_MONTH = 1  and D.DATE_CODE <= @AsOfDate) then S.SALES_ORDERED_QTY else 0 end) as SALES_QTY_WK1,
		--Sum(Case When (D.[Year] = DC.[Year] and D.MONTH_NUMBER = DC.MONTH_NUMBER and  D.WEEK_POSITION_IN_MONTH = 2  and D.DATE_CODE <= @AsOfDate) Then S.SALES_ORDERED_QTY else 0	end)-
		--	Sum(case when (DCAN.[Year] = DC.[Year] and DCAN.MONTH_NUMBER = DC.MONTH_NUMBER AND DCAN.WEEK_POSITION_IN_MONTH = 2  and D.DATE_CODE <= @AsOfDate) then S.SALES_ORDERED_QTY else 0 end) as SALES_QTY_WK2,
		--Sum(Case When (D.[Year] = DC.[Year] and D.MONTH_NUMBER = DC.MONTH_NUMBER AND D.WEEK_POSITION_IN_MONTH = 3  and D.DATE_CODE <= @AsOfDate) Then S.SALES_ORDERED_QTY else 0 end)-
		--	Sum(case when (DCAN.[Year] = DC.[Year] and DCAN.MONTH_NUMBER = DC.MONTH_NUMBER AND DCAN.WEEK_POSITION_IN_MONTH = 3  and D.DATE_CODE <= @AsOfDate) then S.SALES_ORDERED_QTY else 0 end) as SALES_QTY_WK3,
		--Sum(Case When (D.[Year] = DC.[Year] and D.MONTH_NUMBER = DC.MONTH_NUMBER AND D.WEEK_POSITION_IN_MONTH = 4  and D.DATE_CODE <= @AsOfDate) Then S.SALES_ORDERED_QTY else 0	end)-
		--	Sum(case when (DCAN.[Year] = DC.[Year] and DCAN.MONTH_NUMBER = DC.MONTH_NUMBER AND DCAN.WEEK_POSITION_IN_MONTH = 4  and D.DATE_CODE <= @AsOfDate) then S.SALES_ORDERED_QTY else 0 end) as SALES_QTY_WK4,
		--Sum(Case When (D.[Year] = DC.[Year] and D.MONTH_NUMBER = DC.MONTH_NUMBER AND D.WEEK_POSITION_IN_MONTH = 5  and D.DATE_CODE <= @AsOfDate) Then S.SALES_ORDERED_QTY else 0 end)-
		--	Sum(case when (DCAN.[Year] = DC.[Year] and DCAN.MONTH_NUMBER = DC.MONTH_NUMBER AND DCAN.WEEK_POSITION_IN_MONTH = 5  and D.DATE_CODE <= @AsOfDate) then S.SALES_ORDERED_QTY else 0 end) as SALES_QTY_WK5,
		--(Sum(Case When (D.[Year] = DC.[Year] and D.MONTH_NUMBER = DC.MONTH_NUMBER AND D.WEEK_POSITION_IN_MONTH = 1  and D.DATE_CODE <= @AsOfDate) Then S.SALES_CAD_AMT else 0 end)-
		--	Sum(case when (DCAN.[Year] = DC.[Year] and DCAN.MONTH_NUMBER = DC.MONTH_NUMBER AND DCAN.WEEK_POSITION_IN_MONTH = 1  and D.DATE_CODE <= @AsOfDate) then S.SALES_CAD_AMT else 0  end)) / 1000 as SALES_AMT_WK1,
		--(Sum(Case When (D.[Year] = DC.[Year] and D.MONTH_NUMBER = DC.MONTH_NUMBER  AND D.WEEK_POSITION_IN_MONTH = 2  and D.DATE_CODE <= @AsOfDate) Then S.SALES_CAD_AMT else 0	end)-
		--	Sum(case when (DCAN.[Year] = DC.[Year] and DCAN.MONTH_NUMBER = DC.MONTH_NUMBER AND DCAN.WEEK_POSITION_IN_MONTH = 2  and D.DATE_CODE <= @AsOfDate) then S.SALES_CAD_AMT else 0 end)) / 1000 as SALES_AMT_WK2,
		--(Sum(Case When (D.[Year] = DC.[Year] and D.MONTH_NUMBER = DC.MONTH_NUMBER  AND D.WEEK_POSITION_IN_MONTH = 3  and D.DATE_CODE <= @AsOfDate) Then S.SALES_CAD_AMT else 0	end)-
		--	Sum(case when (DCAN.[Year] = DC.[Year] and DCAN.MONTH_NUMBER = DC.MONTH_NUMBER AND DCAN.WEEK_POSITION_IN_MONTH = 3  and D.DATE_CODE <= @AsOfDate) then S.SALES_CAD_AMT else 0 end)) / 1000 as SALES_AMT_WK3,
		--(Sum(Case When (D.[Year] = DC.[Year] and D.MONTH_NUMBER = DC.MONTH_NUMBER AND D.WEEK_POSITION_IN_MONTH = 4  and D.DATE_CODE <= @AsOfDate) Then S.SALES_CAD_AMT else 0 end)-
		--	Sum(case when (DCAN.[Year] = DC.[Year] and DCAN.MONTH_NUMBER = DC.MONTH_NUMBER AND DCAN.WEEK_POSITION_IN_MONTH = 4  and D.DATE_CODE <= @AsOfDate) then S.SALES_CAD_AMT else 0 end)) / 1000 as SALES_AMT_WK4,
		--(Sum(Case When (D.[Year] = DC.[Year] and D.MONTH_NUMBER = DC.MONTH_NUMBER  AND D.WEEK_POSITION_IN_MONTH = 5  and D.DATE_CODE <= @AsOfDate) Then S.SALES_CAD_AMT else 0	end)-
		--	Sum(case when (DCAN.[Year] = DC.[Year] and DCAN.MONTH_NUMBER = DC.MONTH_NUMBER AND DCAN.WEEK_POSITION_IN_MONTH = 5  and D.DATE_CODE <= @AsOfDate) then S.SALES_CAD_AMT else 0 end))/ 1000 as SALES_AMT_WK5,


		Sum(Case When ((@CalendarType = 'CIVIL' AND CIVIL_LASTWEEKS.SEQ = 5) OR (@CalendarType <> 'CIVIL' AND D.[Year] = DC.[Year] and D.MONTH_NUMBER = DC.MONTH_NUMBER  AND D.WEEK_POSITION_IN_MONTH = 1))  and D.DATE_CODE <= @AsOfDate Then S.SALES_ORDERED_QTY else 0	end)-
			Sum(Case When ((@CalendarType = 'CIVIL' AND CANCEL_CIVIL_LASTWEEKS.SEQ = 5) OR (@CalendarType <> 'CIVIL' AND DCAN.[Year] = DC.[Year] and DCAN.MONTH_NUMBER = DC.MONTH_NUMBER AND DCAN.WEEK_POSITION_IN_MONTH = 1))  and D.DATE_CODE <= @AsOfDate then S.SALES_ORDERED_QTY else 0 end) as SALES_QTY_WK1,
		Sum(Case When ((@CalendarType = 'CIVIL' AND CIVIL_LASTWEEKS.SEQ = 4) OR (@CalendarType <> 'CIVIL' AND D.[Year] = DC.[Year] and D.MONTH_NUMBER = DC.MONTH_NUMBER and  D.WEEK_POSITION_IN_MONTH = 2))  and D.DATE_CODE <= @AsOfDate Then S.SALES_ORDERED_QTY else 0	end)-
			Sum(Case When ((@CalendarType = 'CIVIL' AND CANCEL_CIVIL_LASTWEEKS.SEQ = 4) OR (@CalendarType <> 'CIVIL' AND DCAN.[Year] = DC.[Year] and DCAN.MONTH_NUMBER = DC.MONTH_NUMBER AND DCAN.WEEK_POSITION_IN_MONTH = 2))  and D.DATE_CODE <= @AsOfDate then S.SALES_ORDERED_QTY else 0 end) as SALES_QTY_WK2,
		Sum(Case When ((@CalendarType = 'CIVIL' AND CIVIL_LASTWEEKS.SEQ = 3) OR (@CalendarType <> 'CIVIL' AND D.[Year] = DC.[Year] and D.MONTH_NUMBER = DC.MONTH_NUMBER AND D.WEEK_POSITION_IN_MONTH = 3))  and D.DATE_CODE <= @AsOfDate Then S.SALES_ORDERED_QTY else 0 end)-
			Sum(Case When ((@CalendarType = 'CIVIL' AND CANCEL_CIVIL_LASTWEEKS.SEQ = 3) OR (@CalendarType <> 'CIVIL' AND DCAN.[Year] = DC.[Year] and DCAN.MONTH_NUMBER = DC.MONTH_NUMBER AND DCAN.WEEK_POSITION_IN_MONTH = 3))  and D.DATE_CODE <= @AsOfDate then S.SALES_ORDERED_QTY else 0 end) as SALES_QTY_WK3,
		Sum(Case When ((@CalendarType = 'CIVIL' AND CIVIL_LASTWEEKS.SEQ = 2) OR (@CalendarType <> 'CIVIL' AND D.[Year] = DC.[Year] and D.MONTH_NUMBER = DC.MONTH_NUMBER AND D.WEEK_POSITION_IN_MONTH = 4))  and D.DATE_CODE <= @AsOfDate Then S.SALES_ORDERED_QTY else 0	end)-
			Sum(Case When ((@CalendarType = 'CIVIL' AND CANCEL_CIVIL_LASTWEEKS.SEQ = 2) OR (@CalendarType <> 'CIVIL' AND DCAN.[Year] = DC.[Year] and DCAN.MONTH_NUMBER = DC.MONTH_NUMBER AND DCAN.WEEK_POSITION_IN_MONTH = 4))  and D.DATE_CODE <= @AsOfDate then S.SALES_ORDERED_QTY else 0 end) as SALES_QTY_WK4,
		Sum(Case When ((@CalendarType = 'CIVIL' AND CIVIL_LASTWEEKS.SEQ = 1) OR (@CalendarType <> 'CIVIL' AND D.[Year] = DC.[Year] and D.MONTH_NUMBER = DC.MONTH_NUMBER AND D.WEEK_POSITION_IN_MONTH = 5))  and D.DATE_CODE <= @AsOfDate Then S.SALES_ORDERED_QTY else 0 end)-
			Sum(Case When ((@CalendarType = 'CIVIL' AND CANCEL_CIVIL_LASTWEEKS.SEQ = 1) OR (@CalendarType <> 'CIVIL' AND DCAN.[Year] = DC.[Year] and DCAN.MONTH_NUMBER = DC.MONTH_NUMBER AND DCAN.WEEK_POSITION_IN_MONTH = 5))  and D.DATE_CODE <= @AsOfDate then S.SALES_ORDERED_QTY else 0 end) as SALES_QTY_WK5,
		(Sum(Case When ((@CalendarType = 'CIVIL' AND CIVIL_LASTWEEKS.SEQ = 5) OR (@CalendarType <> 'CIVIL' AND D.[Year] = DC.[Year] and D.MONTH_NUMBER = DC.MONTH_NUMBER AND D.WEEK_POSITION_IN_MONTH = 1))  and D.DATE_CODE <= @AsOfDate Then S.SALES_CAD_AMT else 0 end)-
			Sum(Case When ((@CalendarType = 'CIVIL' AND CANCEL_CIVIL_LASTWEEKS.SEQ = 5) OR (@CalendarType <> 'CIVIL' AND DCAN.[Year] = DC.[Year] and DCAN.MONTH_NUMBER = DC.MONTH_NUMBER AND DCAN.WEEK_POSITION_IN_MONTH = 1))  and D.DATE_CODE <= @AsOfDate then S.SALES_CAD_AMT else 0  end)) / 1000 as SALES_AMT_WK1,
		(Sum(Case When ((@CalendarType = 'CIVIL' AND CIVIL_LASTWEEKS.SEQ = 4) OR (@CalendarType <> 'CIVIL' AND D.[Year] = DC.[Year] and D.MONTH_NUMBER = DC.MONTH_NUMBER  AND D.WEEK_POSITION_IN_MONTH = 2))  and D.DATE_CODE <= @AsOfDate Then S.SALES_CAD_AMT else 0	end)-
			Sum(Case When ((@CalendarType = 'CIVIL' AND CANCEL_CIVIL_LASTWEEKS.SEQ = 4) OR (@CalendarType <> 'CIVIL' AND DCAN.[Year] = DC.[Year] and DCAN.MONTH_NUMBER = DC.MONTH_NUMBER AND DCAN.WEEK_POSITION_IN_MONTH = 2))  and D.DATE_CODE <= @AsOfDate then S.SALES_CAD_AMT else 0 end)) / 1000 as SALES_AMT_WK2,
		(Sum(Case When ((@CalendarType = 'CIVIL' AND CIVIL_LASTWEEKS.SEQ = 3) OR (@CalendarType <> 'CIVIL' AND D.[Year] = DC.[Year] and D.MONTH_NUMBER = DC.MONTH_NUMBER  AND D.WEEK_POSITION_IN_MONTH = 3))  and D.DATE_CODE <= @AsOfDate Then S.SALES_CAD_AMT else 0	end)-
			Sum(Case When ((@CalendarType = 'CIVIL' AND CANCEL_CIVIL_LASTWEEKS.SEQ = 3) OR (@CalendarType <> 'CIVIL' AND DCAN.[Year] = DC.[Year] and DCAN.MONTH_NUMBER = DC.MONTH_NUMBER AND DCAN.WEEK_POSITION_IN_MONTH = 3))  and D.DATE_CODE <= @AsOfDate then S.SALES_CAD_AMT else 0 end)) / 1000 as SALES_AMT_WK3,
		(Sum(Case When ((@CalendarType = 'CIVIL' AND CIVIL_LASTWEEKS.SEQ = 2) OR (@CalendarType <> 'CIVIL' AND D.[Year] = DC.[Year] and D.MONTH_NUMBER = DC.MONTH_NUMBER AND D.WEEK_POSITION_IN_MONTH = 4))  and D.DATE_CODE <= @AsOfDate Then S.SALES_CAD_AMT else 0 end)-
			Sum(Case When ((@CalendarType = 'CIVIL' AND CANCEL_CIVIL_LASTWEEKS.SEQ = 2) OR (@CalendarType <> 'CIVIL' AND DCAN.[Year] = DC.[Year] and DCAN.MONTH_NUMBER = DC.MONTH_NUMBER AND DCAN.WEEK_POSITION_IN_MONTH = 4))  and D.DATE_CODE <= @AsOfDate then S.SALES_CAD_AMT else 0 end)) / 1000 as SALES_AMT_WK4,
		(Sum(Case When ((@CalendarType = 'CIVIL' AND CIVIL_LASTWEEKS.SEQ = 1) OR (@CalendarType <> 'CIVIL' AND D.[Year] = DC.[Year] and D.MONTH_NUMBER = DC.MONTH_NUMBER  AND D.WEEK_POSITION_IN_MONTH = 5))  and D.DATE_CODE <= @AsOfDate Then S.SALES_CAD_AMT else 0	end)-
			Sum(Case When ((@CalendarType = 'CIVIL' AND CANCEL_CIVIL_LASTWEEKS.SEQ = 1) OR (@CalendarType <> 'CIVIL' AND DCAN.[Year] = DC.[Year] and DCAN.MONTH_NUMBER = DC.MONTH_NUMBER AND DCAN.WEEK_POSITION_IN_MONTH = 5))  and D.DATE_CODE <= @AsOfDate then S.SALES_CAD_AMT else 0 end))/ 1000 as SALES_AMT_WK5,
		--------------------------------------------------------------- MTD --------------------------------------------------------------------------------
		Sum(Case When (D.[Year] = DC.[Year] and D.MONTH_NUMBER = DC.MONTH_NUMBER  and D.DATE_CODE <= @AsOfDate) Then S.SALES_ORDERED_QTY else 0 end)-
			Sum(case when (DCAN.[Year] = DC.[Year] and DCAN.MONTH_NUMBER = DC.MONTH_NUMBER  and D.DATE_CODE <= @AsOfDate) then S.SALES_ORDERED_QTY else 0 end) as SALES_QTY_MTD,
		Case when @CalendarType = 'CIVIL' then
				Sum(Case When (D.[Year] = DC.[Year] -1 and D.MONTH_NUMBER = DC.MONTH_NUMBER and D.DAY_POSITION_IN_MONTH <= DC.DAY_POSITION_IN_MONTH ) Then S.SALES_ORDERED_QTY else 0 end)-
			Sum(case when (DCAN.[Year] = DC.[Year]-1 and DCAN.MONTH_NUMBER = DC.MONTH_NUMBER  and DCAN.DAY_POSITION_IN_MONTH <= DC.DAY_POSITION_IN_MONTH  ) then S.SALES_ORDERED_QTY else 0 end)
				Else Sum(Case When (D.[Year] = DC.[Year] -1 and D.[WEEK_NUMBER]>= DC.[MONTH_MIN_WEEK_NUMBER] and D.DAY_POSITION_IN_YEAR <= DC.DAY_POSITION_IN_YEAR ) Then S.SALES_ORDERED_QTY else 0 end)-
			Sum(case when (DCAN.[Year] = DC.[Year]-1 and DCAN.[WEEK_NUMBER]>= DC.[MONTH_MIN_WEEK_NUMBER] and DCAN.DAY_POSITION_IN_YEAR <= DC.DAY_POSITION_IN_YEAR  ) then S.SALES_ORDERED_QTY else 0 end) End as SALES_QTY_MTD_LY,
		(Sum(Case When (D.[Year] = DC.[Year] and D.MONTH_NUMBER = DC.MONTH_NUMBER  and D.DATE_CODE <= @AsOfDate ) Then S.SALES_CAD_AMT else 0 end)-
			Sum(case when (DCAN.[Year] = DC.[Year] and DCAN.MONTH_NUMBER = DC.MONTH_NUMBER and D.DATE_CODE <= @AsOfDate) then S.SALES_CAD_AMT else 0 end)) / 1000 as SALES_AMT_MTD,
		Case when @CalendarType = 'CIVIL' then
			(Sum(Case When (D.[Year] = DC.[Year] -1 and D.MONTH_NUMBER = DC.MONTH_NUMBER and D.DAY_POSITION_IN_MONTH <= DC.DAY_POSITION_IN_MONTH ) Then S.SALES_CAD_AMT else 0 end)-
			Sum(case when (DCAN.[Year] = DC.[Year]-1 and DCAN.MONTH_NUMBER = DC.MONTH_NUMBER  and DCAN.DAY_POSITION_IN_MONTH <= DC.DAY_POSITION_IN_MONTH) then S.SALES_CAD_AMT else 0 end)) / 1000
				Else (Sum(Case When (D.[Year] = DC.[Year] -1 and D.[WEEK_NUMBER]>= DC.[MONTH_MIN_WEEK_NUMBER] and D.DAY_POSITION_IN_YEAR <= DC.DAY_POSITION_IN_YEAR ) Then S.SALES_CAD_AMT else 0 end)-
			Sum(case when (DCAN.[Year] = DC.[Year]-1 and DCAN.[WEEK_NUMBER]>= DC.[MONTH_MIN_WEEK_NUMBER] and DCAN.DAY_POSITION_IN_YEAR <= DC.DAY_POSITION_IN_YEAR) then S.SALES_CAD_AMT else 0 end)) / 1000 End as SALES_AMT_MTD_LY,
		--------------------------------------------------------------- YTD --------------------------------------------------------------------------------
		Sum(Case When (D.[Year] = DC.[Year] and D.MONTH_NUMBER <= DC.MONTH_NUMBER  and D.DATE_CODE <= @AsOfDate) Then S.SALES_ORDERED_QTY else 0 end)-
			Sum(case when (DCAN.[Year] = DC.[Year] and DCAN.MONTH_NUMBER <= DC.MONTH_NUMBER  and D.DATE_CODE <= @AsOfDate) then S.SALES_ORDERED_QTY else 0 end) as SALES_QTY_YTD,		
		Sum(Case When (D.[Year] = DC.[Year] -1 /* and D.MONTH_NUMBER <= DC.MONTH_NUMBER*/ and D.DAY_POSITION_IN_YEAR <= DC.DAY_POSITION_IN_YEAR) Then S.SALES_ORDERED_QTY else 0 end)-
			Sum(case when (DCAN.[Year] = DC.[Year]-1 /* and DCAN.MONTH_NUMBER <= DC.MONTH_NUMBER*/ and DCAN.DAY_POSITION_IN_YEAR <= DC.DAY_POSITION_IN_YEAR ) then S.SALES_ORDERED_QTY else 0 end) as SALES_QTY_YTD_LY,
		(Sum(Case When (D.[Year] = DC.[Year] and D.MONTH_NUMBER <= DC.MONTH_NUMBER  and D.DATE_CODE <= @AsOfDate) Then S.SALES_CAD_AMT else 0 end)-
			Sum(case when (DCAN.[Year] = DC.[Year] and DCAN.MONTH_NUMBER <= DC.MONTH_NUMBER  and D.DATE_CODE <= @AsOfDate) then S.SALES_CAD_AMT else 0  end)) / 1000 as SALES_AMT_YTD,
		(Sum(Case When (D.[Year] = DC.[Year] -1 /* and D.MONTH_NUMBER <= DC.MONTH_NUMBER*/ and D.DAY_POSITION_IN_YEAR <= DC.DAY_POSITION_IN_YEAR) Then S.SALES_CAD_AMT else 0 end)-
			Sum(case when (DCAN.[Year] = DC.[Year]-1 /* and DCAN.MONTH_NUMBER <= DC.MONTH_NUMBER*/ and DCAN.DAY_POSITION_IN_YEAR <= DC.DAY_POSITION_IN_YEAR ) then S.SALES_CAD_AMT else 0 end)) / 1000 as SALES_AMT_YTD_LY,
		-------------------------------------------------------------- Budget ------------------------------------------------------------------------------
		--------------------------------------------------------------- MTD --------------------------------------------------------------------------------
		Sum(Case When D.[Year] = DC.[Year] and D.MONTH_NUMBER = DC.MONTH_NUMBER and D.WEEK_NUMBER <= DC.WEEK_NUMBER and D.DAY_POSITION_IN_YEAR <= DC.DAY_POSITION_IN_YEAR  Then S.BUDGET_ORDERED_QTY Else 0 End) as BUDGET_QTY_MTD,
		Sum(Case When D.[Year] = DC.[Year] and D.MONTH_NUMBER = DC.MONTH_NUMBER and D.WEEK_NUMBER <= DC.WEEK_NUMBER and D.DAY_POSITION_IN_YEAR <= DC.DAY_POSITION_IN_YEAR Then S.BUDGET_CAD_AMT Else 0 End) / 1000 as BUDGET_AMT_MTD,
		--------------------------------------------------------------- YTD --------------------------------------------------------------------------------
		Sum(Case When D.[Year] = DC.[Year] and D.MONTH_NUMBER <= DC.MONTH_NUMBER and D.WEEK_NUMBER <= DC.WEEK_NUMBER and D.DAY_POSITION_IN_YEAR <= DC.DAY_POSITION_IN_YEAR Then  S.BUDGET_ORDERED_QTY Else 0 End) as BUDGET_QTY_YTD,
		Sum(Case When D.[Year] = DC.[Year] and D.MONTH_NUMBER <= DC.MONTH_NUMBER and D.WEEK_NUMBER <= DC.WEEK_NUMBER and D.DAY_POSITION_IN_YEAR <= DC.DAY_POSITION_IN_YEAR Then S.BUDGET_CAD_AMT Else 0 End) / 1000 as BUDGET_AMT_YTD

		FROM #Orders s
		INNER JOIN dbo.D_PRODUCTS P on s.PRODUCT_ID = P.PRODUCT_ID
		INNER JOIN #Dates D on ORDER_DATE_ID = D.DATE_ID 
		INNER JOIN #Dates DCAN on CANCEL_DATE_ID = DCAN.DATE_ID 
		INNER JOIN #Dates DC on DC.DATE_CODE = @AsOfDate
		LEFT JOIN (SELECT NA_CIVIL_YR, NA_CIVIL_WEEK_NUM, MIN(DATE_CODE) AS DATE_CODE, ROW_NUMBER() OVER (ORDER BY MIN(DATE_CODE) DESC) AS SEQ
			FROM D_DATES
			WHERE DATE_CODE <= @AsOfDate
			GROUP BY NA_CIVIL_YR, NA_CIVIL_WEEK_NUM
			) CIVIL_LASTWEEKS ON CIVIL_LASTWEEKS.NA_CIVIL_YR = D.YEAR AND CIVIL_LASTWEEKS.NA_CIVIL_WEEK_NUM = D.WEEK_NUMBER
		LEFT JOIN (SELECT NA_CIVIL_YR, NA_CIVIL_WEEK_NUM, MIN(DATE_CODE) AS DATE_CODE, ROW_NUMBER() OVER (ORDER BY MIN(DATE_CODE) DESC) AS SEQ
			FROM D_DATES
			WHERE DATE_CODE <= @AsOfDate
			GROUP BY NA_CIVIL_YR, NA_CIVIL_WEEK_NUM
			) CANCEL_CIVIL_LASTWEEKS ON CANCEL_CIVIL_LASTWEEKS.NA_CIVIL_YR = DCAN.YEAR AND CANCEL_CIVIL_LASTWEEKS.NA_CIVIL_WEEK_NUM = DCAN.WEEK_NUMBER
		LEFT JOIN dbo.D_DOCUMENTS DOC on S.DOCUMENT_ID= DOC.DOCUMENT_ID 
		LEFT JOIN dbo.D_CUSTOMERS CUS on S.SOLDTO_CUSTOMER_ID = CUSTOMER_ID
		LEFT JOIN dbo.D_GEOGRAPHIES SHIPGEO on S.SHIPTO_GEOGRAPHY_ID = SHIPGEO.GEOGRAPHY_ID
		LEFT JOIN dbo.D_BUSINESSSTRUCTURE DBUS on S.BUSINESSSTRUCTURE_ID = DBUS.BUSINESSSTRUCTURE_ID
		INNER JOIN 
		(
			SELECT	Top 1 STATE_NAME, COUNTRY_NAME
			FROM dbo.D_GEOGRAPHIES
			WHERE	COUNTRY_CODE = 'CA' and
					STATE_CODE = 'QC'
		) QC on 1=1
		INNER JOIN dbo.REPORT_FILTER RF on RF.CATEGORY = 'SALES' and @User = RF.USERNAME and
			(
				(SHIPGEO.COUNTRY_CODE = RF.COLUMN1_FILTER and Case When SHIPGEO.COUNTRY_CODE = 'CA' and SHIPGEO.STATE_CODE = '' Then 'QC' Else SHIPGEO.STATE_CODE End = RF.COLUMN2_FILTER) or
				(SHIPGEO.COUNTRY_CODE = RF.COLUMN1_FILTER and RF.COLUMN2_FILTER = 'ALL') or
				(RF.COLUMN1_FILTER = 'ALL')
			)
		WHERE
			D.DATE_ID!= DCAN.DATE_ID And
			(D.[Year] BETWEEN DC.[Year]-3 AND DC.[Year]  or DCAN.[Year] BETWEEN DC.[Year]-3 AND DC.[Year]) AND 	
			
			--S.SALES_CAD_AMT <> 0 and -- ravm 2020-09-02	
				SHIPGEO.STATE_CODE In (Select String From dbo.udfSplitParameter(@State,',')) and
			(
				s.TRANSACTION_TYPE_ID in  ('1','3','5') OR
				(
				(s.TRANSACTION_TYPE_ID = 0 OR s.TRANSACTION_TYPE_ID= 2 OR s.TRANSACTION_TYPE_ID= 4) 
				AND
				DOC.ORDER_TYPE in ('SI','SO','UP') AND 
				(DOC.KIT_LINE_NUMBER is null OR (P.FAMILY3_CODE='E18' AND P.TYPE1_CODE = 'E07'))  AND
				DBUS.COST_CENTER_CODE != '10269' AND 
				DOC.LINE_TYPE_CODE not in ('F','P','T') AND 
				CUS.CUSTOMER_CODE not in ('9','75')  AND 
				DOC.DOCUMENT_COMPANY in ('00002','00009','00015','00022','00023','00027','00047','00048','00053','00058','00059','00063','00064','00065','00066','00067','00068','00075','00076') AND
				DBUS.BUSINESS_CENTER_ADJUSTED_NAME in ('RESIDENTIAL PRODUCTS' , 'SERVICE RESIDENTIAL' , 'E-Commerce')
				/*ADD HAJO 2021-03-12, DELETE CANCELED ORDERS TO NOT BE COUNTED IN THE AGGREGATION*/
				AND CANCEL_DATE_ID =-1
				)
			)

			-- DEBUG CAMS
			--and PRODUCT_INTERNAL_CODE = '366369'
			--and 
			--TRANSACTION_TYPE_ID in ('2','3')
		GROUP BY
			P.CATEGORY2_NAME,
			P.UNITS_IND,
			P.FAMILY1_CODE, -- HAJO 22-03-2021
			P.FAMILY2_NAME,
			P.FAMILY2_CODE, 
			P.FAMILY3_NAME,
			P.FAMILY3_CODE, 
			P.FAMILY2_SORT,
			SHIPGEO.COUNTRY_NAME,
			SHIPGEO.STATE_NAME,
			P.MEDIA_NAME,
			P.DIMENSION_NAME,
			P.PRODUCT_NAME,
			P.TYPE1_NAME,
			P.PRODUCT_INTERNAL_CODE,
			TRANSACTION_TYPE_ID, 
			P.TYPE1_CODE--,
			/* test ravm 20200901 */
			--DOC.DOCUMENT_NUMBER,
			--DOC.ORDER_TYPE
			/* end test */

		ORDER BY FAMILY3_NAME_ADJUSTED




GO


