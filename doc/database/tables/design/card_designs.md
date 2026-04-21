# design.card_designs

## Overview

Data structure belonging to the **NovoCard** application responsible for recording the design (artwork/visual customization) applied to a specific card. Each card has at most one current design (`is_current = 1`), but the full history of previous designs is retained for traceability purposes.

Customers can customize visual elements over the base template, such as a printed name, accent color, monogram, and font preference. All customization goes through a **content moderation** workflow before being approved for printing/rendering.

---

## Schema and Relationships

| Relationship | Referenced Table | FK Column | Delete Behavior |
|---|---|---|---|
| Card | `card.cards` | `card_id` | `CASCADE` — deleting the card removes its designs |
| Template | `design.design_templates` | `template_id` | No cascade (default restriction) |

---

## Column Structure

### Identification

| Column | Type | Nullable | Default | Description |
|---|---|---|---|---|
| `design_id` | `UNIQUEIDENTIFIER` | No | `NEWID()` | Primary key of the design |
| `card_id` | `UNIQUEIDENTIFIER` | No | — | Card to which the design is associated |
| `template_id` | `UNIQUEIDENTIFIER` | No | — | Base template used for the design |

### Customer Customization

| Column | Type | Nullable | Default | Description |
|---|---|---|---|---|
| `custom_name_text` | `NVARCHAR(26)` | Yes | — | Customized name printed on the card face, replacing the full name (max 26 characters) |
| `custom_color` | `NCHAR(7)` | Yes | — | Hexadecimal accent color chosen by the customer (e.g., `#FF5A2D`) |
| `monogram` | `NCHAR(2)` | Yes | — | Monogram of 1 to 2 characters |
| `font_preference` | `NVARCHAR(30)` | Yes | — | Font preference for rendering |

### Design State

| Column | Type | Nullable | Default | Description |
|---|---|---|---|---|
| `is_current` | `BIT` | No | `1` | Indicates whether this is the card's current active design |
| `approval_status` | `NVARCHAR(20)` | No | `PENDING` | Content moderation status |
| `approved_at` | `DATETIMEOFFSET` | Yes | — | Approval date/time |
| `rejection_reason` | `NVARCHAR(255)` | Yes | — | Rejection reason, when applicable |
| `assigned_at` | `DATETIMEOFFSET` | No | `SYSDATETIMEOFFSET()` | Date/time the design was assigned to the card |
| `replaced_at` | `DATETIMEOFFSET` | Yes | — | Date/time the design was replaced by another |

#### Allowed Values for `approval_status`

| Value | Meaning |
|---|---|
| `PENDING` | Awaiting moderation |
| `APPROVED` | Approved for printing/rendering |
| `REJECTED` | Rejected by moderation |
| `CANCELLED` | Cancelled |

### Rendering Metadata

| Column | Type | Nullable | Default | Description |
|---|---|---|---|---|
| `render_url` | `NVARCHAR(500)` | Yes | — | URL of the rendered image/artifact |
| `render_version` | `SMALLINT` | No | `1` | Rendering version (incremented on each re-render) |
| `rendered_at` | `DATETIMEOFFSET` | Yes | — | Date/time of the last rendering |

### Audit

| Column | Type | Nullable | Default | Description |
|---|---|---|---|---|
| `created_at` | `DATETIMEOFFSET` | No | `SYSDATETIMEOFFSET()` | Record creation date/time |

---

## Indexes

| Index | Columns | Type | Purpose |
|---|---|---|---|
| `pk_card_designs` | `design_id` | Primary Key | Unique design identification |
| `idx_card_designs_card_id` | `card_id` | Non-unique | Queries by card |
| `idx_card_designs_template_id` | `template_id` | Non-unique | Queries by template |
| `idx_card_designs_one_current` | `card_id` (filtered: `is_current = 1`) | **Filtered Unique** | Guarantees only one current design exists per card |
| `idx_card_designs_approval` | `approval_status` | Non-unique | Queries by approval status |

---

## Insights

- **Uniqueness of the current design**: The filtered unique index `idx_card_designs_one_current` is the database-level guarantee that there will never be two simultaneous designs marked as current for the same card. Any design replacement process must deactivate the previous one (`is_current = 0` and populate `replaced_at`) before inserting or activating the new one.

- **Mandatory moderation workflow**: Every design starts with status `PENDING`. Customization should only be rendered and printed after transitioning to `APPROVED`. Queue/back-office processes can use the `idx_card_designs_approval` index to efficiently fetch pending items.

- **Cascade delete**: Removing a card from `card.cards` automatically deletes the entire associated design history. Deleting a template from `design.design_templates` will be blocked as long as designs are referencing it.

- **Rendering versioning**: The `render_version` field tracks how many times the artwork was generated, useful for re-rendering scenarios following corrections to the template or customer data.

- **Conditional creation**: The table is only created if it does not already exist in the database (`IF OBJECT_ID ... IS NULL`), ensuring deployment script idempotency.
