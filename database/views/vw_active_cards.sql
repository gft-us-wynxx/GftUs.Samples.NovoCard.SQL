-- =============================================================================
-- View: card.vw_active_cards
-- Application: NovoCard
-- Description: Returns all cards currently in an operable state (ACTIVE).
--              Joins card details with account balances and the current design.
--              Used by the mobile app home screen and customer service dashboards.
-- =============================================================================

CREATE OR ALTER VIEW card.vw_active_cards AS
SELECT
    c.card_id,
    c.customer_id,
    c.masked_pan,
    c.card_holder_name,
    c.last_four_digits,
    c.expiry_month,
    c.expiry_year,
    c.expires_at,
    c.card_format,
    c.is_contactless,
    c.is_online_enabled,
    c.is_international,
    c.status,
    c.activated_at,
    c.last_used_at,

    -- Card type
    ct.type_name                AS card_type_name,
    ct.product_class,
    ct.network,
    ct.tier,

    -- Account financials
    ca.currency,
    ca.credit_limit,
    ca.available_balance,
    ca.balance,
    ca.pending_amount,
    ca.due_date,

    -- Current design
    dt.display_name             AS template_name,
    dt.thumbnail_url            AS design_thumbnail_url,
    dt.primary_color            AS design_primary_color

FROM card.cards c
INNER JOIN card.card_types ct
    ON ct.card_type_id = c.card_type_id
INNER JOIN card.card_accounts ca
    ON ca.card_id = c.card_id
LEFT JOIN design.card_designs cd
    ON cd.card_id = c.card_id AND cd.is_current = 1 AND cd.approval_status = N'APPROVED'
LEFT JOIN design.design_templates dt
    ON dt.template_id = cd.template_id
WHERE
    c.status = N'ACTIVE'
    AND c.expires_at > SYSDATETIMEOFFSET();
GO
