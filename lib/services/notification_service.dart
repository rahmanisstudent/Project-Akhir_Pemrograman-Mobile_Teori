import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz.initializeTimeZones();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('app_icon');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings();

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsIOS,
        );

    await _flutterLocalNotificationsPlugin.initialize(initializationSettings);

    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        _flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();

    await androidImplementation?.requestNotificationsPermission();
  }

  // tes notifikasi di profile
  Future<void> showTestNotification() async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'channel_id_test',
          'Notifikasi Tes',
          channelDescription: 'Channel untuk notifikasi tes',
          importance: Importance.max,
          priority: Priority.high,
        );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
    );

    await _flutterLocalNotificationsPlugin.show(
      0,
      'Tes Notifikasi PixelNomics',
      'Jika kamu melihat ini, notifikasi berhasil!',
      platformDetails,
    );
  }

  // notifikasi harian
  Future<void> scheduleDailyNotification() async {
    final tz.Location wib = tz.getLocation('Asia/Jakarta');

    tz.TZDateTime scheduledTime = tz.TZDateTime(
      wib,
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
      8, // Jam
      0, // Menit
    );

    // settingan kalau lewat, jadinya buat besok
    if (scheduledTime.isBefore(DateTime.now())) {
      scheduledTime = scheduledTime.add(const Duration(days: 1));
    }

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'channel_id_daily',
          'Notifikasi Harian',
          channelDescription: 'Pengingat harian PixelNomics',
          importance: Importance.low,
          priority: Priority.low,
        );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
    );

    // Hapus notifikasi lama
    await _flutterLocalNotificationsPlugin.cancel(1);

    await _flutterLocalNotificationsPlugin.zonedSchedule(
      1,
      'Cek Harga Game Hari Ini!',
      'Kurs mata uang berfluktuasi. Jangan lupa cek wishlist-mu!',
      scheduledTime,
      platformDetails,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }
}
