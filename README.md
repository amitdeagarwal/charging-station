main.dart Documentation
Overview
The main.dart file is the entry point for a Flutter application. It sets up the main app structure, handles initialization, and provides the UI components and business logic for the app. This file includes the main MyApp widget, which sets up the MaterialApp and initializes the core functionality.

File Structure
dart
Copy code
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:location/location.dart';
import 'dart:math';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;
  Location _location = Location();
  LocationData? _currentLocation;

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    _getCurrentLocation();
  }

  Future<void> _initializeNotifications() async {
    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    final InitializationSettings initializationSettings = InitializationSettings(android: initializationSettingsAndroid);
    
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future<void> _getCurrentLocation() async {
    try {
      _currentLocation = await _location.getLocation();
      _location.onLocationChanged.listen((LocationData locationData) {
        setState(() {
          _currentLocation = locationData;
        });
      });
    } catch (e) {
      print('Error getting location: $e');
    }
  }

  void _showNotification(String title, String body) async {
    const AndroidNotificationDetails androidNotificationDetails = AndroidNotificationDetails(
      'your_channel_id',
      'your_channel_name',
      'your_channel_description',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
    );
    const NotificationDetails notificationDetails = NotificationDetails(android: androidNotificationDetails);

    await flutterLocalNotificationsPlugin.show(
      0,
      title,
      body,
      notificationDetails,
    );
  }

  double _toRadians(double degree) => degree * (pi / 180.0);

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    final double dLat = _toRadians(lat2 - lat1);
    final double dLon = _toRadians(lon2 - lon1);
    final double a = (sin(dLat / 2) * sin(dLat / 2)) +
        (cos(_toRadians(lat1)) * cos(_toRadians(lat2)) *
        sin(dLon / 2) * sin(dLon / 2));
    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return 6371 * c; // Earth radius in kilometers
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: Text('Flutter Local Notifications'),
        ),
        body: Center(
          child: ElevatedButton(
            onPressed: () {
              _showNotification('Hello', 'This is a test notification');
            },
            child: Text('Show Notification'),
          ),
        ),
      ),
    );
  }
}
Key Components
Imports
package:flutter/material.dart: Provides the Material Design widgets and themes.
package:flutter_local_notifications/flutter_local_notifications.dart: Manages local notifications.
package:location/location.dart: Handles location services.
dart:math: Provides mathematical functions and constants.
Main Function
dart
Copy code
void main() => runApp(MyApp());
The main function initializes the app by running the MyApp widget.

MyApp Class
MyApp:

Extends StatefulWidget.
Creates the _MyAppState state class.
_MyAppState Class
State Initialization:

Initializes local notifications and retrieves the current location in initState.
Methods:

_initializeNotifications(): Configures local notifications.
_getCurrentLocation(): Fetches and updates the current location.
_showNotification(): Displays a notification.
_toRadians(double degree): Converts degrees to radians.
_calculateDistance(double lat1, double lon1, double lat2, double lon2): Calculates distance between two geographical points.
Build Method:

Returns a MaterialApp with a Scaffold containing an AppBar and a button to show notifications.
Error Handling
Location Errors: Logs errors related to location fetching.
Notification Errors: Assumes proper configuration; issues typically involve misconfiguration in notification details.
Notes
Ensure you have set up permissions for location and notifications in both AndroidManifest.xml and Info.plist (for iOS).
Customize notification details and color themes as per your application's requirements.
