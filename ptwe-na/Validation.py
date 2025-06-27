import pandas as pd
from sqlalchemy import create_engine, text
from utils.connpd import execute_query
from utils.executeProc import execute_proc

###########
##EXECUTION OF A STORED PROCEDURE###################
#####################################################
###########################END EXEUITON#############
##############################

# Read the Excel file into a DataFrame
data = dailyOrdersDataset

# Preview the first few rows
data.head()

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

# Filter the DataFrame
itemsInOrders = data[data["PRODUCT_INTERNAL_CODE"].astype(str).isin(product_codes)]

# filtered_data = data[data["PRODUCT_FAMILY3_CODE"] == "E15"]

# View the filtered result
itemsInOrders.head()


########  # #orders table
orders.head()

orders_filtered = orders[orders["PRODUCT_ID"].astype(str).isin(product_codes)]   

itemsInOrders = data[data["FAMILY3_NAME"].astype(str).str.contains('Septic Tank', na=False)][[
    "PRODUCT_INTERNAL_CODE",
    
    "FAMILY2_CODE",
    "FAMILY2_NAME",
    "FAMILY2_SORT",
    "FAMILY3_NAME",
    "UNITS_IND",
    "DISPLAY_QTY_IND",
    "TRANSACTION_TYPE_ID"
]]
