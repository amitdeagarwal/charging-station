import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_background/flutter_background.dart';
import 'package:flutter/services.dart'; // Import for MethodChannel
import 'dart:async';
import 'dart:math';

const double radius = 50000; // 50 km in meters

// Locations for charging points
const LatLng darmstadt = LatLng(49.8728, 8.6512);
const LatLng mannheim = LatLng(49.4875, 8.4647);
const LatLng heidelburg = LatLng(49.398348, 8.672433);
const LatLng muenchen = LatLng(48.1351, 11.5820);

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
  runApp(MyApp());
}

Future<bool> _checkAndRequestPermissions() async {
  final status = await Permission.ignoreBatteryOptimizations.status;

  if (!status.isGranted) {
    final result = await Permission.ignoreBatteryOptimizations.request();
    if (!result.isGranted) {
      // Use platform channels to open the battery optimization settings
      final platform = MethodChannel('com.example.yourapp/battery_optimizations');
      await platform.invokeMethod('openBatteryOptimizationSettings');
      return false;
    }
  }
  return true;
}

Future<void> initNotifications() async {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('app_icon');
  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final Set<Marker> _markers = {};
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
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
    _markers.add(Marker(
      markerId: MarkerId('darmstadt'),
      position: darmstadt,
      infoWindow: InfoWindow(title: 'Darmstadt'),
    ));
    _markers.add(Marker(
      markerId: MarkerId('mannheim'),
      position: mannheim,
      infoWindow: InfoWindow(title: 'Mannheim'),
    ));
    _markers.add(Marker(
      markerId: MarkerId('heidelburg'),
      position: heidelburg,
      infoWindow: InfoWindow(title: 'Heidelburg'),
    ));
    _markers.add(Marker(
      markerId: MarkerId('muenchen'),
      position: muenchen,
      infoWindow: InfoWindow(title: 'Muenchen'),
    ));
  }

  void _startTracking() async {
    if (!_isTracking) {
      _isTracking = true;
      setState(() {
        _trackingStatus = 'Tracking is on';
      });
      await FlutterBackground.enableBackgroundExecution();
      _showNotification('Tracking started');
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
      _showNotification('Tracking stopped');
    }
  }

  Future<void> _showNotification(String message) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'your_channel_id',
      'your_channel_name',
      importance: Importance.max,
      priority: Priority.high,
    );
    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );
    await _flutterLocalNotificationsPlugin.show(
      0,
      'Location Tracker',
      message,
      platformChannelSpecifics,
      payload: 'item x',
    );
  }

  void _checkProximity() {
    final LatLng currentLocation = LatLng(49.8728, 8.6512); // Example current location

    List<LatLng> chargingPoints = [darmstadt, mannheim, heidelburg, muenchen];
    for (LatLng point in chargingPoints) {
      double distance = _calculateDistance(currentLocation, point);
      if (distance < radius) {
        _showNotification('You are near ${point.toString()}');
        if (point == muenchen) {
          _stopTracking(); // Stop tracking if you reach the final point
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
