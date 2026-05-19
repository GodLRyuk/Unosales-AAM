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
 // bool _hasAutoSwitchedTab = false;


  final List<String> tabTitles = [
    'Total Accepted',
    'In-Progress',
    'In-Principle Approved',
    'Final Approved',
    'Declined',
    'Disbursed',
  ];
  late TabController _tabController;
  List<dynamic> losData = [];

  Map<String, List<dynamic>> categorizedData = {
    'Total Accepted': [],
    'In-Progress': [],
    'In-Principle Approved': [],
    'Final Approved': [],
    'Declined': [],
  };
  List<Map<String, dynamic>> _mergedLeads = [];
int _currentPage = 1;
bool _isFetchingMore = false;
bool _hasMoreData = true;

final ScrollController _scrollController = ScrollController();
 @override
void initState() {
  super.initState();

  _tabController = TabController(length: tabTitles.length, vsync: this);

  int initialIndex = 0;
  if (widget.initialTabTitle != null &&
      tabTitles.contains(widget.initialTabTitle)) {
    initialIndex = tabTitles.indexOf(widget.initialTabTitle!);
    _tabController.index = initialIndex;
  }

  WidgetsBinding.instance.addPostFrameCallback((_) {
    _resetAndLoad();
  });

  _tabController.addListener(() {
    if (_tabController.indexIsChanging) return;
    _resetAndLoad();
  });

  _scrollController.addListener(_onScroll);
}

void _resetAndLoad() {
  final selectedTab = tabTitles[_tabController.index];
  final status = _tabStatusMap[selectedTab];

  setState(() {
  _currentPage = 1;
  _hasMoreData = true;
  _mergedLeads.clear();

});

if(widget.searchQuery != null)

{
  print("search value is ${widget.searchQuery}");
  _searchLOSData(
     offerStatus: status,
     page: 1,
     isLoadMore: false,
     searchQuery: widget.searchQuery
     

  );
}


else
{
  print("No search value");
 _loadLOSData(
  offerStatus: status,
  page: _currentPage,
  isLoadMore: true,
  searchQuery: widget.searchQuery
  
);
}


}


void _onScroll() {
  if (!_scrollController.hasClients ||
      _isFetchingMore ||
      !_hasMoreData) return;

  final threshold = 200.0;

  // if (_scrollController.position.extentAfter < threshold) {
    _isFetchingMore = true;

    Future.delayed(const Duration(seconds: 0), () {
      if (!_hasMoreData) return;

      _currentPage++;

      final selectedTab = tabTitles[_tabController.index];
      final status = _tabStatusMap[selectedTab];

      _loadLOSData(
        offerStatus: status,
        page: _currentPage,
        isLoadMore: true,
        searchQuery: widget.searchQuery
       
      );
    });
  // }
}

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

final Map<String, String> _tabStatusMap = {
  'Total Accepted': 'Accept,Accept_Manual',
  'In-Progress': 'IN-PROGRESS',
  'In-Principle Approved': 'PRE-QUALIFIED',
  'Final Approved': 'Pass',
  'Declined': 'Cancel,Fail,REJECT,Dedupe',
  'Disbursed': 'Availed,Avail_Manual',
};


  Future<void> _loadLOSData({
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
    String token ="";
    List<String>? userInfo = prefs.getStringList('userInfo');
    String userId = userInfo![0];
    String? accessToken = prefs.getString('accessToken');
    try {
      String tokenUrl = "/api/leads/los-access-token/";
      final headers = {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
        //'User-Agent':
          //  'Mozilla/5.0 (Linux; Android 11; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36',
      };
      final Tokenresponse = await ApiService.getWithHeaders(tokenUrl, headers);
      if (Tokenresponse != null) {
        final data = json.decode(Tokenresponse.data.body);
        token = data['access_token'];
      }
    } catch (e) {
      print("HTTP Request Failed: $e");
    }
    
    String url="";
    url = "/application/latest?agentId=$userId&isAllRequired=true";  

    final headers = {
       'Accept': '*/*',
      'Correlation-Id': 'CORR-123456',
      'Channel': 'FSA',
      'Cookie': '__METADATA__=6989a6b0-dbfa-4caa-9a56-5d6231dd6a95',
      "Authorization": "Bearer $token",
    };

    final response = await ApiService.getWithUnoApiHeaders(url, headers);
    print("response is ${response!.data.body}");
    print("response status is ${response!.statusCode}");

    if (response == null || response.statusCode != 200) {
      setState(() {
        _isLoading = false;
        _isFetchingMore = false;
      });
      return;
    }

    final appJson = json.decode(response.data.body);
    final List results = appJson['result'] ?? [];
    print("result is $results");

   final uniqueStatuses = results
    .map((item) => item['offerStatus']?.toString() ?? '')
    .toSet()
    .toList();
   print("uniqueStatuses is $uniqueStatuses");

   List<Map<String, dynamic>> mergedLeads = results.map<Map<String, dynamic>>(
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

    print("leads details $mergedLeads");

    // 🔹 Update UI safely
    setState(() {
      if (isLoadMore) {
        _mergedLeads.addAll(mergedLeads);
      } else {
        _mergedLeads = mergedLeads;
      }

      _isLoading = false;
      _isFetchingMore = false;

      // 🔹 No more pages
      if (mergedLeads.isEmpty) {
        _hasMoreData = false;
      }
    });
  } catch (e) {
    debugPrint("LOS API error: $e");
    setState(() {
      _isLoading = false;
      _isFetchingMore = false;
    });
  }
}

// For search api is call *******************************

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
    String token ="";
    List<String>? userInfo = prefs.getStringList('userInfo');
    String userId = userInfo![0];
    String? accessToken = prefs.getString('accessToken');
    try {
      String tokenUrl = "/api/leads/los-access-token/";
      final headers = {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
        //'User-Agent':
          //  'Mozilla/5.0 (Linux; Android 11; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36',
      };
      final Tokenresponse = await ApiService.getWithHeaders(tokenUrl, headers);
      if (Tokenresponse != null) {
        final data = json.decode(Tokenresponse.data.body);
        token = data['access_token'];
      }
    } catch (e) {
      print("HTTP Request Failed: $e");
    }
    
    print("search query data is... $searchQuery");
    String url="";

    url = "/application/details";  

    final headers = {
       'Accept': '*/*',
      'Correlation-Id': 'CORR-123456',
      'Channel': 'FSA',
      'Cookie': '__METADATA__=6989a6b0-dbfa-4caa-9a56-5d6231dd6a95; __METADATA__=6989a6b0-dbfa-4caa-9a56-5d6231dd6a95',
      "Authorization": "Bearer $token",
      'Content-Type': "application/json",
      
    };

    final body = {
      "applicationId": searchQuery,
      //"mobileNumber": searchQuery
    };

   

 




   


    final response = await ApiService.postJsonWithHeaders(url, body,headers);
    print("response is ${response!.data.body}");
    print("response is ${response.statusCode}"); //_99333220251218174946 639811223344

    if (response == null || response.statusCode != 200) {
      setState(() {
        _isLoading = false;
        _isFetchingMore = false;
      });
      return;
    }

    final appJson = json.decode(response.data.body);
    final List results = appJson['result'] ?? [];
    print("result is $results");

   

   final uniqueStatuses = results
    .map((item) => item['offerStatus']?.toString() ?? '')
    .toSet()
    .toList();
   print("uniqueStatuses is $uniqueStatuses");
  
   _switchToTabForStatus(uniqueStatuses);



   List<Map<String, dynamic>> mergedLeads = results.map<Map<String, dynamic>>(
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
      if (isLoadMore) {
        _mergedLeads.addAll(mergedLeads);
      } else {
        _mergedLeads = mergedLeads;
      }

      _isLoading = false;
      _isFetchingMore = false;

      // 🔹 No more pages
      if (mergedLeads.isEmpty) {
        _hasMoreData = false;
      }
    });
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
  print("firstStatus is $firstStatus");

  String firstUpperText = firstStatus.toUpperCase();
  String? tabTitle = _getTabTitleForStatus(firstUpperText);
 // print("tabTitle is $tabTitle");

  if (tabTitle != null && tabTitles.contains(tabTitle)) {
    int newIndex = tabTitles.indexOf(tabTitle);
   // print("new index is $newIndex");
    //print("tab controller is ${_tabController.index}");

    // Switch tab if it's not already selected
    if (_tabController.index != newIndex) {
      _tabController.animateTo(newIndex);
      //print("switch");
    }
  }
}


//********************************************** */









 void _categorizeLeads() {
      categorizedData['Total Accepted'] = _mergedLeads
          .where((lead) =>
              lead['offerStatus'] == 'Accept' ||
              lead['offerStatus'] == 'Accept_Manual')
          .toList();

      categorizedData['In-Progress'] = _mergedLeads
          .where((lead) => lead['offerStatus'] == 'In-Progress')
          .toList();

      categorizedData['In-Principle Approved'] = _mergedLeads
          .where((lead) => lead['offerStatus'] == 'Pre-Qualified')
          .toList();

      categorizedData['Final Approved'] =
          _mergedLeads.where((lead) => lead['offerStatus'] == 'Pass').toList();

      categorizedData['Declined'] = _mergedLeads
          .where((lead) =>
              lead['offerStatus'] == 'Cancel' ||
              lead['offerStatus'] == 'Fail' ||
              lead['offerStatus'] == 'REJECT' ||
              lead['offerStatus'] == 'Dedupe')
          .toList();

      categorizedData['Disbursed'] = _mergedLeads
          .where((lead) =>
              lead['offerStatus'] == 'Availed' ||
              lead['offerStatus'] == 'Avail_Manual')
          .toList();
    }
    String? _getTabTitleForStatus(String? status) {
    if (status == null) return null;
    switch (status) {
      case 'Accept':
      case 'Accept_Manual':
        return 'Total Accepted';
      case 'IN-PROGRESS':
        return 'In-Progress';
      case 'PRE-QUALIFIED':
        return 'In-Principle Approved';
      case 'Pass':
        return 'Final Approved';
      case 'Cancel':
      case 'Fail':
      case 'REJECT':
      case 'Dedupe':
        return 'Declined';
      case 'Availed':
      case 'Avail_Manual':
        return 'Disbursed';
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
               if (_isLoading) {
                  return Center(
                      child: CircularProgressIndicator(color: Colors.purple));
                }

                if (_mergedLeads.isEmpty) {
                  return const Center(child: Text("No Data Found"));
                }

                return ListView.builder(
                controller: _scrollController,
                itemCount: _mergedLeads.length + (_isFetchingMore ? 1 : 0),
                itemBuilder: (context, index) {

                  // 🔹 Bottom loader
                  if (index == _mergedLeads.length) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Center(
                        child: CircularProgressIndicator(color: Colors.purple),
                      ),
                    );
                  }

                  final lead = _mergedLeads[index];

                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border(
                        top: BorderSide(color: Color(0xFF640D78), width: 1.0),
                        bottom: BorderSide(color: Color(0xFF640D78), width: 1.0),
                        left: BorderSide(color: Color(0xFF640D78), width: 5.0),
                        right: BorderSide(color: Color(0xFF640D78), width: 1.0),
                      ),
                    ),
                    child: ListTile(
                      leading: const Icon(Icons.person, color: Colors.purple, size: 30),
                      title: Text(
                        "${lead['firstName']} ${lead['middleName']} ${lead['lastName']}".trim(),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        "Mobile: ${lead['mobilePhone']}\n"
                        "CWTransactionID: ${lead['CWTransactionID']}\n"
                        "ApplicationNo: ${lead['applicationNo']}\n"
                        "OfferStatus: ${lead['offerStatus']}",
                      ),
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
