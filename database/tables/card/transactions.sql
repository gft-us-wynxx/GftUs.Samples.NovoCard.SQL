-- =============================================================================
-- Table: card.transactions
-- Application: NovoCard
-- Description: Financial transaction records for all card activity including
--              purchases, refunds, cash withdrawals, and balance loads
--              (for prepaid cards). Each row represents a single authorization
--              or posting event. Authorizations move to POSTED after clearing.
--
-- Notes:
--   ISO 18245 Merchant Category Code (MCC) used for spending analytics and limit rules.
--   original_amount is the transaction amount in the merchant currency before FX conversion (NULL for domestic).
--   installments: number of installments for a deferred payment plan (1 = single payment).
--   AUTHORIZED: hold placed. POSTED: cleared and settled. REVERSED: full reversal before posting.
-- =============================================================================

IF OBJECT_ID('card.transactions', 'U') IS NULL
CREATE TABLE card.transactions (
    transaction_id          UNIQUEIDENTIFIER    NOT NULL CONSTRAINT pk_transactions PRIMARY KEY DEFAULT NEWID(),
    card_id                 UNIQUEIDENTIFIER    NOT NULL
                                CONSTRAINT fk_transactions_card REFERENCES card.cards (card_id),
    account_id              UNIQUEIDENTIFIER    NOT NULL
                                CONSTRAINT fk_transactions_account REFERENCES card.card_accounts (account_id),

    -- Transaction identification
    authorization_code      NVARCHAR(20)        NULL,
    external_reference      NVARCHAR(100)       NULL,
    transaction_type        NVARCHAR(30)        NOT NULL
                                CONSTRAINT chk_txn_type CHECK (transaction_type IN (
                                    N'PURCHASE', N'REFUND', N'CASH_WITHDRAWAL',
                                    N'BALANCE_LOAD', N'FEE', N'REVERSAL',
                                    N'CHARGEBACK', N'INTEREST', N'CASH_ADVANCE'
                                )),

    -- Amounts
    amount                  DECIMAL(15, 2)      NOT NULL,
    original_amount         DECIMAL(15, 2)      NULL,
    original_currency       NCHAR(3)            NULL,
    billing_currency        NCHAR(3)            NOT NULL DEFAULT N'USD',
    exchange_rate           DECIMAL(12, 6)      NULL,

    -- Merchant information
    merchant_name           NVARCHAR(255)       NULL,
    merchant_id             NVARCHAR(50)        NULL,
    merchant_category_code  CHAR(4)             NULL,   -- ISO 18245 MCC
    merchant_city           NVARCHAR(100)       NULL,
    merchant_country        NCHAR(2)            NULL,

    -- Transaction state
    status                  NVARCHAR(20)        NOT NULL DEFAULT N'AUTHORIZED'
                                CONSTRAINT chk_txn_status CHECK (status IN (
                                    N'AUTHORIZED', N'POSTED', N'REVERSED',
                                    N'DECLINED', N'CANCELLED', N'DISPUTED'
                                )),
    decline_reason          NVARCHAR(100)       NULL,
    is_online               BIT                 NOT NULL DEFAULT 0,
    is_international        BIT                 NOT NULL DEFAULT 0,
    is_contactless          BIT                 NOT NULL DEFAULT 0,
    installments            SMALLINT            NOT NULL DEFAULT 1
                                CONSTRAINT chk_txn_installments CHECK (installments BETWEEN 1 AND 24),

    authorized_at           DATETIMEOFFSET      NOT NULL DEFAULT SYSDATETIMEOFFSET(),
    posted_at               DATETIMEOFFSET      NULL,
    reversed_at             DATETIMEOFFSET      NULL,
    created_at              DATETIMEOFFSET      NOT NULL DEFAULT SYSDATETIMEOFFSET()
);
GO

CREATE INDEX idx_transactions_card_id       ON card.transactions (card_id);
CREATE INDEX idx_transactions_account_id    ON card.transactions (account_id);
CREATE INDEX idx_transactions_status        ON card.transactions (status);
CREATE INDEX idx_transactions_authorized_at ON card.transactions (authorized_at DESC);
CREATE INDEX idx_transactions_merchant_code ON card.transactions (merchant_category_code);
CREATE INDEX idx_transactions_type          ON card.transactions (transaction_type);
GO
