import 'state_gk_data.dart';

/// General Studies chapters from the APPSC CCE prelims syllabus, alongside the
/// Arunachal chapters in [StateGkData]. Two-column [StateGkChapter.keyFacts]
/// tables double as "match the pair" quizzes in the Learn feed, so every row
/// is a single, settled fact.
class NationalGkData {
  static const List<StateGkChapter> chapters = [
    StateGkChapter(
      id: 'pol1',
      title: 'Indian Polity: Making of the Constitution',
      subtitle: 'Constituent Assembly, Preamble, sources and schedules',
      category: 'Polity',
      highlights: [
        'The Constituent Assembly first met on 9 December 1946; Dr Rajendra Prasad was elected its permanent Chairman on 11 December 1946.',
        'Dr B.R. Ambedkar chaired the Drafting Committee (set up 29 August 1947).',
        'The Constitution was adopted on 26 November 1949 (Constitution Day) and came into force on 26 January 1950 (Republic Day).',
        'The original Constitution had 395 Articles, 22 Parts and 8 Schedules; today there are 12 Schedules.',
        'The Preamble has been amended only once: the 42nd Amendment (1976) added "Socialist", "Secular" and "Integrity".',
        'Arunachal Pradesh is NOT a Sixth Schedule state. The Sixth Schedule covers tribal areas of Assam, Meghalaya, Tripura and Mizoram.',
        'Article 371H gives the Governor of Arunachal Pradesh special responsibility for law and order (55th Amendment, 1986).',
      ],
      keyFacts: [
        {'Feature': 'Parliamentary system', 'Borrowed from': 'United Kingdom'},
        {'Feature': 'Fundamental Rights', 'Borrowed from': 'United States'},
        {'Feature': 'Directive Principles', 'Borrowed from': 'Ireland'},
        {
          'Feature': 'Suspension of rights in Emergency',
          'Borrowed from': 'Germany (Weimar)'
        },
        {'Feature': 'Concurrent List', 'Borrowed from': 'Australia'},
        {'Feature': 'Amendment procedure', 'Borrowed from': 'South Africa'},
        {'Feature': 'Fundamental Duties', 'Borrowed from': 'USSR'},
        {'Feature': 'Residuary powers with Centre', 'Borrowed from': 'Canada'},
      ],
    ),
    StateGkChapter(
      id: 'pol2',
      title: 'Indian Polity: Key Articles',
      subtitle: 'Rights, duties, emergency and the offices of State',
      category: 'Polity',
      highlights: [
        'Fundamental Rights: Part III, Articles 12–35. Ambedkar called Article 32 (constitutional remedies) the "heart and soul" of the Constitution.',
        'Directive Principles of State Policy: Part IV, Articles 36–51.',
        'Fundamental Duties: Part IV-A, Article 51A, added by the 42nd Amendment (1976) on the Swaran Singh Committee\'s advice. There are 11 duties; the 11th was added by the 86th Amendment (2002).',
        'Article 21A (Right to Education, ages 6–14) was added by the 86th Amendment (2002).',
        'The Vice-President is the ex-officio Chairman of the Rajya Sabha.',
        'Rajya Sabha: maximum 250 members (238 elected + 12 nominated by the President).',
      ],
      keyFacts: [
        {'Article': 'Article 14', 'Subject': 'Equality before law'},
        {'Article': 'Article 17', 'Subject': 'Abolition of untouchability'},
        {
          'Article': 'Article 19',
          'Subject': 'Six freedoms (speech, assembly, etc.)'
        },
        {
          'Article': 'Article 21',
          'Subject': 'Protection of life and personal liberty'
        },
        {
          'Article': 'Article 32',
          'Subject': 'Right to constitutional remedies'
        },
        {'Article': 'Article 44', 'Subject': 'Uniform Civil Code'},
        {'Article': 'Article 51A', 'Subject': 'Fundamental Duties'},
        {
          'Article': 'Article 72',
          'Subject': 'Pardoning power of the President'
        },
        {'Article': 'Article 110', 'Subject': 'Definition of Money Bill'},
        {
          'Article': 'Article 112',
          'Subject': 'Annual Financial Statement (Budget)'
        },
        {'Article': 'Article 280', 'Subject': 'Finance Commission'},
        {'Article': 'Article 324', 'Subject': 'Election Commission'},
        {'Article': 'Article 352', 'Subject': 'National Emergency'},
        {'Article': 'Article 356', 'Subject': 'President\'s Rule in states'},
        {'Article': 'Article 360', 'Subject': 'Financial Emergency'},
        {
          'Article': 'Article 371H',
          'Subject': 'Special provision for Arunachal Pradesh'
        },
      ],
    ),
    StateGkChapter(
      id: 'pol3',
      title: 'Indian Polity: Landmark Amendments',
      subtitle: 'The amendments examiners ask about most',
      category: 'Polity',
      highlights: [
        'The 42nd Amendment (1976) is called the "Mini Constitution".',
        'The 44th Amendment (1978) removed the Right to Property from Fundamental Rights; it is now a legal right under Article 300A.',
        'The 73rd and 74th Amendments (1992) gave constitutional status to Panchayats (Part IX) and Municipalities (Part IX-A).',
        'The 106th Amendment (2023), "Nari Shakti Vandan Adhiniyam", reserves one-third of seats in the Lok Sabha and state assemblies for women.',
      ],
      keyFacts: [
        {
          'Amendment': '42nd (1976)',
          'Change':
              'Socialist, Secular, Integrity in Preamble; Fundamental Duties'
        },
        {
          'Amendment': '44th (1978)',
          'Change': 'Right to Property removed from Fundamental Rights'
        },
        {
          'Amendment': '52nd (1985)',
          'Change': 'Anti-defection law (Tenth Schedule)'
        },
        {
          'Amendment': '55th (1986)',
          'Change': 'Statehood for Arunachal Pradesh (Article 371H)'
        },
        {
          'Amendment': '61st (1988)',
          'Change': 'Voting age lowered from 21 to 18'
        },
        {'Amendment': '73rd (1992)', 'Change': 'Panchayati Raj'},
        {'Amendment': '74th (1992)', 'Change': 'Urban local bodies'},
        {
          'Amendment': '86th (2002)',
          'Change': 'Right to Education (Article 21A)'
        },
        {'Amendment': '101st (2016)', 'Change': 'Goods and Services Tax'},
        {'Amendment': '103rd (2019)', 'Change': '10% reservation for EWS'},
        {
          'Amendment': '106th (2023)',
          'Change': 'One-third seats for women in legislatures'
        },
      ],
    ),
    StateGkChapter(
      id: 'his1',
      title: 'Modern India: The Freedom Struggle',
      subtitle: 'From 1857 to Independence',
      category: 'History',
      highlights: [
        'The Revolt of 1857 began at Meerut on 10 May 1857.',
        'The Indian National Congress was founded in 1885 by A.O. Hume; its first session was held in Bombay under W.C. Bonnerjee.',
        'Lord Curzon partitioned Bengal in 1905; it was annulled in 1911.',
        'Purna Swaraj was declared at the Lahore session of 1929 under Jawaharlal Nehru; 26 January 1930 was observed as Independence Day.',
        'The Quit India Movement was launched on 8 August 1942 at Gowalia Tank, Bombay, with the call "Do or Die".',
        'Subhas Chandra Bose proclaimed the Provisional Government of Azad Hind in Singapore in October 1943.',
      ],
      keyFacts: [
        {'Event': 'Partition of Bengal', 'Year': '1905'},
        {'Event': 'All India Muslim League founded (Dhaka)', 'Year': '1906'},
        {'Event': 'Surat Split of Congress', 'Year': '1907'},
        {'Event': 'Gandhi returns from South Africa', 'Year': '1915'},
        {'Event': 'Champaran Satyagraha', 'Year': '1917'},
        {'Event': 'Jallianwala Bagh massacre', 'Year': '1919'},
        {'Event': 'Chauri Chaura incident', 'Year': '1922'},
        {'Event': 'Simon Commission arrives', 'Year': '1928'},
        {'Event': 'Dandi March', 'Year': '1930'},
        {'Event': 'Poona Pact', 'Year': '1932'},
        {'Event': 'Quit India Movement', 'Year': '1942'},
        {'Event': 'Cabinet Mission', 'Year': '1946'},
      ],
    ),
    StateGkChapter(
      id: 'his2',
      title: 'History of the Northeast Frontier',
      subtitle: 'Treaties, lines and wars that shaped Arunachal',
      category: 'History',
      highlights: [
        'The Treaty of Yandabo (1826) ended the First Anglo-Burmese War and brought Assam under British control.',
        'The Inner Line Permit system comes from the Bengal Eastern Frontier Regulation, 1873. Indians from outside the state still need an ILP to enter Arunachal.',
        'The Anglo-Abor Expedition (1911–12) followed the killing of the British officer Noel Williamson in 1911.',
        'The McMahon Line was drawn at the Simla Convention (1913–14), named after Sir Henry McMahon. India treats it as the boundary with Tibet; China rejects it.',
        'The Sino-Indian War was fought from 20 October to 21 November 1962, with major battles at Bum La, Sela and Walong.',
      ],
      keyFacts: [
        {'Event': 'Treaty of Yandabo', 'Year': '1826'},
        {
          'Event': 'Bengal Eastern Frontier Regulation (Inner Line)',
          'Year': '1873'
        },
        {'Event': 'Anglo-Abor Expedition', 'Year': '1911–12'},
        {'Event': 'Simla Convention (McMahon Line)', 'Year': '1914'},
        {'Event': 'NEFA formed', 'Year': '1954'},
        {'Event': 'Sino-Indian War', 'Year': '1962'},
        {'Event': 'Union Territory of Arunachal Pradesh', 'Year': '1972'},
        {'Event': 'Statehood', 'Year': '1987'},
      ],
    ),
    StateGkChapter(
      id: 'geo1',
      title: 'Geography of India',
      subtitle: 'Physical features, rivers and the Northeast',
      category: 'Geography',
      highlights: [
        'Indian Standard Time is UTC+5:30, based on the 82°30′E meridian near Mirzapur.',
        'The Tropic of Cancer passes through 8 states: Gujarat, Rajasthan, Madhya Pradesh, Chhattisgarh, Jharkhand, West Bengal, Tripura and Mizoram.',
        'The Brahmaputra is the Yarlung Tsangpo in Tibet and the Siang (Dihang) in Arunachal. It becomes the Brahmaputra after the Dibang and Lohit join near Sadiya, and the Jamuna in Bangladesh.',
        'The Siliguri Corridor ("Chicken\'s Neck"), about 20–22 km wide, links the Northeast to the rest of India.',
        'Majuli (Assam) is India\'s largest river island. Mawsynram (Meghalaya) is among the wettest places on Earth.',
        'Keibul Lamjao on Loktak Lake (Manipur) is the only floating national park in the world.',
        'Largest state by area: Rajasthan. Smallest: Goa. Most populous (Census 2011): Uttar Pradesh.',
      ],
      keyFacts: [
        {'Feature': 'Longest river in India', 'Answer': 'Ganga'},
        {'Feature': 'Largest river island', 'Answer': 'Majuli (Assam)'},
        {
          'Feature': 'Only floating national park',
          'Answer': 'Keibul Lamjao (Manipur)'
        },
        {
          'Feature': 'One-horned rhino stronghold',
          'Answer': 'Kaziranga (Assam)'
        },
        {'Feature': 'Largest state by area', 'Answer': 'Rajasthan'},
        {'Feature': 'Smallest state by area', 'Answer': 'Goa'},
        {'Feature': 'Highest peak of Arunachal', 'Answer': 'Kangto'},
        {'Feature': 'Easternmost village of India', 'Answer': 'Dong (Anjaw)'},
      ],
    ),
    StateGkChapter(
      id: 'eco1',
      title: 'Indian Economy Essentials',
      subtitle: 'Institutions, plans, banking and taxation',
      category: 'Economy',
      highlights: [
        'The Reserve Bank of India was set up on 1 April 1935 on the Hilton Young Commission\'s advice, and nationalised in 1949.',
        'NITI Aayog replaced the Planning Commission (1950) on 1 January 2015. The Prime Minister is its Chairperson.',
        'GST came into force on 1 July 2017 through the 101st Amendment. The GST Council is set up under Article 279A.',
        'Repo rate: the rate at which the RBI lends to banks. Reverse repo: the rate at which the RBI borrows from banks.',
        'CRR is the share of deposits banks keep with the RBI as cash. SLR is the share they keep themselves as cash, gold or approved securities.',
        'The First Five-Year Plan (1951–56) stressed agriculture. The Second (1956–61), based on the Mahalanobis model, stressed heavy industry. The Twelfth (2012–17) was the last.',
        '14 banks were nationalised in 1969 and 6 more in 1980.',
        'UPI was launched in 2016 by NPCI. Pradhan Mantri Jan Dhan Yojana (2014) is the financial-inclusion mission.',
      ],
      keyFacts: [
        {'Term': 'Repo rate', 'Meaning': 'RBI lends to commercial banks'},
        {
          'Term': 'Reverse repo rate',
          'Meaning': 'RBI borrows from commercial banks'
        },
        {'Term': 'CRR', 'Meaning': 'Cash banks must keep with the RBI'},
        {'Term': 'SLR', 'Meaning': 'Liquid assets banks must keep themselves'},
        {
          'Term': 'Fiscal deficit',
          'Meaning': 'Total expenditure minus receipts excluding borrowings'
        },
        {
          'Term': 'Inflation',
          'Meaning': 'Sustained rise in the general price level'
        },
        {
          'Term': 'GDP',
          'Meaning':
              'Value of final goods and services produced within a country'
        },
      ],
    ),
    StateGkChapter(
      id: 'env1',
      title: 'Environment & Ecology',
      subtitle: 'Laws, conventions, projects and hotspots',
      category: 'Environment',
      highlights: [
        'India has four biodiversity hotspots: the Himalaya, Indo-Burma, the Western Ghats & Sri Lanka, and Sundaland (Nicobar Islands). Arunachal falls in the Himalaya and Indo-Burma hotspots.',
        'Project Tiger began in 1973; Jim Corbett was the first tiger reserve. Project Elephant began in 1992.',
        'The Environment (Protection) Act, 1986 came after the Bhopal gas tragedy (1984).',
        'The National Green Tribunal was set up in 2010.',
        'The ozone layer lies in the stratosphere. The Montreal Protocol (1987) phases out ozone-depleting substances.',
      ],
      keyFacts: [
        {'Law / Treaty': 'Wildlife (Protection) Act', 'Year': '1972'},
        {'Law / Treaty': 'Forest (Conservation) Act', 'Year': '1980'},
        {'Law / Treaty': 'Environment (Protection) Act', 'Year': '1986'},
        {'Law / Treaty': 'Biological Diversity Act', 'Year': '2002'},
        {'Law / Treaty': 'Ramsar Convention (wetlands)', 'Year': '1971'},
        {'Law / Treaty': 'Montreal Protocol (ozone)', 'Year': '1987'},
        {'Law / Treaty': 'Kyoto Protocol', 'Year': '1997'},
        {'Law / Treaty': 'Paris Agreement', 'Year': '2015'},
      ],
    ),
  ];
}
