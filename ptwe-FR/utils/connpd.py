##CONNECTION

import pandas as pd
from sqlalchemy import create_engine

# Define connection parameters
server = "NADWDAT1A"
database = "RDL00001_EnterpriseDataWarehouse"
driver = "ODBC Driver 17 for SQL Server"

# Create SQLAlchemy engine
connection_string = (
    f"mssql+pyodbc://@{server}/{database}?driver={driver}&Trusted_Connection=yes"
)
engine = create_engine(connection_string)


def execute_query(query):
    """
    Execute a SQL query and return the result as a pandas DataFrame.

    Parameters:
    query (str): The SQL query to execute.

    Returns:
    pd.DataFrame: The result of the query.
    """
    with engine.connect() as connection:
        result = pd.read_sql(query, connection)
    return result


## otra forma de hacerlo: df = pd.read_sql(query, engine)
# Read data into DataFrame V_F4311
# this one is to large
# V_F4311 = execute_query('SELECT * FROM RDL00001_EnterpriseDataLanding.[JDE_BI_OPS].[V_F4311]')


# Cataloge_BI_OPS.head()


# Display the first few rows
# Cataloge_BI_OPS.head()
