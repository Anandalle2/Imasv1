import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});
  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with TickerProviderStateMixin {
  final MapController _mapCtrl = MapController();
  late AnimationController _pulseCtrl;
  LatLng _center = const LatLng(12.9716, 77.5946);
  bool _hasCentered = false;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? const Color(0xFF00E5FF) : const Color(0xFF007685);
    final panel = isDark ? const Color(0xFF0E1520) : Colors.white;
    final tp = isDark ? Colors.white : const Color(0xFF0D1117);
    final ts = isDark ? Colors.white54 : Colors.black54;
    final user = FirebaseAuth.instance.currentUser;

    return Stack(
      children: [
        // ── Map ───────────────────────────────────────────────────────
        FlutterMap(
          mapController: _mapCtrl,
          options: MapOptions(initialCenter: _center, initialZoom: 12),
          children: [
            TileLayer(
              urlTemplate: isDark
                  ? 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png'
                  : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              subdomains: isDark ? const ['a', 'b', 'c', 'd'] : const [],
              userAgentPackageName: 'com.imas.app',
            ),
            if (user != null)
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('vehicles')
                    .where('ownerId', isEqualTo: user.uid)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const MarkerLayer(markers: []);
                  final markers = <Marker>[];
                  for (final doc in snapshot.data!.docs) {
                    final d = doc.data() as Map<String, dynamic>;
                    final telemetry =
                        d['telemetry'] as Map<String, dynamic>? ?? {};
                    final lat = (telemetry['lat'] ?? 0.0).toDouble();
                    final lng = (telemetry['lng'] ?? 0.0).toDouble();
                    final speed = (telemetry['speed'] ?? 0.0).toDouble();
                    final status = d['status'] ?? 'offline';
                    final isOnline = status == 'online';
                    final vehicleName = d['vehicleName'] ?? 'Vehicle';
                    final driverName = d['driverName'] ?? '';
                    final vehicleNumber = d['vehicleNumber'] ?? '';
                    final category = d['vehicleCategory'] ?? 'Car';

                    if (lat == 0.0 && lng == 0.0) continue;

                    if (!_hasCentered) {
                      _center = LatLng(lat, lng);
                      _hasCentered = true;
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        _mapCtrl.move(_center, 13);
                      });
                    }

                    final markerColor =
                        isOnline ? const Color(0xFF00E5FF) : Colors.grey;

                    final catIcons = <String, IconData>{
                      'Car': Icons.directions_car_rounded,
                      'Bus': Icons.directions_bus_rounded,
                      'Van': Icons.airport_shuttle_rounded,
                      'Truck': Icons.local_shipping_rounded,
                      'Auto': Icons.electric_rickshaw_rounded,
                      'Bike': Icons.two_wheeler_rounded,
                    };

                    markers.add(Marker(
                      point: LatLng(lat, lng),
                      width: 52,
                      height: 62,
                      child: GestureDetector(
                        onTap: () => _showVehicleInfo(
                            context, vehicleName, vehicleNumber,
                            driverName, category, speed, isOnline,
                            lat, lng, isDark, accent, tp, ts, panel),
                        child: AnimatedBuilder(
                          animation: _pulseCtrl,
                          builder: (_, __) => Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Stack(
                                alignment: Alignment.center,
                                children: [
                                  if (isOnline)
                                    Container(
                                      width: 36 + _pulseCtrl.value * 8,
                                      height: 36 + _pulseCtrl.value * 8,
                                      decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: markerColor.withAlpha(25)),
                                    ),
                                  Container(
                                    width: 30,
                                    height: 30,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: markerColor,
                                      border: Border.all(
                                          color: Colors.white, width: 3),
                                      boxShadow: [
                                        BoxShadow(
                                            color: markerColor.withAlpha(80),
                                            blurRadius: 10),
                                      ],
                                    ),
                                    child: Icon(
                                        catIcons[category] ??
                                            Icons.directions_car_rounded,
                                        color: Colors.white,
                                        size: 14),
                                  ),
                                ],
                              ),
                              Container(
                                margin: const EdgeInsets.only(top: 2),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 4, vertical: 1),
                                decoration: BoxDecoration(
                                  color: Colors.black.withAlpha(160),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(vehicleName,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 7,
                                        fontWeight: FontWeight.w800)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ));
                  }
                  return MarkerLayer(markers: markers);
                },
              ),
          ],
        ),

        // ── Fleet Info Card ───────────────────────────────────────────
        Positioned(
          bottom: 20,
          left: 16,
          right: 16,
          child: user == null
              ? const SizedBox()
              : StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('vehicles')
                      .where('ownerId', isEqualTo: user.uid)
                      .snapshots(),
                  builder: (context, snapshot) {
                    final total = snapshot.data?.docs.length ?? 0;
                    final online = snapshot.data?.docs
                            .where((d) =>
                                (d.data() as Map)['status'] == 'online')
                            .length ?? 0;

                    return Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: panel.withAlpha(230),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: isDark
                                ? Colors.white10
                                : Colors.black.withAlpha(8)),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withAlpha(30),
                              blurRadius: 20,
                              offset: const Offset(0, 8)),
                        ],
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.map_rounded, color: accent, size: 18),
                          const SizedBox(width: 10),
                          Text('LIVE FLEET',
                              style: TextStyle(
                                  color: accent,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.5)),
                          const Spacer(),
                          _statChip('$total', 'TOTAL', accent, panel),
                          const SizedBox(width: 8),
                          _statChip('$online', 'ONLINE',
                              const Color(0xFF00E676), panel),
                          const SizedBox(width: 8),
                          _statChip('${total - online}', 'OFFLINE',
                              Colors.grey, panel),
                        ],
                      ),
                    );
                  },
                ),
        ),

        // ── Controls ──────────────────────────────────────────────────
        Positioned(
          top: 20,
          right: 16,
          child: Column(children: [
            _mapBtn(Icons.my_location_rounded, accent, panel, () {
              if (_hasCentered) _mapCtrl.move(_center, 13);
            }),
            const SizedBox(height: 10),
            _mapBtn(Icons.add_rounded, tp, panel, () {
              _mapCtrl.move(
                  _mapCtrl.camera.center, _mapCtrl.camera.zoom + 1);
            }),
            const SizedBox(height: 10),
            _mapBtn(Icons.remove_rounded, tp, panel, () {
              _mapCtrl.move(
                  _mapCtrl.camera.center, _mapCtrl.camera.zoom - 1);
            }),
          ]),
        ),
      ],
    );
  }

  void _showVehicleInfo(
      BuildContext ctx, String name, String number, String driver,
      String category, double speed, bool isOnline, double lat, double lng,
      bool isDark, Color accent, Color tp, Color ts, Color panel) {
    showModalBottomSheet(
      context: ctx,
      backgroundColor: isDark ? const Color(0xFF0C1420) : Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                      color: Colors.grey.withAlpha(60),
                      borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: 20),
            Row(children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: LinearGradient(
                      colors: isOnline
                          ? [const Color(0xFF00E5FF), const Color(0xFF007685)]
                          : [Colors.grey.shade600, Colors.grey.shade700]),
                ),
                child: const Icon(Icons.directions_car_rounded,
                    color: Colors.white, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        style: TextStyle(
                            color: tp,
                            fontSize: 18,
                            fontWeight: FontWeight.w900)),
                    Text('$number • $driver',
                        style: TextStyle(
                            color: ts,
                            fontSize: 12,
                            fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: (isOnline ? const Color(0xFF00E676) : Colors.grey)
                      .withAlpha(15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: (isOnline
                              ? const Color(0xFF00E676)
                              : Colors.grey)
                          .withAlpha(40)),
                ),
                child: Text(isOnline ? 'ONLINE' : 'OFFLINE',
                    style: TextStyle(
                        color: isOnline
                            ? const Color(0xFF00E676)
                            : Colors.grey,
                        fontSize: 9,
                        fontWeight: FontWeight.w900)),
              ),
            ]),
            const SizedBox(height: 16),
            Row(children: [
              _chipInfo('Speed', '${speed.toStringAsFixed(0)} km/h',
                  accent, panel),
              const SizedBox(width: 8),
              _chipInfo(
                  'Lat', lat.toStringAsFixed(4), tp, panel),
              const SizedBox(width: 8),
              _chipInfo(
                  'Lng', lng.toStringAsFixed(4), tp, panel),
            ]),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _chipInfo(String label, String value, Color c, Color panel) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: c.withAlpha(8),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: c.withAlpha(20)),
        ),
        child: Column(children: [
          Text(label,
              style: TextStyle(
                  color: c.withAlpha(150),
                  fontSize: 8,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5)),
          const SizedBox(height: 3),
          Text(value,
              style: TextStyle(
                  color: c,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'monospace')),
        ]),
      ),
    );
  }

  Widget _statChip(String value, String label, Color c, Color panel) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: c.withAlpha(12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: c.withAlpha(30)),
      ),
      child: Column(children: [
        Text(value,
            style: TextStyle(
                color: c,
                fontSize: 14,
                fontWeight: FontWeight.w900,
                fontFamily: 'monospace')),
        Text(label,
            style: TextStyle(
                color: c.withAlpha(150),
                fontSize: 6,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5)),
      ]),
    );
  }

  Widget _mapBtn(IconData icon, Color color, Color panel, VoidCallback onTap) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: panel,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withAlpha(20),
                blurRadius: 10,
                offset: const Offset(0, 4)),
          ],
        ),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }
}
