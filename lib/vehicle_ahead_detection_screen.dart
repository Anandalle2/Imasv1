import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:http/http.dart' as http;
import 'ui_kit.dart';

class VehicleAheadDetectionScreen extends StatefulWidget {
  final String? vehicleId;
  final String? driverName;
  final String? deviceId;

  const VehicleAheadDetectionScreen({super.key, this.vehicleId, this.driverName, this.deviceId});

  @override
  State<VehicleAheadDetectionScreen> createState() => _VehicleAheadDetectionScreenState();
}

class _VehicleAheadDetectionScreenState extends State<VehicleAheadDetectionScreen> with SingleTickerProviderStateMixin {
  final RTCVideoRenderer _renderer = RTCVideoRenderer();
  bool _videoReady = false;
  late AnimationController _radarController;

  @override
  void initState() {
    super.initState();
    _radarController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    initVideo();
  }

  Future<void> initVideo() async {
    await _renderer.initialize();
    await connectStream();
  }

  Future<void> connectStream() async {
    final pc = await createPeerConnection({'iceServers': [{'urls': 'stun:stun.l.google.com:19302'}]});
    
    pc.onTrack = (event) {
      if (mounted) {
        setState(() {
          _renderer.srcObject = event.streams[0];
          _videoReady = true;
        });
      }
    };

    final url = "http://192.168.137.27:8889/fcw/whep";
    final response = await http.post(Uri.parse(url));
    
    await pc.setRemoteDescription(RTCSessionDescription(response.body, 'offer'));
    
    final answer = await pc.createAnswer();
    // In Flutter 3.27+, setLocalDescription is still awaitable, 
    // but ensure we are using the correct SDP for the PATCH request.
    await pc.setLocalDescription(answer);
    
    final localDescription = await pc.getLocalDescription();
    await http.patch(Uri.parse(url), body: localDescription?.sdp);
  }

  @override
  void dispose() {
    _radarController.dispose();
    _renderer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? ImasColors.darkBg : Colors.white,
      appBar: AppBar(
        title: const Text('IMAS • FCW FEED'),
        backgroundColor: isDark ? ImasColors.darkBg : Colors.white,
        foregroundColor: isDark ? Colors.white : Colors.black,
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 250,
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isDark ? ImasColors.darkBorder : Colors.grey.shade300),
              ),
              clipBehavior: Clip.antiAlias,
              child: _videoReady 
                  ? RTCVideoView(_renderer, objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover)
                  : const Center(child: CircularProgressIndicator(color: ImasColors.cyan)),
            ),
            const SizedBox(height: 40),
            AnimatedBuilder(
              animation: _radarController,
              builder: (context, child) {
                return SizedBox(
                  height: 200,
                  width: 200,
                  child: CustomPaint(
                    painter: _RadarPainter(_radarController.value),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            Text(
              "PROXIMITY SCANNER",
              style: TextStyle(
                color: ImasColors.cyan.withAlpha(150),
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RadarPainter extends CustomPainter {
  final double angle;
  _RadarPainter(this.angle);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    
    final bgPaint = Paint()
      ..color = ImasColors.cyan.withAlpha(30)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    
    canvas.drawCircle(center, radius, bgPaint);
    canvas.drawCircle(center, radius * 0.6, bgPaint);
    canvas.drawCircle(center, radius * 0.3, bgPaint);

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle * 2 * math.pi);
    canvas.translate(-center.dx, -center.dy);

    final sweepPaint = Paint()
      ..shader = SweepGradient(
        colors: [ImasColors.cyan.withAlpha(0), ImasColors.cyan.withAlpha(150)],
        stops: const [0.7, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(center, radius, sweepPaint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_RadarPainter oldDelegate) => oldDelegate.angle != angle;
}
