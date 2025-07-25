SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


-- =============================================
-- Author:		<Author,,BART>
-- Create date: <Create Date,2025-07-03,>
-- Description:	EXEC [dbo].[Load_F_Purchase] 
-- =============================================

CREATE PROCEDURE [dbo].[Load_F_PurchaseOrderLine]
AS
BEGIN
    SET NOCOUNT ON;
    --*******************************************************************************************************************************
    --                                                        DECLARING VARIABLES
    --*******************************************************************************************************************************  
    DECLARE @IdentityAuditId  decimal(18, 0)
          , @RowCountAffected decimal(18, 0)
          , @Database         varchar(22)
          , @BeginDate        datetime
    SET @Database = 'RDL00001_EnterpriseDataStaging'

    -- To have the first financial date of the year 5 years ago
    SELECT @BeginDate = MIN([Date])
    FROM [RDL00001_EnterpriseDataStaging].[Shared].[DimDate]
    WHERE [FiscalYear] =
    (
        SELECT [FiscalYear]
    FROM [RDL00001_EnterpriseDataStaging].[Shared].[DimDate]
    WHERE [Date] = CONVERT(DATE, DATEADD(YEAR, -5, CURRENT_TIMESTAMP))
    );

    /***********************************************************************************************
								REQUETE PRINCIPALE (DELETE)
										DEBUT
************************************************************************************************/

    -- Insert empty ROW into the AUDIT Table for deleted records
    EXEC @IdentityAuditId = RDL00001_EnterpriseDataLanding.dbo.SYS_AUDIT_TRANSACTION 0
                                                                                   , @Database
                                                                                   , 'F_PurchaseOrderLine'
                                                                                   , 'D'
                                                                                   , 'F'
                                                                                   , 0
                                                                                   , 0
                                                                                   , 0
                                                                                   , 'N'
    Truncate table dbo.F_PurchaseOrderLine

    -- SET THE VARIABLE WITH THE ROW COUNT OF THE DELETE
    SElECT @RowCountAffected = @@ROWCOUNT

    -- UPDATE THE AUDIT TABLE WITH THE ROWCOUNTAFFECTED
    EXEC @IdentityAuditId = RDL00001_EnterpriseDataLanding.dbo.SYS_AUDIT_TRANSACTION @IdentityAuditId
                                                                                   , @Database
                                                                                   , 'F_PurchaseOrderLine'
                                                                                   , 'D'
                                                                                   , 'S'
                                                                                   , @RowCountAffected
                                                                                   , 0
                                                                                   , 0
                                                                                   , 'Y'
    -- UPDATE THE AUDIT TABLE WITH THE ROWCOUNTAFFECTED

    /***********************************************************************************************
								REQUETE PRINCIPALE (DELETE)
										FIN
************************************************************************************************/

    /***********************************************************************************************
								REQUETE PRINCIPALE (INSERT)
										DEBUT
************************************************************************************************/

    -- Insert empty ROW into the AUDIT Table for inserted records
    EXEC @IdentityAuditId = RDL00001_EnterpriseDataLanding.dbo.SYS_AUDIT_TRANSACTION 0
                                                                                   , @Database
                                                                                   , 'F_PurchaseOrderLine'
                                                                                   , 'I'
                                                                                   , 'F'
                                                                                   , 0
                                                                                   , 0
                                                                                   , 0
                                                                                   , 'N'
    INSERT INTO [dbo].[F_PurchaseOrderLine]
        (
        [AccountNumber]
        , [AmountOpen]
        , [Branch]
        , [BuyerNumber]
        , [CarrierCode]
        , [CatalogName]
        , [CompanyCode]
        , [CostCenter]
        , [DescriptionLine1]
        , [DescriptionLine2]
        , [ExchangeRate]
        , [ForeignAmount]
        , [ItemNumber]
        , [LastStatusCode]
        , [LineNumber]
        , [LineTypeCode]
        , [NextStatusCode]
        , [OrderNumber]
        , [OrderType]
        , [OriginalAmount]
        , [CancelDate]
        , [GLDate]
        , [OrderDate]
        , [OriginalPromisDate]
        , [PromiseDate]
        , [ReceptionDate]
        , [RequestedDate]
        , [ProjectNumber]
        , [PurchaseOrderCode01]
        , [QtyOpenQtyReceived]
        , [QuantityOpen]
        , [QuantityOrder]
        , [QuantityReceived]
        , [RelatedCO]
        , [RelatedLine]
        , [RelatedNumber]
        , [RelatedOrderType]
        , [Subledger]
        , [SubledgerType]
        , [SupplierNumber]
        , [TransactionOriginator]
        , [UnitCostPurchasing]
        , [UnitPrice]
        , [UOM]
        , [OrderCO]
        , [Currency]
        , [Shipto]
        )
    select F4311.PDANI_AcctNoInputMode         as AccountNumber
         , F4311.PDAOPN_AmountOpen1            as AmountOpen
         , F4311.PDMCU_CostCenter              as Branch
         , F4311.PDANBY_BuyerNumber            as BuyerNumber
         , F4311.[PDURAB_UserReservedNumber]   as CarrierCode
         , F4311.PDCATN_CatalogName            as CatalogName
         , F4311.[PDCO_Company]                as CompanyCode
         , F4311.PDOMCU_PurchasingCostCenter   as CostCenter
         , F4311.PDDSC1_DescriptionLine1       as DescriptionLine1
         , F4311.PDDSC2_DescriptionLine2       as DescriptionLine2
         , F4311.PDCRR_CurrencyConverRateOv    as ExchangeRate
         , F4311.PDFEA_AmountForeignExtPrice   as ForeignAmount                                                             
         , F4311.PDITM_IdentifierShortItem     as ItemNumber
         , F4311.PDLTTR_StatusCodeLast         as LastStatusCode
         , F4311.PDLNID_LineNumber             as LineNumber
         , F4311.PDLNTY_LineType               as LineTypeCode
         , F4311.PDNXTR_StatusCodeNext         as NextStatusCode
         , F4311.PDDOCO_DocumentOrderInvoiceE  as OrderNumber
         , F4311.PDDCTO_OrderType              as OrderType
         , F4311.PDAEXP_AmountExtendedPrice    as OriginalAmount
         , F4311.PDCNDJ_CancelDate             as CancelDate
         , F4311.PDDGL_DtForGLAndVouch1        as GLDate
         , F4311.PDTRDJ_DateTransactionJulian  as OrderDate
         , F4311.PDOPDJ_DateOriginalPromisde   as OriginalPromisDate
         , F4311.PDPDDJ_ScheduledPickDate      as PromiseDate
         , CARDEX.ILTRDJ_DateTransactionJulian as ReceptionDate
         , F4311.PDDRQJ_DateRequestedJulian    as RequestedDate
         , F4311.PDPRJM_ProjectNumber          as ProjectNumber
         , F4301.PHPOHC01_PurchaseOrderCode01  as PurchaseOrderCode01
         , PDUORG_UnitsTransactionQty          as QtyOpenQtyReceived
         , F4311.PDUOPN_UnitsOpenQuantity      as QuantityOpen
         , F4311.PDPQOR_UnitsPrimaryQtyOrder   as QuantityOrder
         , CARDEX.ILTRQT_QuantityTransaction   as QuantityReceived
         , F4311.PDRKCO_CompanyKeyRelated      as RelatedCO
         , F4311.PDRLLN_RelatedPoSoLineNo      as RelatedLine
         , F4311.PDRORN_RelatedPoSoNumber      as RelatedNumber
         , F4311.PDRCTO_RelatedOrderType       as RelatedOrderType
         , F4311.PDSBL_Subledger               as Subledger
         , F4311.PDSBLT_SubledgerType          as SubledgerType
         , F4311.PDAN8_AddressNumber           as SupplierNumber
         , F4311.PDTORG_TransactionOriginator  as TransactionOriginator
         , F4311.PDAMC3_UnitCostPurchasing     as UnitCostPurchasing
         , F4311.PDPRRC_PurchasingUnitPrice    as UnitPrice
         , F4311.PDUOM_UnitOfMeasureAsInput    as UOM
         , F4311.PDKCOO_CompanyKeyOrderNo      as OrderCO
         , F4311.PDCRCD_CurrencyCodeFrom       as Currency
         , F4311.[PDSHAN_AddressNumberShipTo]  as Shipto
    from [RDL00001_EnterpriseDataLanding].[JDE_BI_OPS].[V_F4311]                F4311
        LEFT OUTER JOIN [RDL00001_EnterpriseDataLanding].[JDE_BI_OPS].[V_F4301] F4301
        ON F4311.PDDOCO_DocumentOrderInvoiceE = F4301.PHDOCO_DocumentOrderInvoiceE
            AND F4311.PDKCOO_CompanyKeyOrderNo = F4301.PHKCOO_CompanyKeyOrderNo
            AND F4311.PDDCTO_OrderType = F4301.PHDCTO_OrderType
        LEFT OUTER JOIN [RDL00001_EnterpriseDataLanding].[JDE_BI_OPS].[V_F4111] CARDEX
        ON F4311.PDDOCO_DocumentOrderInvoiceE = CARDEX.ILDOCO_DocumentOrderInvoiceE
            AND F4311.PDDCTO_OrderType = CARDEX.ILDCTO_OrderType
            AND F4311.PDKCOO_CompanyKeyOrderNo = CARDEX.ILKCOO_CompanyKeyOrderNo
            AND F4311.PDLNID_LineNumber = CARDEX.ILLNID_LineNumber
            AND F4311.PDAN8_AddressNumber = CARDEX.ILAN8_AddressNumber
    WHERE     F4311.PDKCOO_CompanyKeyOrderNo IN ( '00001', '00077', '09011', '09052', '09041', '000024' )
        AND TRIM(F4311.PDLNTY_LineType) in ( 'S', 'J', 'N', 'F', 'XX', 'ZZ', 'ND', 'SC', 'D' )
        AND TRIM(F4311.PDDCTO_OrderType) in ( 'OP', 'ON' )
        AND TRIM(F4311.PDTORG_TransactionOriginator) not in ( 'NEXONIAUPD' )
        AND F4311.PDTRDJ_DateTransactionJulian >= @BeginDate;

    -- SET THE VARIABLE WITH THE ROW COUNT OF THE DELETE
    SElECT @RowCountAffected = @@ROWCOUNT

    -- UPDATE THE AUDIT TABLE WITH THE ROWCOUNTAFFECTED
    EXEC RDL00001_EnterpriseDataLanding.dbo.SYS_AUDIT_TRANSACTION @IdentityAuditId
                                                                , @Database
                                                                , 'F_PurchaseOrderLine'
                                                                , 'I'
                                                                , 'S'
                                                                , @RowCountAffected
                                                                , 0
                                                                , 0
                                                                , 'Y'

/***********************************************************************************************
								REQUETE PRINCIPALE (INSERT)
										FIN
************************************************************************************************/
END
GO
