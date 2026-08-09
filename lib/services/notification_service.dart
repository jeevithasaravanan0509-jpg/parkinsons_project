import 'package:flutter_local_notifications/flutter_local_notifications.dart';


class NotificationService {


  static final FlutterLocalNotificationsPlugin
      notifications =
      FlutterLocalNotificationsPlugin();



  static Future<void> initialize() async {


    const AndroidInitializationSettings
        androidSettings =
        AndroidInitializationSettings(
            '@mipmap/ic_launcher');


    const InitializationSettings settings =
        InitializationSettings(
      android: androidSettings,
    );


    await notifications.initialize(
      settings: settings,
    );

  }



  static Future<void> showNotification(
      String title,
      String body) async {


    const AndroidNotificationDetails
        androidDetails =
        AndroidNotificationDetails(

      'parkinson_care_channel',

      'Parkinson Care Notifications',

      channelDescription:
          'Notifications for Parkinson care reminders and updates',

      importance: Importance.high,

      priority: Priority.high,

    );


    const NotificationDetails details =
        NotificationDetails(
      android: androidDetails,
    );


    await notifications.show(

      id: 0,

      title: title,

      body: body,

      notificationDetails: details,

    );

  }

}