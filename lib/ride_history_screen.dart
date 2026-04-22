import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RideHistoryScreen extends StatefulWidget {
  const RideHistoryScreen({super.key});
  @override
  State<RideHistoryScreen> createState() => _RideHistoryScreenState();
}

class _RideHistoryScreenState extends State<RideHistoryScreen> {
  String _filter = 'All';
  final _filters = ['All', 'Critical', 'Warning', 'Info'];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? const Color(0xFF00E5FF) : const Color(0xFF007685);
    final panel = isDark ? const Color(0xFF0E1520) : Colors.white;
    final textPrimary = isDark ? Colors.white : const Color(0xFF0D1117);
    final textSub = isDark ? Colors.white54 : Colors.black54;
    final panelBorder = isDark ? Colors.white10 : Colors.black.withAlpha(12);
    final user = FirebaseAuth.instance.currentUser;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Ride History',
              style: TextStyle(
                  color: textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Text('All alerts from your driving sessions',
              style: TextStyle(color: textSub, fontSize: 14)),
          const SizedBox(height: 20),

          // Filter chips
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: _filters.map((f) {
                final sel = _filter == f;
                final color = _chipColor(f);
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    setState(() => _filter = f);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(right: 10),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: sel ? color : panel,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: sel ? color : panelBorder),
                    ),
                    child: Text(f,
                        style: TextStyle(
                            color: sel ? Colors.white : textSub,
                            fontSize: 12,
                            fontWeight: FontWeight.w700)),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 20),

          // Alert list
          Expanded(
            child: user == null
                ? Center(
                    child: Text('Please sign in',
                        style: TextStyle(color: textSub)))
                : StreamBuilder<QuerySnapshot>(
                    stream: _buildQuery(user.uid),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(
                            child: CircularProgressIndicator(color: accent));
                      }
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return _emptyState(panel, panelBorder, textSub, accent);
                      }
                      final docs = snapshot.data!.docs;
                      return ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        itemCount: docs.length,
                        itemBuilder: (_, i) {
                          final d = docs[i].data() as Map<String, dynamic>;
                          return _alertTile(d, isDark, panel, panelBorder,
                              textPrimary, textSub);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Stream<QuerySnapshot> _buildQuery(String userId) {
    var q = FirebaseFirestore.instance
        .collection('dms_history')
        .where('userId', isEqualTo: userId)
        .limit(50);

    if (_filter != 'All') {
      q = q.where('severity', isEqualTo: _filter);
    }

    return q.snapshots();
  }

  Color _chipColor(String f) {
    switch (f) {
      case 'Critical':
        return const Color(0xFFFF3D5A);
      case 'Warning':
        return const Color(0xFFFF9F43);
      case 'Info':
        return const Color(0xFF00E676);
      default:
        return const Color(0xFF00E5FF);
    }
  }

  Widget _alertTile(Map<String, dynamic> d, bool isDark, Color panel,
      Color border, Color tp, Color ts) {
    final sev = d['severity'] ?? 'Info';
    final type = d['type'] ?? 'Alert';
    final color = _chipColor(sev);
    final ts2 = d['timestamp'] as Timestamp?;
    final time = ts2?.toDate();
    final timeStr = time != null
        ? '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}'
        : '--:--';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withAlpha(isDark ? 12 : 8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withAlpha(40)),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
              color: color.withAlpha(20), shape: BoxShape.circle),
          child: Icon(
            sev == 'Critical'
                ? Icons.crisis_alert_rounded
                : (sev == 'Warning'
                    ? Icons.warning_amber_rounded
                    : Icons.info_outline_rounded),
            color: color,
            size: 18,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(type,
                  style: TextStyle(
                      color: tp,
                      fontWeight: FontWeight.w800,
                      fontSize: 14)),
              const SizedBox(height: 4),
              Text(sev,
                  style: TextStyle(
                      color: color,
                      fontSize: 11,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        Text(timeStr,
            style: TextStyle(
                color: ts,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                fontFamily: 'monospace')),
      ]),
    );
  }

  Widget _emptyState(Color panel, Color border, Color ts, Color accent) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.history_rounded,
              color: accent.withAlpha(60), size: 60),
          const SizedBox(height: 16),
          Text('No History Yet',
              style: TextStyle(
                  color: ts,
                  fontSize: 16,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text('Your driving alerts will appear here',
              style: TextStyle(color: ts.withAlpha(120), fontSize: 13)),
        ],
      ),
    );
  }
}
