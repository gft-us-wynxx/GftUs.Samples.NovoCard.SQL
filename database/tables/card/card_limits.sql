-- =============================================================================
-- Table: card.card_limits
-- Application: NovoCard
-- Description: Per-card spending and withdrawal velocity controls. Each card
--              has one active limit profile. Limits can be overridden by
--              customers within their eligibility ceiling, or by risk analysts
--              as part of a fraud response.
-- =============================================================================

IF OBJECT_ID('card.card_limits', 'U') IS NULL
CREATE TABLE card.card_limits (
    limit_id                    UNIQUEIDENTIFIER    NOT NULL CONSTRAINT pk_card_limits PRIMARY KEY DEFAULT NEWID(),
    card_id                     UNIQUEIDENTIFIER    NOT NULL CONSTRAINT uq_card_limits_card UNIQUE
                                    REFERENCES card.cards (card_id) ON DELETE CASCADE,

    -- Purchase limits
    daily_purchase_limit        DECIMAL(12, 2)      NOT NULL DEFAULT 5000.00,
    monthly_purchase_limit      DECIMAL(12, 2)      NOT NULL DEFAULT 30000.00,

    -- ATM / cash withdrawal limits
    daily_withdrawal_limit      DECIMAL(12, 2)      NOT NULL DEFAULT 1500.00,
    monthly_withdrawal_limit    DECIMAL(12, 2)      NOT NULL DEFAULT 5000.00,

    -- Channel-specific limits
    online_transaction_limit    DECIMAL(12, 2)      NOT NULL DEFAULT 3000.00,
    -- Per-tap ceiling for NFC/contactless transactions without PIN entry
    contactless_limit           DECIMAL(10, 2)      NOT NULL DEFAULT 300.00,
    international_daily_limit   DECIMAL(12, 2)      NOT NULL DEFAULT 2000.00,

    -- Single-transaction ceiling
    single_transaction_limit    DECIMAL(12, 2)      NOT NULL DEFAULT 5000.00,

    -- SYSTEM: default on issuance. CUSTOMER: self-service. RISK_ANALYST: compliance override
    set_by                      NVARCHAR(20)        NOT NULL DEFAULT N'SYSTEM'
                                    CONSTRAINT chk_limits_set_by CHECK (set_by IN (
                                        N'SYSTEM', N'CUSTOMER', N'RISK_ANALYST'
                                    )),
    -- When 1 the limits revert to previous values after temporary_until timestamp
    is_temporary                BIT                 NOT NULL DEFAULT 0,
    temporary_until             DATETIMEOFFSET      NULL,
    reason                      NVARCHAR(255)       NULL,

    created_at                  DATETIMEOFFSET      NOT NULL DEFAULT SYSDATETIMEOFFSET(),
    updated_at                  DATETIMEOFFSET      NOT NULL DEFAULT SYSDATETIMEOFFSET(),

    CONSTRAINT chk_daily_lte_monthly_purchase
        CHECK (daily_purchase_limit <= monthly_purchase_limit),
    CONSTRAINT chk_daily_lte_monthly_withdrawal
        CHECK (daily_withdrawal_limit <= monthly_withdrawal_limit),
    CONSTRAINT chk_single_lte_daily
        CHECK (single_transaction_limit <= daily_purchase_limit)
);
GO

CREATE INDEX idx_card_limits_card_id ON card.card_limits (card_id);
GO
