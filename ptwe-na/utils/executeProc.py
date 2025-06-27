import pandas as pd
from sqlalchemy import create_engine, text
from utils.connpd import execute_query

# Create the SQLAlchemy engine
# Define connection parameters
server = "NADWDAT1A"
database = "RDL00002_00002_Datawarehouse"
driver = "ODBC Driver 17 for SQL Server"

# Create SQLAlchemy engine
connection_string = (
    f"mssql+pyodbc://@{server}/{database}?driver={driver}&Trusted_Connection=yes"
)
engine = create_engine(connection_string)


## Function to execute the stored procedure and return the result as a DataFrame
def execute_proc(query, params):
    # Execute and load into a DataFrame
    with engine.connect() as conn:
        result = pd.read_sql_query(query, conn, params=params)
    return result
