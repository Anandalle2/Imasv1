import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'main.dart';
import 'ui_kit.dart';
import 'permissions_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with TickerProviderStateMixin {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _loading = false;
  bool _obscure1 = true;
  bool _obscure2 = true;
  String? _error;
  int _step = 0;

  late AnimationController _staggerCtrl;
  late AnimationController _orbCtrl;

  @override
  void initState() {
    super.initState();
    _staggerCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..forward();
    _orbCtrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 8))
          ..repeat();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    _staggerCtrl.dispose();
    _orbCtrl.dispose();
    super.dispose();
  }

  Animation<double> _stagger(double begin, double end) =>
      Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(
        parent: _staggerCtrl,
        curve: Interval(begin, end, curve: Curves.easeOutCubic),
      ));

  void _nextStep() {
    if (_nameCtrl.text.trim().isEmpty || !_emailCtrl.text.contains('@')) {
      setState(() => _error = 'Please fill in all fields correctly.');
      return;
    }
    setState(() {
      _step = 1;
      _error = null;
    });
    _staggerCtrl
      ..reset()
      ..forward();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (_passCtrl.text != _confirmCtrl.text) {
      setState(() => _error = 'Passwords do not match.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text.trim(),
      );
      await cred.user!.updateDisplayName(_nameCtrl.text.trim());
      await FirebaseFirestore.instance
          .collection('users')
          .doc(cred.user!.uid)
          .set({
        'username': _nameCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'role': 'OWNER',
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        Navigator.pushAndRemoveUntil(context,
            imasRoute(const PermissionsScreen()), (r) => false);
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _error = switch (e.code) {
          'email-already-in-use' =>
            'An account already exists with this email.',
          'weak-password' =>
            'Password is too weak. Use at least 6 characters.',
          _ => 'Registration failed. Please try again.',
        };
      });
    } catch (_) {
      setState(() => _error = 'Registration failed. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? ImasColors.cyan : ImasColors.cyanDark;
    final panel = isDark ? ImasColors.darkSurface : Colors.white;
    final tp = isDark ? Colors.white : const Color(0xFF0D1117);
    final ts = isDark ? Colors.white54 : Colors.black54;
    final fieldBorder =
        isDark ? ImasColors.darkBorder : Colors.grey.shade200;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor:
            isDark ? ImasColors.darkBg : const Color(0xFFF4F8FB),
        body: Stack(children: [
          if (isDark)
            AnimatedBuilder(
              animation: _orbCtrl,
              builder: (_, __) {
                final t = _orbCtrl.value * 2 * math.pi;
                return Stack(children: [
                  Positioned(
                    top: -40 + 25 * math.sin(t * 0.8),
                    left: -70 + 20 * math.cos(t),
                    child: ImasGlowOrb(240, ImasColors.purple, 0.06),
                  ),
                  Positioned(
                    bottom: 80 + 20 * math.cos(t * 0.6),
                    right: -60,
                    child: ImasGlowOrb(200, ImasColors.cyan, 0.05),
                  ),
                ]);
              },
            ),
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: ImasSpacing.screenPadding,
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),

                    FadeSlide(
                      animation: _stagger(0.0, 0.15),
                      child: Row(children: [
                        ImasIconButton(
                          icon: Icons.arrow_back_ios_new_rounded,
                          onTap: () {
                            if (_step == 1) {
                              setState(() => _step = 0);
                              _staggerCtrl
                                ..reset()
                                ..forward();
                            } else {
                              Navigator.pop(context);
                            }
                          },
                          iconColor: tp,
                          bgColor: isDark
                              ? Colors.white.withAlpha(8)
                              : Colors.black.withAlpha(6),
                        ),
                        const Spacer(),
                        // Step dots
                        Row(children: [
                          _stepDot(0, accent),
                          const SizedBox(width: 8),
                          _stepDot(1, accent),
                        ]),
                      ]),
                    ),

                    const SizedBox(height: 36),

                    FadeSlide(
                      animation: _stagger(0.05, 0.25),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              gradient: const LinearGradient(
                                  colors: ImasColors.purpleGradient),
                              boxShadow: [
                                BoxShadow(
                                  color: ImasColors.purple.withAlpha(40),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Icon(Icons.person_add_rounded,
                                  color: Colors.white, size: 26),
                            ),
                          ),
                          const SizedBox(height: 28),
                          Text(
                            _step == 0
                                ? 'Create\naccount'
                                : 'Set your\npassword',
                            style: TextStyle(
                              color: tp,
                              fontSize: 34,
                              fontWeight: FontWeight.w900,
                              height: 1.15,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            _step == 0
                                ? 'Join IMAS to protect your fleet'
                                : 'Choose a strong password to secure your account',
                            style: TextStyle(
                              color: ts,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    if (_error != null) ImasErrorBanner(_error!),

                    // Step 0
                    if (_step == 0) ...[
                      FadeSlide(
                        animation: _stagger(0.1, 0.35),
                        child: ImasFormField(
                          label: 'Full Name',
                          hint: 'John Smith',
                          icon: Icons.person_outline_rounded,
                          controller: _nameCtrl,
                          panelColor: panel,
                          borderColor: fieldBorder,
                          accentColor: ImasColors.purple,
                          textColor: tp,
                          labelColor: ts,
                        ),
                      ),
                      const SizedBox(height: 18),
                      FadeSlide(
                        animation: _stagger(0.15, 0.4),
                        child: ImasFormField(
                          label: 'Email Address',
                          hint: 'you@company.com',
                          icon: Icons.email_outlined,
                          controller: _emailCtrl,
                          panelColor: panel,
                          borderColor: fieldBorder,
                          accentColor: ImasColors.purple,
                          textColor: tp,
                          labelColor: ts,
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) =>
                              v != null && v.contains('@')
                                  ? null
                                  : 'Enter valid email',
                        ),
                      ),
                      const SizedBox(height: 32),
                      FadeSlide(
                        animation: _stagger(0.2, 0.45),
                        child: ImasGradientButton(
                          label: 'CONTINUE',
                          onPressed: _nextStep,
                          colors: ImasColors.purpleGradient,
                          shadowColor: ImasColors.purple,
                          icon: Icons.arrow_forward_rounded,
                        ),
                      ),
                    ],

                    // Step 1
                    if (_step == 1) ...[
                      FadeSlide(
                        animation: _stagger(0.1, 0.35),
                        child: ImasFormField(
                          label: 'Password',
                          hint: '••••••••',
                          icon: Icons.lock_outline_rounded,
                          controller: _passCtrl,
                          panelColor: panel,
                          borderColor: fieldBorder,
                          accentColor: accent,
                          textColor: tp,
                          labelColor: ts,
                          obscure: _obscure1,
                          suffix: GestureDetector(
                            onTap: () =>
                                setState(() => _obscure1 = !_obscure1),
                            child: Icon(
                              _obscure1
                                  ? Icons.visibility_off_rounded
                                  : Icons.visibility_rounded,
                              color: ts,
                              size: 20,
                            ),
                          ),
                          validator: (v) =>
                              v != null && v.length >= 6
                                  ? null
                                  : 'Minimum 6 characters',
                        ),
                      ),
                      const SizedBox(height: 18),
                      FadeSlide(
                        animation: _stagger(0.15, 0.4),
                        child: ImasFormField(
                          label: 'Confirm Password',
                          hint: '••••••••',
                          icon: Icons.lock_outline_rounded,
                          controller: _confirmCtrl,
                          panelColor: panel,
                          borderColor: fieldBorder,
                          accentColor: accent,
                          textColor: tp,
                          labelColor: ts,
                          obscure: _obscure2,
                          suffix: GestureDetector(
                            onTap: () =>
                                setState(() => _obscure2 = !_obscure2),
                            child: Icon(
                              _obscure2
                                  ? Icons.visibility_off_rounded
                                  : Icons.visibility_rounded,
                              color: ts,
                              size: 20,
                            ),
                          ),
                          validator: (v) =>
                              v == _passCtrl.text
                                  ? null
                                  : 'Passwords do not match',
                        ),
                      ),
                      const SizedBox(height: 32),
                      FadeSlide(
                        animation: _stagger(0.2, 0.45),
                        child: ImasGradientButton(
                          label: 'CREATE ACCOUNT',
                          onPressed: _loading ? null : _register,
                          colors: ImasColors.brandGradient,
                          shadowColor: ImasColors.cyan,
                          loading: _loading,
                        ),
                      ),
                    ],

                    const SizedBox(height: 30),

                    FadeSlide(
                      animation: _stagger(0.3, 0.55),
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Already have an account? ',
                                style: TextStyle(color: ts, fontSize: 13)),
                            GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: Text(
                                'Sign In',
                                style: TextStyle(
                                  color: accent,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _stepDot(int step, Color accent) {
    final active = _step >= step;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: active ? 24 : 10,
      height: 10,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5),
        color: active ? accent : accent.withAlpha(30),
      ),
    );
  }
}