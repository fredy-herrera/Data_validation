SELECT

  PO.TransactionOriginator, d.FiscalYearName
,
  count( *) as TotalLignes,
  COUNT(DISTINCT PO.OrderNumber) AS TotalPO
FROM [RDL00001_EnterpriseDataWarehouse].[dbo].[F_PurchaseOrderLine] PO
  left join [RDL00001_EnterpriseDataWarehouse].[Shared].[DimDate] d on PO.OrderDate=d.id

WHERE
    PO.TransactionOriginator IN ('DUME', 'LAFR', 'LARA', 'LAVP2', 'LECB', 'TREM6', 'ALBD', 'LEDP', 'CARN8', 'CARI3')

GROUP BY
   PO.TransactionOriginator,

   
     d.FiscalYearName

ORDER BY
PO.TransactionOriginator,
      d.FiscalYearName
   