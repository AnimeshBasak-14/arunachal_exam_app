-- ====================================================================
-- MIGRATION 002: QUIZ REFACTOR, QUALITY TRIAGE & IMAGE ASSETS
-- ====================================================================

-- 1. Alter questions table for quality triage, modes, and image assets
ALTER TABLE public.questions 
  ADD COLUMN IF NOT EXISTS image_url text,
  ADD COLUMN IF NOT EXISTS has_image boolean DEFAULT false,
  ADD COLUMN IF NOT EXISTS review_status text DEFAULT 'approved' 
    CHECK (review_status IN ('approved', 'flagged', 'needs_ocr_rerun')),
  ADD COLUMN IF NOT EXISTS flag_reasons text[] DEFAULT '{}',
  ADD COLUMN IF NOT EXISTS mode_availability text[] DEFAULT '{"timed", "study"}';

-- 2. Table for user-reported or auto-flagged issues
CREATE TABLE IF NOT EXISTS public.question_flags (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  question_id uuid NOT NULL REFERENCES public.questions(id) ON DELETE CASCADE,
  reported_by uuid REFERENCES auth.users(id),
  issue_type text NOT NULL CHECK (issue_type IN (
    'merged_options', 'dummy_placeholders', 'bleed_through', 
    'wrong_passage', 'missing_image', 'formatting_noise'
  )),
  notes text,
  resolved boolean DEFAULT false,
  created_at timestamptz DEFAULT now()
);

-- 3. Indexes for fast query filtering during practice test generation & admin review
CREATE INDEX IF NOT EXISTS idx_questions_review_status 
  ON public.questions(review_status);

CREATE INDEX IF NOT EXISTS idx_questions_has_image 
  ON public.questions(has_image) 
  WHERE has_image = true;

CREATE INDEX IF NOT EXISTS idx_question_flags_question_id 
  ON public.question_flags(question_id);

CREATE INDEX IF NOT EXISTS idx_question_flags_resolved 
  ON public.question_flags(resolved) 
  WHERE resolved = false;

-- 4. Automatically sync has_image flag when image_url is modified
CREATE OR REPLACE FUNCTION public.trg_fn_sync_question_has_image()
RETURNS trigger AS $$
BEGIN
  IF NEW.image_url IS NOT NULL AND trim(NEW.image_url) <> '' THEN
    NEW.has_image := true;
  ELSE
    NEW.has_image := false;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_sync_question_has_image ON public.questions;
CREATE TRIGGER trg_sync_question_has_image
  BEFORE INSERT OR UPDATE OF image_url ON public.questions
  FOR EACH ROW
  EXECUTE FUNCTION public.trg_fn_sync_question_has_image();

-- 5. Backfill has_image for existing records with non-empty image_url
UPDATE public.questions
SET has_image = true
WHERE image_url IS NOT NULL AND trim(image_url) <> '';
