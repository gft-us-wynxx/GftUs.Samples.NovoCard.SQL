# Gftus.Samples.NovoCard.SQL

PostgreSQL reference schema for **NovoCard** — a credit, debit, and prepaid card management platform. This sample demonstrates real-world database design patterns including multi-schema organization, audit trails, stored procedures, triggers, and analytical views.

---

## Repository Structure

```
database/
├── schemas/          # Schema creation scripts (run first)
│   ├── 01_customer.sql
│   ├── 02_card.sql
│   ├── 03_design.sql
│   └── 04_audit.sql
├── tables/
│   ├── customer/
│   │   ├── customers.sql
│   │   └── customer_addresses.sql
│   ├── card/
│   │   ├── card_types.sql
│   │   ├── cards.sql
│   │   ├── card_accounts.sql
│   │   ├── card_limits.sql
│   │   ├── card_status_history.sql
│   │   └── transactions.sql
│   └── design/
│       ├── design_templates.sql
│       ├── design_assets.sql
│       └── card_designs.sql
├── procedures/
│   ├── sp_issue_card.sql
│   ├── sp_update_card_status.sql
│   ├── sp_block_card.sql
│   ├── sp_process_transaction.sql
│   └── sp_assign_card_design.sql
├── triggers/
│   ├── trg_card_status_audit.sql
│   ├── trg_transaction_limit_check.sql
│   └── trg_design_version_control.sql
└── views/
    ├── vw_active_cards.sql
    ├── vw_customer_card_portfolio.sql
    ├── vw_transaction_summary.sql
    └── vw_card_design_catalog.sql
```

---

## Schemas

| Schema | Purpose |
|--------|---------|
| `customer` | Customer identity, contact info, and addresses |
| `card` | Card issuance, accounts, limits, status lifecycle, and transactions |
| `design` | Card visual templates, assets, and per-card design assignments |
| `audit` | Centralized immutable audit log for all data mutations |

---

## Tables

### customer
| Table | Description |
|-------|-------------|
| `customers` | Core customer registry; each person enrolled in NovoCard |
| `customer_addresses` | Postal and billing addresses; one primary per customer |

### card
| Table | Description |
|-------|-------------|
| `card_types` | Product catalog (CREDIT / DEBIT / PREPAID combinations) |
| `cards` | Issued cards — physical and virtual — with lifecycle status |
| `card_accounts` | Financial account state: balances, credit limits, available funds |
| `card_limits` | Per-card velocity controls for spending and withdrawals |
| `card_status_history` | Immutable ledger of every card status transition |
| `transactions` | All card financial activity: purchases, refunds, withdrawals, loads |

### design
| Table | Description |
|-------|-------------|
| `design_templates` | Master catalog of visual shells managed by the design team |
| `design_assets` | Layered digital assets (backgrounds, logos, icons) per template |
| `card_designs` | Active and historical design assignments per card |

---

## Stored Procedures

| Procedure | Description |
|-----------|-------------|
| `card.sp_issue_card` | Issues a new card after validating customer eligibility and KYC approval |
| `card.sp_update_card_status` | Enforces the card status state machine, preventing illegal transitions |
| `card.sp_block_card` | Convenience wrapper for temporary or fraud-initiated card blocks |
| `card.sp_process_transaction` | Authorizes or posts transactions, manages holds and balance updates |
| `design.sp_assign_card_design` | Assigns or replaces a card design, validating template compatibility |

---

## Triggers

| Trigger | Table(s) | Description |
|---------|----------|-------------|
| `trg_card_status_audit` | `cards`, `customers`, `card_designs` | Captures INSERT/UPDATE/DELETE mutations as JSONB snapshots in `audit.audit_log` |
| `trg_transaction_limit_check` | `card.transactions` | BEFORE INSERT guard that verifies card is active and the transaction respects spending limits |
| `trg_design_version_control` | `design_templates`, `card_designs` | Enforces template versioning and prevents modifications to templates with active card assignments |

---

## Views

| View | Description |
|------|-------------|
| `card.vw_active_cards` | All cards in ACTIVE state, joined with balances and current design — used by mobile home screen and CS dashboards |
| `customer.vw_customer_card_portfolio` | Customer-level card portfolio with credit exposure and KYC context — used by CRM and risk teams |
| `card.vw_transaction_summary` | Monthly spending per card by type and merchant category — powers spending analytics and statement generation |
| `design.vw_card_design_catalog` | Public-facing design catalog with asset counts and popularity metrics — used by the personalization UI |

---

## Getting Started

Run scripts in this order to build the schema from scratch:

1. `database/schemas/` — create schemas (01 → 04)
2. `database/tables/customer/` — customer tables
3. `database/tables/card/` — card tables (respects FK order: types → cards → accounts → limits → history → transactions)
4. `database/tables/design/` — design tables
5. `database/triggers/` — triggers
6. `database/procedures/` — stored procedures
7. `database/views/` — views

> Requires PostgreSQL 14 or later.
