import os
import openpyxl
from openpyxl.styles import Font, PatternFill, Alignment, Border, Side
from openpyxl.utils import get_column_letter

os.makedirs('scripts/templates', exist_ok=True)
wb = openpyxl.Workbook()
ws = wb.active
ws.title = "Exam Questions"

# Columns definition
headers = [
    ("test_code", 16, "e.g. APSSB-CGLE-2024"),
    ("year", 8, "e.g. 2024"),
    ("paper_type", 12, "PYQ or MOCK"),
    ("subject", 20, "Elementary Maths, General Studies, etc."),
    ("topic", 18, "Optional topic (e.g. Percentage, Polity)"),
    ("question_num", 14, "Official question number (1, 2, 3...)"),
    ("group_code", 14, "e.g. PASSAGE_01 or DIR_01 (links questions)"),
    ("group_type", 14, "comprehension, direction, or data_interpretation"),
    ("direction", 30, "Instructions shared across questions"),
    ("passage_text", 40, "Reading comprehension text (paste once per group)"),
    ("passage_image", 20, "Filename for passage chart (e.g. di_chart.png)"),
    ("question_text", 45, "Main question prompt"),
    ("format", 12, "text, latex, or image_only"),
    ("question_image", 20, "Filename of figure/diagram in test_images/"),
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

# Header styling
header_font = Font(name="Segoe UI", size=11, bold=True, color="FFFFFF")
header_fill = PatternFill(start_color="1E3A8A", end_color="1E3A8A", fill_type="solid")
header_align = Alignment(horizontal="center", vertical="center", wrap_text=True)
thin_border = Border(
    left=Side(style='thin', color='CBD5E1'),
    right=Side(style='thin', color='CBD5E1'),
    top=Side(style='thin', color='CBD5E1'),
    bottom=Side(style='thin', color='CBD5E1')
)

ws.row_dimensions[1].height = 32

for col_idx, (col_name, width, _) in enumerate(headers, start=1):
    cell = ws.cell(row=1, column=col_idx, value=col_name)
    cell.font = header_font
    cell.fill = header_fill
    cell.alignment = header_align
    cell.border = thin_border
    ws.column_dimensions[get_column_letter(col_idx)].width = width

# Sample demonstration rows
sample_data = [
    # 1. Standard General Studies MCQ
    [
        "APSSB-CGLE-2024", 2024, "PYQ", "General Studies", "History", 1,
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
    # 2. Reading Comprehension (Question 1 of 2 linked to PASSAGE_01)
    [
        "APSSB-CGLE-2024", 2024, "PYQ", "General English", "Comprehension", 2,
        "PASSAGE_01", "comprehension", "",
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
    # 3. Reading Comprehension (Question 2 of 2 linked to PASSAGE_01)
    [
        "APSSB-CGLE-2024", 2024, "PYQ", "General English", "Comprehension", 3,
        "PASSAGE_01", "comprehension", "",
        "The climate of Arunachal Pradesh varies with elevation. The sub-Himalayan belt has a humid subtropical climate, while the higher elevations enjoy a cool alpine climate with heavy snow in winter.",
        "",
        "What type of weather is experienced in the higher elevations during winter?",
        "text", "",
        "Dust storms and droughts", "",
        "Extreme tropical rain", "",
        "Heavy snowfall and cool alpine weather", "",
        "High humidity and heatwaves", "",
        "c",
        "The passage states: 'while the higher elevations enjoy a cool alpine climate with heavy snow in winter.'",
        ""
    ],
    # 4. Direction Block (Question 1 of 2 linked to DIR_01)
    [
        "APSSB-CGLE-2024", 2024, "PYQ", "General English", "Vocabulary", 4,
        "DIR_01", "direction",
        "Directions (Q. 4 to 5): Choose the word most nearly OPPOSITE in meaning to the given word.",
        "", "",
        "BENEVOLENT",
        "text", "",
        "Generous", "",
        "Malevolent", "",
        "Charitable", "",
        "Affable", "",
        "b",
        "Benevolent means kind and well-meaning. Its direct antonym is Malevolent (ill-intentioned or spiteful).",
        ""
    ],
    # 5. Math Formula & Geometry Diagram Question
    [
        "APSSB-CGLE-2024", 2024, "PYQ", "Elementary Maths", "Geometry", 5,
        "", "", "", "", "",
        "In the given figure, if line AB is parallel to CD, find the value of angle x: $x = \\frac{180^\\circ - 40^\\circ}{2}$",
        "latex", "parallel_lines_q5.png",
        "50°", "",
        "70°", "",
        "90°", "",
        "110°", "",
        "b",
        "Since lines AB and CD are parallel, consecutive interior angles add up to 180°. Hence 2x + 40° = 180° => x = 70°.",
        "solution_proof_q5.png"
    ]
]

row_font = Font(name="Segoe UI", size=10)
row_align = Alignment(vertical="top", wrap_text=True)

for row_idx, data_row in enumerate(sample_data, start=2):
    ws.row_dimensions[row_idx].height = 55
    # Alternate row shading
    fill = PatternFill(start_color="F8FAFC", end_color="F8FAFC", fill_type="solid") if row_idx % 2 == 0 else PatternFill(fill_type=None)
    for col_idx, val in enumerate(data_row, start=1):
        cell = ws.cell(row=row_idx, column=col_idx, value=val)
        cell.font = row_font
        cell.alignment = row_align
        cell.border = thin_border
        if fill.fill_type:
            cell.fill = fill

# Save master workbook
out_path = "scripts/templates/master_question_template.xlsx"
wb.save(out_path)
print(f"Generated master template: {out_path}")
