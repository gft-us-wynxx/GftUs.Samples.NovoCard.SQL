# design.design_assets

## General Description

Table for registering digital assets linked to card design templates in the **NovoCard** application. Each card template is composed of multiple visual layers (background, logo, icon, hologram, etc.) stored in object storage and referenced here with their dimensions, format, color profile, and rendering role.

---

## Data Structure

### Columns

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| `asset_id` | UNIQUEIDENTIFIER | No | `NEWID()` | Unique asset identifier |
| `template_id` | UNIQUEIDENTIFIER | No | — | Reference to the design template this asset belongs to |
| `asset_name` | NVARCHAR(100) | No | — | Descriptive name of the asset |
| `asset_type` | NVARCHAR(30) | No | — | Type/role of the asset in the visual composition |
| `asset_url` | NVARCHAR(500) | No | — | Source URL of the file in object storage |
| `cdn_url` | NVARCHAR(500) | Yes | — | CDN distribution URL for optimized delivery |
| `file_format` | NVARCHAR(10) | No | — | Image file format |
| `width_px` | SMALLINT | Yes | — | Width in pixels |
| `height_px` | SMALLINT | Yes | — | Height in pixels |
| `file_size_kb` | INT | Yes | — | File size in kilobytes |
| `dpi` | SMALLINT | No | 300 | Resolution in dots per inch |
| `color_profile` | NVARCHAR(10) | No | `sRGB` | Color profile applied to the asset |
| `z_order` | SMALLINT | No | 0 | Stacking order in rendering (higher values render on top) |
| `is_print_ready` | BIT | No | 0 | Indicates whether the asset passed pre-print quality validation |
| `checksum_sha256` | NCHAR(64) | Yes | — | SHA-256 hash for file integrity verification |
| `uploaded_by` | NVARCHAR(100) | Yes | — | Identifier of the user who performed the upload |
| `created_at` | DATETIMEOFFSET | No | `SYSDATETIMEOFFSET()` | Record creation date/time |
| `updated_at` | DATETIMEOFFSET | No | `SYSDATETIMEOFFSET()` | Last update date/time |

---

### Allowed Values

| Column | Accepted Values |
|--------|----------------|
| `asset_type` | BACKGROUND, LOGO, ICON, OVERLAY, TEXTURE, SIGNATURESTRIP, CHIPAREA, HOLOGRAM |
| `file_format` | PNG, SVG, JPEG, WEBP, PDF |
| `color_profile` | sRGB, CMYK, P3 |

---

### Constraints and Relationships

| Type | Name | Details |
|------|------|---------|
| Primary Key | `pk_design_assets` | `asset_id` |
| Foreign Key | `fk_assets_template` | `template_id` → `design.design_templates(template_id)`, with cascade delete |
| Check | `chk_asset_type` | Restricts values of `asset_type` |
| Check | `chk_asset_format` | Restricts values of `file_format` |
| Check | `chk_asset_color_profile` | Restricts values of `color_profile` |

---

### Indexes

| Name | Column | Purpose |
|------|--------|---------|
| `idx_design_assets_template_id` | `template_id` | Optimizes queries by template |
| `idx_design_assets_asset_type` | `asset_type` | Optimizes queries by asset type |

---

## Business Rules

| Rule | Description |
|------|-------------|
| Minimum resolution for printing | Physical cards require at least 300 DPI |
| Pre-print validation | The `is_print_ready` field is only set to true after the asset passes a quality validation for printing |
| Color profile by channel | **sRGB** for digital/virtual cards; **CMYK** for physical printing; **P3** for premium displays |
| Rendering order | The `z_order` field defines the display layer — higher values are rendered on top of lower values |
| File integrity | The SHA-256 checksum allows verification that the asset has not been corrupted or altered after upload |
| Cascade delete | Removing a template automatically deletes all associated assets |

---

## Insights

- The structure supports layered visual composition, allowing a single card template to be assembled from multiple independent assets, facilitating reuse and customization.
- The separate `cdn_url` from `asset_url` indicates an architecture with a cache/distribution layer to optimize asset delivery across digital channels.
- Support for multiple color profiles (sRGB, CMYK, P3) shows that the platform serves both virtual and physical cards simultaneously, with the possibility of premium variants.
- Asset types include payment card-specific elements (CHIPAREA, SIGNATURESTRIP, HOLOGRAM), demonstrating compliance with visual standards of the payment industry.
- The combination of `checksum_sha256` with `is_print_ready` suggests a governance workflow where assets undergo automated validation before being released for graphic production.
