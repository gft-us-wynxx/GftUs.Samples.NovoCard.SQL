-- =============================================================================
-- Table: customer.customers
-- Application: NovoCard
-- Description: Core customer registry. Each row represents a natural person
--              who has enrolled in the NovoCard platform. A customer may hold
--              multiple cards (credit, debit, and/or prepaid) tied to this record.
-- =============================================================================

CREATE TABLE IF NOT EXISTS customer.customers (
    customer_id         UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    first_name          VARCHAR(100)    NOT NULL,
    last_name           VARCHAR(100)    NOT NULL,
    full_name           VARCHAR(200)    GENERATED ALWAYS AS (first_name || ' ' || last_name) STORED,
    email               VARCHAR(255)    NOT NULL UNIQUE,
    phone               VARCHAR(20),
    date_of_birth       DATE            NOT NULL,
    taxpayer_id         VARCHAR(20)     NOT NULL UNIQUE,
    nationality         CHAR(2)         NOT NULL DEFAULT 'BR',
    gender              CHAR(1)         CHECK (gender IN ('M', 'F', 'X')),
    income_range        VARCHAR(30)     CHECK (income_range IN (
                            'BELOW_1K', '1K_3K', '3K_5K', '5K_10K',
                            '10K_20K', 'ABOVE_20K'
                        )),
    credit_score        SMALLINT        CHECK (credit_score BETWEEN 0 AND 1000),
    kyc_status          VARCHAR(20)     NOT NULL DEFAULT 'PENDING'
                            CHECK (kyc_status IN ('PENDING', 'IN_REVIEW', 'APPROVED', 'REJECTED')),
    status              VARCHAR(20)     NOT NULL DEFAULT 'ACTIVE'
                            CHECK (status IN ('ACTIVE', 'SUSPENDED', 'CLOSED', 'BLOCKED')),
    onboarded_at        TIMESTAMPTZ     NOT NULL DEFAULT now(),
    last_login_at       TIMESTAMPTZ,
    created_at          TIMESTAMPTZ     NOT NULL DEFAULT now(),
    updated_at          TIMESTAMPTZ     NOT NULL DEFAULT now()
);

CREATE INDEX idx_customers_email          ON customer.customers (email);
CREATE INDEX idx_customers_taxpayer_id    ON customer.customers (taxpayer_id);
CREATE INDEX idx_customers_status         ON customer.customers (status);
CREATE INDEX idx_customers_kyc_status     ON customer.customers (kyc_status);
CREATE INDEX idx_customers_created_at     ON customer.customers (created_at DESC);

COMMENT ON TABLE customer.customers IS
    'Registry of all individuals enrolled in the NovoCard platform.';
COMMENT ON COLUMN customer.customers.taxpayer_id IS
    'CPF for Brazilian customers or equivalent national tax identifier.';
COMMENT ON COLUMN customer.customers.credit_score IS
    'Internal NovoCard score (0–1000). Derived from bureau data and behavioral signals.';
COMMENT ON COLUMN customer.customers.kyc_status IS
    'Know Your Customer verification state. Cards can only be issued when status is APPROVED.';
COMMENT ON COLUMN customer.customers.income_range IS
    'Self-declared monthly income bracket used for credit limit calculation.';
