import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unosfa/pages/FRModule/leadsByCampaign.dart';
import 'package:unosfa/pages/generalscreens/customNavigation.dart';
import 'package:unosfa/pages/services/api_service.dart';
import 'package:unosfa/widgetSupport/widgetstyle.dart';
import 'package:intl/intl.dart';
import 'dart:async';

class FRCampaignlist extends StatefulWidget {
  @override
  State<FRCampaignlist> createState() => _FRCampaignlistState();
}

class _FRCampaignlistState extends State<FRCampaignlist> {
  final _searchFilter = TextEditingController();
  final _toDate = TextEditingController();
  final _fromDate = TextEditingController();
  List<Map<String, String>> campaign = [];
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
    String apiUrl = '/api/campaigns/';
    final headers = {
      'Authorization': 'Bearer $token',
      'User-Agent':
          'Mozilla/5.0 (Linux; Android 11; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36',
    };
    try {
      final response = await ApiService.getWithHeaders(apiUrl, headers);
      if (response != null) {
        if (response.statusCode == 200) {
          Map<String, dynamic> data = response.data;
          List<dynamic> leadsData = data['results'] ?? [];

          setState(() {
            if (isLoadMore) {
              campaign.addAll(leadsData.map((item) => {
                    'name': '${item['name'] ?? ''}'.trim(),
                    'description': item['description']?.toString() ?? '',
                    'start_date': item['start_date']?.toString() ?? '',
                    'end_date': item['end_date']?.toString() ?? '',
                    'id': item['id']?.toString() ?? '',
                  }));
            } else {
              campaign = leadsData
                  .map((item) => {
                        'name': '${item['name'] ?? ''}'.trim(),
                        'description': item['description']?.toString() ?? '',
                        'start_date': item['start_date']?.toString() ?? '',
                        'end_date': item['end_date']?.toString() ?? '',
                        'id': item['id']?.toString() ?? '',
                      })
                  .toList();
            }

            filteredLeads = List.from(campaign);
            setState(() {
              startDate = DateTime.parse(campaign[0]['start_date']!);
              endDate = DateTime.parse(campaign[0]['end_date']!);
              _updateCampaignDates();
            });
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
          Map<String, dynamic> data = response.data;
          List<dynamic> leadsData = data['results'] ?? [];
          setState(() {
            campaign = leadsData.map((item) {
              return {
                'name': '${item['name']}'.trim(),
                'description': item['description']?.toString() ?? '',
                'id': item['id']?.toString() ?? '',
              };
            }).toList();
            filteredLeads = List.from(campaign);
            hasMoreData = data['next'] != null;

            isLoading = false;
            isFetchingMore = false;
          });
        } else if (response.statusCode == 401) {
          String url2 = "/api/users/token-refresh/";
          Map<String, String> mappedData = {'refresh': refresh ?? ''};
          final response2 = await ApiService.post(url2, mappedData);
          if (response2 != null) {
            final data = json.decode(response2.data);
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

  // Format the date string

  void _updateCampaignDates() {
    if (campaign.isNotEmpty) {
      try {
        DateTime fetchedStartDate = DateTime.parse(campaign[0]['start_date']!);
        DateTime fetchedEndDate = DateTime.parse(campaign[0]['end_date']!);

        setState(() {
          startDate = fetchedStartDate;
          endDate = fetchedEndDate;
          totalDuration =
              endDate!.difference(startDate!); // Calculate total duration
        });
        _startCountdown();
      } catch (e) {
        print("Error parsing dates: $e");
      }
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
                await fetchFilteredLeads();
              },
              child: Column(
                children: [
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.all(
                          10), // Adding some margin around the container

                      child: isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : campaign.isEmpty
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
                                  itemCount: campaign.length +
                                      1, // Add one extra item for the loader
                                  itemBuilder: (context, index) {
                                    if (index < campaign.length) {
                                      return GestureDetector(
                                        onTap: () {
                                          String campaignID =
                                              campaign[index]['id']!;
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  FRLeadListByCampaign(
                                                campaign: campaignID,
                                              ),
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
                                                    horizontal: 0),
                                            leading: Column(
                                              children: [
                                                Image.asset(
                                                  'images/campaign.jpg',
                                                  height: 55,
                                                  width: 80,
                                                ),
                                              ],
                                            ),
                                            title: Container(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Text(
                                                        campaign[index]['name']!
                                                            .toUpperCase(),
                                                        style: WidgetSupport
                                                            .CampaignName(),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Row(
                                                    children: [
                                                      Icon(
                                                        Icons
                                                            .calendar_month_outlined,
                                                        color:
                                                            Color(0xFF640D78),
                                                        size: 17,
                                                      ),
                                                      Text(
                                                        DateFormat(
                                                                'dd MMM yyyy')
                                                            .format(DateTime
                                                                .parse(campaign[
                                                                        index][
                                                                    'start_date']!)),
                                                        style: WidgetSupport
                                                            .inputLabel(),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 5),
                                                  Text(
                                                    "Campaign Expires In"
                                                        .toUpperCase(),
                                                    style: TextStyle(
                                                        fontSize: 15,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color:
                                                            Color(0xFF640D78)),
                                                  ),
                                                  Text(
                                                    "${formatDuration(timeLeft)}",
                                                    style: TextStyle(
                                                        fontSize: 12,
                                                        fontWeight:
                                                            FontWeight.bold),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            trailing: Icon(
                                              Icons.chevron_right,
                                              color: Color(0xFF640D78),
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
