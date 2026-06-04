-- ============================================================================
-- ПОЛНЫЙ ИНИЦИАЛИЗАЦИОННЫЙ СКРИПТ БАЗЫ ДАННЫХ ДЛЯ SUPABASE
-- Basketball Training App
-- ============================================================================
-- Этот скрипт completely удаляет и пересоздает всю базу данных.
-- Запускается один раз для инициализации или полного сброса БД.
-- ============================================================================

-- ============================================================================
-- ШАГ 1: Очистка - Полное удаление схемы public и создание заново
-- ============================================================================

-- Удаление схемы public со всеми объектами (полный сброс)
DROP SCHEMA IF EXISTS public CASCADE;
-- Создание пустой схемы public
CREATE SCHEMA public;

-- ============================================================================
-- ШАГ 2: Создание таблиц
-- ============================================================================

-- Справочник ролей
CREATE TABLE public.roles (
    id smallint NOT NULL,
    name_role text NOT NULL,
    PRIMARY KEY (id)
);

-- Основная таблица пользователей (связана с Supabase Auth)
CREATE TABLE public.users (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    display_id SERIAL UNIQUE NOT NULL,
    nickname text NOT NULL,
    email text NOT NULL,
    id_role smallint NOT NULL DEFAULT 2,
    avatar_url text,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Комплексы упражнений
CREATE TABLE public.complexes (
    id integer NOT NULL,
    name_complex text NOT NULL,
    image text NOT NULL,
    description text,
    PRIMARY KEY (id)
);

-- Упражнения
CREATE TABLE public.exercises (
    id smallint NOT NULL,
    id_user UUID NOT NULL,
    name_exercise text NOT NULL,
    image text NOT NULL,
    video text NOT NULL,
    description text NOT NULL,
    recommended_duration_seconds integer,
    PRIMARY KEY (id)
);

-- Тренировки
CREATE TABLE public.workouts (
    id integer NOT NULL,
    id_complex integer NOT NULL,
    duration integer NOT NULL,
    id_user UUID NOT NULL,
    name_workout text NOT NULL,
    PRIMARY KEY (id),
    CONSTRAINT check_duration_positive CHECK (duration > 0)
);

-- Таблица для избранных упражнений пользователей
CREATE TABLE public.favorites_exercises (
    id BIGSERIAL PRIMARY KEY,
    id_user UUID NOT NULL,
    id_exercise smallint NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    CONSTRAINT unique_favorite_exercise_per_user UNIQUE (id_user, id_exercise)
);

-- Таблица для избранных тренировок пользователей
CREATE TABLE public.favorites_workouts (
    id BIGSERIAL PRIMARY KEY,
    id_user UUID NOT NULL,
    id_workout integer NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    CONSTRAINT unique_favorite_workout_per_user UNIQUE (id_user, id_workout)
);

-- Связь тренировок и упражнений (многие-ко-многим)
CREATE TABLE public.workouts_exercises (
    id SERIAL PRIMARY KEY,
    id_workout integer NOT NULL,
    id_exercise smallint NOT NULL
);

-- ============================================================================
-- ШАГ 3: Таблицы для программ тренировок
-- ============================================================================

-- Программы тренировок
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

-- Дни программ (связь программ, дней и тренировок)
CREATE TABLE public.program_days (
    id SERIAL PRIMARY KEY,
    id_program INTEGER NOT NULL REFERENCES public.programs(id) ON DELETE CASCADE,
    day_number INTEGER NOT NULL,
    id_workout INTEGER NOT NULL REFERENCES public.workouts(id) ON DELETE CASCADE
);

-- Прогресс пользователей по программам
CREATE TABLE public.user_programs (
    id SERIAL PRIMARY KEY,
    id_user UUID NOT NULL,
    id_program INTEGER NOT NULL REFERENCES public.programs(id) ON DELETE CASCADE,
    current_day INTEGER DEFAULT 1,
    started_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    completed_at TIMESTAMP WITH TIME ZONE,
    is_active BOOLEAN DEFAULT TRUE
);

-- Сброс sequence для user_programs (на будущее, если будут INSERT с явными id)
SELECT setval('public.user_programs_id_seq', COALESCE((SELECT MAX(id) FROM public.user_programs), 1));

-- ============================================================================
-- ШАГ 4: Заполнение таблиц данными
-- ============================================================================

-- Роли пользователей
INSERT INTO public.roles (id, name_role) VALUES
(1, 'Администратор'),
(2, 'Пользователь'),
(3, 'Главный администратор');

-- Комплексы упражнений
INSERT INTO public.complexes (id, name_complex, image, description) VALUES
(1, 'Бросок', 'images/brosok.jpg', 'Бросок в баскетболе — это координированное движение всего тела от ног до кисти, которое начинается с устойчивой стойки, небольшого приседа и заканчивается точным направлением мяча в корзину.'),
(2, 'Дриблинг', 'images/drible.jpg', 'Дриблинг в баскетболе — это способ перемещения с мячом, при котором игрок ударяет им об пол одной или обеими руками для продвижения мимо защитника.'),
(3, 'Завершение', 'images/finished.jpg', 'Завершения из-под кольца в баскетболе — это броски, выполняемые в непосредственной близости от корзины, такие как лэй-ап и лэй-ин, а также слэм-данк.'),
(4, 'Передача', 'images/pass.jpg', 'Передача в баскетболе — это прием, с помощью которого игрок направляет мяч партнеру для продолжения атаки.'),
(5, 'Вертикальный прыжок', 'images/jump.jpg', 'Вертикальный прыжок — это движение, при котором человек подпрыгивает вверх, используя силу мышц ног.'),
(6, 'Реабилитация', 'images/reabilitation.jpg', 'Реабилитация — это комплексный процесс восстановления спортсмена после травмы или интенсивных нагрузок.');

-- Демо-пользователь (обязательно должен существовать для внешних ключей)
INSERT INTO public.users (id, nickname, email, id_role) VALUES
('2182419d-8da0-4331-bd92-99bee0870f36', 'Demo User', 'demo@example.com', 2);

-- Упражнения (ВНИМАНИЕ: id_user должен быть реальным UUID пользователя)
INSERT INTO public.exercises (id, id_user, name_exercise, image, video, description, recommended_duration_seconds) VALUES
(1, '2182419d-8da0-4331-bd92-99bee0870f36', 'Бросок после шага от трехочковой линии', 'Изображение 1', 'Видео 1', 'Встаньте за трехочковой линией, сделайте широкий шаг с ведением и бросайте мяч в кольцо', NULL),
(2, '2182419d-8da0-4331-bd92-99bee0870f36', 'Броски с шагом в сторону', 'Изображение 2', 'Видео 2', 'Встаньте на 3-4 метрах от кольца, соберите ноги вместе, сделайте широкий шаг в бок и выполните бросок', NULL),
(3, '2182419d-8da0-4331-bd92-99bee0870f36', 'Броски после разворота на 180', 'Изображение 3', 'Видео 3', 'Встаньте спиной к кольцу на расстоянии 3-4 метра, ноги вместе и в прыжке разворачивайтесь на 180 градусов и выполните бросок', NULL),
(4, '2182419d-8da0-4331-bd92-99bee0870f36', 'V - переводы перед собой', 'Изображение 4', 'Видео 4', 'Встаньте в стойку, переводите мяч между ног перед собой с одной руки в другую', NULL),
(5, '2182419d-8da0-4331-bd92-99bee0870f36', 'Восьмерка', 'Изображение 5', 'Видео 5', 'Встаньте в стойку, делайте переводы между ног с одной руки в другую, образуя восьмерка', NULL),
(6, '2182419d-8da0-4331-bd92-99bee0870f36', 'Переводы за спиной', 'Изображение 6', 'Видео 6', 'Встаньте в стойку, переводите мяч за спиной с одной руки в другую руку', NULL),
(7, '2182419d-8da0-4331-bd92-99bee0870f36', 'Броски одной рукой об щиток', 'Изображение 7', 'Видео 7', 'Встаньте перед щитком, возьмите мяч в одну руку и бросайте об щит, в прыжке ловите и тут же бросайте', NULL),
(8, '2182419d-8da0-4331-bd92-99bee0870f36', 'Евростеп', 'Изображение 8', 'Видео 8', 'Встаньте от кольца в 5-6 метрах, побегите к кольцу, на 1-2 метрах сделайте напрыжку в сторону', NULL),
(9, '2182419d-8da0-4331-bd92-99bee0870f36', 'Флоатер', 'Изображение 9', 'Видео 9', 'Встаньте в 5-6 метрах от кольца, побегите в сторону кольца и бросьте мяч в 2-3 метрах, толкая мяч одной рукой', NULL),
(10, '2182419d-8da0-4331-bd92-99bee0870f36', 'Передача от груди', 'Изображение 10', 'Видео 10', 'Встаньте напротив стены или человека, сделайте передачу мяча от груди ровно вперед', NULL),
(11, '2182419d-8da0-4331-bd92-99bee0870f36', 'Передача с отскоком об пол', 'Изображение 11', 'Видео 11', 'Встаньте напротив стены или человека, сделайте передачу в пол так чтобы мяч отскочил от стены или чтобы попал в руки к напарнику', NULL),
(12, '2182419d-8da0-4331-bd92-99bee0870f36', 'Передача над головой', 'Изображение 12', 'Видео 12', 'Встаньте напротив стены или человека, возьмите мяч над головой и сделайте передачу двумя руками', NULL),
(13, '2182419d-8da0-4331-bd92-99bee0870f36', 'Прыжки с колен', 'Изображение 13', 'Видео 13', 'Встаньте на колени, сделайте прыжок при помощи рук и корпуса, встав на ноги', NULL),
(14, '2182419d-8da0-4331-bd92-99bee0870f36', 'Прыжки со скамейки', 'Изображение 14', 'Видео 14', 'Сядьте на скамейку и сделайте максимальный прыжок вставая со скамейки', NULL),
(15, '2182419d-8da0-4331-bd92-99bee0870f36', 'Прыжки на месте', 'Изображение 15', 'Видео 15', 'Встаньте, поставьте руки на пояс и прыгайте на максимум', NULL),
(16, '2182419d-8da0-4331-bd92-99bee0870f36', 'Подъемы на икры', 'Изображение 16', 'Видео 16', 'Вставайте на носки на месте', NULL),
(17, '2182419d-8da0-4331-bd92-99bee0870f36', 'Ротация голеностопа с резинкой', 'Изображение 17', 'Видео 17', 'Привяжите резинку к чему-нибудь и делайте ротационные движения во внутрь', NULL),
(18, '2182419d-8da0-4331-bd92-99bee0870f36', 'Ходьба на пятках', 'Изображение 18', 'Видео 18', 'Встаньте на пятки и идите вперед', NULL);

-- Тренировки (ВНИМАНИЕ: id_user должен быть реальным UUID пользователя)
INSERT INTO public.workouts (id, id_complex, duration, id_user, name_workout) VALUES
(1, 1, 15, '2182419d-8da0-4331-bd92-99bee0870f36', 'Тренировка средних бросков'),
(2, 1, 20, '2182419d-8da0-4331-bd92-99bee0870f36', 'Броски с трехочковой линии'),
(3, 1, 25, '2182419d-8da0-4331-bd92-99bee0870f36', 'Тренировка бросков Стефа Карри'),
(4, 1, 15, '2182419d-8da0-4331-bd92-99bee0870f36', 'Тренировка штрафных бросков'),
(5, 1, 10, '2182419d-8da0-4331-bd92-99bee0870f36', 'Бросковая разминка'),
(6, 2, 10, '2182419d-8da0-4331-bd92-99bee0870f36', 'Разминка дриблинга'),
(7, 2, 20, '2182419d-8da0-4331-bd92-99bee0870f36', 'Тренировка Кайри Ирвинга'),
(8, 2, 15, '2182419d-8da0-4331-bd92-99bee0870f36', 'Тренировка на чувство мяча'),
(9, 2, 25, '2182419d-8da0-4331-bd92-99bee0870f36', 'Тренировка дриблинга с двумя мячами'),
(10, 3, 15, '2182419d-8da0-4331-bd92-99bee0870f36', 'Тренировка завершений в воздухе под кольцом'),
(11, 3, 10, '2182419d-8da0-4331-bd92-99bee0870f36', 'Разминка завершений'),
(12, 3, 24, '2182419d-8da0-4331-bd92-99bee0870f36', 'Тренировка завершений атак'),
(13, 4, 10, '2182419d-8da0-4331-bd92-99bee0870f36', 'Разминка передач в стену'),
(14, 4, 15, '2182419d-8da0-4331-bd92-99bee0870f36', 'Тренировка передач в паре'),
(15, 4, 25, '2182419d-8da0-4331-bd92-99bee0870f36', 'Тренировка передач со стеной'),
(16, 5, 10, '2182419d-8da0-4331-bd92-99bee0870f36', 'Реабилитация голеностопа'),
(17, 5, 20, '2182419d-8da0-4331-bd92-99bee0870f36', 'Взрывная тренировка прыжков'),
(18, 5, 35, '2182419d-8da0-4331-bd92-99bee0870f36', 'Тренировка силы ног в тренажерном зале'),
(19, 6, 10, '2182419d-8da0-4331-bd92-99bee0870f36', 'Реабилитация голеностопа'),
(20, 6, 10, '2182419d-8da0-4331-bd92-99bee0870f36', 'Разминка всего тела'),
(21, 6, 15, '2182419d-8da0-4331-bd92-99bee0870f36', 'Реабилитация таза'),
(22, 6, 20, '2182419d-8da0-4331-bd92-99bee0870f36', 'Реабилитация поясницы'),
(23, 6, 20, '2182419d-8da0-4331-bd92-99bee0870f36', 'Реабилитация плеч'),
(24, 6, 20, '2182419d-8da0-4331-bd92-99bee0870f36', 'Реабилитация логтей'),
(25, 6, 15, '2182419d-8da0-4331-bd92-99bee0870f36', 'Реабилитация кистей'),
(26, 6, 20, '2182419d-8da0-4331-bd92-99bee0870f36', 'Реабилитация коленей');

-- Избранные упражнения пользователей (уникальные пары id_user + id_exercise)
INSERT INTO public.favorites_exercises (id, id_user, id_exercise) VALUES
(1, '2182419d-8da0-4331-bd92-99bee0870f36', 3),
(2, '2182419d-8da0-4331-bd92-99bee0870f36', 4),
(3, '2182419d-8da0-4331-bd92-99bee0870f36', 6),
(4, '2182419d-8da0-4331-bd92-99bee0870f36', 5),
(5, '2182419d-8da0-4331-bd92-99bee0870f36', 11),
(6, '2182419d-8da0-4331-bd92-99bee0870f36', 7),
(7, '2182419d-8da0-4331-bd92-99bee0870f36', 8),
(8, '2182419d-8da0-4331-bd92-99bee0870f36', 10),
(9, '2182419d-8da0-4331-bd92-99bee0870f36', 9);

-- Сброс sequence для favorites_exercises после ручной вставки id
SELECT setval('public.favorites_exercises_id_seq', COALESCE((SELECT MAX(id) FROM public.favorites_exercises), 1));

-- Избранные тренировки пользователей (примеры)
INSERT INTO public.favorites_workouts (id_user, id_workout) VALUES
('2182419d-8da0-4331-bd92-99bee0870f36', 1),
('2182419d-8da0-4331-bd92-99bee0870f36', 5),
('2182419d-8da0-4331-bd92-99bee0870f36', 7);

-- Сброс sequence для favorites_workouts после ручной вставки id
SELECT setval(pg_get_serial_sequence('public.favorites_workouts', 'id'), COALESCE(MAX(id), 1) FROM public.favorites_workouts);

-- Связи тренировок и упражнений
INSERT INTO public.workouts_exercises (id, id_workout, id_exercise) VALUES
(1, 1, 3), (2, 1, 1), (3, 1, 5), (4, 1, 4), (5, 1, 2),
(6, 2, 7), (7, 2, 5), (8, 2, 8), (9, 2, 9),
(10, 3, 10), (11, 3, 15), (12, 3, 14), (13, 3, 2),
(14, 4, 3), (15, 4, 17), (16, 4, 11),
(17, 5, 12), (18, 5, 3), (19, 5, 1), (20, 5, 5),
(21, 6, 16), (22, 6, 15), (23, 6, 2), (24, 6, 3),
(25, 7, 5), (26, 7, 7), (27, 7, 1), (28, 7, 4),
(29, 8, 9), (30, 8, 2),
(31, 9, 8), (32, 9, 6), (33, 9, 13),
(34, 10, 9), (35, 10, 12),
(36, 11, 11), (37, 11, 17), (38, 11, 18),
(39, 12, 3), (40, 12, 5),
(41, 13, 6), (42, 13, 7), (43, 13, 8),
(44, 14, 2), (45, 14, 3),
(46, 15, 1), (47, 15, 2), (48, 15, 11),
(49, 16, 12), (50, 16, 13),
(51, 17, 15), (52, 17, 1), (53, 17, 2),
(54, 18, 4), (55, 18, 8), (56, 18, 7),
(57, 19, 9), (58, 19, 10),
(59, 20, 11), (60, 20, 12);

-- Сброс sequence для workouts_exercises после ручной вставки id
SELECT setval('public.workouts_exercises_id_seq', COALESCE((SELECT MAX(id) FROM public.workouts_exercises), 1));

-- ============================================================================
-- ШАГ 5: Готовые программы тренировок
-- ============================================================================

INSERT INTO public.programs (name, description, duration_days, difficulty, is_preset) VALUES
('Неделя новичка', 'Базовая программа для начинающих. 7 дней тренировок.', 7, 'начинающий', TRUE),
('Две недели', 'Программа на 14 дней для развития базовых навыков.', 14, 'средний', TRUE),
('Месяц мастера', 'Интенсивная программа на 30 дней для продвинутых.', 30, 'продвинутый', TRUE);

-- Связь дней программ с тренировками
INSERT INTO public.program_days (id_program, day_number, id_workout) VALUES
-- Неделя новичка (7 дней)
(1, 1, 5), (1, 2, 6), (1, 3, 1), (1, 4, 5), (1, 5, 7), (1, 6, 11), (1, 7, 2),
-- Две недели (14 дней)
(2, 1, 5), (2, 2, 6), (2, 3, 1), (2, 4, 7), (2, 5, 8), (2, 6, 2), (2, 7, 3),
(2, 8, 9), (2, 9, 5), (2, 10, 6), (2, 11, 1), (2, 12, 7), (2, 13, 4), (2, 14, 10),
-- Месяц мастера (30 дней)
(3, 1, 1), (3, 2, 2), (3, 3, 3), (3, 4, 4), (3, 5, 7),
(3, 6, 8), (3, 7, 9), (3, 8, 10), (3, 9, 1), (3, 10, 2),
(3, 11, 3), (3, 12, 7), (3, 13, 8), (3, 14, 9),
(3, 15, 5), (3, 16, 6), (3, 17, 1), (3, 18, 2),
(3, 19, 3), (3, 20, 4), (3, 21, 7), (3, 22, 8),
(3, 23, 9), (3, 24, 10), (3, 25, 1), (3, 26, 2),
(3, 27, 3), (3, 28, 5), (3, 29, 6), (3, 30, 7);

-- Сброс sequence для program_days после ручной вставки id
SELECT setval('public.program_days_id_seq', COALESCE((SELECT MAX(id) FROM public.program_days), 1));

-- ============================================================================
-- ШАГ 5: Внешние ключи, индексы и ограничения
-- ============================================================================

-- Внешние ключи для упражнений
ALTER TABLE public.exercises
    ADD CONSTRAINT exercises_id_user_fkey
    FOREIGN KEY (id_user) REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;

-- Внешние ключи для избранных упражнений
ALTER TABLE public.favorites_exercises
    ADD CONSTRAINT fk_favorites_exercises_users
    FOREIGN KEY (id_user) REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE public.favorites_exercises
    ADD CONSTRAINT favorites_exercises_id_exercise_fkey
    FOREIGN KEY (id_exercise) REFERENCES public.exercises(id) ON UPDATE CASCADE ON DELETE CASCADE;

-- Внешние ключи для избранных тренировок
ALTER TABLE public.favorites_workouts
    ADD CONSTRAINT fk_favorites_workouts_users
    FOREIGN KEY (id_user) REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE public.favorites_workouts
    ADD CONSTRAINT favorites_workouts_id_workout_fkey
    FOREIGN KEY (id_workout) REFERENCES public.workouts(id) ON UPDATE CASCADE ON DELETE CASCADE;

-- Внешний ключ для пользователей (роль)
ALTER TABLE public.users
    ADD CONSTRAINT fk_users_roles
    FOREIGN KEY (id_role) REFERENCES public.roles(id) ON UPDATE CASCADE ON DELETE CASCADE;

-- Внешние ключи для тренировок
ALTER TABLE public.workouts
    ADD CONSTRAINT fk_workouts_complexes
    FOREIGN KEY (id_complex) REFERENCES public.complexes(id) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE public.workouts
    ADD CONSTRAINT fk_workouts_users
    FOREIGN KEY (id_user) REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;

-- Внешние ключи для связей тренировок и упражнений
ALTER TABLE public.workouts_exercises
    ADD CONSTRAINT fk_workout_exercises_workouts
    FOREIGN KEY (id_workout) REFERENCES public.workouts(id) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE public.workouts_exercises
    ADD CONSTRAINT workouts_exercises_id_exercise_fkey
    FOREIGN KEY (id_exercise) REFERENCES public.exercises(id) ON UPDATE CASCADE ON DELETE CASCADE;

-- Внешний ключ для программ пользователей
ALTER TABLE public.user_programs
    ADD CONSTRAINT fk_user_programs_users
    FOREIGN KEY (id_user) REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;

-- ============================================================================
-- Индексы для ускорения запросов
-- ============================================================================

-- Индексы для внешних ключей
CREATE INDEX idx_exercises_id_user ON public.exercises(id_user);
CREATE INDEX idx_workouts_id_user ON public.workouts(id_user);
CREATE INDEX idx_workouts_id_complex ON public.workouts(id_complex);
CREATE INDEX idx_workouts_exercises_workout ON public.workouts_exercises(id_workout);
CREATE INDEX idx_workouts_exercises_exercise ON public.workouts_exercises(id_exercise);
CREATE INDEX idx_favorites_exercises_user ON public.favorites_exercises(id_user);
CREATE INDEX idx_favorites_exercises_exercise ON public.favorites_exercises(id_exercise);
CREATE INDEX idx_favorites_workouts_user ON public.favorites_workouts(id_user);
CREATE INDEX idx_favorites_workouts_workout ON public.favorites_workouts(id_workout);
CREATE INDEX idx_user_programs_user ON public.user_programs(id_user);
CREATE INDEX idx_program_days_program ON public.program_days(id_program);
CREATE INDEX idx_program_days_workout ON public.program_days(id_workout);

-- Индексы для поиска
CREATE INDEX idx_exercises_name ON public.exercises(name_exercise);
CREATE INDEX idx_workouts_name ON public.workouts(name_workout);

-- ============================================================================
-- Уникальные ограничения и индексы
-- ============================================================================

-- Один пользователь может иметь только одну активную программу одного типа
CREATE UNIQUE INDEX unique_active_program_per_user ON public.user_programs(id_user, id_program) WHERE is_active = TRUE;

-- Номер дня уникален в пределах программы
ALTER TABLE public.program_days
ADD CONSTRAINT unique_day_per_program
UNIQUE (id_program, day_number);

-- Включаем RLS только для таблиц с приватными данными пользователей
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.exercises ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.workouts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.favorites_exercises ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.favorites_workouts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_programs ENABLE ROW LEVEL SECURITY;

-- Справочники и связи (complexes, programs, program_days, roles, workouts_exercises)
-- не имеют RLS, поэтому доступны всем без авторизации
ALTER TABLE public.complexes DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.programs DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.program_days DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.roles DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.workouts_exercises DISABLE ROW LEVEL SECURITY;

-- ============================================================================
-- ШАГ 8: Политики безопасности Row Level Security
-- ============================================================================

-- Политики для таблицы users
CREATE POLICY "Users can view their own data" 
    ON public.users FOR SELECT 
    USING (auth.uid() = id);

CREATE POLICY "Users can update their own data" 
    ON public.users FOR UPDATE 
    USING (auth.uid() = id);

CREATE POLICY "Users can insert their own data" 
    ON public.users FOR INSERT 
    WITH CHECK (auth.uid() = id);

-- Политики для упражнений
CREATE POLICY "Anyone can view exercises" 
    ON public.exercises FOR SELECT 
    USING (true);

CREATE POLICY "Users can create exercises" 
    ON public.exercises FOR INSERT 
    WITH CHECK (auth.uid() = id_user);

CREATE POLICY "Users can update their own exercises" 
    ON public.exercises FOR UPDATE 
    USING (auth.uid() = id_user);

CREATE POLICY "Users can delete their own exercises" 
    ON public.exercises FOR DELETE 
    USING (auth.uid() = id_user);

-- Политики для тренировок
CREATE POLICY "Anyone can view workouts" 
    ON public.workouts FOR SELECT 
    USING (true);

CREATE POLICY "Users can create workouts" 
    ON public.workouts FOR INSERT 
    WITH CHECK (auth.uid() = id_user);

CREATE POLICY "Users can update their own workouts" 
    ON public.workouts FOR UPDATE 
    USING (auth.uid() = id_user);

CREATE POLICY "Users can delete their own workouts" 
    ON public.workouts FOR DELETE 
    USING (auth.uid() = id_user);

-- Политики для таблицы roles (справочник)
CREATE POLICY "Anyone can view roles"
    ON public.roles FOR SELECT
    USING (true);

-- Политики для избранных упражнений
CREATE POLICY "Users can view their own favorites_exercises" 
    ON public.favorites_exercises FOR SELECT 
    USING (auth.uid() = id_user);

CREATE POLICY "Users can manage their favorites_exercises" 
    ON public.favorites_exercises FOR ALL 
    USING (auth.uid() = id_user);

-- Политики для избранных тренировок
CREATE POLICY "Users can view their own favorites_workouts" 
    ON public.favorites_workouts FOR SELECT 
    USING (auth.uid() = id_user);

CREATE POLICY "Users can manage their favorites_workouts"
    ON public.favorites_workouts FOR ALL
    USING (auth.uid() = id_user);

-- ============================================================================
-- ШАГ 9: Функции и триггеры
-- ============================================================================
-- ШАГ 9: Функции и триггеры
-- ============================================================================

-- Функция для автоматического создания пользователя при регистрации
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    -- Создаем пользователя только если его ещё нет в public.users
    INSERT INTO public.users (id, nickname, email, id_role)
    VALUES (
        NEW.id,
        COALESCE(NEW.raw_user_meta_data->>'nickname', 'User'),
        NEW.email,
        COALESCE((NEW.raw_user_meta_data->>'id_role')::INTEGER, 2)
    )
    ON CONFLICT (id) DO NOTHING;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Триггер для автоматического создания пользователя
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Функция для автоматического обновления updated_at
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Триггер для обновления updated_at в таблице users
CREATE TRIGGER update_users_updated_at
    BEFORE UPDATE ON public.users
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-- ============================================================================
-- ШАГ 10: Предоставление прав доступа
-- ============================================================================

GRANT ALL ON public.users TO authenticated;
GRANT ALL ON public.users TO service_role;
GRANT ALL ON public.exercises TO authenticated;
GRANT ALL ON public.exercises TO service_role;
GRANT ALL ON public.workouts TO authenticated;
GRANT ALL ON public.workouts TO service_role;
GRANT ALL ON public.favorites_exercises TO authenticated;
GRANT ALL ON public.favorites_exercises TO service_role;
GRANT ALL ON public.favorites_workouts TO authenticated;
GRANT ALL ON public.favorites_workouts TO service_role;
GRANT ALL ON public.workouts_exercises TO authenticated;
GRANT ALL ON public.workouts_exercises TO service_role;
 -- Разрешаем читать справочники анонимным пользователям
GRANT SELECT ON public.complexes TO anon;
GRANT SELECT ON public.programs TO anon;
GRANT SELECT ON public.program_days TO anon;
GRANT SELECT ON public.roles TO anon;
GRANT SELECT ON public.workouts_exercises TO anon;
GRANT ALL ON public.program_days TO authenticated;
GRANT ALL ON public.program_days TO service_role;
GRANT ALL ON public.user_programs TO authenticated;
GRANT ALL ON public.user_programs TO service_role;

-- ============================================================================
-- ШАГ 9bis: Row Level Security политики для user_programs и user_program_exercise_progress
-- ============================================================================

-- Включаем RLS для таблицы user_programs
ALTER TABLE public.user_programs ENABLE ROW LEVEL SECURITY;

-- Политики для user_programs
CREATE POLICY "Users can view their own user_programs"
    ON public.user_programs FOR SELECT
    USING (auth.uid() = id_user);

CREATE POLICY "Users can insert their own user_programs"
    ON public.user_programs FOR INSERT
    WITH CHECK (auth.uid() = id_user);

CREATE POLICY "Users can update their own user_programs"
    ON public.user_programs FOR UPDATE
    USING (auth.uid() = id_user);

CREATE POLICY "Users can delete their own user_programs"
    ON public.user_programs FOR DELETE
    USING (auth.uid() = id_user);

-- Включаем RLS для таблицы user_program_exercise_progress
ALTER TABLE public.user_program_exercise_progress ENABLE ROW LEVEL SECURITY;

-- Политики для user_program_exercise_progress
CREATE POLICY "Users can view their own exercise progress"
    ON public.user_program_exercise_progress FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.user_programs up
            WHERE up.id = id_user_program AND up.id_user = auth.uid()
        )
    );

CREATE POLICY "Users can insert their own exercise progress"
    ON public.user_program_exercise_progress FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.user_programs up
            WHERE up.id = id_user_program AND up.id_user = auth.uid()
        )
    );

CREATE POLICY "Users can update their own exercise progress"
    ON public.user_program_exercise_progress FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM public.user_programs up
            WHERE up.id = id_user_program AND up.id_user = auth.uid()
        )
    );

CREATE POLICY "Users can delete their own exercise progress"
    ON public.user_program_exercise_progress FOR DELETE
    USING (
        EXISTS (
            SELECT 1 FROM public.user_programs up
            WHERE up.id = id_user_program AND up.id_user = auth.uid()
        )
    );

-- ============================================================================
-- ШАГ 10: Предоставление прав доступа
-- ============================================================================

GRANT ALL ON public.users TO authenticated;
GRANT ALL ON public.users TO service_role;
GRANT ALL ON public.exercises TO authenticated;
GRANT ALL ON public.exercises TO service_role;
GRANT ALL ON public.workouts TO authenticated;
GRANT ALL ON public.workouts TO service_role;
GRANT ALL ON public.favorites_exercises TO authenticated;
GRANT ALL ON public.favorites_exercises TO service_role;
GRANT ALL ON public.favorites_workouts TO authenticated;
GRANT ALL ON public.favorites_workouts TO service_role;
GRANT ALL ON public.workouts_exercises TO authenticated;
GRANT ALL ON public.workouts_exercises TO service_role;
-- Разрешаем читать справочники анонимным пользователям

-- ============================================================================
-- ШАГ 11: Диагностические запросы (комментированы)
-- ============================================================================

-- Для просмотра статистики запросов (требуется расширение pg_stat_statements)
-- SELECT * FROM pg_stat_statements ORDER BY calls DESC LIMIT 10;

-- Для просмотра информации о триггере
-- SELECT * FROM pg_trigger WHERE tgname = 'on_auth_user_created';

-- Для просмотра всех триггеров в базе
-- SELECT 
--     tgname AS trigger_name,
--     tgrelid::regclass AS table_name,
--     pg_get_triggerdef(oid) AS trigger_definition
-- FROM pg_trigger
-- WHERE NOT tgisinternal
-- ORDER BY table_name, trigger_name;

-- Для проверки целостности внешних ключей
-- SELECT 
--     tc.table_name,
--     kcu.column_name,
--     ccu.table_name AS foreign_table_name,
--     ccu.column_name AS foreign_column_name
-- FROM information_schema.table_constraints AS tc 
-- JOIN information_schema.key_column_usage AS kcu
--     ON tc.constraint_name = kcu.constraint_name
-- JOIN information_schema.constraint_column_usage AS ccu
--     ON ccu.constraint_name = tc.constraint_name
-- WHERE constraint_type = 'FOREIGN KEY';

-- Для просмотра всех таблиц в базе данных
-- SELECT table_name 
-- FROM information_schema.tables 
-- WHERE table_schema = 'public'
-- ORDER BY table_name;

-- Для просмотра Row Level Security политик
-- SELECT 
--     schemaname,
--     tablename,
--     policyname,
--     permissive,
--     roles,
--     cmd,
--     qual,
--     with_check
-- FROM pg_policies
-- WHERE schemaname = 'public'
-- ORDER BY tablename, policyname;

-- ============================================================================
-- ЗАВЕРШЕНО
-- База данных полностью инициализирована и готова к использованию.
-- Все таблицы, данные, ограничения, политики и триггеры созданы.
-- ============================================================================
GRANT SELECT ON public.complexes TO anon;
GRANT SELECT ON public.complexes TO authenticated;
GRANT SELECT ON public.programs TO anon;
GRANT SELECT ON public.programs TO authenticated;
GRANT SELECT ON public.program_days TO anon;
GRANT SELECT ON public.program_days TO authenticated;
GRANT SELECT ON public.roles TO anon;
GRANT SELECT ON public.roles TO authenticated;
GRANT SELECT ON public.workouts_exercises TO anon;
GRANT SELECT ON public.workouts_exercises TO authenticated;
GRANT SELECT ON public.exercises TO anon;
GRANT SELECT ON public.exercises TO authenticated;
GRANT SELECT ON public.workouts TO anon;
GRANT SELECT ON public.workouts TO authenticated;

GRANT USAGE ON SCHEMA public TO anon;
GRANT USAGE ON SCHEMA public TO authenticated;

GRANT SELECT ON ALL TABLES IN SCHEMA public TO anon;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO authenticated;

GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO anon;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO authenticated;


-- Таблица прогресса упражнений внутри дней тренировочных программ
CREATE TABLE public.user_program_exercise_progress (
    id              SERIAL PRIMARY KEY,
    id_user_program INTEGER    NOT NULL REFERENCES public.user_programs(id) ON DELETE CASCADE,
    day_number      INTEGER    NOT NULL,                                     -- номер дня внутри программы
    exercise_id     SMALLINT   NOT NULL REFERENCES public.exercises(id) ON DELETE CASCADE,
    exercise_order  INTEGER    NOT NULL,                                     -- порядковый номер упражнения в этом дне
    completed       BOOLEAN    NOT NULL DEFAULT FALSE,                       -- выполнено ли упражнение
    completed_at    TIMESTAMP WITH TIME ZONE,                                -- когда отмечено как выполнено
    started_at      TIMESTAMP WITH TIME ZONE DEFAULT NOW(),                  -- когда пользователь приступил к упражнению
    -- Уникальность: одно упражнение с определенным порядком в одном дне одной программы пользователя
    CONSTRAINT uq_user_program_exercise_progress
        UNIQUE (id_user_program, day_number, exercise_order)
);

-- Индексы для ускорения частых запросов
CREATE INDEX idx_user_program_exercise_progress_user_program
    ON public.user_program_exercise_progress (id_user_program);
CREATE INDEX idx_user_program_exercise_progress_day
    ON public.user_program_exercise_progress (day_number);
CREATE INDEX idx_user_program_exercise_progress_exercise
    ON public.user_program_exercise_progress (exercise_id);
CREATE INDEX idx_user_program_exercise_progress_completed
    ON public.user_program_exercise_progress (completed);