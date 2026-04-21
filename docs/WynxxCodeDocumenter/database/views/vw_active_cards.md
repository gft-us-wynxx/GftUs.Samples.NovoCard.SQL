# card.vw_active_cards

## Overview

The **card.vw_active_cards** view belongs to the **NovoCard** application and consolidates all relevant information for cards currently in the **ACTIVE** operational state. It is consumed by the mobile app home screen and customer service dashboards.

---

## Data Structure

This is a **data structure** (view) that contains no procedural logic. It aggregates data from multiple tables into a single query to facilitate consumption by downstream systems.

---

## Tables Involved

| Alias | Table | Schema | Join Type | Purpose |
|-------|-------|--------|-----------|---------|
| `c` | `cards` | `card` | Main table | Card registration data |
| `ct` | `card_types` | `card` | INNER JOIN | Card classification and type |
| `ca` | `card_accounts` | `card` | INNER JOIN | Financial information of the linked account |
| `cd` | `card_designs` | `design` | LEFT JOIN | Visual design currently applied to the card |
| `dt` | `design_templates` | `design` | LEFT JOIN | Design template with colors and thumbnail |

---

## Returned Columns

### Card Data

| Column | Description |
|--------|-------------|
| `card_id` | Unique card identifier |
| `customer_id` | Identifier of the cardholder |
| `masked_pan` | Masked card number |
| `card_holder_name` | Name printed on the card |
| `last_four_digits` | Last four digits of the card |
| `expiry_month` | Expiry month |
| `expiry_year` | Expiry year |
| `expires_at` | Full expiry date/time |
| `card_format` | Card format (physical, virtual, etc.) |
| `is_contactless` | Indicates contactless payment support |
| `is_online_enabled` | Indicates whether enabled for online purchases |
| `is_international` | Indicates whether international transactions are allowed |
| `status` | Card status (always ACTIVE in this view) |
| `activated_at` | Activation date/time |
| `last_used_at` | Last used date/time |

### Card Type

| Column | Source | Description |
|--------|--------|-------------|
| `card_type_name` | `ct.type_name` | Card type name |
| `product_class` | `ct.product_class` | Product class |
| `network` | `ct.network` | Payment network (Visa, Mastercard, etc.) |
| `tier` | `ct.tier` | Card tier (Gold, Platinum, etc.) |

### Financial Information

| Column | Description |
|--------|-------------|
| `currency` | Account currency |
| `credit_limit` | Total credit limit |
| `available_balance` | Balance available for spending |
| `balance` | Current account balance |
| `pending_amount` | Amount of transactions pending settlement |
| `due_date` | Statement due date |

### Visual Design

| Column | Source | Description |
|--------|--------|-------------|
| `template_name` | `dt.display_name` | Design template display name |
| `design_thumbnail_url` | `dt.thumbnail_url` | Card design thumbnail URL |
| `design_primary_color` | `dt.primary_color` | Design primary color for UI rendering |

---

## Filter Criteria

| Condition | Description |
|-----------|-------------|
| `c.status = 'ACTIVE'` | Returns only cards with active status |
| `c.expires_at > SYSDATETIMEOFFSET()` | Excludes already-expired cards based on the current server date/time |
| `cd.is_current = 1` | Considers only the card's currently active design |
| `cd.approval_status = 'APPROVED'` | Considers only approved designs |

---

## Insights

- The joins with the design tables (`card_designs` and `design_templates`) use **LEFT JOIN**, meaning cards without custom designs or without an approved design will still be returned — design columns will be `NULL` in those cases. This is expected, as not every card has visual customization.
- The view combines both status **and** temporal validity checks, ensuring that active but expired cards are not displayed.
- The presence of `pending_amount` alongside `available_balance` and `balance` allows consuming interfaces to present a complete financial view without additional calculations.
- The `last_used_at` column can be used to identify active cards with low usage, useful for engagement strategies.
- The separation of `credit_limit`, `balance`, and `available_balance` indicates that the system supports scenarios where pending authorizations reduce available balance before settlement.
