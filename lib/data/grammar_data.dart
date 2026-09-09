class GrammarTopic {
  final String id;
  final String title;
  final String subtitle;
  final String iconName;
  final String level; // 'Beginner', 'Intermediate', 'Advanced'
  final List<GrammarRule> rules;

  const GrammarTopic({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.iconName,
    this.level = 'Intermediate',
    required this.rules,
  });
}

class GrammarRule {
  final String ruleTitle;
  final String explanation;
  final String exampleCorrect;
  final String exampleIncorrect;
  final String? tip;

  const GrammarRule({
    required this.ruleTitle,
    required this.explanation,
    required this.exampleCorrect,
    required this.exampleIncorrect,
    this.tip,
  });
}

class GrammarQuizQuestion {
  final String id;
  final String category;
  final String questionText;
  final List<String> options;
  final String correctAnswer; // 'a', 'b', 'c', 'd'
  final String explanation;

  const GrammarQuizQuestion({
    required this.id,
    required this.category,
    required this.questionText,
    required this.options,
    required this.correctAnswer,
    required this.explanation,
  });
}

class GrammarData {
  static final List<GrammarTopic> topics = [
    // ─── BEGINNER FOUNDATION MODULES ──────────────────────────────
    const GrammarTopic(
      id: 'parts_of_speech_intro',
      title: 'The 8 Parts of Speech (Foundations)',
      subtitle: 'What Nouns, Pronouns, Verbs, and Adjectives actually do',
      iconName: 'category_rounded',
      level: 'Beginner',
      rules: [
        GrammarRule(
          ruleTitle: '1. What is a Noun & Pronoun?',
          explanation: 'A Noun names a person, place, thing, or concept (Itanagar, officer, duty). A Pronoun replaces a noun to prevent repetition (he, she, it, they, who).',
          exampleCorrect: 'Rohan submitted the file because he had verified every record.',
          exampleIncorrect: 'Rohan submitted the file because Rohan had verified every record.',
          tip: 'Test trick: If a word can take "the", "a", or "an", it is almost always a noun.',
        ),
        GrammarRule(
          ruleTitle: '2. What is a Verb?',
          explanation: 'A Verb shows an action (write, run, study) or a state of being (is, am, are, was, were, seem, exist). Every sentence MUST have a verb.',
          exampleCorrect: 'The officer inspected the bridge yesterday.',
          exampleIncorrect: 'The officer the bridge yesterday. (Missing verb)',
          tip: 'Ask: "What is the subject DOING, or what state is the subject IN?"',
        ),
        GrammarRule(
          ruleTitle: '3. Adjectives vs. Adverbs',
          explanation: 'Adjectives modify NOUNS (a diligent aspirant). Adverbs modify VERBS, ADJECTIVES, or other ADVERBS (she solved the paper diligently).',
          exampleCorrect: 'He spoke clearly during the interview.',
          exampleIncorrect: 'He spoke clear during the interview.',
          tip: 'Adverbs often end in "-ly", while adjectives answer "What kind? Which one?"',
        ),
        GrammarRule(
          ruleTitle: '4. Prepositions & Conjunctions',
          explanation: 'Prepositions link nouns to express position, direction, or time (in, on, across, through). Conjunctions connect words or clauses (and, but, because, although).',
          exampleCorrect: 'He walked across the town and met the commissioner.',
          exampleIncorrect: 'He walked town and met the commissioner.',
          tip: 'A preposition is always followed by an object noun or pronoun (e.g. "at 9 AM", "in Arunachal").',
        ),
      ],
    ),
    const GrammarTopic(
      id: 'sentence_structure_basics',
      title: 'Sentence Structure: Finding Subject & Verb',
      subtitle: 'Identify who is doing what before checking agreement rules',
      iconName: 'architecture_rounded',
      level: 'Beginner',
      rules: [
        GrammarRule(
          ruleTitle: '1. What is the Subject of a Sentence?',
          explanation: 'The subject is the person, place, or thing that performs the action or is described by the verb.',
          exampleCorrect: 'The District Collector signed the notification.',
          exampleIncorrect: 'Signed the notification. (Fragment: Who signed?)',
          tip: 'Find the verb first, then ask: "WHO or WHAT performed this verb?"',
        ),
        GrammarRule(
          ruleTitle: '2. What is an Object?',
          explanation: 'The direct object receives the action of the transitive verb. Ask: "[Subject] + [Verb] + WHAT / WHOM?"',
          exampleCorrect: 'The candidates completed the mock test.',
          exampleIncorrect: 'The candidates completed. (Incomplete thought)',
          tip: 'Candidates (Subject) + completed (Verb) + What? -> the mock test (Object).',
        ),
        GrammarRule(
          ruleTitle: '3. Compound Subjects',
          explanation: 'When two or more distinct subjects are joined by "and", the combined subject is plural and requires a plural verb.',
          exampleCorrect: 'Tashi and Bem are preparing for the APPSC CCE prelims.',
          exampleIncorrect: 'Tashi and Bem is preparing for the APPSC CCE prelims.',
          tip: 'Think of "Subject 1 AND Subject 2" as "THEY".',
        ),
      ],
    ),
    const GrammarTopic(
      id: 'nouns_singular_plural',
      title: 'Nouns & Number: Singular vs Plural Traps',
      subtitle: 'Uncountable nouns and irregular plurals commonly tested in APSSB',
      iconName: 'format_list_numbered_rounded',
      level: 'Beginner',
      rules: [
        GrammarRule(
          ruleTitle: '1. The Uncountable Noun Trap',
          explanation: 'Words like furniture, advice, information, luggage, scenery, equipment, and machinery can NEVER take "a/an" or an ending "-s". They are strictly singular.',
          exampleCorrect: 'The officer gave valuable advice to the young recruits.',
          exampleIncorrect: 'The officer gave valuable advices to the young recruits.',
          tip: 'Say "a piece of advice" or "items of luggage", never "advices" or "luggages".',
        ),
        GrammarRule(
          ruleTitle: '2. Nouns Always Plural in Form and Verb',
          explanation: 'Tools and clothes with two symmetric parts (scissors, trousers, binoculars, spectacles, pants) always take a plural verb unless preceded by "a pair of".',
          exampleCorrect: 'These scissors are sharp. (OR: A pair of scissors is on the desk.)',
          exampleIncorrect: 'These scissors is sharp.',
          tip: 'Without "pair of", always treat them as plural.',
        ),
        GrammarRule(
          ruleTitle: '3. Collective Nouns That Are Always Plural',
          explanation: 'Cattle, clergy, gentry, poultry, police, people look singular without an ending "-s", but they are ALWAYS plural.',
          exampleCorrect: 'The police are investigating the security breach.',
          exampleIncorrect: 'The police is investigating the security breach.',
          tip: 'Never say "polices" or "cattles". Treat them as plural.',
        ),
      ],
    ),

    // ─── INTERMEDIATE CORE MODULES ──────────────────────────────
    const GrammarTopic(
      id: 'subject_verb_agreement',
      title: 'Subject-Verb Agreement',
      subtitle: 'The 15 Golden Rules tested in APSSB & APPSC exams',
      iconName: 'rule_rounded',
      level: 'Intermediate',
      rules: [
        GrammarRule(
          ruleTitle: 'Rule 1: Intervening Prepositional Phrases',
          explanation: 'The verb agrees with the true subject, NOT the noun in an intervening phrase like "along with", "together with", "as well as", or "in addition to".',
          exampleCorrect: 'The Governor, along with his security aides, has arrived at the convention.',
          exampleIncorrect: 'The Governor, along with his security aides, have arrived at the convention.',
          tip: 'Cross out the intervening phrase mentally to check the true subject.',
        ),
        GrammarRule(
          ruleTitle: 'Rule 2: "Either... Or" and "Neither... Nor"',
          explanation: 'When two subjects are joined by "either... or" or "neither... nor", the verb agrees with the subject closest to it.',
          exampleCorrect: 'Neither the teacher nor the students were aware of the schedule change.',
          exampleIncorrect: 'Neither the teacher nor the students was aware of the schedule change.',
          tip: 'Look only at the noun immediately preceding the verb.',
        ),
        GrammarRule(
          ruleTitle: 'Rule 3: "Each", "Every", "Neither of", "Either of"',
          explanation: 'These indefinite distributive pronouns are strictly singular and always take a singular verb.',
          exampleCorrect: 'Each of the 25 district commissioners was instructed to attend the meeting.',
          exampleIncorrect: 'Each of the 25 district commissioners were instructed to attend the meeting.',
          tip: '"Each of + plural noun + singular verb".',
        ),
        GrammarRule(
          ruleTitle: 'Rule 4: Collective Nouns (Jury, Committee, Team)',
          explanation: 'Takes a singular verb when acting as a unified unit, but plural when members act individually or disagree.',
          exampleCorrect: 'The committee has submitted its final report on administrative restructuring.',
          exampleIncorrect: 'The committee have submitted its final report on administrative restructuring.',
          tip: 'Check if the members are united or divided in opinion.',
        ),
        GrammarRule(
          ruleTitle: 'Rule 5: Plural Words with Singular Meanings',
          explanation: 'Nouns such as mathematics, physics, economics, news, and politics are singular in sense and take singular verbs.',
          exampleCorrect: 'Physics is an essential subject for the technical engineering prelims.',
          exampleIncorrect: 'Physics are an essential subject for the technical engineering prelims.',
          tip: 'Do not be tricked by the ending letter "s".',
        ),
      ],
    ),
    const GrammarTopic(
      id: 'tenses_and_conditionals',
      title: 'Tenses & Conditional Sentences',
      subtitle: 'Past, Present, Future, and "If" clauses',
      iconName: 'timelapse_rounded',
      rules: [
        GrammarRule(
          ruleTitle: 'Rule 1: Third Conditional (Unreal Past)',
          explanation: 'If + Past Perfect (had + V3) in the if-clause, then would/could/might have + V3 in the main clause.',
          exampleCorrect: 'If she had revised the state budget notes, she would have cleared the cut-off.',
          exampleIncorrect: 'If she would have revised the state budget notes, she would have cleared the cut-off.',
          tip: 'Never use "would have" inside the if-clause.',
        ),
        GrammarRule(
          ruleTitle: 'Rule 2: Since / For with Perfect Continuous',
          explanation: 'Actions that started in the past and continue into the present use Present Perfect Continuous (has/have been + V-ing).',
          exampleCorrect: 'He has been studying Arunachal history since January.',
          exampleIncorrect: 'He is studying Arunachal history since January.',
          tip: '"Since" denotes a specific point in time; "For" denotes duration.',
        ),
        GrammarRule(
          ruleTitle: 'Rule 3: Universal Truths in Indirect Speech',
          explanation: 'When reporting a universal truth or scientific fact, the present tense in the reported clause remains unchanged.',
          exampleCorrect: 'The teacher said that the sun rises in the east.',
          exampleIncorrect: 'The teacher said that the sun rose in the east.',
          tip: 'Do not backshift tenses for permanent truths.',
        ),
      ],
    ),
    const GrammarTopic(
      id: 'active_passive_voice',
      title: 'Active & Passive Voice',
      subtitle: 'Subject-object transformations for all tenses & modals',
      iconName: 'swap_horiz_rounded',
      rules: [
        GrammarRule(
          ruleTitle: 'Rule 1: General Transformation Formula',
          explanation: 'Active: Subject + Verb + Object. Passive: Object + form of "be" + Past Participle (V3) + by + Subject.',
          exampleCorrect: 'The Chief Minister inaugurated the newly constructed highway.',
          exampleIncorrect: 'The newly constructed highway was inaugurated by the Chief Minister.',
          tip: 'Only transitive verbs (verbs with a direct object) can be converted to passive.',
        ),
        GrammarRule(
          ruleTitle: 'Rule 2: Imperative Sentences (Orders / Requests)',
          explanation: 'Orders use: "Let + object + be + V3". Advice uses: "You are advised to + V1".',
          exampleCorrect: 'Let the notification be published immediately.',
          exampleIncorrect: 'You should publish the notification right now.',
          tip: '"Let + object + be + past participle" is standard for official orders.',
        ),
      ],
    ),
    const GrammarTopic(
      id: 'direct_indirect_speech',
      title: 'Direct & Indirect Speech (Narration)',
      subtitle: 'Reporting verbs, pronoun shifts, and tense backshifting',
      iconName: 'record_voice_over_rounded',
      rules: [
        GrammarRule(
          ruleTitle: 'Rule 1: Reporting Verb Tense Rule',
          explanation: 'If the reporting verb is in the Past tense (e.g. "said", "stated"), the reported speech shifts backward in time.',
          exampleCorrect: 'He said, "I am solving mock tests." -> He said that he was solving mock tests.',
          exampleIncorrect: 'He said that he is solving mock tests.',
          tip: 'Present Simple -> Past Simple; Present Continuous -> Past Continuous.',
        ),
        GrammarRule(
          ruleTitle: 'Rule 2: Interrogative Sentences (Questions)',
          explanation: 'Say/tell becomes "asked" or "inquired". Do NOT use "that". For yes/no questions, use "if" or "whether".',
          exampleCorrect: 'She asked me whether I had verified the final answer key.',
          exampleIncorrect: 'She said to me that whether I verified the final answer key.',
          tip: 'Sentence structure changes from question form to assertive form.',
        ),
      ],
    ),
    const GrammarTopic(
      id: 'prepositions_and_conjunctions',
      title: 'Prepositions & Fixed Phrases',
      subtitle: 'Fixed prepositions, confusing pairs, and error traps',
      iconName: 'link_rounded',
      rules: [
        GrammarRule(
          ruleTitle: 'Rule 1: Fixed Prepositions',
          explanation: 'Certain words strictly take specific prepositions: "abstain from", "comply with", "conducive to", "accused of", "proficient in".',
          exampleCorrect: 'Candidates must comply with the exam hall instructions.',
          exampleIncorrect: 'Candidates must comply to the exam hall instructions.',
          tip: 'Memorize the word + preposition pair as a single vocabulary unit.',
        ),
        GrammarRule(
          ruleTitle: 'Rule 2: Confusing Prepositions (Between vs. Among)',
          explanation: '"Between" is used for two entities or distinct named entities; "Among" is used for more than two entities in a collective group.',
          exampleCorrect: 'The scholarship was divided among the ten top-ranking students.',
          exampleIncorrect: 'The scholarship was divided between the ten top-ranking students.',
          tip: 'Use "between" when items are individual, even if more than two (e.g. between India, China, and Myanmar).',
        ),
      ],
    ),
  ];

  static final List<GrammarQuizQuestion> quizQuestions = [
    const GrammarQuizQuestion(
      id: 'gq_1',
      category: 'Subject-Verb Agreement',
      questionText: 'Neither the district commissioner nor the block officers ______ present at the emergency briefing yesterday.',
      options: ['(a) was', '(b) were', '(c) has been', '(d) is'],
      correctAnswer: 'b',
      explanation: 'When subjects are joined by "neither... nor", the verb agrees with the subject closest to it. Here, "the block officers" is plural, so the plural verb "were" is correct.',
    ),
    const GrammarQuizQuestion(
      id: 'gq_2',
      category: 'Subject-Verb Agreement',
      questionText: 'The committee ______ divided in their opinions regarding the new recruitment guidelines.',
      options: ['(a) was', '(b) were', '(c) has been', '(d) is'],
      correctAnswer: 'b',
      explanation: 'When members of a collective noun act individually or are divided in opinion, a plural verb ("were") is used.',
    ),
    const GrammarQuizQuestion(
      id: 'gq_3',
      category: 'Subject-Verb Agreement',
      questionText: 'Each of the selected candidates ______ rewarded with a certificate of merit by the Governor.',
      options: ['(a) were', '(b) was', '(c) have been', '(d) are'],
      correctAnswer: 'b',
      explanation: '"Each of" is followed by a plural noun ("candidates") but strictly takes a singular verb ("was").',
    ),
    const GrammarQuizQuestion(
      id: 'gq_4',
      category: 'Tenses',
      questionText: 'If the government ______ the river embankment on time, the monsoon floods would not have caused such damage.',
      options: ['(a) reinforced', '(b) has reinforced', '(c) had reinforced', '(d) would reinforce'],
      correctAnswer: 'c',
      explanation: 'This is a Third Conditional (unreal past). The if-clause requires Past Perfect ("had reinforced") because the main clause uses "would not have caused".',
    ),
    const GrammarQuizQuestion(
      id: 'gq_5',
      category: 'Prepositions',
      questionText: 'All candidates must strictly abstain ______ bringing electronic gadgets into the examination center.',
      options: ['(a) to', '(b) from', '(c) with', '(d) in'],
      correctAnswer: 'b',
      explanation: 'The verb "abstain" takes the fixed preposition "from".',
    ),
    const GrammarQuizQuestion(
      id: 'gq_6',
      category: 'Voice',
      questionText: 'Identify the correct passive form of: "The selection board evaluated all interview candidates."',
      options: [
        '(a) All interview candidates was evaluated by the selection board.',
        '(b) All interview candidates were evaluated by the selection board.',
        '(c) All interview candidates had been evaluated by the selection board.',
        '(d) All interview candidates have evaluated the selection board.'
      ],
      correctAnswer: 'b',
      explanation: 'Past Simple active ("evaluated") converts to "were + V3" ("were evaluated") for plural subject ("candidates").',
    ),
    const GrammarQuizQuestion(
      id: 'gq_7',
      category: 'Narration',
      questionText: 'Change to indirect speech: The invigilator said, "Stop writing now."',
      options: [
        '(a) The invigilator ordered them to stop writing then.',
        '(b) The invigilator said that they must stop writing now.',
        '(c) The invigilator requested to stop writing now.',
        '(d) The invigilator told that they should stop writing.'
      ],
      correctAnswer: 'a',
      explanation: 'Imperative orders use "ordered + object + to + V1". Also, time adverb "now" changes to "then" in indirect speech.',
    ),
    const GrammarQuizQuestion(
      id: 'gq_8',
      category: 'Idioms & Phrases',
      questionText: 'What is the meaning of the idiom "Burn the midnight oil"?',
      options: [
        '(a) To waste valuable resources carelessly',
        '(b) To study or work late into the night',
        '(c) To cause an accidental fire',
        '(d) To wake up very early in the morning'
      ],
      correctAnswer: 'b',
      explanation: '"Burn the midnight oil" means working, reading, or studying diligently until late at night.',
    ),
    const GrammarQuizQuestion(
      id: 'gq_9',
      category: 'Error Spotting',
      questionText: 'Find the grammatically incorrect part: "He is senior (A) / than me (B) / in government service (C) / No Error (D)"',
      options: ['(a) Part A', '(b) Part B', '(c) Part C', '(d) Part D'],
      correctAnswer: 'b',
      explanation: 'Adjectives ending in "-ior" (senior, junior, superior, inferior, prior) take "to", NOT "than". It should be "senior to me".',
    ),
    const GrammarQuizQuestion(
      id: 'gq_10',
      category: 'One-Word Substitution',
      questionText: 'A person who leaves no stone unturned and shows persistent determination is best described as:',
      options: ['(a) Tenacious', '(b) Lethargic', '(c) Diffident', '(d) Haughty'],
      correctAnswer: 'a',
      explanation: '"Tenacious" means holding firmly to a purpose with relentless determination.',
    ),
  ];
}
