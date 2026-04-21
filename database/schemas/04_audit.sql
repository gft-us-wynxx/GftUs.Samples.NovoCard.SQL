-- =============================================================================
-- Schema: audit
-- Application: NovoCard
-- Description: Centralized audit trail schema. All significant mutations
--              across customer, card, and design schemas are recorded here
--              for compliance, dispute resolution, and forensic analysis.
-- =============================================================================

CREATE SCHEMA IF NOT EXISTS audit;

CREATE TABLE IF NOT EXISTS audit.audit_log (
    log_id          BIGSERIAL       PRIMARY KEY,
    schema_name     VARCHAR(63)     NOT NULL,
    table_name      VARCHAR(63)     NOT NULL,
    operation       VARCHAR(10)     NOT NULL CHECK (operation IN ('INSERT', 'UPDATE', 'DELETE')),
    record_id       VARCHAR(100)    NOT NULL,
    old_values      JSONB,
    new_values      JSONB,
    changed_by      VARCHAR(100)    NOT NULL DEFAULT current_user,
    changed_at      TIMESTAMPTZ     NOT NULL DEFAULT now(),
    ip_address      INET,
    session_id      VARCHAR(100)
);

CREATE INDEX idx_audit_log_table      ON audit.audit_log (schema_name, table_name);
CREATE INDEX idx_audit_log_record     ON audit.audit_log (record_id);
CREATE INDEX idx_audit_log_changed_at ON audit.audit_log (changed_at DESC);
CREATE INDEX idx_audit_log_operation  ON audit.audit_log (operation);

COMMENT ON SCHEMA audit IS
    'Centralized audit log for all data mutations in the NovoCard platform.';
COMMENT ON TABLE audit.audit_log IS
    'Immutable record of every INSERT, UPDATE, and DELETE across all NovoCard business tables.';
COMMENT ON COLUMN audit.audit_log.record_id IS
    'Primary key value of the affected row, cast to text for cross-table compatibility.';
COMMENT ON COLUMN audit.audit_log.old_values IS
    'Full row snapshot before the change (NULL for INSERT).';
COMMENT ON COLUMN audit.audit_log.new_values IS
    'Full row snapshot after the change (NULL for DELETE).';
