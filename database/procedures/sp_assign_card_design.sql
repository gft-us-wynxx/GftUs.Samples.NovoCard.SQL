-- =============================================================================
-- Procedure: design.sp_assign_card_design
-- Application: NovoCard
-- Description: Assigns or replaces the design on an existing card. Validates
--              template compatibility with the card's product class, retires
--              the previous design (is_current = FALSE), and inserts the new
--              design record in PENDING approval state. Physical card reprint
--              is triggered externally once approval_status reaches APPROVED.
--
-- Parameters:
--   p_card_id           UUID    - Target card
--   p_template_id       UUID    - New template to apply
--   p_custom_name_text  VARCHAR - Optional custom name override
--   p_custom_color      CHAR(7) - Optional HEX color override
--   p_monogram          CHAR(2) - Optional 1-2 char monogram
--   p_requested_by      VARCHAR - Customer or operator ID
-- =============================================================================

CREATE OR REPLACE FUNCTION design.sp_assign_card_design(
    p_card_id           UUID,
    p_template_id       UUID,
    p_custom_name_text  VARCHAR(26)     DEFAULT NULL,
    p_custom_color      CHAR(7)         DEFAULT NULL,
    p_monogram          CHAR(2)         DEFAULT NULL,
    p_requested_by      VARCHAR(100)    DEFAULT current_user
)
RETURNS UUID
LANGUAGE plpgsql
AS $$
DECLARE
    v_design_id         UUID;
    v_product_class     VARCHAR(10);
    v_card_status       VARCHAR(30);
    v_compatible        TEXT[];
BEGIN
    -- Validate card is in a valid state for design changes
    SELECT ct.product_class, c.status
    INTO   v_product_class, v_card_status
    FROM   card.cards c
    INNER JOIN card.card_types ct ON ct.card_type_id = c.card_type_id
    WHERE  c.card_id = p_card_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Card % not found', p_card_id;
    END IF;

    IF v_card_status IN ('CANCELLED', 'EXPIRED') THEN
        RAISE EXCEPTION 'Cannot assign design to card % with status %', p_card_id, v_card_status;
    END IF;

    -- Validate template compatibility
    SELECT compatible_product_classes
    INTO   v_compatible
    FROM   design.design_templates
    WHERE  template_id = p_template_id AND is_active = TRUE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Template % not found or is inactive', p_template_id;
    END IF;

    IF NOT (v_product_class = ANY(v_compatible)) THEN
        RAISE EXCEPTION 'Template % is not compatible with product class % (compatible: %)',
            p_template_id, v_product_class, v_compatible;
    END IF;

    -- Retire previous current design
    UPDATE design.card_designs
    SET    is_current   = FALSE,
           replaced_at  = now()
    WHERE  card_id      = p_card_id
      AND  is_current   = TRUE;

    -- Insert new design
    INSERT INTO design.card_designs (
        card_id, template_id, custom_name_text,
        custom_color, monogram, is_current, approval_status
    ) VALUES (
        p_card_id, p_template_id, p_custom_name_text,
        p_custom_color, p_monogram, TRUE, 'PENDING'
    )
    RETURNING design_id INTO v_design_id;

    -- Update download_count on template
    UPDATE design.design_templates
    SET    download_count = download_count + 1,
           updated_at     = now()
    WHERE  template_id = p_template_id;

    RETURN v_design_id;
END;
$$;

COMMENT ON FUNCTION design.sp_assign_card_design IS
    'Assigns a new design template to a card, retiring the previous design. Returns the new design_id.';
