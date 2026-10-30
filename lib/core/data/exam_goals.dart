import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/service_providers.dart';

/// Recruiting bodies a paper can belong to.
enum Department {
  appsc('APPSC', 'Public Service Commission'),
  apssb('APSSB', 'Staff Selection Board'),
  police('Police', 'Police Recruitment'),
  other('Other', 'Other exams');

  final String label;
  final String longName;
  const Department(this.label, this.longName);

  static Department classify(String examCode, {String? board}) {
    final code = examCode.toUpperCase();
    final b = (board ?? '').toUpperCase();
    if (code.contains('POLICE') ||
        code.contains('CONSTABLE') ||
        code.contains('PRB') ||
        b.contains('POLICE')) {
      return Department.police;
    }
    if (code.contains('APPSC') || b == 'APPSC') return Department.appsc;
    if (code.contains('APSSB') || b == 'APSSB') return Department.apssb;
    return Department.other;
  }

  /// Boards shown as filters and goals. Police papers still classify as
  /// [police] but have no tab or goal for now.
  static const primary = [Department.appsc, Department.apssb];
}

class ExamGoal {
  final String id;
  final Department department;
  final String name;

  const ExamGoal(this.id, this.department, this.name);
}

const examGoals = <ExamGoal>[
  ExamGoal('appsc-cce', Department.appsc, 'APPSC Combined Competitive Exam'),
  ExamGoal(
      'appsc-other', Department.appsc, 'APPSC Departmental & Technical Exams'),
  ExamGoal('apssb-cgl', Department.apssb, 'APSSB Combined Graduate Level'),
  ExamGoal(
      'apssb-chsl', Department.apssb, 'APSSB Combined Higher Secondary Level'),
  ExamGoal('apssb-csle', Department.apssb, 'APSSB Combined Secondary Level'),
];

final examGoalProvider =
    NotifierProvider<ExamGoalNotifier, ExamGoal>(ExamGoalNotifier.new);

class ExamGoalNotifier extends Notifier<ExamGoal> {
  static const _key = 'exam_goal_id';

  @override
  ExamGoal build() {
    final id = ref.watch(sharedPreferencesProvider).getString(_key);
    return examGoals.firstWhere((g) => g.id == id,
        orElse: () => examGoals.first);
  }

  Future<void> select(ExamGoal goal) async {
    state = goal;
    await ref.read(sharedPreferencesProvider).setString(_key, goal.id);
  }
}
