-- Select rows from a Table or View 'TableOrViewName' in schema 'SchemaName'
SELECT min(OrderDate), max(OrderDate) 
FROM RDL00001_EnterpriseDataWarehouse.dbo.F_PurchaseOrderLine
-- WHERE 	/* add search conditions here */
GO

SELECT 
--TOP 1000 *
--COUNT(*) 
DISTINCT COLEDG_LedgType, DRDL01_Description001
FROM RDL00001_EnterpriseDataWarehouse.dbo.F_ProductCost_Purchase
WHERE CCCO IN ('00001', '00077', '09011', '09052', '09041', '00024')
and COLEDG_LedgType in (01,07,22)
GO



WHERE  trim(CostCenter)	 IN ('101', '112', '118', '370', '403', '124', '535', '536', '537', '952')
    AND trim(Company) IN ('00001', '00077', '09011', '09052', '09041', '00024')
GO

SELECT  distinct CostCenter 
FROM RDL00001_EnterpriseDataWarehouse.dbo.D_CostCenter
 WHERE  Company IN ('00001', '00077', '09011', '09052', '09041', '00024')


/* add search conditions here */
GO


--d_date
SELECT min(Date), max(Date) , min(Id), max(Id) 
FROM RDL00001_EnterpriseDataWarehouse.Shared.DimDate
-- WHERE 	/* add search conditions here */
go

SELECT min(Date), max(Date) , min(Id), max(Id)
FROM
    RDL00001_EnterpriseDataWarehouse.Shared.DimDate
WHERE
    YEAR(Id) BETWEEN YEAR(getdate()) - 5
    AND YEAR(getdate()) + 1

    GO
    USE [RDL00001_EnterpriseDataStaging]
    --USE [RDL00002_99011_DataWarehouse]
     SELECT ROUTINE_NAME,
    REPLACE(REPLACE(ROUTINE_DEFINITION, CHAR(13), 'salto'), CHAR(10), 'salto') AS definition_no_linebreaks
    FROM INFORMATION_SCHEMA.ROUTINES
    ORDER BY ROUTINE_NAME
    GO


    GO
    USE [RDL00001_EnterpriseDataStaging]
    --USE [RDL00002_99011_DataWarehouse]
     SELECT ROUTINE_NAME,
    REPLACE(REPLACE(ROUTINE_DEFINITION, CHAR(13), 'salto'), CHAR(10), 'salto') AS definition_no_linebreaks
    FROM INFORMATION_SCHEMA.ROUTINES
    ORDER BY ROUTINE_NAME
    GO
     EXEC sp_helptext 'Load_F_ProductCost_Purchase'

     