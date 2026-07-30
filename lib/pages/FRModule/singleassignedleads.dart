import 'dart:convert'; // for json.decode
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unosfa/pages/FSAModule/assignedLeads.dart';
import 'package:unosfa/pages/services/api_service.dart';
import 'package:unosfa/widgetSupport/widgetstyle.dart';
import 'package:intl/intl.dart';

class FRSingleAssignedLead extends StatefulWidget {
  final String leadId;
  const FRSingleAssignedLead({super.key, required this.leadId});

  @override
  State<FRSingleAssignedLead> createState() => _FRSingleAssignedLeadState();
}

class _FRSingleAssignedLeadState extends State<FRSingleAssignedLead> {
  bool isLoading = true;
  Map<String, dynamic> leadDetails = {}; // To store the lead details
  late Map<String, String> StatusCode = {}; // Initialize as an empty map
  late Map<String, String> _dependentData = {}; // List for second dropdown data
  late Map<String, String> _subdependentData =
      {}; // List for second dropdown data
  final callback_date = TextEditingController();
  String? _selectedStatusCode;
  String? _selectedStatusSubCode;
  String _selectedDependentData = "";
  String featchCallBackStatus = "";
  bool visibility = false;
  // Function to fetch lead details by ID
  Future<void> fetchLeadDetails() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('accessToken');
    String? refresh = prefs.getString('refreshToken');
    try {
      String url = "/api/agents/assigned-leads/${widget.leadId}/";
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
            _selectedStatusCode = leadDetails['contact_status'].toString();
            _loadDependentData(leadDetails['contact_status']);
            _loadSubSubData(leadDetails['disposition_status']);

            isLoading = false; // Data loaded
          });
        } else if (response.statusCode == 401) {
          Map<String, String> mappedData = {
            'refresh': refresh ?? '',
          };
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

  @override
  void initState() {
    super.initState();
    fetchLeadDetails(); // Fetch lead details when the screen is loaded
    _loadStatusData();
  }

  Future<void> _loadStatusData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('accessToken');

    try {
      String url = "/api/campaigns/leads-contact-statuses/";
      final headers = {
        'Authorization': 'Bearer $token',
        'User-Agent':
            'Mozilla/5.0 (Linux; Android 11; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36',
      };
      final response = await ApiService.getWithHeaders(url, headers);
      if (response != null) {
        if (response.statusCode == 200) {
          var decodedResponse = response.data;
          if (decodedResponse is Map<String, dynamic> &&
              decodedResponse['results'] != null) {
            decodedResponse = decodedResponse['results'];
          }
          if (decodedResponse is List) {
            Map<String, String> fetchedData = {};
            for (var item in decodedResponse) {
              fetchedData[item['id'].toString()] =
                  item['description'].toString();
            }

            setState(() {
              StatusCode = fetchedData;
            });
          } else {
            throw Exception('Unexpected response format');
          }
        } else if (response.statusCode == 401) {
          SharedPreferences prefs = await SharedPreferences.getInstance();
          String? refresh = prefs.getString('refreshToken');
          prefs.getString('accessToken');
          Map<String, String> mappedData = {
            'refresh': refresh ?? '',
          };
          String url = "/api/users/token-refresh/";
          final response2 = await ApiService.post(url, mappedData);
          if (response2 != null) {
            final data = json.decode(response2.data);
            await prefs.setBool('isLoggedIn', true);
            await prefs.setString('accessToken', data['access']);
            await prefs.setString('refreshToken', data['refresh']);
          }
        } else {
          throw Exception('Failed to load dependent data');
        }
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  Future<void> _loadDependentData(statusId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('accessToken');

    try {
      String url = "/api/campaigns/leads-contact-statuses/$statusId/";
      final headers = {
        'Authorization': 'Bearer $token',
        'User-Agent':
            'Mozilla/5.0 (Linux; Android 11; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36',
      };
      final response = await ApiService.getWithHeaders(url, headers);
      if (response != null) {
        if (response.statusCode == 200) {
          var decodedResponse = response.data;
          if (decodedResponse is Map<String, dynamic> &&
              decodedResponse['disposition_statuses'] != null) {
            decodedResponse = decodedResponse['disposition_statuses'];
          }
          if (decodedResponse is List) {
            Map<String, String> fetchedData = {};
            String? matchedStatusCode;
            String? matchedCallBackStatusCode;

            for (var item in decodedResponse) {
              final id = item['id'].toString();
              final description = item['description'].toString();
              fetchedData[id] = description;

              // Check for matching disposition status
              if (leadDetails['disposition_status']?.toString() == id) {
                matchedStatusCode = id;
                matchedCallBackStatusCode = description;
              }
            }
            setState(() {
              _dependentData = fetchedData;
              _selectedStatusSubCode = matchedStatusCode;
              if (matchedCallBackStatusCode != null) {
                featchCallBackStatus = matchedCallBackStatusCode;
              }
              if (featchCallBackStatus == "Call Back") {
                visibility = true;
                String rawDate = leadDetails['callback_date'];
                DateTime originalDate =
                    DateTime.parse(rawDate).toUtc().add(Duration(hours: 8));
                String formattedDate =
                    DateFormat('yyyy-MM-dd').format(originalDate);
                callback_date.text = formattedDate;
              }
              isLoading = false;
            });
          } else {
            throw Exception('Unexpected response format');
          }
        } else if (response.statusCode == 401) {
          SharedPreferences prefs = await SharedPreferences.getInstance();
          String? refresh = prefs.getString('refreshToken');
          prefs.getString('accessToken');
          Map<String, String> mappedData = {
            'refresh': refresh ?? '',
          };
          String url = "/api/users/token-refresh/";
          final response2 = await ApiService.post(url, mappedData);
          if (response2 != null) {
            final data = json.decode(response2.data);
            await prefs.setBool('isLoggedIn', true);
            await prefs.setString('accessToken', data['access']);
            await prefs.setString('refreshToken', data['refresh']);
          }
        } else {
          throw Exception('Failed to load dependent data');
        }
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  Future<void> _loadSubSubData(SubDispStatusId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('accessToken');
    String? refresh = prefs.getString('refreshToken');
    try {
      String url =
          "/api/campaigns/leads-dispositions-statuses/$SubDispStatusId/";
      final headers = {
        'Authorization': 'Bearer $token',
        'User-Agent':
            'Mozilla/5.0 (Linux; Android 11; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36',
      };
      final response = await ApiService.getWithHeaders(url, headers);
      if (response != null) {
        if (response.statusCode == 200) {
          var decodedResponse = response.data;
          if (decodedResponse is Map<String, dynamic> &&
              decodedResponse['sub_dispositions'] != null) {
            decodedResponse = decodedResponse['sub_dispositions'];
          }
          if (decodedResponse is List) {
            Map<String, String> fetchedData = {};
            String? matchedStatusCode;

            for (var item in decodedResponse) {
              final id = item['id'].toString();
              final description = item['description'].toString();
              fetchedData[id] = description;

              // Check for matching disposition status
              if (leadDetails['sub_disposition_status']?.toString() == id) {
                matchedStatusCode = id;
              }
            }
            setState(() {
              _subdependentData = fetchedData;
              if (matchedStatusCode != null) {
                _selectedDependentData = matchedStatusCode;
              }
            });
          } else {
            throw Exception('Unexpected response format');
          }
        } else if (response.statusCode == 401) {
          Map<String, String> mappedData = {
            'refresh': refresh ?? '',
          };
          String url2 = "/api/users/token-refresh/";
          final response2 = await ApiService.post(url2, mappedData);
          if (response2 != null) {
            final data = json.decode(response2.data);
            SharedPreferences prefs = await SharedPreferences.getInstance();
            await prefs.setBool('isLoggedIn', true);
            await prefs.setString('accessToken', data['access']);
            await prefs.setString('refreshToken', data['refresh']);
          }
        } else {
          throw Exception('Failed to load location types');
        }
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(60.0), // Adjust the height as needed
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFFc433e0), // Start color of the gradient
                Color(0xFF9a37ae), // End color of the gradient
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: AppBar(
            backgroundColor: Colors.transparent, // Make AppBar transparent
            elevation: 0, // Remove shadow
            title: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'images/logo.PNG', // Path to your image
                  height: 30,
                ),
                SizedBox(width: 50), // Adjust spacing if needed
              ],
            ),
            centerTitle: true, // Center the title
            leading: IconButton(
              icon: Icon(Icons.arrow_back,
                  color: Colors.white), // Leading arrow icon
              onPressed: () {
                Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) => AssignedLeads(
                              searchQuery: '',
                            ))); // Go back to the previous screen
              },
            ),
          ),
        ),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator()) // Loading indicator
          : Padding(
              padding: const EdgeInsets.all(0.0),
              child: ListView(
                children: [
                  // Centered Text Above Personal Details
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Center(
                      child: Text(
                        'Lead Details', // The text you want to display
                        style: WidgetSupport.inputLabel().copyWith(
                          fontSize: 20, // Adjust the font size as needed
                          fontWeight: FontWeight
                              .bold, // Adjust the font weight if needed
                        ),
                      ),
                    ),
                  ),
                  // Personal Information Section
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: Color(0xFF640D78),
                                width: 1,
                              ),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.only(
                                bottom:
                                    8.0), // Add padding below the icon and text
                            child: Row(
                              children: [
                                Icon(
                                  Icons
                                      .person, // You can replace this with any other icon you prefer
                                  color: Color(
                                      0xFF640D78), // Match the color with your border
                                  size: 24, // Set the icon size
                                ),
                                Text(
                                  "Personal Information".toUpperCase(),
                                  style: WidgetSupport.inputLabel().copyWith(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(0.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Name
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Name:',
                                    style: WidgetSupport.inputLabel(),
                                    softWrap: true,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    '${(leadDetails['first_name'] ?? '').toUpperCase()} '
                                    '${(leadDetails['middle_name'] ?? '').toUpperCase()} '
                                    '${(leadDetails['last_name'] ?? '').toUpperCase()}',
                                    style: WidgetSupport.inputLabel(),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'BOB:',
                                    style: WidgetSupport.inputLabel(),
                                    softWrap: true,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    '${leadDetails['birth_date'] ?? ''}',
                                    style: WidgetSupport.inputLabel(),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Gender:',
                                    style: WidgetSupport.inputLabel(),
                                    softWrap: true,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    '${leadDetails['gender'] ?? ''}'
                                        .toUpperCase(),
                                    style: WidgetSupport.inputLabel(),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8), // A
                              // Phone
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Phone:',
                                    style: WidgetSupport.inputLabel(),
                                    softWrap: true,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    '${leadDetails['mobile_phone'] ?? ''}',
                                    style: WidgetSupport.inputLabel(),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                  const SizedBox(height: 0),

                  // Address Information Section
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: Color(0xFF640D78),
                                width: 1,
                              ),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.only(
                                bottom:
                                    8.0), // Add padding below the icon and text
                            child: Row(
                              children: [
                                Icon(
                                  Icons
                                      .location_city, // You can replace this with any other icon you prefer
                                  color: Color(
                                      0xFF640D78), // Match the color with your border
                                  size: 24, // Set the icon size
                                ),
                                Text(
                                  "Address Information".toUpperCase(),
                                  style: WidgetSupport.inputLabel().copyWith(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(0.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'State:',
                                    style: WidgetSupport.inputLabel(),
                                    softWrap: true,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    '${leadDetails['perm_state'] ?? ''}'
                                        .toUpperCase(),
                                    style: WidgetSupport.inputLabel(),
                                    softWrap: true,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              // City
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'City:',
                                    style: WidgetSupport.inputLabel(),
                                    softWrap: true,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    '${leadDetails['perm_city'] ?? ''}'
                                        .toUpperCase(),
                                    style: WidgetSupport.inputLabel(),
                                    softWrap: true,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),

                              // Location
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Street:',
                                    style: WidgetSupport.inputLabel(),
                                    softWrap: true,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Flexible(
                                    child: Text(
                                      '${leadDetails['perm_street'] ?? ''}'
                                          .toUpperCase(),
                                      style: WidgetSupport.inputLabel(),
                                      textAlign: TextAlign.end,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Country',
                                    style: WidgetSupport.inputLabel(),
                                    softWrap: true,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    '${leadDetails['perm_country'] ?? ''}'
                                        .toUpperCase(),
                                    style: WidgetSupport.inputLabel(),
                                    softWrap: true,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              // Area
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Zip Code:',
                                      style: WidgetSupport.inputLabel()),
                                  Text(
                                      '${leadDetails['perm_zip_code'] ?? ''}'
                                          .toUpperCase(),
                                      style: WidgetSupport.inputLabel()),
                                ],
                              ),
                              const SizedBox(height: 8),
                              // ZIP
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Barangay:',
                                      style: WidgetSupport.inputLabel()),
                                  Text(
                                      '${leadDetails['perm_barangay'] ?? ''}'
                                          .toUpperCase(),
                                      style: WidgetSupport.inputLabel()),
                                ],
                              ),
                              const SizedBox(height: 8),
                              // Region
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Region:',
                                      style: WidgetSupport.inputLabel()),
                                  Text(
                                      '${leadDetails['perm_region'] ?? ''}'
                                          .toUpperCase(),
                                      style: WidgetSupport.inputLabel()),
                                ],
                              ),
                              const SizedBox(height: 8),
                              // Region
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Country Code:',
                                      style: WidgetSupport.inputLabel()),
                                  Text(
                                      '${leadDetails['perm_country_code'] ?? ''}'
                                          .toUpperCase(),
                                      style: WidgetSupport.inputLabel()),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 0),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: Color(0xFF640D78),
                                width: 1,
                              ),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.only(
                                bottom:
                                    8.0), // Add padding below the icon and text
                            child: Row(
                              children: [
                                Icon(
                                  Icons
                                      .business, // You can replace this with any other icon you prefer
                                  color: Color(
                                      0xFF640D78), // Match the color with your border
                                  size: 24, // Set the icon size
                                ),
                                Text(
                                  "Employee Information".toUpperCase(),
                                  style: WidgetSupport.inputLabel().copyWith(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(0.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Address 1
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Employer Name:',
                                    style: WidgetSupport.inputLabel(),
                                  ),
                                  Text(
                                    '${leadDetails['emp_employer_name'] ?? ''}'
                                        .toUpperCase(), // Ensure leadDetails is null-safe
                                    style: WidgetSupport.inputLabel(),
                                    softWrap: true,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Employee Industry Type:',
                                    style: WidgetSupport.inputLabel(),
                                    softWrap: true,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    '${leadDetails['emp_indus_type'] ?? ''}'
                                        .toUpperCase(),
                                    style: WidgetSupport.inputLabel(),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Employee Email Id:',
                                    style: WidgetSupport.inputLabel(),
                                    softWrap: true,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    '${leadDetails['emp_email'] ?? ''}',
                                    style: WidgetSupport.inputLabel(),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Nationality:',
                                    style: WidgetSupport.inputLabel(),
                                    softWrap: true,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    '${leadDetails['nationality'] ?? ''}'
                                        .toUpperCase(),
                                    style: WidgetSupport.inputLabel(),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Street:',
                                    style: WidgetSupport.inputLabel(),
                                    softWrap: true,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Flexible(
                                    child: Text(
                                      '${leadDetails['emp_street'] ?? ''}'
                                          .toUpperCase(),
                                      style: WidgetSupport.inputLabel(),
                                      textAlign: TextAlign.end,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'State:',
                                    style: WidgetSupport.inputLabel(),
                                    softWrap: true,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    '${leadDetails['emp_state'] ?? ''}'
                                        .toUpperCase(),
                                    style: WidgetSupport.inputLabel(),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'City:',
                                    style: WidgetSupport.inputLabel(),
                                    softWrap: true,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    '${leadDetails['emp_city'] ?? ''}'
                                        .toUpperCase(),
                                    style: WidgetSupport.inputLabel(),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Country:',
                                    style: WidgetSupport.inputLabel(),
                                    softWrap: true,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    '${leadDetails['emp_country'] ?? ''}'
                                        .toUpperCase(),
                                    style: WidgetSupport.inputLabel(),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Zip:',
                                    style: WidgetSupport.inputLabel(),
                                    softWrap: true,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    '${leadDetails['emp_zip_code'] ?? ''}'
                                        .toUpperCase(),
                                    style: WidgetSupport.inputLabel(),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Barangay:',
                                    style: WidgetSupport.inputLabel(),
                                    softWrap: true,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    '${leadDetails['emp_barangay'] ?? ''}'
                                        .toUpperCase(),
                                    style: WidgetSupport.inputLabel(),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Region:',
                                    style: WidgetSupport.inputLabel(),
                                    softWrap: true,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    '${leadDetails['emp_region'] ?? ''}'
                                        .toUpperCase(),
                                    style: WidgetSupport.inputLabel(),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Country Code:',
                                    style: WidgetSupport.inputLabel(),
                                    softWrap: true,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    leadDetails['emp_country_code'] ?? '',
                                    style: WidgetSupport.inputLabel(),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Civil Status:',
                                    style: WidgetSupport.inputLabel(),
                                    softWrap: true,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    '${leadDetails['civil_status'] ?? ''}'
                                        .toUpperCase(),
                                    style: WidgetSupport.inputLabel(),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Place Of Birth:',
                                    style: WidgetSupport.inputLabel(),
                                    softWrap: true,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    '${leadDetails['place_of_birth'] ?? ''}'
                                        .toUpperCase(),
                                    style: WidgetSupport.inputLabel(),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Sourche Company:',
                                    style: WidgetSupport.inputLabel(),
                                    softWrap: true,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    '${leadDetails['source_company'] ?? ''}'
                                        .toUpperCase(),
                                    style: WidgetSupport.inputLabel(),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Partner Name:',
                                    style: WidgetSupport.inputLabel(),
                                    softWrap: true,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    '${leadDetails['partner_name'] ?? ''}'
                                        .toUpperCase(),
                                    style: WidgetSupport.inputLabel(),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Nature Of Partnership:',
                                    style: WidgetSupport.inputLabel(),
                                    softWrap: true,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    '${leadDetails['nature_of_partnership'] ?? ''}'
                                        .toUpperCase(),
                                    style: WidgetSupport.inputLabel(),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Monthly Income:',
                                    style: WidgetSupport.inputLabel(),
                                    softWrap: true,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    '${leadDetails['fin_monthly_income'] ?? ''}'
                                        .toUpperCase(),
                                    style: WidgetSupport.inputLabel(),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Source Of Funds:',
                                    style: WidgetSupport.inputLabel(),
                                    softWrap: true,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    '${leadDetails['fin_src_of_funds'] ?? ''}'
                                        .toUpperCase(),
                                    style: WidgetSupport.inputLabel(),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Source Of Funds Code:',
                                    style: WidgetSupport.inputLabel(),
                                    softWrap: true,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    '${leadDetails['fin_src_of_funds_code'] ?? ''}'
                                        .toUpperCase(),
                                    style: WidgetSupport.inputLabel(),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 0),
                  // KYC Details Section
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: Color(0xFF640D78),
                                width: 1,
                              ),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.only(
                                bottom:
                                    8.0), // Add padding below the icon and text
                            child: Row(
                              children: [
                                Icon(
                                  Icons
                                      .business, // You can replace this with any other icon you prefer
                                  color: Color(
                                      0xFF640D78), // Match the color with your border
                                  size: 24, // Set the icon size
                                ),
                                Text(
                                  "Verification Information".toUpperCase(),
                                  style: WidgetSupport.inputLabel().copyWith(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(0.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Email Verification:',
                                    style: WidgetSupport.inputLabel(),
                                    softWrap: true,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    leadDetails['email_verification'] ?? '',
                                    style: WidgetSupport.inputLabel(),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Income Verification:',
                                    style: WidgetSupport.inputLabel(),
                                    softWrap: true,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    '${leadDetails['income_validation'] ?? ''}',
                                    style: WidgetSupport.inputLabel(),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Address Verification:',
                                    style: WidgetSupport.inputLabel(),
                                    softWrap: true,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    '${leadDetails['address_validation'] ?? ''}'
                                        .toUpperCase(),
                                    style: WidgetSupport.inputLabel(),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Employment Verification:',
                                    style: WidgetSupport.inputLabel(),
                                    softWrap: true,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    '${leadDetails['employment_validation'] ?? ''}'
                                        .toUpperCase(),
                                    style: WidgetSupport.inputLabel(),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        _buildStatusDropdownField(),
                        _builddispositionDropdownField(),
                        if (visibility == false) ...[
                          _buildDependentDropdownField(),
                        ],
                        if (visibility != false) ...[
                          _buildTextField(
                            callback_date,
                            "Call Back Date",
                            "",
                            "callback_date",
                            icon: FontAwesomeIcons.calendar,
                            isRequired: false,
                          ),
                        ],
                        const SizedBox(height: 20),
                        if (leadDetails['los_status'] != "submitted")
                          ElevatedButton.icon(
                            onPressed: () {
                              updateLeadStatus();
                            },
                            label: Text(
                              "UPDATE",
                              style: TextStyle(color: Colors.white),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF6e0386),
                              padding: EdgeInsets.symmetric(
                                  horizontal: 70, vertical: 10),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  Future<void> updateLeadStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('accessToken');
    String? refresh = prefs.getString('refreshToken');

    String contact_status = _selectedStatusCode!;
    String disposition_status = _selectedStatusSubCode!;
    String sub_disposition_status = "";
    String? callBackDate;

    if (visibility == false) {
      sub_disposition_status = _selectedDependentData;
      callBackDate = null; // explicitly set null
    } else {
      sub_disposition_status = "";
      callBackDate = callback_date.text.isNotEmpty ? callback_date.text : null;
    }

    Map<String, dynamic> mappedData = {
      "contact_status": contact_status,
      "disposition_status": disposition_status,
      "sub_disposition_status": sub_disposition_status,
      "callback_date": callBackDate,
    };

    String campaign = leadDetails["campaign"].toString();
    String leadid = leadDetails["id"].toString();

    try {
      String url = "/api/campaigns/$campaign/leads/$leadid/";
      final headers = {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'User-Agent':
            'Mozilla/5.0 (Linux; Android 11; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36',
      };
      final response =
          await ApiService.patchWithHeaders(url, headers, mappedData);
      if (response != null) {
        if (response.statusCode == 200) {
          response.data;
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text('Success'),
                content: Text('Status updated successfully!'),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AssignedLeads(searchQuery: ''),
                        ),
                      );
                    },
                    child: Text('OK'),
                  ),
                ],
              );
            },
          );
        } else if (response.statusCode == 401) {
          String url = "/api/users/token-refresh/";
          final headers = {
            'Content-Type': 'application/json',
            'User-Agent':
                'Mozilla/5.0 (Linux; Android 11; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36',
          };
          Map<String, String> mappedData = {'refresh': refresh ?? ''};
          final refreshResponse =
              await ApiService.postJsonWithHeaders(url, mappedData, headers);
          if (refreshResponse != null) {
            if (refreshResponse.statusCode == 200) {
              final data = refreshResponse.data;
              await prefs.setBool('isLoggedIn', true);
              await prefs.setString('accessToken', data['access']);
              await prefs.setString('refreshToken', data['refresh']);

              await updateLeadStatus(); // retry after refresh
              return;
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text("Session expired. Please log in again.")),
              );
            }
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content:
                    Text("Failed to submit lead. Error: ${response.data}")),
          );
        }
      }
    } catch (e) {
      debugPrint("Error updating lead: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("An error occurred while updating lead.")),
      );
    }
  }

  Widget _buildStatusDropdownField() {
    return DropdownSearch<String>(
      popupProps: PopupProps.menu(
        showSearchBox: false,
        fit: FlexFit.loose,
      ),
      items: StatusCode.values.toList(),
      dropdownDecoratorProps: DropDownDecoratorProps(
        dropdownSearchDecoration: InputDecoration(
          hintText: "Select Status",
          hintStyle: WidgetSupport.inputLabel(),
        ),
      ),
      selectedItem:
          _selectedStatusCode != null ? StatusCode[_selectedStatusCode] : null,
      onChanged: (String? newValue) {
        setState(() {
          if (newValue != null) {
            _selectedStatusCode = StatusCode.entries
                .firstWhere((entry) => entry.value == newValue)
                .key;
            print(_selectedStatusCode);
            _loadDependentData(_selectedStatusCode!);
          }
        });
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Select Status';
        }
        return null;
      },
      dropdownBuilder: (BuildContext context, String? selectedItem) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              selectedItem ?? "Select Status",
              style: WidgetSupport.dropDownText(),
            ),
            const SizedBox(width: 2),
            const Text('*', style: TextStyle(color: Colors.red, fontSize: 25)),
          ],
        );
      },
    );
  }

  Widget _builddispositionDropdownField() {
    return DropdownSearch<String>(
      popupProps: PopupProps.menu(
        showSearchBox: false,
        fit: FlexFit.loose,
      ),
      items: _dependentData.values.toList(),
      dropdownDecoratorProps: DropDownDecoratorProps(
        dropdownSearchDecoration: InputDecoration(
          hintText: "Select Sub Status",
          hintStyle: WidgetSupport.inputLabel(),
        ),
      ),
      selectedItem: _selectedStatusSubCode != null
          ? _dependentData[_selectedStatusSubCode]
          : null,
      onChanged: (String? newValue) {
        setState(() {
          if (newValue != null) {
            _selectedStatusSubCode = _dependentData.entries
                .firstWhere((entry) => entry.value == newValue)
                .key;
            _subdependentData = {};
            if (newValue != "Call Back") {
              setState(() {
                visibility = false;
              });
              _loadSubSubData(_selectedStatusSubCode!);
            } else {
              setState(() {
                visibility = true;
              });
            }
          }
        });
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Select Sub Status';
        }
        return null;
      },
      dropdownBuilder: (BuildContext context, String? selectedItem) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              selectedItem ?? "Select Sub Status",
              style: WidgetSupport.dropDownText(),
            ),
            const SizedBox(width: 2),
            const Text('*', style: TextStyle(color: Colors.red, fontSize: 25)),
          ],
        );
      },
    );
  }

  Widget _buildDependentDropdownField() {
    return DropdownSearch<String>(
      popupProps: PopupProps.menu(
        showSearchBox: false,
        fit: FlexFit.loose,
      ),
      items: _subdependentData.values.toList(),
      dropdownDecoratorProps: DropDownDecoratorProps(
        dropdownSearchDecoration: InputDecoration(
          hintText: "Select Reason",
          hintStyle: WidgetSupport.inputLabel(),
        ),
      ),
      // ignore: unnecessary_null_comparison
      selectedItem: _selectedDependentData != null
          ? _subdependentData[_selectedDependentData]
          : null,
      onChanged: (String? newValue) {
        setState(() {
          if (newValue != null) {
            _selectedDependentData = _subdependentData.entries
                .firstWhere((entry) => entry.value == newValue)
                .key;
          }
        });
      },
      dropdownBuilder: (BuildContext context, String? selectedItem) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              selectedItem ?? "Select Reason",
              style: WidgetSupport.dropDownText(),
            ),
            const SizedBox(width: 2),
          ],
        );
      },
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String hintText,
    String validationMessage,
    String validationKey, {
    IconData icon = FontAwesomeIcons.solidCircleUser,
    bool obscureText = false,
    bool isRequired = true,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        label: isRequired
            ? RichText(
                text: TextSpan(
                  text: hintText,
                  style: WidgetSupport.inputLabel(),
                  children: const [
                    TextSpan(
                      text: ' *',
                      style: TextStyle(color: Colors.red, fontSize: 25),
                    ),
                  ],
                ),
              )
            : Text(hintText, style: WidgetSupport.inputLabel()),
        suffixIcon: Padding(
          padding: const EdgeInsets.all(0),
          child: Icon(
            icon,
            color: Colors.purple,
            size: 15,
          ),
        ),
      ),
    );
  }
}
