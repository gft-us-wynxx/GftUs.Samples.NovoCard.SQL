# Documentation: customer.customer_addresses

## Application
**NovoCard**

## Overview

Data structure responsible for storing postal and billing addresses associated with each customer. A customer can have multiple registered addresses; exactly one must be flagged as **primary** (main contact/delivery address) and one as **billing** (used for card statement delivery and billing correspondence).

## Type

**Data Structure** (Table)

## Schema and Object

| Schema     | Table                |
|------------|----------------------|
| `customer` | `customer_addresses` |

## Column Structure

| Column         | Data Type        | Required | Default               | Description                                                                         |
|----------------|------------------|----------|-----------------------|-------------------------------------------------------------------------------------|
| `address_id`   | UNIQUEIDENTIFIER | Yes      | `NEWID()`             | Unique address identifier (primary key)                                             |
| `customer_id`  | UNIQUEIDENTIFIER | Yes      | —                     | Identifier of the customer who owns the address                                     |
| `address_type` | NVARCHAR(20)     | Yes      | —                     | Address type: Residential, Billing, Commercial, or Other                            |
| `street`       | NVARCHAR(255)    | Yes      | —                     | Street name                                                                         |
| `number`       | NVARCHAR(20)     | Yes      | —                     | Street number                                                                       |
| `complement`   | NVARCHAR(100)    | No       | —                     | Unit, suite, apartment, etc.                                                        |
| `neighborhood` | NVARCHAR(100)    | No       | —                     | Neighborhood or district                                                            |
| `city`         | NVARCHAR(100)    | Yes      | —                     | City                                                                                |
| `state`        | NCHAR(2)         | Yes      | —                     | State or province (2-character code)                                                |
| `zip_code`     | NVARCHAR(10)     | Yes      | —                     | Postal / ZIP code                                                                   |
| `country`      | NCHAR(2)         | Yes      | `'US'`                | Country code (ISO 2-character, default United States)                               |
| `is_primary`   | BIT              | Yes      | `0`                   | Marks the default contact/delivery address. Only one primary per customer is expected |
| `is_billing`   | BIT              | Yes      | `0`                   | Marks the address used for statement delivery and billing correspondence             |
| `verified_at`  | DATETIMEOFFSET   | No       | —                     | Date/time when the address was confirmed via postal verification or document upload |
| `created_at`   | DATETIMEOFFSET   | Yes      | `SYSDATETIMEOFFSET()` | Record creation timestamp                                                           |
| `updated_at`   | DATETIMEOFFSET   | Yes      | `SYSDATETIMEOFFSET()` | Last update timestamp                                                               |

## Allowed Values for Address Type

| Value         | Meaning              |
|---------------|----------------------|
| `RESIDENTIAL` | Residential address  |
| `BILLING`     | Billing address      |
| `COMMERCIAL`  | Commercial address   |
| `OTHER`       | Other address type   |

## Relationships

| Type           | Referenced Table       | Local Column  | Referenced Column | Delete Behavior                                                           |
|----------------|------------------------|---------------|-------------------|---------------------------------------------------------------------------|
| Foreign Key    | `customer.customers`   | `customer_id` | `customer_id`     | Cascade delete (removing a customer automatically removes all their addresses) |

## Constraints

| Name                    | Type        | Description                                              |
|-------------------------|-------------|----------------------------------------------------------|
| `pk_customer_addresses` | Primary Key | Guarantees uniqueness of `address_id`                   |
| `fk_addresses_customer` | Foreign Key | Links the address to an existing customer               |
| `chk_address_type`      | Check       | Restricts `address_type` to the four allowed types       |

## Indexes

| Index Name                  | Column(s)      | Purpose                                        |
|-----------------------------|----------------|------------------------------------------------|
| `idx_addresses_customer_id` | `customer_id`  | Optimizes queries for addresses by customer    |
| `idx_addresses_type`        | `address_type` | Optimizes filtering by address type            |
| `idx_addresses_zip_code`    | `zip_code`     | Optimizes lookups by postal/ZIP code           |

## Insights

- The table is created conditionally (only if it does not already exist), ensuring safety in repeated deployment script executions.
- Using `UNIQUEIDENTIFIER` with `NEWID()` as the primary key indicates an architecture prepared for distributed environments, where ID generation does not depend on centralized sequences.
- Cascade delete (`ON DELETE CASCADE`) on the foreign key means removing a customer automatically eliminates all their addresses, simplifying data lifecycle management.
- The business rule that only **one address should be primary** and **one should be billing** per customer **is not enforced at the database level** — there is no filtered unique index or trigger to guarantee this constraint. This validation must be controlled by the application layer.
- The `verified_at` field indicates the existence of an address verification process (via postal correspondence or document upload), relevant for compliance and fraud prevention in the card context.
- There is no automatic mechanism to update `updated_at` (such as a trigger); the application must manage this update with each record modification.
