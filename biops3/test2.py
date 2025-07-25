import pandas as pd
from utils.connpd import execute_query
from utils.connpp import execute_queryPP
from openpyxl.styles import Alignment
from openpyxl.utils import get_column_letter
import requests
from bs4 import BeautifulSoup

import openpyxl
from openpyxl import load_workbook


select_columns = """
    TABLE_NAME
    ,TABLE_SCHEMA+'.'+TABLE_NAME as TABLE_FULL_NAME
	,COLUMN_NAME
	,DATA_TYPE	
 	,IS_NULLABLE
	,TABLE_CATALOG 
    ,GetDate() as Date
    ,ORDINAL_POSITION
	"""
#####################
###################
## Connect to the Data Lake and extract the catalog of JDE_BI_OPS
DL_biops_DataLake = execute_query(f"""
SELECT 
	{select_columns}
        
FROM [RDL00001_EnterpriseDataLanding].INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'JDE_BI_OPS' AND TABLE_NAME NOT LIKE '%Test%'
ORDER BY TABLE_NAME,COLUMN_NAME""")


# connect to shema dbo Datawarehouse
DW_dboPD = execute_query(f"""
SELECT 
	{select_columns}
FROM [RDL00001_EnterpriseDataWarehouse].INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'dbo' AND TABLE_NAME NOT LIKE '%Test%'
ORDER BY TABLE_NAME,COLUMN_NAME""")


DW_dboPP = execute_queryPP(f"""
SELECT 
	{select_columns}
FROM [RDL00001_EnterpriseDataWarehouse].INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'dbo' AND TABLE_NAME NOT LIKE '%Test%' 
ORDER BY TABLE_NAME,COLUMN_NAME""")


# connect to shema dbo Biops2 en PP
# Cataloge_Biops2 = execute_queryPP(f"""
# SELECT
# 	{select_columns}
# FROM [RDL00001_EnterpriseDataWarehouse].INFORMATION_SCHEMA.COLUMNS
# WHERE TABLE_SCHEMA = 'dbo' AND TABLE_NAME NOT LIKE '%Test%' """)


# connect to shema JDE DataLanding_jde
DataLanding_jde = execute_query(f"""
SELECT 
	{select_columns}
FROM 
    [RDL00001_EnterpriseDataLanding].INFORMATION_SCHEMA.COLUMNS
WHERE 
    TABLE_SCHEMA = 'JDE' 
    AND TABLE_NAME NOT LIKE '%Test%'
    AND TABLE_NAME NOT LIKE '%copy%'
    AND TABLE_NAME NOT LIKE '%bkp%'
    ORDER BY TABLE_NAME,COLUMN_NAME
    """)
