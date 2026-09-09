"""
ARUNACHAL EXAM PREP - MASTER QUESTION EXCEL TEMPLATE GENERATOR
==============================================================
Generates a production-ready Excel workbook with:
1. Sheet 'Questions': Pre-configured columns with data validation dropdowns,
   systematic exam codes, branch codes, subject codes, and topic codes.
2. Sheet 'Code Reference': Comprehensive dictionary of all standard codes for:
   - Agencies (APSSB, APPSC)
   - Branches (GEN, CE, EE, ME, CSE, AGRI, etc.)
   - Exams (CGLE, CHSL, CSLE, CCE, JE, AE, ADO, etc.)
   - Subjects (ENG, MATH, GK, APGK, CE_SOM, EE_MACH, etc.)
   - Topics (MATH-ARITH, GK-HIST, ENG-VOCAB, etc.)
"""

import os
import openpyxl
from openpyxl.styles import Font, PatternFill, Alignment, Border, Side
from openpyxl.utils import get_column_letter
from openpyxl.worksheet.datavalidation import DataValidation

os.makedirs('scripts/templates', exist_ok=True)
wb = openpyxl.Workbook()

# ====================================================================
# 1. SHEET 1: QUESTIONS
# ====================================================================
ws_q = wb.active
ws_q.title = "Questions"

headers = [
    ("agency", 12, "APSSB or APPSC"),
    ("exam_code", 14, "CGLE, CHSL, CSLE, JE, AE, CCE, ADO..."),
    ("branch", 12, "GEN, CE, EE, ME, CSE, AGRI..."),
    ("year", 8, "e.g. 2024"),
    ("paper_type", 12, "PYQ or MOCK"),
    ("paper_num", 12, "P1, P2 or blank"),
    ("test_code", 22, "Auto-computed if blank (e.g. APPSC-JE-CE-2023-P1)"),
    ("subject_code", 16, "ENG, MATH, GK, APGK, CE_SOM..."),
    ("topic_code", 16, "MATH-ARITH, ENG-VOCAB, GK-HIST..."),
    ("question_num", 14, "Official Q.No (1, 2, 3...)"),
    ("group_code", 16, "COMP-01, DIR-01 (links shared passage/direction)"),
    ("group_type", 16, "comprehension, direction, or data_interpretation"),
    ("direction", 30, "Instructions shared across questions"),
    ("passage_text", 40, "Reading comprehension text (paste once per group)"),
    ("passage_image", 20, "Filename for passage chart (e.g. di_chart.png)"),
    ("question_text", 45, "Main question prompt"),
    ("format", 12, "text, latex, or image_only"),
    ("question_image", 20, "Filename of figure in test_images/"),
    ("option_a", 24, "Option A text"),
    ("option_a_image", 18, "Image for Option A (optional)"),
    ("option_b", 24, "Option B text"),
    ("option_b_image", 18, "Image for Option B (optional)"),
    ("option_c", 24, "Option C text"),
    ("option_c_image", 18, "Image for Option C (optional)"),
    ("option_d", 24, "Option D text"),
    ("option_d_image", 18, "Image for Option D (optional)"),
    ("correct_answer", 14, "a, b, c, or d"),
    ("explanation", 40, "Detailed solution or explanation"),
    ("explanation_image", 20, "Filename of solution diagram (optional)")
]

# Styling
header_font = Font(name="Segoe UI", size=11, bold=True, color="FFFFFF")
header_fill = PatternFill(start_color="1E3A8A", end_color="1E3A8A", fill_type="solid")
header_align = Alignment(horizontal="center", vertical="center", wrap_text=True)
thin_border = Border(
    left=Side(style='thin', color='CBD5E1'),
    right=Side(style='thin', color='CBD5E1'),
    top=Side(style='thin', color='CBD5E1'),
    bottom=Side(style='thin', color='CBD5E1')
)

ws_q.row_dimensions[1].height = 32

for col_idx, (col_name, width, _) in enumerate(headers, start=1):
    cell = ws_q.cell(row=1, column=col_idx, value=col_name)
    cell.font = header_font
    cell.fill = header_fill
    cell.alignment = header_align
    cell.border = thin_border
    ws_q.column_dimensions[get_column_letter(col_idx)].width = width

# Sample demonstration rows illustrating different types of questions
sample_rows = [
    # Row 1: APSSB CGLE 2024 General Studies History MCQ
    [
        "APSSB", "CGLE", "GEN", 2024, "PYQ", "", "APSSB-CGLE-2024",
        "GK", "GK-HIST", 1,
        "", "", "", "", "",
        "Who was the first President of Independent India?",
        "text", "",
        "Dr. Rajendra Prasad", "",
        "Dr. S. Radhakrishnan", "",
        "Jawaharlal Nehru", "",
        "Sardar Vallabhbhai Patel", "",
        "a",
        "Dr. Rajendra Prasad served as the first President of India from 1950 to 1962.",
        ""
    ],
    # Row 2: APSSB CGLE 2024 Reading Comprehension Q1 (Linked to COMP-01)
    [
        "APSSB", "CGLE", "GEN", 2024, "PYQ", "", "APSSB-CGLE-2024",
        "ENG", "ENG-COMP", 2,
        "COMP-01", "comprehension", "",
        "The climate of Arunachal Pradesh varies with elevation. The sub-Himalayan belt has a humid subtropical climate, while the higher elevations enjoy a cool alpine climate with heavy snow in winter.",
        "arunachal_climate_map.png",
        "According to the passage, what climate prevails in the sub-Himalayan belt of Arunachal Pradesh?",
        "text", "",
        "Dry arid climate", "",
        "Humid subtropical climate", "",
        "Tropical savanna", "",
        "Polar ice cap", "",
        "b",
        "The passage explicitly states that the sub-Himalayan belt experiences a humid subtropical climate.",
        ""
    ],
    # Row 3: APSSB CGLE 2024 Reading Comprehension Q2 (Linked to COMP-01)
    [
        "APSSB", "CGLE", "GEN", 2024, "PYQ", "", "APSSB-CGLE-2024",
        "ENG", "ENG-COMP", 3,
        "COMP-01", "comprehension", "",
        "The climate of Arunachal Pradesh varies with elevation. The sub-Himalayan belt has a humid subtropical climate, while the higher elevations enjoy a cool alpine climate with heavy snow in winter.",
        "",
        "What type of weather is experienced in the higher elevations during winter?",
        "text", "",
        "Hot and arid", "",
        "Tropical monsoon with no rain", "",
        "Cool alpine climate with heavy snow", "",
        "Mild desert weather", "",
        "c",
        "The higher elevations enjoy a cool alpine climate with heavy snow in winter.",
        ""
    ],
    # Row 4: APPSC JE Civil Engineering Paper 1 Technical Question
    [
        "APPSC", "JE", "CE", 2023, "PYQ", "P1", "APPSC-JE-CE-2023-P1",
        "CE_SOM", "", 15,
        "", "", "", "", "",
        "For a simply supported beam of span L subjected to a central point load W, what is the maximum bending moment?",
        "latex", "",
        "WL / 2", "",
        "WL / 4", "",
        "WL / 8", "",
        "WL / 12", "",
        "b",
        "For a simply supported beam with central point load W: M_max = WL / 4 occurring at mid-span.",
        "ss_beam_bm_diagram.png"
    ],
    # Row 5: Shared Direction Set (Questions 4-5 follow same instructions)
    [
        "APSSB", "CHSL", "GEN", 2023, "PYQ", "", "APSSB-CHSL-2023",
        "ENG", "ENG-VOCAB", 4,
        "DIR-01", "direction",
        "Directions (Q.4 - Q.5): Choose the word that is most nearly OPPOSITE in meaning (ANTONYM) to the capitalized word.",
        "", "",
        "AMELIORATE",
        "text", "",
        "Worsen", "",
        "Improve", "",
        "Brighten", "",
        "Clarify", "",
        "a",
        "Ameliorate means to improve or make better; its direct antonym is worsen.",
        ""
    ]
]

data_font = Font(name="Segoe UI", size=10)
data_align = Alignment(vertical="center")

for row_idx, row_values in enumerate(sample_rows, start=2):
    ws_q.row_dimensions[row_idx].height = 24
    for col_idx, val in enumerate(row_values, start=1):
        cell = ws_q.cell(row=row_idx, column=col_idx, value=val)
        cell.font = data_font
        cell.alignment = data_align
        cell.border = thin_border

# Add Excel Data Validations
dv_agency = DataValidation(type="list", formula1='"APSSB,APPSC"', allow_blank=True)
ws_q.add_data_validation(dv_agency)
dv_agency.add(f"A2:A5000")

dv_paper_type = DataValidation(type="list", formula1='"PYQ,MOCK"', allow_blank=True)
ws_q.add_data_validation(dv_paper_type)
dv_paper_type.add(f"E2:E5000")

dv_group_type = DataValidation(type="list", formula1='"comprehension,direction,data_interpretation"', allow_blank=True)
ws_q.add_data_validation(dv_group_type)
dv_group_type.add(f"L2:L5000")

dv_format = DataValidation(type="list", formula1='"text,latex,image_only"', allow_blank=True)
ws_q.add_data_validation(dv_format)
dv_format.add(f"Q2:Q5000")

dv_correct = DataValidation(type="list", formula1='"a,b,c,d"', allow_blank=True)
ws_q.add_data_validation(dv_correct)
dv_correct.add(f"AA2:AA5000")

# ====================================================================
# 2. SHEET 2: CODE REFERENCE
# ====================================================================
ws_ref = wb.create_sheet(title="Code Reference")

section_title_font = Font(name="Segoe UI", size=12, bold=True, color="1E3A8A")
section_header_font = Font(name="Segoe UI", size=10, bold=True, color="FFFFFF")
section_header_fill = PatternFill(start_color="3B82F6", end_color="3B82F6", fill_type="solid")

def write_reference_section(ws, start_row, title, headers, rows):
    # Title
    ws.cell(row=start_row, column=1, value=title).font = section_title_font
    current_row = start_row + 1
    
    # Headers
    ws.row_dimensions[current_row].height = 24
    for c_idx, h in enumerate(headers, start=1):
        c = ws.cell(row=current_row, column=c_idx, value=h)
        c.font = section_header_font
        c.fill = section_header_fill
        c.alignment = Alignment(horizontal="center", vertical="center")
        c.border = thin_border
    
    current_row += 1
    for r in rows:
        ws.row_dimensions[current_row].height = 20
        for c_idx, val in enumerate(r, start=1):
            c = ws.cell(row=current_row, column=c_idx, value=val)
            c.font = Font(name="Segoe UI", size=9)
            c.alignment = Alignment(vertical="center")
            c.border = thin_border
        current_row += 1
    
    return current_row + 2

r_row = 1

# Agencies
r_row = write_reference_section(
    ws_ref, r_row, "1. AGENCIES (agency)",
    ["agency_code", "Full Commission Name", "Cadre & Level"],
    [
        ["APSSB", "Arunachal Pradesh Staff Selection Board", "Group C Non-Gazetted (10th, 12th, Graduate)"],
        ["APPSC", "Arunachal Pradesh Public Service Commission", "Group A & B Gazetted Officers, Engineering & Civil Services"]
    ]
)

# Branches
r_row = write_reference_section(
    ws_ref, r_row, "2. BRANCHES & DISCIPLINES (branch)",
    ["branch_code", "Discipline Name", "Category", "Target Exams"],
    [
        ["GEN", "General Studies & Non-Technical", "general", "CGLE, CHSL, CSLE, CCE, SI"],
        ["CE", "Civil Engineering", "engineering", "APPSC-JE-CE, APPSC-AE-CE"],
        ["EE", "Electrical Engineering", "engineering", "APPSC-JE-EE, APPSC-AE-EE"],
        ["ME", "Mechanical Engineering", "engineering", "APPSC-JE-ME, APPSC-AE-ME"],
        ["CSE", "Computer Science & Engineering / IT", "engineering", "APPSC-JE-CSE, APPSC-LECT-CSE"],
        ["ECE", "Electronics & Communication Engineering", "engineering", "APPSC-JE-ECE, APPSC-AE-ECE"],
        ["AGRI", "Agricultural Science & Engineering", "allied_science", "APPSC-JE-AGRI, APPSC-ADO"],
        ["HORT", "Horticulture Science", "allied_science", "APPSC-HDO"],
        ["VET", "Veterinary Science & Animal Husbandry", "allied_science", "APPSC-VET"],
        ["FOREST", "Forestry & Wildlife Science", "allied_science", "APPSC-RFO, APSSB-FOREST"]
    ]
)

# Exams
r_row = write_reference_section(
    ws_ref, r_row, "3. EXAM CADRES (exam_code)",
    ["exam_code", "agency", "Full Examination Title", "Eligibility Level"],
    [
        ["CGLE", "APSSB", "Combined Graduate Level Examination", "Graduate"],
        ["CHSL", "APSSB", "Combined Higher Secondary Level Examination", "Class 12 / 10+2"],
        ["CSLE", "APSSB", "Combined Secondary Level Examination", "Class 10 / Matric"],
        ["STENO", "APSSB", "Stenographer Grade-III Examination", "12th + Shorthand"],
        ["FOREST", "APSSB", "Forester & Forest Guard Examination", "10th / 12th"],
        ["POLICE", "APSSB", "Police Constable / IRBn / AAPBn Examination", "10th Pass"],
        ["CCE", "APPSC", "Combined Competitive Examination (Civil Services)", "Graduate"],
        ["JE", "APPSC", "Junior Engineer Examination", "3-Year Engineering Diploma"],
        ["AE", "APPSC", "Assistant Engineer Examination", "B.Tech / B.E. Degree"],
        ["SI", "APPSC", "Sub-Inspector of Police Examination", "Graduate"],
        ["ADO", "APPSC", "Agriculture Development Officer Examination", "B.Sc. Agriculture"],
        ["HDO", "APPSC", "Horticulture Development Officer Examination", "B.Sc. Horticulture"],
        ["VET", "APPSC", "Veterinary Officer Examination", "B.V.Sc & AH"],
        ["LECT", "APPSC", "Polytechnic Lecturer Examination", "B.Tech / M.Tech"]
    ]
)

# Subjects
r_row = write_reference_section(
    ws_ref, r_row, "4. SYSTEMATIC SUBJECT CODES (subject_code)",
    ["subject_code", "branch", "Standard Subject Name", "Category"],
    [
        ["ENG", "GEN", "General English", "general"],
        ["MATH", "GEN", "Elementary Mathematics", "general"],
        ["GK", "GEN", "General Knowledge / Studies", "general"],
        ["APGK", "GEN", "Arunachal Pradesh General Knowledge", "state_gk"],
        ["REAS", "GEN", "Logical Reasoning & Mental Ability", "aptitude"],
        ["CSAT", "GEN", "Civil Services Aptitude Test", "aptitude"],
        ["CE_SOM", "CE", "Strength of Materials & Structural Mechanics", "technical"],
        ["CE_RCC", "CE", "Reinforced Concrete & Steel Structures", "technical"],
        ["CE_SURV", "CE", "Surveying & Geomatics", "technical"],
        ["CE_FLUID", "CE", "Fluid Mechanics, Hydraulics & Irrigation", "technical"],
        ["CE_GEO", "CE", "Soil Mechanics & Geotechnical Engineering", "technical"],
        ["CE_TRANS", "CE", "Highway & Transportation Engineering", "technical"],
        ["CE_ENV", "CE", "Environmental & Sanitary Engineering", "technical"],
        ["EE_CKT", "EE", "Circuit Theory & Network Analysis", "technical"],
        ["EE_MACH", "EE", "Electrical Machines & Transformers", "technical"],
        ["EE_POWER", "EE", "Power Systems, Transmission & Protection", "technical"],
        ["EE_CTRL", "EE", "Control Systems & Instrumentation", "technical"],
        ["ME_THERM", "ME", "Thermodynamics & IC Engines", "technical"],
        ["ME_FLUID", "ME", "Fluid Mechanics & Hydraulic Machinery", "technical"],
        ["ME_MFG", "ME", "Manufacturing Science & Production Tech", "technical"],
        ["ME_TOM", "ME", "Theory of Machines & Machine Design", "technical"],
        ["CSE_PROG", "CSE", "Programming & Data Structures", "technical"],
        ["CSE_DBMS", "CSE", "Database Management Systems & SQL", "technical"],
        ["CSE_OS", "CSE", "Operating Systems & System Software", "technical"],
        ["CSE_NET", "CSE", "Computer Networks & Cybersecurity", "technical"],
        ["AGRI_AGRO", "AGRI", "Agronomy & Crop Production", "technical"],
        ["AGRI_SOIL", "AGRI", "Soil Science & Agricultural Chemistry", "technical"],
        ["AGRI_PATH", "AGRI", "Plant Pathology & Crop Protection", "technical"]
    ]
)

# Topics
r_row = write_reference_section(
    ws_ref, r_row, "5. COMMON TOPIC CODES (topic_code)",
    ["topic_code", "subject_code", "Topic Name", "Scope & Coverage"],
    [
        ["MATH-ARITH", "MATH", "Arithmetic & Commercial Math", "Percentage, Profit/Loss, Ratio, SI/CI, Time & Work"],
        ["MATH-NUM", "MATH", "Number System & Simplification", "BODMAS, Fractions, Decimals, Surds, LCM/HCF"],
        ["MATH-ALG", "MATH", "Algebra & Equations", "Linear/Quadratic equations, Factorization, Polynomials"],
        ["MATH-GEOM", "MATH", "Geometry & Mensuration", "2D/3D shapes, Triangles, Circles, Perimeter, Area, Volume"],
        ["MATH-TRIG", "MATH", "Trigonometry", "Identities, Heights & Distances, Standard angles"],
        ["ENG-VOCAB", "ENG", "Vocabulary & Word Power", "Synonyms, Antonyms, One-word substitutions, Spelling"],
        ["ENG-GRAM", "ENG", "Grammar & Usage", "Tenses, Prepositions, Voice, Narration, Articles"],
        ["ENG-COMP", "ENG", "Reading Comprehension", "Passage analysis, Inference, Title, Tone"],
        ["ENG-ERR", "ENG", "Spotting Errors", "Error detection, Sentence improvement, Cloze test"],
        ["GK-HIST", "GK", "Indian History", "Ancient, Medieval, Modern Freedom Movement"],
        ["GK-POL", "GK", "Polity & Constitution", "Preamble, Fundamental Rights, Parliament, Judiciary"],
        ["GK-GEOG", "GK", "Indian & World Geography", "Rivers, Physical relief, Climate, Minerals, Agriculture"],
        ["GK-ECON", "GK", "Indian Economy", "Five Year Plans, Budget, Inflation, Banking, GDP"],
        ["GK-SCI", "GK", "General Science", "Everyday Physics, Chemistry, Biology, Diseases"],
        ["APGK-HIST", "APGK", "Arunachal History", "NEFA, Statehood 1987, Historical monuments"],
        ["APGK-TRIB", "APGK", "Tribes & Festivals", "Nyishi, Adi, Galo, Apatani, Monpa, Mishmi, etc."],
        ["APGK-GEOG", "APGK", "Arunachal Geography", "Rivers (Siang, Subansiri), High passes (Sela, Bum La)"],
        ["REAS-VERB", "REAS", "Verbal Reasoning", "Series, Analogy, Coding, Blood relations, Direction"],
        ["REAS-NONVERB", "REAS", "Non-Verbal Reasoning", "Pattern completion, Paper folding, Mirror images"]
    ]
)

# Auto-adjust column widths on Code Reference sheet
for col in ws_ref.columns:
    max_len = max(len(str(cell.value or '')) for cell in col)
    col_letter = get_column_letter(col[0].column)
    ws_ref.column_dimensions[col_letter].width = max(max_len + 3, 14)

template_path = "scripts/templates/master_question_template.xlsx"
try:
    wb.save(template_path)
    print(f"Master question template successfully generated at: {template_path}")
except PermissionError:
    alt_path = "scripts/templates/master_question_taxonomy_template.xlsx"
    wb.save(alt_path)
    print(f"Notice: '{template_path}' is currently open in Excel. Saved to '{alt_path}' instead!")

