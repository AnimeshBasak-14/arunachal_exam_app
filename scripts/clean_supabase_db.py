"""
ARUNACHAL EXAM PREP - SUPABASE DATABASE CLEANER & AUDITOR
==========================================================
This script inspects, audits, and repairs question data in Supabase.

Usage:
  # 1. Audit and print health report of the database:
  python scripts/clean_supabase_db.py --audit

  # 2. Preview OCR text and subject fixes (dry-run):
  python scripts/clean_supabase_db.py --fix-ocr --dry-run

  # 3. Apply OCR and subject fixes:
  python scripts/clean_supabase_db.py --fix-ocr --apply

  # 4. Generate SQL cleanup script for Supabase Dashboard:
  python scripts/clean_supabase_db.py --generate-sql
"""

import os
import sys
import re
import json
import argparse
import requests

if hasattr(sys.stdout, 'reconfigure'):
    try:
        sys.stdout.reconfigure(encoding='utf-8', line_buffering=True)
        sys.stderr.reconfigure(encoding='utf-8', line_buffering=True)
    except Exception:
        pass

SUPABASE_URL = os.environ.get('SUPABASE_URL', 'https://fllopztywwblbucvaths.supabase.co')
# Use service_role key if available for write operations, else fallback to anon key
SUPABASE_KEY = os.environ.get('SUPABASE_KEY', 'sb_publishable_y68QKKHxBTZxBP3Sf1X7tw_zfFnXX8M')

HEADERS = {
    'apikey': SUPABASE_KEY,
    'Authorization': f'Bearer {SUPABASE_KEY}',
    'Content-Type': 'application/json',
    'Prefer': 'return=representation',
}

# --- OCR REPAIR RULES ---
OCR_REPLACEMENTS = [
    (r'\bIniriangles\b', 'In triangles'),
    (r'\[A\s*=\s*IQ', '∠A = ∠Q'),
    (r'I\s*B\s*=\s*IR', '∠B = ∠R'),
    (r'\bAABC\b', 'ΔABC'),
    (r'\bAPQR\b', 'ΔPQR'),
    (r'\bAXYZ\b', 'ΔXYZ'),
    (r'\bADef\b', 'ΔDEF'),
    (r'\bADEF\b', 'ΔDEF'),
    (r'\[([A-Z])\s*=\s*([A-Z])', r'∠\1 = ∠\2'),
    (r'\s{2,}', ' '), # Collapse multiple spaces
]

def classify_subject(text):
    """Classifies question into accurate subject based on keywords."""
    t = text.lower()
    # Elementary Maths
    if any(k in t for k in ['triangle', 'congruent', 'perimeter', 'algebra', 'ratio', 'percentage',
                            'profit', 'loss', 'simple interest', 'compound interest', 'hcf', 'lcm',
                            'speed', 'distance', 'cylinder', 'sphere', 'radius', 'polynomial',
                            'arithmetic', 'trigonometry', 'sin ', 'cos ', 'tan ']):
        return 'Elementary Maths'
    # English Grammar & Vocabulary
    if any(k in t for k in ['antonym', 'synonym', 'idiom', 'preposition', 'passive voice',
                            'active voice', 'indirect speech', 'direct speech', 'one word substitution',
                            'misspelt', 'spelt correctly', 'grammatical error', 'fill in the blank']):
        return 'General English'
    # English Comprehension
    if any(k in t for k in ['comprehension', 'passage', 'according to the passage', 'read the following']):
        return 'English Comprehension'
    # Reasoning
    if any(k in t for k in ['series', 'analogy', 'odd one out', 'syllogism', 'blood relation',
                            'coding-decoding', 'direction sense', 'seating arrangement', 'venn diagram']):
        return 'General Intelligence & Reasoning'
    # Arunachal GK
    if any(k in t for k in ['arunachal', 'itangar', 'tawang', 'namdapha', 'kameng', 'subansiri',
                            'siang', 'tirap', 'changlang', 'nyishi', 'galog', 'monpa', 'adi tribe']):
        return 'Arunachal Pradesh GK'
    # General Science
    if any(k in t for k in ['photosynthesis', 'chromosome', 'dna', 'cell', 'newton', 'velocity',
                            'chemical formula', 'acid', 'base', 'vitamin', 'hormone', 'respiration']):
        return 'General Science'
    # General Studies
    return 'General Studies'

def fetch_tests():
    url = f"{SUPABASE_URL}/rest/v1/tests?select=id,title,exam_code,year,paper_type,duration_minutes,marks_per_correct,negative_marks"
    r = requests.get(url, headers=HEADERS, timeout=15)
    if r.status_code == 200:
        return r.json()
    print(f"❌ Error fetching tests: {r.status_code} {r.text}")
    return []

def fetch_questions(test_id=None):
    url = f"{SUPABASE_URL}/rest/v1/questions?select=id,test_id,question_number,question_text,options,correct_answer,subject,explanation"
    if test_id:
        url += f"&test_id=eq.{test_id}"
    url += "&order=question_number.asc"
    r = requests.get(url, headers=HEADERS, timeout=30)
    if r.status_code == 200:
        return r.json()
    print(f"[ERROR] Error fetching questions: {r.status_code} {r.text}")
    return []

def audit_database():
    print("=" * 70)
    print("SUPABASE EXAM DATABASE HEALTH AUDIT")
    print("=" * 70)
    
    tests = fetch_tests()
    print(f"\nTotal Tests Found: {len(tests)}")
    
    total_questions = 0
    issues = {
        'ocr_typos': 0,
        'missing_options': 0,
        'clustered_options': 0,
        'generic_subject': 0,
    }

    for t in tests:
        t_id = t['id']
        questions = fetch_questions(t_id)
        count = len(questions)
        total_questions += count
        
        print(f"\n* [{t.get('exam_code')}] {t.get('title')} ({t.get('year')}) - Type: {t.get('paper_type')}")
        print(f"  ID: {t_id}")
        print(f"  Live Questions in DB: {count} questions | Duration: {t.get('duration_minutes')}m | Marking: +{t.get('marks_per_correct')} / -{t.get('negative_marks')}")
        
        # Check questions in this test
        for q in questions:
            q_text = q.get('question_text') or ''
            options = q.get('options') or []
            subject = q.get('subject') or ''
            
            # 1. OCR Typos
            for pat, _ in OCR_REPLACEMENTS:
                if re.search(pat, q_text):
                    issues['ocr_typos'] += 1
                    break
            
            # 2. Options check
            if len(options) < 4:
                issues['missing_options'] += 1
            else:
                for opt in options:
                    txt = opt.get('text', '') if isinstance(opt, dict) else str(opt)
                    if re.search(r'\([b-d]\)', txt.lower()):
                        issues['clustered_options'] += 1
                        break
            
            # 3. Subject generic check
            if subject == 'General Studies' or not subject:
                suggested = classify_subject(q_text)
                if suggested != 'General Studies':
                    issues['generic_subject'] += 1

    print("\n" + "=" * 70)
    print("AUDIT SUMMARY:")
    print(f"  * Total Questions: {total_questions}")
    print(f"  * Questions with OCR / Math Corruptions: {issues['ocr_typos']}")
    print(f"  * Questions with Missing Options (< 4): {issues['missing_options']}")
    print(f"  * Options with Clustered Answers: {issues['clustered_options']}")
    print(f"  * Questions with Generic 'General Studies' Tag: {issues['generic_subject']}")
    print("=" * 70)

def fix_ocr_and_subjects(dry_run=True):
    print("=" * 70)
    print(f"REPAIRING OCR AND SUBJECTS ({'DRY-RUN' if dry_run else 'LIVE APPLY'})")
    print("=" * 70)

    tests = fetch_tests()
    fixed_count = 0

    for t in tests:
        questions = fetch_questions(t['id'])
        for q in questions:
            q_id = q['id']
            old_text = q.get('question_text') or ''
            old_subject = q.get('subject') or ''
            
            # Apply OCR fixes
            new_text = old_text
            for pat, repl in OCR_REPLACEMENTS:
                new_text = re.sub(pat, repl, new_text)
            
            # Suggest subject
            new_subject = classify_subject(new_text) if old_subject in ('General Studies', '') else old_subject
            
            has_text_change = new_text != old_text
            has_subject_change = new_subject != old_subject
            
            if has_text_change or has_subject_change:
                fixed_count += 1
                if dry_run:
                    print(f"\n[Question {q.get('question_number')}] {q_id}:")
                    if has_text_change:
                        print(f"  OLD TEXT: {old_text[:90]}...")
                        print(f"  NEW TEXT: {new_text[:90]}...")
                    if has_subject_change:
                        print(f"  SUBJECT: {old_subject} -> {new_subject}")
                else:
                    # Update question in Supabase
                    patch_payload = {}
                    if has_text_change:
                        patch_payload['question_text'] = new_text
                    if has_subject_change:
                        patch_payload['subject'] = new_subject
                    
                    patch_url = f"{SUPABASE_URL}/rest/v1/questions?id=eq.{q_id}"
                    res = requests.patch(patch_url, headers=HEADERS, json=patch_payload, timeout=10)
                    if res.status_code in (200, 204):
                        print(f"  [OK] Updated question {q.get('question_number')}")
                    else:
                        print(f"  [ERROR] Failed to update {q_id}: {res.status_code} {res.text}")

    print(f"\n[DONE] Total questions {'identified to update' if dry_run else 'updated'}: {fixed_count}")

def generate_sql():
    sql = """-- ====================================================================
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
"""
    sql_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'supabase_cleanup_queries.sql')
    with open(sql_path, 'w', encoding='utf-8') as f:
        f.write(sql)
    print(f"[OK] Generated SQL script at: {sql_path}")
    print("\nSample SQL commands:")
    print(sql[:800] + "\n...")

def main():
    parser = argparse.ArgumentParser(description="Supabase DB Cleaner & Auditor")
    parser.add_argument('--audit', action='store_true', help="Audit database health and print report")
    parser.add_argument('--fix-ocr', action='store_true', help="Fix OCR typos in question text")
    parser.add_argument('--dry-run', action='store_true', help="Preview fixes without applying changes")
    parser.add_argument('--apply', action='store_true', help="Apply changes to Supabase")
    parser.add_argument('--generate-sql', action='store_true', help="Generate ready-to-run SQL script for Supabase Dashboard")
    args = parser.parse_args()

    if args.generate_sql:
        generate_sql()
    elif args.fix_ocr:
        fix_ocr_and_subjects(dry_run=not args.apply)
    else:
        audit_database()

if __name__ == '__main__':
    main()
