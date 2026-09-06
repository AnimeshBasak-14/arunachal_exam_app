import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../../models/exam.dart';

final examViewModelProvider =
    StateNotifierProvider<ExamViewModel, List<Exam>>((ref) {
  return ExamViewModel();
});

final searchFilterProvider = StateProvider<String>((ref) => '');

final bookmarkedExamsProvider = Provider<List<Exam>>((ref) {
  final exams = ref.watch(examViewModelProvider);
  return exams.where((exam) => exam.isBookmarked).toList();
});

class ExamViewModel extends StateNotifier<List<Exam>> {
  ExamViewModel() : super(_initialExams);

  static final List<Exam> _initialExams = [
    // APPSC Exams
    Exam(
      id: 'appsc_apcs',
      code: 'APCS',
      name: 'Arunachal Pradesh Civil Services',
      icon: Icons.workspace_premium,
      categoryId: 'appsc',
    ),
    Exam(
      id: 'appsc_ado',
      code: 'ADO',
      name: 'Agriculture Development Officer',
      icon: Icons.agriculture_rounded,
      categoryId: 'appsc',
    ),
    Exam(
      id: 'appsc_hdo',
      code: 'HDO',
      name: 'Horticulture Development Officer',
      icon: Icons.volunteer_activism_rounded,
      categoryId: 'appsc',
    ),
    Exam(
      id: 'appsc_fao',
      code: 'FAO',
      name: 'Financial Advisory Officer',
      icon: Icons.monetization_on_outlined,
      categoryId: 'appsc',
    ),
    Exam(
      id: 'appsc_ae',
      code: 'AE',
      name: 'Assistant Engineer',
      icon: Icons.settings,
      categoryId: 'appsc',
    ),
    Exam(
      id: 'appsc_je',
      code: 'JE',
      name: 'Junior Engineer',
      icon: Icons.build_circle_outlined,
      categoryId: 'appsc',
    ),
    Exam(
      id: 'appsc_pgt',
      code: 'PGT',
      name: 'Post Graduate Teacher',
      icon: Icons.school,
      categoryId: 'appsc',
    ),
    Exam(
      id: 'appsc_tgt',
      code: 'TGT',
      name: 'Trained Graduate Teacher',
      icon: Icons.school_outlined,
      categoryId: 'appsc',
    ),
    Exam(
      id: 'appsc_prof',
      code: 'Assistant Professor Exam',
      name: 'Assistant Professor Examination',
      icon: Icons.history_edu,
      categoryId: 'appsc',
    ),
    Exam(
      id: 'appsc_prosecutor',
      code: 'Asnt Public Prosecutor Examination',
      name: 'Assistant Public Prosecutor Examination',
      icon: Icons.gavel_rounded,
      categoryId: 'appsc',
    ),

    // APSSB Exams
    Exam(
      id: 'apssb_chsl',
      code: 'CHSL',
      name: 'Combined Higher Secondary Level',
      icon: Icons.workspace_premium_outlined,
      categoryId: 'apssb',
    ),
    Exam(
      id: 'apssb_cgl',
      code: 'CGL',
      name: 'Combined Graduate Level',
      icon: Icons.edit_calendar_outlined,
      categoryId: 'apssb',
    ),
    Exam(
      id: 'apssb_mts',
      code: 'MTS',
      name: 'Multi Tasking Staff',
      icon: Icons.edit_note_rounded,
      categoryId: 'apssb',
    ),
    Exam(
      id: 'apssb_csce',
      code: 'CSCE',
      name: 'Combined Secondary Cadre Examination',
      icon: Icons.edit_rounded,
      categoryId: 'apssb',
    ),
    Exam(
      id: 'apssb_udc',
      code: 'UDC',
      name: 'Upper Division Clerk',
      icon: Icons.account_balance_outlined,
      categoryId: 'apssb',
    ),
  ];

  void toggleBookmark(String id) {
    state = [
      for (final exam in state)
        if (exam.id == id)
          exam.copyWith(isBookmarked: !exam.isBookmarked)
        else
          exam
    ];
  }
}
