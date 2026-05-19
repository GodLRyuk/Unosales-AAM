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
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class DailyAgentPlaner extends StatefulWidget {
  final String pageMode;
  final String activityId;

  const DailyAgentPlaner({super.key, required this.pageMode, required this.activityId});

  @override
  State<DailyAgentPlaner> createState() => _DailyAgentPlanerState();
}

class _DailyAgentPlanerState extends State<DailyAgentPlaner> {
  final plannedMeeting = TextEditingController();
  final targetAplication = TextEditingController();
  final locationType = TextEditingController();
  final activityType = TextEditingController();
  final targetMeetingArea = TextEditingController();
  final buddyAssigned = TextEditingController();
  final buddyCode = TextEditingController();
  final agentCode = TextEditingController();
  final agency = TextEditingController();
  final supervisor = TextEditingController();
  final dateTime = TextEditingController();
  final location = TextEditingController();
  bool confirmLocation = false;

  double? _latitude;
  double? _longitude;
  List<double?> _latitudeFromMapList = [];
  List<double?> _longitudeFromMapList = [];
  List<String> _addressFromMapList = [];

  String _currentAddress = "";
  bool _showNextButton = false;
  bool _showFinalSaveButton = false;
  bool finalSaveDone = false;
  List<int> _locationBlocks = [];
  List<LatLng?> _selectedLocations = [];
  bool _loadingCurrentLocation = true;
  LatLng? _currentLocation; 
  Map<int, GoogleMapController> _mapControllers = {};
  String startTime = "";
  bool step2 = false;
  int? selectedActivityId;
  List<Map<String, dynamic>> activityTypelist = [];
  int? selectedLocationId;
  List<Map<String, dynamic>> locationTypelist = [];
  String daily_activity = "";
  bool isPageMode = false;
  bool isLoading = true;
  String addressFromMap="";
  double? _latitudeFromMap;
  double? _longitudeFromMap;
  List<bool> _isLocationSaved = [];

  @override
  void initState() {
    print(widget.pageMode);
    super.initState();

    DateTime now = DateTime.now();
    startTime = now.toIso8601String();

    if (widget.pageMode == 'view') {
      step2 = true;
      _showNextButton = false;
      loaddata();
    }
    else
    {
      loaddata();
    }

    _fetchCurrentLocation();
    _initializeActivityTypeList();
    _initializeLocationList();
  }

  Future<void> loaddata() async {
    
    setState(() {
      isLoading = true;
    });
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('accessToken');

    final headers = {
      'Authorization': 'Bearer $token',
      'User-Agent':
          'Mozilla/5.0 (Linux; Android 11; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36',
    };
      String apiUrl = "";
      if (widget.pageMode == 'view') {
           apiUrl = '/api/timesheet/agent-daily-activities/${widget.activityId}/';
      }
      else
      {
           apiUrl = '/api/timesheet/agent-daily-activities/';

      }
      final response = await ApiService.getWithHeaders(apiUrl, headers);
    try {
      if (response != null) {
        final data = json.decode(response.data);
        final locationData = data['assigned_locations'];

        plannedMeeting.text = data['meetings_planned']?.toString() ?? "";
        targetAplication.text = data['application_target']?.toString() ?? "";

        _locationBlocks.clear();
        _selectedLocations.clear();
        _latitudeFromMapList.clear();
        _longitudeFromMapList.clear();
        _addressFromMapList.clear();

        for (int i = 0; i < locationData.length; i++) {
          var loc = locationData[i];
          double lat = double.tryParse(loc['latitude'] ?? '0.0') ?? 0.0;
          double lng = double.tryParse(loc['longitude'] ?? '0.0') ?? 0.0;
          String address = loc['lead_location_name'] ?? '';
          _locationBlocks.add(i);
          _selectedLocations.add(LatLng(lat, lng));
          _latitudeFromMapList.add(lat);
          _longitudeFromMapList.add(lng);
          _addressFromMapList.add(address);
        }

        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching Activity: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _fetchCurrentLocation() async {
  setState(() {
    _loadingCurrentLocation = true; // show loader
  });

  LocationPermission permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Location permission denied")),
      );
      setState(() => _loadingCurrentLocation = false);
      return;
    }
  }

  if (permission == LocationPermission.deniedForever) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text("Enable location permission from settings")),
    );
    setState(() => _loadingCurrentLocation = false);
    return;
  }

  try {
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    _latitude = position.latitude;
    _longitude = position.longitude;
    _currentLocation = LatLng(_latitude!, _longitude!);

    String address = "";
    try {
      List<Placemark> placemarks =
          await placemarkFromCoordinates(_latitude!, _longitude!);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        address =
            "${place.name ?? ''}, ${place.locality ?? ''}, ${place.administrativeArea ?? ''}, ${place.country ?? ''}";
      }
    } catch (e) {
      debugPrint("Reverse geocoding failed: $e");
    }

    setState(() {
      _currentAddress = address;

      // Add first location safely
      if (_locationBlocks.isEmpty && _currentLocation != null) {
        _locationBlocks.add(0);
        _selectedLocations.add(_currentLocation!);
        _latitudeFromMapList.add(_currentLocation!.latitude);
        _longitudeFromMapList.add(_currentLocation!.longitude);
        _addressFromMapList.add(_currentAddress);
        _isLocationSaved.add(false);
      }

      _loadingCurrentLocation = false; // hide loader
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

  Future<void> _initializeActivityTypeList() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('accessToken');
    try {
      final response = await http.get(
        Uri.parse('${AppConfig.dynamicBaseUrl}/api/leads/activities/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseBody = jsonDecode(response.body);
        if (responseBody['results'] is List) {
          final List<dynamic> results = responseBody['results'];
          setState(() {
            activityTypelist = results.map<Map<String, dynamic>>((item) {
              return {
                'id': item['id'] ?? 0,
                'name': (item['description'] ?? item['name'] ?? '').toString(),
              };
            }).toList();
          });
        }
      }
    } catch (e) {
      debugPrint("Error loading Activity Type list: $e");
    }
  }

  Future<void> _initializeLocationList() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('accessToken');
    try {
      final response = await http.get(
        Uri.parse('${AppConfig.dynamicBaseUrl}/api/leads/location-types/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseBody = jsonDecode(response.body);
        if (responseBody['results'] is List) {
          final List<dynamic> results = responseBody['results'];
          setState(() {
            locationTypelist = results.map<Map<String, dynamic>>((item) {
              return {
                'id': item['id'] ?? 0,
                'name': (item['description'] ?? item['name'] ?? '').toString(),
              };
            }).toList();
          });
        }
      }
    } catch (e) {
      debugPrint("Error loading Location Type list: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        final shouldLeave = await _showExitConfirmationDialog(context);
        return shouldLeave ?? false;
      },
      child: Scaffold(
        resizeToAvoidBottomInset: true,
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
                onPressed: () async {
                  final shouldLeave = await _showExitConfirmationDialog(context);
                if (shouldLeave == true) {
                  Navigator.pop(context);
                }
                  // Navigator.pushReplacement(
                  //   context,
                  //   MaterialPageRoute(builder: (context) => DailyActivityList()),
                  // );
                },
              ),
            ),
          ),
        ),
        body: _loadingCurrentLocation || isLoading
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
                    _showFinalSaveButton!=true
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // ADD Button
                        
                        // NEXT Button
                        ElevatedButton(
                          onPressed: () {
                            DailyActivityStart();
                            // createMap();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                          ),
                          child: Text("Save".toUpperCase(), style: WidgetSupport.formBUttonBig()),
                        ),
                      ],
                    )
                  : 
                  Row(
                    children: [
                      ElevatedButton.icon(
                      onPressed: (_loadingCurrentLocation || _currentLocation == null)
                          ? null
                          : () {
                              setState(() {
                                int newIndex = _locationBlocks.length;
                                _locationBlocks.add(newIndex);
                                _selectedLocations.add(_currentLocation!);
                                _latitudeFromMapList.add(_currentLocation!.latitude);
                                _longitudeFromMapList.add(_currentLocation!.longitude);
                                _addressFromMapList.add(_currentAddress);
                                _isLocationSaved.add(false);
                                _showNextButton=true;
                              });
                            },
                            icon: const Icon(Icons.add_location_alt_outlined, color: Colors.white, size: 18),
                            label: Text("Add Location", style: WidgetSupport.formBUttonBig()),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                            ),
                          ),
                          
                    ],
                  ),
                    const SizedBox(height: 15),
                    
                    Column(
                            children: _showNextButton!=false ?_locationBlocks
                                .map((index) =>
                                    _buildLocationBlock(context, index, _selectedLocations[index]))
                                .toList(): [],
                          ),
                          _showNextButton==true ?Align(
                            alignment: Alignment.topCenter,
                            child: ElevatedButton.icon(
                            onPressed: () {
                              finalSaveDone==true ?showDialog(
                                context: context,
                                builder: (BuildContext dialogContext) {
                                  return AlertDialog(
                                    title: Text(
                                      "Thank You",
                                      style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                      color: Color(0xFFa604ad),                                  ),
                                      textAlign: TextAlign.center,
                                    ),
                                    content: Text(
                                      "Activity For Today is saved Successfully",
                                      style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: Colors.black,                                  ),
                                      textAlign: TextAlign.center,
                                    ),
                                    actions: [
                                      Center(
                                        child: TextButton(
                                          onPressed: () {
                                            // Navigator.of(dialogContext).pop();
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => DailyActivityList(),
                                              ),
                                            );
                                          },
                                          child: const Text("OK"),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ):
                              showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                title: Text(
                                  "Leave this page?",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: Color(0xFFa604ad),                                  ),
                                  textAlign: TextAlign.center,
                                  
                                ),
                                content: Text(
                                  "Are you sure you want to leave the page without saving the location?",
                                  style: WidgetSupport.inputLabel2(),
                                  textAlign: TextAlign.center,
                                ),
                                actionsAlignment: MainAxisAlignment.center,
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(context).pop(false); // Stay on page
                                    },
                                    child: const Text(
                                      "Cancel",
                                      style: TextStyle(color: Colors.black),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(context).pop(true); // Confirm exit
                                    },
                                    child: const Text(
                                      "Leave",
                                      style: TextStyle(color: Color(0xFFa604ad)),
                                    ),
                                  ),
                                ],
                              ),
                            );
                            },
                            icon: const Icon(
                              Icons.add_location_alt_outlined,
                              color: Colors.white,
                              size: 18,
                            ),
                            label: Text(
                              "Save",
                              style: WidgetSupport.formBUttonBig(),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                            ),
                                                  ),
                          ): const SizedBox.shrink(),
      
                  ],
                  
                ),
              ),
      ),
    );
  }

 Widget _buildLocationBlock(
    BuildContext context, int index, LatLng? selectedLocation) {
  LatLng loc = selectedLocation ?? _currentLocation!;

  return GestureDetector(
    onTap: () async {
      if (_isLocationSaved[index]) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("You already saved this location.")),
        );
        return; // prevent reopening edit mode
      }

      final LatLng? pickedLocation = await _openLocationModal(
        context,
        loc,
        initialAddress: addressFromMap.isNotEmpty
            ? addressFromMap
            : _currentAddress,
        index: index,
      );

      if (pickedLocation != null) {
        setState(() {
          _selectedLocations[index] = pickedLocation;
          _latitudeFromMap = pickedLocation.latitude;
          _longitudeFromMap = pickedLocation.longitude;

          // 👇 Mark location as saved
          _isLocationSaved[index] = true;
        });

        if (_mapControllers.containsKey(index)) {
          _mapControllers[index]!
              .animateCamera(CameraUpdate.newLatLngZoom(pickedLocation, 15));
        }
      }

    },
    child: Container(
      height: 200,
      width: double.infinity,
      margin: const EdgeInsets.only(top: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey[200],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            GoogleMap(
              initialCameraPosition: CameraPosition(target: loc, zoom: 15),
              markers: {Marker(markerId: MarkerId('loc$index'), position: loc)},
              onMapCreated: (controller) => _mapControllers[index] = controller,
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
            ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.touch_app,
                      size: 40, color: Color(0xFFa604ad)),
                  const SizedBox(height: 8),
                  Text(
                    _isLocationSaved[index]
                        ? "Location Already Saved"
                        : "Tap to select location",
                    style: const TextStyle(
                      color: Color(0xFFa604ad),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}



  ///====================== NEW UPDATED MODAL FUNCTION ======================///

  Future<LatLng?> _openLocationModal(
  BuildContext context,
  LatLng currentLatLng, {
  String? initialAddress,
  required int index,
}) async {
  // 1️⃣ Clear all old data
  setState(() {
    
    activityType.clear();
    targetMeetingArea.clear();
    buddyAssigned.clear();
    buddyCode.clear();
    addressFromMap = '';
    confirmLocation = false;
    _latitudeFromMap = 0.0;
    _longitudeFromMap = 0.0;
    selectedLocationId = null;
    selectedActivityId = null;
    if (_isLocationSaved.length > index) {
      _isLocationSaved[index] = false;
    }
  });

  // 2️⃣ Show temporary loader while APIs fetch
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => const Center(child: CircularProgressIndicator()),
  );

  // 3️⃣ Fetch dropdown data before showing the form
  await Future.wait([
    _initializeActivityTypeList(),
    _initializeLocationList(),
  ]);

  // 4️⃣ Close loader
  Navigator.pop(context);

  // 5️⃣ Setup local modal variables
  LatLng selectedLatLng = currentLatLng;
  TextEditingController addressController = TextEditingController();
  GoogleMapController? mapController;

  Future<void> _moveCamera(LatLng target) async {
    if (mapController != null) {
      await mapController!.animateCamera(CameraUpdate.newLatLngZoom(target, 15));
    }
  }

  Future<void> _updateAddressFromLatLng(LatLng pos, Function setModalState) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        pos.latitude,
        pos.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        String address =
            "${place.name ?? ''}, "
            "${place.subThoroughfare ?? ''} "
            "${place.thoroughfare ?? ''}, "
            "${place.subLocality ?? ''}, "
            "${place.locality ?? ''}, "
            "${place.administrativeArea ?? ''}, "
            "${place.postalCode ?? ''}, "
            "${place.country ?? ''}";

        setModalState(() {
          selectedLatLng = pos;
          addressFromMap = address;
          _latitudeFromMap = selectedLatLng.latitude;
          _longitudeFromMap = selectedLatLng.longitude;
        });
      }
    } catch (e) {
      debugPrint("Reverse geocoding failed: $e");
    }
  }

  // 6️⃣ Show actual modal
  return showDialog<LatLng>(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return StatefulBuilder(builder: (context, setModalState) {
        return Dialog(
          insetPadding: const EdgeInsets.all(10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: SizedBox(
            width: double.infinity,
            height: MediaQuery.of(context).size.height * 0.9,
            child: Column(
              children: [
                // 🔹 Address Search Field
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    controller: addressController,
                    decoration: InputDecoration(
                      hintText: "Enter Address",
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.search),
                        onPressed: () async {
                          if (addressController.text.isEmpty) return;
                          try {
                            List<Location> locations =
                                await locationFromAddress(addressController.text);
                            if (locations.isNotEmpty) {
                              LatLng newLocation = LatLng(
                                locations.first.latitude,
                                locations.first.longitude,
                              );
                              setModalState(() {
                                selectedLatLng = newLocation;
                              });
                              await _moveCamera(newLocation);
                            }
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Address not found")),
                            );
                          }
                        },
                      ),
                    ),
                  ),
                ),

                // 🔹 Map Section
                SizedBox(
                  height: 200,
                  child: GoogleMap(
                    initialCameraPosition:
                        CameraPosition(target: selectedLatLng, zoom: 15),
                    onMapCreated: (controller) {
                      mapController = controller;
                      _moveCamera(selectedLatLng);
                    },
                    markers: {
                      Marker(
                        markerId: const MarkerId('selected'),
                        position: selectedLatLng,
                      ),
                    },
                    onTap: (pos) async {
                      await _updateAddressFromLatLng(pos, setModalState);
                      await _moveCamera(pos);
                    },
                    myLocationEnabled: true,
                    myLocationButtonEnabled: true,
                    zoomControlsEnabled: false,
                  ),
                ),

                // 🔹 Confirm Location Button
                Padding(
                  padding: const EdgeInsets.all(5.0),
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        confirmLocation = true;
                      });
                      _updateAddressFromLatLng(selectedLatLng, setModalState);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    child: Text("Confirm Location", style: WidgetSupport.formBUttonBig()),
                  ),
                ),

                // 🔹 Scrollable Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Align(
                          alignment: Alignment.topLeft,
                          child: Text(
                            "What type of location will you be covering for First Location?",
                            style: WidgetSupport.Questionblack(),
                          ),
                        ),
                        _buildLocationDropdown(controller: locationType, label: "Select"),

                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.topLeft,
                          child: Text(
                            "What type of activity are you going to do today to get clients in location",
                            style: WidgetSupport.Questionblack(),
                          ),
                        ),
                        _buildEmpActivityTypeDropdown(controller: activityType, label: "Select"),

                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.topLeft,
                          child: Text(
                            "Target meeting in that area",
                            style: WidgetSupport.Questionblack(),
                          ),
                        ),
                        _buildTextField(
                          targetMeetingArea,
                          "Target meeting in that area",
                          "Please Enter Target meeting in that area",
                          "targetMeetingArea",
                          icon: Icons.location_city,
                          isNumeric: true,
                        ),

                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.topLeft,
                          child: Text(
                            "Have you been assigned any Buddy for the Day?",
                            style: WidgetSupport.Questionblack(),
                          ),
                        ),
                        StatefulBuilder(
                          builder: (context, setRadioState) {
                            return Row(
                              children: [
                                Expanded(
                                  child: RadioListTile<String>(
                                    title: const Text("Yes"),
                                    value: "Yes",
                                    groupValue: buddyAssigned.text,
                                    onChanged: (value) {
                                      setRadioState(() {
                                        buddyAssigned.text = value!;
                                      });
                                    },
                                  ),
                                ),
                                Expanded(
                                  child: RadioListTile<String>(
                                    title: const Text("No"),
                                    value: "No",
                                    groupValue: buddyAssigned.text,
                                    onChanged: (value) {
                                      setRadioState(() {
                                        buddyAssigned.text = value!;
                                      });
                                    },
                                  ),
                                ),
                              ],
                            );
                          },
                        ),

                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.topLeft,
                          child: Text(
                            "If Yes, enter Buddy Code",
                            style: WidgetSupport.Questionblack(),
                          ),
                        ),
                        _buildTextField(
                          buddyCode,
                          "If Yes, enter Buddy Code",
                          "Please Enter Buddy Code",
                          "buddyCode",
                          icon: Icons.pattern,
                        ),

                        const SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: () async {
                            if (confirmLocation) {
                              await locationSubmit();
                              setState(() {
                                _showNextButton=true;
                                _isLocationSaved[index] = true;
                              });
                            } else {
                              showDialog(
                                context: context,
                                builder: (_) => AlertDialog(
                                  title: const Text("Missing Information"),
                                  content: const Text(
                                    "Please click on the confirm location to confirm your location in the map.",
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text("OK"),
                                    ),
                                  ],
                                ),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                          ),
                          child: Text("SAVE", style: WidgetSupport.formBUttonBig()),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      });
    },
  );
}



//   void createMap() {
 
//   // Parse number of target applications
//   int targetCount = int.tryParse(targetAplication.text.trim()) ?? 0;


//   setState(() {
//     // step2 = true;
//     // _showNextButton = false;

//     _locationBlocks.clear();
//     _selectedLocations.clear();
//     _latitudeFromMapList.clear();
//     _longitudeFromMapList.clear();
//     _addressFromMapList.clear();

//     for (int i = 0; i < targetCount; i++) {
//       _locationBlocks.add(i);
//       _selectedLocations.add(_currentLocation);
//       _latitudeFromMapList.add(_currentLocation?.latitude);
//       _longitudeFromMapList.add(_currentLocation?.longitude);
//       _addressFromMapList.add(_currentAddress);
//       _isLocationSaved.add(false); // 👈 initially not saved
//     }

//   });
// }
 Future<void> DailyActivityStart() async {
  String planned_meeting = plannedMeeting.text.trim();
  String target_aplication = targetAplication.text.trim();

  final Map<String, String> fieldMap = {
    "meetings_planned": planned_meeting,
    "application_target": target_aplication
  };
  final blankFields = fieldMap.entries
      .where((entry) => entry.value.isEmpty)
      .map((e) => e.key)
      .toList();

  if (blankFields.isNotEmpty) {
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Missing Information"),
        content: Text(
          "Please fill the following fields:\n\n${blankFields.join(", ")}",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
    return;
  }

  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? token = prefs.getString('accessToken');

  Map<String, String> mappedData = {
    "meetings_planned": planned_meeting,
    "application_target": target_aplication,
    'latitude': _latitude?.toStringAsFixed(10) ?? '00.00',
    'longitude': _longitude?.toStringAsFixed(10) ?? '00.00',
    'started_at': startTime,
  };

  String url = '/api/timesheet/agent-daily-activities/';
  final headers = {
    'Authorization': 'Bearer $token',
    'Accept': 'application/json',
    'Content-Type': 'application/json',
    'User-Agent':
        'Mozilla/5.0 (Linux; Android 11; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36',
  };

  try {
    final response = await ApiService.postJsonWithHeaders(url, mappedData, headers);

    if (response != null && response.statusCode == 201) {
      final data = json.decode(response.data);
      setState(() {
        daily_activity = data['id'].toString();
      });
      // ✅ Extract `application_target` value
      int targetCount = int.tryParse(data['application_target'].toString()) ?? 0;

      setState(() {
        step2=true;
        _locationBlocks.clear();
        _selectedLocations.clear();
        _showFinalSaveButton=true;
        // ✅ Create blocks based on `application_target`
        // for (int i = 0; i < targetCount; i++) {
        //   _locationBlocks.add(i);
        //   _selectedLocations.add(_currentLocation);
        // }
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to start daily activity")),
      );
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Error: $e")),
    );
  }
}

  Future<void> locationSubmit() async {
  String location_type = selectedLocationId.toString();
  int? activity_type = selectedActivityId;
  String target_meetings = targetMeetingArea.text.trim();
  String buddy_code = buddyCode.text.trim();

  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? token = prefs.getString('accessToken');
  DateTime now = DateTime.now();
  String ended_at = now.toIso8601String();
  Map<String, String> mappedData = {
    'lead_location_name': addressFromMap,
    'lead_latitude': _latitudeFromMap?.toStringAsFixed(10)?? '00.00',
    'lead_longitude': _longitudeFromMap?.toStringAsFixed(10)?? '00.00',
    'location_type_other': '',
    'activity_type_other': '',
    'started_at': startTime,
    'ended_at': ended_at,
    'target_meetings': target_meetings,
    'buddy_code':buddy_code,
    'location_name': _currentAddress,
    'latitude': _latitude?.toStringAsFixed(10) ?? '00.00',
    'longitude': _longitude?.toStringAsFixed(10) ?? '00.00',
    'daily_activity': daily_activity,
    'location_type': location_type,
    'activity': activity_type.toString()
  };
  String url = '/api/timesheet/agent-location-visits/';
  final headers = {
    'Authorization': 'Bearer $token',
    'Accept': 'application/json',
    'Content-Type': 'application/json',
    'User-Agent':
        'Mozilla/5.0 (Linux; Android 11; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36',
  };
  try {
    final response = await ApiService.postJsonWithHeaders(url, mappedData, headers);
    if (response != null && response.statusCode == 201) {
      // showDialog(
      // context: context,
      // builder: (_) => AlertDialog(
      //   title: const Text("Thank You"),
      //   content: Text("Activity Details Save Successfull", ),
      //   actions: [
      //     TextButton(
      //       onPressed: () => Navigator.pop(context),
      //       child: const Text("OK"),
      //     ),
      //   ],
      // ),
      // );
      setState(() {
        _showFinalSaveButton=true;
        finalSaveDone=true;
      });
      Navigator.of(context, rootNavigator: true).pop();
    }
    else
    {
      final data = json.decode(response!.data);
      showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Information"),
        content: Text("$data", ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
      );
    }
  }
  catch (e)
  {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Error: $e")),
    );
  }

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
  controller.clear();
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
        // Optionally update controller with dropdown value name
        final selectedItem = locationTypelist.firstWhere(
          (e) => e['id'] == val,
          orElse: () => {'name': ''},
        );
        controller.text = selectedItem['name']; // you can remove if not needed
        print(controller.text );
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
                    style: TextStyle(color: Colors.red, fontSize: 25),
                  ),
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
Future<bool?> _showExitConfirmationDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Leave this page?"),
        content: Text("Are you sure you want to leave this page?"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(false); // Stay on the page
            },
            child: Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(true); // Exit the page
            },
            child: Text("Leave"),
          ),
        ],
      ),
    );
  }

}
