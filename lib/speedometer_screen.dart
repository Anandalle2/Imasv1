import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Live Speedometer — Real-time speed, trip stats, and speed limit alerts.
class SpeedometerScreen extends StatefulWidget {
  final String? vehicleId;
  final String? vehicleName;
  final String? driverName;

  const SpeedometerScreen({
    super.key, this.vehicleId, this.vehicleName, this.driverName,
  });

  @override
  State<SpeedometerScreen> createState() => _SpeedometerScreenState();
}

class _SpeedometerScreenState extends State<SpeedometerScreen>
    with TickerProviderStateMixin {
  late AnimationController _needleCtrl;
  late AnimationController _pulseCtrl;
  late AnimationController _glowCtrl;

  double _speed = 0;
  double _maxSpeed = 0;
  double _avgSpeed = 0;
  double _distance = 0;
  int _speedLimit = 80;
  bool _isLive = false;
  bool _isOverSpeed = false;

  final _speedLimits = [40, 60, 80, 100, 120];

  @override
  void initState() {
    super.initState();
    _needleCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600))..repeat(reverse: true);
    _glowCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _needleCtrl.dispose();
    _pulseCtrl.dispose();
    _glowCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF060B14) : const Color(0xFFF4F8FB);
    final panel = isDark ? const Color(0xFF0C1420) : Colors.white;
    final tp = isDark ? Colors.white : const Color(0xFF0D1117);
    final ts = isDark ? Colors.white54 : Colors.black54;
    final accent = isDark ? const Color(0xFF00E5FF) : const Color(0xFF007685);
    final border = isDark ? const Color(0xFF1A2535) : Colors.black.withAlpha(8);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: bg,
        body: SafeArea(
          child: widget.vehicleId != null
            ? StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance.collection('vehicles').doc(widget.vehicleId).snapshots(),
                builder: (context, snap) {
                  if (snap.hasData && snap.data!.exists) {
                    final d = snap.data!.data() as Map<String, dynamic>? ?? {};
                    final telemetry = d['telemetry'] as Map<String, dynamic>? ?? {};
                    final spd = (telemetry['speed'] ?? 0.0).toDouble();
                    final dist = (telemetry['distance'] ?? 0.0).toDouble();
                    final status = d['status'] ?? 'offline';

                    if (spd != _speed) {
                      _speed = spd;
                      _isLive = status == 'online';
                      _distance = dist;
                      if (spd > _maxSpeed) _maxSpeed = spd;
                      _avgSpeed = (_avgSpeed + spd) / 2;
                      _isOverSpeed = spd > _speedLimit;
                      _needleCtrl.forward(from: 0);
                    }
                  }
                  return _buildContent(isDark, bg, panel, tp, ts, accent, border);
                })
            : _buildContent(isDark, bg, panel, tp, ts, accent, border),
        ),
      ),
    );
  }

  Widget _buildContent(bool isDark, Color bg, Color panel, Color tp, Color ts, Color accent, Color border) {
    final speedColor = _isOverSpeed
        ? const Color(0xFFFF3D5A)
        : _speed > _speedLimit * 0.8
            ? const Color(0xFFFF9F43)
            : const Color(0xFF00E676);

    return CustomScrollView(
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
              Text('SPEEDOMETER', style: TextStyle(color: tp, fontSize: 16, fontWeight: FontWeight.w900)),
              Text(widget.driverName ?? 'Live Speed Monitor',
                  style: TextStyle(color: ts, fontSize: 11, fontWeight: FontWeight.w600)),
            ])),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: (_isLive ? const Color(0xFF00E676) : Colors.grey).withAlpha(12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: (_isLive ? const Color(0xFF00E676) : Colors.grey).withAlpha(40))),
              child: Text(_isLive ? 'LIVE' : 'OFFLINE',
                  style: TextStyle(color: _isLive ? const Color(0xFF00E676) : Colors.grey,
                    fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1)),
            ),
          ]),
          const SizedBox(height: 28),

          // Speedometer gauge
          Center(child: _buildGauge(isDark, panel, border, tp, ts, speedColor, accent)),
          const SizedBox(height: 24),

          // Speed Limit Selector
          _sectionTitle('SPEED LIMIT', accent),
          const SizedBox(height: 12),
          _buildSpeedLimitSelector(panel, border, tp, ts, accent),
          const SizedBox(height: 20),

          // Trip stats
          _sectionTitle('TRIP STATISTICS', accent),
          const SizedBox(height: 12),
          _buildTripStats(isDark, panel, border, tp, ts, speedColor),
          const SizedBox(height: 20),

          // Speed status
          _buildSpeedStatus(isDark, panel, border, tp, ts, speedColor),
        ]),
      ))],
    );
  }

  Widget _buildGauge(bool isDark, Color panel, Color border, Color tp, Color ts, Color speedColor, Color accent) {
    return AnimatedBuilder(
      animation: _glowCtrl,
      builder: (_, __) => Container(
        width: 260, height: 260,
        decoration: BoxDecoration(
          shape: BoxShape.circle, color: panel,
          border: Border.all(color: border),
          boxShadow: [
            BoxShadow(color: speedColor.withAlpha(10 + (_glowCtrl.value * 15).toInt()),
              blurRadius: 30, spreadRadius: 5),
          ],
        ),
        child: Stack(alignment: Alignment.center, children: [
          // Gauge arc
          SizedBox(width: 220, height: 220,
            child: CustomPaint(painter: _SpeedGaugePainter(
              speed: _speed, maxSpeed: 200, speedColor: speedColor, isDark: isDark)),
          ),

          // Speed value
          Column(mainAxisSize: MainAxisSize.min, children: [
            Text(_speed.toStringAsFixed(0),
                style: TextStyle(color: tp, fontSize: 52, fontWeight: FontWeight.w900, fontFamily: 'monospace', height: 1)),
            Text('km/h', style: TextStyle(color: ts, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 2)),
            if (_isOverSpeed) ...[
              const SizedBox(height: 8),
              AnimatedBuilder(animation: _pulseCtrl, builder: (_, __) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF3D5A).withAlpha(10 + (_pulseCtrl.value * 15).toInt()),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFFF3D5A).withAlpha(50))),
                child: const Text('⚠ OVER SPEED', style: TextStyle(color: Color(0xFFFF3D5A),
                  fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 1)),
              )),
            ],
          ]),

          // Limit badge
          Positioned(bottom: 30, child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: accent.withAlpha(10), borderRadius: BorderRadius.circular(6),
              border: Border.all(color: accent.withAlpha(30))),
            child: Text('LIMIT: $_speedLimit km/h', style: TextStyle(color: accent,
              fontSize: 8, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
          )),
        ]),
      ),
    );
  }

  Widget _buildSpeedLimitSelector(Color panel, Color border, Color tp, Color ts, Color accent) {
    return Row(children: _speedLimits.map((limit) {
      final sel = limit == _speedLimit;
      return Expanded(child: GestureDetector(
        onTap: () { HapticFeedback.lightImpact(); setState(() => _speedLimit = limit); },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: EdgeInsets.only(right: limit != _speedLimits.last ? 8 : 0),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: sel ? accent.withAlpha(15) : panel,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: sel ? accent : border, width: sel ? 2 : 1)),
          child: Center(child: Text('$limit', style: TextStyle(
            color: sel ? accent : ts, fontSize: 14, fontWeight: FontWeight.w900, fontFamily: 'monospace'))),
        ),
      ));
    }).toList());
  }

  Widget _buildTripStats(bool isDark, Color panel, Color border, Color tp, Color ts, Color speedColor) {
    return Row(children: [
      _tripStat('Current', _speed.toStringAsFixed(0), 'km/h', speedColor, panel, border, tp, ts, isDark),
      const SizedBox(width: 10),
      _tripStat('Max', _maxSpeed.toStringAsFixed(0), 'km/h', const Color(0xFFFF9F43), panel, border, tp, ts, isDark),
      const SizedBox(width: 10),
      _tripStat('Average', _avgSpeed.toStringAsFixed(0), 'km/h', const Color(0xFF00E5FF), panel, border, tp, ts, isDark),
      const SizedBox(width: 10),
      _tripStat('Distance', _distance.toStringAsFixed(1), 'km', const Color(0xFF00E676), panel, border, tp, ts, isDark),
    ]);
  }

  Widget _tripStat(String label, String value, String unit, Color color,
      Color panel, Color border, Color tp, Color ts, bool isDark) {
    return Expanded(child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: panel, borderRadius: BorderRadius.circular(14), border: Border.all(color: border)),
      child: Column(children: [
        Text(value, style: TextStyle(color: tp, fontSize: 18, fontWeight: FontWeight.w900, fontFamily: 'monospace')),
        Text(unit, style: TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: ts, fontSize: 8, fontWeight: FontWeight.w700, letterSpacing: 0.3)),
      ]),
    ));
  }

  Widget _buildSpeedStatus(bool isDark, Color panel, Color border, Color tp, Color ts, Color speedColor) {
    String statusText;
    String detail;
    IconData icon;

    if (!_isLive) {
      statusText = 'Vehicle Offline';
      detail = 'Connect device to monitor speed';
      icon = Icons.sensors_off_rounded;
    } else if (_isOverSpeed) {
      statusText = 'Over Speed Limit!';
      detail = 'Current: ${_speed.toStringAsFixed(0)} km/h • Limit: $_speedLimit km/h';
      icon = Icons.speed_rounded;
    } else if (_speed > _speedLimit * 0.8) {
      statusText = 'Approaching Speed Limit';
      detail = '${(_speedLimit - _speed).toStringAsFixed(0)} km/h below limit';
      icon = Icons.warning_rounded;
    } else {
      statusText = 'Speed Normal';
      detail = 'Driving within safe limits';
      icon = Icons.verified_user_rounded;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: speedColor.withAlpha(isDark ? 8 : 5),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: speedColor.withAlpha(20))),
      child: Row(children: [
        Container(width: 42, height: 42, decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12), color: speedColor.withAlpha(15)),
          child: Icon(icon, color: speedColor, size: 20)),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(statusText, style: TextStyle(color: tp, fontSize: 14, fontWeight: FontWeight.w800)),
          const SizedBox(height: 3),
          Text(detail, style: TextStyle(color: ts, fontSize: 10, fontWeight: FontWeight.w500)),
        ])),
      ]),
    );
  }

  Widget _sectionTitle(String t, Color c) => Row(children: [
    Container(width: 4, height: 16, decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(2))),
    const SizedBox(width: 10),
    Text(t, style: TextStyle(color: c.withAlpha(180), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2)),
  ]);
}

// ══════════════════════════════════════════════════════════════════════════════
// SPEED GAUGE PAINTER
// ══════════════════════════════════════════════════════════════════════════════
class _SpeedGaugePainter extends CustomPainter {
  final double speed;
  final double maxSpeed;
  final Color speedColor;
  final bool isDark;

  _SpeedGaugePainter({required this.speed, required this.maxSpeed, required this.speedColor, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 15;
    const startAngle = 2.4; // ~135 degrees
    const sweepAngle = 4.9; // ~280 degrees

    // Background arc
    final bgPaint = Paint()
      ..color = (isDark ? Colors.white : Colors.black).withAlpha(8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), startAngle, sweepAngle, false, bgPaint);

    // Speed arc
    final speedFraction = (speed / maxSpeed).clamp(0, 1);
    final speedArc = sweepAngle * speedFraction;
    final speedPaint = Paint()
      ..shader = SweepGradient(
        startAngle: startAngle,
        endAngle: startAngle + sweepAngle,
        colors: [const Color(0xFF00E676), const Color(0xFFFF9F43), const Color(0xFFFF3D5A)],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), startAngle, speedArc, false, speedPaint);

    // Tick marks
    for (var i = 0; i <= 10; i++) {
      final angle = startAngle + (sweepAngle * i / 10);
      final isMain = i % 2 == 0;
      final innerR = radius - (isMain ? 22 : 16);
      final outerR = radius - 8;
      final p1 = Offset(center.dx + math.cos(angle) * innerR, center.dy + math.sin(angle) * innerR);
      final p2 = Offset(center.dx + math.cos(angle) * outerR, center.dy + math.sin(angle) * outerR);
      canvas.drawLine(p1, p2, Paint()
        ..color = (isDark ? Colors.white : Colors.black).withAlpha(isMain ? 30 : 15)
        ..strokeWidth = isMain ? 2 : 1);

      if (isMain) {
        final label = '${(maxSpeed * i / 10).toInt()}';
        final tp = TextPainter(
          text: TextSpan(text: label, style: TextStyle(
            color: (isDark ? Colors.white : Colors.black).withAlpha(50),
            fontSize: 8, fontWeight: FontWeight.w700)),
          textDirection: TextDirection.ltr)..layout();
        final labelPos = Offset(
          center.dx + math.cos(angle) * (innerR - 12) - tp.width / 2,
          center.dy + math.sin(angle) * (innerR - 12) - tp.height / 2);
        tp.paint(canvas, labelPos);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SpeedGaugePainter old) =>
      old.speed != speed || old.speedColor != speedColor;
}
