import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

/// Complete alert pipeline: MQTT (Jetson) → Firebase → UI
///
/// DEBUG MODE: Subscribes to ALL topics (#) to discover what your Jetson publishes.
/// Check your app logs for "MQTT TOPIC:" lines to find the correct topic names.
class AlertListenerService {
  static final AlertListenerService _instance = AlertListenerService._internal();
  factory AlertListenerService() => _instance;
  AlertListenerService._internal();

  // Live alert notifiers — UI listens to these
  final ValueNotifier<Map<String, dynamic>?> latestAlert =
      ValueNotifier<Map<String, dynamic>?>(null);
  final ValueNotifier<Map<String, dynamic>?> latestVehicleAlert =
      ValueNotifier<Map<String, dynamic>?>(null);

  // Connection status
  final ValueNotifier<bool> mqttConnected = ValueNotifier<bool>(false);
  final ValueNotifier<bool> firebaseConnected = ValueNotifier<bool>(false);

  bool _initialized = false;
  MqttServerClient? _mqttClient;
  StreamSubscription? _firebaseDmsSub;
  StreamSubscription? _firebaseFcwSub;

  // Deduplication state
  String? _lastAlertId;
  DateTime? _lastAlertTime;

  // ══════════════════════════════════════════════════════════════════════
  // ⚙️  CONFIGURATION — UPDATE THESE TO MATCH YOUR JETSON
  // ══════════════════════════════════════════════════════════════════════
  static const String _mqttBroker = '192.168.137.27';
  static const int _mqttPort = 1883;

  // Subscribe to ALL topics to discover what your Jetson publishes
  // Once you find the correct topics, replace '#' with the specific topic
  static const List<String> _subscribeTopics = [
    '#',                    // Wildcard: catches ALL messages (for debugging)
    // 'imas/dms/alerts',   // Uncomment once you know the correct DMS topic
    // 'imas/fcw/alerts',   // Uncomment once you know the correct FCW topic
  ];

  // Keywords to identify DMS vs FCW alerts
  static const _dmsKeywords = ['drowsy', 'sleepy', 'yawn', 'ear', 'mar', 'fatigue', 'dms', 'driver', 'blink', 'distract'];
  static const _fcwKeywords = ['collision', 'vehicle', 'distance', 'ttc', 'fcw', 'proximity', 'detection'];

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      debugPrint('⚠️ AlertListener: No authenticated user, skipping.');
      return;
    }

    debugPrint('🚀 AlertListener: Initializing...');
    _connectMqtt();
    _listenFirebaseRTDB();
  }

  // ═══════════════════════════════════════════════════════════════════════
  // MQTT CONNECTION
  // ═══════════════════════════════════════════════════════════════════════
  Future<void> _connectMqtt() async {
    try {
      final clientId = 'imas_flutter_${DateTime.now().millisecondsSinceEpoch}';
      _mqttClient = MqttServerClient(_mqttBroker, '');
      _mqttClient!.port = _mqttPort;
      _mqttClient!.keepAlivePeriod = 20;
      _mqttClient!.connectTimeoutPeriod = 10000; // Increased to 10s
      _mqttClient!.autoReconnect = true;
      _mqttClient!.logging(on: false);
      _mqttClient!.onConnected = _onMqttConnected;
      _mqttClient!.onDisconnected = _onMqttDisconnected;
      _mqttClient!.onAutoReconnect = () => debugPrint('🔄 MQTT: Reconnecting...');
      _mqttClient!.onAutoReconnected = () => debugPrint('✅ MQTT: Reconnected!');

      final connMessage = MqttConnectMessage()
          .withClientIdentifier(clientId)
          .startClean()
          .withWillQos(MqttQos.atMostOnce);
      _mqttClient!.connectionMessage = connMessage;

      debugPrint('🔌 MQTT: Connecting to $_mqttBroker:$_mqttPort...');
      await _mqttClient!.connect();
    } catch (e) {
      debugPrint('❌ MQTT: Connection FAILED — $e');
      debugPrint('   → Is Jetson ON and reachable at $_mqttBroker?');
      debugPrint('   → Is MQTT broker running on port $_mqttPort?');
      debugPrint('   → Is your phone on the same WiFi as Jetson?');
      mqttConnected.value = false;
    }
  }

  void _onMqttConnected() {
    debugPrint('✅ MQTT: Connected to $_mqttBroker:$_mqttPort');
    mqttConnected.value = true;

    // Subscribe to topics
    for (final topic in _subscribeTopics) {
      _mqttClient!.subscribe(topic, MqttQos.atMostOnce);
      debugPrint('📡 MQTT: Subscribed to "$topic"');
    }

    // Listen for ALL messages
    _mqttClient!.updates?.listen((List<MqttReceivedMessage<MqttMessage>> messages) {
      for (final msg in messages) {
        final payload = msg.payload as MqttPublishMessage;
        final text = MqttPublishPayload.bytesToStringAsString(payload.payload.message);

        // ════════════════════════════════════════════════════════════════
        // 🔍 DEBUG: Print every received message with its topic
        // ════════════════════════════════════════════════════════════════
        debugPrint('═══════════════════════════════════════');
        debugPrint('📨 MQTT TOPIC: "${msg.topic}"');
        debugPrint('📨 MQTT DATA:  $text');
        debugPrint('═══════════════════════════════════════');

        _processMessage(msg.topic, text);
      }
    });
  }

  void _onMqttDisconnected() {
    debugPrint('⚠️ MQTT: Disconnected from $_mqttBroker');
    mqttConnected.value = false;
  }

  // ═══════════════════════════════════════════════════════════════════════
  // MESSAGE PROCESSING — Auto-detects DMS vs FCW based on content
  // ═══════════════════════════════════════════════════════════════════════
  void _processMessage(String topic, String text) {
    try {
      // Try parsing as JSON
      Map<String, dynamic> data;
      try {
        data = jsonDecode(text) as Map<String, dynamic>;
      } catch (_) {
        data = {'alert_type': text.trim(), 'raw': true};
      }

      // ── DEDUPLICATION LOGIC ─────────────────────────────────────────
      // Use timestamp + alert_type to create a unique fingerprint
      final ts = data['timestamp']?.toString() ?? '';
      final type = data['alert_type']?.toString() ?? '';
      final fingerprint = '$ts|$type';

      if (fingerprint == _lastAlertId && 
          _lastAlertTime != null && 
          DateTime.now().difference(_lastAlertTime!).inMilliseconds < 800) {
        return; // Skip duplicate if within 800ms
      }
      _lastAlertId = fingerprint;
      _lastAlertTime = DateTime.now();
      // ───────────────────────────────────────────────────────────────

      final userId = FirebaseAuth.instance.currentUser?.uid;
      final topicLower = topic.toLowerCase();
      final textLower = text.toLowerCase();

      // Determine if this is a DMS or FCW alert
      bool isDms = false;
      bool isFcw = false;

      // Check topic name first
      if (topicLower.contains('dms') || topicLower.contains('driver') || topicLower.contains('drowsy')) {
        isDms = true;
      } else if (topicLower.contains('fcw') || topicLower.contains('vehicle') || topicLower.contains('collision')) {
        isFcw = true;
      } else {
        // Check message content for keywords
        for (final kw in _dmsKeywords) {
          if (textLower.contains(kw)) { isDms = true; break; }
        }
        if (!isDms) {
          for (final kw in _fcwKeywords) {
            if (textLower.contains(kw)) { isFcw = true; break; }
          }
        }
      }

      // Default to DMS if we can't determine
      if (!isDms && !isFcw) isDms = true;

      if (isDms) {
        debugPrint('🧠 Classified as DMS alert');
        latestAlert.value = data;
        _saveToRTDB('dms', data);
        if (userId != null) _saveToFirestoreHistory('dms_history', data, userId);
      } else {
        debugPrint('🚗 Classified as FCW alert');
        latestVehicleAlert.value = data;
        _saveToRTDB('fcw', data);
        if (userId != null) _saveToFirestoreHistory('fcw_history', data, userId);
      }
    } catch (e) {
      debugPrint('❌ MQTT: Process error — $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // FIREBASE RTDB — Save + Listen
  // ═══════════════════════════════════════════════════════════════════════
  void _saveToRTDB(String type, Map<String, dynamic> data) {
    try {
      FirebaseDatabase.instance.ref('imas/$type/latest').set({
        ...data,
        'timestamp': ServerValue.timestamp,
      });
      FirebaseDatabase.instance.ref('alerts').push().set({
        ...data,
        'type': type,
        'timestamp': ServerValue.timestamp,
      });
    } catch (e) {
      debugPrint('❌ RTDB: Save error — $e');
    }
  }

  void _listenFirebaseRTDB() {
    try {
      final dmsRef = FirebaseDatabase.instance.ref('imas/dms/latest');
      _firebaseDmsSub = dmsRef.onValue.listen(
        (event) {
          firebaseConnected.value = true;
          if (event.snapshot.value != null) {
            final data = Map<String, dynamic>.from(event.snapshot.value as Map);
            debugPrint('🔥 Firebase DMS update received');
            latestAlert.value = data;
          }
        },
        onError: (error) {
          debugPrint('❌ RTDB DMS: $error');
          firebaseConnected.value = false;
        },
      );

      final fcwRef = FirebaseDatabase.instance.ref('imas/fcw/latest');
      _firebaseFcwSub = fcwRef.onValue.listen(
        (event) {
          if (event.snapshot.value != null) {
            final data = Map<String, dynamic>.from(event.snapshot.value as Map);
            debugPrint('🔥 Firebase FCW update received');
            latestVehicleAlert.value = data;
          }
        },
        onError: (error) {
          debugPrint('❌ RTDB FCW: $error');
        },
      );
      debugPrint('🔥 Firebase RTDB: Listening...');
    } catch (e) {
      debugPrint('❌ RTDB: Setup error — $e');
      firebaseConnected.value = false;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // FIRESTORE — Save alert history
  // ═══════════════════════════════════════════════════════════════════════
  Future<void> _saveToFirestoreHistory(
      String collection, Map<String, dynamic> data, String userId) async {
    try {
      await FirebaseFirestore.instance.collection(collection).add({
        ...data,
        'userId': userId,
        'timestamp': FieldValue.serverTimestamp(),
        'severity': _determineSeverity(data),
        'type': _determineAlertType(data),
        'detail': _formatDetail(data),
      });
      debugPrint('✅ Firestore: Alert saved to $collection');
    } catch (e) {
      debugPrint('❌ Firestore: Save error — $e');
    }
  }

  String _determineSeverity(Map<String, dynamic> data) {
    final alertType = (data['alert_type'] ?? data['status'] ?? '').toString().toUpperCase();
    if (alertType.contains('SLEEP') || alertType.contains('COLLISION') ||
        alertType.contains('DANGER') || alertType.contains('CRITICAL')) {
      return 'Critical';
    } else if (alertType.contains('DROWSY') || alertType.contains('YAWN') ||
        alertType.contains('WARN') || alertType.contains('CLOSE')) {
      return 'Warning';
    }
    return 'Info';
  }

  String _determineAlertType(Map<String, dynamic> data) {
    final alertType = (data['alert_type'] ?? data['type'] ?? 'Alert').toString();
    switch (alertType.toUpperCase()) {
      case 'SLEEPY': case 'SLEEPING': return 'Drowsiness Detected';
      case 'YAWNING': return 'Driver Yawning';
      case 'DISTRACTED': return 'Driver Distracted';
      case 'COLLISION_WARNING': return 'Collision Warning';
      case 'VEHICLE_CLOSE': return 'Vehicle Too Close';
      default: return alertType;
    }
  }

  String _formatDetail(Map<String, dynamic> data) {
    final ear = data['ear'];
    final mar = data['mar'];
    final distance = data['distance'] ?? data['distance_m'];
    final parts = <String>[];
    if (ear != null) parts.add('EAR: ${(ear as num).toStringAsFixed(2)}');
    if (mar != null) parts.add('MAR: ${(mar as num).toStringAsFixed(2)}');
    if (distance != null) parts.add('Distance: ${(distance as num).toStringAsFixed(1)}m');
    return parts.isNotEmpty ? parts.join(' • ') : '';
  }

  void dispose() {
    _mqttClient?.disconnect();
    _firebaseDmsSub?.cancel();
    _firebaseFcwSub?.cancel();
    mqttConnected.value = false;
    firebaseConnected.value = false;
    _initialized = false;
  }
}
