-- =============================================================================
-- Table: card.card_status_history
-- Application: NovoCard
-- Description: Immutable ledger of all card status transitions. Every time a
--              card moves from one status to another (e.g. ACTIVE → BLOCKED_FRAUD)
--              a row is appended here. Used for compliance reporting and customer
--              dispute investigations.
-- =============================================================================

CREATE TABLE IF NOT EXISTS card.card_status_history (
    history_id      BIGSERIAL       PRIMARY KEY,
    card_id         UUID            NOT NULL
                        REFERENCES card.cards (card_id) ON DELETE CASCADE,
    previous_status VARCHAR(30)     NOT NULL,
    new_status      VARCHAR(30)     NOT NULL,
    reason          VARCHAR(255),
    initiated_by    VARCHAR(20)     NOT NULL
                        CHECK (initiated_by IN ('CUSTOMER', 'SYSTEM', 'RISK_ANALYST', 'FRAUD_ENGINE', 'SUPPORT')),
    operator_id     VARCHAR(100),
    channel         VARCHAR(20)     CHECK (channel IN ('APP', 'WEB', 'IVR', 'BRANCH', 'API', 'BATCH')),
    ip_address      INET,
    changed_at      TIMESTAMPTZ     NOT NULL DEFAULT now()
);

CREATE INDEX idx_card_status_history_card_id    ON card.card_status_history (card_id);
CREATE INDEX idx_card_status_history_changed_at ON card.card_status_history (changed_at DESC);
CREATE INDEX idx_card_status_history_new_status ON card.card_status_history (new_status);

COMMENT ON TABLE card.card_status_history IS
    'Append-only log of all card status transitions in the NovoCard platform.';
COMMENT ON COLUMN card.card_status_history.initiated_by IS
    'Actor that triggered the status change. FRAUD_ENGINE = automated rule engine.';
COMMENT ON COLUMN card.card_status_history.operator_id IS
    'Internal user ID when initiated_by is RISK_ANALYST or SUPPORT.';
COMMENT ON COLUMN card.card_status_history.channel IS
    'Channel through which the status change was requested.';
