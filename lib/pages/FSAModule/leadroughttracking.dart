import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unosfa/pages/FSAModule/mytodolist.dart';
import 'package:unosfa/pages/services/api_service.dart';
import 'package:unosfa/pages/services/secret_key.dart';
import 'package:unosfa/widgetSupport/widgetstyle.dart';
import 'package:url_launcher/url_launcher.dart';

const String graphHopperApiKey =
    "5b3ce3597851110001cf6248c69a4cac7d204ad08965cee4a6faa5e9";

class FSAOSMRouteTracking extends StatefulWidget {
  final String leadId;

  const FSAOSMRouteTracking({super.key, required this.leadId});

  @override
  _FSAOSMRouteTrackingState createState() => _FSAOSMRouteTrackingState();
}

class _FSAOSMRouteTrackingState extends State<FSAOSMRouteTracking> {
  LatLng _currentPosition = const LatLng(0.0, 0.0);
  LatLng _destination = const LatLng(0.0, 0.0);
  List<LatLng> _routePoints = [];
  bool isRouteLoading = false;
  bool isFetchingLocation = false;
  Set<Polyline> _polylines = {};
  GoogleMapController? mapController;
  Set<Marker> _markers = {};
  bool _locationLoaded = false;

  bool isLoading = true;
  Map<String, dynamic> leadDetails = {};

  StreamSubscription<Position>? _positionStream;
  bool isTracking = false;

  @override
  void initState() {
    super.initState();
    getCurrentLocation();
    fetchLeadDetails();
    requestLocationPermission();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }

  Future<void> requestLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      print("Location permissions are permanently denied.");
      return;
    }
  }

  Future<void> fetchLeadDetails() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('accessToken');
    String? refresh = prefs.getString('refreshToken');

    try {
      String url = "/api/agents/todos/${widget.leadId}/";
      final headers = {
        'Authorization': 'Bearer $token',
        'User-Agent':
            'Mozilla/5.0 (Linux; Android 11; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36',
      };

      final response = await ApiService.getWithHeaders(url, headers);

      if (response != null) {
        if (response.statusCode == 200) {
          setState(() {
            leadDetails = json.decode(response.data.body);
            isLoading = false;
          });

          // Added space between address parts for proper geocoding
          String fullAddress =
              "${leadDetails['perm_street'] ?? ''}, ${leadDetails['perm_city'] ?? ''}, ${leadDetails['perm_state'] ?? ''}";

          getLatLngFromAddress(fullAddress);
        } else if (response.statusCode == 401) {
          Map<String, String> mappedData = {'refresh': refresh ?? ''};
          String url = "/api/users/token-refresh/";
          final response2 = await ApiService.post(url, mappedData);
          if (response2 != null) {
            final data = json.decode(response2.data);
            await prefs.setBool('isLoggedIn', true);
            await prefs.setString('accessToken', data['access']);
            await prefs.setString('refreshToken', data['refresh']);
            fetchLeadDetails();
          }
        } else {
          throw Exception('Failed to load lead details');
        }
      }
    } catch (e) {
      print('Error fetching lead details: $e');
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> getLatLngFromAddress(String address) async {
    try {
      List<Location> locations = await locationFromAddress(address);
      if (locations.isNotEmpty) {
        setState(() {
          _destination =
              LatLng(locations.first.latitude, locations.first.longitude);
        });
        fetchRoute(_destination);
      } else {
        print("No locations found for address: $address");
      }
    } catch (e) {
      print("Error getting LatLng from address: $e");
    }
  }

  Future<void> getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
        _markers.add(Marker(
          markerId: const MarkerId("current_location"),
          position: _currentPosition,
          infoWindow: const InfoWindow(title: "Current Location"),
        ));
        _locationLoaded = true;
      });
    } catch (e) {
      print("Error getting location: $e");
    }
  }

  Future<void> fetchRoute(LatLng destination) async {
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    setState(() {
      isRouteLoading = true;
    });

    try {
      String clientSecret = await googleApiKey();
      String apiKey = clientSecret;

      final String url = "https://maps.googleapis.com/maps/api/directions/json?origin=${position.latitude},${position.longitude}&destination=${destination.latitude},${destination.longitude}&mode=driving&key=$apiKey";

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['routes'] != null && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final polyline = route['overview_polyline']['points'];

          List<LatLng> decodedPoints = _decodePolyline(polyline);

          setState(() {
            _routePoints = decodedPoints;
            _polylines = {
              Polyline(
                polylineId: const PolylineId("route"),
                color: Colors.blue,
                width: 5,
                points: _routePoints,
              ),
            };
            isRouteLoading = false;
          });
        } else {
          print("No route found");
        }
      } else {
        print("Failed to load route: ${response.body}");
      }
    } catch (e) {
      print("Error fetching route: $e");
    }

    setState(() {
      isRouteLoading = false;
    });
  }

  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> poly = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);

      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);

      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      poly.add(LatLng(lat / 1E5, lng / 1E5));
    }
    return poly;
  }

  void openGoogleMaps() async {
    String googleMapsUrl =
        "https://www.google.com/maps/dir/?api=1&origin=${_currentPosition.latitude},${_currentPosition.longitude}&destination=${_destination.latitude},${_destination.longitude}&travelmode=driving";
    if (await canLaunch(googleMapsUrl)) {
      await launch(googleMapsUrl);
    } else {
      throw 'Could not open Google Maps';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                    builder: (context) => const FSAMyTodoList(searchQuery: ''),
                  ),
                );
              },
            ),
          ),
        ),
      ),
      body: !_locationLoaded
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  flex: 6,
                  child: Column(
                    children: [
                      Stack(
                        children: [
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.58,
                            child: GoogleMap(
                              initialCameraPosition: CameraPosition(
                                target: _currentPosition,
                                zoom: 15,
                                tilt: 20,
                              ),
                              polylines: _polylines,
                              markers: {
                                Marker(
                                  markerId: const MarkerId("end"),
                                  position: _destination,
                                ),
                              },
                              onMapCreated: (controller) {
                                mapController = controller;
                              },
                              myLocationEnabled: true,
                            ),
                          ),
                        ],
                      ),
                      if (isRouteLoading)
                        const Center(child: CircularProgressIndicator()),
                      Expanded(
                        flex: 4,
                        child: SingleChildScrollView(
                          child: Container(
                            height: MediaQuery.of(context).size.height * 0.4,
                            padding: const EdgeInsets.all(15.0),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: const Border(
                                top: BorderSide(
                                    color: Color(0xFF640D78), width: 1.0),
                                bottom: BorderSide(
                                    color: Color(0xFF640D78), width: 1.0),
                                left: BorderSide(
                                    color: Color(0xFF640D78), width: 5.0),
                                right: BorderSide(
                                    color: Color(0xFF640D78), width: 1.0),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text("Lead Details:",
                                    style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold)),
                                Text(
                                  "NAME: ${(leadDetails['first_name'] ?? '')} ${(leadDetails['middle_name'] ?? '')} ${(leadDetails['last_name'] ?? '')}"
                                      .toUpperCase(),
                                  style: const TextStyle(
                                      fontSize: 16, color: Color(0xFF2C2B2B)),
                                ),
                                Text(
                                  "PHONE NUMBER: ${leadDetails['mobile_phone'] ?? ''}",
                                  style: const TextStyle(
                                      fontSize: 16, color: Color(0xFF2C2B2B)),
                                ),
                                Text(
                                  "ZIP: ${leadDetails['perm_zip_code'] ?? ''}",
                                  style: const TextStyle(
                                      fontSize: 16, color: Color(0xFF2C2B2B)),
                                ),
                                Text(
                                  "BARANGAY: ${(leadDetails['perm_barangay'] ?? '')}"
                                      .toUpperCase(),
                                  style: const TextStyle(
                                      fontSize: 16, color: Color(0xFF2C2B2B)),
                                ),
                                const SizedBox(height: 10),
                                const Text("Destination:",
                                    style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold)),
                                Text(
                                  "Address: ${(leadDetails['perm_street'] ?? '')}, ${(leadDetails['perm_city'] ?? '')}, ${(leadDetails['perm_state'] ?? '')}"
                                      .toUpperCase(),
                                  style: const TextStyle(
                                      fontSize: 16, color: Color(0xFF2C2B2B)),
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    ElevatedButton(
                                      onPressed: () {
                                        openGoogleMaps();
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.transparent,
                                        shadowColor: Colors.transparent,
                                        padding: EdgeInsets.symmetric(
                                          horizontal: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              0.02,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8.0),
                                        ),
                                      ),
                                      child: Text(
                                        "Going For Lead",
                                        style: WidgetSupport
                                            .LoginButtonTextColor(),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
