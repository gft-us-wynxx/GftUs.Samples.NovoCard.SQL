# customer.vw_customer_card_portfolio

## Overview

**View** data structure belonging to the `customer` schema in the **NovoCard** application. Consolidates card portfolio information at the customer level, presenting card counts by product class, total credit exposure, and KYC and registration status context. Used by **CRM** and **Risk** teams.

---

## Source Tables

| Alias | Table | Schema | Join Type | Relationship Key |
|-------|-------|--------|-----------|-----------------|
| `cust` | `customers` | `customer` | Main table | — |
| `c` | `cards` | `card` | LEFT JOIN | `c.customer_id = cust.customer_id` |
| `ct` | `card_types` | `card` | LEFT JOIN | `ct.card_type_id = c.card_type_id` |
| `ca` | `card_accounts` | `card` | LEFT JOIN | `ca.card_id = c.card_id` |

The use of `LEFT JOIN` ensures all customers are returned, including those without any linked cards.

---

## Returned Columns

### Customer Registration Data

| Column | Description |
|--------|-------------|
| `customer_id` | Unique customer identifier |
| `full_name` | Full name |
| `email` | Email address |
| `kyc_status` | Know Your Customer verification status |
| `customer_status` | Customer registration status |
| `credit_score` | Credit score |
| `income_range` | Self-declared income bracket |

### Card Count by Product Class

| Column | Description |
|--------|-------------|
| `total_cards` | Total number of cards linked to the customer (all statuses) |
| `active_credit_cards` | Number of **credit** cards with active status |
| `active_debit_cards` | Number of **debit** cards with active status |
| `active_prepaid_cards` | Number of **prepaid** cards with active status |

### Credit Exposure

| Column | Description |
|--------|-------------|
| `total_credit_limit` | Sum of credit limits across all credit cards |
| `total_credit_utilized` | Sum of utilized balances on credit cards |
| `total_credit_available` | Sum of available credit on credit cards |

### Prepaid Balances

| Column | Description |
|--------|-------------|
| `total_prepaid_balance` | Sum of balances on prepaid cards |

### Activity and Dates

| Column | Description |
|--------|-------------|
| `last_card_used_at` | Date/time of the last use of any of the customer's cards |
| `onboarded_at` | Customer onboarding/registration date |
| `last_login_at` | Date/time of the customer's last login |

---

## Product Classes Considered

| Class | Description |
|-------|-------------|
| `CREDIT` | Credit card |
| `DEBIT` | Debit card |
| `PREPAID` | Prepaid card |

---

## Business Rules

1. **Active card count**: only cards with `status = 'ACTIVE'` are counted in the columns segmented by product class. The `total_cards` column counts all cards regardless of status.
2. **Credit exposure**: calculated exclusively for `CREDIT` class cards, without a status filter — meaning it includes blocked or cancelled credit cards that still carry a balance.
3. **Prepaid balance**: aggregated for all `PREPAID` class cards, also without a status filter.
4. **Null handling**: financial columns use `COALESCE(..., 0)` to ensure customers without cards of the respective class return zero instead of null.

---

## Insights

- The view provides a **360° view of each customer's card portfolio**, serving as a centralized source for CRM dashboards and risk reports.
- The inclusion of `credit_score` and `income_range` alongside credit exposure enables **risk concentration** and **limit adequacy** analysis directly from this view.
- The comparison between `total_credit_limit` and `total_credit_utilized` enables the calculation of the **credit utilization rate**, a fundamental metric for risk management.
- The presence of `kyc_status` allows quickly filtering customers with pending regulatory issues who have active credit exposure.
- The `last_card_used_at` and `last_login_at` columns enable identifying **inactive** customers or those at churn risk, supporting retention campaigns.
- Inactive, blocked, or cancelled credit cards **are included** in the financial exposure totals, which is relevant for collection and provisioning scenarios.
- There is no financial metric segmentation for **debit** cards, indicating that these cards do not carry a managed balance or limit in this model.
