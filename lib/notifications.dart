import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class Notifications {
  static final flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  static const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  static const InitializationSettings initializationSettings =
      InitializationSettings(android: initializationSettingsAndroid);

  static Future showRecordNotification({
    int id = 0,
    String? title,
    String? body,
  }) async {
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
    return await flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'Record',
          'Record',
          playSound: false,
          enableVibration: false,
          ongoing: true,
          autoCancel: false,
        ),
      ),
    );
  }

  static Future deleteNotification(int id) async {
    await flutterLocalNotificationsPlugin.cancel(id);
  }
}
