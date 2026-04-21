-- =============================================================================
-- Table: card.card_types
-- Application: NovoCard
-- Description: Catalog of card product types offered by NovoCard.
--              Defines the combination of product class (CREDIT/DEBIT/PREPAID),
--              payment network, and tier that determines card behavior,
--              fees, and default limits.
-- =============================================================================

IF OBJECT_ID('card.card_types', 'U') IS NULL
CREATE TABLE card.card_types (
    card_type_id            INT IDENTITY(1,1)   NOT NULL CONSTRAINT pk_card_types PRIMARY KEY,
    type_name               NVARCHAR(50)        NOT NULL CONSTRAINT uq_card_types_name UNIQUE,
    product_class           NVARCHAR(10)        NOT NULL
                                CONSTRAINT chk_card_types_class CHECK (product_class IN (N'CREDIT', N'DEBIT', N'PREPAID')),
    network                 NVARCHAR(20)        NOT NULL
                                CONSTRAINT chk_card_types_network CHECK (network IN (
                                    N'VISA', N'MASTERCARD', N'DISCOVER', N'AMEX', N'UNIONPAY'
                                )),
    tier                    NVARCHAR(20)        NOT NULL DEFAULT N'STANDARD'
                                CONSTRAINT chk_card_types_tier CHECK (tier IN (
                                    N'STANDARD', N'GOLD', N'PLATINUM', N'BLACK', N'INFINITE'
                                )),
    annual_fee              DECIMAL(10, 2)      NOT NULL DEFAULT 0.00,
    minimum_income          DECIMAL(12, 2)      NULL,
    -- Minimum internal credit score required for card issuance. NULL means no restriction
    minimum_credit_score    SMALLINT            NULL
                                CONSTRAINT chk_card_types_min_score CHECK (minimum_credit_score BETWEEN 0 AND 1000),
    description             NVARCHAR(MAX)       NULL,
    -- JSON array of benefit strings e.g. ["Airport lounge access","2x points on travel"]
    benefits                NVARCHAR(MAX)       NULL,
    is_active               BIT                 NOT NULL DEFAULT 1,
    created_at              DATETIMEOFFSET      NOT NULL DEFAULT SYSDATETIMEOFFSET(),
    updated_at              DATETIMEOFFSET      NOT NULL DEFAULT SYSDATETIMEOFFSET()
);
GO

INSERT INTO card.card_types (type_name, product_class, network, tier, annual_fee, description) VALUES
    (N'NOVOCARD_DEBIT_STANDARD',    N'DEBIT',   N'MASTERCARD', N'STANDARD', 0.00,   N'Standard debit card linked to checking account'),
    (N'NOVOCARD_CREDIT_STANDARD',   N'CREDIT',  N'VISA',       N'STANDARD', 149.90, N'Entry-level credit card for new customers'),
    (N'NOVOCARD_CREDIT_GOLD',       N'CREDIT',  N'MASTERCARD', N'GOLD',     299.90, N'Gold credit card with travel benefits'),
    (N'NOVOCARD_CREDIT_PLATINUM',   N'CREDIT',  N'VISA',       N'PLATINUM', 599.90, N'Platinum card with concierge and lounge access'),
    (N'NOVOCARD_CREDIT_BLACK',      N'CREDIT',  N'MASTERCARD', N'BLACK',    0.00,   N'Invite-only Black card with unlimited benefits'),
    (N'NOVOCARD_PREPAID_GIFT',      N'PREPAID', N'DISCOVER',   N'STANDARD', 0.00,   N'Single-use prepaid gift card'),
    (N'NOVOCARD_PREPAID_TRAVEL',    N'PREPAID', N'VISA',       N'STANDARD', 19.90,  N'Reloadable multi-currency travel prepaid card'),
    (N'NOVOCARD_PREPAID_CORPORATE', N'PREPAID', N'MASTERCARD', N'STANDARD', 0.00,   N'Corporate expense prepaid card managed by employer');
GO
