import 'dart:async';

import 'package:flutter/material.dart';

import '../app_state.dart';
import '../theme.dart';
import '../widgets.dart';
import 'bunk_calculator_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.onNavigate});

  /// Switches the bottom-nav tab (0 Home, 1 Schedule, 2 Notifications, 3 Profile).
  final ValueChanged<int> onNavigate;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        final student = appState.user;
        if (student == null) return const SizedBox.shrink();
        final now = DateTime.now();

        return SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              _Header(student: student, now: now),
              const SizedBox(height: 16),
              const _ClassStatusCard(),
              const SizedBox(height: 8),
              SectionHeader("Today's timetable",
                  actionLabel: 'Full schedule', onAction: () => onNavigate(1)),
              ..._todayTimetable(now),
              const SizedBox(height: 4),
              const SectionHeader('Attendance summary'),
              _attendanceCard(context),
              SectionHeader('Upcoming events',
                  actionLabel: 'See all', onAction: () => onNavigate(1)),
              ..._upcomingEvents(),
              SectionHeader('Important announcements',
                  actionLabel: 'See all', onAction: () => onNavigate(2)),
              ..._announcements(),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _todayTimetable(DateTime now) {
    final classes = appState.classesOn(now);
    if (classes.isEmpty) {
      return [
        const AppCard(
          child: Row(
            children: [
              Icon(Icons.weekend_rounded, color: AppColors.success),
              SizedBox(width: 12),
              Expanded(child: Text('No classes today. Enjoy your day!')),
            ],
          ),
        ),
      ];
    }
    final out = <Widget>[];
    for (final p in appState.periods) {
      final match = classes.where((c) => c.period.index == p.index).toList();
      out.add(match.isEmpty
          ? FreePeriodTile(period: p)
          : ClassTile(session: match.first, date: now));
    }
    return out;
  }

  Widget _attendanceCard(BuildContext context) {
    final pct = appState.overallPercent;
    final target = appState.attendanceTarget;
    final ok = pct >= target;
    final safe = safeBunks(appState.totalAttended, appState.totalClasses, target);
    final need = classesToRecover(appState.totalAttended, appState.totalClasses, target);
    final color = ok ? AppColors.success : AppColors.danger;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 76,
                height: 76,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CircularProgressIndicator(
                      value: (pct / 100).clamp(0.0, 1.0),
                      strokeWidth: 8,
                      color: color,
                      backgroundColor: tint(color, 0.15),
                    ),
                    Center(
                      child: Text('${pct.toStringAsFixed(0)}%',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Pill(ok ? 'On track' : 'Below target', color),
                        const SizedBox(width: 8),
                        Text('Target ${target.round()}%',
                            style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      ok
                          ? (safe == 0
                              ? "You're right at the limit. Don't miss any class."
                              : 'You can safely miss $safe more class${safe == 1 ? '' : 'es'}.')
                          : (need < 0
                              ? 'Target cannot be reached.'
                              : 'Attend the next $need class${need == 1 ? '' : 'es'} to reach your target.'),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          for (final s in appState.subjects)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  SizedBox(
                    width: 120,
                    child: Text(s.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12.5)),
                  ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: (s.percent / 100).clamp(0.0, 1.0),
                        minHeight: 7,
                        color: s.percent >= target ? AppColors.success : AppColors.danger,
                        backgroundColor: tint(AppColors.muted, 0.15),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 44,
                    child: Text('${s.percent.toStringAsFixed(0)}%',
                        textAlign: TextAlign.right,
                        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 14),
          FilledButton.tonalIcon(
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(46)),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const BunkCalculatorScreen()),
            ),
            icon: const Icon(Icons.calculate_rounded),
            label: const Text('Open Bunk Calculator'),
          ),
        ],
      ),
    );
  }

  List<Widget> _upcomingEvents() {
    final list = appState.upcomingEvents(limit: 4);
    if (list.isEmpty) {
      return [const AppCard(child: Text('No upcoming events.'))];
    }
    return [for (final e in list) EventTile(event: e, showDate: true)];
  }

  List<Widget> _announcements() {
    final list = appState.announcements();
    if (list.isEmpty) {
      return [const AppCard(child: Text('No announcements right now.'))];
    }
    return [
      for (final n in list)
        AppCard(
          padding: const EdgeInsets.all(14),
          margin: const EdgeInsets.only(bottom: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(n.category.icon, color: n.category.color),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(n.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 3),
                    Text(n.body,
                        style: const TextStyle(fontSize: 12.5, color: AppColors.muted)),
                    const SizedBox(height: 4),
                    Text(timeAgo(n.time),
                        style: const TextStyle(fontSize: 11, color: AppColors.muted)),
                  ],
                ),
              ),
            ],
          ),
        ),
    ];
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.student, required this.now});
  final Student student;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Hello, ${student.firstName} 👋',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text(fmtDate(now),
                  style: const TextStyle(fontSize: 14, color: AppColors.muted)),
            ],
          ),
        ),
        CircleAvatar(
          radius: 24,
          backgroundColor: tint(AppColors.primary, 0.12),
          child: Text(student.initials,
              style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.primary)),
        ),
      ],
    );
  }
}

/// Ongoing class + next class countdown (ticks every second).
class _ClassStatusCard extends StatefulWidget {
  const _ClassStatusCard();

  @override
  State<_ClassStatusCard> createState() => _ClassStatusCardState();
}

class _ClassStatusCardState extends State<_ClassStatusCard> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _dayLabel(DateTime start, DateTime now) {
    if (sameDay(start, now)) return 'Today';
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    if (sameDay(start, tomorrow)) return 'Tomorrow';
    return dayName(start);
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final current = appState.currentClass(now);
    final next = appState.nextClass(now);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [AppColors.primary, Color(0xFF7C3AED)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (current != null) ..._ongoing(current, now),
          if (current != null && next != null)
            const Divider(color: Colors.white24, height: 28),
          if (next != null) ..._next(next, now, compact: current != null),
          if (current == null && next == null)
            const Text('No upcoming classes',
                style: TextStyle(color: Colors.white, fontSize: 16)),
        ],
      ),
    );
  }

  List<Widget> _ongoing(ClassSession c, DateTime now) {
    final start = atTime(now, c.period.start);
    final end = atTime(now, c.period.end);
    final elapsed = now.difference(start).inSeconds / end.difference(start).inSeconds;
    return [
      const Text('ONGOING NOW',
          style: TextStyle(color: Colors.white70, fontSize: 12, letterSpacing: 1.2, fontWeight: FontWeight.w700)),
      const SizedBox(height: 6),
      Text(c.subject.name,
          style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
      const SizedBox(height: 4),
      Text('${c.subject.faculty} • ${c.subject.room}',
          style: const TextStyle(color: Colors.white70)),
      const SizedBox(height: 12),
      ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: LinearProgressIndicator(
          value: elapsed.clamp(0.0, 1.0),
          minHeight: 6,
          color: Colors.white,
          backgroundColor: Colors.white24,
        ),
      ),
      const SizedBox(height: 8),
      Text('Ends in ${fmtCountdown(end.difference(now))}',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
    ];
  }

  List<Widget> _next(NextClass n, DateTime now, {required bool compact}) {
    return [
      Text(compact ? 'UP NEXT' : 'NEXT CLASS',
          style: const TextStyle(color: Colors.white70, fontSize: 12, letterSpacing: 1.2, fontWeight: FontWeight.w700)),
      const SizedBox(height: 6),
      Text(n.session.subject.name,
          style: TextStyle(
              color: Colors.white,
              fontSize: compact ? 17 : 22,
              fontWeight: FontWeight.w800)),
      const SizedBox(height: 4),
      Text('${_dayLabel(n.start, now)} • ${fmtTime(n.session.period.start)} • ${n.session.subject.room}',
          style: const TextStyle(color: Colors.white70)),
      const SizedBox(height: 10),
      Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const Icon(Icons.timer_outlined, color: Colors.white, size: 20),
          const SizedBox(width: 6),
          Text(fmtCountdown(n.start.difference(now)),
              style: TextStyle(
                  color: Colors.white,
                  fontSize: compact ? 20 : 30,
                  fontWeight: FontWeight.w800)),
          const SizedBox(width: 8),
          const Padding(
            padding: EdgeInsets.only(bottom: 4),
            child: Text('to start', style: TextStyle(color: Colors.white70)),
          ),
        ],
      ),
    ];
  }
}
