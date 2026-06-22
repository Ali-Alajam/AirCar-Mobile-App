// lib/profile_page.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'app_theme.dart';
import 'edit_profile_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return SafeArea(
      child: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .snapshots(),
        builder: (ctx, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final data =
              snap.data!.data() as Map<String, dynamic>? ?? {};
          final initials =
              ((data['firstName'] ?? 'U') as String)
                  .substring(0, 1)
                  .toUpperCase();

          return ListView(
            padding: EdgeInsets.zero,
            children: [
              // ── Hero header
              Container(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 30),
                decoration: const BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.vertical(
                      bottom: Radius.circular(28)),
                ),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 46,
                      backgroundColor:
                          Colors.white.withOpacity(0.2),
                      child: Text(initials,
                          style: const TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '${data['firstName'] ?? ''} ${data['lastName'] ?? ''}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Text(data['email'] ?? '',
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 13)),
                    const SizedBox(height: 12),
                    // Dual mode badges
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _ModeBadge(
                            icon: Icons.directions_car_rounded,
                            label: 'Renter',
                            color: Colors.white),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          child: Text('&',
                              style: TextStyle(
                                  color: Colors.white60)),
                        ),
                        _ModeBadge(
                            icon: Icons.vpn_key_rounded,
                            label: 'Owner',
                            color: Colors.amberAccent),
                      ],
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Stats
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            icon: Icons.directions_car_rounded,
                            label: 'My Cars',
                            color: AppTheme.primary,
                            stream: FirebaseFirestore.instance
                                .collection('cars')
                                .where('ownerId', isEqualTo: uid)
                                .snapshots(),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _StatCard(
                            icon: Icons.calendar_month,
                            label: 'Bookings',
                            color: AppTheme.success,
                            stream: FirebaseFirestore.instance
                                .collection('bookings')
                                .where('renterId', isEqualTo: uid)
                                .snapshots(),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _StatCard(
                            icon: Icons.inbox_rounded,
                            label: 'Requests',
                            color: AppTheme.warning,
                            stream: FirebaseFirestore.instance
                                .collection('bookings')
                                .where('ownerId', isEqualTo: uid)
                                .snapshots(),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // ── Personal info
                    const Text('Personal Information',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textMain)),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: AppTheme.cardShadow,
                      ),
                      child: Column(
                        children: [
                          _InfoRow(Icons.email_outlined, 'Email',
                              data['email'] ?? ''),
                          const Divider(height: 1, indent: 56),
                          _InfoRow(Icons.phone_outlined, 'Phone',
                              data['phone'] ?? ''),
                          const Divider(height: 1, indent: 56),
                          _PasswordRow(context),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ── Actions
                    AppButton(
                      label: 'Edit Profile',
                      icon: Icons.edit_outlined,
                      onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  const EditProfilePage())),
                    ),
                    const SizedBox(height: 12),
                    AppButton(
                      label: 'Logout',
                      icon: Icons.logout_rounded,
                      outline: true,
                      color: AppTheme.error,
                      onPressed: () async {
                        final ok = await showDialog<bool>(
                          context: context,
                          builder: (_) => AlertDialog(
                            shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(16)),
                            title: const Text('Logout'),
                            content: const Text(
                                'Are you sure you want to logout?'),
                            actions: [
                              TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: const Text('Cancel')),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.error),
                                onPressed: () =>
                                    Navigator.pop(context, true),
                                child: const Text('Logout',
                                    style: TextStyle(
                                        color: Colors.white)),
                              ),
                            ],
                          ),
                        );
                        if (ok == true) {
                          await FirebaseAuth.instance.signOut();
                        }
                      },
                    ),
                    const SizedBox(height: 90),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ModeBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _ModeBadge(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(label,
              style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Stream<QuerySnapshot> stream;
  const _StatCard(
      {required this.icon,
      required this.label,
      required this.color,
      required this.stream});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (_, snap) {
        final count = snap.data?.docs.length ?? 0;
        return Container(
          padding:
              const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 6),
              Text('$count',
                  style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 22)),
              Text(label,
                  style: const TextStyle(
                      fontSize: 11, color: AppTheme.textSub),
                  textAlign: TextAlign.center),
            ],
          ),
        );
      },
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: AppTheme.primary),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 11, color: AppTheme.textSub)),
              Text(value,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textMain)),
            ],
          ),
        ],
      ),
    );
  }
}

class _PasswordRow extends StatelessWidget {
  final BuildContext parentCtx;
  const _PasswordRow(this.parentCtx);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.lock_outlined,
                size: 18, color: AppTheme.primary),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Password',
                    style: TextStyle(
                        fontSize: 11, color: AppTheme.textSub)),
                Text('••••••••',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textMain)),
              ],
            ),
          ),
          TextButton(
            onPressed: () async {
              final email =
                  FirebaseAuth.instance.currentUser!.email!;
              await FirebaseAuth.instance
                  .sendPasswordResetEmail(email: email);
              if (parentCtx.mounted) {
                ScaffoldMessenger.of(parentCtx).showSnackBar(
                  const SnackBar(
                    content: Text('Password reset email sent!'),
                    backgroundColor: AppTheme.success,
                  ),
                );
              }
            },
            child: const Text('Change',
                style: TextStyle(color: AppTheme.primary)),
          ),
        ],
      ),
    );
  }
}


class  ProfileButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final bool outline;
  final IconData? icon;
  final Color? color;
  final double height;

  const ProfileButton({
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
    if (outline) {
      return SizedBox(
        height: height,
        width: double.infinity,
        child: OutlinedButton(
          onPressed: loading ? null : onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: bg,
            side: BorderSide(color: bg, width: 1.5),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
          child: loading
              ? SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: bg))
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, size: 17),
                      const SizedBox(width: 8),
                    ],
                    Text(label,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15)),
                  ],
                ),
        ),
      );
    }
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
