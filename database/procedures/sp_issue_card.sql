-- =============================================================================
-- Procedure: card.sp_issue_card
-- Application: NovoCard
-- Description: Issues a new card for an eligible customer. Validates that
--              the customer exists, KYC is approved, and the requested card
--              type is active. Creates the card, its account, and default
--              spending limits in a single atomic transaction. Optionally
--              assigns a design template if provided.
--
-- Parameters:
--   p_customer_id      UUID    - Target customer
--   p_card_type_id     INT     - Product type to issue
--   p_card_holder_name VARCHAR - Name to emboss on the card
--   p_masked_pan       VARCHAR - Pre-generated masked PAN from vault service
--   p_expiry_month     INT     - Expiry month (1–12)
--   p_expiry_year      INT     - Expiry 4-digit year
--   p_card_format      VARCHAR - PHYSICAL | VIRTUAL | BOTH
--   p_template_id      UUID    - Optional design template (nullable)
--   p_credit_limit     NUMERIC - Initial credit limit (0 for debit/prepaid)
--   p_initial_balance  NUMERIC - Initial loaded balance (prepaid only)
--   p_issued_by        VARCHAR - Operator or system identifier
--
-- Returns: UUID of the newly created card_id
-- =============================================================================

CREATE OR REPLACE FUNCTION card.sp_issue_card(
    p_customer_id       UUID,
    p_card_type_id      INTEGER,
    p_card_holder_name  VARCHAR(100),
    p_masked_pan        VARCHAR(19),
    p_expiry_month      SMALLINT,
    p_expiry_year       SMALLINT,
    p_card_format       VARCHAR(10)     DEFAULT 'PHYSICAL',
    p_template_id       UUID            DEFAULT NULL,
    p_credit_limit      NUMERIC(15, 2)  DEFAULT 0.00,
    p_initial_balance   NUMERIC(15, 2)  DEFAULT 0.00,
    p_issued_by         VARCHAR(100)    DEFAULT current_user
)
RETURNS UUID
LANGUAGE plpgsql
AS $$
DECLARE
    v_card_id           UUID;
    v_account_id        UUID;
    v_product_class     VARCHAR(10);
    v_kyc_status        VARCHAR(20);
    v_customer_status   VARCHAR(20);
    v_type_active       BOOLEAN;
BEGIN
    -- Validate customer
    SELECT kyc_status, status
    INTO   v_kyc_status, v_customer_status
    FROM   customer.customers
    WHERE  customer_id = p_customer_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Customer % not found', p_customer_id;
    END IF;

    IF v_kyc_status <> 'APPROVED' THEN
        RAISE EXCEPTION 'Customer % KYC status is %. Card issuance requires APPROVED status.',
            p_customer_id, v_kyc_status;
    END IF;

    IF v_customer_status <> 'ACTIVE' THEN
        RAISE EXCEPTION 'Customer % is not ACTIVE (current: %). Cannot issue card.',
            p_customer_id, v_customer_status;
    END IF;

    -- Validate card type
    SELECT product_class, is_active
    INTO   v_product_class, v_type_active
    FROM   card.card_types
    WHERE  card_type_id = p_card_type_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Card type % not found', p_card_type_id;
    END IF;

    IF NOT v_type_active THEN
        RAISE EXCEPTION 'Card type % is not currently active', p_card_type_id;
    END IF;

    -- Insert card
    INSERT INTO card.cards (
        customer_id, card_type_id, card_holder_name,
        masked_pan, expiry_month, expiry_year,
        card_format, status, issued_at
    ) VALUES (
        p_customer_id, p_card_type_id, p_card_holder_name,
        p_masked_pan, p_expiry_month, p_expiry_year,
        p_card_format, 'PENDING_ACTIVATION', now()
    )
    RETURNING card_id INTO v_card_id;

    -- Create account
    INSERT INTO card.card_accounts (
        card_id, currency, credit_limit,
        available_balance, balance
    ) VALUES (
        v_card_id, 'BRL', p_credit_limit,
        p_credit_limit,
        CASE v_product_class WHEN 'PREPAID' THEN p_initial_balance ELSE 0 END
    )
    RETURNING account_id INTO v_account_id;

    -- Create default limits
    INSERT INTO card.card_limits (card_id, set_by)
    VALUES (v_card_id, 'SYSTEM');

    -- Assign default design template if provided
    IF p_template_id IS NOT NULL THEN
        INSERT INTO design.card_designs (card_id, template_id, is_current, approval_status)
        VALUES (v_card_id, p_template_id, TRUE, 'APPROVED');

        UPDATE card.cards SET design_id = (
            SELECT design_id FROM design.card_designs
            WHERE card_id = v_card_id AND is_current = TRUE
        ) WHERE card_id = v_card_id;
    END IF;

    -- Record initial status
    INSERT INTO card.card_status_history (
        card_id, previous_status, new_status,
        reason, initiated_by, operator_id
    ) VALUES (
        v_card_id, 'N/A', 'PENDING_ACTIVATION',
        'Card issued', 'SYSTEM', p_issued_by
    );

    RETURN v_card_id;
END;
$$;

COMMENT ON FUNCTION card.sp_issue_card IS
    'Issues a new NovoCard card for an eligible KYC-approved customer. Creates card, account, and limit profile atomically.';
