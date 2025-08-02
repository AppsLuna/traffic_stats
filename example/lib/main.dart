import 'package:flutter/material.dart';
import 'package:traffic_stats/traffic_stats.dart'; // Update this import based on your actual package path

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Network Speed Monitor',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: NetworkSpeedPage(),
    );
  }
}

class NetworkSpeedPage extends StatefulWidget {
  @override
  _NetworkSpeedPageState createState() => _NetworkSpeedPageState();
}

class _NetworkSpeedPageState extends State<NetworkSpeedPage> {
  final NetworkSpeedService _networkSpeedService = NetworkSpeedService();
  late Stream<NetworkSpeedData> _speedStream;
  late NetworkSpeedData _currentSpeed;

  @override
  void initState() {
    super.initState();
    _networkSpeedService.init(); // Initialize the service
    _speedStream = _networkSpeedService.speedStream;
    _currentSpeed = NetworkSpeedData(downloadSpeed: 0, uploadSpeed: 0);

    // Listen to the stream and update the state with new data
    _speedStream.listen((speedData) {
      setState(() {
        _currentSpeed = speedData;
      });
    });
  }

  @override
  void dispose() {
    _networkSpeedService.dispose(); // Dispose the service when the widget is disposed
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Network Speed Monitor'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'Download Speed: ${_currentSpeed.downloadSpeed} Kbps',
              style: TextStyle(fontSize: 20),
            ),
            SizedBox(height: 16),
            Text(
              'Upload Speed: ${_currentSpeed.uploadSpeed} Kbps',
              style: TextStyle(fontSize: 20),
            ),
          ],
        ),
      ),
    );
  }
}
