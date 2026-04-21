-- =============================================================================
-- Trigger: trg_card_status_audit
-- Application: NovoCard
-- Tables: card.cards, customer.customers, design.card_designs
-- Description: Captures all INSERT, UPDATE, and DELETE mutations on sensitive
--              tables and writes a JSONB snapshot to audit.audit_log. Provides
--              a tamper-evident audit trail for compliance and forensic analysis.
--              Fires AFTER the DML statement to capture committed values.
-- =============================================================================

-- ── Trigger function ──────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION audit.fn_capture_audit()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_record_id     VARCHAR(100);
    v_old_values    JSONB;
    v_new_values    JSONB;
BEGIN
    IF TG_OP = 'DELETE' THEN
        v_record_id  := OLD.ctid::TEXT;    -- fallback; tables should expose a known PK alias
        v_old_values := to_jsonb(OLD);
        v_new_values := NULL;
    ELSIF TG_OP = 'INSERT' THEN
        v_record_id  := NEW.ctid::TEXT;
        v_old_values := NULL;
        v_new_values := to_jsonb(NEW);
    ELSE  -- UPDATE
        v_record_id  := NEW.ctid::TEXT;
        v_old_values := to_jsonb(OLD);
        v_new_values := to_jsonb(NEW);
    END IF;

    INSERT INTO audit.audit_log (
        schema_name, table_name, operation,
        record_id, old_values, new_values,
        changed_by, changed_at
    ) VALUES (
        TG_TABLE_SCHEMA, TG_TABLE_NAME, TG_OP,
        v_record_id, v_old_values, v_new_values,
        current_user, now()
    );

    RETURN NULL;  -- AFTER trigger; return value ignored
END;
$$;

-- ── Apply to card.cards ───────────────────────────────────────────────────────

CREATE OR REPLACE TRIGGER trg_cards_audit
AFTER INSERT OR UPDATE OR DELETE
ON card.cards
FOR EACH ROW
EXECUTE FUNCTION audit.fn_capture_audit();

-- ── Apply to customer.customers ───────────────────────────────────────────────

CREATE OR REPLACE TRIGGER trg_customers_audit
AFTER INSERT OR UPDATE OR DELETE
ON customer.customers
FOR EACH ROW
EXECUTE FUNCTION audit.fn_capture_audit();

-- ── Apply to design.card_designs ─────────────────────────────────────────────

CREATE OR REPLACE TRIGGER trg_card_designs_audit
AFTER INSERT OR UPDATE OR DELETE
ON design.card_designs
FOR EACH ROW
EXECUTE FUNCTION audit.fn_capture_audit();

COMMENT ON FUNCTION audit.fn_capture_audit IS
    'Generic AFTER trigger function that serializes the affected row to JSONB and writes to audit.audit_log.';
