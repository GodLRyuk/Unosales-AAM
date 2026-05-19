import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unosfa/pages/Form/daily_activity_planerView.dart';
import 'package:unosfa/pages/Form/daily_agent_planer.dart';
import 'package:unosfa/pages/generalscreens/customNavigation.dart';
import 'package:unosfa/pages/services/api_service.dart';
import 'package:unosfa/widgetSupport/widgetstyle.dart';
import 'dart:async';

class DailyActivityList extends StatefulWidget {
  @override
  State<DailyActivityList> createState() => _CampaignlistState();
}

class _CampaignlistState extends State<DailyActivityList> {
  final _searchFilter = TextEditingController();
  List<Map<String, dynamic>> leads = [];
  bool isLoading = true;
  final _scrollController = ScrollController();
  bool isFetchingMore = false;
  String? nextPageUrl;
  Timer? countdownTimer;
  Duration timeLeft = Duration.zero;

  late Map<String, String> DispositionCode = {}; // stores id -> description
  late Map<String, String> SubDispositionCode = {}; // for sub codes

  @override
  void initState() {
    super.initState();
    fetchLeads();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    countdownTimer?.cancel();
    super.dispose();
  }

  // ===================== FETCH LEADS =======================
  Future<void> fetchLeads({bool isLoadMore = false, String? url}) async {
    if (isLoadMore) {
      setState(() => isFetchingMore = true);
    } else {
      setState(() => isLoading = true);
    }

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('accessToken');

    final headers = {
      'Authorization': 'Bearer $token',
      'User-Agent':
          'Mozilla/5.0 (Linux; Android 11; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36',
    };

    String apiUrl = url ?? '/api/timesheet/agent-daily-activities/';

    try {
      final response = await ApiService.getWithHeaders(apiUrl, headers);
      if (response != null && response.statusCode == 200) {
        final data = json.decode(response.data);
        final leadsData = data['results'];
        List<Map<String, dynamic>> newLeads =
            List<Map<String, dynamic>>.from(leadsData);
        setState(() {
          if (isLoadMore) {
            leads.addAll(newLeads);
          } else {
            leads = newLeads;
          }
          nextPageUrl = data['next'];
          isLoading = false;
          isFetchingMore = false;
        });
      } else {
        throw Exception('Failed to load leads');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
          isFetchingMore = false;
        });
      }
      debugPrint('Error fetching leads: $e');
    }
  }

  // ===================== GET DISPOSITION CODES =======================
  

  // ==================== SCROLL LISTENER ====================
  void _onScroll() {
    if (_scrollController.position.pixels ==
            _scrollController.position.maxScrollExtent &&
        !isFetchingMore &&
        nextPageUrl != null) {
      fetchLeads(isLoadMore: true, url: nextPageUrl);
    }
  }

  // ======================= UI ==============================
  Future<void> fetchFilteredLeads({bool isLoadMore = false}) async {
    // if (_searchFilter.text.isEmpty) {
    //   fetchLeads();
    //   return;
    // }

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('accessToken');

    String date = _searchFilter.text;
    String url =
        '/api/timesheet/agent-daily-activities/?created_at__gte=${date}T00:00:00&created_at__lte=${date}T23:59:59';
    final headers = {
      'Authorization': 'Bearer $token',
      'User-Agent':
          'Mozilla/5.0 (Linux; Android 11; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36',
    };
    try {
      final response = await ApiService.getWithHeaders(url, headers);
      if (response != null && response.statusCode == 200) {
                final data = json.decode(response.data);

        final leadsData = data['results'];
        List<Map<String, dynamic>> newLeads =
            List<Map<String, dynamic>>.from(leadsData);
        setState(() {
          if (isLoadMore) {
            leads.addAll(newLeads);
          } else {
            leads = newLeads;
          }
          nextPageUrl = data['next'];
          isLoading = false;
          isFetchingMore = false;
        });
      } else {
        throw Exception('Failed to load leads');
      }
    } catch (e) {
      debugPrint('Error fetching leads: $e');
      setState(() => isLoading = false);
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
                  MaterialPageRoute(builder: (context) => NavigationPage()),
                );
              },
            ),
          ),
        ),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: TextField(
                    controller: _searchFilter,
                    readOnly: true,
                    onTap: () async {
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
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFFac00d0)),
                      ),
                      suffixIcon: Container(
                        color: Color(0xFFac00d0),
                        child: IconButton(
                          onPressed: fetchFilteredLeads,
                          icon: Icon(Icons.search, color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: leads.isEmpty
                      ? Center(
                          child: Text(
                            'No Leads Found',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        )
                      : Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: ListView.builder(
                          controller: _scrollController,
                          itemCount: leads.length + 1,
                          itemBuilder: (context, index) {
                            if (index < leads.length) {
                              final lead = leads[index];

                              // Parse created_at safely
                              String createdAtStr = (lead['created_at'] ?? '').toString();
                              DateTime? createdAt;

                              try {
                                // Parse ISO 8601 timestamp with timezone
                                createdAt = DateTime.parse(createdAtStr);

                                // Convert to local timezone
                                createdAt = createdAt.toLocal();

                                // Remove time, keep only date
                                createdAt = DateTime(createdAt.year, createdAt.month, createdAt.day);
                              } catch (_) {
                                createdAt = null;
                              }

                              DateTime now = DateTime.now();

                              // Today's date (local, date only)
                              DateTime todayDateOnly = DateTime(now.year, now.month, now.day);


                              // Format date as yyyy-MM-dd
                              String formattedCreatedAt = createdAt != null
                                  ? "${createdAt.year.toString().padLeft(4, '0')}-${createdAt.month.toString().padLeft(2, '0')}-${createdAt.day.toString().padLeft(2, '0')}"
                                  : "Unknown Date";

                              String formattedToday = "${todayDateOnly.year.toString().padLeft(4, '0')}-${todayDateOnly.month.toString().padLeft(2, '0')}-${todayDateOnly.day.toString().padLeft(2, '0')}";
                              bool isToday = (createdAt != null && formattedCreatedAt == formattedToday);
                              return GestureDetector(
                                onTap: () {
                                  String id = (lead['id'] ?? '').toString();
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => DailyActivityViewPage(
                                        pageMode: 'view',
                                        activityId: id,
                                      ),
                                    ),
                                  );
                                },
                                child: Container(
                                  height: 75,
                                  margin: const EdgeInsets.symmetric(vertical: 5),
                                  decoration: BoxDecoration(
                                    color: isToday ? const Color(0xFFEEDFF2) : Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    border: const Border(
                                      left: BorderSide(color: Color(0xFF640D78), width: 5.0),
                                      top: BorderSide(color: Color(0xFF640D78), width: 1.0),
                                      bottom: BorderSide(color: Color(0xFF640D78), width: 1.0),
                                      right: BorderSide(color: Color(0xFF640D78), width: 1.0),
                                    ),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                isToday? "Today Activity ": formattedCreatedAt,
                                                style: WidgetSupport.mediumText().copyWith(
                                                  color: isToday
                                                      ? const Color(0xFF640D78)
                                                      : Colors.black,
                                                  fontWeight: isToday
                                                      ? FontWeight.bold
                                                      : FontWeight.normal,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            } else {
                              return nextPageUrl != null
                                  ? const Center(child: CircularProgressIndicator())
                                  : const Center(child: Text('No more data'));
                            }
                          },
                        ),
                      ),

                ),
              ],
            ),
      floatingActionButton: Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: FloatingActionButton(
            onPressed: () {
              // Check if today's activity exists
              bool hasTodayActivity = leads.any((lead) {
                String createdAtStr = (lead['created_at'] ?? '').toString();
                DateTime? createdAt;
                try {
                  createdAt = DateTime.parse(createdAtStr);
                } catch (_) {
                  createdAt = null;
                }

                return createdAt != null &&
                    createdAt.year == DateTime.now().year &&
                    createdAt.month == DateTime.now().month &&
                    createdAt.day == DateTime.now().day;
              });

              if (hasTodayActivity) {
                // ✅ Show modal dialog
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      title: const Text(
                        "Notice",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF640D78),
                        ),
                      ),
                      content: const Text(
                        "Your plan for the day has already been submitted.",
                        style: TextStyle(fontSize: 16),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text(
                            "OK",
                            style: TextStyle(
                              color: Color(0xFF640D78),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                );
              } else {
                // ✅ Navigate to planner only if no activity today
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => DailyAgentPlaner(pageMode: '', activityId: '',)),
                );
              }
            },
            tooltip: 'Create New Plan',
            backgroundColor: const Color(0xFFac00d0),
            child: const Icon(Icons.add, color: Colors.white),
          ),
        ),
    );
  }
}
