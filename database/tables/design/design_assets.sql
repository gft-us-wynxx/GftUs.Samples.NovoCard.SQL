-- =============================================================================
-- Table: design.design_assets
-- Application: NovoCard
-- Description: Digital asset registry for each design template. A template is
--              composed of multiple layered assets (background, logo, icon, etc.)
--              stored in object storage and referenced here with their
--              dimensions, format, and rendering role.
-- =============================================================================

CREATE TABLE IF NOT EXISTS design.design_assets (
    asset_id            UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    template_id         UUID            NOT NULL
                            REFERENCES design.design_templates (template_id) ON DELETE CASCADE,
    asset_name          VARCHAR(100)    NOT NULL,
    asset_type          VARCHAR(30)     NOT NULL
                            CHECK (asset_type IN (
                                'BACKGROUND', 'LOGO', 'ICON', 'OVERLAY',
                                'TEXTURE', 'SIGNATURE_STRIP', 'CHIP_AREA', 'HOLOGRAM'
                            )),
    asset_url           VARCHAR(500)    NOT NULL,
    cdn_url             VARCHAR(500),
    file_format         VARCHAR(10)     NOT NULL
                            CHECK (file_format IN ('PNG', 'SVG', 'JPEG', 'WEBP', 'PDF')),
    width_px            SMALLINT,
    height_px           SMALLINT,
    file_size_kb        INTEGER,
    dpi                 SMALLINT        NOT NULL DEFAULT 300,
    color_profile       VARCHAR(10)     NOT NULL DEFAULT 'sRGB'
                            CHECK (color_profile IN ('sRGB', 'CMYK', 'P3')),
    z_order             SMALLINT        NOT NULL DEFAULT 0,
    is_print_ready      BOOLEAN         NOT NULL DEFAULT FALSE,
    checksum_sha256     CHAR(64),
    uploaded_by         VARCHAR(100),
    created_at          TIMESTAMPTZ     NOT NULL DEFAULT now(),
    updated_at          TIMESTAMPTZ     NOT NULL DEFAULT now()
);

CREATE INDEX idx_design_assets_template_id  ON design.design_assets (template_id);
CREATE INDEX idx_design_assets_asset_type   ON design.design_assets (asset_type);

COMMENT ON TABLE design.design_assets IS
    'Individual digital assets (layers) that compose each card design template.';
COMMENT ON COLUMN design.design_assets.z_order IS
    'Rendering stack order. Higher values render on top of lower values.';
COMMENT ON COLUMN design.design_assets.dpi IS
    'Dots per inch. Physical card print requires minimum 300 DPI.';
COMMENT ON COLUMN design.design_assets.is_print_ready IS
    'TRUE when the asset has passed pre-press quality validation for physical card production.';
COMMENT ON COLUMN design.design_assets.color_profile IS
    'sRGB for digital/virtual cards; CMYK for physical print production; P3 for premium displays.';
