-- =============================================================================
-- View: customer.vw_customer_card_portfolio
-- Application: NovoCard
-- Description: Aggregated customer-level portfolio showing how many cards of
--              each product class a customer holds, total credit exposure,
--              and overall KYC and status context. Used by CRM and risk teams.
-- =============================================================================

CREATE OR ALTER VIEW customer.vw_customer_card_portfolio AS
SELECT
    cust.customer_id,
    cust.full_name,
    cust.email,
    cust.kyc_status,
    cust.status                                     AS customer_status,
    cust.credit_score,
    cust.income_range,

    -- Card counts by product class
    COUNT(c.card_id)                                AS total_cards,
    SUM(CASE WHEN ct.product_class = N'CREDIT'  AND c.status = N'ACTIVE' THEN 1 ELSE 0 END) AS active_credit_cards,
    SUM(CASE WHEN ct.product_class = N'DEBIT'   AND c.status = N'ACTIVE' THEN 1 ELSE 0 END) AS active_debit_cards,
    SUM(CASE WHEN ct.product_class = N'PREPAID' AND c.status = N'ACTIVE' THEN 1 ELSE 0 END) AS active_prepaid_cards,

    -- Credit exposure
    COALESCE(SUM(CASE WHEN ct.product_class = N'CREDIT' THEN ca.credit_limit    END), 0) AS total_credit_limit,
    COALESCE(SUM(CASE WHEN ct.product_class = N'CREDIT' THEN ca.balance         END), 0) AS total_credit_utilized,
    COALESCE(SUM(CASE WHEN ct.product_class = N'CREDIT' THEN ca.available_balance END), 0) AS total_credit_available,

    -- Prepaid balances
    COALESCE(SUM(CASE WHEN ct.product_class = N'PREPAID' THEN ca.balance END), 0)        AS total_prepaid_balance,

    -- Activity
    MAX(c.last_used_at)                             AS last_card_used_at,
    cust.onboarded_at,
    cust.last_login_at

FROM customer.customers cust
LEFT JOIN card.cards c
    ON c.customer_id = cust.customer_id
LEFT JOIN card.card_types ct
    ON ct.card_type_id = c.card_type_id
LEFT JOIN card.card_accounts ca
    ON ca.card_id = c.card_id
GROUP BY
    cust.customer_id,
    cust.full_name,
    cust.email,
    cust.kyc_status,
    cust.status,
    cust.credit_score,
    cust.income_range,
    cust.onboarded_at,
    cust.last_login_at;
GO
