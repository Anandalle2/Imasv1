import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Central alerts screen with Critical / Warning / Info filter tabs.
/// Shows all DMS + FCW alerts from the owner's fleet.
class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});
  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen>
    with TickerProviderStateMixin {
  int _activeFilter = 0; // 0=All, 1=Critical, 2=Warning, 3=Info
  final _filters = ['All', 'Critical', 'Warning', 'Info'];
  final _filterColors = [
    const Color(0xFF00E5FF),
    const Color(0xFFFF3D5A),
    const Color(0xFFFF9F43),
    const Color(0xFF00E676),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? const Color(0xFF00E5FF) : const Color(0xFF007685);
    final panel = isDark ? const Color(0xFF0C1420) : Colors.white;
    final tp = isDark ? Colors.white : const Color(0xFF0D1117);
    final ts = isDark ? Colors.white54 : Colors.black54;
    final border = isDark ? const Color(0xFF1A2535) : Colors.black.withAlpha(8);
    final user = FirebaseAuth.instance.currentUser;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────
          Text('Alert History',
              style: TextStyle(
                  color: tp, fontSize: 24, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text('All alerts from your fleet devices',
              style:
                  TextStyle(color: ts, fontSize: 13, fontWeight: FontWeight.w500)),

          const SizedBox(height: 20),

          // ── Filter Chips ────────────────────────────────────
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _filters.length,
              itemBuilder: (_, i) {
                final sel = _activeFilter == i;
                final color = _filterColors[i];
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    setState(() => _activeFilter = i);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(right: 10),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                    decoration: BoxDecoration(
                      color: sel ? color.withAlpha(20) : panel,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: sel ? color : border, width: sel ? 2 : 1),
                    ),
                    child: Center(
                      child: Text(
                        _filters[i].toUpperCase(),
                        style: TextStyle(
                            color: sel ? color : ts,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 16),

          // ── Alert List ──────────────────────────────────────
          Expanded(
            child: user == null
                ? Center(child: Text('Please sign in', style: TextStyle(color: ts)))
                : _buildAlertList(user, isDark, panel, border, accent, tp, ts),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertList(User user, bool isDark, Color panel, Color border,
      Color accent, Color tp, Color ts) {
    // Build Firestore query based on filter
    Query query = FirebaseFirestore.instance
        .collection('dms_history')
        .where('userId', isEqualTo: user.uid)
        .limit(50);

    if (_activeFilter == 1) {
      query = query.where('severity', isEqualTo: 'Critical');
    } else if (_activeFilter == 2) {
      query = query.where('severity', isEqualTo: 'Warning');
    } else if (_activeFilter == 3) {
      query = query.where('severity', isEqualTo: 'Info');
    }

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
              child: CircularProgressIndicator(color: accent));
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline_rounded,
                    color: const Color(0xFFFF3D5A).withAlpha(120), size: 40),
                const SizedBox(height: 14),
                Text('Unable to load alerts',
                    style: TextStyle(
                        color: tp, fontSize: 16, fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                Text('Check Firebase rules & try again',
                    style: TextStyle(color: ts, fontSize: 12)),
              ],
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF00E676).withAlpha(10)),
                  child: Icon(Icons.verified_user_rounded,
                      color: const Color(0xFF00E676).withAlpha(80), size: 36),
                ),
                const SizedBox(height: 20),
                Text('All Clear',
                    style: TextStyle(
                        color: tp, fontSize: 18, fontWeight: FontWeight.w900)),
                const SizedBox(height: 6),
                Text(
                    _activeFilter == 0
                        ? 'No alerts from your fleet'
                        : 'No ${_filters[_activeFilter].toLowerCase()} alerts',
                    style: TextStyle(color: ts, fontSize: 13)),
              ],
            ),
          );
        }

        return ListView.builder(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 100),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (_, i) {
            final doc = snapshot.data!.docs[i];
            final d = doc.data() as Map<String, dynamic>;
            return _alertCard(d, isDark, panel, border, tp, ts);
          },
        );
      },
    );
  }

  Widget _alertCard(Map<String, dynamic> d, bool isDark, Color panel,
      Color border, Color tp, Color ts) {
    final severity = d['severity'] ?? 'Warning';
    final type = d['type'] ?? 'Alert';
    final detail = d['detail'] ?? '';
    final ts2 = d['timestamp'] as Timestamp?;
    final dateStr = ts2 != null
        ? '${ts2.toDate().day}/${ts2.toDate().month} ${ts2.toDate().hour.toString().padLeft(2, '0')}:${ts2.toDate().minute.toString().padLeft(2, '0')}'
        : '--';

    Color color;
    IconData icon;
    switch (severity) {
      case 'Critical':
        color = const Color(0xFFFF3D5A);
        icon = Icons.crisis_alert_rounded;
        break;
      case 'Warning':
        color = const Color(0xFFFF9F43);
        icon = Icons.warning_amber_rounded;
        break;
      default:
        color = const Color(0xFF00E676);
        icon = Icons.info_outline_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: panel,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withAlpha(isDark ? 20 : 10)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withAlpha(isDark ? 8 : 3),
              blurRadius: 10,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: color.withAlpha(15),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(type,
                          style: TextStyle(
                              color: tp,
                              fontSize: 14,
                              fontWeight: FontWeight.w800),
                          overflow: TextOverflow.ellipsis),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withAlpha(12),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: color.withAlpha(40)),
                      ),
                      child: Text(severity.toUpperCase(),
                          style: TextStyle(
                              color: color,
                              fontSize: 7,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5)),
                    ),
                  ],
                ),
                if (detail.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(detail,
                      style: TextStyle(
                          color: ts,
                          fontSize: 11,
                          fontWeight: FontWeight.w500),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(dateStr,
                  style: TextStyle(
                      color: ts,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'monospace')),
            ],
          ),
        ],
      ),
    );
  }
}
