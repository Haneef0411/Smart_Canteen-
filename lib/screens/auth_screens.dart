import 'package:flutter/material.dart';
import '../services/firebase_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../utils/validators.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});
  @override
  Widget build(BuildContext context) => const Scaffold(
    body: SafeArea(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            BrandMark(size: 92),
            SizedBox(height: 24),
            Text(
              'Smart Canteen',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Order ahead. Skip the queue.',
              style: TextStyle(color: AppColors.muted),
            ),
            SizedBox(height: 36),
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
          ],
        ),
      ),
    ),
  );
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _hidden = true, _loading = false;
  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await authService.login(_email.text, _password.text);
    } catch (e) {
      if (mounted) showMessage(context, authService.message(e), error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _forgot() async {
    if (_email.text.trim().isEmpty) {
      showMessage(context, 'Enter your email address first.', error: true);
      return;
    }
    try {
      await authService.resetPassword(_email.text);
      if (mounted) showMessage(context, 'Password reset email sent.');
    } catch (e) {
      if (mounted) showMessage(context, authService.message(e), error: true);
    }
  }

  @override
  Widget build(BuildContext context) => AuthLayout(
    child: Form(
      key: _form,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const BrandMark(),
          const SizedBox(height: 24),
          Text(
            'Welcome back',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          const Text(
            'Sign in to order from your university canteen.',
            style: TextStyle(color: AppColors.muted),
          ),
          const SizedBox(height: 28),
          TextFormField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            decoration: const InputDecoration(
              labelText: 'Email address',
              prefixIcon: Icon(Icons.mail_outline),
            ),
            validator: Validators.email,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _password,
            obscureText: _hidden,
            autofillHints: const [AutofillHints.password],
            onFieldSubmitted: (_) => _submit(),
            decoration: InputDecoration(
              labelText: 'Password',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                tooltip: _hidden ? 'Show password' : 'Hide password',
                onPressed: () => setState(() => _hidden = !_hidden),
                icon: Icon(
                  _hidden
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
              ),
            ),
            validator: Validators.requiredPassword,
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _loading ? null : _forgot,
              child: const Text('Forgot password?'),
            ),
          ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: _loading ? null : _submit,
            child: _loading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Sign in'),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('New to Smart Canteen?'),
              TextButton(
                onPressed: _loading
                    ? null
                    : () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const RegisterScreen(),
                        ),
                      ),
                child: const Text('Create account'),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController(),
      _id = TextEditingController(),
      _email = TextEditingController(),
      _password = TextEditingController(),
      _confirm = TextEditingController();
  bool _hidden = true, _loading = false;
  @override
  void dispose() {
    for (final c in [_name, _id, _email, _password, _confirm]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final profileSaved = await authService.register(
        name: _name.text,
        registrationNumber: _id.text,
        email: _email.text,
        password: _password.text,
      );
      if (mounted) {
        Navigator.pop(context);
        if (!profileSaved) {
          showMessage(
            context,
            'Account created. Profile sync needs Cloud Firestore to be enabled.',
            error: true,
          );
        }
      }
    } catch (e) {
      if (mounted) showMessage(context, authService.message(e), error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => AuthLayout(
    showBack: true,
    child: Form(
      key: _form,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Create your account',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          const Text(
            'Use your university details to get started.',
            style: TextStyle(color: AppColors.muted),
          ),
          const SizedBox(height: 24),
          _field(_name, 'Full name', Icons.person_outline, Validators.name),
          const SizedBox(height: 14),
          _field(
            _id,
            'Registration number',
            Icons.badge_outlined,
            Validators.registrationNumber,
          ),
          const SizedBox(height: 14),
          _field(
            _email,
            'Email address',
            Icons.mail_outline,
            Validators.email,
            type: TextInputType.emailAddress,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _password,
            obscureText: _hidden,
            decoration: InputDecoration(
              labelText: 'Password',
              helperText: 'At least 8 characters',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                onPressed: () => setState(() => _hidden = !_hidden),
                icon: Icon(
                  _hidden
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
              ),
            ),
            validator: Validators.password,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _confirm,
            obscureText: _hidden,
            onFieldSubmitted: (_) => _submit(),
            decoration: const InputDecoration(
              labelText: 'Confirm password',
              prefixIcon: Icon(Icons.lock_reset_outlined),
            ),
            validator: (v) => Validators.confirmation(v, _password.text),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _loading ? null : _submit,
            child: _loading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Create account'),
          ),
        ],
      ),
    ),
  );
  Widget _field(
    TextEditingController c,
    String label,
    IconData icon,
    String? Function(String?) validate, {
    TextInputType? type,
  }) => TextFormField(
    controller: c,
    keyboardType: type,
    decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
    validator: validate,
  );
}

class AuthLayout extends StatelessWidget {
  const AuthLayout({super.key, required this.child, this.showBack = false});
  final Widget child;
  final bool showBack;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: showBack ? AppBar() : null,
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: child,
          ),
        ),
      ),
    ),
  );
}
