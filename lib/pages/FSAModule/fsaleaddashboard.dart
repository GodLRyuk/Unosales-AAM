import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import 'package:unosfa/pages/FSAModule/fsacreatcompantlead.dart';
import 'package:unosfa/pages/FSAModule/fsasingleleaddetail.dart';
import 'package:unosfa/pages/FSAModule/losApplication.dart';
import 'package:unosfa/pages/Report/save_pdf.dart';
import 'package:unosfa/pages/generalscreens/customNavigation.dart';
import 'package:unosfa/pages/otpscreens/dedupeCheck.dart';
import 'package:unosfa/pages/services/api_service.dart';
import 'package:unosfa/pages/services/in_app_storage.dart';
import 'package:unosfa/pages/services/in_app_tutorial_target.dart';
import 'package:unosfa/widgetSupport/widgetstyle.dart';

class FsaLeadDashBoard extends StatefulWidget {
  final String? initialTabTitle;
  final String searchQuery;
  const FsaLeadDashBoard(
      {super.key, required this.searchQuery, this.initialTabTitle});

  @override
  State<FsaLeadDashBoard> createState() => _FsaLeadDashBoardState();
}

class _FsaLeadDashBoardState extends State<FsaLeadDashBoard>
    with TickerProviderStateMixin {
  List<String>? userInfo;
  final _scrollController = ScrollController();
  List<Map<String, String>> leads = [];
  List<Map<String, String>> filteredLeads = [];
  bool isLoading = true;
  bool isFetchingMore = false;
  int currentPage = 1;
  bool hasMoreData = true;
  bool areDateFieldsVisible = false;
  DateTime? selectedFromDate;
  DateTime? selectedToDate;
  bool isExpanded = false;
  bool onGoingStatus = false;
  late TabController _tabController;
  final List<String> tabTitles = ['Customer Leads', 'Company Leads'];
  Map<String, List<Map<String, String>>> categorizedData = {
    'Customer Leads': [],
    'Company Leads': [],
  };

  late TutorialCoachMark tutorialCoachMark;
  final CreateLeadIconKey = GlobalKey();
  final EditLeadIconKey = GlobalKey();
  final DisplayLeadKey = GlobalKey();
  final LeadDescriptionKey = GlobalKey();
  final LeadFilterKey = GlobalKey();
  final descriptionCustomerLeadKey = GlobalKey();
  final descriptionCompanyLeadKey = GlobalKey();
  final editCompanyLeadKey = GlobalKey();
  final displayCustomerLeadKey = GlobalKey();
  final displayCompanyLeadKey = GlobalKey();
  static const String kAddAppTourKey = "saveLeadDashboardTour";

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: tabTitles.length, vsync: this);
    fetchLeads();
    _showInAppTour();
    _inAppLeadDashboardTour();
    _scrollController.addListener(_onScroll);
    _tabController = TabController(length: tabTitles.length, vsync: this);
    if (widget.initialTabTitle != null &&
        tabTitles.contains(widget.initialTabTitle)) {
      final index = tabTitles.indexOf(widget.initialTabTitle!);
      _tabController.index = index;
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _inAppLeadDashboardTour() {
    tutorialCoachMark = TutorialCoachMark(
      targets: appTargetFsaLeadDashboard(
        CreateLeadIconKey: CreateLeadIconKey,
        EditLeadIconKey: EditLeadIconKey,
        DisplayLeadKey: DisplayLeadKey,
        LeadDescriptionKey: LeadDescriptionKey,
        LeadFilterKey: LeadFilterKey,
      ),
      colorShadow: Color(0xFF420244),
      paddingFocus: 10,
      hideSkip: false,
      textStyleSkip: TextStyle(
          fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
      skipWidget: Container(
        padding: EdgeInsets.symmetric(horizontal: 15, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          "Skip",
          style: TextStyle(
            fontSize: 18,
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      opacityShadow: 0.8,
      onFinish: () async {
        await AppTourManager.saveTourStatus(kAddAppTourKey);
      },
      //  onFinish: () async => await AppTourManager.saveTourStatus(kAddAppTourKey),
      onSkip: () {
        AppTourManager.saveTourStatus(kAddAppTourKey); // don't await
        return true; // continue skipping
      },
    );
  }

  void _showInAppTour() {
    Future.delayed(Duration.zero, () async {
      bool hasSeenTour = await AppTourManager.getTourStatus(kAddAppTourKey);
      if (!hasSeenTour) {
        tutorialCoachMark.show(context: context);
      }
    });
  }

  Future<void> fetchLeads({bool isLoadMore = false}) async {
    if (isLoadMore) {
      setState(() => isFetchingMore = true);
    } else {
      setState(() => isLoading = true);
    }

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('accessToken');

    String apiUrl1 =
        "/api/leads/los-details/?search=${widget.searchQuery}&page=$currentPage";
    String apiUrl2 =
        "/api/leads/company-leads/?search=${widget.searchQuery}&ordering=-created_at&page=$currentPage";
    final headers = {
      'Authorization': 'Bearer $token',
      'User-Agent':
          'Mozilla/5.0 (Linux; Android 11; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36',
    };
    try {
      final responses = await Future.wait([
        ApiService.getWithHeaders(apiUrl1, headers),
        ApiService.getWithHeaders(apiUrl2, headers)
      ]);
      List<Map<String, String>> allLeadsData = [];

      for (int i = 0; i < responses.length; i++) {
        final response = responses[i];
        if (response != null) {
          if (response.statusCode == 200) {
            Map<String, dynamic> data = json.decode(response.body);
            List<dynamic> leadsData = data['results'] ?? [];

            if (i == 0) {
              allLeadsData.addAll(leadsData.map((item) {
                final client = item['clientDetails'] ?? {};
                return {
                  'name':
                      '${(client['firstName'] ?? '')} ${(client['middleName'] ?? '')} ${(client['lastName'] ?? '')}'
                          .trim(),
                  'phone': (client['mobilePhone'] ?? '').toString(),
                  'id': (item['id'] ?? '').toString(),
                  'type': 'Customer Lead',
                };
              }));
              hasMoreData = data['next'] != null;
            } else {
              allLeadsData.addAll(leadsData.map((item) => {
                    'name':
                        (item['company_name'] ?? 'Unknown Company').toString(),
                    'phone':
                        (item['contact_person_mobile_no'] ?? '').toString(),
                    'id': (item['id'] ?? '').toString(),
                    'type': 'Company Lead',
                  }));
            }
          }
        }
      }

      setState(() {
        if (isLoadMore) {
          leads.addAll(allLeadsData);
        } else {
          leads = allLeadsData;
        }

        categorizedData['Customer Leads'] =
            leads.where((lead) => lead['type'] == 'Customer Lead').toList();
        categorizedData['Company Leads'] =
            leads.where((lead) => lead['type'] == 'Company Lead').toList();

        filteredLeads = List.from(leads);
        isLoading = false;
        isFetchingMore = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        isFetchingMore = false;
      });
      print('Error fetching leads: $e');
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels ==
            _scrollController.position.maxScrollExtent &&
        !isFetchingMore &&
        hasMoreData) {
      currentPage++;
      fetchLeads(isLoadMore: true);
    }
  }
   Future<String> getlatesApplication() async {
  
    String token = "";
    SharedPreferences prefs = await SharedPreferences.getInstance();
    userInfo = prefs.getStringList('userInfo');
    String? accessToken = prefs.getString('accessToken');
    try {
      String tokenUrl = "/api/leads/los-access-token/";
      final headers = {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
        'User-Agent':
            'Mozilla/5.0 (Linux; Android 11; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36',
      };
      final Tokenresponse = await ApiService.getWithHeaders(tokenUrl, headers);
      if (Tokenresponse != null) {
        final data = json.decode(Tokenresponse.body);
        token = data['access_token'];
        print("fsaleaddashboard token is $token");
      }
    } catch (e) {
      print("HTTP Request Failed: $e");
    }

    final url = "/application/latest?agentId=${userInfo![0]}";
    final headers = {
      'Content-Type': 'application/json',
      'Correlation-Id': '3fa85f64-5717-4562-b3fc-2c963f66afa6',
      //'Channel': 'salesapp',
      'Channel': 'fsa',
      "Cookie": "METADATA=3c6749d5-60ea-4486-aede-fd4538d2fe39",
      "Authorization": "Bearer $token",
      'User-Agent':
          'Mozilla/5.0 (Linux; Android 11; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36',
    };
    try {
    final response = await ApiService.getWithHeadersOnlyUnoApi(url, headers);
     if (response == null) return "";
    final data = json.decode(response.body);
    print("Latest Application Response: $data");
    String status = data['status']?.toString() ?? "";

    String createdAt = data['created_Date']; 
    DateTime createdTime = DateTime.parse(createdAt.replaceAll(" ", "T"));
    DateTime now = DateTime.now();
    Duration diff = now.difference(createdTime);

    if (diff.inMinutes > 10) {
        print("Time exceeded 10 minutes");
        setState(() {
          onGoingStatus=true;
        });
      } 
    print("status is $status, type is ${status.runtimeType}");
    return status;
  } catch (e) {
    print("Latest Application API Error: $e");
    return "";
  }
  }


  Widget _buildLeadTile(Map<String, String> lead, int index) {
    final isCustomerLead = lead['type'] == 'Customer Lead';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: const Border(
          top: BorderSide(color: Color(0xFF640D78), width: 1.0),
          bottom: BorderSide(color: Color(0xFF640D78), width: 1.0),
          left: BorderSide(color: Color(0xFF640D78), width: 5.0),
          right: BorderSide(color: Color(0xFF640D78), width: 1.0),
        ),
      ),
      child: ListTile(
        key: index == 0
            ? (isCustomerLead ? displayCustomerLeadKey : displayCompanyLeadKey)
            : null,
        onTap: () {
          if (!isCustomerLead) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    FsaCompanySingleLead(leadId: lead['id'] ?? ''),
              ),
            );
          }
        },
        contentPadding: const EdgeInsets.symmetric(horizontal: 15),
        leading: SizedBox(         //Sized Box is added  because of white screen ISSUE .
          width: MediaQuery.of(context).size.width * 0.8, 
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  lead['name']?.toUpperCase() ?? 'NO NAME',
                  style: WidgetSupport.label(),
                  softWrap: true,
                  textAlign: TextAlign.start,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                lead['phone'] ?? 'NO PHONE',
                style: WidgetSupport.inputLabel(),
              ),
            ],
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              key: index == 0
                  ? (isCustomerLead
                      ? descriptionCustomerLeadKey
                      : descriptionCompanyLeadKey)
                  : null,
              margin: const EdgeInsets.only(top: 20, right: 10),
              width: 100,
              height: 25,
              // decoration: BoxDecoration(
              //   color: isCustomerLead
              //       ? const Color(0xFFc433e0)
              //       : const Color(0xFF640D78),
              //   borderRadius: BorderRadius.circular(10),
              // ),
              // child: Center(
              //   child: Text(
              //     lead['type'] ?? '',
              //     style: const TextStyle(color: Colors.white),
              //   ),
              // ),
            ),
            if (!isCustomerLead)
              // GestureDetector(
              //   onTap: () {
              //     Navigator.push(
              //       context,
              //       MaterialPageRoute(
              //         builder: (context) =>
              //             FsaCompanyLeadGenerate(edit: lead['id'] ?? ''),
              //       ),
              //     );
              //   },
              //   child: Icon(Icons.edit,
              //       color: const Color(0xFF640D78),
              //       key: index == 0 ? editCompanyLeadKey : null),
              // ),
              const SizedBox(width: 10),
            if (!isCustomerLead)
              const Icon(Icons.chevron_right, color: Color(0xFF640D78)),
          ],
        ),
      ),
    );
  }

  Widget _buildLeadList(List<Map<String, String>> leads) {
    if (isLoading) return const Center(child: CircularProgressIndicator());
    if (leads.isEmpty) return const Center(child: Text('No Leads Found'));

    return ListView.builder(
      controller: _scrollController,
      itemCount: leads.length + 1, // Extra item for loader or no more data
      itemBuilder: (context, index) {
        if (index < leads.length) {
          return _buildLeadTile(leads[index], index);
        } else {
          // Loader or "No more data" at the end
          if (isFetchingMore) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: CircularProgressIndicator(),
              ),
            );
          } else {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Text(hasMoreData ? '' : 'No more data'),
              ),
            );
          }
        }
      },
    );
  }

  @override
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(100.0), // Adjusted height for TabBar
        child: Container(
          decoration: const BoxDecoration(
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
                const SizedBox(width: 50),
              ],
            ),
            centerTitle: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => NavigationPage()),
                );
              },
            ),
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white,
              tabs: const [
                Tab(text: 'Customer Leads'),
                Tab(text: 'Company Leads'),
              ],
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: TabBarView(
          controller: _tabController,
          children: tabTitles.map((title) {
            final leadList = categorizedData[title] ?? [];
            return _buildLeadList(leadList);
          }).toList(),
        ),
      ),


      // Updated at 1/12/2025


      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Container(
              width: 56, 
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Colors.blue, Colors.purple],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: FloatingActionButton(
                onPressed: () async{
                  String currentTab =
                      tabTitles[_tabController.index].toLowerCase();

                  if (currentTab.contains('customer')) {
                    // if it is in progress
                    String resultstatus = await getlatesApplication();
                    print("resultstatus is $resultstatus");
                    print("onGoingStatus is $onGoingStatus");
                   
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DedupeCheck(),
                      ),
                    );

                  // if(resultstatus.isEmpty || onGoingStatus!=false)                   
                  //   {
                  //     Navigator.push(
                  //     context,
                  //     MaterialPageRoute(
                  //       builder: (context) => DedupeCheck(),
                  //     ),
                  //   );
                  // }

                  // else if(resultstatus == "In-Progress" && onGoingStatus == false)
                  //  // else if(resultstatus == "IN-PROGRESS"  && onGoingStatus==true)
                  //   {
                  //     showDialog(
                  //     context: context,
                  //     barrierDismissible: false,
                  //     builder: (BuildContext context) {
                  //       return AlertDialog(
                  //         title: Text("Application"),
                  //         content: Text(
                  //           "You already have an ongoing application in AAM.\n"
                  //           "Starting a new application is not allowed at this time."
                  //         ),
                  //         actions: [
                  //           TextButton(
                  //             onPressed: () {
                  //               Navigator.of(context).pop();
                  //               Navigator.pushReplacement(
                  //                 context,
                  //                 MaterialPageRoute(
                  //                   builder: (context) => NavigationPage(),
                  //                 ),
                  //               );
                  //             },
                  //             child: Text("Ok"),
                  //           ),
                  //         ],
                  //       );
                  //     },
                  //   );
                  //   }
                    
                  } else if (currentTab.contains('company')) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => FsaCompanyLeadGenerate(
                          edit: '',
                        ),
                      ),
                    );
                  }
                },
                tooltip: tabTitles[_tabController.index]
                        .toLowerCase()
                        .contains('customer')
                    ? 'Create Customer Lead'
                    : 'Create Company Lead',
                child: Icon(Icons.add, color: Colors.white),
                backgroundColor: Colors.transparent, // So gradient shows
                elevation: 0, // Optional: remove shadow if needed
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
