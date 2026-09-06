class PyqPaperSpec {
  final String name;
  final String code;
  final int year;

  const PyqPaperSpec(
      {required this.name, required this.code, required this.year});
}

class QuizSpec {
  final String name;
  final String type;
  final String desc;

  const QuizSpec({required this.name, required this.type, required this.desc});
}

class ExamSpec {
  final String examId;
  final String code;
  final List<String> syllabusDetails;
  final List<PyqPaperSpec> pyqPapers;
  final List<QuizSpec> quizzes;

  const ExamSpec({
    required this.examId,
    required this.code,
    required this.syllabusDetails,
    required this.pyqPapers,
    required this.quizzes,
  });
}

class ExamSpecData {
  static ExamSpec getSpec(String examId, String examCode) {
    return _specs[examId] ??
        _specs[examCode.toLowerCase()] ??
        _defaultSpec(examCode);
  }

  static ExamSpec _defaultSpec(String code) {
    return ExamSpec(
      examId: code,
      code: code,
      syllabusDetails: [
        'Paper I: General English (Grammar, Vocabulary & Comprehension) — 100 Marks',
        'Paper II: General Knowledge & Arunachal Pradesh GK — 100 Marks',
        'Paper III: Subject / Domain Specialization — 100 Marks',
      ],
      pyqPapers: [
        PyqPaperSpec(name: '$code Solved Paper 2023', code: code, year: 2023),
        PyqPaperSpec(name: '$code Solved Paper 2021', code: code, year: 2021),
      ],
      quizzes: [
        const QuizSpec(
            name: 'Full-length Mock Test',
            type: 'full',
            desc: 'Full exam simulation with timer & ELO rating'),
        const QuizSpec(
            name: 'Topic Test: General English',
            type: 'topic_english',
            desc: 'Grammar and vocabulary questions'),
        const QuizSpec(
            name: 'Topic Test: General Knowledge',
            type: 'topic_gk',
            desc: 'Arunachal & National GK'),
      ],
    );
  }

  static final Map<String, ExamSpec> _specs = {
    // 1. APSSB CGL
    'apssb_cgl': const ExamSpec(
      examId: 'apssb_cgl',
      code: 'CGL',
      syllabusDetails: [
        'General English (50 Marks / 25 Qs): Grammar, Vocabulary, Idioms, Comprehension',
        'Elementary Mathematics (50 Marks / 25 Qs): Arithmetic, Percentage, Algebra, Mensuration',
        'General Knowledge (50 Marks / 25 Qs): Arunachal Profile, History, Polity, Current Affairs',
        'Basic Computer & Reasoning (50 Marks / 25 Qs): Logical Reasoning, IT Fundamentals',
      ],
      pyqPapers: [
        PyqPaperSpec(
            name: 'APSSB CGL 2023 Solved Paper', code: 'CGL', year: 2023),
        PyqPaperSpec(
            name: 'APSSB CGL 2021 Solved Paper', code: 'CGL', year: 2021),
      ],
      quizzes: [
        QuizSpec(
            name: 'Full APSSB CGL Mock Test',
            type: 'full',
            desc: 'Combined Graduate Level 10-question timed exam'),
        QuizSpec(
            name: 'Topic Test: Elementary Mathematics',
            type: 'topic_math',
            desc: 'Arithmetic, Profit & Loss, Geometry'),
        QuizSpec(
            name: 'Topic Test: General English',
            type: 'topic_english',
            desc: 'Grammar, Synonyms, Cloze Test'),
        QuizSpec(
            name: 'Topic Test: General Knowledge & Arunachal GK',
            type: 'topic_gk',
            desc: 'State history, geography & administration'),
      ],
    ),

    // 2. APSSB CHSL
    'apssb_chsl': const ExamSpec(
      examId: 'apssb_chsl',
      code: 'CHSL',
      syllabusDetails: [
        'General English (100 Marks / 50 Qs): Spotting Errors, Fill in Blanks, Synonyms/Antonyms, One-word Substitution',
        'Elementary Mathematics (100 Marks / 50 Qs): Number Systems, Ratio & Proportion, Average, Time & Work',
        'General Knowledge (100 Marks / 50 Qs): Arunachal Pradesh History, Geography, Indian Constitution, General Science',
      ],
      pyqPapers: [
        PyqPaperSpec(
            name: 'APSSB CHSL 2023 Solved Paper', code: 'CHSL', year: 2023),
        PyqPaperSpec(
            name: 'APSSB CHSL 2021 Solved Paper', code: 'CHSL', year: 2021),
      ],
      quizzes: [
        QuizSpec(
            name: 'Full APSSB CHSL Mock Test',
            type: 'full',
            desc: 'Combined Higher Secondary Level 10+2 mock test'),
        QuizSpec(
            name: 'Topic Test: English Language',
            type: 'topic_english',
            desc: '10+2 Level Grammar & Vocabulary'),
        QuizSpec(
            name: 'Topic Test: Elementary Mathematics',
            type: 'topic_math',
            desc: 'Arithmetic & Numerical Ability'),
        QuizSpec(
            name: 'Topic Test: General Knowledge',
            type: 'topic_gk',
            desc: 'State GK & Current Affairs'),
      ],
    ),

    // 3. APSSB CSCE / CSLE
    'apssb_csce': const ExamSpec(
      examId: 'apssb_csce',
      code: 'CSCE',
      syllabusDetails: [
        'General English (100 Marks / 50 Qs): Sentence Structure, Spelling Test, Basic Grammar',
        'Elementary Mathematics (100 Marks / 50 Qs): Basic Calculations, Decimals, Fractions, Percentage',
        'General Knowledge (100 Marks / 50 Qs): Arunachal State Basics, Sports, National Symbols, Everyday Science',
      ],
      pyqPapers: [
        PyqPaperSpec(
            name: 'APSSB CSLE/CSCE 2023 Solved Paper',
            code: 'CSCE',
            year: 2023),
        PyqPaperSpec(
            name: 'APSSB CSLE 2021 Solved Paper', code: 'CSCE', year: 2021),
      ],
      quizzes: [
        QuizSpec(
            name: 'Full APSSB CSLE Mock Test',
            type: 'full',
            desc: 'Combined Secondary Cadre Exam for Constable/Fireman'),
        QuizSpec(
            name: 'Topic Test: Basic Numerical Ability',
            type: 'topic_math',
            desc: '10th Level Arithmetic'),
        QuizSpec(
            name: 'Topic Test: General Awareness',
            type: 'topic_gk',
            desc: 'Arunachal Culture & State Profile'),
      ],
    ),

    // 4. APSSB UDC
    'apssb_udc': const ExamSpec(
      examId: 'apssb_udc',
      code: 'UDC',
      syllabusDetails: [
        'General English (100 Marks): Advanced Grammar, Precis Writing, Essay, Comprehension',
        'Elementary Mathematics (100 Marks): Data Interpretation, Quantitative Aptitude, Mensuration',
        'General Knowledge (100 Marks): Indian Governance, Economy, Arunachal Pradesh GK, Current Events',
      ],
      pyqPapers: [
        PyqPaperSpec(
            name: 'APSSB UDC 2019 Solved Paper', code: 'UDC', year: 2019),
        PyqPaperSpec(
            name: 'APSSB UDC 2021 Solved Paper', code: 'UDC', year: 2021),
      ],
      quizzes: [
        QuizSpec(
            name: 'Full APSSB UDC Mock Test',
            type: 'full',
            desc: 'Upper Division Clerk 10-question timed exam'),
        QuizSpec(
            name: 'Topic Test: Advanced Quantitative Aptitude',
            type: 'topic_math',
            desc: 'Maths & Data Interpretation'),
        QuizSpec(
            name: 'Topic Test: English Comprehension',
            type: 'topic_english',
            desc: 'Advanced Grammar & Precis Topics'),
      ],
    ),

    // 5. APSSB MTS
    'apssb_mts': const ExamSpec(
      examId: 'apssb_mts',
      code: 'MTS',
      syllabusDetails: [
        'General English (100 Marks): Basic Reading, Grammar, Spelling, Simple Vocabulary',
        'Elementary Mathematics (100 Marks): Addition, Subtraction, Multiplication, Fractions, Percentage',
        'General Knowledge (100 Marks): Arunachal State Symbols, Districts, Culture & General Science',
      ],
      pyqPapers: [
        PyqPaperSpec(
            name: 'APSSB MTS 2022 Solved Paper', code: 'MTS', year: 2022),
        PyqPaperSpec(
            name: 'APSSB MTS 2020 Solved Paper', code: 'MTS', year: 2020),
      ],
      quizzes: [
        QuizSpec(
            name: 'Full APSSB MTS Mock Test',
            type: 'full',
            desc: 'Multi Tasking Staff 10th Level Mock Test'),
        QuizSpec(
            name: 'Topic Test: Basic Mathematics',
            type: 'topic_math',
            desc: 'Simple Arithmetic & Calculations'),
        QuizSpec(
            name: 'Topic Test: General Awareness',
            type: 'topic_gk',
            desc: 'Basic State GK & Science'),
      ],
    ),

    // 6. APPSC APCS (Civil Services)
    'appsc_apcs': const ExamSpec(
      examId: 'appsc_apcs',
      code: 'APCS',
      syllabusDetails: [
        'Prelims Paper I: General Studies (200 Marks) — History, Geography, Indian Polity, Economy, Environment & Arunachal GK',
        'Prelims Paper II: CSAT (200 Marks) — Comprehension, Logical Reasoning, Decision Making, Basic Numeracy',
        'Mains Written: General English (300m), General Studies I-IV (250m each), Optional Subject Papers',
      ],
      pyqPapers: [
        PyqPaperSpec(
            name: 'APCS Prelims 2022 Solved Paper', code: 'APCS', year: 2022),
        PyqPaperSpec(
            name: 'APCS Prelims 2020 Solved Paper', code: 'APCS', year: 2020),
      ],
      quizzes: [
        QuizSpec(
            name: 'APCS Prelims Full GS Mock',
            type: 'full',
            desc: 'General Studies Paper 1 Simulation'),
        QuizSpec(
            name: 'CSAT Paper II Practice Test',
            type: 'csat',
            desc: 'Logical Reasoning & Analytical Ability'),
        QuizSpec(
            name: 'Special Test: Arunachal Pradesh GS',
            type: 'topic_arunachal',
            desc: 'Tribes, Customary Laws, History & Administration'),
      ],
    ),

    // 7. APPSC AE (Assistant Engineer)
    'appsc_ae': const ExamSpec(
      examId: 'appsc_ae',
      code: 'AE',
      syllabusDetails: [
        'Part A (Non-Technical): General English (100 Marks) & General Knowledge (100 Marks)',
        'Part B (Technical Core - Civil/Elec/Mech): Engineering Mechanics, Strength of Materials, Structural Analysis (200 Marks)',
        'Fluid Mechanics, Hydraulics, Soil Mechanics, Building Construction & Surveying (Technical)',
      ],
      pyqPapers: [
        PyqPaperSpec(
            name: 'APPSC AE Civil 2022 Solved Paper', code: 'AE', year: 2022),
        PyqPaperSpec(
            name: 'APPSC AE Electrical 2021 Solved Paper',
            code: 'AE',
            year: 2021),
      ],
      quizzes: [
        QuizSpec(
            name: 'Full APPSC AE Engineering Mock',
            type: 'full',
            desc: 'Complete Technical + Non-Technical 10-Q Test'),
        QuizSpec(
            name: 'Technical Core: Civil / Electrical Engineering',
            type: 'technical_eng',
            desc: 'Mechanics, Hydraulics & Structures'),
        QuizSpec(
            name: 'Non-Technical: General English & GK',
            type: 'non_tech',
            desc: 'English & Arunachal GK Paper'),
      ],
    ),

    // 8. APPSC JE (Junior Engineer)
    'appsc_je': const ExamSpec(
      examId: 'appsc_je',
      code: 'JE',
      syllabusDetails: [
        'Part A (Non-Technical): General English (100 Marks) & General Knowledge (100 Marks)',
        'Part B (Technical Diploma Level): Building Materials, Surveying, Hydraulics, Estimating & Costing (200 Marks)',
        'Concrete Technology, RCC Structures, Highway Engineering & Soil Mechanics',
      ],
      pyqPapers: [
        PyqPaperSpec(
            name: 'APPSC JE Civil 2023 Solved Paper', code: 'JE', year: 2023),
        PyqPaperSpec(
            name: 'APPSC JE Electrical 2021 Solved Paper',
            code: 'JE',
            year: 2021),
      ],
      quizzes: [
        QuizSpec(
            name: 'Full APPSC JE Mock Test',
            type: 'full',
            desc: 'Junior Engineer Diploma-level Mock Test'),
        QuizSpec(
            name: 'Technical Module: Civil / Electrical Diploma',
            type: 'technical_je',
            desc: 'Surveying, Hydraulics & Estimating'),
        QuizSpec(
            name: 'Non-Technical Module: English & State GK',
            type: 'non_tech',
            desc: 'General English & Arunachal Profile'),
      ],
    ),

    // 9. APPSC ADO (Agriculture Development Officer)
    'appsc_ado': const ExamSpec(
      examId: 'appsc_ado',
      code: 'ADO',
      syllabusDetails: [
        'Paper I (Non-Tech): General English (100 Marks) & General Knowledge (100 Marks)',
        'Paper II (Technical Agriculture): Agronomy, Soil Science, Agricultural Chemistry (100 Marks)',
        'Paper III: Plant Pathology, Horticulture, Agricultural Economics & Extension Education (100 Marks)',
      ],
      pyqPapers: [
        PyqPaperSpec(
            name: 'APPSC ADO 2022 Solved Paper', code: 'ADO', year: 2022),
        PyqPaperSpec(
            name: 'APPSC ADO 2019 Solved Paper', code: 'ADO', year: 2019),
      ],
      quizzes: [
        QuizSpec(
            name: 'Full APPSC ADO Agriculture Mock',
            type: 'full',
            desc: 'Complete ADO Technical & Non-Tech Test'),
        QuizSpec(
            name: 'Technical Module: Agronomy & Soil Science',
            type: 'technical_agri',
            desc: 'Crops, Soil Fertility & Irrigation'),
        QuizSpec(
            name: 'Non-Tech Module: English & General Awareness',
            type: 'non_tech',
            desc: 'General English & State GK'),
      ],
    ),

    // 10. APPSC HDO (Horticulture Development Officer)
    'appsc_hdo': const ExamSpec(
      examId: 'appsc_hdo',
      code: 'HDO',
      syllabusDetails: [
        'Paper I (Non-Tech): General English (100 Marks) & General Knowledge (100 Marks)',
        'Paper II (Technical Horticulture): Pomology (Fruit Science), Olericulture (Vegetable Science) (100 Marks)',
        'Paper III: Floriculture, Post-Harvest Technology, Spices & Medicinal Plants (100 Marks)',
      ],
      pyqPapers: [
        PyqPaperSpec(
            name: 'APPSC HDO 2022 Solved Paper', code: 'HDO', year: 2022),
        PyqPaperSpec(
            name: 'APPSC HDO 2020 Solved Paper', code: 'HDO', year: 2020),
      ],
      quizzes: [
        QuizSpec(
            name: 'Full APPSC HDO Horticulture Mock',
            type: 'full',
            desc: 'Complete HDO Technical Mock Test'),
        QuizSpec(
            name: 'Technical Module: Pomology & Fruit Science',
            type: 'technical_horti',
            desc: 'Fruit Crops, Nursery & Post-Harvest'),
        QuizSpec(
            name: 'Non-Tech Module: English & GK',
            type: 'non_tech',
            desc: 'General English & GK'),
      ],
    ),

    // 11. APPSC FAO (Financial Advisory Officer)
    'appsc_fao': const ExamSpec(
      examId: 'appsc_fao',
      code: 'FAO',
      syllabusDetails: [
        'Paper I (Non-Tech): General English (100 Marks) & General Knowledge (100 Marks)',
        'Paper II (Finance & Accounting): Financial Management, Corporate Accounting, Auditing (100 Marks)',
        'Paper III: Commercial Laws, Taxation, Public Finance & Treasury Rules (100 Marks)',
      ],
      pyqPapers: [
        PyqPaperSpec(
            name: 'APPSC FAO 2021 Solved Paper', code: 'FAO', year: 2021),
      ],
      quizzes: [
        QuizSpec(
            name: 'Full APPSC FAO Finance Mock',
            type: 'full',
            desc: 'Financial Advisory Officer Full Mock'),
        QuizSpec(
            name: 'Technical Module: Accounting & Auditing',
            type: 'technical_finance',
            desc: 'Financial Management & Corporate Accounting'),
        QuizSpec(
            name: 'Non-Tech Module: English & GK',
            type: 'non_tech',
            desc: 'General English & General Awareness'),
      ],
    ),

    // 12. APPSC PGT
    'appsc_pgt': const ExamSpec(
      examId: 'appsc_pgt',
      code: 'PGT',
      syllabusDetails: [
        'Paper I: General English (100 Marks)',
        'Paper II: General Knowledge & Educational Pedagogy / Child Psychology (100 Marks)',
        'Paper III: Post-Graduate Level Subject Specialization (200 Marks)',
      ],
      pyqPapers: [
        PyqPaperSpec(
            name: 'APPSC PGT 2022 Solved Paper', code: 'PGT', year: 2022),
      ],
      quizzes: [
        QuizSpec(
            name: 'Full APPSC PGT Teacher Mock',
            type: 'full',
            desc: 'Post Graduate Teacher Combined Test'),
        QuizSpec(
            name: 'Pedagogy & Teaching Methodology',
            type: 'pedagogy',
            desc: 'Child Psychology & Teaching Methods'),
        QuizSpec(
            name: 'General English & GK',
            type: 'non_tech',
            desc: 'Language Proficiency & State GK'),
      ],
    ),

    // 13. APPSC TGT
    'appsc_tgt': const ExamSpec(
      examId: 'appsc_tgt',
      code: 'TGT',
      syllabusDetails: [
        'Paper I: General English (100 Marks)',
        'Paper II: General Knowledge & Teaching Aptitude (100 Marks)',
        'Paper III: Graduate Level Concerned Subject (200 Marks)',
      ],
      pyqPapers: [
        PyqPaperSpec(
            name: 'APPSC TGT 2021 Solved Paper', code: 'TGT', year: 2021),
      ],
      quizzes: [
        QuizSpec(
            name: 'Full APPSC TGT Mock Test',
            type: 'full',
            desc: 'Trained Graduate Teacher Mock'),
        QuizSpec(
            name: 'Teaching Aptitude & Classroom Management',
            type: 'pedagogy',
            desc: 'Pedagogy & Education Principles'),
        QuizSpec(
            name: 'General English & GK',
            type: 'non_tech',
            desc: 'English Grammar & General Awareness'),
      ],
    ),

    // 14. APPSC Assistant Public Prosecutor
    'appsc_prosecutor': const ExamSpec(
      examId: 'appsc_prosecutor',
      code: 'Asnt Public Prosecutor Examination',
      syllabusDetails: [
        'Paper I: General English (100 Marks) & General Knowledge (100 Marks)',
        'Paper II (Law - Part 1): Indian Penal Code (IPC), Code of Criminal Procedure (CrPC) (100 Marks)',
        'Paper III (Law - Part 2): Indian Evidence Act, Constitutional Law & Local Acts (100 Marks)',
      ],
      pyqPapers: [
        PyqPaperSpec(
            name: 'APPSC APP Law 2021 Solved Paper', code: 'APP', year: 2021),
      ],
      quizzes: [
        QuizSpec(
            name: 'Full Assistant Public Prosecutor Mock',
            type: 'full',
            desc: 'Complete Criminal Law & General Test'),
        QuizSpec(
            name: 'Law Special: Criminal Law & Evidence Act',
            type: 'technical_law',
            desc: 'IPC, CrPC & Indian Evidence Act'),
        QuizSpec(
            name: 'Non-Tech: English & Arunachal GK',
            type: 'non_tech',
            desc: 'General English & State Profile'),
      ],
    ),
  };
}
