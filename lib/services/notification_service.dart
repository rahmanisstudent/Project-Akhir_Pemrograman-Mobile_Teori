import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  // Buat instance plugin
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // --- 1. Inisialisasi Service ---
  Future<void> init() async {
    // Inisialisasi database timezone
    tz.initializeTimeZones();

    // Pengaturan untuk Android
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('app_icon');

    // Pengaturan untuk iOS
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings();

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsIOS,
        );

    // Jalankan inisialisasi plugin
    await _flutterLocalNotificationsPlugin.initialize(initializationSettings);

    // --- TAMBAHAN PENTING: MINTA IZIN ANDROID 13+ ---
    // (Kita harus minta izin 'postNotifications' secara manual)
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        _flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();

    await androidImplementation?.requestNotificationsPermission();
    // ------------------------------------------------
  }

  // --- 2. Fungsi untuk tes notifikasi (SEKARANG) ---
  Future<void> showTestNotification() async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'channel_id_test', // ID unik untuk channel
          'Notifikasi Tes', // Nama channel
          channelDescription: 'Channel untuk notifikasi tes',
          importance: Importance.max,
          priority: Priority.high,
        );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
    );

    // Tampilkan notifikasi
    await _flutterLocalNotificationsPlugin.show(
      0, // ID notifikasi
      'Tes Notifikasi PixelNomics', // Judul
      'Jika kamu melihat ini, notifikasi berhasil!', // Isi
      platformDetails,
    );
  }

  // --- 3. Fungsi untuk notifikasi harian (SYARAT PROYEK) ---
  Future<void> scheduleDailyNotification() async {
    // Setel zona waktu ke Waktu Indonesia Barat (WIB)
    final tz.Location wib = tz.getLocation('Asia/Jakarta');

    // Setel waktu notifikasi (misal: jam 8 pagi)
    tz.TZDateTime scheduledTime = tz.TZDateTime(
      wib,
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
      8, // Jam 8
      0, // Menit 0
    );

    // Jika jam 8 pagi ini sudah lewat, setel untuk besok
    if (scheduledTime.isBefore(DateTime.now())) {
      scheduledTime = scheduledTime.add(const Duration(days: 1));
    }

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'channel_id_daily',
          'Notifikasi Harian',
          channelDescription: 'Pengingat harian PixelNomics',
          importance: Importance.low, // Biar tidak mengganggu
          priority: Priority.low,
        );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
    );

    // Hapus notifikasi lama (jika ada) agar tidak menumpuk
    await _flutterLocalNotificationsPlugin.cancel(1); // ID 1 untuk harian

    // Jadwalkan notifikasi
    await _flutterLocalNotificationsPlugin.zonedSchedule(
      1, // ID notifikasi (berbeda dari tes)
      'Cek Harga Game Hari Ini!', // Judul
      'Kurs mata uang berfluktuasi. Jangan lupa cek wishlist-mu!', // Isi
      scheduledTime,
      platformDetails,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents:
          DateTimeComponents.time, // Ulangi setiap hari di jam yang sama
    );
  }
}
