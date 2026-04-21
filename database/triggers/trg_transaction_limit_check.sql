-- =============================================================================
-- Trigger: trg_transaction_limit_check
-- Application: NovoCard
-- Table: card.transactions
-- Description: AFTER INSERT trigger that performs a last-mile sanity check
--              on incoming transaction records. It verifies the card is active,
--              the amount is positive, and that the single-transaction limit
--              has not been exceeded. Acts as a database-level safety net
--              independent of the application-layer checks in sp_process_transaction.
--
-- Notes:
--   THROW inside a trigger automatically rolls back the entire transaction.
--   This trigger fires AFTER INSERT (no INSTEAD OF) so that constraint violations
--   in the table itself are caught first.
-- =============================================================================

CREATE OR ALTER TRIGGER trg_transaction_limit_check
ON card.transactions
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    -- Amount must be positive for non-credit types
    IF EXISTS (
        SELECT 1
        FROM   INSERTED
        WHERE  amount <= 0
          AND  transaction_type NOT IN (N'REVERSAL', N'REFUND')
    )
        THROW 51000, 'Transaction amount must be positive for this transaction type.', 1;

    -- Skip further checks for non-debit types and already-declined rows
    -- Card must be ACTIVE for purchase / withdrawal authorizations
    IF EXISTS (
        SELECT 1
        FROM   INSERTED i
        INNER JOIN card.cards c ON c.card_id = i.card_id
        WHERE  i.transaction_type IN (N'PURCHASE', N'CASH_WITHDRAWAL', N'CASH_ADVANCE')
          AND  i.status <> N'DECLINED'
          AND  c.status <> N'ACTIVE'
    )
        THROW 51001, 'Cannot post transaction to an inactive card.', 1;

    -- Single-transaction ceiling check
    IF EXISTS (
        SELECT 1
        FROM   INSERTED i
        INNER JOIN card.card_limits cl ON cl.card_id = i.card_id
        WHERE  i.transaction_type IN (N'PURCHASE', N'CASH_WITHDRAWAL', N'CASH_ADVANCE')
          AND  i.status <> N'DECLINED'
          AND  i.amount > cl.single_transaction_limit
    )
        THROW 51002, 'Transaction amount exceeds single-transaction limit.', 1;
END;
GO
