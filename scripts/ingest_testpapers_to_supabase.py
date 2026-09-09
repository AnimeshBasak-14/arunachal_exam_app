"""
ARUNACHAL EXAM PREP - TEST PAPER INGESTION ENGINE
=================================================
Parses MOCK, PYQ, and GRAMMAR PDFs, extracts questions, passages, and options,
creates tests in Supabase 'tests' table, and batch-uploads questions to 'questions' table.
"""

import os
import sys
import re
import json
import uuid
import subprocess
import requests
import fitz  # PyMuPDF

if hasattr(sys.stdout, 'reconfigure'):
    try:
        sys.stdout.reconfigure(encoding='utf-8', line_buffering=True)
        sys.stderr.reconfigure(encoding='utf-8', line_buffering=True)
    except Exception:
        pass

# --- Supabase Configuration ---
SUPABASE_URL = os.environ.get('SUPABASE_URL', 'https://fllopztywwblbucvaths.supabase.co')
SUPABASE_KEY = os.environ.get('SUPABASE_KEY', 'sb_publishable_y68QKKHxBTZxBP3Sf1X7tw_zfFnXX8M')

HEADERS = {
    'apikey': SUPABASE_KEY,
    'Authorization': f'Bearer {SUPABASE_KEY}',
    'Content-Type': 'application/json',
    'Prefer': 'return=representation',
}

TESSERACT_EXE = r"C:\Program Files\Tesseract-OCR\tesseract.exe"

# Pre-compiled Regexes
OPTION_PATTERN = re.compile(r'\(([a-dA-D])\)\s*(.+?)(?=\([a-dA-D]\)|\Z)', re.DOTALL)
ANSWER_PATTERN = re.compile(r'(?:Answer|Ans\.?|ANS\.?|Correct Option)[:\s]+\(?([a-dA-D])\)?', re.IGNORECASE)
PASSAGE_PATTERN = re.compile(r'Passage\s*(?:[I|V|X\d]+)?[:\s\-]+(.*?)(?=\n\s*Q\d+[\.:\)]|\Z)', re.DOTALL | re.IGNORECASE)


def extract_subject_from_context(text, default_subject='General Studies'):
    t = text.lower()
    if any(k in t for k in ['grammar', 'tenses', 'voice', 'narration', 'preposition', 'conjunction', 'synonym', 'antonym', 'idiom', 'clause']):
        return 'General English'
    if any(k in t for k in ['comprehension', 'reading passage', 'penicillin', 'passage:']):
        return 'Reading Comprehension'
    if any(k in t for k in ['arithmetic', 'profit', 'loss', 'percentage', 'interest', 'ratio',
                             'algebra', 'trigonometry', 'geometry', 'mensuration', 'bodmas', 'simplification', 'hcf', 'lcm', 'square root']):
        return 'Elementary Maths'
    if any(k in t for k in ['reasoning', 'analogy', 'series', 'syllogism', 'coding', 'decoding',
                             'direction', 'blood relation', 'puzzle', 'logical', 'odd one out']):
        return 'Logical Reasoning'
    if any(k in t for k in ['civil engg', 'civil engineering', 'rcc', 'concrete', 'soil', 'hydraulics', 'surveying']):
        return 'Civil Engineering'
    if any(k in t for k in ['current affair', 'gdp', 'budget', 'sports', 'scheme', 'award']):
        return 'General Studies'
    if any(k in t for k in ['arunachal', 'history', 'polity', 'constitution', 'geography', 'vitamin', 'biology', 'physics', 'chemistry']):
        return 'General Studies'
    return default_subject


def clean_text(text):
    if not text:
        return ""
    # Normalize unicode spaces & artifacts
    text = text.replace('\u200b', '').replace('\xa0', ' ')
    # Remove scanner footer codes
    text = re.sub(r'\bHEM\s*-\s*\d+/\d+\b', '', text, flags=re.I)
    text = re.sub(r'\|\s*\|+', ' ', text)
    text = re.sub(r'(?<!\w)[\|~](?!\w)', ' ', text)
    text = re.sub(r'\bP\.?\s*T\.?\s*O\.?\b', '', text, flags=re.I)
    text = re.sub(r'Contact:\s*\d{10}.*?\n', '', text, flags=re.I)
    text = re.sub(r'Itanagar\s*\|\s*Naharlagun.*?\n', '', text, flags=re.I)
    text = re.sub(r'Name of Candidate.*?Mobile Number.*?\n', '', text, flags=re.I)
    return text.strip()


def ocr_page(doc, page_num):
    """Fallback OCR for scanned PDF pages using local Tesseract."""
    if not os.path.exists(TESSERACT_EXE):
        return ""
    try:
        page = doc[page_num]
        pix = page.get_pixmap(dpi=200)
        temp_img = os.path.join(os.environ.get('TEMP', '.'), f'temp_ocr_{uuid.uuid4().hex[:8]}.png')
        pix.save(temp_img)
        cmd = [TESSERACT_EXE, temp_img, 'stdout', '--oem', '1', '-l', 'eng']
        res = subprocess.run(cmd, capture_output=True, encoding='utf-8', errors='ignore', timeout=60)
        if os.path.exists(temp_img):
            os.remove(temp_img)
        return res.stdout or ""
    except Exception as e:
        print(f"    OCR Error on page {page_num}: {e}")
        return ""


def extract_full_text(pdf_path):
    doc = fitz.open(pdf_path)
    pages_text = []
    
    for i in range(len(doc)):
        txt = doc[i].get_text() or ""
        unprintable = sum(1 for c in txt if ord(c) < 32 and c not in '\n\r\t')
        if len(txt.strip()) < 20 or (len(txt) > 0 and unprintable / len(txt) > 0.2):
            print(f"    [OCR] Processing scanned page {i+1}/{len(doc)}...", end='\r')
            txt = ocr_page(doc, i) or ""
        pages_text.append(txt)
    
    return "\n".join(pages_text)


def parse_questions(full_text, default_subject='General Studies'):
    full_text = clean_text(full_text)
    
    # Check for linked reading comprehension passage
    active_passage = None
    pass_m = PASSAGE_PATTERN.search(full_text)
    if pass_m:
        active_passage = clean_text(pass_m.group(1))
        if len(active_passage) < 30:
            active_passage = None

    # Split into question blocks by 'Q1.', 'Q 1.', '1.', etc.
    blocks = re.split(r'\n(?=(?:Q\.?\s*)?\d{1,3}[\.:\)]\s)', full_text)
    questions = []

    for block in blocks:
        block = block.strip()
        if not block:
            continue

        q_match = re.match(
            r'^(?:Q\.?\s*)?(\d+)[\.:\)]\s*(.+?)(?=(?:\([a-dA-D]\)|\([A-D]\))|$)',
            block, re.DOTALL | re.IGNORECASE
        )
        if not q_match:
            continue

        q_num = int(q_match.group(1))
        q_text = clean_text(q_match.group(2)).replace('\n', ' ')
        if len(q_text) < 2:
            continue

        options_raw = OPTION_PATTERN.findall(block)
        if len(options_raw) < 2:
            continue

        options = [
            {'id': c.lower(), 'text': clean_text(t).replace('\n', ' ')}
            for c, t in options_raw
        ]

        ans_match = ANSWER_PATTERN.search(block)
        correct_answer = ans_match.group(1).lower() if ans_match else ''
        subject = extract_subject_from_context(block, default_subject)

        # Check if question has a local passage
        q_passage = None
        local_pass = re.search(r'Passage:\s*(.*?)(?=\n\s*(?:Q\d+|\([a-d]\)))', block, re.DOTALL | re.IGNORECASE)
        if local_pass:
            q_passage = clean_text(local_pass.group(1))
        elif active_passage and q_num >= 90:
            q_passage = active_passage

        questions.append({
            'question_number': q_num,
            'question_text': q_text,
            'options': options,
            'correct_answer': correct_answer,
            'subject': subject,
            'difficulty': 'Medium',
            'explanation': '',
            'passage': q_passage,
        })

    return questions


def get_or_create_test(meta):
    """Fetch existing test or insert new test record in Supabase."""
    title = meta['title']
    try:
        # Check by title
        r = requests.get(
            f"{SUPABASE_URL}/rest/v1/tests?title=eq.{requests.utils.quote(title)}&limit=1",
            headers=HEADERS, timeout=10
        )
        if r.status_code == 200:
            data = r.json()
            if data:
                print(f"  [Found existing test] ID: {data[0]['id']} - {title}")
                return data[0]['id']
    except Exception as e:
        print(f"  Error checking test: {e}")

    test_id = str(uuid.uuid4())
    payload = {
        'id': test_id,
        'exam_code': meta['exam_code'],
        'paper_type': meta['paper_type'],
        'year': meta.get('year', 2024),
        'title': title,
        'duration_minutes': meta.get('duration_minutes', 120),
        'marks_per_correct': meta.get('marks_per_correct', 2.0),
        'negative_marks': meta.get('negative_marks', 0.5),
        'is_published': True,
    }

    try:
        r = requests.post(f"{SUPABASE_URL}/rest/v1/tests", headers=HEADERS, json=payload, timeout=10)
        if r.status_code in (200, 201):
            data = r.json()
            ret_id = (data[0]['id'] if isinstance(data, list) else data.get('id')) or test_id
            print(f"  [Created test] ID: {ret_id} - {title}")
            return ret_id
        else:
            print(f"  Failed to create test: {r.status_code} {r.text[:200]}")
    except Exception as e:
        print(f"  Error creating test: {e}")

    return None


def upload_questions_batch(test_id, questions):
    if not questions:
        return 0

    # Fetch existing question numbers for this test to prevent duplicates
    existing_nums = set()
    try:
        r = requests.get(f"{SUPABASE_URL}/rest/v1/questions?test_id=eq.{test_id}&select=question_number", headers=HEADERS, timeout=10)
        if r.status_code == 200:
            existing_nums = {q['question_number'] for q in r.json() if 'question_number' in q}
    except Exception:
        pass

    to_insert = []
    for q in questions:
        if q['question_number'] in existing_nums:
            continue
        to_insert.append({
            'id': str(uuid.uuid4()),
            'test_id': test_id,
            'question_number': q['question_number'],
            'question_text': q['question_text'],
            'options': q['options'],
            'correct_answer': q['correct_answer'],
            'subject': q['subject'],
            'difficulty': q['difficulty'],
            'explanation': q.get('explanation', ''),
        })

    if not to_insert:
        print(f"  All {len(questions)} questions already exist in database.")
        return 0

    uploaded = 0
    # Batch in chunks of 50
    for i in range(0, len(to_insert), 50):
        chunk = to_insert[i:i + 50]
        try:
            r = requests.post(f"{SUPABASE_URL}/rest/v1/questions", headers=HEADERS, json=chunk, timeout=20)
            if r.status_code in (200, 201):
                uploaded += len(chunk)
            else:
                print(f"  Chunk {i//50 + 1} error: {r.status_code} {r.text[:200]}")
        except Exception as e:
            print(f"  Error uploading chunk: {e}")

    return uploaded


def detect_test_meta(filename, folder_name):
    name = os.path.splitext(filename)[0]
    nl = name.lower()
    folder_type = 'MOCK' if 'mock' in folder_name.lower() else 'PYQ'
    
    # Year detection
    ym = re.search(r'(20\d{2})', name)
    year = int(ym.group(1)) if ym else (2026 if folder_type == 'MOCK' else 2024)

    # Exam code detection
    if 'cgle' in nl or 'cgl' in nl or 'graduate level' in nl:
        ec = 'APSSB-CGLE'
    elif 'chsl' in nl or 'higher secondary' in nl:
        ec = 'APSSB-CHSL'
    elif 'csle' in nl or 'secondary level' in nl:
        ec = 'APSSB-CSLE'
    elif 'udc' in nl:
        ec = 'APSSB-UDC'
    elif 'ado' in nl:
        ec = 'APPSC-ADO'
    elif 'civil' in nl:
        ec = 'APPSC-CIVIL'
    elif 'math' in nl:
        ec = 'APSSB-MOCK-MATHS'
    elif 'vocab' in nl or 'grammar' in nl or 'grammer' in nl:
        ec = 'APSSB-ENGLISH'
    elif 'science' in nl:
        ec = 'APSSB-SCIENCE'
    else:
        ec = 'APSSB-MOCK' if folder_type == 'MOCK' else 'APSSB-CGLE'

    # Title formatting
    title = re.sub(r'[\s_-]+', ' ', name).strip()
    tm = re.search(r'[Tt]est\s*(\d+)', name)
    if tm:
        test_num = tm.group(1)
        if 'math' in nl:
            title = f"APSSB Elementary Maths Mock Test {test_num}"
        else:
            title = f"APSSB Mock Test {test_num} (Full Exam)"
    elif 'cgle' in nl or 'graduate level' in nl:
        title = f"APSSB Combined Graduate Level Examination {year}"
    elif 'chsl' in nl:
        title = f"APSSB Combined Higher Secondary Level Examination {year}"
    elif 'csle' in nl:
        title = f"APSSB Combined Secondary Level Examination {year}"
    elif 'udc' in nl:
        title = f"APSSB UDC Official Paper ({year})"
    elif 'ado' in nl:
        title = f"APPSC ADO Recruitment Test {year}"

    duration = 120
    if 'math' in nl and '25' in title:
        duration = 45

    return {
        'exam_code': ec,
        'year': year,
        'paper_type': folder_type,
        'title': title,
        'duration_minutes': duration,
    }


def ingest_folder(folder_path, folder_category):
    if not os.path.exists(folder_path):
        print(f"Folder does not exist: {folder_path}")
        return 0

    files = sorted([f for f in os.listdir(folder_path) if f.lower().endswith('.pdf')])
    print(f"\n=======================================================")
    print(f"Ingesting {len(files)} PDFs from: {folder_category} ({folder_path})")
    print(f"=======================================================")

    total_uploaded = 0

    for idx, fname in enumerate(files):
        fpath = os.path.join(folder_path, fname)
        print(f"\n[{idx+1}/{len(files)}] Processing: {fname}")

        try:
            full_text = extract_full_text(fpath)
            default_sub = 'Elementary Maths' if 'math' in fname.lower() else 'General Studies'
            if 'vocab' in fname.lower() or 'grammar' in fname.lower():
                default_sub = 'General English'
            elif 'science' in fname.lower():
                default_sub = 'General Studies'

            questions = parse_questions(full_text, default_sub)
            print(f"  Extracted: {len(questions)} valid questions")

            if not questions:
                print("  ⚠️ No questions parsed, skipping.")
                continue

            meta = detect_test_meta(fname, folder_category)
            meta['total_questions'] = len(questions)
            test_id = get_or_create_test(meta)

            if not test_id:
                print("  ❌ Could not resolve test ID, skipping questions.")
                continue

            uploaded = upload_questions_batch(test_id, questions)
            print(f"  ✅ Uploaded {uploaded} questions to Supabase!")
            total_uploaded += uploaded

        except Exception as e:
            print(f"  ❌ Error processing {fname}: {e}")

    return total_uploaded


def main():
    base_dir = r"C:\Users\basak\Desktop\Arunachal Exam App\arunachal_exam_app\TESTPAPER"

    folders_to_ingest = [
        (os.path.join(base_dir, "mock"), "MOCK"),
        (os.path.join(base_dir, "pyq"), "PYQ"),
        (os.path.join(base_dir, "grammer"), "GRAMMAR"),
    ]

    grand_total = 0
    for fpath, cat in folders_to_ingest:
        uploaded = ingest_folder(fpath, cat)
        grand_total += uploaded

    print(f"\n🎉 INGESTION COMPLETE! Total new questions uploaded to Supabase: {grand_total}")


if __name__ == '__main__':
    main()
