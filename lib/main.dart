import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:no_screenshot/no_screenshot.dart';
import 'package:unosfa/pages/config/config.dart';
import 'package:unosfa/pages/generalscreens/entrypage.dart';
import 'package:unosfa/pages/services/secret_key.dart';
import 'package:unosfa/pages/splash_screen.dart';
import 'package:firebase_core/firebase_core.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

final _noScreenshot = NoScreenshot.instance;

class SecureHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final client = super.createHttpClient(context);
    client.badCertificateCallback =
        (X509Certificate cert, String host, int port) => false;
    return client;
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const apiKey = String.fromEnvironment('GOOGLE_API_KEY');
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: apiKey,
      appId: '1:981376072634:android:60e1a67f6ad6375724bb83',
      messagingSenderId: '981376072634',
      projectId: 'unosales-1a493',
      storageBucket: 'unosales-1a493.firebasestorage.app',
    ),
  );
  await AppConfig.initSecurity();
  await enableSecurityChecks();

  AppConfig.certificateChecks = await setupSslKeys();
  if (AppConfig.isScreenshotDisabled) {
    print("Disabling screenshots...");
    await _noScreenshot.screenshotOff();
  } else {
    print("Enabling screenshots...");
    await _noScreenshot.screenshotOn(); // Explicitly allow screenshots
  }
  runApp(
    SessionTimeoutListener(
      duration: const Duration(minutes: 10),
      onTimeOut: () {
        navigatorKey.currentState?.pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const EntryPage()),
          (route) => false,
        );
      },
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      locale: const Locale('en', 'GB'),
      supportedLocales: const [Locale('en', 'IN')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      home: SplashScreen(),
    );
  }
}

class SessionTimeoutListener extends StatefulWidget {
  const SessionTimeoutListener({
    super.key,
    required this.child,
    required this.duration,
    required this.onTimeOut,
  });

  final Widget child;
  final Duration duration;
  final VoidCallback onTimeOut;

  @override
  State<SessionTimeoutListener> createState() => _SessionTimeoutListenerState();
}

class _SessionTimeoutListenerState extends State<SessionTimeoutListener> {
  Timer? _timer;

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer(widget.duration, () {
      widget.onTimeOut();
    });
  }

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) {
        _startTimer(); // Reset on user interaction
      },
      child: widget.child,
    );
  }
}
