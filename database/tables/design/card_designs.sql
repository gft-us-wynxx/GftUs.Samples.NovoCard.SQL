-- =============================================================================
-- Table: design.card_designs
-- Application: NovoCard
-- Description: Records the design applied to a specific card. A card has at
--              most one current design (is_current = TRUE) but retains history
--              of all previous designs for traceability. Customers can
--              personalize text and color overrides on top of the base template.
-- =============================================================================

CREATE TABLE IF NOT EXISTS design.card_designs (
    design_id           UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    card_id             UUID            NOT NULL
                            REFERENCES card.cards (card_id) ON DELETE CASCADE,
    template_id         UUID            NOT NULL
                            REFERENCES design.design_templates (template_id),

    -- Customer customization overrides
    custom_name_text    VARCHAR(26),    -- printed on card instead of full name
    custom_color        CHAR(7),        -- customer HEX override for accent
    monogram            CHAR(2),        -- 1-2 character monogram option
    font_preference     VARCHAR(30),

    -- Design state
    is_current          BOOLEAN         NOT NULL DEFAULT TRUE,
    approved_at         TIMESTAMPTZ,
    approval_status     VARCHAR(20)     NOT NULL DEFAULT 'PENDING'
                            CHECK (approval_status IN ('PENDING', 'APPROVED', 'REJECTED', 'CANCELLED')),
    rejection_reason    VARCHAR(255),
    assigned_at         TIMESTAMPTZ     NOT NULL DEFAULT now(),
    replaced_at         TIMESTAMPTZ,

    -- Rendering metadata
    render_url          VARCHAR(500),
    render_version      SMALLINT        NOT NULL DEFAULT 1,
    rendered_at         TIMESTAMPTZ,

    created_at          TIMESTAMPTZ     NOT NULL DEFAULT now()
);

CREATE INDEX idx_card_designs_card_id       ON design.card_designs (card_id);
CREATE INDEX idx_card_designs_template_id   ON design.card_designs (template_id);
CREATE INDEX idx_card_designs_is_current    ON design.card_designs (card_id) WHERE is_current = TRUE;
CREATE INDEX idx_card_designs_approval      ON design.card_designs (approval_status);

COMMENT ON TABLE design.card_designs IS
    'Design assignments per card, including customization overrides and approval workflow state.';
COMMENT ON COLUMN design.card_designs.custom_name_text IS
    'Optional name override printed on the card face (max 26 chars). Defaults to card_holder_name.';
COMMENT ON COLUMN design.card_designs.is_current IS
    'Only one design per card should have is_current=TRUE at any time. Set to FALSE on replacement.';
COMMENT ON COLUMN design.card_designs.approval_status IS
    'Design personalization requires content moderation approval before card print/rendering.';
