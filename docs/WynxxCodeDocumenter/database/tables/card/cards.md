# Documentation: Table `card.cards`

## Overview

| Attribute      | Value                          |
|----------------|--------------------------------|
| **Application**| NovoCard                       |
| **Schema**     | card                           |
| **Object**     | cards                          |
| **Type**       | Data Structure (Table)         |

The `card.cards` table is the central structure for the registry of issued cards. Each record represents a unique card — physical or virtual — belonging to a customer. The table manages the complete card lifecycle, from issuance through cancellation, covering activation, blocks, and expiry.

Card numbers (PAN) are stored in masked format (e.g., `4111 **** **** 1234`), in compliance with **PCI-DSS** standards. The full PAN is maintained exclusively in an external secure vault.

---

## Column Structure

### Identification and Relationships

| Column         | Type               | Nullable | Description                                                                         |
|----------------|--------------------|----------|-------------------------------------------------------------------------------------|
| `card_id`      | UNIQUEIDENTIFIER   | No       | Unique card identifier (PK, auto-generated via `NEWID()`)                           |
| `customer_id`  | UNIQUEIDENTIFIER   | No       | Reference to the owning customer (`customer.customers`)                             |
| `card_type_id` | INT                | No       | Card type (`card.card_types`)                                                       |
| `design_id`    | UNIQUEIDENTIFIER   | Yes      | Visual design of the card, assigned after design selection                          |

### Card Data (PCI-DSS)

| Column            | Type           | Nullable | Description                                                        |
|-------------------|----------------|----------|--------------------------------------------------------------------|
| `masked_pan`      | NVARCHAR(19)   | No       | Card number in masked format                                       |
| `card_holder_name`| NVARCHAR(100)  | No       | Name printed on the card                                           |
| `expiry_month`    | SMALLINT       | No       | Expiry month (1–12)                                                |
| `expiry_year`     | SMALLINT       | No       | Expiry year (> 2020)                                               |
| `last_four_digits`| Computed       | —        | Last 4 digits of the PAN (persisted, derived from `masked_pan`)   |
| `expires_at`      | Computed       | —        | Expiry date as DATETIMEOFFSET (1st day of the month, UTC)          |

### Format and Capabilities

| Column            | Type          | Default    | Description                                                    |
|-------------------|---------------|------------|----------------------------------------------------------------|
| `card_format`     | NVARCHAR(10)  | PHYSICAL   | Card format: PHYSICAL, VIRTUAL, or BOTH                        |
| `is_contactless`  | BIT           | 1 (Yes)    | Enabled for contactless/NFC payment                            |
| `is_online_enabled`| BIT          | 1 (Yes)    | Enabled for online purchases                                   |
| `is_international`| BIT           | 0 (No)     | Enabled for international use                                  |

### Lifecycle

| Column               | Type              | Description                                              |
|----------------------|-------------------|----------------------------------------------------------|
| `status`             | NVARCHAR(30)      | Current card status (see status table below)             |
| `issued_at`          | DATETIMEOFFSET    | Issuance date/time                                       |
| `activated_at`       | DATETIMEOFFSET    | Activation date/time                                     |
| `last_used_at`       | DATETIMEOFFSET    | Last recorded use date/time                              |
| `cancelled_at`       | DATETIMEOFFSET    | Cancellation date/time                                   |
| `cancellation_reason`| NVARCHAR(255)     | Reason for cancellation                                  |
| `created_at`         | DATETIMEOFFSET    | Record creation timestamp                                |
| `updated_at`         | DATETIMEOFFSET    | Last update timestamp                                    |

---

## Card Status

| Status               | Description                                                    |
|----------------------|----------------------------------------------------------------|
| `PENDING_ACTIVATION` | Card issued, awaiting customer activation                      |
| `ACTIVE`             | Card active and available for use                              |
| `BLOCKED_TEMPORARY`  | Temporary block initiated by the customer                      |
| `BLOCKED_FRAUD`      | Block due to suspected fraud (system or analyst)               |
| `EXPIRED`            | Card has expired                                               |
| `CANCELLED`          | Card permanently cancelled                                     |
| `LOST`               | Card reported as lost                                          |
| `STOLEN`             | Card reported as stolen                                        |

---

## Indexes

| Index                  | Column(s)         | Note                                    |
|------------------------|-------------------|-----------------------------------------|
| `pk_cards` (PK)        | `card_id`         | Clustered primary key                   |
| `idx_cards_customer_id`| `customer_id`     | Lookup by customer                      |
| `idx_cards_card_type_id`| `card_type_id`   | Lookup by card type                     |
| `idx_cards_status`     | `status`          | Filter by lifecycle state               |
| `idx_cards_last_four`  | `last_four_digits`| Lookup by last four digits              |
| `idx_cards_expires_at` | `expires_at`      | Expiry queries                          |
| `idx_cards_issued_at`  | `issued_at` (DESC)| Queries by most recent issuance date    |

---

## Relationships (Foreign Keys)

| Constraint             | Referenced Table          | Referenced Column |
|------------------------|---------------------------|-------------------|
| `fk_cards_customer`    | `customer.customers`      | `customer_id`     |
| `fk_cards_card_type`   | `card.card_types`         | `card_type_id`    |

---

## Business Rules (Constraints)

| Constraint              | Rule                                                                  |
|-------------------------|-----------------------------------------------------------------------|
| `chk_cards_expiry_month`| Expiry month between 1 and 12                                         |
| `chk_cards_expiry_year` | Expiry year greater than 2020                                         |
| `chk_cards_format`      | Format must be PHYSICAL, VIRTUAL, or BOTH                             |
| `chk_cards_status`      | Status restricted to the 8 valid lifecycle values                     |

---

## Insights

- **PCI-DSS compliance**: The architecture separates the masked PAN (stored in the table) from the full PAN (kept in an external secure vault), reducing the PCI audit scope.
- **Virtual and physical cards**: The `card_format` field with the `BOTH` option allows a single record to represent a physical card with a linked digital counterpart, supporting digitization strategies.
- **Granular usage control**: The `is_contactless`, `is_online_enabled`, and `is_international` flags allow individual per-card configuration, enabling customer- or institution-defined security policies.
- **Complete lifecycle**: The distinction between `BLOCKED_TEMPORARY` (customer action) and `BLOCKED_FRAUD` (system/analyst action) provides clear traceability of the block origin for regulatory and service purposes.
- **Conditional creation**: The script checks for the table's existence before creating it, ensuring idempotency in continuous deployment environments.
- **Persisted computed columns**: `last_four_digits` and `expires_at` are calculated and stored physically, optimizing frequent queries without runtime recalculation overhead.
- **Descending index on `issued_at`**: Optimized for queries seeking the most recently issued cards, a common scenario in operational and customer service dashboards.
