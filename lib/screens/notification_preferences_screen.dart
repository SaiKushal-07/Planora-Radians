import 'package:flutter/material.dart';

import '../app_state.dart';
import '../theme.dart';
import '../widgets.dart';

class NotificationPreferencesScreen extends StatelessWidget {
  const NotificationPreferencesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notification preferences')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListenableBuilder(
            listenable: appState,
            builder: (context, _) => ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(4, 0, 4, 12),
                  child: Text('Choose which notifications you want to receive.',
                      style: TextStyle(color: AppColors.muted)),
                ),
                for (final c in NotifCategory.values)
                  AppCard(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: SwitchListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                      secondary: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: tint(c.color, 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(c.icon, color: c.color),
                      ),
                      title: Text(c.label,
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: Text(c.description, style: const TextStyle(fontSize: 12)),
                      value: appState.prefs[c] ?? true,
                      onChanged: (v) => appState.setPref(c, v),
                    ),
                  ),
                const SectionHeader('Smart notifications'),
                AppCard(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: SwitchListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                    secondary: const Icon(Icons.auto_awesome_rounded, color: AppColors.primary),
                    title: const Text('Smart reminders',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: const Text(
                        'Get nudged before deadlines, exams and events found in your email.',
                        style: TextStyle(fontSize: 12)),
                    value: appState.smartReminders,
                    onChanged: appState.setSmartReminders,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
