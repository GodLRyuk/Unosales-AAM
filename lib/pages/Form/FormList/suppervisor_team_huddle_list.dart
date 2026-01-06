import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unosfa/pages/Form/supervisor_team_huddle.dart';
import 'package:unosfa/pages/generalscreens/customNavigation.dart';
import 'package:unosfa/pages/services/api_service.dart';
import 'package:unosfa/widgetSupport/widgetstyle.dart';
import 'package:intl/intl.dart';
import 'dart:async';

class SuppervisorHuddleList extends StatefulWidget {
  @override
  State<SuppervisorHuddleList> createState() => _CampaignlistState();
}

class _CampaignlistState extends State<SuppervisorHuddleList> {
  final _searchFilter = TextEditingController();
  final _toDate = TextEditingController();
  final _fromDate = TextEditingController();
  List<Map<String, String>> leads = [];
  List<Map<String, String>> filteredLeads = [];
  String filterText = '';
  bool isLoading = true;
  bool areDateFieldsVisible =
      false; // Boolean to control visibility of date fields
  // DateTime? selectedFromDate;
  // DateTime? selectedToDate;
  final _scrollController = ScrollController();
  bool isFetchingMore = false;
  int currentPage = 1;
  bool hasMoreData = true;
  DateTime? startDate;
  DateTime? endDate;
  Duration totalDuration = Duration.zero;
  Duration timeLeft = Duration.zero;
  Timer? countdownTimer;

  @override
  void initState() {
    super.initState();
    fetchLeads(); // Fetch leads on initialization
    _scrollController.addListener(_onScroll);
    _startCountdown();
  }

  @override
  void dispose() {
    _scrollController.dispose(); // Dispose the scroll controller
    countdownTimer?.cancel();
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
    String apiUrl = '/api/timesheet/supervisor-team-huddles/';
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
                    'location_name': '${item['location_name'] ?? ''}'.trim(),
                    'created_at': item['created_at']?.toString() ?? '',
                    'id': item['id']?.toString() ?? '',
                  }));
            } else {
              leads = leadsData
                  .map((item) => {
                        'location_name':
                            '${item['location_name'] ?? ''}'.trim(),
                        'created_at': item['created_at']?.toString() ?? '',
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
      if (mounted) {
        setState(() {
          isLoading = false;
          isFetchingMore = false;
        });
      }

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
    String searchQuery = _searchFilter.text;
    // if (_fromDate.text.isNotEmpty) {
    //   searchQuery += 'created_at=${_fromDate.text}T23:59:59';
    // }
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('accessToken');
    String? refresh = prefs.getString('refreshToken');
    String url = '/api/timesheet/supervisor-team-huddles/?created_at__gte=${searchQuery}T00:00:00&created_at__lte=${searchQuery}T23:59:59';
    final headers = {
      'Authorization': 'Bearer $token',
      'User-Agent':
          'Mozilla/5.0 (Linux; Android 11; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36',
    };
    try {
      final response = await ApiService.getWithHeaders(url, headers);
      if (response != null) {
        if (response.statusCode == 200) {
          Map<String, dynamic> data = json.decode(response.body);
          List<dynamic> leadsData = data['results'] ?? [];
          setState(() {
            leads = leadsData.map((item) {
              return {
                'location_name': '${item['location_name'] ?? ''}'.trim(),
                'created_at': item['created_at']?.toString() ?? '',
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
          final response2 =
              await ApiService.getWithHeaders(url, {'refresh': refresh ?? ''});
          if (response2 != null) {
            final data = json.decode(response2.body);
            SharedPreferences prefs = await SharedPreferences.getInstance();
            await prefs.setString('accessToken', data['access']);
            await prefs.setString('refreshToken', data['refresh']);
            fetchFilteredLeads();
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

  void _startCountdown() {
    if (endDate == null) return;
    countdownTimer?.cancel(); // Cancel previous timer if exists
    countdownTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      final now = DateTime.now();
      final remaining = endDate!.difference(now);
      if (remaining.isNegative) {
        timer.cancel();
        setState(() {
          timeLeft = Duration.zero;
        });
      } else {
        setState(() {
          timeLeft = remaining;
        });
      }
    });
  }

  String formatDuration(Duration duration) {
    if (duration.inSeconds <= 0) return "Expired";

    String twoDigits(int n) => n.toString().padLeft(2, '0');

    // Check if the duration is more than 24 hours, if so, convert to days.
    int days = duration.inDays;
    int hours = duration.inHours.remainder(24);
    int minutes = duration.inMinutes.remainder(60);
    int seconds = duration.inSeconds.remainder(60);

    if (days > 0) {
      return "$days days   Hr:${twoDigits(hours)} Min:${twoDigits(minutes)} Sec:${twoDigits(seconds)}";
    } else if (hours >= 24) {
      return "$days days ${twoDigits(hours)}${twoDigits(minutes)}:${twoDigits(seconds)}";
    } else {
      return "${twoDigits(hours)}:${twoDigits(minutes)}:${twoDigits(seconds)}";
    }
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
                // await fetchFilteredLeads();
              },
              child: Column(
                children: [
                  SizedBox(
                    height: 10,
                  ),
                  Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // TextField that opens a calendar only when tapped
                        TextField(
                          controller: _searchFilter,
                          readOnly: true, // Prevent keyboard from appearing
                          onTap: () async {
                            // Show the date picker ONLY when tapping the field
                            DateTime? pickedDate = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2101),
                            );

                            if (pickedDate != null) {
                              setState(() {
                                _searchFilter.text =
                                    "${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}";
                              });
                            }
                          },
                          decoration: InputDecoration(
                            labelText: 'Select Date',
                            border: const UnderlineInputBorder(
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
                                onPressed: () {
                                  // 🔹 Search action — no calendar here
                                  fetchFilteredLeads();
                                },
                                icon: const Icon(
                                  Icons.search,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          style: const TextStyle(height: 1),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.all(10), // Margin around the container
                      child: isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : leads.isEmpty
                              ? const Center(
                                  child: Text(
                                    'No Leads Found',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                )
                              : ListView.builder(
                                  controller: _scrollController, // Attach ScrollController
                                  itemCount: leads.length + 1, // Add one extra item for loader
                                  itemBuilder: (context, index) {
                                    if (index < leads.length) {
                                      return GestureDetector(
                                        onTap: () {
                                          String id = leads[index]['id']!;
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  SuppervisorHuddle(id: id, isView: true),
                                            ),
                                          );
                                        },
                                        child: Container(
                                          margin: const EdgeInsets.symmetric(vertical: 10),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
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
                                          child: ListTile(
                                            contentPadding:
                                                const EdgeInsets.symmetric(horizontal: 8),
                                            leading: SizedBox(
                                              width: 70, // slightly smaller width for better spacing
                                              child: Image.asset(
                                                'images/campaign.jpg',
                                                height: 55,
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                            title: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text("Team Huddle".toUpperCase(),
                                                  style: WidgetSupport.inputLabel(),
                                                  softWrap: true,
                                                  overflow: TextOverflow.ellipsis,
                                                  maxLines: 3,
                                                ),
                                                const SizedBox(height: 5),
                                                Text(
                                                  DateFormat('dd MMM yyyy').format(
                                                    DateTime.parse(
                                                      leads[index]['created_at']!,
                                                    ),
                                                  ),
                                                  style: WidgetSupport.inputLabel(),
                                                ),
                                              ],
                                            ),
                                            trailing: const Icon(
                                              Icons.chevron_right,
                                              color: Color(0xFF640D78),
                                            ),
                                          ),
                                        ),
                                      );
                                    } else {
                                      // Loader or "No more data" indicator
                                      return hasMoreData
                                          ? const Center(child: CircularProgressIndicator())
                                          : const Center(
                                              child: Text(
                                                'No more data',
                                                style: TextStyle(fontWeight: FontWeight.w500),
                                              ),
                                            );
                                    }
                                  },
                                ),
                    ),
                  ),
                ],
              ),
            ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Container(
              width: 56, // Standard FAB size
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Colors.blue, Colors.purple],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: FloatingActionButton(
                onPressed: () {
                  // 👉 put your action here
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SuppervisorHuddle(),
                    ),
                  );
                },
                tooltip: 'Create New Lead',
                child: const Icon(Icons.add, color: Colors.white),
                backgroundColor:
                    Colors.transparent, // So gradient shows from container
                elevation: 0, // Optional: remove shadow if needed
              ),
            ),
          ],
        ),
      ),
    );
  }
}
