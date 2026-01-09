import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:unosfa/pages/generalscreens/entrypage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unosfa/pages/generalscreens/profileUpdate.dart';
import 'package:unosfa/pages/services/api_service.dart';
import 'package:unosfa/widgetSupport/widgetstyle.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String appVersion ="";
  String appCode = "";
  List<String>? userInfo;
  Map<String, dynamic> userData = {};

  LatLng _currentPosition = LatLng(0.0, 0.0);
  LatLng _currentLocation = LatLng(00, 00);

  bool _isLoading = false;
  double? _latitude;
  double? _longitude;
  String _currentAddress = "";

  @override
  void initState() {
    super.initState();
    _loadData();
    loadVersion();
  }

  Future<void> loadVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final cleanVersion = packageInfo.version.split('-').first;
    setState(() {
      appVersion ='Version $cleanVersion';
      appCode ='Code ${packageInfo.buildNumber}';
    });      
    } catch (e) {
      print("catch error $e");
    }
   
  }

  Future<void> _loadData() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('accessToken');
      String apiUrl = '/api/users/profile/';
      final headers = {
        'Authorization': 'Bearer $token',
        'User-Agent':
            'Mozilla/5.0 (Linux; Android 11; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36',
      };
      final response = await ApiService.getWithHeaders(apiUrl, headers);

      if (response != null && response.statusCode == 200) {
        setState(() {
          userData = json.decode(response.body);
        });
      } else {
        print("Profile load failed: ${response?.statusCode}");
      }
    } catch (e) {
      print("Error in _loadData: $e");
    }
  }

  String capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  /// Get current location
  Future<void> getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
      });
    } catch (e) {
      print("Error getting location: $e");
    }
  }

  /// Retain only tour-related preferences
  Future<void> clearPrefsExceptTours() async {
    final prefs = await SharedPreferences.getInstance();

    bool? saveTourStatus = prefs.getBool("saveTour");
    bool? saveFRTourStatus = prefs.getBool("saveFRTour");
    bool? saveLeadDashboardTourStatus = prefs.getBool("saveLeadDashboardTour");
    bool? saveFRLeadDashboardTourStatus =
        prefs.getBool("saveFRLeadDashboardTour");

    for (String key in prefs.getKeys()) {
      if (key != "saveTour" &&
          key != "saveFRTour" &&
          key != "saveLeadDashboardTour" &&
          key != "saveFRLeadDashboardTour") {
        await prefs.remove(key);
      }
    }

    if (saveTourStatus != null) await prefs.setBool("saveTour", saveTourStatus);
    if (saveFRTourStatus != null) {
      await prefs.setBool("saveFRTour", saveFRTourStatus);
    }
    if (saveLeadDashboardTourStatus != null) {
      await prefs.setBool("saveLeadDashboardTour", saveLeadDashboardTourStatus);
    }
    if (saveFRLeadDashboardTourStatus != null) {
      await prefs.setBool(
          "saveFRLeadDashboardTour", saveFRLeadDashboardTourStatus);
    }
  }

  /// Handles both Logout and Checkout
  Future<void> _handleLogout(BuildContext context,
      {bool isCheckout = false}) async {
    String message = isCheckout
        ? "Do you want to Check out and log out?"
        : "Do you want to log out?";

    bool? confirmAction = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Confirmation"),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(isCheckout ? "Check Out" : "Logout"),
            ),
          ],
        );
      },
    );

    if (confirmAction == true) {
      if (isCheckout) {
        setState(() {
          _isLoading = true; // 👈 show loader
        });
        await _checkoutApi();
        setState(() {
          _isLoading = false; // 👈 hide loader after API
        });
      }
      await clearPrefsExceptTours();

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const EntryPage()),
        (route) => false,
      );
    }
  }

  /// Checkout API call
  Future<void> _checkoutApi() async {
    print("Starting checkout…");
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Location permission denied")),
        );
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Enable location permission from settings")),
      );
      return;
    }

    // Get current location
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    _latitude = position.latitude;
    _longitude = position.longitude;
    _currentLocation = LatLng(position.latitude, position.longitude);

    // Reverse geocode safely
    String address = "";
    try {
      final placemarks = await placemarkFromCoordinates(
        _latitude!,
        _longitude!,
      ).timeout(const Duration(seconds: 5), onTimeout: () {
        debugPrint("Geocoding timeout – returning empty address");
        return <Placemark>[]; // fallback
      });

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        address =
            "${place.name}, ${place.locality}, ${place.administrativeArea}, ${place.country}";
      }
    } catch (e) {
      debugPrint("Reverse geocoding failed: $e");
      address = "";
    }

    setState(() {
      _currentAddress = address;
    });

    // Continue API call
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('accessToken');
      var checkInUrl = "/api/users/attendance/check-out/";

      final mapeddata = {
        // 'location': LatLng(position.latitude, position.longitude),
        'location_name': _currentAddress,
        'latitude': _latitude.toString(),
        'longitude': _longitude.toString(),
      };

      final headers = {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        "Content-Type": "application/json",
      };

      final response =
          await ApiService.postJsonWithHeaders(checkInUrl, mapeddata, headers);
    } catch (e) {
      debugPrint("Checkout API error: $e");
    }
  }

  Widget _infoRow(
      {required IconData icon, required String label, String? value}) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon),
            const SizedBox(width: 8),
            Text(label, style: WidgetSupport.labelTextsmall()),
            const Spacer(),
            Text(value ?? 'Not Available',
                style: WidgetSupport.personaldetailsText()),
          ],
        ),
        const Divider(
          color: Colors.grey,
          thickness: 1,
          height: 15,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60.0),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFFc433e0),
                Color(0xFF9a37ae),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: AppBar(
            automaticallyImplyLeading: false,
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Column(
                  children: [
                    Image.asset(
                      'images/logo.PNG',
                      height: 30,
                    ),
                  ],
                ),
                const SizedBox(width: 80),
                Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.logout),
                      onPressed: () =>
                          _handleLogout(context, isCheckout: false),
                    ),
                  ],
                ),
              ],
            ),
            centerTitle: true,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 15.0),
          child: Column(
            children: [
              Stack(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(0),
                        border: Border.all(
                          color: const Color(0xFF640D78),
                        )),
                    child: Row(
                      children: [
                        Image.asset(
                          "images/user.png",
                          width: 50,
                          height: 50,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${capitalize(userData['first_name'] ?? 'No First Name')} ${capitalize(userData['last_name'] ?? 'No Last Name')}',
                                style: const TextStyle(
                                    fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                              Text("ID: ${userData['username'] ?? ''}",
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: IconButton(
                      icon: const Icon(Icons.edit_note_rounded),
                      onPressed: () {
                        // Navigator.push(
                        //   context,
                        //   MaterialPageRoute(
                        //     builder: (context) => const ProfileUpdate(),
                        //   ),
                        // );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10.0),
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(0),
                    border: Border.all(
                      color: const Color(0xFF640D78),
                    )),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Personal Information".toUpperCase(),
                        style: WidgetSupport.titleTextPurple()),
                    const SizedBox(height: 7),
                    _infoRow(
                        icon: Icons.person,
                        label: "First Name",
                        value: capitalize(
                            userData['first_name'] ?? 'No First Name')),
                    _infoRow(
                        icon: Icons.person,
                        label: "Last Name",
                        value: capitalize(
                            userData['last_name'] ?? 'No Last Name')),
                    _infoRow(
                        icon: Icons.phone_android_outlined,
                        label: "Phone Number",
                        value: userData['phone_number'] ?? 'No Phone Number'),
                    _infoRow(
                        icon: Icons.email,
                        label: "Email",
                        value: userData['email'] ?? 'No Email'),
                    const SizedBox(height: 7),
                        Text("Right Quality Application Defination".toUpperCase(),
                        style: WidgetSupport.titleTextPurple()),
                    const SizedBox(height: 7),
                    Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.arrow_right, color: Color(0xFFa604ad), size: 25),
                          const SizedBox(width: 5),
                          Text(
                            "Age >21 and <60",
                            style: WidgetSupport.personaldetailsText(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.arrow_right, color: Color(0xFFa604ad), size: 25),
                          const SizedBox(width: 5),
                          Text(
                            "Location is part of Serviceable Zip codes",
                            style: WidgetSupport.personaldetailsText(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.arrow_right, color: Color(0xFFa604ad), size: 25),
                          const SizedBox(width: 5),
                          Text(
                            "Non-BPO 25K+ income",
                            style: WidgetSupport.personaldetailsText(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.arrow_right, color: Color(0xFFa604ad), size: 25),
                          const SizedBox(width: 5),
                          Text(
                            "BPO 40K+ income",
                            style: WidgetSupport.personaldetailsText(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.arrow_right, color: Color(0xFFa604ad), size: 25),
                          const SizedBox(width: 5),
                          Text(
                            "Bank Loan 25,000 or above",
                            style: WidgetSupport.personaldetailsText(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.arrow_right, color: Color(0xFFa604ad), size: 25),
                          const SizedBox(width: 5),
                          Text(
                            "Bank CC 25,000 limit or above",
                            style: WidgetSupport.personaldetailsText(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.arrow_right, color: Color(0xFFa604ad), size: 25),
                          const SizedBox(width: 5),
                          Text(
                            "Home Credit Loan 15,000 or above",
                            style: WidgetSupport.personaldetailsText(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.arrow_right, color: Color(0xFFa604ad), size: 25),
                          const SizedBox(width: 5),
                          Text(
                            "GLoan 15,000 or above",
                            style: WidgetSupport.personaldetailsText(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.arrow_right, color: Color(0xFFa604ad), size: 25),
                          const SizedBox(width: 5),
                          Text(
                            "Valid and complete Document",
                            style: WidgetSupport.personaldetailsText(),
                          ),
                        ],
                      ),
                    ],
                  )
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Container(
                height: 40,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFFc433e0),
                      Color(0xFF9a37ae),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 40, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                  child: _isLoading // 👈 show loading spinner instead of text
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          "CHECK OUT",
                          style: TextStyle(color: Colors.white, fontSize: 15),
                        ),
                  onPressed: _isLoading
                      ? null
                      : () => _handleLogout(context, isCheckout: true),
                ),
              ),

              SizedBox(height: MediaQuery.sizeOf(context).height *0.2,),
             
              Text("$appVersion", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),),
              SizedBox(height: MediaQuery.sizeOf(context).height *0.01,),

              Text("$appCode", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),),

            ],
          ),
        ),
      ),
    );
  }
}
