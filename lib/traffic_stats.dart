import 'dart:async';
import 'package:flutter/services.dart';

// Data class to hold network speed data
class NetworkSpeedData {
  final int downloadSpeed;
  final int uploadSpeed;

  NetworkSpeedData({required this.downloadSpeed, required this.uploadSpeed});
}

// Service class for network speed monitoring
class NetworkSpeedService {
  // EventChannel for receiving network speed updates from the native side
  static const EventChannel _speedChannel = EventChannel('traffic_stats/network_speed');

  // StreamSubscription for managing the subscription to the EventChannel
  StreamSubscription? _subscription;

  // StreamController to broadcast network speed data to multiple listeners
  StreamController<NetworkSpeedData> _speedStreamController = StreamController<NetworkSpeedData>.broadcast();

  // Private constructor to ensure only one instance is created
  NetworkSpeedService._internal();

  // Singleton instance of the service
  static final NetworkSpeedService _instance = NetworkSpeedService._internal();

  // Factory constructor to return the singleton instance
  factory NetworkSpeedService() => _instance;

  // Validate and sanitize speed data
  NetworkSpeedData _validateSpeedData(Map<dynamic, dynamic> data) {
    int downloadSpeed = data['downloadSpeed'] ?? 0;
    int uploadSpeed = data['uploadSpeed'] ?? 0;

    // Ensure non-negative values
    downloadSpeed = downloadSpeed < 0 ? 0 : downloadSpeed;
    uploadSpeed = uploadSpeed < 0 ? 0 : uploadSpeed;

    // Cap extremely high values (likely measurement errors)
    const int maxReasonableSpeed = 1000000; // 1 Gbps in kbps
    downloadSpeed = downloadSpeed > maxReasonableSpeed ? 0 : downloadSpeed;
    uploadSpeed = uploadSpeed > maxReasonableSpeed ? 0 : uploadSpeed;

    return NetworkSpeedData(
      downloadSpeed: downloadSpeed,
      uploadSpeed: uploadSpeed,
    );
  }

  // Initialize the service and start listening to network speed updates
  void init() {
    // Dispose any existing subscription before initializing a new one
    dispose();

    _speedStreamController = StreamController<NetworkSpeedData>.broadcast();

    // Listen to the EventChannel and handle incoming data
    _subscription = _speedChannel.receiveBroadcastStream().listen((data) {
      try {
        // Parse and validate the incoming data
        NetworkSpeedData speedData = _validateSpeedData(data);

        // Add the validated data to the stream controller
        _speedStreamController.add(speedData);
      } catch (e) {
        // Handle parsing errors by sending zero values
        _speedStreamController.add(NetworkSpeedData(downloadSpeed: 0, uploadSpeed: 0));
      }
    }, onError: (error) {
      // Handle errors by adding them to the stream controller
      _speedStreamController.addError("Failed to get network speed: '$error'.");
    });
  }

  // Stream to allow listeners to receive network speed updates
  Stream<NetworkSpeedData> get speedStream => _speedStreamController.stream;

  // Dispose the service by closing the stream controller and cancelling the subscription
  void dispose() {
    _speedStreamController.close();
    _subscription?.cancel();
    _subscription = null;
  }
}
