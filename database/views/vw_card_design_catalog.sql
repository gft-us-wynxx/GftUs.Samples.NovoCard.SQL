-- =============================================================================
-- View: design.vw_card_design_catalog
-- Application: NovoCard
-- Description: Public-facing design catalog used by the card personalization
--              UI. Returns active templates enriched with asset counts and
--              popularity metrics. Excludes retired or inactive templates.
-- =============================================================================

CREATE OR REPLACE VIEW design.vw_card_design_catalog AS
SELECT
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

    -- Asset composition
    COUNT(da.asset_id)                                          AS total_assets,
    COUNT(da.asset_id) FILTER (WHERE da.is_print_ready = TRUE)  AS print_ready_assets,
    BOOL_AND(da.is_print_ready)                                 AS is_fully_print_ready,

    -- In-use stats
    COUNT(DISTINCT cd.card_id) FILTER (
        WHERE cd.is_current = TRUE
        AND cd.approval_status = 'APPROVED')                    AS cards_currently_using,

    dt.created_at,
    dt.updated_at

FROM design.design_templates dt
LEFT JOIN design.design_assets da
    ON da.template_id = dt.template_id
LEFT JOIN design.card_designs cd
    ON cd.template_id = dt.template_id
WHERE
    dt.is_active = TRUE
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
    dt.updated_at
ORDER BY
    dt.download_count DESC,
    dt.display_name;

COMMENT ON VIEW design.vw_card_design_catalog IS
    'Active template catalog with asset composition and popularity metrics for the NovoCard design picker UI.';
