# card.vw_transaction_summary

## Overview

View that provides a **monthly spending summary per card**, aggregating information by transaction type and merchant category code (MCC). This structure feeds the **spending analysis dashboard** of the NovoCard app and the **batch statement generation process**.

**Application:** NovoCard
**Schema:** card
**Type:** View (derived data structure)

---

## Data Sources

| Table | Alias | Description |
|---|---|---|
| `card.transactions` | `t` | Card transactions |
| `card.cards` | `c` | Card registry |
| `card.card_types` | `ct` | Card types/products |

### Relationships

| Source | Destination | Condition |
|---|---|---|
| `card.transactions` | `card.cards` | `c.card_id = t.card_id` |
| `card.cards` | `card.card_types` | `ct.card_type_id = c.card_type_id` |

---

## Applied Filters

Only transactions with the following statuses are included:

| Status | Description |
|---|---|
| `POSTED` | Settled transactions |
| `REVERSED` | Reversed/refunded transactions |
| `DISPUTED` | Transactions under dispute |

---

## Returned Columns

### Identification

| Column | Description |
|---|---|
| `card_id` | Card identifier |
| `customer_id` | Customer identifier |
| `masked_pan` | Masked card number |
| `last_four_digits` | Last four digits of the card |
| `product_class` | Product class (e.g., Credit, Prepaid) |
| `network` | Card network |

### Grouping Dimensions

| Column | Description |
|---|---|
| `statement_month` | First day of the reference month (truncation of the authorization date) |
| `transaction_type` | Transaction type (e.g., purchase, withdrawal) |
| `merchant_category_code` | Merchant category code (MCC) |
| `billing_currency` | Billing currency |

### Volume and Amount Metrics

| Column | Description |
|---|---|
| `transaction_count` | Total number of transactions |
| `total_amount` | Total amount of transactions |
| `avg_amount` | Average amount per transaction |
| `max_single_transaction` | Highest amount in a single transaction |
| `first_transaction_at` | Date/time of the first transaction in the period |
| `last_transaction_at` | Date/time of the last transaction in the period |

### Channel Counters

| Column | Description |
|---|---|
| `online_count` | Number of online transactions |
| `international_count` | Number of international transactions |
| `contactless_count` | Number of contactless transactions |
| `reversal_count` | Number of reversed transactions |
| `dispute_count` | Number of disputed transactions |

---

## Granularity

Each row in the view represents the unique combination of:

**Card → Reference month → Transaction type → Merchant category → Billing currency**

---

## Insights

- The `statement_month` column is calculated using `DATEADD/DATEDIFF` to truncate the date to the first day of the month, ensuring broad compatibility across different SQL Server versions.
- The channel counters (`online_count`, `international_count`, `contactless_count`) enable card usage behavior analysis without querying the source transaction table.
- Including transactions with `REVERSED` and `DISPUTED` status alongside `POSTED` allows view consumers to calculate net amounts (total minus reversals and disputes) according to the report's needs.
- The presence of `reversal_count` and `dispute_count` as separate columns enables operational quality and risk indicators per card/month.
- The view centralizes data from three distinct tables, serving as an abstraction layer for both the real-time dashboard and the statement batch process, reducing business logic duplication.
