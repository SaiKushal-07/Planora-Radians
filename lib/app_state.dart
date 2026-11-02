import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'theme.dart';

// ───────────────────────── Date / time helpers ─────────────────────────

const _dayNames = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday'
];

const _monthNames = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December'
];

String dayName(DateTime d) => _dayNames[d.weekday - 1];
String shortDayName(DateTime d) => _dayNames[d.weekday - 1].substring(0, 3);
String monthName(int m) => _monthNames[m - 1];
String shortMonth(int m) => _monthNames[m - 1].substring(0, 3);

String fmtDate(DateTime d) =>
    '${dayName(d)}, ${d.day} ${monthName(d.month)} ${d.year}';

String fmtShortDate(DateTime d) =>
    '${shortDayName(d)}, ${d.day} ${shortMonth(d.month)}';

String fmtClock(TimeOfDay t) {
  final h = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
  return '$h:${t.minute.toString().padLeft(2, '0')}';
}

String fmtTime(TimeOfDay t) =>
    '${fmtClock(t)} ${t.period == DayPeriod.am ? 'AM' : 'PM'}';

DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

DateTime atTime(DateTime d, TimeOfDay t) =>
    DateTime(d.year, d.month, d.day, t.hour, t.minute);

bool sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

int minutesOf(TimeOfDay t) => t.hour * 60 + t.minute;

String timeAgo(DateTime t) {
  final d = DateTime.now().difference(t);
  if (d.inMinutes < 1) return 'Just now';
  if (d.inMinutes < 60) return '${d.inMinutes}m ago';
  if (d.inHours < 24) return '${d.inHours}h ago';
  if (d.inDays < 7) return '${d.inDays}d ago';
  return '${t.day} ${shortMonth(t.month)}';
}

String fmtCountdown(Duration d) {
  if (d.isNegative) d = Duration.zero;

  String two(int n) => n.toString().padLeft(2, '0');

  final days = d.inDays;
  final h = d.inHours % 24;
  final m = d.inMinutes % 60;
  final s = d.inSeconds % 60;

  if (days > 0) return '${days}d ${two(h)}h ${two(m)}m';
  return '${two(h)}:${two(m)}:${two(s)}';
}

// ───────────────────────── Bunk calculator maths ─────────────────────────

int safeBunks(int attended, int total, double target) {
  if (target <= 0) return 999;
  final x = (attended * 100 / target - total + 1e-9).floor();
  return x < 0 ? 0 : x;
}

int classesToRecover(int attended, int total, double target) {
  if (attended * 100 >= target * total) return 0;
  if (target >= 100) return -1;
  return ((target * total - 100 * attended) / (100 - target) - 1e-9).ceil();
}

// ───────────────────────── Enums ─────────────────────────

enum EventType { exam, assignment, event, personal, academic }

extension EventTypeX on EventType {
  String get label => switch (this) {
        EventType.exam => 'Exam',
        EventType.assignment => 'Assignment',
        EventType.event => 'Event',
        EventType.personal => 'Personal',
        EventType.academic => 'Academic',
      };

  Color get color => switch (this) {
        EventType.exam => AppColors.danger,
        EventType.assignment => AppColors.warning,
        EventType.event => const Color(0xFF8B5CF6),
        EventType.personal => const Color(0xFF0D9488),
        EventType.academic => const Color(0xFF2563EB),
      };

  IconData get icon => switch (this) {
        EventType.exam => Icons.edit_note_rounded,
        EventType.assignment => Icons.assignment_rounded,
        EventType.event => Icons.celebration_rounded,
        EventType.personal => Icons.person_pin_circle_rounded,
        EventType.academic => Icons.school_rounded,
      };
}

enum NotifCategory { academic, events, exams, important, personal }

extension NotifCategoryX on NotifCategory {
  String get label => switch (this) {
        NotifCategory.academic => 'Academic updates',
        NotifCategory.events => 'Events & competitions',
        NotifCategory.exams => 'Examination updates',
        NotifCategory.important => 'Important announcements',
        NotifCategory.personal => 'Personal reminders',
      };

  String get shortLabel => switch (this) {
        NotifCategory.academic => 'Academic',
        NotifCategory.events => 'Events',
        NotifCategory.exams => 'Exams',
        NotifCategory.important => 'Important',
        NotifCategory.personal => 'Personal',
      };

  String get description => switch (this) {
        NotifCategory.academic =>
          'Timetable changes, class cancellations, study material',
        NotifCategory.events => 'Fests, hackathons, workshops, competitions',
        NotifCategory.exams => 'Exam schedules, hall tickets, results',
        NotifCategory.important => 'Announcements from the college',
        NotifCategory.personal => 'Reminders for events you create',
      };

  IconData get icon => switch (this) {
        NotifCategory.academic => Icons.school_rounded,
        NotifCategory.events => Icons.celebration_rounded,
        NotifCategory.exams => Icons.quiz_rounded,
        NotifCategory.important => Icons.campaign_rounded,
        NotifCategory.personal => Icons.alarm_rounded,
      };

  Color get color => switch (this) {
        NotifCategory.academic => const Color(0xFF2563EB),
        NotifCategory.events => const Color(0xFF8B5CF6),
        NotifCategory.exams => AppColors.danger,
        NotifCategory.important => AppColors.warning,
        NotifCategory.personal => const Color(0xFF0D9488),
      };
}

// ───────────────────────── Models ─────────────────────────

const departments = [
  'Computer Science & Engineering',
  'Information Science & Engineering',
  'AI & Machine Learning',
  'Electronics & Communication',
  'Electrical & Electronics',
  'Mechanical Engineering',
  'Civil Engineering',
  'Business Administration',
];

class Student {
  Student({
    required this.name,
    required this.email,
    required this.username,
    required this.usn,
    required this.department,
    required this.semester,
  });

  String name;
  String email;
  String username;
  String usn;
  String department;
  int semester;

  String get firstName => name.trim().split(' ').first;

  String get initials {
    final parts =
        name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();

    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();

    return (parts.first[0] + parts.last[0]).toUpperCase();
  }
}

class Subject {
  const Subject({
    required this.code,
    required this.name,
    required this.faculty,
    required this.room,
    required this.attended,
    required this.total,
  });

  final String code;
  final String name;
  final String faculty;
  final String room;
  final int attended;
  final int total;

  double get percent => total == 0 ? 100 : attended * 100 / total;
}

class Period {
  const Period(this.index, this.start, this.end);

  final int index;
  final TimeOfDay start;
  final TimeOfDay end;

  String get label => '${fmtTime(start)} – ${fmtTime(end)}';
}

class ClassSession {
  const ClassSession(this.subject, this.period);

  final Subject subject;
  final Period period;
}

class NextClass {
  const NextClass(this.session, this.start);

  final ClassSession session;
  final DateTime start;
}

class CalendarEvent {
  CalendarEvent({
    required this.id,
    required this.title,
    required this.date,
    required this.type,
    this.start,
    this.end,
    this.note = '',
    this.source = 'user',
  });

  final String id;
  final String title;
  final DateTime date;
  final TimeOfDay? start;
  final TimeOfDay? end;
  final EventType type;
  final String note;
  final String source;

  String get timeLabel {
    if (start == null) return 'All day';
    if (end == null) return fmtTime(start!);
    return '${fmtTime(start!)} – ${fmtTime(end!)}';
  }
}

class AppNotification {
  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.category,
    required this.time,
    this.read = false,
  });

  final String id;
  final String title;
  final String body;
  final NotifCategory category;
  final DateTime time;
  bool read;
}

// ───────────────────────── App state ─────────────────────────

class AppState extends ChangeNotifier {
  AppState() {
    _seed();
    _authSubscription = _auth.authStateChanges().listen(_handleAuthChange);
  }

  // Firebase services
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  late final StreamSubscription<User?> _authSubscription;

  // Demo account (local only)
  static const demoEmail = 'demo@campuspulse.com';
  static const demoUsername = 'demo';
  static const demoPassword = 'demo123';

  Student? user;

  bool authInitializing = true;

  bool get loggedIn => user != null;
  bool get isDemo => user?.email == demoEmail;

  // ───────────────── Firebase authentication ─────────────────

  Future<void> _handleAuthChange(User? firebaseUser) async {
    if (firebaseUser == null) {
      if (!isDemo) user = null;

      authInitializing = false;
      notifyListeners();
      return;
    }

    await _loadStudentProfile(firebaseUser);
  }

  Future<void> _loadStudentProfile(User firebaseUser) async {
    try {
      final doc =
          await _firestore.collection('users').doc(firebaseUser.uid).get();

      if (!doc.exists) {
        user = null;
        return;
      }

      final data = doc.data()!;

      user = Student(
        name: data['name'] ?? '',
        email: data['email'] ?? firebaseUser.email ?? '',
        username: data['username'] ?? '',
        usn: data['usn'] ?? '',
        department: data['department'] ?? '',
        semester: (data['semester'] as num?)?.toInt() ?? 1,
      );
    } catch (e) {
      debugPrint('Profile loading error: $e');
      user = null;
    } finally {
      authInitializing = false;
      notifyListeners();
    }
  }

  Future<String?> login(String email, String password) async {
    final key = email.trim().toLowerCase();

    // Local demo login
    if (key == demoEmail && password == demoPassword) {
      user = Student(
        name: 'Arjun Mehta',
        email: demoEmail,
        username: demoUsername,
        usn: 'AU23CS042',
        department: 'Computer Science & Engineering',
        semester: 5,
      );

      notifyListeners();
      return null;
    }

    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final firebaseUser = credential.user;

      if (firebaseUser == null) {
        return 'Login failed. Please try again.';
      }

      await _loadStudentProfile(firebaseUser);

      if (user == null) {
        await _auth.signOut();
        return 'Student profile not found. Please contact support.';
      }

      return null;
    } on FirebaseAuthException catch (e) {
      return _authErrorMessage(e);
    } catch (e) {
      debugPrint('Login error: $e');
      return 'Something went wrong. Please try again.';
    }
  }

  void loginDemo() {
    user = Student(
      name: 'Arjun Mehta',
      email: demoEmail,
      username: demoUsername,
      usn: 'AU23CS042',
      department: 'Computer Science & Engineering',
      semester: 5,
    );

    notifyListeners();
  }

  Future<String?> register(Student student, String password) async {
    User? firebaseUser;

    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: student.email.trim(),
        password: password,
      );

      firebaseUser = credential.user;

      if (firebaseUser == null) {
        return 'Account creation failed. Please try again.';
      }

      await _firestore.collection('users').doc(firebaseUser.uid).set({
        'name': student.name.trim(),
        'email': student.email.trim(),
        'username': student.username.trim(),
        'usn': student.usn.trim(),
        'department': student.department,
        'semester': student.semester,
        'createdAt': FieldValue.serverTimestamp(),
      });

      user = student;
      notifyListeners();

      return null;
    } on FirebaseAuthException catch (e) {
      return _authErrorMessage(e);
    } catch (e) {
      debugPrint('Registration error: $e');

      // Clean up the Auth account if saving its profile fails.
      try {
        await firebaseUser?.delete();
      } catch (cleanupError) {
        debugPrint('Account cleanup error: $cleanupError');
      }

      return 'Could not save your profile. Please try again.';
    }
  }

  Future<void> logout() async {
    if (isDemo) {
      user = null;
      notifyListeners();
      return;
    }

    try {
      await _auth.signOut();
    } catch (e) {
      debugPrint('Logout error: $e');
    }

    user = null;
    notifyListeners();
  }

  Future<String?> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      return null;
    } on FirebaseAuthException catch (e) {
      return _authErrorMessage(e);
    } catch (e) {
      debugPrint('Password reset error: $e');
      return 'Could not send the reset email. Please try again.';
    }
  }

  String _authErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'An account with this email already exists.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Invalid email or password.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Try again later.';
      case 'network-request-failed':
        return 'Network error. Check your internet connection.';
      default:
        return e.message ?? 'Authentication failed. Please try again.';
    }
  }

  // ───────────────── Academic data ─────────────────

  final List<Subject> subjects = const [
    Subject(
      code: 'CS301',
      name: 'Data Structures',
      faculty: 'Dr. Anita Rao',
      room: 'Room 204',
      attended: 38,
      total: 46,
    ),
    Subject(
      code: 'CS302',
      name: 'Database Systems',
      faculty: 'Prof. Suresh Kumar',
      room: 'Room 205',
      attended: 34,
      total: 44,
    ),
    Subject(
      code: 'CS303',
      name: 'Operating Systems',
      faculty: 'Dr. Meera Nair',
      room: 'Room 301',
      attended: 29,
      total: 42,
    ),
    Subject(
      code: 'CS304',
      name: 'Computer Networks',
      faculty: 'Prof. Rahul Verma',
      room: 'Room 302',
      attended: 36,
      total: 45,
    ),
    Subject(
      code: 'CS305',
      name: 'Software Engineering',
      faculty: 'Dr. Kavya Shetty',
      room: 'Room 210',
      attended: 33,
      total: 40,
    ),
    Subject(
      code: 'CS306',
      name: 'DBMS Lab',
      faculty: 'Prof. Suresh Kumar',
      room: 'Lab 2',
      attended: 14,
      total: 16,
    ),
  ];

  final List<Period> periods = const [
    Period(0, TimeOfDay(hour: 9, minute: 0), TimeOfDay(hour: 10, minute: 0)),
    Period(1, TimeOfDay(hour: 10, minute: 0), TimeOfDay(hour: 11, minute: 0)),
    Period(2, TimeOfDay(hour: 11, minute: 15), TimeOfDay(hour: 12, minute: 15)),
    Period(3, TimeOfDay(hour: 12, minute: 15), TimeOfDay(hour: 13, minute: 15)),
    Period(4, TimeOfDay(hour: 14, minute: 0), TimeOfDay(hour: 15, minute: 0)),
    Period(5, TimeOfDay(hour: 15, minute: 0), TimeOfDay(hour: 16, minute: 0)),
  ];

  final Map<int, Map<int, String>> timetable = {
    1: {0: 'CS301', 1: 'CS302', 2: 'CS303', 4: 'CS304'},
    2: {0: 'CS304', 1: 'CS305', 2: 'CS301', 3: 'CS302', 4: 'CS306', 5: 'CS306'},
    3: {1: 'CS303', 2: 'CS305', 3: 'CS304', 4: 'CS301'},
    4: {0: 'CS302', 1: 'CS303', 3: 'CS301', 4: 'CS305'},
    5: {0: 'CS305', 1: 'CS304', 2: 'CS302', 3: 'CS303', 4: 'CS301'},
    6: {0: 'CS302', 1: 'CS301'},
  };

  static const _palette = [
    Color(0xFF4F46E5),
    Color(0xFF0891B2),
    Color(0xFFDB2777),
    Color(0xFFEA580C),
    Color(0xFF16A34A),
    Color(0xFF7C3AED),
  ];

  Subject subjectByCode(String code) =>
      subjects.firstWhere((s) => s.code == code);

  Color subjectColor(String code) {
    final i = subjects.indexWhere((s) => s.code == code);
    return _palette[(i < 0 ? 0 : i) % _palette.length];
  }

  // ───────────────── Calendar / events ─────────────────

  final List<CalendarEvent> events = [];

  int _idCounter = 100;
  String _nextId() => '${_idCounter++}';

  // ───────────────── Notifications ─────────────────

  final List<AppNotification> notifications = [];

  final Map<NotifCategory, bool> prefs = {
    for (final c in NotifCategory.values) c: true
  };

  bool smartReminders = true;

  // ───────────────── Profile / integrations ─────────────────

  double attendanceTarget = 75;

  bool erpConnected = true;
  bool erpSyncing = false;
  DateTime? lastErpSync;

  bool outlookConnected = false;
  bool outlookSyncing = false;

  // ───────────────── Timetable queries ─────────────────

  List<ClassSession> classesOn(DateTime d) {
    final day = timetable[d.weekday];
    if (day == null) return [];

    final out = <ClassSession>[];

    for (final p in periods) {
      final code = day[p.index];
      if (code != null) {
        out.add(ClassSession(subjectByCode(code), p));
      }
    }

    return out;
  }

  List<Period> freePeriodsOn(DateTime d) {
    final classes = classesOn(d);
    if (classes.isEmpty) return [];

    final busy = classes.map((c) => c.period.index).toSet();

    return periods.where((p) => !busy.contains(p.index)).toList();
  }

  ClassSession? currentClass(DateTime now) {
    for (final c in classesOn(now)) {
      final s = atTime(now, c.period.start);
      final e = atTime(now, c.period.end);

      if (!now.isBefore(s) && now.isBefore(e)) return c;
    }

    return null;
  }

  NextClass? nextClass(DateTime now) {
    for (var i = 0; i < 8; i++) {
      final d = DateTime(now.year, now.month, now.day + i);

      for (final c in classesOn(d)) {
        final s = atTime(d, c.period.start);
        if (s.isAfter(now)) return NextClass(c, s);
      }
    }

    return null;
  }

  // ───────────────── Attendance ─────────────────

  int get totalAttended => subjects.fold(0, (a, s) => a + s.attended);

  int get totalClasses => subjects.fold(0, (a, s) => a + s.total);

  double get overallPercent =>
      totalClasses == 0 ? 100 : totalAttended * 100 / totalClasses;

  void setAttendanceTarget(double v) {
    attendanceTarget = v;
    notifyListeners();
  }

  // ───────────────── Events ─────────────────

  static int _cmpEvent(CalendarEvent a, CalendarEvent b) {
    final c = a.date.compareTo(b.date);
    if (c != 0) return c;

    final am = a.start == null ? -1 : minutesOf(a.start!);
    final bm = b.start == null ? -1 : minutesOf(b.start!);

    return am.compareTo(bm);
  }

  List<CalendarEvent> eventsOn(DateTime d) =>
      events.where((e) => sameDay(e.date, d)).toList()..sort(_cmpEvent);

  List<CalendarEvent> eventsBetween(DateTime from, DateTime to) => events
      .where((e) => !e.date.isBefore(from) && !e.date.isAfter(to))
      .toList()
    ..sort(_cmpEvent);

  List<CalendarEvent> upcomingEvents({int limit = 4}) {
    final today = dateOnly(DateTime.now());

    final list = events.where((e) => !e.date.isBefore(today)).toList()
      ..sort(_cmpEvent);

    return list.take(limit).toList();
  }

  void addEvent({
    required String title,
    required DateTime date,
    required EventType type,
    TimeOfDay? start,
    TimeOfDay? end,
    String note = '',
  }) {
    events.add(CalendarEvent(
      id: _nextId(),
      title: title,
      date: dateOnly(date),
      type: type,
      start: start,
      end: end,
      note: note,
      source: 'user',
    ));

    notifications.insert(
      0,
      AppNotification(
        id: _nextId(),
        title: 'Reminder set',
        body: '"$title" on ${fmtShortDate(date)}',
        category: NotifCategory.personal,
        time: DateTime.now(),
      ),
    );

    notifyListeners();
  }

  void deleteEvent(String id) {
    events.removeWhere((e) => e.id == id);
    notifyListeners();
  }

  // ───────────────── Notifications ─────────────────

  List<AppNotification> get visibleNotifications {
    final list = notifications.where((n) => prefs[n.category] == true).toList()
      ..sort((a, b) => b.time.compareTo(a.time));

    return list;
  }

  List<AppNotification> announcements({int limit = 3}) => visibleNotifications
      .where((n) => n.category == NotifCategory.important)
      .take(limit)
      .toList();

  int get unreadCount => visibleNotifications.where((n) => !n.read).length;

  void markRead(String id) {
    for (final n in notifications) {
      if (n.id == id) n.read = true;
    }

    notifyListeners();
  }

  void markAllRead() {
    for (final n in notifications) {
      n.read = true;
    }

    notifyListeners();
  }

  void setPref(NotifCategory c, bool v) {
    prefs[c] = v;
    notifyListeners();
  }

  void setSmartReminders(bool v) {
    smartReminders = v;
    notifyListeners();
  }

  // ───────────────── Integrations (simulated) ─────────────────

  Future<void> syncErp() async {
    erpSyncing = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 1400));

    erpConnected = true;
    erpSyncing = false;
    lastErpSync = DateTime.now();

    notifyListeners();
  }

  void disconnectErp() {
    erpConnected = false;
    notifyListeners();
  }

  int get detectedEmailEvents =>
      events.where((e) => e.source == 'email').length;

  Future<void> setOutlook(bool connect) async {
    if (connect) {
      outlookSyncing = true;
      notifyListeners();

      await Future.delayed(const Duration(milliseconds: 1500));

      outlookConnected = true;
      outlookSyncing = false;

      if (detectedEmailEvents == 0) {
        final today = dateOnly(DateTime.now());

        DateTime inDays(int n) =>
            DateTime(today.year, today.month, today.day + n);

        events.addAll([
          CalendarEvent(
            id: _nextId(),
            title: 'Placement Talk – Infosys',
            date: inDays(7),
            start: const TimeOfDay(hour: 11, minute: 0),
            end: const TimeOfDay(hour: 12, minute: 30),
            type: EventType.event,
            source: 'email',
            note: 'Seminar Hall',
          ),
          CalendarEvent(
            id: _nextId(),
            title: 'Flutter Workshop',
            date: inDays(9),
            start: const TimeOfDay(hour: 14, minute: 0),
            end: const TimeOfDay(hour: 16, minute: 0),
            type: EventType.event,
            source: 'email',
            note: 'Lab 3',
          ),
        ]);

        notifications.insert(
          0,
          AppNotification(
            id: _nextId(),
            title: '2 events found in your Outlook inbox',
            body:
                'Placement Talk and Flutter Workshop were added to your calendar.',
            category: NotifCategory.events,
            time: DateTime.now(),
          ),
        );
      }
    } else {
      outlookConnected = false;
      events.removeWhere((e) => e.source == 'email');
    }

    notifyListeners();
  }

  // ───────────────── Mock data seed ─────────────────

  void _seed() {
    // Demo account is created locally, not in Firebase.
    lastErpSync = DateTime.now().subtract(const Duration(minutes: 25));

    final today = dateOnly(DateTime.now());

    DateTime inDays(int n) => DateTime(today.year, today.month, today.day + n);

    TimeOfDay t({required int hour, required int minute}) =>
        TimeOfDay(hour: hour, minute: minute);

    events.addAll([
      CalendarEvent(
        id: '1',
        title: 'OS Assignment 3 – Deadline',
        date: inDays(2),
        start: t(hour: 23, minute: 59),
        type: EventType.assignment,
        source: 'college',
        note: 'Submit on AUERP',
      ),
      CalendarEvent(
        id: '2',
        title: 'Guest Lecture: AI in Industry',
        date: inDays(1),
        start: t(hour: 15, minute: 0),
        end: t(hour: 16, minute: 0),
        type: EventType.academic,
        source: 'college',
        note: 'Auditorium',
      ),
      CalendarEvent(
        id: '3',
        title: 'Tech Fest – Registration closes',
        date: inDays(3),
        type: EventType.event,
        source: 'college',
      ),
      CalendarEvent(
        id: '4',
        title: 'CN Lab Record Submission',
        date: inDays(4),
        start: t(hour: 16, minute: 0),
        type: EventType.assignment,
        source: 'college',
      ),
      CalendarEvent(
        id: '5',
        title: 'CodeStorm Hackathon',
        date: inDays(5),
        start: t(hour: 9, minute: 0),
        end: t(hour: 17, minute: 0),
        type: EventType.event,
        source: 'college',
        note: 'Innovation Lab',
      ),
      CalendarEvent(
        id: '6',
        title: 'IA-1: Data Structures',
        date: inDays(6),
        start: t(hour: 10, minute: 0),
        end: t(hour: 11, minute: 30),
        type: EventType.exam,
        source: 'college',
        note: 'Hall A',
      ),
      CalendarEvent(
        id: '7',
        title: 'IA-1: Database Systems',
        date: inDays(8),
        start: t(hour: 10, minute: 0),
        end: t(hour: 11, minute: 30),
        type: EventType.exam,
        source: 'college',
        note: 'Hall A',
      ),
      CalendarEvent(
        id: '8',
        title: 'Gym session',
        date: today,
        start: t(hour: 18, minute: 0),
        end: t(hour: 19, minute: 0),
        type: EventType.personal,
      ),
      CalendarEvent(
        id: '9',
        title: 'Study group – DSA',
        date: inDays(1),
        start: t(hour: 17, minute: 0),
        end: t(hour: 18, minute: 30),
        type: EventType.personal,
        note: 'Library',
      ),
    ]);

    final now = DateTime.now();

    notifications.addAll([
      AppNotification(
        id: 'n1',
        title: 'Class rescheduled',
        body: 'Computer Networks on Wednesday has moved to Room 305.',
        category: NotifCategory.academic,
        time: now.subtract(const Duration(hours: 2)),
      ),
      AppNotification(
        id: 'n2',
        title: 'New study material',
        body: 'DBMS Unit 4 notes were uploaded by Prof. Suresh Kumar.',
        category: NotifCategory.academic,
        time: now.subtract(const Duration(hours: 20)),
        read: true,
      ),
      AppNotification(
        id: 'n3',
        title: 'CodeStorm Hackathon – registrations open',
        body: 'Teams of 2–4. Last date to register is this week.',
        category: NotifCategory.events,
        time: now.subtract(const Duration(hours: 5)),
      ),
      AppNotification(
        id: 'n4',
        title: 'Tech Fest registration closing soon',
        body: 'Register before the deadline to secure your spot.',
        category: NotifCategory.events,
        time: now.subtract(const Duration(days: 1)),
        read: true,
      ),
      AppNotification(
        id: 'n5',
        title: 'IA-1 timetable released',
        body:
            'Internal Assessment 1 starts next week. Check the calendar for dates.',
        category: NotifCategory.exams,
        time: now.subtract(const Duration(hours: 8)),
      ),
      AppNotification(
        id: 'n6',
        title: 'Hall ticket available',
        body: 'Download your IA-1 hall ticket from AUERP.',
        category: NotifCategory.exams,
        time: now.subtract(const Duration(days: 2)),
        read: true,
      ),
      AppNotification(
        id: 'n7',
        title: 'Fee payment last date',
        body:
            'Semester fee payment closes in 5 days. Pay at the accounts office or online.',
        category: NotifCategory.important,
        time: now.subtract(const Duration(hours: 3)),
      ),
      AppNotification(
        id: 'n8',
        title: 'Library timings changed',
        body: 'The library will stay open until 8 PM during the exam period.',
        category: NotifCategory.important,
        time: now.subtract(const Duration(days: 1, hours: 3)),
        read: true,
      ),
      AppNotification(
        id: 'n9',
        title: 'Gym session at 6:00 PM',
        body: 'Personal reminder you created.',
        category: NotifCategory.personal,
        time: now.subtract(const Duration(minutes: 40)),
      ),
    ]);
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    super.dispose();
  }
}

// ───────────────────────── Global app state ─────────────────────────

final AppState appState = AppState();
