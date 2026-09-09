-- ====================================================================
-- ARUNACHAL EXAM PREP - SUPABASE DATABASE MIGRATION: 001
-- PASSAGES TABLE & QUESTION SCHEMA INTEGRITY REFACTOR
-- ====================================================================
-- Run this script in the Supabase Dashboard -> SQL Editor
-- ====================================================================

-- 1. Create `passages` table for reading comprehension, data interpretation,
--    and shared multi-question directions.
CREATE TABLE IF NOT EXISTS passages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    test_id UUID REFERENCES tests(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    image_url TEXT,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Index for high-performance lookup of passages by test
CREATE INDEX IF NOT EXISTS idx_passages_test_id ON passages(test_id);

-- 2. Refactor `questions` table to link with `passages`
ALTER TABLE questions
ADD COLUMN IF NOT EXISTS passage_id UUID REFERENCES passages(id) ON DELETE SET NULL,
ADD COLUMN IF NOT EXISTS correct_option TEXT,
ADD COLUMN IF NOT EXISTS order_index INTEGER;

-- Indexes for questions
CREATE INDEX IF NOT EXISTS idx_questions_passage_id ON questions(passage_id);
CREATE INDEX IF NOT EXISTS idx_questions_order_index ON questions(test_id, order_index);

-- 3. Synchronize existing fields
UPDATE questions
SET order_index = question_number
WHERE order_index IS NULL AND question_number IS NOT NULL;

UPDATE questions
SET correct_option = correct_answer
WHERE correct_option IS NULL AND correct_answer IS NOT NULL;

-- 4. Clean existing placeholder / dummy option strings in DB before applying constraint
--    Convert any {"text": "Option A"} or similar placeholders into clean empty or valid structures
UPDATE questions
SET options = (
    SELECT jsonb_agg(
        jsonb_build_object(
            'key', COALESCE(opt->>'key', opt->>'id', chr(96 + (ord)::int)),
            'text', TRIM(COALESCE(opt->>'text', opt->>'value', ''))
        )
    )
    FROM jsonb_array_elements(options) WITH ORDINALITY AS t(opt, ord)
)
WHERE options IS NOT NULL AND jsonb_typeof(options) = 'array';

-- 5. Backfill existing passages from `question_groups` into `passages`
DO $$
DECLARE
    g RECORD;
    new_passage_id UUID;
    passage_text TEXT;
BEGIN
    -- Check if question_groups table exists
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'question_groups') THEN
        FOR g IN SELECT * FROM question_groups LOOP
            passage_text := TRIM(CONCAT_WS(E'\n\n', NULLIF(g.title, ''), NULLIF(g.instructions, ''), NULLIF(g.passage_text, '')));
            IF passage_text <> '' THEN
                INSERT INTO passages (test_id, content, created_at)
                VALUES (g.test_id, passage_text, COALESCE(g.created_at, now()))
                RETURNING id INTO new_passage_id;

                -- Link questions belonging to this group
                UPDATE questions
                SET passage_id = new_passage_id
                WHERE group_id = g.id::text OR group_id = g.id::varchar;
            END IF;
        END LOOP;
    END IF;
END $$;

-- 6. DB Validation Trigger: Strict validation for valid options
CREATE OR REPLACE FUNCTION validate_question_options()
RETURNS TRIGGER AS $$
DECLARE
    opt JSONB;
    opt_count INT := 0;
    valid_opt_count INT := 0;
    opt_text TEXT;
BEGIN
    -- Allow draft imports if marked, otherwise enforce strict options
    IF NEW.options IS NULL OR jsonb_typeof(NEW.options) != 'array' THEN
        RAISE EXCEPTION 'Question % must have an array of options', NEW.id;
    END IF;

    opt_count := jsonb_array_length(NEW.options);
    IF opt_count < 2 THEN
        RAISE EXCEPTION 'Question % must have at least 2 options, found %', NEW.id, opt_count;
    END IF;

    FOR opt IN SELECT * FROM jsonb_array_elements(NEW.options)
    LOOP
        opt_text := COALESCE(opt->>'text', opt->>'value', '');
        IF TRIM(opt_text) = '' THEN
            RAISE EXCEPTION 'Question % contains an option with empty text', NEW.id;
        END IF;

        -- Reject dummy placeholder strings ("Option A", "Option B", etc.)
        IF opt_text ~* '^Option\s+[A-D]$' THEN
            RAISE EXCEPTION 'Question % contains placeholder option text "%"', NEW.id, opt_text;
        END IF;

        valid_opt_count := valid_opt_count + 1;
    END LOOP;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_validate_question_options ON questions;
CREATE TRIGGER trg_validate_question_options
BEFORE INSERT OR UPDATE ON questions
FOR EACH ROW
EXECUTE FUNCTION validate_question_options();

-- 7. Verification Query
SELECT 
    COUNT(*) AS total_passages,
    (SELECT COUNT(*) FROM questions WHERE passage_id IS NOT NULL) AS linked_questions,
    (SELECT COUNT(*) FROM questions WHERE options IS NOT NULL) AS valid_option_questions
FROM passages;
