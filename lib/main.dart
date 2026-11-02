import 'package:flutter/material.dart';

import 'app_state.dart';
import 'screens/login_screen.dart';
import 'screens/main_shell.dart';
import 'theme.dart';

void main() => runApp(const CampusPulseApp());

class CampusPulseApp extends StatelessWidget {
  const CampusPulseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CampusPulse',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      // Auth gate: login screen until a user is signed in, then the 4-tab shell.
      home: ListenableBuilder(
        listenable: appState,
        builder: (context, _) =>
            appState.loggedIn ? const MainShell() : const LoginScreen(),
      ),
    );
  }
}
