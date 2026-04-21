-- =============================================================================
-- Trigger: trg_transaction_limit_check
-- Application: NovoCard
-- Table: card.transactions
-- Description: BEFORE INSERT trigger that performs a last-mile sanity check
--              on incoming transaction records. It verifies the card is active,
--              the amount is positive, and that the single-transaction limit
--              has not been exceeded. Acts as a database-level safety net
--              independent of the application-layer checks in sp_process_transaction.
-- =============================================================================

CREATE OR REPLACE FUNCTION card.fn_check_transaction_limits()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_card_status       VARCHAR(30);
    v_single_limit      NUMERIC(12, 2);
BEGIN
    -- Sanity: amount must be positive
    IF NEW.amount <= 0 AND NEW.transaction_type NOT IN ('REVERSAL', 'REFUND') THEN
        RAISE EXCEPTION 'Transaction amount must be positive for type %. Got: %',
            NEW.transaction_type, NEW.amount;
    END IF;

    -- Skip limit checks for non-debit types
    IF NEW.transaction_type NOT IN ('PURCHASE', 'CASH_WITHDRAWAL', 'CASH_ADVANCE') THEN
        RETURN NEW;
    END IF;

    -- Skip limit check for already-declined transactions
    IF NEW.status = 'DECLINED' THEN
        RETURN NEW;
    END IF;

    -- Fetch card status
    SELECT status
    INTO   v_card_status
    FROM   card.cards
    WHERE  card_id = NEW.card_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Transaction references unknown card_id %', NEW.card_id;
    END IF;

    IF v_card_status <> 'ACTIVE' THEN
        RAISE EXCEPTION 'Cannot post transaction to card % with status %',
            NEW.card_id, v_card_status;
    END IF;

    -- Single-transaction ceiling check
    SELECT single_transaction_limit
    INTO   v_single_limit
    FROM   card.card_limits
    WHERE  card_id = NEW.card_id;

    IF FOUND AND NEW.amount > v_single_limit THEN
        RAISE EXCEPTION
            'Transaction amount % exceeds single-transaction limit % for card %',
            NEW.amount, v_single_limit, NEW.card_id;
    END IF;

    RETURN NEW;
END;
$$;

CREATE OR REPLACE TRIGGER trg_transaction_limit_check
BEFORE INSERT
ON card.transactions
FOR EACH ROW
EXECUTE FUNCTION card.fn_check_transaction_limits();

COMMENT ON FUNCTION card.fn_check_transaction_limits IS
    'BEFORE INSERT guard on card.transactions: validates card state and single-transaction limit as a database-layer safety net.';
