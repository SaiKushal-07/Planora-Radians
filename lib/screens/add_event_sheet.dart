import 'package:flutter/material.dart';

import '../app_state.dart';
import '../theme.dart';
import '../widgets.dart';

/// Bottom sheet for adding a personal schedule item manually.
Future<void> showAddEventSheet(BuildContext context, DateTime initialDate) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.white,
    constraints: const BoxConstraints(maxWidth: 560),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _AddEventSheet(initialDate: initialDate),
  );
}

class _AddEventSheet extends StatefulWidget {
  const _AddEventSheet({required this.initialDate});
  final DateTime initialDate;

  @override
  State<_AddEventSheet> createState() => _AddEventSheetState();
}

class _AddEventSheetState extends State<_AddEventSheet> {
  final _title = TextEditingController();
  final _note = TextEditingController();
  late DateTime _date = dateOnly(widget.initialDate);
  TimeOfDay? _start;
  TimeOfDay? _end;
  EventType _type = EventType.personal;
  String? _error;

  static const _types = [EventType.personal, EventType.assignment, EventType.exam];

  @override
  void dispose() {
    _title.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (d != null) setState(() => _date = dateOnly(d));
  }

  Future<void> _pickTime(bool isStart) async {
    final t = await showTimePicker(
      context: context,
      initialTime: (isStart ? _start : _end) ?? const TimeOfDay(hour: 9, minute: 0),
    );
    if (t != null) setState(() => isStart ? _start = t : _end = t);
  }

  void _save() {
    if (_title.text.trim().isEmpty) {
      setState(() => _error = 'Please enter a title');
      return;
    }
    if (_start != null && _end != null && minutesOf(_end!) <= minutesOf(_start!)) {
      setState(() => _error = 'End time must be after start time');
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    appState.addEvent(
      title: _title.text.trim(),
      date: _date,
      type: _type,
      start: _start,
      end: _end,
      note: _note.text.trim(),
    );
    Navigator.pop(context);
    messenger.showSnackBar(const SnackBar(
      content: Text('Added to your schedule'),
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 20, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Add to my schedule',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            AppTextField(
              controller: _title,
              label: 'Title',
              icon: Icons.edit_outlined,
              capitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.next,
            ),
            Wrap(
              spacing: 8,
              children: [
                for (final t in _types)
                  ChoiceChip(
                    label: Text(t == EventType.personal ? 'Personal' : '${t.label} reminder'),
                    avatar: Icon(t.icon, size: 18, color: t.color),
                    selected: _type == t,
                    onSelected: (_) => setState(() => _type = t),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: _pickDate,
              icon: const Icon(Icons.event_rounded),
              label: Align(
                alignment: Alignment.centerLeft,
                child: Text(fmtDate(_date)),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickTime(true),
                    icon: const Icon(Icons.access_time_rounded),
                    label: Text(_start == null ? 'Start' : fmtTime(_start!)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickTime(false),
                    icon: const Icon(Icons.access_time_filled_rounded),
                    label: Text(_end == null ? 'End' : fmtTime(_end!)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            AppTextField(
              controller: _note,
              label: 'Note / location (optional)',
              icon: Icons.notes_rounded,
              capitalization: TextCapitalization.sentences,
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(_error!,
                    style: const TextStyle(color: AppColors.danger, fontWeight: FontWeight.w600)),
              ),
            FilledButton(
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
              onPressed: _save,
              child: const Text('Save', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}
