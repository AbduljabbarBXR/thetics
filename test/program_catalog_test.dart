import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:thetics/features/training/data/exercise_seed.dart';
import 'package:thetics/features/training/data/program_catalog.dart';

void main() {
  group('program catalog', () {
    test('contains the five advertised programs with unique ids', () {
      expect(programCatalog, hasLength(5));
      expect(
        programCatalog.map((program) => program.id).toSet(),
        {
          'heavy_duty',
          'tempo_4x4',
          'foundation_5x5',
          'upper_lower_recomp',
          'ppl_aesthetics',
        },
      );
    });

    test('every program day has real exercises and prescriptions', () {
      final exerciseIds = exerciseSeed.map((exercise) => exercise.id).toSet();
      for (final program in programCatalog) {
        expect(program.days, isNotEmpty, reason: program.id);
        expect(program.weeks, greaterThan(0), reason: program.id);
        expect(program.daysPerWeek, inInclusiveRange(1, 7), reason: program.id);
        for (final day in program.days) {
          expect(day.exercises, isNotEmpty, reason: '${program.id}/${day.id}');
          expect(day.totalSets, greaterThan(0));
          for (final exercise in day.exercises) {
            expect(
              exerciseIds,
              contains(exercise.exerciseId),
              reason: '${program.id}/${day.id} references '
                  '${exercise.exerciseId}',
            );
            expect(exercise.sets, greaterThan(0));
            expect(exercise.reps.trim(), isNotEmpty);
            expect(exercise.restSeconds, greaterThanOrEqualTo(0));
          }
        }
      }
    });

    test('program and day ids are unique', () {
      final programIds = programCatalog.map((program) => program.id).toSet();
      expect(programIds, hasLength(programCatalog.length));
      for (final program in programCatalog) {
        final dayIds = program.days.map((day) => day.id).toSet();
        expect(dayIds, hasLength(program.days.length), reason: program.id);
      }
    });
  });

  group('exercise seed', () {
    test('has unique ids and complete instructions', () {
      expect(exerciseSeed, hasLength(69));
      expect(
        exerciseSeed.map((exercise) => exercise.id).toSet(),
        hasLength(exerciseSeed.length),
      );
      for (final exercise in exerciseSeed) {
        expect(exercise.name.trim(), isNotEmpty);
        expect(exercise.instructions, isNotEmpty);
        expect(exercise.imageAsset, startsWith('assets/exercises/'));
      }
    });

    test('every bundled image exists', () {
      for (final exercise in exerciseSeed) {
        expect(
          File(exercise.imageAsset).existsSync(),
          isTrue,
          reason: 'Missing ${exercise.imageAsset}',
        );
      }
    });
  });
}
