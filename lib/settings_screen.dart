import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'theme_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _drivingMode = false;
  bool _hapticAlerts = true;
  bool _soundAlerts = true;
  bool _criticalOnly = false;
  bool _edgeAI = false;
  bool _autoConnect = true;
  String _sensitivity = 'Medium';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF060B14) : const Color(0xFFF4FBFC);
    final panel = isDark ? const Color(0xFF0E1520) : Colors.white;
    final accent = isDark ? const Color(0xFF00E5FF) : const Color(0xFF007685);
    final textPrimary = isDark ? Colors.white : const Color(0xFF0D1117);
    final textSub = isDark ? Colors.white54 : Colors.black54;
    final panelBorder = isDark ? Colors.white10 : Colors.black.withAlpha(12);
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      backgroundColor: bg,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            backgroundColor: bg,
            expandedHeight: 100,
            pinned: true,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios_new_rounded,
                  color: textPrimary, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              title: Text('SETTINGS',
                  style: TextStyle(
                      color: textPrimary,
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                      letterSpacing: 1.5)),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
              child: Column(children: [
                // Driving Mode
                _section('DRIVING MODE', Icons.drive_eta_rounded,
                    const Color(0xFF00E5FF), panel, panelBorder, textPrimary, textSub, [
                  _toggle('Auto Driving Mode', 'Auto-enable when vehicle moves',
                      _drivingMode, (v) {
                    HapticFeedback.lightImpact();
                    setState(() => _drivingMode = v);
                  }, accent, textPrimary, textSub),
                ]),
                const SizedBox(height: 16),

                // Alerts
                _section('ALERTS', Icons.notifications_rounded,
                    const Color(0xFFFF9F43), panel, panelBorder, textPrimary, textSub, [
                  _toggle('Haptic Feedback', 'Vibrate on critical alerts',
                      _hapticAlerts, (v) {
                    HapticFeedback.lightImpact();
                    setState(() => _hapticAlerts = v);
                  }, accent, textPrimary, textSub),
                  Divider(height: 1, color: panelBorder),
                  _toggle('Sound Alerts', 'Audible warnings for drowsiness',
                      _soundAlerts, (v) {
                    HapticFeedback.lightImpact();
                    setState(() => _soundAlerts = v);
                  }, accent, textPrimary, textSub),
                  Divider(height: 1, color: panelBorder),
                  _toggle('Critical Only', 'Filter non-critical alerts',
                      _criticalOnly, (v) {
                    HapticFeedback.lightImpact();
                    setState(() => _criticalOnly = v);
                  }, accent, textPrimary, textSub),
                ]),
                const SizedBox(height: 16),

                // AI & Features
                _section('AI & FEATURES', Icons.smart_toy_rounded,
                    const Color(0xFF7C4DFF), panel, panelBorder, textPrimary, textSub, [
                  _toggle('Edge AI Processing', 'Run AI models locally on Jetson',
                      _edgeAI, (v) {
                    HapticFeedback.lightImpact();
                    setState(() => _edgeAI = v);
                  }, accent, textPrimary, textSub,
                      badge: 'BETA'),
                  Divider(height: 1, color: panelBorder),
                  _dropdown('Detection Sensitivity', _sensitivity,
                      ['Low', 'Medium', 'High'], (v) {
                    HapticFeedback.lightImpact();
                    setState(() => _sensitivity = v!);
                  }, accent, textPrimary, textSub),
                ]),
                const SizedBox(height: 16),

                // Connectivity
                _section('CONNECTIVITY', Icons.wifi_rounded,
                    const Color(0xFF00E676), panel, panelBorder, textPrimary, textSub, [
                  _toggle('Auto Connect', 'Connect to Jetson on startup',
                      _autoConnect, (v) {
                    HapticFeedback.lightImpact();
                    setState(() => _autoConnect = v);
                  }, accent, textPrimary, textSub),
                ]),
                const SizedBox(height: 16),

                // Display
                _section('DISPLAY', Icons.palette_rounded,
                    const Color(0xFFFF3D5A), panel, panelBorder, textPrimary, textSub, [
                  _dropdown(
                    'Theme',
                    themeProvider.themeMode == ThemeMode.dark
                        ? 'Dark'
                        : (themeProvider.themeMode == ThemeMode.light
                            ? 'Light'
                            : 'System'),
                    ['Dark', 'Light', 'System'],
                    (v) {
                      HapticFeedback.lightImpact();
                      switch (v) {
                        case 'Dark':
                          themeProvider.setThemeMode(ThemeMode.dark);
                          break;
                        case 'Light':
                          themeProvider.setThemeMode(ThemeMode.light);
                          break;
                        case 'System':
                          themeProvider.setThemeMode(ThemeMode.system);
                          break;
                      }
                    },
                    accent,
                    textPrimary,
                    textSub,
                  ),
                ]),
                const SizedBox(height: 16),

                // About
                _section('ABOUT', Icons.info_outline_rounded,
                    accent, panel, panelBorder, textPrimary, textSub, [
                  ListTile(
                    title: Text('Version',
                        style: TextStyle(
                            color: textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600)),
                    trailing: Text('1.0.0',
                        style: TextStyle(
                            color: textSub,
                            fontSize: 13,
                            fontWeight: FontWeight.w600)),
                  ),
                ]),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _section(String title, IconData icon, Color color, Color panel,
      Color border, Color tp, Color ts, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: panel,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
            child: Row(children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 10),
              Text(title,
                  style: TextStyle(
                      color: color,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5)),
            ]),
          ),
          ...children,
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _toggle(String title, String sub, bool value,
      ValueChanged<bool> onChanged, Color accent, Color tp, Color ts,
      {String? badge}) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
      title: Row(children: [
        Text(title,
            style: TextStyle(
                color: tp, fontSize: 14, fontWeight: FontWeight.w600)),
        if (badge != null) ...[
          const SizedBox(width: 8),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.orangeAccent.withAlpha(20),
              borderRadius: BorderRadius.circular(4),
              border:
                  Border.all(color: Colors.orangeAccent.withAlpha(60)),
            ),
            child: Text(badge,
                style: const TextStyle(
                    color: Colors.orangeAccent,
                    fontSize: 8,
                    fontWeight: FontWeight.w900)),
          ),
        ],
      ]),
      subtitle: Text(sub,
          style: TextStyle(color: ts, fontSize: 11)),
      trailing:
          Switch(value: value, onChanged: onChanged, activeColor: accent),
    );
  }

  Widget _dropdown(String title, String value, List<String> items,
      ValueChanged<String?> onChanged, Color accent, Color tp, Color ts) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
      title: Text(title,
          style: TextStyle(
              color: tp, fontSize: 14, fontWeight: FontWeight.w600)),
      trailing: DropdownButton<String>(
        value: value,
        items: items
            .map((e) => DropdownMenuItem(
                value: e,
                child: Text(e,
                    style: TextStyle(color: tp, fontSize: 13))))
            .toList(),
        onChanged: onChanged,
        underline: const SizedBox(),
        dropdownColor:
            Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF0E1520)
                : Colors.white,
      ),
    );
  }
}
