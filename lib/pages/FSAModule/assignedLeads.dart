import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unosfa/pages/FSAModule/singleassignedleads.dart';
import 'package:unosfa/pages/generalscreens/customNavigation.dart';
import 'package:unosfa/pages/services/api_service.dart';
import 'package:unosfa/widgetSupport/widgetstyle.dart';

class AssignedLeads extends StatefulWidget {
  final String searchQuery;
  const AssignedLeads({super.key, required this.searchQuery});

  @override
  State<AssignedLeads> createState() => _AssignedLeadsState();
}

class _AssignedLeadsState extends State<AssignedLeads> {
  final _searchFilter = TextEditingController();
  List<Map<String, String>> leads = [];
  List<Map<String, String>> filteredLeads = [];
  String filterText = '';
  bool isLoading = true;
  bool areDateFieldsVisible = false;
  DateTime? selectedFromDate;
  DateTime? selectedToDate;
  final _scrollController = ScrollController();
  bool isFetchingMore = false;
  int currentPage = 1;
  bool hasMoreData = true;

  @override
  void initState() {
    super.initState();
    selectedFromDate = DateTime.now();
    selectedToDate = DateTime.now();
    fetchLeads(); // Fetch leads on initialization
    _scrollController.addListener(_onScroll); // Attach scroll listener
  }

  @override
  void dispose() {
    _scrollController.dispose(); // Dispose the scroll controller
    super.dispose();
  }

// Fetch leads from API
  Future<void> fetchLeads({bool isLoadMore = false}) async {
    if (isLoadMore) {
      setState(() {
        isFetchingMore = true;
      });
    } else {
      setState(() {
        isLoading = true;
      });
    }

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('accessToken');
    String apiUrl =
        '/api/agents/assigned-leads/?search=${widget.searchQuery}&ordering=-created_at';
    final headers = {
      'Authorization': 'Bearer $token',
      'User-Agent':
          'Mozilla/5.0 (Linux; Android 11; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36',
    };
    print(apiUrl);
    print(token);
    try {
      final response = await ApiService.getWithHeaders(
        apiUrl,
        headers,
      );
      if (response != null) {
        if (response.statusCode == 200) {
          Map<String, dynamic> data = response.data;
          List<dynamic> leadsData = data['results'] ?? [];
          setState(() {
            if (isLoadMore) {
              leads.addAll(leadsData.map((item) => {
                    'name':
                        '${item['first_name'] ?? ''} ${item['middle_name'] ?? ''} ${item['last_name'] ?? ''}'
                            .trim(),
                    'phone': item['mobile_phone']?.toString() ?? '',
                    'id': item['id']?.toString() ?? '',
                  }));
            } else {
              leads = leadsData
                  .map((item) => {
                        'name':
                            '${item['first_name'] ?? ''} ${item['middle_name'] ?? ''} ${item['last_name'] ?? ''}'
                                .trim(),
                        'phone': item['mobile_phone']?.toString() ?? '',
                        'id': item['id']?.toString() ?? '',
                      })
                  .toList();
            }

            filteredLeads = List.from(leads);

            // Check if there's more data
            hasMoreData = data['next'] != null;

            isLoading = false;
            isFetchingMore = false;
          });
        } else {
          setState(() {
            isLoading = false;
            isFetchingMore = false;
          });
          throw Exception('Failed to load leads');
        }
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        isFetchingMore = false;
      });
      print('Error fetching leads: $e');
    }
  }

// Scroll listener
  void _onScroll() {
    if (_scrollController.position.pixels ==
            _scrollController.position.maxScrollExtent &&
        !isFetchingMore &&
        hasMoreData) {
      currentPage++;
      fetchLeads(isLoadMore: true); // Fetch more data
    }
  }

  Future<void> fetchFilteredLeads() async {
    String searchQuery = '';
    if (_searchFilter.text.isNotEmpty) {
      searchQuery = '${_searchFilter.text}';
    }
    // if (_toDate.text.isNotEmpty && _fromDate.text.isNotEmpty) {
    //   searchQuery += (searchQuery.isNotEmpty ? '&' : '?') +
    //       'created_at_from=${_fromDate.text}&created_at_to=${_toDate.text}T23:59:59';
    // }
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('accessToken');
    String? refresh = prefs.getString('refreshToken');
    try {
      String url =
          '/api/agents/assigned-leads/?search=$searchQuery&ordering=-created_at';
      final headers = {
        'Authorization': 'Bearer $token',
        'User-Agent':
            'Mozilla/5.0 (Linux; Android 11; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36',
      };
      final response = await ApiService.getWithHeaders("$url", headers);
      if (response != null) {
        if (response.statusCode == 200) {
          Map<String, dynamic> data = response.data;
          List<dynamic> leadsData = data['results'] ?? [];
          setState(() {
            leads = leadsData.map((item) {
              return {
                'name':
                    '${item['first_name'] ?? ''} ${item['middle_name'] ?? ''} ${item['last_name'] ?? ''}'
                        .trim(),
                'phone': item['mobile_phone']?.toString() ?? '',
                'id': item['id']?.toString() ?? '',
              };
            }).toList();
            filteredLeads = List.from(leads);
            hasMoreData = data['next'] != null;

            isLoading = false;
            isFetchingMore = false;
          });
        } else if (response.statusCode == 401) {
          String url = '/api/users/token-refresh/';

          try {
            final response2 = await ApiService.post(
              url,
              {
                'refresh': refresh ?? '',
                'User-Agent':
                    'Mozilla/5.0 (Linux; Android 11; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36',
              },
            );

            if (response2 != null && response2.statusCode == 200) {
              final data = json.decode(response2.data);
              SharedPreferences prefs = await SharedPreferences.getInstance();
              await prefs.setString('accessToken', data['access']);
              await prefs.setString('refreshToken', data['refresh']);
              fetchFilteredLeads(); // Retry after refreshing token
            } else {
              print(
                  "🔒 Token refresh failed. Status: ${response2?.statusCode}");
              // Handle token expiration here (e.g., logout)
            }
          } catch (e) {
            print("🔴 Error during token refresh: $e");
          }
        } else {
          throw Exception('Failed to load leads');
        }
      }
    } catch (e) {
      print('Error fetching leads: $e');
      setState(() {
        isLoading = false; // Stop loading on error
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching leads: $e')),
      );
    }
  }

  // Format the date string
  String getFormattedFromDate(DateTime? date) {
    if (date == null) {
      return 'Select Date';
    }
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  String getFormattedToDate(DateTime? date1) {
    if (date1 == null) {
      return 'Select Date';
    }
    return "${date1.year}-${date1.month.toString().padLeft(2, '0')}-${date1.day.toString().padLeft(2, '0')}";
  }

  // Toggle visibility of the date fields
  void _toggleDateFieldsVisibility() {
    setState(() {
      areDateFieldsVisible = !areDateFieldsVisible;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
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
                Navigator.pushReplacement(context,
                    MaterialPageRoute(builder: (context) => NavigationPage()));
              },
            ),
          ),
        ),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async {
                // Refresh the data or reset necessary states
                await fetchFilteredLeads();
              },
              child: Column(
                children: [
                  // Filter section
                  Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // TextField for phone number filter
                        TextField(
                          controller: _searchFilter,
                          decoration: InputDecoration(
                            labelText: 'Search Leads',
                            border: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.grey),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(0),
                              borderSide: const BorderSide(
                                color: Colors.grey,
                                width: 1.0,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(0),
                              borderSide: const BorderSide(
                                color: Color(0xFFac00d0),
                                width: 1.0,
                              ),
                            ),
                            suffixIcon: Container(
                              color: const Color(0xFFac00d0),
                              child: IconButton(
                                onPressed: _toggleDateFieldsVisibility,
                                icon: const Icon(
                                  Icons.filter_list,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),

                          style: TextStyle(height: 1),
                          // onChanged: _filterLeads, // Uncomment if needed
                        ),
                        SizedBox(
                          height: 10,
                        ),
                        // Search button for applying filters
                        if (areDateFieldsVisible)
                          Padding(
                            padding: const EdgeInsets.all(0),
                            child: Column(
                              children: [
                                SizedBox(
                                  child: Container(
                                    width: MediaQuery.of(context).size.width,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Color(0xFFc433e0),
                                          Color(0xFF9a37ae)
                                        ], // Define your gradient colors
                                        begin: Alignment
                                            .topLeft, // Start from top-left
                                        end: Alignment
                                            .bottomRight, // End at bottom-right
                                      ),
                                    ),
                                    child: ElevatedButton(
                                      onPressed: () {
                                        fetchFilteredLeads();
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.transparent,
                                        elevation: 0,
                                      ),
                                      child: Text(
                                        "Search",
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 18), // Text style
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  // ListView.builder for displaying filtered leads
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.all(
                          10), // Adding some margin around the container

                      child: isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : leads.isEmpty
                              ? const Center(
                                  child: Text(
                                    'No Leads Found',
                                    style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold),
                                  ),
                                )
                              : ListView.builder(
                                  controller:
                                      _scrollController, // Attach ScrollController
                                  itemCount: leads.length +
                                      1, // Add one extra item for the loader
                                  itemBuilder: (context, index) {
                                    if (index < leads.length) {
                                      return GestureDetector(
                                        onTap: () {
                                          String leadId = leads[index]['id']!;
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  FSASingleAssignedLead(
                                                      leadId: leadId),
                                            ),
                                          );
                                        },
                                        child: Container(
                                          margin: const EdgeInsets.symmetric(
                                              vertical: 10),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            border: Border(
                                              top: BorderSide(
                                                  color: Color(0xFF640D78),
                                                  width: 1.0),
                                              bottom: BorderSide(
                                                  color: Color(0xFF640D78),
                                                  width: 1.0),
                                              left: BorderSide(
                                                  color: Color(0xFF640D78),
                                                  width: 5.0),
                                              right: BorderSide(
                                                  color: Color(0xFF640D78),
                                                  width: 1.0),
                                            ),
                                          ),
                                          child: ListTile(
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                                    horizontal: 15),
                                            leading: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Text(
                                                  leads[index]['name']!
                                                      .toUpperCase(),
                                                  style: WidgetSupport.label(),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  leads[index]['phone']!,
                                                  style: WidgetSupport
                                                      .inputLabel(),
                                                ),
                                              ],
                                            ),
                                            trailing: Row(
                                              mainAxisSize: MainAxisSize
                                                  .min, // Ensures the row doesn't take up unnecessary space
                                              children: [
                                                // Container(
                                                //   padding: EdgeInsets.symmetric(
                                                //       horizontal: 10,
                                                //       vertical:
                                                //           5), // Added padding for better spacing
                                                //   decoration: BoxDecoration(
                                                //     color: Color(
                                                //         0xFFc433e0), // Default color if no condition matches
                                                //     borderRadius:
                                                //         BorderRadius.circular(
                                                //             10),
                                                //   ),
                                                //   child: Text(
                                                //     leads[index]
                                                //             ['description'] ??
                                                //         '',
                                                //     style: TextStyle(
                                                //         color: Colors.white),
                                                //   ),
                                                // ),
                                                const SizedBox(
                                                    width:
                                                        8), // Spacing between container and icon
                                                Icon(
                                                  Icons.chevron_right,
                                                  color: Color(0xFF640D78),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    } else {
                                      // Loader at the bottom
                                      return hasMoreData
                                          ? Center(
                                              child:
                                                  CircularProgressIndicator())
                                          : Center(child: Text('No more data'));
                                    }
                                  },
                                ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class LeadDetailPage extends StatelessWidget {
  final String leadId;
  const LeadDetailPage({super.key, required this.leadId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Lead Details"),
      ),
      body: Center(
        child: Text(
            'Lead ID: $leadId'), // Here you can fetch and display the lead details
      ),
    );
  }
}
