import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unosfa/pages/Form/FormList/supervisor_intraday_call.dart';
import 'package:unosfa/pages/services/api_service.dart';
import 'package:unosfa/widgetSupport/widgetstyle.dart';
import 'package:geolocator/geolocator.dart';

class SuppervisorIntraDayCall extends StatefulWidget {
  final bool isView; // 🔹 Add parameter
  final String? id;

  SuppervisorIntraDayCall({super.key, this.isView = false, this.id});
  @override
  State<SuppervisorIntraDayCall> createState() => _DailyAgentPlanerState();
}

class _DailyAgentPlanerState extends State<SuppervisorIntraDayCall> {
  final inputAgentCode = TextEditingController();
  final mettingCompleted = TextEditingController();
  final applicationSubmitted = TextEditingController();
  final issueFaced = TextEditingController();
  final trainingRecomendation = TextEditingController();
  double? _latitude;
  double? _longitude;
  String startTime = "";
  String endTime = "";
  List<int> _locationBlocks = [];
  List<LatLng?> _selectedLocations = [];
  bool _loadingCurrentLocation = true;
  LatLng? _currentLocation;
  // ignore: unused_field
  bool _isLoading = false;
  String _currentAddress = "";
  @override
  void initState() {
    super.initState();
    _fetchCurrentLocation();
    DateTime now = DateTime.now();
    setState(() {
      startTime = now.toIso8601String();
    });
    if (widget.id != null) {
      _featchData();
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

  Future<void> _featchData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('accessToken');

    String apiUrl1 = "/api/timesheet/supervisor-intraday-calls/${widget.id}/";
    final headers = {
      'Authorization': 'Bearer $token',
      'User-Agent':
          'Mozilla/5.0 (Linux; Android 11; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36',
    };

    final response = await ApiService.getWithHeaders(apiUrl1, headers);
    if (response != null && response.statusCode == 200) {
      final decoded = json.decode(response.data);

      // print(decoded['live_agents_count']);
      setState(() {
        inputAgentCode.text = decoded['agent_code'].toString();
        mettingCompleted.text = decoded['meetings_conducted'].toString();
        applicationSubmitted.text = decoded['applications_submitted'].toString();
        issueFaced.text = decoded['issues_faced'].toString();
        trainingRecomendation.text = decoded['training_recommendation'] ?? '';
      });
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
                      builder: (context) => SuppervisorIntraDayList()),
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
                      "Suppervisor - Intraday Call".toUpperCase(),
                      style: WidgetSupport.HeaderBoldBlack(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "Agent's code for intraday call",
                    style: WidgetSupport.Questionblack(),
                  ),
                  _buildTextField(inputAgentCode, "",
                      "Please Enter Your Agent Code", "inputAgentCode",
                      isNumeric: false, readOnly: widget.isView,),
                  const SizedBox(height: 15),
                  Text(
                    "Meeting completed by the agent so far?",
                    style: WidgetSupport.Questionblack(),
                  ),
                  _buildTextField(
                      mettingCompleted,
                      "",
                      "Please Enter Meeting completed by the agent so far",
                      "mettingCompleted",
                      isNumeric: true,
                      readOnly: widget.isView),
                  const SizedBox(height: 15),
                  Text(
                    "Application submitted by the agent so far?",
                    style: WidgetSupport.Questionblack(),
                  ),
                  _buildTextField(
                      applicationSubmitted,
                      "",
                      "Please Enter Application submitted by the agent so far",
                      "applicationSubmitted",
                      isNumeric: true,
                      readOnly: widget.isView),
                  const SizedBox(height: 15),
                  Text(
                    "Issue faced by agent",
                    style: WidgetSupport.Questionblack(),
                  ),
                  _buildTextField(issueFaced, "",
                      "Please Enter Issue faced by agent", "issueFaced",
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
                  widget.isView!=true?
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
                  ):SizedBox.shrink(),
                ],
              ),
            ),
    );
  }

  Future<void> leadSubmit() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('accessToken');
    String agent_code = inputAgentCode.text.trim();
    String meeting_completed = mettingCompleted.text.trim();
    String application_submitred = applicationSubmitted.text.trim();
    String issue_faced = issueFaced.text.trim();
    String training_recomendation = trainingRecomendation.text.trim();

    if (agent_code.isEmpty ||
        meeting_completed.isEmpty ||
        application_submitred.isEmpty ||
        issue_faced.isEmpty ||
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
    DateTime now = DateTime.now();
    String ended_at = now.toIso8601String();
    Map<String, String> mappedData = {
      'agent_code': agent_code,
      'meetings_conducted': meeting_completed,
      'applications_submitted': application_submitred,
      'issues_faced': issue_faced,
      'training_recommendation': training_recomendation,
      'location_name': _currentAddress,
      'latitude': _latitude?.toStringAsFixed(10) ?? '00.00',
      'longitude': _longitude?.toStringAsFixed(10) ?? '00.00',
      'started_at': startTime,
      'ended_at': ended_at,
    };

    var url = '/api/timesheet/supervisor-intraday-calls/';
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
                    Navigator.of(context).pop();
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SuppervisorIntraDayList(),
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
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("An error occurred: $e")),
      );
    }

    setState(() {
      _isLoading = false;
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
