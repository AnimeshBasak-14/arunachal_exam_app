import 'package:flutter/material.dart';

class Exam {
  final String id;
  final String code; // Short code e.g. APCS, ADO, CHSL
  final String name; // Full name e.g. Assistant Professor Exam
  final IconData icon;
  final bool isBookmarked;
  final String categoryId; // 'appsc' or 'apssb'

  Exam({
    required this.id,
    required this.code,
    required this.name,
    required this.icon,
    this.isBookmarked = false,
    required this.categoryId,
  });

  Exam copyWith({
    String? id,
    String? code,
    String? name,
    IconData? icon,
    bool? isBookmarked,
    String? categoryId,
  }) {
    return Exam(
      id: id ?? this.id,
      code: code ?? this.code,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      isBookmarked: isBookmarked ?? this.isBookmarked,
      categoryId: categoryId ?? this.categoryId,
    );
  }
}
