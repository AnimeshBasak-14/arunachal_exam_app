import 'dart:math' as math;

enum DailyItemType { word, idiom, quote }

class DailyDoseItem {
  final DailyItemType type;
  final String title;
  final String category; // 'Noun', 'Adjective', 'Idiom', 'Civil Services Quote'
  final String meaning;
  final String exampleOrAuthor;
  final List<String> synonyms;
  final List<String> antonyms;

  const DailyDoseItem({
    required this.type,
    required this.title,
    required this.category,
    required this.meaning,
    required this.exampleOrAuthor,
    this.synonyms = const [],
    this.antonyms = const [],
  });
}

class DailyDoseData {
  static final List<DailyDoseItem> words = [
    const DailyDoseItem(
      type: DailyItemType.word,
      title: 'Aberrant',
      category: 'Adjective',
      meaning: 'Departing from an accepted standard; divergent or abnormal.',
      exampleOrAuthor: 'The committee investigated the aberrant behavior of the official.',
      synonyms: ['deviant', 'anomalous', 'irregular'],
      antonyms: ['normal', 'standard', 'typical'],
    ),
    const DailyDoseItem(
      type: DailyItemType.word,
      title: 'Benevolent',
      category: 'Adjective',
      meaning: 'Well-meaning, kindly, and generous in spirit towards others.',
      exampleOrAuthor: 'The benevolent administrator approved scholarship funds for rural students.',
      synonyms: ['kind', 'generous', 'charitable'],
      antonyms: ['malevolent', 'cruel', 'selfish'],
    ),
    const DailyDoseItem(
      type: DailyItemType.word,
      title: 'Cacophony',
      category: 'Noun',
      meaning: 'A harsh, discordant, and chaotic mixture of sounds.',
      exampleOrAuthor: 'The cacophony of street traffic broke his concentration during mock tests.',
      synonyms: ['discord', 'noise', 'clamor'],
      antonyms: ['harmony', 'melody', 'euphony'],
    ),
    const DailyDoseItem(
      type: DailyItemType.word,
      title: 'Dauntless',
      category: 'Adjective',
      meaning: 'Showing fearlessness and determination in the face of danger or difficulty.',
      exampleOrAuthor: 'The dauntless forest ranger navigated the dense valleys of Arunachal.',
      synonyms: ['fearless', 'brave', 'intrepid'],
      antonyms: ['timid', 'cowardly', 'hesitant'],
    ),
    const DailyDoseItem(
      type: DailyItemType.word,
      title: 'Ebullient',
      category: 'Adjective',
      meaning: 'Cheerful, lively, and overflowing with enthusiastic energy.',
      exampleOrAuthor: 'Her ebullient spirits lifted the morale of the entire study group.',
      synonyms: ['exuberant', 'buoyant', 'vivacious'],
      antonyms: ['gloomy', 'depressed', 'lethargic'],
    ),
    const DailyDoseItem(
      type: DailyItemType.word,
      title: 'Fastidious',
      category: 'Adjective',
      meaning: 'Very attentive to accuracy and detail; meticulous and hard to please.',
      exampleOrAuthor: 'The examiner was fastidious when evaluating descriptive answer papers.',
      synonyms: ['meticulous', 'scrupulous', 'punctilious'],
      antonyms: ['careless', 'sloppy', 'negligent'],
    ),
    const DailyDoseItem(
      type: DailyItemType.word,
      title: 'Gregarious',
      category: 'Adjective',
      meaning: 'Fond of company; sociable and outgoing in community settings.',
      exampleOrAuthor: 'Being gregarious helped him organize peer discussion groups effectively.',
      synonyms: ['sociable', 'convivial', 'outgoing'],
      antonyms: ['solitary', 'reclusive', 'introverted'],
    ),
    const DailyDoseItem(
      type: DailyItemType.word,
      title: 'Judicious',
      category: 'Adjective',
      meaning: 'Having, showing, or done with good judgment or sense; prudent.',
      exampleOrAuthor: 'A judicious allocation of exam minutes between GS and Maths is vital.',
      synonyms: ['wise', 'prudent', 'sensible'],
      antonyms: ['foolish', 'imprudent', 'reckless'],
    ),
    const DailyDoseItem(
      type: DailyItemType.word,
      title: 'Laconic',
      category: 'Adjective',
      meaning: 'Using very few words in speech or writing; concise and to the point.',
      exampleOrAuthor: 'His laconic telegram carried all the crucial military orders.',
      synonyms: ['terse', 'concise', 'succinct'],
      antonyms: ['verbose', 'garrulous', 'loquacious'],
    ),
    const DailyDoseItem(
      type: DailyItemType.word,
      title: 'Meticulous',
      category: 'Adjective',
      meaning: 'Showing great attention to detail; very careful and precise.',
      exampleOrAuthor: 'Meticulous revision of PYQ answer keys ensures maximum marks.',
      synonyms: ['diligent', 'thorough', 'exacting'],
      antonyms: ['careless', 'hasty', 'inaccurate'],
    ),
    const DailyDoseItem(
      type: DailyItemType.word,
      title: 'Perspicacious',
      category: 'Adjective',
      meaning: 'Having a ready insight into and understanding of things; shrewd.',
      exampleOrAuthor: 'A perspicacious candidate quickly spots hidden traps in reasoning questions.',
      synonyms: ['astute', 'discerning', 'perceptive'],
      antonyms: ['obtuse', 'unperceptive', 'dull'],
    ),
    const DailyDoseItem(
      type: DailyItemType.word,
      title: 'Sagacious',
      category: 'Adjective',
      meaning: 'Having or showing keen mental discernment and good judgment; wise.',
      exampleOrAuthor: 'The sagacious tribal elders resolved village boundary disputes peacefully.',
      synonyms: ['wise', 'knowledgeable', 'insightful'],
      antonyms: ['foolish', 'ignorant', 'naive'],
    ),
    const DailyDoseItem(
      type: DailyItemType.word,
      title: 'Tenacious',
      category: 'Adjective',
      meaning: 'Tending to keep a firm hold of something; persistent and resolute.',
      exampleOrAuthor: 'Tenacious daily practice is the secret behind clearing competitive exams.',
      synonyms: ['persistent', 'resolute', 'dogged'],
      antonyms: ['yielding', 'irresolute', 'surrendering'],
    ),
  ];

  static final List<DailyDoseItem> idioms = [
    const DailyDoseItem(
      type: DailyItemType.idiom,
      title: 'A blessing in disguise',
      category: 'Idiom & Phrase',
      meaning: 'An apparent misfortune or setback that eventually has good or positive results.',
      exampleOrAuthor: 'Missing the earlier notification was a blessing in disguise, as it gave him time for thorough preparation.',
    ),
    const DailyDoseItem(
      type: DailyItemType.idiom,
      title: 'Achilles heel',
      category: 'Idiom & Phrase',
      meaning: 'A weakness or vulnerable point in an otherwise strong situation or person.',
      exampleOrAuthor: 'Time management during General English was his Achilles heel in the previous exam.',
    ),
    const DailyDoseItem(
      type: DailyItemType.idiom,
      title: 'Ace in the hole',
      category: 'Idiom & Phrase',
      meaning: 'A major hidden or reserved advantage that can be deployed at the decisive moment.',
      exampleOrAuthor: 'Her mastery of Arunachal State GK was her ace in the hole for the interview round.',
    ),
    const DailyDoseItem(
      type: DailyItemType.idiom,
      title: 'Break the ice',
      category: 'Idiom & Phrase',
      meaning: 'To do or say something that relieves tension and makes people feel comfortable.',
      exampleOrAuthor: 'The interview chairperson cracked a warm joke to break the ice before formal questioning.',
    ),
    const DailyDoseItem(
      type: DailyItemType.idiom,
      title: 'Bolt from the blue',
      category: 'Idiom & Phrase',
      meaning: 'A sudden, unexpected, and shocking event or piece of news.',
      exampleOrAuthor: 'The surprise announcement of exam dates came as a bolt from the blue for unprepared aspirants.',
    ),
    const DailyDoseItem(
      type: DailyItemType.idiom,
      title: 'Burn the midnight oil',
      category: 'Idiom & Phrase',
      meaning: 'To read, work, or study late into the night.',
      exampleOrAuthor: 'He burned the midnight oil for three solid months before clearing APSSB CGL.',
    ),
    const DailyDoseItem(
      type: DailyItemType.idiom,
      title: 'Back to the drawing board',
      category: 'Idiom & Phrase',
      meaning: 'Starting an idea or strategy all over again after a previous attempt failed.',
      exampleOrAuthor: 'When his formula shortcut failed in the mock test, he went back to the drawing board.',
    ),
    const DailyDoseItem(
      type: DailyItemType.idiom,
      title: 'Bite off more than you can chew',
      category: 'Idiom & Phrase',
      meaning: 'To take on a commitment or task that is far too large or difficult to manage.',
      exampleOrAuthor: 'Do not try to master 10 new topics in one night and bite off more than you can chew.',
    ),
    const DailyDoseItem(
      type: DailyItemType.idiom,
      title: 'Cool as a cucumber',
      category: 'Idiom & Phrase',
      meaning: 'Composed, calm, and untroubled, even under extreme pressure or stress.',
      exampleOrAuthor: 'She remained cool as a cucumber throughout the 2-hour APPSC Prelims paper.',
    ),
    const DailyDoseItem(
      type: DailyItemType.idiom,
      title: 'Hit the nail on the head',
      category: 'Idiom & Phrase',
      meaning: 'To describe exactly what is causing a situation or to state the precise truth.',
      exampleOrAuthor: 'The mentor hit the nail on the head by identifying negative marking as his weak spot.',
    ),
    const DailyDoseItem(
      type: DailyItemType.idiom,
      title: 'Leave no stone unturned',
      category: 'Idiom & Phrase',
      meaning: 'To do everything possible and explore every avenue to achieve a goal.',
      exampleOrAuthor: 'He left no stone unturned in revising the entire Arunachal Pradesh history curriculum.',
    ),
    const DailyDoseItem(
      type: DailyItemType.idiom,
      title: 'Through thick and thin',
      category: 'Idiom & Phrase',
      meaning: 'Under all circumstances, no matter how difficult or challenging they may be.',
      exampleOrAuthor: 'His family supported his civil service dreams through thick and thin.',
    ),
    const DailyDoseItem(
      type: DailyItemType.idiom,
      title: 'Spill the beans',
      category: 'Idiom & Phrase',
      meaning: 'To disclose a secret or reveal confidential information prematurely.',
      exampleOrAuthor: 'The question paper setter was strictly guarded so no one could spill the beans.',
    ),
  ];

  static final List<DailyDoseItem> quotes = [
    const DailyDoseItem(
      type: DailyItemType.quote,
      title: 'Dream is not that which you see while sleeping, it is something that does not let you sleep.',
      category: 'Inspirational Quote',
      meaning: 'True passion and ambition require unwavering dedication and active daily discipline.',
      exampleOrAuthor: '— Dr. A.P.J. Abdul Kalam',
    ),
    const DailyDoseItem(
      type: DailyItemType.quote,
      title: 'Arise, awake, and stop not till the goal is reached.',
      category: 'Inspirational Quote',
      meaning: 'Never relent in your hard work until you have achieved your highest destination in life.',
      exampleOrAuthor: '— Swami Vivekananda',
    ),
    const DailyDoseItem(
      type: DailyItemType.quote,
      title: 'Cultivation of mind should still be the ultimate aim of human existence.',
      category: 'Inspirational Quote',
      meaning: 'Continuous learning and mental sharpness are the greatest foundation for public leadership.',
      exampleOrAuthor: '— Dr. B.R. Ambedkar',
    ),
    const DailyDoseItem(
      type: DailyItemType.quote,
      title: 'It always seems impossible until it is done.',
      category: 'Inspirational Quote',
      meaning: 'Every monumental target appears daunting at the start; consistency transforms it into reality.',
      exampleOrAuthor: '— Nelson Mandela',
    ),
    const DailyDoseItem(
      type: DailyItemType.quote,
      title: 'Success is no accident. It is hard work, perseverance, learning, studying, and sacrifice.',
      category: 'Inspirational Quote',
      meaning: 'Excellence in competitive exams is the cumulative result of daily deliberate effort.',
      exampleOrAuthor: '— Pelé',
    ),
    const DailyDoseItem(
      type: DailyItemType.quote,
      title: 'The secret of getting ahead is getting started.',
      category: 'Inspirational Quote',
      meaning: 'Procrastination disappears the moment you open your books and solve the first question.',
      exampleOrAuthor: '— Mark Twain',
    ),
    const DailyDoseItem(
      type: DailyItemType.quote,
      title: 'You don\'t have to be great to start, but you have to start to be great.',
      category: 'Inspirational Quote',
      meaning: 'Take action today, however modest, and let compounding effort forge your expertise.',
      exampleOrAuthor: '— Zig Ziglar',
    ),
  ];

  /// Rotates based on calendar day or allows manual random shuffle
  static DailyDoseItem getTodayItem(DailyItemType type, [int offset = 0]) {
    final dayIndex = (DateTime.now().difference(DateTime(2024, 1, 1)).inDays + offset);
    switch (type) {
      case DailyItemType.word:
        return words[dayIndex.abs() % words.length];
      case DailyItemType.idiom:
        return idioms[dayIndex.abs() % idioms.length];
      case DailyItemType.quote:
        return quotes[dayIndex.abs() % quotes.length];
    }
  }

  static DailyDoseItem getRandomItem() {
    final rng = math.Random();
    final all = [...words, ...idioms, ...quotes];
    return all[rng.nextInt(all.length)];
  }
}
