-- =============================================================================
-- View: customer.vw_customer_card_portfolio
-- Application: NovoCard
-- Description: Aggregated customer-level portfolio showing how many cards of
--              each product class a customer holds, total credit exposure,
--              and overall KYC and status context. Used by CRM and risk teams.
-- =============================================================================

CREATE OR REPLACE VIEW customer.vw_customer_card_portfolio AS
SELECT
    cust.customer_id,
    cust.full_name,
    cust.email,
    cust.kyc_status,
    cust.status                         AS customer_status,
    cust.credit_score,
    cust.income_range,

    -- Card counts by product class
    COUNT(c.card_id)                    AS total_cards,
    COUNT(c.card_id) FILTER (
        WHERE ct.product_class = 'CREDIT'
        AND c.status = 'ACTIVE')        AS active_credit_cards,
    COUNT(c.card_id) FILTER (
        WHERE ct.product_class = 'DEBIT'
        AND c.status = 'ACTIVE')        AS active_debit_cards,
    COUNT(c.card_id) FILTER (
        WHERE ct.product_class = 'PREPAID'
        AND c.status = 'ACTIVE')        AS active_prepaid_cards,

    -- Credit exposure
    COALESCE(SUM(ca.credit_limit)
        FILTER (WHERE ct.product_class = 'CREDIT'), 0)
                                        AS total_credit_limit,
    COALESCE(SUM(ca.balance)
        FILTER (WHERE ct.product_class = 'CREDIT'), 0)
                                        AS total_credit_utilized,
    COALESCE(SUM(ca.available_balance)
        FILTER (WHERE ct.product_class = 'CREDIT'), 0)
                                        AS total_credit_available,

    -- Prepaid balances
    COALESCE(SUM(ca.balance)
        FILTER (WHERE ct.product_class = 'PREPAID'), 0)
                                        AS total_prepaid_balance,

    -- Activity
    MAX(c.last_used_at)                 AS last_card_used_at,
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

COMMENT ON VIEW customer.vw_customer_card_portfolio IS
    'Per-customer summary of card holdings, credit exposure, and prepaid balances. Used by CRM and risk systems.';
