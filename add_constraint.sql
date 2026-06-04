-- Добавление связи для user_programs

ALTER TABLE public.user_programs 
ADD CONSTRAINT fk_user_programs_users 
FOREIGN KEY (id_user) REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;