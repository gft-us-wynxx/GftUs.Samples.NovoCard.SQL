-- =============================================================================
-- Table: card.card_accounts
-- Application: NovoCard
-- Description: Financial account state for each card. For CREDIT cards this
--              tracks credit limit and utilized amount. For PREPAID it tracks
--              loaded balance. For DEBIT the balance reflects the linked
--              checking account snapshot (updated asynchronously).
-- =============================================================================

IF OBJECT_ID('card.card_accounts', 'U') IS NULL
CREATE TABLE card.card_accounts (
    account_id          UNIQUEIDENTIFIER    NOT NULL CONSTRAINT pk_card_accounts PRIMARY KEY DEFAULT NEWID(),
    card_id             UNIQUEIDENTIFIER    NOT NULL CONSTRAINT uq_card_accounts_card UNIQUE
                            REFERENCES card.cards (card_id) ON DELETE CASCADE,
    currency            NCHAR(3)            NOT NULL DEFAULT N'USD',
    balance             DECIMAL(15, 2)      NOT NULL DEFAULT 0.00,
    credit_limit        DECIMAL(15, 2)      NOT NULL DEFAULT 0.00,
    -- Real-time spendable amount = credit_limit - utilized - pending_amount
    available_balance   DECIMAL(15, 2)      NOT NULL DEFAULT 0.00,
    -- Authorization holds not yet cleared as posted transactions
    pending_amount      DECIMAL(15, 2)      NOT NULL DEFAULT 0.00,
    -- Balance captured at last statement close date; basis for minimum payment calculation
    statement_balance   DECIMAL(15, 2)      NOT NULL DEFAULT 0.00,
    minimum_payment     DECIMAL(15, 2)      NOT NULL DEFAULT 0.00,
    due_date            DATE                NULL,
    last_statement_date DATE                NULL,
    last_payment_date   DATETIMEOFFSET      NULL,
    last_payment_amount DECIMAL(15, 2)      NULL,
    updated_at          DATETIMEOFFSET      NOT NULL DEFAULT SYSDATETIMEOFFSET(),

    CONSTRAINT chk_credit_limit_non_negative    CHECK (credit_limit >= 0),
    CONSTRAINT chk_available_balance_range      CHECK (available_balance <= credit_limit),
    CONSTRAINT chk_pending_non_negative         CHECK (pending_amount >= 0)
);
GO

CREATE INDEX idx_card_accounts_card_id  ON card.card_accounts (card_id);
CREATE INDEX idx_card_accounts_due_date ON card.card_accounts (due_date);
GO
