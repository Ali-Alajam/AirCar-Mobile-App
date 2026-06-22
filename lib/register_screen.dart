// lib/register_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'app_theme.dart' hide AppButton;
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _firstCtl = TextEditingController();
  final _lastCtl = TextEditingController();
  final _emailCtl = TextEditingController();
  final _phoneCtl = TextEditingController();
  final _passCtl = TextEditingController();
  final _confirmCtl = TextEditingController();

  bool _loading = false;
  bool _obscurePass = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    for (final c in [
      _firstCtl, _lastCtl, _emailCtl, _phoneCtl, _passCtl, _confirmCtl
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _register() async {
    if ([
      _firstCtl.text.trim(),
      _lastCtl.text.trim(),
      _emailCtl.text.trim(),
      _phoneCtl.text.trim(),
      _passCtl.text.trim()
    ].any((s) => s.isEmpty)) {
      _snack('Please fill in all fields', AppTheme.error);
      return;
    }
    if (_passCtl.text != _confirmCtl.text) {
      _snack('Passwords do not match', AppTheme.error);
      return;
    }
    if (_passCtl.text.length < 6) {
      _snack('Password must be at least 6 characters', AppTheme.error);
      return;
    }

    setState(() => _loading = true);

    try {
      final cred =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailCtl.text.trim(),
        password: _passCtl.text.trim(),
      );

      await FirebaseFirestore.instance
          .collection('users')
          .doc(cred.user!.uid)
          .set({
        'firstName': _firstCtl.text.trim(),
        'lastName': _lastCtl.text.trim(),
        'phone': _phoneCtl.text.trim(),
        'email': _emailCtl.text.trim(),
        'activeMode': 'renter', // default; user can switch freely
        'createdAt': FieldValue.serverTimestamp(),
      });

      await cred.user!.sendEmailVerification();

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.success.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.mark_email_read,
                      color: AppTheme.success, size: 48),
                ),
                const SizedBox(height: 16),
                const Text('Account Created! 🎉',
                    style: TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(
                  'A verification email was sent to ${_emailCtl.text.trim()}.\n\nVerify your email, then sign in.\n\n💡 After login, switch freely between Renter & Owner modes!',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: AppTheme.textSub, fontSize: 13),
                ),
              ],
            ),
            actions: [
              AppButton(
                label: 'Go to Sign In',
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const LoginScreen()));
                },
              ),
            ],
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      String msg = 'Registration failed';
      if (e.code == 'email-already-in-use') {
        msg = 'Email is already registered';
      } else if (e.code == 'weak-password') {
        msg = 'Password is too weak';
      } else if (e.code == 'invalid-email') {
        msg = 'Invalid email address';
      }
      _snack(msg, AppTheme.error);
    } catch (e) {
      _snack(e.toString(), AppTheme.error);
    } finally {
      if (mounted) setState(() => _loading = false);
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
      appBar: AppBar(title: const Text('Create Account')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 450),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const SizedBox(height: 10),

              const Center(
                child: Column(
                  children: [
                    Icon(Icons.person_add_alt_1_rounded,
                        size: 52, color: AppTheme.primary),
                    SizedBox(height: 10),
                    Text('Join AirCar',
                        style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textMain)),
                    SizedBox(height: 4),
                    Text(
                      'One account • Two modes • Endless possibilities',
                      style: TextStyle(
                          color: AppTheme.textSub, fontSize: 13),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Dual mode info
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [
                    AppTheme.primary.withOpacity(0.05),
                    AppTheme.primaryLight.withOpacity(0.03),
                  ]),
                  borderRadius: BorderRadius.circular(14),
                  border:
                      Border.all(color: AppTheme.primary.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _ModePreview(
                        icon: Icons.directions_car_rounded,
                        label: 'Renter',
                        desc: 'Browse & rent cars',
                        color: AppTheme.primary,
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 60,
                      margin: const EdgeInsets.symmetric(horizontal: 12),
                      color: AppTheme.divider,
                    ),
                    Expanded(
                      child: _ModePreview(
                        icon: Icons.vpn_key_rounded,
                        label: 'Owner',
                        desc: 'List & earn from cars',
                        color: const Color(0xFF92400E),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Form
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: AppTheme.cardShadow,
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(children: [
                      Expanded(
                        child: TextField(
                          controller: _firstCtl,
                          textCapitalization: TextCapitalization.words,
                          decoration: const InputDecoration(
                            labelText: 'First Name',
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _lastCtl,
                          textCapitalization: TextCapitalization.words,
                          decoration: const InputDecoration(
                            labelText: 'Last Name',
                          ),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _emailCtl,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email Address',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _phoneCtl,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number',
                        prefixIcon: Icon(Icons.phone_outlined),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _passCtl,
                      obscureText: _obscurePass,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outlined),
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePass
                              ? Icons.visibility_off
                              : Icons.visibility),
                          onPressed: () =>
                              setState(() => _obscurePass = !_obscurePass),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _confirmCtl,
                      obscureText: _obscureConfirm,
                      decoration: InputDecoration(
                        labelText: 'Confirm Password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(_obscureConfirm
                              ? Icons.visibility_off
                              : Icons.visibility),
                          onPressed: () => setState(
                              () => _obscureConfirm = !_obscureConfirm),
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    AppButton(
                      label: 'Create Account',
                      icon: Icons.person_add_alt_1_rounded,
                      loading: _loading,
                      onPressed: _loading ? null : _register,
                      height: 52,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Already have an account? ',
                      style: TextStyle(color: AppTheme.textSub)),
                  TextButton(
                    onPressed: () => Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const LoginScreen())),
                    child: const Text('Sign In',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primary)),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModePreview extends StatelessWidget {
  final IconData icon;
  final String label;
  final String desc;
  final Color color;
  const _ModePreview(
      {required this.icon,
      required this.label,
      required this.desc,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 6),
        Text(label,
            style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 13)),
        Text(desc,
            style: const TextStyle(
                color: AppTheme.textSub, fontSize: 11),
            textAlign: TextAlign.center),
      ],
    );
  }
}
