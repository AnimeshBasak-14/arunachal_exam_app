-- 006: Lock down writes.
--
-- Before this migration, policies such as "Allow all on questions" and
-- "Allow All Question Assets" used `FOR ALL` with role {public}, which includes
-- `anon`. Anyone holding the publishable key (it ships in the app) could
-- update or delete every question, test, and uploaded image.
--
-- After this migration:
--   * Everyone can still READ questions / groups / tests / catalogs / assets.
--   * Anyone can still INSERT into question_flags, if that table exists.
--   * Only signed-in Supabase Auth users listed in public.admin_users can write.
--   * service_role (local Python scripts) bypasses RLS as before.
--
-- Written against the live schema on 2026-10-10 (tables: questions,
-- question_groups, tests; bucket: question_assets). Tables from migration 005
-- are handled too if they are created later. Safe to re-run.

BEGIN;

-- 1. Admin allowlist ---------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.admin_users (
    email      text PRIMARY KEY,
    created_at timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE public.admin_users ENABLE ROW LEVEL SECURITY;
-- No policies: the allowlist is not readable or writable through the API.
REVOKE ALL ON public.admin_users FROM anon, authenticated;

INSERT INTO public.admin_users (email)
VALUES ('basakanimesh16@gmail.com')
ON CONFLICT (email) DO NOTHING;

CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
    SELECT EXISTS (
        SELECT 1 FROM public.admin_users
        WHERE lower(email) = lower(coalesce(auth.jwt() ->> 'email', ''))
    );
$$;
REVOKE ALL ON FUNCTION public.is_admin() FROM public;
GRANT EXECUTE ON FUNCTION public.is_admin() TO anon, authenticated;

-- 2. Replace open write policies on content tables ---------------------------
DO $$
DECLARE
    t text;
    p record;
BEGIN
    FOREACH t IN ARRAY ARRAY['questions','question_groups','tests','agencies','branches',
                             'exam_catalog','subject_catalog','topic_catalog']
    LOOP
        IF to_regclass('public.' || t) IS NULL THEN
            CONTINUE;
        END IF;

        -- Drop every policy that is not read-only (ALL / INSERT / UPDATE / DELETE).
        FOR p IN SELECT policyname FROM pg_policies
                 WHERE schemaname = 'public' AND tablename = t AND cmd <> 'SELECT'
        LOOP
            EXECUTE format('DROP POLICY %I ON public.%I', p.policyname, t);
        END LOOP;

        EXECUTE format(
            'CREATE POLICY "Admins write %1$s" ON public.%1$I FOR ALL TO authenticated '
            'USING (public.is_admin()) WITH CHECK (public.is_admin())', t);

        -- Defence in depth: anon never needs to write content.
        EXECUTE format('REVOKE INSERT, UPDATE, DELETE, TRUNCATE ON public.%I FROM anon', t);
    END LOOP;

    -- Users may report problems with questions.
    IF to_regclass('public.question_flags') IS NOT NULL THEN
        EXECUTE 'DROP POLICY IF EXISTS "Allow insert access to question_flags" ON public.question_flags';
        EXECUTE 'CREATE POLICY "Allow insert access to question_flags" ON public.question_flags '
                'FOR INSERT WITH CHECK (true)';
    END IF;
END $$;

-- 3. Storage: public read, admin-only write ----------------------------------
DROP POLICY IF EXISTS "Allow All Question Assets" ON storage.objects;
DROP POLICY IF EXISTS "Allow authenticated/service upload exam assets" ON storage.objects;
DROP POLICY IF EXISTS "Allow authenticated/service update exam assets" ON storage.objects;

DROP POLICY IF EXISTS "Admins write question assets" ON storage.objects;
CREATE POLICY "Admins write question assets" ON storage.objects
    FOR ALL TO authenticated
    USING (bucket_id IN ('question_assets', 'exam-assets') AND public.is_admin())
    WITH CHECK (bucket_id IN ('question_assets', 'exam-assets') AND public.is_admin());

COMMIT;

-- 4. Verify after running. Every non-SELECT policy should be TO {authenticated}
--    with is_admin(), except question_flags INSERT.
-- SELECT schemaname, tablename, policyname, cmd, roles, qual, with_check
-- FROM pg_policies WHERE schemaname IN ('public','storage') ORDER BY 1,2,3;
