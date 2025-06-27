# from ..conn.pdConn import execute_query
# from ..conn.pdConn import execute_query
import sys
import os
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '..conn')))

from pdConn import execute_query


# Save source as dataframe


retfiter = execute_query("select * from [RDL00002_00002_Datawarehouse].[dbo].[REPORT_FILTER]")
