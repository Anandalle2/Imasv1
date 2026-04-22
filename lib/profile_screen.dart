import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'edit_profile_screen.dart';
import 'settings_screen.dart';
import 'add_vehicle_screen.dart';
import 'welcome_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with TickerProviderStateMixin {
  late AnimationController _staggerCtrl;

  @override
  void initState() {
    super.initState();
    _staggerCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..forward();
  }

  @override
  void dispose() {
    _staggerCtrl.dispose();
    super.dispose();
  }

  Animation<double> _stagger(double begin, double end) {
    return Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(
      parent: _staggerCtrl,
      curve: Interval(begin, end, curve: Curves.easeOutCubic),
    ));
  }

  Future<void> _signOut() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF0C1420) : Colors.white,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Sign Out',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
        content: const Text(
            'Are you sure you want to sign out of your fleet management account?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await GoogleSignIn().signOut();
              await FirebaseAuth.instance.signOut();
              if (mounted) {
                Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const WelcomeScreen()),
                    (route) => false);
              }
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF3D5A),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12))),
            child: const Text('Sign Out',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? const Color(0xFF00E5FF) : const Color(0xFF007685);
    final panel = isDark ? const Color(0xFF0C1420) : Colors.white;
    final tp = isDark ? Colors.white : const Color(0xFF0D1117);
    final ts = isDark ? Colors.white54 : Colors.black54;
    final border = isDark ? const Color(0xFF1A2535) : Colors.black.withAlpha(8);
    final user = FirebaseAuth.instance.currentUser;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Owner Profile Card
                _fadeSlide(
                  _stagger(0.0, 0.2),
                  child: _buildOwnerCard(
                      user, isDark, panel, border, accent, tp, ts),
                ),
                const SizedBox(height: 24),

                // Fleet Stats
                _fadeSlide(
                  _stagger(0.1, 0.3),
                  child: _buildFleetStats(user, panel, border, accent, tp, ts),
                ),
                const SizedBox(height: 24),

                // My Vehicles
                _fadeSlide(
                  _stagger(0.15, 0.35),
                  child: _sectionTitle('MY VEHICLES', accent),
                ),
                const SizedBox(height: 14),
                _fadeSlide(
                  _stagger(0.2, 0.4),
                  child: _buildVehiclesList(
                      user, isDark, panel, border, accent, tp, ts),
                ),
                const SizedBox(height: 24),

                // Account Menu
                _fadeSlide(
                  _stagger(0.25, 0.45),
                  child: _sectionTitle('ACCOUNT', accent),
                ),
                const SizedBox(height: 14),
                _fadeSlide(
                  _stagger(0.3, 0.5),
                  child:
                      _buildMenu(isDark, panel, border, accent, tp, ts),
                ),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOwnerCard(User? user, bool isDark, Color panel, Color border,
      Color accent, Color tp, Color ts) {
    if (user == null) return const SizedBox();

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        String userName = user.displayName ?? 'Fleet Owner';
        String email = user.email ?? '';
        String company = '';
        String phone = '';

        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
          userName = data['username'] ?? userName;
          company = data['company'] ?? '';
          phone = data['phone'] ?? '';
        }

        final photoUrl = user.photoURL;

        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: panel,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: border),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withAlpha(isDark ? 12 : 5),
                  blurRadius: 15,
                  offset: const Offset(0, 6)),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient:
                      LinearGradient(colors: [accent, accent.withAlpha(150)]),
                  boxShadow: [
                    BoxShadow(
                        color: accent.withAlpha(40),
                        blurRadius: 15,
                        offset: const Offset(0, 4)),
                  ],
                ),
                child: photoUrl != null && photoUrl.isNotEmpty
                    ? ClipOval(
                        child: Image.network(photoUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _avatarText(userName)))
                    : _avatarText(userName),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(userName,
                        style: TextStyle(
                            color: tp,
                            fontSize: 20,
                            fontWeight: FontWeight.w900)),
                    const SizedBox(height: 4),
                    Text(email,
                        style: TextStyle(
                            color: ts,
                            fontSize: 12,
                            fontWeight: FontWeight.w500)),
                    if (phone.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(phone,
                          style: TextStyle(
                              color: ts,
                              fontSize: 11,
                              fontWeight: FontWeight.w500)),
                    ],
                    if (company.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(children: [
                        Icon(Icons.business_rounded,
                            color: accent, size: 12),
                        const SizedBox(width: 4),
                        Text(company,
                            style: TextStyle(
                                color: accent,
                                fontSize: 11,
                                fontWeight: FontWeight.w600)),
                      ]),
                    ],
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: accent.withAlpha(15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: accent.withAlpha(40)),
                      ),
                      child: Text('FLEET OWNER',
                          style: TextStyle(
                              color: accent,
                              fontSize: 8,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _avatarText(String name) {
    return Center(
      child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : 'O',
          style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w900)),
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
      builder: (_, snap) {
        final total = snap.data?.docs.length ?? 0;
        final online = snap.data?.docs
                .where((d) => (d.data() as Map)['status'] == 'online')
                .length ?? 0;

        return Row(
          children: [
            _stat('Vehicles', '$total', Icons.directions_car_rounded,
                accent, panel, border, tp, ts),
            const SizedBox(width: 10),
            _stat('Online', '$online', Icons.wifi_rounded,
                const Color(0xFF00E676), panel, border, tp, ts),
            const SizedBox(width: 10),
            _stat('Offline', '${total - online}', Icons.wifi_off_rounded,
                Colors.grey, panel, border, tp, ts),
          ],
        );
      },
    );
  }

  Widget _stat(String label, String value, IconData icon, Color color,
      Color panel, Color border, Color tp, Color ts) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: panel,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: border),
        ),
        child: Column(children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 8),
          Text(value,
              style: TextStyle(
                  color: tp, fontSize: 20, fontWeight: FontWeight.w900)),
          const SizedBox(height: 2),
          Text(label,
              style: TextStyle(
                  color: ts,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5)),
        ]),
      ),
    );
  }

  Widget _buildVehiclesList(User? user, bool isDark, Color panel, Color border,
      Color accent, Color tp, Color ts) {
    if (user == null) return const SizedBox();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('vehicles')
          .where('ownerId', isEqualTo: user.uid)
          .limit(3)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 28),
            decoration: BoxDecoration(
              color: panel,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: border),
            ),
            child: Column(children: [
              Icon(Icons.directions_car_outlined,
                  color: ts.withAlpha(80), size: 32),
              const SizedBox(height: 10),
              Text('No vehicles added yet',
                  style: TextStyle(
                      color: ts, fontSize: 12, fontWeight: FontWeight.w600)),
            ]),
          );
        }

        return Column(
          children: [
            ...snapshot.data!.docs.map((doc) {
              final d = doc.data() as Map<String, dynamic>;
              final name = d['vehicleName'] ?? 'Vehicle';
              final number = d['vehicleNumber'] ?? '--';
              final driver = d['driverName'] ?? 'No driver';
              final status = d['status'] ?? 'offline';
              final isOnline = status == 'online';

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: panel,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: border),
                ),
                child: Row(children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      gradient: LinearGradient(
                        colors: isOnline
                            ? [accent, accent.withAlpha(150)]
                            : [Colors.grey.shade600, Colors.grey.shade700],
                      ),
                    ),
                    child: const Icon(Icons.directions_car_rounded,
                        color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name,
                            style: TextStyle(
                                color: tp,
                                fontSize: 13,
                                fontWeight: FontWeight.w700)),
                        Text('$number • $driver',
                            style: TextStyle(
                                color: ts,
                                fontSize: 10,
                                fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isOnline
                          ? const Color(0xFF00E676)
                          : Colors.grey,
                    ),
                  ),
                ]),
              );
            }),
            const SizedBox(height: 6),
            GestureDetector(
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const AddVehicleScreen())),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: accent.withAlpha(10),
                  border: Border.all(color: accent.withAlpha(30)),
                ),
                child: Center(
                  child: Text('ADD MORE VEHICLES',
                      style: TextStyle(
                          color: accent,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1)),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMenu(bool isDark, Color panel, Color border, Color accent,
      Color tp, Color ts) {
    return Container(
      decoration: BoxDecoration(
        color: panel,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
      ),
      child: Column(
        children: [
          _menuItem(Icons.edit_rounded, 'Edit Profile', accent, tp, ts, () {
            Navigator.push(context,
                MaterialPageRoute(builder: (_) => const EditProfileScreen()));
          }),
          Divider(height: 1, color: border),
          _menuItem(Icons.settings_rounded, 'Settings',
              const Color(0xFFFF9F43), tp, ts, () {
            Navigator.push(context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()));
          }),
          Divider(height: 1, color: border),
          _menuItem(Icons.logout_rounded, 'Sign Out',
              const Color(0xFFFF3D5A), tp, ts, _signOut),
        ],
      ),
    );
  }

  Widget _menuItem(IconData icon, String label, Color color, Color tp,
      Color ts, VoidCallback onTap) {
    return ListTile(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: color.withAlpha(15)),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(label,
          style: TextStyle(
              color: tp, fontSize: 14, fontWeight: FontWeight.w700)),
      trailing: Icon(Icons.chevron_right_rounded,
          color: tp.withAlpha(40), size: 20),
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

  Widget _fadeSlide(Animation<double> anim, {required Widget child}) {
    return AnimatedBuilder(
      animation: anim,
      builder: (_, __) => Opacity(
        opacity: anim.value,
        child: Transform.translate(
            offset: Offset(0, 20 * (1 - anim.value)), child: child),
      ),
    );
  }
}
