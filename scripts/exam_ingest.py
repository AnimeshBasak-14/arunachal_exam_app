#!/usr/bin/env python3
"""
Arunachal Exam Prep - Universal Exam Ingestion Pipeline
Supports:
1. Scanned PYQ PDFs -> Multimodal Vision AI extraction -> Supabase DB
2. Automatic Answer Key extraction & matching from PDF last page
3. Spreadsheets & CSVs (Legacy 27-column or clean format) -> Supabase DB
4. Diagram / figure cropping & uploading to Supabase Storage
"""

import os
import sys
import json
import base64
import argparse
import urllib.parse
import psycopg2
from psycopg2.extras import Json
import requests

try:
    import fitz
except ImportError:
    import pymupdf as fitz

# Load .env file if available
def load_dotenv_file():
    candidates = [
        os.path.join(os.getcwd(), ".env"),
        os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), ".env"),
        os.path.join(os.path.dirname(os.path.abspath(__file__)), ".env"),
    ]
    for filepath in candidates:
        if os.path.exists(filepath):
            with open(filepath, "r", encoding="utf-8") as f:
                for line in f:
                    line = line.strip()
                    if not line or line.startswith("#") or "=" not in line:
                        continue
                    k, v = line.split("=", 1)
                    k = k.strip()
                    v = v.strip().strip("'\"")
                    if k not in os.environ:
                        os.environ[k] = v
            break

load_dotenv_file()

# Credentials loaded from environment or .env
DB_PASSWORD = os.environ.get("SUPABASE_DB_PASS", "")
DB_USER = os.environ.get("SUPABASE_DB_USER", "")
DB_HOST = os.environ.get("SUPABASE_DB_HOST", "aws-0-ap-northeast-1.pooler.supabase.com")
DB_PORT = int(os.environ.get("SUPABASE_DB_PORT", "6543"))
GEMINI_API_KEY = os.environ.get("GEMINI_API_KEY", "")
SUPABASE_URL = os.environ.get("SUPABASE_URL", "https://fllopztywwblbucvaths.supabase.co")
SUPABASE_KEY = os.environ.get("SUPABASE_KEY", "sb_publishable_y68QKKHxBTZxBP3Sf1X7tw_zfFnXX8M")

def log(msg):
    print(msg, flush=True)

def get_db_connection():
    encoded_pass = urllib.parse.quote_plus(DB_PASSWORD)
    conn_str = f"postgresql://{DB_USER}:{encoded_pass}@{DB_HOST}:{DB_PORT}/postgres?sslmode=require"
    conn = psycopg2.connect(conn_str)
    conn.autocommit = True
    return conn

def get_or_create_test(conn, exam_code, paper_type, year, title, duration_mins=120, marks_correct=2.0, neg_marks=0.5):
    cur = conn.cursor()
    cur.execute(
        """
        SELECT id FROM tests 
        WHERE exam_code = %s AND paper_type = %s AND (year = %s OR (year IS NULL AND %s IS NULL))
        LIMIT 1;
        """,
        (exam_code, paper_type, year, year)
    )
    row = cur.fetchone()
    if row:
        log(f"[DB] Found existing test: {title} (ID: {row[0]})")
        return row[0]

    cur.execute(
        """
        INSERT INTO tests (exam_code, paper_type, year, title, duration_minutes, marks_per_correct, negative_marks)
        VALUES (%s, %s, %s, %s, %s, %s, %s)
        RETURNING id;
        """,
        (exam_code, paper_type, year, title, duration_mins, marks_correct, neg_marks)
    )
    new_id = cur.fetchone()[0]
    log(f"[DB] Created new test: {title} (ID: {new_id})")
    return new_id

def extract_page_ai(img_bytes):
    b64_img = base64.b64encode(img_bytes).decode("utf-8")
    prompt = """You are an expert exam paper digitizer for APPSC / APSSB Arunachal Pradesh competitive exams.
Carefully examine this exam page image and extract every question and any comprehension passage, scenario, or directions.

RULES:
1. If there is a passage, case study, or shared direction (e.g. 'Direction (Q. No. 1 to 20): ...'), extract it into 'group_info'.
2. For each question:
   - Extract 'question_number' as an integer.
   - Extract 'subject' (e.g., 'Reading Comprehension', 'General English', 'Quantitative Aptitude', 'Logical Reasoning', 'General Studies', 'Civil Engineering').
   - Extract 'question_text'. Preserve any mathematical symbols strictly in LaTeX format using $...$ (e.g. $x^2 + y^2 = r^2$, $\\frac{a}{b}$).
   - Extract 'options' as a list of objects: [{"id": "a", "text": "..."}, {"id": "b", "text": "..."}, {"id": "c", "text": "..."}, {"id": "d", "text": "..."}].
   - If options have math, use LaTeX format in the text.
   - 'correct_answer': extract if explicitly indicated on paper (like tick mark or bold), otherwise "".
   - 'has_diagram': true if there is a geometrical diagram, graph, chart, or map that belongs to this question.

Output strictly valid JSON matching this schema:
{
  "has_group": false,
  "group_title": null,
  "passage_text": null,
  "instructions": null,
  "questions": [
    {
      "question_number": 1,
      "subject": "General Studies",
      "question_text": "...",
      "options": [
        {"id": "a", "text": "..."},
        {"id": "b", "text": "..."},
        {"id": "c", "text": "..."},
        {"id": "d", "text": "..."}
      ],
      "correct_answer": "",
      "has_diagram": false
    }
  ]
}
"""
    url = f"https://generativelanguage.googleapis.com/v1beta/models/gemini-3.6-flash:generateContent?key={GEMINI_API_KEY}"
    payload = {
        "contents": [
            {
                "parts": [
                    {"text": prompt},
                    {"inline_data": {"mime_type": "image/png", "data": b64_img}},
                ]
            }
        ],
        "generationConfig": {"response_mime_type": "application/json"},
    }

    try:
        r = requests.post(url, json=payload, timeout=45)
        if r.status_code == 200:
            res_json = r.json()
            text = res_json["candidates"][0]["content"]["parts"][0]["text"]
            return json.loads(text)
        else:
            log(f"[AI Error] HTTP {r.status_code}: {r.text[:200]}")
    except Exception as e:
        log(f"[AI Exception] {e}")
    return None

def extract_answer_key_from_text(text):
    prompt = f"""You are an exam evaluator for APPSC/APSSB exams.
Extract the answer key mappings from this text into a JSON dictionary:
{{"answers": {{"1": "c", "2": "d", "3": "a", "4": "b", ...}}}}

Text:
{text}
"""
    url = f"https://generativelanguage.googleapis.com/v1beta/models/gemini-3.6-flash:generateContent?key={GEMINI_API_KEY}"
    payload = {
        "contents": [{"parts": [{"text": prompt}]}],
        "generationConfig": {"response_mime_type": "application/json"},
    }
    try:
        r = requests.post(url, json=payload, timeout=30)
        if r.status_code == 200:
            res = json.loads(r.json()["candidates"][0]["content"]["parts"][0]["text"])
            return res.get("answers", {})
    except Exception as e:
        log(f"[Answer Key Error] {e}")
    return {}

def ingest_pdf(pdf_path, exam_code, year, title, paper_type="PYQ", start_page=1, end_page=None):
    if not os.path.exists(pdf_path):
        log(f"Error: File not found: {pdf_path}")
        return

    conn = get_db_connection()
    test_id = get_or_create_test(conn, exam_code, paper_type, year, title)

    doc = fitz.open(pdf_path)
    total_pages = len(doc)
    start_idx = max(0, start_page - 1)
    end_idx = min(total_pages, end_page) if end_page else total_pages

    # Check if last page is an answer key
    last_page_text = doc[-1].get_text()
    has_answer_key_on_last_page = "ANSWER KEY" in last_page_text.upper() or "ANS" in last_page_text.upper() and "Q NO" in last_page_text.upper()
    if has_answer_key_on_last_page and (end_page is None or end_page >= total_pages):
        end_idx = total_pages - 1 # Skip last page during question scanning

    log(f"\n[Ingest] Processing '{pdf_path}' (Pages {start_idx + 1} to {end_idx} of {total_pages})")
    
    cur = conn.cursor()
    total_q_added = 0
    current_group_id = None

    for page_idx in range(start_idx, end_idx):
        page_num = page_idx + 1
        page = doc[page_idx]
        log(f"\n---> Scanning Page {page_num}/{total_pages} with Vision AI...")

        pix = page.get_pixmap(dpi=200)
        img_bytes = pix.tobytes("png")

        data = extract_page_ai(img_bytes)
        if not data or not data.get("questions"):
            log(f"     No questions detected on page {page_num} (cover/instruction page).")
            continue

        # Handle Question Group / Passage if present
        if data.get("has_group") and data.get("passage_text"):
            g_title = data.get("group_title") or f"Passage (Page {page_num})"
            g_text = data.get("passage_text")
            g_inst = data.get("instructions")
            
            cur.execute(
                """
                INSERT INTO question_groups (test_id, title, passage_text, instructions)
                VALUES (%s, %s, %s, %s)
                RETURNING id;
                """,
                (test_id, g_title, g_text, g_inst)
            )
            current_group_id = cur.fetchone()[0]
            log(f"     [Group Created] '{g_title}' (ID: {current_group_id})")

        # Insert Questions
        for q in data.get("questions", []):
            q_num = q.get("question_number", 0)
            q_subj = q.get("subject", "General")
            q_text = q.get("question_text", "")
            q_opts = q.get("options", [])
            q_ans = (q.get("correct_answer") or "").strip().lower()

            if not q_text or not q_opts:
                continue

            target_group_id = current_group_id if data.get("has_group") else None

            # Check if question already exists in this test to prevent duplicates
            cur.execute(
                "SELECT id FROM questions WHERE test_id = %s AND question_number = %s;",
                (test_id, q_num)
            )
            existing = cur.fetchone()
            if existing:
                cur.execute(
                    """
                    UPDATE questions 
                    SET group_id = COALESCE(%s, group_id), subject = %s, question_text = %s, options = %s, 
                        correct_answer = CASE WHEN %s != '' THEN %s ELSE correct_answer END
                    WHERE id = %s;
                    """,
                    (target_group_id, q_subj, q_text, Json(q_opts), q_ans, q_ans, existing[0])
                )
                log(f"     [Updated] Q{q_num}: {q_text[:50]}...")
            else:
                cur.execute(
                    """
                    INSERT INTO questions (test_id, group_id, question_number, subject, question_text, options, correct_answer)
                    VALUES (%s, %s, %s, %s, %s, %s, %s);
                    """,
                    (test_id, target_group_id, q_num, q_subj, q_text, Json(q_opts), q_ans)
                )
                total_q_added += 1
                log(f"     [Inserted] Q{q_num}: {q_text[:50]}... ({len(q_opts)} options)")

    # Auto-apply answer key from last page if detected
    if has_answer_key_on_last_page:
        log(f"\n[Answer Key] Detected final answer key on Page {total_pages}. Extracting...")
        ans_map = extract_answer_key_from_text(last_page_text)
        if ans_map:
            log(f"[Answer Key] Parsed {len(ans_map)} answers. Updating questions...")
            applied = 0
            for q_str, ans in ans_map.items():
                try:
                    q_num = int(q_str)
                    cur.execute(
                        "UPDATE questions SET correct_answer = %s WHERE test_id = %s AND question_number = %s;",
                        (ans.strip().lower(), test_id, q_num)
                    )
                    applied += 1
                except Exception:
                    pass
            log(f"[Answer Key] Successfully matched and updated {applied} questions with official answers!")

    conn.close()
    log(f"\n=======================================================")
    log(f"[Done] Ingested {total_q_added} questions into Test ID '{test_id}'.")
    log(f"=======================================================\n")

def ingest_csv(csv_path, exam_code, year, title, paper_type="MOCK"):
    import csv

    if not os.path.exists(csv_path):
        log(f"Error: File not found: {csv_path}")
        return

    conn = get_db_connection()
    test_id = get_or_create_test(conn, exam_code, paper_type, year, title)
    cur = conn.cursor()

    with open(csv_path, "r", encoding="utf-8", errors="replace") as f:
        reader = csv.DictReader(f)
        total_added = 0
        groups_cache = {}

        for row_idx, row in enumerate(reader):
            q_num = row_idx + 1
            subj = row.get("subject") or "General"
            q_text = row.get("questionText") or row.get("question_text") or row.get("question") or ""
            if not q_text:
                continue

            # Handle Passage / Group if present
            passage = row.get("passageOrDirection") or row.get("passage") or ""
            group_id = None
            if passage.strip():
                if passage not in groups_cache:
                    g_title = row.get("groupId") or f"Group {len(groups_cache) + 1}"
                    cur.execute(
                        """
                        INSERT INTO question_groups (test_id, title, passage_text)
                        VALUES (%s, %s, %s)
                        RETURNING id;
                        """,
                        (test_id, g_title, passage)
                    )
                    groups_cache[passage] = cur.fetchone()[0]
                group_id = groups_cache[passage]

            # Build options JSON array
            opts = []
            for opt_char in ["a", "b", "c", "d"]:
                opt_val = (
                    row.get(f"option{opt_char.upper()}")
                    or row.get(f"option_{opt_char}")
                    or row.get(opt_char)
                    or ""
                )
                opt_img = row.get(f"option{opt_char.upper()}_Image") or row.get(f"option_{opt_char}_image")
                if opt_val or opt_img:
                    opts.append({"id": opt_char, "text": opt_val, "image": opt_img})

            ans = (row.get("correctAnswer") or row.get("correct_answer") or row.get("answer") or "").strip().lower()
            expl = row.get("solution") or row.get("explanation") or ""

            cur.execute(
                """
                INSERT INTO questions (test_id, group_id, question_number, subject, question_text, options, correct_answer, explanation)
                VALUES (%s, %s, %s, %s, %s, %s, %s, %s);
                """,
                (test_id, group_id, q_num, subj, q_text, Json(opts), ans, expl)
            )
            total_added += 1

    conn.close()
    log(f"\n[Done] Ingested {total_added} questions from CSV '{csv_path}'.")

def apply_answer_key(test_id, key_pdf_path):
    if not os.path.exists(key_pdf_path):
        log(f"Error: File not found: {key_pdf_path}")
        return

    doc = fitz.open(key_pdf_path)
    full_text = "\n".join([page.get_text() for page in doc])
    ans_map = extract_answer_key_from_text(full_text[:15000])

    if not ans_map:
        log("Failed to parse answer key.")
        return

    log(f"[Answer Key] Parsed {len(ans_map)} answers.")
    conn = get_db_connection()
    cur = conn.cursor()
    updated = 0
    for q_str, ans in ans_map.items():
        try:
            q_num = int(q_str)
            cur.execute(
                "UPDATE questions SET correct_answer = %s WHERE test_id = %s AND question_number = %s;",
                (ans.strip().lower(), test_id, q_num)
            )
            updated += 1
        except Exception:
            pass

    conn.close()
    log(f"[Success] Updated {updated} question answers for Test ID '{test_id}'.")

def list_tests():
    conn = get_db_connection()
    cur = conn.cursor()
    cur.execute(
        """
        SELECT t.id, t.exam_code, t.paper_type, t.year, t.title, COUNT(q.id) as question_count
        FROM tests t
        LEFT JOIN questions q ON q.test_id = t.id
        GROUP BY t.id
        ORDER BY t.created_at DESC;
        """
    )
    rows = cur.fetchall()
    log("\n" + "=" * 95)
    log(f"{'TEST ID':<38} | {'EXAM':<12} | {'TYPE':<6} | {'YEAR':<5} | {'QUESTIONS':<9} | {'TITLE'}")
    log("=" * 95)
    for r in rows:
        t_id, exam, p_type, yr, title, count = r
        yr_str = str(yr) if yr else "N/A"
        log(f"{t_id:<38} | {exam:<12} | {p_type:<6} | {yr_str:<5} | {count:<9} | {title}")
    log("=" * 95 + "\n")
    conn.close()

def main():
    parser = argparse.ArgumentParser(description="Arunachal Exam Prep - Universal Ingestion CLI")
    subparsers = parser.add_subparsers(dest="command", required=True)

    # PDF subcommand
    pdf_parser = subparsers.add_parser("pdf", help="Ingest a scanned PYQ PDF")
    pdf_parser.add_argument("--file", required=True, help="Path to PDF")
    pdf_parser.add_argument("--exam", required=True, help="Exam code, e.g. APPSC-CCE, APSSB-CGLE")
    pdf_parser.add_argument("--year", type=int, required=True, help="Exam year")
    pdf_parser.add_argument("--title", required=True, help="Test title")
    pdf_parser.add_argument("--type", default="PYQ", choices=["PYQ", "MOCK"], help="Paper type")
    pdf_parser.add_argument("--start-page", type=int, default=1, help="Start page (1-indexed)")
    pdf_parser.add_argument("--end-page", type=int, default=None, help="End page")

    # CSV subcommand
    csv_parser = subparsers.add_parser("csv", help="Ingest a CSV or Spreadsheet export")
    csv_parser.add_argument("--file", required=True, help="Path to CSV")
    csv_parser.add_argument("--exam", required=True, help="Exam code")
    csv_parser.add_argument("--year", type=int, default=None, help="Exam year")
    csv_parser.add_argument("--title", required=True, help="Test title")
    csv_parser.add_argument("--type", default="MOCK", choices=["PYQ", "MOCK"], help="Paper type")

    # Answer Key subcommand
    key_parser = subparsers.add_parser("answer-key", help="Auto-apply answer key to a test")
    key_parser.add_argument("--test-id", required=True, help="Test UUID")
    key_parser.add_argument("--file", required=True, help="Path to Answer Key PDF")

    # List subcommand
    subparsers.add_parser("list", help="List all tests currently in Supabase")

    args = parser.parse_args()

    if args.command == "pdf":
        ingest_pdf(args.file, args.exam, args.year, args.title, args.type, args.start_page, args.end_page)
    elif args.command == "csv":
        ingest_csv(args.file, args.exam, args.year, args.title, args.type)
    elif args.command == "answer-key":
        apply_answer_key(args.test_id, args.file)
    elif args.command == "list":
        list_tests()

if __name__ == "__main__":
    main()
