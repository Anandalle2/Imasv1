import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'driver_monitoring_screen.dart';
import 'vehicle_ahead_detection_screen.dart';
import 'gps_location_screen.dart';
import 'emergency_response_screen.dart';
import 'speedometer_screen.dart';

/// Per-vehicle dashboard — shows all monitoring features for a specific vehicle.
class VehicleDashboardScreen extends StatefulWidget {
  final String vehicleId;
  final Map<String, dynamic> vehicleData;

  const VehicleDashboardScreen({
    super.key,
    required this.vehicleId,
    required this.vehicleData,
  });

  @override
  State<VehicleDashboardScreen> createState() => _VehicleDashboardScreenState();
}

class _VehicleDashboardScreenState extends State<VehicleDashboardScreen>
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? const Color(0xFF00E5FF) : const Color(0xFF007685);
    final bg = isDark ? const Color(0xFF060B14) : const Color(0xFFF4F8FB);
    final panel = isDark ? const Color(0xFF0C1420) : Colors.white;
    final tp = isDark ? Colors.white : const Color(0xFF0D1117);
    final ts = isDark ? Colors.white54 : Colors.black54;
    final border = isDark ? const Color(0xFF1A2535) : Colors.black.withAlpha(8);

    final v = widget.vehicleData;
    final vehicleName = v['vehicleName'] ?? 'Vehicle';
    final vehicleNumber = v['vehicleNumber'] ?? '--';
    final driverName = v['driverName'] ?? 'No driver';
    final driverPhone = v['driverPhone'] ?? '';
    final category = v['vehicleCategory'] ?? 'Car';
    final status = v['status'] ?? 'offline';
    final isOnline = status == 'online';
    final deviceId = v['deviceId'] ?? '--';
    final statusColor = isOnline ? const Color(0xFF00E676) : Colors.grey;

    final catIcons = <String, IconData>{
      'Car': Icons.directions_car_rounded,
      'Bus': Icons.directions_bus_rounded,
      'Van': Icons.airport_shuttle_rounded,
      'Truck': Icons.local_shipping_rounded,
      'Auto': Icons.electric_rickshaw_rounded,
      'Bike': Icons.two_wheeler_rounded,
    };

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: bg,
        body: SafeArea(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 30),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Header ──────────────────────────────────
                      _fadeSlide(_stagger(0.0, 0.15), child: Row(children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(width: 44, height: 44,
                            decoration: BoxDecoration(borderRadius: BorderRadius.circular(14),
                              color: isDark ? Colors.white.withAlpha(8) : Colors.black.withAlpha(6)),
                            child: Icon(Icons.arrow_back_ios_new_rounded, color: tp, size: 18)),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(color: statusColor.withAlpha(15),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: statusColor.withAlpha(40))),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            Container(width: 6, height: 6,
                              decoration: BoxDecoration(shape: BoxShape.circle, color: statusColor)),
                            const SizedBox(width: 6),
                            Text(isOnline ? 'ONLINE' : 'OFFLINE',
                                style: TextStyle(color: statusColor, fontSize: 9,
                                    fontWeight: FontWeight.w900, letterSpacing: 1)),
                          ]),
                        ),
                      ])),
                      const SizedBox(height: 24),

                      // ── Vehicle Info Card ──────────────────────
                      _fadeSlide(_stagger(0.05, 0.2), child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(color: panel, borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: border),
                          boxShadow: [BoxShadow(color: Colors.black.withAlpha(isDark ? 12 : 5),
                            blurRadius: 15, offset: const Offset(0, 6))]),
                        child: Row(children: [
                          Container(width: 64, height: 64,
                            decoration: BoxDecoration(borderRadius: BorderRadius.circular(18),
                              gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
                                colors: isOnline
                                    ? [const Color(0xFF00E5FF), const Color(0xFF007685)]
                                    : [Colors.grey.shade600, Colors.grey.shade700]),
                              boxShadow: [BoxShadow(color: (isOnline ? accent : Colors.grey).withAlpha(30),
                                blurRadius: 12, offset: const Offset(0, 4))]),
                            child: Icon(catIcons[category] ?? Icons.directions_car_rounded,
                                color: Colors.white, size: 28)),
                          const SizedBox(width: 18),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(vehicleName, style: TextStyle(color: tp, fontSize: 20, fontWeight: FontWeight.w900)),
                            const SizedBox(height: 4),
                            Text(vehicleNumber, style: TextStyle(color: accent, fontSize: 13,
                                fontWeight: FontWeight.w700, fontFamily: 'monospace')),
                            const SizedBox(height: 6),
                            Row(children: [
                              Icon(Icons.person_rounded, color: ts, size: 13),
                              const SizedBox(width: 4),
                              Text(driverName, style: TextStyle(color: ts, fontSize: 12, fontWeight: FontWeight.w600)),
                              const SizedBox(width: 12),
                              Icon(Icons.memory_rounded, color: ts, size: 13),
                              const SizedBox(width: 4),
                              Flexible(child: Text(deviceId, style: TextStyle(color: ts, fontSize: 10,
                                  fontWeight: FontWeight.w600, fontFamily: 'monospace'),
                                  overflow: TextOverflow.ellipsis)),
                            ]),
                          ])),
                        ]),
                      )),
                      const SizedBox(height: 28),

                      // ── Features Section ───────────────────────
                      _fadeSlide(_stagger(0.1, 0.28), child: _sectionTitle('MONITORING FEATURES', accent)),
                      const SizedBox(height: 14),

                      // Feature cards
                      _buildFeatureGrid(context, isDark, panel, border, accent, tp, ts,
                          vehicleName, driverName, driverPhone, deviceId),

                      const SizedBox(height: 28),

                      // ── Coming Soon ────────────────────────────
                      _fadeSlide(_stagger(0.35, 0.5), child: _sectionTitle('COMING IN V2', Colors.grey)),
                      const SizedBox(height: 14),
                      _buildV2Features(isDark, panel, border, tp, ts),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureGrid(BuildContext context, bool isDark, Color panel, Color border,
      Color accent, Color tp, Color ts,
      String vehicleName, String driverName, String driverPhone, String deviceId) {
    final features = [
      _FeatureItem(
        'Driver\nMonitoring', 'AI drowsiness & fatigue\ndetection system',
        Icons.remove_red_eye_rounded, const [Color(0xFF00E5FF), Color(0xFF007685)], true,
        () => Navigator.push(context, MaterialPageRoute(builder: (_) => DriverMonitoringScreen(
            vehicleId: widget.vehicleId, driverName: driverName, deviceId: deviceId))),
      ),
      _FeatureItem(
        'Vehicle Ahead\nDetection', 'Forward collision warning\n& proximity radar',
        Icons.radar_rounded, const [Color(0xFFFF9F43), Color(0xFFFF6348)], true,
        () => Navigator.push(context, MaterialPageRoute(builder: (_) => VehicleAheadDetectionScreen(
            vehicleId: widget.vehicleId, driverName: driverName, deviceId: deviceId))),
      ),
      _FeatureItem(
        'GPS\nLocation', 'Real-time vehicle\ntracking on map',
        Icons.location_on_rounded, const [Color(0xFF00E676), Color(0xFF00C853)], true,
        () => Navigator.push(context, MaterialPageRoute(builder: (_) => GpsLocationScreen(
            vehicleId: widget.vehicleId, vehicleName: vehicleName, driverName: driverName))),
      ),
      _FeatureItem(
        'Emergency\nResponse', 'SOS alerts &\nemergency protocol',
        Icons.sos_rounded, const [Color(0xFFFF3D5A), Color(0xFFD50032)], true,
        () => Navigator.push(context, MaterialPageRoute(builder: (_) => EmergencyResponseScreen(
            vehicleId: widget.vehicleId, vehicleName: vehicleName,
            driverName: driverName, driverPhone: driverPhone))),
      ),
      _FeatureItem(
        'Speedometer', 'Live speed monitoring\n& alerts',
        Icons.speed_rounded, const [Color(0xFF7C4DFF), Color(0xFF651FFF)], true,
        () => Navigator.push(context, MaterialPageRoute(builder: (_) => SpeedometerScreen(
            vehicleId: widget.vehicleId, vehicleName: vehicleName, driverName: driverName))),
      ),
    ];

    return Column(children: [
      Row(children: [
        Expanded(child: _featureCard(features[0], isDark, panel, border, tp, ts, 1.0, 0)),
        const SizedBox(width: 14),
        Expanded(child: _featureCard(features[1], isDark, panel, border, tp, ts, 1.0, 1)),
      ]),
      const SizedBox(height: 14),
      Row(children: [
        Expanded(child: _featureCard(features[2], isDark, panel, border, tp, ts, 0.85, 2)),
        const SizedBox(width: 10),
        Expanded(child: _featureCard(features[3], isDark, panel, border, tp, ts, 0.85, 3)),
        const SizedBox(width: 10),
        Expanded(child: _featureCard(features[4], isDark, panel, border, tp, ts, 0.85, 4)),
      ]),
    ]);
  }

  Widget _featureCard(_FeatureItem f, bool isDark, Color panel, Color border,
      Color tp, Color ts, double aspectRatio, int index) {
    final delay = 0.12 + index * 0.04;
    return _fadeSlide(
      _stagger(delay.clamp(0.1, 0.4), (delay + 0.2).clamp(0.2, 0.6)),
      child: GestureDetector(
        onTap: () { HapticFeedback.lightImpact(); f.onTap(); },
        child: AspectRatio(
          aspectRatio: aspectRatio,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: panel, borderRadius: BorderRadius.circular(20),
              border: Border.all(color: border),
              boxShadow: [BoxShadow(color: Colors.black.withAlpha(isDark ? 10 : 4),
                blurRadius: 12, offset: const Offset(0, 4))]),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(width: 40, height: 40,
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: f.gradient),
                  boxShadow: [BoxShadow(color: f.gradient[0].withAlpha(35),
                    blurRadius: 10, offset: const Offset(0, 3))]),
                child: Icon(f.icon, color: Colors.white, size: 20)),
              const Spacer(),
              Text(f.title, style: TextStyle(color: tp, fontSize: 13, fontWeight: FontWeight.w900, height: 1.2)),
              const SizedBox(height: 4),
              if (f.active)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: const Color(0xFF00E676).withAlpha(15),
                    borderRadius: BorderRadius.circular(4)),
                  child: const Text('ACTIVE', style: TextStyle(color: Color(0xFF00E676),
                    fontSize: 7, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                ),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _buildV2Features(bool isDark, Color panel, Color border, Color tp, Color ts) {
    final v2 = [
      {'name': 'Lane Departure Warning', 'icon': Icons.swap_calls_rounded},
      {'name': 'Blind Spot Detection', 'icon': Icons.visibility_off_rounded},
    ];

    return Row(children: v2.map((f) => Expanded(
      child: _fadeSlide(_stagger(0.4, 0.55), child: Container(
        margin: EdgeInsets.only(right: f == v2.first ? 10 : 0, left: f == v2.last ? 10 : 0),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: panel, borderRadius: BorderRadius.circular(18),
          border: Border.all(color: isDark ? Colors.white.withAlpha(6) : border)),
        child: Row(children: [
          Container(width: 36, height: 36,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: Colors.grey.withAlpha(15)),
            child: Icon(f['icon'] as IconData, color: Colors.grey, size: 18)),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(f['name'] as String, style: TextStyle(color: ts, fontSize: 10, fontWeight: FontWeight.w800), maxLines: 2),
            const SizedBox(height: 2),
            Text('COMING SOON', style: TextStyle(color: Colors.grey.withAlpha(120),
              fontSize: 7, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
          ])),
        ]),
      )),
    )).toList());
  }

  Widget _sectionTitle(String t, Color accent) => Row(children: [
    Container(width: 4, height: 16, decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(2))),
    const SizedBox(width: 10),
    Text(t, style: TextStyle(color: accent.withAlpha(180), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2)),
  ]);

  Widget _fadeSlide(Animation<double> anim, {required Widget child}) {
    return AnimatedBuilder(
      animation: anim,
      builder: (_, __) => Opacity(opacity: anim.value,
        child: Transform.translate(offset: Offset(0, 20 * (1 - anim.value)), child: child)),
    );
  }
}

class _FeatureItem {
  final String title, subtitle;
  final IconData icon;
  final List<Color> gradient;
  final bool active;
  final VoidCallback onTap;
  const _FeatureItem(this.title, this.subtitle, this.icon, this.gradient, this.active, this.onTap);
}
