-- ====================================================================
-- ARUNACHAL EXAM PREP - SUPABASE DATABASE CLEANUP SCRIPT
-- Paste this script into Supabase Dashboard -> SQL Editor and click 'Run'
-- ====================================================================

-- 1. Fix common OCR artifacts in math & geometry questions
UPDATE questions
SET question_text = REPLACE(question_text, 'Iniriangles', 'In triangles')
WHERE question_text LIKE '%Iniriangles%';

UPDATE questions
SET question_text = REPLACE(question_text, 'AABC', 'ΔABC')
WHERE question_text LIKE '%AABC%';

UPDATE questions
SET question_text = REPLACE(question_text, 'APQR', 'ΔPQR')
WHERE question_text LIKE '%APQR%';

UPDATE questions
SET question_text = REPLACE(question_text, '[A =IQ', '∠A = ∠Q')
WHERE question_text LIKE '%[A =IQ%';

UPDATE questions
SET question_text = REPLACE(question_text, 'I B =IR', '∠B = ∠R')
WHERE question_text LIKE '%I B =IR%';

-- 2. Correct Subject classifications for Elementary Maths
UPDATE questions
SET subject = 'Elementary Maths'
WHERE (subject = 'General Studies' OR subject IS NULL)
  AND (
    question_text ILIKE '%triangle%' OR
    question_text ILIKE '%perimeter%' OR
    question_text ILIKE '%algebra%' OR
    question_text ILIKE '%ratio%' OR
    question_text ILIKE '%simple interest%' OR
    question_text ILIKE '%profit and loss%' OR
    question_text ILIKE '%cylinder%' OR
    question_text ILIKE '%polynomial%'
  );

-- 3. Correct Subject classifications for General English
UPDATE questions
SET subject = 'General English'
WHERE (subject = 'General Studies' OR subject IS NULL)
  AND (
    question_text ILIKE '%synonym%' OR
    question_text ILIKE '%antonym%' OR
    question_text ILIKE '%idiom%' OR
    question_text ILIKE '%passive voice%' OR
    question_text ILIKE '%preposition%' OR
    question_text ILIKE '%misspelt%'
  );

-- 4. Correct Subject classifications for Reasoning
UPDATE questions
SET subject = 'General Intelligence & Reasoning'
WHERE (subject = 'General Studies' OR subject IS NULL)
  AND (
    question_text ILIKE '%series%' OR
    question_text ILIKE '%analogy%' OR
    question_text ILIKE '%syllogism%' OR
    question_text ILIKE '%coding-decoding%' OR
    question_text ILIKE '%blood relation%'
  );

-- 5. Standardize Test marking schemes (+2 correct, -0.5 negative)
UPDATE tests
SET marks_per_correct = 2.0,
    negative_marks = 0.5
WHERE marks_per_correct IS NULL OR marks_per_correct = 0;

-- 6. Calibrate CGL 2024 test duration to match live questions
UPDATE tests
SET duration_minutes = 60
WHERE exam_code = 'APSSB-CGLE' AND year = 2024;

-- 7. View questions summary after cleanup
SELECT 
    t.exam_code,
    t.year,
    t.title,
    COUNT(q.id) AS total_questions,
    t.duration_minutes,
    t.marks_per_correct,
    t.negative_marks
FROM tests t
LEFT JOIN questions q ON q.test_id = t.id
GROUP BY t.id, t.exam_code, t.year, t.title, t.duration_minutes, t.marks_per_correct, t.negative_marks
ORDER BY t.year DESC;
