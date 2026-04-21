-- =============================================================================
-- Table: card.cards
-- Application: NovoCard
-- Description: Central table for issued cards. Each row represents a single
--              physical or virtual card belonging to a customer. Tracks the
--              full lifecycle from PENDING_ACTIVATION through to CANCELLED.
--              Card numbers are stored masked; the secure vault holds full PANs.
-- =============================================================================

IF OBJECT_ID('card.cards', 'U') IS NULL
CREATE TABLE card.cards (
    card_id             UNIQUEIDENTIFIER    NOT NULL CONSTRAINT pk_cards PRIMARY KEY DEFAULT NEWID(),
    customer_id         UNIQUEIDENTIFIER    NOT NULL
                            CONSTRAINT fk_cards_customer REFERENCES customer.customers (customer_id),
    card_type_id        INT                 NOT NULL
                            CONSTRAINT fk_cards_card_type REFERENCES card.card_types (card_type_id),
    design_id           UNIQUEIDENTIFIER    NULL,   -- resolved after design assignment

    -- Card identification (PCI-DSS compliant storage)
    -- PAN stored in masked format e.g. 4111 **** **** 1234. Full PAN lives in the secure vault only
    masked_pan          NVARCHAR(19)        NOT NULL,
    card_holder_name    NVARCHAR(100)       NOT NULL,
    expiry_month        SMALLINT            NOT NULL CONSTRAINT chk_cards_expiry_month CHECK (expiry_month BETWEEN 1 AND 12),
    expiry_year         SMALLINT            NOT NULL CONSTRAINT chk_cards_expiry_year  CHECK (expiry_year >= 2020),
    last_four_digits    AS (RIGHT(masked_pan, 4)) PERSISTED,
    -- Computed card expiry as a DATETIMEOFFSET (first day of expiry month, UTC)
    expires_at          AS (TODATETIMEOFFSET(DATETIMEFROMPARTS(expiry_year, expiry_month, 1, 0, 0, 0, 0), 0)) PERSISTED,

    -- Card mode and channel
    -- PHYSICAL = embossed card sent by mail; VIRTUAL = digital-only; BOTH = physical + linked virtual
    card_format         NVARCHAR(10)        NOT NULL DEFAULT N'PHYSICAL'
                            CONSTRAINT chk_cards_format CHECK (card_format IN (N'PHYSICAL', N'VIRTUAL', N'BOTH')),
    is_contactless      BIT                 NOT NULL DEFAULT 1,
    is_online_enabled   BIT                 NOT NULL DEFAULT 1,
    is_international    BIT                 NOT NULL DEFAULT 0,

    -- Lifecycle
    -- BLOCKED_TEMPORARY: customer-initiated lock. BLOCKED_FRAUD: system/analyst fraud hold
    status              NVARCHAR(30)        NOT NULL DEFAULT N'PENDING_ACTIVATION'
                            CONSTRAINT chk_cards_status CHECK (status IN (
                                N'PENDING_ACTIVATION', N'ACTIVE', N'BLOCKED_TEMPORARY',
                                N'BLOCKED_FRAUD', N'EXPIRED', N'CANCELLED', N'LOST', N'STOLEN'
                            )),
    issued_at           DATETIMEOFFSET      NOT NULL DEFAULT SYSDATETIMEOFFSET(),
    activated_at        DATETIMEOFFSET      NULL,
    last_used_at        DATETIMEOFFSET      NULL,
    cancelled_at        DATETIMEOFFSET      NULL,
    cancellation_reason NVARCHAR(255)       NULL,

    created_at          DATETIMEOFFSET      NOT NULL DEFAULT SYSDATETIMEOFFSET(),
    updated_at          DATETIMEOFFSET      NOT NULL DEFAULT SYSDATETIMEOFFSET()
);
GO

CREATE INDEX idx_cards_customer_id  ON card.cards (customer_id);
CREATE INDEX idx_cards_card_type_id ON card.cards (card_type_id);
CREATE INDEX idx_cards_status       ON card.cards (status);
CREATE INDEX idx_cards_last_four    ON card.cards (last_four_digits);
CREATE INDEX idx_cards_expires_at   ON card.cards (expires_at);
CREATE INDEX idx_cards_issued_at    ON card.cards (issued_at DESC);
GO
