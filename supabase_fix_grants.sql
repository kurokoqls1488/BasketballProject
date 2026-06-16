-- Fix: Grant SELECT on complexes and programs to authenticated role
GRANT SELECT ON public.complexes TO authenticated;
GRANT SELECT ON public.programs TO authenticated;

-- Optional: also grant to anon (already present, but safe to re-run)
GRANT SELECT ON public.complexes TO anon;
GRANT SELECT ON public.programs TO anon;