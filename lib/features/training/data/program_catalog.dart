import '../models/program.dart';

const programCatalog = <TrainingProgram>[
  TrainingProgram(
    id: 'heavy_duty',
    name: 'Heavy Duty',
    badge: 'HIT',
    tagline: 'One set. All in. Then recover.',
    description:
        'A high-intensity, low-volume approach inspired by Mike Mentzer. '
        'Each exercise gets one all-out working set, then you leave the gym and grow.',
    level: 'Advanced',
    goal: 'Muscle · Strength',
    daysPerWeek: 3,
    weeks: 6,
    equipment: 'Full gym',
    principles: [
      'One working set per exercise, taken to technical failure.',
      'Log the load and beat it next time — overload is the stimulus.',
      'Space sessions 4–7 days apart. Recovery is the workout.',
      'Stop the set when form breaks, not when the ego says so.',
    ],
    credit:
        'Inspired by Mike Mentzer’s Heavy Duty principles. Educational programming; '
        'not affiliated with or endorsed by the Mentzer estate.',
    days: [
      ProgramDay(
        id: 'push',
        name: 'Push',
        focus: 'Chest · Shoulders · Triceps',
        note:
            'One set each. Take 3–5 minutes between exercises. Stop 1 rep before failure if you are new to HIT.',
        exercises: [
          ProgramExercise(
            exerciseId: 'barbell_incline_bench_press_medium_grip',
            sets: 1,
            reps: '6–8 to failure',
            restSeconds: 240,
            tempo: '3/1/1',
          ),
          ProgramExercise(
            exerciseId: 'dips_chest_version',
            sets: 1,
            reps: '6–10 to failure',
            restSeconds: 240,
            note: 'Add weight once bodyweight sets hit the top of the range.',
          ),
          ProgramExercise(
            exerciseId: 'side_lateral_raise',
            sets: 1,
            reps: '8–12 to failure',
            restSeconds: 180,
            tempo: '2/0/2',
          ),
          ProgramExercise(
            exerciseId: 'triceps_pushdown_rope_attachment',
            sets: 1,
            reps: '8–12 to failure',
            restSeconds: 180,
          ),
        ],
      ),
      ProgramDay(
        id: 'pull',
        name: 'Pull',
        focus: 'Back · Traps · Biceps',
        note:
            'Use a full range. A controlled negative is part of the set, not a rest.',
        exercises: [
          ProgramExercise(
            exerciseId: 'wide_grip_lat_pulldown',
            sets: 1,
            reps: '6–8 to failure',
            restSeconds: 240,
            tempo: '3/1/1',
          ),
          ProgramExercise(
            exerciseId: 't_bar_row_with_handle',
            sets: 1,
            reps: '6–8 to failure',
            restSeconds: 240,
          ),
          ProgramExercise(
            exerciseId: 'barbell_shrug',
            sets: 1,
            reps: '8–12 to failure',
            restSeconds: 180,
          ),
          ProgramExercise(
            exerciseId: 'barbell_curl',
            sets: 1,
            reps: '8–12 to failure',
            restSeconds: 120,
          ),
        ],
      ),
      ProgramDay(
        id: 'legs',
        name: 'Legs',
        focus: 'Quads · Hamstrings · Calves · Core',
        note:
            'Leg training is systemic. Do not stack this day next to another heavy session.',
        exercises: [
          ProgramExercise(
            exerciseId: 'leg_press',
            sets: 1,
            reps: '8–12 to failure',
            restSeconds: 240,
            tempo: '3/1/1',
          ),
          ProgramExercise(
            exerciseId: 'lying_leg_curls',
            sets: 1,
            reps: '8–12 to failure',
            restSeconds: 180,
          ),
          ProgramExercise(
            exerciseId: 'standing_calf_raises',
            sets: 1,
            reps: '10–15 to failure',
            restSeconds: 120,
          ),
          ProgramExercise(
            exerciseId: 'ab_roller',
            sets: 1,
            reps: '8–12',
            restSeconds: 90,
          ),
        ],
      ),
    ],
  ),
  TrainingProgram(
    id: 'tempo_4x4',
    name: '4×4 Tempo',
    badge: '2 / 2 / 1',
    tagline: 'Own every inch of the rep.',
    description:
        'Four heavy sets of four with a strict 2-second lowering phase, 2-second '
        'lifting phase and 1-second pause. Less weight, more muscle tension.',
    level: 'Intermediate',
    goal: 'Strength · Control',
    daysPerWeek: 3,
    weeks: 8,
    equipment: 'Barbell + basics',
    principles: [
      'Tempo: 2 seconds down, 2 seconds up, 1 second pause.',
      'Leave 1–2 reps in reserve on sets 1–3; set 4 can be near failure.',
      'Add 2.5 kg once you complete all 16 reps with clean tempo.',
      'If tempo breaks, the set is over. No bouncing.',
    ],
    credit:
        'Tempo prescription 2/2/1 is a classic hypertrophy and control method. '
        'This specific program is an original Thetics template.',
    days: [
      ProgramDay(
        id: 'day_a',
        name: 'Day A',
        focus: 'Squat · Bench · Row',
        exercises: [
          ProgramExercise(
            exerciseId: 'barbell_squat',
            sets: 4,
            reps: '4',
            restSeconds: 150,
            tempo: '2/2/1',
          ),
          ProgramExercise(
            exerciseId: 'barbell_bench_press_medium_grip',
            sets: 4,
            reps: '4',
            restSeconds: 150,
            tempo: '2/2/1',
          ),
          ProgramExercise(
            exerciseId: 'bent_over_barbell_row',
            sets: 4,
            reps: '4',
            restSeconds: 120,
            tempo: '2/2/1',
          ),
          ProgramExercise(
            exerciseId: 'standing_calf_raises',
            sets: 3,
            reps: '12',
            restSeconds: 60,
            tempo: '2/2/1',
          ),
          ProgramExercise(
            exerciseId: 'plank',
            sets: 2,
            reps: '45 sec',
            restSeconds: 60,
          ),
        ],
      ),
      ProgramDay(
        id: 'day_b',
        name: 'Day B',
        focus: 'Deadlift · Press · Pull-up',
        exercises: [
          ProgramExercise(
            exerciseId: 'barbell_deadlift',
            sets: 4,
            reps: '4',
            restSeconds: 180,
            tempo: '2/2/1',
            note: 'Reset between reps. Never trade a neutral spine for tempo.',
          ),
          ProgramExercise(
            exerciseId: 'standing_military_press',
            sets: 4,
            reps: '4',
            restSeconds: 150,
            tempo: '2/2/1',
          ),
          ProgramExercise(
            exerciseId: 'chin_up',
            sets: 4,
            reps: '4–8',
            restSeconds: 120,
            tempo: '2/2/1',
            note: 'Use added weight if 8 strict reps are easy.',
          ),
          ProgramExercise(
            exerciseId: 'hanging_leg_raise',
            sets: 3,
            reps: '10',
            restSeconds: 60,
          ),
          ProgramExercise(
            exerciseId: 'side_lateral_raise',
            sets: 3,
            reps: '12',
            restSeconds: 60,
            tempo: '2/0/2',
          ),
        ],
      ),
      ProgramDay(
        id: 'day_c',
        name: 'Day C',
        focus: 'Front squat · Incline · Row',
        exercises: [
          ProgramExercise(
            exerciseId: 'front_barbell_squat',
            sets: 4,
            reps: '4',
            restSeconds: 150,
            tempo: '2/2/1',
          ),
          ProgramExercise(
            exerciseId: 'incline_dumbbell_press',
            sets: 4,
            reps: '4',
            restSeconds: 120,
            tempo: '2/2/1',
          ),
          ProgramExercise(
            exerciseId: 'seated_cable_rows',
            sets: 4,
            reps: '4',
            restSeconds: 120,
            tempo: '2/2/1',
          ),
          ProgramExercise(
            exerciseId: 'leg_extensions',
            sets: 3,
            reps: '12',
            restSeconds: 60,
            tempo: '2/1/2',
          ),
          ProgramExercise(
            exerciseId: 'cable_crunch',
            sets: 3,
            reps: '12',
            restSeconds: 60,
          ),
        ],
      ),
    ],
  ),
  TrainingProgram(
    id: 'foundation_5x5',
    name: 'Foundation 5×5',
    badge: '5 × 5',
    tagline: 'The shortest road to a stronger you.',
    description:
        'Three full-body sessions a week built on the big five. Add a little weight, '
        'keep the form, repeat. Perfect for a first serious strength block.',
    level: 'Beginner–Intermediate',
    goal: 'Strength · Foundation',
    daysPerWeek: 3,
    weeks: 12,
    equipment: 'Barbell + rack',
    principles: [
      'Alternate Day A and Day B: A–B–A, then B–A–B the next week.',
      'Squat every session. Start lighter than your ego wants.',
      'Complete all 25 reps cleanly, then add 2.5 kg next time.',
      'Deadlift is one heavy set of five after your squats and press.',
    ],
    credit:
        'Classic 5×5 progression popularised by Bill Starr and later StrongLifts. '
        'This is an original Thetics presentation of the method.',
    days: [
      ProgramDay(
        id: 'day_a',
        name: 'Workout A',
        focus: 'Squat · Bench · Row',
        exercises: [
          ProgramExercise(
            exerciseId: 'barbell_squat',
            sets: 5,
            reps: '5',
            restSeconds: 180,
            note: 'Add 2.5 kg when all 5×5 are completed.',
          ),
          ProgramExercise(
            exerciseId: 'barbell_bench_press_medium_grip',
            sets: 5,
            reps: '5',
            restSeconds: 180,
          ),
          ProgramExercise(
            exerciseId: 'bent_over_barbell_row',
            sets: 5,
            reps: '5',
            restSeconds: 150,
          ),
          ProgramExercise(
            exerciseId: 'plank',
            sets: 2,
            reps: '60 sec',
            restSeconds: 60,
          ),
        ],
      ),
      ProgramDay(
        id: 'day_b',
        name: 'Workout B',
        focus: 'Squat · Press · Deadlift',
        exercises: [
          ProgramExercise(
            exerciseId: 'barbell_squat',
            sets: 5,
            reps: '5',
            restSeconds: 180,
          ),
          ProgramExercise(
            exerciseId: 'standing_military_press',
            sets: 5,
            reps: '5',
            restSeconds: 180,
          ),
          ProgramExercise(
            exerciseId: 'barbell_deadlift',
            sets: 1,
            reps: '5',
            restSeconds: 240,
            note: 'Add 5 kg when the set is completed with a neutral spine.',
          ),
          ProgramExercise(
            exerciseId: 'hanging_leg_raise',
            sets: 3,
            reps: '8–12',
            restSeconds: 60,
          ),
        ],
      ),
    ],
  ),
  TrainingProgram(
    id: 'ppl_aesthetics',
    name: 'PPL Aesthetics',
    badge: '6 DAY',
    tagline: 'Width. Shape. Detail. Repeat.',
    description:
        'A six-day push/pull/legs split biased toward shoulders, back width and arms. '
        'High frequency, moderate volume, focused on the lines that read on stage.',
    level: 'Intermediate',
    goal: 'Aesthetics · Hypertrophy',
    daysPerWeek: 6,
    weeks: 10,
    equipment: 'Full gym',
    principles: [
      'Train 1–2 reps in reserve; failure is a tool, not a daily target.',
      'Prioritise lateral delts and back width in the A sessions.',
      'Add reps before weight; add weight when you own the top of the range.',
      'Take a deload week if sleep and performance both drop.',
    ],
    credit: 'Original Thetics push/pull/legs programming built around classic '
        'hypertrophy principles.',
    days: [
      ProgramDay(
        id: 'push_a',
        name: 'Push A',
        focus: 'Chest · Shoulders · Triceps',
        exercises: [
          ProgramExercise(
            exerciseId: 'incline_dumbbell_press',
            sets: 4,
            reps: '8–10',
            restSeconds: 120,
          ),
          ProgramExercise(
            exerciseId: 'machine_bench_press',
            sets: 3,
            reps: '10–12',
            restSeconds: 90,
          ),
          ProgramExercise(
            exerciseId: 'side_lateral_raise',
            sets: 4,
            reps: '12–15',
            restSeconds: 60,
          ),
          ProgramExercise(
            exerciseId: 'cable_crossover',
            sets: 3,
            reps: '12–15',
            restSeconds: 60,
          ),
          ProgramExercise(
            exerciseId: 'triceps_pushdown_rope_attachment',
            sets: 3,
            reps: '10–12',
            restSeconds: 60,
          ),
          ProgramExercise(
            exerciseId: 'cable_rope_overhead_triceps_extension',
            sets: 3,
            reps: '12–15',
            restSeconds: 60,
          ),
        ],
      ),
      ProgramDay(
        id: 'pull_a',
        name: 'Pull A',
        focus: 'Lats · Mid-back · Biceps',
        exercises: [
          ProgramExercise(
            exerciseId: 'pullups',
            sets: 4,
            reps: '6–10',
            restSeconds: 120,
          ),
          ProgramExercise(
            exerciseId: 'seated_cable_rows',
            sets: 4,
            reps: '8–10',
            restSeconds: 90,
          ),
          ProgramExercise(
            exerciseId: 'face_pull',
            sets: 3,
            reps: '15–20',
            restSeconds: 60,
          ),
          ProgramExercise(
            exerciseId: 'incline_dumbbell_curl',
            sets: 4,
            reps: '8–10',
            restSeconds: 60,
          ),
          ProgramExercise(
            exerciseId: 'alternate_hammer_curl',
            sets: 3,
            reps: '10–12',
            restSeconds: 60,
          ),
        ],
      ),
      ProgramDay(
        id: 'legs_a',
        name: 'Legs A',
        focus: 'Quads · Hamstrings · Calves',
        exercises: [
          ProgramExercise(
            exerciseId: 'barbell_squat',
            sets: 4,
            reps: '6–8',
            restSeconds: 150,
          ),
          ProgramExercise(
            exerciseId: 'romanian_deadlift',
            sets: 3,
            reps: '8–10',
            restSeconds: 120,
          ),
          ProgramExercise(
            exerciseId: 'leg_press',
            sets: 3,
            reps: '10–12',
            restSeconds: 90,
          ),
          ProgramExercise(
            exerciseId: 'lying_leg_curls',
            sets: 3,
            reps: '12',
            restSeconds: 60,
          ),
          ProgramExercise(
            exerciseId: 'standing_calf_raises',
            sets: 4,
            reps: '12–15',
            restSeconds: 60,
          ),
          ProgramExercise(
            exerciseId: 'hanging_leg_raise',
            sets: 3,
            reps: '10–15',
            restSeconds: 60,
          ),
        ],
      ),
      ProgramDay(
        id: 'push_b',
        name: 'Push B',
        focus: 'Shoulders · Upper chest',
        exercises: [
          ProgramExercise(
            exerciseId: 'standing_military_press',
            sets: 4,
            reps: '6–8',
            restSeconds: 150,
          ),
          ProgramExercise(
            exerciseId: 'incline_dumbbell_press',
            sets: 4,
            reps: '8–10',
            restSeconds: 120,
          ),
          ProgramExercise(
            exerciseId: 'side_lateral_raise',
            sets: 3,
            reps: '15–20',
            restSeconds: 45,
          ),
          ProgramExercise(
            exerciseId: 'butterfly',
            sets: 3,
            reps: '12–15',
            restSeconds: 60,
          ),
          ProgramExercise(
            exerciseId: 'close_grip_barbell_bench_press',
            sets: 3,
            reps: '8–10',
            restSeconds: 90,
          ),
          ProgramExercise(
            exerciseId: 'dips_triceps_version',
            sets: 3,
            reps: '8–12',
            restSeconds: 60,
          ),
        ],
      ),
      ProgramDay(
        id: 'pull_b',
        name: 'Pull B',
        focus: 'Thickness · Rear delts · Arms',
        exercises: [
          ProgramExercise(
            exerciseId: 'rack_pulls',
            sets: 4,
            reps: '6–8',
            restSeconds: 180,
          ),
          ProgramExercise(
            exerciseId: 'one_arm_dumbbell_row',
            sets: 4,
            reps: '8–10',
            restSeconds: 90,
          ),
          ProgramExercise(
            exerciseId: 'wide_grip_lat_pulldown',
            sets: 3,
            reps: '10–12',
            restSeconds: 60,
          ),
          ProgramExercise(
            exerciseId: 'reverse_flyes',
            sets: 3,
            reps: '15–20',
            restSeconds: 45,
          ),
          ProgramExercise(
            exerciseId: 'preacher_curl',
            sets: 3,
            reps: '10–12',
            restSeconds: 60,
          ),
          ProgramExercise(
            exerciseId: 'barbell_shrug',
            sets: 3,
            reps: '12–15',
            restSeconds: 60,
          ),
        ],
      ),
      ProgramDay(
        id: 'legs_b',
        name: 'Legs B',
        focus: 'Glutes · Quads · Core',
        exercises: [
          ProgramExercise(
            exerciseId: 'front_barbell_squat',
            sets: 4,
            reps: '6–8',
            restSeconds: 150,
          ),
          ProgramExercise(
            exerciseId: 'barbell_hip_thrust',
            sets: 3,
            reps: '10–12',
            restSeconds: 90,
          ),
          ProgramExercise(
            exerciseId: 'dumbbell_lunges',
            sets: 3,
            reps: '10 / leg',
            restSeconds: 90,
          ),
          ProgramExercise(
            exerciseId: 'leg_extensions',
            sets: 3,
            reps: '15',
            restSeconds: 60,
          ),
          ProgramExercise(
            exerciseId: 'seated_calf_raise',
            sets: 4,
            reps: '15–20',
            restSeconds: 45,
          ),
          ProgramExercise(
            exerciseId: 'ab_roller',
            sets: 3,
            reps: '10–12',
            restSeconds: 60,
          ),
        ],
      ),
    ],
  ),
  TrainingProgram(
    id: 'upper_lower_recomp',
    name: 'Upper / Lower Recomp',
    badge: '4 DAY',
    tagline: 'Lean out without shrinking.',
    description:
        'Four focused sessions that keep the heavy compounds in while adding enough '
        'volume for shape. Built for a slow, controlled recomposition.',
    level: 'Beginner–Intermediate',
    goal: 'Fat loss · Recomp',
    daysPerWeek: 4,
    weeks: 8,
    equipment: 'Full gym',
    principles: [
      'Keep strength on the big lifts while calories are lower.',
      'Two hard upper days, two lower days. No junk volume.',
      'Walk 8–10k steps daily; adjust food based on the weekly weight trend.',
      'Protein is non-negotiable. Hit the target before worrying about the rest.',
    ],
    credit: 'Original Thetics upper/lower template for body recomposition.',
    days: [
      ProgramDay(
        id: 'upper_a',
        name: 'Upper A',
        focus: 'Strength · Chest · Back',
        exercises: [
          ProgramExercise(
            exerciseId: 'barbell_bench_press_medium_grip',
            sets: 4,
            reps: '6–8',
            restSeconds: 150,
          ),
          ProgramExercise(
            exerciseId: 'bent_over_barbell_row',
            sets: 4,
            reps: '8–10',
            restSeconds: 120,
          ),
          ProgramExercise(
            exerciseId: 'incline_dumbbell_press',
            sets: 3,
            reps: '8–10',
            restSeconds: 90,
          ),
          ProgramExercise(
            exerciseId: 'wide_grip_lat_pulldown',
            sets: 3,
            reps: '10–12',
            restSeconds: 60,
          ),
          ProgramExercise(
            exerciseId: 'side_lateral_raise',
            sets: 3,
            reps: '15',
            restSeconds: 45,
          ),
          ProgramExercise(
            exerciseId: 'barbell_curl',
            sets: 3,
            reps: '12',
            restSeconds: 60,
          ),
          ProgramExercise(
            exerciseId: 'triceps_pushdown_rope_attachment',
            sets: 3,
            reps: '12',
            restSeconds: 60,
          ),
        ],
      ),
      ProgramDay(
        id: 'lower_a',
        name: 'Lower A',
        focus: 'Squat · Posterior chain',
        exercises: [
          ProgramExercise(
            exerciseId: 'barbell_squat',
            sets: 4,
            reps: '6–8',
            restSeconds: 150,
          ),
          ProgramExercise(
            exerciseId: 'romanian_deadlift',
            sets: 3,
            reps: '8–10',
            restSeconds: 120,
          ),
          ProgramExercise(
            exerciseId: 'leg_press',
            sets: 3,
            reps: '10–12',
            restSeconds: 90,
          ),
          ProgramExercise(
            exerciseId: 'lying_leg_curls',
            sets: 3,
            reps: '12',
            restSeconds: 60,
          ),
          ProgramExercise(
            exerciseId: 'standing_calf_raises',
            sets: 4,
            reps: '12–15',
            restSeconds: 45,
          ),
          ProgramExercise(
            exerciseId: 'plank',
            sets: 3,
            reps: '45 sec',
            restSeconds: 45,
          ),
        ],
      ),
      ProgramDay(
        id: 'upper_b',
        name: 'Upper B',
        focus: 'Shoulders · Width',
        exercises: [
          ProgramExercise(
            exerciseId: 'standing_military_press',
            sets: 3,
            reps: '6–8',
            restSeconds: 150,
          ),
          ProgramExercise(
            exerciseId: 'pullups',
            sets: 4,
            reps: '6–10',
            restSeconds: 120,
          ),
          ProgramExercise(
            exerciseId: 'dumbbell_bench_press',
            sets: 3,
            reps: '10–12',
            restSeconds: 90,
          ),
          ProgramExercise(
            exerciseId: 'seated_cable_rows',
            sets: 3,
            reps: '10–12',
            restSeconds: 90,
          ),
          ProgramExercise(
            exerciseId: 'seated_bent_over_rear_delt_raise',
            sets: 3,
            reps: '15',
            restSeconds: 45,
          ),
          ProgramExercise(
            exerciseId: 'alternate_hammer_curl',
            sets: 3,
            reps: '12',
            restSeconds: 60,
          ),
          ProgramExercise(
            exerciseId: 'dips_triceps_version',
            sets: 3,
            reps: '10–12',
            restSeconds: 60,
          ),
        ],
      ),
      ProgramDay(
        id: 'lower_b',
        name: 'Lower B',
        focus: 'Deadlift · Glutes',
        exercises: [
          ProgramExercise(
            exerciseId: 'barbell_deadlift',
            sets: 3,
            reps: '5',
            restSeconds: 180,
          ),
          ProgramExercise(
            exerciseId: 'front_barbell_squat',
            sets: 3,
            reps: '8',
            restSeconds: 120,
          ),
          ProgramExercise(
            exerciseId: 'barbell_hip_thrust',
            sets: 3,
            reps: '10–12',
            restSeconds: 90,
          ),
          ProgramExercise(
            exerciseId: 'leg_extensions',
            sets: 3,
            reps: '15',
            restSeconds: 60,
          ),
          ProgramExercise(
            exerciseId: 'seated_calf_raise',
            sets: 4,
            reps: '15',
            restSeconds: 45,
          ),
          ProgramExercise(
            exerciseId: 'ab_roller',
            sets: 3,
            reps: '10–12',
            restSeconds: 60,
          ),
        ],
      ),
    ],
  ),
];

TrainingProgram? programById(String id) {
  for (final program in programCatalog) {
    if (program.id == id) return program;
  }
  return null;
}
