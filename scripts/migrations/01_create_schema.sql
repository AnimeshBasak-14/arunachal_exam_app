-- 1. Tests Table
CREATE TABLE IF NOT EXISTS tests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    exam_code VARCHAR(50) NOT NULL,
    paper_type VARCHAR(20) NOT NULL DEFAULT 'PYQ',
    year INT,
    title VARCHAR(255) NOT NULL,
    duration_minutes INT DEFAULT 120,
    marks_per_correct NUMERIC(4, 2) DEFAULT 2.0,
    negative_marks NUMERIC(4, 2) DEFAULT 0.5,
    is_published BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now())
);

-- 2. Question Groups Table (Passages / Directions)
CREATE TABLE IF NOT EXISTS question_groups (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    test_id UUID NOT NULL REFERENCES tests(id) ON DELETE CASCADE,
    title VARCHAR(150),
    passage_text TEXT,
    passage_image_url TEXT,
    instructions TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now())
);

-- 3. Questions Table
CREATE TABLE IF NOT EXISTS questions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    test_id UUID NOT NULL REFERENCES tests(id) ON DELETE CASCADE,
    group_id UUID REFERENCES question_groups(id) ON DELETE SET NULL,
    question_number INT NOT NULL,
    subject VARCHAR(100) NOT NULL DEFAULT 'General',
    difficulty VARCHAR(20) DEFAULT 'Medium',
    question_text TEXT NOT NULL,
    question_image_url TEXT,
    options JSONB NOT NULL,
    correct_answer VARCHAR(10) NOT NULL,
    explanation TEXT,
    explanation_image_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now())
);

-- Indexes for blazing fast query speeds
CREATE INDEX IF NOT EXISTS idx_questions_test_id ON questions(test_id);
CREATE INDEX IF NOT EXISTS idx_questions_group_id ON questions(group_id);
CREATE INDEX IF NOT EXISTS idx_tests_exam_code ON tests(exam_code, paper_type);

-- Enable RLS
ALTER TABLE tests ENABLE ROW LEVEL SECURITY;
ALTER TABLE question_groups ENABLE ROW LEVEL SECURITY;
ALTER TABLE questions ENABLE ROW LEVEL SECURITY;

-- Drop old policies if any to ensure clean rerun
DO $$ 
BEGIN
    DROP POLICY IF EXISTS "Allow public read access to tests" ON tests;
    DROP POLICY IF EXISTS "Allow public read access to question_groups" ON question_groups;
    DROP POLICY IF EXISTS "Allow public read access to questions" ON questions;
    DROP POLICY IF EXISTS "Allow all on tests" ON tests;
    DROP POLICY IF EXISTS "Allow all on question_groups" ON question_groups;
    DROP POLICY IF EXISTS "Allow all on questions" ON questions;
END $$;

-- Public read policies for students
CREATE POLICY "Allow public read access to tests" ON tests FOR SELECT USING (true);
CREATE POLICY "Allow public read access to question_groups" ON question_groups FOR SELECT USING (true);
CREATE POLICY "Allow public read access to questions" ON questions FOR SELECT USING (true);

-- Full access for service/authenticated roles
CREATE POLICY "Allow all on tests" ON tests FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Allow all on question_groups" ON question_groups FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Allow all on questions" ON questions FOR ALL USING (true) WITH CHECK (true);
