import 'dart:convert'; // for json.decode
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unosfa/pages/FSAModule/fsaleaddashboard.dart';
import 'package:unosfa/pages/services/api_service.dart';
import 'package:unosfa/widgetSupport/widgetstyle.dart';

class CustomerSingleLead extends StatefulWidget {
  final String leadId; // Lead ID passed from the previous screen

  const CustomerSingleLead({super.key, required this.leadId});

  @override
  State<CustomerSingleLead> createState() => _CustomerSingleLeadState();
}

class _CustomerSingleLeadState extends State<CustomerSingleLead> {
  bool isLoading = true;
  Map<String, dynamic> leadDetails = {}; // To store the lead details

  // Function to fetch lead details by ID
  Future<void> fetchLeadDetails() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('accessToken');
    String? refresh = prefs.getString('refreshToken');
    try {
      String url = "/api/leads/${widget.leadId}/";
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
                                  Flexible(
                                    child: Text(
                                      '${leadDetails['first_name'] ?? ''} ${leadDetails['middle_name'] ?? ''} ${leadDetails['last_name'] ?? ''}',
                                      style: WidgetSupport.inputLabel(),
                                      softWrap: true,
                                      textAlign: TextAlign.end,
                                    ),
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
                                    'Phone:',
                                    style: WidgetSupport.inputLabel(),
                                    softWrap: true,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    '${leadDetails['phone_number'] ?? ''}',
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
                                    'Customer Type:',
                                    style: WidgetSupport.inputLabel(),
                                    softWrap: true,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    leadDetails['customer_type'] == 'salaried'
                                        ? "Salaried"
                                        : "Self Employed",
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
                                    'Income:',
                                    style: WidgetSupport.inputLabel(),
                                    softWrap: true,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    '${leadDetails['income'] ?? ''}',
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
                                    'Loan Requested:',
                                    style: WidgetSupport.inputLabel(),
                                    softWrap: true,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    '${leadDetails['loan_amount_requested'] ?? ''}',
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
                                    'Interest:',
                                    style: WidgetSupport.inputLabel(),
                                    softWrap: true,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    '${leadDetails['interest'] ?? ''}%',
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
                                    'Monthly Installment:',
                                    style: WidgetSupport.inputLabel(),
                                    softWrap: true,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    '${leadDetails['monthly_installment'] ?? ''}',
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
                              // Address 1
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
                                  Flexible(
                                    child: Text(
                                      '${leadDetails['address1'] ?? ''}',
                                      style: WidgetSupport.inputLabel(),
                                      softWrap: true,
                                      textAlign: TextAlign.end,
                                    ),
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
                                    'Address 2:',
                                    style: WidgetSupport.inputLabel(),
                                    softWrap: true,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Flexible(
                                    child: Text(
                                      '${leadDetails['address2'] ?? ''}',
                                      style: WidgetSupport.inputLabel(),
                                      softWrap: true,
                                      textAlign: TextAlign.end,
                                    ),
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
                                    '${leadDetails['city_name'] ?? ''}',
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
                                    'Location:',
                                    style: WidgetSupport.inputLabel(),
                                    softWrap: true,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Flexible(
                                    child: Text(
                                      '${leadDetails['location'] ?? ''}',
                                      style: WidgetSupport.inputLabel(),
                                      softWrap: true,
                                      textAlign: TextAlign.end,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              // Address 2
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Location Type',
                                    style: WidgetSupport.inputLabel(),
                                    softWrap: true,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    '${leadDetails['location_type_description'] ?? ''}',
                                    style: WidgetSupport.inputLabel(),
                                    softWrap: true,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8), // Space between rows

                              // ZIP
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('ZIP:',
                                      style: WidgetSupport.inputLabel()),
                                  Text('${leadDetails['zip'] ?? ''}',
                                      style: WidgetSupport.inputLabel()),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 5),

                  // Company Information Section
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
                              // Address 1
                              leadDetails['company_name'] != null &&
                                      leadDetails['company_name']!.isNotEmpty
                                  ? Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Company Name:',
                                          style: WidgetSupport.inputLabel(),
                                        ),
                                        MediaQuery.of(context).size.width < 600
                                            ? Expanded(
                                                child: Text(
                                                  '${leadDetails['company_name'] ?? ''}', // Ensure leadDetails is null-safe
                                                  style: WidgetSupport
                                                      .inputLabel(),
                                                  softWrap: true,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              )
                                            : Text(
                                                '${leadDetails['company_name'] ?? ''}', // Ensure leadDetails is null-safe
                                                style:
                                                    WidgetSupport.inputLabel(),
                                                softWrap: true,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                      ],
                                    )
                                  : SizedBox(),
                              const SizedBox(height: 8), // Space between rows

                              // Address 2
                              leadDetails['business_name'] != null &&
                                      leadDetails['business_name']!.isNotEmpty
                                  ? Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Business Name:',
                                          style: WidgetSupport.inputLabel(),
                                          softWrap: true,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          '${leadDetails['business_name']}',
                                          style: WidgetSupport.inputLabel(),
                                        ),
                                      ],
                                    )
                                  : SizedBox(),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 5),

                  // Loan Information Section
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
                                      .monetization_on_outlined, // You can replace this with any other icon you prefer
                                  color: Color(
                                      0xFF640D78), // Match the color with your border
                                  size: 24, // Set the icon size
                                ),
                                Text(
                                  "Loan Information".toUpperCase(),
                                  style: WidgetSupport.inputLabel().copyWith(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
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
                                    'Tenor:',
                                    style: WidgetSupport.inputLabel(),
                                    softWrap: true,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    '${leadDetails['tenor_description'] ?? ''}',
                                    style: WidgetSupport.inputLabel(),
                                    softWrap: true,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8), // Space between rows

                              // Desposition Code
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Disposition:',
                                    style: WidgetSupport.inputLabel(),
                                    softWrap: true,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    '${leadDetails['disposition_code_description'] ?? ''}',
                                    style: WidgetSupport.inputLabel(),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              // Sub-Desposition Code
                              leadDetails['sub_disposition_code_description'] !=
                                          null &&
                                      leadDetails[
                                              'sub_disposition_code_description']!
                                          .isNotEmpty
                                  ? Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Sub-Disposition:',
                                          style: WidgetSupport.inputLabel(),
                                          softWrap: true,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          '${leadDetails['sub_disposition_code_description'] ?? ''}',
                                          style: WidgetSupport.inputLabel(),
                                        ),
                                      ],
                                    )
                                  : SizedBox(),
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
