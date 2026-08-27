"""
ARUNACHAL EXAM PREP - BATCH QUESTION UPLOADER (EXCEL / CSV / SCENARIOS)

Usage:
  python scripts/upload_questions.py --file "path/to/mock_or_pyq.xlsx" --mode "firestore"
"""

import os
import sys
import json
import re
import argparse
from difflib import SequenceMatcher
import pandas as pd

REQUIRED_COLUMNS = [
    'examCode', 'year', 'paperType', 'testId', 'testTitle', 
    'subject', 'difficulty', 'questionText', 'optionA', 
    'optionB', 'optionC', 'optionD', 'correctAnswer', 'solution'
]

def normalize_text(text):
    """Normalize text by lowercasing, removing punctuation, and trimming extra spaces."""
    if not text:
        return ""
    text = text.lower()
    text = re.sub(r'[^\w\s]', '', text)
    # Remove common filler/stop words
    stopwords = {'what', 'which', 'is', 'the', 'of', 'in', 'and', 'to', 'a', 'an', 'for', 'on', 'with', 'as', 'by'}
    tokens = [w for w in text.split() if w not in stopwords]
    return " ".join(sorted(tokens)) # Token sort normalization

def compute_similarity(q1, q2):
    """Computes similarity percentage between two question strings."""
    norm1 = normalize_text(q1)
    norm2 = normalize_text(q2)
    return SequenceMatcher(None, norm1, norm2).ratio() * 100.0

def parse_and_validate(file_path):
    print(f"\n📂 Reading file: {file_path}")
    if file_path.endswith('.xlsx') or file_path.endswith('.xls'):
        df = pd.read_excel(file_path)
    elif file_path.endswith('.csv'):
        df = pd.read_csv(file_path)
    else:
        raise ValueError("Unsupported format! Please use .xlsx or .csv")

    # Clean header names
    df.columns = [str(c).strip() for c in df.columns]
    
    missing_cols = [col for col in REQUIRED_COLUMNS if col not in df.columns]
    if missing_cols:
        raise ValueError(f"❌ Missing mandatory columns: {missing_cols}")

    print(f"📊 Total Rows Found: {len(df)}")
    valid_questions = []
    errors = []

    for idx, row in df.iterrows():
        row_num = idx + 2
        
        exam_code = str(row.get('examCode', '')).strip()
        paper_type = str(row.get('paperType', 'MOCK')).strip().upper()
        test_id = str(row.get('testId', '')).strip()
        test_title = str(row.get('testTitle', '')).strip()
        subject = str(row.get('subject', '')).strip()
        difficulty = str(row.get('difficulty', 'Medium')).strip()
        q_text = str(row.get('questionText', '')).strip()
        
        opt_a = str(row.get('optionA', '')).strip()
        opt_b = str(row.get('optionB', '')).strip()
        opt_c = str(row.get('optionC', '')).strip()
        opt_d = str(row.get('optionD', '')).strip()
        correct = str(row.get('correctAnswer', '')).strip().lower()
        solution = str(row.get('solution', '')).strip()

        # Image fields (optional)
        q_img = str(row.get('questionImage', '')).strip() if pd.notna(row.get('questionImage')) else None
        opt_a_img = str(row.get('optionA_Image', '')).strip() if pd.notna(row.get('optionA_Image')) else None
        opt_b_img = str(row.get('optionB_Image', '')).strip() if pd.notna(row.get('optionB_Image')) else None
        opt_c_img = str(row.get('optionC_Image', '')).strip() if pd.notna(row.get('optionC_Image')) else None
        opt_d_img = str(row.get('optionD_Image', '')).strip() if pd.notna(row.get('optionD_Image')) else None
        sol_img = str(row.get('solutionImage', '')).strip() if pd.notna(row.get('solutionImage')) else None

        # Scenario & Test Series configs
        time_limit = int(row.get('timeLimitMins', 120)) if pd.notna(row.get('timeLimitMins')) else 120
        marks_correct = float(row.get('marksPerCorrect', 2.0)) if pd.notna(row.get('marksPerCorrect')) else 2.0
        neg_marks = float(row.get('negativeMarks', 0.66)) if pd.notna(row.get('negativeMarks')) else 0.66
        is_scenario = bool(row.get('isScenarioTest', False)) if pd.notna(row.get('isScenarioTest')) else False
        scenario_tags = str(row.get('scenarioTags', '')).strip() if pd.notna(row.get('scenarioTags')) else ""

        if not q_text:
            errors.append(f"Row {row_num}: questionText is empty.")
        if not opt_a or not opt_b or not opt_c or not opt_d:
            errors.append(f"Row {row_num}: One or more options are empty.")
        if correct not in ['a', 'b', 'c', 'd']:
            errors.append(f"Row {row_num}: correctAnswer '{correct}' is invalid (must be a, b, c, or d).")
        if not solution:
            errors.append(f"Row {row_num}: solution explanation is missing.")

        # Check for duplicates within this batch
        for prev_idx, prev_q in enumerate(valid_questions):
            sim = compute_similarity(q_text, prev_q['questionText'])
            if sim >= 85.0:
                errors.append(f"Row {row_num}: Duplicate/Redundant question detected! ({sim:.1f}% match with Row {prev_idx+2}): '{q_text[:60]}...'")
                break
            elif sim >= 70.0:
                print(f"  ⚠️ Warning [Row {row_num}]: {sim:.1f}% similar to Row {prev_idx+2} ('{q_text[:50]}...')")

        question_obj = {
            "id": f"{test_id}_q{idx+1}",
            "examCode": exam_code,
            "year": int(row.get('year', 2024)) if pd.notna(row.get('year')) else 2024,
            "paperType": paper_type,
            "testId": test_id,
            "testTitle": test_title,
            "subject": subject,
            "difficulty": difficulty,
            "questionText": q_text,
            "questionImage": q_img,
            "options": [
                {"key": "a", "text": opt_a, "image": opt_a_img},
                {"key": "b", "text": opt_b, "image": opt_b_img},
                {"key": "c", "text": opt_c, "image": opt_c_img},
                {"key": "d", "text": opt_d, "image": opt_d_img},
            ],
            "correctAnswer": correct,
            "solution": solution,
            "solutionImage": sol_img,
            "timeLimitMins": time_limit,
            "marksPerCorrect": marks_correct,
            "negativeMarks": neg_marks,
            "isScenarioTest": is_scenario,
            "scenarioTags": scenario_tags
        }
        valid_questions.append(question_obj)

    if errors:
        print(f"\n❌ Found {len(errors)} Validation & Redundancy Errors:")
        for err in errors[:10]:
            print(f"  • {err}")
        if len(errors) > 10:
            print(f"  ...and {len(errors)-10} more.")
        return None

    print(f"\n✅ Anti-Redundancy Scan Passed: All {len(valid_questions)} questions are unique & validated!")
    return valid_questions

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Upload question papers in bulk.")
    parser.add_argument("--file", required=True, help="Path to .xlsx or .csv file")
    parser.add_argument("--export-json", action="store_true", help="Export to validated JSON file")
    args = parser.parse_args()

    questions = parse_and_validate(args.file)
    if questions and args.export_json:
        out_name = f"{questions[0]['testId']}_export.json"
        with open(out_name, "w", encoding="utf-8") as f:
            json.dump(questions, f, indent=2, ensure_ascii=False)
        print(f"📁 Exported validated payload to: {out_name}")
