-- Таблицы для программ тренировок

CREATE TABLE public.programs (
    id SERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    description TEXT,
    duration_days INTEGER NOT NULL,
    difficulty TEXT NOT NULL,
    image TEXT,
    is_preset BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE public.program_days (
    id SERIAL PRIMARY KEY,
    id_program INTEGER NOT NULL REFERENCES public.programs(id) ON DELETE CASCADE,
    day_number INTEGER NOT NULL,
    id_workout INTEGER NOT NULL REFERENCES public.workouts(id) ON DELETE CASCADE
);

CREATE TABLE public.user_programs (
    id SERIAL PRIMARY KEY,
    id_user UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    id_program INTEGER NOT NULL REFERENCES public.programs(id) ON DELETE CASCADE,
    current_day INTEGER DEFAULT 1,
    started_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    completed_at TIMESTAMP WITH TIME ZONE,
    is_active BOOLEAN DEFAULT TRUE
);

-- Готовые программы
INSERT INTO public.programs (name, description, duration_days, difficulty, is_preset) VALUES
('Неделя новичка', 'Базовая программа для начинающих. 7 дней тренировок.', 7, 'начинающий', TRUE),
('Две недели', 'Программа на 14 дней для развития базовых навыков.', 14, 'средний', TRUE),
('Месяц мастера', 'Интенсивная программа на 30 дней для продвинутых.', 30, 'продвинутый', TRUE);

-- Связь дней программ с тренировками
INSERT INTO public.program_days (id_program, day_number, id_workout) VALUES
(1, 1, 5), (1, 2, 6), (1, 3, 1), (1, 4, 5), (1, 5, 7), (1, 6, 11), (1, 7, 2);

INSERT INTO public.program_days (id_program, day_number, id_workout) VALUES
(2, 1, 5), (2, 2, 6), (2, 3, 1), (2, 4, 7), (2, 5, 8), (2, 6, 2), (2, 7, 3),
(2, 8, 9), (2, 9, 5), (2, 10, 6), (2, 11, 1), (2, 12, 7), (2, 13, 4), (2, 14, 10);

INSERT INTO public.program_days (id_program, day_number, id_workout) VALUES
(3, 1, 1), (3, 2, 2), (3, 3, 3), (3, 4, 4), (3, 5, 7), (3, 6, 8), (3, 7, 9),
(3, 8, 10), (3, 9, 1), (3, 10, 2), (3, 11, 3), (3, 12, 7), (3, 13, 8), (3, 14, 9),
(3, 15, 5), (3, 16, 6), (3, 17, 1), (3, 18, 2), (3, 19, 3), (3, 20, 4),
(3, 21, 7), (3, 22, 8), (3, 23, 9), (3, 24, 10), (3, 25, 1), (3, 26, 2), (3, 27, 3), (3, 28, 5),
(3, 29, 6), (3, 30, 7);

-- Grants
GRANT ALL ON public.programs TO authenticated;
GRANT ALL ON public.programs TO service_role;
GRANT ALL ON public.program_days TO authenticated;
GRANT ALL ON public.program_days TO service_role;
GRANT ALL ON public.user_programs TO authenticated;
GRANT ALL ON public.user_programs TO service_role;

-- RLS
ALTER TABLE public.programs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.program_days ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_programs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view programs" ON public.programs FOR SELECT USING (TRUE);
CREATE POLICY "Anyone can view program_days" ON public.program_days FOR SELECT USING (TRUE);
CREATE POLICY "Users can manage their user_programs" ON public.user_programs FOR ALL USING (auth.uid() = id_user);