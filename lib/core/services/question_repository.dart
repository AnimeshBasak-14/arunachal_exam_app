class Question {
  final String id;
  final String examCode; // 'CGL', 'UDC', 'CSLE'
  final int year; // 2021, 2019, 2023
  final String subject; // 'English', 'Mathematics', 'General Knowledge'
  final String questionText;
  final List<String> options; // ['(a) ...', '(b) ...']
  final String correctAnswer; // 'a', 'b', 'c', 'd'
  final String officialAnswer;
  final String solution;
  final List<String> initialComments;
  final String? pyqText;

  const Question({
    required this.id,
    required this.examCode,
    required this.year,
    required this.subject,
    required this.questionText,
    required this.options,
    required this.correctAnswer,
    required this.officialAnswer,
    required this.solution,
    required this.initialComments,
    this.pyqText,
  });
}

class QuestionRepository {
  static final List<Question> allQuestions = [
    // --- CGL 2021 ---
    Question(
      id: 'cgl_2021_q1',
      examCode: 'CGL',
      year: 2021,
      subject: 'English',
      questionText: 'Though very slender, she is strong.',
      options: ['(a) bony', '(b) tiny', '(c) tall', '(d) slim'],
      correctAnswer: 'd',
      officialAnswer: '(d) slim',
      solution: '"Slender" means gracefully thin. The correct synonym is "slim". Options (a) "bony" has a negative connotation, (b) "tiny" means small, and (c) "tall" refers to height.',
      initialComments: [
        'Easy synonym question from CGL 2021 English grammar section!',
        'Yes, slim fits the context perfectly.'
      ],
      pyqText: '[CGL 2021]',
    ),
    Question(
      id: 'cgl_2021_q2',
      examCode: 'CGL',
      year: 2021,
      subject: 'English',
      questionText: 'Our annual accounts passed the scrutiny of the government auditors.',
      options: ['(a) inspection', '(b) attention', '(c) warning', '(d) attack'],
      correctAnswer: 'a',
      officialAnswer: '(a) inspection',
      solution: '"Scrutiny" means critical observation or examination. Therefore, "inspection" is the exact synonym.',
      initialComments: [
        'Very common vocabulary in public service exams.',
        'Auditors always do inspections/scrutiny!'
      ],
      pyqText: '[CGL 2021]',
    ),
    Question(
      id: 'cgl_2021_q3',
      examCode: 'CGL',
      year: 2021,
      subject: 'English',
      questionText: 'Change Active to Passive: I saw him leaving the house.',
      options: [
        '(a) He had been seen leaving the house.',
        '(b) He was seen to be leaving the house.',
        '(c) Leaving the house he was seen by me.',
        '(d) He was seen leaving the house by me.'
      ],
      correctAnswer: 'd',
      officialAnswer: '(d) He was seen leaving the house by me.',
      solution: 'The active sentence "I saw him leaving the house" has simple past tense ("saw"). Passive transformation is "He was seen leaving the house by me".',
      initialComments: [
        'Standard passive rule: Object + was/were + V3 + by Subject.',
        'Option d is grammatically correct and sounds natural.'
      ],
      pyqText: '[CGL 2021]',
    ),
    Question(
      id: 'cgl_2021_q51',
      examCode: 'CGL',
      year: 2021,
      subject: 'Mathematics',
      questionText: 'The equation of a line passing through (3, -3) and perpendicular to the line 2x + 5y - 2 = 0 is:',
      options: [
        '(a) 5x - 2y - 21 = 0',
        '(b) x + 2y + 21 = 0',
        '(c) 2x - 5y - 21 = 0',
        '(d) x + 5y - 21 = 0'
      ],
      correctAnswer: 'a',
      officialAnswer: '(a) 5x - 2y - 21 = 0',
      solution: 'Slope of 2x + 5y - 2 = 0 is m1 = -2/5. Slope of perpendicular line m2 = 5/2. Equation is y - y1 = m2(x - x1) => y - (-3) = 5/2(x - 3) => 2(y + 3) = 5(x - 3) => 2y + 6 = 5x - 15 => 5x - 2y - 21 = 0.',
      initialComments: [
        'Great explanation of slope perpendicularity (m1 * m2 = -1).',
        'Took me 45 seconds to solve.'
      ],
      pyqText: '[CGL 2021]',
    ),
    Question(
      id: 'cgl_2021_q52',
      examCode: 'CGL',
      year: 2021,
      subject: 'Mathematics',
      questionText: 'If A.M. (Arithmetic Mean) and G.M. (Geometric Mean) of 2 numbers are 5 and 4 respectively, the two numbers are:',
      options: ['(a) 8 and 2', '(b) 6 and 4', '(c) 7 and 11', '(d) none of these'],
      correctAnswer: 'a',
      officialAnswer: '(a) 8 and 2',
      solution: 'Let numbers be a and b. AM = (a + b)/2 = 5 => a + b = 10. GM = sqrt(ab) = 4 => ab = 16. Solve equation: a(10 - a) = 16 => a^2 - 10a + 16 = 0 => (a - 8)(a - 2) = 0 => numbers are 8 and 2.',
      initialComments: [
        'You can also check options directly! 8+2=10 (AM=5) and 8*2=16 (GM=sqrt(16)=4). Highly recommended shortcut!',
        'Checking options saved so much time here.'
      ],
      pyqText: '[CGL 2021]',
    ),
    Question(
      id: 'cgl_2021_q102',
      examCode: 'CGL',
      year: 2021,
      subject: 'General Knowledge',
      questionText: 'Broad flat steps or terraces made on steep slopes so flat surfaces are available to grow crops is called:',
      options: ['(a) Terrace Farming', '(b) Rock Dam', '(c) Contour Barriers', '(d) Mulching'],
      correctAnswer: 'a',
      officialAnswer: '(a) Terrace Farming',
      solution: 'Terrace farming is the practice of cutting flat steps into steep slopes to allow agriculture and prevent soil runoff.',
      initialComments: [
        'Geographical land practices question.',
        'Commonly practiced in hilly states like Arunachal!'
      ],
      pyqText: '[CGL 2021]',
    ),

    // --- UDC 2019 ---
    Question(
      id: 'udc_2019_q1',
      examCode: 'UDC',
      year: 2019,
      subject: 'English',
      questionText: 'Identify the part of speech of the underlined word: Akbar was a great king. (Akbar)',
      options: ['a) Noun', 'b) Pronoun', 'c) Adjective', 'd) Verb'],
      correctAnswer: 'a',
      officialAnswer: 'a) Noun',
      solution: '"Akbar" is the name of a specific historical emperor, which makes it a proper Noun.',
      initialComments: [
        'Extremely basic question from UDC 2019.',
        'Proper nouns represent specific names.'
      ],
      pyqText: '[UDC 2019]',
    ),
    Question(
      id: 'udc_2019_q2',
      examCode: 'UDC',
      year: 2019,
      subject: 'English',
      questionText: 'Identify the part of speech of the underlined word: He worked the sum quickly. (quickly)',
      options: ['a) Verb', 'b) Adverb', 'c) Adjective', 'd) Pronoun'],
      correctAnswer: 'b',
      officialAnswer: 'b) Adverb',
      solution: '"Quickly" describes *how* the action of working the sum was performed, so it functions as an Adverb.',
      initialComments: [
        'Adverbs typically end in -ly and modify verbs.',
        'Yes, it modifies the verb "worked".'
      ],
      pyqText: '[UDC 2019]',
    ),
    Question(
      id: 'udc_2019_q51',
      examCode: 'UDC',
      year: 2019,
      subject: 'General Knowledge',
      questionText: 'D Ering Wildlife Sanctuary is located near:',
      options: ['a) Bomdila', 'b) Pasighat', 'c) Tezu', 'd) Khonsa'],
      correctAnswer: 'b',
      officialAnswer: 'b) Pasighat',
      solution: 'Daying Ering Wildlife Sanctuary is located near Pasighat in East Siang District of Arunachal Pradesh, famous for migratory birds.',
      initialComments: [
        'Crucial Arunachal Pradesh State GK question.',
        'D Ering is surrounded by the Siang River.'
      ],
      pyqText: '[UDC 2019]',
    ),
    Question(
      id: 'udc_2019_q52',
      examCode: 'UDC',
      year: 2019,
      subject: 'General Knowledge',
      questionText: 'Hangpan Dada Memorial Trophy is related to:',
      options: ['a) Football', 'b) Karate', 'c) Wushu', 'd) Hockey'],
      correctAnswer: 'a',
      officialAnswer: 'a) Football',
      solution: 'The Hangpan Dada Memorial Trophy is an annual state-level football and volleyball tournament named after Ashoka Chakra recipient Hangpan Dada.',
      initialComments: [
        'Dedicated to Havildar Hangpan Dada who laid down his life fighting terrorists.',
        'Great initiative by Govt of Arunachal to promote sports.'
      ],
      pyqText: '[UDC 2019]',
    ),
    Question(
      id: 'udc_2019_q101',
      examCode: 'UDC',
      year: 2019,
      subject: 'Mathematics',
      questionText: 'The average age of 10 boys in a class is 13 years. What is the sum of their ages?',
      options: ['a) 130', 'b) 120', 'c) 150', 'd) 180'],
      correctAnswer: 'a',
      officialAnswer: 'a) 130',
      solution: 'Average age = (Sum of ages) / (Number of boys) => 13 = Sum / 10 => Sum = 130 years.',
      initialComments: [
        'Simple arithmetic average multiplication.',
        'Easy mark score.'
      ],
      pyqText: '[UDC 2019]',
    ),

    // --- CSLE 2023 ---
    Question(
      id: 'csle_2023_q1',
      examCode: 'CSCE',
      year: 2023,
      subject: 'English',
      questionText: 'Choose the correct meaning of the underlined idiom: Ananya has been trying to shake off some of her weight.',
      options: [
        '(a) to culminate in',
        '(b) to get rid of',
        '(c) to concoct',
        '(d) to cause'
      ],
      correctAnswer: 'b',
      officialAnswer: '(b) to get rid of',
      solution: 'To "shake off" is a phrasal idiom meaning to free oneself from or get rid of something undesirable, like excess weight or an illness.',
      initialComments: [
        'Idiomatic phrasal verbs are very scoring if you read them regularly.',
        'Shake off weight = lose/get rid of weight.'
      ],
      pyqText: '[CSLE 2023]',
    ),
    Question(
      id: 'csle_2023_q51',
      examCode: 'CSCE',
      year: 2023,
      subject: 'Mathematics',
      questionText: 'Convert the fraction 2/5 into percentage form.',
      options: ['(a) 20%', '(b) 42%', '(c) 40%', '(d) 22%'],
      correctAnswer: 'c',
      officialAnswer: '(c) 40%',
      solution: 'To convert a fraction to percentage, multiply by 100: (2 / 5) * 100 = 2 * 20 = 40%.',
      initialComments: [
        'Fraction to percent conversion is standard base 100.',
        'Very basic arithmetic.'
      ],
      pyqText: '[CSLE 2023]',
    ),
    Question(
      id: 'csle_2023_q52',
      examCode: 'CSCE',
      year: 2023,
      subject: 'Mathematics',
      questionText: 'If p - q = 14, p + q = 20, then p x q =',
      options: ['(a) 48', '(b) 51', '(c) 54', '(d) 52'],
      correctAnswer: 'b',
      officialAnswer: '(b) 51',
      solution: 'Add the equations: (p - q) + (p + q) = 14 + 20 => 2p = 34 => p = 17. Substitute: 17 + q = 20 => q = 3. Therefore, p * q = 17 * 3 = 51.',
      initialComments: [
        'Linear system of two variables. Add to find p, subtract to find q.',
        'Answer is 51.'
      ],
      pyqText: '[CSLE 2023]',
    ),
    Question(
      id: 'csle_2023_q101',
      examCode: 'CSCE',
      year: 2023,
      subject: 'General Knowledge',
      questionText: 'Who won the 2023 Men\'s US Open Tennis Singles Championship?',
      options: [
        '(a) Daniil Medvedev',
        '(b) Casper Ruud',
        '(c) Carlos Alcaraz',
        '(d) Novak Djokovic'
      ],
      correctAnswer: 'd',
      officialAnswer: '(d) Novak Djokovic',
      solution: 'Novak Djokovic defeated Daniil Medvedev in the 2023 US Open Men\'s Singles final to secure his 24th Grand Slam title.',
      initialComments: [
        'Novak Djokovic is a legend, 24th grand slam!',
        'Important current affairs question from CSLE 2023 GK section.'
      ],
      pyqText: '[CSLE 2023]',
    ),
  ];
}
