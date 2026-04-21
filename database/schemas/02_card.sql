-- =============================================================================
-- Schema: card
-- Application: NovoCard
-- Description: Core card management schema. Contains card product types,
--              issued cards, accounts, spending limits, status lifecycle,
--              and transaction records.
-- =============================================================================

CREATE SCHEMA IF NOT EXISTS card;

COMMENT ON SCHEMA card IS
    'Card issuance, account balances, spending limits, status history, and transactions for NovoCard.';
