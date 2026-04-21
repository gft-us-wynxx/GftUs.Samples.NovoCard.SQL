-- =============================================================================
-- Table: customer.customer_addresses
-- Application: NovoCard
-- Description: Postal and billing addresses for each customer. A customer may
--              have multiple addresses; exactly one must be flagged as primary
--              and one as billing (used for card statement delivery).
-- =============================================================================

IF OBJECT_ID('customer.customer_addresses', 'U') IS NULL
CREATE TABLE customer.customer_addresses (
    address_id      UNIQUEIDENTIFIER    NOT NULL CONSTRAINT pk_customer_addresses PRIMARY KEY DEFAULT NEWID(),
    customer_id     UNIQUEIDENTIFIER    NOT NULL
                        CONSTRAINT fk_addresses_customer REFERENCES customer.customers (customer_id) ON DELETE CASCADE,
    address_type    NVARCHAR(20)        NOT NULL
                        CONSTRAINT chk_address_type CHECK (address_type IN (
                            N'RESIDENTIAL', N'BILLING', N'COMMERCIAL', N'OTHER'
                        )),
    street          NVARCHAR(255)       NOT NULL,
    number          NVARCHAR(20)        NOT NULL,
    complement      NVARCHAR(100)       NULL,
    neighborhood    NVARCHAR(100)       NULL,
    city            NVARCHAR(100)       NOT NULL,
    state           NCHAR(2)            NOT NULL,
    zip_code        NVARCHAR(10)        NOT NULL,
    country         NCHAR(2)            NOT NULL DEFAULT N'US',
    -- Marks the default contact/delivery address. Only one primary per customer is expected
    is_primary      BIT                 NOT NULL DEFAULT 0,
    -- Marks the address used for card statement delivery and billing correspondence
    is_billing      BIT                 NOT NULL DEFAULT 0,
    -- Timestamp when address was confirmed via postal verification or document upload
    verified_at     DATETIMEOFFSET      NULL,
    created_at      DATETIMEOFFSET      NOT NULL DEFAULT SYSDATETIMEOFFSET(),
    updated_at      DATETIMEOFFSET      NOT NULL DEFAULT SYSDATETIMEOFFSET()
);
GO

CREATE INDEX idx_addresses_customer_id  ON customer.customer_addresses (customer_id);
CREATE INDEX idx_addresses_type         ON customer.customer_addresses (address_type);
CREATE INDEX idx_addresses_zip_code     ON customer.customer_addresses (zip_code);
GO
