-- =============================================================================
-- Table: design.design_templates
-- Application: NovoCard
-- Description: Master catalog of card design templates managed by the NovoCard
--              design team. Templates define the visual shell that customers
--              can personalize. Each template is versioned; new versions do
--              not invalidate existing card designs that reference older versions.
--
-- Notes:
--   compatible_product_classes and compatible_networks are stored as JSON arrays
--   (NVARCHAR(MAX)) e.g. '["CREDIT","DEBIT"]'. Use OPENJSON() to query them.
--   tags is also a JSON array e.g. '["travel","dark","minimalist"]'.
--   download_count is a running count of how many cards have used this template.
--   is_default: when 1 this template is auto-assigned during card issuance if no
--   design is selected.
-- =============================================================================

IF OBJECT_ID('design.design_templates', 'U') IS NULL
CREATE TABLE design.design_templates (
    template_id                 UNIQUEIDENTIFIER    NOT NULL CONSTRAINT pk_design_templates PRIMARY KEY DEFAULT NEWID(),
    template_name               NVARCHAR(100)       NOT NULL,
    display_name                NVARCHAR(100)       NOT NULL,
    version                     SMALLINT            NOT NULL DEFAULT 1,
    description                 NVARCHAR(MAX)       NULL,

    -- Compatibility stored as JSON arrays; use OPENJSON() to filter
    compatible_product_classes  NVARCHAR(MAX)       NOT NULL DEFAULT N'["CREDIT","DEBIT","PREPAID"]',
    compatible_networks         NVARCHAR(MAX)       NOT NULL DEFAULT N'["VISA","MASTERCARD","DISCOVER","AMEX"]',

    -- Visual properties
    primary_color               NCHAR(7)            NULL,   -- HEX e.g. #1A2B3C
    secondary_color             NCHAR(7)            NULL,
    base_image_url              NVARCHAR(500)       NOT NULL,
    thumbnail_url               NVARCHAR(500)       NULL,
    is_dark_theme               BIT                 NOT NULL DEFAULT 0,

    -- Metadata
    category                    NVARCHAR(50)        NULL
                                    CONSTRAINT chk_template_category CHECK (category IN (
                                        N'CLASSIC', N'NATURE', N'SPORTS', N'ART',
                                        N'GRADIENT', N'PATTERN', N'CUSTOM', N'LIMITED_EDITION'
                                    )),
    tags                        NVARCHAR(MAX)       NULL,   -- JSON array of tag strings
    is_active                   BIT                 NOT NULL DEFAULT 1,
    is_default                  BIT                 NOT NULL DEFAULT 0,
    download_count              INT                 NOT NULL DEFAULT 0,
    created_by                  NVARCHAR(100)       NULL,
    created_at                  DATETIMEOFFSET      NOT NULL DEFAULT SYSDATETIMEOFFSET(),
    updated_at                  DATETIMEOFFSET      NOT NULL DEFAULT SYSDATETIMEOFFSET(),

    CONSTRAINT uq_template_name_version UNIQUE (template_name, version)
);
GO

CREATE INDEX idx_templates_active   ON design.design_templates (is_active);
CREATE INDEX idx_templates_category ON design.design_templates (category);
GO
