import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'app_state.dart';
import 'screens/login_screen.dart';
import 'screens/main_shell.dart';
import 'theme.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const CampusPulseApp());
}

class CampusPulseApp extends StatelessWidget {
  const CampusPulseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CampusPulse',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: ListenableBuilder(
        listenable: appState,
        builder: (context, _) =>
            appState.loggedIn ? const MainShell() : const LoginScreen(),
      ),
    );
  }
}
