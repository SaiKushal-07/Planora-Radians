import 'package:flutter/material.dart';

import '../app_state.dart';
import '../theme.dart';
import '../widgets.dart';
import 'add_event_sheet.dart';

/// Schedule tab: Daily / Weekly / Monthly views sharing one selected date.
class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  DateTime _selected = dateOnly(DateTime.now());

  void _select(DateTime d) => setState(() => _selected = dateOnly(d));

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Schedule'),
          actions: [
            IconButton(
              tooltip: 'Jump to today',
              icon: const Icon(Icons.today_rounded),
              onPressed: () => _select(DateTime.now()),
            ),
          ],
          bottom: const TabBar(
            tabs: [Tab(text: 'Daily'), Tab(text: 'Weekly'), Tab(text: 'Monthly')],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => showAddEventSheet(context, _selected),
          icon: const Icon(Icons.add_rounded),
          label: const Text('Add'),
        ),
        body: ListenableBuilder(
          listenable: appState,
          builder: (context, _) => TabBarView(
            children: [
              _DailyView(selected: _selected, onChanged: _select),
              _WeeklyView(selected: _selected, onChanged: _select),
              _MonthlyView(selected: _selected, onChanged: _select),
            ],
          ),
        ),
      ),
    );
  }
}

DateTime _addDays(DateTime d, int n) => DateTime(d.year, d.month, d.day + n);
DateTime _mondayOf(DateTime d) => _addDays(d, -(d.weekday - 1));

// ───────────────────────── Daily ─────────────────────────

class _Item {
  const _Item(this.minutes, this.widget);
  final int minutes;
  final Widget widget;
}

class _DailyView extends StatelessWidget {
  const _DailyView({required this.selected, required this.onChanged});
  final DateTime selected;
  final ValueChanged<DateTime> onChanged;

  List<_Item> _items() {
    final items = <_Item>[];
    for (final c in appState.classesOn(selected)) {
      items.add(_Item(minutesOf(c.period.start), ClassTile(session: c, date: selected)));
    }
    for (final p in appState.freePeriodsOn(selected)) {
      items.add(_Item(minutesOf(p.start), FreePeriodTile(period: p)));
    }
    for (final e in appState.eventsOn(selected)) {
      items.add(_Item(
        e.start == null ? -1 : minutesOf(e.start!),
        EventTile(
          event: e,
          onDelete: e.source == 'user' ? () => appState.deleteEvent(e.id) : null,
        ),
      ));
    }
    items.sort((a, b) => a.minutes.compareTo(b.minutes));
    return items;
  }

  @override
  Widget build(BuildContext context) {
    final monday = _mondayOf(selected);
    final items = _items();
    final classCount = appState.classesOn(selected).length;
    final freeCount = appState.freePeriodsOn(selected).length;
    final eventCount = appState.eventsOn(selected).length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      children: [
        Row(
          children: [
            IconButton(
              onPressed: () => onChanged(_addDays(selected, -1)),
              icon: const Icon(Icons.chevron_left_rounded),
            ),
            Expanded(
              child: Column(
                children: [
                  Text(dayName(selected),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                  Text('${selected.day} ${monthName(selected.month)} ${selected.year}',
                      style: const TextStyle(color: AppColors.muted)),
                ],
              ),
            ),
            IconButton(
              onPressed: () => onChanged(_addDays(selected, 1)),
              icon: const Icon(Icons.chevron_right_rounded),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            for (var i = 0; i < 7; i++)
              Expanded(
                child: _DayChip(
                  date: _addDays(monday, i),
                  selected: selected,
                  onTap: onChanged,
                ),
              ),
          ],
        ),
        const SizedBox(height: 14),
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text(
            '$classCount classes • $freeCount free periods • $eventCount events',
            style: const TextStyle(color: AppColors.muted, fontSize: 13),
          ),
        ),
        if (items.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 48),
            child: Column(
              children: [
                Icon(Icons.event_available_rounded, size: 56, color: AppColors.muted),
                SizedBox(height: 12),
                Text('Nothing scheduled', style: TextStyle(fontWeight: FontWeight.w700)),
                SizedBox(height: 4),
                Text('Tap Add to create a personal schedule.',
                    style: TextStyle(color: AppColors.muted)),
              ],
            ),
          )
        else
          ...items.map((e) => e.widget),
      ],
    );
  }
}

class _DayChip extends StatelessWidget {
  const _DayChip({required this.date, required this.selected, required this.onTap});
  final DateTime date;
  final DateTime selected;
  final ValueChanged<DateTime> onTap;

  @override
  Widget build(BuildContext context) {
    final isSel = sameDay(date, selected);
    final isToday = sameDay(date, DateTime.now());
    final hasEvents = appState.eventsOn(date).isNotEmpty;
    return GestureDetector(
      onTap: () => onTap(date),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSel ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: isToday && !isSel ? Border.all(color: AppColors.primary, width: 1.5) : null,
        ),
        child: Column(
          children: [
            Text(shortDayName(date),
                style: TextStyle(
                    fontSize: 11,
                    color: isSel ? Colors.white70 : AppColors.muted)),
            const SizedBox(height: 2),
            Text('${date.day}',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: isSel ? Colors.white : AppColors.text)),
            const SizedBox(height: 4),
            Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: hasEvents
                    ? (isSel ? Colors.white : AppColors.warning)
                    : Colors.transparent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ───────────────────────── Weekly ─────────────────────────

class _WeeklyView extends StatelessWidget {
  const _WeeklyView({required this.selected, required this.onChanged});
  final DateTime selected;
  final ValueChanged<DateTime> onChanged;

  void _details(BuildContext context, ClassSession s, DateTime date) {
    final color = appState.subjectColor(s.subject.code);
    showModalBottomSheet<void>(
      context: context,
      constraints: const BoxConstraints(maxWidth: 560),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 6,
                    height: 40,
                    decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(s.subject.name,
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _row(Icons.badge_outlined, s.subject.code),
              _row(Icons.person_outline_rounded, s.subject.faculty),
              _row(Icons.meeting_room_outlined, s.subject.room),
              _row(Icons.access_time_rounded, '${fmtDate(date)}\n${s.period.label}'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(IconData icon, String text) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: AppColors.muted),
            const SizedBox(width: 12),
            Expanded(child: Text(text, style: const TextStyle(fontSize: 15))),
          ],
        ),
      );

  Widget _cell(BuildContext context, DateTime date, Period p) {
    final classes = appState.classesOn(date);
    final match = classes.where((c) => c.period.index == p.index).toList();
    if (match.isEmpty) {
      return Container(
        height: 52,
        margin: const EdgeInsets.all(2),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: classes.isEmpty ? Colors.transparent : tint(AppColors.success, 0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(classes.isEmpty ? '' : 'free',
            style: const TextStyle(fontSize: 9, color: AppColors.success)),
      );
    }
    final s = match.first;
    final color = appState.subjectColor(s.subject.code);
    return GestureDetector(
      onTap: () => _details(context, s, date),
      child: Container(
        height: 52,
        margin: const EdgeInsets.all(2),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: tint(color, 0.15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(s.subject.code,
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: color)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final monday = _mondayOf(selected);
    final saturday = _addDays(monday, 5);
    final sunday = _addDays(monday, 6);
    final today = DateTime.now();

    final rows = <TableRow>[
      TableRow(children: [
        const SizedBox(),
        for (var i = 0; i < 6; i++)
          Builder(builder: (_) {
            final d = _addDays(monday, i);
            final isToday = sameDay(d, today);
            return Container(
              margin: const EdgeInsets.all(2),
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: isToday ? AppColors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Text(shortDayName(d),
                      style: TextStyle(
                          fontSize: 11,
                          color: isToday ? Colors.white70 : AppColors.muted)),
                  Text('${d.day}',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: isToday ? Colors.white : AppColors.text)),
                ],
              ),
            );
          }),
      ]),
    ];

    for (final p in appState.periods) {
      rows.add(TableRow(children: [
        Padding(
          padding: const EdgeInsets.only(right: 4),
          child: Text('${fmtClock(p.start)}\n${fmtClock(p.end)}',
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 10, color: AppColors.muted, height: 1.3)),
        ),
        for (var i = 0; i < 6; i++) _cell(context, _addDays(monday, i), p),
      ]));
      if (p.index == 3) {
        rows.add(TableRow(children: [
          const Padding(
            padding: EdgeInsets.only(right: 4),
            child: Text('Lunch',
                textAlign: TextAlign.right,
                style: TextStyle(fontSize: 10, color: AppColors.muted)),
          ),
          for (var i = 0; i < 6; i++)
            Container(
              height: 18,
              margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
              decoration: BoxDecoration(
                color: tint(AppColors.muted, 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
            ),
        ]));
      }
    }

    final weekEvents = appState.eventsBetween(monday, sunday);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      children: [
        Row(
          children: [
            IconButton(
              onPressed: () => onChanged(_addDays(selected, -7)),
              icon: const Icon(Icons.chevron_left_rounded),
            ),
            Expanded(
              child: Text(
                '${monday.day} ${shortMonth(monday.month)} – ${saturday.day} ${shortMonth(saturday.month)}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
              ),
            ),
            IconButton(
              onPressed: () => onChanged(_addDays(selected, 7)),
              icon: const Icon(Icons.chevron_right_rounded),
            ),
          ],
        ),
        AppCard(
          padding: const EdgeInsets.all(8),
          child: Table(
            columnWidths: const {0: FixedColumnWidth(40)},
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            children: rows,
          ),
        ),
        const SectionHeader('Subjects & faculty'),
        for (final s in appState.subjects)
          Padding(
            padding: const EdgeInsets.only(bottom: 8, left: 4),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: appState.subjectColor(s.code),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text('${s.code} • ${s.name}',
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                ),
                Text(s.faculty,
                    style: const TextStyle(fontSize: 12, color: AppColors.muted)),
              ],
            ),
          ),
        const SectionHeader('This week: exams, deadlines & events'),
        if (weekEvents.isEmpty)
          const AppCard(child: Text('Nothing this week.'))
        else
          for (final e in weekEvents)
            EventTile(
              event: e,
              showDate: true,
              onDelete: e.source == 'user' ? () => appState.deleteEvent(e.id) : null,
            ),
      ],
    );
  }
}

// ───────────────────────── Monthly ─────────────────────────

class _MonthlyView extends StatefulWidget {
  const _MonthlyView({required this.selected, required this.onChanged});
  final DateTime selected;
  final ValueChanged<DateTime> onChanged;

  @override
  State<_MonthlyView> createState() => _MonthlyViewState();
}

class _MonthlyViewState extends State<_MonthlyView> {
  late DateTime _month = DateTime(widget.selected.year, widget.selected.month);

  @override
  void didUpdateWidget(covariant _MonthlyView old) {
    super.didUpdateWidget(old);
    if (old.selected.month != widget.selected.month ||
        old.selected.year != widget.selected.year) {
      _month = DateTime(widget.selected.year, widget.selected.month);
    }
  }

  void _shiftMonth(int n) =>
      setState(() => _month = DateTime(_month.year, _month.month + n));

  Widget _dayCell(DateTime date) {
    final isSel = sameDay(date, widget.selected);
    final isToday = sameDay(date, DateTime.now());
    final types = appState.eventsOn(date).map((e) => e.type).toSet().take(3).toList();
    final hasClasses = appState.classesOn(date).isNotEmpty;

    return GestureDetector(
      onTap: () => widget.onChanged(date),
      child: Container(
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: isSel ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: isToday && !isSel ? Border.all(color: AppColors.primary, width: 1.5) : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('${date.day}',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: isSel
                      ? Colors.white
                      : (hasClasses ? AppColors.text : AppColors.muted),
                )),
            const SizedBox(height: 4),
            SizedBox(
              height: 6,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (final t in types)
                    Container(
                      width: 6,
                      height: 6,
                      margin: const EdgeInsets.symmetric(horizontal: 1),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSel ? Colors.white : t.color,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final first = DateTime(_month.year, _month.month, 1);
    final offset = first.weekday - 1;
    final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
    final sel = widget.selected;
    final dayEvents = appState.eventsOn(sel);
    final classCount = appState.classesOn(sel).length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      children: [
        Row(
          children: [
            IconButton(
              onPressed: () => _shiftMonth(-1),
              icon: const Icon(Icons.chevron_left_rounded),
            ),
            Expanded(
              child: Text('${monthName(_month.month)} ${_month.year}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            ),
            IconButton(
              onPressed: () => _shiftMonth(1),
              icon: const Icon(Icons.chevron_right_rounded),
            ),
          ],
        ),
        AppCard(
          padding: const EdgeInsets.all(8),
          child: Column(
            children: [
              Row(
                children: [
                  for (final d in ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'])
                    Expanded(
                      child: Center(
                        child: Text(d,
                            style: const TextStyle(fontSize: 11, color: AppColors.muted)),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              GridView.count(
                crossAxisCount: 7,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 0.9,
                children: [
                  for (var i = 0; i < offset; i++) const SizedBox(),
                  for (var d = 1; d <= daysInMonth; d++)
                    _dayCell(DateTime(_month.year, _month.month, d)),
                ],
              ),
            ],
          ),
        ),
        Wrap(
          spacing: 12,
          runSpacing: 6,
          children: [
            for (final t in EventType.values)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(color: t.color, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 4),
                  Text(t.label,
                      style: const TextStyle(fontSize: 11, color: AppColors.muted)),
                ],
              ),
          ],
        ),
        SectionHeader(fmtDate(sel)),
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text(
            classCount == 0
                ? 'No classes'
                : '$classCount classes scheduled • see the Daily tab for details',
            style: const TextStyle(color: AppColors.muted, fontSize: 13),
          ),
        ),
        if (dayEvents.isEmpty)
          const AppCard(child: Text('No exams, deadlines or events on this day.'))
        else
          for (final e in dayEvents)
            EventTile(
              event: e,
              onDelete: e.source == 'user' ? () => appState.deleteEvent(e.id) : null,
            ),
      ],
    );
  }
}
