-- =============================================================================
-- Schema: design
-- Application: NovoCard
-- Description: Card customization and branding schema. Stores design templates,
--              customer-assigned designs, and the digital assets that compose them.
--              Enables the personalization experience for credit, debit, and
--              prepaid cards.
-- =============================================================================

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = N'design')
    EXEC(N'CREATE SCHEMA design');
GO
