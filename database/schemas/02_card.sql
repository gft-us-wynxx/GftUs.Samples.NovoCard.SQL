-- =============================================================================
-- Schema: card
-- Application: NovoCard
-- Description: Core card management schema. Contains card product types,
--              issued cards, accounts, spending limits, status lifecycle,
--              and transaction records.
-- =============================================================================

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = N'card')
    EXEC(N'CREATE SCHEMA card');
GO
