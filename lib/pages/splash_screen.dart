import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unosfa/pages/config/config.dart';
import 'package:unosfa/pages/generalscreens/customNavigation.dart';
import 'package:unosfa/pages/generalscreens/entrypage.dart';
import 'package:unosfa/widgetSupport/widgetstyle.dart';

// final bool ENABLE_SECURITY_CHECKS = false;
final bool ENABLE_SECURITY_CHECKS = AppConfig.enableSecurityChecks;

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _brandingcontroller;
  late Animation<Offset> _unoAnimation;
  late Animation<Offset> _salesAnimation;
  late Animation<double> _brandingOpacity;

  static const MethodChannel _channel = MethodChannel('com.UnoSales.unosfa');

  @override
  void initState() {
    super.initState();

    // Setup animations
    _controller =
        AnimationController(duration: const Duration(seconds: 1), vsync: this);
    _brandingcontroller =
        AnimationController(duration: const Duration(seconds: 3), vsync: this);

    _unoAnimation = Tween<Offset>(
      begin: const Offset(0.0, -8.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _salesAnimation = Tween<Offset>(
      begin: const Offset(0.0, 8.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _brandingOpacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
        CurvedAnimation(parent: _brandingcontroller, curve: Curves.easeInOut));

    _controller.forward();
    _brandingcontroller.forward();

    // ✅ Run app logic after first frame to safely use context
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _runAppLogic();
    });
  }

  Future<void> _runAppLogic() async {
    if (ENABLE_SECURITY_CHECKS) {
      await _runSecurityChecks();
    } else {
      debugPrint("⚠️ Security checks disabled for development.");
      _navigateBasedOnLogin();
    }
  }

  Future<void> _runSecurityChecks() async {
    bool isRooted = false;
    bool isEmulator = false;
    bool isDevMode = false;
    bool isDebug = kDebugMode;
    bool isMultiUser = false;

    try {
      if (Platform.isAndroid) {
        isRooted = await _channel.invokeMethod('isRooted');
        isEmulator = await _channel.invokeMethod('isEmulator');
        isDevMode = await _channel.invokeMethod('isDevMode');
        isMultiUser = await _channel.invokeMethod('isMultiUser');
      }
    } catch (e) {
      debugPrint("Security check error: $e");
    }

    if (!mounted) return;

    if (isRooted || isDevMode || isDebug || isEmulator || isMultiUser) {
      _showSecurityAlert(isRooted, isDevMode, isDebug, isEmulator, isMultiUser);
    } else {
      _navigateBasedOnLogin();
    }
  }

  void _navigateBasedOnLogin() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

    if (!mounted) return;
    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (_) => isLoggedIn ? NavigationPage() : const EntryPage(),
    ));
  }

  void _showSecurityAlert(
    bool rooted,
    bool devMode,
    bool debug,
    bool emulator,
    bool multiUser,
  ) {
    String issues = "";
    if (rooted) issues += "• Rooted/Jailbroken\n";
    if (devMode) issues += "• Developer Mode Enabled\n";
    if (debug) issues += "• App running in Debug mode\n";
    if (emulator) issues += "• Running on Emulator\n";
    if (multiUser) issues += "• Multiple User / App Cloning Detected\n";

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => WillPopScope(
        onWillPop: () async => false,
        child: AlertDialog(
          title: const Text("Security Alert"),
          content: Text("Your device is not secure:\n\n$issues"),
          actions: [
            TextButton(
              onPressed: () {
                SystemNavigator.pop();
              },
              child: const Text("Exit"),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _brandingcontroller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SlideTransition(
                  position: _unoAnimation,
                  child: Image.asset(
                    "images/Uno1.PNG",
                    width: MediaQuery.of(context).size.width * 0.4,
                  ),
                ),
                const SizedBox(width: 10),
                Transform.translate(
                  offset: Offset(
                    MediaQuery.of(context).size.width > 600
                        ? (MediaQuery.of(context).orientation ==
                                Orientation.portrait
                            ? -14
                            : -97)
                        : (MediaQuery.of(context).orientation ==
                                Orientation.portrait
                            ? -12
                            : -16),
                    0,
                  ),
                  child: SlideTransition(
                    position: _salesAnimation,
                    child: Image.asset(
                      "images/sales1.PNG",
                      width: MediaQuery.of(context).size.width * 0.4,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 60),
            FadeTransition(
              opacity: _brandingOpacity,
              child: Column(
                children: [
                  Text("Powered by", style: WidgetSupport.btandingText()),
                  const SizedBox(height: 10),
                  Image.asset(
                    "images/branding.png",
                    width: MediaQuery.of(context).size.width * 0.15,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
