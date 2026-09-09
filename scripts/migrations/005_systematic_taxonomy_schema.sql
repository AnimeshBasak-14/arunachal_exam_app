-- ====================================================================
-- ARUNACHAL EXAM PREP - SUPABASE DATABASE MIGRATION
-- MIGRATION: 005_systematic_taxonomy_schema.sql
-- Systematic Hierarchical Taxonomy & ID Coding Architecture:
-- 1. Agencies (APSSB, APPSC)
-- 2. Engineering & Allied Branches (GEN, CE, EE, ME, CSE, ECE, AGRI, etc.)
-- 3. Exam Cadre Catalog (CGLE, CHSL, CSLE, CCE, JE, AE, ADO, etc.)
-- 4. Systematic Subject Catalog (ENG, MATH, GK, APGK, CE_SOM, CSE_PROG, etc.)
-- 5. Granular Topic Catalog (MATH-ARITH, GK-HIST, etc.)
-- 6. Tests & Groups Upgrades (test_code, group_code, branch_code)
-- 7. Backfill of existing records + Compatibility Views
-- ====================================================================
-- Execute this script in your Supabase Dashboard -> SQL Editor
-- ====================================================================

-- --------------------------------------------------------------------
-- 1. CATALOG TABLES CREATION
-- --------------------------------------------------------------------

-- 1.1 Agencies Catalog
CREATE TABLE IF NOT EXISTS public.agencies (
    agency_code VARCHAR(20) PRIMARY KEY,
    name TEXT NOT NULL,
    description TEXT,
    created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now())
);

-- 1.2 Engineering & Allied Branches Catalog
CREATE TABLE IF NOT EXISTS public.branches (
    branch_code VARCHAR(20) PRIMARY KEY,
    name TEXT NOT NULL,
    category VARCHAR(50) NOT NULL DEFAULT 'general',
    created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now())
);

-- 1.3 Exam Cadres Catalog
CREATE TABLE IF NOT EXISTS public.exam_catalog (
    exam_code VARCHAR(30) PRIMARY KEY,
    agency_code VARCHAR(20) REFERENCES public.agencies(agency_code) ON DELETE CASCADE,
    title TEXT NOT NULL,
    qualification_level VARCHAR(50),
    created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now())
);

-- 1.4 Systematic Subject Catalog
CREATE TABLE IF NOT EXISTS public.subject_catalog (
    subject_code VARCHAR(50) PRIMARY KEY,
    branch_code VARCHAR(20) REFERENCES public.branches(branch_code) ON DELETE CASCADE DEFAULT 'GEN',
    name TEXT NOT NULL,
    category VARCHAR(50) DEFAULT 'general',
    created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now())
);

-- 1.5 Topic Catalog
CREATE TABLE IF NOT EXISTS public.topic_catalog (
    topic_code VARCHAR(50) PRIMARY KEY,
    subject_code VARCHAR(50) REFERENCES public.subject_catalog(subject_code) ON DELETE CASCADE,
    name TEXT NOT NULL,
    description TEXT,
    created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now())
);

-- --------------------------------------------------------------------
-- 2. ALTER EXISTING TABLES WITH NEW TAXONOMY COLUMNS
-- --------------------------------------------------------------------

-- 2.1 Upgrade `tests` table
ALTER TABLE public.tests
    ADD COLUMN IF NOT EXISTS test_code VARCHAR(100),
    ADD COLUMN IF NOT EXISTS agency_code VARCHAR(20) REFERENCES public.agencies(agency_code) ON DELETE SET NULL,
    ADD COLUMN IF NOT EXISTS branch_code VARCHAR(20) REFERENCES public.branches(branch_code) ON DELETE SET NULL DEFAULT 'GEN';

-- Ensure test_code is unique if present
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'tests_test_code_unique'
    ) THEN
        ALTER TABLE public.tests ADD CONSTRAINT tests_test_code_unique UNIQUE (test_code);
    END IF;
EXCEPTION
    WHEN others THEN NULL;
END $$;

-- 2.2 Upgrade `question_groups` table
ALTER TABLE public.question_groups
    ADD COLUMN IF NOT EXISTS group_code VARCHAR(100);

-- 2.3 Upgrade `questions` table
ALTER TABLE public.questions
    ADD COLUMN IF NOT EXISTS subject_code VARCHAR(50) REFERENCES public.subject_catalog(subject_code) ON DELETE SET NULL,
    ADD COLUMN IF NOT EXISTS topic_code VARCHAR(50) REFERENCES public.topic_catalog(topic_code) ON DELETE SET NULL;

-- --------------------------------------------------------------------
-- 3. SEED CATALOG DATA
-- --------------------------------------------------------------------

-- 3.1 Agencies
INSERT INTO public.agencies (agency_code, name, description) VALUES
('APSSB', 'Arunachal Pradesh Staff Selection Board', 'Recruitment board for Group C non-gazetted administrative and technical posts.'),
('APPSC', 'Arunachal Pradesh Public Service Commission', 'Constitutional state commission for Group A & B gazetted officers and civil services.')
ON CONFLICT (agency_code) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description;

-- 3.2 Branches (Engineering, General & Allied)
INSERT INTO public.branches (branch_code, name, category) VALUES
('GEN', 'General Studies & Non-Technical', 'general'),
('CE', 'Civil Engineering', 'engineering'),
('EE', 'Electrical Engineering', 'engineering'),
('ME', 'Mechanical Engineering', 'engineering'),
('CSE', 'Computer Science & Engineering / IT', 'engineering'),
('ECE', 'Electronics & Communication Engineering', 'engineering'),
('AGRI', 'Agricultural Science & Engineering', 'allied_science'),
('HORT', 'Horticulture Science', 'allied_science'),
('VET', 'Veterinary Science & Animal Husbandry', 'allied_science'),
('FOREST', 'Forestry & Wildlife Science', 'allied_science')
ON CONFLICT (branch_code) DO UPDATE SET name = EXCLUDED.name, category = EXCLUDED.category;

-- 3.3 Exam Catalog (APSSB & APPSC)
INSERT INTO public.exam_catalog (exam_code, agency_code, title, qualification_level) VALUES
-- APSSB
('CGLE', 'APSSB', 'Combined Graduate Level Examination', 'graduate'),
('CHSL', 'APSSB', 'Combined Higher Secondary Level Examination', 'higher_secondary'),
('CSLE', 'APSSB', 'Combined Secondary Level Examination', 'matric'),
('STENO', 'APSSB', 'Stenographer Grade-III Examination', 'higher_secondary'),
('FOREST', 'APSSB', 'Forester & Forest Guard Examination', 'matric'),
('POLICE', 'APSSB', 'Police Constable / IRBn / AAPBn Examination', 'matric'),
('DRIVER', 'APSSB', 'Driver Recruitment Examination', 'matric'),
('TECH', 'APSSB', 'Technical Trade & ITI Examination', 'vocational'),
-- APPSC
('CCE', 'APPSC', 'Combined Competitive Examination (Civil Services)', 'graduate'),
('JE', 'APPSC', 'Junior Engineer Examination', 'diploma'),
('AE', 'APPSC', 'Assistant Engineer Examination', 'degree'),
('SI', 'APPSC', 'Sub-Inspector of Police Examination', 'graduate'),
('ADO', 'APPSC', 'Agriculture Development Officer Examination', 'degree'),
('HDO', 'APPSC', 'Horticulture Development Officer Examination', 'degree'),
('VET', 'APPSC', 'Veterinary Officer Examination', 'degree'),
('FEO', 'APPSC', 'Fisheries Extension Officer Examination', 'degree'),
('RFO', 'APPSC', 'Range Forest Officer Examination', 'degree'),
('LECT', 'APPSC', 'Polytechnic Lecturer Examination', 'post_graduate'),
('ASSTPROF', 'APPSC', 'Assistant Professor Examination', 'post_graduate')
ON CONFLICT (exam_code) DO UPDATE SET title = EXCLUDED.title, agency_code = EXCLUDED.agency_code, qualification_level = EXCLUDED.qualification_level;

-- 3.4 Subject Catalog
INSERT INTO public.subject_catalog (subject_code, branch_code, name, category) VALUES
-- Non-Technical / General Papers (Used across APSSB & APPSC Prelims)
('ENG', 'GEN', 'General English', 'general'),
('MATH', 'GEN', 'Elementary Mathematics', 'general'),
('GK', 'GEN', 'General Knowledge / Studies', 'general'),
('APGK', 'GEN', 'Arunachal Pradesh General Knowledge', 'state_gk'),
('REAS', 'GEN', 'Logical Reasoning & Mental Ability', 'aptitude'),
('CSAT', 'GEN', 'Civil Services Aptitude Test', 'aptitude'),

-- Civil Engineering (CE)
('CE_SOM', 'CE', 'Strength of Materials & Structural Mechanics', 'technical'),
('CE_RCC', 'CE', 'Reinforced Concrete & Steel Structures', 'technical'),
('CE_SURV', 'CE', 'Surveying & Geomatics', 'technical'),
('CE_FLUID', 'CE', 'Fluid Mechanics, Hydraulics & Irrigation', 'technical'),
('CE_GEO', 'CE', 'Soil Mechanics & Geotechnical Engineering', 'technical'),
('CE_TRANS', 'CE', 'Highway & Transportation Engineering', 'technical'),
('CE_ENV', 'CE', 'Environmental & Sanitary Engineering', 'technical'),
('CE_BLD', 'CE', 'Building Materials & Construction Management', 'technical'),
('CE_ESTIM', 'CE', 'Estimating, Costing & Specifications', 'technical'),

-- Electrical Engineering (EE)
('EE_CKT', 'EE', 'Circuit Theory & Network Analysis', 'technical'),
('EE_MACH', 'EE', 'Electrical Machines & Transformers', 'technical'),
('EE_POWER', 'EE', 'Power Systems, Transmission & Protection', 'technical'),
('EE_CTRL', 'EE', 'Control Systems & Instrumentation', 'technical'),
('EE_MEAS', 'EE', 'Electrical & Electronic Measurements', 'technical'),
('EE_ELEC', 'EE', 'Basic & Power Electronics', 'technical'),

-- Mechanical Engineering (ME)
('ME_THERM', 'ME', 'Thermodynamics & IC Engines', 'technical'),
('ME_FLUID', 'ME', 'Fluid Mechanics & Hydraulic Machinery', 'technical'),
('ME_MFG', 'ME', 'Manufacturing Science & Production Tech', 'technical'),
('ME_TOM', 'ME', 'Theory of Machines & Machine Design', 'technical'),
('ME_SOM', 'ME', 'Engineering Mechanics & Strength of Materials', 'technical'),

-- Computer Science / IT (CSE)
('CSE_PROG', 'CSE', 'Programming (C/C++/Java/Python) & Data Structures', 'technical'),
('CSE_DBMS', 'CSE', 'Database Management Systems & SQL', 'technical'),
('CSE_OS', 'CSE', 'Operating Systems & System Software', 'technical'),
('CSE_NET', 'CSE', 'Computer Networks & Cybersecurity', 'technical'),
('CSE_SE', 'CSE', 'Software Engineering & Web Tech', 'technical'),
('CSE_DLD', 'CSE', 'Digital Logic & Computer Architecture', 'technical'),

-- Agricultural Science (AGRI)
('AGRI_AGRO', 'AGRI', 'Agronomy & Crop Production', 'technical'),
('AGRI_SOIL', 'AGRI', 'Soil Science & Agricultural Chemistry', 'technical'),
('AGRI_PATH', 'AGRI', 'Plant Pathology & Crop Protection', 'technical'),
('AGRI_HORT', 'AGRI', 'Horticulture & Vegetable Production', 'technical'),
('AGRI_EXT', 'AGRI', 'Agricultural Extension & Economics', 'technical'),
('AGRI_ENGG', 'AGRI', 'Farm Machinery, Power & Soil Water Engg', 'technical')
ON CONFLICT (subject_code) DO UPDATE SET name = EXCLUDED.name, branch_code = EXCLUDED.branch_code, category = EXCLUDED.category;

-- 3.5 Topic Catalog (Key Topics)
INSERT INTO public.topic_catalog (topic_code, subject_code, name, description) VALUES
-- Mathematics
('MATH-ARITH', 'MATH', 'Arithmetic & Commercial Math', 'Percentage, Profit/Loss, Ratio/Proportion, Simple & Compound Interest, Time & Work, Speed/Distance'),
('MATH-NUM', 'MATH', 'Number System & Simplification', 'BODMAS, Fractions, Decimals, Surds & Indices, HCF/LCM, Divisibility rules'),
('MATH-ALG', 'MATH', 'Algebra & Polynomials', 'Linear equations, Quadratic equations, Factorization, Algebraic identities'),
('MATH-GEOM', 'MATH', 'Geometry & Mensuration', 'Triangles, Quadrilaterals, Circles, Coordinate geometry, Perimeter, Area, Surface area, Volume'),
('MATH-TRIG', 'MATH', 'Trigonometry', 'Trigonometric ratios, Standard angles, Heights and Distances, Basic identities'),
('MATH-STAT', 'MATH', 'Statistics & Probability', 'Mean, Median, Mode, Standard Deviation, Basic probability'),

-- English
('ENG-VOCAB', 'ENG', 'Vocabulary & Word Power', 'Synonyms, Antonyms, Homonyms, One-word substitution, Spelling check'),
('ENG-GRAM', 'ENG', 'Grammar & Usage', 'Tenses, Subject-Verb agreement, Articles, Prepositions, Conjunctions, Active/Passive voice, Direct/Indirect speech'),
('ENG-IDIOM', 'ENG', 'Idioms & Phrases', 'Idiomatic expressions, Phrasal verbs, Common sayings'),
('ENG-COMP', 'ENG', 'Reading Comprehension', 'Passage analysis, Inference questions, Main idea, Tone'),
('ENG-ERR', 'ENG', 'Spotting Errors & Sentence Correction', 'Error identification, Sentence improvement, Cloze test'),

-- General Knowledge / Studies
('GK-HIST', 'GK', 'Indian History', 'Ancient India, Medieval India, Indian National Movement & Modern History'),
('GK-POL', 'GK', 'Indian Polity & Constitution', 'Preamble, Fundamental Rights/Duties, Parliament, Judiciary, Constitutional Amendments'),
('GK-GEOG', 'GK', 'Indian & World Geography', 'Physical features, Rivers, Climate, Minerals, Agriculture, World continents & oceans'),
('GK-ECON', 'GK', 'Indian Economy', 'Budget, Five Year Plans, RBI monetary policy, Inflation, National Income, Banking'),
('GK-SCI', 'GK', 'General Science', 'Everyday Physics, Basic Chemistry, Biology, Diseases, Human physiology'),
('GK-CA', 'GK', 'Current Affairs', 'National & International events, Awards, Sports, Government schemes, Defense'),

-- Arunachal Pradesh GK
('APGK-HIST', 'APGK', 'Arunachal History & Statehood', 'NEFA history, 1962 conflict, UT to Statehood in 1987, Historical monuments'),
('APGK-TRIB', 'APGK', 'Tribes, Culture & Festivals', 'Nyishi (Nyokum), Adi (Solung), Galo (Mopin), Apatani (Dree), Monpa (Losar), Mishmi (Reh), etc.'),
('APGK-GEOG', 'APGK', 'Arunachal Geography & Ecology', 'Rivers (Siang, Subansiri, Kameng), High passes (Sela, Bum La), Namdapha & Mouling National Parks'),
('APGK-POL', 'APGK', 'Arunachal Administration & Polity', 'Districts, Assembly constituencies, Autonomous councils, Panchayati Raj'),

-- Logical Reasoning
('REAS-VERB', 'REAS', 'Verbal Reasoning', 'Analogy, Classification, Series completion, Coding-Decoding, Blood relations, Direction sense'),
('REAS-NONVERB', 'REAS', 'Non-Verbal Reasoning', 'Pattern completion, Mirror/Water images, Paper folding, Cube and dice, Embedded figures')
ON CONFLICT (topic_code) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description;

-- --------------------------------------------------------------------
-- 4. BACKFILL EXISTING TESTS AND QUESTIONS
-- --------------------------------------------------------------------

-- 4.1 Backfill agency_code on `tests`
UPDATE public.tests
SET agency_code = CASE
    WHEN exam_code ILIKE '%APPSC%' THEN 'APPSC'
    ELSE 'APSSB'
END
WHERE agency_code IS NULL;

-- 4.2 Backfill branch_code on `tests`
UPDATE public.tests
SET branch_code = CASE
    WHEN title ILIKE '%Civil%' OR exam_code ILIKE '%CE%' THEN 'CE'
    WHEN title ILIKE '%Electrical%' OR exam_code ILIKE '%EE%' THEN 'EE'
    WHEN title ILIKE '%Mechanical%' OR exam_code ILIKE '%ME%' THEN 'ME'
    WHEN title ILIKE '%Computer%' OR exam_code ILIKE '%CSE%' THEN 'CSE'
    WHEN title ILIKE '%Agriculture%' OR exam_code ILIKE '%ADO%' OR exam_code ILIKE '%AGRI%' THEN 'AGRI'
    ELSE 'GEN'
END
WHERE branch_code IS NULL;

-- 4.3 Backfill test_code on `tests` if null
UPDATE public.tests
SET test_code = COALESCE(
    exam_code || '-' || COALESCE(year::text, '2024') || '-' || COALESCE(paper_type, 'PYQ') || '-' || SUBSTRING(id::text, 1, 4),
    'TEST-' || SUBSTRING(id::text, 1, 8)
)
WHERE test_code IS NULL;

-- 4.4 Backfill subject_code on `questions` based on existing subject text
UPDATE public.questions
SET subject_code = CASE
    WHEN subject ILIKE '%English%' THEN 'ENG'
    WHEN subject ILIKE '%Math%' OR subject ILIKE '%Arithmetic%' OR subject ILIKE '%Quantitative%' THEN 'MATH'
    WHEN subject ILIKE '%Arunachal%' THEN 'APGK'
    WHEN subject ILIKE '%Reasoning%' OR subject ILIKE '%Mental%' OR subject ILIKE '%Aptitude%' THEN 'REAS'
    WHEN subject ILIKE '%Civil%' THEN 'CE_SOM'
    WHEN subject ILIKE '%Electrical%' THEN 'EE_CKT'
    WHEN subject ILIKE '%Mechanical%' THEN 'ME_THERM'
    WHEN subject ILIKE '%Computer%' THEN 'CSE_PROG'
    WHEN subject ILIKE '%Agri%' THEN 'AGRI_AGRO'
    ELSE 'GK'
END
WHERE subject_code IS NULL;

-- --------------------------------------------------------------------
-- 5. COMPATIBILITY VIEWS & HELPER FUNCTIONS
-- --------------------------------------------------------------------

-- Unified Question View joining all catalogs for clean UI and exports
CREATE OR REPLACE VIEW public.v_questions_expanded AS
SELECT
    q.id,
    q.test_id,
    q.group_id,
    t.test_code,
    t.title AS test_title,
    t.exam_code,
    t.year,
    t.paper_type,
    t.agency_code,
    a.name AS agency_name,
    t.branch_code,
    b.name AS branch_name,
    q.question_number,
    q.order_index,
    q.subject_code,
    s.name AS subject_name,
    s.category AS subject_category,
    q.topic_code,
    tc.name AS topic_name,
    q.question_type,
    q.content_format,
    q.direction_text,
    q.question_text,
    q.question_image_url,
    q.options,
    q.correct_option,
    q.marks,
    q.negative_marks,
    q.explanation,
    q.explanation_image_url,
    q.difficulty,
    q.review_status,
    q.flagged_issues,
    q.admin_notes,
    g.group_code,
    g.group_type,
    g.passage_text,
    g.image_url AS group_image_url,
    q.created_at,
    q.updated_at
FROM public.questions q
LEFT JOIN public.tests t ON q.test_id = t.id
LEFT JOIN public.agencies a ON t.agency_code = a.agency_code
LEFT JOIN public.branches b ON t.branch_code = b.branch_code
LEFT JOIN public.subject_catalog s ON q.subject_code = s.subject_code
LEFT JOIN public.topic_catalog tc ON q.topic_code = tc.topic_code
LEFT JOIN public.question_groups g ON q.group_id = g.id;

-- --------------------------------------------------------------------
-- 6. PERMISSIONS & ROW LEVEL SECURITY (RLS)
-- --------------------------------------------------------------------

-- Enable RLS on catalog tables
ALTER TABLE public.agencies ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.branches ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.exam_catalog ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.subject_catalog ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.topic_catalog ENABLE ROW LEVEL SECURITY;

-- Allow public read access to catalogs
DO $$
BEGIN
    DROP POLICY IF EXISTS "Allow public read on agencies" ON public.agencies;
    CREATE POLICY "Allow public read on agencies" ON public.agencies FOR SELECT USING (true);

    DROP POLICY IF EXISTS "Allow public read on branches" ON public.branches;
    CREATE POLICY "Allow public read on branches" ON public.branches FOR SELECT USING (true);

    DROP POLICY IF EXISTS "Allow public read on exam_catalog" ON public.exam_catalog;
    CREATE POLICY "Allow public read on exam_catalog" ON public.exam_catalog FOR SELECT USING (true);

    DROP POLICY IF EXISTS "Allow public read on subject_catalog" ON public.subject_catalog;
    CREATE POLICY "Allow public read on subject_catalog" ON public.subject_catalog FOR SELECT USING (true);

    DROP POLICY IF EXISTS "Allow public read on topic_catalog" ON public.topic_catalog;
    CREATE POLICY "Allow public read on topic_catalog" ON public.topic_catalog FOR SELECT USING (true);

    -- Allow authenticated / service_role full access
    DROP POLICY IF EXISTS "Allow service_role full on agencies" ON public.agencies;
    CREATE POLICY "Allow service_role full on agencies" ON public.agencies FOR ALL USING (true) WITH CHECK (true);

    DROP POLICY IF EXISTS "Allow service_role full on branches" ON public.branches;
    CREATE POLICY "Allow service_role full on branches" ON public.branches FOR ALL USING (true) WITH CHECK (true);

    DROP POLICY IF EXISTS "Allow service_role full on exam_catalog" ON public.exam_catalog;
    CREATE POLICY "Allow service_role full on exam_catalog" ON public.exam_catalog FOR ALL USING (true) WITH CHECK (true);

    DROP POLICY IF EXISTS "Allow service_role full on subject_catalog" ON public.subject_catalog;
    CREATE POLICY "Allow service_role full on subject_catalog" ON public.subject_catalog FOR ALL USING (true) WITH CHECK (true);

    DROP POLICY IF EXISTS "Allow service_role full on topic_catalog" ON public.topic_catalog;
    CREATE POLICY "Allow service_role full on topic_catalog" ON public.topic_catalog FOR ALL USING (true) WITH CHECK (true);
EXCEPTION
    WHEN others THEN NULL;
END $$;

-- Grant permissions to anon and authenticated roles
GRANT SELECT ON public.agencies TO anon, authenticated;
GRANT SELECT ON public.branches TO anon, authenticated;
GRANT SELECT ON public.exam_catalog TO anon, authenticated;
GRANT SELECT ON public.subject_catalog TO anon, authenticated;
GRANT SELECT ON public.topic_catalog TO anon, authenticated;
GRANT SELECT ON public.v_questions_expanded TO anon, authenticated;

GRANT ALL ON public.agencies TO service_role;
GRANT ALL ON public.branches TO service_role;
GRANT ALL ON public.exam_catalog TO service_role;
GRANT ALL ON public.subject_catalog TO service_role;
GRANT ALL ON public.topic_catalog TO service_role;
GRANT ALL ON public.v_questions_expanded TO service_role;
