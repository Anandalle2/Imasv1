import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddVehicleScreen extends StatefulWidget {
  const AddVehicleScreen({super.key});
  @override
  State<AddVehicleScreen> createState() => _AddVehicleScreenState();
}

class _AddVehicleScreenState extends State<AddVehicleScreen>
    with TickerProviderStateMixin {
  final _deviceIdCtrl = TextEditingController();
  final _vehicleNameCtrl = TextEditingController();
  final _vehicleNumberCtrl = TextEditingController();
  final _driverNameCtrl = TextEditingController();
  final _driverPhoneCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  String? _error;
  String _selectedCategory = 'Car';

  final List<Map<String, dynamic>> _categories = [
    {'name': 'Car', 'icon': Icons.directions_car_rounded},
    {'name': 'Bus', 'icon': Icons.directions_bus_rounded},
    {'name': 'Van', 'icon': Icons.airport_shuttle_rounded},
    {'name': 'Truck', 'icon': Icons.local_shipping_rounded},
    {'name': 'Auto', 'icon': Icons.electric_rickshaw_rounded},
    {'name': 'Bike', 'icon': Icons.two_wheeler_rounded},
  ];

  late AnimationController _staggerCtrl;
  late AnimationController _orbCtrl;

  @override
  void initState() {
    super.initState();
    _staggerCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1400))
      ..forward();
    _orbCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 8))
      ..repeat();
  }

  @override
  void dispose() {
    _deviceIdCtrl.dispose();
    _vehicleNameCtrl.dispose();
    _vehicleNumberCtrl.dispose();
    _driverNameCtrl.dispose();
    _driverPhoneCtrl.dispose();
    _staggerCtrl.dispose();
    _orbCtrl.dispose();
    super.dispose();
  }

  Animation<double> _stagger(double begin, double end) {
    return Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(
      parent: _staggerCtrl,
      curve: Interval(begin, end, curve: Curves.easeOutCubic),
    ));
  }

  Future<void> _addVehicle() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _error = 'Not signed in.';
        _loading = false;
      });
      return;
    }

    try {
      // Check if device ID already registered
      final existing = await FirebaseFirestore.instance
          .collection('vehicles')
          .where('deviceId', isEqualTo: _deviceIdCtrl.text.trim())
          .limit(1)
          .get();

      if (existing.docs.isNotEmpty) {
        setState(() {
          _error = 'This Device ID is already registered to a vehicle.';
          _loading = false;
        });
        return;
      }

      await FirebaseFirestore.instance.collection('vehicles').add({
        'ownerId': user.uid,
        'deviceId': _deviceIdCtrl.text.trim(),
        'vehicleName': _vehicleNameCtrl.text.trim(),
        'vehicleNumber': _vehicleNumberCtrl.text.trim().toUpperCase(),
        'vehicleCategory': _selectedCategory,
        'driverName': _driverNameCtrl.text.trim(),
        'driverPhone': _driverPhoneCtrl.text.trim(),
        'status': 'offline',
        'telemetry': {
          'lat': 0.0,
          'lng': 0.0,
          'speed': 0.0,
        },
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        Navigator.pop(context, true); // return true to indicate vehicle added
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('✅ Vehicle registered successfully!'),
          backgroundColor: Color(0xFF00E676),
        ));
      }
    } catch (e) {
      setState(() => _error = 'Failed to register vehicle. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const accent = Color(0xFF00E5FF);
    final bg = isDark ? const Color(0xFF050A12) : const Color(0xFFF4F8FB);
    final panel = isDark ? const Color(0xFF0C1420) : Colors.white;
    final textPrimary = isDark ? Colors.white : const Color(0xFF0D1117);
    final textSub = isDark ? Colors.white54 : Colors.black54;
    final fieldBorder =
        isDark ? const Color(0xFF1A2535) : Colors.grey.shade200;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: bg,
        body: Stack(
          children: [
            // Animated orbs
            if (isDark)
              AnimatedBuilder(
                animation: _orbCtrl,
                builder: (_, __) {
                  final t = _orbCtrl.value * 2 * math.pi;
                  return Stack(children: [
                    Positioned(
                      top: -40 + 25 * math.sin(t * 0.8),
                      right: -70 + 20 * math.cos(t),
                      child: _glowOrb(240, accent, 0.06),
                    ),
                    Positioned(
                      bottom: 60 + 15 * math.cos(t * 0.6),
                      left: -50,
                      child: _glowOrb(180, const Color(0xFF7C4DFF), 0.04),
                    ),
                  ]);
                },
              ),

            SafeArea(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),

                      // Back button
                      _fadeSlide(
                        _stagger(0.0, 0.1),
                        child: GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              color: isDark
                                  ? Colors.white.withAlpha(8)
                                  : Colors.black.withAlpha(6),
                            ),
                            child: Icon(Icons.arrow_back_ios_new_rounded,
                                color: textPrimary, size: 18),
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Header
                      _fadeSlide(
                        _stagger(0.03, 0.18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                gradient: const LinearGradient(colors: [
                                  Color(0xFF00E5FF),
                                  Color(0xFF007685)
                                ]),
                                boxShadow: [
                                  BoxShadow(
                                      color: accent.withAlpha(40),
                                      blurRadius: 20,
                                      offset: const Offset(0, 8)),
                                ],
                              ),
                              child: const Center(
                                  child: Icon(Icons.directions_car_rounded,
                                      color: Colors.white, size: 26)),
                            ),
                            const SizedBox(height: 24),
                            Text('Add Vehicle',
                                style: TextStyle(
                                    color: textPrimary,
                                    fontSize: 30,
                                    fontWeight: FontWeight.w900,
                                    height: 1.15)),
                            const SizedBox(height: 8),
                            Text(
                                'Register a vehicle with its IMAS device and driver details',
                                style: TextStyle(
                                    color: textSub,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ),

                      const SizedBox(height: 28),

                      // Error
                      if (_error != null)
                        _fadeSlide(_stagger(0.0, 0.1),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 20),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color:
                                    const Color(0xFFFF3D5A).withAlpha(10),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                    color: const Color(0xFFFF3D5A)
                                        .withAlpha(30)),
                              ),
                              child: Row(children: [
                                const Icon(Icons.error_outline_rounded,
                                    color: Color(0xFFFF3D5A), size: 18),
                                const SizedBox(width: 12),
                                Expanded(
                                    child: Text(_error!,
                                        style: const TextStyle(
                                            color: Color(0xFFFF3D5A),
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600))),
                              ]),
                            )),

                      // ── Section: Device ────────────────────────────
                      _fadeSlide(
                        _stagger(0.05, 0.2),
                        child: _sectionLabel(
                            'IMAS DEVICE', Icons.memory_rounded, accent),
                      ),
                      const SizedBox(height: 12),
                      _fadeSlide(
                        _stagger(0.08, 0.25),
                        child: _field(
                          'Device ID',
                          'e.g. IMAS-JET-001',
                          Icons.developer_board_rounded,
                          _deviceIdCtrl,
                          panel,
                          fieldBorder,
                          accent,
                          textPrimary,
                          textSub,
                          isDark,
                          validator: (v) => v != null && v.trim().length >= 3
                              ? null
                              : 'Enter valid Device ID',
                        ),
                      ),

                      const SizedBox(height: 24),

                      // ── Section: Vehicle ───────────────────────────
                      _fadeSlide(
                        _stagger(0.1, 0.28),
                        child: _sectionLabel('VEHICLE DETAILS',
                            Icons.directions_car_rounded, const Color(0xFF7C4DFF)),
                      ),
                      const SizedBox(height: 12),

                      // Vehicle Category selector
                      _fadeSlide(
                        _stagger(0.12, 0.3),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Vehicle Category',
                                style: TextStyle(
                                    color: textSub,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.5)),
                            const SizedBox(height: 10),
                            SizedBox(
                              height: 80,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: _categories.length,
                                itemBuilder: (_, i) {
                                  final cat = _categories[i];
                                  final sel =
                                      _selectedCategory == cat['name'];
                                  return GestureDetector(
                                    onTap: () {
                                      HapticFeedback.lightImpact();
                                      setState(() =>
                                          _selectedCategory = cat['name']);
                                    },
                                    child: AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 200),
                                      width: 72,
                                      margin:
                                          const EdgeInsets.only(right: 10),
                                      decoration: BoxDecoration(
                                        color: sel
                                            ? accent.withAlpha(15)
                                            : panel,
                                        borderRadius:
                                            BorderRadius.circular(16),
                                        border: Border.all(
                                            color: sel
                                                ? accent
                                                : fieldBorder,
                                            width: sel ? 2 : 1),
                                      ),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(cat['icon'] as IconData,
                                              color:
                                                  sel ? accent : textSub,
                                              size: 24),
                                          const SizedBox(height: 6),
                                          Text(cat['name'] as String,
                                              style: TextStyle(
                                                  color: sel
                                                      ? accent
                                                      : textSub,
                                                  fontSize: 9,
                                                  fontWeight:
                                                      FontWeight.w800)),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      _fadeSlide(
                        _stagger(0.15, 0.33),
                        child: _field(
                          'Vehicle Name',
                          'e.g. Tata Ace, Ashok Leyland',
                          Icons.label_rounded,
                          _vehicleNameCtrl,
                          panel,
                          fieldBorder,
                          accent,
                          textPrimary,
                          textSub,
                          isDark,
                          validator: (v) => v != null && v.trim().isNotEmpty
                              ? null
                              : 'Enter vehicle name',
                        ),
                      ),
                      const SizedBox(height: 14),

                      _fadeSlide(
                        _stagger(0.18, 0.36),
                        child: _field(
                          'Registration Number',
                          'e.g. KA-01-AB-1234',
                          Icons.pin_rounded,
                          _vehicleNumberCtrl,
                          panel,
                          fieldBorder,
                          accent,
                          textPrimary,
                          textSub,
                          isDark,
                          validator: (v) => v != null && v.trim().isNotEmpty
                              ? null
                              : 'Enter registration number',
                        ),
                      ),

                      const SizedBox(height: 24),

                      // ── Section: Driver ────────────────────────────
                      _fadeSlide(
                        _stagger(0.2, 0.38),
                        child: _sectionLabel('DRIVER DETAILS',
                            Icons.person_rounded, const Color(0xFF00E676)),
                      ),
                      const SizedBox(height: 12),

                      _fadeSlide(
                        _stagger(0.23, 0.4),
                        child: _field(
                          'Driver Full Name',
                          'Full name of the driver',
                          Icons.person_outline_rounded,
                          _driverNameCtrl,
                          panel,
                          fieldBorder,
                          accent,
                          textPrimary,
                          textSub,
                          isDark,
                          validator: (v) => v != null && v.trim().isNotEmpty
                              ? null
                              : 'Enter driver name',
                        ),
                      ),
                      const SizedBox(height: 14),

                      _fadeSlide(
                        _stagger(0.25, 0.43),
                        child: _field(
                          'Driver Phone Number',
                          '+91 XXXXX XXXXX',
                          Icons.phone_rounded,
                          _driverPhoneCtrl,
                          panel,
                          fieldBorder,
                          accent,
                          textPrimary,
                          textSub,
                          isDark,
                          keyboardType: TextInputType.phone,
                          validator: (v) =>
                              v != null && v.trim().length >= 10
                                  ? null
                                  : 'Enter valid phone number',
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Submit button
                      _fadeSlide(
                        _stagger(0.28, 0.48),
                        child: SizedBox(
                          width: double.infinity,
                          height: 58,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(18),
                              gradient: const LinearGradient(colors: [
                                Color(0xFF00D4E8),
                                Color(0xFF007685)
                              ]),
                              boxShadow: [
                                BoxShadow(
                                    color: accent.withAlpha(50),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8)),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: _loading ? null : _addVehicle,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                foregroundColor: Colors.white,
                                disabledBackgroundColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(18)),
                              ),
                              child: _loading
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          color: Colors.white))
                                  : const Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.add_rounded, size: 20),
                                        SizedBox(width: 10),
                                        Text('REGISTER VEHICLE',
                                            style: TextStyle(
                                                fontWeight:
                                                    FontWeight.w900,
                                                letterSpacing: 2,
                                                fontSize: 14)),
                                      ],
                                    ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String label, IconData icon, Color color) {
    return Row(children: [
      Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: color.withAlpha(15)),
        child: Icon(icon, color: color, size: 14),
      ),
      const SizedBox(width: 10),
      Text(label,
          style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5)),
    ]);
  }

  Widget _field(
      String label,
      String hint,
      IconData icon,
      TextEditingController ctrl,
      Color panel,
      Color border,
      Color accent,
      Color tp,
      Color ts,
      bool isDark,
      {TextInputType? keyboardType,
      String? Function(String?)? validator}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label,
          style: TextStyle(
              color: ts,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5)),
      const SizedBox(height: 8),
      TextFormField(
        controller: ctrl,
        validator: validator,
        keyboardType: keyboardType,
        style:
            TextStyle(color: tp, fontWeight: FontWeight.w600, fontSize: 15),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: ts.withAlpha(80)),
          prefixIcon: Padding(
              padding: const EdgeInsets.only(left: 14, right: 10),
              child: Icon(icon, color: ts.withAlpha(150), size: 20)),
          prefixIconConstraints:
              const BoxConstraints(minWidth: 0, minHeight: 0),
          filled: true,
          fillColor: panel,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: border)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: border)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: accent, width: 2)),
          errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFFF3D5A))),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        ),
      ),
    ]);
  }

  Widget _glowOrb(double size, Color color, double opacity) {
    return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(colors: [
              color.withAlpha((opacity * 255).toInt()),
              color.withAlpha((opacity * 100).toInt()),
              Colors.transparent,
            ])));
  }

  Widget _fadeSlide(Animation<double> anim, {required Widget child}) {
    return AnimatedBuilder(
      animation: anim,
      builder: (_, __) => Opacity(
          opacity: anim.value,
          child: Transform.translate(
              offset: Offset(0, 18 * (1 - anim.value)), child: child)),
    );
  }
}
