import 'package:flutter/material.dart';

import '../app_state.dart';
import '../theme.dart';
import '../widgets.dart';

class BunkCalculatorScreen extends StatefulWidget {
  const BunkCalculatorScreen({super.key});

  @override
  State<BunkCalculatorScreen> createState() => _BunkCalculatorScreenState();
}

class _BunkCalculatorScreenState extends State<BunkCalculatorScreen> {
  int _sel = -1; // -1 = overall, otherwise index into appState.subjects
  double _skip = 0;

  String _plural(int n) => n == 1 ? 'class' : 'classes';

  @override
  Widget build(BuildContext context) {
    final subjects = appState.subjects;
    final target = appState.attendanceTarget;
    final attended = _sel < 0 ? appState.totalAttended : subjects[_sel].attended;
    final total = _sel < 0 ? appState.totalClasses : subjects[_sel].total;
    final pct = total == 0 ? 100.0 : attended * 100 / total;
    final ok = pct >= target;
    final safe = safeBunks(attended, total, target);
    final need = classesToRecover(attended, total, target);
    final color = ok ? (safe <= 2 ? AppColors.warning : AppColors.success) : AppColors.danger;

    final skip = _skip.round();
    final after = attended * 100 / (total + skip);
    final afterOk = after >= target;

    String headline;
    if (ok) {
      headline = safe == 0
          ? "Don't miss any class"
          : 'You can safely miss $safe ${_plural(safe)}';
    } else if (need < 0) {
      headline = 'Target is out of reach';
    } else {
      headline = 'Attend the next $need ${_plural(need)}';
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Bunk Calculator')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  ChoiceChip(
                    label: const Text('Overall'),
                    selected: _sel < 0,
                    onSelected: (_) => setState(() => _sel = -1),
                  ),
                  for (var i = 0; i < subjects.length; i++)
                    ChoiceChip(
                      label: Text(subjects[i].code),
                      selected: _sel == i,
                      onSelected: (_) => setState(() => _sel = i),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              AppCard(
                color: tint(color, 0.08),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_sel < 0 ? 'Overall attendance' : subjects[_sel].name,
                        style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    Text('${pct.toStringAsFixed(1)}%',
                        style: TextStyle(fontSize: 40, fontWeight: FontWeight.w800, color: color)),
                    Text('$attended attended of $total • target ${target.round()}%',
                        style: const TextStyle(color: AppColors.muted)),
                    const SizedBox(height: 14),
                    Text(headline,
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: color)),
                    if (ok && safe > 0)
                      const Padding(
                        padding: EdgeInsets.only(top: 4),
                        child: Text('…and still stay above your target.',
                            style: TextStyle(color: AppColors.muted)),
                      ),
                    if (!ok && need > 0)
                      const Padding(
                        padding: EdgeInsets.only(top: 4),
                        child: Text('…in a row, without missing any, to get back to your target.',
                            style: TextStyle(color: AppColors.muted)),
                      ),
                  ],
                ),
              ),
              const SectionHeader('What if I skip…'),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Missing $skip more ${_plural(skip)}',
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    Slider(
                      value: _skip,
                      min: 0,
                      max: 20,
                      divisions: 20,
                      label: '$skip',
                      onChanged: (v) => setState(() => _skip = v),
                    ),
                    Row(
                      children: [
                        Text('${after.toStringAsFixed(1)}%',
                            style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: afterOk ? AppColors.success : AppColors.danger)),
                        const SizedBox(width: 10),
                        Pill(afterOk ? 'Above target' : 'Below target',
                            afterOk ? AppColors.success : AppColors.danger),
                      ],
                    ),
                  ],
                ),
              ),
              const SectionHeader('By subject'),
              for (var i = 0; i < subjects.length; i++)
                _SubjectRow(
                  subject: subjects[i],
                  target: target,
                  selected: _sel == i,
                  onTap: () => setState(() => _sel = i),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SubjectRow extends StatelessWidget {
  const _SubjectRow({
    required this.subject,
    required this.target,
    required this.selected,
    required this.onTap,
  });
  final Subject subject;
  final double target;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ok = subject.percent >= target;
    final safe = safeBunks(subject.attended, subject.total, target);
    final need = classesToRecover(subject.attended, subject.total, target);
    final color = ok ? AppColors.success : AppColors.danger;
    return AppCard(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 10),
      onTap: onTap,
      color: selected ? tint(AppColors.primary, 0.06) : null,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(subject.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text('${subject.attended}/${subject.total} • ${subject.percent.toStringAsFixed(1)}%',
                    style: const TextStyle(fontSize: 12, color: AppColors.muted)),
              ],
            ),
          ),
          Pill(
            ok
                ? (safe == 0 ? 'Don\'t miss' : 'Can miss $safe')
                : (need < 0 ? 'Unreachable' : 'Attend $need'),
            color,
          ),
        ],
      ),
    );
  }
}
