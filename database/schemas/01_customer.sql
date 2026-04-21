-- =============================================================================
-- Schema: customer
-- Application: NovoCard
-- Description: Holds all customer identity and contact information.
--              Customers can own multiple cards across product types.
-- =============================================================================

CREATE SCHEMA IF NOT EXISTS customer;

COMMENT ON SCHEMA customer IS
    'Customer identity, contact, and address data for NovoCard cardholders.';
