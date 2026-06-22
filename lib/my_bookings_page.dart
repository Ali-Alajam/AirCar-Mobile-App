// lib/my_bookings_page.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'app_theme.dart';

class MyBookingsPage extends StatelessWidget {
  const MyBookingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return SafeArea(
      child: Column(
        children: [
          // ── Header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
            decoration: const BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('My Bookings',
                    style: TextStyle(
                        color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('All your rental requests in one place',
                    style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13)),
                const SizedBox(height: 16),
                Row(children: [
                  _LegendDot(color: AppTheme.warning, label: 'Pending'),
                  const SizedBox(width: 14),
                  _LegendDot(color: AppTheme.success, label: 'Confirmed'),
                  const SizedBox(width: 14),
                  _LegendDot(color: AppTheme.error, label: 'Rejected'),
                ]),
              ],
            ),
          ),

          // ── Unified list
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('bookings').snapshots(),
              builder: (ctx, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.connectionState == ConnectionState.waiting) {
  return const Center(child: CircularProgressIndicator());
}

if (!snap.hasData) {
  return const _EmptyState();
}

                final docs = snap.data!.docs.where((doc) {
                  final b = doc.data() as Map<String, dynamic>;
                  return b['renterId'] == uid;
                }).toList();

                if (docs.isEmpty) return const _EmptyState();

                // Sort: pending first, then confirmed, then rejected
                const statusOrder = {'pending': 0, 'confirmed': 1, 'rejected': 2};
                docs.sort((a, b) {
                  final sa = (a.data() as Map)['status'] as String? ?? '';
                  final sb = (b.data() as Map)['status'] as String? ?? '';
                  return (statusOrder[sa] ?? 3).compareTo(statusOrder[sb] ?? 3);
                });

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 16, 12, 80),
                  itemCount: docs.length,
                  itemBuilder: (_, i) {
                    final doc = docs[i];
                    final b = doc.data() as Map<String, dynamic>;
                    final status = b['status'] as String? ?? 'pending';
                    return _BookingCard(bookingId: doc.id, data: b, status: status);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 9, height: 9,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 5),
      Text(label,
          style: TextStyle(
              color: Colors.white.withOpacity(0.85),
              fontSize: 12, fontWeight: FontWeight.w500)),
    ]);
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.calendar_month_outlined,
            size: 80, color: AppTheme.textSub.withOpacity(0.2)),
        const SizedBox(height: 16),
        const Text('No bookings yet',
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textMain)),
        const SizedBox(height: 6),
        const Text('Browse cars and send your first booking request',
            style: TextStyle(color: AppTheme.textSub, fontSize: 13),
            textAlign: TextAlign.center),
      ]),
    );
  }
}

// ── Booking Card – color-coded by status ─────────────────────────
class _BookingCard extends StatelessWidget {
  final String bookingId;
  final Map<String, dynamic> data;
  final String status;

  const _BookingCard(
      {required this.bookingId, required this.data, required this.status});

  Color get _accent {
    switch (status) {
      case 'confirmed': return AppTheme.success;
      case 'rejected':  return AppTheme.error;
      default:          return AppTheme.warning;
    }
  }

  Color get _cardBg {
    switch (status) {
      case 'confirmed': return const Color(0xFFF0FDF4);
      case 'rejected':  return const Color(0xFFFFF5F5);
      default:          return const Color(0xFFFFFBEB);
    }
  }

  String get _statusLabel {
    switch (status) {
      case 'confirmed': return 'Confirmed';
      case 'rejected':  return 'Rejected';
      default:          return 'Pending Approval';
    }
  }

  String get _statusEmoji {
    switch (status) {
      case 'confirmed': return '✅';
      case 'rejected':  return '❌';
      default:          return '⏳';
    }
  }

  String get _statusMessage {
    switch (status) {
      case 'confirmed': return 'Booking confirmed — have a wonderful trip! 🎉';
      case 'rejected':  return 'The owner declined this. Try different dates or another car.';
      default:          return 'Waiting for the car owner to review your request.';
    }
  }

  IconData get _messageIcon {
    switch (status) {
      case 'confirmed': return Icons.celebration_rounded;
      case 'rejected':  return Icons.info_outline;
      default:          return Icons.schedule_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final b = data;
    final start   = (b['startDate'] as Timestamp?)?.toDate();
    final end     = (b['endDate']   as Timestamp?)?.toDate();
    final created = (b['createdAt'] as Timestamp?)?.toDate();
    final hasId      = b['idImage']      != null;
    final hasLicense = b['licenseImage'] != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _accent.withOpacity(0.4), width: 1.5),
        boxShadow: [
          BoxShadow(color: _accent.withOpacity(0.10), blurRadius: 14, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(children: [
        // ── Top colored bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: _accent,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(17)),
          ),
          child: Row(children: [
            Text('$_statusEmoji  $_statusLabel',
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
            if (status == 'pending') ...[
              const Spacer(),
              const SizedBox(
                width: 14, height: 14,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              ),
            ],
          ]),
        ),

        // ── Body
        Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

            // Car image + info + price badge
            Row(children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  b['carImage'] ?? '',
                  width: 82, height: 68, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 82, height: 68,
                    decoration: BoxDecoration(
                        color: _accent.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12)),
                    child: Icon(Icons.directions_car_rounded,
                        color: _accent.withOpacity(0.4), size: 28),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(b['carTitle'] ?? '',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.textMain)),
                  const SizedBox(height: 6),
                  Row(children: [
                    Icon(Icons.date_range_outlined, size: 13, color: _accent),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '${start?.toString().split(" ")[0] ?? ""} → ${end?.toString().split(" ")[0] ?? ""}',
                        style: TextStyle(fontSize: 12, color: _accent),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ]),
                  Row(children: [
                    const Icon(Icons.nights_stay_outlined, size: 13, color: AppTheme.textSub),
                    const SizedBox(width: 4),
                    Text(
                      '${b["daysCount"] ?? 1} day${(b["daysCount"] ?? 1) > 1 ? "s" : ""}',
                      style: const TextStyle(fontSize: 12, color: AppTheme.textSub),
                    ),
                  ]),
                ]),
              ),
              // Price badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(color: _accent, borderRadius: BorderRadius.circular(12)),
                child: Column(children: [
                  Text('${b["totalPrice"] ?? 0}',
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                  const Text('SAR',
                      style: TextStyle(color: Colors.white70, fontSize: 10)),
                ]),
              ),
            ]),

            const SizedBox(height: 12),
            Divider(color: _accent.withOpacity(0.2), height: 1),
            const SizedBox(height: 10),

            // Docs + date
            Row(children: [
              _DocBadge(label: 'ID',      ok: hasId),
              const SizedBox(width: 6),
              _DocBadge(label: 'License', ok: hasLicense),
              const Spacer(),
              if (created != null)
                Row(children: [
                  const Icon(Icons.access_time, size: 11, color: AppTheme.textSub),
                  const SizedBox(width: 3),
                  Text(created.toString().split(' ')[0],
                      style: const TextStyle(fontSize: 11, color: AppTheme.textSub)),
                ]),
            ]),

            const SizedBox(height: 10),

            // Status message
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: _accent.withOpacity(0.10),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _accent.withOpacity(0.25)),
              ),
              child: Row(children: [
                Icon(_messageIcon, color: _accent, size: 15),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(_statusMessage,
                      style: TextStyle(
                          color: _accent, fontSize: 12, fontWeight: FontWeight.w500)),
                ),
              ]),
            ),

            // Cancel button – pending only
            if (status == 'pending') ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  style: TextButton.styleFrom(
                      foregroundColor: AppTheme.error,
                      padding: const EdgeInsets.symmetric(horizontal: 10)),
                  icon: const Icon(Icons.cancel_outlined, size: 15),
                  label: const Text('Cancel Request',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  onPressed: () => _cancel(context),
                ),
              ),
            ],
          ]),
        ),
      ]),
    );
  }

  Future<void> _cancel(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Cancel Booking'),
        content: const Text('Are you sure you want to cancel this booking request?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false), child: const Text('No')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes, Cancel', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (ok == true) {
      await FirebaseFirestore.instance.collection('bookings').doc(bookingId).delete();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Booking request cancelled'),
          backgroundColor: AppTheme.warning,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ));
      }
    }
  }
}

class _DocBadge extends StatelessWidget {
  final String label;
  final bool ok;
  const _DocBadge({required this.label, required this.ok});

  @override
  Widget build(BuildContext context) {
    final color = ok ? AppTheme.success : AppTheme.error;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(ok ? Icons.check_circle_outline : Icons.highlight_off,
            size: 11, color: color),
        const SizedBox(width: 4),
        Text(label,
            style: TextStyle(
                fontSize: 10, fontWeight: FontWeight.bold, color: color)),
      ]),
    );
  }
}
