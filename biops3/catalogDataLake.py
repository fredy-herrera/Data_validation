from utils.connpd import execute_query
from utils.connpp import execute_queryPP

#####################
###################
## Connect to the Data Lake and extract the catalog of JDE_BI_OPS
Cataloge_BI_OPS = execute_query("""SELECT TABLE_CATALOG
	,TABLE_SCHEMA
	,TABLE_NAME
	,COLUMN_NAME
	,ORDINAL_POSITION
	,IS_NULLABLE
	,DATA_TYPE
	,CHARACTER_OCTET_LENGTH
	,NUMERIC_PRECISION
	,DATETIME_PRECISION
FROM [RDL00001_EnterpriseDataLanding].INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'JDE_BI_OPS' AND TABLE_NAME NOT LIKE '%Test%' """)

# execute connection and query to the Data Warehouse for D_ItemMaster
d_item_master = execute_query("""
SELECT * FROM [RDL00001_EnterpriseDataWarehouse].[dbo].[D_ItemMaster]
 """)

# execute connection and query to the Data Warehouse for D_ItemBranch
d_item_branch = execute_queryPP("""
SELECT * FROM [RDL00001_EnterpriseDataWarehouse].[dbo].[D_ItemBranch]
 """)


Cataloge_BI_OPS.head()
# # Save the DataFrame to an Excel file
Cataloge_BI_OPS.to_excel("Cataloge_DataLake.xlsx", index=False)

catalogeFiltered = Cataloge_BI_OPS[
    Cataloge_BI_OPS["COLUMN_NAME"].str.contains("CLIENT", case=False)
]

F4311 = Cataloge_BI_OPS[Cataloge_BI_OPS["TABLE_NAME"].str.contains("4311", case=False)]
ILTRDJ_DateTransactionJulian = Cataloge_BI_OPS[Cataloge_BI_OPS["COLUMN_NAME"].str.contains("ILTRDJ_DateTransactionJulian", case=False)]

PDTORG_TransactionOriginator=Cataloge_BI_OPS[Cataloge_BI_OPS["COLUMN_NAME"].str.contains("PDTORG_TransactionOriginator", case=False)]



Cataloge_Datawarehouse = execute_query("""SELECT TABLE_CATALOG
	,TABLE_SCHEMA
	,TABLE_NAME
	,COLUMN_NAME
	,ORDINAL_POSITION
	,IS_NULLABLE
	,DATA_TYPE
	,CHARACTER_OCTET_LENGTH
	,NUMERIC_PRECISION
	,DATETIME_PRECISION
FROM [RDL00001_EnterpriseDataWarehouse].INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'dbo' AND TABLE_NAME NOT LIKE '%Test%' """)

Cataloge_Datawarehouse.to_excel("Cataloge_Datawarehouse.xlsx", index=False)