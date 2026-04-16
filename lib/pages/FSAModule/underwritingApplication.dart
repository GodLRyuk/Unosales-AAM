import 'dart:convert';
import 'package:encrypt/encrypt.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pointycastle/asymmetric/api.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unosfa/pages/config/config.dart';
import 'package:unosfa/pages/generalscreens/customNavigation.dart';
import 'package:unosfa/pages/services/api_service.dart';
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

  @override
  void initState() {
    super.initState();
    loadInitialLeads();
  }

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
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => NavigationPage()),
                );
              },
            ),
          ),
        ),
      ),
      body: Column(
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
                    child: CircularProgressIndicator(),
                  )
                : results.isEmpty
                    ? const Center(
                        child: Text(
                          "No Data Found",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      )
                    : ListView.builder(
                        itemCount: results.length,
                        itemBuilder: (context, index) {
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
                                      "CWTransactionID: ${leadData['CWTransactionID'] ?? 'N/A'}"),
                                  Text(
                                      "Offer Status: ${losStatus['offerStatus'] ?? 'N/A'}"),
                                  Text(
                                      "UW Status: ${losStatus['uwStatus'] ?? 'N/A'}"),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          "Application No: ${losStatus['applicationNo'] ?? 'N/A'}",
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
    );
  }

  Future<void> loadInitialLeads() async {
    try {
      setState(() {
        isLoading = true;
      });

      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('accessToken');

      final url = "/api/leads/los-details/";

      final headers = {
        'Authorization': 'Bearer $token',
        'User-Agent':
            'Mozilla/5.0 (Linux; Android 11; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36',
      };

      final response = await ApiService.getWithHeaders(url, headers);

      if (response != null && response.statusCode == 200) {
        final data = jsonDecode(response.body);

        List allResults = data["results"] ?? [];

        List filteredResults = allResults
            .where((item) => item["workflow_status"] == "SW_PW")
            .toList();

        setState(() {
          results = filteredResults;
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print("Exception: $e");
    }
  }

  Future<void> underWritingStatus(String searchValue) async {
    try {
      setState(() {
        isLoading = true;
      });

      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('accessToken');

      final url = "/api/leads/los-details/?search=$searchValue";

      final headers = {
        'Authorization': 'Bearer $token',
        'User-Agent':
            'Mozilla/5.0 (Linux; Android 11; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36',
      };

      final response = await ApiService.getWithHeaders(url, headers);

      if (response != null && response.statusCode == 200) {
        final data = jsonDecode(response.body);

        List allResults = data["results"] ?? [];

        List filteredResults = allResults
            .where((item) => item["workflow_status"] == "SW_PW")
            .toList();

        setState(() {
          results = filteredResults;
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
        print("Error: ${response?.body}");
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print("Exception: $e");
    }
  }

  String publicKeyP1 = """
-----BEGIN PUBLIC KEY-----
MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAibVtzmmpQ8OpmWzF3M3Z
KPDURcq55io/K5K0OJaoHrkVfEaDTy+irLoqvwaQc80jFJtbQRjYSIezK8gYnRM6
e4MlSw+Wojr9NSjBMYRZ7mr+WDXNqdVI36ml9IXl4e0xAD/4Gm/IhaQCZFCxWl35
VeKdfNI1YdfMp2vYRLgGDWfeSFf87REIUCfOv6pUeG5cwE8ittGFh6M+k5ZXdB5O
Vs7yVx5vqbrIzL+ucHlys2K5PDgPJ5VDBZ6GeyoS7+PlC/JOp9OH5kS/53KUTgs+
ZEFCBwjHh4gEzA2LBumOEHpxOTV42d0zLDlr1qmLXuLVbKIoVn1/9mhyf2a5L63N
AQIDAQAB
-----END PUBLIC KEY-----
""";

  Future<Map<String, dynamic>> buildPayload() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    userInfo = prefs.getStringList('userInfo');
    //String agentCode = "testFSA";
    print("agent code is $userInfo[0]");

    if (userInfo![0] == null || userInfo![0].isEmpty) {
      throw Exception("Agent code not found in SharedPreferences");
    }

    // Parse RSA Public Key
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
      // print("encode token is $encodedToken");

      final url = Uri.parse('${AppConfig.unoBaseApiUrl}/api/app/offer');

      final headers = {
        'Authorization': 'Bearer $losToken',
        'Content-Type': 'application/json',
      };

      final body = {
        "applicationId": cwId,
      };
      print("cw id is $cwId");

      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(body),
      );

      final data = json.decode(response.body);
      String offerStatus = data[0]['offerStatus'];
      //********************************************** */

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

          final losUrl =
              "${AppConfig.dynamicBaseUrl}/api/leads/los-details/$losId/";
          final headers = {
            'Authorization': 'Bearer $token',
            'User-Agent':
                'Mozilla/5.0 (Linux; Android 11; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36',
          };
          final body = {"workflow_status": "AAM Invoked"};

          final responsefromLOS =
              await ApiService.patchWithHeaders(losUrl, headers, body);
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
          "offerStatus": "Fail"
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
          "offerStatus": "Fail",
          
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
      }
    } catch (e) {
      print("ERROR calling API: $e");
    }
  }
}
