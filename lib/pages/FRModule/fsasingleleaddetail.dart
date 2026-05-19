import 'dart:convert'; // for json.decode
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unosfa/pages/FRModule/assignedLeads.dart';
import 'package:unosfa/pages/services/api_service.dart';
import 'package:unosfa/widgetSupport/widgetstyle.dart';

class FsaSingleAssignLead extends StatefulWidget {
  final String leadId;
  const FsaSingleAssignLead({super.key, required this.leadId});

  @override
  State<FsaSingleAssignLead> createState() => _FsaSingleAssignLeadState();
}

class _FsaSingleAssignLeadState extends State<FsaSingleAssignLead> {
  bool isLoading = true;
  Map<String, dynamic> leadDetails = {}; // To store the lead details

  // Function to fetch lead details by ID
  Future<void> fetchLeadDetails() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('accessToken');
    String? refresh = prefs.getString('refreshToken');
    try {
      String url = "/api/agents/assigned-leads/${widget.leadId}";
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

  @override
  void initState() {
    super.initState();
    fetchLeadDetails(); // Fetch lead details when the screen is loaded
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
                                    '${leadDetails['gender'].toUpperCase() ?? ''}',
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
                                  Text(
                                      '${leadDetails['perm_street'] ?? ''}'
                                          .toUpperCase(),
                                      style: WidgetSupport.inputLabel()),
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
                                  Text(
                                    '${leadDetails['emp_street'] ?? ''}'
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
                                    leadDetails['emp_country_code']
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
                  const SizedBox(height: 10),
                ],
              ),
            ),
    );
  }
}
