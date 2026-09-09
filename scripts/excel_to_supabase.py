"""
ARUNACHAL EXAM PREP - EXCEL TO SUPABASE INGESTION TOOL
======================================================
Imports curated questions from Excel (.xlsx) or CSV into Supabase PostgreSQL.
Handles:
- Systematic test_code resolution (e.g. APPSC-JE-CE-2023-P1)
- Agency & Branch linking (APSSB/APPSC, CE/EE/ME/CSE/AGRI/GEN)
- Subject codes (ENG, MATH, GK, APGK, CE_SOM, etc.) & Topic codes
- Question groups (Comprehension Passages, Directions, and Charts)
- Image uploading to Supabase Storage bucket 'exam-assets'
- Mathematics formatting (LaTeX, Unicode, Image-Only)
- Full relational integrity with graceful schema compatibility fallback
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

# Standard dictionary mapping subject codes to full names
SUBJECT_MAP = {
    'ENG': 'General English',
    'MATH': 'Elementary Mathematics',
    'GK': 'General Knowledge / Studies',
    'APGK': 'Arunachal Pradesh GK',
    'REAS': 'Logical Reasoning & Mental Ability',
    'CSAT': 'Civil Services Aptitude Test',
    'CE_SOM': 'Strength of Materials & Structural Mechanics',
    'CE_RCC': 'Reinforced Concrete & Steel Structures',
    'CE_SURV': 'Surveying & Geomatics',
    'CE_FLUID': 'Fluid Mechanics & Hydraulics',
    'CE_GEO': 'Soil Mechanics & Geotechnical Engg',
    'CE_TRANS': 'Highway & Transportation Engineering',
    'CE_ENV': 'Environmental & Public Health Engg',
    'EE_CKT': 'Circuit Theory & Networks',
    'EE_MACH': 'Electrical Machines & Transformers',
    'EE_POWER': 'Power Systems & Switchgear',
    'ME_THERM': 'Thermodynamics & Heat Transfer',
    'ME_FLUID': 'Fluid Mechanics & Hydraulic Machinery',
    'ME_MFG': 'Manufacturing Science & Technology',
    'CSE_PROG': 'Programming & Data Structures',
    'CSE_DBMS': 'Database Systems & SQL',
    'CSE_OS': 'Operating Systems & System Software',
    'CSE_NET': 'Computer Networks & Security',
    'AGRI_AGRO': 'Agronomy & Field Crops',
    'AGRI_SOIL': 'Soil Science & Chemistry',
    'AGRI_PATH': 'Plant Pathology & Crop Protection'
}

# Inverted mapping to deduce subject_code from free text
SUBJECT_INVERTED_MAP = {
    'english': 'ENG',
    'math': 'MATH',
    'mathematics': 'MATH',
    'arithmetic': 'MATH',
    'quantitative': 'MATH',
    'gk': 'GK',
    'general studies': 'GK',
    'general knowledge': 'GK',
    'arunachal': 'APGK',
    'reasoning': 'REAS',
    'aptitude': 'REAS',
    'csat': 'CSAT'
}

def deduce_subject_code(subject_code_input, subject_name_input):
    if subject_code_input:
        code = str(subject_code_input).strip().upper()
        if code in SUBJECT_MAP:
            return code, SUBJECT_MAP[code]
        return code, subject_name_input or code

    if subject_name_input:
        lower = str(subject_name_input).lower()
        for key, code in SUBJECT_INVERTED_MAP.items():
            if key in lower:
                return code, str(subject_name_input).strip()
        return 'GK', str(subject_name_input).strip()

    return 'GK', 'General Studies'

def upload_image_if_exists(image_name_or_url, images_dir, test_code):
    if not image_name_or_url:
        return None
    val = str(image_name_or_url).strip()
    if val.startswith('http://') or val.startswith('https://'):
        return val

    # Look for local file in images_dir
    local_path = os.path.join(images_dir, val)
    if not os.path.isfile(local_path):
        basename = os.path.basename(val)
        local_path = os.path.join(images_dir, basename)
        if not os.path.isfile(local_path):
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
            return None
    except Exception as e:
        print(f"  [Storage Error] {e}")
        return None

def compute_systematic_test_code(agency, exam_code, branch, year, paper_type, paper_num):
    # If exam_code already contains agency prefix like APPSC-JE-CE-2023-P1, normalize and return
    if '-' in exam_code and (exam_code.startswith('APSSB') or exam_code.startswith('APPSC')):
        return exam_code.strip()

    agency_str = (agency or 'APSSB').strip().upper()
    exam_str = (exam_code or 'CGLE').strip().upper()
    branch_str = (branch or 'GEN').strip().upper()
    year_str = str(year or '2024').strip()
    
    parts = [agency_str, exam_str]
    if branch_str and branch_str != 'GEN':
        parts.append(branch_str)
    parts.append(year_str)
    if paper_num:
        parts.append(paper_num.strip().upper())
    
    return "-".join(parts)

def get_or_create_test(test_code, agency, branch, year, paper_type, exam_raw=None):
    # 1. Search by test_code or exam_code
    check_url = f"{SUPABASE_URL}/rest/v1/tests?or=(test_code.eq.{test_code},exam_code.eq.{test_code})&limit=1"
    r = requests.get(check_url, headers=HEADERS)
    if r.status_code == 200 and r.json():
        return r.json()[0]['id']

    # Fallback search by raw exam_code and year
    if exam_raw:
        check_url2 = f"{SUPABASE_URL}/rest/v1/tests?exam_code=eq.{exam_raw}&year=eq.{year}&limit=1"
        r2 = requests.get(check_url2, headers=HEADERS)
        if r2.status_code == 200 and r2.json():
            return r2.json()[0]['id']

    # 2. Create new test with taxonomy columns
    create_url = f"{SUPABASE_URL}/rest/v1/tests"
    clean_title = f"{test_code} Official {paper_type} ({year})"
    payload = {
        'test_code': test_code,
        'agency_code': agency,
        'branch_code': branch if branch else 'GEN',
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
    elif res.status_code >= 400:
        # Graceful fallback: remove taxonomy columns if migration 005 not applied yet
        fallback_keys = ['exam_code', 'year', 'paper_type', 'title', 'duration_minutes', 'marks_per_correct', 'negative_marks', 'is_published']
        res2 = requests.post(create_url, headers=HEADERS, json={k: payload[k] for k in fallback_keys if k in payload})
        if res2.status_code in (200, 201):
            return res2.json()[0]['id']
        else:
            raise RuntimeError(f"Failed to create test: {res2.text}")

def main():
    parser = argparse.ArgumentParser(description="Ingest questions from Excel into Supabase with systematic taxonomy")
    parser.add_argument("excel_file", help="Path to .xlsx file")
    parser.add_argument("--images-dir", default="test_images", help="Folder containing diagrams/charts")
    args = parser.parse_args()

    if not os.path.isfile(args.excel_file):
        print(f"Error: File not found: {args.excel_file}")
        sys.exit(1)

    wb = openpyxl.load_workbook(args.excel_file, data_only=True)
    # Prefer 'Questions' sheet if present, else active
    ws = wb['Questions'] if 'Questions' in wb.sheetnames else wb.active

    rows = list(ws.iter_rows(values_only=True))
    if not rows or len(rows) < 2:
        print("Excel sheet is empty or contains only headers.")
        sys.exit(0)

    header = [str(col).strip().lower() if col else '' for col in rows[0]]
    col_map = {name: idx for idx, name in enumerate(header) if name}

    # Verify essential columns
    has_test_code = 'test_code' in col_map or 'exam_code' in col_map
    if not has_test_code or 'question_text' not in col_map or 'correct_answer' not in col_map:
        print(f"Error: Required columns ('test_code' or 'exam_code', 'question_text', 'correct_answer') missing.")
        print(f"Found headers: {header}")
        sys.exit(1)

    print(f"\nProcessing {len(rows)-1} rows from '{args.excel_file}'...")

    groups_cache = {}
    inserted_count = 0

    for r_idx, row in enumerate(rows[1:], start=2):
        def get_val(col_name, default=""):
            if col_name in col_map and col_map[col_name] < len(row):
                v = row[col_map[col_name]]
                return "" if v is None else str(v).strip()
            return default

        agency = get_val('agency', 'APSSB').upper()
        exam_raw = get_val('exam_code')
        branch = get_val('branch', get_val('branch_code', 'GEN')).upper()
        year = get_val('year', '2024')
        paper_type = get_val('paper_type', 'PYQ').upper()
        paper_num = get_val('paper_num')
        explicit_test_code = get_val('test_code')

        if explicit_test_code:
            test_code = explicit_test_code
        else:
            test_code = compute_systematic_test_code(agency, exam_raw, branch, year, paper_type, paper_num)

        if not test_code:
            continue

        subj_code_in = get_val('subject_code')
        subj_name_in = get_val('subject')
        subject_code, subject_name = deduce_subject_code(subj_code_in, subj_name_in)
        topic_code = get_val('topic_code', get_val('topic'))

        q_num_raw = get_val('question_num')
        q_num = int(float(q_num_raw)) if q_num_raw and q_num_raw.replace('.','',1).isdigit() else r_idx - 1

        group_code_in = get_val('group_code')
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

        test_id = get_or_create_test(test_code, agency, branch, year, paper_type, exam_raw)

        # Handle Question Group (Passage or Direction)
        group_id = None
        if group_code_in or passage_text or direction:
            standard_group_code = f"{test_code}-{group_code_in}" if group_code_in and not group_code_in.startswith(test_code) else group_code_in
            cache_key = (test_id, standard_group_code if standard_group_code else passage_text[:50])
            if cache_key in groups_cache:
                group_id = groups_cache[cache_key]
            else:
                p_img_url = upload_image_if_exists(passage_img_file, args.images_dir, test_code)
                group_payload = {
                    'test_id': test_id,
                    'group_code': standard_group_code,
                    'group_type': group_type if group_type in ('comprehension', 'direction', 'data_interpretation') else 'comprehension',
                    'title': standard_group_code if standard_group_code else 'Passage Set',
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
                elif g_res.status_code >= 400:
                    # Fallback without group_code
                    g_res2 = requests.post(f"{SUPABASE_URL}/rest/v1/question_groups", headers=HEADERS, json={k: v for k, v in group_payload.items() if k != 'group_code'})
                    if g_res2.status_code in (200, 201):
                        group_id = g_res2.json()[0]['id']
                        groups_cache[cache_key] = group_id

        # Upload images
        q_img_url = upload_image_if_exists(q_img_file, args.images_dir, test_code)
        exp_img_url = upload_image_if_exists(exp_img_file, args.images_dir, test_code)
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
            'subject_code': subject_code,
            'topic_code': topic_code if topic_code else None,
            'subject': subject_name,
            'topic': topic_code if topic_code else None,
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

        # Check existing row
        check_q = requests.get(f"{SUPABASE_URL}/rest/v1/questions?test_id=eq.{test_id}&question_number=eq.{q_num}&limit=1", headers=HEADERS)

        def fallback_payload(p):
            # Strip taxonomy columns that may not exist prior to migration 005
            unsupported = {'subject_code', 'topic_code'}
            return {k: v for k, v in p.items() if k not in unsupported}

        def core_payload(p):
            core_keys = ['test_id', 'group_id', 'question_number', 'subject', 'difficulty', 'question_text', 'question_image_url', 'options', 'correct_answer', 'explanation', 'explanation_image_url']
            return {k: v for k, v in p.items() if k in core_keys}

        if check_q.status_code == 200 and check_q.json():
            qid = check_q.json()[0]['id']
            up_res = requests.patch(f"{SUPABASE_URL}/rest/v1/questions?id=eq.{qid}", headers=HEADERS, json=question_payload)
            if up_res.status_code in (200, 204):
                inserted_count += 1
                print(f"  [Q{q_num}] Updated question ID {qid} ({test_code})")
            elif up_res.status_code >= 400:
                up_res2 = requests.patch(f"{SUPABASE_URL}/rest/v1/questions?id=eq.{qid}", headers=HEADERS, json=fallback_payload(question_payload))
                if up_res2.status_code in (200, 204):
                    inserted_count += 1
                    print(f"  [Q{q_num}] Updated question ID {qid} (Taxonomy fallback mode)")
                else:
                    up_res3 = requests.patch(f"{SUPABASE_URL}/rest/v1/questions?id=eq.{qid}", headers=HEADERS, json=core_payload(question_payload))
                    if up_res3.status_code in (200, 204):
                        inserted_count += 1
                        print(f"  [Q{q_num}] Updated question ID {qid} (Core compatibility mode)")
                    else:
                        print(f"  [Error Q{q_num}] {up_res3.text}")
        else:
            in_res = requests.post(f"{SUPABASE_URL}/rest/v1/questions", headers=HEADERS, json=question_payload)
            if in_res.status_code in (200, 201):
                inserted_count += 1
                print(f"  [Q{q_num}] Inserted new question ({test_code})")
            elif in_res.status_code >= 400:
                in_res2 = requests.post(f"{SUPABASE_URL}/rest/v1/questions", headers=HEADERS, json=fallback_payload(question_payload))
                if in_res2.status_code in (200, 201):
                    inserted_count += 1
                    print(f"  [Q{q_num}] Inserted new question (Taxonomy fallback mode)")
                else:
                    in_res3 = requests.post(f"{SUPABASE_URL}/rest/v1/questions", headers=HEADERS, json=core_payload(question_payload))
                    if in_res3.status_code in (200, 201):
                        inserted_count += 1
                        print(f"  [Q{q_num}] Inserted new question (Core compatibility mode)")
                    else:
                        print(f"  [Error Q{q_num}] {in_res3.text}")

    print(f"\nCompleted! Successfully synced {inserted_count} questions into Supabase.")

if __name__ == '__main__':
    main()
