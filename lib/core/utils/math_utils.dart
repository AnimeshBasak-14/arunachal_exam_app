class MathUtils {
  MathUtils._();

  /// Cleans redundant leading numbers like "Q8. Q33. ", "Q1. ", "33. "
  static String cleanQuestionText(String text) {
    var cleaned = text.trim();
    // Strip redundant leading numbering patterns: "Q33. ", "Q.33 ", "33. ", "33) "
    cleaned = cleaned.replaceFirst(
      RegExp(r'^(?:Q\s*\d+[\.\:\)\s]+|\d+[\.\:\)\s]+)', caseSensitive: false),
      '',
    ).trim();
    return formatMath(cleaned);
  }

  /// Formats LaTeX formulas into clean, readable mathematical typography
  static String formatMath(String text) {
    if (text.isEmpty) return text;

    var s = text;

    // Trigonometric functions
    s = s.replaceAll(r'\text{cosec}', 'cosec')
        .replaceAll(r'\cosec', 'cosec')
        .replaceAll(r'\text{sin}', 'sin')
        .replaceAll(r'\sin', 'sin')
        .replaceAll(r'\text{cos}', 'cos')
        .replaceAll(r'\cos', 'cos')
        .replaceAll(r'\text{tan}', 'tan')
        .replaceAll(r'\tan', 'tan')
        .replaceAll(r'\text{cot}', 'cot')
        .replaceAll(r'\cot', 'cot')
        .replaceAll(r'\text{sec}', 'sec')
        .replaceAll(r'\sec', 'sec')
        .replaceAll(r'\text{log}', 'log')
        .replaceAll(r'\log', 'log')
        .replaceAll(r'\ln', 'ln');

    // Greek symbols & angles
    s = s.replaceAll(r'\theta', 'θ')
        .replaceAll(r'\alpha', 'α')
        .replaceAll(r'\beta', 'β')
        .replaceAll(r'\gamma', 'γ')
        .replaceAll(r'\lambda', 'λ')
        .replaceAll(r'\pi', 'π')
        .replaceAll(r'\phi', 'φ')
        .replaceAll(r'\omega', 'ω')
        .replaceAll(r'\Delta', 'Δ');

    // Degrees and angles
    s = s.replaceAll(r'^\circ', '°')
        .replaceAll(r'^{\circ}', '°')
        .replaceAll(r'\circ', '°')
        .replaceAll(r'\angle', '∠');

    // Mathematical operators & relations
    s = s.replaceAll(r'\times', '×')
        .replaceAll(r'\cdot', '·')
        .replaceAll(r'\div', '÷')
        .replaceAll(r'\pm', '±')
        .replaceAll(r'\mp', '∓')
        .replaceAll(r'\le', '≤')
        .replaceAll(r'\leq', '≤')
        .replaceAll(r'\ge', '≥')
        .replaceAll(r'\geq', '≥')
        .replaceAll(r'\ne', '≠')
        .replaceAll(r'\neq', '≠')
        .replaceAll(r'\approx', '≈')
        .replaceAll(r'\infty', '∞')
        .replaceAll(r'\in', '∈')
        .replaceAll(r'\notin', '∉')
        .replaceAll(r'\subset', '⊂')
        .replaceAll(r'\subseteq', '⊆')
        .replaceAll(r'\cap', '∩')
        .replaceAll(r'\cup', '∪');

    // Square root
    s = s.replaceAllMapped(RegExp(r'\\sqrt\{([^}]+)\}'), (m) => '√(${m[1]})')
        .replaceAll(r'\sqrt', '√');

    // Fractions: \frac{a}{b} -> (a / b)
    s = s.replaceAllMapped(RegExp(r'\\frac\{([^}]+)\}\{([^}]+)\}'), (m) => '(${m[1]}/${m[2]})');

    // Superscripts
    s = s.replaceAllMapped(RegExp(r'\^\{?([0-9])\}?'), (m) {
      final digit = m[1];
      switch (digit) {
        case '0': return '⁰';
        case '1': return '¹';
        case '2': return '²';
        case '3': return '³';
        case '4': return '⁴';
        case '5': return '⁵';
        case '6': return '⁶';
        case '7': return '⁷';
        case '8': return '⁸';
        case '9': return '⁹';
        default: return '^$digit';
      }
    });

    // Subscripts
    s = s.replaceAllMapped(RegExp(r'_\{?([0-9])\}?'), (m) {
      final digit = m[1];
      switch (digit) {
        case '0': return '₀';
        case '1': return '₁';
        case '2': return '₂';
        case '3': return '₃';
        case '4': return '₄';
        case '5': return '₅';
        case '6': return '₆';
        case '7': return '₇';
        case '8': return '₈';
        case '9': return '₉';
        default: return '_$digit';
      }
    });

    // Strip unnecessary braces
    s = s.replaceAll('{', '').replaceAll('}', '');

    // Strip raw dollar signs
    s = s.replaceAll(r'$', '');

    // Normalize excess spaces
    s = s.replaceAll(RegExp(r'\s{2,}'), ' ');

    return s.trim();
  }
}
