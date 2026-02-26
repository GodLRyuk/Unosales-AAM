import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unosfa/pages/generalscreens/customNavigation.dart';
import 'package:unosfa/pages/services/api_service.dart';

class LosStatusChart extends StatefulWidget {
  final String? initialTabTitle;
  final String? searchQuery;
  const LosStatusChart({super.key, this.initialTabTitle, this.searchQuery});

  @override
  State<LosStatusChart> createState() => _LosStatusChartState();
}

class _LosStatusChartState extends State<LosStatusChart>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  final List<String> tabTitles = [
    'Underwriting Status',
    'Total Accepted',
    'In-Progress',
    'In-Principle Approved',
    'Final Approved',
    'Declined',
    'Disbursed',
  ];
  late TabController _tabController;
  List<dynamic> losData = [];
  final _searchFilter = TextEditingController();

  Map<String, List<dynamic>> categorizedData = {
    'Underwriting Status': [],
    'Total Accepted': [],
    'In-Progress': [],
    'In-Principle Approved': [],
    'Final Approved': [],
    'Declined': [],
    'Disbursed': []
  };
  List<Map<String, dynamic>> _mergedLeads = [];
  int _currentPage = 1;
  bool _isFetchingMore = false;
  bool _hasMoreData = true;
  final ScrollController _scrollController = ScrollController();

  Map<int, bool> _tabLoading = {};
 String tabSearch = "";
  @override
  void initState() {
    super.initState();
    tabSearch=widget.initialTabTitle.toString().toUpperCase();
    // Initialize TabController
    _tabController = TabController(length: tabTitles.length, vsync: this);

    // If an initial tab is provided, set the index
    if (widget.initialTabTitle != null &&
        tabTitles.contains(widget.initialTabTitle)) {
      final index = tabTitles.indexOf(widget.initialTabTitle!);
      _tabController.index = index;
    }

    // Initialize loading state for each tab
    for (int i = 0; i < tabTitles.length; i++) {
      _tabLoading[i] = false;
    }

    // Listen to tab changes to show loader
    _tabController.addListener(() {
      final currentTitle = tabTitles[_tabController.index];
      tabSearch=currentTitle.toUpperCase();
      if (_tabController.indexIsChanging) {
        setState(() {
          _tabLoading[_tabController.index] = true;
          _loadLOSData();
        });

        Future.delayed(Duration(milliseconds: 200), () {
          setState(() {
            _tabLoading[_tabController.index] = false;
          });
        });
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _resetAndLoad();
    });

    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      _resetAndLoad();
    });

    _scrollController.addListener(_onScroll);

    // Load LOS data
    //_loadLOSData();
  }

  void _resetAndLoad() {
    final selectedTab = tabTitles[_tabController.index];
    final status = _tabStatusMap[selectedTab];

    setState(() {
      _currentPage = 1;
      _hasMoreData = true;
      _mergedLeads.clear();
    });

    if (widget.searchQuery != null) {
      //print("search value is ${widget.searchQuery}");
      _searchLOSData(
        offerStatus: status,
        page: 1,
        isLoadMore: false,
        searchQuery: widget.searchQuery,
      );
    } else {
      print("No search value");
      _loadLOSData();
    }
  }

  void _onScroll() {
    if (!_scrollController.hasClients || _isFetchingMore || !_hasMoreData)
      return;

    final threshold = 200.0;

    // if (_scrollController.position.extentAfter < threshold) {
    _isFetchingMore = true;

    Future.delayed(const Duration(seconds: 0), () {
      if (!_hasMoreData) return;

      _currentPage++;

      final selectedTab = tabTitles[_tabController.index];
      final status = _tabStatusMap[selectedTab];

      _loadLOSData();
    });
    // }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  final Map<String, String> _tabStatusMap = {
    'Underwriting Status': 'SW_PW',
    'Total Accepted': 'Accept,Accept_Manual',
    'In-Progress': 'IN-PROGRESS',
    'In-Principle Approved': 'PRE-QUALIFIED',
    'Final Approved': 'Pass',
    'Declined': 'Cancel,Fail,REJECT,Dedupe',
    'Disbursed': 'Availed,Avail_Manual',
  };


 // Work 25.2.2026
  
  Future<void> _loadLOSData() async {
    setState(() => _isLoading = true);
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? userInfo = prefs.getStringList('userInfo');
    String userId = userInfo![0];
    String? accessToken = prefs.getString('accessToken');

    if (userInfo == null || accessToken == null) {
      print("User info or access token not found.");
      setState(() => _isLoading = false);
      return;
    }

    String token = "";

    try {
      // 🔹 First call: Get LOS access token
      String url = "/api/leads/los-access-token/";
      final headers = {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
        'User-Agent':
            'Mozilla/5.0 (Linux; Android 11; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36',
      };
      final tokenResponse = await ApiService.getWithHeaders(url, headers);
      if (tokenResponse != null) {
        final data = json.decode(tokenResponse.body);
        token = data['access_token'] ?? "";
      }
    } catch (e) {
      print("HTTP Token Request Failed: $e");
      setState(() => _isLoading = false);
      return;
    }

    final mappedData = {
      "mobileNo": "",
      "agentCode": userInfo[0],
      "applicationNo": "",
      "channel": "",
      "source": ""
    };

   try {
   
  String url = "/api/leads/los-details/?los_status__uwStatus=$tabSearch";

  final headers = {
    'Authorization': 'Bearer $accessToken',
    'User-Agent':
        'Mozilla/5.0 (Linux; Android 11; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36',
  };

  final response = await ApiService.getWithHeaders(url, headers);

  List<Map<String, dynamic>> mergedLeads = [];

  if (response != null && response.statusCode == 200) {
  final appJson = json.decode(response.body);
  final List results = appJson['results'];

  for (var item in results) {
    final clientDetails = item['clientDetails'];
    final losStatus = item['los_status'];

    String offerStatus = losStatus?['offerStatus']?.toString() ?? '';
    String uwStatus = losStatus?['uwStatus']?.toString() ?? '';

    mergedLeads.add({
      'firstName': clientDetails?['firstName']?.toString() ?? '',
      'middleName': clientDetails?['middleName']?.toString() ?? '',
      'lastName': clientDetails?['lastName']?.toString() ?? '',
      'mobilePhone': clientDetails?['mobilePhone']?.toString() ?? '',
      'CWTransactionID': item['CWTransactionID']?.toString() ?? '',
      'applicationNo': losStatus?['applicationNo']?.toString() ?? '',
      'offerStatus': offerStatus,
      'uwStatus': uwStatus,
      'workflow_status': item['workflow_status']?.toString() ?? '',
    });
  }

  setState(() {
    _mergedLeads = mergedLeads;
    _categorizeLeads();
    _isLoading = false;
  });
}
} catch (e) {
  print("HTTP LOS Request Failed: $e");
  setState(() => _isLoading = false);
}
}



  Future<void> _searchLOSData({
    String? offerStatus,
    String? searchQuery,
    int page = 1,
    bool isLoadMore = false,
  }) async {
    // 🔹 Set correct loader flags
    if (isLoadMore) {
      setState(() => _isFetchingMore = true);
    } else {
      setState(() => _isLoading = true);
    }

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String token = "";
      List<String>? userInfo = prefs.getStringList('userInfo');
      String userId = userInfo![0];
      String? accessToken = prefs.getString('accessToken');
      try {
        String tokenUrl = "/api/leads/los-access-token/";
        final headers = {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
          'User-Agent':
              'Mozilla/5.0 (Linux; Android 11; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36',
        };
        final Tokenresponse =
            await ApiService.getWithHeaders(tokenUrl, headers);
        if (Tokenresponse != null) {
          final data = json.decode(Tokenresponse.body);
          token = data['access_token'];
        }
      } catch (e) {
        print("HTTP Request Failed: $e");
      }

      //print("search query data is... $searchQuery");
      String url = "";

      url = "/application/details";

      final headers = {
        'Accept': '*/*',
        'Correlation-Id': 'CORR-123456',
        'Channel': 'FSA',
        'Cookie':
            '__METADATA__=6989a6b0-dbfa-4caa-9a56-5d6231dd6a95; __METADATA__=6989a6b0-dbfa-4caa-9a56-5d6231dd6a95',
        "Authorization": "Bearer $token",
        'Content-Type': "application/json",
      };

  //"applicationId": "FSA_99333220251218174946",  "mobileNumber": "639811223344"
     
      Map<String, dynamic> body;

      if (RegExp(r'^\d{12}$').hasMatch(searchQuery!)) {
       
        body = {"mobileNumber": searchQuery};
      } else {
        
        body = {"applicationId": searchQuery};
      }


      final response = await ApiService.postJsonWithUNOApiHeaders(url, body, headers);

      if (response == null || response.statusCode != 200) {
        setState(() {
          _isLoading = false;
          _isFetchingMore = false;
        });
        return;
      }

      final appJson = json.decode(response.body);
      final List results = appJson['result'] ?? [];
      //print("result is $results");

      final uniqueStatuses = results
          .map((item) => item['offerStatus']?.toString() ?? '')
          .toSet()
          .toList();
      //print("uniqueStatuses is $uniqueStatuses");

      _switchToTabForStatus(uniqueStatuses);

      List<Map<String, dynamic>> mergedLeads =
          results.map<Map<String, dynamic>>(
        (appLead) {
          return {
            'firstName': appLead['firstName'] ?? '',
            'middleName': appLead['middleName'] ?? '',
            'lastName': appLead['lastName'] ?? '',
            'mobilePhone': appLead['mobileNo'] ?? '',
            'CWTransactionID': appLead['applicationNo'] ?? '',
            'applicationNo': appLead['applicationNo'] ?? '',
            'offerStatus': appLead['offerStatus'] ?? '',
          };
        },
      ).toList();
      // 🔹 Update UI safely
      setState(() {
        _mergedLeads = mergedLeads;
        _categorizeLeads();
        _isLoading = false;
      });
      if (_mergedLeads.isNotEmpty) {
        // Get the first match’s offer status
        final matchedStatus = _mergedLeads.first['offerStatus'];
        final statusTab = _getTabTitleForStatus(matchedStatus);

        if (statusTab != null && tabTitles.contains(statusTab)) {
          final index = tabTitles.indexOf(statusTab);
          _tabController.animateTo(index);
        }

        //print("merge leade is $mergedLeads");

        // Show only the filtered results in their categories
        setState(() {
          //_mergedLeads = filteredLeads;
          _categorizeLeads();
        });
      } else {
        print("No matching results for: ${widget.searchQuery}");
      }
    } catch (e) {
      debugPrint("LOS API error: $e");
      setState(() {
        _isLoading = false;
        _isFetchingMore = false;
      });
    }
  }

  void _switchToTabForStatus(List<String> uniqueStatuses) {
    if (uniqueStatuses.isEmpty) return;
    String firstStatus = uniqueStatuses.first;
    //print("firstStatus is $firstStatus");

    String firstUpperText = firstStatus.toUpperCase();
    String? tabTitle = _getTabTitleForStatus(firstUpperText);
    //print("tabTitle is $tabTitle");

    if (tabTitle != null && tabTitles.contains(tabTitle)) {
      int newIndex = tabTitles.indexOf(tabTitle);

      // Switch tab if it's not already selected
      if (_tabController.index != newIndex) {
        _tabController.animateTo(newIndex);
        
      }
    }
  }



  void _categorizeLeads() {
  categorizedData['Total Accepted'] = _mergedLeads
      .where((lead) {
        final status = (lead['offerStatus'] ?? '').toString().toUpperCase();
        return status == 'ACCEPT' || status == 'ACCEPT_MANUAL';
      })
      .toList();

  categorizedData['In-Progress'] = _mergedLeads
      .where((lead) =>
          (lead['offerStatus'] ?? '').toString().toUpperCase() ==
          'IN-PROGRESS')
      .toList();

  categorizedData['In-Principle Approved'] = _mergedLeads
      .where((lead) =>
          (lead['offerStatus'] ?? '').toString().toUpperCase() ==
          'PRE-QUALIFIED')
      .toList();

  categorizedData['Final Approved'] = _mergedLeads
      .where((lead) =>
          (lead['offerStatus'] ?? '').toString().toUpperCase() ==
          'PASS')
      .toList();

  categorizedData['Declined'] = _mergedLeads
      .where((lead) {
        final status = (lead['offerStatus'] ?? '').toString().toUpperCase();
        return status == 'CANCEL' ||
            status == 'FAIL' ||
            status == 'REJECT' ||
            status == 'DEDUPE';
      })
      .toList();

  categorizedData['Disbursed'] = _mergedLeads
      .where((lead) {
        final status = (lead['offerStatus'] ?? '').toString().toUpperCase();
        return status == 'AVAILED' ||
            status == 'AVAIL_MANUAL';
      })
      .toList();



   categorizedData['Underwriting Status'] = _mergedLeads
      .where((lead) {
        final status = (lead['workflow_status'] ?? '').toString().toUpperCase();
        print("status is ${lead['workflow_status']}");
        return status == 'SW_PW';
        
      })
      .toList();

   


}

  String? _getTabTitleForStatus(String? status) {
  if (status == null) return null;

  switch (status.toUpperCase()) {
    case 'ACCEPT':
    case 'ACCEPT_MANUAL':
      return 'Total Accepted';

    case 'IN-PROGRESS':
      return 'In-Progress';

    case 'PRE-QUALIFIED':
      return 'In-Principle Approved';

    case 'PASS':
      return 'Final Approved';

    case 'CANCEL':
    case 'FAIL':
    case 'REJECT':
    case 'DEDUPE':
      return 'Declined';

    case 'AVAILED':
    case 'AVAIL_MANUAL':    
      return 'Disbursed';

    case 'SW_PW':
     return 'Underwriting Status';

    

    

    default:
      return null;
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
      body: Column(
        children: [
          Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: TextField(
                    controller: _searchFilter,
                    decoration: InputDecoration(
                      labelText: 'Search By Name,Phone Number,TranscationID ',
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFFac00d0)),
                      ),
                      suffixIcon: Container(
                        color: Color(0xFFac00d0),
                        child: IconButton(
                          onPressed: ()=>{},
                          icon: Icon(Icons.search, color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              labelColor: Colors.purple,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Colors.purple,
              labelPadding: EdgeInsets.only(left: 16.0, right: 16.0),
              tabs: tabTitles.map((title) {
                return Container(
                  alignment: Alignment.centerLeft,
                  width: 120,
                  child: Tab(text: title),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: Builder(
              builder: (context) {
                if (_isLoading || _tabLoading[_tabController.index]!) {
                  return Center(
                      child: CircularProgressIndicator(color: Colors.purple));
                }

                //print("TabTile is $tabTitles");

                //print(categorizedData[tabTitles[_tabController.index]]);
                final currentTabLeads =
                    categorizedData[tabTitles[_tabController.index]]!;
                //print("current tab leads is $currentTabLeads");
                if (currentTabLeads.isEmpty) {
                  return Center(child: Text("No Data Found"));
                }
                //print("current tab leads is ${currentTabLeads.length}");

                return ListView.builder(
                  itemCount: currentTabLeads.length,
                  itemBuilder: (context, index) {
                    final lead = currentTabLeads[index];
                    final selectedTab = tabTitles[_tabController.index];

                    return Container(
                      margin: const EdgeInsets.symmetric(
                          vertical: 10, horizontal: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border(
                          top: BorderSide(color: Color(0xFF640D78), width: 1.0),
                          bottom:
                              BorderSide(color: Color(0xFF640D78), width: 1.0),
                          left:
                              BorderSide(color: Color(0xFF640D78), width: 5.0),
                          right:
                              BorderSide(color: Color(0xFF640D78), width: 1.0),
                        ),
                      ),
                      child: ListTile(
                        leading:
                            Icon(Icons.person, color: Colors.purple, size: 30),
                        title: Text(
                          "${lead['firstName']} ${lead['middleName']} ${lead['lastName']}"
                              .trim(),
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),

                        

                        

                  subtitle: selectedTab == 'Underwriting Status'
                      ? Text(
                          "Mobile: ${lead['mobilePhone']}\n"
                          "CWTransactionID: ${lead['CWTransactionID']}\n"
                          "ApplicationNo: ${lead['applicationNo']}\n"
                          "WorkFlow Status: ${lead['workflow_status']}",
                        )

                      : Text(
                          "Mobile: ${lead['mobilePhone']}\n"
                          "CWTransactionID: ${lead['CWTransactionID']}\n"
                          "ApplicationNo: ${lead['applicationNo']}\n"
                          "OfferStatus: ${lead['offerStatus']}",
                        ),


                        // subtitle: Text(
                        //   "Mobile: ${lead['mobilePhone']}\n"
                        //   "CWTransactionID: ${lead['CWTransactionID']}\n"
                        //   "ApplicationNo: ${lead['applicationNo']}\n"
                        //   "OfferStatus: ${lead['offerStatus']}",
                        // ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
