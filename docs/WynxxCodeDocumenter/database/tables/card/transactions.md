# card.transactions

## Overview

Data structure responsible for storing financial transaction records made with cards in the **NovoCard** application. Covers all card activity, including purchases, refunds, cash withdrawals, prepaid balance loads, fees, reversals, chargebacks, and interest. Each record represents a single authorization or settlement (posting) event.

---

## Transaction Lifecycle

| State | Description |
|---|---|
| **AUTHORIZED** | Hold placed on the card balance/limit |
| **POSTED** | Transaction cleared and settled |
| **REVERSED** | Full reversal completed before settlement |
| **DECLINED** | Transaction denied |
| **CANCELLED** | Transaction cancelled |
| **DISPUTED** | Transaction under dispute/contestation |

> Authorized transactions move to the **POSTED** state after the clearing process.

---

## Data Structure

### Transaction Identification

| Column | Type | Required | Description |
|---|---|---|---|
| `transaction_id` | UNIQUEIDENTIFIER | Yes | Unique transaction identifier (PK, auto-generated) |
| `card_id` | UNIQUEIDENTIFIER | Yes | Reference to the card used (FK → `card.cards`) |
| `account_id` | UNIQUEIDENTIFIER | Yes | Reference to the card account (FK → `card.card_accounts`) |
| `authorization_code` | NVARCHAR(20) | No | Authorization code returned by the network |
| `external_reference` | NVARCHAR(100) | No | External reference for integration with third-party systems |

### Transaction Type

| Column | Type | Required | Allowed Values |
|---|---|---|---|
| `transaction_type` | NVARCHAR(30) | Yes | PURCHASE, REFUND, CASH_WITHDRAWAL, BALANCE_LOAD, FEE, REVERSAL, CHARGEBACK, INTEREST, CASH_ADVANCE |

### Amounts and Exchange

| Column | Type | Required | Description |
|---|---|---|---|
| `amount` | DECIMAL(15,2) | Yes | Final transaction amount in the billing currency |
| `original_amount` | DECIMAL(15,2) | No | Original amount in the merchant's currency (before conversion). Null for domestic transactions |
| `original_currency` | NCHAR(3) | No | Original transaction currency (ISO code) |
| `billing_currency` | NCHAR(3) | Yes | Billing currency (default: **USD**) |
| `exchange_rate` | DECIMAL(12,6) | No | Exchange rate applied in the conversion |

### Merchant Data

| Column | Type | Required | Description |
|---|---|---|---|
| `merchant_name` | NVARCHAR(255) | No | Merchant name |
| `merchant_id` | NVARCHAR(50) | No | Merchant identifier |
| `merchant_category_code` | CHAR(4) | No | Merchant category code per ISO 18245 (MCC) |
| `merchant_city` | NVARCHAR(100) | No | Merchant city |
| `merchant_country` | NCHAR(2) | No | Merchant country (2-character ISO code) |

### Transaction State and Characteristics

| Column | Type | Required | Description |
|---|---|---|---|
| `status` | NVARCHAR(20) | Yes | Current transaction state (default: AUTHORIZED) |
| `decline_reason` | NVARCHAR(100) | No | Decline reason, when applicable |
| `is_online` | BIT | Yes | Indicates whether the transaction was conducted online |
| `is_international` | BIT | Yes | Indicates whether the transaction is international |
| `is_contactless` | BIT | Yes | Indicates whether the transaction was contactless |
| `installments` | SMALLINT | Yes | Number of installments (1 to 24). Value 1 indicates a single-payment transaction |

### Dates and Timestamps

| Column | Type | Required | Description |
|---|---|---|---|
| `authorized_at` | DATETIMEOFFSET | Yes | Authorization date/time |
| `posted_at` | DATETIMEOFFSET | No | Settlement date/time |
| `reversed_at` | DATETIMEOFFSET | No | Reversal date/time |
| `created_at` | DATETIMEOFFSET | Yes | Record creation date/time |

---

## Relationships

| Foreign Key | Referenced Table | Column |
|---|---|---|
| `fk_transactions_card` | `card.cards` | `card_id` |
| `fk_transactions_account` | `card.card_accounts` | `account_id` |

---

## Indexes

| Index | Column(s) | Purpose |
|---|---|---|
| `pk_transactions` | `transaction_id` | Primary key |
| `idx_transactions_card_id` | `card_id` | Queries by card |
| `idx_transactions_account_id` | `account_id` | Queries by account |
| `idx_transactions_status` | `status` | Filtering by transaction state |
| `idx_transactions_authorized_at` | `authorized_at` (DESC) | Queries ordered by authorization date (most recent first) |
| `idx_transactions_merchant_code` | `merchant_category_code` | Analysis by merchant category (MCC) |
| `idx_transactions_type` | `transaction_type` | Filtering by transaction type |

---

## Business Rules and Validations

| Rule | Description |
|---|---|
| `chk_txn_type` | Transaction type restricted to 9 predefined values |
| `chk_txn_status` | Status restricted to 6 valid states |
| `chk_txn_installments` | Installments limited between 1 and 24 |
| Conditional creation | The table is only created if it does not already exist in the database |

---

## Insights

- **Installment plan support**: The `installments` field supports 1 to 24 installments, enabling deferred payment plans commonly used in credit card products.
- **International transaction support**: The structure supports full currency conversion with original currency, billing currency, and exchange rate, enabling complete traceability of the amount charged to the cardholder.
- **MCC classification (ISO 18245)**: The merchant category code is used for spending analytics and applying category-based limit rules.
- **Performance-oriented indexing**: Indexes on high-cardinality query columns (card, account, status, date, type, and MCC) reflect high transaction volumes and the need for fast responses in both operational and analytical queries.
- **Capture channel flags**: The `is_online`, `is_international`, and `is_contactless` flags enable detailed segmentation of the capture channel, essential for fraud analysis and usage behavior.
- **Default currency USD**: The default billing currency is US Dollar, confirming that the application targets the US market with support for international operations.
- **Complete temporal traceability**: The date fields (`authorized_at`, `posted_at`, `reversed_at`, `created_at`) allow tracking the full transaction lifecycle with time-zone precision (DATETIMEOFFSET).
