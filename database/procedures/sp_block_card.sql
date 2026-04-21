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
--   @p_card_id       UNIQUEIDENTIFIER - Card to block
--   @p_block_type    NVARCHAR         - TEMPORARY | FRAUD
--   @p_reason        NVARCHAR         - Human-readable reason for the block
--   @p_initiated_by  NVARCHAR         - CUSTOMER | RISK_ANALYST | FRAUD_ENGINE | SUPPORT
--   @p_operator_id   NVARCHAR         - Employee ID when initiated_by is not CUSTOMER
--   @p_channel       NVARCHAR         - Channel of the request
-- =============================================================================

CREATE OR ALTER PROCEDURE card.sp_block_card
    @p_card_id      UNIQUEIDENTIFIER,
    @p_block_type   NVARCHAR(20)    = N'TEMPORARY',
    @p_reason       NVARCHAR(255)   = NULL,
    @p_initiated_by NVARCHAR(20)    = N'CUSTOMER',
    @p_operator_id  NVARCHAR(100)   = NULL,
    @p_channel      NVARCHAR(20)    = N'APP'
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @v_new_status NVARCHAR(30);

    IF @p_block_type NOT IN (N'TEMPORARY', N'FRAUD')
        THROW 51000, 'Invalid block type. Must be TEMPORARY or FRAUD.', 1;

    IF @p_block_type = N'FRAUD' AND @p_initiated_by = N'CUSTOMER'
        THROW 51001, 'Customers cannot initiate FRAUD blocks. Use TEMPORARY instead.', 1;

    SET @v_new_status = CASE @p_block_type
        WHEN N'TEMPORARY' THEN N'BLOCKED_TEMPORARY'
        WHEN N'FRAUD'     THEN N'BLOCKED_FRAUD'
    END;

    EXEC card.sp_update_card_status
        @p_card_id      = @p_card_id,
        @p_new_status   = @v_new_status,
        @p_reason       = @p_reason,
        @p_initiated_by = @p_initiated_by,
        @p_operator_id  = @p_operator_id,
        @p_channel      = @p_channel;
END;
GO
