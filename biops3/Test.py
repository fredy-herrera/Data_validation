import pandas as pd
from utils import olap, connpd, connpp


# FILTER BY ORDER NUMBER
OrderNumber = {137290}

dax_purchase = f"""
EVALUATE SELECTCOLUMNS(
FILTER(
    'Purchase Order Line',
    'Purchase Order Line'[OrderNumber] IN  {OrderNumber}
),
    "OrderDate", 'Purchase Order Line'[OrderDate],
    "OrderNumber", 'Purchase Order Line'[OrderNumber],
    "Branch", 'Purchase Order Line'[Branch],
    "DescriptionLine1", 'Purchase Order Line'[DescriptionLine1],
    "GLDate", 'Purchase Order Line'[GLDate],
    "ItemKey", 'Purchase Order Line'[ItemKey],
    "LineNumber", 'Purchase Order Line'[LineNumber],
    
    "OriginalAmount", 'Purchase Order Line'[OriginalAmount],
    "OriginalPromisDate", 'Purchase Order Line'[OriginalPromisDate],
    "QuantityOpen", 'Purchase Order Line'[QuantityOpen],
    "QuantityReceived", 'Purchase Order Line'[QuantityReceived],
    "QuantityOrder", 'Purchase Order Line'[QuantityOrder],
    "RequestedDate", 'Purchase Order Line'[RequestedDate],
    "PromiseDate", 'Purchase Order Line'[PromiseDate],
    "ReceptionDate", 'Purchase Order Line'[ReceptionDate],
    "TransactionOriginator", 'Purchase Order Line'[TransactionOriginator],
    "CancelDate", 'Purchase Order Line'[CancelDate],
    "TotalOpenAmount", [TotalOpenAmount],
    "TotalQtyReceived", [TotalQtyReceived]
)
"""

purchase = olap.execute_dax_query(dax_purchase)

tablaFPurchase = """
EVALUATE
SELECTCOLUMNS(
    'Purchase Order Line',
    "Branch", 'Purchase Order Line'[Branch],
    "DescriptionLine1", 'Purchase Order Line'[DescriptionLine1],
    "GLDate", 'Purchase Order Line'[GLDate],
    "ItemKey", 'Purchase Order Line'[ItemKey],
    "LineNumber", 'Purchase Order Line'[LineNumber],
    "OrderDate", 'Purchase Order Line'[OrderDate],
    "OrderNumber", 'Purchase Order Line'[OrderNumber],
    "OriginalAmount", 'Purchase Order Line'[OriginalAmount],
    "OriginalPromisDate", 'Purchase Order Line'[OriginalPromisDate],
    "QuantityOpen", 'Purchase Order Line'[QuantityOpen],
    "QuantityReceived", 'Purchase Order Line'[QuantityReceived],
    "QuantityOrder", 'Purchase Order Line'[QuantityOrder],
    "RequestedDate", 'Purchase Order Line'[RequestedDate],
    "PromiseDate", 'Purchase Order Line'[PromiseDate],
    "ReceptionDate", 'Purchase Order Line'[ReceptionDate],
      "TotalOpenAmount", [TotalOpenAmount],
    "TotalQtyReceived", [TotalQtyReceived]
)

"""
 
##ORDERS A TESTER
poTesting=25850655,25652178

####DW EN pp F_PurchaseOrderLine

f_purchase = connpp.execute_queryPP(f"""
Select * from F_PurchaseOrderLine where
OrderNumber IN {poTesting}""")

#Datalake PO
df_V_F4311 = connpp.execute_queryPP(f"""
select * from RDL00001_EnterpriseDataLanding.JDE_BI_OPS.V_F4311 where
PDDOCO_DocumentOrderInvoiceE IN {poTesting}
""")
                                    

items = connpp.execute_queryPP("D_ItemMaster")
items = connpp.execute_queryPP("D_ItemMaster")


Orders=25850655,25652178
filtro = f_purchase[f_purchase['OrderNumber'].isin(Orders)]

Orders=25850655,25652178
filtro = f_purchase[f_purchase['OrderNumber'].isin(Orders)]
filtered_biopsPO=df_V_F4311[df_V_F4311['OrderNumber'].isin(Orders)]


# %%
