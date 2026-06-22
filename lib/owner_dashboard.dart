// lib/owner_dashboard.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'app_theme.dart';
import 'main.dart' show AddCarSheet;
import 'my_cars_page.dart';

/* ══════════════════════════════════════════════════
   OWNER DASHBOARD PAGE
══════════════════════════════════════════════════ */
class OwnerDashboardPage extends StatelessWidget {
  const OwnerDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Amber gradient header
            Container(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF92400E), Color(0xFFB45309)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(28)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .doc(uid)
                        .snapshots(),
                    builder: (ctx, snap) {
                      final name = snap.data?.data() != null
                          ? ((snap.data!.data()
                              as Map)['firstName'] ?? '')
                          : '';
                      return Text(
                        'Welcome back, $name 👋',
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.85),
                            fontSize: 14),
                      );
                    },
                  ),
                  const SizedBox(height: 4),
                  const Text('Owner Dashboard',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),

                  // ── Stats grid
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('cars')
                        .where('ownerId', isEqualTo: uid)
                        .snapshots(),
                    builder: (_, carsSnap) {
                      return StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('bookings')
                            .where('ownerId', isEqualTo: uid)
                            .snapshots(),
                        builder: (_, bSnap) {
                          final carsCount =
                              carsSnap.data?.docs.length ?? 0;
                          final allB = bSnap.data?.docs ?? [];
                          final pending = allB
                              .where((b) =>
                                  (b.data()
                                          as Map)['status'] ==
                                  'pending')
                              .length;
                          final confirmed = allB
                              .where((b) =>
                                  (b.data()
                                          as Map)['status'] ==
                                  'confirmed')
                              .length;
                          final earnings = allB
                              .where((b) =>
                                  (b.data()
                                          as Map)['status'] ==
                                  'confirmed')
                              .fold<int>(
                                  0,
                                  (s, b) =>
                                      s +
                                      (((b.data()
                                                  as Map)['totalPrice']
                                              as num?) ??
                                          0)
                                          .toInt());

                          return Row(
                            children: [
                              _StatCard(
                                  value: '$carsCount',
                                  label: 'My Cars',
                                  icon: Icons.directions_car_rounded,
                                  color: Colors.white),
                              const SizedBox(width: 10),
                              _StatCard(
                                  value: '$pending',
                                  label: 'Pending',
                                  icon: Icons.hourglass_top,
                                  color: Colors.amber.shade200),
                              const SizedBox(width: 10),
                              _StatCard(
                                  value: '$confirmed',
                                  label: 'Confirmed',
                                  icon: Icons.check_circle_outline,
                                  color: Colors.greenAccent.shade200),
                              const SizedBox(width: 10),
                              _EarningsCard(amount: earnings),
                            ],
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── My Cars
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('My Listed Cars',
                          style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textMain)),
                      Row(children: [
                        TextButton.icon(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const MyCarsPage()),
                          ),
                          icon: const Icon(Icons.list_alt_outlined, size: 15),
                          label: const Text('View All'),
                          style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFF92400E)),
                        ),
                        TextButton.icon(
                          onPressed: () => showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (_) => AddCarSheet(ownerId: uid),
                          ),
                          icon: const Icon(Icons.add_circle_outline, size: 15),
                          label: const Text('Add'),
                          style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFF92400E)),
                        ),
                      ]),
                    ],
                  ),
                  const SizedBox(height: 10),

                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('cars')
                        .where('ownerId', isEqualTo: uid)
                        .orderBy('createdAt', descending: true)
                        .snapshots(),
                    builder: (ctx, snap) {
                     if (snap.connectionState == ConnectionState.waiting) {
  return const Center(child: CircularProgressIndicator());
}

if (!snap.hasData) {
  return const SizedBox();
}
final docs = snap.data!.docs;
if (docs.isEmpty) {
  return _EmptyOwnerCard(
    icon: Icons.add_circle_outline,
    title: 'No cars listed yet',
    subtitle: 'Tap "Add Car" to list your first car',
    color: const Color(0xFF92400E),
  );
}

                      return SizedBox(
                        height: 160,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: snap.data!.docs.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: 10),
                          itemBuilder: (_, i) {
                            final doc = snap.data!.docs[i];
                            final d =
                                doc.data() as Map<String, dynamic>;
                            return _OwnerCarTile(
                                carId: doc.id, data: d);
                          },
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 24),

                  // ── Pending requests preview
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(children: [
                        const Text('Pending Requests',
                            style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textMain)),
                        const SizedBox(width: 8),
                        StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('bookings')
                              .where('ownerId', isEqualTo: uid)
                             
                              .snapshots(),
                          builder: (_, s) {
                            final c = s.data?.docs.length ?? 0;
                            if (c == 0) return const SizedBox.shrink();
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                  color: AppTheme.error,
                                  borderRadius:
                                      BorderRadius.circular(12)),
                              child: Text('$c',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold)),
                            );
                          },
                        ),
                      ]),
                      TextButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  const OwnerRequestsPage()),
                        ),
                        style: TextButton.styleFrom(
                            foregroundColor:
                                const Color(0xFF92400E)),
                        child: const Text('View All'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('bookings')
                        .where('ownerId', isEqualTo: uid)
                      
                        .orderBy('createdAt', descending: true)
                        .snapshots(),
                    builder: (ctx, snap) {
                      if (!snap.hasData ||
                          snap.data!.docs.isEmpty) {
                        return _EmptyOwnerCard(
                          icon: Icons.inbox_outlined,
                          title: 'No pending requests',
                          subtitle:
                              'New booking requests will appear here',
                          color: AppTheme.textSub,
                        );
                      }

                      final docs = snap.data!.docs.take(4).toList();
                      return Column(
                        children: docs.map((doc) {
                          final b = doc.data() as Map<String, dynamic>;
                          return _CompactBookingCard(
                              bookingId: doc.id, data: b);
                        }).toList(),
                      );
                    },
                  ),

                  const SizedBox(height: 90),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* ──── Compact Booking Card (dashboard preview) ──── */
class _CompactBookingCard extends StatefulWidget {
  final String bookingId;
  final Map<String, dynamic> data;
  const _CompactBookingCard({required this.bookingId, required this.data});

  @override
  State<_CompactBookingCard> createState() => _CompactBookingCardState();
}

class _CompactBookingCardState extends State<_CompactBookingCard> {
  bool _loading = false;

  Future<void> _update(String status) async {
    setState(() => _loading = true);
    await FirebaseFirestore.instance
        .collection('bookings')
        .doc(widget.bookingId)
        .update({'status': status});
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final b = widget.data;
    final start = (b['startDate'] as Timestamp?)?.toDate();
    final end = (b['endDate'] as Timestamp?)?.toDate();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.warning.withOpacity(0.3)),
        boxShadow: AppTheme.softShadow,
      ),
      child: Row(children: [
        // Car image
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            b['carImage'] ?? '',
            width: 52, height: 44, fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              width: 52, height: 44,
              color: AppTheme.surface,
              child: const Icon(Icons.directions_car_rounded,
                  color: AppTheme.textSub, size: 22),
            ),
          ),
        ),
        const SizedBox(width: 10),
        // Info
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(b['carTitle'] ?? '',
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13, color: AppTheme.textMain),
                maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            Text(b['renterName'] ?? '',
                style: const TextStyle(fontSize: 11, color: AppTheme.textSub)),
            Row(children: [
              const Icon(Icons.date_range_outlined,
                  size: 11, color: AppTheme.textSub),
              const SizedBox(width: 3),
              Text(
                '${start?.toString().split(" ")[0] ?? ""} → ${end?.toString().split(" ")[0] ?? ""}',
                style: const TextStyle(fontSize: 11, color: AppTheme.textSub),
              ),
            ]),
          ]),
        ),
        const SizedBox(width: 8),
        // Price
        Text('${b['totalPrice'] ?? 0} SAR',
            style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13, color: AppTheme.primary)),
        const SizedBox(width: 8),
        // Quick actions
        if (_loading)
          const SizedBox(
              width: 18, height: 18,
              child: CircularProgressIndicator(strokeWidth: 2))
        else
          Row(children: [
            _QuickBtn(
                icon: Icons.close,
                color: AppTheme.error,
                onTap: () => _update('rejected')),
            const SizedBox(width: 4),
            _QuickBtn(
                icon: Icons.check,
                color: AppTheme.success,
                onTap: () => _update('confirmed')),
          ]),
      ]),
    );
  }
}

class _QuickBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _QuickBtn({required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30, height: 30,
        decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withOpacity(0.3))),
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }
}

/* ──── Stat Card ──── */
class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;
  const _StatCard(
      {required this.value,
      required this.label,
      required this.icon,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(14),
          border:
              Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(value,
                style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 18)),
            Text(label,
                style: TextStyle(
                    color: Colors.white.withOpacity(0.75),
                    fontSize: 10),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _EarningsCard extends StatelessWidget {
  final int amount;
  const _EarningsCard({required this.amount});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(14),
          border:
              Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            const Icon(Icons.account_balance_wallet_outlined,
                color: Colors.amberAccent, size: 22),
            const SizedBox(height: 6),
            Text('$amount',
                style: const TextStyle(
                    color: Colors.amberAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 14),
                overflow: TextOverflow.ellipsis),
            Text('SAR',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.75),
                    fontSize: 10)),
          ],
        ),
      ),
    );
  }
}

/* ──── Owner Car Tile ──── */
class _OwnerCarTile extends StatelessWidget {
  final String carId;
  final Map<String, dynamic> data;
  const _OwnerCarTile({required this.carId, required this.data});

  @override
  Widget build(BuildContext context) {
    final available = data['available'] == true;

    return Container(
      width: 200,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          Expanded(
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16)),
                  child: Image.network(
                    data['imageUrl'] ?? '',
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF92400E), Color(0xFFB45309)],
                        ),
                        borderRadius: BorderRadius.vertical(
                            top: Radius.circular(16)),
                      ),
                      child: const Center(
                        child: Icon(Icons.directions_car_rounded,
                            color: Colors.white54, size: 36),
                      ),
                    ),
                  ),
                ),
                // Toggle availability
                Positioned(
                  top: 6,
                  right: 6,
                  child: GestureDetector(
                    onTap: () => FirebaseFirestore.instance
                        .collection('cars')
                        .doc(carId)
                        .update({'available': !available}),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: available
                            ? AppTheme.success
                            : AppTheme.error,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        available ? '● Live' : '● Hidden',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Info
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(data['title'] ?? '',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: AppTheme.textMain),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 3),
                Text('${data['pricePerDay']} SAR/day',
                    style: const TextStyle(
                        color: Color(0xFF92400E),
                        fontWeight: FontWeight.bold,
                        fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyOwnerCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  const _EmptyOwnerCard(
      {required this.icon,
      required this.title,
      required this.subtitle,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        children: [
          Icon(icon, size: 48, color: color.withOpacity(0.5)),
          const SizedBox(height: 8),
          Text(title,
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textMain)),
          const SizedBox(height: 4),
          Text(subtitle,
              style: const TextStyle(
                  color: AppTheme.textSub, fontSize: 12),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

/* ══════════════════════════════════════════════════
   OWNER REQUESTS PAGE (full tabbed view)
══════════════════════════════════════════════════ */
class OwnerRequestsPage extends StatefulWidget {
  const OwnerRequestsPage({super.key});

  @override
  State<OwnerRequestsPage> createState() => _OwnerRequestsPageState();
}

class _OwnerRequestsPageState extends State<OwnerRequestsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF92400E),
        title: const Text('Booking Requests'),
        bottom: TabBar(
          controller: _tabs,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          indicatorColor: Colors.amberAccent,
          tabs: const [
            Tab(text: '⏳ Pending'),
            Tab(text: '✅ Confirmed'),
            Tab(text: '❌ Rejected'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _OwnerBookingList(uid: uid, status: 'pending'),
          _OwnerBookingList(uid: uid, status: 'confirmed'),
          _OwnerBookingList(uid: uid, status: 'rejected'),
        ],
      ),
    );
  }
}

class _OwnerBookingList extends StatelessWidget {
  final String uid;
  final String status;
  const _OwnerBookingList(
      {required this.uid, required this.status});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('bookings')
          .where('ownerId', isEqualTo: uid)
          
          
          .snapshots(),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
       if (snap.connectionState == ConnectionState.waiting) {
  return const Center(child: CircularProgressIndicator());
}

if (!snap.hasData) {
  final docs = snap.data!.docs.where((doc) {
  final b = doc.data() as Map<String, dynamic>;
  return b['status'] == 'pending';
}).toList();
  return const SizedBox();
}
final docs = snap.data!.docs.where((doc) {
  final b = doc.data() as Map<String, dynamic>;
  return b['status'] == status;
}).toList();
if (docs.isEmpty) {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          status == 'confirmed'
              ? Icons.check_circle_outline
              : status == 'rejected'
                  ? Icons.cancel_outlined
                  : Icons.inbox_outlined,
          size: 72,
          color: AppTheme.textSub.withOpacity(0.3),
        ),
        const SizedBox(height: 12),
        Text('No $status requests',
            style: const TextStyle(
                color: AppTheme.textSub, fontSize: 15)),
      ],
    ),
  );
}


        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: snap.data!.docs.length,
          itemBuilder: (ctx, i) {
            final doc = snap.data!.docs[i];
            final b = doc.data() as Map<String, dynamic>;
            return OwnerBookingCard(
                bookingId: doc.id, data: b, status: status);
          },
        );
      },
    );
  }
}

/* ══════════════════════════════════════════════════
   OWNER BOOKING CARD  (shared between dashboard & requests page)
══════════════════════════════════════════════════ */
class OwnerBookingCard extends StatefulWidget {
  final String bookingId;
  final Map<String, dynamic> data;
  final String status;

  const OwnerBookingCard(
      {super.key,
      required this.bookingId,
      required this.data,
      required this.status});

  @override
  State<OwnerBookingCard> createState() => _OwnerBookingCardState();
}

class _OwnerBookingCardState extends State<OwnerBookingCard> {
  bool _loading = false;

  Future<void> _update(String newStatus) async {
    setState(() => _loading = true);
    await FirebaseFirestore.instance
        .collection('bookings')
        .doc(widget.bookingId)
        .update({'status': newStatus});
    if (mounted) setState(() => _loading = false);
  }

  Color _color(String s) {
    if (s == 'confirmed') return AppTheme.success;
    if (s == 'rejected') return AppTheme.error;
    return AppTheme.warning;
  }

  @override
  Widget build(BuildContext context) {
    final b = widget.data;
    final status = widget.status;
    final start = (b['startDate'] as Timestamp?)?.toDate();
    final end = (b['endDate'] as Timestamp?)?.toDate();
    final created = (b['createdAt'] as Timestamp?)?.toDate();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: _color(status).withOpacity(0.2), width: 1.5),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        children: [
          // Status strip
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: _color(status).withOpacity(0.08),
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                        color: _color(status),
                        shape: BoxShape.circle)),
                const SizedBox(width: 8),
                Text(
                  status == 'confirmed'
                      ? 'Booking Confirmed'
                      : status == 'rejected'
                          ? 'Booking Rejected'
                          : 'Awaiting Your Response',
                  style: TextStyle(
                      color: _color(status),
                      fontWeight: FontWeight.bold,
                      fontSize: 12),
                ),
                const Spacer(),
                if (created != null)
                  Text(
                    created.toString().split(' ')[0],
                    style: const TextStyle(
                        fontSize: 11, color: AppTheme.textSub),
                  ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Car + renter
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        b['carImage'] ?? '',
                        width: 66,
                        height: 56,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 66,
                          height: 56,
                          decoration: const BoxDecoration(
                              gradient: AppTheme.primaryGradient),
                          child: const Icon(Icons.directions_car,
                              color: Colors.white54),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(b['carTitle'] ?? '',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textMain)),
                          const SizedBox(height: 3),
                          Row(children: [
                            const Icon(Icons.person_outline,
                                size: 13, color: AppTheme.textSub),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(b['renterName'] ?? '',
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.textSub),
                                  overflow: TextOverflow.ellipsis),
                            ),
                          ]),
                          Row(children: [
                            const Icon(Icons.phone_outlined,
                                size: 13, color: AppTheme.textSub),
                            const SizedBox(width: 4),
                            Text(b['renterPhone'] ?? '',
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.textSub)),
                          ]),
                        ],
                      ),
                    ),
                    Text('${b['totalPrice'] ?? 0} SAR',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: AppTheme.primary)),
                  ],
                ),

                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(children: [
                        const Icon(Icons.date_range_outlined,
                            size: 14, color: AppTheme.textSub),
                        const SizedBox(width: 6),
                        Text(
                          '${start?.toString().split(' ')[0] ?? ''} → ${end?.toString().split(' ')[0] ?? ''}',
                          style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.textMain,
                              fontWeight: FontWeight.w500),
                        ),
                      ]),
                      Text('${b['daysCount'] ?? 1} days',
                          style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSub)),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                // Documents badges
                Row(children: [
                  const Text('Documents: ',
                      style: TextStyle(
                          fontSize: 12, color: AppTheme.textSub)),
                  _DocBadge('ID', b['idImage'] != null),
                  const SizedBox(width: 6),
                  _DocBadge('License', b['licenseImage'] != null),
                  const Spacer(),
                  if (b['idImage'] != null || b['licenseImage'] != null)
                    TextButton(
                      style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8),
                          minimumSize: Size.zero),
                      onPressed: () =>
                          _showDocs(context, b),
                      child: const Text('View Docs',
                          style: TextStyle(
                              fontSize: 11,
                              color: AppTheme.primary)),
                    ),
                ]),

                // Accept / Reject buttons
                if (status == 'pending') ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _loading
                              ? null
                              : () => _update('rejected'),
                          icon: const Icon(Icons.close, size: 15),
                          label: const Text('Reject'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.error,
                            side: const BorderSide(
                                color: AppTheme.error),
                            shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _loading
                              ? null
                              : () => _update('confirmed'),
                          icon: _loading
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white))
                              : const Icon(Icons.check, size: 15),
                          label: const Text('Accept'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.success,
                            shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showDocs(BuildContext context, Map<String, dynamic> b) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: const Row(children: [
          Icon(Icons.folder_outlined, color: AppTheme.primary),
          SizedBox(width: 8),
          Text('Renter Documents'),
        ]),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (b['idImage'] != null) ...[
                const Text('🪪 National ID',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.divider),
                  ),
                  child: SelectableText(b['idImage'].toString(),
                      style: const TextStyle(fontSize: 12)),
                ),
                const SizedBox(height: 14),
              ],
              if (b['licenseImage'] != null) ...[
                const Text('🚗 Driving License',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.divider),
                  ),
                  child: SelectableText(
                      b['licenseImage'].toString(),
                      style: const TextStyle(fontSize: 12)),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close')),
        ],
      ),
    );
  }
}

class _DocBadge extends StatelessWidget {
  final String label;
  final bool ok;
  const _DocBadge(this.label, this.ok);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: ok
            ? AppTheme.success.withOpacity(0.1)
            : AppTheme.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
            color: ok
                ? AppTheme.success.withOpacity(0.3)
                : AppTheme.error.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(ok ? Icons.check : Icons.close,
              size: 10, color: ok ? AppTheme.success : AppTheme.error),
          const SizedBox(width: 3),
          Text(label,
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: ok ? AppTheme.success : AppTheme.error)),
        ],
      ),
    );
  }
}
