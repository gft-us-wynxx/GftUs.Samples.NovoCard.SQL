-- =============================================================================
-- Table: design.design_templates
-- Application: NovoCard
-- Description: Master catalog of card design templates managed by the NovoCard
--              design team. Templates define the visual shell that customers
--              can personalize. Each template is versioned; new versions do
--              not invalidate existing card designs that reference older versions.
-- =============================================================================

CREATE TABLE IF NOT EXISTS design.design_templates (
    template_id             UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    template_name           VARCHAR(100)    NOT NULL,
    display_name            VARCHAR(100)    NOT NULL,
    version                 SMALLINT        NOT NULL DEFAULT 1,
    description             TEXT,

    -- Compatibility
    compatible_product_classes  TEXT[]      NOT NULL DEFAULT ARRAY['CREDIT', 'DEBIT', 'PREPAID'],
    compatible_networks         TEXT[]      NOT NULL DEFAULT ARRAY['VISA', 'MASTERCARD', 'ELO', 'AMEX'],

    -- Visual properties
    primary_color           CHAR(7),        -- HEX e.g. #1A2B3C
    secondary_color         CHAR(7),
    base_image_url          VARCHAR(500)    NOT NULL,
    thumbnail_url           VARCHAR(500),
    is_dark_theme           BOOLEAN         NOT NULL DEFAULT FALSE,

    -- Metadata
    category                VARCHAR(50)     CHECK (category IN (
                                'CLASSIC', 'NATURE', 'SPORTS', 'ART',
                                'GRADIENT', 'PATTERN', 'CUSTOM', 'LIMITED_EDITION'
                            )),
    tags                    TEXT[],
    is_active               BOOLEAN         NOT NULL DEFAULT TRUE,
    is_default              BOOLEAN         NOT NULL DEFAULT FALSE,
    download_count          INTEGER         NOT NULL DEFAULT 0,
    created_by              VARCHAR(100),
    created_at              TIMESTAMPTZ     NOT NULL DEFAULT now(),
    updated_at              TIMESTAMPTZ     NOT NULL DEFAULT now(),

    UNIQUE (template_name, version)
);

CREATE INDEX idx_templates_active       ON design.design_templates (is_active);
CREATE INDEX idx_templates_category     ON design.design_templates (category);
CREATE INDEX idx_templates_product_class ON design.design_templates USING GIN (compatible_product_classes);
CREATE INDEX idx_templates_tags         ON design.design_templates USING GIN (tags);

COMMENT ON TABLE design.design_templates IS
    'Catalog of card visual templates available for customer personalization in NovoCard.';
COMMENT ON COLUMN design.design_templates.compatible_product_classes IS
    'Array of product classes that can use this template (e.g. ARRAY[''CREDIT'', ''DEBIT'']).';
COMMENT ON COLUMN design.design_templates.is_default IS
    'When TRUE this template is auto-assigned during card issuance if no design is selected.';
COMMENT ON COLUMN design.design_templates.download_count IS
    'Running count of how many cards have been issued with this template.';
