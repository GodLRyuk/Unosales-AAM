import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unosfa/pages/Form/FormList/suppervisor_team_huddle_list.dart';
import 'package:unosfa/pages/services/api_service.dart';
import 'package:unosfa/widgetSupport/widgetstyle.dart';
import 'package:geolocator/geolocator.dart';

class SuppervisorHuddle extends StatefulWidget {
  final bool isView; // 🔹 Add parameter
  final String? id;

  SuppervisorHuddle({super.key, this.isView = false, this.id});
  @override
  State<SuppervisorHuddle> createState() => _DailyAgentPlanerState();
}

class _DailyAgentPlanerState extends State<SuppervisorHuddle> {
  final totalAgent = TextEditingController();
  final attendedAgent = TextEditingController();
  final totalMeetingtargetDay = TextEditingController();
  final applicationTargetDay = TextEditingController();
  final additionalSupport = TextEditingController();
  final trainingRecomendation = TextEditingController();
  double? _latitude;
  double? _longitude;

  List<int> _locationBlocks = [];
  List<LatLng?> _selectedLocations = [];
  bool _loadingCurrentLocation = true;
  LatLng? _currentLocation;
  // ignore: unused_field
  bool _isLoading = false;
  String _currentAddress = "";
  Map<String, dynamic> leadDetails = {};
  String startTime = "";

  @override
  void initState() {
    super.initState();
    DateTime now = DateTime.now();
    setState(() {
      startTime = now.toIso8601String();
    });
    _fetchCurrentLocation();
    if (widget.id != null) {
      _featchData();
    }
  }

  Future<void> _featchData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('accessToken');

    String apiUrl1 = "/api/timesheet/supervisor-team-huddles/${widget.id}/";
    final headers = {
      'Authorization': 'Bearer $token',
      'User-Agent':
          'Mozilla/5.0 (Linux; Android 11; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36',
    };

    final response = await ApiService.getWithHeaders(apiUrl1, headers);
    if (response != null && response.statusCode == 200) {
      final decoded = json.decode(response.data);

      // print(decoded);
      // print(decoded['live_agents_count']);
      setState(() {
        totalAgent.text = decoded['live_agents_count'].toString();
        attendedAgent.text = decoded['agents_attended_meeting'].toString();
        totalMeetingtargetDay.text = decoded['total_meeting_target'].toString();
        applicationTargetDay.text =
            decoded['total_application_target'].toString();
        additionalSupport.text = decoded['additional_support_needed'] ?? '';
        trainingRecomendation.text = decoded['training_recommendation'] ?? '';
      });
    }
  }

  Future<void> _fetchCurrentLocation() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Location permission denied")),
        );
        return; // Stop here if still denied
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Enable location permission from settings")),
      );
      return;
    }
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      _latitude = position.latitude;
      _longitude = position.longitude;
      _currentLocation = LatLng(_latitude!, _longitude!);

      List<Placemark> placemarks =
          await placemarkFromCoordinates(_latitude!, _longitude!);

      String address = "";
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        address =
            "${place.name}, ${place.locality}, ${place.administrativeArea}, ${place.country}";
      }

      setState(() {
        _loadingCurrentLocation = false;
        _currentAddress = address;

        if (_locationBlocks.isEmpty) {
          _locationBlocks.add(0);
          _selectedLocations.add(_currentLocation);
        }
      });
    } catch (e) {
      setState(() {
        _loadingCurrentLocation = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Could not get current location")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // resizeToAvoidBottomInset: false,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60.0),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFc433e0), Color(0xFF9a37ae)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('images/logo.PNG', height: 30),
                const SizedBox(width: 50),
              ],
            ),
            centerTitle: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (context) => SuppervisorHuddleList()),
                );
              },
            ),
          ),
        ),
      ),
      body: _loadingCurrentLocation
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Text(
                      "Suppervisor - Team Huddle".toUpperCase(),
                      style: WidgetSupport.HeaderBoldBlack(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "Total Agent Present Today?",
                    style: WidgetSupport.Questionblack(),
                  ),
                  _buildTextField(totalAgent, "",
                      "Please Enter Total Agent Present Today", "totalAgent",
                      isNumeric: true, readOnly: widget.isView),
                  const SizedBox(height: 15),
                  Text(
                    "How many agents attended the meeting today?",
                    style: WidgetSupport.Questionblack(),
                  ),
                  _buildTextField(
                      attendedAgent,
                      "",
                      "Please Enter how many agents attended the meeting today?",
                      "attendedAgent",
                      isNumeric: true,
                      readOnly: widget.isView),
                  const SizedBox(height: 15),
                  Text(
                    "Total meeting target for the day including all agents?",
                    style: WidgetSupport.Questionblack(),
                  ),
                  _buildTextField(
                      totalMeetingtargetDay,
                      "",
                      "Please Enter Total meeting target for the day including all agents?",
                      "totalMeetingtargetDay",
                      isNumeric: true,
                      readOnly: widget.isView),
                  const SizedBox(height: 15),
                  Text(
                    "Application target for the day including all agents?",
                    style: WidgetSupport.Questionblack(),
                  ),
                  _buildTextField(
                      applicationTargetDay,
                      "",
                      "Please Enter Application target for the day including all agents?",
                      "applicationTargetDay",
                      isNumeric: true,
                      readOnly: widget.isView),
                  const SizedBox(height: 15),
                  Text(
                    "Any additional support needed?",
                    style: WidgetSupport.Questionblack(),
                  ),
                  _buildTextField(
                      additionalSupport,
                      "",
                      "Please Any additional support needed?",
                      "additionalSupport",
                      readOnly: widget.isView),
                  const SizedBox(height: 15),
                  Text(
                    "Any training recomendation for Agents?",
                    style: WidgetSupport.Questionblack(),
                  ),
                  _buildTextField(
                      trainingRecomendation,
                      "",
                      "Please training recomendation for Agents?",
                      "trainingRecomendation",
                      readOnly: widget.isView),
                  const SizedBox(height: 10),
                  // Inside your build method where you build the button container:
                  if (widget.id == null)
                    Container(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              leadSubmit();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              padding: EdgeInsets.symmetric(
                                horizontal:
                                    MediaQuery.of(context).size.width * 0.1,
                                vertical:
                                    MediaQuery.of(context).size.height * 0.01,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                            ),
                            child: Text(
                              "Submit".toUpperCase(),
                              style: WidgetSupport.LoginButtonTextColor(),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    const SizedBox
                        .shrink(), // 👈 if id is not null, hide button
                ],
              ),
            ),
    );
  }

  Future<void> leadSubmit() async {
    setState(() {
      _loadingCurrentLocation=true;
    });
    // Trim all text fields
    String total_agent = totalAgent.text.trim();
    String attended_agent = attendedAgent.text.trim();
    String total_meeting_target_day = totalMeetingtargetDay.text.trim();
    String application_target_day = applicationTargetDay.text.trim();
    String additional_support = additionalSupport.text.trim();
    String training_recomendation = trainingRecomendation.text.trim();

    // 🔹 Validate fields before submitting
    if (total_agent.isEmpty ||
        attended_agent.isEmpty ||
        total_meeting_target_day.isEmpty ||
        application_target_day.isEmpty ||
        additional_support.isEmpty ||
        training_recomendation.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please fill all fields before submitting"),
          backgroundColor: Colors.red,
        ),
      );
      return; // Stop execution
    }

    // 🔹 Validate location as well
    if (_latitude == null || _longitude == null || _currentAddress.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Unable to fetch location. Please try again."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // 🔹 If all good, continue submitting
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('accessToken');
    DateTime now = DateTime.now();
    String ended_at = now.toIso8601String();
    Map<String, String> mappedData = {
      'live_agents_count': total_agent,
      'agents_attended_meeting': attended_agent,
      'total_meeting_target': total_meeting_target_day,
      'total_application_target': application_target_day,
      'additional_support_needed': additional_support,
      'training_recommendation': training_recomendation,
      'location_name': _currentAddress,
      'latitude': _latitude?.toStringAsFixed(10) ?? '00.00',
      'longitude': _longitude?.toStringAsFixed(10) ?? '00.00',
      'started_at': startTime,
      'ended_at': ended_at,
    };

    var url = '/api/timesheet/supervisor-team-huddles/';
    final headers = {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      'User-Agent':
          'Mozilla/5.0 (Linux; Android 11; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36',
    };
    try {
      final response =
          await ApiService.postJsonWithHeaders(url, mappedData, headers);
      if (response != null && (response.statusCode == 201)) {
        // ✅ Show success dialog
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text("Application"),
              content: const Text(
                "Form Submitted Successfully",
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SuppervisorHuddleList(),
                    ),
                  );
                  },
                  child: const Text("OK"),
                ),
              ],
            );
          },
        );
      } else if (response != null && response.statusCode == 401) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Session expired. Please login again.")),
        );
      }
    } catch (e) {
      setState(() {
        _loadingCurrentLocation = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("An error occurred: $e")),
      );
    }
    setState(() {
      _loadingCurrentLocation = false;
    });
  }

  Widget _buildTextField(
    TextEditingController controller,
    String hintText,
    String validationMessage,
    String validationKey, {
    IconData icon = FontAwesomeIcons.solidCircleUser,
    bool obscureText = false,
    bool isEmail = false,
    bool isPhoneNumber = false,
    bool isAlphabetic = false,
    bool isNumeric = false,
    bool allowSpaces = false,
    bool isReferralCode = false,
    bool readOnly = false,
  }) {
    // Actual field
    final field = TextFormField(
      controller: controller,
      readOnly: widget.isView, // still set to prevent editing via keyboard
      enabled: !widget.isView, // disables the field completely
      obscureText: obscureText,
      keyboardType: isPhoneNumber || isNumeric
          ? TextInputType.number
          : isEmail
              ? TextInputType.emailAddress
              : TextInputType.text,
      inputFormatters: [
        if (isPhoneNumber || isNumeric) ...[
          FilteringTextInputFormatter.digitsOnly,
          if (isPhoneNumber) LengthLimitingTextInputFormatter(12),
        ],
        if (isAlphabetic)
          FilteringTextInputFormatter.allow(
              allowSpaces ? RegExp(r'^[a-zA-Z\s]+$') : RegExp(r'^[a-zA-Z]+$')),
        if (isReferralCode)
          FilteringTextInputFormatter.allow(RegExp(r'^[a-zA-Z0-9]+$')),
      ],
      decoration: InputDecoration(
        label: Text(hintText, style: WidgetSupport.inputLabel()),
        suffixIcon: Padding(
          padding: const EdgeInsets.all(0),
          child: Icon(icon, color: Colors.purple, size: 15),
        ),
        // Grayed-out style for read-only
        filled: widget.isView,
        fillColor: widget.isView ? Colors.grey.shade200 : null,
      ),
    );

    // Prevent any taps when view mode is on
    if (widget.isView) {
      return IgnorePointer(child: field); // No clicks, no focus
    } else {
      return field;
    }
  }
}
