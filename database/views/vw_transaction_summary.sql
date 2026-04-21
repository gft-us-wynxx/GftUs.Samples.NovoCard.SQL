-- =============================================================================
-- View: card.vw_transaction_summary
-- Application: NovoCard
-- Description: Monthly spending summary per card, aggregated by transaction
--              type and merchant category. Powers the spending analytics
--              dashboard in the NovoCard app and the statement generation
--              batch process.
-- =============================================================================

CREATE OR REPLACE VIEW card.vw_transaction_summary AS
SELECT
    t.card_id,
    c.customer_id,
    c.masked_pan,
    c.last_four_digits,
    ct.product_class,
    ct.network,

    DATE_TRUNC('month', t.authorized_at)    AS statement_month,
    t.transaction_type,
    t.merchant_category_code,
    t.billing_currency,

    COUNT(*)                                AS transaction_count,
    SUM(t.amount)                           AS total_amount,
    AVG(t.amount)                           AS avg_amount,
    MAX(t.amount)                           AS max_single_transaction,
    MIN(t.authorized_at)                    AS first_transaction_at,
    MAX(t.authorized_at)                    AS last_transaction_at,

    COUNT(*) FILTER (WHERE t.is_online = TRUE)          AS online_count,
    COUNT(*) FILTER (WHERE t.is_international = TRUE)   AS international_count,
    COUNT(*) FILTER (WHERE t.is_contactless = TRUE)     AS contactless_count,
    COUNT(*) FILTER (WHERE t.status = 'REVERSED')       AS reversal_count,
    COUNT(*) FILTER (WHERE t.status = 'DISPUTED')       AS dispute_count

FROM card.transactions t
INNER JOIN card.cards c
    ON c.card_id = t.card_id
INNER JOIN card.card_types ct
    ON ct.card_type_id = c.card_type_id
WHERE
    t.status IN ('POSTED', 'REVERSED', 'DISPUTED')
GROUP BY
    t.card_id,
    c.customer_id,
    c.masked_pan,
    c.last_four_digits,
    ct.product_class,
    ct.network,
    DATE_TRUNC('month', t.authorized_at),
    t.transaction_type,
    t.merchant_category_code,
    t.billing_currency;

COMMENT ON VIEW card.vw_transaction_summary IS
    'Monthly per-card spending aggregates by transaction type and MCC. Used for statements and analytics.';
