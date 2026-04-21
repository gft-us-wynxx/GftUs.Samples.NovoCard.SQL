-- =============================================================================
-- Table: card.card_types
-- Application: NovoCard
-- Description: Catalog of card product types offered by NovoCard.
--              Defines the combination of product class (CREDIT/DEBIT/PREPAID),
--              payment network, and tier that determines card behavior,
--              fees, and default limits.
-- =============================================================================

CREATE TABLE IF NOT EXISTS card.card_types (
    card_type_id        SERIAL          PRIMARY KEY,
    type_name           VARCHAR(50)     NOT NULL UNIQUE,
    product_class       VARCHAR(10)     NOT NULL CHECK (product_class IN ('CREDIT', 'DEBIT', 'PREPAID')),
    network             VARCHAR(20)     NOT NULL CHECK (network IN ('VISA', 'MASTERCARD', 'ELO', 'AMEX', 'HIPERCARD')),
    tier                VARCHAR(20)     NOT NULL DEFAULT 'STANDARD'
                            CHECK (tier IN ('STANDARD', 'GOLD', 'PLATINUM', 'BLACK', 'INFINITE')),
    annual_fee          NUMERIC(10, 2)  NOT NULL DEFAULT 0.00,
    minimum_income      NUMERIC(12, 2),
    minimum_credit_score SMALLINT       CHECK (minimum_credit_score BETWEEN 0 AND 1000),
    description         TEXT,
    benefits            JSONB,
    is_active           BOOLEAN         NOT NULL DEFAULT TRUE,
    created_at          TIMESTAMPTZ     NOT NULL DEFAULT now(),
    updated_at          TIMESTAMPTZ     NOT NULL DEFAULT now()
);

INSERT INTO card.card_types (type_name, product_class, network, tier, annual_fee, description) VALUES
    ('NOVOCARD_DEBIT_STANDARD',      'DEBIT',   'MASTERCARD', 'STANDARD', 0.00,   'Standard debit card linked to checking account'),
    ('NOVOCARD_CREDIT_STANDARD',     'CREDIT',  'VISA',       'STANDARD', 149.90, 'Entry-level credit card for new customers'),
    ('NOVOCARD_CREDIT_GOLD',         'CREDIT',  'MASTERCARD', 'GOLD',     299.90, 'Gold credit card with travel benefits'),
    ('NOVOCARD_CREDIT_PLATINUM',     'CREDIT',  'VISA',       'PLATINUM', 599.90, 'Platinum card with concierge and lounge access'),
    ('NOVOCARD_CREDIT_BLACK',        'CREDIT',  'MASTERCARD', 'BLACK',    0.00,   'Invite-only Black card with unlimited benefits'),
    ('NOVOCARD_PREPAID_GIFT',        'PREPAID', 'ELO',        'STANDARD', 0.00,   'Single-use prepaid gift card'),
    ('NOVOCARD_PREPAID_TRAVEL',      'PREPAID', 'VISA',       'STANDARD', 19.90,  'Reloadable multi-currency travel prepaid card'),
    ('NOVOCARD_PREPAID_CORPORATE',   'PREPAID', 'MASTERCARD', 'STANDARD', 0.00,   'Corporate expense prepaid card managed by employer');

COMMENT ON TABLE card.card_types IS
    'Product catalog defining the available card types, networks, tiers, and eligibility rules.';
COMMENT ON COLUMN card.card_types.benefits IS
    'JSON array of benefit strings (e.g. ["Airport lounge access", "2x points on travel"]).';
COMMENT ON COLUMN card.card_types.minimum_credit_score IS
    'Minimum internal credit score required for card issuance. NULL means no restriction.';
