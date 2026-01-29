import 'package:flutter/material.dart';

import '../../../data/models/lesson.dart';

class LessonPickingSheet extends StatelessWidget {
  final LessonModel lesson;
  final double progress; // 0..1
  final int lessonIndex; // 0-based
  final int totalLessons;
  final VoidCallback onContinue;

  const LessonPickingSheet({
    super.key,
    required this.lesson,
    required this.progress,
    required this.lessonIndex,
    required this.totalLessons,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    // Lesson picking sheet has been removed — this widget kept as a no-op
    // to avoid breaking references during migration. Navigation now
    // goes directly to the lesson screen.
    return const SizedBox.shrink();
  }
}
