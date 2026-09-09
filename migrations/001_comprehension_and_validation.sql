-- ====================================================================
-- ARUNACHAL EXAM PREP - SUPABASE DATABASE MIGRATION
-- MIGRATION: 001_comprehension_and_validation.sql
-- Relational passages model, questions refactor & data guard trigger
-- ====================================================================
-- Run this script in your Supabase Dashboard -> SQL Editor
-- ====================================================================

-- 1. Create `passages` table for reading comprehension, data interpretation,
--    and shared multi-question directions.
CREATE TABLE IF NOT EXISTS public.passages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    test_id UUID NOT NULL REFERENCES public.tests(id) ON DELETE CASCADE,
    title TEXT, -- e.g., 'Direction (Q. 85 - 87)'
    content TEXT NOT NULL, -- Passage or instruction text
    image_url TEXT, -- For pie charts, bar graphs, DI figures
    metadata JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Index for high-performance lookup of passages by test
CREATE INDEX IF NOT EXISTS idx_passages_test_id ON public.passages(test_id);

-- 2. Update `questions` table schema
ALTER TABLE public.questions
ADD COLUMN IF NOT EXISTS passage_id UUID REFERENCES public.passages(id) ON DELETE SET NULL,
ADD COLUMN IF NOT EXISTS question_number INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS correct_option TEXT,
ADD COLUMN IF NOT EXISTS order_index INTEGER;

-- Indexes for questions table
CREATE INDEX IF NOT EXISTS idx_questions_passage_id ON public.questions(passage_id);
CREATE INDEX IF NOT EXISTS idx_questions_test_qnum ON public.questions(test_id, question_number);
CREATE INDEX IF NOT EXISTS idx_questions_order_index ON public.questions(test_id, order_index);

-- 3. Synchronize question numbers and correct options
UPDATE public.questions
SET question_number = order_index
WHERE (question_number IS NULL OR question_number = 0) AND order_index IS NOT NULL;

UPDATE public.questions
SET order_index = question_number
WHERE order_index IS NULL AND question_number IS NOT NULL AND question_number > 0;

UPDATE public.questions
SET correct_option = LOWER(TRIM(correct_answer))
WHERE correct_option IS NULL AND correct_answer IS NOT NULL;

-- 4. Clean & normalize existing options in DB to adhere to the strict contract:
--    [{"id": "a", "text": "..."}, {"id": "b", "text": "..."}]
UPDATE public.questions
SET options = (
    SELECT jsonb_agg(
        jsonb_build_object(
            'id', LOWER(COALESCE(opt->>'id', opt->>'key', chr(96 + (ord)::int))),
            'text', TRIM(COALESCE(opt->>'text', opt->>'value', ''))
        )
    )
    FROM jsonb_array_elements(options) WITH ORDINALITY AS t(opt, ord)
)
WHERE options IS NOT NULL AND jsonb_typeof(options) = 'array';

-- 5. Backfill existing passages from `question_groups` into `passages` table
DO $$
DECLARE
    g RECORD;
    new_passage_id UUID;
    passage_content TEXT;
    passage_title TEXT;
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'question_groups') THEN
        FOR g IN SELECT * FROM public.question_groups LOOP
            passage_title := NULLIF(TRIM(COALESCE(g.title, '')), '');
            passage_content := TRIM(CONCAT_WS(E'\n\n', NULLIF(g.instructions, ''), NULLIF(g.passage_text, '')));
            
            IF passage_content = '' AND passage_title IS NOT NULL THEN
                passage_content := passage_title;
            END IF;

            IF passage_content <> '' THEN
                INSERT INTO public.passages (test_id, title, content, created_at)
                VALUES (g.test_id, passage_title, passage_content, COALESCE(g.created_at, now()))
                RETURNING id INTO new_passage_id;

                -- Link questions belonging to this group
                UPDATE public.questions
                SET passage_id = new_passage_id
                WHERE group_id = g.id::text OR group_id = g.id::varchar;
            END IF;
        END LOOP;
    END IF;
END $$;

-- 6. Data Guard Trigger: Validates options contract & answers BEFORE INSERT OR UPDATE
CREATE OR REPLACE FUNCTION public.validate_question_options()
RETURNS TRIGGER AS $$
DECLARE
    opt JSONB;
    opt_count INT := 0;
    opt_id TEXT;
    opt_text TEXT;
    is_draft BOOLEAN := FALSE;
BEGIN
    -- Check if record is marked as draft
    IF NEW.metadata IS NOT NULL AND (NEW.metadata->>'status' = 'draft' OR NEW.metadata->>'is_draft' = 'true') THEN
        is_draft := TRUE;
    END IF;
    
    -- In case questions table has a status column
    BEGIN
        IF NEW.status = 'draft' THEN
            is_draft := TRUE;
        END IF;
    EXCEPTION WHEN undefined_column THEN
        -- Column status does not exist on table, ignore
    END;

    -- If draft, allow bypassing strict validation for incomplete OCR parsing
    IF is_draft THEN
        RETURN NEW;
    END IF;

    -- Options array validation
    IF NEW.options IS NULL OR jsonb_typeof(NEW.options) != 'array' THEN
        RAISE EXCEPTION 'Question % must have an array of options', NEW.id;
    END IF;

    opt_count := jsonb_array_length(NEW.options);
    IF opt_count < 2 THEN
        RAISE EXCEPTION 'Question % must have at least 2 distinct choices, found %', NEW.id, opt_count;
    END IF;

    FOR opt IN SELECT * FROM jsonb_array_elements(NEW.options)
    LOOP
        opt_id := LOWER(TRIM(COALESCE(opt->>'id', opt->>'key', '')));
        opt_text := TRIM(COALESCE(opt->>'text', opt->>'value', ''));

        IF opt_text = '' THEN
            RAISE EXCEPTION 'Question % contains an option with empty text', NEW.id;
        END IF;

        -- Reject generic dummy placeholders unless status = 'draft'
        IF opt_text ~* '^Option\s+[A-D]$' THEN
            RAISE EXCEPTION 'Question % contains placeholder option text "%"', NEW.id, opt_text;
        END IF;
    END LOOP;

    -- Correct option validation (must be in 'a', 'b', 'c', 'd')
    IF NEW.correct_option IS NOT NULL AND TRIM(NEW.correct_option) <> '' THEN
        IF LOWER(TRIM(NEW.correct_option)) NOT IN ('a', 'b', 'c', 'd') THEN
            RAISE EXCEPTION 'Question % has invalid correct_option "%", must be a, b, c, or d', NEW.id, NEW.correct_option;
        END IF;
        NEW.correct_option := LOWER(TRIM(NEW.correct_option));
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_validate_question_options ON public.questions;
CREATE TRIGGER trg_validate_question_options
BEFORE INSERT OR UPDATE ON public.questions
FOR EACH ROW
EXECUTE FUNCTION public.validate_question_options();

-- 7. Verification Summary
SELECT 
    COUNT(*) AS total_passages,
    (SELECT COUNT(*) FROM public.questions WHERE passage_id IS NOT NULL) AS linked_questions,
    (SELECT COUNT(*) FROM public.questions WHERE options IS NOT NULL) AS valid_option_questions
FROM public.passages;
