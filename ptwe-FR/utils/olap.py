import pandas as pd
from sys import path


path.append("C:\\Program Files\\Microsoft.NET\\ADOMD.NET\\150\\")
from pyadomd import Pyadomd

def execute_dax_query(dataSource='cube01Procurementv2PP.premiertech.com',
    modelName = "RDL00001_Procurement_v2", query_string=""):
    # ==================================ENDquery_string):
    """
    Connects to an SSAS cube and executes the given DAX query,
    returning results as a Pandas DataFrame.

    Parameters:

        query_string (str): The DAX query to execute.

    Returns:
        pd.DataFrame: Query results as a DataFrame.
    """
   
    # Chaîne de connexion OLEDB via le pilote SSAS:
    conn_str = (
        "Provider=MSOLAP;"
        f"Data Source={dataSource};"
        f"Catalog={modelName};"
        "Integrated Security=SSPI"
    )

    # EXECUTE CONNECTION:
    with Pyadomd(conn_str) as conn:
        cursor = conn.cursor()
        cursor.execute(query_string)
        columns = [column[0] for column in cursor.description]
        data = cursor.fetchall()
        df = pd.DataFrame(data, columns=columns)

    return df
