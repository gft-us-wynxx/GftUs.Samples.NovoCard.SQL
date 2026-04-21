-- =============================================================================
-- Table: card.transactions
-- Application: NovoCard
-- Description: Financial transaction records for all card activity including
--              purchases, refunds, cash withdrawals, and balance loads
--              (for prepaid cards). Each row represents a single authorization
--              or posting event. Authorizations move to POSTED after clearing.
-- =============================================================================

CREATE TABLE IF NOT EXISTS card.transactions (
    transaction_id          UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    card_id                 UUID            NOT NULL
                                REFERENCES card.cards (card_id),
    account_id              UUID            NOT NULL
                                REFERENCES card.card_accounts (account_id),

    -- Transaction identification
    authorization_code      VARCHAR(20),
    external_reference      VARCHAR(100),
    transaction_type        VARCHAR(30)     NOT NULL
                                CHECK (transaction_type IN (
                                    'PURCHASE', 'REFUND', 'CASH_WITHDRAWAL',
                                    'BALANCE_LOAD', 'FEE', 'REVERSAL',
                                    'CHARGEBACK', 'INTEREST', 'CASH_ADVANCE'
                                )),

    -- Amounts
    amount                  NUMERIC(15, 2)  NOT NULL,
    original_amount         NUMERIC(15, 2),
    original_currency       CHAR(3),
    billing_currency        CHAR(3)         NOT NULL DEFAULT 'BRL',
    exchange_rate           NUMERIC(12, 6),

    -- Merchant information
    merchant_name           VARCHAR(255),
    merchant_id             VARCHAR(50),
    merchant_category_code  CHAR(4),
    merchant_city           VARCHAR(100),
    merchant_country        CHAR(2),

    -- Transaction state
    status                  VARCHAR(20)     NOT NULL DEFAULT 'AUTHORIZED'
                                CHECK (status IN (
                                    'AUTHORIZED', 'POSTED', 'REVERSED',
                                    'DECLINED', 'CANCELLED', 'DISPUTED'
                                )),
    decline_reason          VARCHAR(100),
    is_online               BOOLEAN         NOT NULL DEFAULT FALSE,
    is_international        BOOLEAN         NOT NULL DEFAULT FALSE,
    is_contactless          BOOLEAN         NOT NULL DEFAULT FALSE,
    installments            SMALLINT        NOT NULL DEFAULT 1
                                CHECK (installments BETWEEN 1 AND 24),

    authorized_at           TIMESTAMPTZ     NOT NULL DEFAULT now(),
    posted_at               TIMESTAMPTZ,
    reversed_at             TIMESTAMPTZ,
    created_at              TIMESTAMPTZ     NOT NULL DEFAULT now()
);

CREATE INDEX idx_transactions_card_id          ON card.transactions (card_id);
CREATE INDEX idx_transactions_account_id       ON card.transactions (account_id);
CREATE INDEX idx_transactions_status           ON card.transactions (status);
CREATE INDEX idx_transactions_authorized_at    ON card.transactions (authorized_at DESC);
CREATE INDEX idx_transactions_merchant_code    ON card.transactions (merchant_category_code);
CREATE INDEX idx_transactions_type             ON card.transactions (transaction_type);

COMMENT ON TABLE card.transactions IS
    'All financial events (authorizations and postings) for NovoCard issued cards.';
COMMENT ON COLUMN card.transactions.merchant_category_code IS
    'ISO 18245 Merchant Category Code (MCC) used for spending analytics and limit rules.';
COMMENT ON COLUMN card.transactions.original_amount IS
    'Transaction amount in the merchant currency before FX conversion. NULL for domestic.';
COMMENT ON COLUMN card.transactions.installments IS
    'Number of installments for Brazilian parcelamento (1 = no installments).';
COMMENT ON COLUMN card.transactions.status IS
    'AUTHORIZED: hold placed. POSTED: cleared and settled. REVERSED: full reversal before posting.';
