import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unosfa/pages/FSAModule/losApplication.dart';
import 'package:unosfa/pages/Form/daily_sales_report.dart';
import 'package:unosfa/pages/generalscreens/customNavigation.dart';
import 'package:unosfa/pages/services/api_service.dart';
import 'package:unosfa/widgetSupport/widgetstyle.dart';
import 'dart:async';

class DailySalesReportList extends StatefulWidget {
  final String searchQuery;
  const DailySalesReportList({super.key, required this.searchQuery});
  @override
  State<DailySalesReportList> createState() => _CampaignlistState();
}

class _CampaignlistState extends State<DailySalesReportList> {
  final _searchFilter = TextEditingController();
  List<Map<String, dynamic>> leads = [];
  bool isLoading = true;
  final _scrollController = ScrollController();
  bool isFetchingMore = false;
  int currentPage = 1;
  bool hasMore = true;
  Timer? countdownTimer;
  Duration timeLeft = Duration.zero;

  late Map<String, String> DispositionCode = {}; // stores id -> description
  late Map<String, String> SubDispositionCode = {}; // for sub codes

  @override
  void initState() {
    super.initState();
    fetchLeads();
    _scrollController.addListener(_onScroll);
    getDispositioncode();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    countdownTimer?.cancel();
    super.dispose();
  }

  // ===================== FETCH LEADS =======================
  Future<void> fetchLeads({bool isLoadMore = false}) async {
    if (isLoadMore) {
      setState(() => isFetchingMore = true);
    } else {
      setState(() {
        isLoading = true;
        currentPage = 1;
        hasMore = true;
      });
    }

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('accessToken');

    final headers = {
      'Authorization': 'Bearer $token',
      'User-Agent':
          'Mozilla/5.0 (Linux; Android 11; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36',
    };

    String date = widget.searchQuery;
    String apiUrl = "";
    if (date != "") {
      apiUrl =
          '/api/timesheet/agent-daily-sales/?follow_up_date__gte=${date}T00:00:00&follow_up_date__lte=${date}T23:59:59&page=$currentPage';
    } else {
      apiUrl = '/api/timesheet/agent-daily-sales/?page=$currentPage';
    }

    try {
      final response = await ApiService.getWithHeaders(apiUrl, headers);
      if (response != null && response.statusCode == 200) {
        final data = response.data;
        final leadsData = data['results'];
        List<Map<String, dynamic>> newLeads =
            List<Map<String, dynamic>>.from(leadsData);
        setState(() {
          if (isLoadMore) {
            leads.addAll(newLeads);
          } else {
            leads = newLeads;
          }
          hasMore = data['next'] != null;
          currentPage++;
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
  Future<void> getDispositioncode() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('accessToken');

    try {
      String url = "/api/leads/disposition-codes/";
      final headers = {
        'Authorization': 'Bearer $token',
        'User-Agent':
            'Mozilla/5.0 (Linux; Android 11; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36',
      };
      final response = await ApiService.getWithHeaders(url, headers);
      if (response != null && response.statusCode == 200) {
        var decodedResponse = response.data;

        if (decodedResponse is Map<String, dynamic> &&
            decodedResponse['results'] != null) {
          decodedResponse = decodedResponse['results'];
        }

        if (decodedResponse is List) {
          Map<String, String> fetchedData = {};
          for (var item in decodedResponse) {
            fetchedData[item['id'].toString()] = item['description'].toString();
          }
          setState(() {
            DispositionCode = fetchedData;
          });
        }
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  // ==================== SCROLL LISTENER ====================
  void _onScroll() {
    if (_scrollController.position.pixels ==
            _scrollController.position.maxScrollExtent &&
        !isFetchingMore &&
        hasMore) {
      fetchLeads(isLoadMore: true);
    }
  }

  // ======================= UI ==============================
  Future<void> fetchFilteredLeads({bool isLoadMore = false}) async {
    if (!isLoadMore) {
      setState(() {
        currentPage = 1;
        hasMore = true;
      });
    }

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('accessToken');

    String date = _searchFilter.text;
    String url =
        '/api/timesheet/agent-daily-sales/?created_at__gte=${date}T00:00:00&created_at__lte=${date}T23:59:59&page=$currentPage';
    final headers = {
      'Authorization': 'Bearer $token',
      'User-Agent':
          'Mozilla/5.0 (Linux; Android 11; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36',
    };
    try {
      final response = await ApiService.getWithHeaders(url, headers);
      if (response != null && response.statusCode == 200) {
        final data = response.data;

        final leadsData = data['results'];
        List<Map<String, dynamic>> newLeads =
            List<Map<String, dynamic>>.from(leadsData);
        setState(() {
          if (isLoadMore) {
            leads.addAll(newLeads);
          } else {
            leads = newLeads;
          }
          hasMore = data['next'] != null;
          currentPage++;
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
                                final dispositionId =
                                    lead['disposition_code']?.toString() ?? "";
                                final subDispositionId =
                                    lead['sub_disposition_code']?.toString() ??
                                        "";

                                return GestureDetector(
                                  onTap: () {
                                    String id = (lead['id'] ?? '').toString();
                                    if (lead['los_initiated'] != true &&
                                        DispositionCode[dispositionId] ==
                                            "Interested & Eligible") {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              LosApplicationPage(
                                            leadId: "",
                                            campaign: "",
                                            pagemode: "fromDSR",
                                            dsrId: id,
                                          ),
                                        ),
                                      );
                                    } else if (DispositionCode[dispositionId] ==
                                        "Eligible-Not yet Submitted") {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              DailySalesReport(
                                            pagemode: 'edit',
                                            dsrId: id,
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                  child: Container(
                                    height: 75,
                                    margin:
                                        const EdgeInsets.symmetric(vertical: 5),
                                    decoration: BoxDecoration(
                                      color: const Color.fromARGB(
                                          255, 255, 255, 255),
                                      borderRadius: BorderRadius.circular(8),
                                      border: const Border(
                                        left: BorderSide(
                                            color: Color(0xFF640D78),
                                            width: 5.0),
                                        top: BorderSide(
                                            color: Color(0xFF640D78),
                                            width: 1.0),
                                        bottom: BorderSide(
                                            color: Color(0xFF640D78),
                                            width: 1.0),
                                        right: BorderSide(
                                            color: Color(0xFF640D78),
                                            width: 1.0),
                                      ),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          // LEFT SIDE (Name + Phone)
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Text(
                                                  ('${lead['first_name'] ?? ''} ${lead['middle_name'] ?? ''} ${lead['last_name'] ?? ''}')
                                                      .toUpperCase(),
                                                  style: WidgetSupport
                                                      .mediumText(),
                                                ),
                                                Text(
                                                  (lead['phone_number'] ?? '')
                                                      .toString(),
                                                  style: WidgetSupport
                                                      .mediumText(),
                                                ),
                                              ],
                                            ),
                                          ),

                                          // RIGHT SIDE (Badges)
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.end,
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              if (lead['los_initiated'] !=
                                                      true &&
                                                  DispositionCode[
                                                          dispositionId] ==
                                                      "Interested & Eligible")
                                                Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 6,
                                                      vertical: 3),
                                                  decoration: BoxDecoration(
                                                    color: Colors.red.shade100,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            4),
                                                  ),
                                                  child: Text(
                                                    'Qualified App not Submited'
                                                        .toUpperCase(),
                                                    style: const TextStyle(
                                                      color: Colors.red,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 10,
                                                    ),
                                                  ),
                                                ),
                                              const SizedBox(height: 4),
                                              if (dispositionId.isNotEmpty)
                                                Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 6,
                                                      vertical: 3),
                                                  decoration: BoxDecoration(
                                                    color: Colors.blue.shade100,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            4),
                                                  ),
                                                  child: Column(
                                                    children: [
                                                      Text(
                                                        (DispositionCode[
                                                                    dispositionId] ??
                                                                "Unknown")
                                                            .toUpperCase(),
                                                        style: TextStyle(
                                                          color: (DispositionCode[
                                                                      dispositionId] ==
                                                                  "Interested & Eligible")
                                                              ? Colors.green
                                                              : Colors.blue,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 10,
                                                        ),
                                                      ),
                                                      if (DispositionCode[
                                                              dispositionId] ==
                                                          "Eligible-Not yet Submitted")
                                                        Text(
                                                          "Action Required"
                                                              .toUpperCase(),
                                                          style: TextStyle(
                                                            color: Colors
                                                                .redAccent,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            fontSize: 10,
                                                          ),
                                                        ),
                                                    ],
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              } else {
                                return hasMore
                                    ? Center(child: CircularProgressIndicator())
                                    : Center(child: Text('No more data'));
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
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => DailySalesReport(
                          pagemode: '',
                          dsrId: '',
                        )));
          },
          tooltip: 'Create New Lead',
          child: Icon(Icons.add, color: Colors.white),
          backgroundColor: Color(0xFFac00d0),
        ),
      ),
    );
  }
}
