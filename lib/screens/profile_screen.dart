import 'package:flutter/material.dart';

import '../app_state.dart';
import '../theme.dart';
import '../widgets.dart';
import 'bunk_calculator_screen.dart';
import 'notification_preferences_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _confirmLogout(BuildContext context) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text('You will need to sign in again to see your schedule.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Log out')),
        ],
      ),
    );
    if (yes == true) appState.logout();
  }

  String _lastSync() {
    final t = appState.lastErpSync;
    return t == null ? 'Never synced' : 'Last synced ${timeAgo(t)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListenableBuilder(
        listenable: appState,
        builder: (context, _) {
          final s = appState.user;
          if (s == null) return const SizedBox.shrink();
          final enabled = appState.prefs.values.where((v) => v).length;

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
            children: [
              AppCard(
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: tint(AppColors.primary, 0.12),
                      child: Text(s.initials,
                          style: const TextStyle(
                              fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.primary)),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s.name,
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 2),
                          Text(s.email, style: const TextStyle(color: AppColors.muted)),
                          if (appState.isDemo)
                            const Padding(
                              padding: EdgeInsets.only(top: 6),
                              child: Pill('Demo account', AppColors.primary),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SectionHeader('Student information'),
              AppCard(
                child: Column(
                  children: [
                    _InfoRow(Icons.badge_outlined, 'USN', s.usn),
                    _InfoRow(Icons.alternate_email_rounded, 'Username', s.username),
                    _InfoRow(Icons.apartment_rounded, 'Department', s.department),
                    _InfoRow(Icons.layers_outlined, 'Semester', 'Semester ${s.semester}',
                        last: true),
                  ],
                ),
              ),
              const SectionHeader('Integrations'),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.cloud_sync_rounded, color: AppColors.primary),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text('AUERP',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                        ),
                        Pill(appState.erpConnected ? 'Connected' : 'Not connected',
                            appState.erpConnected ? AppColors.success : AppColors.muted),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Syncs your timetable, attendance and exam schedule. ${_lastSync()}.',
                      style: const TextStyle(fontSize: 12.5, color: AppColors.muted),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        FilledButton.tonalIcon(
                          onPressed: appState.erpSyncing ? null : appState.syncErp,
                          icon: appState.erpSyncing
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.sync_rounded),
                          label: Text(appState.erpSyncing ? 'Syncing…' : 'Sync now'),
                        ),
                        const SizedBox(width: 8),
                        if (appState.erpConnected)
                          TextButton(
                              onPressed: appState.disconnectErp, child: const Text('Disconnect')),
                      ],
                    ),
                  ],
                ),
              ),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.mail_outline_rounded, color: AppColors.primary),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text('Outlook email',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                        ),
                        if (appState.outlookSyncing)
                          const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2))
                        else
                          Switch(
                            value: appState.outlookConnected,
                            onChanged: (v) => appState.setOutlook(v),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      appState.outlookConnected
                          ? 'Email event detection is on. ${appState.detectedEmailEvents} events found and added to your calendar.'
                          : 'Connect to automatically detect events, workshops and deadlines from your emails.',
                      style: const TextStyle(fontSize: 12.5, color: AppColors.muted),
                    ),
                  ],
                ),
              ),
              const SectionHeader('Preferences'),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.track_changes_rounded, color: AppColors.primary),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text('Attendance target',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                        ),
                        Text('${appState.attendanceTarget.round()}%',
                            style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary)),
                      ],
                    ),
                    Slider(
                      value: appState.attendanceTarget,
                      min: 50,
                      max: 100,
                      divisions: 50,
                      label: '${appState.attendanceTarget.round()}%',
                      onChanged: (v) => appState.setAttendanceTarget(v.roundToDouble()),
                    ),
                    const Text('Used by the Attendance Manager and attendance summary.',
                        style: TextStyle(fontSize: 12.5, color: AppColors.muted)),
                  ],
                ),
              ),
              AppCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.notifications_active_outlined,
                          color: AppColors.primary),
                      title: const Text('Notification preferences',
                          style: TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: Text('$enabled of ${NotifCategory.values.length} categories on'),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const NotificationPreferencesScreen()),
                      ),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.calculate_rounded, color: AppColors.primary),
                      title: const Text('Attendance Manager',
                          style: TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: const Text('How many classes can you safely miss?'),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const BunkCalculatorScreen()),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.danger,
                  minimumSize: const Size.fromHeight(50),
                  side: BorderSide(color: tint(AppColors.danger, 0.5)),
                ),
                onPressed: () => _confirmLogout(context),
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Log out'),
              ),
              const SizedBox(height: 16),
              const Center(
                child: Text('CampusPulse v1.0 • Running on sample data',
                    style: TextStyle(fontSize: 12, color: AppColors.muted)),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.icon, this.label, this.value, {this.last = false});
  final IconData icon;
  final String label;
  final String value;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: last ? 0 : 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.muted),
          const SizedBox(width: 12),
          SizedBox(
            width: 90,
            child: Text(label, style: const TextStyle(color: AppColors.muted)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
