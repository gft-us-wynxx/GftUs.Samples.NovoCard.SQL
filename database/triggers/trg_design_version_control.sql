-- =============================================================================
-- Trigger: trg_design_version_control
-- Application: NovoCard
-- Tables: design.design_templates, design.card_designs
-- Description: Two related triggers:
--
--  1. trg_template_updated_at  — Keeps design_templates.updated_at current on
--     every UPDATE without requiring callers to set the column explicitly.
--
--  2. trg_enforce_single_current_design — AFTER INSERT/UPDATE on card_designs.
--     When is_current is set to 1 for a card, automatically sets is_current = 0
--     on all other designs for that card, ensuring the "only one current design
--     per card" invariant at the database level.
--
-- Notes:
--   trg_enforce_single_current_design uses @@NESTLEVEL to prevent recursive
--   firing when the trigger itself updates other card_design rows.
-- =============================================================================

-- ── 1. Auto-update updated_at on design_templates ────────────────────────────

CREATE OR ALTER TRIGGER trg_template_updated_at
ON design.design_templates
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE design.design_templates
    SET    updated_at = SYSDATETIMEOFFSET()
    FROM   design.design_templates dt
    INNER JOIN INSERTED i ON i.template_id = dt.template_id;
END;
GO

-- ── 2. Enforce single current design per card ─────────────────────────────────

CREATE OR ALTER TRIGGER trg_enforce_single_current_design
ON design.card_designs
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    -- Prevent recursive firing: this trigger's own UPDATE would re-fire it
    IF @@NESTLEVEL > 1 RETURN;

    -- For every inserted/updated row that sets is_current = 1, retire all
    -- other current designs for the same card
    UPDATE design.card_designs
    SET    is_current   = 0,
           replaced_at  = SYSDATETIMEOFFSET()
    FROM   design.card_designs cd
    INNER JOIN INSERTED i
        ON  i.card_id  = cd.card_id
        AND i.is_current = 1
        AND cd.design_id <> i.design_id
        AND cd.is_current = 1;
END;
GO
