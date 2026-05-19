import 'dart:convert'; // for json.decode
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unosfa/pages/FSAModule/fsaleaddashboard.dart';
import 'package:unosfa/pages/services/api_service.dart';
import 'package:unosfa/widgetSupport/widgetstyle.dart';

class FsaCompanySingleLead extends StatefulWidget {
  final String leadId; // Lead ID passed from the previous screen

  const FsaCompanySingleLead({super.key, required this.leadId});

  @override
  State<FsaCompanySingleLead> createState() => _FsaCompanySingleLeadState();
}

class _FsaCompanySingleLeadState extends State<FsaCompanySingleLead> {
  bool isLoading = true;
  Map<String, dynamic> leadDetails = {}; // To store the lead details
  Uint8List? _imageBytes;
  // Function to fetch lead details by ID
  Future<void> fetchLeadDetails() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('accessToken');
    String? refresh = prefs.getString('refreshToken');
    try {
      String url = "/api/leads/company-leads/${widget.leadId}/";
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
            leadDetails = json.decode(response.data.body);
            isLoading = false; // Data loaded
            _fetchImage(leadDetails['kyc_document']);
          });
        } else if (response.statusCode == 401) {
          Map<String, String> mappedData = {
            'refresh': refresh ?? '',
          };
          String url = "/api/users/token-refresh/";
          final response2 = await ApiService.post(url, mappedData);
          if (response2 != null) {
            final data = json.decode(response2.body);
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
      setState(() {
        isLoading = false; // Stop loading on error
      });
    }
  }

  @override
  void initState() {
    super.initState();
    fetchLeadDetails(); // Fetch lead details when the screen is loaded
  }

  Future<void> _fetchImage(String imageUrl) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('accessToken');

    try {
      final headers = {
        'Authorization': 'Bearer $token',
        'User-Agent':
            'Mozilla/5.0 (Linux; Android 11; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36',
      };
      final response = await ApiService.getWithHeaders(imageUrl, headers);
      if (response != null) {
        if (response.statusCode == 200) {
          Uint8List imageBytes = response.data.bodyBytes;
          if (imageBytes.isNotEmpty) {
            setState(() {
              _imageBytes = imageBytes;
            });
          } else {
            _handleImageError();
          }
        } else {
          _handleImageError();
        }
      }
    } catch (e) {
      print("Image loading error: $e");
      _handleImageError();
    }
  }

  void _handleImageError() {
    if (mounted) {
      setState(() {
        _imageBytes = null;
      });
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
                        builder: (context) => FsaLeadDashBoard(
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
                        'Comapny Lead Details', // The text you want to display
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
                                  "Company Information".toUpperCase(),
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
                                    'Comapny Name:',
                                    style: WidgetSupport.inputLabel(),
                                    softWrap: true,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    '${leadDetails['company_name'] ?? ''}',
                                    style: WidgetSupport.inputLabel(),
                                  ),
                                ],
                              ),
                              const SizedBox(
                                  height: 8), // Add space between rows

                              // Phone
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Comapny Type:',
                                    style: WidgetSupport.inputLabel(),
                                    softWrap: true,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    '${leadDetails['type_name'] ?? ''}',
                                    style: WidgetSupport.inputLabel(),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),

                              // Customer Type
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Number Of Employees:',
                                    style: WidgetSupport.inputLabel(),
                                    softWrap: true,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    '${leadDetails['number_of_employees'] ?? ''}',
                                    style: WidgetSupport.inputLabel(),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),

                              // Income
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Operating Since:',
                                    style: WidgetSupport.inputLabel(),
                                    softWrap: true,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    '${leadDetails['operating_since'] ?? ''}',
                                    style: WidgetSupport.inputLabel(),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),

                              // Loan Requested
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Address 1:',
                                    style: WidgetSupport.inputLabel(),
                                    softWrap: true,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    '${leadDetails['address_line_1'] ?? ''}',
                                    style: WidgetSupport.inputLabel(),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),

                              // Interest
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Address 2:',
                                    style: WidgetSupport.inputLabel(),
                                    softWrap: true,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    '${leadDetails['address_line_1'] ?? ''}',
                                    style: WidgetSupport.inputLabel(),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),

                              // Monthly Installment
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Zip Code:',
                                    style: WidgetSupport.inputLabel(),
                                    softWrap: true,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    '${leadDetails['zip_code'] ?? ''}',
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
                                    '${leadDetails['city_name'] ?? ''}',
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
                  const SizedBox(height: 5),

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
                                  "Contact Person Information".toUpperCase(),
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
                                    'Contact Person Frist Name:',
                                    style: WidgetSupport.inputLabel(),
                                    softWrap: true,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    '${leadDetails['contact_person_first_name'] ?? ''}',
                                    style: WidgetSupport.inputLabel(),
                                    softWrap: true,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8), // Space between rows

                              // Address 2
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Contact Person Last Name:',
                                    style: WidgetSupport.inputLabel(),
                                    softWrap: true,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    '${leadDetails['contact_person_last_name'] ?? ''}',
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
                                    'Phone Number:',
                                    style: WidgetSupport.inputLabel(),
                                    softWrap: true,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    '${leadDetails['contact_person_mobile_no'] ?? ''}',
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
                                    'Email:',
                                    style: WidgetSupport.inputLabel(),
                                    softWrap: true,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text('${leadDetails['email'] ?? ''}',
                                      style: WidgetSupport.inputLabel()),
                                ],
                              ),
                              const SizedBox(height: 8),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

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
                                  "KYC Information".toUpperCase(),
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
                                    'KYC ID:',
                                    style: WidgetSupport.inputLabel(),
                                    softWrap: true,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    leadDetails['kyc_id_type'] ?? '',
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
                                    'ID Number:',
                                    style: WidgetSupport.inputLabel(),
                                    softWrap: true,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    '${leadDetails['kyc_id_number'] ?? ''}',
                                    style: WidgetSupport.inputLabel(),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Padding(
                                padding: const EdgeInsets.only(top: 16.0),
                                child: _imageBytes != null
                                    ? Image.memory(
                                        _imageBytes!,
                                        width: 300,
                                        height: 150,
                                        fit: BoxFit.cover,
                                      )
                                    : Icon(Icons.image_not_supported,
                                        size: 50, color: Colors.grey),
                              ),
                              const SizedBox(height: 1),
                            ],
                          ),
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
