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
--   @p_customer_id      UNIQUEIDENTIFIER - Target customer
--   @p_card_type_id     INT              - Product type to issue
--   @p_card_holder_name NVARCHAR         - Name to emboss on the card
--   @p_masked_pan       NVARCHAR         - Pre-generated masked PAN from vault service
--   @p_expiry_month     SMALLINT         - Expiry month (1-12)
--   @p_expiry_year      SMALLINT         - Expiry 4-digit year
--   @p_card_format      NVARCHAR         - PHYSICAL | VIRTUAL | BOTH
--   @p_template_id      UNIQUEIDENTIFIER - Optional design template (nullable)
--   @p_credit_limit     DECIMAL          - Initial credit limit (0 for debit/prepaid)
--   @p_initial_balance  DECIMAL          - Initial loaded balance (prepaid only)
--   @p_issued_by        NVARCHAR         - Operator or system identifier
--   @p_card_id          UNIQUEIDENTIFIER OUTPUT - Returns the newly created card_id
-- =============================================================================

CREATE OR ALTER PROCEDURE card.sp_issue_card
    @p_customer_id      UNIQUEIDENTIFIER,
    @p_card_type_id     INT,
    @p_card_holder_name NVARCHAR(100),
    @p_masked_pan       NVARCHAR(19),
    @p_expiry_month     SMALLINT,
    @p_expiry_year      SMALLINT,
    @p_card_format      NVARCHAR(10)        = N'PHYSICAL',
    @p_template_id      UNIQUEIDENTIFIER    = NULL,
    @p_credit_limit     DECIMAL(15, 2)      = 0.00,
    @p_initial_balance  DECIMAL(15, 2)      = 0.00,
    @p_issued_by        NVARCHAR(100)       = NULL,
    @p_card_id          UNIQUEIDENTIFIER    OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE
        @v_kyc_status       NVARCHAR(20),
        @v_customer_status  NVARCHAR(20),
        @v_product_class    NVARCHAR(10),
        @v_type_active      BIT,
        @v_account_id       UNIQUEIDENTIFIER,
        @v_design_id        UNIQUEIDENTIFIER,
        @v_initial_balance  DECIMAL(15, 2);

    IF @p_issued_by IS NULL SET @p_issued_by = SYSTEM_USER;

    -- Validate customer
    SELECT @v_kyc_status = kyc_status, @v_customer_status = status
    FROM   customer.customers WITH (UPDLOCK, ROWLOCK)
    WHERE  customer_id = @p_customer_id;

    IF @@ROWCOUNT = 0
        THROW 51000, 'Customer not found.', 1;

    IF @v_kyc_status <> N'APPROVED'
    BEGIN
        DECLARE @kyc_msg NVARCHAR(200) = N'Customer KYC status is ' + @v_kyc_status + N'. Card issuance requires APPROVED status.';
        THROW 51001, @kyc_msg, 1;
    END;

    IF @v_customer_status <> N'ACTIVE'
    BEGIN
        DECLARE @status_msg NVARCHAR(200) = N'Customer is not ACTIVE (current: ' + @v_customer_status + N'). Cannot issue card.';
        THROW 51002, @status_msg, 1;
    END;

    -- Validate card type
    SELECT @v_product_class = product_class, @v_type_active = is_active
    FROM   card.card_types
    WHERE  card_type_id = @p_card_type_id;

    IF @@ROWCOUNT = 0
        THROW 51003, 'Card type not found.', 1;

    IF @v_type_active = 0
        THROW 51004, 'Card type is not currently active.', 1;

    -- Pre-generate IDs
    SET @p_card_id    = NEWID();
    SET @v_account_id = NEWID();

    SET @v_initial_balance = CASE @v_product_class WHEN N'PREPAID' THEN @p_initial_balance ELSE 0.00 END;

    -- Insert card
    INSERT INTO card.cards (
        card_id, customer_id, card_type_id, card_holder_name,
        masked_pan, expiry_month, expiry_year,
        card_format, status, issued_at
    ) VALUES (
        @p_card_id, @p_customer_id, @p_card_type_id, @p_card_holder_name,
        @p_masked_pan, @p_expiry_month, @p_expiry_year,
        @p_card_format, N'PENDING_ACTIVATION', SYSDATETIMEOFFSET()
    );

    -- Create account
    INSERT INTO card.card_accounts (
        account_id, card_id, currency, credit_limit, available_balance, balance
    ) VALUES (
        @v_account_id, @p_card_id, N'USD', @p_credit_limit,
        @p_credit_limit, @v_initial_balance
    );

    -- Create default limits
    INSERT INTO card.card_limits (card_id, set_by)
    VALUES (@p_card_id, N'SYSTEM');

    -- Assign default design template if provided
    IF @p_template_id IS NOT NULL
    BEGIN
        SET @v_design_id = NEWID();

        INSERT INTO design.card_designs (
            design_id, card_id, template_id, is_current, approval_status
        ) VALUES (
            @v_design_id, @p_card_id, @p_template_id, 1, N'APPROVED'
        );

        UPDATE card.cards
        SET    design_id  = @v_design_id,
               updated_at = SYSDATETIMEOFFSET()
        WHERE  card_id = @p_card_id;
    END;

    -- Record initial status
    INSERT INTO card.card_status_history (
        card_id, previous_status, new_status,
        reason, initiated_by, operator_id
    ) VALUES (
        @p_card_id, N'N/A', N'PENDING_ACTIVATION',
        N'Card issued', N'SYSTEM', @p_issued_by
    );
END;
GO
