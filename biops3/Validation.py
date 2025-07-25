import pandas as pd
from utils.connpd import execute_query
from utils.connpp import execute_queryPP


# open the catalog.xlsx file and read the DataLake sheet
Cataloge_DataLake = pd.read_excel(
    "catalog.xlsx",
    sheet_name="DL_biops_DataLake",
    skiprows=2,  # Salta las dos primeras filas (0-indexed)
)


# execute connection and query to the Data Warehouse for D_ItemMaster
d_item_master = execute_query("""
SELECT * FROM [RDL00001_EnterpriseDataWarehouse].[dbo].[D_ItemMaster]
 """)

# execute connection and query to the Data Warehouse for D_ItemBranch
d_item_branch = execute_queryPP("""
SELECT * FROM [RDL00001_EnterpriseDataWarehouse].[dbo].[D_ItemBranch]
 """)


# # Save the DataFrame to an Excel file
# Cataloge_DataLake.to_excel("Cataloge_DataLake.xlsx", index=False)


catalogeFiltered = Cataloge_DataLake[
    Cataloge_DataLake["COLUMN_NAME"].str.contains("CLIENT", case=False)
]

F4311 = Cataloge_DataLake[
    Cataloge_DataLake["TABLE_NAME"].str.contains("4311", case=False)
]
ILTRDJ_DateTransactionJulian = Cataloge_DataLake[
    Cataloge_DataLake["COLUMN_NAME"].str.contains(
        "ILTRDJ_DateTransactionJulian", case=False
    )
]

PDTORG_TransactionOriginator = Cataloge_DataLake[
    Cataloge_DataLake["COLUMN_NAME"].str.contains(
        "PDTORG_TransactionOriginator", case=False
    )
]

######################
##############################





############################
#######################



proc=execute_queryPP("""SELECT 
    ROUTINE_NAME
FROM [RDL00001_EnterpriseDataStaging].INFORMATION_SCHEMA.ROUTINES
WHERE ROUTINE_TYPE = 'PROCEDURE'
  AND ROUTINE_SCHEMA = 'dbo'
  AND ROUTINE_NAME NOT LIKE '%Test%'
ORDER BY ROUTINE_NAME;
""")

ptwe_proc=execute_queryPP("""SELECT 
    ROUTINE_NAME
FROM [RDL00002_99011_DataWarehouse].INFORMATION_SCHEMA.ROUTINES
WHERE ROUTINE_TYPE = 'PROCEDURE'
  AND ROUTINE_SCHEMA = 'dbo'
  AND ROUTINE_NAME NOT LIKE '%Test%'
ORDER BY ROUTINE_NAME;
""")



# Definir las consultas en un diccionario para mantener el código organizado
queries = {
    "NextStatusCode": "SELECT distinct NextStatusCode FROM F_PurchaseOrderLine",
    "LineTypeCode": "SELECT distinct LineTypeCode FROM RDL00001_EnterpriseDataWarehouse.dbo.F_PurchaseOrderLine",
    "CompanyCode": "SELECT distinct CompanyCode FROM RDL00001_EnterpriseDataWarehouse.dbo.F_PurchaseOrderLine",
    "OrderType": "SELECT distinct OrderType FROM RDL00001_EnterpriseDataWarehouse.dbo.F_PurchaseOrderLine"
}

# Ejecutar las consultas y almacenar los resultados en un diccionario de DataFrames
dataframes = {name: execute_queryPP(query) for name, query in queries.items()}

# Concatenar los DataFrames horizontalmente
df_combined = pd.concat(dataframes.values(), axis=1)

# Renombrar las columnas para que coincidan con los nombres en el diccionario
df_combined.columns = dataframes.keys()

df_combined = df_combined.fillna('')

# Mostrar el resultado
df_combined
