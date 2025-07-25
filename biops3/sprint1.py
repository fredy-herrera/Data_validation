import pandas as pd
from utils.connpd import execute_query
from utils.connpp import execute_queryPP


# open the catalog.xlsx file and read the DataLake sheet
Cataloge_DataLake = pd.read_excel("catalog.xlsx", sheet_name="DataLake")

# execute connection and query to the Data Warehouse PP for F_PurchaseOrderLine
df_purchaseOrder = execute_queryPP("""
SELECT * FROM [RDL00001_EnterpriseDataWarehouse].[dbo].[F_PurchaseOrderLine]
""")

# execute connection and query to the Data Warehouse for D_ItemMaster
df_item_master = execute_queryPP("""
SELECT * FROM [RDL00001_EnterpriseDataWarehouse].[dbo].[D_ItemMaster]
 """)

# execute connection and query to the Data Warehouse for D_ItemBranch
df_item_branch = execute_queryPP("""
SELECT * FROM [RDL00001_EnterpriseDataWarehouse].[dbo].[D_ItemBranch]
 """)


dfs = [
    ("df_item_branch", df_item_branch),
    ("df_purchaseOrder", df_purchaseOrder),
    ("df_item_master", df_item_master),
]

# Build the summary
summary = pd.DataFrame(
    {"name": [name for name, df in dfs], "count": [len(df) for name, df in dfs]}
)

print(summary)

# Cataloge_DataLake.to_excel("Cataloge_DataLake.xlsx", index=False)

# catalogeFiltered = Cataloge_DataLake[
#     Cataloge_DataLake["COLUMN_NAME"].str.contains("CLIENT", case=False)
# ]


#####################################FILTERS######################

filtered_PURCHASE = df_purchaseOrder[
    df_purchaseOrder["OrderNumber"].isin([1200082, 24118074])
]


F4301 = Cataloge_DataLake[
    Cataloge_DataLake["TABLE_NAME"].str.contains("4301", case=False)
]


T4301  = execute_query("""
    SELECT	*
    FROM [RDL00001_EnterpriseDataLanding].JDE_BI_OPS.[V_F4301]
    WHERE PHANBY_BuyerNumber IN ('DUME', 'LAFR', 'LARA', 'LAVP2', 'LECB', 'TREM6', 'ALBD', 'LEDP', 'CARN8', 'CARI3')
 """)