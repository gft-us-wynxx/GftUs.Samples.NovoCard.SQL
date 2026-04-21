-- =============================================================================
-- Table: customer.customers
-- Application: NovoCard
-- Description: Core customer registry. Each row represents a natural person
--              who has enrolled in the NovoCard platform. A customer may hold
--              multiple cards (credit, debit, and/or prepaid) tied to this record.
-- =============================================================================

IF OBJECT_ID('customer.customers', 'U') IS NULL
CREATE TABLE customer.customers (
    customer_id         UNIQUEIDENTIFIER    NOT NULL CONSTRAINT pk_customers PRIMARY KEY DEFAULT NEWID(),
    first_name          NVARCHAR(100)       NOT NULL,
    last_name           NVARCHAR(100)       NOT NULL,
    -- Computed full name; persisted for indexing and display
    full_name           AS (first_name + N' ' + last_name) PERSISTED,
    email               NVARCHAR(255)       NOT NULL CONSTRAINT uq_customers_email UNIQUE,
    phone               NVARCHAR(20)        NULL,
    date_of_birth       DATE                NOT NULL,
    -- CPF for Brazilian customers or equivalent national tax identifier
    taxpayer_id         NVARCHAR(20)        NOT NULL CONSTRAINT uq_customers_taxpayer_id UNIQUE,
    nationality         NCHAR(2)            NOT NULL DEFAULT N'BR',
    gender              NCHAR(1)            NULL
                            CONSTRAINT chk_customers_gender CHECK (gender IN (N'M', N'F', N'X')),
    -- Self-declared monthly income bracket used for credit limit calculation
    income_range        NVARCHAR(30)        NULL
                            CONSTRAINT chk_customers_income_range CHECK (income_range IN (
                                N'BELOW_1K', N'1K_3K', N'3K_5K', N'5K_10K',
                                N'10K_20K', N'ABOVE_20K'
                            )),
    -- Internal NovoCard score (0-1000). Derived from bureau data and behavioral signals
    credit_score        SMALLINT            NULL
                            CONSTRAINT chk_customers_credit_score CHECK (credit_score BETWEEN 0 AND 1000),
    -- Know Your Customer verification state. Cards can only be issued when status is APPROVED
    kyc_status          NVARCHAR(20)        NOT NULL DEFAULT N'PENDING'
                            CONSTRAINT chk_customers_kyc_status CHECK (kyc_status IN (
                                N'PENDING', N'IN_REVIEW', N'APPROVED', N'REJECTED'
                            )),
    status              NVARCHAR(20)        NOT NULL DEFAULT N'ACTIVE'
                            CONSTRAINT chk_customers_status CHECK (status IN (
                                N'ACTIVE', N'SUSPENDED', N'CLOSED', N'BLOCKED'
                            )),
    onboarded_at        DATETIMEOFFSET      NOT NULL DEFAULT SYSDATETIMEOFFSET(),
    last_login_at       DATETIMEOFFSET      NULL,
    created_at          DATETIMEOFFSET      NOT NULL DEFAULT SYSDATETIMEOFFSET(),
    updated_at          DATETIMEOFFSET      NOT NULL DEFAULT SYSDATETIMEOFFSET()
);
GO

CREATE INDEX idx_customers_email        ON customer.customers (email);
CREATE INDEX idx_customers_taxpayer_id  ON customer.customers (taxpayer_id);
CREATE INDEX idx_customers_status       ON customer.customers (status);
CREATE INDEX idx_customers_kyc_status   ON customer.customers (kyc_status);
CREATE INDEX idx_customers_created_at   ON customer.customers (created_at DESC);
GO
