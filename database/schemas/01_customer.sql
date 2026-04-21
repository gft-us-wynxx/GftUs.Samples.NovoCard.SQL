-- =============================================================================
-- Schema: customer
-- Application: NovoCard
-- Description: Holds all customer identity and contact information.
--              Customers can own multiple cards across product types.
-- =============================================================================

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = N'customer')
    EXEC(N'CREATE SCHEMA customer');
GO
