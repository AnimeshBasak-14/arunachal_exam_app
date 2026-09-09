// Official Syllabus & Exam Pattern Repository for Arunachal Pradesh Examinations
// Comprehensive data for APSSB (Staff Selection Board) & APPSC (Public Service Commission)

class ExecutiveOverviewItem {
  final String parameter;
  final String apssb;
  final String appsc;
  final String? note;

  const ExecutiveOverviewItem({
    required this.parameter,
    required this.apssb,
    required this.appsc,
    this.note,
  });
}

class ApssbSyllabusSection {
  final String examName;
  final String targetCadres;
  final String stage;
  final String subject;
  final int? questions;
  final int? marks;
  final String duration;
  final String markingStandard;
  final String syllabusBreakdown;
  final bool isSkillTest;

  const ApssbSyllabusSection({
    required this.examName,
    required this.targetCadres,
    required this.stage,
    required this.subject,
    this.questions,
    this.marks,
    required this.duration,
    required this.markingStandard,
    required this.syllabusBreakdown,
    this.isSkillTest = false,
  });
}

class AppscSyllabusSection {
  final String examName;
  final String targetCadres;
  final String stage;
  final String paperName;
  final int marks;
  final String duration;
  final String negativeMarking;
  final String primaryCurriculum;
  final String arunachalComponent;
  final String weightageImpact;
  final bool isInterview;

  const AppscSyllabusSection({
    required this.examName,
    required this.targetCadres,
    required this.stage,
    required this.paperName,
    required this.marks,
    required this.duration,
    required this.negativeMarking,
    required this.primaryCurriculum,
    required this.arunachalComponent,
    required this.weightageImpact,
    this.isInterview = false,
  });
}

class SubjectMatrixItem {
  final String category;
  final String subTopic;
  final String coreCurriculum;
  final String apssbScope;
  final String appscScope;
  final String typicalWeightage;
  final String highYieldFocus;

  const SubjectMatrixItem({
    required this.category,
    required this.subTopic,
    required this.coreCurriculum,
    required this.apssbScope,
    required this.appscScope,
    required this.typicalWeightage,
    required this.highYieldFocus,
  });
}

class OfficialSyllabusData {
  // ---------------------------------------------------------------------------
  // 1. COMPARATIVE EXECUTIVE OVERVIEW
  // ---------------------------------------------------------------------------
  static const List<ExecutiveOverviewItem> executiveOverview = [
    ExecutiveOverviewItem(
      parameter: 'Commission / Board',
      apssb: 'Arunachal Pradesh Staff Selection Board (APSSB)',
      appsc: 'Arunachal Pradesh Public Service Commission (APPSC)',
      note: 'Constitutional vs Statutory Body',
    ),
    ExecutiveOverviewItem(
      parameter: 'Legal / Mandate',
      apssb: 'Constituted under APSSB Act 2018 for meritocratic Group C recruitment',
      appsc: 'State Public Service Commission established under Article 315 of Indian Constitution',
    ),
    ExecutiveOverviewItem(
      parameter: 'Recruitment Jurisdictions',
      apssb: "Group 'C' (Ministerial, Technical, Uniformed Police/Forest/Fire, Non-Ministerial)",
      appsc: "Group 'A' & Group 'B' (Gazetted & Non-Gazetted Administrative, Technical, Medical, Academic)",
    ),
    ExecutiveOverviewItem(
      parameter: 'Key Flagship Examinations',
      apssb: 'CGL, CHSL, CSL (MTS), Uniformed Cadre (Constable/Fireman), Combined Technical',
      appsc: 'APPSCCE (Civil Services), AESE (AE Civil/EE/ME), JE Common, TGT/PGT, ADO/HDO, GDMO',
    ),
    ExecutiveOverviewItem(
      parameter: 'Negative Marking Policy',
      apssb: 'Strictly NO Negative Marking in standard Objective Tests (2 marks/correct answer)',
      appsc: '1/3rd (0.33) Negative Marking in Prelims & Screening Tests; Descriptive evaluation in Mains',
      note: 'Crucial distinction for exam strategy',
    ),
    ExecutiveOverviewItem(
      parameter: 'Standard Test Duration',
      apssb: '2 Hours (120 min) for 100 MCQs / 200 Marks (3 Hours for specialized technical)',
      appsc: 'Prelims: 2 Hours per paper (100 Qs); Mains: 3 Hours descriptive per subject paper',
    ),
    ExecutiveOverviewItem(
      parameter: 'Minimum Qualifying Cutoff',
      apssb: '33% aggregate marks across written stages (plus passing requisite skill tests)',
      appsc: '33% per paper & 40%-45% aggregate in written descriptive exams + Personality Test',
    ),
    ExecutiveOverviewItem(
      parameter: 'Official Web Portals',
      apssb: 'https://apssb.nic.in',
      appsc: 'https://appsc.gov.in',
    ),
  ];

  // ---------------------------------------------------------------------------
  // 2. APSSB SYLLABUS SECTIONS
  // ---------------------------------------------------------------------------
  static const List<ApssbSyllabusSection> apssbSections = [
    // CGL
    ApssbSyllabusSection(
      examName: 'Combined Graduate Level (CGL)',
      targetCadres: 'Upper Division Clerk (UDC), Auditor, Inspector, Personal Assistant (Steno Gr-III)',
      stage: 'Stage 1: Written Examination (OMR)',
      subject: 'General Awareness',
      questions: 25,
      marks: 50,
      duration: '2 Hours (Total Exam)',
      markingStandard: '2 marks/Q, No Negative Marking; 33% Aggregate Pass',
      syllabusBreakdown:
          'Current Events (National/International), Indian History, Culture, Geography, Indian Polity, Constitution, Indian Economy, Everyday Science, Scientific Research, National & International Organizations, Awards & Honors, and Arunachal Pradesh GK (Tribes, Geography, Administration, Festivals, State Symbols).',
    ),
    ApssbSyllabusSection(
      examName: 'Combined Graduate Level (CGL)',
      targetCadres: 'Upper Division Clerk (UDC), Auditor, Inspector, Personal Assistant (Steno Gr-III)',
      stage: 'Stage 1: Written Examination (OMR)',
      subject: 'General Intelligence & Reasoning Ability',
      questions: 25,
      marks: 50,
      duration: '2 Hours (Total Exam)',
      markingStandard: '2 marks/Q, No Negative Marking; 33% Aggregate Pass',
      syllabusBreakdown:
          'Analogies, Similarities and Differences, Space Visualization, Problem Solving, Analysis, Judgment, Decision Making, Visual Memory, Discrimination, Observation, Relationship Concepts, Arithmetical Reasoning, Verbal and Figure Classification, Arithmetical Number Series, Coding-Decoding, Non-verbal series.',
    ),
    ApssbSyllabusSection(
      examName: 'Combined Graduate Level (CGL)',
      targetCadres: 'Upper Division Clerk (UDC), Auditor, Inspector, Personal Assistant (Steno Gr-III)',
      stage: 'Stage 1: Written Examination (OMR)',
      subject: 'Arithmetical & Numerical Ability',
      questions: 25,
      marks: 50,
      duration: '2 Hours (Total Exam)',
      markingStandard: '2 marks/Q, No Negative Marking; 33% Aggregate Pass',
      syllabusBreakdown:
          'Number System (Fractions, Decimals), LCM & HCF, Ratio & Proportion, Percentage, Averages, Profit & Loss, Discount, Simple & Compound Interest, Mensuration (2D/3D shapes), Time & Work, Time & Distance, Tables & Graphs, Basic Algebra & Linear Equations, Elementary Data Interpretation (Bar, Pie).',
    ),
    ApssbSyllabusSection(
      examName: 'Combined Graduate Level (CGL)',
      targetCadres: 'Upper Division Clerk (UDC), Auditor, Inspector, Personal Assistant (Steno Gr-III)',
      stage: 'Stage 1: Written Examination (OMR)',
      subject: 'Test of English Language & Comprehension',
      questions: 25,
      marks: 50,
      duration: '2 Hours (Total Exam)',
      markingStandard: '2 marks/Q, No Negative Marking; 33% Aggregate Pass',
      syllabusBreakdown:
          'Spotting Errors, Fill in the Blanks (Prepositions, Articles, Tenses), Synonyms and Antonyms, Spellings / Detecting Misspelled Words, Idioms & Phrases, One Word Substitution, Sentence Improvement, Active & Passive Voice, Direct & Indirect Speech, Shuffling of Sentence Parts, Comprehension Passage.',
    ),
    ApssbSyllabusSection(
      examName: 'Combined Graduate Level (CGL)',
      targetCadres: 'UDC / Personal Assistant (Stenographer Gr-III)',
      stage: 'Stage 2: Skill / Proficiency Test',
      subject: 'Basic Computer Application / Stenography Test',
      duration: 'Varies',
      markingStandard: 'Qualifying Only (Must secure minimum prescribed standard)',
      syllabusBreakdown:
          'For UDC: Basic Computer Application Certificate Test (Word Processing, Spreadsheets, Presentation, Internet Navigation). For Stenographer: Dictation at 80 w.p.m. for 5 minutes, Transcription in 45 minutes on Computer.',
      isSkillTest: true,
    ),

    // CHSL
    ApssbSyllabusSection(
      examName: 'Combined Higher Secondary Level (CHSL)',
      targetCadres: 'Lower Division Clerk (LDC), Junior Secretariat Assistant (JSA), Data Entry Operator (DEO), Agri Field Asst (Jr), Fishery Demonstrator, Stockman',
      stage: 'Stage 1: Written Examination (OMR)',
      subject: 'General Awareness',
      questions: 25,
      marks: 50,
      duration: '2 Hours (Total Exam)',
      markingStandard: '2 marks/Q, No Negative Marking; 33% Aggregate Pass',
      syllabusBreakdown:
          'Current Affairs of National and International importance, Indian Polity and Constitution, Indian History & Culture, Physical and Political Geography of India, General Science (Class 10 level), Basic Economic concepts, and Arunachal Pradesh History, Geography, Culture, Flora, Fauna, Demography.',
    ),
    ApssbSyllabusSection(
      examName: 'Combined Higher Secondary Level (CHSL)',
      targetCadres: 'LDC, JSA, DEO, Field Assistants',
      stage: 'Stage 1: Written Examination (OMR)',
      subject: 'General Intelligence & Reasoning Ability',
      questions: 25,
      marks: 50,
      duration: '2 Hours (Total Exam)',
      markingStandard: '2 marks/Q, No Negative Marking; 33% Aggregate Pass',
      syllabusBreakdown:
          'Verbal and Non-verbal reasoning, Series completion (Alphabet, Number), Pattern recognition, Coding-Decoding, Blood Relations, Direction Sense Test, Venn diagrams, Syllogisms, Figural series, Paper folding, Cube & Dice, Embedded figures, Statement & Conclusion.',
    ),
    ApssbSyllabusSection(
      examName: 'Combined Higher Secondary Level (CHSL)',
      targetCadres: 'LDC, JSA, DEO, Field Assistants',
      stage: 'Stage 1: Written Examination (OMR)',
      subject: 'Arithmetical & Numerical Ability',
      questions: 25,
      marks: 50,
      duration: '2 Hours (Total Exam)',
      markingStandard: '2 marks/Q, No Negative Marking; 33% Aggregate Pass',
      syllabusBreakdown:
          'Number systems, Simplification, Fractions, Decimals, Square Roots, LCM & HCF, Ratio & Proportion, Percentage, Averages, Profit and Loss, Simple Interest and Compound Interest, Time and Work, Pipes & Cisterns, Speed, Time and Distance, Perimeter and Area of basic geometrical figures.',
    ),
    ApssbSyllabusSection(
      examName: 'Combined Higher Secondary Level (CHSL)',
      targetCadres: 'LDC, JSA, DEO, Field Assistants',
      stage: 'Stage 1: Written Examination (OMR)',
      subject: 'Test of English Language & Comprehension',
      questions: 25,
      marks: 50,
      duration: '2 Hours (Total Exam)',
      markingStandard: '2 marks/Q, No Negative Marking; 33% Aggregate Pass',
      syllabusBreakdown:
          'Grammar rules, Parts of Speech, Vocabulary, Error Recognition, Fill in the blanks with correct verbs/prepositions, Synonyms & Antonyms, Sentence Correction/Improvement, Common Idioms, One-word substitutes, Cloze test, Short reading comprehension passages.',
    ),
    ApssbSyllabusSection(
      examName: 'Combined Higher Secondary Level (CHSL)',
      targetCadres: 'LDC, JSA, Data Entry Operator (DEO)',
      stage: 'Stage 2: Skill Test',
      subject: 'Typing Speed Test (Computer)',
      duration: '10 Minutes',
      markingStandard: 'Minimum 35 w.p.m. in English on Computer (Qualifying)',
      syllabusBreakdown:
          'Typing test on computer keyboard with speed of minimum 35 words per minute (wpm) in English (equivalent to 10,500 key depressions per hour). Purely qualifying in nature.',
      isSkillTest: true,
    ),

    // CSL / MTS
    ApssbSyllabusSection(
      examName: 'Combined Secondary Level (CSL / MTS)',
      targetCadres: 'Multi-Tasking Staff (MTS), Peon, Chowkidar, Daftry, Sweeper, Driver',
      stage: 'Stage 1: Written Examination (OMR)',
      subject: 'General Awareness',
      questions: 25,
      marks: 50,
      duration: '2 Hours (Total Exam)',
      markingStandard: '2 marks/Q, No Negative Marking; 33% Aggregate Pass',
      syllabusBreakdown:
          'Matriculation level questions: Everyday Science, Current Events, Indian History, National Movement, Geography of India and Arunachal Pradesh, Indian Constitution, Sports, Important Days, State symbols and heritage of Arunachal Pradesh.',
    ),
    ApssbSyllabusSection(
      examName: 'Combined Secondary Level (CSL / MTS)',
      targetCadres: 'MTS, Peon, Chowkidar, Driver',
      stage: 'Stage 1: Written Examination (OMR)',
      subject: 'Elementary Mathematics',
      questions: 25,
      marks: 50,
      duration: '2 Hours (Total Exam)',
      markingStandard: '2 marks/Q, No Negative Marking; 33% Aggregate Pass',
      syllabusBreakdown:
          'Class 10 Matric standard: Whole numbers, Decimals and fractions, Basic operations (BODMAS), Percentages, Ratio and Proportion, Averages, Simple Interest, Profit & Loss, Work & Time, Distance & Time, Mensuration (Area and perimeter of square, rectangle, triangle).',
    ),
    ApssbSyllabusSection(
      examName: 'Combined Secondary Level (CSL / MTS)',
      targetCadres: 'MTS, Peon, Chowkidar, Driver',
      stage: 'Stage 1: Written Examination (OMR)',
      subject: 'General English',
      questions: 25,
      marks: 50,
      duration: '2 Hours (Total Exam)',
      markingStandard: '2 marks/Q, No Negative Marking; 33% Aggregate Pass',
      syllabusBreakdown:
          'Basic English grammar: Articles, Prepositions, Tenses, Subject-Verb Agreement, Vocabulary, Antonyms and Synonyms, Correct spelling of words, Sentence ordering, Basic comprehension questions.',
    ),
    ApssbSyllabusSection(
      examName: 'Combined Secondary Level (CSL / MTS)',
      targetCadres: 'MTS, Peon, Chowkidar, Driver',
      stage: 'Stage 1: Written Examination (OMR)',
      subject: 'General Intelligence & Reasoning',
      questions: 25,
      marks: 50,
      duration: '2 Hours (Total Exam)',
      markingStandard: '2 marks/Q, No Negative Marking; 33% Aggregate Pass',
      syllabusBreakdown:
          'Basic logical reasoning: Odd one out, Series completion, Simple analogy, Coding & Decoding, Direction test, Order and Ranking, Visual pattern matching, Simple family tree relationships.',
    ),
    ApssbSyllabusSection(
      examName: 'Combined Secondary Level (CSL / MTS)',
      targetCadres: 'Heavy / Light Motor Vehicle Driver',
      stage: 'Stage 2: Skill / Driving Test',
      subject: 'Driving & Technical Trade Test',
      duration: 'Practical Evaluation',
      markingStandard: 'Proficiency Test (Qualifying)',
      syllabusBreakdown:
          'For Driver posts: Practical driving test on designated vehicle, traffic rules, vehicle maintenance, road signs, and trouble shooting.',
      isSkillTest: true,
    ),

    // Uniformed Cadre
    ApssbSyllabusSection(
      examName: 'Uniformed Cadre Examination',
      targetCadres: 'Constable (Civil Police), Constable (IRBn), Fireman, Forest Guard, STPF Guard',
      stage: 'Stage 1: Physical Efficiency & Measurement Test (PST/PET)',
      subject: 'Physical Fitness Standards',
      duration: 'Field Test',
      markingStandard: 'Qualifying Only (Mandatory gate to written test)',
      syllabusBreakdown:
          'Height & Chest measurements as per Arunachal Police / Forest norms. PET: 1500m race (men) / 800m race (women), Long Jump, High Jump, 100m sprint. Chin-ups / Push-ups where applicable. Must qualify to sit for Written Examination.',
      isSkillTest: true,
    ),
    ApssbSyllabusSection(
      examName: 'Uniformed Cadre Examination',
      targetCadres: 'Constable (Civil Police/IRBn), Fireman, Forest Guard',
      stage: 'Stage 2: Written Examination (OMR)',
      subject: 'General Knowledge & Arunachal Pradesh',
      questions: 25,
      marks: 50,
      duration: '2 Hours (Total Exam)',
      markingStandard: '2 marks/Q, No Negative Marking; 33% Aggregate Pass',
      syllabusBreakdown:
          'State Profile of Arunachal Pradesh, North-East geography & tribes, Indian History, Indian Polity, Current Affairs, Science in everyday life, Sports, National Parks and Wildlife Sanctuaries of Arunachal Pradesh.',
    ),
    ApssbSyllabusSection(
      examName: 'Uniformed Cadre Examination',
      targetCadres: 'Constable, Fireman, Forest Guard',
      stage: 'Stage 2: Written Examination (OMR)',
      subject: 'Elementary Mathematics',
      questions: 25,
      marks: 50,
      duration: '2 Hours (Total Exam)',
      markingStandard: '2 marks/Q, No Negative Marking; 33% Aggregate Pass',
      syllabusBreakdown:
          'Arithmetic calculations, Number systems, HCF/LCM, Percentages, Profit and Loss, Ratio and Proportion, Time and Work, Speed and Distance, Simple Interest, Basic geometry and perimeter.',
    ),
    ApssbSyllabusSection(
      examName: 'Uniformed Cadre Examination',
      targetCadres: 'Constable, Fireman, Forest Guard',
      stage: 'Stage 2: Written Examination (OMR)',
      subject: 'General English',
      questions: 25,
      marks: 50,
      duration: '2 Hours (Total Exam)',
      markingStandard: '2 marks/Q, No Negative Marking; 33% Aggregate Pass',
      syllabusBreakdown:
          'Basic Grammar, Vocabulary, Correct word usage, Tenses, Prepositions, Spotting errors, Synonyms and Antonyms, Sentence rearrangement, Elementary passage reading.',
    ),
    ApssbSyllabusSection(
      examName: 'Uniformed Cadre Examination',
      targetCadres: 'Constable, Fireman, Forest Guard',
      stage: 'Stage 2: Written Examination (OMR)',
      subject: 'General Intelligence & Reasoning Ability',
      questions: 25,
      marks: 50,
      duration: '2 Hours (Total Exam)',
      markingStandard: '2 marks/Q, No Negative Marking; 33% Aggregate Pass',
      syllabusBreakdown:
          'Analogies, Classification, Number and letter series, Coding-decoding, Directions, Blood relations, Non-verbal mirror images, Figural pattern completion.',
    ),

    // Combined Technical
    ApssbSyllabusSection(
      examName: 'Combined Technical / Trade Examination',
      targetCadres: 'Surveyor, Draughtsman, Electrician, Plumber, Mechanic, Lab Attendant, Junior Technical Staff',
      stage: 'Stage 1: Written (Part A - General)',
      subject: 'General English, GK & Elementary Maths',
      questions: 50,
      marks: 100,
      duration: '3 Hours (Combined with Part B)',
      markingStandard: '2 marks/Q, 33% Qualifying',
      syllabusBreakdown:
          'General English (Grammar, vocabulary, comprehension - 30 marks); General Knowledge & Arunachal Pradesh (Current affairs, heritage, geography - 35 marks); Elementary Maths (Arithmetic & mensuration - 35 marks).',
    ),
    ApssbSyllabusSection(
      examName: 'Combined Technical / Trade Examination',
      targetCadres: 'Surveyor, Draughtsman, Electrician, Plumber, ITI Cadres',
      stage: 'Stage 1: Written (Part B - Technical Domain)',
      subject: 'Concerned Technical Trade / Subject Paper',
      questions: 50,
      marks: 100,
      duration: 'Combined with Part A',
      markingStandard: '2 marks/Q, Domain Specialization',
      syllabusBreakdown:
          'ITI / Diploma curriculum specific to the applied post: For Draughtsman/Surveyor (Autocad, Surveying instruments, Levelling, Chain surveying, Building drawing); For Electrician (Circuits, AC/DC machines, Wiring, Earthing, Safety rules); For Plumber (Piping, Valves, Drainage, Plumbing tools).',
    ),
    ApssbSyllabusSection(
      examName: 'Combined Technical / Trade Examination',
      targetCadres: 'Surveyor, Draughtsman, Electrician, Mechanic',
      stage: 'Stage 2: Trade Skill Test',
      subject: 'Practical Trade Demonstration',
      duration: 'Hands-on evaluation',
      markingStandard: 'Hands-on Practical Evaluation (Qualifying)',
      syllabusBreakdown:
          'Evaluation of practical trade proficiency, machinery handling, tool operations, and blueprint reading as per NCVT/State technical standards.',
      isSkillTest: true,
    ),
  ];

  // ---------------------------------------------------------------------------
  // 3. APPSC SYLLABUS SECTIONS
  // ---------------------------------------------------------------------------
  static const List<AppscSyllabusSection> appscSections = [
    // APPSCCE Civil Services
    AppscSyllabusSection(
      examName: 'APPSCCE (Civil Services)',
      targetCadres: 'APCS (Admin / Circle Officer), APPS (DySP), FAO/TO, Asst Director',
      stage: 'Stage 1: Preliminary Exam (Objective)',
      paperName: 'Paper-I: General Studies',
      marks: 200,
      duration: '2 Hours (100 MCQs)',
      negativeMarking: '1/3rd (0.33) Negative Marking',
      primaryCurriculum:
          'Current events of national & international importance; History of India and Indian National Movement; Indian and World Geography (Physical, Social, Economic); Indian Polity and Governance (Constitution, Political System, Panchayati Raj, Public Policy, Rights Issues); Economic and Social Development (Poverty, Inclusion, Demographics, Social Sector); Environmental Ecology, Biodiversity, Climate Change; General Science.',
      arunachalComponent:
          'History, Land, People, Culture, Administration, Tribal institutions, Customary laws, Demography, and Economic Development of Arunachal Pradesh and North-East India (30-35% weightage).',
      weightageImpact: 'Screening only. Marks determine qualification for Mains (roughly 12-15x vacancies).',
    ),
    AppscSyllabusSection(
      examName: 'APPSCCE (Civil Services)',
      targetCadres: 'APCS, APPS, FAO/TO, Allied Services',
      stage: 'Stage 1: Preliminary Exam (Objective)',
      paperName: 'Paper-II: Civil Services Aptitude Test (CSAT)',
      marks: 200,
      duration: '2 Hours (80 MCQs)',
      negativeMarking: '1/3rd (0.33) Negative Marking',
      primaryCurriculum:
          'Comprehension; Interpersonal skills including communication skills; Logical reasoning and analytical ability; Decision-making and problem-solving; General mental ability; Basic numeracy (numbers and relations, orders of magnitude, Class X level); Data interpretation (charts, graphs, tables, data sufficiency - Class X level).',
      arunachalComponent: 'None (Universal Aptitude standards).',
      weightageImpact: 'Qualifying paper only. Candidate must secure minimum 33% marks to be evaluated in Paper-I.',
    ),
    AppscSyllabusSection(
      examName: 'APPSCCE (Civil Services)',
      targetCadres: 'APCS, APPS, FAO/TO, Allied Services',
      stage: 'Stage 2: Mains Exam (Descriptive)',
      paperName: 'Qualifying Paper: General English',
      marks: 300,
      duration: '3 Hours (Descriptive)',
      negativeMarking: 'No Negative (Min 33% pass required)',
      primaryCurriculum:
          'Matriculation standard: Comprehension of given passages; Precis writing; Usage and vocabulary; Short essay writing.',
      arunachalComponent: 'Contextual themes involving state culture / North-East perspectives in comprehension or essays.',
      weightageImpact: 'Qualifying nature only. Marks NOT counted for final merit ranking, but mandatory to pass.',
    ),
    AppscSyllabusSection(
      examName: 'APPSCCE (Civil Services)',
      targetCadres: 'APCS, APPS, FAO/TO, Allied Services',
      stage: 'Stage 2: Mains Exam (Descriptive)',
      paperName: 'Paper-I: Essay',
      marks: 250,
      duration: '3 Hours (Descriptive)',
      negativeMarking: 'Subjective Evaluation',
      primaryCurriculum:
          'Candidates write essays on multiple sections/topics (Social, Political, Economic, Philosophical, Science & Tech, Environmental). Tested on concise expression, coherent organization of ideas, and critical argumentation.',
      arunachalComponent: 'At least one topic or context generally involves regional socio-economic development or cultural preservation in Arunachal Pradesh.',
      weightageImpact: 'Counted for final merit ranking.',
    ),
    AppscSyllabusSection(
      examName: 'APPSCCE (Civil Services)',
      targetCadres: 'APCS, APPS, FAO/TO, Allied Services',
      stage: 'Stage 2: Mains Exam (Descriptive)',
      paperName: 'Paper-II: General Studies - I',
      marks: 250,
      duration: '3 Hours (Descriptive)',
      negativeMarking: 'Subjective Evaluation',
      primaryCurriculum:
          'Indian Heritage & Culture, World & Indian History, Geography of the World & India, and Society. Modern Indian history, Freedom struggle, Post-independence consolidation; World history since 18th century; Salient aspects of Indian Society, Diversity, Role of women, Urbanization, Globalization.',
      arunachalComponent: 'Substantial section dedicated to History, Art, Culture, Customary Laws, Tribes, Festivals, and Physical/Resource Geography of Arunachal Pradesh and North-East.',
      weightageImpact: 'Counted for final merit ranking.',
    ),
    AppscSyllabusSection(
      examName: 'APPSCCE (Civil Services)',
      targetCadres: 'APCS, APPS, FAO/TO, Allied Services',
      stage: 'Stage 2: Mains Exam (Descriptive)',
      paperName: 'Paper-III: General Studies - II',
      marks: 250,
      duration: '3 Hours (Descriptive)',
      negativeMarking: 'Subjective Evaluation',
      primaryCurriculum:
          'Governance, Constitution, Polity, Social Justice, and International Relations. Indian Constitution evolution & features, Functions of Union and States, Separation of powers, Dispute mechanisms, Parliament and State Legislatures, Executive & Judiciary, Representation of People Act, Welfare schemes.',
      arunachalComponent:
          'Special constitutional provisions for Arunachal Pradesh (Article 371H, 6th Schedule dynamics, Inner Line Permit/BEFR 1873, Assam Frontier Regulation 1945, Daying Ering Committee, Panchayati Raj devolution).',
      weightageImpact: 'Counted for final merit ranking.',
    ),
    AppscSyllabusSection(
      examName: 'APPSCCE (Civil Services)',
      targetCadres: 'APCS, APPS, FAO/TO, Allied Services',
      stage: 'Stage 2: Mains Exam (Descriptive)',
      paperName: 'Paper-IV: General Studies - III',
      marks: 250,
      duration: '3 Hours (Descriptive)',
      negativeMarking: 'Subjective Evaluation',
      primaryCurriculum:
          'Technology, Economic Development, Bio-diversity, Environment, Security, and Disaster Management. Indian Economy, Planning, Growth, Agriculture, Public Distribution System, Infrastructure, Science & Tech applications, Conservation, Environmental Impact Assessment, Disaster management, Border security.',
      arunachalComponent:
          'State economic landscape: Hydropower potential, Horticulture/Organic farming, Border area development (Vibrant Villages Programme), Land degradation, Landslide management, Forest conservation.',
      weightageImpact: 'Counted for final merit ranking.',
    ),
    AppscSyllabusSection(
      examName: 'APPSCCE (Civil Services)',
      targetCadres: 'APCS, APPS, FAO/TO, Allied Services',
      stage: 'Stage 2: Mains Exam (Descriptive)',
      paperName: 'Paper-V: General Studies - IV',
      marks: 250,
      duration: '3 Hours (Descriptive)',
      negativeMarking: 'Subjective Evaluation',
      primaryCurriculum:
          'Ethics, Integrity, and Aptitude. Ethics and Human Interface, Determinants & consequences of ethics in human action, Human values, Attitude, Foundational values for civil service (Integrity, Impartiality, Objectivity, Empathy), Emotional Intelligence, Moral thinkers, Probity in governance, Case Studies.',
      arunachalComponent: 'Case studies reflecting administrative, tribal, communal, infrastructure, and resource challenges in Arunachal Pradesh.',
      weightageImpact: 'Counted for final merit ranking.',
    ),
    AppscSyllabusSection(
      examName: 'APPSCCE (Civil Services)',
      targetCadres: 'APCS, APPS, FAO/TO, Allied Services',
      stage: 'Stage 2: Mains Exam (Descriptive)',
      paperName: 'Paper-VI & VII: Optional Subject (Paper I & II)',
      marks: 500,
      duration: '3 Hours each (250 Marks x 2)',
      negativeMarking: 'Subjective Evaluation',
      primaryCurriculum:
          'Candidate chooses ONE optional subject (e.g. Civil Engineering, Political Science, History, Geography, Agriculture, Public Admin, Sociology, etc.). Paper I: Foundational & theoretical principles; Paper II: Advanced specialization & applied dimensions.',
      arunachalComponent: 'Contextual application as per chosen optional syllabus.',
      weightageImpact: 'Major determinant of final rank. Total Written = 1,750 Marks.',
    ),
    AppscSyllabusSection(
      examName: 'APPSCCE (Civil Services)',
      targetCadres: 'APCS, APPS, FAO/TO, Allied Services',
      stage: 'Stage 3: Personality Test (Interview)',
      paperName: 'Viva-Voce / Personality Test',
      marks: 275,
      duration: 'Interview Board',
      negativeMarking: 'Comprehensive Board Evaluation',
      primaryCurriculum:
          'Assessment of intellectual caliber, mental alertness, critical powers of assimilation, balance of judgment, clear and logical exposition, integrity, and social leadership traits.',
      arunachalComponent: 'Extensive grilling on Arunachal Pradesh history, boundary disputes, tribal traditions, state development issues, and current state affairs.',
      weightageImpact: 'Total Mains Merit: 1750 (Written) + 275 (Interview) = 2,025 Marks.',
      isInterview: true,
    ),

    // AESE (Assistant Engineer)
    AppscSyllabusSection(
      examName: 'Arunachal Engineering Service (AESE - AE)',
      targetCadres: 'Assistant Engineer (Civil, Electrical, Mechanical, ECE, CSE/IT, Agri) in PWD, RWD, PHE, WRD, Power, DHPD, IT',
      stage: 'Stage 1: Recruitment Exam (Written)',
      paperName: 'Paper-I: General English (Common to All Disciplines)',
      marks: 100,
      duration: '2 Hours (Descriptive/Objective)',
      negativeMarking: 'Pass mark: 33%',
      primaryCurriculum: 'Comprehension, Essay writing, Letter writing, Precis, Sentence construction, Idioms, Grammatical accuracy.',
      arunachalComponent: 'General local context in essay/letter topics.',
      weightageImpact: 'Mandatory component of total written score (500 marks).',
    ),
    AppscSyllabusSection(
      examName: 'Arunachal Engineering Service (AESE - AE)',
      targetCadres: 'Assistant Engineer (All Engineering Disciplines)',
      stage: 'Stage 1: Recruitment Exam (Written)',
      paperName: 'Paper-II: General Studies (Common to All Disciplines)',
      marks: 100,
      duration: '2 Hours (Objective/Descriptive)',
      negativeMarking: 'Pass mark: 33%',
      primaryCurriculum: 'Current events, Indian Polity, History, Geography, General Science, Indian Economy, Ecology.',
      arunachalComponent: 'Arunachal Pradesh geography, natural resources, tribes, infrastructure challenges.',
      weightageImpact: 'Mandatory component of total written score.',
    ),

    // AESE Technical - Civil Engineering (CE)
    AppscSyllabusSection(
      examName: 'Arunachal Engineering Service (AESE - AE)',
      targetCadres: 'Assistant Engineer (Civil) in PWD, RWD, PHE, WRD, Urban Development',
      stage: 'Stage 1: Recruitment Exam (Written)',
      paperName: 'Paper-III: Technical Paper-I (Civil Engineering)',
      marks: 150,
      duration: '3 Hours (Objective/Descriptive)',
      negativeMarking: 'Pass mark: 33%',
      primaryCurriculum:
          'Degree standard (B.Tech/BE): Solid Mechanics & Structural Analysis; Building Materials, Construction Practice & Concrete Technology; Design of Reinforced Concrete & Prestressed Structures; Design of Steel Structures; Fluid Mechanics, Open Channel Hydraulics & Hydraulic Machines; Geotechnical Engineering, Soil Mechanics & Deep/Shallow Foundations.',
      arunachalComponent: 'Seismic Zone-V design standards, high-altitude concrete curing, landslide stabilization techniques, and hill slope retention.',
      weightageImpact: 'Major core technical score.',
    ),
    AppscSyllabusSection(
      examName: 'Arunachal Engineering Service (AESE - AE)',
      targetCadres: 'Assistant Engineer (Civil) in PWD, RWD, PHE, WRD',
      stage: 'Stage 1: Recruitment Exam (Written)',
      paperName: 'Paper-IV: Technical Paper-II (Civil Engineering)',
      marks: 150,
      duration: '3 Hours (Objective/Descriptive)',
      negativeMarking: 'Pass mark: 33%',
      primaryCurriculum:
          'Hydrology & Water Resources Engineering; Irrigation & Flood Control; Environmental Engineering (Water Supply, Waste Water Engineering, Solid Waste); Transportation Engineering (Highway planning, Pavement design, Hill roads as per IRC:SP:48, Traffic engineering); Surveying, Photogrammetry & Total Station / GPS; Construction Planning, Management, CPM/PERT & Estimating.',
      arunachalComponent: 'Mountain highway alignment, RCC bridge foundations across flash-flood rivers, and spring-shed water harvesting in hilly settlements.',
      weightageImpact: 'Major core technical score. Total Written = 500 marks.',
    ),

    // AESE Technical - Electrical Engineering (EE)
    AppscSyllabusSection(
      examName: 'Arunachal Engineering Service (AESE - AE)',
      targetCadres: 'Assistant Engineer (Electrical) in Department of Power, Hydro Power Development (DHPD)',
      stage: 'Stage 1: Recruitment Exam (Written)',
      paperName: 'Paper-III: Technical Paper-I (Electrical Engineering)',
      marks: 150,
      duration: '3 Hours (Objective/Descriptive)',
      negativeMarking: 'Pass mark: 33%',
      primaryCurriculum:
          'Electrical Circuits & Network Theory; Electromagnetic Fields & Waves; Electrical & Electronic Materials; Electrical Measurements & Instrumentation; Analog & Digital Electronics; Microprocessors & Microcontrollers (8085/8086, Embedded systems); Signals & Systems.',
      arunachalComponent: 'Protection of measuring instruments and transmission lines against lightning and high humidity in dense forest corridors.',
      weightageImpact: 'Major core technical score.',
    ),
    AppscSyllabusSection(
      examName: 'Arunachal Engineering Service (AESE - AE)',
      targetCadres: 'Assistant Engineer (Electrical) in Department of Power, DHPD',
      stage: 'Stage 1: Recruitment Exam (Written)',
      paperName: 'Paper-IV: Technical Paper-II (Electrical Engineering)',
      marks: 150,
      duration: '3 Hours (Objective/Descriptive)',
      negativeMarking: 'Pass mark: 33%',
      primaryCurriculum:
          'Electrical Machines (DC Machines, Transformers, Synchronous & Induction Machines); Power Systems (Generation, EHV transmission, load flow, fault analysis, switchgear & protection); Control Systems (Time/frequency domain, state-space); Power Electronics & Drives (Thyristors, inverters, choppers); Non-Conventional Energy (Micro/Mini hydro, Solar PV, grid integration).',
      arunachalComponent: 'Run-of-the-river hydro generation, transmission line sag & icing in sub-zero elevations, and micro-grid distribution in remote hilly villages.',
      weightageImpact: 'Major core technical score. Total Written = 500 marks.',
    ),

    // AESE Technical - Mechanical Engineering (ME)
    AppscSyllabusSection(
      examName: 'Arunachal Engineering Service (AESE - AE)',
      targetCadres: 'Assistant Engineer (Mechanical) in Power, PWD, Transport, Industries',
      stage: 'Stage 1: Recruitment Exam (Written)',
      paperName: 'Paper-III: Technical Paper-I (Mechanical Engineering)',
      marks: 150,
      duration: '3 Hours (Objective/Descriptive)',
      negativeMarking: 'Pass mark: 33%',
      primaryCurriculum:
          'Engineering Mechanics; Mechanics of Materials (Strength of Materials, Stress-Strain, Mohr circle); Theory of Machines & Mechanisms (Balancing, Governors, Cams, Gear trains); Design of Machine Elements (Shafts, Bearings, Gears, Welded joints); Materials Science & Metallurgy; Mechanical Vibrations.',
      arunachalComponent: 'Cold-weather brittleness of metals, fatigue in heavy machinery operating on unpaved mountain roads.',
      weightageImpact: 'Major core technical score.',
    ),
    AppscSyllabusSection(
      examName: 'Arunachal Engineering Service (AESE - AE)',
      targetCadres: 'Assistant Engineer (Mechanical) in Power, PWD, Transport',
      stage: 'Stage 1: Recruitment Exam (Written)',
      paperName: 'Paper-IV: Technical Paper-II (Mechanical Engineering)',
      marks: 150,
      duration: '3 Hours (Objective/Descriptive)',
      negativeMarking: 'Pass mark: 33%',
      primaryCurriculum:
          'Thermodynamics (Laws, cycles, availability); IC Engines, Steam Turbines & Gas Turbines; Heat Transfer (Conduction, Convection, Radiation, Heat Exchangers); Fluid Mechanics & Machinery (Pelton, Francis, Kaplan turbines, Centrifugal pumps); Refrigeration & Air Conditioning; Manufacturing Science (Casting, Welding, Metal Forming, CNC, Metrology); Industrial Engineering & Operations Research.',
      arunachalComponent: 'Hydro-turbine runner silt erosion (sand abrasion in Himalayan rivers), heavy earthmoving equipment deployment and maintenance in hill sectors.',
      weightageImpact: 'Major core technical score. Total Written = 500 marks.',
    ),

    // AESE Technical - Electronics & Communication (ECE)
    AppscSyllabusSection(
      examName: 'Arunachal Engineering Service (AESE - AE)',
      targetCadres: 'Assistant Engineer (Electronics / Telecomm) in IT Dept, Police Radio Organization',
      stage: 'Stage 1: Recruitment Exam (Written)',
      paperName: 'Paper-III: Technical Paper-I (Electronics & Communication)',
      marks: 150,
      duration: '3 Hours (Objective/Descriptive)',
      negativeMarking: 'Pass mark: 33%',
      primaryCurriculum:
          'Electronic Devices & Semiconductor Physics; Analog Integrated Circuits (Op-Amps, Amplifiers, Oscillators); Digital Circuits & Combinational/Sequential Logic; Microprocessors, Microcontrollers & Interfacing; Signals & Systems; Electromagnetic Theory & Microwave Engineering (Waveguides, Radar, Antennas).',
      arunachalComponent: 'Mountain terrain RF propagation, microwave line-of-sight repeater stations in deep valleys.',
      weightageImpact: 'Major core technical score.',
    ),
    AppscSyllabusSection(
      examName: 'Arunachal Engineering Service (AESE - AE)',
      targetCadres: 'Assistant Engineer (Electronics / Telecomm) in IT Dept, Police Radio',
      stage: 'Stage 1: Recruitment Exam (Written)',
      paperName: 'Paper-IV: Technical Paper-II (Electronics & Communication)',
      marks: 150,
      duration: '3 Hours (Objective/Descriptive)',
      negativeMarking: 'Pass mark: 33%',
      primaryCurriculum:
          'Analog & Digital Communication Systems (AM, FM, PCM, QAM, SNR); Wireless & Mobile Communication (4G/5G, MIMO, OFDM); Optical Fiber Communications (Fibers, WDM, Lasers); Computer Networks & Protocols (TCP/IP, Routing, Security); Control Systems; Digital Signal Processing (DSP algorithms, FIR/IIR filters); Satellite Communication & VSAT systems.',
      arunachalComponent: 'Satellite broadband & VSAT networks for border outposts and remote administrative centers, optical ground wire (OPGW) along hill transmission lines.',
      weightageImpact: 'Major core technical score. Total Written = 500 marks.',
    ),

    // AESE Technical - Computer Science & IT (CSE/IT)
    AppscSyllabusSection(
      examName: 'Arunachal Engineering Service (AESE - AE)',
      targetCadres: 'Assistant Engineer (Computer / IT / Systems) in Department of IT & Communication',
      stage: 'Stage 1: Recruitment Exam (Written)',
      paperName: 'Paper-III: Technical Paper-I (Computer Science & IT)',
      marks: 150,
      duration: '3 Hours (Objective/Descriptive)',
      negativeMarking: 'Pass mark: 33%',
      primaryCurriculum:
          'Discrete Mathematics & Graph Theory; Digital Logic & Computer Organization/Architecture (Instruction pipelining, Memory hierarchy); Programming in C, C++, Java & Python; Data Structures & Algorithms (Sorting, Trees, Graphs, Dynamic Programming, Complexity); Theory of Computation & Compiler Design.',
      arunachalComponent: 'Secure local caching and offline-first software architecture for connectivity-limited remote administrative blocks.',
      weightageImpact: 'Major core technical score.',
    ),
    AppscSyllabusSection(
      examName: 'Arunachal Engineering Service (AESE - AE)',
      targetCadres: 'Assistant Engineer (Computer / IT / Systems) in Department of IT & Communication',
      stage: 'Stage 1: Recruitment Exam (Written)',
      paperName: 'Paper-IV: Technical Paper-II (Computer Science & IT)',
      marks: 150,
      duration: '3 Hours (Objective/Descriptive)',
      negativeMarking: 'Pass mark: 33%',
      primaryCurriculum:
          'Operating Systems (Process management, Concurrency, Virtual memory, Linux); Database Management Systems (SQL, Normalization, Transactions, NoSQL); Computer Networks (TCP/IP, Routing protocols, Network Security); Software Engineering (Agile, CI/CD); Web & Mobile Technologies; Cyber Security & Cryptography (PKI, Firewalls, Threat mitigation); Cloud Computing & Virtualization.',
      arunachalComponent: 'State Data Center (SDC) management, e-Governance services (e-Office, Jan Suvidha), and State Wide Area Network (SWAN) operations across Arunachal districts.',
      weightageImpact: 'Major core technical score. Total Written = 500 marks.',
    ),

    // AESE Technical - Agricultural Engineering (AGRI)
    AppscSyllabusSection(
      examName: 'Arunachal Engineering Service (AESE - AE)',
      targetCadres: 'Assistant Engineer (Agricultural / Soil Conservation) in Dept of Agriculture & Rural Development',
      stage: 'Stage 1: Recruitment Exam (Written)',
      paperName: 'Paper-III: Technical Paper-I (Agricultural Engineering)',
      marks: 150,
      duration: '3 Hours (Objective/Descriptive)',
      negativeMarking: 'Pass mark: 33%',
      primaryCurriculum:
          'Farm Power & Tractor Technology (IC engines, transmission, power tillers, ergonomics); Farm Machinery & Implements (Tillage, sowing, planting, plant protection, harvesting, threshing); Post-Harvest Technology & Food Process Engineering (Drying, milling, cold storage, food preservation); Farm Structures, Rural Housing & Livestock Environmental Control.',
      arunachalComponent: 'Specialized lightweight farm power machinery and mechanized hill terrace farming implements suited for Jhum and terrace cultivation.',
      weightageImpact: 'Major core technical score.',
    ),
    AppscSyllabusSection(
      examName: 'Arunachal Engineering Service (AESE - AE)',
      targetCadres: 'Assistant Engineer (Agricultural / Soil Conservation) in Dept of Agriculture & Rural Development',
      stage: 'Stage 1: Recruitment Exam (Written)',
      paperName: 'Paper-IV: Technical Paper-II (Agricultural Engineering)',
      marks: 150,
      duration: '3 Hours (Objective/Descriptive)',
      negativeMarking: 'Pass mark: 33%',
      primaryCurriculum:
          'Soil and Water Conservation Engineering (Water and wind erosion, contour bunding, graded terracing, bench terraces, gully control structures, silt detention basins); Watershed Hydrology, Planning & Resource Management; Irrigation & Drainage Engineering (Pressurized irrigation, Drip, Micro-sprinkler); Ground Water, Wells and Lift Pumps; Renewable Energy Applications (Biogas, solar dryers); GIS & Remote Sensing in Watersheds.',
      arunachalComponent: 'Hill terrace soil erosion mitigation, catchment area treatment for hilly streams, and gravity-fed micro-irrigation systems in tribal farming tracts.',
      weightageImpact: 'Major core technical score. Total Written = 500 marks.',
    ),

    AppscSyllabusSection(
      examName: 'Arunachal Engineering Service (AESE - AE)',
      targetCadres: 'Assistant Engineer (All Engineering Disciplines)',
      stage: 'Stage 2: Viva-Voce / Interview',
      paperName: 'Personality & Technical Viva',
      marks: 75,
      duration: 'Interview Board',
      negativeMarking: 'Comprehensive Assessment',
      primaryCurriculum: 'Technical assessment, practical problem-solving in field engineering, project execution in difficult terrain, code of ethics.',
      arunachalComponent: 'Knowledge of terrain, geological formations, earthquake vulnerability (Zone V) of Arunachal Pradesh.',
      weightageImpact: 'Final Merit = 500 (Written) + 75 (Viva) = 575 Marks.',
      isInterview: true,
    ),

    // JE Common
    AppscSyllabusSection(
      examName: 'Junior Engineer (JE) Common Exam',
      targetCadres: 'Junior Engineer (Civil, Electrical, Mechanical, ECE, CSE/IT, Agri) in all State Departments',
      stage: 'Stage 1: Written Examination',
      paperName: 'Paper-I: General English & General Knowledge (Common to All Trades)',
      marks: 100,
      duration: '2 Hours (50 English + 50 GK)',
      negativeMarking: 'Qualifying / Merit (Min 33%)',
      primaryCurriculum:
          'Part A (English - 50 marks): Grammar, vocabulary, error correction, comprehension. Part B (GK - 50 marks): Current affairs, national history, geography, constitution, science, and Arunachal Pradesh GK.',
      arunachalComponent: 'Arunachal Pradesh general geography, tribal history, major projects.',
      weightageImpact: 'Written component of total 300 marks.',
    ),
    AppscSyllabusSection(
      examName: 'Junior Engineer (JE) Common Exam',
      targetCadres: 'Junior Engineer (Civil) in PWD, RWD, PHE, WRD, UD',
      stage: 'Stage 1: Written Examination',
      paperName: 'Paper-II: Technical Domain - Civil Engineering (CE)',
      marks: 200,
      duration: '3 Hours (Objective/Conventional)',
      negativeMarking: 'Technical Core (Min 33%)',
      primaryCurriculum:
          'Diploma Standard: Building Materials (Bricks, Cement, Aggregates, Mortar, Timber, Bitumen); Estimating, Costing & Valuation; Surveying (Chain, Compass, Plane table, Levelling, Theodolite, Contouring); Soil Mechanics & Foundation; Hydraulics & Fluid Mechanics; Irrigation Engineering; Transportation Engineering (Highway design, pavements, hill road drainage); Environmental Engineering (Water purification, sewerage); Theory of Structures, Concrete Technology, RCC & Steel Design.',
      arunachalComponent: 'Hill slope cutting, gabion wall & sausage crate retaining structures, bamboo-reinforced composites, and mountain road drain clearing.',
      weightageImpact: 'Written component. Total Written = 300 Marks.',
    ),
    AppscSyllabusSection(
      examName: 'Junior Engineer (JE) Common Exam',
      targetCadres: 'Junior Engineer (Electrical) in Power Department, DHPD, PWD Electrical',
      stage: 'Stage 1: Written Examination',
      paperName: 'Paper-II: Technical Domain - Electrical Engineering (EE)',
      marks: 200,
      duration: '3 Hours (Objective/Conventional)',
      negativeMarking: 'Technical Core (Min 33%)',
      primaryCurriculum:
          'Diploma Standard: Basic Electrical Concepts (Ohm’s law, Kirchhoff’s laws, Network theorems, AC circuits); Magnetic Circuits; Electrical & Electronic Measurements (Meters, bridges); Electrical Machines (DC Motors/Generators, 1-Phase & 3-Phase Transformers, Induction Motors); Generation, Transmission & Distribution of Power; Switchgear & Protection (Fuses, circuit breakers, earthing); Estimation and Costing of Electrical Installations; Utilization of Electrical Energy (Illumination, Heating, Drives); Basic Electronics & Power Devices (Diodes, Transistors, SCR).',
      arunachalComponent: 'Hill terrain distribution line maintenance, high lightning protection, transformer maintenance in damp mountain climates.',
      weightageImpact: 'Written component. Total Written = 300 Marks.',
    ),
    AppscSyllabusSection(
      examName: 'Junior Engineer (JE) Common Exam',
      targetCadres: 'Junior Engineer (Mechanical) in PWD Mechanical, Power, Transport',
      stage: 'Stage 1: Written Examination',
      paperName: 'Paper-II: Technical Domain - Mechanical Engineering (ME)',
      marks: 200,
      duration: '3 Hours (Objective/Conventional)',
      negativeMarking: 'Technical Core (Min 33%)',
      primaryCurriculum:
          'Diploma Standard: Engineering Mechanics (Forces, moments, friction); Strength of Materials (Stress, strain, bending moments, torsion in shafts); Theory of Machines (Simple mechanisms, gear trains, governors); Machine Design (Design of joints, keys, couplings, shafts); Thermal Engineering (Thermodynamic laws, boilers, steam turbines, IC Engines - 2 stroke, 4 stroke, Otto/Diesel cycles); Fluid Mechanics & Hydraulic Machinery (Bernoulli theorem, Pelton wheel, Francis turbine, pumps); Manufacturing Technology (Workshop processes, lathes, welding, casting); Industrial Management & Safety.',
      arunachalComponent: 'Cold climate engine starting techniques, maintenance of road construction machinery (bulldozers, excavators, rock breakers) in remote hill sectors.',
      weightageImpact: 'Written component. Total Written = 300 Marks.',
    ),
    AppscSyllabusSection(
      examName: 'Junior Engineer (JE) Common Exam',
      targetCadres: 'Junior Engineer (Electronics / Telecommunication) in Police Telecom, IT, Power',
      stage: 'Stage 1: Written Examination',
      paperName: 'Paper-II: Technical Domain - Electronics & Comm. (ECE)',
      marks: 200,
      duration: '3 Hours (Objective/Conventional)',
      negativeMarking: 'Technical Core (Min 33%)',
      primaryCurriculum:
          'Diploma Standard: Electronic Components & Semiconductor Devices (Diodes, BJTs, FETs, MOSFETs); Audio & Radio Frequency Amplifiers; Op-Amps & 555 Timers; Digital Electronics (Number systems, Logic gates, Flip-flops, Counters, Registers, Multiplexers); Communication Engineering (AM/FM/PM, transmitters, receivers, antennas, transmission lines); Microprocessors (8085 architecture, pin diagram, instruction set, programming); Electronic Measurements & Instruments (CRO, Multimeters, Signal generators); Industrial Electronics & Sensors.',
      arunachalComponent: 'Maintenance of VHF/UHF wireless repeaters on high mountain ridges, solar-powered communication hubs in non-electrified outposts.',
      weightageImpact: 'Written component. Total Written = 300 Marks.',
    ),
    AppscSyllabusSection(
      examName: 'Junior Engineer (JE) Common Exam',
      targetCadres: 'Junior Engineer (Computer / IT) in Government Departments, NIC, IT Dept',
      stage: 'Stage 1: Written Examination',
      paperName: 'Paper-II: Technical Domain - Computer Science & IT (CSE/IT)',
      marks: 200,
      duration: '3 Hours (Objective/Conventional)',
      negativeMarking: 'Technical Core (Min 33%)',
      primaryCurriculum:
          'Diploma Standard: Computer Fundamentals & PC Architecture (CPU, Memory, I/O devices, BIOS); Operating Systems (Windows, Linux commands, File systems, Process scheduling); Programming in C & C++ (Functions, pointers, OOP concepts); Data Structures (Arrays, Stacks, Queues, Linked Lists, Trees, Sorting); Database Management Systems (SQL queries, normalization, table constraints); Computer Networks (LAN, WAN, TCP/IP, IP addressing, routers, switches); Web Development (HTML, CSS, JavaScript); Information Security & Cyber Laws; Hardware Troubleshooting & Peripheral Maintenance.',
      arunachalComponent: 'Deploying and maintaining district IT infrastructure, LAN setups for Jan Suvidha / DC offices, and local backup mechanisms for remote offices.',
      weightageImpact: 'Written component. Total Written = 300 Marks.',
    ),
    AppscSyllabusSection(
      examName: 'Junior Engineer (JE) Common Exam',
      targetCadres: 'Junior Engineer (Agricultural) in Agriculture & Soil Conservation Departments',
      stage: 'Stage 1: Written Examination',
      paperName: 'Paper-II: Technical Domain - Agricultural Engineering (AGRI)',
      marks: 200,
      duration: '3 Hours (Objective/Conventional)',
      negativeMarking: 'Technical Core (Min 33%)',
      primaryCurriculum:
          'Diploma Standard: Farm Power (Sources of farm power, IC engine systems, tractors, power tillers); Farm Machinery (Tillage implements, seed drills, planters, plant protection equipment, harvesting and threshing machinery); Soil and Water Conservation (Soil erosion types, contour bunding, terracing, drop structures, water harvesting ponds); Irrigation and Drainage (Sprinkler, drip, canal lining, drainage for waterlogged lands); Post Harvest Technology & Agricultural Processing (Cleaning, grading, drying, storage); Renewable Energy in Agriculture (Biogas, solar appliances).',
      arunachalComponent: 'Gravity water harvesting tanks for mountain slopes, terraced farming implement maintenance, and processing equipment for indigenous cash crops (large cardamom, ginger, kiwi, orange).',
      weightageImpact: 'Written component. Total Written = 300 Marks.',
    ),
    AppscSyllabusSection(
      examName: 'Junior Engineer (JE) Common Exam',
      targetCadres: 'Junior Engineer (All Engineering Disciplines)',
      stage: 'Stage 2: Viva-Voce',
      paperName: 'Technical Interview',
      marks: 50,
      duration: 'Board Interview',
      negativeMarking: 'Technical Assessment',
      primaryCurriculum: 'Domain knowledge, site inspection capabilities, instrument handling, survey tools, estimation accuracy.',
      arunachalComponent: 'Arunachal terrain awareness and local engineering challenges.',
      weightageImpact: 'Final Merit = 300 + 50 = 350 Marks.',
      isInterview: true,
    ),

    // Teaching (PGT / TGT)
    AppscSyllabusSection(
      examName: 'Post Graduate Teacher (PGT)',
      targetCadres: 'PGT in Govt Higher Secondary Schools (English, Maths, Physics, Chemistry, Biology, History, Pol Science, Geography, Economics)',
      stage: 'Stage 1: Written Examination',
      paperName: 'Paper-I: General English',
      marks: 100,
      duration: '3 Hours (Descriptive)',
      negativeMarking: 'Pass mark: 33%',
      primaryCurriculum: 'Comprehension, Essay writing, Precis writing, Letter writing, English grammar, Syntax and vocabulary.',
      arunachalComponent: 'Regional themes in essay writing.',
      weightageImpact: 'Written component (Total 400 marks).',
    ),
    AppscSyllabusSection(
      examName: 'Post Graduate Teacher (PGT)',
      targetCadres: 'PGT (Various Subjects)',
      stage: 'Stage 1: Written Examination',
      paperName: 'Paper-II: General Knowledge',
      marks: 100,
      duration: '2 Hours (Objective/Descriptive)',
      negativeMarking: 'Pass mark: 33%',
      primaryCurriculum: 'Current affairs, Indian polity, geography, history, everyday science, sports, environment.',
      arunachalComponent: 'Arunachal Pradesh historical background, demography, tribes, art, and administrative structure.',
      weightageImpact: 'Written component.',
    ),
    AppscSyllabusSection(
      examName: 'Post Graduate Teacher (PGT)',
      targetCadres: 'PGT (Various Subjects)',
      stage: 'Stage 1: Written Examination',
      paperName: 'Paper-III: Relevant PG Subject Paper',
      marks: 200,
      duration: '3 Hours (Descriptive)',
      negativeMarking: "Master's Degree Standard",
      primaryCurriculum:
          'Advanced Master level curriculum in chosen subject discipline (e.g. advanced calculus/algebra for Maths; organic/inorganic/physical for Chemistry; political thought & theories for Political Science).',
      arunachalComponent: 'Applied context where applicable.',
      weightageImpact: 'Core qualifying & ranking paper. Viva = 50 Marks. Total = 450 Marks.',
    ),
    AppscSyllabusSection(
      examName: 'Trained Graduate Teacher (TGT)',
      targetCadres: 'TGT in Govt Secondary Schools (Language, Sciences, Social Science, Maths)',
      stage: 'Stage 1: Written Examination',
      paperName: 'Paper-I: General English',
      marks: 100,
      duration: '3 Hours (Descriptive/Objective)',
      negativeMarking: 'Pass mark: 33%',
      primaryCurriculum: 'English grammar, sentence comprehension, essay, letter, vocabulary, correction of sentences.',
      arunachalComponent: 'General regional topics.',
      weightageImpact: 'Written component (Total 400 marks).',
    ),
    AppscSyllabusSection(
      examName: 'Trained Graduate Teacher (TGT)',
      targetCadres: 'TGT (Various Subjects)',
      stage: 'Stage 1: Written Examination',
      paperName: 'Paper-II: General Knowledge',
      marks: 100,
      duration: '2 Hours (Objective)',
      negativeMarking: 'Pass mark: 33%',
      primaryCurriculum: 'Current national & international events, Indian constitution, Indian geography, history, science.',
      arunachalComponent: 'Arunachal Pradesh heritage, geography, economy, culture.',
      weightageImpact: 'Written component.',
    ),
    AppscSyllabusSection(
      examName: 'Trained Graduate Teacher (TGT)',
      targetCadres: 'TGT (Various Subjects)',
      stage: 'Stage 1: Written Examination',
      paperName: 'Paper-III: Relevant Subject & Pedagogy',
      marks: 200,
      duration: '3 Hours (Descriptive/Objective)',
      negativeMarking: 'Graduate / B.Ed Standard',
      primaryCurriculum:
          'Degree syllabus in relevant subject along with Educational Psychology, Teaching Pedagogy, Classroom management, Curriculum development, and Assessment methodologies.',
      arunachalComponent: 'Teaching methods suited for multicultural and tribal student cohorts.',
      weightageImpact: 'Core ranking paper. Viva = 50 Marks. Total = 450 Marks.',
    ),

    // Agriculture / Horticulture (ADO & HDO)
    AppscSyllabusSection(
      examName: 'Agriculture / Horticulture Development Officer (ADO & HDO)',
      targetCadres: 'ADO & HDO in Dept of Agriculture / Horticulture',
      stage: 'Stage 1: Written Examination',
      paperName: 'Paper-I: General English',
      marks: 100,
      duration: '2 Hours',
      negativeMarking: 'Pass mark: 33%',
      primaryCurriculum: 'Essay writing, precis, comprehension, grammar, vocabulary, sentence correction.',
      arunachalComponent: 'State agricultural topics.',
      weightageImpact: 'Written component (Total 400 marks).',
    ),
    AppscSyllabusSection(
      examName: 'Agriculture / Horticulture Development Officer (ADO & HDO)',
      targetCadres: 'ADO & HDO',
      stage: 'Stage 1: Written Examination',
      paperName: 'Paper-II: General Knowledge',
      marks: 100,
      duration: '2 Hours',
      negativeMarking: 'Pass mark: 33%',
      primaryCurriculum: 'Current events, Indian economy, geography, polity, science, rural development.',
      arunachalComponent:
          'Arunachal Pradesh agro-climatic zones, traditional farming systems (Jhum / shifting cultivation, Apatani wet rice-fish farming), state agricultural policies.',
      weightageImpact: 'Written component.',
    ),
    AppscSyllabusSection(
      examName: 'Agriculture / Horticulture Development Officer (ADO & HDO)',
      targetCadres: 'ADO & HDO',
      stage: 'Stage 1: Written Examination',
      paperName: 'Paper-III: Agriculture / Horticulture Science',
      marks: 200,
      duration: '3 Hours',
      negativeMarking: 'B.Sc (Agri / Horti) Standard',
      primaryCurriculum:
          'For ADO: Agronomy, Soil Science, Plant Breeding & Genetics, Plant Pathology, Entomology, Agricultural Extension, Agricultural Economics, Seed Technology. For HDO: Pomology, Olericulture, Floriculture, Post-Harvest Management, Plantation Crops, Spices.',
      arunachalComponent: 'Indigenous crops of Arunachal Pradesh (Large cardamom, ginger, kiwi, oranges, off-season vegetables), organic farming initiatives.',
      weightageImpact: 'Core technical paper. Viva = 50 Marks. Total = 450 Marks.',
    ),

    // Medical (GDMO / Dental Surgeon)
    AppscSyllabusSection(
      examName: 'Medical Officer (GDMO & Dental Surgeon)',
      targetCadres: 'Medical Officer (Allopathy, Dental) in Dept of Health & Family Welfare',
      stage: 'Stage 1: Recruitment Examination',
      paperName: 'Paper-I: General English & General Studies',
      marks: 100,
      duration: '2 Hours (50 + 50)',
      negativeMarking: 'Screening / Written',
      primaryCurriculum: 'English: Comprehension, grammar, precis. GS: Indian Polity, health policies, public health systems, current events, Arunachal Pradesh profile.',
      arunachalComponent: 'Health demographics, indigenous health challenges, epidemiology in hill tracts of Arunachal Pradesh.',
      weightageImpact: 'Written screening score.',
    ),
    AppscSyllabusSection(
      examName: 'Medical Officer (GDMO & Dental Surgeon)',
      targetCadres: 'Medical Officer (Allopathy, Dental)',
      stage: 'Stage 1: Recruitment Examination',
      paperName: 'Paper-II: Medical Science / Dental Surgery',
      marks: 300,
      duration: '3 Hours (Objective/MCQ)',
      negativeMarking: 'MBBS / BDS Standard',
      primaryCurriculum:
          'General Medicine, Paediatrics, Surgery, Obstetrics & Gynaecology, Preventive & Social Medicine (PSM), Forensic Medicine, Pathology, Pharmacology, Microbiology.',
      arunachalComponent: 'Public health diseases prevalent in Arunachal Pradesh (Vector-borne diseases, malaria, tuberculosis, endemic goitre).',
      weightageImpact: 'Core technical ranking paper. Viva = 50 Marks. Total = 450 Marks.',
    ),
  ];

  // ---------------------------------------------------------------------------
  // 4. SUBJECT-WISE DEEP-DIVE MATRIX
  // ---------------------------------------------------------------------------
  static const List<SubjectMatrixItem> subjectMatrix = [
    SubjectMatrixItem(
      category: 'Arunachal Pradesh General Studies',
      subTopic: 'Geography & Natural Resources',
      coreCurriculum:
          'Physical geography, river systems (Siang, Subansiri, Kameng, Lohit, Dibang, Tirap), mountain passes, agro-climatic zones, wildlife sanctuaries, national parks (Namdapha, Mouling, Pakke), mineral wealth, biodiversity hotspots.',
      apssbScope: 'Direct facts: Rivers, origins, sanctuaries, district headquarters, borders with Tibet/China, Myanmar, Bhutan, Assam, Nagaland.',
      appscScope: 'Descriptive analysis: Hydropower potential, environmental impact, trans-Himalayan connectivity, disaster vulnerability (Zone V seismic activity, floods).',
      typicalWeightage: '10 - 15% of GK in APSSB; 30 - 35% of GS-I/Prelims in APPSC',
      highYieldFocus: 'National parks, rivers, borders, biodiversity, environmental clearances.',
    ),
    SubjectMatrixItem(
      category: 'Arunachal Pradesh General Studies',
      subTopic: 'History, Tribes, Culture & Administration',
      coreCurriculum:
          'Major tribes (Nyishi, Adi, Apatani, Galo, Tagin, Monpa, Mishmi, Wancho, Noctes, Tangsa, Singpho, etc.), festivals (Nyokum, Solung, Dree, Si-Donyi, Losar, Mopin, Chalo Loku), customary laws (Kebang, Buliang, Nyele), NEFA history, Daying Ering committee, Statehood Act 1986, Article 371H, Inner Line Permit (BEFR 1873).',
      apssbScope: 'Festival dates, tribes associated, indigenous dances, traditional attires, year of NEFA renaming, first Chief Minister/Governor.',
      appscScope: 'Evolution of local self-government, customary village councils vs statutory Panchayati Raj, border disputes, cultural preservation vs modernization.',
      typicalWeightage: '15 - 20% of GK in APSSB; Up to 35% in APPSC Prelims & GS-I/II',
      highYieldFocus: 'Tribal festivals, customary administration, constitutional safeguards (Art 371H, BEFR).',
    ),
    SubjectMatrixItem(
      category: 'General English',
      subTopic: 'Grammar & Functional Syntax',
      coreCurriculum:
          'Articles, Prepositions, Tenses, Subject-Verb Agreement, Voice change (Active/Passive), Direct & Indirect Speech, Sentence rearrangement, Sentence completion, Modal auxiliaries, Conditional clauses.',
      apssbScope: '25 MCQs (50 marks): Spotting errors, sentence improvement, fill in the blanks, cloze tests.',
      appscScope: 'Descriptive: Transformation of sentences, synthesis, grammatical correction, standard usage.',
      typicalWeightage: '25% in APSSB CGL/CHSL; 300 marks qualifying or 100 marks scoring in APPSC',
      highYieldFocus: 'Prepositions, subject-verb concord, voice and speech transformation.',
    ),
    SubjectMatrixItem(
      category: 'General English',
      subTopic: 'Vocabulary & Composition',
      coreCurriculum:
          'Synonyms, Antonyms, Homonyms, Idioms & Phrases, One-word substitution, Spelling corrections, Precis writing, Comprehension passages, Formal & Informal letter writing, Essay drafting.',
      apssbScope: 'MCQs on antonyms, synonyms, idioms, spellings, one-word substitutes, and short passage comprehension.',
      appscScope: 'Descriptive: 1000-1200 word essays, precis writing of dense administrative/socio-economic texts, argument writing.',
      typicalWeightage: '50% of English section in APSSB; 70% of descriptive English paper in APPSC',
      highYieldFocus: 'Vocabulary flashcards, formal precis condensation, structured multi-paragraph essays.',
    ),
    SubjectMatrixItem(
      category: 'Elementary / Quantitative Maths',
      subTopic: 'Arithmetic & Commercial Math',
      coreCurriculum:
          'Number systems, Fractions, Decimals, Surds & Indices, LCM & HCF, Ratio & Proportion, Unitary method, Percentages, Profit & Loss, Simple Interest, Compound Interest, Discount, Partnership, Work & Time, Pipes & Cisterns, Speed, Distance & Time, Trains, Boats & Streams.',
      apssbScope: '25 MCQs (50 marks): Quick calculations, formula applications, shortcut methods (Class 10 level).',
      appscScope: 'CSAT Paper-II (Prelims): Quantitative aptitude, logical problem-solving, data sufficiency.',
      typicalWeightage: '25% in APSSB CGL/CHSL/CSL; Major portion of APPSC CSAT (Paper-II)',
      highYieldFocus: 'Percentages, Profit & Loss, Ratio, Time & Work, Speed & Distance.',
    ),
    SubjectMatrixItem(
      category: 'Elementary / Quantitative Maths',
      subTopic: 'Geometry, Mensuration & Algebra',
      coreCurriculum:
          'Algebraic identities, Linear equations, Polynomials, Angles, Triangles, Quadrilaterals, Circles, Chords & Tangents, Perimeter and Area of 2D figures, Surface Area & Volume of 3D solids (Cylinder, Cone, Sphere, Prism, Pyramid), Trigonometric ratios.',
      apssbScope: 'Standard formula-based geometry and mensuration MCQs in APSSB CGL.',
      appscScope: 'Secondary level mathematical problems in CSAT; Applied geometry in AE/JE exams.',
      typicalWeightage: '20 - 30% of Mathematics section in APSSB CGL',
      highYieldFocus: 'Mensuration formulas, circle theorems, coordinate algebra.',
    ),
    SubjectMatrixItem(
      category: 'General Intelligence & Reasoning',
      subTopic: 'Verbal & Analytical Reasoning',
      coreCurriculum:
          'Analogies, Classification, Alphabetical & Numerical series, Coding-Decoding, Blood relations, Direction sense, Order & Ranking, Venn diagrams, Syllogisms, Statement & Conclusions, Assertion & Reason, Critical reasoning.',
      apssbScope: '25 MCQs (50 marks): Fast pattern recognition, coding rules, ranking logic.',
      appscScope: 'Major component of APPSC Prelims Paper-II (CSAT): Critical logical deductions, argument evaluation.',
      typicalWeightage: '25% in APSSB exams; 30 - 40% of CSAT in APPSC',
      highYieldFocus: 'Syllogisms, blood relations, series completion, coding-decoding.',
    ),
    SubjectMatrixItem(
      category: 'General Intelligence & Reasoning',
      subTopic: 'Non-Verbal & Spatial Reasoning',
      coreCurriculum:
          'Figure series, Pattern completion, Mirror & Water images, Paper folding & cutting, Embedded figures, Cube & Dice, Figure counting, Spatial visualization.',
      apssbScope: '5 to 8 MCQs in APSSB CGL/CHSL/CSL.',
      appscScope: 'Pattern evaluation in CSAT.',
      typicalWeightage: '10 - 15% of Reasoning section in APSSB',
      highYieldFocus: 'Cube and dice, paper folding, mirror images.',
    ),
    SubjectMatrixItem(
      category: 'General Studies',
      subTopic: 'Indian Polity, Constitution & Governance',
      coreCurriculum:
          'Preamble, Fundamental Rights, Directive Principles (DPSP), Fundamental Duties, Union Executive (President, PM, Council of Ministers), Parliament, State Legislature, Judiciary (Supreme Court, High Courts), Constitutional & Statutory bodies, Emergency provisions, Amendments, Panchayati Raj & Urban Local Bodies.',
      apssbScope: 'Direct objective questions on Articles, Amendments, Tenures, Constitutional powers.',
      appscScope: 'In-depth Mains GS-II: Federalism disputes, Judicial activism, Separation of powers, Electoral reforms, Civil service neutrality.',
      typicalWeightage: '15 - 20% of GS in APSSB; Dedicated 250-mark paper (GS-II) in APPSC Mains',
      highYieldFocus: 'Fundamental Rights, Articles 1-51A, Judiciary, Panchayati Raj, Art 371H.',
    ),
    SubjectMatrixItem(
      category: 'General Studies',
      subTopic: 'Indian History & National Movement',
      coreCurriculum:
          'Ancient India (Indus Valley, Vedic period, Buddhism/Jainism, Mauryan, Gupta empire), Medieval India (Delhi Sultanate, Mughal Empire, Bhakti & Sufi movements), Modern India (British expansion, Revolt of 1857, Socio-religious reforms, Indian National Congress, Gandhian movements, Partition & Independence).',
      apssbScope: 'Chronological questions, historical battles, treaties, freedom fighter publications, acts (1909, 1919, 1935).',
      appscScope: 'Analytical GS-I: Impact of colonial economic policies, tribal revolts, social reform debates, post-independence state reorganization.',
      typicalWeightage: '15 - 20% of GS in APSSB; Significant portion of APPSC GS-I',
      highYieldFocus: 'Modern freedom struggle (1905-1947), 1857 revolt, major tribal uprisings in North East.',
    ),
    SubjectMatrixItem(
      category: 'General Studies',
      subTopic: 'Indian & World Geography',
      coreCurriculum:
          'Physical geography (Geomorphology, Climatology, Oceanography), Indian physical features (Himalayas, Northern Plains, Peninsular plateau, Coastal plains), Indian drainage systems, Monsoons & Climate, Soil types, Natural vegetation, Minerals, Agriculture, Industrial corridors, Population & Urbanization.',
      apssbScope: 'Factual MCQs: Major rivers, mountain peaks, dams, soil distributions, minerals, census facts.',
      appscScope: 'Analytical GS-I: Plate tectonics, resource distribution, climate change impacts on monsoon, industrial locational factors.',
      typicalWeightage: '15% of GS in APSSB; Core part of APPSC Prelims & Mains GS-I',
      highYieldFocus: 'Indian river basins, Himalayan geology, monsoons, soil & agricultural patterns.',
    ),
    SubjectMatrixItem(
      category: 'General Studies',
      subTopic: 'Indian Economy & Development',
      coreCurriculum:
          'Basic macroeconomic concepts, GDP/GNP, Inflation, Monetary Policy (RBI, Repo rates), Fiscal Policy (Budget, Taxation, GST), Banking system, Balance of Payments, Poverty, Unemployment, NITI Aayog, Government flagship schemes, Infrastructure & Agriculture.',
      apssbScope: 'Definitions, current economic statistics, schemes, budgetary terms, inflation indices.',
      appscScope: 'Analytical GS-III: Inclusive growth, fiscal federalism, agricultural supply chains, subsidies, industrial growth, employment generation.',
      typicalWeightage: '10 - 15% of GS in APSSB; Core part of APPSC GS-III',
      highYieldFocus: 'Union & State Budgets, RBI monetary tools, poverty alleviation programmes.',
    ),
    SubjectMatrixItem(
      category: 'General Studies',
      subTopic: 'Science, Technology & Environment',
      coreCurriculum:
          'Everyday Physics, Chemistry, Biology; Health and nutrition, Vitamins & diseases; Space technology (ISRO missions), Nuclear science, Defense systems, IT & Artificial Intelligence; Environmental ecology, Biodiversity, Wildlife conservation, Climate change protocols, Pollution control.',
      apssbScope: 'Everyday science MCQs, scientific inventions, disease vectors, ISRO launch missions.',
      appscScope: 'Analytical GS-III: Biotechnology applications, renewable energy transitions, climate negotiations, cyber security, environmental impact assessments.',
      typicalWeightage: '15 - 20% of GS in APSSB; Major part of APPSC GS-III',
      highYieldFocus: 'Renewable energy, space missions, environmental conventions, public health epidemiology.',
    ),
  ];
}
