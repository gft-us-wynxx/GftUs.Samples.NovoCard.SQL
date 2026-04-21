-- =============================================================================
-- View: card.vw_transaction_summary
-- Application: NovoCard
-- Description: Monthly spending summary per card, aggregated by transaction
--              type and merchant category. Powers the spending analytics
--              dashboard in the NovoCard app and the statement generation
--              batch process.
-- =============================================================================

CREATE OR ALTER VIEW card.vw_transaction_summary AS
SELECT
    t.card_id,
    c.customer_id,
    c.masked_pan,
    c.last_four_digits,
    ct.product_class,
    ct.network,

    -- Truncate to start of month; use DATEADD/DATEDIFF for broad SQL Server compatibility
    DATEADD(month, DATEDIFF(month, 0, t.authorized_at), 0)  AS statement_month,
    t.transaction_type,
    t.merchant_category_code,
    t.billing_currency,

    COUNT(*)                                                AS transaction_count,
    SUM(t.amount)                                           AS total_amount,
    AVG(t.amount)                                           AS avg_amount,
    MAX(t.amount)                                           AS max_single_transaction,
    MIN(t.authorized_at)                                    AS first_transaction_at,
    MAX(t.authorized_at)                                    AS last_transaction_at,

    SUM(CASE WHEN t.is_online       = 1 THEN 1 ELSE 0 END) AS online_count,
    SUM(CASE WHEN t.is_international = 1 THEN 1 ELSE 0 END) AS international_count,
    SUM(CASE WHEN t.is_contactless  = 1 THEN 1 ELSE 0 END) AS contactless_count,
    SUM(CASE WHEN t.status = N'REVERSED' THEN 1 ELSE 0 END) AS reversal_count,
    SUM(CASE WHEN t.status = N'DISPUTED' THEN 1 ELSE 0 END) AS dispute_count

FROM card.transactions t
INNER JOIN card.cards c
    ON c.card_id = t.card_id
INNER JOIN card.card_types ct
    ON ct.card_type_id = c.card_type_id
WHERE
    t.status IN (N'POSTED', N'REVERSED', N'DISPUTED')
GROUP BY
    t.card_id,
    c.customer_id,
    c.masked_pan,
    c.last_four_digits,
    ct.product_class,
    ct.network,
    DATEADD(month, DATEDIFF(month, 0, t.authorized_at), 0),
    t.transaction_type,
    t.merchant_category_code,
    t.billing_currency;
GO
