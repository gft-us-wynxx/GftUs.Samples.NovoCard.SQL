-- =============================================================================
-- Procedure: design.sp_assign_card_design
-- Application: NovoCard
-- Description: Assigns or replaces the design on an existing card. Validates
--              template compatibility with the card's product class, retires
--              the previous design (is_current = 0), and inserts the new
--              design record in PENDING approval state. Physical card reprint
--              is triggered externally once approval_status reaches APPROVED.
--
-- Parameters:
--   @p_card_id           UNIQUEIDENTIFIER - Target card
--   @p_template_id       UNIQUEIDENTIFIER - New template to apply
--   @p_custom_name_text  NVARCHAR         - Optional custom name override
--   @p_custom_color      NCHAR(7)         - Optional HEX color override
--   @p_monogram          NCHAR(2)         - Optional 1-2 char monogram
--   @p_requested_by      NVARCHAR         - Customer or operator ID
--   @p_design_id         UNIQUEIDENTIFIER OUTPUT - Returns the new design_id
-- =============================================================================

CREATE OR ALTER PROCEDURE design.sp_assign_card_design
    @p_card_id          UNIQUEIDENTIFIER,
    @p_template_id      UNIQUEIDENTIFIER,
    @p_custom_name_text NVARCHAR(26)        = NULL,
    @p_custom_color     NCHAR(7)            = NULL,
    @p_monogram         NCHAR(2)            = NULL,
    @p_requested_by     NVARCHAR(100)       = NULL,
    @p_design_id        UNIQUEIDENTIFIER    OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE
        @v_product_class    NVARCHAR(10),
        @v_card_status      NVARCHAR(30),
        @v_compatible       NVARCHAR(MAX);

    IF @p_requested_by IS NULL SET @p_requested_by = SYSTEM_USER;

    -- Validate card is in a valid state for design changes
    SELECT @v_product_class = ct.product_class,
           @v_card_status   = c.status
    FROM   card.cards c
    INNER JOIN card.card_types ct ON ct.card_type_id = c.card_type_id
    WHERE  c.card_id = @p_card_id;

    IF @@ROWCOUNT = 0
        THROW 51000, 'Card not found.', 1;

    IF @v_card_status IN (N'CANCELLED', N'EXPIRED')
    BEGIN
        DECLARE @state_msg NVARCHAR(200) = N'Cannot assign design to card with status ' + @v_card_status;
        THROW 51001, @state_msg, 1;
    END;

    -- Validate template compatibility
    SELECT @v_compatible = compatible_product_classes
    FROM   design.design_templates
    WHERE  template_id = @p_template_id AND is_active = 1;

    IF @@ROWCOUNT = 0
        THROW 51002, 'Template not found or is inactive.', 1;

    -- compatible_product_classes is a JSON array; use OPENJSON to check membership
    IF NOT EXISTS (
        SELECT 1 FROM OPENJSON(@v_compatible) WHERE value = @v_product_class
    )
    BEGIN
        DECLARE @compat_msg NVARCHAR(200) = N'Template is not compatible with product class ' + @v_product_class;
        THROW 51003, @compat_msg, 1;
    END;

    -- Retire previous current design
    UPDATE design.card_designs
    SET    is_current   = 0,
           replaced_at  = SYSDATETIMEOFFSET()
    WHERE  card_id      = @p_card_id
      AND  is_current   = 1;

    -- Insert new design
    SET @p_design_id = NEWID();

    INSERT INTO design.card_designs (
        design_id, card_id, template_id, custom_name_text,
        custom_color, monogram, is_current, approval_status
    ) VALUES (
        @p_design_id, @p_card_id, @p_template_id, @p_custom_name_text,
        @p_custom_color, @p_monogram, 1, N'PENDING'
    );

    -- Increment download count on template
    UPDATE design.design_templates
    SET    download_count = download_count + 1,
           updated_at     = SYSDATETIMEOFFSET()
    WHERE  template_id = @p_template_id;
END;
GO
