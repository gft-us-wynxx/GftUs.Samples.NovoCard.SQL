# Documentation: Card Type Catalog — `card.card_types`

## Overview

Data structure belonging to the **NovoCard** application representing the catalog of card products offered by the institution. Each record defines a unique combination of **product class** (Credit, Debit, or Prepaid), **payment network**, and **tier**, determining card behavior, fees, and default limits.

---

## Data Structure

### Table: `card.card_types`

| Column                 | Type           | Required | Description                                                                          |
|------------------------|----------------|----------|--------------------------------------------------------------------------------------|
| `card_type_id`         | INT (Identity) | Yes      | Unique card type identifier (primary key, auto-increment)                            |
| `type_name`            | NVARCHAR(50)   | Yes      | Unique name for the card type                                                        |
| `product_class`        | NVARCHAR(10)   | Yes      | Product class: **CREDIT**, **DEBIT**, or **PREPAID**                                |
| `network`              | NVARCHAR(20)   | Yes      | Payment network: **VISA**, **MASTERCARD**, **DISCOVER**, **AMEX**, or **UNIONPAY**  |
| `tier`                 | NVARCHAR(20)   | Yes      | Card tier: **STANDARD**, **GOLD**, **PLATINUM**, **BLACK**, or **INFINITE**. Default: STANDARD |
| `annual_fee`           | DECIMAL(10,2)  | Yes      | Annual fee charged for the card. Default: 0.00                                       |
| `minimum_income`       | DECIMAL(12,2)  | No       | Minimum income required for eligibility                                              |
| `minimum_credit_score` | SMALLINT       | No       | Minimum internal credit score for issuance (0–1000). NULL means no restriction      |
| `description`          | NVARCHAR(MAX)  | No       | Textual description of the product                                                   |
| `benefits`             | NVARCHAR(MAX)  | No       | JSON array containing the list of card benefits                                      |
| `is_active`            | BIT            | Yes      | Indicates whether the card type is active for issuance. Default: 1 (active)         |
| `created_at`           | DATETIMEOFFSET | Yes      | Record creation timestamp (auto-populated)                                           |
| `updated_at`           | DATETIMEOFFSET | Yes      | Last update timestamp (auto-populated)                                               |

### Constraints and Rules

| Constraint              | Type        | Description                                                    |
|-------------------------|-------------|----------------------------------------------------------------|
| `pk_card_types`         | Primary Key | Guarantees uniqueness of `card_type_id`                        |
| `uq_card_types_name`    | Unique      | Prevents duplicate card type names                             |
| `chk_card_types_class`  | Check       | Restricts `product_class` to CREDIT, DEBIT, or PREPAID         |
| `chk_card_types_network`| Check       | Restricts `network` to the approved payment networks           |
| `chk_card_types_tier`   | Check       | Restricts `tier` to the defined institution levels             |
| `chk_card_types_min_score` | Check    | Validates that the minimum score is between 0 and 1000         |

---

## Seed Data

The table is pre-populated with **8 card products** that make up the initial NovoCard portfolio:

### Debit Cards

| Name                       | Network    | Tier     | Annual Fee | Description                                              |
|----------------------------|------------|----------|------------|----------------------------------------------------------|
| NOVOCARD_DEBIT_STANDARD    | Mastercard | Standard | $0.00      | Standard debit card linked to checking account           |

### Credit Cards

| Name                       | Network    | Tier     | Annual Fee | Description                                              |
|----------------------------|------------|----------|------------|----------------------------------------------------------|
| NOVOCARD_CREDIT_STANDARD   | Visa       | Standard | $149.90    | Entry-level credit card for new customers                |
| NOVOCARD_CREDIT_GOLD       | Mastercard | Gold     | $299.90    | Gold credit card with travel benefits                    |
| NOVOCARD_CREDIT_PLATINUM   | Visa       | Platinum | $599.90    | Platinum card with concierge and lounge access           |
| NOVOCARD_CREDIT_BLACK      | Mastercard | Black    | $0.00      | Invite-only Black card with unlimited benefits           |

### Prepaid Cards

| Name                       | Network    | Tier     | Annual Fee | Description                                              |
|----------------------------|------------|----------|------------|----------------------------------------------------------|
| NOVOCARD_PREPAID_GIFT      | Discover   | Standard | $0.00      | Single-use prepaid gift card                             |
| NOVOCARD_PREPAID_TRAVEL    | Visa       | Standard | $19.90     | Reloadable multi-currency travel prepaid card            |
| NOVOCARD_PREPAID_CORPORATE | Mastercard | Standard | $0.00      | Corporate expense prepaid card managed by employer       |

---

## Insights

- **Conditional creation**: The table is only created if it does not already exist, ensuring safety in repeated executions (idempotency).
- **Annual fee waiver strategy**: The Black (credit), Debit Standard, Gift, and Corporate cards have zero annual fees, indicating that monetization for these products occurs through other mechanisms (interchange, exclusive invite, corporate fees).
- **Network diversification**: The portfolio distributes products across Visa, Mastercard, and Discover — Amex and UnionPay are approved as valid networks but unused in initial products.
- **Optional eligibility fields**: `minimum_income` and `minimum_credit_score` are not populated in the initial seed, suggesting eligibility rules will be configured later or managed by another module.
- **Benefits in JSON**: The `benefits` field allows flexible benefit definition per product without auxiliary tables, but requires careful validation in the application layer.
- **Unused tier**: The **INFINITE** tier is listed in the validation rule, but no initial product uses it, indicating potential future portfolio expansion.
- **Temporal audit**: The `created_at` and `updated_at` fields use `DATETIMEOFFSET`, ensuring time-zone-aware traceability — essential for multi-region operations.
