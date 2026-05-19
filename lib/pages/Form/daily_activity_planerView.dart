import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unosfa/pages/Form/FormList/daily_activity_report_list.dart';
import 'package:unosfa/pages/config/config.dart';
import 'package:unosfa/pages/services/api_service.dart';
import 'package:unosfa/widgetSupport/widgetstyle.dart';

class DailyActivityViewPage extends StatefulWidget {
  final String activityId;
  final String pageMode;

  const DailyActivityViewPage({Key? key, required this.activityId, required this.pageMode})
      : super(key: key);

  @override
  State<DailyActivityViewPage> createState() => _DailyActivityViewPageState();
}

class _DailyActivityViewPageState extends State<DailyActivityViewPage> {
  bool isLoading = true;
  bool hasError = false;
  final plannedMeeting = TextEditingController();
  final targetAplication = TextEditingController();
  List<LatLng> _locations = [];
  List<String> _addresses = [];
  String plannedMeetings = "";
  String targetApplications = "";
  String targetMeetingArea = "";
  String buddyAssigned = "";
  String buddyCode = "";
  bool step2 = true;
  List<dynamic> _apiLocations = [];
  int? selectedActivityId;
  List<Map<String, dynamic>> activityTypelist = [];
  int? selectedLocationId;
  List<Map<String, dynamic>> locationTypelist = [];
  final locationType = TextEditingController();
  final activityType = TextEditingController();
  String locationText= "";
  String activityText= "";
  @override
  void initState() {
    super.initState();
    fetchActivityData();
  }

  Future<void> fetchActivityData() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? token = prefs.getString('accessToken');

  final url = "/api/timesheet/agent-daily-activities/${widget.activityId}/";
  final headers = {
    'Authorization': 'Bearer $token',
    'User-Agent':
        'Mozilla/5.0 (Linux; Android 11; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36',
  };

  final response = await ApiService.getWithHeaders(url, headers);

  try {
    if (response != null && response.statusCode == 200) {
      final data = json.decode(response.data.body);
      if (data != null && data.isNotEmpty) {
        final List<dynamic> locations = data['assigned_locations'] ?? [];

        // Use a temporary list to avoid async setState chaos
        List<LatLng> tempLocations = [];
        List<String> tempAddresses = [];
        List<dynamic> enrichedLocations = [];

        for (var loc in locations) {
          double lat = double.tryParse(loc['lead_latitude'].toString()) ?? 0.0;
          double lng = double.tryParse(loc['lead_longitude'].toString()) ?? 0.0;

          // Fetch extra info for each location
          final locationDesc =
              await _getLocationTypeDescription(loc['location_type']);
          final activityDesc =
              await _getActivityTypeDescription(loc['activity']);

          // Merge data
          loc['locationText'] = locationDesc;
          loc['activityText'] = activityDesc;

          tempLocations.add(LatLng(lat, lng));
          tempAddresses.add(loc['lead_location_name'] ?? "Address not available");
          enrichedLocations.add(loc);
        }

        setState(() {
          plannedMeeting.text = data['meetings_planned']?.toString() ?? '';
          targetAplication.text = data['application_target']?.toString() ?? '';
          _locations = tempLocations;
          _addresses = tempAddresses;
          _apiLocations = enrichedLocations;
          isLoading = false;
        });
      }
    } else {
      hasError = true;
      isLoading = false;
    }
  } catch (e) {
    debugPrint("Error fetching activity data: $e");
    hasError = true;
    isLoading = false;
  }
  setState(() {});
}

Future<String> _getLocationTypeDescription(dynamic locid) async {
  if (locid == null) return "N/A";
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? token = prefs.getString('accessToken');

  try {
    final response = await http.get(
      Uri.parse('${AppConfig.dynamicBaseUrl}/api/leads/location-types/$locid/'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    if (response.statusCode == 200) {
      final Map<String, dynamic> body = jsonDecode(response.body);
      return body['description'] ?? 'N/A';
    }
  } catch (e) {
    debugPrint("Error loading location type: $e");
  }
  return "N/A";
}

Future<String> _getActivityTypeDescription(dynamic actid) async {
  if (actid == null) return "N/A";
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? token = prefs.getString('accessToken');

  try {
    final response = await http.get(
      Uri.parse('${AppConfig.dynamicBaseUrl}/api/leads/activities/$actid/'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    if (response.statusCode == 200) {
      final Map<String, dynamic> body = jsonDecode(response.data.body);
      return body['description'] ?? 'N/A';
    }
  } catch (e) {
    debugPrint("Error loading activity type: $e");
  }
  return "N/A";
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
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
                  MaterialPageRoute(builder: (context) => DailyActivityList()),
                );
              },
            ),
          ),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Text(
                      "Daily Activity Planner".toUpperCase(),
                      style: WidgetSupport.HeaderBoldBlack(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text("How many meetings planned for today?",
                      style: WidgetSupport.Questionblack()),
                  _buildTextField(
                    plannedMeeting,
                    "Meetings planned for today?",
                    "Please Enter Meetings planned for today?",
                    "meetingPlanned",
                    icon: Icons.meeting_room,
                    isNumeric: true,
                    readOnly: step2,
                  ),
                  const SizedBox(height: 15),
                  Text("What is your application target for the day?",
                      style: WidgetSupport.Questionblack()),
                  _buildTextField(
                    targetAplication,
                    "What is your application target for the day",
                    "Please Enter Application target for the day",
                    "targetAplication",
                    icon: Icons.app_registration,
                    isNumeric: true,
                    readOnly: step2,
                  ),
                  const SizedBox(height: 10),
                  const SizedBox(height: 10),

                  // 🗺️ Display Maps Below the 2 Fields
                  _locations.isNotEmpty
                      ? Column(
                          children: List.generate(_locations.length, (index) {
                            final loc = _locations[index];
                            final address = (index < _addresses.length)
                                ? _addresses[index]
                                : "Address not available";
                            return _buildMapCard(index, loc, address);
                          }),
                        )
                      : const Center(
                          child: Padding(
                            padding: EdgeInsets.only(top: 20),
                            child: Text(
                              "No assigned locations found.",
                              style: TextStyle(color: Colors.black54, fontSize: 16),
                            ),
                          ),
                        ),

                  const SizedBox(height: 20),

                  
                ],
              ),
            ),
    );
  }

  

  /// EACH LOCATION CARD WITH MAP
  Widget _buildMapCard(int index, LatLng loc, String address) {
    return Padding(
      padding: const EdgeInsets.only(top: 15),
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
              child: SizedBox(
                height: 200,
                width: double.infinity,
                child: GoogleMap(
                  initialCameraPosition: CameraPosition(target: loc, zoom: 15),
                  markers: {
                    Marker(
                      markerId: MarkerId('view_$index'),
                      position: loc,
                    )
                  },
                  zoomControlsEnabled: false,
                  myLocationEnabled: false,
                  myLocationButtonEnabled: false,
                  scrollGesturesEnabled: false,
                  zoomGesturesEnabled: false,
                  rotateGesturesEnabled: false,
                  tiltGesturesEnabled: false,
                  gestureRecognizers: {},
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("📍 Address: $address",
                      style: WidgetSupport.Questionblack()),
                  const SizedBox(height: 4),
                      if (index < _addresses.length)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 5),
                      Text("Buddy Code: ${_apiLocations[index]['buddy_code'] ?? 'N/A'}",
                          style: const TextStyle(color: Colors.black87)),
                      Text("Target Meetings: ${_apiLocations[index]['target_meetings'] ?? 'N/A'}",
                          style: const TextStyle(color: Colors.black87)),
                      Text("Location Type: ${_apiLocations[index]['locationText'] ?? 'N/A'}",
                      style: const TextStyle(color: Colors.black87)),
                      Text("Activity Type: ${_apiLocations[index]['activityText'] ?? 'N/A'}",
                      style: const TextStyle(color: Colors.black87)),

                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
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
    
    // bool isRequired = false,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      readOnly: readOnly,
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
        filled: true,
        fillColor: readOnly
            ? Colors.grey.shade200 // Light grey for read-only
            : Colors.transparent,
      ),
      // decoration: InputDecoration(
      //   label: Text(hintText, style: WidgetSupport.inputLabel()),
      //   suffixIcon: Padding(
      //     padding: const EdgeInsets.all(0),
      //     child: Icon(icon, color: Colors.purple, size: 15),
      //   ),
      // ),
    );
  }
  Widget _buildEmpActivityTypeDropdown({
    required TextEditingController controller,
    required String label,
    bool isRequired = true,
  }) {
    return DropdownButtonFormField<int>(
      value: selectedActivityId,
      items: activityTypelist
          .map((e) => DropdownMenuItem<int>(
                value: e['id'],
                child: Text(e['name']),
              ))
          .toList(),
      onChanged: (val) {
        setState(() {
          selectedActivityId = val;
        });
      },
      decoration: InputDecoration(
        label: isRequired
            ? RichText(
                text: TextSpan(
                  text: label,
                  style: WidgetSupport.inputLabel(),
                  children: const [
                    TextSpan(
                        text: ' *',
                        style: TextStyle(color: Colors.red, fontSize: 25))
                  ],
                ),
              )
            : Text(label, style: WidgetSupport.inputLabel()),
      ),
      validator: (value) {
        if (isRequired && value == null) {
          return "Please select $label";
        }
        return null;
      },
    );
  }

  Widget _buildLocationDropdown({
    required TextEditingController controller,
    required String label,
    bool isRequired = true,
  }) {
    return DropdownButtonFormField<int>(
      value: selectedLocationId,
      items: locationTypelist
          .map((e) => DropdownMenuItem<int>(
                value: e['id'],
                child: Text(e['name']),
              ))
          .toList(),
      onChanged: (val) {
        setState(() {
          selectedLocationId = val;
        });
      },
      decoration: InputDecoration(
        label: isRequired
            ? RichText(
                text: TextSpan(
                  text: label,
                  style: WidgetSupport.inputLabel(),
                  children: const [
                    TextSpan(
                        text: ' *',
                        style: TextStyle(color: Colors.red, fontSize: 25))
                  ],
                ),
              )
            : Text(label, style: WidgetSupport.inputLabel()),
      ),
      validator: (value) {
        if (isRequired && value == null) {
          return "Please select $label";
        }
        return null;
      },
    );
  }
}
