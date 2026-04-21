-- =============================================================================
-- Procedure: card.sp_update_card_status
-- Application: NovoCard
-- Description: Manages card status transitions enforcing the allowed state
--              machine. Prevents illegal transitions (e.g. CANCELLED -> ACTIVE),
--              records the change in card_status_history, and updates the card
--              row. Called by the block/unblock, fraud response, and
--              cancellation flows.
--
-- Allowed transitions:
--   PENDING_ACTIVATION -> ACTIVE
--   ACTIVE             -> BLOCKED_TEMPORARY | BLOCKED_FRAUD | CANCELLED | LOST | STOLEN | EXPIRED
--   BLOCKED_TEMPORARY  -> ACTIVE | BLOCKED_FRAUD | CANCELLED
--   BLOCKED_FRAUD      -> CANCELLED
--   LOST               -> CANCELLED
--   STOLEN             -> CANCELLED
-- =============================================================================

CREATE OR ALTER PROCEDURE card.sp_update_card_status
    @p_card_id      UNIQUEIDENTIFIER,
    @p_new_status   NVARCHAR(30),
    @p_reason       NVARCHAR(255)   = NULL,
    @p_initiated_by NVARCHAR(20)    = N'SYSTEM',
    @p_operator_id  NVARCHAR(100)   = NULL,
    @p_channel      NVARCHAR(20)    = N'API'
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE
        @v_current_status   NVARCHAR(30),
        @v_transition_ok    BIT = 0;

    SELECT @v_current_status = status
    FROM   card.cards WITH (UPDLOCK, ROWLOCK)
    WHERE  card_id = @p_card_id;

    IF @@ROWCOUNT = 0
        THROW 51000, 'Card not found.', 1;

    IF @v_current_status = @p_new_status
    BEGIN
        PRINT N'Card is already in the requested status. No change made.';
        RETURN;
    END;

    -- Enforce state machine
    IF  (@v_current_status = N'PENDING_ACTIVATION' AND @p_new_status = N'ACTIVE')
     OR (@v_current_status = N'ACTIVE'             AND @p_new_status IN (N'BLOCKED_TEMPORARY', N'BLOCKED_FRAUD', N'CANCELLED', N'LOST', N'STOLEN', N'EXPIRED'))
     OR (@v_current_status = N'BLOCKED_TEMPORARY'  AND @p_new_status IN (N'ACTIVE', N'BLOCKED_FRAUD', N'CANCELLED'))
     OR (@v_current_status = N'BLOCKED_FRAUD'      AND @p_new_status = N'CANCELLED')
     OR (@v_current_status = N'LOST'               AND @p_new_status = N'CANCELLED')
     OR (@v_current_status = N'STOLEN'             AND @p_new_status = N'CANCELLED')
        SET @v_transition_ok = 1;

    IF @v_transition_ok = 0
    BEGIN
        DECLARE @err_msg NVARCHAR(200) = N'Illegal card status transition: ' + @v_current_status + N' -> ' + @p_new_status;
        THROW 51001, @err_msg, 1;
    END;

    -- Update card
    UPDATE card.cards SET
        status              = @p_new_status,
        activated_at        = CASE WHEN @p_new_status = N'ACTIVE' AND activated_at IS NULL
                                   THEN SYSDATETIMEOFFSET() ELSE activated_at END,
        cancelled_at        = CASE WHEN @p_new_status IN (N'CANCELLED', N'LOST', N'STOLEN')
                                   THEN SYSDATETIMEOFFSET() ELSE cancelled_at END,
        cancellation_reason = CASE WHEN @p_new_status IN (N'CANCELLED', N'LOST', N'STOLEN')
                                   THEN @p_reason ELSE cancellation_reason END,
        updated_at          = SYSDATETIMEOFFSET()
    WHERE card_id = @p_card_id;

    -- Audit history
    INSERT INTO card.card_status_history (
        card_id, previous_status, new_status,
        reason, initiated_by, operator_id, channel
    ) VALUES (
        @p_card_id, @v_current_status, @p_new_status,
        @p_reason, @p_initiated_by, @p_operator_id, @p_channel
    );
END;
GO
