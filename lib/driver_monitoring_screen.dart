import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:http/http.dart' as http;
import 'ui_kit.dart';

class DriverMonitoringScreen extends StatefulWidget {
  final String? vehicleId;
  final String? driverName;
  final String? deviceId;

  const DriverMonitoringScreen({super.key, this.vehicleId, this.driverName, this.deviceId});

  @override
  State<DriverMonitoringScreen> createState() => _DriverMonitoringScreenState();
}

class _DriverMonitoringScreenState extends State<DriverMonitoringScreen> {
  final RTCVideoRenderer _renderer = RTCVideoRenderer();
  bool _videoReady = false;

  @override
  void initState() {
    super.initState();
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

    final url = "http://192.168.137.27:8889/dms/whep";
    final response = await http.post(Uri.parse(url));
    
    await pc.setRemoteDescription(RTCSessionDescription(response.body, 'offer'));
    
    final answer = await pc.createAnswer();
    await pc.setLocalDescription(answer);
    
    final localDescription = await pc.getLocalDescription();
    await http.patch(Uri.parse(url), body: localDescription?.sdp);
  }

  @override
  void dispose() {
    _renderer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? ImasColors.darkBg : Colors.white,
      appBar: AppBar(
        title: const Text('IMAS • DRIVER FEED'),
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
          ],
        ),
      ),
    );
  }
}
