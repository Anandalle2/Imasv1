import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Emergency Response — SOS trigger, emergency contact management, alert history.
class EmergencyResponseScreen extends StatefulWidget {
  final String? vehicleId;
  final String? vehicleName;
  final String? driverName;
  final String? driverPhone;

  const EmergencyResponseScreen({
    super.key, this.vehicleId, this.vehicleName, this.driverName, this.driverPhone,
  });

  @override
  State<EmergencyResponseScreen> createState() => _EmergencyResponseScreenState();
}

class _EmergencyResponseScreenState extends State<EmergencyResponseScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late AnimationController _rippleCtrl;
  bool _sosTriggered = false;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000))..repeat(reverse: true);
    _rippleCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000))..repeat();
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _rippleCtrl.dispose();
    super.dispose();
  }

  Future<void> _triggerSOS() async {
    if (_isSending) return;
    setState(() => _isSending = true);

    HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 300));
    HapticFeedback.heavyImpact();

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await FirebaseFirestore.instance.collection('sos_alerts').add({
          'userId': user.uid,
          'vehicleId': widget.vehicleId ?? '',
          'vehicleName': widget.vehicleName ?? '',
          'driverName': widget.driverName ?? '',
          'driverPhone': widget.driverPhone ?? '',
          'status': 'ACTIVE',
          'severity': 'Critical',
          'type': 'SOS Emergency',
          'detail': 'Emergency SOS triggered by fleet owner',
          'timestamp': FieldValue.serverTimestamp(),
        });
      } catch (_) {}
    }

    if (mounted) {
      setState(() { _sosTriggered = true; _isSending = false; });
    }
  }

  Future<void> _cancelSOS() async {
    HapticFeedback.mediumImpact();
    setState(() => _sosTriggered = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF060B14) : const Color(0xFFF4F8FB);
    final panel = isDark ? const Color(0xFF0C1420) : Colors.white;
    final tp = isDark ? Colors.white : const Color(0xFF0D1117);
    final ts = isDark ? Colors.white54 : Colors.black54;
    final border = isDark ? const Color(0xFF1A2535) : Colors.black.withAlpha(8);
    const sos = Color(0xFFFF3D5A);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: bg,
        body: SafeArea(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [SliverToBoxAdapter(child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                // Header
                Row(children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(width: 42, height: 42,
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(12),
                        color: isDark ? Colors.white.withAlpha(8) : Colors.black.withAlpha(5)),
                      child: Icon(Icons.arrow_back_ios_new_rounded, color: tp, size: 16)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('EMERGENCY RESPONSE', style: TextStyle(color: tp, fontSize: 16, fontWeight: FontWeight.w900)),
                    Text(widget.vehicleName ?? 'Emergency Protocol',
                        style: TextStyle(color: ts, fontSize: 11, fontWeight: FontWeight.w600)),
                  ])),
                ]),
                const SizedBox(height: 28),

                // SOS Button
                Center(child: _buildSOSButton(isDark, tp, ts, sos)),
                const SizedBox(height: 28),

                // Vehicle/Driver Info
                _buildInfoCard(panel, border, tp, ts, isDark),
                const SizedBox(height: 20),

                // Emergency Contacts
                _sectionTitle('EMERGENCY CONTACTS', sos),
                const SizedBox(height: 12),
                _buildContacts(panel, border, tp, ts, isDark),
                const SizedBox(height: 20),

                // SOS History
                _sectionTitle('SOS HISTORY', const Color(0xFFFF9F43)),
                const SizedBox(height: 12),
                _buildSOSHistory(panel, border, tp, ts, isDark),
              ]),
            ))],
          ),
        ),
      ),
    );
  }

  Widget _buildSOSButton(bool isDark, Color tp, Color ts, Color sos) {
    return AnimatedBuilder(
      animation: _sosTriggered ? _rippleCtrl : _pulseCtrl,
      builder: (_, __) {
        if (_sosTriggered) {
          return Column(children: [
            Stack(alignment: Alignment.center, children: [
              // Ripple circles
              for (var i = 0; i < 3; i++)
                Container(
                  width: 160 + i * 30 + _rippleCtrl.value * 40,
                  height: 160 + i * 30 + _rippleCtrl.value * 40,
                  decoration: BoxDecoration(shape: BoxShape.circle,
                    border: Border.all(color: sos.withAlpha(20 - i * 5), width: 2)),
                ),
              Container(
                width: 140, height: 140,
                decoration: BoxDecoration(shape: BoxShape.circle,
                  color: sos.withAlpha(15),
                  border: Border.all(color: sos.withAlpha(60), width: 3)),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.sos_rounded, color: sos, size: 36),
                  const SizedBox(height: 6),
                  Text('SOS ACTIVE', style: TextStyle(color: sos, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1)),
                ]),
              ),
            ]),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: _cancelSOS,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: sos.withAlpha(40))),
                child: Text('CANCEL SOS', style: TextStyle(color: sos, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1)),
              ),
            ),
          ]);
        }

        return GestureDetector(
          onLongPress: _triggerSOS,
          child: Column(children: [
            Stack(alignment: Alignment.center, children: [
              Container(
                width: 160 + _pulseCtrl.value * 16,
                height: 160 + _pulseCtrl.value * 16,
                decoration: BoxDecoration(shape: BoxShape.circle, color: sos.withAlpha(6)),
              ),
              Container(
                width: 140, height: 140,
                decoration: BoxDecoration(shape: BoxShape.circle,
                  gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
                    colors: [sos, sos.withAlpha(200)]),
                  boxShadow: [BoxShadow(color: sos.withAlpha(40 + (_pulseCtrl.value * 20).toInt()),
                    blurRadius: 24 + _pulseCtrl.value * 8, spreadRadius: _pulseCtrl.value * 3)]),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.sos_rounded, color: Colors.white, size: 40),
                  const SizedBox(height: 6),
                  Text(_isSending ? 'SENDING...' : 'SOS',
                      style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 2)),
                ]),
              ),
            ]),
            const SizedBox(height: 16),
            Text('LONG PRESS TO ACTIVATE', style: TextStyle(color: ts, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1)),
          ]),
        );
      },
    );
  }

  Widget _buildInfoCard(Color panel, Color border, Color tp, Color ts, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: panel, borderRadius: BorderRadius.circular(18), border: Border.all(color: border)),
      child: Row(children: [
        Container(width: 48, height: 48, decoration: BoxDecoration(borderRadius: BorderRadius.circular(14),
          gradient: const LinearGradient(colors: [Color(0xFF00E5FF), Color(0xFF007685)])),
          child: const Icon(Icons.directions_car_rounded, color: Colors.white, size: 22)),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(widget.vehicleName ?? 'Vehicle', style: TextStyle(color: tp, fontSize: 15, fontWeight: FontWeight.w800)),
          const SizedBox(height: 3),
          Text('Driver: ${widget.driverName ?? "N/A"} • Phone: ${widget.driverPhone ?? "N/A"}',
              style: TextStyle(color: ts, fontSize: 10, fontWeight: FontWeight.w500)),
        ])),
      ]),
    );
  }

  Widget _buildContacts(Color panel, Color border, Color tp, Color ts, bool isDark) {
    final contacts = [
      {'name': 'Police', 'number': '100', 'icon': Icons.local_police_rounded, 'color': const Color(0xFF4FC3F7)},
      {'name': 'Ambulance', 'number': '108', 'icon': Icons.local_hospital_rounded, 'color': const Color(0xFFFF3D5A)},
      {'name': 'Fire', 'number': '101', 'icon': Icons.local_fire_department_rounded, 'color': const Color(0xFFFF9F43)},
    ];

    return Row(children: contacts.map((c) {
      final color = c['color'] as Color;
      return Expanded(child: Container(
        margin: EdgeInsets.only(right: c != contacts.last ? 10 : 0),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: panel, borderRadius: BorderRadius.circular(16), border: Border.all(color: border)),
        child: Column(children: [
          Container(width: 44, height: 44, decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: color.withAlpha(15)),
            child: Icon(c['icon'] as IconData, color: color, size: 20)),
          const SizedBox(height: 10),
          Text(c['name'] as String, style: TextStyle(color: tp, fontSize: 11, fontWeight: FontWeight.w800)),
          const SizedBox(height: 3),
          Text(c['number'] as String, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w900, fontFamily: 'monospace')),
        ]),
      ));
    }).toList());
  }

  Widget _buildSOSHistory(Color panel, Color border, Color tp, Color ts, bool isDark) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('sos_alerts')
          .where('userId', isEqualTo: user.uid)
          .limit(5).snapshots(),
      builder: (_, snap) {
        if (!snap.hasData || snap.data!.docs.isEmpty) {
          return Container(
            width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 24),
            decoration: BoxDecoration(color: panel, borderRadius: BorderRadius.circular(16), border: Border.all(color: border)),
            child: Column(children: [
              Icon(Icons.verified_user_rounded, color: const Color(0xFF00E676).withAlpha(60), size: 28),
              const SizedBox(height: 8),
              Text('No SOS History', style: TextStyle(color: tp, fontSize: 13, fontWeight: FontWeight.w800)),
              const SizedBox(height: 3),
              Text('All clear — no emergencies recorded', style: TextStyle(color: ts, fontSize: 11)),
            ]),
          );
        }

        return Column(children: snap.data!.docs.map((doc) {
          final d = doc.data() as Map<String, dynamic>;
          final ts2 = d['timestamp'] as Timestamp?;
          final dateStr = ts2 != null
              ? '${ts2.toDate().day}/${ts2.toDate().month} ${ts2.toDate().hour.toString().padLeft(2, '0')}:${ts2.toDate().minute.toString().padLeft(2, '0')}'
              : '--';
          final vehicle = d['vehicleName'] ?? '';
          final status = d['status'] ?? 'ACTIVE';

          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: panel, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFFF3D5A).withAlpha(15))),
            child: Row(children: [
              Container(width: 36, height: 36, decoration: BoxDecoration(borderRadius: BorderRadius.circular(10),
                color: const Color(0xFFFF3D5A).withAlpha(12)),
                child: const Icon(Icons.sos_rounded, color: Color(0xFFFF3D5A), size: 16)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('SOS Emergency', style: TextStyle(color: tp, fontSize: 12, fontWeight: FontWeight.w700)),
                Text('$vehicle • $dateStr', style: TextStyle(color: ts, fontSize: 9, fontWeight: FontWeight.w500)),
              ])),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: (status == 'ACTIVE' ? const Color(0xFFFF3D5A) : const Color(0xFF00E676)).withAlpha(10),
                  borderRadius: BorderRadius.circular(4)),
                child: Text(status, style: TextStyle(
                  color: status == 'ACTIVE' ? const Color(0xFFFF3D5A) : const Color(0xFF00E676),
                  fontSize: 7, fontWeight: FontWeight.w900)),
              ),
            ]),
          );
        }).toList());
      },
    );
  }

  Widget _sectionTitle(String t, Color c) => Row(children: [
    Container(width: 4, height: 16, decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(2))),
    const SizedBox(width: 10),
    Text(t, style: TextStyle(color: c.withAlpha(180), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2)),
  ]);
}
