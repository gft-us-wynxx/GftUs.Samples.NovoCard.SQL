-- =============================================================================
-- Table: design.design_assets
-- Application: NovoCard
-- Description: Digital asset registry for each design template. A template is
--              composed of multiple layered assets (background, logo, icon, etc.)
--              stored in object storage and referenced here with their
--              dimensions, format, and rendering role.
--
-- Notes:
--   z_order: rendering stack order; higher values render on top of lower values.
--   dpi: physical card print requires minimum 300 DPI.
--   is_print_ready: 1 when asset passed pre-press quality validation.
--   color_profile: sRGB for digital/virtual cards; CMYK for physical print; P3 for premium displays.
-- =============================================================================

IF OBJECT_ID('design.design_assets', 'U') IS NULL
CREATE TABLE design.design_assets (
    asset_id            UNIQUEIDENTIFIER    NOT NULL CONSTRAINT pk_design_assets PRIMARY KEY DEFAULT NEWID(),
    template_id         UNIQUEIDENTIFIER    NOT NULL
                            CONSTRAINT fk_assets_template REFERENCES design.design_templates (template_id) ON DELETE CASCADE,
    asset_name          NVARCHAR(100)       NOT NULL,
    asset_type          NVARCHAR(30)        NOT NULL
                            CONSTRAINT chk_asset_type CHECK (asset_type IN (
                                N'BACKGROUND', N'LOGO', N'ICON', N'OVERLAY',
                                N'TEXTURE', N'SIGNATURE_STRIP', N'CHIP_AREA', N'HOLOGRAM'
                            )),
    asset_url           NVARCHAR(500)       NOT NULL,
    cdn_url             NVARCHAR(500)       NULL,
    file_format         NVARCHAR(10)        NOT NULL
                            CONSTRAINT chk_asset_format CHECK (file_format IN (
                                N'PNG', N'SVG', N'JPEG', N'WEBP', N'PDF'
                            )),
    width_px            SMALLINT            NULL,
    height_px           SMALLINT            NULL,
    file_size_kb        INT                 NULL,
    dpi                 SMALLINT            NOT NULL DEFAULT 300,
    color_profile       NVARCHAR(10)        NOT NULL DEFAULT N'sRGB'
                            CONSTRAINT chk_asset_color_profile CHECK (color_profile IN (N'sRGB', N'CMYK', N'P3')),
    z_order             SMALLINT            NOT NULL DEFAULT 0,
    is_print_ready      BIT                 NOT NULL DEFAULT 0,
    checksum_sha256     NCHAR(64)           NULL,
    uploaded_by         NVARCHAR(100)       NULL,
    created_at          DATETIMEOFFSET      NOT NULL DEFAULT SYSDATETIMEOFFSET(),
    updated_at          DATETIMEOFFSET      NOT NULL DEFAULT SYSDATETIMEOFFSET()
);
GO

CREATE INDEX idx_design_assets_template_id  ON design.design_assets (template_id);
CREATE INDEX idx_design_assets_asset_type   ON design.design_assets (asset_type);
GO
