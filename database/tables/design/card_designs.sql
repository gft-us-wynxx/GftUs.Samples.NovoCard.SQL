-- =============================================================================
-- Table: design.card_designs
-- Application: NovoCard
-- Description: Records the design applied to a specific card. A card has at
--              most one current design (is_current = 1) but retains history
--              of all previous designs for traceability. Customers can
--              personalize text and color overrides on top of the base template.
--
-- Notes:
--   custom_name_text: optional name override printed on the card face (max 26 chars).
--   is_current: only one design per card should have is_current=1 at any time.
--   approval_status: design personalization requires content moderation approval
--   before card print/rendering.
-- =============================================================================

IF OBJECT_ID('design.card_designs', 'U') IS NULL
CREATE TABLE design.card_designs (
    design_id           UNIQUEIDENTIFIER    NOT NULL CONSTRAINT pk_card_designs PRIMARY KEY DEFAULT NEWID(),
    card_id             UNIQUEIDENTIFIER    NOT NULL
                            CONSTRAINT fk_card_designs_card REFERENCES card.cards (card_id) ON DELETE CASCADE,
    template_id         UNIQUEIDENTIFIER    NOT NULL
                            CONSTRAINT fk_card_designs_template REFERENCES design.design_templates (template_id),

    -- Customer customization overrides
    custom_name_text    NVARCHAR(26)        NULL,   -- printed on card instead of full name
    custom_color        NCHAR(7)            NULL,   -- customer HEX override for accent
    monogram            NCHAR(2)            NULL,   -- 1-2 character monogram option
    font_preference     NVARCHAR(30)        NULL,

    -- Design state
    is_current          BIT                 NOT NULL DEFAULT 1,
    approved_at         DATETIMEOFFSET      NULL,
    approval_status     NVARCHAR(20)        NOT NULL DEFAULT N'PENDING'
                            CONSTRAINT chk_card_designs_approval CHECK (approval_status IN (
                                N'PENDING', N'APPROVED', N'REJECTED', N'CANCELLED'
                            )),
    rejection_reason    NVARCHAR(255)       NULL,
    assigned_at         DATETIMEOFFSET      NOT NULL DEFAULT SYSDATETIMEOFFSET(),
    replaced_at         DATETIMEOFFSET      NULL,

    -- Rendering metadata
    render_url          NVARCHAR(500)       NULL,
    render_version      SMALLINT            NOT NULL DEFAULT 1,
    rendered_at         DATETIMEOFFSET      NULL,

    created_at          DATETIMEOFFSET      NOT NULL DEFAULT SYSDATETIMEOFFSET()
);
GO

CREATE INDEX idx_card_designs_card_id       ON design.card_designs (card_id);
CREATE INDEX idx_card_designs_template_id   ON design.card_designs (template_id);
-- Filtered index: only one current design per card at any time
CREATE UNIQUE INDEX idx_card_designs_one_current ON design.card_designs (card_id) WHERE is_current = 1;
CREATE INDEX idx_card_designs_approval      ON design.card_designs (approval_status);
GO
