import pandas as pd
from utils.connpd import execute_query
from utils.connpp import execute_queryPP



ptwe_procs=execute_queryPP("""SELECT 
    ROUTINE_NAME
FROM [RDL00002_99011_DataWarehouse].INFORMATION_SCHEMA.ROUTINES
WHERE ROUTINE_TYPE = 'PROCEDURE'
  AND ROUTINE_SCHEMA = 'dbo'
  AND ROUTINE_NAME NOT LIKE '%Test%'
ORDER BY ROUTINE_NAME;
""")

