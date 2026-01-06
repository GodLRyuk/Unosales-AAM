import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import 'package:unosfa/pages/FRModule/createnewlead.dart';
import 'package:unosfa/pages/generalscreens/customNavigation.dart';
import 'package:unosfa/pages/FRModule/singleleaddetail.dart';
import 'package:unosfa/pages/services/api_service.dart';
import 'package:unosfa/widgetSupport/widgetstyle.dart';

class LeadDashBoard extends StatefulWidget {
  final String searchQuery;
  const LeadDashBoard({super.key, required this.searchQuery});

  @override
  State<LeadDashBoard> createState() => _LeadDashBoardState();
}

class _LeadDashBoardState extends State<LeadDashBoard> {
  final _searchFilter = TextEditingController();
  final _toDate = TextEditingController();
  final _fromDate = TextEditingController();
  List<Map<String, String>> leads = [];
  List<Map<String, String>> filteredLeads = [];
  String filterText = '';
  bool isLoading = true;
  bool areDateFieldsVisible =
      false; // Boolean to control visibility of date fields
  DateTime? selectedFromDate;
  DateTime? selectedToDate;
  final _scrollController = ScrollController();
  bool isFetchingMore = false;
  int currentPage = 1;
  bool hasMoreData = true;
  bool isExpanded = false;
  late TutorialCoachMark tutorialCoachMark;
  final CreateLeadIconKey = GlobalKey();
  final EditLeadIconKey = GlobalKey();
  final DisplayLeadKey = GlobalKey();
  final LeadDescriptionKey = GlobalKey();
  final LeadFilterKey = GlobalKey();

  @override
  void initState() {
    fetchLeads();
    super.initState();
    selectedFromDate = DateTime.now();
    selectedToDate = DateTime.now();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose(); // Dispose the scroll controller
    super.dispose();
  }

  // Method to fetch leads
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
        "/api/leads/?search=${widget.searchQuery}&ordering=-created_at&page=$currentPage";
    final headers = {
      'Authorization': 'Bearer $token',
      'User-Agent':
          'Mozilla/5.0 (Linux; Android 11; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36',
    };
    try {
      final response = await ApiService.getWithHeaders(apiUrl, headers);
      if (response != null) {
        if (response.statusCode == 200) {
          Map<String, dynamic> data = json.decode(response.body);
          List<dynamic> leadsData = data['results'] ?? [];

          setState(() {
            if (isLoadMore) {
              leads.addAll(leadsData.map((item) => {
                    'name':
                        '${item['first_name'] ?? ''} ${item['middle_name'] ?? ''} ${item['last_name'] ?? ''}'
                            .trim(),
                    'phone': item['phone_number']?.toString() ?? '',
                    'id': item['id']?.toString() ?? '',
                  }));
            } else {
              leads = leadsData
                  .map((item) => {
                        'name':
                            '${item['first_name'] ?? ''} ${item['middle_name'] ?? ''} ${item['last_name'] ?? ''}'
                                .trim(),
                        'phone': item['phone_number']?.toString() ?? '',
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
      searchQuery = '?phone_number=${_searchFilter.text}';
    }
    if (_toDate.text.isNotEmpty && _fromDate.text.isNotEmpty) {
      searchQuery += (searchQuery.isNotEmpty ? '&' : '?') +
          'created_at_from=${_fromDate.text}&created_at_to=${_toDate.text}T23:59:59';
    }
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('accessToken');
    String? refresh = prefs.getString('refreshToken');
    try {
      String url = "/api/leads/$searchQuery";
      final headers = {
        'Authorization': 'Bearer $token',
                 'User-Agent':
                'Mozilla/5.0 (Linux; Android 11; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36', 
      };
      final response = await ApiService.getWithHeaders(url, headers);
      if (response != null) {
        if (response.statusCode == 200) {
          Map<String, dynamic> data = json.decode(response.body);
          List<dynamic> leadsData = data['results'] ?? [];
          setState(() {
            leads = leadsData.map((item) {
              return {
                'name':
                    '${item['first_name']} ${item['middle_name']} ${item['last_name']}'
                        .trim(),
                'phone': item['phone_number']?.toString() ?? '',
                'id': item['id']?.toString() ?? '',
              };
            }).toList();
            filteredLeads = List.from(leads);
            hasMoreData = data['next'] != null;

            isLoading = false;
            isFetchingMore = false;
          });
        } else if (response.statusCode == 401) {
          String url3 = "/api/users/token-refresh/";
          Map<String, String> mappedData = {'refresh': refresh ?? ''};
          final response2 = await ApiService.post(url3, mappedData);
          if (response2 != null) {
            final data = json.decode(response2.body);
            SharedPreferences prefs = await SharedPreferences.getInstance();
            await prefs.setString('accessToken', data['access']);
            await prefs.setString('refreshToken', data['refresh']);
            fetchFilteredLeads(); // Retry fetching after token refresh
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

  // Method to filter leads by phone number
  // void _filterLeads(String query) {
  //   setState(() {
  //     filterText = query;
  //     if (query.isEmpty) {
  //       filteredLeads = List.from(leads);
  //     } else {
  //       filteredLeads =
  //           leads.where((lead) => lead['phone']!.contains(query)).toList();
  //     }
  //   });
  // }

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
                          key: LeadFilterKey,
                          decoration: InputDecoration(
                            labelText: 'Filter by Phone Number',
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

                        // Date fields visibility control
                        if (areDateFieldsVisible)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              SizedBox(
                                width: 150,
                                child: TextField(
                                  controller: _fromDate,
                                  readOnly: true,
                                  onTap: () => _selectFromDate(),
                                  decoration: InputDecoration(
                                    labelText: "From Date",
                                    hintText: selectedFromDate == null
                                        ? 'Select Date'
                                        : getFormattedFromDate(
                                            selectedFromDate),
                                    enabledBorder: UnderlineInputBorder(
                                      borderSide:
                                          BorderSide(color: Colors.grey),
                                    ),
                                    focusedBorder: UnderlineInputBorder(
                                      borderSide:
                                          BorderSide(color: Color(0xFF640D78)),
                                    ),
                                    suffixIcon:
                                        Icon(Icons.calendar_month_outlined),
                                  ),
                                ),
                              ),
                              SizedBox(width: 10),
                              SizedBox(
                                width: 150,
                                child: TextField(
                                  controller: _toDate,
                                  readOnly: true,
                                  onTap: () => _selectToDate(),
                                  decoration: InputDecoration(
                                    labelText: "To Date",
                                    hintText: selectedToDate == null
                                        ? 'Select Date'
                                        : getFormattedToDate(selectedToDate),
                                    enabledBorder: UnderlineInputBorder(
                                      borderSide:
                                          BorderSide(color: Colors.grey),
                                    ),
                                    focusedBorder: UnderlineInputBorder(
                                      borderSide:
                                          BorderSide(color: Color(0xFF640D78)),
                                    ),
                                    suffixIcon:
                                        Icon(Icons.calendar_month_outlined),
                                  ),
                                ),
                              ),
                            ],
                          ),

                        SizedBox(
                          height: 10,
                        ),

                        // Search button for applying filters
                        if (areDateFieldsVisible)
                          Padding(
                            padding: const EdgeInsets.all(10.0),
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
                  if (leads == "")
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.all(
                            10), // Adding some margin around the container

                        child: ListView.builder(
                          controller:
                              _scrollController, // Attach ScrollController
                          itemCount: 1, // Add one extra item for the loader
                          itemBuilder: (context, index) {
                            return GestureDetector(
                              onTap: () {},
                              child: Container(
                                margin:
                                    const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: Colors.white,
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
                                child: ListTile(
                                  key: DisplayLeadKey,
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 15),
                                  leading: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        "Example Name".toUpperCase(),
                                        style: WidgetSupport.label(),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        "63**********",
                                        style: WidgetSupport.inputLabel(),
                                      ),
                                    ],
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        key: LeadDescriptionKey,
                                        margin:
                                            EdgeInsets.only(top: 20, right: 10),
                                        width: 100,
                                        height: 25,
                                        decoration: BoxDecoration(
                                          color: Color(0xFFc433e0),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              "Lead Type",
                                              style: TextStyle(
                                                  color: Colors.white),
                                            ),
                                          ],
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () {
                                          // Navigator.push(
                                          //   context,
                                          //   MaterialPageRoute(
                                          //     builder: (context) =>
                                          //         FsaLeadGenerate(edit: ""),
                                          //   ),
                                          // );
                                          // Navigator.push(
                                          //   context,
                                          //   MaterialPageRoute(
                                          //     builder: (context) =>
                                          //         FsaCompanyLeadGenerate(
                                          //             edit: ""),
                                          //   ),
                                          // );
                                        },
                                        child: Icon(
                                          Icons.edit,
                                          color: Color(0xFF640D78),
                                          key: EditLeadIconKey,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Icon(
                                        Icons.chevron_right,
                                        color: Color(0xFF640D78),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
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
                                                  SingleLead(leadId: leadId),
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
                                            key: index == 0
                                                ? DisplayLeadKey
                                                : null,
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
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                GestureDetector(
                                                  onTap: () {
                                                    String leadId =
                                                        leads[index]['id']!;
                                                    Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder: (context) =>
                                                            LeadGenerate(
                                                                edit: leadId),
                                                      ),
                                                    );
                                                  },
                                                  child: Icon(
                                                    Icons.edit,
                                                    color: Color(0xFF640D78),
                                                    key: index == 0
                                                        ? EditLeadIconKey
                                                        : null,
                                                  ),
                                                ),
                                                const SizedBox(width: 10),
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
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 10), // Adjust padding as needed
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            Color(0xFFc433e0),
                            Color(0xFF9a37ae),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                      child: FloatingActionButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => LeadGenerate(edit: ''),
                            ),
                          );
                        },
                        child: Icon(
                          isExpanded ? Icons.close : Icons.add,
                          color: Colors.white,
                          key: CreateLeadIconKey,
                        ),
                        backgroundColor: Colors
                            .transparent, // Set transparent so gradient is visible
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Show Date Picker for From Date
  Future<void> _selectFromDate() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedFromDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (pickedDate != null && pickedDate != selectedFromDate) {
      setState(() {
        selectedFromDate = pickedDate;
        _fromDate.text =
            getFormattedFromDate(selectedFromDate); // Update the text field
      });
    }
  }

// Show Date Picker for To Date
  Future<void> _selectToDate() async {
    DateTime? pickedDateTo = await showDatePicker(
      context: context,
      initialDate: selectedToDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (pickedDateTo != null && pickedDateTo != selectedToDate) {
      setState(() {
        selectedToDate = pickedDateTo;
        _toDate.text =
            getFormattedToDate(selectedToDate); // Update the text field
      });
    }
  }

  // Handle Refresh
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
