import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_palette.dart';
import '../../core/widgets/app_logo.dart';
import '../../core/widgets/surfaces.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: p.bg,
      appBar: AppBar(title: const Text('About Thetics')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 36),
        children: [
          Center(child: AppMark(size: 76, radius: 20)),
          const SizedBox(height: 16),
          Center(
            child: Text(
              'THETICS',
              style: text.displayMedium?.copyWith(
                fontSize: 44,
                letterSpacing: 1.5,
                height: 0.9,
              ),
            ),
          ),
          const SizedBox(height: 7),
          Center(
            child: Eyebrow('Natural physique · honest data', color: p.accent),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'Version 1.0.0 (build 1)',
              style: TextStyle(color: p.faint, fontSize: 9.5),
            ),
          ),
          const SizedBox(height: 24),
          const DividerLabel('Why this exists'),
          const SizedBox(height: 12),
          Text(
            'Thetics is a training and nutrition tracker for people who want a '
            'strong, lean, muscular physique without pretending the process is '
            'fast or fair.',
            style: TextStyle(color: p.text, fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 10),
          Text(
            'Training should be simple enough to repeat and hard enough to '
            'matter. Nutrition should be built from real food, enough protein '
            'and a weekly average that survives a birthday. Progress should be '
            'measured with a scale, a tape, photos and a logbook — not vibes '
            'from a mirror at midnight.',
            style: TextStyle(color: p.muted, fontSize: 11.5, height: 1.6),
          ),
          const SizedBox(height: 24),
          const DividerLabel('Natural means natural'),
          const SizedBox(height: 12),
          SurfaceCard(
            color: p.ember.withValues(alpha: 0.06),
            borderColor: p.ember.withValues(alpha: 0.22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.science_outlined, size: 18, color: p.ember),
                    const SizedBox(width: 8),
                    Text(
                      'THE HONEST CEILING',
                      style: TextStyle(
                        color: p.ember,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 9),
                Text(
                  'A good year of natural training might add roughly 2–4 kg of '
                  'lean body mass for a lifter who is already trained. Beginners '
                  'can gain faster; advanced lifters often gain far less. '
                  'Genetics, age, sleep, calories, training age and consistency '
                  'all matter.\\n\\n'
                  'Physiques that look like comic-book covers usually involve '
                  'performance-enhancing drugs, professional lighting, pumps, '
                  'dehydration, editing or all of the above. Thetics will not '
                  'sell you a fictional ceiling. It will help you build the best '
                  'version of your own frame.',
                  style: TextStyle(color: p.muted, fontSize: 10.5, height: 1.6),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const DividerLabel('Training philosophy'),
          const SizedBox(height: 12),
          _AboutBullet(
            icon: Icons.fitness_center_rounded,
            title: 'Progressive overload',
            body: 'Add weight, reps or quality over time. The logbook decides, '
                'not how sore you feel.',
          ),
          _AboutBullet(
            icon: Icons.timer_outlined,
            title: 'Recovery is training',
            body:
                'Heavy Duty-style HIT, 4×4 and 5×5 all work when the effort is '
                'real and the recovery is there. More is not automatically better.',
          ),
          _AboutBullet(
            icon: Icons.restaurant_outlined,
            title: 'Food first',
            body:
                'Calories and protein drive body composition. Supplements are '
                'optional; the basics are not.',
          ),
          _AboutBullet(
            icon: Icons.trending_up_rounded,
            title: 'The long game',
            body: 'You are playing a five-year game. One missed session or one '
                'birthday meal changes nothing. Quitting for a month changes a lot.',
          ),
          const SizedBox(height: 14),
          Text(
            'Programs are inspired by classic natural-bodybuilding and '
            'strength methods, including Mike Mentzer’s Heavy Duty principles, '
            '4×4 density work and 5×5 linear progression. Thetics is an '
            'independent educational project and is not affiliated with or '
            'endorsed by any coach, athlete or estate.',
            style: TextStyle(color: p.faint, fontSize: 10, height: 1.55),
          ),
          const SizedBox(height: 24),
          const DividerLabel('Not medical advice'),
          const SizedBox(height: 12),
          Text(
            'Thetics provides general fitness and nutrition education. It is '
            'not a medical device and does not diagnose, treat or prevent any '
            'condition. BMI is a population screening tool, not a diagnosis. '
            'Body-fat estimates from scales, calipers or formulas are estimates.\\n\\n'
            'Talk to a qualified clinician or registered dietitian before '
            'starting a new plan if you are pregnant, under 18, managing a '
            'health condition, taking medication, recovering from an injury or '
            'have a history of disordered eating. If something hurts sharply, '
            'stop and get it checked. If a number is affecting your mental '
            'health, that matters more than the number.',
            style: TextStyle(color: p.muted, fontSize: 10.5, height: 1.6),
          ),
          const SizedBox(height: 24),
          const DividerLabel('Privacy'),
          const SizedBox(height: 12),
          _AboutBullet(
            icon: Icons.lock_outline_rounded,
            title: 'Local-first by design',
            body:
                'No account, no cloud, no ads and no analytics. Your profile, '
                'workouts, meals and photos live on this device. Exported '
                'backups are only as private as the place you paste them.',
          ),
          _AboutBullet(
            icon: Icons.photo_library_outlined,
            title: 'Your photos stay yours',
            body: 'Progress photos are copied into the app’s private storage. '
                'They are not uploaded or scanned. The planned AI food-photo '
                'feature will be opt-in and clearly labelled when it ships.',
          ),
          const SizedBox(height: 24),
          const DividerLabel('Credits'),
          const SizedBox(height: 12),
          Text(
            'Exercise images and data: free-exercise-db by yuhonas, released '
            'under the Unlicense. Fonts: Barlow Condensed by Jeremy Tribby and '
            'Manrope by Mikhail Sharanda, licensed under the SIL Open Font '
            'License. The rest of the app was built for Thetics.',
            style: TextStyle(color: p.faint, fontSize: 10, height: 1.55),
          ),
          const SizedBox(height: 18),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: () async {
                await Clipboard.setData(
                  const ClipboardData(
                    text: 'https://github.com/AbduljabbarBXR/thetics',
                  ),
                );
                if (!context.mounted) return;
                showTheticsSnack(context, 'Repository link copied.');
              },
              icon: const Icon(Icons.link_rounded, size: 17),
              label: const Text('COPY REPOSITORY LINK'),
            ),
          ),
          const SizedBox(height: 26),
          Center(
            child: Column(
              children: [
                Text(
                  'BUILT FOR THE LONG GAME.',
                  style: TextStyle(
                    color: p.accent,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.6,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Thetics · local-first fitness tracking',
                  style: TextStyle(color: p.faint, fontSize: 9),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AboutBullet extends StatelessWidget {
  const _AboutBullet({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: p.accent.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: p.accent, size: 17),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: p.text,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  body,
                  style: TextStyle(color: p.faint, fontSize: 10, height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
