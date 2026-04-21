-- =============================================================================
-- Procedure: card.sp_block_card
-- Application: NovoCard
-- Description: Convenience wrapper over sp_update_card_status for blocking a
--              card. Supports both customer-initiated temporary blocks (via app)
--              and fraud-response blocks (via risk analyst or fraud engine).
--              A temporary block can be reversed; a fraud block cannot without
--              manual analyst review.
--
-- Parameters:
--   p_card_id       UUID    - Card to block
--   p_block_type    VARCHAR - TEMPORARY | FRAUD
--   p_reason        VARCHAR - Human-readable reason for the block
--   p_initiated_by  VARCHAR - CUSTOMER | RISK_ANALYST | FRAUD_ENGINE | SUPPORT
--   p_operator_id   VARCHAR - Employee ID when initiated_by is not CUSTOMER
--   p_channel       VARCHAR - Channel of the request
-- =============================================================================

CREATE OR REPLACE PROCEDURE card.sp_block_card(
    p_card_id       UUID,
    p_block_type    VARCHAR(20)     DEFAULT 'TEMPORARY',
    p_reason        VARCHAR(255)    DEFAULT NULL,
    p_initiated_by  VARCHAR(20)     DEFAULT 'CUSTOMER',
    p_operator_id   VARCHAR(100)    DEFAULT NULL,
    p_channel       VARCHAR(20)     DEFAULT 'APP'
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_new_status    VARCHAR(30);
BEGIN
    IF p_block_type NOT IN ('TEMPORARY', 'FRAUD') THEN
        RAISE EXCEPTION 'Invalid block type %. Must be TEMPORARY or FRAUD.', p_block_type;
    END IF;

    IF p_block_type = 'FRAUD' AND p_initiated_by = 'CUSTOMER' THEN
        RAISE EXCEPTION 'Customers cannot initiate FRAUD blocks. Use TEMPORARY instead.';
    END IF;

    v_new_status := CASE p_block_type
        WHEN 'TEMPORARY' THEN 'BLOCKED_TEMPORARY'
        WHEN 'FRAUD'     THEN 'BLOCKED_FRAUD'
    END;

    CALL card.sp_update_card_status(
        p_card_id       => p_card_id,
        p_new_status    => v_new_status,
        p_reason        => p_reason,
        p_initiated_by  => p_initiated_by,
        p_operator_id   => p_operator_id,
        p_channel       => p_channel
    );
END;
$$;

COMMENT ON PROCEDURE card.sp_block_card IS
    'Blocks a card as BLOCKED_TEMPORARY (customer-reversible) or BLOCKED_FRAUD (analyst review required).';
