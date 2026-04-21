-- =============================================================================
-- Table: customer.customer_addresses
-- Application: NovoCard
-- Description: Postal and billing addresses for each customer. A customer may
--              have multiple addresses; exactly one must be flagged as primary
--              and one as billing (used for card statement delivery).
-- =============================================================================

CREATE TABLE IF NOT EXISTS customer.customer_addresses (
    address_id      UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    customer_id     UUID            NOT NULL
                        REFERENCES customer.customers (customer_id) ON DELETE CASCADE,
    address_type    VARCHAR(20)     NOT NULL CHECK (address_type IN ('RESIDENTIAL', 'BILLING', 'COMMERCIAL', 'OTHER')),
    street          VARCHAR(255)    NOT NULL,
    number          VARCHAR(20)     NOT NULL,
    complement      VARCHAR(100),
    neighborhood    VARCHAR(100),
    city            VARCHAR(100)    NOT NULL,
    state           CHAR(2)         NOT NULL,
    zip_code        VARCHAR(10)     NOT NULL,
    country         CHAR(2)         NOT NULL DEFAULT 'BR',
    is_primary      BOOLEAN         NOT NULL DEFAULT FALSE,
    is_billing      BOOLEAN         NOT NULL DEFAULT FALSE,
    verified_at     TIMESTAMPTZ,
    created_at      TIMESTAMPTZ     NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ     NOT NULL DEFAULT now()
);

CREATE INDEX idx_addresses_customer_id  ON customer.customer_addresses (customer_id);
CREATE INDEX idx_addresses_type         ON customer.customer_addresses (address_type);
CREATE INDEX idx_addresses_zip_code     ON customer.customer_addresses (zip_code);

COMMENT ON TABLE customer.customer_addresses IS
    'Physical and billing addresses associated with NovoCard customers.';
COMMENT ON COLUMN customer.customer_addresses.is_primary IS
    'Marks the default contact/delivery address. Only one primary per customer is expected.';
COMMENT ON COLUMN customer.customer_addresses.is_billing IS
    'Marks the address used for card statement delivery and billing correspondence.';
COMMENT ON COLUMN customer.customer_addresses.verified_at IS
    'Timestamp when address was confirmed via postal verification or document upload.';
