import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'main.dart';
import 'ui_kit.dart';
import 'login_screen.dart';
import 'register_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});
  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _orbCtrl;
  late AnimationController _fadeCtrl;
  late PageController _pageCtrl;
  int _currentPage = 0;

  static const _onboardingData = [
    _OnboardItem(
      icon: Icons.remove_red_eye_rounded,
      gradient: [ImasColors.cyan, ImasColors.cyanDark],
      title: 'Driver Monitoring',
      subtitle:
          'AI-powered drowsiness detection with real-time EAR, MAR & fatigue tracking to keep drivers alert.',
    ),
    _OnboardItem(
      icon: Icons.radar_rounded,
      gradient: [ImasColors.orange, ImasColors.orangeDark],
      title: 'Collision Avoidance',
      subtitle:
          'Forward collision warning with time-to-collision radar and smart proximity alerts.',
    ),
    _OnboardItem(
      icon: Icons.map_rounded,
      gradient: [ImasColors.green, ImasColors.greenDark],
      title: 'Fleet Tracking',
      subtitle:
          'Live GPS telemetry, route tracking, and real-time fleet management on interactive maps.',
    ),
    _OnboardItem(
      icon: Icons.shield_rounded,
      gradient: [ImasColors.purple, ImasColors.purpleDark],
      title: 'Safety Analytics',
      subtitle:
          'Comprehensive driving reports, safety scores, and incident history with Firebase cloud sync.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _orbCtrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 10))
          ..repeat();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..forward();
    _pageCtrl = PageController();
  }

  @override
  void dispose() {
    _orbCtrl.dispose();
    _fadeCtrl.dispose();
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: ImasColors.darkBg,
        body: FadeTransition(
          opacity: CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut),
          child: Stack(children: [
            // Animated background orbs
            AnimatedBuilder(
              animation: _orbCtrl,
              builder: (_, __) {
                final t = _orbCtrl.value * 2 * math.pi;
                return Stack(children: [
                  Positioned(
                    top: -50 + 40 * math.sin(t),
                    right: -80 + 30 * math.cos(t * 0.7),
                    child: ImasGlowOrb(280, ImasColors.cyan, 0.08),
                  ),
                  Positioned(
                    bottom: 100 + 25 * math.cos(t * 1.2),
                    left: -60 + 20 * math.sin(t * 0.5),
                    child: ImasGlowOrb(220, ImasColors.purple, 0.06),
                  ),
                  Positioned(
                    top: MediaQuery.of(context).size.height * 0.35 +
                        15 * math.sin(t * 0.8),
                    right: -40,
                    child: ImasGlowOrb(160, ImasColors.orange, 0.04),
                  ),
                ]);
              },
            ),

            // Gradient overlay
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        ImasColors.darkBg.withAlpha(200),
                        ImasColors.darkBg,
                      ],
                      stops: const [0.0, 0.55, 1.0],
                    ),
                  ),
                ),
              ),
            ),

            SafeArea(
              child: Column(children: [
                // Brand bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                  child: Row(children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        gradient: const LinearGradient(
                            colors: ImasColors.brandGradient),
                      ),
                      child: const Center(
                        child: Text(
                          'IM',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'IMAS',
                      style: TextStyle(
                        color: Colors.white.withAlpha(200),
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 3,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () =>
                          Navigator.push(context, imasRoute(const LoginScreen())),
                      child: Text(
                        'Skip',
                        style: TextStyle(
                          color: Colors.white.withAlpha(70),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ]),
                ),

                // Onboarding pages
                Expanded(
                  child: PageView.builder(
                    controller: _pageCtrl,
                    itemCount: _onboardingData.length,
                    onPageChanged: (i) => setState(() => _currentPage = i),
                    physics: const BouncingScrollPhysics(),
                    itemBuilder: (_, i) =>
                        _buildPage(_onboardingData[i]),
                  ),
                ),

                // Dots
                Padding(
                  padding: const EdgeInsets.only(bottom: 30),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _onboardingData.length,
                      (i) => AnimatedContainer(
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeOutCubic,
                        margin: const EdgeInsets.symmetric(horizontal: 5),
                        width: _currentPage == i ? 40 : 10,
                        height: 6,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          gradient: _currentPage == i
                              ? LinearGradient(colors: _onboardingData[_currentPage].gradient)
                              : null,
                          color: _currentPage == i
                              ? null
                              : Colors.white.withOpacity(0.2),
                          boxShadow: _currentPage == i
                              ? [
                                  BoxShadow(
                                    color: _onboardingData[_currentPage].gradient[0].withOpacity(0.6),
                                    blurRadius: 12,
                                    spreadRadius: 2,
                                  )
                                ]
                              : [],
                        ),
                      ),
                    ),
                  ),
                ),

                // Bottom buttons
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                  child: Column(children: [
                    ImasGradientButton(
                      label: 'GET STARTED',
                      onPressed: () =>
                          Navigator.push(context, imasRoute(const LoginScreen())),
                      colors: ImasColors.brandGradient,
                      shadowColor: ImasColors.cyan,
                      icon: Icons.arrow_forward_rounded,
                    ),
                    const SizedBox(height: 14),
                    ImasOutlinedButton(
                      label: 'CREATE ACCOUNT',
                      onPressed: () => Navigator.push(
                          context, imasRoute(const RegisterScreen())),
                      accentColor: ImasColors.cyan,
                    ),
                  ]),
                ),

                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Text(
                    'By continuing, you agree to our Terms & Privacy Policy',
                    style: TextStyle(
                      color: Colors.white.withAlpha(35),
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildPage(_OnboardItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(flex: 3),
          
          // Ultra-Premium Glassmorphic Floating Icon
          AnimatedBuilder(
            animation: _orbCtrl,
            builder: (context, child) {
              final floatY = math.sin(_orbCtrl.value * 4 * math.pi) * 12; // Gentle hover
              return Transform.translate(
                offset: Offset(0, floatY),
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: item.gradient[0].withOpacity(0.2),
                        blurRadius: 60,
                        spreadRadius: 10,
                        offset: const Offset(0, 20),
                      )
                    ]
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Backdrop Glass Ring
                      ClipOval(
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white.withOpacity(0.15), width: 1.5),
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.white.withOpacity(0.1),
                                  item.gradient[0].withOpacity(0.15),
                                ]
                              )
                            ),
                          ),
                        ),
                      ),
                      
                      // Solid Inner Core
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: item.gradient,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: item.gradient[0].withOpacity(0.8),
                              blurRadius: 25,
                              offset: const Offset(0, 8),
                            )
                          ]
                        ),
                        child: Icon(item.icon, color: Colors.white, size: 48),
                      ),
                    ],
                  ),
                ),
              );
            }
          ),
          
          const Spacer(flex: 2),
          
          // Sleek Typography
          Text(
            item.title.toUpperCase(),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 27,
              fontWeight: FontWeight.w900,
              letterSpacing: 3.5,
              height: 1.2,
              shadows: [
                Shadow(color: item.gradient[0].withOpacity(0.5), blurRadius: 15),
              ]
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Premium Subtle Subtitle
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              item.subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
                fontWeight: FontWeight.w400,
                letterSpacing: 0.5,
                height: 1.7,
              ),
            ),
          ),
          
          const Spacer(flex: 2),
        ],
      ),
    );
  }
}

class _OnboardItem {
  final IconData icon;
  final List<Color> gradient;
  final String title;
  final String subtitle;

  const _OnboardItem({
    required this.icon,
    required this.gradient,
    required this.title,
    required this.subtitle,
  });
}