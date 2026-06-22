import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unosfa/pages/FRModule/mytodolist.dart';
import 'package:unosfa/pages/services/api_service.dart';
import 'package:unosfa/pages/services/secret_key.dart';

class AgentRouteTraveled extends StatefulWidget {
  @override
  _AgentRouteTraveledState createState() => _AgentRouteTraveledState();
}

class _AgentRouteTraveledState extends State<AgentRouteTraveled> {
  bool isRouteLoading = false;
  GoogleMapController? mapController;
  Map<String, dynamic> leadDetails = {};
  List<dynamic> allleadsdetails = [];
  List<LatLng> _destinations = [];
  List<LatLng> _routePoints = [];
  Set<Polyline> _polylines = {};
  Set<Marker> _markers = {};
  LatLng _currentPosition = LatLng(0.0, 0.0);
  bool _locationLoaded = false;

  @override
  void initState() {
    getCurrentLocation();
    super.initState();
    fetchLeadDetails();
  }

  Future<void> fetchLeadDetails() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('accessToken');

    try {
      String url = "/api/agents/todos/";
      final headers = {
        'Authorization': 'Bearer $token',
        'User-Agent':
            'Mozilla/5.0 (Linux; Android 11; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36',
      };
      final response = await ApiService.getWithHeaders(url, headers);
      if (response != null) {
        if (response.statusCode == 200) {
          final Map<String, dynamic> data = response.data;
          leadDetails = data;
          setState(() {
            allleadsdetails = data['results'] ?? [];
          });

          // Clear existing destinations and markers before re-adding
          _destinations.clear();
          _markers.clear();

          List<dynamic> leads = data['results'] ?? [];
          for (var lead in leads) {
            // String address = "${lead['perm_street']}";

            String address =
                "${lead['perm_state']} ${lead['perm_city']} ${lead['perm_street']} ${lead['perm_country']} ${lead['perm_zip_code']} ${lead['perm_barangay']} ${lead['perm_region']}";
            if (address.trim().isNotEmpty) {
              await getLatLngFromAddress(address);
            }
          }
          if (_destinations.isNotEmpty) {
            findAndFetchFullRoute();
          }
        } else {
          throw Exception('Failed to load lead details');
        }
      }
    } catch (e) {
      print('Error fetching lead details: $e');
    }
  }

  Future<void> getLatLngFromAddress(String address) async {
    try {
      List<Location> locations = await locationFromAddress(address);
      if (locations.isNotEmpty) {
        LatLng destination = LatLng(
          locations.first.latitude,
          locations.first.longitude,
        );
        setState(() {
          _destinations.add(destination);
          _markers.add(Marker(
            markerId: MarkerId(destination.toString()),
            position: destination,
            infoWindow: InfoWindow(title: 'Lead Location'),
          ));
        });
      }
    } catch (e) {
      print("Error while geocoding: $e");
    }
  }

  void findAndFetchFullRoute() {
    if (_destinations.isEmpty) return;

    // Sort destinations by distance from current position
    _destinations.sort((a, b) {
      final distanceA = Geolocator.distanceBetween(
        _currentPosition.latitude,
        _currentPosition.longitude,
        a.latitude,
        a.longitude,
      );
      final distanceB = Geolocator.distanceBetween(
        _currentPosition.latitude,
        _currentPosition.longitude,
        b.latitude,
        b.longitude,
      );
      return distanceA.compareTo(distanceB);
    });

    // Fetch the multi-stop route for the sorted destinations
    fetchMultiStopRoute();
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

  Future<void> fetchMultiStopRoute() async {
    setState(() {
      isRouteLoading = true;
    });

    try {
      String clientSecret = await googleApiKey();
      String apiKey = clientSecret;
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      final origin = LatLng(position.latitude, position.longitude);

      // Sort _destinations by distance from current location
      List<LatLng> sortedDestinations = List.from(_destinations);
      sortedDestinations.sort((a, b) {
        double distanceA = Geolocator.distanceBetween(
            origin.latitude, origin.longitude, a.latitude, a.longitude);
        double distanceB = Geolocator.distanceBetween(
            origin.latitude, origin.longitude, b.latitude, b.longitude);
        return distanceA.compareTo(distanceB);
      });

      final destination =
          "${sortedDestinations.last.latitude},${sortedDestinations.last.longitude}";

      // Build waypoints excluding the final destination
      final waypoints = sortedDestinations
          .sublist(0, sortedDestinations.length - 1)
          .map((loc) => "${loc.latitude},${loc.longitude}")
          .join('|');

//  No need to change AS this is for google API and it is working fine
      final url =
          "https://maps.googleapis.com/maps/api/directions/json?origin=${origin.latitude},${origin.longitude}"
          "&destination=$destination"
          "${waypoints.isNotEmpty ? "&waypoints=optimize:true|$waypoints" : ""}"
          "&key=$apiKey";
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['routes'].isNotEmpty) {
          final polyline = data['routes'][0]['overview_polyline']['points'];
          List<LatLng> routePoints = _decodePolyline(polyline);
          setState(() {
            _routePoints = routePoints;
            _polylines = {
              Polyline(
                polylineId: PolylineId("route"),
                points: _routePoints,
                color: Colors.blue,
                width: 5,
              ),
            };
          });
          zoomToFitRoute(routePoints);
        } else {
          print("No route found.");
        }
      } else {
        print("Google Directions API error: ${response..body}");
      }
    } catch (e) {
      print("Error fetching Google route: $e");
    }

    setState(() {
      isRouteLoading = false;
    });
  }

  void zoomToFitRoute(List<LatLng> points) {
    final bounds = _boundsFromLatLngList(points);
    mapController?.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
  }

  LatLngBounds _boundsFromLatLngList(List<LatLng> list) {
    double x0 = list.first.latitude;
    double x1 = list.first.latitude;
    double y0 = list.first.longitude;
    double y1 = list.first.longitude;

    for (LatLng latLng in list) {
      if (latLng.latitude > x1) x1 = latLng.latitude;
      if (latLng.latitude < x0) x0 = latLng.latitude;
      if (latLng.longitude > y1) y1 = latLng.longitude;
      if (latLng.longitude < y0) y0 = latLng.longitude;
    }

    return LatLngBounds(
      southwest: LatLng(x0, y0),
      northeast: LatLng(x1, y1),
    );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(60.0),
        child: Container(
          decoration: BoxDecoration(
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
                    builder: (context) => MyTodoList(searchQuery: ''),
                  ),
                );
              },
            ),
          ),
        ),
      ),
      body: !_locationLoaded
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  flex: 6,
                  child: GoogleMap(
                    onMapCreated: (controller) => mapController = controller,
                    initialCameraPosition: CameraPosition(
                        target: _currentPosition, zoom: 15, tilt: 20),
                    markers: _markers,
                    polylines: _polylines,
                    myLocationEnabled: true,
                  ),
                ),
                if (isRouteLoading) Center(child: CircularProgressIndicator()),
                Expanded(
                  flex: 3,
                  child: SingleChildScrollView(
                    child: Container(
                      width: MediaQuery.of(context).size.width,
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 5,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Leads Details:",
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 10),
                          for (var lead in allleadsdetails) ...[
                            Container(
                              width: MediaQuery.of(context).size.width,
                              margin: EdgeInsets.only(bottom: 16),
                              padding: EdgeInsets.all(12),
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
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        "Name:",
                                        style: TextStyle(
                                            fontSize: 17,
                                            fontWeight: FontWeight.w500),
                                      ),
                                      Flexible(
                                        child: Text(
                                          " ${lead['first_name']} ${lead['middle_name'] ?? ''} ${lead['last_name']}"
                                              .toUpperCase(),
                                          style: TextStyle(
                                              fontSize: 16,
                                              color: Color(0xFF2C2B2B)),
                                          softWrap: true,
                                          textAlign: TextAlign.end,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        "Phone Number:",
                                        style: TextStyle(
                                            fontSize: 17,
                                            fontWeight: FontWeight.w500),
                                      ),
                                      Text(
                                        "${lead['mobile_phone']}".toUpperCase(),
                                        style: TextStyle(
                                            fontSize: 16,
                                            color: Color(0xFF2C2B2B)),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        "Address:",
                                        style: TextStyle(
                                            fontSize: 17,
                                            fontWeight: FontWeight.w500),
                                      ),
                                      Flexible(
                                        child: Text(
                                          " ${lead['perm_city']}, ${lead['perm_state']}, ${lead['perm_street']}",
                                          style: TextStyle(
                                              fontSize: 16,
                                              color: Color(0xFF2C2B2B)),
                                          softWrap: true,
                                          textAlign: TextAlign.end,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ]
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
