-- =============================================================================
-- Schema: design
-- Application: NovoCard
-- Description: Card customization and branding schema. Stores design templates,
--              customer-assigned designs, and the digital assets that compose them.
--              Enables the personalization experience for credit, debit, and
--              prepaid cards.
-- =============================================================================

CREATE SCHEMA IF NOT EXISTS design;

COMMENT ON SCHEMA design IS
    'Card design templates, customer card personalization, and visual asset registry for NovoCard.';
