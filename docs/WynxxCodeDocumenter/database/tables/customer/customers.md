# Documentation — `customer.customers`

## Application

**NovoCard**

---

## Overview

Data structure representing the **core customer registry** of the NovoCard platform. Each record corresponds to a natural person who completed the onboarding process. A customer can hold multiple cards (credit, debit, and/or prepaid) linked to their registration.

---

## Schema and Table

| Schema     | Table       |
|------------|-------------|
| `customer` | `customers` |

---

## Data Structure

### Columns

| Column          | Type                      | Required | Default                  | Description                                                                                      |
|-----------------|---------------------------|----------|--------------------------|--------------------------------------------------------------------------------------------------|
| `customer_id`   | `UNIQUEIDENTIFIER`        | Yes      | `NEWID()`                | Unique customer identifier (primary key).                                                        |
| `first_name`    | `NVARCHAR(100)`           | Yes      | —                        | Customer's first name.                                                                           |
| `last_name`     | `NVARCHAR(100)`           | Yes      | —                        | Customer's last name.                                                                            |
| `full_name`     | Computed column (persisted)| —       | `first_name + ' ' + last_name` | Full name, automatically generated for indexing and display.                            |
| `email`         | `NVARCHAR(255)`           | Yes      | —                        | Customer's email address. Must be unique.                                                        |
| `phone`         | `NVARCHAR(20)`            | No       | —                        | Phone number.                                                                                    |
| `date_of_birth` | `DATE`                    | Yes      | —                        | Date of birth.                                                                                   |
| `taxpayer_id`   | `NVARCHAR(20)`            | Yes      | —                        | SSN or equivalent national tax identifier. Must be unique.                                       |
| `nationality`   | `NCHAR(2)`                | Yes      | `US`                     | Nationality code (2-character ISO standard).                                                     |
| `gender`        | `NCHAR(1)`                | No       | —                        | Self-declared gender.                                                                            |
| `income_range`  | `NVARCHAR(30)`            | No       | —                        | Self-declared monthly income bracket, used in credit limit calculation.                          |
| `credit_score`  | `SMALLINT`                | No       | —                        | Internal NovoCard score (0–1000), derived from bureau data and behavioral signals.               |
| `kyc_status`    | `NVARCHAR(20)`            | Yes      | `PENDING`                | Know Your Customer verification state. Cards can only be issued when status is **APPROVED**.     |
| `status`        | `NVARCHAR(20)`            | Yes      | `ACTIVE`                 | General status of the customer's registration on the platform.                                   |
| `onboarded_at`  | `DATETIMEOFFSET`          | Yes      | `SYSDATETIMEOFFSET()`    | Date/time when the customer completed onboarding.                                                |
| `last_login_at` | `DATETIMEOFFSET`          | No       | —                        | Date/time of the customer's last login.                                                          |
| `created_at`    | `DATETIMEOFFSET`          | Yes      | `SYSDATETIMEOFFSET()`    | Record creation timestamp.                                                                       |
| `updated_at`    | `DATETIMEOFFSET`          | Yes      | `SYSDATETIMEOFFSET()`    | Last update timestamp.                                                                           |

---

### Allowed Values (Domain Constraints)

| Column        | Accepted Values                                                               |
|---------------|-------------------------------------------------------------------------------|
| `gender`      | `M` (Male), `F` (Female), `X` (Other/Non-binary)                             |
| `income_range`| `BELOW_1K`, `1K_3K`, `3K_5K`, `5K_10K`, `10K_20K`, `ABOVE_20K`              |
| `credit_score`| Integer between **0** and **1000**                                            |
| `kyc_status`  | `PENDING`, `IN_REVIEW`, `APPROVED`, `REJECTED`                                |
| `status`      | `ACTIVE`, `SUSPENDED`, `CLOSED`, `BLOCKED`                                    |

---

### Uniqueness Constraints

| Constraint               | Column        | Purpose                                                      |
|--------------------------|---------------|--------------------------------------------------------------|
| `uq_customers_email`     | `email`       | Ensures each email is associated with exactly one customer.  |
| `uq_customers_taxpayer_id` | `taxpayer_id` | Ensures each tax ID is associated with exactly one customer. |

---

### Indexes

| Index                       | Column(s)     | Order       | Purpose                                |
|-----------------------------|---------------|-------------|----------------------------------------|
| `idx_customers_email`       | `email`       | ASC (default)| Fast lookup by email.                 |
| `idx_customers_taxpayer_id` | `taxpayer_id` | ASC (default)| Fast lookup by tax identifier.        |
| `idx_customers_status`      | `status`      | ASC (default)| Filter by registration status.        |
| `idx_customers_kyc_status`  | `kyc_status`  | ASC (default)| Filter by KYC verification state.     |
| `idx_customers_created_at`  | `created_at`  | DESC         | List most recently created customers first. |

---

## Business Rules

1. **Card issuance conditional on KYC**: No card (credit, debit, or prepaid) can be issued to a customer whose `kyc_status` is not `APPROVED`.
2. **Credit limit based on income**: The self-declared income bracket (`income_range`) is one of the inputs for calculating the customer's credit limit.
3. **Internal score**: `credit_score` is a proprietary NovoCard score (0–1000 scale), fed by credit bureau data and the customer's own behavioral signals on the platform.
4. **Conditional creation**: The table is only created if it does not already exist, preventing errors on repeated script executions.

---

## Insights

- The `last_login_at` field being optional suggests that registered customers may not have yet logged in (possibly still in onboarding or enrolled through alternative channels).
- The separation between `onboarded_at` and `created_at` indicates that the technical record may be created at a different moment from onboarding completion, suggesting a multi-step registration flow.
- The descending index on `created_at` reflects frequent queries that prioritize the most recently created customers (dashboards, analysis queues, etc.).
- The `SUSPENDED` and `BLOCKED` statuses represent distinct levels of restriction, which may indicate different severity levels or block reasons (e.g., delinquency vs. fraud).
- The persisted `full_name` column optimizes search and display queries, eliminating the need for runtime concatenation.
