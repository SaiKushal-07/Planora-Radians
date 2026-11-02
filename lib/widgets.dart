// Small reusable widgets shared by all screens.

import 'package:flutter/material.dart';

import 'app_state.dart';
import 'theme.dart';

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin = const EdgeInsets.only(bottom: 12),
    this.onTap,
    this.color,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final VoidCallback? onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: color ?? Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: tint(Colors.black, 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.actionLabel, this.onAction});
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 0, 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.text,
              ),
            ),
          ),
          if (actionLabel != null)
            TextButton(onPressed: onAction, child: Text(actionLabel!)),
        ],
      ),
    );
  }
}

class Pill extends StatelessWidget {
  const Pill(this.text, this.color, {super.key});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: tint(color, 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }
}

InputDecoration fieldDecoration(String label, IconData icon, {Widget? suffix}) {
  OutlineInputBorder border(Color c, [double w = 1]) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: c, width: w),
      );
  return InputDecoration(
    labelText: label,
    prefixIcon: Icon(icon),
    suffixIcon: suffix,
    filled: true,
    fillColor: Colors.white,
    border: border(tint(AppColors.muted, 0.35)),
    enabledBorder: border(tint(AppColors.muted, 0.35)),
    focusedBorder: border(AppColors.primary, 1.8),
  );
}

class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    this.obscure = false,
    this.keyboardType,
    this.validator,
    this.suffix,
    this.textInputAction,
    this.onSubmitted,
    this.capitalization = TextCapitalization.none,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool obscure;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final Widget? suffix;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final TextCapitalization capitalization;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboardType,
        validator: validator,
        textInputAction: textInputAction,
        textCapitalization: capitalization,
        onFieldSubmitted: onSubmitted,
        decoration: fieldDecoration(label, icon, suffix: suffix),
      ),
    );
  }
}

/// A dropdown-like field that opens a bottom sheet list.
class PickerField extends StatelessWidget {
  const PickerField({
    super.key,
    required this.label,
    required this.icon,
    required this.value,
    required this.options,
    required this.onChanged,
    this.errorText,
  });

  final String label;
  final IconData icon;
  final String? value;
  final List<String> options;
  final ValueChanged<String> onChanged;
  final String? errorText;

  Future<void> _open(BuildContext context) async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      builder: (_) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Text(label,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            ),
            for (final o in options)
              ListTile(
                title: Text(o),
                trailing: o == value
                    ? const Icon(Icons.check_rounded, color: AppColors.primary)
                    : null,
                onTap: () => Navigator.pop(context, o),
              ),
          ],
        ),
      ),
    );
    if (picked != null) onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _open(context),
        child: InputDecorator(
          isEmpty: value == null,
          decoration: fieldDecoration(
            label,
            icon,
            suffix: const Icon(Icons.arrow_drop_down_rounded),
          ).copyWith(errorText: errorText),
          child: Text(value ?? '', maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
      ),
    );
  }
}

void showSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message), behavior: SnackBarBehavior.floating));
}

// ───────────────────────── Schedule tiles ─────────────────────────

/// A class row. If [date] is today it also shows Done / Ongoing / Upcoming.
class ClassTile extends StatelessWidget {
  const ClassTile({super.key, required this.session, required this.date, this.onTap});
  final ClassSession session;
  final DateTime date;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final color = appState.subjectColor(session.subject.code);
    String? status;
    var statusColor = AppColors.muted;
    if (sameDay(date, now)) {
      final s = atTime(date, session.period.start);
      final e = atTime(date, session.period.end);
      if (!now.isBefore(e)) {
        status = 'Done';
      } else if (!now.isBefore(s)) {
        status = 'Ongoing';
        statusColor = AppColors.success;
      } else {
        status = 'Upcoming';
        statusColor = AppColors.primary;
      }
    }
    final ongoing = status == 'Ongoing';

    return AppCard(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 10),
      color: ongoing ? Color.alphaBlend(tint(color, 0.08), Colors.white) : null,
      onTap: onTap,
      child: Row(
        children: [
          SizedBox(
            width: 76,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(fmtTime(session.period.start),
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(fmtTime(session.period.end),
                    style: const TextStyle(fontSize: 12, color: AppColors.muted)),
              ],
            ),
          ),
          Container(
            width: 4,
            height: 46,
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(session.subject.name,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(session.subject.faculty,
                    style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                Text(session.subject.room,
                    style: const TextStyle(fontSize: 12, color: AppColors.muted)),
              ],
            ),
          ),
          if (status != null) Pill(status, statusColor),
        ],
      ),
    );
  }
}

class FreePeriodTile extends StatelessWidget {
  const FreePeriodTile({super.key, required this.period});
  final Period period;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      margin: const EdgeInsets.only(bottom: 10),
      color: tint(AppColors.success, 0.08),
      child: Row(
        children: [
          const Icon(Icons.coffee_rounded, color: AppColors.success, size: 20),
          const SizedBox(width: 10),
          const Text('Free period',
              style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.success)),
          const Spacer(),
          Text(period.label,
              style: const TextStyle(fontSize: 12, color: AppColors.muted)),
        ],
      ),
    );
  }
}

class EventTile extends StatelessWidget {
  const EventTile({super.key, required this.event, this.onDelete, this.showDate = false});
  final CalendarEvent event;
  final VoidCallback? onDelete;
  final bool showDate;

  @override
  Widget build(BuildContext context) {
    final color = event.type.color;
    final parts = <String>[
      if (showDate) fmtShortDate(event.date),
      event.timeLabel,
      if (event.source == 'email') 'From Outlook',
      if (event.note.isNotEmpty) event.note,
    ];
    return AppCard(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: tint(color, 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(event.type.icon, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(event.title,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                const SizedBox(height: 3),
                Text(parts.join(' • '),
                    style: const TextStyle(fontSize: 12, color: AppColors.muted)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Pill(event.type.label, color),
          if (onDelete != null)
            IconButton(
              tooltip: 'Delete',
              visualDensity: VisualDensity.compact,
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline_rounded, color: AppColors.muted),
            ),
        ],
      ),
    );
  }
}
