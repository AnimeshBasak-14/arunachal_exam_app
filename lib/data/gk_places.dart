/// Places shown on the GK map.
///
/// Coordinates come from Wikidata (P625), except Tato and Zemithang which come
/// from OpenStreetMap; all were checked on 29 Oct 2026. Places whose
/// coordinates couldn't be confirmed (e.g. Napangphung, Ganga Lake) are left
/// off the map rather than guessed. [wiki] is the English Wikipedia title used
/// to load a live photo and summary.
enum PlaceKind { capital, district, heritage, nature, border, water }

extension PlaceKindLabel on PlaceKind {
  String get label => switch (this) {
        PlaceKind.capital => 'Capital',
        PlaceKind.district => 'District HQ',
        PlaceKind.heritage => 'History & faith',
        PlaceKind.nature => 'Parks & wildlife',
        PlaceKind.border => 'Passes & borders',
        PlaceKind.water => 'Rivers, lakes & dams',
      };
}

class GkPlace {
  final String name;
  final String wiki;
  final double lat;
  final double lng;
  final PlaceKind kind;
  final String district;
  final List<String> facts;

  const GkPlace(this.name, this.wiki, this.lat, this.lng, this.kind,
      this.district, this.facts);
}

const gkPlaces = <GkPlace>[
  // ── Capital region ──────────────────────────────────────────────────────
  GkPlace('Itanagar', 'Itanagar', 27.1000, 93.6200, PlaceKind.capital,
      'Itanagar Capital Complex', [
    'State capital; the capital moved here from Shillong in 1974.',
    'Named after Ita Fort, the "fort of bricks".',
  ]),
  GkPlace('Ita Fort', 'Ita Fort', 27.0920, 93.6320, PlaceKind.heritage,
      'Itanagar Capital Complex', [
    'Brick fort generally dated to the 14th–15th century.',
    'Gives the capital its name.',
  ]),
  GkPlace('Donyi Polo Airport, Hollongi', 'Donyi Polo Airport, Itanagar',
      26.9700, 93.6647, PlaceKind.capital, 'Papum Pare', [
    'First greenfield airport of Arunachal; inaugurated 19 Nov 2022.',
    '"Donyi Polo" = Sun and Moon, the indigenous faith of the Tani tribes.',
  ]),
  GkPlace('Rajiv Gandhi University', 'Rajiv Gandhi University', 27.1472,
      93.7669, PlaceKind.capital, 'Papum Pare', [
    'At Rono Hills, Doimukh. Founded 1984 as Arunachal University.',
    'Became a Central University in 2007.',
  ]),
  GkPlace('Itanagar Wildlife Sanctuary', 'Itanagar Wildlife Sanctuary',
      27.0685, 93.5814, PlaceKind.nature, 'Papum Pare', [
    'Sanctuary on the edge of the capital.',
  ]),

  // ── District headquarters (west → east) ─────────────────────────────────
  GkPlace('Tawang', 'Tawang', 27.5883, 91.8653, PlaceKind.district, 'Tawang', [
    'HQ of Tawang, the westernmost district.',
    'Birthplace of the 6th Dalai Lama, Tsangyang Gyatso.',
    'Monpa heartland; Losar and Torgya are major festivals.',
  ]),
  GkPlace('Bomdila', 'Bomdila', 27.2628, 92.4211, PlaceKind.district,
      'West Kameng', ['HQ of West Kameng.']),
  GkPlace('Seppa', 'Seppa', 27.3500, 93.0456, PlaceKind.district, 'East Kameng',
      ['HQ of East Kameng, on the Kameng river.']),
  GkPlace('Lemmi', 'Lemmi', 27.1600, 93.2200, PlaceKind.district,
      'Pakke-Kessang', ['HQ of Pakke-Kessang (created 2018).']),
  GkPlace('Yupia', 'Yupia', 27.1692, 93.7431, PlaceKind.district, 'Papum Pare',
      ['HQ of Papum Pare, the most populous district (Census 2011).']),
  GkPlace('Ziro', 'Ziro', 27.5950, 93.8385, PlaceKind.district,
      'Lower Subansiri', [
    'HQ of Lower Subansiri; home of the Apatani tribe.',
    'Apatani cultural landscape is on UNESCO\'s Tentative List.',
    'Known for paddy-cum-fish farming and the Ziro Festival of Music.',
    'Dree (July) and Myoko are the main Apatani festivals.',
  ]),
  GkPlace('Yachuli', 'Yachuli', 27.5142, 93.7810, PlaceKind.district,
      'Keyi Panyor', ['HQ of Keyi Panyor, one of the two newest districts (March 2024).']),
  GkPlace('Koloriang', 'Koloriang', 27.9167, 93.3500, PlaceKind.district,
      'Kurung Kumey', ['HQ of Kurung Kumey.']),
  GkPlace('Palin', 'Palin, Arunachal Pradesh', 27.7039, 93.6910,
      PlaceKind.district, 'Kra Daadi', ['HQ of Kra Daadi (created 2015).']),
  GkPlace('Raga', 'Raga, Arunachal Pradesh', 27.8000, 94.0750,
      PlaceKind.district, 'Kamle', ['HQ of Kamle (created 2017).']),
  GkPlace('Daporijo', 'Daporijo', 27.9861, 94.2217, PlaceKind.district,
      'Upper Subansiri', ['HQ of Upper Subansiri, on the Subansiri river.']),
  GkPlace('Basar', 'Basar, Arunachal Pradesh', 27.9833, 94.6667,
      PlaceKind.district, 'Lepa Rada', ['HQ of Lepa Rada (created 2018).']),
  GkPlace('Likabali', 'Likabali', 27.6590, 94.6920, PlaceKind.district,
      'Lower Siang', ['HQ of Lower Siang (created 2017).']),
  GkPlace('Aalo', 'Aalo', 28.1700, 94.7700, PlaceKind.district, 'West Siang', [
    'HQ of West Siang (also written Along).',
    'Galo heartland; Mopin is celebrated in April.',
  ]),
  GkPlace('Tato', 'Tato, Arunachal Pradesh', 28.5315, 94.3753,
      PlaceKind.district, 'Shi-Yomi', ['HQ of Shi-Yomi (created 2018).']),
  GkPlace('Mechuka', 'Mechuka', 28.6050, 94.1281, PlaceKind.district,
      'Shi-Yomi', [
    'Valley on the Yargyap Chu (Siyom) river, near the border.',
    'Has an Advanced Landing Ground used by the Indian Air Force.',
  ]),
  GkPlace('Boleng', 'Boleng', 28.3350, 94.9610, PlaceKind.district, 'Siang',
      ['HQ of Siang (created 2015); Pangin served as temporary HQ.']),
  GkPlace('Pasighat', 'Pasighat', 28.0619, 95.3259, PlaceKind.district,
      'East Siang', [
    'Oldest town of Arunachal, founded in 1911.',
    'On the Siang (Brahmaputra) as it enters the plains.',
    'Adi heartland; Solung is celebrated in September.',
  ]),
  GkPlace('Yingkiong', 'Yingkiong', 28.6104, 95.0475, PlaceKind.district,
      'Upper Siang', ['HQ of Upper Siang; gateway to Mouling National Park.']),
  GkPlace('Roing', 'Roing', 28.1428, 95.8428, PlaceKind.district,
      'Lower Dibang Valley', ['HQ of Lower Dibang Valley; Idu Mishmi homeland.']),
  GkPlace('Anini', 'Anini', 28.7833, 95.8833, PlaceKind.district,
      'Dibang Valley', [
    'HQ of Dibang Valley, the largest district by area.',
    'Dibang Valley is the least populous district in India (8,004, Census 2011).',
  ]),
  GkPlace('Tezu', 'Tezu', 27.9167, 96.1667, PlaceKind.district, 'Lohit',
      ['HQ of Lohit; Mishmi homeland.']),
  GkPlace('Hawai', 'Hawai, Arunachal Pradesh', 27.8858, 96.8008,
      PlaceKind.district, 'Anjaw', ['HQ of Anjaw, the easternmost district.']),
  GkPlace('Namsai', 'Namsai district', 27.6689, 95.8714, PlaceKind.district,
      'Namsai', ['HQ of Namsai; Tai Khamti homeland. Sangken is the water festival.']),
  GkPlace('Changlang', 'Changlang', 27.1200, 95.7100, PlaceKind.district,
      'Changlang', ['HQ of Changlang; Tangsa, Tutsa and Singpho communities.']),
  GkPlace('Khonsa', 'Khonsa', 27.0200, 95.5700, PlaceKind.district, 'Tirap',
      ['HQ of Tirap; Nocte homeland. Chalo-Loku is the harvest festival.']),
  GkPlace('Longding', 'Longding district', 26.8585, 95.3357, PlaceKind.district,
      'Longding', ['Carved out of Tirap in 2012; Wancho homeland, known for wood carving.']),

  // ── History & faith ─────────────────────────────────────────────────────
  GkPlace('Tawang Monastery', 'Tawang Monastery', 27.5864, 91.8575,
      PlaceKind.heritage, 'Tawang', [
    'Largest monastery in India; also called Galden Namgey Lhatse.',
    'Founded c. 1680 by Merak Lama Lodre Gyatso, at the wish of the 5th Dalai Lama.',
  ]),
  GkPlace('Parshuram Kund', 'Parshuram Kund', 27.8775, 96.3592,
      PlaceKind.heritage, 'Lohit', [
    'Pilgrimage pool on the Lohit river.',
    'Legend: sage Parshuram washed away his sin here.',
    'Large mela on Makar Sankranti (January).',
  ]),
  GkPlace('Malinithan', 'Malinithan', 27.6567, 94.7058, PlaceKind.heritage,
      'Lower Siang', [
    'Ruins of a stone temple near Likabali.',
    'Legend links it to Lord Krishna and Rukmini resting here.',
  ]),
  GkPlace('Bhismaknagar', 'Bhismaknagar', 28.0483, 96.0045, PlaceKind.heritage,
      'Lower Dibang Valley', [
    'Archaeological brick-fort site near Roing.',
    'Linked in legend to King Bhismaka, father of Rukmini.',
  ]),
  GkPlace('Golden Pagoda, Namsai', 'Golden Pagoda, Namsai', 27.7725, 95.9749,
      PlaceKind.heritage, 'Namsai', [
    'Burmese-style Theravada Buddhist pagoda (Kongmu Kham) of the Tai Khamti.',
  ]),
  GkPlace('Walong', 'Walong', 28.1333, 97.0167, PlaceKind.heritage, 'Anjaw', [
    'Site of the Battle of Walong in the 1962 war; has a war memorial.',
  ]),
  GkPlace('Jairampur', 'Jairampur', 27.3511, 96.0158, PlaceKind.heritage,
      'Changlang', [
    'On the WWII Stilwell (Ledo) Road; has a WWII cemetery.',
  ]),
  GkPlace('Dong', 'Dong, Arunachal Pradesh', 28.1696, 97.0378,
      PlaceKind.heritage, 'Anjaw', [
    'Easternmost village: India\'s first sunrise is seen here.',
  ]),

  // ── Parks & wildlife ────────────────────────────────────────────────────
  GkPlace('Namdapha National Park', 'Namdapha National Park', 27.6498,
      96.1103, PlaceKind.nature, 'Changlang', [
    'National park and tiger reserve since 1983; about 1,985 sq km.',
    'Home to four big cats: tiger, leopard, clouded leopard and snow leopard.',
    'Also home to the hoolock gibbon, the state animal.',
  ]),
  GkPlace('Mouling National Park', 'Mouling National Park', 28.5833, 94.8667,
      PlaceKind.nature, 'Upper Siang', [
    'One of the two national parks of the state (1986).',
    'Part of the Dihang-Dibang Biosphere Reserve.',
  ]),
  GkPlace('Pakke Tiger Reserve', 'Pakke Tiger Reserve', 27.0833, 92.8583,
      PlaceKind.nature, 'Pakke-Kessang', [
    'Known for its Hornbill Nest Adoption Programme.',
    'Hosts the Pakke Paga Hornbill Festival.',
  ]),
  GkPlace('Eaglenest Wildlife Sanctuary', 'Eaglenest Wildlife Sanctuary',
      27.1000, 92.4000, PlaceKind.nature, 'West Kameng', [
    'Birding hotspot; the Bugun liocichla was described from here in 2006.',
  ]),
  GkPlace('Kamlang Tiger Reserve', 'Kamlang Wildlife Sanctuary', 27.6667,
      96.4333, PlaceKind.nature, 'Lohit', [
    'Third tiger reserve of the state, with Namdapha and Pakke.',
  ]),
  GkPlace('D\'Ering Memorial Wildlife Sanctuary',
      'D\'Ering Memorial Wildlife Sanctuary', 27.9378, 95.4458,
      PlaceKind.nature, 'East Siang', [
    'Grassland and river islands of the Siang near Pasighat.',
    'Named after Daying Ering.',
  ]),
  GkPlace('Mehao Wildlife Sanctuary', 'Mehao Wildlife Sanctuary', 28.1575,
      95.9400, PlaceKind.nature, 'Lower Dibang Valley',
      ['Around Mehao lake, near Roing.']),
  GkPlace('Dibang Wildlife Sanctuary', 'Dibang Wildlife Sanctuary', 29.0470,
      95.7900, PlaceKind.nature, 'Dibang Valley',
      ['Largest wildlife sanctuary of the state.']),
  GkPlace('Sessa Orchid Sanctuary', 'Sessa Orchid Sanctuary', 27.2000,
      92.5000, PlaceKind.nature, 'West Kameng',
      ['Orchid sanctuary; Arunachal has 500+ orchid species.']),
  GkPlace('Dihang-Dibang Biosphere Reserve', 'Dihang-Dibang Biosphere Reserve',
      27.9833, 94.5000, PlaceKind.nature, 'Upper Siang · Dibang Valley', [
    'The state\'s biosphere reserve, declared in 1998.',
  ]),

  // ── Passes & borders ────────────────────────────────────────────────────
  GkPlace('Sela Pass', 'Sela Pass', 27.5035, 92.1045, PlaceKind.border,
      'West Kameng · Tawang', [
    'About 4,170 m; on the only road into Tawang.',
    'Sela Tunnel below the pass opened in March 2024.',
  ]),
  GkPlace('Bum La Pass', 'Bum La Pass', 27.7237, 91.8916, PlaceKind.border,
      'Tawang', [
    'India–China border pass; one of the Border Personnel Meeting points.',
    'Saw fighting in the 1962 war.',
  ]),
  GkPlace('Khenzimane (Zemithang)', 'Zemithang', 27.7107, 91.7301,
      PlaceKind.border, 'Tawang', [
    'The 14th Dalai Lama entered India near here on 31 March 1959.',
  ]),
  GkPlace('Kibithu', 'Kibithu', 28.2803, 97.0178, PlaceKind.border, 'Anjaw', [
    'Border village where the Lohit enters India.',
    'Vibrant Villages Programme was launched here in April 2023.',
  ]),
  GkPlace('Pangsau Pass', 'Pangsau Pass', 27.2333, 96.1500, PlaceKind.border,
      'Changlang', [
    'India–Myanmar pass on the Stilwell Road.',
    'The Lake of No Return is nearby; Pangsau Pass Winter Festival at Nampong.',
  ]),
  GkPlace('Mayodia Pass', 'Mayodia Pass', 28.2336, 95.9100, PlaceKind.border,
      'Lower Dibang Valley', ['High pass on the Roing–Anini road; gets snowfall.']),
  GkPlace('Vijaynagar', 'Vijaynagar, Arunachal Pradesh', 27.1919, 96.9997,
      PlaceKind.border, 'Changlang', [
    'Remote valley near the Myanmar border, long reachable mainly by air.',
  ]),
  GkPlace('Kangto', 'Kangto', 27.8650, 92.5325, PlaceKind.border,
      'East Kameng · West Kameng', [
    'Highest peak of Arunachal, about 7,090 m.',
  ]),

  // ── Rivers, lakes & dams ────────────────────────────────────────────────
  GkPlace('Sangetsar Tso (Madhuri Lake)', 'Sangestar Tso', 27.7200, 91.8200,
      PlaceKind.water, 'Tawang', [
    'Formed by the 1950 Assam–Tibet earthquake.',
    'Called Madhuri Lake after the film Koyla was shot here.',
  ]),
  GkPlace('Nuranang (Jang) Falls', 'Nuranang Falls', 27.5894, 91.9842,
      PlaceKind.water, 'Tawang', ['Waterfall near Jang, about 100 m high.']),
  GkPlace('Dibang Multipurpose Project', 'Dibang Dam', 28.3375, 95.7708,
      PlaceKind.water, 'Lower Dibang Valley', [
    '2,880 MW project by NHPC, under construction.',
    'Planned to be India\'s tallest dam.',
  ]),
  GkPlace('Subansiri Lower Project', 'Subansiri Lower Dam', 27.5524, 94.2590,
      PlaceKind.water, 'Lower Subansiri · Assam border', [
    '2,000 MW by NHPC: India\'s largest hydroelectric project.',
  ]),
  GkPlace('Dhola–Sadiya Bridge', 'Dhola–Sadiya Bridge', 27.7986, 95.6761,
      PlaceKind.water, 'Assam (gateway to eastern Arunachal)', [
    'Bhupen Hazarika Setu over the Lohit; opened 26 May 2017.',
    'Often cited as about 9.15 km long.',
  ]),
  GkPlace('Bhalukpong', 'Bhalukpong', 27.0100, 92.6500, PlaceKind.water,
      'West Kameng', [
    'Entry from Assam on the Kameng (Jia Bharali) river.',
    'Tipi Orchid Research Centre is nearby.',
  ]),
];
