-- =============================================================================
-- Table: card.card_accounts
-- Application: NovoCard
-- Description: Financial account state for each card. For CREDIT cards this
--              tracks credit limit and utilized amount. For PREPAID it tracks
--              loaded balance. For DEBIT the balance reflects the linked
--              checking account snapshot (updated asynchronously).
-- =============================================================================

CREATE TABLE IF NOT EXISTS card.card_accounts (
    account_id          UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    card_id             UUID            NOT NULL UNIQUE
                            REFERENCES card.cards (card_id) ON DELETE CASCADE,
    currency            CHAR(3)         NOT NULL DEFAULT 'BRL',
    balance             NUMERIC(15, 2)  NOT NULL DEFAULT 0.00,
    credit_limit        NUMERIC(15, 2)  NOT NULL DEFAULT 0.00,
    available_balance   NUMERIC(15, 2)  NOT NULL DEFAULT 0.00,
    pending_amount      NUMERIC(15, 2)  NOT NULL DEFAULT 0.00,
    statement_balance   NUMERIC(15, 2)  NOT NULL DEFAULT 0.00,
    minimum_payment     NUMERIC(15, 2)  NOT NULL DEFAULT 0.00,
    due_date            DATE,
    last_statement_date DATE,
    last_payment_date   TIMESTAMPTZ,
    last_payment_amount NUMERIC(15, 2),
    updated_at          TIMESTAMPTZ     NOT NULL DEFAULT now(),

    CONSTRAINT chk_credit_limit_non_negative   CHECK (credit_limit >= 0),
    CONSTRAINT chk_available_balance_range     CHECK (available_balance <= credit_limit),
    CONSTRAINT chk_pending_non_negative        CHECK (pending_amount >= 0)
);

CREATE INDEX idx_card_accounts_card_id    ON card.card_accounts (card_id);
CREATE INDEX idx_card_accounts_due_date   ON card.card_accounts (due_date);

COMMENT ON TABLE card.card_accounts IS
    'Financial account state per card: balances, credit limits, and billing cycle data.';
COMMENT ON COLUMN card.card_accounts.available_balance IS
    'Real-time spendable amount = credit_limit - utilized - pending_amount.';
COMMENT ON COLUMN card.card_accounts.pending_amount IS
    'Authorization holds not yet cleared as posted transactions.';
COMMENT ON COLUMN card.card_accounts.statement_balance IS
    'Balance captured at last statement close date. Basis for minimum payment calculation.';
