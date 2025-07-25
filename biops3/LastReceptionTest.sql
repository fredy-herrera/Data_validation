drop table if exists ##OrderedLines;
SELECT
    ItemKey,
    ItemBranchkey,
    OrderNumber,
    LineNumber,
    OriginalAmount,
    QuantityOrder,
    QuantityReceived,
    QtyOpenQtyReceived,
    QuantityOpen,
    AmountOpen,
    PromiseDate,
    GLDate,
    ReceptionDate,
    ROW_NUMBER() OVER (
            PARTITION BY OrderNumber, ItemBranchkey, ItemKey, LineNumber
            ORDER BY OrderNumber, ItemBranchkey, ItemKey, LineNumber,ReceptionDate desc
        ) AS LastReception

        , CASE 
             WHEN ROW_NUMBER() OVER (
        PARTITION BY OrderNumber, ItemBranchkey, ItemKey, LineNumber
        ORDER BY ReceptionDate DESC
             ) = 1 
             THEN OriginalAmount 
             ELSE NULL 
            END AS LastReception_QuantityOrder
into ##OrderedLines
FROM [RDL00001_EnterpriseDataWarehouse].[dbo].[F_PurchaseOrderLine]
--    WHERE [OrderNumber] in
--                            (1200082,24118074)


--------------------------
SELECT *
FROM ##OrderedLines
WHERE   AmountOpen > 0
go
----------------------
  SELECT *
FROM ##OrderedLines
WHERE      [OrderNumber] --=138418
                    in(1200082,24118074)
GO
------------------------------


select *
from [RDL00001_EnterpriseDataLanding].JDE_BI_OPS.[V_F4301]
where [PHDOCO_DocumentOrderInvoiceE] in
                            (1200082,24118074)


SELECT sum(QuantityOrder) as TotalQuantityOrder,
    sum(OriginalAmount) as TotalOriginalAmount,
    sum(QuantityOpen) as TotalQuantityOpen,
    sum(AmountOpen) as TotalAmountOpen
FROM ##OrderedLines
WHERE rn = 1