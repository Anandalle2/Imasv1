import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'alerts_screen.dart';
import 'add_vehicle_screen.dart';
import 'map_screen.dart';
import 'profile_screen.dart';
import 'vehicle_dashboard_screen.dart';
import 'settings_screen.dart';
import 'services/alert_listener_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  int _currentIndex = 0;
  late AnimationController _pulseCtrl;
  final _alertService = AlertListenerService();

  @override
  void initState() {
    super.initState();
    _alertService.initialize();
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);

    // Check if owner has vehicles — if not, prompt to add
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkFirstVehicle());
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  Future<void> _checkFirstVehicle() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final snap = await FirebaseFirestore.instance
        .collection('vehicles')
        .where('ownerId', isEqualTo: user.uid)
        .limit(1)
        .get();
    if (snap.docs.isEmpty && mounted) {
      _showAddVehiclePrompt();
    }
  }

  void _showAddVehiclePrompt() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? const Color(0xFF00E5FF) : const Color(0xFF007685);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF0C1420) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                    colors: [accent, accent.withAlpha(150)]),
              ),
              child: const Icon(Icons.directions_car_rounded,
                  color: Colors.white, size: 32),
            ),
            const SizedBox(height: 24),
            Text('Welcome to IMAS!',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: isDark ? Colors.white : const Color(0xFF0D1117),
                    fontSize: 20,
                    fontWeight: FontWeight.w900)),
            const SizedBox(height: 10),
            Text(
                'Add your first vehicle with an IMAS device to get started with fleet monitoring.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: isDark ? Colors.white54 : Colors.black54,
                    fontSize: 13,
                    fontWeight: FontWeight.w500)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Later',
                style: TextStyle(
                    color: isDark ? Colors.white38 : Colors.black38,
                    fontWeight: FontWeight.w700)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _openAddVehicle();
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: accent,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14))),
            child: const Text('ADD VEHICLE',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1)),
          ),
        ],
      ),
    );
  }

  void _openAddVehicle() async {
    final result = await Navigator.push(
        context, MaterialPageRoute(builder: (_) => const AddVehicleScreen()));
    if (result == true && mounted) {
      setState(() {}); // Refresh
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF060B14) : const Color(0xFFF4F8FB);
    final accent = isDark ? const Color(0xFF00E5FF) : const Color(0xFF007685);
    final panel = isDark ? const Color(0xFF0C1420) : Colors.white;
    final textPrimary = isDark ? Colors.white : const Color(0xFF0D1117);
    final panelBorder =
        isDark ? Colors.white.withAlpha(8) : Colors.black.withAlpha(8);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: bg,
        body: SafeArea(
          child: IndexedStack(
            index: _currentIndex,
            children: [
              _OverviewTab(
                  isDark: isDark, accent: accent, pulseCtrl: _pulseCtrl),
              const AlertsScreen(),
              const SizedBox(), // Add Vehicle placeholder (handled by FAB)
              const MapScreen(),
              const ProfileScreen(),
            ],
          ),
        ),
        floatingActionButton: _buildAddVehicleFAB(accent),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        bottomNavigationBar: _buildBottomNav(
            isDark, panel, panelBorder, accent, textPrimary),
      ),
    );
  }

  Widget _buildAddVehicleFAB(Color accent) {
    return AnimatedBuilder(
      animation: _pulseCtrl,
      builder: (_, __) => GestureDetector(
        onTap: () {
          HapticFeedback.mediumImpact();
          _openAddVehicle();
        },
        child: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF00E5FF), Color(0xFF007685)],
            ),
            boxShadow: [
              BoxShadow(
                color: accent
                    .withAlpha((50 + _pulseCtrl.value * 30).toInt()),
                blurRadius: 16 + _pulseCtrl.value * 6,
                spreadRadius: _pulseCtrl.value * 2,
              ),
            ],
          ),
          child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
        ),
      ),
    );
  }

  Widget _buildBottomNav(bool isDark, Color panel, Color panelBorder,
      Color accent, Color textPrimary) {
    final items = [
      _NavItem(Icons.dashboard_rounded, 'Overview'),
      _NavItem(Icons.notifications_active_rounded, 'Alerts'),
      _NavItem(Icons.add, ''), // spacer for FAB
      _NavItem(Icons.map_rounded, 'Live Fleet'),
      _NavItem(Icons.person_rounded, 'Profile'),
    ];

    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: panel,
        border: Border(top: BorderSide(color: panelBorder)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withAlpha(isDark ? 20 : 8),
              blurRadius: 20,
              offset: const Offset(0, -5)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(items.length, (i) {
          if (i == 2) return const SizedBox(width: 60);
          final sel = _currentIndex == i;
          return GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              setState(() => _currentIndex = i);
            },
            behavior: HitTestBehavior.opaque,
            child: SizedBox(
              width: 64,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: sel ? accent.withAlpha(15) : Colors.transparent,
                    ),
                    child: Icon(items[i].icon,
                        color: sel ? accent : textPrimary.withAlpha(80),
                        size: 22),
                  ),
                  const SizedBox(height: 4),
                  Text(items[i].label,
                      style: TextStyle(
                          color: sel ? accent : textPrimary.withAlpha(80),
                          fontSize: 8,
                          fontWeight: sel ? FontWeight.w900 : FontWeight.w600,
                          letterSpacing: 0.3)),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem(this.icon, this.label);
}

// ══════════════════════════════════════════════════════════════════════════════
// OVERVIEW TAB — Vehicle Cards Dashboard
// ══════════════════════════════════════════════════════════════════════════════
class _OverviewTab extends StatelessWidget {
  final bool isDark;
  final Color accent;
  final AnimationController pulseCtrl;

  const _OverviewTab({
    required this.isDark,
    required this.accent,
    required this.pulseCtrl,
  });

  @override
  Widget build(BuildContext context) {
    final tp = isDark ? Colors.white : const Color(0xFF0D1117);
    final ts = isDark ? Colors.white54 : Colors.black54;
    final panel = isDark ? const Color(0xFF0C1420) : Colors.white;
    final border = isDark ? const Color(0xFF1A2535) : Colors.black.withAlpha(8);
    final user = FirebaseAuth.instance.currentUser;

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Greeting ────────────────────────────────────────
                _buildHeader(context, tp, ts, accent, panel),
                const SizedBox(height: 24),

                // ── Fleet Stats ─────────────────────────────────────
                _buildFleetStats(user, panel, border, accent, tp, ts),
                const SizedBox(height: 24),

                // ── My Vehicles ─────────────────────────────────────
                _sectionTitle('MY VEHICLES', accent),
                const SizedBox(height: 14),

                // ── Vehicle Cards (LIVE) ────────────────────────────
                _buildVehicleCards(context, user, panel, border, accent, tp, ts),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(
      BuildContext context, Color tp, Color ts, Color accent, Color panel) {
    final user = FirebaseAuth.instance.currentUser;
    final displayName = user?.displayName ?? 'Fleet Owner';
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good Morning ☀️'
        : hour < 17
            ? 'Good Afternoon 🌤️'
            : 'Good Evening 🌙';

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(greeting,
                  style: TextStyle(
                      color: ts, fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Text(displayName,
                  style: TextStyle(
                      color: tp, fontSize: 24, fontWeight: FontWeight.w900)),
            ],
          ),
        ),
        GestureDetector(
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const SettingsScreen())),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: isDark
                  ? Colors.white.withAlpha(6)
                  : Colors.black.withAlpha(4),
              border: Border.all(
                  color: isDark
                      ? Colors.white.withAlpha(8)
                      : Colors.black.withAlpha(6)),
            ),
            child: Icon(Icons.settings_rounded,
                color: tp.withAlpha(120), size: 20),
          ),
        ),
      ],
    );
  }

  Widget _buildFleetStats(User? user, Color panel, Color border, Color accent,
      Color tp, Color ts) {
    if (user == null) return const SizedBox();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('vehicles')
          .where('ownerId', isEqualTo: user.uid)
          .snapshots(),
      builder: (context, snap) {
        final total = snap.data?.docs.length ?? 0;
        final online = snap.data?.docs
                .where((d) => (d.data() as Map)['status'] == 'online')
                .length ??
            0;

        return Row(
          children: [
            _statCard('Total\nVehicles', '$total',
                Icons.directions_car_rounded, accent, panel, border, tp, ts),
            const SizedBox(width: 10),
            _statCard('Online\nNow', '$online', Icons.wifi_rounded,
                const Color(0xFF00E676), panel, border, tp, ts),
            const SizedBox(width: 10),
            _statCard('Offline', '${total - online}',
                Icons.wifi_off_rounded, Colors.grey, panel, border, tp, ts),
          ],
        );
      },
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color,
      Color panel, Color border, Color tp, Color ts) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: panel,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: border),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withAlpha(isDark ? 10 : 4),
                blurRadius: 12,
                offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: color.withAlpha(15)),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 10),
            Text(value,
                style: TextStyle(
                    color: tp, fontSize: 24, fontWeight: FontWeight.w900)),
            const SizedBox(height: 4),
            Text(label,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: ts,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    height: 1.3)),
          ],
        ),
      ),
    );
  }

  // ── VEHICLE CARDS ─────────────────────────────────────────────────────
  Widget _buildVehicleCards(BuildContext context, User? user, Color panel,
      Color border, Color accent, Color tp, Color ts) {
    if (user == null) return const SizedBox();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('vehicles')
          .where('ownerId', isEqualTo: user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
              child: Padding(
            padding: const EdgeInsets.all(40),
            child: CircularProgressIndicator(color: accent),
          ));
        }

        if (snapshot.hasError) {
          return _errorCard(panel, border, tp, ts);
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _emptyVehicles(context, accent, panel, border, tp, ts);
        }

        final docs = snapshot.data!.docs;
        return Column(
          children: docs.map((doc) {
            final d = doc.data() as Map<String, dynamic>;
            return _vehicleCard(context, doc.id, d, panel, border, accent, tp, ts);
          }).toList(),
        );
      },
    );
  }

  Widget _vehicleCard(BuildContext context, String docId,
      Map<String, dynamic> d, Color panel, Color border, Color accent,
      Color tp, Color ts) {
    final vehicleName = d['vehicleName'] ?? 'Vehicle';
    final vehicleNumber = d['vehicleNumber'] ?? '--';
    final driverName = d['driverName'] ?? 'No driver';
    final category = d['vehicleCategory'] ?? 'Car';
    final status = d['status'] ?? 'offline';
    final isOnline = status == 'online';
    final deviceId = d['deviceId'] ?? '--';
    final statusColor =
        isOnline ? const Color(0xFF00E676) : Colors.grey;

    final catIcons = <String, IconData>{
      'Car': Icons.directions_car_rounded,
      'Bus': Icons.directions_bus_rounded,
      'Van': Icons.airport_shuttle_rounded,
      'Truck': Icons.local_shipping_rounded,
      'Auto': Icons.electric_rickshaw_rounded,
      'Bike': Icons.two_wheeler_rounded,
    };

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => VehicleDashboardScreen(
                vehicleId: docId, vehicleData: d),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: panel,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
              color: isOnline ? accent.withAlpha(25) : border),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withAlpha(isDark ? 12 : 5),
                blurRadius: 15,
                offset: const Offset(0, 6)),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                // Vehicle icon
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isOnline
                          ? [const Color(0xFF00E5FF), const Color(0xFF007685)]
                          : [Colors.grey.shade600, Colors.grey.shade700],
                    ),
                    boxShadow: [
                      BoxShadow(
                          color: (isOnline ? accent : Colors.grey).withAlpha(30),
                          blurRadius: 12,
                          offset: const Offset(0, 4)),
                    ],
                  ),
                  child: Icon(
                      catIcons[category] ?? Icons.directions_car_rounded,
                      color: Colors.white,
                      size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(vehicleName,
                                style: TextStyle(
                                    color: tp,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800),
                                overflow: TextOverflow.ellipsis),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: statusColor.withAlpha(15),
                              borderRadius: BorderRadius.circular(6),
                              border:
                                  Border.all(color: statusColor.withAlpha(40)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 5,
                                  height: 5,
                                  decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: statusColor),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                    isOnline ? 'ONLINE' : 'OFFLINE',
                                    style: TextStyle(
                                        color: statusColor,
                                        fontSize: 7,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 0.5)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(vehicleNumber,
                          style: TextStyle(
                              color: accent,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'monospace')),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded,
                    color: tp.withAlpha(40), size: 24),
              ],
            ),
            const SizedBox(height: 16),
            // Info row
            Container(
              padding:
                  const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withAlpha(4)
                    : Colors.black.withAlpha(3),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  _infoItem(Icons.person_rounded, 'Driver', driverName, tp, ts),
                  Container(
                      width: 1,
                      height: 26,
                      margin: const EdgeInsets.symmetric(horizontal: 12),
                      color: border),
                  _infoItem(
                      Icons.memory_rounded, 'Device', deviceId, tp, ts),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoItem(
      IconData icon, String label, String value, Color tp, Color ts) {
    return Expanded(
      child: Row(
        children: [
          Icon(icon, color: ts, size: 14),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        color: ts,
                        fontSize: 8,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5)),
                const SizedBox(height: 2),
                Text(value,
                    style: TextStyle(
                        color: tp,
                        fontSize: 12,
                        fontWeight: FontWeight.w700),
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyVehicles(BuildContext context, Color accent, Color panel,
      Color border, Color tp, Color ts) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40),
      decoration: BoxDecoration(
        color: panel,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: border),
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
                shape: BoxShape.circle, color: accent.withAlpha(10)),
            child: Icon(Icons.directions_car_rounded,
                color: accent.withAlpha(60), size: 36),
          ),
          const SizedBox(height: 20),
          Text('No Vehicles Yet',
              style: TextStyle(
                  color: tp, fontSize: 18, fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          Text('Tap + to add your first vehicle',
              style: TextStyle(color: ts, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _errorCard(Color panel, Color border, Color tp, Color ts) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: panel,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: border),
      ),
      child: Column(
        children: [
          Icon(Icons.error_outline_rounded,
              color: const Color(0xFFFF3D5A).withAlpha(100), size: 36),
          const SizedBox(height: 14),
          Text('Unable to load vehicles',
              style: TextStyle(
                  color: tp, fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text('Check your internet & Firebase rules',
              style: TextStyle(color: ts, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _sectionTitle(String t, Color accent) {
    return Row(children: [
      Container(
          width: 4,
          height: 16,
          decoration: BoxDecoration(
              color: accent, borderRadius: BorderRadius.circular(2))),
      const SizedBox(width: 10),
      Text(t,
          style: TextStyle(
              color: accent.withAlpha(180),
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 2)),
    ]);
  }
}
