import pandas as pd
from utils.connpd import execute_query
from utils.connpp import execute_queryPP
import openpyxl
from openpyxl import load_workbook





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
df_combined.to_excel('ListChampsOptions.xlsx', index=False)
