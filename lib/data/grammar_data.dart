class GrammarTopic {
  final String id;
  final String title;
  final String subtitle;
  final String iconName;
  final List<GrammarRule> rules;

  const GrammarTopic({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.iconName,
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
    const GrammarTopic(
      id: 'subject_verb_agreement',
      title: 'Subject-Verb Agreement',
      subtitle: 'The 15 Golden Rules tested in APSSB & APPSC exams',
      iconName: 'rule_rounded',
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
