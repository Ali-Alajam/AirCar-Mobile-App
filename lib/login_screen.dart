// lib/login_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'app_theme.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtl = TextEditingController();
  final _passCtl = TextEditingController();
  bool _loading = false;
  bool _obscure = true;

  @override
  void dispose() {
    _emailCtl.dispose();
    _passCtl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_emailCtl.text.trim().isEmpty || _passCtl.text.isEmpty) {
      _snack('Please enter email and password', AppTheme.error);
      return;
    }
    setState(() => _loading = true);
    try {
      final cred =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailCtl.text.trim(),
        password: _passCtl.text.trim(),
      );
      if (!cred.user!.emailVerified) {
        _snack(
            'Please verify your email before logging in',
            AppTheme.warning);
        await FirebaseAuth.instance.signOut();
      }
    } on FirebaseAuthException catch (e) {
      String msg = 'Login failed';
      if (e.code == 'user-not-found') {
        msg = 'No account found with this email';
      } else if (e.code == 'wrong-password' ||
          e.code == 'invalid-credential') {
        msg = 'Incorrect email or password';
      } else if (e.code == 'too-many-requests') {
        msg = 'Too many attempts. Try again later';
      }
      _snack(msg, AppTheme.error);
    } catch (e) {
      _snack(e.toString(), AppTheme.error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _forgotPass() async {
    final email = _emailCtl.text.trim();
    if (email.isEmpty) {
      _snack('Enter your email first', AppTheme.warning);
      return;
    }
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      _snack('Password reset email sent!', AppTheme.success);
    } catch (e) {
      _snack(e.toString(), AppTheme.error);
    }
  }

  void _snack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 450),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const SizedBox(height: 60),

              // Logo
              Center(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color:
                                AppTheme.primary.withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Icon(
                          Icons.directions_car_rounded,
                          size: 52,
                          color: Colors.white),
                    ),
                    const SizedBox(height: 20),
                    const Text('AirCar',
                        style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primary,
                            letterSpacing: 1.5)),
                    const SizedBox(height: 6),
                    Text('Rent or list your car',
                        style: TextStyle(
                            color: AppTheme.textSub, fontSize: 14)),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // Feature pills
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _FeaturePill(Icons.directions_car, 'Rent Cars'),
                  const SizedBox(width: 10),
                  _FeaturePill(Icons.vpn_key, 'List Cars'),
                  const SizedBox(width: 10),
                  _FeaturePill(Icons.auto_awesome, 'AI Assist'),
                ],
              ),

              const SizedBox(height: 32),

              // Form card
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: AppTheme.cardShadow,
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Sign In',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textMain)),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _emailCtl,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _passCtl,
                      obscureText: _obscure,
                      onSubmitted: (_) => _login(),
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outlined),
                        suffixIcon: IconButton(
                          icon: Icon(_obscure
                              ? Icons.visibility_off
                              : Icons.visibility),
                          onPressed: () =>
                              setState(() => _obscure = !_obscure),
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _forgotPass,
                        child: const Text('Forgot Password?',
                            style: TextStyle(
                                color: AppTheme.primary,
                                fontSize: 13)),
                      ),
                    ),
                    AppButton(
                      label: 'Sign In',
                      icon: Icons.login_rounded,
                      loading: _loading,
                      onPressed: _loading ? null : _login,
                      height: 52,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Don't have an account? ",
                      style: TextStyle(color: AppTheme.textSub)),
                  TextButton(
                    onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const RegisterScreen())),
                    child: const Text('Sign Up',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primary)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeaturePill extends StatelessWidget {
  final IconData icon;
  final String label;
  const _FeaturePill(this.icon, this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppTheme.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border:
            Border.all(color: AppTheme.primary.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppTheme.primary),
          const SizedBox(width: 5),
          Text(label,
              style: const TextStyle(
                  fontSize: 11,
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// Needed by main.dart
class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final bool outline;
  final IconData? icon;
  final Color? color;
  final double height;

  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.loading = false,
    this.outline = false,
    this.icon,
    this.color,
    this.height = 50,
  });

  @override
  Widget build(BuildContext context) {
    final bg = color ?? AppTheme.primary;
    return SizedBox(
      height: height,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ),
        child: loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white))
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 18, color: Colors.white),
                    const SizedBox(width: 8),
                  ],
                  Text(label,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15)),
                ],
              ),
      ),
    );
  }
}
