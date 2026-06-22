// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'app_theme.dart' hide AppButton;
import 'login_screen.dart';
import 'profile_page.dart';
import 'my_bookings_page.dart';
import 'owner_dashboard.dart';
import 'ai_assistant_page.dart';
import 'my_cars_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform);
  runApp(const AircarApp());
}

/* ══════════════════════════════════════════════════
   APP
══════════════════════════════════════════════════ */
class AircarApp extends StatelessWidget {
  const AircarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AirCar',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: StreamBuilder(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const _SplashScreen();
          }
          return snap.hasData ? const RootPage() : const LoginScreen();
        },
      ),
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.directions_car_rounded,
                  size: 64, color: Colors.white),
            ),
            const SizedBox(height: 20),
            const Text('AirCar',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2)),
            const SizedBox(height: 8),
            Text('Your trusted car rental platform',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14)),
            const SizedBox(height: 40),
            const CircularProgressIndicator(
                color: Colors.white, strokeWidth: 2),
          ],
        ),
      ),
    );
  }
}

/* ══════════════════════════════════════════════════
   ROOT PAGE  (dual-mode controller)
══════════════════════════════════════════════════ */
class RootPage extends StatefulWidget {
  const RootPage({super.key});

  @override
  State<RootPage> createState() => _RootPageState();
}

class _RootPageState extends State<RootPage> {
  String _activeMode = 'renter'; // 'renter' | 'owner'
  int _tabIndex = 0; // 0=home/dash, 1=bookings/requests, 2=AI, 3=profile
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadMode();
    _syncEmail();
  }

  Future<void> _loadMode() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();
    if (mounted) {
      setState(() {
        _activeMode = doc.data()?['activeMode'] ?? 'renter';
        _loading = false;
      });
    }
  }

  Future<void> _syncEmail() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await user.reload();
    final fresh = FirebaseAuth.instance.currentUser;
    if (fresh != null && fresh.emailVerified) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(fresh.uid)
          .update({'email': fresh.email});
    }
  }

  Future<void> _switchMode(String mode) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    setState(() {
      _activeMode = mode;
      _tabIndex = 0;
    });
    if (uid != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .update({'activeMode': mode});
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const _SplashScreen();

    final uid = FirebaseAuth.instance.currentUser!.uid;
    final isOwner = _activeMode == 'owner';

    // Tab pages
    final pages = isOwner
        ? [
            const OwnerDashboardPage(),
            const OwnerRequestsPage(),
            const AiAssistantPage(),
            const ProfilePage(),
          ]
        : [
            const RenterHomePage(),
            const MyBookingsPage(),
            const AiAssistantPage(),
            const ProfilePage(),
          ];

    return Scaffold(
      drawer: _AppDrawer(
        uid: uid,
        activeMode: _activeMode,
        onSwitchMode: _switchMode,
        onNavTo: (i) => setState(() => _tabIndex = i),
      ),
      appBar: _buildAppBar(isOwner, uid),
      body: IndexedStack(index: _tabIndex, children: pages),
      bottomNavigationBar: _buildBottomNav(isOwner),
    );
  }

  AppBar _buildAppBar(bool isOwner, String uid) {
    return AppBar(
      backgroundColor: isOwner ? const Color(0xFF92400E) : AppTheme.primary,
      leading: Builder(
        builder: (ctx) => IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => Scaffold.of(ctx).openDrawer(),
        ),
      ),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.directions_car_rounded, size: 22),
          const SizedBox(width: 8),
          const Text('AirCar'),
          const SizedBox(width: 10),
          _ModeChip(isOwner: isOwner),
        ],
      ),
      actions: [
        // Pending badge for owner
        if (isOwner)
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('bookings')
                .where('ownerId', isEqualTo: uid)
                
                .snapshots(),
            builder: (ctx, snap) {
              final count = snap.data?.docs.length ?? 0;
              
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined),
                    onPressed: () => setState(() => _tabIndex = 1),
                  ),
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: const BoxDecoration(
                          color: AppTheme.error, shape: BoxShape.circle),
                      child: Center(
                        child: Text('$count',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),

        // Mode toggle button
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: GestureDetector(
            onTap: () => _switchMode(isOwner ? 'renter' : 'owner'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white24),
              ),
              child: Row(
                children: [
                  Icon(
                    isOwner ? Icons.directions_car : Icons.vpn_key,
                    size: 14,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    isOwner ? 'Renter' : 'Owner',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  BottomNavigationBar _buildBottomNav(bool isOwner) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final color =
        isOwner ? const Color(0xFF92400E) : AppTheme.primary;

    return BottomNavigationBar(
      currentIndex: _tabIndex,
      selectedItemColor: color,
      unselectedItemColor: AppTheme.textSub,
      onTap: (i) => setState(() => _tabIndex = i),
      type: BottomNavigationBarType.fixed,
      backgroundColor: Colors.white,
      elevation: 16,
      selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
      items: [
        BottomNavigationBarItem(
          icon: Icon(isOwner ? Icons.dashboard_outlined : Icons.home_outlined),
          activeIcon:
              Icon(isOwner ? Icons.dashboard : Icons.home_rounded),
          label: isOwner ? 'Dashboard' : 'Home',
        ),
        BottomNavigationBarItem(
          icon: StreamBuilder<QuerySnapshot>(
            stream: isOwner
                ? FirebaseFirestore.instance
                    .collection('bookings')
                    .where('ownerId', isEqualTo: uid)
                    
                    .snapshots()
                : FirebaseFirestore.instance
                    .collection('bookings')
                    .where('renterId', isEqualTo: uid)
                    .where('status', isEqualTo: 'pending')
                    .snapshots(),
            builder: (ctx, snap) {
              final count = snap.data?.docs.length ?? 0;
              if (count == 0) {
                return Icon(isOwner
                    ? Icons.inbox_outlined
                    : Icons.calendar_month_outlined);
              }
              return Badge(
                label: Text('$count'),
                backgroundColor: AppTheme.error,
                child: Icon(isOwner
                    ? Icons.inbox_outlined
                    : Icons.calendar_month_outlined),
              );
            },
          ),
          activeIcon: Icon(isOwner ? Icons.inbox : Icons.calendar_month),
          label: isOwner ? 'Requests' : 'Bookings',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.auto_awesome_outlined),
          activeIcon: Icon(Icons.auto_awesome),
          label: 'AI Assist',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          activeIcon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
    );
  }
}

/* ──── Mode chip ──── */
class _ModeChip extends StatelessWidget {
  final bool isOwner;
  const _ModeChip({required this.isOwner});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isOwner
            ? AppTheme.gold.withOpacity(0.25)
            : Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        isOwner ? '⭐ Owner' : '🚗 Renter',
        style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Colors.white),
      ),
    );
  }
}

/* ══════════════════════════════════════════════════
   DRAWER
══════════════════════════════════════════════════ */
class _AppDrawer extends StatelessWidget {
  final String uid;
  final String activeMode;
  final void Function(String) onSwitchMode;
  final void Function(int) onNavTo;

  const _AppDrawer({
    required this.uid,
    required this.activeMode,
    required this.onSwitchMode,
    required this.onNavTo,
  });

  @override
  Widget build(BuildContext context) {
    final isOwner = activeMode == 'owner';

    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          // Header
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(uid)
                .snapshots(),
            builder: (ctx, snap) {
              final d =
                  snap.data?.data() as Map<String, dynamic>? ?? {};
              final name =
                  '${d['firstName'] ?? ''} ${d['lastName'] ?? ''}';
              final initials =
                  name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : 'U';

              return Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 50, 16, 20),
                decoration: BoxDecoration(
                  gradient: isOwner
                      ? const LinearGradient(colors: [
                          Color(0xFF92400E),
                          Color(0xFFB45309)
                        ])
                      : AppTheme.primaryGradient,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.white.withOpacity(0.2),
                      child: Text(initials,
                          style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                    ),
                    const SizedBox(height: 12),
                    Text(name.trim(),
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text(d['email'] ?? '',
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.75),
                            fontSize: 12)),
                  ],
                ),
              );
            },
          ),

          // Mode toggle
          Padding(
            padding: const EdgeInsets.all(12),
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.divider),
              ),
              child: Row(
                children: [
                  _DrawerModeTab(
                    label: 'Renter',
                    icon: Icons.directions_car_rounded,
                    selected: !isOwner,
                    color: AppTheme.primary,
                    onTap: () {
                      onSwitchMode('renter');
                      Navigator.pop(context);
                    },
                  ),
                  _DrawerModeTab(
                    label: 'Owner',
                    icon: Icons.vpn_key_rounded,
                    selected: isOwner,
                    color: const Color(0xFF92400E),
                    onTap: () {
                      onSwitchMode('owner');
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),
          ),

          const Divider(height: 1),

          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _DrawerItem(
                  icon: isOwner ? Icons.dashboard : Icons.home_rounded,
                  label: isOwner ? 'Dashboard' : 'Browse Cars',
                  onTap: () {
                    onNavTo(0);
                    Navigator.pop(context);
                  },
                ),

                if (!isOwner)
                  _DrawerItem(
                    icon: Icons.calendar_month,
                    label: 'My Bookings',
                    onTap: () {
                      onNavTo(1);
                      Navigator.pop(context);
                    },
                    badge: _PendingBadge(
                      stream: FirebaseFirestore.instance
                          .collection('bookings')
                          .where('renterId', isEqualTo: uid)
                          .where('status', isEqualTo: 'pending')
                          .snapshots(),
                    ),
                  ),

                if (isOwner) ...[
                  _DrawerItem(
                    icon: Icons.inbox_rounded,
                    label: 'Booking Requests',
                    onTap: () {
                      onNavTo(1);
                      Navigator.pop(context);
                    },
                    badge: _PendingBadge(
                      stream: FirebaseFirestore.instance
                          .collection('bookings')
                          .where('ownerId', isEqualTo: uid)
                          
                          .snapshots(),
                      color: AppTheme.error,
                    ),
                  ),
                  _DrawerItem(
                    icon: Icons.directions_car_rounded,
                    label: 'My Cars',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const MyCarsPage()));
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.add_circle_outline,
                    label: 'Add New Car',
                    onTap: () {
                      Navigator.pop(context);
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => AddCarSheet(ownerId: uid),
                      );
                    },
                  ),
                ],

                _DrawerItem(
                  icon: Icons.auto_awesome_outlined,
                  label: 'AI Assistant',
                  onTap: () {
                    onNavTo(2);
                    Navigator.pop(context);
                  },
                ),

                _DrawerItem(
                  icon: Icons.person_outline,
                  label: 'Profile',
                  onTap: () {
                    onNavTo(3);
                    Navigator.pop(context);
                  },
                ),

                const Divider(height: 24),

                _DrawerItem(
                  icon: Icons.logout_rounded,
                  label: 'Logout',
                  color: AppTheme.error,
                  onTap: () async {
                    Navigator.pop(context);
                    await FirebaseAuth.instance.signOut();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DrawerModeTab extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _DrawerModeTab({
    required this.label,
    required this.icon,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? color : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Icon(icon,
                  size: 20, color: selected ? Colors.white : AppTheme.textSub),
              const SizedBox(height: 4),
              Text(label,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: selected ? Colors.white : AppTheme.textSub)),
            ],
          ),
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;
  final Widget? badge;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppTheme.textMain;
    return ListTile(
      leading: Icon(icon, color: c, size: 22),
      title: Text(label,
          style: TextStyle(
              color: c, fontWeight: FontWeight.w500, fontSize: 14)),
      trailing: badge,
      onTap: onTap,
      dense: true,
    );
  }
}

class _PendingBadge extends StatelessWidget {
  final Stream<QuerySnapshot> stream;
  final Color color;

  const _PendingBadge({
    required this.stream,
    this.color = AppTheme.warning,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (ctx, snap) {
        final count = snap.data?.docs.length ?? 0;
        if (count == 0) return const SizedBox.shrink();
        return Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
              color: color, borderRadius: BorderRadius.circular(12)),
          child: Text('$count',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold)),
        );
      },
    );
  }
}

/* ══════════════════════════════════════════════════
   RENTER HOME
══════════════════════════════════════════════════ */
class RenterHomePage extends StatefulWidget {
  const RenterHomePage({super.key});

  @override
  State<RenterHomePage> createState() => _RenterHomePageState();
}

class _RenterHomePageState extends State<RenterHomePage> {
  String _query = '';
  String _city = 'All';
  DateTimeRange? _range;
  String _priceSort = 'none'; // none | asc | desc
  RangeValues _priceRange = const RangeValues(0, 2000);
  final _cities = [
    'All', 'Riyadh', 'Jeddah', 'Dammam', 'Mecca', 'Medina', 'Abha'
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Hero header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
            decoration: const BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius:
                  BorderRadius.vertical(bottom: Radius.circular(24)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _greeting(),
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14),
                ),
                const SizedBox(height: 4),
                const Text('Find your perfect ride',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),

                // Search bar
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: AppTheme.softShadow,
                  ),
                  child: Row(
                    children: [
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Icon(Icons.search, color: AppTheme.textSub),
                      ),
                      Expanded(
                        child: TextField(
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintText: 'Search cars, brands...',
                            filled: false,
                            contentPadding:
                                EdgeInsets.symmetric(vertical: 14),
                          ),
                          onChanged: (v) => setState(() => _query = v),
                        ),
                      ),
                      GestureDetector(
                        onTap: _showFilterSheet,
                        child: Container(
                          margin: const EdgeInsets.all(6),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _hasActiveFilter
                                ? AppTheme.primary
                                : AppTheme.surface,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.tune,
                              size: 18,
                              color: _hasActiveFilter
                                  ? Colors.white
                                  : AppTheme.textSub),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── City chips
          SizedBox(
            height: 48,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              scrollDirection: Axis.horizontal,
              itemCount: _cities.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final c = _cities[i];
                final sel = _city == c;
                return GestureDetector(
                  onTap: () => setState(() => _city = c),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: sel ? AppTheme.primary : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: sel
                              ? AppTheme.primary
                              : AppTheme.divider),
                      boxShadow:
                          sel ? AppTheme.softShadow : [],
                    ),
                    child: Text(c,
                        style: TextStyle(
                            color:
                                sel ? Colors.white : AppTheme.textSub,
                            fontWeight: sel
                                ? FontWeight.bold
                                : FontWeight.normal,
                            fontSize: 12)),
                  ),
                );
              },
            ),
          ),

          // ── Active filters row
          if (_hasActiveFilter)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                children: [
                  if (_range != null)
                    _FilterChip(
                      label:
                          '${_fmt(_range!.start)} → ${_fmt(_range!.end)}',
                      onRemove: () => setState(() => _range = null),
                    ),
                  if (_priceSort != 'none') ...[
                    const SizedBox(width: 6),
                    _FilterChip(
                      label: _priceSort == 'asc'
                          ? 'Price ↑'
                          : 'Price ↓',
                      onRemove: () =>
                          setState(() => _priceSort = 'none'),
                    ),
                  ],
                ],
              ),
            ),

          // ── Cars grid
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('cars')
                  .where('available', isEqualTo: true)
                  .snapshots(),
              builder: (ctx, snap) {
                if (!snap.hasData) {
                  return const Center(
                      child: CircularProgressIndicator());
                }

                var docs = snap.data!.docs.where((doc) {
                  final d = doc.data() as Map<String, dynamic>;
                  final title =
                      (d['title'] ?? '').toString().toLowerCase();
                  final city = d['city'] ?? '';
                  final price =
                      ((d['pricePerDay'] ?? 0) as num).toDouble();
                  final matchQ = _query.isEmpty ||
                      title.contains(_query.toLowerCase());
                  final matchCity =
                      _city == 'All' || city == _city;
                  final matchP =
                      price >= _priceRange.start &&
                          price <= _priceRange.end;
                  return matchQ && matchCity && matchP;
                }).toList();

                if (_priceSort == 'asc') {
                  docs.sort((a, b) => ((a.data()
                              as Map)['pricePerDay'] as num)
                      .compareTo(
                          ((b.data() as Map)['pricePerDay'] as num)));
                } else if (_priceSort == 'desc') {
                  docs.sort((a, b) => ((b.data()
                              as Map)['pricePerDay'] as num)
                      .compareTo(
                          ((a.data() as Map)['pricePerDay'] as num)));
                }

                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off,
                            size: 72,
                            color: AppTheme.textSub
                                .withOpacity(0.3)),
                        const SizedBox(height: 12),
                        const Text('No cars found',
                            style: TextStyle(
                                color: AppTheme.textSub,
                                fontSize: 16)),
                        TextButton(
                          onPressed: _clearFilters,
                          child: const Text('Clear filters'),
                        ),
                      ],
                    ),
                  );
                }

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                          14, 8, 14, 4),
                      child: Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          Text('${docs.length} cars available',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textMain)),
                          // Price sort toggle
                          GestureDetector(
                            onTap: () => setState(() {
                              if (_priceSort == 'none') {
                                _priceSort = 'asc';
                              } else if (_priceSort == 'asc') {
                                _priceSort = 'desc';
                              } else {
                                _priceSort = 'none';
                              }
                            }),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 5),
                              decoration: BoxDecoration(
                                color: _priceSort != 'none'
                                    ? AppTheme.primary
                                    : Colors.white,
                                borderRadius:
                                    BorderRadius.circular(10),
                                border: Border.all(
                                    color: _priceSort != 'none'
                                        ? AppTheme.primary
                                        : AppTheme.divider),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    _priceSort == 'asc'
                                        ? Icons.arrow_upward
                                        : _priceSort == 'desc'
                                            ? Icons.arrow_downward
                                            : Icons.sort,
                                    size: 14,
                                    color: _priceSort != 'none'
                                        ? Colors.white
                                        : AppTheme.textSub,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _priceSort == 'asc'
                                        ? 'Price ↑'
                                        : _priceSort == 'desc'
                                            ? 'Price ↓'
                                            : 'Sort',
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: _priceSort != 'none'
                                            ? Colors.white
                                            : AppTheme.textSub),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: GridView.builder(
                        padding: const EdgeInsets.fromLTRB(
                            12, 4, 12, 90),
                        itemCount: docs.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisExtent: 256,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                        itemBuilder: (ctx, i) {
                          final d =
                              docs[i].data() as Map<String, dynamic>;
                          return CarGridCard(
                              carId: docs[i].id,
                              data: d,
                              selectedRange: _range);
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  bool get _hasActiveFilter =>
      _range != null ||
      _priceSort != 'none' ||
      _priceRange != const RangeValues(0, 2000);

  void _clearFilters() => setState(() {
        _range = null;
        _priceSort = 'none';
        _priceRange = const RangeValues(0, 2000);
      });

  String _fmt(DateTime d) =>
      '${d.day}/${d.month}/${d.year.toString().substring(2)}';

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning 🌅';
    if (h < 17) return 'Good afternoon ☀️';
    return 'Good evening 🌙';
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FilterSheet(
        initialRange: _range,
        initialSort: _priceSort,
        initialPriceRange: _priceRange,
        onApply: (r, s, p) =>
            setState(() {
              _range = r;
              _priceSort = s;
              _priceRange = p;
            }),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final VoidCallback onRemove;
  const _FilterChip({required this.label, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      margin: const EdgeInsets.only(right: 6, bottom: 4),
      decoration: BoxDecoration(
        color: AppTheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
              style: const TextStyle(
                  color: AppTheme.primary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600)),
          const SizedBox(width: 5),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(Icons.close,
                size: 13, color: AppTheme.primary),
          ),
        ],
      ),
    );
  }
}

/* ══════════════════════════════════════════════════
   FILTER SHEET
══════════════════════════════════════════════════ */
class _FilterSheet extends StatefulWidget {
  final DateTimeRange? initialRange;
  final String initialSort;
  final RangeValues initialPriceRange;
  final void Function(DateTimeRange?, String, RangeValues) onApply;

  const _FilterSheet({
    required this.initialRange,
    required this.initialSort,
    required this.initialPriceRange,
    required this.onApply,
  });

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late DateTimeRange? _range;
  late String _sort;
  late RangeValues _price;

  @override
  void initState() {
    super.initState();
    _range = widget.initialRange;
    _sort = widget.initialSort;
    _price = widget.initialPriceRange;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
          20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Filters',
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              TextButton(
                onPressed: () => setState(() {
                  _range = null;
                  _sort = 'none';
                  _price = const RangeValues(0, 2000);
                }),
                child: const Text('Reset'),
              ),
            ],
          ),

          const SizedBox(height: 16),
          const Text('Booking Dates',
              style: TextStyle(
                  fontWeight: FontWeight.bold, color: AppTheme.textMain)),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () async {
              final now = DateTime.now();
              final p = await showDateRangePicker(
                context: context,
                firstDate: DateTime(now.year, now.month, now.day),
                lastDate: DateTime(now.year + 1),
                initialDateRange: _range,
                builder: (ctx, child) => Theme(
                  data: ThemeData(colorSchemeSeed: AppTheme.primary),
                  child: child!,
                ),
              );
              if (p != null) setState(() => _range = p);
            },
            icon: const Icon(Icons.date_range),
            label: Text(_range == null
                ? 'Select dates'
                : '${_range!.start.toString().split(' ')[0]} → ${_range!.end.toString().split(' ')[0]}'),
            style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(46)),
          ),
          if (_range != null)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => setState(() => _range = null),
                child: const Text('Clear',
                    style: TextStyle(color: AppTheme.error)),
              ),
            ),

          const SizedBox(height: 16),
          const Text('Sort by Price',
              style: TextStyle(
                  fontWeight: FontWeight.bold, color: AppTheme.textMain)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _SortBtn(
                  label: 'Low → High',
                  icon: Icons.arrow_upward,
                  selected: _sort == 'asc',
                  onTap: () => setState(() =>
                      _sort = _sort == 'asc' ? 'none' : 'asc'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SortBtn(
                  label: 'High → Low',
                  icon: Icons.arrow_downward,
                  selected: _sort == 'desc',
                  onTap: () => setState(() =>
                      _sort = _sort == 'desc' ? 'none' : 'desc'),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Price Range',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textMain)),
              Text(
                  '${_price.start.round()} – ${_price.end.round()} SAR',
                  style: const TextStyle(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.bold)),
            ],
          ),
          RangeSlider(
            values: _price,
            min: 0,
            max: 2000,
            divisions: 40,
            activeColor: AppTheme.primary,
            labels: RangeLabels(
                '${_price.start.round()} SAR',
                '${_price.end.round()} SAR'),
            onChanged: (v) => setState(() => _price = v),
          ),

          const SizedBox(height: 16),
          AppButton(
            label: 'Apply Filters',
            icon: Icons.check,
            onPressed: () {
              widget.onApply(_range, _sort, _price);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}

class _SortBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  const _SortBtn(
      {required this.label,
      required this.icon,
      required this.selected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primary : AppTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color:
                  selected ? AppTheme.primary : AppTheme.divider),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 15,
                color: selected ? Colors.white : AppTheme.textSub),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: selected
                        ? Colors.white
                        : AppTheme.textSub)),
          ],
        ),
      ),
    );
  }
}

/* ══════════════════════════════════════════════════
   CAR GRID CARD
══════════════════════════════════════════════════ */
class CarGridCard extends StatelessWidget {
  final String carId;
  final Map<String, dynamic> data;
  final DateTimeRange? selectedRange;

  const CarGridCard(
      {super.key,
      required this.carId,
      required this.data,
      this.selectedRange});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CarDetailsScreen(
              carId: carId, data: data, selectedRange: selectedRange),
        ),
      ),
      child: Container(
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
              flex: 3,
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
                        decoration: BoxDecoration(
                          gradient: AppTheme.primaryGradient,
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(16)),
                        ),
                        child: const Center(
                          child: Icon(Icons.directions_car_rounded,
                              size: 40, color: Colors.white54),
                        ),
                      ),
                    ),
                  ),
                  // Price tag
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${data['pricePerDay']} SAR',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 11),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Info
            Expanded(
              flex: 2,
              child: Padding(
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
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined,
                            size: 11,
                            color: AppTheme.textSub),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(data['city'] ?? '',
                              style: const TextStyle(
                                  color: AppTheme.textSub,
                                  fontSize: 11),
                              overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        const Icon(Icons.settings_outlined,
                            size: 10, color: AppTheme.textSub),
                        const SizedBox(width: 3),
                        Text(data['transmission'] ?? 'Auto',
                            style: const TextStyle(
                                fontSize: 10,
                                color: AppTheme.textSub)),
                        const SizedBox(width: 8),
                        const Icon(Icons.event_seat_outlined,
                            size: 10, color: AppTheme.textSub),
                        const SizedBox(width: 3),
                        Text('${data['seats'] ?? 5}',
                            style: const TextStyle(
                                fontSize: 10,
                                color: AppTheme.textSub)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* ══════════════════════════════════════════════════
   CAR DETAILS SCREEN
══════════════════════════════════════════════════ */
class CarDetailsScreen extends StatefulWidget {
  final String carId;
  final Map<String, dynamic> data;
  final DateTimeRange? selectedRange;

  const CarDetailsScreen(
      {super.key,
      required this.carId,
      required this.data,
      this.selectedRange});

  @override
  State<CarDetailsScreen> createState() => _CarDetailsScreenState();
}

class _CarDetailsScreenState extends State<CarDetailsScreen> {
  DateTimeRange? _range;
  bool _submitting = false;
  String? _idImageUrl;
  String? _licenseImageUrl;

  @override
  void initState() {
    super.initState();
    _range = widget.selectedRange;
  }

  int get _days {
    if (_range == null) return 0;
    final d = _range!.duration.inDays;
    return d == 0 ? 1 : d;
  }

  int get _total =>
      _days * ((widget.data['pricePerDay'] ?? 0) as num).toInt();

  Future<void> _pickDocument(bool isId) async {
    final ctrl = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: Row(children: [
          Icon(isId ? Icons.badge_outlined : Icons.credit_card,
              color: AppTheme.primary),
          const SizedBox(width: 8),
          Text(isId ? 'Upload National ID' : 'Upload License'),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: AppTheme.warning.withOpacity(0.3)),
              ),
              child: const Row(children: [
                Icon(Icons.info_outline,
                    color: AppTheme.warning, size: 16),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'In production this opens camera/gallery. Enter image URL to simulate.',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              decoration: InputDecoration(
                labelText: isId ? 'ID Image URL' : 'License Image URL',
                prefixIcon: const Icon(Icons.link),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          AppButton(
            label: 'Confirm',
            height: 40,
            onPressed: () => Navigator.pop(context, ctrl.text.trim()),
          ),
        ],
      ),
    );
    if (result != null && result.isNotEmpty) {
      setState(() {
        if (isId) {
          _idImageUrl = result;
        } else {
          _licenseImageUrl = result;
        }
      });
    }
  }

  Future<void> _submitBooking() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || _range == null) return;

    if (_idImageUrl == null || _licenseImageUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(children: [
            Icon(Icons.warning_amber_rounded, color: Colors.white),
            SizedBox(width: 8),
            Expanded(
                child: Text(
                    'You must upload both ID and License to continue')),
          ]),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    if (uid == widget.data['ownerId']) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('You cannot book your own car'),
        backgroundColor: AppTheme.warning,
      ));
      return;
    }

    setState(() => _submitting = true);

    try {
      // Check date conflicts
      final conflicts = await FirebaseFirestore.instance
          .collection('bookings')
          .where('carId', isEqualTo: widget.carId)
          .where('status', whereIn: ['pending', 'confirmed'])
          .get();

      final sMs = _range!.start.millisecondsSinceEpoch;
      final eMs = _range!.end.millisecondsSinceEpoch;

      for (final doc in conflicts.docs) {
        final bS = (doc.data()['startDate'] as Timestamp)
            .millisecondsSinceEpoch;
        final bE =
            (doc.data()['endDate'] as Timestamp).millisecondsSinceEpoch;
        if (sMs < bE && bS < eMs) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text(
                  'Car is already booked for selected dates'),
              backgroundColor: AppTheme.error,
            ));
          }
          setState(() => _submitting = false);
          return;
        }
      }

      final rDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      final rd = rDoc.data() ?? {};

      await FirebaseFirestore.instance.collection('bookings').add({
        'carId': widget.carId,
        'carTitle': widget.data['title'],
        'carImage': widget.data['imageUrl'],
        'carCity': widget.data['city'],
        'ownerId': widget.data['ownerId'],
        'renterId': uid,
        'renterName':
            '${rd['firstName'] ?? ''} ${rd['lastName'] ?? ''}',
        'renterPhone': rd['phone'] ?? '',
        'renterEmail': rd['email'] ?? '',
        'startDate': Timestamp.fromDate(_range!.start),
        'endDate': Timestamp.fromDate(_range!.end),
        'totalPrice': _total,
        'pricePerDay': widget.data['pricePerDay'],
        'daysCount': _days,
        'status': 'pending',
        'idImage': _idImageUrl,
        'licenseImage': _licenseImageUrl,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        showDialog(
          context: context,
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
                  child: const Icon(Icons.check_circle,
                      color: AppTheme.success, size: 48),
                ),
                const SizedBox(height: 16),
                const Text('Request Sent!',
                    style: TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text(
                  'Your booking request has been sent to the car owner. Track it in "My Bookings".',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.textSub),
                ),
              ],
            ),
            actions: [
              AppButton(
                label: 'Great!',
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppTheme.error,
        ));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.data;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ── App bar with image
          SliverAppBar(
            expandedHeight: 260,
            pinned: true,
            backgroundColor: AppTheme.primary,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(d['title'] ?? '',
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.bold)),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    d['imageUrl'] ?? '',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      decoration:
                          const BoxDecoration(gradient: AppTheme.primaryGradient),
                      child: const Icon(Icons.directions_car_rounded,
                          size: 80, color: Colors.white30),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.6),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Price & location
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(d['title'] ?? '',
                                style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textMain)),
                            const SizedBox(height: 4),
                            Row(children: [
                              const Icon(Icons.location_on_outlined,
                                  size: 14, color: AppTheme.textSub),
                              const SizedBox(width: 3),
                              Text(d['city'] ?? '',
                                  style: const TextStyle(
                                      color: AppTheme.textSub,
                                      fontSize: 13)),
                            ]),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          gradient: AppTheme.primaryGradient,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: AppTheme.softShadow,
                        ),
                        child: Column(
                          children: [
                            Text('${d['pricePerDay']}',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20)),
                            const Text('SAR/day',
                                style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 11)),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // ── Spec chips
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _SpecChip(Icons.calendar_today,
                          '${d['year'] ?? ''}'),
                      _SpecChip(Icons.settings, d['transmission'] ?? 'Auto'),
                      _SpecChip(Icons.local_gas_station,
                          d['fuelType'] ?? 'Petrol'),
                      _SpecChip(Icons.event_seat,
                          '${d['seats'] ?? 5} Seats'),
                    ],
                  ),

                  if ((d['description'] ?? '').toString().isNotEmpty) ...[
                    const SizedBox(height: 20),
                    const Text('About this car',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: AppTheme.textMain)),
                    const SizedBox(height: 8),
                    Text(d['description'] ?? '',
                        style: const TextStyle(
                            color: AppTheme.textSub, height: 1.6)),
                  ],

                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),

                  // ── Date picker
                  const Text('Select Dates',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppTheme.textMain)),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: () async {
                      final now = DateTime.now();
                      final p = await showDateRangePicker(
                        context: context,
                        firstDate:
                            DateTime(now.year, now.month, now.day),
                        lastDate: DateTime(now.year + 1),
                        initialDateRange: _range,
                        builder: (ctx, child) => Theme(
                          data: ThemeData(
                              colorSchemeSeed: AppTheme.primary),
                          child: child!,
                        ),
                      );
                      if (p != null) setState(() => _range = p);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: _range != null
                            ? AppTheme.primary.withOpacity(0.05)
                            : AppTheme.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: _range != null
                                ? AppTheme.primary
                                : AppTheme.divider,
                            width: _range != null ? 1.5 : 1),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.primary
                                  .withOpacity(0.1),
                              borderRadius:
                                  BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.date_range,
                                color: AppTheme.primary, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _range == null
                                  ? 'Tap to select booking dates'
                                  : '${_range!.start.toString().split(' ')[0]} → ${_range!.end.toString().split(' ')[0]}',
                              style: TextStyle(
                                color: _range != null
                                    ? AppTheme.textMain
                                    : AppTheme.textSub,
                                fontWeight: _range != null
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                          const Icon(Icons.chevron_right,
                              color: AppTheme.textSub),
                        ],
                      ),
                    ),
                  ),

                  // ── Price summary
                  if (_range != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.primary.withOpacity(0.06),
                            AppTheme.primaryLight.withOpacity(0.04),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color:
                                AppTheme.primary.withOpacity(0.15)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                    '${d['pricePerDay']} SAR × $_days day${_days > 1 ? 's' : ''}',
                                    style: const TextStyle(
                                        color: AppTheme.textSub,
                                        fontSize: 13)),
                                const Text('Total amount',
                                    style: TextStyle(
                                        color: AppTheme.textSub,
                                        fontSize: 11)),
                              ],
                            ),
                          ),
                          Text('$_total SAR',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 24,
                                  color: AppTheme.primary)),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),

                  // ── Documents
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppTheme.warning.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.shield_outlined,
                          color: AppTheme.warning, size: 18),
                    ),
                    const SizedBox(width: 10),
                    const Text('Required Documents',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: AppTheme.textMain)),
                  ]),
                  const SizedBox(height: 6),
                  Text(
                    'Both documents are required before your booking request can be sent.',
                    style: TextStyle(
                        color: AppTheme.textSub.withOpacity(0.8),
                        fontSize: 12),
                  ),
                  const SizedBox(height: 12),

                  _DocUploadTile(
                   
                    title: 'National ID',
                    subtitle: 'Clear photo of your ID card',
                    uploaded: _idImageUrl != null,
                    onTap: () => _pickDocument(true),
                  ),
                  const SizedBox(height: 10),
                  _DocUploadTile(
                   
                    title: 'Driving License',
                    subtitle: 'Clear photo of your license',
                    uploaded: _licenseImageUrl != null,
                    onTap: () => _pickDocument(false),
                  ),

                  const SizedBox(height: 28),

                  // ── Book button
                  if (_range != null)
                    AppButton(
                      label: 'Send Booking Request',
                      icon: Icons.send_rounded,
                      loading: _submitting,
                      height: 54,
                      color: _idImageUrl != null &&
                              _licenseImageUrl != null
                          ? AppTheme.primary
                          : AppTheme.textSub,
                      onPressed: _submitting ? null : _submitBooking,
                    )
                  else
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppTheme.divider),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.info_outline,
                              color: AppTheme.textSub, size: 16),
                          SizedBox(width: 8),
                          Text('Select dates first to continue',
                              style: TextStyle(
                                  color: AppTheme.textSub,
                                  fontSize: 13)),
                        ],
                      ),
                    ),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SpecChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _SpecChip(this.icon, this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.divider),
        boxShadow: AppTheme.softShadow,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppTheme.primary),
          const SizedBox(width: 5),
          Text(label,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textMain)),
        ],
      ),
    );
  }
}

class _DocUploadTile extends StatelessWidget {
 
  final String title;
  final String subtitle;
  final bool uploaded;
  final VoidCallback onTap;

  const _DocUploadTile({
    
    required this.title,
    required this.subtitle,
    required this.uploaded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: uploaded
              ? AppTheme.success.withOpacity(0.06)
              : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: uploaded
                  ? AppTheme.success.withOpacity(0.4)
                  : AppTheme.divider,
              width: uploaded ? 1.5 : 1),
          boxShadow: AppTheme.softShadow,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: uploaded
                    ? AppTheme.success.withOpacity(0.1)
                    : AppTheme.surface,
                borderRadius: BorderRadius.circular(10),
              ),
              
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: AppTheme.textMain)),
                  Text(
                    uploaded ? '✓ Uploaded successfully' : subtitle,
                    style: TextStyle(
                        color: uploaded
                            ? AppTheme.success
                            : AppTheme.textSub,
                        fontSize: 12),
                  ),
                ],
              ),
            ),
            Icon(
              uploaded
                  ? Icons.check_circle
                  : Icons.upload_file_outlined,
              color: uploaded ? AppTheme.success : AppTheme.textSub,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}

/* ══════════════════════════════════════════════════
   ADD CAR SHEET
══════════════════════════════════════════════════ */
class AddCarSheet extends StatefulWidget {
  final String ownerId;
  const AddCarSheet({super.key, required this.ownerId});

  @override
  State<AddCarSheet> createState() => _AddCarSheetState();
}

class _AddCarSheetState extends State<AddCarSheet> {
  final _form = GlobalKey<FormState>();
  final _titleCtl = TextEditingController();
  final _cityCtl = TextEditingController(text: 'Riyadh');
  final _yearCtl = TextEditingController();
  final _priceCtl = TextEditingController();
  final _imgCtl = TextEditingController();
  final _descCtl = TextEditingController();
  final _mileageCtl = TextEditingController();
  String _transmission = 'Automatic';
  String _fuelType = 'Petrol';
  int _seats = 5;
  bool _saving = false;

  @override
  void dispose() {
    for (var c in [_titleCtl, _cityCtl, _yearCtl, _priceCtl, _imgCtl, _descCtl, _mileageCtl]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    try {
      await FirebaseFirestore.instance.collection('cars').add({
        'ownerId': widget.ownerId,
        'title': _titleCtl.text.trim(),
        'city': _cityCtl.text.trim(),
        'year': int.parse(_yearCtl.text.trim()),
        'pricePerDay': int.parse(_priceCtl.text.trim()),
        'description': _descCtl.text.trim(),
        'imageUrl': _imgCtl.text.trim().isEmpty
            ? 'https://images.unsplash.com/photo-1568605117036-5fe5e7bab0b7?w=800'
            : _imgCtl.text.trim(),
        'transmission': _transmission,
        'fuelType': _fuelType,
        'seats': _seats,
        'mileage': _mileageCtl.text.trim().isEmpty
            ? 'Not specified'
            : _mileageCtl.text.trim(),
        'available': true,
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content:
              const Text('✅ Car listed successfully!'),
          backgroundColor: AppTheme.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppTheme.error,
        ));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
          20, 8, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: SingleChildScrollView(
        child: Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppTheme.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('List Your Car',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textMain)),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _titleCtl,
                decoration: const InputDecoration(
                    labelText: 'Car Title',
                    hintText: 'e.g. Toyota Camry 2024',
                    prefixIcon: Icon(Icons.directions_car_rounded)),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: TextFormField(
                    controller: _cityCtl,
                    decoration: const InputDecoration(
                        labelText: 'City',
                        prefixIcon: Icon(Icons.location_city)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: _yearCtl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                        labelText: 'Year',
                        prefixIcon: Icon(Icons.calendar_today)),
                    validator: (v) =>
                        int.tryParse(v ?? '') == null
                            ? 'Invalid'
                            : null,
                  ),
                ),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: TextFormField(
                    controller: _priceCtl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                        labelText: 'SAR/day',
                        prefixIcon: Icon(Icons.attach_money)),
                    validator: (v) =>
                        int.tryParse(v ?? '') == null
                            ? 'Invalid'
                            : null,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: _mileageCtl,
                    decoration: const InputDecoration(
                        labelText: 'Mileage (km)',
                        prefixIcon: Icon(Icons.speed)),
                  ),
                ),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _transmission,
                    decoration: const InputDecoration(
                        labelText: 'Transmission'),
                    items: ['Automatic', 'Manual']
                        .map((e) => DropdownMenuItem(
                            value: e, child: Text(e)))
                        .toList(),
                    onChanged: (v) =>
                        setState(() => _transmission = v!),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _fuelType,
                    decoration: const InputDecoration(
                        labelText: 'Fuel Type'),
                    items: ['Petrol', 'Diesel', 'Electric', 'Hybrid']
                        .map((e) => DropdownMenuItem(
                            value: e, child: Text(e)))
                        .toList(),
                    onChanged: (v) =>
                        setState(() => _fuelType = v!),
                  ),
                ),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                const Text('Seats: ',
                    style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textSub)),
                Expanded(
                  child: Slider(
                    value: _seats.toDouble(),
                    min: 2,
                    max: 8,
                    divisions: 6,
                    label: '$_seats seats',
                    activeColor: AppTheme.primary,
                    onChanged: (v) =>
                        setState(() => _seats = v.round()),
                  ),
                ),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppTheme.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text('$_seats',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold)),
                  ),
                ),
              ]),
              const SizedBox(height: 12),
              TextFormField(
                controller: _imgCtl,
                decoration: const InputDecoration(
                    labelText: 'Car Image URL (optional)',
                    prefixIcon: Icon(Icons.image_outlined)),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descCtl,
                maxLines: 3,
                decoration: const InputDecoration(
                    labelText: 'Description',
                    alignLabelWithHint: true,
                    prefixIcon: Icon(Icons.description_outlined)),
              ),
              const SizedBox(height: 20),
              AppButton(
                label: 'List My Car',
                icon: Icons.add_circle_outline,
                loading: _saving,
                onPressed: _saving ? null : _save,
                height: 52,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
