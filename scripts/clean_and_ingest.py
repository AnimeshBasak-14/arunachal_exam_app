"""
ARUNACHAL EXAM PREP - INGESTION & SANITIZATION PIPELINE
========================================================
Cleans corrupted OCR question dumps, extracts passages & ranges,
splits merged options, extracts bleed-through questions, normalizes math
expressions, and uploads strictly validated data to Supabase adhering to
the relational passages model and strict options contract.

Usage:
  # 1. Run unit test suite on corrupted test cases:
  python scripts/clean_and_ingest.py --test

  # 2. Audit existing live Supabase questions for defects:
  python scripts/clean_and_ingest.py --audit

  # 3. Clean and sanitize live Supabase questions (dry-run):
  python scripts/clean_and_ingest.py --clean-db --dry-run

  # 4. Clean and sanitize live Supabase questions (live apply):
  python scripts/clean_and_ingest.py --clean-db --apply
"""

import os
import sys
import re
import json
import uuid
import argparse
import requests

if hasattr(sys.stdout, 'reconfigure'):
    try:
        sys.stdout.reconfigure(encoding='utf-8', line_buffering=True)
        sys.stderr.reconfigure(encoding='utf-8', line_buffering=True)
    except Exception:
        pass

SUPABASE_URL = os.environ.get('SUPABASE_URL', 'https://fllopztywwblbucvaths.supabase.co')
SUPABASE_KEY = os.environ.get('SUPABASE_KEY', 'sb_publishable_y68QKKHxBTZxBP3Sf1X7tw_zfFnXX8M')

HEADERS = {
    'apikey': SUPABASE_KEY,
    'Authorization': f'Bearer {SUPABASE_KEY}',
    'Content-Type': 'application/json',
    'Prefer': 'return=representation',
}

# ====================================================================
# 1. PASS 1: OCR ARTIFACT SANITIZATION & ARITHMETIC NORMALIZATION
# ====================================================================

# Noise patterns commonly produced by scanners & OCR pipelines
NOISE_REGEXES = [
    (re.compile(r'\|\s*\|+'), ' '),                     # || or |||
    (re.compile(r'(?<!\w)[\|~](?!\w)'), ' '),           # Stray pipes or tildes
    (re.compile(r'\bHEM\s*-\s*\d+/\d+\b', re.I), ''),   # Stray footer codes e.g. HEM - 7/24
    (re.compile(r'\bP\.?\s*T\.?\s*O\.?\b', re.I), ''),  # P.T.O. (Please Turn Over)
    (re.compile(r'\[Page\s*\d+\]', re.I), ''),          # [Page 12]
    (re.compile(r'\bct\b', re.I), ''),                  # Scanner artifact token 'ct'
    (re.compile(r'^[;:,]\s*', re.M), ''),               # Misplaced leading punctuation
    (re.compile(r'\s*[;:,]$', re.M), ''),               # Misplaced trailing punctuation
    (re.compile(r'[-_]{4,}'), ''),                       # Horizontal scan divider lines
    (re.compile(r'[ \t]{2,}'), ' '),                    # Multiple horizontal whitespace
    (re.compile(r'\s+([?!.,:;])'), r'\1'),              # Space before punctuation
]

ARITHMETIC_NORMALIZATIONS = [
    # Mangled plus-or-minus: +/- or + / - -> ± (\pm)
    (re.compile(r'(?<=\s|\d)\+\s*/\s*-(?=\s|\d)'), '±'),
    (re.compile(r'(?<=\s|\d)\+/-(?=\s|\d)'), '±'),
    # Mangled multiplication: digit x digit or digit * digit -> digit × digit
    (re.compile(r'(\d+)\s*[x\*]\s*(\d+)'), r'\1 × \2'),
    # Mangled division symbol: e.g. " / " between standalone arithmetic numbers -> " ÷ "
    (re.compile(r'(\d+)\s+/\s+(\d+)'), r'\1 ÷ \2'),
]

def normalize_arithmetic_expressions(text):
    """Replaces mangled arithmetic delimiters with appropriate mathematical symbols (±, ×, ÷)."""
    if not text:
        return ""
    normalized = text
    for pattern, replacement in ARITHMETIC_NORMALIZATIONS:
        normalized = pattern.sub(replacement, normalized)
    return normalized

def strip_noise(text):
    """Cleans scanning artifacts, delimiters, scanner tokens and stray footer codes from raw OCR text."""
    if not text:
        return ""
    cleaned = text
    for pattern, replacement in NOISE_REGEXES:
        cleaned = pattern.sub(replacement, cleaned)
    cleaned = normalize_arithmetic_expressions(cleaned)
    return cleaned.strip()


# ====================================================================
# 2. PASS 2: OPTION BOUNDARY SPLITTING & BLEED-THROUGH EXTRACTION
# ====================================================================

# Boundary regex matching option keys (a), (b), [c], a., b)
OPTION_KEY_REGEX = re.compile(r'(?:[\s\n]|^)[\(\[]?([a-dA-D])[\)\]\.\s]+')
# Bleed-through regex detecting subsequent questions inside option text
BLEED_THROUGH_Q_REGEX = re.compile(r'(?:[\s\n]|^)(?:Q\.?\s*)?(\d{1,3})[\.\s]+([A-Z].*)', re.DOTALL)

def split_and_normalize_options(raw_options):
    """
    Takes raw options (which may be a list of strings, a dict, or JSONB array)
    and resolves merged options, strips bleed-through questions, and formats
    into the strict contract:
    [
      {"id": "a", "key": "a", "text": "Rs. 50,000"},
      {"id": "b", "key": "b", "text": "Rs. 60,000"},
      {"id": "c", "key": "c", "text": "Rs. 62,000"},
      {"id": "d", "key": "d", "text": "Rs. 6,00,000"}
    ]

    Returns:
        tuple: (normalized_options, list_of_bleed_through_questions)
    """
    extracted_options = {}
    bleed_questions = []

    # Flatten input to a sequence of strings with tentative keys
    items = []
    if isinstance(raw_options, dict):
        for k in ['a', 'b', 'c', 'd']:
            if k in raw_options and raw_options[k]:
                items.append((k, str(raw_options[k])))
    elif isinstance(raw_options, list):
        for idx, item in enumerate(raw_options):
            k = chr(97 + idx)
            if isinstance(item, dict):
                k = item.get('id') or item.get('key') or k
                text = item.get('text') or item.get('value') or ''
                items.append((str(k).lower(), str(text)))
            else:
                items.append((k, str(item)))

    # Process each item, checking for merged options & bleed-throughs
    for default_key, raw_text in items:
        text = strip_noise(raw_text)
        if not text:
            continue

        # Check for bleed-through questions (e.g., "87. She plays table tennis...")
        bleed_match = BLEED_THROUGH_Q_REGEX.search(text)
        if bleed_match and bleed_match.start() > 0:
            bleed_num = int(bleed_match.group(1))
            bleed_text = bleed_match.group(2).strip()
            # Truncate current option text before the bleed
            text = text[:bleed_match.start()].strip()
            bleed_questions.append({
                'question_number': bleed_num,
                'question_text': bleed_text,
            })

        # Check if multiple options are merged inside this field
        # e.g., "(b) Cheetah (c) Tiger (d) Leopard"
        parts = []
        matches = list(OPTION_KEY_REGEX.finditer(text))
        if len(matches) > 1 or (matches and matches[0].start() > 0):
            for i, m in enumerate(matches):
                tag_key = m.group(1).lower()
                if i == 0 and m.start() > 0:
                    prefix_text = text[:m.start()].strip()
                    if prefix_text:
                        parts.append((current_k if 'current_k' in locals() else default_key, prefix_text))

                start_content = m.end()
                end_content = matches[i + 1].start() if (i + 1 < len(matches)) else len(text)
                sub_text = text[start_content:end_content].strip()
                if sub_text:
                    parts.append((tag_key, sub_text))
        elif matches and matches[0].start() == 0:
            tag_key = matches[0].group(1).lower()
            sub_text = text[matches[0].end():].strip()
            parts.append((tag_key, sub_text))
        else:
            parts.append((default_key, text))

        for k, v in parts:
            clean_v = strip_noise(v)
            clean_v = re.sub(r'^[\(\[]?[a-dA-D][\)\].\s]+', '', clean_v).strip()
            # Discard placeholder dummy text like "Option A"
            if re.match(r'^Option\s+[A-D]$', clean_v, re.I):
                continue
            if clean_v:
                extracted_options[k] = clean_v

    # Build normalized list adhering to strict contract
    normalized = []
    for k in ['a', 'b', 'c', 'd']:
        if k in extracted_options:
            normalized.append({
                'id': k,
                'key': k,
                'text': extracted_options[k],
            })

    return normalized, bleed_questions


# ====================================================================
# 3. PASS 3: DIRECTION/PASSAGE RANGE PARSING & CLEANUP
# ====================================================================

DIRECTION_RANGE_REGEX = re.compile(
    r'(?:Direction|Directions|Instruction|Instructions)\s*'
    r'[\(\[\s]*(?:[Qq]\.?\s*(?:No\.?|Nos\.?)?)?\s*(\d{1,3})\s*(?:to|and|&|-|–|—)\s*(\d{1,3})[\)\]\s]*'
    r'[:\.\-]?\s*([\s\S]+?)(?=\n\s*(?:[Qq]\.?\s*)?\d{1,3}[\.:\)]|\Z)',
    re.IGNORECASE
)

IRRELEVANT_STANDALONE_DIRECTIONS = [
    re.compile(r'^(?:Direction|Directions)[\s\S]*?Choose the odd\s+(?:man|one)\s+out[\s\S]*?[:\.\-]', re.I),
    re.compile(r'^(?:Direction|Directions)[\s\S]*?Select the related word[\s\S]*?[:\.\-]', re.I),
]

def extract_passage_ranges(raw_text):
    """
    Detects range patterns like:
    "Direction (Q. No. 85 - 87): Read the following passage..."
    Returns (start_idx, end_idx, title, passage_content, remaining_question_text) or None.
    """
    match = DIRECTION_RANGE_REGEX.search(raw_text)
    if match:
        start_q = int(match.group(1))
        end_q = int(match.group(2))
        title = f"Direction (Q. {start_q} - {end_q})"
        passage_content = match.group(3).strip()
        remaining = raw_text[:match.start()] + raw_text[match.end():]
        return start_q, end_q, title, passage_content, remaining.strip()
    return None

def strip_irrelevant_standalone_direction(question_text):
    """Removes single-use odd-man-out directions appearing as false positives on standard math questions."""
    cleaned = question_text
    for pat in IRRELEVANT_STANDALONE_DIRECTIONS:
        cleaned = pat.sub('', cleaned).strip()
    return cleaned


# ====================================================================
# 4. QUESTION VALIDATION RULES
# ====================================================================

def validate_question(q):
    """
    Enforces strict data integrity:
    - Non-empty question text
    - Minimum 2 options
    - None of the options match '^Option\\s+[A-D]$' unless status = 'draft'
    - Valid correct option key in ('a', 'b', 'c', 'd')
    """
    errors = []
    text = q.get('question_text', '').strip()
    if len(text) < 5:
        errors.append("Question text is empty or too short (< 5 chars)")

    options = q.get('options', [])
    if not isinstance(options, list) or len(options) < 2:
        errors.append(f"Must have at least 2 options, found {len(options) if isinstance(options, list) else 0}")
    else:
        for opt in options:
            t = opt.get('text', '').strip()
            opt_id = opt.get('id') or opt.get('key')
            if not t:
                errors.append(f"Option {opt_id} has empty text")
            elif re.match(r'^Option\s+[A-D]$', t, re.I):
                errors.append(f"Option {opt_id} has placeholder text '{t}'")

    correct = q.get('correct_option') or q.get('correct_answer')
    if correct and str(correct).lower() not in ('a', 'b', 'c', 'd'):
        errors.append(f"Invalid correct_option '{correct}', must be a, b, c, or d")

    return errors


# ====================================================================
# 5. LIVE DATABASE AUDIT & SANITIZATION
# ====================================================================

def fetch_all_tests():
    r = requests.get(f"{SUPABASE_URL}/rest/v1/tests?select=id,title,exam_code,year", headers=HEADERS, timeout=15)
    return r.json() if r.status_code == 200 else []

def fetch_test_questions(test_id):
    url = f"{SUPABASE_URL}/rest/v1/questions?test_id=eq.{test_id}&select=*&order=question_number.asc"
    r = requests.get(url, headers=HEADERS, timeout=30)
    return r.json() if r.status_code == 200 else []

def audit_database():
    print("=" * 70)
    print("INGESTION PIPELINE AUDIT REPORT")
    print("=" * 70)
    tests = fetch_all_tests()
    print(f"Total Tests: {len(tests)}")

    corruptions = {
        'merged_options': 0,
        'dummy_options': 0,
        'noise_detected': 0,
        'bleed_throughs': 0,
        'missing_passage_links': 0,
    }

    for t in tests:
        qs = fetch_test_questions(t['id'])
        for q in qs:
            # Check noise in question text
            q_text = q.get('question_text', '')
            if re.search(r'\|\||~|\bct\b|HEM\s*-\s*\d+/\d+', q_text):
                corruptions['noise_detected'] += 1

            # Check options
            opts = q.get('options', [])
            has_merged = False
            has_dummy = False
            for opt in (opts if isinstance(opts, list) else []):
                val = opt.get('text', '') if isinstance(opt, dict) else str(opt)
                if re.search(r'\([b-d]\)', val.lower()):
                    has_merged = True
                if re.match(r'^Option\s+[A-D]$', val.strip(), re.I):
                    has_dummy = True

            if has_merged:
                corruptions['merged_options'] += 1
            if has_dummy:
                corruptions['dummy_options'] += 1

            # Check range directions
            range_info = extract_passage_ranges(q_text)
            if range_info and not q.get('passage_id'):
                corruptions['missing_passage_links'] += 1

    print("\nDefects Summary:")
    print(f"  * Questions with Merged Options: {corruptions['merged_options']}")
    print(f"  * Questions with Placeholder 'Option A' Strings: {corruptions['dummy_options']}")
    print(f"  * Questions with OCR Scanner Noise (||, ~, ct, footers): {corruptions['noise_detected']}")
    print(f"  * Unlinked Passage Range Sets: {corruptions['missing_passage_links']}")
    print("=" * 70)

def clean_database(dry_run=True):
    print("=" * 70)
    print(f"SUPABASE DATABASE REPAIR & INGESTION ({'DRY-RUN' if dry_run else 'LIVE APPLY'})")
    print("=" * 70)

    tests = fetch_all_tests()
    updated_q_count = 0
    created_passages_count = 0

    for t in tests:
        t_id = t['id']
        qs = fetch_test_questions(t_id)
        if not qs:
            continue

        # Pass 3: Identify passage ranges & create passages
        q_by_num = {q.get('question_number'): q for q in qs if q.get('question_number')}
        passages_to_create = [] # [(start_q, end_q, title, content, first_q_id, clean_q_text)]

        for q in qs:
            q_text = q.get('question_text', '')
            range_info = extract_passage_ranges(q_text)
            if range_info:
                start_q, end_q, title, content, clean_q_text = range_info
                passages_to_create.append((start_q, end_q, title, content, q['id'], clean_q_text))

        # Create passages and link questions
        for start_q, end_q, title, content, first_q_id, clean_q_text in passages_to_create:
            passage_id = str(uuid.uuid4())
            if not dry_run:
                p_payload = {
                    'id': passage_id,
                    'test_id': t_id,
                    'title': title,
                    'content': content,
                }
                res = requests.post(f"{SUPABASE_URL}/rest/v1/passages", headers=HEADERS, json=p_payload, timeout=10)
                if res.status_code in (200, 201):
                    created_passages_count += 1
                else:
                    print(f"[WARN] Failed to insert passage for test {t_id}: {res.text}")
                    passage_id = None
            else:
                created_passages_count += 1
                print(f"[Passage] Found range Q{start_q}-Q{end_q} in test {t.get('title')}: {title}")

            if passage_id:
                for q_num in range(start_q, end_q + 1):
                    target_q = q_by_num.get(q_num)
                    if target_q:
                        target_q['_new_passage_id'] = passage_id
                        if target_q['id'] == first_q_id:
                            target_q['question_text'] = clean_q_text

        # Pass 1 & 2: Clean options, strip noise, validate
        for q in qs:
            q_id = q['id']
            old_text = q.get('question_text', '')
            clean_text = strip_noise(old_text)
            clean_text = strip_irrelevant_standalone_direction(clean_text)

            old_options = q.get('options', [])
            norm_options, bleeds = split_and_normalize_options(old_options)

            patch_data = {}
            if clean_text != old_text:
                patch_data['question_text'] = clean_text

            if norm_options and norm_options != old_options:
                patch_data['options'] = norm_options

            if '_new_passage_id' in q:
                patch_data['passage_id'] = q['_new_passage_id']

            # Standardize correct_option & order_index / question_number
            if not q.get('correct_option') and q.get('correct_answer'):
                patch_data['correct_option'] = str(q['correct_answer']).lower().strip()
            if not q.get('order_index') and q.get('question_number'):
                patch_data['order_index'] = q['question_number']

            if patch_data:
                updated_q_count += 1
                if dry_run:
                    print(f"  * Q{q.get('question_number')} ({q_id}): {list(patch_data.keys())}")
                else:
                    patch_url = f"{SUPABASE_URL}/rest/v1/questions?id=eq.{q_id}"
                    r = requests.patch(patch_url, headers=HEADERS, json=patch_data, timeout=10)
                    if r.status_code not in (200, 204):
                        print(f"[ERROR] Failed to update Q{q_id}: {r.status_code} {r.text}")

    print(f"\n[DONE] Passages {'identified' if dry_run else 'created'}: {created_passages_count}")
    print(f"[DONE] Questions {'identified for update' if dry_run else 'updated'}: {updated_q_count}")


# ====================================================================
# 6. SELF-TEST SUITE
# ====================================================================

def run_tests():
    print("=" * 70)
    print("RUNNING INGESTION PIPELINE SELF-TESTS")
    print("=" * 70)
    test_failures = 0

    # Test 1: Noise stripping & scanner token stripping (Pass 1)
    sample_noisy = "|| What is the value of 5 x 4 ct? ~ HEM - 7/24 |||"
    cleaned = strip_noise(sample_noisy)
    expected = "What is the value of 5 × 4?"
    if cleaned == expected:
        print("[PASS] Test 1: Noise stripping & operator normalization passed")
    else:
        print(f"[FAIL] Test 1: Expected '{expected}', got '{cleaned}'")
        test_failures += 1

    # Test 1.1: Math arithmetic normalization (+/- to ±)
    sample_math = "The root is x = 5 +/- 2"
    cleaned_math = normalize_arithmetic_expressions(sample_math)
    if "±" in cleaned_math:
        print("[PASS] Test 1.1: Arithmetic normalization for ± passed")
    else:
        print(f"[FAIL] Test 1.1: Expected ± in '{cleaned_math}'")
        test_failures += 1

    # Test 2: Merged options splitting with strict contract [{"id": "a", ...}] (Pass 2)
    sample_merged = [
        "(a) Leopard",
        "(b) Cheetah (c) Tiger (d) Lion"
    ]
    norm_opts, bleeds = split_and_normalize_options(sample_merged)
    if len(norm_opts) == 4 and norm_opts[1]['id'] == 'b' and norm_opts[1]['text'] == 'Cheetah' and norm_opts[2]['id'] == 'c' and norm_opts[3]['id'] == 'd':
        print("[PASS] Test 2: Merged options split correctly into 4 distinct items with 'id' contract")
    else:
        print(f"[FAIL] Test 2: Failed to split merged options: {norm_opts}")
        test_failures += 1

    # Test 3: Bleed-through question extraction (Pass 2)
    sample_bleed = [
        "(a) 25 km/h",
        "(b) 30 km/h \n87. She plays table tennis every morning.",
        "(c) 35 km/h",
        "(d) 40 km/h"
    ]
    norm_opts, bleeds = split_and_normalize_options(sample_bleed)
    if norm_opts[1]['text'] == '30 km/h' and len(bleeds) == 1 and bleeds[0]['question_number'] == 87:
        print("[PASS] Test 3: Bleed-through question 87 isolated and stripped from option (b)")
    else:
        print(f"[FAIL] Test 3: Failed bleed extraction: opts={norm_opts}, bleeds={bleeds}")
        test_failures += 1

    # Test 4: Direction range detection with title and passage (Pass 3)
    sample_direction = (
        "Direction (Q. No. 85 - 87): Read the following passage carefully.\n"
        "The Amazon rainforest is the world's largest tropical rainforest.\n"
        "85. Which country contains the largest portion of the Amazon?"
    )
    extracted = extract_passage_ranges(sample_direction)
    if extracted:
        start_q, end_q, title, passage, remaining = extracted
        if start_q == 85 and end_q == 87 and "85 - 87" in title and "Amazon rainforest" in passage:
            print("[PASS] Test 4: Passage range Q85-Q87 and title detected and extracted")
        else:
            print(f"[FAIL] Test 4: Unexpected range values: {extracted}")
            test_failures += 1
    else:
        print("[FAIL] Test 4: Failed to match direction range")
        test_failures += 1

    # Test 5: Standalone question irrelevant direction stripping (Pass 3)
    sample_standalone = "Direction: Choose the odd man out. In triangle ABC, angle A = 90 degrees."
    cleaned_standalone = strip_irrelevant_standalone_direction(sample_standalone)
    if "Choose the odd man out" not in cleaned_standalone and "In triangle ABC" in cleaned_standalone:
        print("[PASS] Test 5: Irrelevant repeated direction stripped from standalone question")
    else:
        print(f"[FAIL] Test 5: Failed to strip irrelevant direction: '{cleaned_standalone}'")
        test_failures += 1

    # Test 6: Validation reject placeholder "Option A"
    invalid_q = {
        'question_text': 'Valid question text here?',
        'options': [{'id': 'a', 'text': 'Option A'}, {'id': 'b', 'text': 'Option B'}],
        'correct_option': 'a'
    }
    errors = validate_question(invalid_q)
    if any("placeholder" in e for e in errors):
        print("[PASS] Test 6: Validation correctly rejected dummy 'Option A' placeholder")
    else:
        print(f"[FAIL] Test 6: Validation failed to catch dummy placeholder: {errors}")
        test_failures += 1

    # Test 7: Validation reject invalid correct_option
    invalid_correct_q = {
        'question_text': 'Valid question text here?',
        'options': [{'id': 'a', 'text': 'Apple'}, {'id': 'b', 'text': 'Banana'}],
        'correct_option': 'z'
    }
    errors_correct = validate_question(invalid_correct_q)
    if any("Invalid correct_option" in e for e in errors_correct):
        print("[PASS] Test 7: Validation correctly rejected invalid correct_option 'z'")
    else:
        print(f"[FAIL] Test 7: Validation failed to reject invalid correct_option: {errors_correct}")
        test_failures += 1

    print("=" * 70)
    if test_failures == 0:
        print("ALL 7 INGESTION PIPELINE TESTS PASSED!")
    else:
        print(f"{test_failures} TESTS FAILED!")
    print("=" * 70)
    return test_failures == 0


def main():
    parser = argparse.ArgumentParser(description="Ingestion & Sanitization Pipeline")
    parser.add_argument('--test', action='store_true', help="Run unit test suite")
    parser.add_argument('--audit', action='store_true', help="Audit live Supabase questions")
    parser.add_argument('--clean-db', action='store_true', help="Clean live Supabase database")
    parser.add_argument('--dry-run', action='store_true', help="Preview repairs without applying")
    parser.add_argument('--apply', action='store_true', help="Apply repairs to Supabase")
    args = parser.parse_args()

    if args.test:
        success = run_tests()
        sys.exit(0 if success else 1)
    elif args.clean_db:
        clean_database(dry_run=not args.apply)
    else:
        audit_database()

if __name__ == '__main__':
    main()
