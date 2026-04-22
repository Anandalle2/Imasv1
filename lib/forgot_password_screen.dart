import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});
  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen>
    with TickerProviderStateMixin {
  final _emailCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  bool _sent = false;
  String? _error;

  late AnimationController _staggerCtrl;
  late AnimationController _orbCtrl;
  late AnimationController _successCtrl;

  @override
  void initState() {
    super.initState();
    _staggerCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..forward();
    _orbCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 8))
      ..repeat();
    _successCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _staggerCtrl.dispose();
    _orbCtrl.dispose();
    _successCtrl.dispose();
    super.dispose();
  }

  Animation<double> _stagger(double begin, double end) {
    return Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(
      parent: _staggerCtrl,
      curve: Interval(begin, end, curve: Curves.easeOutCubic),
    ));
  }

  Future<void> _sendReset() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });
    try {
      await FirebaseAuth.instance
          .sendPasswordResetEmail(email: _emailCtrl.text.trim());
      setState(() => _sent = true);
      _successCtrl.forward();
    } on FirebaseAuthException catch (e) {
      setState(() {
        switch (e.code) {
          case 'user-not-found':
            _error = 'No account found with this email.';
          default:
            _error = 'Failed to send reset email. Try again.';
        }
      });
    } catch (_) {
      setState(() => _error = 'Failed to send reset email. Try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // accent is used as const inline below
    final panel = isDark ? const Color(0xFF0C1420) : Colors.white;
    final textPrimary = isDark ? Colors.white : const Color(0xFF0D1117);
    final textSub = isDark ? Colors.white54 : Colors.black54;
    final fieldBorder = isDark ? const Color(0xFF1A2535) : Colors.grey.shade200;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF050A12) : const Color(0xFFF4F8FB),
        body: Stack(
          children: [
            if (isDark)
              AnimatedBuilder(
                animation: _orbCtrl,
                builder: (_, __) {
                  final t = _orbCtrl.value * 2 * math.pi;
                  return Positioned(
                    top: -50 + 30 * math.sin(t),
                    right: -90,
                    child: Container(
                      width: 280, height: 280,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(colors: [
                          const Color(0xFFFF9F43).withAlpha(12),
                          Colors.transparent,
                        ]),
                      ),
                    ),
                  );
                },
              ),

            SafeArea(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),

                      _fadeSlide(_stagger(0.0, 0.15), child:
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            width: 44, height: 44,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              color: isDark ? Colors.white.withAlpha(8) : Colors.black.withAlpha(6),
                            ),
                            child: Icon(Icons.arrow_back_ios_new_rounded,
                                color: textPrimary, size: 18),
                          ),
                        ),
                      ),

                      const SizedBox(height: 36),

                      if (!_sent) ...[
                        // ── Reset Form ───────────────────────────
                        _fadeSlide(_stagger(0.05, 0.25), child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 56, height: 56,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                gradient: const LinearGradient(
                                  colors: [Color(0xFFFF9F43), Color(0xFFFF6348)],
                                ),
                                boxShadow: [BoxShadow(
                                  color: const Color(0xFFFF9F43).withAlpha(40),
                                  blurRadius: 20, offset: const Offset(0, 8),
                                )],
                              ),
                              child: const Center(child: Icon(Icons.lock_reset_rounded,
                                  color: Colors.white, size: 26)),
                            ),
                            const SizedBox(height: 28),
                            Text('Forgot\npassword?',
                                style: TextStyle(color: textPrimary,
                                    fontSize: 34, fontWeight: FontWeight.w900,
                                    height: 1.15)),
                            const SizedBox(height: 10),
                            Text("Enter your email and we'll send a reset link",
                                style: TextStyle(color: textSub,
                                    fontSize: 15, fontWeight: FontWeight.w500)),
                          ],
                        )),

                        const SizedBox(height: 36),

                        if (_error != null)
                          Container(
                            margin: const EdgeInsets.only(bottom: 20),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF3D5A).withAlpha(10),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFFF3D5A).withAlpha(30)),
                            ),
                            child: Row(children: [
                              const Icon(Icons.error_outline_rounded,
                                  color: Color(0xFFFF3D5A), size: 18),
                              const SizedBox(width: 12),
                              Expanded(child: Text(_error!,
                                  style: const TextStyle(color: Color(0xFFFF3D5A),
                                      fontSize: 12, fontWeight: FontWeight.w600))),
                            ]),
                          ),

                        _fadeSlide(_stagger(0.1, 0.35), child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Email Address', style: TextStyle(color: textSub,
                                fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                            const SizedBox(height: 10),
                            TextFormField(
                              controller: _emailCtrl,
                              keyboardType: TextInputType.emailAddress,
                              validator: (v) => v != null && v.contains('@')
                                  ? null : 'Enter valid email',
                              style: TextStyle(color: textPrimary,
                                  fontWeight: FontWeight.w600, fontSize: 15),
                              decoration: InputDecoration(
                                hintText: 'you@company.com',
                                hintStyle: TextStyle(color: textSub.withAlpha(80)),
                                prefixIcon: Padding(
                                  padding: const EdgeInsets.only(left: 16, right: 12),
                                  child: Icon(Icons.email_outlined,
                                      color: textSub.withAlpha(150), size: 20)),
                                prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                                filled: true, fillColor: panel,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide(color: fieldBorder)),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide(color: fieldBorder)),
                                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16),
                                    borderSide: const BorderSide(color: Color(0xFFFF9F43), width: 2)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                              ),
                            ),
                          ],
                        )),

                        const SizedBox(height: 32),

                        _fadeSlide(_stagger(0.2, 0.45), child: SizedBox(
                          width: double.infinity, height: 58,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(18),
                              gradient: const LinearGradient(
                                colors: [Color(0xFFFF9F43), Color(0xFFFF6348)],
                              ),
                              boxShadow: [BoxShadow(
                                color: const Color(0xFFFF9F43).withAlpha(40),
                                blurRadius: 20, offset: const Offset(0, 8),
                              )],
                            ),
                            child: ElevatedButton(
                              onPressed: _loading ? null : _sendReset,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                foregroundColor: Colors.white,
                                disabledBackgroundColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18)),
                              ),
                              child: _loading
                                  ? const SizedBox(width: 22, height: 22,
                                      child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                                  : const Text('SEND RESET LINK',
                                      style: TextStyle(fontWeight: FontWeight.w900,
                                          letterSpacing: 2, fontSize: 14)),
                            ),
                          ),
                        )),
                      ] else ...[
                        // ── Success State ────────────────────────
                        ScaleTransition(
                          scale: CurvedAnimation(parent: _successCtrl, curve: Curves.elasticOut),
                          child: Column(
                            children: [
                              const SizedBox(height: 60),
                              Container(
                                width: 120, height: 120,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF00E676), Color(0xFF00C853)],
                                  ),
                                  boxShadow: [BoxShadow(
                                    color: const Color(0xFF00E676).withAlpha(50),
                                    blurRadius: 40, spreadRadius: 5,
                                  )],
                                ),
                                child: const Icon(Icons.mark_email_read_rounded,
                                    color: Colors.white, size: 54),
                              ),
                              const SizedBox(height: 36),
                              Text('Check your inbox',
                                  style: TextStyle(color: textPrimary,
                                      fontSize: 28, fontWeight: FontWeight.w900)),
                              const SizedBox(height: 14),
                              Text(
                                'We sent a reset link to\n${_emailCtrl.text.trim()}',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: textSub,
                                    fontSize: 15, fontWeight: FontWeight.w500, height: 1.6),
                              ),
                              const SizedBox(height: 40),
                              SizedBox(
                                width: double.infinity, height: 58,
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(18),
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFF00D4E8), Color(0xFF007685)],
                                    ),
                                  ),
                                  child: ElevatedButton(
                                    onPressed: () => Navigator.pop(context),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      shadowColor: Colors.transparent,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(18)),
                                    ),
                                    child: const Text('RETURN TO LOGIN',
                                        style: TextStyle(fontWeight: FontWeight.w900,
                                            letterSpacing: 2, fontSize: 14)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

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

  Widget _fadeSlide(Animation<double> anim, {required Widget child}) {
    return AnimatedBuilder(
      animation: anim,
      builder: (_, __) => Opacity(opacity: anim.value,
        child: Transform.translate(
          offset: Offset(0, 18 * (1 - anim.value)), child: child)),
    );
  }
}
