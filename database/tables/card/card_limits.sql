-- =============================================================================
-- Table: card.card_limits
-- Application: NovoCard
-- Description: Per-card spending and withdrawal velocity controls. Each card
--              has one active limit profile. Limits can be overridden by
--              customers within their eligibility ceiling, or by risk analysts
--              as part of a fraud response.
-- =============================================================================

CREATE TABLE IF NOT EXISTS card.card_limits (
    limit_id                    UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    card_id                     UUID            NOT NULL UNIQUE
                                    REFERENCES card.cards (card_id) ON DELETE CASCADE,

    -- Purchase limits
    daily_purchase_limit        NUMERIC(12, 2)  NOT NULL DEFAULT 5000.00,
    monthly_purchase_limit      NUMERIC(12, 2)  NOT NULL DEFAULT 30000.00,

    -- ATM / cash withdrawal limits
    daily_withdrawal_limit      NUMERIC(12, 2)  NOT NULL DEFAULT 1500.00,
    monthly_withdrawal_limit    NUMERIC(12, 2)  NOT NULL DEFAULT 5000.00,

    -- Channel-specific limits
    online_transaction_limit    NUMERIC(12, 2)  NOT NULL DEFAULT 3000.00,
    contactless_limit           NUMERIC(10, 2)  NOT NULL DEFAULT 300.00,
    international_daily_limit   NUMERIC(12, 2)  NOT NULL DEFAULT 2000.00,

    -- Single-transaction ceiling
    single_transaction_limit    NUMERIC(12, 2)  NOT NULL DEFAULT 5000.00,

    -- Control flags
    set_by                      VARCHAR(20)     NOT NULL DEFAULT 'SYSTEM'
                                    CHECK (set_by IN ('SYSTEM', 'CUSTOMER', 'RISK_ANALYST')),
    is_temporary                BOOLEAN         NOT NULL DEFAULT FALSE,
    temporary_until             TIMESTAMPTZ,
    reason                      VARCHAR(255),

    created_at                  TIMESTAMPTZ     NOT NULL DEFAULT now(),
    updated_at                  TIMESTAMPTZ     NOT NULL DEFAULT now(),

    CONSTRAINT chk_daily_lte_monthly_purchase
        CHECK (daily_purchase_limit <= monthly_purchase_limit),
    CONSTRAINT chk_daily_lte_monthly_withdrawal
        CHECK (daily_withdrawal_limit <= monthly_withdrawal_limit),
    CONSTRAINT chk_single_lte_daily
        CHECK (single_transaction_limit <= daily_purchase_limit)
);

CREATE INDEX idx_card_limits_card_id ON card.card_limits (card_id);

COMMENT ON TABLE card.card_limits IS
    'Spending velocity controls for each NovoCard card across purchase, withdrawal, and channel dimensions.';
COMMENT ON COLUMN card.card_limits.set_by IS
    'SYSTEM: default profile on issuance. CUSTOMER: self-service adjustment. RISK_ANALYST: compliance override.';
COMMENT ON COLUMN card.card_limits.is_temporary IS
    'When TRUE the limits revert to previous values after temporary_until timestamp.';
COMMENT ON COLUMN card.card_limits.contactless_limit IS
    'Per-tap ceiling for NFC/contactless transactions without PIN entry.';
