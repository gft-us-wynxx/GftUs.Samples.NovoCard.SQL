-- =============================================================================
-- Table: card.card_status_history
-- Application: NovoCard
-- Description: Immutable ledger of all card status transitions. Every time a
--              card moves from one status to another (e.g. ACTIVE -> BLOCKED_FRAUD)
--              a row is appended here. Used for compliance reporting and customer
--              dispute investigations.
-- =============================================================================

IF OBJECT_ID('card.card_status_history', 'U') IS NULL
CREATE TABLE card.card_status_history (
    history_id      BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT pk_card_status_history PRIMARY KEY,
    card_id         UNIQUEIDENTIFIER    NOT NULL
                        CONSTRAINT fk_status_history_card REFERENCES card.cards (card_id) ON DELETE CASCADE,
    previous_status NVARCHAR(30)        NOT NULL,
    new_status      NVARCHAR(30)        NOT NULL,
    reason          NVARCHAR(255)       NULL,
    -- Actor that triggered the status change. FRAUD_ENGINE = automated rule engine
    initiated_by    NVARCHAR(20)        NOT NULL
                        CONSTRAINT chk_status_history_initiator CHECK (initiated_by IN (
                            N'CUSTOMER', N'SYSTEM', N'RISK_ANALYST', N'FRAUD_ENGINE', N'SUPPORT'
                        )),
    -- Internal user ID when initiated_by is RISK_ANALYST or SUPPORT
    operator_id     NVARCHAR(100)       NULL,
    -- Channel through which the status change was requested
    channel         NVARCHAR(20)        NULL
                        CONSTRAINT chk_status_history_channel CHECK (channel IN (
                            N'APP', N'WEB', N'IVR', N'BRANCH', N'API', N'BATCH'
                        )),
    ip_address      VARCHAR(45)         NULL,   -- IPv4 or IPv6
    changed_at      DATETIMEOFFSET      NOT NULL DEFAULT SYSDATETIMEOFFSET()
);
GO

CREATE INDEX idx_card_status_history_card_id    ON card.card_status_history (card_id);
CREATE INDEX idx_card_status_history_changed_at ON card.card_status_history (changed_at DESC);
CREATE INDEX idx_card_status_history_new_status ON card.card_status_history (new_status);
GO
