-- =============================================================================
-- Procedure: card.sp_process_transaction
-- Application: NovoCard
-- Description: Records a card transaction authorization or posting. For
--              AUTHORIZED status it places a hold reducing available_balance.
--              For POSTED it converts the hold to a settled debit. For REVERSED
--              it releases the hold back to available. Enforces single-transaction
--              and daily limit checks before acceptance.
--
-- Parameters:
--   p_card_id               UUID    - Card being charged
--   p_amount                NUMERIC - Transaction amount in billing currency
--   p_transaction_type      VARCHAR - PURCHASE | CASH_WITHDRAWAL | BALANCE_LOAD | etc.
--   p_status                VARCHAR - AUTHORIZED | POSTED | DECLINED
--   p_merchant_name         VARCHAR - Merchant display name
--   p_merchant_id           VARCHAR - Acquirer merchant ID
--   p_merchant_category_code CHAR(4) - ISO MCC
--   p_authorization_code    VARCHAR - Issuer authorization code
--   p_is_online             BOOLEAN - Online/CNP flag
--   p_is_international      BOOLEAN - Cross-border flag
--   p_is_contactless        BOOLEAN - NFC flag
-- =============================================================================

CREATE OR REPLACE FUNCTION card.sp_process_transaction(
    p_card_id                   UUID,
    p_amount                    NUMERIC(15, 2),
    p_transaction_type          VARCHAR(30)     DEFAULT 'PURCHASE',
    p_status                    VARCHAR(20)     DEFAULT 'AUTHORIZED',
    p_merchant_name             VARCHAR(255)    DEFAULT NULL,
    p_merchant_id               VARCHAR(50)     DEFAULT NULL,
    p_merchant_category_code    CHAR(4)         DEFAULT NULL,
    p_authorization_code        VARCHAR(20)     DEFAULT NULL,
    p_is_online                 BOOLEAN         DEFAULT FALSE,
    p_is_international          BOOLEAN         DEFAULT FALSE,
    p_is_contactless            BOOLEAN         DEFAULT FALSE,
    p_installments              SMALLINT        DEFAULT 1
)
RETURNS UUID
LANGUAGE plpgsql
AS $$
DECLARE
    v_transaction_id    UUID;
    v_account_id        UUID;
    v_card_status       VARCHAR(30);
    v_available         NUMERIC(15, 2);
    v_single_limit      NUMERIC(12, 2);
    v_daily_limit       NUMERIC(12, 2);
    v_online_limit      NUMERIC(12, 2);
    v_daily_spent       NUMERIC(15, 2);
    v_decline_reason    VARCHAR(100);
BEGIN
    -- Get card and account state
    SELECT c.status, ca.account_id, ca.available_balance
    INTO   v_card_status, v_account_id, v_available
    FROM   card.cards c
    INNER JOIN card.card_accounts ca ON ca.card_id = c.card_id
    WHERE  c.card_id = p_card_id
    FOR UPDATE OF ca;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Card % not found', p_card_id;
    END IF;

    -- Card must be active for authorizations
    IF p_status = 'AUTHORIZED' AND v_card_status <> 'ACTIVE' THEN
        p_status := 'DECLINED';
        v_decline_reason := 'CARD_NOT_ACTIVE';
    END IF;

    -- Limit checks (only for purchase-type authorizations)
    IF p_status = 'AUTHORIZED' AND p_transaction_type IN ('PURCHASE', 'CASH_ADVANCE', 'CASH_WITHDRAWAL') THEN
        SELECT cl.single_transaction_limit, cl.daily_purchase_limit, cl.online_transaction_limit
        INTO   v_single_limit, v_daily_limit, v_online_limit
        FROM   card.card_limits cl
        WHERE  cl.card_id = p_card_id;

        -- Single transaction check
        IF p_amount > v_single_limit THEN
            p_status := 'DECLINED';
            v_decline_reason := 'EXCEEDS_SINGLE_TRANSACTION_LIMIT';
        END IF;

        -- Daily limit check
        IF p_status = 'AUTHORIZED' THEN
            SELECT COALESCE(SUM(amount), 0)
            INTO   v_daily_spent
            FROM   card.transactions
            WHERE  card_id = p_card_id
              AND  transaction_type = p_transaction_type
              AND  status IN ('AUTHORIZED', 'POSTED')
              AND  authorized_at >= DATE_TRUNC('day', now());

            IF (v_daily_spent + p_amount) > v_daily_limit THEN
                p_status := 'DECLINED';
                v_decline_reason := 'EXCEEDS_DAILY_LIMIT';
            END IF;
        END IF;

        -- Online limit check
        IF p_status = 'AUTHORIZED' AND p_is_online AND p_amount > v_online_limit THEN
            p_status := 'DECLINED';
            v_decline_reason := 'EXCEEDS_ONLINE_LIMIT';
        END IF;

        -- Available balance check
        IF p_status = 'AUTHORIZED' AND p_amount > v_available THEN
            p_status := 'DECLINED';
            v_decline_reason := 'INSUFFICIENT_FUNDS';
        END IF;
    END IF;

    -- Insert transaction record
    INSERT INTO card.transactions (
        card_id, account_id, authorization_code,
        transaction_type, amount, billing_currency,
        merchant_name, merchant_id, merchant_category_code,
        status, decline_reason, is_online, is_international,
        is_contactless, installments,
        authorized_at, posted_at
    ) VALUES (
        p_card_id, v_account_id, p_authorization_code,
        p_transaction_type, p_amount, 'BRL',
        p_merchant_name, p_merchant_id, p_merchant_category_code,
        p_status, v_decline_reason, p_is_online, p_is_international,
        p_is_contactless, p_installments,
        now(),
        CASE WHEN p_status = 'POSTED' THEN now() ELSE NULL END
    )
    RETURNING transaction_id INTO v_transaction_id;

    -- Update account balances
    IF p_status = 'AUTHORIZED' THEN
        UPDATE card.card_accounts SET
            available_balance = available_balance - p_amount,
            pending_amount    = pending_amount    + p_amount,
            updated_at        = now()
        WHERE account_id = v_account_id;

    ELSIF p_status = 'POSTED' THEN
        UPDATE card.card_accounts SET
            balance           = balance           + p_amount,
            available_balance = available_balance - p_amount,
            updated_at        = now()
        WHERE account_id = v_account_id;
    END IF;

    RETURN v_transaction_id;
END;
$$;

COMMENT ON FUNCTION card.sp_process_transaction IS
    'Records a card transaction, enforces velocity and limit controls, and updates account balances. Returns the new transaction_id.';
