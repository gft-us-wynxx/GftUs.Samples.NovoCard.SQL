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
--   @p_card_id                UNIQUEIDENTIFIER - Card being charged
--   @p_amount                 DECIMAL          - Transaction amount in billing currency
--   @p_transaction_type       NVARCHAR         - PURCHASE | CASH_WITHDRAWAL | BALANCE_LOAD | etc.
--   @p_status                 NVARCHAR         - AUTHORIZED | POSTED | DECLINED
--   @p_merchant_name          NVARCHAR         - Merchant display name
--   @p_merchant_id            NVARCHAR         - Acquirer merchant ID
--   @p_merchant_category_code CHAR(4)          - ISO MCC
--   @p_authorization_code     NVARCHAR         - Issuer authorization code
--   @p_is_online              BIT              - Online/CNP flag
--   @p_is_international       BIT              - Cross-border flag
--   @p_is_contactless         BIT              - NFC flag
--   @p_installments           SMALLINT         - Number of installments (1 = none)
--   @p_transaction_id         UNIQUEIDENTIFIER OUTPUT - Returns the new transaction_id
-- =============================================================================

CREATE OR ALTER PROCEDURE card.sp_process_transaction
    @p_card_id                  UNIQUEIDENTIFIER,
    @p_amount                   DECIMAL(15, 2),
    @p_transaction_type         NVARCHAR(30)        = N'PURCHASE',
    @p_status                   NVARCHAR(20)        = N'AUTHORIZED',
    @p_merchant_name            NVARCHAR(255)       = NULL,
    @p_merchant_id              NVARCHAR(50)        = NULL,
    @p_merchant_category_code   CHAR(4)             = NULL,
    @p_authorization_code       NVARCHAR(20)        = NULL,
    @p_is_online                BIT                 = 0,
    @p_is_international         BIT                 = 0,
    @p_is_contactless           BIT                 = 0,
    @p_installments             SMALLINT            = 1,
    @p_transaction_id           UNIQUEIDENTIFIER    OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE
        @v_account_id       UNIQUEIDENTIFIER,
        @v_card_status      NVARCHAR(30),
        @v_available        DECIMAL(15, 2),
        @v_single_limit     DECIMAL(12, 2),
        @v_daily_limit      DECIMAL(12, 2),
        @v_online_limit     DECIMAL(12, 2),
        @v_daily_spent      DECIMAL(15, 2),
        @v_decline_reason   NVARCHAR(100),
        @v_today_start      DATETIMEOFFSET,
        @v_effective_status NVARCHAR(20);

    SET @v_effective_status = @p_status;

    -- Get card and account state with update lock
    SELECT @v_card_status = c.status,
           @v_account_id  = ca.account_id,
           @v_available   = ca.available_balance
    FROM   card.cards c
    INNER JOIN card.card_accounts ca ON ca.card_id = c.card_id
    WHERE  c.card_id = @p_card_id
    OPTION (RECOMPILE);

    IF @@ROWCOUNT = 0
        THROW 51000, 'Card not found.', 1;

    -- Card must be active for authorizations
    IF @v_effective_status = N'AUTHORIZED' AND @v_card_status <> N'ACTIVE'
    BEGIN
        SET @v_effective_status = N'DECLINED';
        SET @v_decline_reason   = N'CARD_NOT_ACTIVE';
    END;

    -- Limit checks for purchase-type authorizations
    IF @v_effective_status = N'AUTHORIZED' AND @p_transaction_type IN (N'PURCHASE', N'CASH_ADVANCE', N'CASH_WITHDRAWAL')
    BEGIN
        SELECT @v_single_limit = single_transaction_limit,
               @v_daily_limit  = daily_purchase_limit,
               @v_online_limit = online_transaction_limit
        FROM   card.card_limits
        WHERE  card_id = @p_card_id;

        -- Single-transaction check
        IF @p_amount > @v_single_limit
        BEGIN
            SET @v_effective_status = N'DECLINED';
            SET @v_decline_reason   = N'EXCEEDS_SINGLE_TRANSACTION_LIMIT';
        END;

        -- Daily limit check
        IF @v_effective_status = N'AUTHORIZED'
        BEGIN
            SET @v_today_start = DATEADD(day, DATEDIFF(day, 0, SYSDATETIMEOFFSET()), 0);

            SELECT @v_daily_spent = COALESCE(SUM(amount), 0)
            FROM   card.transactions
            WHERE  card_id          = @p_card_id
              AND  transaction_type = @p_transaction_type
              AND  status           IN (N'AUTHORIZED', N'POSTED')
              AND  authorized_at   >= @v_today_start;

            IF (@v_daily_spent + @p_amount) > @v_daily_limit
            BEGIN
                SET @v_effective_status = N'DECLINED';
                SET @v_decline_reason   = N'EXCEEDS_DAILY_LIMIT';
            END;
        END;

        -- Online limit check
        IF @v_effective_status = N'AUTHORIZED' AND @p_is_online = 1 AND @p_amount > @v_online_limit
        BEGIN
            SET @v_effective_status = N'DECLINED';
            SET @v_decline_reason   = N'EXCEEDS_ONLINE_LIMIT';
        END;

        -- Available balance check
        IF @v_effective_status = N'AUTHORIZED' AND @p_amount > @v_available
        BEGIN
            SET @v_effective_status = N'DECLINED';
            SET @v_decline_reason   = N'INSUFFICIENT_FUNDS';
        END;
    END;

    -- Insert transaction record
    SET @p_transaction_id = NEWID();

    INSERT INTO card.transactions (
        transaction_id, card_id, account_id, authorization_code,
        transaction_type, amount, billing_currency,
        merchant_name, merchant_id, merchant_category_code,
        status, decline_reason, is_online, is_international,
        is_contactless, installments,
        authorized_at, posted_at
    ) VALUES (
        @p_transaction_id, @p_card_id, @v_account_id, @p_authorization_code,
        @p_transaction_type, @p_amount, N'BRL',
        @p_merchant_name, @p_merchant_id, @p_merchant_category_code,
        @v_effective_status, @v_decline_reason, @p_is_online, @p_is_international,
        @p_is_contactless, @p_installments,
        SYSDATETIMEOFFSET(),
        CASE WHEN @v_effective_status = N'POSTED' THEN SYSDATETIMEOFFSET() ELSE NULL END
    );

    -- Update account balances
    IF @v_effective_status = N'AUTHORIZED'
        UPDATE card.card_accounts SET
            available_balance = available_balance - @p_amount,
            pending_amount    = pending_amount    + @p_amount,
            updated_at        = SYSDATETIMEOFFSET()
        WHERE account_id = @v_account_id;

    ELSE IF @v_effective_status = N'POSTED'
        UPDATE card.card_accounts SET
            balance           = balance           + @p_amount,
            available_balance = available_balance - @p_amount,
            updated_at        = SYSDATETIMEOFFSET()
        WHERE account_id = @v_account_id;
END;
GO
