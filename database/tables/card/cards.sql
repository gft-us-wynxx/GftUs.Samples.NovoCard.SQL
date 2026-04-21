-- =============================================================================
-- Table: card.cards
-- Application: NovoCard
-- Description: Central table for issued cards. Each row represents a single
--              physical or virtual card belonging to a customer. Tracks the
--              full lifecycle from PENDING_ACTIVATION through to CANCELLED.
--              Card numbers are stored masked; the secure vault holds full PANs.
-- =============================================================================

CREATE TABLE IF NOT EXISTS card.cards (
    card_id             UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    customer_id         UUID            NOT NULL
                            REFERENCES customer.customers (customer_id),
    card_type_id        INTEGER         NOT NULL
                            REFERENCES card.card_types (card_type_id),
    design_id           UUID,

    -- Card identification (PCI-DSS compliant storage)
    masked_pan          VARCHAR(19)     NOT NULL,           -- e.g. 4111 **** **** 1234
    card_holder_name    VARCHAR(100)    NOT NULL,
    expiry_month        SMALLINT        NOT NULL CHECK (expiry_month BETWEEN 1 AND 12),
    expiry_year         SMALLINT        NOT NULL CHECK (expiry_year >= 2020),
    last_four_digits    CHAR(4)         NOT NULL
                            GENERATED ALWAYS AS (RIGHT(masked_pan, 4)) STORED,

    -- Card mode and channel
    card_format         VARCHAR(10)     NOT NULL DEFAULT 'PHYSICAL'
                            CHECK (card_format IN ('PHYSICAL', 'VIRTUAL', 'BOTH')),
    is_contactless      BOOLEAN         NOT NULL DEFAULT TRUE,
    is_online_enabled   BOOLEAN         NOT NULL DEFAULT TRUE,
    is_international    BOOLEAN         NOT NULL DEFAULT FALSE,

    -- Lifecycle
    status              VARCHAR(30)     NOT NULL DEFAULT 'PENDING_ACTIVATION'
                            CHECK (status IN (
                                'PENDING_ACTIVATION', 'ACTIVE', 'BLOCKED_TEMPORARY',
                                'BLOCKED_FRAUD', 'EXPIRED', 'CANCELLED', 'LOST', 'STOLEN'
                            )),
    issued_at           TIMESTAMPTZ     NOT NULL DEFAULT now(),
    activated_at        TIMESTAMPTZ,
    expires_at          TIMESTAMPTZ     GENERATED ALWAYS AS (
                            make_timestamptz(expiry_year, expiry_month, 1, 0, 0, 0, 'UTC')
                        ) STORED,
    last_used_at        TIMESTAMPTZ,
    cancelled_at        TIMESTAMPTZ,
    cancellation_reason VARCHAR(255),

    created_at          TIMESTAMPTZ     NOT NULL DEFAULT now(),
    updated_at          TIMESTAMPTZ     NOT NULL DEFAULT now()
);

CREATE INDEX idx_cards_customer_id      ON card.cards (customer_id);
CREATE INDEX idx_cards_card_type_id     ON card.cards (card_type_id);
CREATE INDEX idx_cards_status           ON card.cards (status);
CREATE INDEX idx_cards_last_four        ON card.cards (last_four_digits);
CREATE INDEX idx_cards_expires_at       ON card.cards (expires_at);
CREATE INDEX idx_cards_issued_at        ON card.cards (issued_at DESC);

COMMENT ON TABLE card.cards IS
    'Issued card registry for all NovoCard credit, debit, and prepaid cards.';
COMMENT ON COLUMN card.cards.masked_pan IS
    'PAN stored in masked format (e.g. 4111 **** **** 1234). Full PAN lives in the secure vault only.';
COMMENT ON COLUMN card.cards.card_format IS
    'PHYSICAL = embossed card sent by mail; VIRTUAL = digital-only; BOTH = physical + linked virtual.';
COMMENT ON COLUMN card.cards.status IS
    'BLOCKED_TEMPORARY: customer-initiated temporary lock. BLOCKED_FRAUD: system/analyst-initiated fraud hold.';
COMMENT ON COLUMN card.cards.design_id IS
    'FK to design.card_designs resolved after design assignment. NULL until a design is applied.';
