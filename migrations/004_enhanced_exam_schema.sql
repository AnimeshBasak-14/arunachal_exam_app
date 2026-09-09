-- ====================================================================
-- ARUNACHAL EXAM PREP - SUPABASE DATABASE MIGRATION
-- MIGRATION: 004_enhanced_exam_schema.sql
-- Unified question groups (Directions & Comprehensions), multi-tier
-- images, content formats (LaTeX/Unicode/Image), and review triage.
-- ====================================================================
-- Execute this script in your Supabase Dashboard -> SQL Editor
-- ====================================================================

-- 1. Ensure `question_groups` table exists and has all required columns
CREATE TABLE IF NOT EXISTS public.question_groups (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    test_id UUID NOT NULL REFERENCES public.tests(id) ON DELETE CASCADE,
    group_type VARCHAR(30) NOT NULL DEFAULT 'comprehension',
    title VARCHAR(255),
    direction_text TEXT,
    passage_text TEXT,
    image_url TEXT,
    metadata JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now())
);

-- Safely add missing columns to question_groups if the table already existed
ALTER TABLE public.question_groups
    ADD COLUMN IF NOT EXISTS group_type VARCHAR(30) NOT NULL DEFAULT 'comprehension',
    ADD COLUMN IF NOT EXISTS title VARCHAR(255),
    ADD COLUMN IF NOT EXISTS direction_text TEXT,
    ADD COLUMN IF NOT EXISTS passage_text TEXT,
    ADD COLUMN IF NOT EXISTS image_url TEXT,
    ADD COLUMN IF NOT EXISTS metadata JSONB DEFAULT '{}'::jsonb,
    ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()),
    ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now());

-- 2. Safely upgrade `questions` table with all enhanced attributes
ALTER TABLE public.questions
    ADD COLUMN IF NOT EXISTS group_id UUID REFERENCES public.question_groups(id) ON DELETE SET NULL,
    ADD COLUMN IF NOT EXISTS question_number INTEGER DEFAULT 0,
    ADD COLUMN IF NOT EXISTS order_index INTEGER,
    ADD COLUMN IF NOT EXISTS subject VARCHAR(100) DEFAULT 'General',
    ADD COLUMN IF NOT EXISTS topic VARCHAR(100),
    ADD COLUMN IF NOT EXISTS difficulty VARCHAR(20) DEFAULT 'Medium',
    ADD COLUMN IF NOT EXISTS question_type VARCHAR(30) DEFAULT 'mcq',
    ADD COLUMN IF NOT EXISTS content_format VARCHAR(20) DEFAULT 'text',
    ADD COLUMN IF NOT EXISTS direction_text TEXT,
    ADD COLUMN IF NOT EXISTS question_image_url TEXT,
    ADD COLUMN IF NOT EXISTS correct_option VARCHAR(10),
    ADD COLUMN IF NOT EXISTS marks NUMERIC(4, 2) DEFAULT 2.0,
    ADD COLUMN IF NOT EXISTS negative_marks NUMERIC(4, 2) DEFAULT 0.5,
    ADD COLUMN IF NOT EXISTS explanation TEXT,
    ADD COLUMN IF NOT EXISTS explanation_image_url TEXT,
    ADD COLUMN IF NOT EXISTS review_status VARCHAR(20) DEFAULT 'unreviewed',
    ADD COLUMN IF NOT EXISTS flagged_issues JSONB DEFAULT '[]'::jsonb,
    ADD COLUMN IF NOT EXISTS admin_notes TEXT,
    ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now());

-- 3. Synchronize `correct_option` and `order_index` on existing rows
UPDATE public.questions
SET correct_option = LOWER(TRIM(correct_answer))
WHERE correct_option IS NULL AND correct_answer IS NOT NULL;

UPDATE public.questions
SET order_index = question_number
WHERE order_index IS NULL AND question_number IS NOT NULL AND question_number > 0;

UPDATE public.questions
SET question_number = order_index
WHERE (question_number IS NULL OR question_number = 0) AND order_index IS NOT NULL;

-- 4. High-Performance Indexes for Filtering and Real-time Practice
CREATE INDEX IF NOT EXISTS idx_questions_test_id ON public.questions(test_id);
CREATE INDEX IF NOT EXISTS idx_questions_group_id ON public.questions(group_id);
CREATE INDEX IF NOT EXISTS idx_questions_test_order ON public.questions(test_id, order_index);
CREATE INDEX IF NOT EXISTS idx_questions_review_status ON public.questions(review_status);
CREATE INDEX IF NOT EXISTS idx_questions_subject ON public.questions(subject);
CREATE INDEX IF NOT EXISTS idx_question_groups_test_id ON public.question_groups(test_id);

-- 5. Row Level Security (RLS) Policies
ALTER TABLE public.question_groups ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.questions ENABLE ROW LEVEL SECURITY;

DO $$ 
BEGIN
    DROP POLICY IF EXISTS "Allow public read access to question_groups" ON public.question_groups;
    DROP POLICY IF EXISTS "Allow public read access to questions" ON public.questions;
    DROP POLICY IF EXISTS "Allow all on question_groups" ON public.question_groups;
    DROP POLICY IF EXISTS "Allow all on questions" ON public.questions;
END $$;

CREATE POLICY "Allow public read access to question_groups" 
    ON public.question_groups FOR SELECT USING (true);

CREATE POLICY "Allow public read access to questions" 
    ON public.questions FOR SELECT USING (true);

CREATE POLICY "Allow all on question_groups" 
    ON public.question_groups FOR ALL USING (true) WITH CHECK (true);

CREATE POLICY "Allow all on questions" 
    ON public.questions FOR ALL USING (true) WITH CHECK (true);

-- 6. Storage Bucket Configuration for Exam Images
INSERT INTO storage.buckets (id, name, public)
VALUES ('exam-assets', 'exam-assets', true)
ON CONFLICT (id) DO UPDATE SET public = true;

DO $$
BEGIN
    DROP POLICY IF EXISTS "Allow public view exam assets" ON storage.objects;
    DROP POLICY IF EXISTS "Allow authenticated/service upload exam assets" ON storage.objects;
END $$;

CREATE POLICY "Allow public view exam assets" 
    ON storage.objects FOR SELECT 
    USING (bucket_id = 'exam-assets');

CREATE POLICY "Allow authenticated/service upload exam assets" 
    ON storage.objects FOR INSERT 
    WITH CHECK (bucket_id = 'exam-assets');

CREATE POLICY "Allow authenticated/service update exam assets" 
    ON storage.objects FOR UPDATE 
    USING (bucket_id = 'exam-assets');
