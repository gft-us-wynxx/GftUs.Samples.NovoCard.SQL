# card.card_accounts

## Overview

Data structure belonging to the **NovoCard** application representing the financial account state associated with each card. This table stores balance, credit limit, pending amounts, and billing data for the different card types supported:

| Card Type  | Behavior                                                                               |
|------------|----------------------------------------------------------------------------------------|
| **Credit** | Tracks credit limit and utilized amount                                                |
| **Prepaid**| Tracks loaded balance                                                                  |
| **Debit**  | Reflects a snapshot of the linked checking account balance, updated asynchronously     |

---

## Data Structure

### Schema and Location

- **Schema:** `card`
- **Table:** `card_accounts`
- **Type:** Relational table (data structure)

### Columns

| Column               | Type             | Required | Default               | Description                                                                                       |
|----------------------|------------------|----------|-----------------------|---------------------------------------------------------------------------------------------------|
| `account_id`         | UNIQUEIDENTIFIER | Yes      | `NEWID()`             | Unique account identifier                                                                         |
| `card_id`            | UNIQUEIDENTIFIER | Yes      | —                     | Reference to the associated card                                                                  |
| `currency`           | NCHAR(3)         | Yes      | `USD`                 | Currency code (ISO 4217)                                                                          |
| `balance`            | DECIMAL(15,2)    | Yes      | 0.00                  | Current account balance                                                                           |
| `credit_limit`       | DECIMAL(15,2)    | Yes      | 0.00                  | Granted credit limit                                                                              |
| `available_balance`  | DECIMAL(15,2)    | Yes      | 0.00                  | Real-time spendable amount (limit − utilized − pending)                                           |
| `pending_amount`     | DECIMAL(15,2)    | Yes      | 0.00                  | Authorization holds not yet cleared as posted transactions                                        |
| `statement_balance`  | DECIMAL(15,2)    | Yes      | 0.00                  | Balance captured at last statement close; basis for minimum payment calculation                   |
| `minimum_payment`    | DECIMAL(15,2)    | Yes      | 0.00                  | Minimum payment amount due                                                                        |
| `due_date`           | DATE             | No       | NULL                  | Statement due date                                                                                |
| `last_statement_date`| DATE             | No       | NULL                  | Date of the last statement close                                                                  |
| `last_payment_date`  | DATETIMEOFFSET   | No       | NULL                  | Date/time of the last payment made                                                                |
| `last_payment_amount`| DECIMAL(15,2)    | No       | NULL                  | Amount of the last payment made                                                                   |
| `updated_at`         | DATETIMEOFFSET   | Yes      | `SYSDATETIMEOFFSET()` | Last update timestamp                                                                             |

### Primary Key

| Constraint        | Column       |
|-------------------|--------------|
| `pk_card_accounts`| `account_id` |

### Relationships

| Constraint             | Column    | Referenced Table | Referenced Column | Delete Behavior |
|------------------------|-----------|------------------|-------------------|-----------------|
| `uq_card_accounts_card`| `card_id` | `card.cards`     | `card_id`         | CASCADE         |

The `uq_card_accounts_card` constraint also guarantees **uniqueness**, ensuring each card has at most one financial account.

### Validation Rules (CHECK Constraints)

| Constraint                       | Rule                                   | Purpose                                           |
|----------------------------------|----------------------------------------|---------------------------------------------------|
| `chk_credit_limit_non_negative`  | `credit_limit >= 0`                    | Prevents negative credit limit                    |
| `chk_available_balance_range`    | `available_balance <= credit_limit`    | Ensures available balance does not exceed limit   |
| `chk_pending_non_negative`       | `pending_amount >= 0`                  | Prevents negative pending amount                  |

### Indexes

| Index                       | Column     | Purpose                                                    |
|-----------------------------|------------|------------------------------------------------------------|
| `idx_card_accounts_card_id` | `card_id`  | Optimizes queries by card                                  |
| `idx_card_accounts_due_date`| `due_date` | Optimizes queries by due date (e.g., billing, alerts)      |

---

## Insights

- Table creation is **idempotent** — it only executes if the table does not already exist, preventing errors on script re-runs.
- The `available_balance` field represents the amount actually available for spending, already discounting pending authorizations — essential for real-time transaction approval decisions.
- The `statement_balance` field serves as the basis for minimum payment calculation, decoupling the statement balance from the current balance that continues to be updated.
- The index on `due_date` suggests the existence of batch processes or notification routines that query accounts by proximity to their due date.
- Cascade delete via `card_id` ensures that removing a card from `card.cards` automatically removes its financial account, maintaining referential integrity.
- The use of `DATETIMEOFFSET` on timestamp fields indicates support for multiple time zones, relevant for international operations or precise audit records.
