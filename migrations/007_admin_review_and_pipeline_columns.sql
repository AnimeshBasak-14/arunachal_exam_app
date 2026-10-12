-- 007: Columns the admin screens and the Excel pipeline write, but which the
-- live database never received (migrations 001/003/004/005 were not applied).
--
-- Purely additive: every new column is nullable or has a default, so existing
-- reads in the live app are unaffected. Safe to re-run.
--
-- Also adds a trigger that keeps correct_option and correct_answer in sync, so
-- there is effectively one answer key no matter which column a tool writes.

BEGIN;

-- 1. questions: review workflow -------------------------------------------
ALTER TABLE public.questions
    ADD COLUMN IF NOT EXISTS review_status    text        DEFAULT 'unreviewed',
    ADD COLUMN IF NOT EXISTS flagged_issues   text[]      DEFAULT '{}',
    ADD COLUMN IF NOT EXISTS flag_reasons     text[]      DEFAULT '{}',
    ADD COLUMN IF NOT EXISTS admin_notes      text,
    ADD COLUMN IF NOT EXISTS last_reviewed_at timestamptz;

UPDATE public.questions SET review_status = 'unreviewed' WHERE review_status IS NULL;

ALTER TABLE public.questions DROP CONSTRAINT IF EXISTS questions_review_status_check;
ALTER TABLE public.questions ADD CONSTRAINT questions_review_status_check
    CHECK (review_status IN ('unreviewed', 'approved', 'flagged', 'needs_ocr_rerun'));

-- 2. questions: content / taxonomy fields used by the app and Excel pipeline -
ALTER TABLE public.questions
    ADD COLUMN IF NOT EXISTS correct_option  varchar(10),
    ADD COLUMN IF NOT EXISTS direction_text  text,
    ADD COLUMN IF NOT EXISTS content_format  varchar(20) DEFAULT 'text',
    ADD COLUMN IF NOT EXISTS question_type   varchar(20) DEFAULT 'mcq',
    ADD COLUMN IF NOT EXISTS topic           varchar(100),
    ADD COLUMN IF NOT EXISTS subject_code    varchar(50),
    ADD COLUMN IF NOT EXISTS topic_code      varchar(50),
    ADD COLUMN IF NOT EXISTS order_index     integer,
    ADD COLUMN IF NOT EXISTS image_url       text;

-- 3. tests / question_groups: fields the pipeline sends ---------------------
ALTER TABLE public.tests
    ADD COLUMN IF NOT EXISTS test_code   varchar(100),
    ADD COLUMN IF NOT EXISTS agency_code varchar(20),
    ADD COLUMN IF NOT EXISTS branch_code varchar(20);

ALTER TABLE public.question_groups
    ADD COLUMN IF NOT EXISTS group_type     varchar(30) DEFAULT 'comprehension',
    ADD COLUMN IF NOT EXISTS direction_text text;

-- 4. Keep the two answer-key columns consistent -----------------------------
-- The app reads correct_option first, then correct_answer.
--   * Writing correct_option copies it into correct_answer.
--   * Updating only correct_answer clears a stale correct_option, so the new
--     correct_answer is what students see.
-- Existing rows are NOT backfilled: correct_option stays NULL and the app keeps
-- using correct_answer exactly as before.
CREATE OR REPLACE FUNCTION public.sync_answer_key()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    IF NEW.correct_option IS NOT NULL AND btrim(NEW.correct_option) <> '' THEN
        NEW.correct_option := lower(btrim(NEW.correct_option));
        IF NEW.correct_option NOT IN ('a', 'b', 'c', 'd') THEN
            RAISE EXCEPTION 'correct_option must be a, b, c or d (got "%")', NEW.correct_option;
        END IF;
    END IF;

    IF TG_OP = 'INSERT' THEN
        IF coalesce(NEW.correct_option, '') <> '' THEN
            NEW.correct_answer := NEW.correct_option;
        END IF;
    ELSE
        IF NEW.correct_option IS DISTINCT FROM OLD.correct_option
           AND coalesce(NEW.correct_option, '') <> '' THEN
            NEW.correct_answer := NEW.correct_option;
        ELSIF NEW.correct_answer IS DISTINCT FROM OLD.correct_answer THEN
            NEW.correct_option := NULL;
        END IF;
    END IF;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_sync_answer_key ON public.questions;
CREATE TRIGGER trg_sync_answer_key
    BEFORE INSERT OR UPDATE ON public.questions
    FOR EACH ROW EXECUTE FUNCTION public.sync_answer_key();

-- 5. Flag audit table (admin-only) ------------------------------------------
CREATE TABLE IF NOT EXISTS public.question_flags (
    id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    question_id uuid NOT NULL REFERENCES public.questions(id) ON DELETE CASCADE,
    issue_type  text,
    notes       text,
    flagged_by  text DEFAULT (auth.jwt() ->> 'email'),
    resolved    boolean DEFAULT false,
    created_at  timestamptz DEFAULT now()
);
ALTER TABLE public.question_flags ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.question_flags FROM anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.question_flags TO authenticated;
DROP POLICY IF EXISTS "Admins manage question_flags" ON public.question_flags;
CREATE POLICY "Admins manage question_flags" ON public.question_flags
    FOR ALL TO authenticated
    USING (public.is_admin()) WITH CHECK (public.is_admin());

-- 6. Indexes for the admin filters -------------------------------------------
CREATE INDEX IF NOT EXISTS idx_questions_review_status ON public.questions(review_status);
CREATE INDEX IF NOT EXISTS idx_questions_test_number   ON public.questions(test_id, question_number);
CREATE INDEX IF NOT EXISTS idx_question_flags_question ON public.question_flags(question_id);

COMMIT;
