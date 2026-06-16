-- ============================================================
-- КАЧЕСТВЕННОЕ РЕШЕНИЕ: кэширование прогресса программ в БД
-- Заменяет медленные N+1 запросы на чтение 1 строки
-- ============================================================

-- 1. Добавляем столбцы для кэширования в user_programs
ALTER TABLE user_programs
ADD COLUMN IF NOT EXISTS progress_percent INTEGER NOT NULL DEFAULT 0,
ADD COLUMN IF NOT EXISTS is_completed BOOLEAN NOT NULL DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS day_progress JSONB,
ADD COLUMN IF NOT EXISTS last_progress_update TIMESTAMPTZ;

-- 2. Основная функция пересчёта прогресса (та же)
CREATE OR REPLACE FUNCTION recompute_user_program_progress(p_user_program_id INT)
RETURNS VOID AS $$
DECLARE
    overall_total BIGINT;
    overall_completed BIGINT;
    overall_percent INT;
    overall_completed_flag BOOLEAN;
    day_stats_json JSONB;
BEGIN
    -- Статистика по дням в JSON
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

    -- Общая статистика
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

-- 3. Триггерная функция для row-level триггера
-- Вызывается для каждой измененной строки, но выполняет пересчёт только один раз
CREATE OR REPLACE FUNCTION trigger_recompute_program_progress()
RETURNS TRIGGER AS $$
DECLARE
    affected_user_program_id INT;
BEGIN
    -- Получаем id программы из затронутой строки
    IF TG_OP = 'DELETE' THEN
        affected_user_program_id := OLD.id_user_program;
    ELSE
        affected_user_program_id := NEW.id_user_program;
    END IF;

    -- Пересчитываем, если это строка user_program_exercise_progress
    IF affected_user_program_id IS NOT NULL THEN
        PERFORM recompute_user_program_progress(affected_user_program_id);
    END IF;

    RETURN NULL;  -- AFTER trigger должен вернуть NULL
END;
$$ LANGUAGE plpgsql;

-- 4. Создаём row-level AFTER триггер (FOR EACH ROW)
DROP TRIGGER IF EXISTS trg_recompute_after_progress_change ON user_program_exercise_progress;

CREATE TRIGGER trg_recompute_after_progress_change
AFTER INSERT OR UPDATE OR DELETE ON user_program_exercise_progress
FOR EACH ROW
EXECUTE FUNCTION trigger_recompute_program_progress();

-- 5. Первичный пересчёт для существующих данных
DO $$ 
DECLARE
    r RECORD;
BEGIN
    FOR r IN SELECT DISTINCT id_user_program FROM user_program_exercise_progress LOOP
        PERFORM recompute_user_program_progress(r.id_user_program);
    END LOOP;
END $$;

-- ============================================================
-- ИНДЕКСЫ для ускорения
-- ============================================================
CREATE INDEX IF NOT EXISTS idx_user_program_exercise_progress_user_program 
ON user_program_exercise_progress(id_user_program, day_number, completed);

CREATE INDEX IF NOT EXISTS idx_user_programs_active 
ON user_programs(id_user, is_active) WHERE is_active = TRUE;

-- ============================================================
-- ВЕРИФИКАЦИЯ
-- ============================================================
-- Проверить созданные столбцы:
-- \d user_programs

-- Проверить триггер:
-- SELECT tgname, tgtype, tgenabled 
-- FROM pg_trigger 
-- WHERE tgrelid = 'user_program_exercise_progress'::regclass;

-- Тест: при обновлении одной записи прогресса поля в user_progments обновляются:
-- UPDATE user_program_exercise_progress SET completed = true WHERE id = 1;
-- SELECT progress_percent, is_completed FROM user_programs WHERE id = <id_user_program>;
