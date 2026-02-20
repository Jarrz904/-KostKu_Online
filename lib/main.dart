import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'landing_page.dart';
import 'user_dashboard.dart';
import 'admin_dashboard.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// Fungsi untuk menangani notifikasi saat aplikasi di background/tertutup
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint("Menangani pesan background: ${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Inisialisasi Firebase Messaging
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  // Inisialisasi plugin notifikasi secara global di level State
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Langsung update status saat app terbuka
    _updateStatus(true);

    _setupNotificationChannels();
    _initForegroundNotificationListener();
  }

  void _initForegroundNotificationListener() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;

      if (notification != null && android != null) {
        _localNotifications.show(
          id: notification.hashCode, // Tambahkan 'id:'
          title: notification.title, // Tambahkan 'title:'
          body: notification.body, // Tambahkan 'body:'
          notificationDetails: NotificationDetails(
            // Tambahkan 'notificationDetails:'
            android: AndroidNotificationDetails(
              'high_importance_channel',
              'Notifikasi Penting',
              channelDescription:
                  'Channel ini digunakan untuk notifikasi chat dan sistem.',
              importance: Importance.max,
              priority: Priority.high,
              icon: '@mipmap/ic_launcher',
              playSound: true,
              enableVibration: true,
            ),
          ),
        );
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint("Notifikasi diklik: ${message.data}");
    });
  }

  void _setupNotificationChannels() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel',
      'Notifikasi Penting',
      description: 'Channel ini digunakan untuk notifikasi chat dan sistem.',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      showBadge: true,
    );

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await _localNotifications.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse details) {
        debugPrint("Notifikasi diklik: ${details.payload}");
      },
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);
  }

  @override
  void dispose() {
    _updateStatus(false); // Pastikan offline saat app hancur
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Perbaikan: Tambahkan state inactive agar status lebih akurat
    if (state == AppLifecycleState.resumed) {
      _updateStatus(true);
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.inactive) {
      _updateStatus(false);
    }
  }

  void _updateStatus(bool isOnline) {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
            'is_online': isOnline,
            'is_active': isOnline,
            'last_online': FieldValue.serverTimestamp(),
            'last_seen':
                FieldValue.serverTimestamp(), // Field krusial untuk fitur admin
          })
          .catchError((e) => debugPrint("Gagal update status: $e"));
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Aplikasi KostKu',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blueAccent,
        fontFamily: 'Roboto',
      ),
      home: const LoadingSplashScreen(),
    );
  }
}

class LoadingSplashScreen extends StatefulWidget {
  const LoadingSplashScreen({super.key});

  @override
  State<LoadingSplashScreen> createState() => _LoadingSplashScreenState();
}

class _LoadingSplashScreenState extends State<LoadingSplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late Animation<double> _keyRotate;
  late Animation<double> _doorOpen;
  late Animation<double> _contentZoom;
  late Animation<double> _doorOpacity;

  @override
  void initState() {
    super.initState();

    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    );

    _keyRotate = Tween<double>(begin: 0, end: 0.5).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.3, curve: Curves.easeInOut),
      ),
    );

    _doorOpen = Tween<double>(begin: 0, end: -1.4).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.3, 0.6, curve: Curves.easeInCirc),
      ),
    );

    _contentZoom = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.5, 1.0, curve: Curves.fastOutSlowIn),
      ),
    );

    _doorOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.6, 0.8, curve: Curves.easeOut),
      ),
    );

    _mainController.forward();

    _mainController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _checkAuthAndNavigate();
      }
    });
  }

  void _checkAuthAndNavigate() async {
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      FirebaseMessaging messaging = FirebaseMessaging.instance;

      // Minta izin dan cek statusnya
      NotificationSettings settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      String? fcmToken;
      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        fcmToken = await messaging.getToken();
      }

      // Update data lengkap agar sinkron dengan Dashboard Admin
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
            'is_online': true,
            'is_active': true,
            'last_online': FieldValue.serverTimestamp(),
            'last_seen': FieldValue.serverTimestamp(),
            if (fcmToken != null) 'fcmToken': fcmToken,
          });

      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (mounted) {
        if (userDoc.exists) {
          String role = userDoc['role'] ?? 'user';
          _goToPage(
            role == 'admin' ? const AdminDashboard() : const UserDashboard(),
          );
        } else {
          _goToPage(const LandingPage());
        }
      }
    } else {
      if (mounted) _goToPage(const LandingPage());
    }
  }

  void _goToPage(Widget page) {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 1000),
        pageBuilder: (context, anim, _) =>
            FadeTransition(opacity: anim, child: page),
      ),
    );
  }

  @override
  void dispose() {
    _mainController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D47A1),
      body: AnimatedBuilder(
        animation: _mainController,
        builder: (context, child) {
          double dynamicOpacity = (_mainController.value > 0.4)
              ? ((_mainController.value - 0.4) * 2).clamp(0.0, 1.0)
              : 0.0;

          return Stack(
            alignment: Alignment.center,
            children: [
              Transform.scale(
                scale: _contentZoom.value,
                child: Opacity(
                  opacity: dynamicOpacity,
                  child: Container(
                    width: double.infinity,
                    height: double.infinity,
                    decoration: const BoxDecoration(
                      gradient: RadialGradient(
                        colors: [Color(0xFF42A5F5), Color(0xFF0D47A1)],
                        radius: 1.0,
                      ),
                    ),
                    child: const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.home_work_rounded,
                            size: 80,
                            color: Colors.white,
                          ),
                          SizedBox(height: 20),
                          Text(
                            "Selamat Datang di KostKu",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              if (_doorOpacity.value > 0.01)
                Opacity(
                  opacity: _doorOpacity.value.clamp(0.0, 1.0),
                  child: Transform(
                    alignment: Alignment.centerLeft,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.001)
                      ..rotateY(_doorOpen.value),
                    child: Container(
                      width: 250,
                      height: 400,
                      decoration: BoxDecoration(
                        color: Colors.brown[700],
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.brown[900]!, width: 8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.5),
                            blurRadius: 20,
                          ),
                        ],
                      ),
                      child: Stack(
                        alignment: Alignment.centerRight,
                        children: [
                          Positioned(
                            right: 20,
                            child: Column(
                              children: [
                                Container(
                                  width: 15,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: Colors.amber,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Transform.rotate(
                                  angle: _keyRotate.value * pi * 2,
                                  child: const Icon(
                                    Icons.vpn_key_rounded,
                                    color: Colors.amber,
                                    size: 40,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
