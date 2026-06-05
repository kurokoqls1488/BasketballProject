-- ============================================================================
-- MIGRATION 2: Composite index for program progress queries
-- ============================================================================

CREATE INDEX IF NOT EXISTS idx_user_program_exercise_progress_program_day
    ON user_program_exercise_progress (id_user_program, day_number, completed);

-- Verify:
-- SELECT indexname FROM pg_indexes WHERE indexname = 'idx_user_program_exercise_progress_program_day';
