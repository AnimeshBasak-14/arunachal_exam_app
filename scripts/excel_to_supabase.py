"""
ARUNACHAL EXAM PREP - EXCEL TO SUPABASE INGESTION TOOL
======================================================
Imports curated questions from Excel (.xlsx) or CSV into Supabase PostgreSQL.
Handles:
- Tests creation & linking
- Question groups (Comprehension Passages & Shared Directions)
- Image uploading to Supabase Storage bucket 'exam-assets'
- Mathematics formatting (LaTeX, Unicode, Image-Only)
- Full relational integrity
"""

import os
import sys
import argparse
import mimetypes
import openpyxl
import requests

SUPABASE_URL = os.environ.get('SUPABASE_URL', 'https://fllopztywwblbucvaths.supabase.co')
SUPABASE_KEY = os.environ.get('SUPABASE_KEY', 'sb_publishable_y68QKKHxBTZxBP3Sf1X7tw_zfFnXX8M')

HEADERS = {
    'apikey': SUPABASE_KEY,
    'Authorization': f'Bearer {SUPABASE_KEY}',
    'Content-Type': 'application/json',
    'Prefer': 'return=representation'
}

def upload_image_if_exists(image_name_or_url, images_dir, test_code):
    if not image_name_or_url:
        return None
    val = str(image_name_or_url).strip()
    if val.startswith('http://') or val.startswith('https://'):
        return val

    # Look for local file in images_dir
    local_path = os.path.join(images_dir, val)
    if not os.path.isfile(local_path):
        # Also check without directory prefix
        basename = os.path.basename(val)
        local_path = os.path.join(images_dir, basename)
        if not os.path.isfile(local_path):
            print(f"  [Notice] Local image file not found: {val} (searched in {images_dir})")
            return None

    mime_type, _ = mimetypes.guess_type(local_path)
    mime_type = mime_type or 'image/png'
    remote_path = f"{test_code}/{os.path.basename(local_path)}"

    storage_url = f"{SUPABASE_URL}/storage/v1/object/exam-assets/{remote_path}"
    with open(local_path, 'rb') as f:
        file_bytes = f.read()

    upload_headers = {
        'apikey': SUPABASE_KEY,
        'Authorization': f'Bearer {SUPABASE_KEY}',
        'Content-Type': mime_type,
        'x-upsert': 'true'
    }

    try:
        res = requests.post(storage_url, headers=upload_headers, data=file_bytes)
        if res.status_code in (200, 201):
            public_url = f"{SUPABASE_URL}/storage/v1/object/public/exam-assets/{remote_path}"
            print(f"  [Storage] Uploaded {val} -> {public_url}")
            return public_url
        else:
            print(f"  [Storage Warning] Upload failed ({res.status_code}): {res.text}")
            return None
    except Exception as e:
        print(f"  [Storage Error] {e}")
        return None

def get_or_create_test(test_code, year, paper_type):
    # Check existing test
    check_url = f"{SUPABASE_URL}/rest/v1/tests?exam_code=eq.{test_code}&limit=1"
    r = requests.get(check_url, headers=HEADERS)
    if r.status_code == 200 and r.json():
        return r.json()[0]['id']

    # Create new test
    create_url = f"{SUPABASE_URL}/rest/v1/tests"
    clean_title = f"{test_code} Official {paper_type} ({year})"
    payload = {
        'exam_code': test_code,
        'year': int(year) if year else 2024,
        'paper_type': paper_type if paper_type else 'PYQ',
        'title': clean_title,
        'duration_minutes': 120,
        'marks_per_correct': 2.0,
        'negative_marks': 0.5,
        'is_published': True
    }
    res = requests.post(create_url, headers=HEADERS, json=payload)
    if res.status_code in (200, 201):
        return res.json()[0]['id']
    else:
        raise RuntimeError(f"Failed to create test: {res.text}")

def main():
    parser = argparse.ArgumentParser(description="Ingest questions from Excel into Supabase")
    parser.add_argument("excel_file", help="Path to .xlsx file")
    parser.add_argument("--images-dir", default="test_images", help="Folder containing diagrams/charts")
    args = parser.parse_args()

    if not os.path.isfile(args.excel_file):
        print(f"Error: File not found: {args.excel_file}")
        sys.exit(1)

    wb = openpyxl.load_workbook(args.excel_file, data_only=True)
    ws = wb.active

    rows = list(ws.iter_rows(values_only=True))
    if not rows or len(rows) < 2:
        print("Excel sheet is empty or contains only headers.")
        sys.exit(0)

    header = [str(col).strip().lower() if col else '' for col in rows[0]]
    col_map = {name: idx for idx, name in enumerate(header) if name}

    required = ['test_code', 'question_text', 'correct_answer']
    for req in required:
        if req not in col_map:
            print(f"Error: Required column '{req}' missing from Excel headers: {header}")
            sys.exit(1)

    print(f"\nProcessing {len(rows)-1} rows from '{args.excel_file}'...")

    # Group cache: {(test_id, group_code): group_id}
    groups_cache = {}
    inserted_count = 0

    for r_idx, row in enumerate(rows[1:], start=2):
        def get_val(col_name, default=""):
            if col_name in col_map and col_map[col_name] < len(row):
                v = row[col_map[col_name]]
                return "" if v is None else str(v).strip()
            return default

        test_code = get_val('test_code', 'APSSB-TEST')
        if not test_code:
            continue

        year = get_val('year', '2024')
        paper_type = get_val('paper_type', 'PYQ').upper()
        subject = get_val('subject', 'General Studies')
        topic = get_val('topic')
        q_num_raw = get_val('question_num')
        q_num = int(float(q_num_raw)) if q_num_raw and q_num_raw.replace('.','',1).isdigit() else r_idx - 1

        group_code = get_val('group_code')
        group_type = get_val('group_type', 'comprehension').lower()
        direction = get_val('direction')
        passage_text = get_val('passage_text')
        passage_img_file = get_val('passage_image')

        q_text = get_val('question_text')
        fmt = get_val('format', 'text').lower()
        q_img_file = get_val('question_image')

        opt_a = get_val('option_a')
        opt_b = get_val('option_b')
        opt_c = get_val('option_c')
        opt_d = get_val('option_d')

        opt_a_img = get_val('option_a_image')
        opt_b_img = get_val('option_b_image')
        opt_c_img = get_val('option_c_image')
        opt_d_img = get_val('option_d_image')

        correct = get_val('correct_answer').lower().replace('(', '').replace(')', '').strip()
        explanation = get_val('explanation', 'Verified with official key.')
        exp_img_file = get_val('explanation_image')

        test_id = get_or_create_test(test_code, year, paper_type)

        # Handle Question Group (Passage or Direction)
        group_id = None
        if group_code or passage_text or direction:
            cache_key = (test_id, group_code if group_code else passage_text[:50])
            if cache_key in groups_cache:
                group_id = groups_cache[cache_key]
            else:
                p_img_url = upload_image_if_exists(passage_img_file, args.images_dir, test_code)
                group_payload = {
                    'test_id': test_id,
                    'group_type': group_type if group_type in ('comprehension', 'direction', 'data_interpretation') else 'comprehension',
                    'title': group_code if group_code else 'Passage Set',
                    'direction_text': direction if direction else None,
                    'instructions': direction if direction else None,
                    'passage_text': passage_text if passage_text else None,
                    'passage_image_url': p_img_url,
                    'image_url': p_img_url,
                }
                g_res = requests.post(f"{SUPABASE_URL}/rest/v1/question_groups", headers=HEADERS, json=group_payload)
                if g_res.status_code in (200, 201):
                    group_id = g_res.json()[0]['id']
                    groups_cache[cache_key] = group_id
                    print(f"  [Group] Created question group: {group_payload['title']}")

        # Upload question image
        q_img_url = upload_image_if_exists(q_img_file, args.images_dir, test_code)
        exp_img_url = upload_image_if_exists(exp_img_file, args.images_dir, test_code)

        # Upload option images
        opt_a_url = upload_image_if_exists(opt_a_img, args.images_dir, test_code)
        opt_b_url = upload_image_if_exists(opt_b_img, args.images_dir, test_code)
        opt_c_url = upload_image_if_exists(opt_c_img, args.images_dir, test_code)
        opt_d_url = upload_image_if_exists(opt_d_img, args.images_dir, test_code)

        options_json = [
            {'id': 'a', 'key': 'a', 'text': opt_a, 'image': opt_a_url, 'image_url': opt_a_url},
            {'id': 'b', 'key': 'b', 'text': opt_b, 'image': opt_b_url, 'image_url': opt_b_url},
            {'id': 'c', 'key': 'c', 'text': opt_c, 'image': opt_c_url, 'image_url': opt_c_url},
            {'id': 'd', 'key': 'd', 'text': opt_d, 'image': opt_d_url, 'image_url': opt_d_url},
        ]

        question_payload = {
            'test_id': test_id,
            'group_id': group_id,
            'question_number': q_num,
            'order_index': q_num,
            'subject': subject,
            'topic': topic if topic else None,
            'difficulty': 'Medium',
            'question_type': 'mcq',
            'content_format': fmt if fmt in ('text', 'latex', 'image_only') else 'text',
            'direction_text': direction if direction and not group_id else None,
            'question_text': q_text,
            'question_image_url': q_img_url,
            'image_url': q_img_url,
            'options': options_json,
            'correct_answer': correct[0] if correct else 'a',
            'correct_option': correct[0] if correct else 'a',
            'explanation': explanation,
            'explanation_image_url': exp_img_url,
            'review_status': 'approved',
            'flagged_issues': [],
            'admin_notes': 'Imported via Master Excel Template'
        }

        # Check if question already exists for this test_id and question_number
        check_q = requests.get(f"{SUPABASE_URL}/rest/v1/questions?test_id=eq.{test_id}&question_number=eq.{q_num}&limit=1", headers=HEADERS)
        
        def fallback_payload(p):
            core_keys = ['test_id', 'group_id', 'question_number', 'subject', 'difficulty', 'question_text', 'question_image_url', 'options', 'correct_answer', 'explanation', 'explanation_image_url']
            return {k: v for k, v in p.items() if k in core_keys}

        if check_q.status_code == 200 and check_q.json():
            # Update existing row
            qid = check_q.json()[0]['id']
            up_res = requests.patch(f"{SUPABASE_URL}/rest/v1/questions?id=eq.{qid}", headers=HEADERS, json=question_payload)
            if up_res.status_code in (200, 204):
                inserted_count += 1
                print(f"  [Q{q_num}] Updated question ID {qid} (Test: {test_code})")
            elif up_res.status_code >= 400:
                up_res2 = requests.patch(f"{SUPABASE_URL}/rest/v1/questions?id=eq.{qid}", headers=HEADERS, json=fallback_payload(question_payload))
                if up_res2.status_code in (200, 204):
                    inserted_count += 1
                    print(f"  [Q{q_num}] Updated question ID {qid} (Compatibility mode)")
                else:
                    print(f"  [Error Q{q_num}] {up_res2.text}")
        else:
            # Insert new row
            in_res = requests.post(f"{SUPABASE_URL}/rest/v1/questions", headers=HEADERS, json=question_payload)
            if in_res.status_code in (200, 201):
                inserted_count += 1
                print(f"  [Q{q_num}] Inserted new question (Test: {test_code})")
            elif in_res.status_code >= 400:
                in_res2 = requests.post(f"{SUPABASE_URL}/rest/v1/questions", headers=HEADERS, json=fallback_payload(question_payload))
                if in_res2.status_code in (200, 201):
                    inserted_count += 1
                    print(f"  [Q{q_num}] Inserted new question (Compatibility mode)")
                else:
                    print(f"  [Error Q{q_num}] {in_res2.text}")

    print(f"\nCompleted! Successfully synced {inserted_count} questions into Supabase.")

if __name__ == '__main__':
    main()
