import 'package:flutter/material.dart';

import '../app_state.dart';
import '../theme.dart';
import '../widgets.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _usn = TextEditingController();
  final _email = TextEditingController();
  final _username = TextEditingController();
  final _pw = TextEditingController();
  final _pw2 = TextEditingController();
  String? _dept;
  String? _sem;
  bool _tried = false;
  bool _hide = true;
  bool _loading = false;

  @override
  void dispose() {
    for (final c in [_name, _usn, _email, _username, _pw, _pw2]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _required(String? v, String msg) =>
      (v == null || v.trim().isEmpty) ? msg : null;

  Future<void> _submit() async {
    setState(() => _tried = true);
    if (!_formKey.currentState!.validate() || _dept == null || _sem == null) return;
    setState(() => _loading = true);
    await Future.delayed(const Duration(milliseconds: 600));
    final err = appState.register(Student(
      name: _name.text.trim(),
      email: _email.text.trim(),
      username: _username.text.trim(),
      password: _pw.text,
      usn: _usn.text.trim().toUpperCase(),
      department: _dept!,
      semester: int.parse(_sem!),
    ));
    if (!mounted) return;
    if (err != null) {
      setState(() => _loading = false);
      showSnack(context, err);
    } else {
      // Signed in -> root swaps to the main app; remove this page.
      Navigator.of(context).popUntil((r) => r.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create account')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(bottom: 16),
                      child: Text('Student details',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.muted)),
                    ),
                    AppTextField(
                      controller: _name,
                      label: 'Full name',
                      icon: Icons.person_outline_rounded,
                      capitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      validator: (v) => _required(v, 'Enter your name'),
                    ),
                    AppTextField(
                      controller: _usn,
                      label: 'USN',
                      icon: Icons.badge_outlined,
                      capitalization: TextCapitalization.characters,
                      textInputAction: TextInputAction.next,
                      validator: (v) => _required(v, 'Enter your USN'),
                    ),
                    PickerField(
                      label: 'Department',
                      icon: Icons.apartment_rounded,
                      value: _dept,
                      options: departments,
                      errorText: _tried && _dept == null ? 'Select your department' : null,
                      onChanged: (v) => setState(() => _dept = v),
                    ),
                    PickerField(
                      label: 'Semester',
                      icon: Icons.layers_outlined,
                      value: _sem == null ? null : 'Semester $_sem',
                      options: [for (var i = 1; i <= 8; i++) 'Semester $i'],
                      errorText: _tried && _sem == null ? 'Select your semester' : null,
                      onChanged: (v) => setState(() => _sem = v.replaceAll('Semester ', '')),
                    ),
                    const Padding(
                      padding: EdgeInsets.only(top: 6, bottom: 16),
                      child: Text('Account',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.muted)),
                    ),
                    AppTextField(
                      controller: _email,
                      label: 'Personal email',
                      icon: Icons.mail_outline_rounded,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      validator: (v) {
                        final s = v?.trim() ?? '';
                        if (s.isEmpty) return 'Enter your email';
                        if (!s.contains('@') || !s.contains('.')) return 'Enter a valid email';
                        return null;
                      },
                    ),
                    AppTextField(
                      controller: _username,
                      label: 'Username',
                      icon: Icons.alternate_email_rounded,
                      textInputAction: TextInputAction.next,
                      validator: (v) {
                        final s = v?.trim() ?? '';
                        if (s.length < 3) return 'At least 3 characters';
                        if (s.contains(' ')) return 'No spaces allowed';
                        return null;
                      },
                    ),
                    AppTextField(
                      controller: _pw,
                      label: 'Password',
                      icon: Icons.lock_outline_rounded,
                      obscure: _hide,
                      textInputAction: TextInputAction.next,
                      suffix: IconButton(
                        icon: Icon(_hide ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                        onPressed: () => setState(() => _hide = !_hide),
                      ),
                      validator: (v) =>
                          (v == null || v.length < 6) ? 'At least 6 characters' : null,
                    ),
                    AppTextField(
                      controller: _pw2,
                      label: 'Confirm password',
                      icon: Icons.lock_reset_rounded,
                      obscure: _hide,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _submit(),
                      validator: (v) => v != _pw.text ? 'Passwords do not match' : null,
                    ),
                    const SizedBox(height: 4),
                    FilledButton(
                      style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                      onPressed: _loading ? null : _submit,
                      child: _loading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                            )
                          : const Text('Sign up', style: TextStyle(fontSize: 16)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
