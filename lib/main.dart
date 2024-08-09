// main.dart

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_background/flutter_background.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:math';

import 'constants.dart'; // Import the constants
import 'notification_service.dart'; // Import the notification service

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final hasPermissions = await _checkAndRequestPermissions();

  if (hasPermissions) {
    await FlutterBackground.initialize(
      androidConfig: FlutterBackgroundAndroidConfig(
        notificationTitle: 'Tracking',
        notificationIcon: AndroidResource(name: 'app_icon', defType: 'drawable'),
      ),
    );
  }

  final notificationService = NotificationService();
  await notificationService.initNotifications();

  runApp(MyApp(notificationService: notificationService));
}

Future<bool> _checkAndRequestPermissions() async {
  final status = await Permission.ignoreBatteryOptimizations.status;

  if (!status.isGranted) {
    final result = await Permission.ignoreBatteryOptimizations.request();
    if (!result.isGranted) {
      final platform = MethodChannel('com.example.yourapp/battery_optimizations');
      await platform.invokeMethod('openBatteryOptimizationSettings');
      return false;
    }
  }
  return true;
}

class MyApp extends StatelessWidget {
  final NotificationService notificationService;

  MyApp({required this.notificationService});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Charging Points Tracker',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: HomePage(notificationService: notificationService),
    );
  }
}

class HomePage extends StatefulWidget {
  final NotificationService notificationService;

  HomePage({required this.notificationService});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final Set<Marker> _markers = {};
  bool _isTracking = false;
  String _trackingStatus = 'Tracking is off';

  @override
  void initState() {
    super.initState();
    _setMarkers();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final status = await Permission.locationWhenInUse.request();
    if (status.isDenied) {
      await Permission.locationWhenInUse.request();
    }
  }

  void _setMarkers() {
    _markers.addAll([
      Marker(
        markerId: MarkerId('darmstadt'),
        position: darmstadt,
        infoWindow: InfoWindow(title: 'Darmstadt'),
      ),
      Marker(
        markerId: MarkerId('mannheim'),
        position: mannheim,
        infoWindow: InfoWindow(title: 'Mannheim'),
      ),
      Marker(
        markerId: MarkerId('heidelburg'),
        position: heidelburg,
        infoWindow: InfoWindow(title: 'Heidelburg'),
      ),
      Marker(
        markerId: MarkerId('muenchen'),
        position: muenchen,
        infoWindow: InfoWindow(title: 'Muenchen'),
      ),
    ]);
  }

  void _startTracking() async {
    if (!_isTracking) {
      _isTracking = true;
      setState(() {
        _trackingStatus = 'Tracking is on';
      });
      await FlutterBackground.enableBackgroundExecution();
      widget.notificationService.showNotification('Tracking started');
      Timer.periodic(Duration(seconds: 5), (timer) {
        if (!_isTracking) {
          timer.cancel();
          return;
        }
        _checkProximity();
      });
    }
  }

  void _stopTracking() async {
    if (_isTracking) {
      _isTracking = false;
      setState(() {
        _trackingStatus = 'Tracking is off';
      });
      await FlutterBackground.disableBackgroundExecution();
      widget.notificationService.showNotification('Tracking stopped');
    }
  }

  void _checkProximity() {
    final LatLng currentLocation = LatLng(49.8728, 8.6512); // Example current location

    List<LatLng> chargingPoints = [darmstadt, mannheim, heidelburg, muenchen];
    for (LatLng point in chargingPoints) {
      double distance = _calculateDistance(currentLocation, point);
      if (distance < radius) {
        widget.notificationService.showNotification('You are near charging station $currentLocation');
        if (point == muenchen) {
          _stopTracking();
        }
        break;
      }
    }
  }

  double _calculateDistance(LatLng start, LatLng end) {
    const double earthRadius = 6371000; // meters
    double dLat = _toRadians(end.latitude - start.latitude);
    double dLon = _toRadians(end.longitude - start.longitude);
    double a =
        (sin(dLat / 2) * sin(dLat / 2)) +
        cos(_toRadians(start.latitude)) * cos(_toRadians(end.latitude)) *
        (sin(dLon / 2) * sin(dLon / 2));
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  double _toRadians(double degree) {
    return degree * (pi / 180.0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Charging Points Tracker'),
      ),
      body: Column(
        children: [
          SizedBox(height: 10),
          Text(
            _trackingStatus,
            style: TextStyle(fontSize: 18),
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              if (_isTracking) {
                _stopTracking();
              } else {
                _startTracking();
              }
            },
            child: Text(_isTracking ? 'Stop Tracking' : 'Start Tracking'),
          ),
          Expanded(
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: darmstadt,
                zoom: 10,
              ),
              markers: _markers,
              onMapCreated: (GoogleMapController controller) {
                // You can use this controller to manipulate the map
              },
            ),
          ),
        ],
      ),
    );
  }
}
