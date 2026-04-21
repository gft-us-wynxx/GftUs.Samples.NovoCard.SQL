# Documentation — `card.card_status_history`

## Overview

| Attribute      | Detail                                                                                                                                                       |
|----------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------|
| **Application**| NovoCard                                                                                                                                                     |
| **Schema**     | `card`                                                                                                                                                       |
| **Object**     | `card_status_history`                                                                                                                                        |
| **Type**       | Data structure (table)                                                                                                                                       |
| **Purpose**    | Immutable ledger of all card status transitions. Each status change generates a new record, ensuring complete traceability.                                   |

This table is primarily used for **compliance reporting** and **customer dispute investigations**, enabling a full reconstruction of the status history for any given card.

---

## Data Structure

### Columns

| Column           | Type                  | Nullable | Description                                                                                      |
|------------------|-----------------------|----------|--------------------------------------------------------------------------------------------------|
| `history_id`     | `BIGINT IDENTITY`     | No       | Unique sequential identifier for the history record (primary key).                               |
| `card_id`        | `UNIQUEIDENTIFIER`    | No       | Reference to the card in `card.cards`. Cascade delete.                                           |
| `previous_status`| `NVARCHAR(30)`        | No       | Card status **before** the transition.                                                           |
| `new_status`     | `NVARCHAR(30)`        | No       | Card status **after** the transition.                                                            |
| `reason`         | `NVARCHAR(255)`       | Yes      | Reason or justification for the status change.                                                   |
| `initiated_by`   | `NVARCHAR(20)`        | No       | Actor responsible for the status change.                                                         |
| `operator_id`    | `NVARCHAR(100)`       | Yes      | Internal identifier of the operator user (applicable when the actor is RISKANALYST or SUPPORT).  |
| `channel`        | `NVARCHAR(20)`        | Yes      | Channel through which the status change was requested.                                           |
| `ip_address`     | `VARCHAR(45)`         | Yes      | Source IP address of the request (supports IPv4 and IPv6).                                       |
| `changed_at`     | `DATETIMEOFFSET`      | No       | Date and time of the status change, with time zone. Default: current server time.                |

### Allowed Values — `initiated_by`

| Value          | Description                                          |
|----------------|------------------------------------------------------|
| `CUSTOMER`     | Change initiated by the customer.                    |
| `SYSTEM`       | Automated system change.                             |
| `RISKANALYST`  | Change made by a risk analyst.                       |
| `FRAUDENGINE`  | Change triggered by the automated fraud rules engine.|
| `SUPPORT`      | Change made by the support team.                     |

### Allowed Values — `channel`

| Value    | Description                          |
|----------|--------------------------------------|
| `APP`    | Mobile application                   |
| `WEB`    | Web portal                           |
| `IVR`    | Interactive Voice Response (IVR)     |
| `BRANCH` | Branch / service point               |
| `API`    | API integration                      |
| `BATCH`  | Batch processing                     |

---

## Relationships

| Type         | Referenced Table | Local Column | Referenced Column | Delete Behavior |
|--------------|------------------|--------------|-------------------|-----------------|
| Foreign Key  | `card.cards`     | `card_id`    | `card_id`         | `CASCADE`       |

Deleting a card from `card.cards` automatically removes all associated status history records.

---

## Indexes

| Name                                        | Column(s)    | Order | Purpose                                                             |
|---------------------------------------------|--------------|-------|---------------------------------------------------------------------|
| `pk_card_status_history` (PK, clustered)    | `history_id` | ASC   | Unique identification of each record.                               |
| `idx_card_status_history_card_id`           | `card_id`    | ASC   | Fast history queries by card.                                       |
| `idx_card_status_history_changed_at`        | `changed_at` | DESC  | Chronologically ordered queries (most recent first).                |
| `idx_card_status_history_new_status`        | `new_status` | ASC   | Efficient filtering by target status (e.g., find all fraud blocks). |

---

## Constraints

| Name                          | Type  | Rule                                                                                       |
|-------------------------------|-------|--------------------------------------------------------------------------------------------|
| `pk_card_status_history`      | PK    | `history_id` is unique and non-null.                                                       |
| `fk_status_history_card`      | FK    | `card_id` must exist in `card.cards`.                                                      |
| `chk_status_history_initiator`| CHECK | `initiated_by` restricted to: CUSTOMER, SYSTEM, RISKANALYST, FRAUDENGINE, SUPPORT.        |
| `chk_status_history_channel`  | CHECK | `channel` restricted to: APP, WEB, IVR, BRANCH, API, BATCH.                               |

---

## Insights

- **Immutable nature**: the table functions as an audit log — records are only inserted, never updated or removed directly (except by cascade delete from the parent card).
- **Complete traceability**: the combination of `initiated_by`, `operator_id`, `channel`, and `ip_address` allows precise identification of **who**, **how**, and **from where** each status change originated, satisfying regulatory and audit requirements.
- **Volume growth**: as an append-only model tied to every status transition of every card, this table tends to grow significantly over time. The descending index on `changed_at` favors queries that prioritize the most recent events.
- **Support for automation and human action**: the `initiated_by` field clearly distinguishes automated actions (SYSTEM, FRAUDENGINE) from manual actions (CUSTOMER, RISKANALYST, SUPPORT), facilitating analysis of automated rule effectiveness versus human interventions.
- **Cascade delete**: removing a card eliminates its entire transition history, which must be considered in data retention and regulatory compliance policies — archiving the data before deletion may be necessary.
- **Optional `reason` field**: not all transitions include a textual justification, which can complicate retroactive investigations if the application layers do not standardize this field's population.
