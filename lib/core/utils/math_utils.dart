class MathUtils {
  MathUtils._();

  static String cleanQuestionText(String text, [int? currentQNum]) {
    var cleaned = text.trim();
    cleaned = cleaned.replaceFirst(
      RegExp(r'''^(?:Q\s*\d+[\.:\)\s]+|\d+[\.:\)\s]+)''', caseSensitive: false),
      '',
    ).trim();
    if (currentQNum != null && currentQNum > 0) {
      cleaned = formatDirectionRange(cleaned, currentQNum);
    }
    return formatMath(cleaned);
  }

  /// Dynamically replaces hardcoded direction question numbers (e.g. "Q. No. 90 and 91")
  /// with the test's actual dynamic question numbers (e.g. "Q. No. 1 to 2")
  static String formatDirectionRange(String text, int displayStart, [int? displayEnd]) {
    if (text.isEmpty) return text;
    final rangeText = (displayEnd != null && displayEnd > displayStart)
        ? '$displayStart to $displayEnd'
        : '$displayStart';

    var s = text.replaceAllMapped(
      RegExp(r'(?:Q\.?\s*(?:No\.?|Nos\.?)?\s*)\d+\s*(?:to|and|&|-|–|—)\s*\d+', caseSensitive: false),
      (_) => 'Q. No. $rangeText',
    );
    // Also match standalone "(Q. No. 90)" or "Q. 90"
    s = s.replaceAllMapped(
      RegExp(r'(?:Q\.?\s*(?:No\.?|Nos\.?)?\s*)\d+\b', caseSensitive: false),
      (_) => 'Q. No. $rangeText',
    );
    return formatMath(s);
  }

  static String formatMath(String text) {
    if (text.isEmpty) return text;
    var s = text;

    s = s.replaceAllMapped(
      RegExp(r'''[/\\]text\{?([a-zA-Z]+)\}?''', caseSensitive: false),
      (m) => m[1]!.toLowerCase(),
    );
    s = s.replaceAll(r'\cosec', 'cosec').replaceAll(r'\sin', 'sin').replaceAll(r'\cos', 'cos')
        .replaceAll(r'\tan', 'tan').replaceAll(r'\cot', 'cot').replaceAll(r'\sec', 'sec')
        .replaceAll(r'\log', 'log').replaceAll(r'\ln', 'ln');

    s = s.replaceAll(r'\theta', 'θ').replaceAll(r'\alpha', 'α').replaceAll(r'\beta', 'β')
        .replaceAll(r'\gamma', 'γ').replaceAll(r'\lambda', 'λ').replaceAll(r'\pi', 'π')
        .replaceAll(r'\phi', 'φ').replaceAll(r'\omega', 'ω').replaceAll(r'\mu', 'μ')
        .replaceAll(r'\sigma', 'σ').replaceAll(r'\rho', 'ρ').replaceAll(r'\Delta', 'Δ')
        .replaceAll(r'\delta', 'δ');

    s = s.replaceAll(r'^\circ', '°').replaceAll(r'^{\circ}', '°').replaceAll(r'\circ', '°')
        .replaceAll(r'\angle', '∠');

    s = s.replaceAll(r'\triangle', '△').replaceAll(r'\Triangle', '△');
    s = s.replaceAllMapped(RegExp(r'''\bIriangl[a-z]*\b''', caseSensitive: false), (_) => '△');
    s = s.replaceAll('[triangle]', '△').replaceAll('[Triangle]', '△').replaceAll('[TRIANGLE]', '△');

    s = s.replaceAll(r'\parallel', '∥').replaceAll(r'\perp', '⊥').replaceAll(r'\sim', '∼')
        .replaceAll(r'\cong', '≅').replaceAll(r'\square', '□');

    s = s.replaceAll(r'\times', '×').replaceAll(r'\cdot', '·').replaceAll(r'\div', '÷')
        .replaceAll(r'\pm', '±').replaceAll(r'\mp', '∓').replaceAll(r'\le', '≤')
        .replaceAll(r'\leq', '≤').replaceAll(r'\ge', '≥').replaceAll(r'\geq', '≥')
        .replaceAll(r'\ne', '≠').replaceAll(r'\neq', '≠').replaceAll(r'\approx', '≈')
        .replaceAll(r'\infty', '∞').replaceAll(r'\in', '∈').replaceAll(r'\notin', '∉')
        .replaceAll(r'\subset', '⊂').replaceAll(r'\subseteq', '⊆').replaceAll(r'\cap', '∩')
        .replaceAll(r'\cup', '∪').replaceAll(r'\therefore', '∴').replaceAll(r'\because', '∵');

    s = s.replaceAllMapped(RegExp(r'''\\sqrt\{([^}]+)\}'''), (m) => '√(${m[1]})').replaceAll(r'\sqrt', '√');
    s = s.replaceAllMapped(RegExp(r'''\\frac\{([^}]+)\}\{([^}]+)\}'''), (m) => '(${m[1]}/${m[2]})');

    s = s.replaceAllMapped(RegExp(r'''\^\{?([0-9])\}?'''), (m) {
      const sup = ['⁰','¹','²','³','⁴','⁵','⁶','⁷','⁸','⁹'];
      final i = int.tryParse(m[1]!);
      return (i != null && i < sup.length) ? sup[i] : '^${m[1]}';
    });

    s = s.replaceAllMapped(RegExp(r'''_\{?([0-9])\}?'''), (m) {
      const sub = ['₀','₁','₂','₃','₄','₅','₆','₇','₈','₉'];
      final i = int.tryParse(m[1]!);
      return (i != null && i < sub.length) ? sub[i] : '_${m[1]}';
    });

    s = s.replaceAll('{', '').replaceAll('}', '');
    s = s.replaceAll(r'$', '');
    s = s.replaceAll(RegExp(r'\s{2,}'), ' ');
    return s.trim();
  }
}
