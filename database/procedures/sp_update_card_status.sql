-- =============================================================================
-- Procedure: card.sp_update_card_status
-- Application: NovoCard
-- Description: Manages card status transitions enforcing the allowed state
--              machine. Prevents illegal transitions (e.g. CANCELLED → ACTIVE),
--              records the change in card_status_history, and updates the card
--              row. Called by the block/unblock, fraud response, and
--              cancellation flows.
--
-- Allowed transitions:
--   PENDING_ACTIVATION → ACTIVE
--   ACTIVE             → BLOCKED_TEMPORARY | BLOCKED_FRAUD | CANCELLED | LOST | STOLEN
--   BLOCKED_TEMPORARY  → ACTIVE | BLOCKED_FRAUD | CANCELLED
--   BLOCKED_FRAUD      → CANCELLED
--   LOST               → CANCELLED
--   STOLEN             → CANCELLED
--   ACTIVE             → EXPIRED (system-only, batch)
-- =============================================================================

CREATE OR REPLACE PROCEDURE card.sp_update_card_status(
    p_card_id       UUID,
    p_new_status    VARCHAR(30),
    p_reason        VARCHAR(255)    DEFAULT NULL,
    p_initiated_by  VARCHAR(20)     DEFAULT 'SYSTEM',
    p_operator_id   VARCHAR(100)    DEFAULT NULL,
    p_channel       VARCHAR(20)     DEFAULT 'API'
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_current_status    VARCHAR(30);
    v_customer_id       UUID;
BEGIN
    SELECT status, customer_id
    INTO   v_current_status, v_customer_id
    FROM   card.cards
    WHERE  card_id = p_card_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Card % not found', p_card_id;
    END IF;

    IF v_current_status = p_new_status THEN
        RAISE NOTICE 'Card % is already in status %. No change made.', p_card_id, p_new_status;
        RETURN;
    END IF;

    -- Enforce state machine
    IF NOT (
        (v_current_status = 'PENDING_ACTIVATION' AND p_new_status = 'ACTIVE')
        OR (v_current_status = 'ACTIVE'            AND p_new_status IN ('BLOCKED_TEMPORARY', 'BLOCKED_FRAUD', 'CANCELLED', 'LOST', 'STOLEN', 'EXPIRED'))
        OR (v_current_status = 'BLOCKED_TEMPORARY' AND p_new_status IN ('ACTIVE', 'BLOCKED_FRAUD', 'CANCELLED'))
        OR (v_current_status = 'BLOCKED_FRAUD'     AND p_new_status = 'CANCELLED')
        OR (v_current_status = 'LOST'              AND p_new_status = 'CANCELLED')
        OR (v_current_status = 'STOLEN'            AND p_new_status = 'CANCELLED')
    ) THEN
        RAISE EXCEPTION 'Illegal card status transition: % → % for card %',
            v_current_status, p_new_status, p_card_id;
    END IF;

    -- Update card
    UPDATE card.cards SET
        status          = p_new_status,
        activated_at    = CASE WHEN p_new_status = 'ACTIVE' AND activated_at IS NULL THEN now() ELSE activated_at END,
        cancelled_at    = CASE WHEN p_new_status IN ('CANCELLED', 'LOST', 'STOLEN')   THEN now() ELSE cancelled_at END,
        cancellation_reason = CASE WHEN p_new_status IN ('CANCELLED', 'LOST', 'STOLEN') THEN p_reason ELSE cancellation_reason END,
        updated_at      = now()
    WHERE card_id = p_card_id;

    -- Audit history
    INSERT INTO card.card_status_history (
        card_id, previous_status, new_status,
        reason, initiated_by, operator_id, channel
    ) VALUES (
        p_card_id, v_current_status, p_new_status,
        p_reason, p_initiated_by, p_operator_id, p_channel
    );
END;
$$;

COMMENT ON PROCEDURE card.sp_update_card_status IS
    'Transitions a card status through the allowed state machine and appends an audit history record.';
