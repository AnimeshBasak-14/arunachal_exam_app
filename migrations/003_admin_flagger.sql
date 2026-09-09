-- ====================================================================
-- MIGRATION 003: ADMIN FLAGGER & TRIAGE SCHEMA
-- ====================================================================

-- 1. Ensure review_status, flagged_issues, admin_notes, and last_reviewed_at exist on questions
alter table public.questions 
  add column if not exists review_status text default 'unreviewed',
  add column if not exists flagged_issues text[] default '{}',
  add column if not exists flag_reasons text[] default '{}',
  add column if not exists admin_notes text,
  add column if not exists last_reviewed_at timestamptz;

-- 2. Update check constraint on review_status to safely support unreviewed, approved, flagged, needs_ocr_rerun
alter table public.questions drop constraint if exists questions_review_status_check;
alter table public.questions add constraint questions_review_status_check 
  check (review_status in ('unreviewed', 'approved', 'flagged', 'needs_ocr_rerun'));

-- 3. Dedicated audit table for granular issue logging
create table if not exists public.question_flags (
  id uuid primary key default gen_random_uuid(),
  question_id uuid not null references public.questions(id) on delete cascade,
  issue_category text,
  issue_type text,
  notes text,
  flagged_by uuid references auth.users(id),
  resolved boolean default false,
  created_at timestamptz default now()
);

-- Ensure columns exist if table was previously created with issue_type
alter table public.question_flags 
  add column if not exists issue_category text,
  add column if not exists issue_type text,
  add column if not exists notes text,
  add column if not exists flagged_by uuid references auth.users(id),
  add column if not exists resolved boolean default false;

-- Allow check constraint on issue_category to accept standard categories
alter table public.question_flags drop constraint if exists question_flags_issue_category_check;
alter table public.question_flags add constraint question_flags_issue_category_check check (
  issue_category is null or issue_category in (
    'correct',
    'question_text_wrong',
    'options_wrong',
    'dummy_placeholders',
    'next_question_bleed',
    'wrong_passage_direction',
    'missing_image',
    'other'
  )
);

-- 4. Indexes for fast admin filtering
create index if not exists idx_questions_review_status on public.questions(review_status);
create index if not exists idx_questions_last_reviewed on public.questions(last_reviewed_at);
create index if not exists idx_question_flags_question_id on public.question_flags(question_id);
