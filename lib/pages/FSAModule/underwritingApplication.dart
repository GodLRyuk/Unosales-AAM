import 'dart:convert';
import 'package:encrypt/encrypt.dart';
import 'package:flutter/material.dart';
import 'package:pointycastle/asymmetric/api.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unosfa/pages/FSAModule/los_status_chart.dart';
import 'package:unosfa/pages/config/config.dart';
import 'package:unosfa/pages/generalscreens/customNavigation.dart';
import 'package:unosfa/pages/services/api_service.dart';
import 'package:unosfa/pages/services/secret_key.dart';
import 'package:url_launcher/url_launcher.dart';

class Underwritingapplication extends StatefulWidget {
  const Underwritingapplication({super.key});

  @override
  State<Underwritingapplication> createState() =>
      _UnderwritingapplicationState();
}

class _UnderwritingapplicationState extends State<Underwritingapplication> {
  final TextEditingController _searchFilter = TextEditingController();

  List results = [];
  String? workflowStatus;
  bool isLoading = false;
  List<String>? userInfo;

  // Pagination variables
  int _currentPage = 1;
  bool _isFetchingMore = false;
  bool _hasMoreData = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    loadInitialLeads();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients || _isFetchingMore || !_hasMoreData)
      return;

    final threshold = 200.0;
    // Trigger pagination when reaching near the bottom
    if (_scrollController.position.extentAfter < threshold) {
      setState(() {
        _isFetchingMore = true;
      });

      _currentPage++;

      final searchData = _searchFilter.text.trim();
      if (searchData.isNotEmpty) {
        underWritingStatus(searchData, isLoadMore: true);
      } else {
        loadInitialLeads(isLoadMore: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60.0),
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
            centerTitle: true,
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
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        LosStatusChart(initialTabTitle: 'IN-PROGRESS'),
                  ),
                );
              },
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        child: Column(
          children: [
            /// 🔎 Search Field
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: TextField(
                controller: _searchFilter,
                decoration: InputDecoration(
                  labelText: 'Search By Name, Phone Number, TransactionID',
                  enabledBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFFac00d0)),
                  ),
                  suffixIcon: Container(
                    color: const Color(0xFFac00d0),
                    child: IconButton(
                      onPressed: () {
                        final searchData = _searchFilter.text.trim();
                        if (searchData.isNotEmpty) {
                          underWritingStatus(searchData);
                        }
                      },
                      icon: const Icon(Icons.search, color: Colors.white),
                    ),
                  ),
                ),
              ),
            ),

            Expanded(
              child: isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: Colors.purple),
                    )
                  : results.isEmpty
                      ? ListView(
                          physics: AlwaysScrollableScrollPhysics(),
                          children: [
                              SizedBox(height: 200),
                              Center(
                                child: Text(
                                  "No Data Found",
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ])
                      : ListView.builder(
                          controller:
                              _scrollController, // Added ScrollController for pagination
                          itemCount: results.length + (_isFetchingMore ? 1 : 0),
                          itemBuilder: (context, index) {
                            // Bottom loader
                            if (index == results.length) {
                              return const Center(
                                child: Padding(
                                  padding: EdgeInsets.symmetric(vertical: 16.0),
                                  child: CircularProgressIndicator(
                                      color: Colors.purple),
                                ),
                              );
                            }

                            final leadData = results[index];
                            final client = leadData["clientDetails"] ?? {};
                            final losStatus = leadData["los_status"] ?? {};

                            return Container(
                              margin: const EdgeInsets.symmetric(
                                  vertical: 10, horizontal: 10),
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
                                leading: const Icon(
                                  Icons.person,
                                  color: Colors.purple,
                                  size: 30,
                                ),
                                title: Text(
                                  "${client['firstName'] ?? ''} "
                                          "${client['middleName'] ?? ''} "
                                          "${client['lastName'] ?? ''}"
                                      .trim(),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                        "Mobile: ${client['mobilePhone'] ?? 'N/A'}"),
                                    Text(
                                        "Application No: ${losStatus['applicationNo'] ?? 'N/A'}"),
                                    Text(
                                        "Offer Status: ${losStatus['offerStatus'] ?? 'N/A'}"),
                                   
                                    // Text(
                                    //     "UW Status: ${losStatus['uwStatus'] ?? 'N/A'}"),
                                    
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child:  Text(
                                        "Application Status: ${losStatus['applicationStatus'] ?? 'N/A'}",
                                        overflow: TextOverflow.ellipsis,
                                        ),
                                        
                                        ),
                                        GestureDetector(
                                          onTap: () {
                                            String cwTransactionID =
                                                leadData['CWTransactionID'];

                                            waybookImplement(cwTransactionID,
                                                leadData['id'].toString());
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
                                    SizedBox(height: 5),
                                  ],
                                ),
                              ),
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
    await loadInitialLeads();
    await Future.delayed(Duration(seconds: 2)); // Simulate a delay
  }

  Future<void> loadInitialLeads({bool isLoadMore = false}) async {
    try {
      if (!isLoadMore) {
        setState(() {
          isLoading = true;
          _currentPage = 1;
          _hasMoreData = true;
        });
      }

      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('accessToken');

      // Append page parameter to URL
      final url = "/api/leads/los-details/?page=$_currentPage";

      final headers = {
        'Authorization': 'Bearer $token',
        'User-Agent':
            'Mozilla/5.0 (Linux; Android 11; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36',
      };

      final response = await ApiService.getWithHeaders(url, headers);

      if (response != null && response.statusCode == 200) {
        final data = response.data;

        List allResults = data["results"] ?? [];

        if (allResults.isEmpty) {
          _hasMoreData = false;
        }

        List filteredResults = allResults
            .where((item) =>
                item["workflow_status"] == "SW_PW" ||
                item["workflow_status"] == "submit")
            .toList();

        setState(() {
          if (isLoadMore) {
            results.addAll(filteredResults);
            _isFetchingMore = false;
          } else {
            results = filteredResults;
            isLoading = false;
          }
        });
      } else {
        setState(() {
          isLoading = false;
          _isFetchingMore = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        _isFetchingMore = false;
      });
      print("Exception: $e");
    }
  }

  Future<void> underWritingStatus(String searchValue,
      {bool isLoadMore = false}) async {
    try {
      if (!isLoadMore) {
        setState(() {
          isLoading = true;
          _currentPage = 1;
          _hasMoreData = true;
        });
      }

      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('accessToken');

      // Append page parameter to search URL
      final url =
          "/api/leads/los-details/?search=$searchValue&page=$_currentPage";

      final headers = {
        'Authorization': 'Bearer $token',
        'User-Agent':
            'Mozilla/5.0 (Linux; Android 11; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36',
      };

      final response = await ApiService.getWithHeaders(url, headers);

      if (response != null && response.statusCode == 200) {
        final data = response.data;

        List allResults = data["results"] ?? [];

        if (allResults.isEmpty) {
          _hasMoreData = false;
        }

        List filteredResults = allResults
            .where((item) =>
                item["workflow_status"] == "SW_PW" ||
                item["workflow_status"] == "submit")
            .toList();

        setState(() {
          if (isLoadMore) {
            results.addAll(filteredResults);
            _isFetchingMore = false;
          } else {
            results = filteredResults;
            isLoading = false;
          }
        });
      } else {
        setState(() {
          isLoading = false;
          _isFetchingMore = false;
        });
        print("Error: ${response?.data}");
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        _isFetchingMore = false;
      });
      print("Exception: $e");
    }
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
          //'User-Agent':
          //  'Mozilla/5.0 (Linux; Android 11; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36',
        };
        final Tokenresponse =
            await ApiService.getWithHeaders(tokenUrl, headers);
        if (Tokenresponse != null) {
          final data = Tokenresponse.data;
          token = data['access_token'];
        }
      } catch (e) {
        print("HTTP Request Failed: $e");
      }

      final endpoint = '/auth/sso-login';

      final headers = {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'User-Agent':
            'Mozilla/5.0 (Linux; Android 11; Mobile) AppleWebKit/537.36 '
                '(KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36',
      };

      final response =
          await ApiService.postWithHeadersUnoApi(endpoint, payload, headers);

      if (response != null && response.statusCode == 200) {
        final data = response.data;
        final sostoken = data["token"];

        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString("ssoToken", sostoken);

        //return sostoken;
      } else {
        print("Error happened → Status: ${response!.statusCode}");
        // return null;
      }
    } catch (e) {
      print("Error is this: $e");
      //return null;
    }
  }

  Future<void> waybookImplement(String cwId, String losId) async {
    setState(() {
      isLoading = true;
    });

    print("web hock call");
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
          // 'User-Agent':
          //   'Mozilla/5.0 (Linux; Android 11; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36',
        };
        final Tokenresponse =
            await ApiService.getWithHeaders(tokenUrl, headers);

        if (Tokenresponse != null) {
          final data = Tokenresponse.data;
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

      final url = "/api/app/offer";

      final headers = {
        'Authorization': 'Bearer $losToken',
        'Content-Type': 'application/json',
      };

      final body = {
        "applicationId": cwId,
      };
      print("cw id is $cwId");

      final response =
          await ApiService.postJsonWithUNOApiHeaders(url, body, headers);

      final data = response!.data;
      String offerStatus = data[0]['offerStatus'];

      String aamUrl = "/api/leads/los-details/?los_status__applicationNo=$cwId";
      final aamheader = {'Authorization': 'Bearer $token'};

      final res = await ApiService.getWithHeaders(aamUrl, aamheader);
      final datares = res!.data;
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
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          final losUrl = "/api/leads/los-details/$losId/";
          final headers = {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
            'User-Agent':
                'Mozilla/5.0 (Linux; Android 11; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36',
          };
          final body = {"workflow_status": "AAM_InProgress"};

          final responsefromLOS =
              await ApiService.patchWithHeaders(losUrl, headers, body);
          await Future.delayed(Duration(seconds: 5));
          if (!mounted) return;

          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
               // title: Text("Congratulations!"),
                content: Text("Your application successfully redirected to AAM"),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (context) => NavigationPage(),
                        ),
                        (route) => false,
                      );
                    },
                    child: Text("OK"),
                  ),
                ],
              );
            },
          );
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
          "los_status": {
            "offerStatus": "Fail",
          }
        };

        final responsefromLOS =
            await ApiService.patchWithHeaders(losUrl, headers, body);
        // print("code is ${responsefromLOS!.statusCode}");

        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text("Application Status\n $offerStatus"),
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
          isLoading = false;
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
          "los_status": {
            "offerStatus": "Fail",
          }
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
          isLoading = false;
        });

        return;
      } else {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text("Application Status\n $offerStatus"),
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
          isLoading = false;
        });

        return;
      }
    } catch (e) {
      print("ERROR calling API: $e");
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }
}
