-- ============================================================================
-- MIGRATION 3: Repair duplicate index and create triggers for program progress
-- ============================================================================

-- Step 1: Drop the duplicate pre-trigger index (the AFTER trigger is the canonical one)
DROP INDEX IF EXISTS idx_user_program_exercise_progress_completed;

-- Step 2: Create the recompute function (idempotent - safe to run multiple times)
CREATE OR REPLACE FUNCTION recompute_user_program_progress(p_user_program_id INT)
RETURNS VOID AS $$
DECLARE
    overall_total BIGINT;
    overall_completed BIGINT;
    overall_percent INT;
    overall_completed_flag BOOLEAN;
    day_stats_json JSONB;
BEGIN
    SELECT json_object_agg(day_number, json_build_object(
                'total', day_total,
                'completed', day_completed,
                'percent', day_percent,
                'is_completed', is_day_completed
            ) ORDER BY day_number)
    INTO day_stats_json
    FROM (
        SELECT
            day_number,
            COUNT(*) as day_total,
            COUNT(*) FILTER (WHERE completed) as day_completed,
            ROUND(COUNT(*) FILTER (WHERE completed) * 100.0 / COUNT(*)) as day_percent,
            (COUNT(*) = COUNT(*) FILTER (WHERE completed)) as is_day_completed
        FROM user_program_exercise_progress
        WHERE id_user_program = p_user_program_id
        GROUP BY day_number
    ) d;

    SELECT COUNT(*), COUNT(*) FILTER (WHERE completed)
    INTO overall_total, overall_completed
    FROM user_program_exercise_progress
    WHERE id_user_program = p_user_program_id;

    overall_percent := CASE
                        WHEN overall_total > 0 THEN ROUND(overall_completed * 100.0 / overall_total)
                        ELSE 0
                       END;
    overall_completed_flag := (overall_total > 0 AND overall_completed = overall_total);

    UPDATE user_programs
    SET progress_percent = overall_percent,
        is_completed = overall_completed_flag,
        day_progress = day_stats_json,
        last_progress_update = NOW()
    WHERE id = p_user_program_id;
END;
$$ LANGUAGE plpgsql;

-- Step 3: Create trigger function (idempotent)
CREATE OR REPLACE FUNCTION trigger_recompute_program_progress()
RETURNS TRIGGER AS $$
DECLARE
    affected_user_program_id INT;
BEGIN
    IF TG_OP = 'DELETE' THEN
        affected_user_program_id := OLD.id_user_program;
    ELSE
        affected_user_program_id := NEW.id_user_program;
    END IF;

    IF affected_user_program_id IS NOT NULL THEN
        PERFORM recompute_user_program_progress(affected_user_program_id);
    END IF;

    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Step 4: Drop and recreate trigger (idempotent)
DROP TRIGGER IF EXISTS trg_recompute_after_progress_change ON user_program_exercise_progress;

CREATE TRIGGER trg_recompute_after_progress_change
AFTER INSERT OR UPDATE OR DELETE ON user_program_exercise_progress
FOR EACH ROW
EXECUTE FUNCTION trigger_recompute_program_progress();

-- Step 5: Backfill progress for all existing user_programs
DO $$
DECLARE
    r RECORD;
BEGIN
    FOR r IN SELECT DISTINCT id_user_program FROM user_program_exercise_progress LOOP
        PERFORM recompute_user_program_progress(r.id_user_program);
    END LOOP;
END $$;

-- Verification:
-- SELECT id, progress_percent, is_completed FROM user_programs LIMIT 5;
