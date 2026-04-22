import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'ui_kit.dart';
import 'welcome_screen.dart';
import 'permissions_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _fadeCtrl;
  late AnimationController _scanCtrl;
  late AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600))..forward();
    _scanCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))..repeat(reverse: true);
    
    _fastBoot();
  }

  Future<void> _fastBoot() async {
    // Ultra-fast 1.5s boot sequence
    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;

    Widget destScreen = const WelcomeScreen();
    try {
      if (FirebaseAuth.instance.currentUser != null) destScreen = const PermissionsScreen();
    } catch (_) {}

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => destScreen,
          transitionDuration: const Duration(milliseconds: 800),
          transitionsBuilder: (_, anim, __, child) => FadeTransition(
            opacity: CurvedAnimation(parent: anim, curve: Curves.easeInOut),
            child: child,
          ),
        ),
      );
    });
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _scanCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: const Color(0xFF03070E), // Deep space blue/black
        body: FadeTransition(
          opacity: CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeIn),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    // Dynamic Outer Ripple
                    AnimatedBuilder(
                      animation: _pulseCtrl,
                      builder: (_, __) => Container(
                        width: 160 + (_pulseCtrl.value * 20),
                        height: 160 + (_pulseCtrl.value * 20),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFF00E5FF).withOpacity(0.2 - (_pulseCtrl.value * 0.2)),
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                    
                    // Core Premium Logo Background
                    Container(
                      width: 130,
                      height: 130,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF1E88E5), // Vivid Blue
                            Color(0xFF00E5FF), // Cyan
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF00E5FF).withOpacity(0.4),
                            blurRadius: 40,
                            spreadRadius: 5,
                            offset: const Offset(0, 10),
                          ),
                          BoxShadow(
                            color: Colors.black.withOpacity(0.5),
                            blurRadius: 20,
                            spreadRadius: -5,
                            offset: const Offset(0, 5),
                          )
                        ]
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          const Icon(
                            Icons.electric_car_rounded, // Better suited for 'Mobility Assistance'
                            size: 65,
                            color: Colors.white,
                          ),
                          // Subtle glass reflection inside the logo
                          Positioned(
                            top: 5,
                            left: 15,
                            child: Container(
                              width: 30,
                              height: 15,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          )
                        ],
                      ),
                    ),

                    // Scanner beam effect
                    Positioned.fill(
                      child: AnimatedBuilder(
                        animation: _scanCtrl,
                        builder: (_, __) => Align(
                          alignment: Alignment(0, -1.0 + (_scanCtrl.value * 2.0)),
                          child: Container(
                            height: 4,
                            width: 100,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              boxShadow: const [
                                BoxShadow(color: Colors.white, blurRadius: 15, spreadRadius: 3),
                                BoxShadow(color: Color(0xFF00E5FF), blurRadius: 25, spreadRadius: 5),
                              ]
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 50),
                
                // Advanced Typography for 'IMAS'
                const Text(
                  'IMAS',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 48,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 12.0,
                    shadows: [
                      Shadow(
                        color: Color(0xFF00E5FF),
                        blurRadius: 20,
                      )
                    ],
                  ),
                ),
                
                const SizedBox(height: 12),
                
                // Corrected Subtitle
                Text(
                  'INTELLIGENT MOBILITY ASSISTANCE SYSTEM',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: const Color(0xFF00E5FF).withOpacity(0.85),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 3.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}