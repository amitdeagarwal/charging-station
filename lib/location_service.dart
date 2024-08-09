import 'package:flutter_background/flutter_background.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';

class LocationService {
  final FlutterLocalNotificationsPlugin _notificationsPlugin;
  LocationService(this._notificationsPlugin);

  Future<void> startTracking() async {
    await FlutterBackground.initialize();
    await FlutterBackground.enableBackgroundExecution();
    
    Position? lastPosition;
    Geolocator.getPositionStream().listen((Position position) {
      lastPosition = position;
      _checkProximity(position);
    });
  }

  Future<void> stopTracking() async {
    await FlutterBackground.disableBackgroundExecution();
  }

  void _checkProximity(Position position) {
    const chargingPoints = [
      {'lat': 49.8728, 'lng': 8.6512, 'name': 'Darmstadt'},
      {'lat': 49.4875, 'lng': 8.4660, 'name': 'Mannheim'},
      {'lat': 49.398348, 'lng': 8.672433, 'name': 'Heidelburg'},
      {'lat': 48.1351, 'lng': 11.5820, 'name': 'Muchen'}
    ];

    for (var point in chargingPoints) {
      final distance = Geolocator.distanceBetween(
        position.latitude, position.longitude, point['lat'], point['lng']
      );
      
      if (distance < 50000) { // 50 km radius
        _showNotification('Proximity Alert', 'You are close to ${point['name']} charging point.');
        if (point['name'] == 'Muchen') { // Stop tracking if you reach Muchen
          stopTracking();
        }
      }
    }
  }

  Future<void> _showNotification(String title, String body) async {
    const androidPlatformChannelSpecifics = AndroidNotificationDetails(
        'your_channel_id', 'your_channel_name', 'your_channel_description',
        importance: Importance.max, priority: Priority.high);
    const iOSPlatformChannelSpecifics = IOSNotificationDetails();
    const platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics, iOS: iOSPlatformChannelSpecifics);
    
    await _notificationsPlugin.show(
        0, title, body, platformChannelSpecifics,
        payload: 'item x');
  }
}
