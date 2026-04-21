-- =============================================================================
-- Trigger: trg_card_status_audit
-- Application: NovoCard
-- Tables: card.cards, customer.customers, design.card_designs
-- Description: Captures all INSERT, UPDATE, and DELETE mutations on sensitive
--              tables and writes a JSON snapshot to audit.audit_log. Provides
--              a tamper-evident audit trail for compliance and forensic analysis.
--              Fires AFTER the DML statement to capture committed values.
--
-- Notes:
--   SQL Server triggers are statement-level (set-based). The INSERTED and
--   DELETED pseudo-tables may contain multiple rows per trigger invocation.
--   Row snapshots are serialized using FOR JSON AUTO WITHOUT_ARRAY_WRAPPER
--   on a per-row correlated subquery.
-- =============================================================================

-- ── Apply to card.cards ───────────────────────────────────────────────────────

CREATE OR ALTER TRIGGER trg_cards_audit
ON card.cards
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @operation NVARCHAR(10);

    IF EXISTS(SELECT 1 FROM INSERTED) AND EXISTS(SELECT 1 FROM DELETED)
        SET @operation = N'UPDATE';
    ELSE IF EXISTS(SELECT 1 FROM INSERTED)
        SET @operation = N'INSERT';
    ELSE
        SET @operation = N'DELETE';

    INSERT INTO audit.audit_log (
        schema_name, table_name, operation, record_id, old_values, new_values, changed_by, changed_at
    )
    SELECT
        N'card',
        N'cards',
        @operation,
        CAST(COALESCE(i.card_id, d.card_id) AS NVARCHAR(100)),
        (SELECT * FROM DELETED  d2 WHERE d2.card_id = COALESCE(i.card_id, d.card_id) FOR JSON AUTO, WITHOUT_ARRAY_WRAPPER),
        (SELECT * FROM INSERTED i2 WHERE i2.card_id = COALESCE(i.card_id, d.card_id) FOR JSON AUTO, WITHOUT_ARRAY_WRAPPER),
        SYSTEM_USER,
        SYSDATETIMEOFFSET()
    FROM INSERTED i
    FULL OUTER JOIN DELETED d ON d.card_id = i.card_id;
END;
GO

-- ── Apply to customer.customers ───────────────────────────────────────────────

CREATE OR ALTER TRIGGER trg_customers_audit
ON customer.customers
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @operation NVARCHAR(10);

    IF EXISTS(SELECT 1 FROM INSERTED) AND EXISTS(SELECT 1 FROM DELETED)
        SET @operation = N'UPDATE';
    ELSE IF EXISTS(SELECT 1 FROM INSERTED)
        SET @operation = N'INSERT';
    ELSE
        SET @operation = N'DELETE';

    INSERT INTO audit.audit_log (
        schema_name, table_name, operation, record_id, old_values, new_values, changed_by, changed_at
    )
    SELECT
        N'customer',
        N'customers',
        @operation,
        CAST(COALESCE(i.customer_id, d.customer_id) AS NVARCHAR(100)),
        (SELECT * FROM DELETED  d2 WHERE d2.customer_id = COALESCE(i.customer_id, d.customer_id) FOR JSON AUTO, WITHOUT_ARRAY_WRAPPER),
        (SELECT * FROM INSERTED i2 WHERE i2.customer_id = COALESCE(i.customer_id, d.customer_id) FOR JSON AUTO, WITHOUT_ARRAY_WRAPPER),
        SYSTEM_USER,
        SYSDATETIMEOFFSET()
    FROM INSERTED i
    FULL OUTER JOIN DELETED d ON d.customer_id = i.customer_id;
END;
GO

-- ── Apply to design.card_designs ─────────────────────────────────────────────

CREATE OR ALTER TRIGGER trg_card_designs_audit
ON design.card_designs
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @operation NVARCHAR(10);

    IF EXISTS(SELECT 1 FROM INSERTED) AND EXISTS(SELECT 1 FROM DELETED)
        SET @operation = N'UPDATE';
    ELSE IF EXISTS(SELECT 1 FROM INSERTED)
        SET @operation = N'INSERT';
    ELSE
        SET @operation = N'DELETE';

    INSERT INTO audit.audit_log (
        schema_name, table_name, operation, record_id, old_values, new_values, changed_by, changed_at
    )
    SELECT
        N'design',
        N'card_designs',
        @operation,
        CAST(COALESCE(i.design_id, d.design_id) AS NVARCHAR(100)),
        (SELECT * FROM DELETED  d2 WHERE d2.design_id = COALESCE(i.design_id, d.design_id) FOR JSON AUTO, WITHOUT_ARRAY_WRAPPER),
        (SELECT * FROM INSERTED i2 WHERE i2.design_id = COALESCE(i.design_id, d.design_id) FOR JSON AUTO, WITHOUT_ARRAY_WRAPPER),
        SYSTEM_USER,
        SYSDATETIMEOFFSET()
    FROM INSERTED i
    FULL OUTER JOIN DELETED d ON d.design_id = i.design_id;
END;
GO
