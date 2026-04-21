# Audit Schema — NovoCard

## Overview

This artifact defines the data structure of the **audit** schema, responsible for centralizing the audit trail of the **NovoCard** application. All significant mutations performed in the customer, card, and design schemas are recorded here to meet requirements for **regulatory compliance**, **dispute resolution**, and **forensic analysis**.

---

## Data Structure

### Schema `audit`

The `audit` schema is created conditionally (only if it does not already exist), ensuring idempotent script execution.

---

### Table `audit.audit_log`

Immutable record of every **INSERT**, **UPDATE**, and **DELETE** operation performed on NovoCard business tables. Values before and after each change are stored as JSON, enabling complete change traceability.

#### Columns

| Column        | Type                   | Nullable | Description                                                                                         |
|---------------|------------------------|----------|-----------------------------------------------------------------------------------------------------|
| `log_id`      | `BIGINT IDENTITY(1,1)` | No       | Unique sequential identifier for the audit record (primary key)                                     |
| `schema_name` | `NVARCHAR(63)`         | No       | Name of the schema of the affected table                                                            |
| `table_name`  | `NVARCHAR(63)`         | No       | Name of the affected table                                                                          |
| `operation`   | `NVARCHAR(10)`         | No       | Type of operation performed (restricted to `INSERT`, `UPDATE`, or `DELETE`)                         |
| `record_id`   | `NVARCHAR(100)`        | No       | Primary key of the affected row, cast to text for cross-table compatibility                         |
| `old_values`  | `NVARCHAR(MAX)`        | Yes      | JSON snapshot of values **before** the change (NULL for INSERT)                                     |
| `new_values`  | `NVARCHAR(MAX)`        | Yes      | JSON snapshot of values **after** the change (NULL for DELETE)                                      |
| `changed_by`  | `NVARCHAR(100)`        | No       | User responsible for the change (default: current session system user)                              |
| `changed_at`  | `DATETIMEOFFSET`       | No       | Date and time of the change with time zone (default: current moment)                                |
| `ip_address`  | `VARCHAR(45)`          | Yes      | Source IP address (supports IPv4 and IPv6)                                                          |
| `session_id`  | `NVARCHAR(100)`        | Yes      | Identifier of the session that originated the change                                                |

#### Constraints

| Type        | Name                   | Detail                                         |
|-------------|------------------------|------------------------------------------------|
| Primary Key | `pk_audit_log`         | Column `log_id`                                |
| Check       | `chk_audit_operation`  | `operation` must be `INSERT`, `UPDATE`, or `DELETE` |

#### Indexes

| Name                     | Columns                     | Note                                              |
|--------------------------|-----------------------------|---------------------------------------------------|
| `idx_audit_log_table`    | `schema_name`, `table_name` | Optimizes queries filtered by source table        |
| `idx_audit_log_record`   | `record_id`                 | Optimizes lookups by affected record              |
| `idx_audit_log_changed_at` | `changed_at DESC`         | Optimizes chronological queries (most recent first) |
| `idx_audit_log_operation`| `operation`                 | Optimizes filters by operation type               |

---

## Insights

- **Immutability by design**: The table is designed as an append-only log. No update or delete mechanisms are provided, reinforcing the integrity of the audit trail.
- **Cross-table compatibility**: Using `NVARCHAR(100)` for `record_id` allows primary keys of different types (integers, GUIDs, concatenated composites) to be recorded in a single centralized table.
- **JSON storage**: Choosing `NVARCHAR(MAX)` with JSON snapshots for `old_values` and `new_values` offers flexibility to audit tables with distinct structures without requiring entity-specific columns.
- **Complete traceability**: The combination of `changed_by`, `ip_address`, and `session_id` identifies not only **who** made the change, but also **from where** and in what **session context**.
- **Idempotent creation**: Both the schema and the table use existence checks, allowing the script to be executed multiple times without errors.
- **Cross-domain coverage**: The schema serves multiple application domains (customers, cards, and designs), consolidating auditing into a single query point.
- **Compliance support**: The structure meets common regulatory requirements such as PCI-DSS, which mandate detailed tracking of access and changes to sensitive data.
