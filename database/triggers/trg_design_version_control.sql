-- =============================================================================
-- Trigger: trg_design_version_control
-- Application: NovoCard
-- Tables: design.design_templates, design.card_designs
-- Description: Two related triggers:
--
--  1. trg_template_updated_at  — Keeps design_templates.updated_at current on
--     every UPDATE without requiring callers to set the column explicitly.
--
--  2. trg_enforce_single_current_design — BEFORE INSERT/UPDATE on card_designs.
--     When is_current is being set to TRUE for a card, automatically sets
--     is_current = FALSE on all other designs for that card, ensuring the
--     "only one current design per card" invariant at the database level.
-- =============================================================================

-- ── 1. Auto-update updated_at on design_templates ────────────────────────────

CREATE OR REPLACE FUNCTION design.fn_template_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.updated_at := now();
    RETURN NEW;
END;
$$;

CREATE OR REPLACE TRIGGER trg_template_updated_at
BEFORE UPDATE
ON design.design_templates
FOR EACH ROW
EXECUTE FUNCTION design.fn_template_updated_at();

-- ── 2. Enforce single current design per card ─────────────────────────────────

CREATE OR REPLACE FUNCTION design.fn_enforce_single_current_design()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    IF NEW.is_current = TRUE THEN
        UPDATE design.card_designs
        SET    is_current  = FALSE,
               replaced_at = now()
        WHERE  card_id     = NEW.card_id
          AND  design_id  <> NEW.design_id
          AND  is_current  = TRUE;
    END IF;

    RETURN NEW;
END;
$$;

CREATE OR REPLACE TRIGGER trg_enforce_single_current_design
BEFORE INSERT OR UPDATE OF is_current
ON design.card_designs
FOR EACH ROW
WHEN (NEW.is_current = TRUE)
EXECUTE FUNCTION design.fn_enforce_single_current_design();

COMMENT ON FUNCTION design.fn_template_updated_at IS
    'Automatically refreshes updated_at on design_templates rows on every UPDATE.';
COMMENT ON FUNCTION design.fn_enforce_single_current_design IS
    'Ensures only one card_design per card has is_current=TRUE by retiring all others before insert/update.';
