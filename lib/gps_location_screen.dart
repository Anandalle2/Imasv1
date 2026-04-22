import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// GPS Location — Real-time vehicle tracking on map.
class GpsLocationScreen extends StatefulWidget {
  final String? vehicleId;
  final String? vehicleName;
  final String? driverName;

  const GpsLocationScreen({
    super.key, this.vehicleId, this.vehicleName, this.driverName,
  });

  @override
  State<GpsLocationScreen> createState() => _GpsLocationScreenState();
}

class _GpsLocationScreenState extends State<GpsLocationScreen>
    with TickerProviderStateMixin {
  final MapController _mapCtrl = MapController();
  late AnimationController _pulseCtrl;

  LatLng _vehiclePos = const LatLng(12.9716, 77.5946);
  double _speed = 0;
  bool _isLive = false;
  String _lastUpdate = '--';

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
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
          child: Column(children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(width: 42, height: 42,
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(12),
                      color: isDark ? Colors.white.withAlpha(8) : Colors.black.withAlpha(5)),
                    child: Icon(Icons.arrow_back_ios_new_rounded, color: tp, size: 16)),
                ),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('GPS LOCATION', style: TextStyle(color: tp, fontSize: 16, fontWeight: FontWeight.w900)),
                  Text(widget.vehicleName ?? 'Vehicle Tracking',
                      style: TextStyle(color: ts, fontSize: 11, fontWeight: FontWeight.w600)),
                ])),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(color: (_isLive ? const Color(0xFF00E676) : Colors.grey).withAlpha(12),
                    borderRadius: BorderRadius.circular(8), border: Border.all(color: (_isLive ? const Color(0xFF00E676) : Colors.grey).withAlpha(40))),
                  child: Text(_isLive ? 'TRACKING' : 'OFFLINE',
                      style: TextStyle(color: _isLive ? const Color(0xFF00E676) : Colors.grey, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1)),
                ),
              ]),
            ),
            const SizedBox(height: 14),

            // Map
            Expanded(
              child: Stack(children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  child: widget.vehicleId != null
                    ? StreamBuilder<DocumentSnapshot>(
                        stream: FirebaseFirestore.instance.collection('vehicles').doc(widget.vehicleId).snapshots(),
                        builder: (context, snap) {
                          if (snap.hasData && snap.data!.exists) {
                            final d = snap.data!.data() as Map<String, dynamic>? ?? {};
                            final telemetry = d['telemetry'] as Map<String, dynamic>? ?? {};
                            final lat = (telemetry['lat'] ?? 0.0).toDouble();
                            final lng = (telemetry['lng'] ?? 0.0).toDouble();
                            final spd = (telemetry['speed'] ?? 0.0).toDouble();

                            if (lat != 0 && lng != 0) {
                              _vehiclePos = LatLng(lat, lng);
                              _speed = spd;
                              _isLive = d['status'] == 'online';
                              final ts2 = d['lastUpdate'] as Timestamp?;
                              _lastUpdate = ts2 != null
                                  ? '${ts2.toDate().hour.toString().padLeft(2, '0')}:${ts2.toDate().minute.toString().padLeft(2, '0')}'
                                  : '--';

                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                try { _mapCtrl.move(_vehiclePos, 15); } catch (_) {}
                              });
                            }
                          }
                          return _buildMap(isDark, accent);
                        })
                    : _buildMap(isDark, accent),
                ),

                // Controls
                Positioned(top: 16, right: 16, child: Column(children: [
                  _mapBtn(Icons.my_location_rounded, accent, panel, () {
                    _mapCtrl.move(_vehiclePos, 16);
                  }),
                  const SizedBox(height: 8),
                  _mapBtn(Icons.add_rounded, tp, panel, () {
                    _mapCtrl.move(_mapCtrl.camera.center, _mapCtrl.camera.zoom + 1);
                  }),
                  const SizedBox(height: 8),
                  _mapBtn(Icons.remove_rounded, tp, panel, () {
                    _mapCtrl.move(_mapCtrl.camera.center, _mapCtrl.camera.zoom - 1);
                  }),
                ])),

                // Bottom info card
                Positioned(bottom: 16, left: 16, right: 16,
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(color: panel.withAlpha(240), borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: border),
                      boxShadow: [BoxShadow(color: Colors.black.withAlpha(20), blurRadius: 16, offset: const Offset(0, 6))]),
                    child: Column(children: [
                      Row(children: [
                        Container(width: 42, height: 42, decoration: BoxDecoration(borderRadius: BorderRadius.circular(12),
                          gradient: LinearGradient(colors: [accent, accent.withAlpha(150)])),
                          child: const Icon(Icons.location_on_rounded, color: Colors.white, size: 20)),
                        const SizedBox(width: 14),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(widget.vehicleName ?? 'Vehicle', style: TextStyle(color: tp, fontSize: 14, fontWeight: FontWeight.w800)),
                          Text('${widget.driverName ?? "Driver"} • Last: $_lastUpdate',
                              style: TextStyle(color: ts, fontSize: 10, fontWeight: FontWeight.w500)),
                        ])),
                      ]),
                      const SizedBox(height: 14),
                      Row(children: [
                        _infoChip('Speed', '${_speed.toStringAsFixed(0)} km/h', accent, panel),
                        const SizedBox(width: 8),
                        _infoChip('Lat', _vehiclePos.latitude.toStringAsFixed(4), tp, panel),
                        const SizedBox(width: 8),
                        _infoChip('Lng', _vehiclePos.longitude.toStringAsFixed(4), tp, panel),
                      ]),
                    ]),
                  ),
                ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildMap(bool isDark, Color accent) {
    return FlutterMap(
      mapController: _mapCtrl,
      options: MapOptions(initialCenter: _vehiclePos, initialZoom: 14),
      children: [
        TileLayer(
          urlTemplate: isDark
              ? 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png'
              : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          subdomains: isDark ? const ['a', 'b', 'c', 'd'] : const [],
          userAgentPackageName: 'com.imas.app'),
        MarkerLayer(markers: [
          Marker(point: _vehiclePos, width: 50, height: 50, child: AnimatedBuilder(
            animation: _pulseCtrl,
            builder: (_, __) => Stack(alignment: Alignment.center, children: [
              Container(width: 36 + _pulseCtrl.value * 8, height: 36 + _pulseCtrl.value * 8,
                decoration: BoxDecoration(shape: BoxShape.circle, color: accent.withAlpha(20))),
              Container(width: 24, height: 24, decoration: BoxDecoration(shape: BoxShape.circle, color: accent,
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: [BoxShadow(color: accent.withAlpha(60), blurRadius: 10)]),
                child: const Icon(Icons.directions_car_rounded, color: Colors.white, size: 12)),
            ]),
          )),
        ]),
      ],
    );
  }

  Widget _infoChip(String label, String value, Color c, Color panel) {
    return Expanded(child: Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      decoration: BoxDecoration(color: c.withAlpha(8), borderRadius: BorderRadius.circular(10), border: Border.all(color: c.withAlpha(15))),
      child: Column(children: [
        Text(label, style: TextStyle(color: c.withAlpha(130), fontSize: 8, fontWeight: FontWeight.w700)),
        const SizedBox(height: 3),
        Text(value, style: TextStyle(color: c, fontSize: 11, fontWeight: FontWeight.w900, fontFamily: 'monospace')),
      ]),
    ));
  }

  Widget _mapBtn(IconData icon, Color color, Color panel, VoidCallback onTap) {
    return GestureDetector(
      onTap: () { HapticFeedback.lightImpact(); onTap(); },
      child: Container(width: 40, height: 40, decoration: BoxDecoration(color: panel, borderRadius: BorderRadius.circular(10),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(15), blurRadius: 8, offset: const Offset(0, 3))]),
        child: Icon(icon, color: color, size: 18)),
    );
  }
}
