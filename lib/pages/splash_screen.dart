import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unosfa/pages/generalscreens/customNavigation.dart';
import 'package:unosfa/pages/generalscreens/entrypage.dart';
import 'package:unosfa/pages/services/secret_key.dart';
import 'package:unosfa/widgetSupport/widgetstyle.dart';

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

  // ── Same channel name must match CHANNEL in MainActivity.kt ──
  static const MethodChannel _channel = MethodChannel('com.UnoSales.unosfa');

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    _brandingcontroller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _unoAnimation = Tween<Offset>(
      begin: const Offset(0.0, -8.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _salesAnimation = Tween<Offset>(
      begin: const Offset(0.0, 8.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _brandingOpacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _brandingcontroller,
      curve: Curves.easeInOut,
    ));

    _controller.forward();
    _brandingcontroller.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _runAppLogic();
    });
  }

  // ════════════════════════════════════════════════════
  //  STEP 1 — Check if security is enabled via build flavor
  // ════════════════════════════════════════════════════
  Future<void> _runAppLogic() async {
    final String flavor =
        const String.fromEnvironment('FLAVOR', defaultValue: 'dev');

    final bool isProd = flavor == 'prod';
    final bool isScreenshotDisabled = isProd;
    final bool enableSecurityChecks = isProd;

    // Screenshot blocking can be wired up here using isScreenshotDisabled
    // (e.g. via FlutterWindowManager on Android) if/when that feature
    // is implemented.
    debugPrint(
        "🏳️ Flavor: $flavor | Screenshot disabled: $isScreenshotDisabled");

    if (enableSecurityChecks) {
      await _runSecurityChecks();
    } else {
      debugPrint("⚠️ Security checks disabled for development.");
      _navigateBasedOnLogin();
    }
  }

  // ════════════════════════════════════════════════════
  //  STEP 2 — Call each MethodChannel check from KT file
  // ════════════════════════════════════════════════════
  Future<void> _runSecurityChecks() async {
    bool isRooted = false;
    bool isEmulator = false;
    bool isDevMode = false;
    bool isMultiUser = false;
    bool isDebug = kDebugMode; // checked in Dart directly

    try {
      if (Platform.isAndroid) {
        // ── These map 1:1 to when() cases in MainActivity.kt ──
        // Calls isRooted() in KT
        isRooted = await _channel.invokeMethod<bool>('isRooted') ?? false;

        // Calls isEmulator() in KT
        isEmulator = await _channel.invokeMethod<bool>('isEmulator') ?? false;

        // Calls isDevMode() in KT
        isDevMode = await _channel.invokeMethod<bool>('isDevMode') ?? false;

        // Calls isMultiUserEnabled() in KT
        isMultiUser = await _channel.invokeMethod<bool>('isMultiUser') ?? false;

        debugPrint("🔒 Security Results:");
        debugPrint("   isRooted    : $isRooted");
        debugPrint("   isEmulator  : $isEmulator");
        debugPrint("   isDevMode   : $isDevMode");
        debugPrint("   isMultiUser : $isMultiUser");
        debugPrint("   isDebug     : $isDebug");
      }
    } on PlatformException catch (e) {
      // PlatformException = KT threw an error
      debugPrint("❌ PlatformException in security check: ${e.message}");
    } on MissingPluginException catch (e) {
      // MissingPluginException = channel name mismatch
      debugPrint("❌ MethodChannel not found: ${e.message}");
      debugPrint("   Check CHANNEL name matches in MainActivity.kt");
    } catch (e) {
      debugPrint("❌ Security check error: $e");
    }

    if (!mounted) return;

    // ── If ANY check fails → show alert, else navigate ──
    if (isRooted || isEmulator || isDevMode || isDebug || isMultiUser) {
      _showSecurityAlert(
        isRooted,
        isDevMode,
        isDebug,
        isEmulator,
        isMultiUser,
      );
    } else {
      _navigateBasedOnLogin();
    }
  }

  // ════════════════════════════════════════════════════
  //  STEP 3 — Navigate based on login state
  // ════════════════════════════════════════════════════
  Future<void> _navigateBasedOnLogin() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => isLoggedIn ? NavigationPage() : const EntryPage(),
      ),
    );
  }

  // ════════════════════════════════════════════════════
  //  STEP 4 — Show security alert
  // ════════════════════════════════════════════════════
  void _showSecurityAlert(
    bool rooted,
    bool devMode,
    bool debug,
    bool emulator,
    bool multiUser,
  ) {
    String issues = "";
    if (rooted) issues += "• Rooted / Jailbroken device\n";
    if (devMode) issues += "• Developer Mode Enabled\n";
    if (debug) issues += "• App running in Debug mode\n";
    if (emulator) issues += "• Running on Emulator\n";
    if (multiUser) issues += "• Multiple User / App Cloning Detected\n";

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => PopScope(
        canPop: false,
        child: AlertDialog(
          title: const Text("Security Alert"),
          content: Text(
            "This app cannot run on your device:\n\n$issues",
          ),
          actions: [
            TextButton(
              onPressed: () => SystemNavigator.pop(),
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
