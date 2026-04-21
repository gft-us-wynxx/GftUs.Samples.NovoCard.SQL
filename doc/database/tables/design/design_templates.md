# design.design_templates

## General Description

Master catalog of card design templates managed by the **NovoCard** design team. Templates define the base visual structure that customers can customize. Each template is versioned — new versions do not invalidate existing card designs that reference previous versions.

---

## Schema and Location

| Property | Value |
|---|---|
| **Application** | NovoCard |
| **Schema** | `design` |
| **Table** | `design_templates` |
| **Type** | Data Structure (Table) |

---

## Column Structure

### Identification and Versioning

| Column | Type | Nullable | Default | Description |
|---|---|---|---|---|
| `template_id` | UNIQUEIDENTIFIER | No | `NEWID()` | Unique template identifier (PK) |
| `template_name` | NVARCHAR(100) | No | — | Technical name of the template |
| `display_name` | NVARCHAR(100) | No | — | Display name shown to the user |
| `version` | SMALLINT | No | `1` | Template version number |
| `description` | NVARCHAR(MAX) | Yes | — | Detailed description of the template |

### Compatibility

| Column | Type | Nullable | Default | Description |
|---|---|---|---|---|
| `compatible_product_classes` | NVARCHAR(MAX) | No | `["CREDIT","DEBIT","PREPAID"]` | Compatible product classes (JSON array) |
| `compatible_networks` | NVARCHAR(MAX) | No | `["VISA","MASTERCARD","DISCOVER","AMEX"]` | Compatible payment networks (JSON array) |

### Visual Properties

| Column | Type | Nullable | Default | Description |
|---|---|---|---|---|
| `primary_color` | NCHAR(7) | Yes | — | Primary color in HEX format (e.g., `#1A2B3C`) |
| `secondary_color` | NCHAR(7) | Yes | — | Secondary color in HEX format |
| `base_image_url` | NVARCHAR(500) | No | — | URL of the template's base image |
| `thumbnail_url` | NVARCHAR(500) | Yes | — | Thumbnail URL for preview |
| `is_dark_theme` | BIT | No | `0` | Indicates whether the template uses a dark theme |

### Metadata and Control

| Column | Type | Nullable | Default | Description |
|---|---|---|---|---|
| `category` | NVARCHAR(50) | Yes | — | Template category (restricted values) |
| `tags` | NVARCHAR(MAX) | Yes | — | Classification tags (JSON array) |
| `is_active` | BIT | No | `1` | Indicates whether the template is active for use |
| `is_default` | BIT | No | `0` | When active, automatically assigned at card issuance if no design is selected |
| `download_count` | INT | No | `0` | Cumulative counter of cards that have used this template |
| `created_by` | NVARCHAR(100) | Yes | — | User responsible for creation |
| `created_at` | DATETIMEOFFSET | No | `SYSDATETIMEOFFSET()` | Creation date/time |
| `updated_at` | DATETIMEOFFSET | No | `SYSDATETIMEOFFSET()` | Last update date/time |

---

## Allowed Categories

The `category` column is restricted to the following values via a `CHECK` constraint:

| Value |
|---|
| CLASSIC |
| NATURE |
| SPORTS |
| ART |
| GRADIENT |
| PATTERN |
| CUSTOM |
| LIMITEDEDITION |

---

## Constraints

| Name | Type | Detail |
|---|---|---|
| `pk_design_templates` | Primary Key | `template_id` |
| `uq_template_name_version` | Unique | `template_name` + `version` combination — guarantees uniqueness per version |
| `chk_template_category` | Check | Restricts `category` to allowed values |

---

## Indexes

| Name | Column | Purpose |
|---|---|---|
| `idx_templates_active` | `is_active` | Optimizes queries filtering active/inactive templates |
| `idx_templates_category` | `category` | Optimizes queries by template category |

---

## Insights

- **Non-breaking versioning**: The unique combination of `template_name` + `version` allows multiple versions of the same template to coexist. Already-issued cards continue referencing the original version, avoiding retroactive visual impact.

- **Default template (`is_default`)**: The default template mechanism automates card issuance when the customer does not make an active design choice. It is important to ensure that only one template is marked as default at a time (this rule is not enforced by the table structure and must be controlled by the application).

- **JSON fields for compatibility and tags**: The `compatible_product_classes`, `compatible_networks`, and `tags` columns store JSON arrays. For filtering queries, the SQL Server `OPENJSON` function should be used, which provides flexibility but requires attention to performance at large volumes.

- **Broad network coverage**: By default, templates are compatible with four major networks (Visa, Mastercard, Discover, and Amex) and all three product types (Credit, Debit, and Prepaid), covering the majority of issuance scenarios.

- **Popularity metric**: The `download_count` field serves as a popularity/adoption indicator for each template, useful for rankings, recommendations, and discontinuation decisions.

- **Conditional creation**: The table is only created if it does not already exist (`IF OBJECT_ID ... IS NULL`), ensuring safety in repeated script executions (idempotency).
