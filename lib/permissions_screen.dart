import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'home_screen.dart';

class PermissionsScreen extends StatefulWidget {
  const PermissionsScreen({super.key});
  @override
  State<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends State<PermissionsScreen>
    with TickerProviderStateMixin {
  late AnimationController _staggerCtrl;
  late AnimationController _pulseCtrl;

  bool _locationGranted = false;
  bool _notificationGranted = false;
  bool _locationRequested = false;
  bool _notificationRequested = false;

  @override
  void initState() {
    super.initState();
    _staggerCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1400))
      ..forward();
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2000))
      ..repeat(reverse: true);
    _checkExisting();
  }

  @override
  void dispose() {
    _staggerCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  Animation<double> _stagger(double begin, double end) {
    return Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(
      parent: _staggerCtrl,
      curve: Interval(begin, end, curve: Curves.easeOutCubic),
    ));
  }

  Future<void> _checkExisting() async {
    final locStatus = await Permission.location.status;
    final notifStatus = await Permission.notification.status;
    if (mounted) {
      setState(() {
        _locationGranted = locStatus.isGranted;
        _notificationGranted = notifStatus.isGranted;
        _locationRequested = locStatus.isGranted || locStatus.isPermanentlyDenied;
        _notificationRequested = notifStatus.isGranted || notifStatus.isPermanentlyDenied;
      });
      // If both already granted, skip straight ahead
      if (_locationGranted && _notificationGranted) {
        _goHome();
      }
    }
  }

  Future<void> _requestLocation() async {
    HapticFeedback.lightImpact();
    final status = await Permission.location.request();
    if (mounted) {
      setState(() {
        _locationGranted = status.isGranted;
        _locationRequested = true;
      });
    }
  }

  Future<void> _requestNotification() async {
    HapticFeedback.lightImpact();
    final status = await Permission.notification.request();
    if (mounted) {
      setState(() {
        _notificationGranted = status.isGranted;
        _notificationRequested = true;
      });
    }
  }

  void _goHome() {
    Navigator.pushAndRemoveUntil(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const HomeScreen(),
        transitionDuration: const Duration(milliseconds: 600),
        transitionsBuilder: (_, anim, __, child) {
          return FadeTransition(
            opacity: CurvedAnimation(parent: anim, curve: Curves.easeInOut),
            child: child,
          );
        },
      ),
      (route) => false,
    );
  }

  bool get _canProceed => _locationRequested && _notificationRequested;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF050A12) : const Color(0xFFF4F8FB);
    final accent = isDark ? const Color(0xFF00E5FF) : const Color(0xFF007685);
    final panel = isDark ? const Color(0xFF0C1420) : Colors.white;
    final textPrimary = isDark ? Colors.white : const Color(0xFF0D1117);
    final textSub = isDark ? Colors.white54 : Colors.black54;
    final panelBorder = isDark ? const Color(0xFF1A2535) : Colors.black.withAlpha(8);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: bg,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 50),

                // ── Header ─────────────────────────────────────
                _fadeSlide(_stagger(0.0, 0.2), child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 60, height: 60,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [accent, accent.withAlpha(180)],
                        ),
                        boxShadow: [BoxShadow(
                          color: accent.withAlpha(40),
                          blurRadius: 25, offset: const Offset(0, 10),
                        )],
                      ),
                      child: const Center(
                        child: Icon(Icons.security_rounded,
                            color: Colors.white, size: 28),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text('Enable\npermissions',
                        style: TextStyle(
                            color: textPrimary,
                            fontSize: 34,
                            fontWeight: FontWeight.w900,
                            height: 1.15)),
                    const SizedBox(height: 12),
                    Text(
                      'IMAS needs these permissions to keep you safe on the road.',
                      style: TextStyle(
                          color: textSub,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          height: 1.5),
                    ),
                  ],
                )),

                const SizedBox(height: 44),

                // ── Location Permission Card ───────────────────
                _fadeSlide(_stagger(0.15, 0.4), child: _permissionCard(
                  title: 'Location Access',
                  subtitle: 'Required for GPS tracking, live maps, and fleet management.',
                  icon: Icons.location_on_rounded,
                  gradientColors: const [Color(0xFF00E676), Color(0xFF00C853)],
                  isGranted: _locationGranted,
                  isRequested: _locationRequested,
                  onRequest: _requestLocation,
                  panel: panel,
                  border: panelBorder,
                  textPrimary: textPrimary,
                  textSub: textSub,
                  accent: accent,
                  isDark: isDark,
                )),

                const SizedBox(height: 16),

                // ── Notification Permission Card ───────────────
                _fadeSlide(_stagger(0.25, 0.5), child: _permissionCard(
                  title: 'Notifications',
                  subtitle: 'Get instant alerts for drowsiness, collisions, and SOS events.',
                  icon: Icons.notifications_active_rounded,
                  gradientColors: const [Color(0xFFFF9F43), Color(0xFFFF6348)],
                  isGranted: _notificationGranted,
                  isRequested: _notificationRequested,
                  onRequest: _requestNotification,
                  panel: panel,
                  border: panelBorder,
                  textPrimary: textPrimary,
                  textSub: textSub,
                  accent: accent,
                  isDark: isDark,
                )),

                const Spacer(),

                // ── Continue Button ────────────────────────────
                _fadeSlide(_stagger(0.35, 0.6), child: SizedBox(
                  width: double.infinity,
                  height: 58,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 400),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      gradient: LinearGradient(
                        colors: _canProceed
                            ? [const Color(0xFF00D4E8), const Color(0xFF007685)]
                            : isDark
                                ? [const Color(0xFF1A2535), const Color(0xFF1A2535)]
                                : [Colors.grey.shade300, Colors.grey.shade300],
                      ),
                      boxShadow: _canProceed
                          ? [BoxShadow(
                              color: accent.withAlpha(40),
                              blurRadius: 20, offset: const Offset(0, 8))]
                          : [],
                    ),
                    child: ElevatedButton(
                      onPressed: _canProceed ? _goHome : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.transparent,
                        disabledForegroundColor: isDark
                            ? Colors.white.withAlpha(30)
                            : Colors.black.withAlpha(30),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _canProceed ? 'CONTINUE TO IMAS' : 'GRANT PERMISSIONS TO CONTINUE',
                            style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.5,
                                fontSize: 13),
                          ),
                          if (_canProceed) ...[
                            const SizedBox(width: 10),
                            const Icon(Icons.arrow_forward_rounded, size: 18),
                          ],
                        ],
                      ),
                    ),
                  ),
                )),

                const SizedBox(height: 16),

                // Skip option
                _fadeSlide(_stagger(0.4, 0.65), child: Center(
                  child: TextButton(
                    onPressed: _goHome,
                    child: Text('Skip for now',
                        style: TextStyle(
                            color: textSub.withAlpha(120),
                            fontSize: 13,
                            fontWeight: FontWeight.w600)),
                  ),
                )),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _permissionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Color> gradientColors,
    required bool isGranted,
    required bool isRequested,
    required VoidCallback onRequest,
    required Color panel,
    required Color border,
    required Color textPrimary,
    required Color textSub,
    required Color accent,
    required bool isDark,
  }) {
    final statusColor = isGranted
        ? const Color(0xFF00E676)
        : (isRequested ? const Color(0xFFFF3D5A) : gradientColors[0]);
    final statusText = isGranted
        ? 'GRANTED'
        : (isRequested ? 'DENIED' : 'REQUIRED');

    return GestureDetector(
      onTap: isGranted ? null : onRequest,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: panel,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isGranted
                ? const Color(0xFF00E676).withAlpha(60)
                : border,
            width: isGranted ? 1.5 : 1,
          ),
          boxShadow: isGranted
              ? [BoxShadow(
                  color: const Color(0xFF00E676).withAlpha(15),
                  blurRadius: 20, offset: const Offset(0, 6))]
              : [BoxShadow(
                  color: Colors.black.withAlpha(isDark ? 10 : 4),
                  blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 56, height: 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: isGranted
                    ? const LinearGradient(
                        colors: [Color(0xFF00E676), Color(0xFF00C853)])
                    : LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: gradientColors),
                boxShadow: [BoxShadow(
                  color: (isGranted ? const Color(0xFF00E676) : gradientColors[0])
                      .withAlpha(30),
                  blurRadius: 12, offset: const Offset(0, 4))],
              ),
              child: Icon(
                isGranted ? Icons.check_rounded : icon,
                color: Colors.white,
                size: isGranted ? 28 : 26,
              ),
            ),

            const SizedBox(width: 16),

            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Text(title,
                        style: TextStyle(
                            color: textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w800)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: statusColor.withAlpha(15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: statusColor.withAlpha(40)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 5, height: 5,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: statusColor,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(statusText,
                              style: TextStyle(
                                  color: statusColor,
                                  fontSize: 7,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5)),
                        ],
                      ),
                    ),
                  ]),
                  const SizedBox(height: 6),
                  Text(subtitle,
                      style: TextStyle(
                          color: textSub,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          height: 1.4)),
                ],
              ),
            ),

            // Action
            if (!isGranted)
              AnimatedBuilder(
                animation: _pulseCtrl,
                builder: (_, child) => Transform.scale(
                  scale: 0.95 + _pulseCtrl.value * 0.05,
                  child: child,
                ),
                child: Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: gradientColors[0].withAlpha(15),
                  ),
                  child: Icon(Icons.chevron_right_rounded,
                      color: gradientColors[0], size: 22),
                ),
              )
            else
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: const Color(0xFF00E676).withAlpha(15),
                ),
                child: const Icon(Icons.check_circle_rounded,
                    color: Color(0xFF00E676), size: 22),
              ),
          ],
        ),
      ),
    );
  }

  Widget _fadeSlide(Animation<double> anim, {required Widget child}) {
    return AnimatedBuilder(
      animation: anim,
      builder: (_, __) => Opacity(
        opacity: anim.value,
        child: Transform.translate(
          offset: Offset(0, 20 * (1 - anim.value)),
          child: child,
        ),
      ),
    );
  }
}
