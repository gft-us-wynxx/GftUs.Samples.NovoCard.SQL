-- =============================================================================
-- View: design.vw_card_design_catalog
-- Application: NovoCard
-- Description: Public-facing design catalog used by the card personalization
--              UI. Returns active templates enriched with asset counts and
--              popularity metrics. Excludes retired or inactive templates.
-- =============================================================================

CREATE OR ALTER VIEW design.vw_card_design_catalog AS
SELECT
    dt.template_id,
    dt.template_name,
    dt.display_name,
    dt.version,
    dt.description,
    dt.category,
    dt.tags,                            -- JSON array of tag strings
    dt.primary_color,
    dt.secondary_color,
    dt.base_image_url,
    dt.thumbnail_url,
    dt.is_dark_theme,
    dt.is_default,
    dt.compatible_product_classes,      -- JSON array
    dt.compatible_networks,             -- JSON array
    dt.download_count,

    -- Asset composition
    COUNT(da.asset_id)                                                      AS total_assets,
    SUM(CASE WHEN da.is_print_ready = 1 THEN 1 ELSE 0 END)                 AS print_ready_assets,
    -- 1 when every asset in the template is print-ready, 0 if any are not
    CAST(MIN(CAST(da.is_print_ready AS INT)) AS BIT)                        AS is_fully_print_ready,

    -- In-use stats: distinct cards that currently use this template with an approved design
    COUNT(DISTINCT CASE WHEN cd.is_current = 1 AND cd.approval_status = N'APPROVED'
                        THEN cd.card_id END)                                AS cards_currently_using,

    dt.created_at,
    dt.updated_at

FROM design.design_templates dt
LEFT JOIN design.design_assets da
    ON da.template_id = dt.template_id
LEFT JOIN design.card_designs cd
    ON cd.template_id = dt.template_id
WHERE
    dt.is_active = 1
GROUP BY
    dt.template_id,
    dt.template_name,
    dt.display_name,
    dt.version,
    dt.description,
    dt.category,
    dt.tags,
    dt.primary_color,
    dt.secondary_color,
    dt.base_image_url,
    dt.thumbnail_url,
    dt.is_dark_theme,
    dt.is_default,
    dt.compatible_product_classes,
    dt.compatible_networks,
    dt.download_count,
    dt.created_at,
    dt.updated_at;
GO
