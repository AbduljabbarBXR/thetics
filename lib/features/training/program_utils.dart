import 'package:flutter/material.dart';

import '../../core/models/app_data.dart';
import '../../core/theme/app_palette.dart';
import 'models/program.dart';
import 'models/workout_session.dart';

Color programColor(String id, TheticsPalette p) {
  return switch (id) {
    'heavy_duty' => p.ember,
    'tempo_4x4' => p.sky,
    'foundation_5x5' => p.lilac,
    'upper_lower_recomp' => p.success,
    _ => p.accent,
  };
}

ProgramDay nextDayForProgram(TrainingProgram program, AppData data) {
  final sessions = data.completedSessions
      .where((session) => session.programId == program.id)
      .toList();
  if (sessions.isEmpty) return program.days.first;
  final lastDayId = sessions.first.dayId;
  final index = program.days.indexWhere((day) => day.id == lastDayId);
  if (index < 0) return program.days.first;
  return program.days[(index + 1) % program.days.length];
}

int estimateMinutes(ProgramDay day) {
  final sets = day.totalSets;
  return ((sets * 3.2) + 8).round();
}

int sessionsInLastDays(AppData data, int days) {
  final cutoff = DateTime.now().subtract(Duration(days: days));
  return data.completedSessions.where((session) {
    final date = session.completedAt ?? session.startedAt;
    return date.isAfter(cutoff);
  }).length;
}

int programSessions(TrainingProgram program, AppData data) {
  return data.completedSessions
      .where((session) => session.programId == program.id)
      .length;
}

WorkoutSession? latestSessionForProgram(TrainingProgram program, AppData data) {
  for (final session in data.completedSessions) {
    if (session.programId == program.id) return session;
  }
  return null;
}
