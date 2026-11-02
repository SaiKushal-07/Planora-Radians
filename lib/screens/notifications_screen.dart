import 'package:flutter/material.dart';

import '../app_state.dart';
import '../theme.dart';
import '../widgets.dart';
import 'notification_preferences_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  NotifCategory? _filter;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          IconButton(
            tooltip: 'Mark all as read',
            icon: const Icon(Icons.done_all_rounded),
            onPressed: appState.markAllRead,
          ),
          IconButton(
            tooltip: 'Preferences',
            icon: const Icon(Icons.tune_rounded),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NotificationPreferencesScreen()),
            ),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: appState,
        builder: (context, _) {
          final all = appState.visibleNotifications;
          final list =
              _filter == null ? all : all.where((n) => n.category == _filter).toList();

          return Column(
            children: [
              SizedBox(
                height: 50,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: const Text('All'),
                        selected: _filter == null,
                        onSelected: (_) => setState(() => _filter = null),
                      ),
                    ),
                    for (final c in NotifCategory.values)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          avatar: Icon(c.icon, size: 16, color: c.color),
                          label: Text(c.shortLabel),
                          selected: _filter == c,
                          onSelected: (_) => setState(() => _filter = c),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: list.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.notifications_off_outlined,
                                size: 56, color: AppColors.muted),
                            SizedBox(height: 12),
                            Text("You're all caught up",
                                style: TextStyle(fontWeight: FontWeight.w700)),
                            SizedBox(height: 4),
                            Text('No notifications in this category.',
                                style: TextStyle(color: AppColors.muted)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        itemCount: list.length,
                        itemBuilder: (context, i) => _NotificationCard(n: list[i]),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({required this.n});
  final AppNotification n;

  @override
  Widget build(BuildContext context) {
    final c = n.category;
    return AppCard(
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.only(bottom: 10),
      color: n.read ? null : Color.alphaBlend(tint(c.color, 0.05), Colors.white),
      onTap: () => appState.markRead(n.id),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: tint(c.color, 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(c.icon, color: c.color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        n.title,
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: n.read ? FontWeight.w600 : FontWeight.w800,
                        ),
                      ),
                    ),
                    if (!n.read)
                      Container(
                        width: 9,
                        height: 9,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(n.body,
                    style: const TextStyle(fontSize: 13, color: AppColors.muted)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Pill(c.shortLabel, c.color),
                    const SizedBox(width: 8),
                    Text(timeAgo(n.time),
                        style: const TextStyle(fontSize: 11, color: AppColors.muted)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
