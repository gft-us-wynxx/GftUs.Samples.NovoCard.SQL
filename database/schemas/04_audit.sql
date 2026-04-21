-- =============================================================================
-- Schema: audit
-- Application: NovoCard
-- Description: Centralized audit trail schema. All significant mutations
--              across customer, card, and design schemas are recorded here
--              for compliance, dispute resolution, and forensic analysis.
-- =============================================================================

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = N'audit')
    EXEC(N'CREATE SCHEMA audit');
GO

-- -----------------------------------------------------------------------------
-- Table: audit.audit_log
-- Immutable record of every INSERT, UPDATE, and DELETE across all NovoCard
-- business tables. old_values / new_values are stored as JSON strings.
-- record_id holds the PK of the affected row cast to NVARCHAR for cross-table
-- compatibility.
-- -----------------------------------------------------------------------------
IF OBJECT_ID('audit.audit_log', 'U') IS NULL
CREATE TABLE audit.audit_log (
    log_id          BIGINT IDENTITY(1,1)    NOT NULL CONSTRAINT pk_audit_log PRIMARY KEY,
    schema_name     NVARCHAR(63)            NOT NULL,
    table_name      NVARCHAR(63)            NOT NULL,
    operation       NVARCHAR(10)            NOT NULL
                        CONSTRAINT chk_audit_operation CHECK (operation IN ('INSERT', 'UPDATE', 'DELETE')),
    record_id       NVARCHAR(100)           NOT NULL,
    old_values      NVARCHAR(MAX)           NULL,   -- JSON snapshot before change
    new_values      NVARCHAR(MAX)           NULL,   -- JSON snapshot after change
    changed_by      NVARCHAR(100)           NOT NULL DEFAULT SYSTEM_USER,
    changed_at      DATETIMEOFFSET          NOT NULL DEFAULT SYSDATETIMEOFFSET(),
    ip_address      VARCHAR(45)             NULL,   -- IPv4 or IPv6
    session_id      NVARCHAR(100)           NULL
);
GO

CREATE INDEX idx_audit_log_table      ON audit.audit_log (schema_name, table_name);
CREATE INDEX idx_audit_log_record     ON audit.audit_log (record_id);
CREATE INDEX idx_audit_log_changed_at ON audit.audit_log (changed_at DESC);
CREATE INDEX idx_audit_log_operation  ON audit.audit_log (operation);
GO
