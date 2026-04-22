import 'package:flutter/material.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});
  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _regCtrl = TextEditingController();
  final _vehicleCtrl = TextEditingController();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (userDoc.exists) {
        final d = userDoc.data()!;
        _nameCtrl.text = d['username'] ?? '';
        _phoneCtrl.text = d['phone'] ?? '';
        _emailCtrl.text = d['email'] ?? user.email ?? '';
      }
      final vehicles = await FirebaseFirestore.instance
          .collection('vehicles')
          .where('ownerId', isEqualTo: user.uid)
          .limit(1)
          .get();
      if (vehicles.docs.isNotEmpty) {
        final v = vehicles.docs.first.data();
        _regCtrl.text = v['registrationNumber'] ?? '';
        _vehicleCtrl.text = v['vehicleName'] ?? '';
      }
    } catch (_) {}
    if (mounted) setState(() {});
  }

  Future<void> _save() async {
    setState(() => _loading = true);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'username': _nameCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile updated!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _regCtrl.dispose();
    _vehicleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF060B14) : const Color(0xFFF4FBFC);
    final panel = isDark ? const Color(0xFF0E1520) : Colors.white;
    final accent = isDark ? const Color(0xFF00E5FF) : const Color(0xFF007685);
    final textPrimary = isDark ? Colors.white : const Color(0xFF0D1117);
    final textSub = isDark ? Colors.white54 : Colors.black54;
    final fieldBorder = isDark ? Colors.white10 : Colors.black12;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Fleet Configuration',
            style: TextStyle(
                color: textPrimary,
                fontWeight: FontWeight.w900,
                fontSize: 16)),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _field('Name', _nameCtrl, Icons.person_outline_rounded,
                panel, fieldBorder, accent, textPrimary, textSub),
            const SizedBox(height: 16),
            _field('Phone', _phoneCtrl, Icons.phone_outlined,
                panel, fieldBorder, accent, textPrimary, textSub,
                keyboardType: TextInputType.phone),
            const SizedBox(height: 16),
            _field('Email', _emailCtrl, Icons.email_outlined,
                panel, fieldBorder, accent, textPrimary, textSub,
                readOnly: true),
            const SizedBox(height: 16),
            _field('Vehicle', _vehicleCtrl, Icons.directions_car_rounded,
                panel, fieldBorder, accent, textPrimary, textSub,
                readOnly: true),
            const SizedBox(height: 16),
            _field('Registration', _regCtrl, Icons.pin_rounded,
                panel, fieldBorder, accent, textPrimary, textSub,
                readOnly: true),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _loading ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: accent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: _loading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.5, color: Colors.white))
                    : const Text('SAVE CHANGES',
                        style: TextStyle(
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.5,
                            fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController ctrl, IconData icon,
      Color panel, Color border, Color accent, Color tp, Color ts,
      {bool readOnly = false, TextInputType? keyboardType}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label,
          style: TextStyle(
              color: ts, fontSize: 12, fontWeight: FontWeight.w700)),
      const SizedBox(height: 8),
      TextFormField(
        controller: ctrl,
        readOnly: readOnly,
        keyboardType: keyboardType,
        style: TextStyle(
          color: readOnly ? ts : tp,
          fontWeight: FontWeight.w600,
        ),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: ts, size: 20),
          suffixIcon:
              readOnly ? Icon(Icons.lock_rounded, color: ts, size: 16) : null,
          filled: true,
          fillColor: panel,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: border)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: border)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: accent, width: 2)),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    ]);
  }
}
