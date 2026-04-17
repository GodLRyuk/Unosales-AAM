import 'dart:convert';
import 'package:encrypt/encrypt.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pointycastle/asymmetric/api.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unosfa/pages/FSAModule/underwritingApplication.dart';
import 'package:unosfa/pages/config/config.dart';
import 'package:unosfa/pages/generalscreens/customNavigation.dart';
import 'package:unosfa/pages/services/api_service.dart';
import 'package:unosfa/pages/services/secret_key.dart';
import 'package:url_launcher/url_launcher.dart';

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
  List<String>? userInfo;
  final List<String> tabTitles = [
    'UNDERWRITING STATUS', //'SW_PW'
    'TOTAL ACCEPTED',
    'IN-PROGRESS',
    'IN-PRINCIPLE APPROVED',
    'FINAL APPROVED',
    'DECLINED',
    'DISBURSED',
  ];
  late TabController _tabController;
  List<dynamic> losData = [];
  final _searchFilter = TextEditingController();

  Map<String, List<dynamic>> categorizedData = {
    'UNDERWRITING STATUS': [],
    'TOTAL ACCEPTED': [],
    'IN-PROGRESS': [],
    'IN-PRINCIPLE APPROVED': [],
    'FINAL APPROVED': [],
    'DECLINED': [],
    'DISBURSED': []
  };
  List<Map<String, dynamic>> _mergedLeads = [];
  int _currentPage = 1;
  bool _isFetchingMore = false;
  bool _hasMoreData = true;
  final ScrollController _scrollController = ScrollController();

  Map<int, bool> _tabLoading = {};
  String tabSearch = "";
  String searchValue = ""; //******************************* */
  bool _isSearchCompleted = false;
  bool _isAutoTabChange = false;

  @override
  void initState() {
    super.initState();
    searchValue = widget.searchQuery ?? '';

    tabSearch = widget.initialTabTitle.toString().toUpperCase();
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
      tabSearch = currentTitle.toUpperCase();

      if (_tabController.indexIsChanging) {
        setState(() {
          _tabLoading[_tabController.index] = true;
          //_loadLOSData(); //********** */
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

    // _tabController.addListener(() {
    //   setState(() {
    //     searchValue = "";
    //     print("search value is null");
    //   });
    //   // if (_tabController.indexIsChanging) return;
    //   _resetAndLoad();
    // });

    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;

      // ✅ If tab change is from search
      if (_isAutoTabChange) {
        _isAutoTabChange = false;

        if (_isSearchCompleted) {
          setState(() {
            searchValue = "";
          });
          _isSearchCompleted = false;
        }

        return;
      }

      _resetAndLoad();
    });

    _scrollController.addListener(_onScroll);

    // Load LOS data
    //_loadLOSData();
    callSosLogoin();
  }

  void _resetAndLoad() async {
    final selectedTab = tabTitles[_tabController.index];
    final status = _tabStatusMap[selectedTab];

    setState(() {
      _currentPage = 1;
      _hasMoreData = true;
      _mergedLeads.clear();
    });

    if (searchValue.trim().isNotEmpty) {
      await _searchLOSData(
        isLoadMore: false,
        searchQuery: searchValue,
      );
    } else {
      print("No search value");
      await _loadLOSData();
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
    'UNDERWRITING STATUS': 'UNDERWRITING STATUS',
    'TOTAL ACCEPTED': 'Accept,Accept_Manual',
    'IN-PROGRESS': 'IN-PROGRESS',
    'IN-PRINCIPLE APPROVED': 'PRE-QUALIFIED',
    'FINAL APPROVED': 'Pass',
    'DECLINED': 'Cancel,Fail,REJECT,Dedupe',
    'DISBURSED': 'Availed,Avail_Manual',
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

    String? statusValue = _tabStatusMap[tabSearch];

    List<String> statusList = statusValue?.split(',') ?? [];

    List<Map<String, dynamic>> mergedLeads = [];

    final headers = {
      'Authorization': 'Bearer $accessToken',
      'User-Agent':
          'Mozilla/5.0 (Linux; Android 11; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36',
    };

    for (String status in statusList) {
      String endPointUrl = "los_status__offerStatus=$status";
      if (status == "UNDERWRITING STATUS") {
        endPointUrl = "workflow_status=SW_PW";
      }
      String url = "/api/leads/los-details/?$endPointUrl";

      final response = await ApiService.getWithHeaders(url, headers);
      if (response != null && response.statusCode == 200) {
        final appJson = json.decode(response.body);
        final List results = appJson['results'];

        for (var item in results) {
          final clientDetails = item['clientDetails'];

          final losStatus = item['los_status'];

          mergedLeads.add({
            'id': item['id']?.toString() ?? '',
            'firstName': clientDetails?['firstName']?.toString() ?? '',
            'middleName': clientDetails?['middleName']?.toString() ?? '',
            'lastName': clientDetails?['lastName']?.toString() ?? '',
            'mobilePhone': clientDetails?['mobilePhone']?.toString() ?? '',
            'CWTransactionID': item['CWTransactionID']?.toString() ?? '',
            'applicationNo': losStatus?['applicationNo']?.toString() ?? '',
            'offerStatus': losStatus?['offerStatus']?.toString() ?? '',
            'uwStatus': losStatus?['uwStatus']?.toString() ?? '',
            'workflow_status': item['workflow_status']?.toString() ?? '',
          });
        }
      }
    }

    setState(() {
      _mergedLeads = mergedLeads;
      _categorizeLeads();
      _isLoading = false;
    });
  }

  Future<void> _searchLOSData({
    String? searchQuery,
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
      String? accessToken = prefs.getString('accessToken');

      String url = "/api/leads/los-details/?search=$searchQuery";
      final headers = {
        'Authorization': 'Bearer $accessToken',
        'User-Agent':
            'Mozilla/5.0 (Linux; Android 11; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36',
      };

      final response = await ApiService.getWithHeaders(url, headers);

      if (response == null || response.statusCode != 200) {
        setState(() {
          _isLoading = false;
          _isFetchingMore = false;
        });
        return;
      }

      final appJson = json.decode(response.body);
      final List results = appJson['results'] ?? [];

      final uniqueStatuses = results
          .map((item) => item['los_status']?['offerStatus']?.toString() ?? '')
          .toSet()
          .toList();

      List<Map<String, dynamic>> mergedLeads =
          results.map<Map<String, dynamic>>(
        (appLead) {
          final client = appLead['clientDetails'] ?? {};
          final losStatus = appLead['los_status'] ?? {};
          return {
            'firstName': client['firstName'] ?? '',
            'middleName': client['middleName'] ?? '',
            'lastName': client['lastName'] ?? '',
            'mobilePhone': client['mobilePhone'] ?? '',
            'CWTransactionID': appLead['CWTransactionID'] ?? '',
            'applicationNo': appLead['CWTransactionID'] ?? '',
            'offerStatus': losStatus['offerStatus'] ?? '',
          };
        },
      ).toList();

      setState(() {
        _mergedLeads = mergedLeads;
        _categorizeLeads();
        _isLoading = false;
      });

      if (_mergedLeads.isNotEmpty) {
        final matchedStatus = _mergedLeads.first['offerStatus'];
        final statusTab = _getTabTitleForStatus(matchedStatus);

        if (statusTab != null && tabTitles.contains(statusTab)) {
          final index = tabTitles.indexOf(statusTab);
          _isSearchCompleted = true;
          _isAutoTabChange = true;
          _tabController.animateTo(index);
        }
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

  void _categorizeLeads() {
    categorizedData['TOTAL ACCEPTED'] = _mergedLeads.where((lead) {
      final status = (lead['offerStatus'] ?? '').toString().toUpperCase();
      return status == 'ACCEPT' || status == 'ACCEPT_MANUAL';
    }).toList();

    categorizedData['IN-PROGRESS'] = _mergedLeads
        .where((lead) =>
            (lead['offerStatus'] ?? '').toString().toUpperCase() ==
            'IN-PROGRESS')
        .toList();

    categorizedData['IN-PRINCIPLE APPROVED'] = _mergedLeads
        .where((lead) =>
            (lead['offerStatus'] ?? '').toString().toUpperCase() ==
            'PRE-QUALIFIED')
        .toList();

    categorizedData['FINAL APPROVED'] = _mergedLeads
        .where((lead) =>
            (lead['offerStatus'] ?? '').toString().toUpperCase() == 'PASS')
        .toList();

    categorizedData['DECLINED'] = _mergedLeads.where((lead) {
      final status = (lead['offerStatus'] ?? '').toString().toUpperCase();
      return status == 'CANCEL' ||
          status == 'FAIL' ||
          status == 'REJECT' ||
          status == 'DEDUPE';
    }).toList();

    categorizedData['DISBURSED'] = _mergedLeads.where((lead) {
      final status = (lead['offerStatus'] ?? '').toString().toUpperCase();
      return status == 'AVAILED' || status == 'AVAIL_MANUAL';
    }).toList();

    categorizedData['UNDERWRITING STATUS'] = _mergedLeads.where((lead) {
      final status = (lead['workflow_status'] ?? '').toString().toUpperCase();
      // print("status is ${lead['workflow_status']}");
      return status == 'SW_PW';
    }).toList();
  }

  String? _getTabTitleForStatus(String? status) {
    if (status == null) return null;

    switch (status.toUpperCase()) {
      case 'ACCEPT':
      case 'ACCEPT_MANUAL':
        return 'TOTAL ACCEPTED';

      case 'IN-PROGRESS':
        return 'IN-PROGRESS';

      case 'PRE-QUALIFIED':
        return 'IN-PRINCIPLE APPROVED';

      case 'PASS':
        return 'FINAL APPROVED';

      case 'CANCEL':
      case 'FAIL':
      case 'REJECT':
      case 'DEDUPE':
        return 'DECLINED';

      case 'AVAILED':
      case 'AVAIL_MANUAL':
        return 'DISBURSED';

      case 'SW_PW':
        return 'UNDERWRITING STATUS';

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
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 17, left: 250),
              child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                        context,
                        (MaterialPageRoute(
                            builder: (context) => Underwritingapplication())));
                  },
                  child: Text(
                    "CHECK UW APPLICATION",
                    style: TextStyle(fontSize: 13, color: Colors.purple),
                  )),
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
        
                  final currentTabLeads =
                      categorizedData[tabTitles[_tabController.index]]!;
        
                  if (currentTabLeads.isEmpty) {
                    return ListView(
                      physics: AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                        Center(child: Text("No Data Found"))
                        ]);
                  }
        
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
                          subtitle: selectedTab == 'UNDERWRITING STATUS'
                              ? Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text("Mobile: ${lead['mobilePhone']}"),
                                          Text(
                                              "CWTransactionID: ${lead['CWTransactionID']}"),
                                          Text(
                                              "ApplicationNo: ${lead['applicationNo']}"),
                                          SizedBox(height: 5),
                                          Row(
                                            //mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  "OfferStatus: ${lead['offerStatus']}",
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              GestureDetector(
                                                onTap: () {
                                                  String cwTransactionID =
                                                      lead['CWTransactionID']
                                                          .toString();
                                                  waybookImplement(
                                                      cwTransactionID,
                                                      lead['id'].toString());
                                                },
                                                child: Text(
                                                  "CHECK STATUS",
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                    color: Colors.purple,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                )
                              : Text(
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
      ),
    );
  }

  Future<void> _handleRefresh() async {
     _searchFilter.clear();
   _resetAndLoad();  
    await Future.delayed(Duration(seconds: 2)); // Simulate a delay
  }


  Future<Map<String, dynamic>> buildPayload() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    userInfo = prefs.getStringList('userInfo');
    //String agentCode = "testFSA";
    print("agent code is $userInfo[0]");

    if (userInfo![0] == null || userInfo![0].isEmpty) {
      throw Exception("Agent code not found in SharedPreferences");
    }

    // Parse RSA Public Key
    String publicKeyP1 = await getPublicKey();
    final parser = RSAKeyParser();
    final RSAPublicKey rsaPublicKey = parser.parse(publicKeyP1) as RSAPublicKey;

    final encrypter = Encrypter(
      RSA(publicKey: rsaPublicKey),
    );

    // 1️⃣ JSON object to encrypt
    final jsonObject = {
      "userId": userInfo![0],
      "appId": "Sales_App",
    };

    // 2️⃣ Convert to JSON string
    final jsonString = json.encode(jsonObject);

    // 3️⃣ Encrypt JSON once
    final encrypted = encrypter.encrypt(jsonString).base64;

    // 4️⃣ Final payload
    return {
      "data": encrypted,
      "keyId": "v1",
    };
  }

  Future<void> callSosLogoin() async {
    try {
      final payload = await buildPayload();
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('accessToken');
      try {
        String tokenUrl = "/api/leads/los-access-token/";
        final headers = {
          'Authorization': 'Bearer $token',
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

      // Done
      final url = Uri.parse("${AppConfig.otpUrl}/auth/sso-login");
      final headers = {
        "Authorization": 'Bearer $token',
        "Content-Type": "application/json",
        "Accept": "application/json",
        "User-Agent":
            "Mozilla/5.0 (Linux; Android 11; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36",
      };

      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(payload),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final sostoken = data["token"];

        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString("ssoToken", sostoken);

        //return sostoken;
      } else {
        print("Error happened → Status: ${response.statusCode}");
        // return null;
      }
    } catch (e) {
      print("Error is this: $e");
      //return null;
    }
  }

  Future<void> waybookImplement(String cwId, String losId) async {
    setState(() {
      _isLoading = true;
    });
    String losToken = "";
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('accessToken');
      String? ssotoken = prefs.getString('ssoToken');

      try {
        String tokenUrl = "/api/leads/los-access-token/";
        final headers = {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'User-Agent':
              'Mozilla/5.0 (Linux; Android 11; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36',
        };
        final Tokenresponse =
            await ApiService.getWithHeaders(tokenUrl, headers);
        if (Tokenresponse != null) {
          final data = json.decode(Tokenresponse.body);
          losToken = data['access_token'];
        }
      } catch (e) {
        print("HTTP Request Failed: $e");
      }

      if (ssotoken == null) {
        print("ERROR: SSO token is missing. Run callSosLogoin() first.");
        return;
      }

      final encodedToken = Uri.encodeComponent(ssotoken);
      final offerUrl = "/api/app/offer";

      final headers = {
        'Authorization': 'Bearer $losToken',
        'Content-Type': 'application/json',
      };

      final body = {
        "applicationId": cwId,
      };
      final response =
          await ApiService.postJsonWithUNOApiHeaders(offerUrl, body, headers);
      final data = json.decode(response!.body);
      String offerStatus = data[0]['offerStatus'];
      String aamUrl = "/api/leads/los-details/?los_status__applicationNo=$cwId";
      final aamheader = {'Authorization': 'Bearer $token'};

      final res = await ApiService.getWithHeaders(aamUrl, aamheader);
      final datares = json.decode(res!.body);
      final resresult = datares['results'][0]['los_status'];

      final applicationStatus = resresult['applicationStatus'];

      // 1) PASSED → STOP LOOP + REDIRECT

      if (offerStatus == "In-Progress" && applicationStatus == "Passed") {
        print("APPROVED → Redirecting to AAM");

        String applicationId = cwId;

        final redirectUrl =
            "${AppConfig.aamredictUrl}/fsa-aam-auth?token=$encodedToken&sales_app=$applicationId";

        final uri = Uri.parse(redirectUrl);
        if (await canLaunchUrl(uri)) {
          // 1️⃣ Navigate to Dashboard first
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => NavigationPage()),
            (route) => false,
          );

          // 2️⃣ Then launch AAM URL in browser
          await launchUrl(uri, mode: LaunchMode.externalApplication);

          final losUrl = "/api/leads/los-details/$losId/";
          final headers = {
            'Authorization': 'Bearer $token',
            'User-Agent':
                'Mozilla/5.0 (Linux; Android 11; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36',
            'Content-Type': 'application/json',
          };
          final body = {"workflow_status": "AAM Invoked"};

          final responsefromLOS =
              await ApiService.patchWithHeaders(losUrl, headers, body);
          print("response code ${responsefromLOS!.statusCode}");
        } else {
          print("Could not launch $redirectUrl");
        }

        return;
      } else if (offerStatus == "In-Progress" &&
          applicationStatus == "Failed") {
        final losUrl = "/api/leads/los-details/$losId/";
        final headers = {
          'Authorization': 'Bearer $token',
          'User-Agent':
              'Mozilla/5.0 (Linux; Android 11; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36',
          'Content-Type': 'application/json',
        };
        final body = {
          "workflow_status": "Prelim UW Failed",
           "los_status":{"offerStatus": "Fail",}
        };

        final responsefromLOS =
            await ApiService.patchWithHeaders(losUrl, headers, body);
        // print("code is ${responsefromLOS!.statusCode}");

        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text("Application Status $offerStatus"),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => NavigationPage()));
                  },
                  child: const Text("OK"),
                ),
              ],
            );
          },
        );

        setState(() {
          _isLoading = false;
        });

        return;
      } else if (offerStatus == "Fail" && applicationStatus == "Failed") {
        final losUrl = "/api/leads/los-details/$losId/";
        final headers = {
          'Authorization': 'Bearer $token',
          'User-Agent':
              'Mozilla/5.0 (Linux; Android 11; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36',
          'Content-Type': 'application/json',
        };
        final body = {
          "workflow_status": "Prelim UW Failed",
           "los_status":{"offerStatus": "Fail",}
        };

        final responsefromLOS =
            await ApiService.patchWithHeaders(losUrl, headers, body);
        // print("code is ${responsefromLOS!.statusCode}");

        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text("Application Status $offerStatus"),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => NavigationPage()));
                  },
                  child: const Text("OK"),
                ),
              ],
            );
          },
        );

        setState(() {
          _isLoading = false;
        });

        return;
      } else {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text("Application Status $offerStatus"),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => NavigationPage()));
                  },
                  child: const Text("OK"),
                ),
              ],
            );
          },
        );

        setState(() {
          _isLoading = false;
        });

        return;
      }
    } catch (e) {
      print("ERROR calling API: $e");
    }
  }
}
