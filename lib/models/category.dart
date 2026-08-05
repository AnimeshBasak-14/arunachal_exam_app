import 'package:flutter/material.dart';

enum CategoryType { appsc, apssb }

class ExamCategory {
  final String id;
  final String title;
  final CategoryType type;
  final LinearGradient gradient;

  ExamCategory({
    required this.id,
    required this.title,
    required this.type,
    required this.gradient,
  });
}
