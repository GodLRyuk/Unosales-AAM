import 'dart:async';
// import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unosfa/pages/FRModule/mytodolist.dart';
import 'package:unosfa/pages/services/api_service.dart';
import 'package:unosfa/pages/services/secret_key.dart';
import 'package:unosfa/widgetSupport/widgetstyle.dart';
import 'package:url_launcher/url_launcher.dart';

class OSMRouteTracking extends StatefulWidget {
  final String leadId;
  const OSMRouteTracking({super.key, required this.leadId});
  @override
  _OSMRouteTrackingState createState() => _OSMRouteTrackingState();
}

class _OSMRouteTrackingState extends State<OSMRouteTracking> {
  // late MapController _mapController;
  LatLng _currentPosition = LatLng(0.0, 0.0);
  LatLng _destination = LatLng(0.0, 0.0);
  Set<Polyline> _polylines = {};
  List<LatLng> _routePoints = [];
  bool isRouteLoading = false;
  bool isFetchingLocation = false;
  GoogleMapController? mapController;
  Set<Marker> _markers = {};
  bool _locationLoaded = false;

  @override
  void initState() {
    getCurrentLocation();
    super.initState();
    // _mapController = MapController();
    fetchLeadDetails();
    // trackUserMovement();
    requestLocationPermission();
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

  @override
  void dispose() {
    _positionStream?.cancel();
    // _mapController.dispose();
    super.dispose();
  }

  bool isLoading = true;
  Map<String, dynamic> leadDetails = {};
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
          // Parse the response body as JSON
          setState(() {
            leadDetails = response.data;
            isLoading = false; // Data loaded
            getLatLngFromAddress(leadDetails['perm_state'] +
                ' ' +
                leadDetails['perm_city'] +
                ' ' +
                leadDetails['perm_street'] +
                ' ' +
                leadDetails['perm_country']);
          });
        } else if (response.statusCode == 401) {
          Map<String, String> mappedData = {
            'refresh': refresh ?? '',
          };
          String url2 = "/api/users/token-refresh/";
          final response2 = await ApiService.post(url2, mappedData);
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

        // Call route fetching function
        fetchRoute(_destination);
      }
    } catch (e) {
      print("Error: $e");
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
          markerId: MarkerId("current_location"),
          position: _currentPosition,
          infoWindow: InfoWindow(title: "Current Location"),
        ));
        _locationLoaded = true;
      });
    } catch (e) {
      print("Error getting location: $e");
    }
  }

  // Future<void> getCurrentLocation() async {
  //   print("current position ");
  //   try {
  //     Position position = await Geolocator.getCurrentPosition(
  //       desiredAccuracy: LocationAccuracy.high,
  //     );
  //     setState(() {
  //       _currentPosition = LatLng(position.latitude, position.longitude);
  //       print("Current Posi: $_currentPosition");
  //     });
  //     _mapController.move(_currentPosition, 15.0);
  //   } catch (e) {
  //     print("Error getting location: $e");
  //   }
  // }

  // void trackUserMovement() {
  //   _positionStream?.cancel(); // Cancel any existing stream
  //   _positionStream = Geolocator.getPositionStream(
  //     locationSettings: LocationSettings(
  //       accuracy: LocationAccuracy.high,
  //       distanceFilter: 1, // Update on every 1 meter movement
  //     ),
  //   ).listen((Position position) {
  //     if (mounted) {
  //       LatLng newPosition = LatLng(position.latitude, position.longitude);

  //       // Add the new position only if it differs significantly
  //       if (_routePoints.isEmpty ||
  //           Geolocator.distanceBetween(
  //                   _routePoints.last.latitude,
  //                   _routePoints.last.longitude,
  //                   newPosition.latitude,
  //                   newPosition.longitude) >=
  //               1) {
  //         setState(() {
  //           _currentPosition = newPosition;
  //           _routePoints.add(newPosition);

  //         });

  //         _mapController.move(newPosition, 15.0);
  //       }
  //     }
  //   }, onError: (error) {
  //     print("Error in position stream: $error");
  //   });
  // }

  void trackUserMovement() {
    _positionStream?.cancel(); // Cancel any existing stream

    _positionStream = Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 1, // Update on every 1 meter movement
      ),
    ).listen((Position position) {
      if (mounted) {
        LatLng newPosition = LatLng(position.latitude, position.longitude);

        // Ensure we have a route from API
        if (_routePoints.isNotEmpty) {
          // Find the nearest point on the route
          LatLng closestPoint = _routePoints.first;
          double minDistance = double.infinity;

          for (LatLng point in _routePoints) {
            double distance = Geolocator.distanceBetween(point.latitude,
                point.longitude, newPosition.latitude, newPosition.longitude);
            if (distance < minDistance) {
              minDistance = distance;
              closestPoint = point;
            }
          }

          // Remove past points to keep route relevant
          _routePoints.removeWhere((point) =>
              Geolocator.distanceBetween(point.latitude, point.longitude,
                  newPosition.latitude, newPosition.longitude) <
              1);

          setState(() {
            _currentPosition = newPosition;

            // Keep the user near the predefined route
            _routePoints.insert(0, newPosition);

            // Ensure continuity in the route
            if (!_routePoints.contains(closestPoint)) {
              _routePoints.add(closestPoint);
            }
          });

          // _mapController.move(newPosition, 15.0);
        }
      }
    }, onError: (error) {
      print("Error in position stream: $error");
    });
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
      final String url =
          "https://maps.googleapis.com/maps/api/directions/json?origin=${position.latitude},${position.longitude}&destination=${destination.latitude},${destination.longitude}&mode=driving&key=$apiKey";

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

  // final DatabaseReference _dbRef =
  //     FirebaseDatabase.instance.ref("Lead Movement");
  StreamSubscription<Position>? _positionStream;
  bool isTracking = false;
  List<Map<String, dynamic>> path = [];
  Future<void> startTracking() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? userInfo = prefs.getStringList('userInfo');
    String unm = userInfo?.isNotEmpty == true ? userInfo![0] : "UnknownUser";
    setState(() => isTracking = true);
    if (mounted) {
      setState(() {
        isFetchingLocation = true;
      });
    }

    try {
      // Get last known location or fetch new one if not available
      Position? position = await Geolocator.getLastKnownPosition() ??
          await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
          );

      if (mounted) {
        setState(() {
          _currentPosition = LatLng(position.latitude, position.longitude);
          isFetchingLocation = false;
        });
      }
      // Store initial location in Firebase
      _storeLocationToFirebase(unm, position);

      // Listen for real-time updates (only when moved at least 1 meter)
      _positionStream = Geolocator.getPositionStream(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 1, // Only update when moving at least 1 meter
        ),
      ).listen((Position newPosition) {
        if (mounted) {
          setState(() {
            _currentPosition =
                LatLng(newPosition.latitude, newPosition.longitude);
          });
        }
        _storeLocationToFirebase(unm, newPosition);
      });
    } catch (e) {
      print("Error getting location: $e");
    }
  }

  /// Helper function to store location in Firebase
  void _storeLocationToFirebase(String user, Position position) {
    Map<String, dynamic> newLocation = {
      'latitude': position.latitude,
      'longitude': position.longitude,
      'timestamp': DateTime.now().toIso8601String(),
    };

    // _dbRef
    //     .child(user)
    //     .child(widget.leadId)
    //     .child(DateTime.now().millisecondsSinceEpoch.toString())
    //     .set(newLocation)
    //     .catchError((error) {
    //   print("Error storing data in Firebase: $error");
    // });
  }

  void stopTracking() {
    _positionStream?.cancel();
    setState(() => isTracking = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(60.0),
        child: Container(
          decoration: BoxDecoration(
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
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'images/logo.PNG',
                  height: 30,
                ),
                SizedBox(width: 50),
              ],
            ),
            centerTitle: true,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () {
                Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) => MyTodoList(
                              searchQuery: '',
                            )));
              },
            ),
          ),
        ),
      ),
      body: !_locationLoaded
          ? Center(child: CircularProgressIndicator())
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
                            height: MediaQuery.of(context).size.height *
                                0.58, // Set height
                            child: GoogleMap(
                              initialCameraPosition: CameraPosition(
                                  target: _currentPosition, zoom: 15, tilt: 20),
                              polylines: _polylines,
                              markers: {
                                // Marker(
                                //   markerId: MarkerId("start"),
                                //   position: LatLng(_currentPosition.latitude,
                                //       _currentPosition.longitude),
                                // ),
                                Marker(
                                  markerId: MarkerId("end"),
                                  position:
                                      _destination, // or any fixed end point
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
                        Center(child: CircularProgressIndicator()),
                      Expanded(
                        flex: 4,
                        child: SingleChildScrollView(
                          child: Container(
                            height: MediaQuery.of(context).size.height * 0.4,
                            padding: const EdgeInsets.all(15.0),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border(
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
                                Text(
                                  "Lead Details:",
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  "Name: ${leadDetails['first_name']} ${leadDetails['middle_name']} ${leadDetails['last_name']}"
                                      .toUpperCase(),
                                  style: TextStyle(
                                      fontSize: 16, color: Color(0xFF2C2B2B)),
                                ),
                                Text(
                                  "PHONE NUMBER: +${leadDetails['mobile_phone']} ",
                                  style: TextStyle(
                                      fontSize: 16, color: Color(0xFF2C2B2B)),
                                ),
                                Text(
                                  "ZIP: ${leadDetails['perm_zip_code']} ",
                                  style: TextStyle(
                                      fontSize: 16, color: Color(0xFF2C2B2B)),
                                ),
                                Text(
                                  "BARANGAY: ${leadDetails['perm_barangay']}"
                                      .toUpperCase(),
                                  style: TextStyle(
                                      fontSize: 16, color: Color(0xFF2C2B2B)),
                                ),
                                SizedBox(
                                  height:
                                      MediaQuery.of(context).size.height * 0.01,
                                ),
                                Text(
                                  "Destination:",
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  "Address: ${leadDetails['perm_city']} ${leadDetails['perm_state']} ${leadDetails['perm_street']} "
                                      .toUpperCase(),
                                  style: TextStyle(
                                      fontSize: 16, color: Color(0xFF2C2B2B)),
                                ),
                                SizedBox(
                                  height:
                                      MediaQuery.of(context).size.height * 0.01,
                                ),
                                Container(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      ElevatedButton(
                                        onPressed: () {
                                          if (isTracking) {
                                            // stopTracking();
                                          } else {
                                            // startTracking();
                                            openGoogleMaps();
                                          }
                                        },
                                        child: Text(
                                          "Start Location",
                                          style: WidgetSupport
                                              .LoginButtonTextColor(),
                                        ),
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
                  ),
                ),
              ],
            ),
    );
  }
}
