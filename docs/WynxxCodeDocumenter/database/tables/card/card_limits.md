# card.card_limits — Spending and Withdrawal Velocity Controls per Card

## Overview

Data structure belonging to the **NovoCard** application responsible for storing the **spending and withdrawal velocity limits** associated with each card. Each card has a single active limit profile. Limits can be adjusted by the customer (within the eligibility ceiling) or by risk analysts as part of a fraud response.

---

## Data Structure

### Identification and Relationship

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| `limit_id` | UNIQUEIDENTIFIER | No | `NEWID()` | Unique limit record identifier (primary key) |
| `card_id` | UNIQUEIDENTIFIER | No | — | Reference to the associated card (unique, with cascade delete) |

### Purchase Limits

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| `daily_purchase_limit` | DECIMAL(12,2) | No | 5,000.00 | Daily limit for purchases |
| `monthly_purchase_limit` | DECIMAL(12,2) | No | 30,000.00 | Monthly limit for purchases |

### Withdrawal Limits (ATM / Cash)

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| `daily_withdrawal_limit` | DECIMAL(12,2) | No | 1,500.00 | Daily limit for ATM withdrawals |
| `monthly_withdrawal_limit` | DECIMAL(12,2) | No | 5,000.00 | Monthly limit for ATM withdrawals |

### Channel Limits

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| `online_transaction_limit` | DECIMAL(12,2) | No | 3,000.00 | Limit for online transactions |
| `contactless_limit` | DECIMAL(10,2) | No | 300.00 | Per-tap ceiling (NFC/contactless) without requiring PIN |
| `international_daily_limit` | DECIMAL(12,2) | No | 2,000.00 | Daily limit for international transactions |

### Per-Transaction Limit

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| `single_transaction_limit` | DECIMAL(12,2) | No | 5,000.00 | Maximum amount allowed in a single transaction |

### Source and Temporal Control

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| `set_by` | NVARCHAR(20) | No | `SYSTEM` | Origin of the limit definition |
| `is_temporary` | BIT | No | 0 | Indicates whether the limits are temporary |
| `temporary_until` | DATETIMEOFFSET | Yes | — | Date/time until which temporary limits are valid; after this point, previous values are restored |
| `reason` | NVARCHAR(255) | Yes | — | Justification for the limit change |
| `created_at` | DATETIMEOFFSET | No | `SYSDATETIMEOFFSET()` | Record creation timestamp |
| `updated_at` | DATETIMEOFFSET | No | `SYSDATETIMEOFFSET()` | Last update timestamp |

### Allowed Values for `set_by`

| Value | Meaning |
|-------|---------|
| `SYSTEM` | Limits defined automatically at card issuance |
| `CUSTOMER` | Limits adjusted by the customer via self-service |
| `RISKANALYST` | Limits changed by a risk analyst (compliance/fraud override) |

---

## Constraints and Integrity Rules

| Constraint | Type | Rule |
|------------|------|------|
| `pk_card_limits` | Primary Key | `limit_id` is the unique record identifier |
| `uq_card_limits_card` | Unique + Foreign Key | Each card has at most one limit record; references `card.cards(card_id)` with cascade delete |
| `chk_limits_set_by` | Check | `set_by` must be `SYSTEM`, `CUSTOMER`, or `RISKANALYST` |
| `chk_daily_lte_monthly_purchase` | Check | Daily purchase limit cannot exceed the monthly purchase limit |
| `chk_daily_lte_monthly_withdrawal` | Check | Daily withdrawal limit cannot exceed the monthly withdrawal limit |
| `chk_single_lte_daily` | Check | Per-transaction limit cannot exceed the daily purchase limit |

---

## Indexes

| Index | Column(s) | Purpose |
|-------|-----------|---------|
| `idx_card_limits_card_id` | `card_id` | Optimizes queries by card |

---

## Insights

- **1:1 relationship with the card**: The `UNIQUE` constraint on `card_id` guarantees that each card has exactly one active limit profile, simplifying transaction authorization logic.
- **Cascade delete**: Removing a card from `card.cards` automatically deletes the corresponding limit record, maintaining referential consistency.
- **Limit hierarchy enforced by constraints**: The check rules guarantee at the database level that `single transaction ≤ daily ≤ monthly`, preventing inconsistent configurations regardless of who made the change.
- **Temporary limit mechanism**: The combination of `is_temporary` and `temporary_until` allows risk analysts to reduce limits on an emergency basis with a scheduled automatic reversion — a typical fraud response scenario.
- **Change traceability**: The `set_by` and `reason` fields provide an audit trail of who changed the limits and why, essential for regulatory compliance.
- **Significantly lower contactless limit**: The 300.00 ceiling for tap-based transactions (without PIN) reflects market practice of mitigating risk in transactions without strong authentication.
- **Conditional creation**: The table is only created if it does not already exist, enabling idempotent script execution in continuous deployment environments.
