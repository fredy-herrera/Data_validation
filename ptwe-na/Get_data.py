import pandas as pd
from sqlalchemy import create_engine, text
from utils.connpd import execute_query
from utils.executeProc import execute_proc

###########
##EXECUTION OF A STORED PROCEDURE###################
#####################################################
# Define the list of codes
product_codes = [
    "778952",
    "778957",
    "778960",
    "778963",
    "778965",
    "778966",
    "778967",
    "780184",
    "780186",
    "780188",
    "780189",
]
# Define the stored procedure call
query = text("""
    SET NOCOUNT ON;
    EXEC [dbo].[uspRptOrder] 
        @CalendarType = :CalendarType,
        @AsOfDate = :AsOfDate,
        @State = :State,
        @User = :User
""")

# Define the parameters
params = {
    "CalendarType": "FISCAL ADJUSTED",
    "AsOfDate": "2025-06-22",
    "State": "ON,QC",
    "User": "TECHNT\\HERF2",
}
# Execute the stored procedure and load the result into a DataFrame
dailyOrdersDataset = execute_proc(query, params)

###########################END EXEUITON#############
##############################
####dailyOrdersModified uspRptOrder_test

query = text("""
    SET NOCOUNT ON;
    EXEC [dbo].[uspRptOrder_test] 
        @CalendarType = :CalendarType,
        @AsOfDate = :AsOfDate,
        @State = :State,
        @User = :User
""")

# Define the parameters
params = {
    "CalendarType": "FISCAL ADJUSTED",
    "AsOfDate": "2025-06-22",
    "State": "ON,QC",
    "User": "TECHNT\\HERF2",
}
# Execute the stored procedure and load the result into a DataFrame
dailyOrdersModified = execute_proc(query, params)
filtered_dailyOrdersModified = dailyOrdersModified[
    dailyOrdersModified["PRODUCT_INTERNAL_CODE"].astype(str).isin(product_codes)
]


# Read the Excel file into a DataFrame
data = dailyOrdersDataset

# Preview the first few rows
dailyOrdersDataset.head()


# Filter the DataFrame
filtered_data = dailyOrdersDataset[
    dailyOrdersDataset["PRODUCT_INTERNAL_CODE"].astype(str).isin(product_codes)
]

filtered_data = dailyOrdersDataset[dailyOrdersDataset["PRODUCT_FAMILY3_CODE"] == "E15"]

# View the filtered result
filtered_data.head()


########  # #orders table
with open("queries\\orders.sql", "r") as file:
    ordersquery = file.read()
orders = execute_query(ordersquery)
