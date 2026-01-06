import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:encrypt/encrypt.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:pointycastle/api.dart' hide Padding;
import 'package:pointycastle/asymmetric/api.dart';
import 'package:pointycastle/random/fortuna_random.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';
import 'package:unosfa/pages/FSAModule/LosApplicationModel.dart';
import 'package:unosfa/pages/FSAModule/LosSubmit.dart';
import 'package:unosfa/pages/FSAModule/fsadashboard.dart';
import 'package:unosfa/pages/FSAModule/leadsByCampaign.dart';
import 'package:unosfa/pages/FSAModule/losApplication.dart';
import 'package:unosfa/pages/Report/form_report.dart';
import 'package:unosfa/pages/config/config.dart';
import 'package:unosfa/pages/generalscreens/customNavigation.dart';
import 'package:unosfa/pages/generalscreens/message.dart';
import 'package:unosfa/pages/services/api_service.dart';
import 'package:unosfa/pages/services/secret_key.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../widgetSupport/widgetstyle.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_html/flutter_html.dart';

class Otpconcent extends StatefulWidget {
  final String phoneNumber;
  final LosApplicationModel losData;
  final String campaign;
  final String leadId;
  final String pagemode;

  const Otpconcent({
    super.key,
    required this.phoneNumber,
    required this.losData,
    required this.campaign,
    required this.leadId,
    required this.pagemode,
  });
  @override
  State<Otpconcent> createState() => OtpconcentState();
}

class OtpconcentState extends State<Otpconcent> {
  String IpAddress="";
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  Timer? _timer;
  int _start = 120;
  bool _isLoading = false;
  String recivedOtp = "";
  bool resendTimer = false;
  bool isOtpExpired = false;
  bool checkBox1 = false;
  bool checkBox2 = false;
  bool checkBox3 = false;
  String dsrIdValue = "";

  //bool isChecked = false;
  bool showOtpSection = false;
  List<String>? userInfo;

  @override
  void initState() {
    super.initState(); // check what data receive
    print("check what data receive");
    print(widget.losData.toJson());
   _start = 120; // 🔥 Add this line to initialize the countdown
    resendTimer = false;
    isOtpExpired = false;
    _sendOtp();
    _startTimer();
    getPublicIP();
    callSosLogoin();
  }
  Future<void> getPublicIP() async {
    final response =
        await http.get(Uri.parse('https://api64.ipify.org?format=json'));
    if (response.statusCode == 200) {
      String ip = jsonDecode(response.body)['ip'];
      // if (mounted) {
      setState(() {
        IpAddress = ip;
      });
      // }
    }
  }

  String formatedCode(String? code) {
  if (code == null || code.isEmpty) return "";
 // Remove all leading zeros first
  String cleaned = code.replaceFirst(RegExp(r'^0+'), '');
  if (cleaned.isEmpty) cleaned = "0";
  if (cleaned.length == 1) {
    return "0$cleaned";
  }
  return cleaned;
 }


  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_start == 0) {
        _timer?.cancel();
        setState(() {
          resendTimer = true;
          isOtpExpired = true;
        });
      } else {
        setState(() {
          _start--;
        });
      }
    });
  }

  String get _timerText {
    int minutes = _start ~/ 60;
    int seconds = _start % 60;
    return "$minutes:${seconds.toString().padLeft(2, '0')}";
  }

  void _resendOtp() {
    setState(() {
      _sendOtp();
      _start = 120; // Reset the timer
      _otpController.clear(); // Clear the OTP field
      resendTimer = false;
      isOtpExpired = false;
    });
    _startTimer(); // Start the timer again
  }


  FortunaRandom createSecureFortunaRandomFromEntropy(String entropySource) {
    final secureRandom = FortunaRandom();
    final entropy = sha256.convert(utf8.encode(entropySource)).bytes;
    secureRandom.seed(KeyParameter(Uint8List.fromList(entropy)));
    return secureRandom;
  }
 
 
  String generateSecureTransactionId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final entropyInput = '$timestamp:UnoSecureSeed';
    final secureRandom = createSecureFortunaRandomFromEntropy(entropyInput);

    // generate 4 random digits
    final digits = List.generate(6, (_) {
      final byte = secureRandom.nextUint8();
      return (byte % 10).toString();
    }).join();

    final now = DateTime.now();
    // final formattedDate =
    //     "${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}";

    final formattedDate =
      "${now.year}"
      "${now.month.toString().padLeft(2, '0')}"
      "${now.day.toString().padLeft(2, '0')}"
      "${now.hour.toString().padLeft(2, '0')}"
      "${now.minute.toString().padLeft(2, '0')}"
      "${now.second.toString().padLeft(2, '0')}";

    return "FSA_$digits$formattedDate"; 
  }



  String generateSecureOTP() {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final entropyInput = '$timestamp:UnoSecureSeed';
    final secureRandom = createSecureFortunaRandomFromEntropy(entropyInput);

    // generate 4 random digits
    final digits = List.generate(4, (_) {
      final byte = secureRandom.nextUint8();
      return (byte % 10).toString();
    }).join();

    // format date as YYYYMMDD
    final now = DateTime.now();
    final formattedDate =
        "${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}";

    return "$digits"; // appended date
  }

  void submitLos(LosApplicationModel data) async{ // async is updated here 2.12.2025
    setState(() => _isLoading = true);

    String CWTransactionID = generateSecureTransactionId();
    //final parsedDate = DateFormat('dd-MM-yyyy').parse(data.birthDate!);
    // String dob = data.birthDate!;
    // final parsedDate = DateFormat('dd-MM-yyyy').parse(dob);

    // String formattedBirthDate = DateFormat('yyyy-MM-dd').format(parsedDate);
    // print("formatted date is $formattedBirthDate");
   String dob = data.birthDate!; // "28-01-1960"

  // Split the string
    List<String> parts = dob.split('-');

    String day = '';
    String month = '';
    String year = '';
    if (parts[0].length == 4) {
      year = parts[0];
      month = parts[1];
      day = parts[2];
    } else if (parts[2].length == 4) {
      day = parts[0];
      month = parts[1];
      year = parts[2];
    }
    print("DAY $day");
    print("Month $month");
    print("YEar $year");
    // Reformat to yyyy-MM-dd
    String formattedBirthDate = "$year-$month-$day";

    print("Formated date $formattedBirthDate"); // 1960-01-28

   Map<String, dynamic> requestData = {
      "CWTransactionID": CWTransactionID,
      "clientDetails": {
        "ARN": "1513411334533400",
        "idmArnNo": "",
        "clientType": "",
        "firstName": data.firstName,
        "lastName": data.lastName,
        "middleName": (data.middleName == null || data.middleName!.isEmpty)? null : data.middleName,
        "mobilePhone": "63"+data.mobilePhone.toString(),
        "birthDate": formattedBirthDate,
        "gender": data.gender,
        "emailAddress": data.email,
        "homePhoneNumber": "",
        "branchKey": "",
        "branchId": "",
        "branch": "",
        "ClientIP": IpAddress.trim(),
        "Longitude": "",
        "Latitude": "",
        "addresses": [
          {
            "line1": "",
            "line2": "",
            "city": data.permCity,
            "region": data.permRegion,
            "postcode": data.permZipCode,
            "country": data.permCountryCode,
          }
        ],

       "idDocuments": [
        {
            "issuingAuthority": "",
            "address": data.address,
            "documentType": data.documentType,
            "validUntil": data.validUntil,
            "documentId": data.documentId,
            "firstName":data.firstName,
            "middleName":data.middleName,
            "lastName":data.lastName,
        }
    ],
        "_Perm_Address": {
          "perm_State": data.permState,
          "perm_City": data.permCity,
          "perm_Street": data.permStreet,
          "perm_ZipCode": data.permZipCode,
          "perm_Barangay": data.permBarangay,
          "perm_Region": data.permRegion,
          "perm_Country":
              data.nationality!.replaceFirst(RegExp(r'^0+'), ''),
          "perm_countryCode": data.nationality,
          "hra": ""
        },
        "_Fin_Details": {
          "fin_Mthly_Income": double.tryParse(data.empMonthsInCompany!)?.toInt().toString(),
          "fin_Ownr_Car": "",
          "fin_Ann_Income": "",
          "fin_Ownr_Home": "",
          "fin_Src_Of_Funds": data.finSourceOfFunds,
          "fin_Src_Of_Funds_Code": formatedCode(data.finSourceOfFundsCode),
          "fin_Salary_Period": "",
          "fin_Salary_dates": "",
        },
        "_Identification_Details": {
          "identity_TinId": data.tinId,
          "identity_GsisID": data.gsisId,
          "identity_SssID": data.sssId,
        },
        "Nom_Details": null,
        "_Emp_Details": {
          "emp_Work_Nature": data.empWorkNature,
          "emp_Mths_In_Cur_Comp": data.empMonthsInCompany,
          "emp_Status": formatedCode(data.empStatusCode),       //data.empStatus,
          "emp_Employer_Name": data.empEmployerName,
          "emp_Indus_Type": formatedCode(data.empIndustryTypeCode), //data.empIndustryType
          "emp_Type": formatedCode(data.empTypeCode), //data.empType
          "emp_Yrs_In_Cur_Comp": data.empYearsInCompany,
          "Office_phone_no": "",
          "emp_Type_Code": formatedCode(data.empTypeCode),    //data.empTypeCode!.replaceFirst(RegExp(r'^0+'), ''),
          "emp_Status_Code": formatedCode(data.empStatusCode), // data.empStatusCode!.replaceFirst(RegExp(r'^0+'), ''),
          "emp_Work_Nature_Code": formatedCode(data.empWorkNatureCode),  //data.empWorkNatureCode!.replaceFirst(RegExp(r'^0+'), ''),
          "emp_Indus_Type_Code":formatedCode(data.empIndustryTypeCode), //data.empIndustryTypeCode!.replaceFirst(RegExp(r'^0+'), ''),
          "emp_email": data.empEmail,
          "companyCategorySegment": "",
          "profession": data.profession
        },
        "_Emp_Address": {
          "emp_Street": data.empStreet,
          "emp_State": data.empState,
          "emp_City": data.empCity,
          "emp_Country": data.empCountry!.replaceFirst(RegExp(r'^0+'), ''),
          "emp_ZipCode": data.empZipCode,
          "emp_Barangay": data.empBarangay,
          "emp_Region": data.empRegion,
          "emp_countryCode": data.empCountryCode,
        },
        "_Personal_Details": {
          "fatca_Cert_US_Non_US": "",
          "fatca_W9_IdNumber": "",
          "no_Of_Dependents": "",
          "fatca_W9_IdType": "",
          "civil_Status": data.civilStatus,
          "yrs_In_Residence": "",
          "nationality": data.nationality,
          "marketing_Consent": "",
          "mailing_Adrs": "",
          "place_Of_Birth": data.placeOfBirth,
          "my_Job": "",
          "suffix": "",
          "nom_Counter": "",
          "cust_IdType": "",
          "card_Issuance_Status": "",
          "my_Job_Code": "",
          "vcard_issueDt": "",
          "data_Pvcy_Agrmt": "",
          "is_Term_Cond_Accepted": "",
          "is_Rcds_Edited": "",
          "designation": "",
        },
        "_Spouse_Details": {
          "spouse_Name": "",
          "spouse_Nationality": "",
          "spouse_DOB": "",
          "spouse_Place_Of_Birth": "",
          "spouse_Employment": "",
        },
        "dosri_Check": {
          "dosriCheck": "",
          "dosriName": "",
          "dosriRelationship": "",
        },
        "rpt_Check": {
          "rptCheck": "",
          "rptName": "",
          "rptRelationship": "",
        },
        "_Biz_Address": {
          "biz_Country": "",
          "biz_ZipCode": "",
          "biz_City": "",
          "biz_Street": "",
          "biz_State": "",
          "biz_Barangay": "",
          "biz_Region": "",
          "biz_countryCode": ""
        },
        "_Biz_Details": {
          "biz_IndusType": "",
          "biz_Nature": "",
          "biz_Name": "",
          "biz_Yrs_Operating": "",
          "biz_Mths_Operating": "",
          "Office_phone_no": "",
          "biz_email": ""
        },
        "_AML_Status": {
          "aml_Name_Screening_Flag": "",
          "aml_Scoring_Flag": "",
          "aml_Name_Request_ID": "",
          "aml_Name_Case_ID": "",
          "aml_Scoring_Request_ID": "",
          "aml_Scoring_Case_ID": ""
        },
      },
      "sourcing": {
        "customer": {
          "referralPromoCodeFlag": "",
          "referralCode": "",
          "promotionalCode": "",
          "sourceCompany": "UnoSales",
          "agentCode": data.agentCode,
        },
        "account": {
          "referralPromoCodeFlag": "",
          "referralCode": "",
          "promotionalCode": "",
          "sourceCompany": "UnoSales",
          "agentCode": data.agentCode,
        }
      },
      "partner": {
        "partnerName": "USA FSA",
        "natureOfPartnership": "USA FSA",
        "partnerUserID": "",
        "applicationNumber": CWTransactionID,
        "expectedMonthlyTransaction": "",
        "redirectionURL": "",
        "docURL": {
          "selfieURL": "",
          "idProofURL": "",
        },
        "partnerScore": {
          "partnerTelcoScore": 0,
          "partnerPrefilterScore": 0,
          "partnerBehaviourScore": 0,
          "partnerSocialScore": 0,
          "partnerAdditionalScore1": 0,
          "partnerAdditionalScore2": 0,
          "partnerAdditionalScore3": 0,
        },
        "partnerScreeningStages": {
          "eKYC": {
            "emailVerification": "N",
            "incomeValidation": "N",
            "addressValidation": "N",
            "employmentValidation": "N",
          }
        },
      },
      "customerConsent": 1,
    };

    setState(() {
      dsrIdValue = data.dsrId.toString();
    });
    postLoanCheck(requestData);
 
    // String jsonString = jsonEncode(requestData);
    // for (int i = 0; i < jsonString.length; i += 1000) {
    //   print(jsonString.substring(
    //       i, (i + 1000 > jsonString.length) ? jsonString.length : i + 1000));
    // }
  }

 
 // start created by 2/12/2025  *********

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
  final jsonObject = 
 

  {
    "userId": userInfo![0],
    "appId": "Sales_App",
  };

  // 2️⃣ Convert to JSON string
  final jsonString = json.encode(jsonObject);

  print("JSON Before Encryption: $jsonString");

  // 3️⃣ Encrypt JSON once
  final encrypted = encrypter.encrypt(jsonString).base64;

  print("Encrypted JSON: $encrypted");

  // 4️⃣ Final payload
  return {
    "data": encrypted,
    "keyId": "v1",
  };
}

Future<void> callSosLogoin() async {
  try {
    final payload = await buildPayload();
    print("Payload value is ${jsonEncode(payload)}");

    // 10.12.2025
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('accessToken');
    print("167.88.160.87 token is $token");

     try {
      String tokenUrl = "/api/leads/los-access-token/";
      final headers = {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'User-Agent':
            'Mozilla/5.0 (Linux; Android 11; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36',
      };
      final Tokenresponse = await ApiService.getWithHeaders(tokenUrl, headers);
      if (Tokenresponse != null) {
        final data = json.decode(Tokenresponse.body);
        token = data['access_token'];
        print("token get from los is this $token");
      }
    } catch (e) {
      print("HTTP Request Failed: $e");
    }

    // Done
    final url = Uri.parse("${AppConfig.otpUrl}/auth/sso-login");   //https://unoapi.uat.ph.unobank.asia/auth/sso-login
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

    print("API response is ${response.body}");

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final sostoken = data["token"];

      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString("ssoToken", sostoken);

      print("Token saved successfully $sostoken");
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
// Done created by 2/12/2025 *****************


  Future<void> waybookImplement(String cwId) async {
  try {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('accessToken');
    String? ssotoken = prefs.getString('ssoToken');

    print("Token: $token");
    print("SSO Token: $ssotoken");

    if (ssotoken == null) {
      print("ERROR: SSO token is missing. Run callSosLogoin() first.");
      return;
    }

    final encodedToken = Uri.encodeComponent(ssotoken);
    print("encode token is $encodedToken");



    int retryCount = 0;
    const int maxRetries = 3;

  
    while (retryCount < maxRetries) {
            print("API Attempt: $retryCount");

            final response = await http.get(
              Uri.parse(
                '${AppConfig.dynamicBaseUrl}/api/leads/los-details/?los_status__applicationNo=$cwId',
              ),
              headers: {'Authorization': 'Bearer $token'},
            );

            final data = json.decode(response.body);
            final result2 = data['results'][0]['los_status'];

            final offerStatus = result2['offerStatus'];
            final applicationStatus = result2['applicationStatus'];

            print("offerStatus = $offerStatus");
            print("applicationStatus = $applicationStatus");

            // ---------------------------------------------------
            // 1) PASSED → STOP LOOP + REDIRECT
            // ---------------------------------------------------
            if (offerStatus == "IN-PROGRESS" && applicationStatus == "Passed") {
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

                } else {
                  print("Could not launch $redirectUrl");
                }
              return;
            }

            // ---------------------------------------------------
            // 2) EMPTY OR NULL → WAIT 30 SEC & RETRY
            // ---------------------------------------------------
            if (offerStatus == "IN-PROGRESS" &&
                (applicationStatus == null || applicationStatus == "")) {

              retryCount++;

              print("ApplicationStatus empty → Retry $retryCount of $maxRetries");
              await Future.delayed(Duration(seconds: 30));

              if (retryCount >= maxRetries) {
                print("Max retries reached → Going to Dashboard");
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => NavigationPage()),
                  (route) => false,
                );
                return;
              }

              continue; // go to next loop iteration
            }

            // ---------------------------------------------------
            // 3) FAILED → STOP LOOP + GO DASHBOARD
            // ---------------------------------------------------
            if (offerStatus == "IN-PROGRESS" && applicationStatus == "Failed") {
              print("REJECTED");
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => NavigationPage()),
                (route) => false,
              );
              return;
            }

            break;
         }

      } catch (e) {
         print("ERROR calling API: $e");
      }
   }




// Done  by 8.12.2025


  Future<void> postLoanCheck(Map<String, dynamic> requestData) async {
    print("position 1");
    setState(() {});
    String tokens = "";
    try {
      print("position 2");
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('accessToken');
      final Tokenresponse = await http.get(
        Uri.parse('${AppConfig.dynamicBaseUrl}/api/leads/los-access-token/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'multipart/form-data',
          'User-Agent':
              'Mozilla/5.0 (Linux; Android 11; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36',
        },
      );
      final data = json.decode(Tokenresponse.body);
      tokens = data['access_token'];
    } catch (e) {
      print("HTTP Request Failed: $e");
    }

    print("position 3");
    final url = Uri.parse("${AppConfig.otpUrl}/pre-uw/save-payload"); 
   // https://unoapi.uat.ph.unobank.asia/pre-uw/save-payload' 
      
    final headers = {
      "Idempotency-Key": "th37per9-185d-4e22-83fb-18gf96g0g861",
      "Content-Type": "application/json",
      "Accept": "application/json",
      "Authorization": "Bearer $tokens",
      'User-Agent':
          'Mozilla/5.0 (Linux; Android 11; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36',
      "Correlation-Id": "1234",
      //"Channel": "SalesApp",
      "Channel": "FSA",
     "Cookie": "AWSALB=BBxk3EbWLtIG1Kav8Uzq4M35AQ6O/x7hZqOtLs0CoXlu4BrBbrhRhfBqa6tAbbpnx/2orMd0kt7fwL8nCPxthrnqBBozntvZC/Sf6p1jkVPiG3X9ttn0KLI4rtnY; AWSALBCORS=BBxk3EbWLtIG1Kav8Uzq4M35AQ6O/x7hZqOtLs0CoXlu4BrBbrhRhfBqa6tAbbpnx/2orMd0kt7fwL8nCPxthrnqBBozntvZC/Sf6p1jkVPiG3X9ttn0KLI4rtnY; METADATA=3c6749d5-60ea-4486-aede-fd4538d2fe39"

      
    };
    print("token for otp Cencent page is $tokens");
    // Api which work properly

    // final url = Uri.parse("${AppConfig.otpUrl}/partner/loans/check");
    // final headers = {
    //   "Idempotency-Key": "th37per9-185d-4e22-83fb-18gf96g0g861",
    //   "Content-Type": "application/json",
    //   "Accept": "application/json",
    //   "Authorization": "Bearer $tokens",
    //   'User-Agent':
    //       'Mozilla/5.0 (Linux; Android 11; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36',     
      
    // };
   print("url is $url");
   print("Header is $headers");
    String jsonString = jsonEncode(requestData);
    for (int i = 0; i < jsonString.length; i += 1000) {
      print(jsonString.substring(
          i, (i + 1000 > jsonString.length) ? jsonString.length : i + 1000));
    }
    print("position 4");
    try {
      print("position 5");
      print(url);
      print(headers);
      print(json.encode(requestData));
      final response = await http.post(
        url,
        headers: headers,
        body: json.encode(requestData),
      );
      print("los respose ${response.statusCode}");
        print("Response body ${response.body}");
      if (response.statusCode == 200) {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        String? token = prefs.getString('accessToken');
        final LosStatusUrl = Uri.parse(
            '${AppConfig.dynamicBaseUrl}/api/campaigns/${widget.campaign}/leads/${widget.leadId}/');

        final headers2 = {
          "Content-Type": "application/json",
          "Accept": "application/json",
          "Authorization": "Bearer $token",
          'User-Agent':
              'Mozilla/5.0 (Linux; Android 11; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36',
        };
        print("position 6");
        Map<String, String> mappedLOsData = {
          "cwtransection_id": "${requestData['CWTransactionID']}",
          "los_status": "submitted",
        };
        final responseLOS = await http.patch(
          LosStatusUrl,
          headers: headers2,
          body: json.encode(mappedLOsData),
        );
        print(responseLOS);
        final LoSResponcedata = json.decode(response.body);
        Map<String, dynamic> mappedData = {
          "mobileNo": "",
          "agentCode": "",
          "applicationNo": "${LoSResponcedata['applicationNumber']}",
          "channel": "",
          "source": ""
        };

        print("position 7");
        final fetchStatusUrl =
            Uri.parse("${AppConfig.otpUrl}/api/app/fetch/application/status");
        final fetchStatusHeaders = {
          'Content-Type': 'application/json',
          "Idempotency-Key": "jbkjdbjkjk",
          "Authorization": "Bearer $tokens",
          'User-Agent':
              'Mozilla/5.0 (Linux; Android 11; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36',
        };

        try {
          print("position 8");
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            },
          );



          // int retryCount = 0;
          // Map<String, dynamic>? data;
          // List<dynamic>? result;

          // while (retryCount < 3) {
          //   final Statusresponse = await http.post(
          //     fetchStatusUrl,
          //     headers: fetchStatusHeaders,
          //     body: json.encode(mappedData),
          //   );

          //   await Future.delayed(const Duration(seconds: 2)); // 2-second delay

          //   if (Statusresponse.statusCode == 200) {
          //     data = json.decode(Statusresponse.body);
          //     result = data?['result'];
          //     if (result != null && result.isNotEmpty) {
          //       break; // Success, exit retry loop
          //     }
          //   }
          //   retryCount++;
          // }
          // For wayBook
          Navigator.of(context).pop(); // close loader

          // print("Result status is show like that $result");

          // if (result == null || result.isEmpty) {
          //   showDialog(
          //     context: context,
          //     builder: (BuildContext context) {
          //       return const AlertDialog(
          //         title: Text("No Application Data"),
          //         content: Text(
          //             "The application status response returned null after retries."),
          //       );
          //     },
          //   );
          //   return;
          // }

          // var application = result[0]; // Safe to access now?
          print("position 9");

          final LosbackendStatusUrl =
              Uri.parse('${AppConfig.dynamicBaseUrl}/api/leads/los-details/');
          final headers3 = {
            "Content-Type": "application/json",
            "Accept": "application/json",
            "Authorization": "Bearer $token",
            'User-Agent':
                'Mozilla/5.0 (Linux; Android 11; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36',
          };
          print("position 10");

          final finalRequestData;
          if (widget.pagemode == 'edit') {
            finalRequestData = Map<String, dynamic>.from(requestData)
              ..["lead_type"] = "campaign_lead"
              ..["declaration"] = true
              ..["dsr"] = null;
          } else {
            print("fresh leadddd");
            finalRequestData = Map<String, dynamic>.from(requestData)
              ..["lead_type"] = "fresh_lead"
              ..["declaration"] = true
              // ..["dsr"] = "${widget.dsrId}";
              ..["dsr"] = dsrIdValue;
          }

          final backendresponseLOS = await http.post(
            LosbackendStatusUrl,
            headers: headers3,
            body: json.encode(finalRequestData),
          );
          // print(LosbackendStatusUrl);
          // print(headers3);
          // String jsonString = jsonEncode(finalRequestData);
          // for (int i = 0; i < jsonString.length; i += 1000) {
          //   print(jsonString.substring(i,
          //       (i + 1000 > jsonString.length) ? jsonString.length : i + 1000));
          // }

          print("backend response status is ${backendresponseLOS.statusCode}");

          if (backendresponseLOS.statusCode == 201) {
            
            final data = json.decode(backendresponseLOS.body);
            print("print data is $data");
            final LosBackendResponseUrl = Uri.parse(
                '${AppConfig.dynamicBaseUrl}/api/leads/los-details/${data['id']}/');
            final headers4 = {
              "Content-Type": "application/json",
              "Accept": "application/json",
              "Authorization": "Bearer $token",
              'User-Agent':
                  'Mozilla/5.0 (Linux; Android 11; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36',
            };
            print("header is $headers4");
            print("url is $LosBackendResponseUrl");

            Map<String, dynamic> mappedResponseLOsData = {
              "los_status": {
                "mobileNo": requestData['clientDetails']['mobilePhone'],
                "applicationNo": requestData['CWTransactionID'],
                "applicationId": requestData['CWTransactionID'],
                "source": 'UnoSales',
                "channel": 'fsa',
                "offerStatus": 'IN-PROGRESS',
                "uwStatus": '',
                "lastScreen": ''
              }
            };
            print(json.encode(mappedResponseLOsData));
            final responseLOS = await http.patch(
              LosBackendResponseUrl,
              headers: headers4,
              body: json.encode(mappedResponseLOsData),
            );
          }
          
          print("responseLOS is ${responseLOS.statusCode}");
          print("responseLOS is ${responseLOS.body}");

          waybookImplement(requestData['CWTransactionID']); 

    

          // if (application['offerStatus'] == "IN-PROGRESS") {
          //   print("position 11");
          //   checkApplicationStatusLoop(application);
          // } else {
          //   print("position 12");
          //   showDialog(
          //     context: context,
          //     builder: (BuildContext context) {
          //       return AlertDialog(
          //         title: Text("Application Status"),
          //         content: Text(
          //           "Offer Status: ${application['offerStatus']}\nUnderWriting Status: ${application['uwStatus']}",
          //         ),
          //         actions: [
          //           TextButton(
          //             onPressed: () {
          //               Navigator.of(context).pop();
          //               Navigator.pushReplacement(
          //                 context,
          //                 MaterialPageRoute(
          //                   builder: (context) =>
          //                       LeadListByCampaign(campaign: widget.campaign),
          //                 ),
          //               );
          //             },
          //             child: Text("OK"),
          //           ),
          //         ],
          //       );
          //     },
          //   );
          // }
        } catch (e) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Something went wrong: $e')),
          );
        }
      } else {
        print("position 14");
        SharedPreferences prefs = await SharedPreferences.getInstance();
        String? authToken = prefs.getString('accessToken');
        Map<String, dynamic> logmappedData = {
          "url": "${AppConfig.otpUrl}/partner/loans/check",
          "request_body": requestData,
          "status_code": response.statusCode,
          "response_body": json.decode(response.body),
        };
        final logUrl = Uri.parse("${AppConfig.dynamicBaseUrl}/api/logs/");

        final headers = {
          "Content-Type": "application/json",
          "Accept": "application/json",
          "Authorization": "Bearer $authToken",
          'User-Agent':
              'Mozilla/5.0 (Linux; Android 11; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36',
        };
        final LogResponse = await http.post(
          logUrl,
          headers: headers,
          body: json.encode(logmappedData),
        );
        if (LogResponse.statusCode == 201) {
          print("Log Created");
        }
        final data = json.decode(response.body);
        String message = data['message'] ?? "Validation Error";
        Map<String, dynamic> errors = data['errors'] ?? {};
        String errorMessages =
            errors.entries.map((entry) => "${entry.value}").join("\n");

        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              //title: Text("Hello Error"),
              title: Text("Success"),
              content: Text("$message\n\n$errorMessages"),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text("OK"),
                ),
              ],
            );
          },
        );
      }
      setState(() {});
    } catch (e) {
      print("HTTP Request Failed: $e");

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("Error"),
            content: Text("An error occurred. Please try again."),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text("OK"),
              ),
            ],
          );
        },
      );

      setState(() {});
    }
  }

  void checkApplicationStatusLoop(Map<String, dynamic> application) async {
    setState(() {
      _isLoading = true;
    });
    int retryCount = 0;
    bool isFinalStatus = false;
    String tokens = "";
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('accessToken');
    final Tokenresponse = await http.get(
      Uri.parse('${AppConfig.dynamicBaseUrl}/api/leads/los-access-token/'),
      headers: {
        'Authorization': 'Bearer $token',
        'User-Agent':
            'Mozilla/5.0 (Linux; Android 11; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36',
      },
    );
    final data = json.decode(Tokenresponse.body);
    tokens = data['access_token'];
    // String applicationN =application['applicationNo'];
    showDialog(
      barrierDismissible: false, // Prevent closing
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            Future<void> pollStatus(applicationN) async {
              while (retryCount < 5 &&
                  application['offerStatus'] == "IN-PROGRESS") {
                await Future.delayed(Duration(seconds: 20)); // Wait 10 seconds
                retryCount++;

                // Refresh status via API
                final refreshedResponse = await http.post(
                  Uri.parse(
                      '${AppConfig.dynamicBaseUrl}/api/app/fetch/application/status'),
                  headers: {
                    'Content-Type': 'application/json',
                    "Idempotency-Key": "jbkjdbjkjk",
                    "Authorization": "Bearer $tokens",
                  },
                  body: json.encode({
                    "mobileNo": "",
                    "agentCode": "",
                    "applicationNo": "${application['applicationNo']}",
                    "channel": "",
                    "source": ""
                  }),
                );
                if (refreshedResponse.statusCode == 200) {
                  final refreshedData = json.decode(refreshedResponse.body);
                  if (refreshedData['result'] != null &&
                      refreshedData['result'].isNotEmpty) {
                    application = refreshedData['result'][0];
                  }
                }

                if (application['offerStatus'] != "IN-PROGRESS") {
                  isFinalStatus = true;
                  break;
                }
              }

              Navigator.of(context).pop(); // Close progress dialog
              if (isFinalStatus) {
                String offerStatus = application['offerStatus'];
                if (["Cancel", "Fail", "REJECT", "Dedupe"]
                    .contains(offerStatus)) {
                  // Rejected states
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Text("Application"),
                        content: Text(
                          "Your application does not meet Uno Criteria, thank you for applying – Uno Bank\n"
                          "Application Status: $offerStatus\n"
                          "Application No: $applicationN",
                        ),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => NavigationPage(),
                                ),
                              );
                            },
                            child: Text("Ok"),
                          ),
                        ],
                      );
                    },
                  );
                } else {
                  // Approved or any other final state
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Text("Application"),
                        content: Text(
                          "Your application has been in-principally approved, please ask customer to visit Uno Bank Mobile app to complete the application – Uno Bank\n"
                          "Application Status: $offerStatus\n"
                          "Application No: $applicationN",
                        ),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => NavigationPage(),
                                ),
                              );
                            },
                            child: Text("Ok"),
                          ),
                        ],
                      );
                    },
                  );
                }
              } else {
                String offerStatus = application['offerStatus'];

                if (offerStatus == "IN-PROGRESS" ||
                    offerStatus == "PRE-QUALIFIED") {
                  // Still in progress
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Text("Application"),
                        content: Text(
                          "Your application is currently **$offerStatus**. Our team is reviewing your details.\n"
                          "Application Status: $offerStatus\n"
                          "Application No:  $applicationN",
                        ),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => NavigationPage(),
                                ),
                              );
                            },
                            child: Text("Ok"),
                          ),
                        ],
                      );
                    },
                  );
                }
              }
            }

            // Start polling
            pollStatus(application['applicationNo']);

            return AlertDialog(
              title: Text("Checking Status..."),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 10),
                  Text(
                      "Checking application status...\nThis may take up to 30 seconds or more."),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _sendOtp() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? authToken = prefs.getString('accessToken');
    String otp = generateSecureOTP();
    setState(() {
      recivedOtp = otp.toString();
    });
    // Step 1: Get access token
    String clientId = await otpClientId();
    String clientSecret = await otpClientSecret();

    final body = {
      'client_id': clientId,
      'client_secret': clientSecret,
      'grant_type': 'client_credentials',
    };

    final response = await http.post(
      Uri.parse('${AppConfig.otpUrl}/oauth2/token'),
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: body,
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final accessToken = data['access_token'];
      // Step 2: Send SMS using the access token
      final smsResponse = await http.post(
        Uri.parse('${AppConfig.otpUrl}/fnf/api/v2/sms/sendSmsMessage'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: json.encode({
          "messages": [
            {
              "from": "UnoBank",
              "destinations": [
                {"to": "${widget.phoneNumber}"}
              ],
              "text":
                  """Your One-Time PIN is ${otp}. NEVER SHARE YOUR OTP. UNO will never request OTP from customers. If you did not request an OTP, please contact us."""
            }
          ]
        }),
      );
      if (smsResponse.statusCode == 200) {
        print('SMS sent successfully!');
        setState(() {
          recivedOtp = otp.toString();
        });
      } else {
        Map<String, dynamic> logmappedData = {
          "url": "${AppConfig.otpUrl}/fnf/api/v2/sms/sendSmsMessage'",
          "request_body": json.encode({
            "messages": [
              {
                "from": "UnoBank",
                "destinations": [
                  {"to": "${widget.phoneNumber}"}
                ],
                "text":
                    """Your One-Time PIN is ${otp}. NEVER SHARE YOUR OTP. UNO will never request OTP from customers. If you did not request an OTP, please contact us."""
              }
            ]
          }),
          "status_code": smsResponse.statusCode,
          "response_body": json.decode(smsResponse.body),
        };
        final logUrl = Uri.parse("${AppConfig.dynamicBaseUrl}/api/logs/");
        final headers = {
          "Content-Type": "application/json",
          "Accept": "application/json",
          "Authorization": "Bearer $authToken",
          'User-Agent':
              'Mozilla/5.0 (Linux; Android 11; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36',
        };
        // ignore: unused_local_variable
        final LogResponse = await http.post(
          logUrl,
          headers: headers,
          body: json.encode(logmappedData),
        );
      }
    } else {
      print('Failed to fetch token. Status: ${response.statusCode}');
    }
  }

  Future<void> _verifyOtp() async {
    setState(() {
      _isLoading = true;
    });
    if (isOtpExpired) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text("Invalid OTP"),
          content: Text("The OTP has expired."),
        ),
      );
      return;
    } else {
      if (_formKey.currentState?.validate() ?? false) {
        if (recivedOtp == _otpController.text) {
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: Text("Info"),
              content: Text("OTP Success Full"),
              actions: [
                TextButton(
                  //onPressed: () => Navigator.of(context).pop(),
                  onPressed: () {
                    Navigator.of(context).pop(); // Close dialog
                    submitLos(widget.losData);
                  },
                  child: Text("OK"),
                ),
              ],
            ),
          );
        } else {
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: Text("Info"),
              content: Text("Invalid OTP"),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text("OK"),
                ),
              ],
            ),
          );
        }
      }

      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
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
                  MaterialPageRoute(
                      builder: (context) => NavigationPage()),
                );
              },
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.05,
                ),
                _buildTextbox(),
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.05,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 0.0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Checkbox(
                            value: checkBox1,
                            onChanged: (value) {
                              _showInfoDialog(
                                title: "Terms & Conditions",
                                content: consentTermsDesc,
                                onAgree: () {
                                  setState(() => checkBox1 = true);
                                },
                              );
                            },
                          ),
                          const Expanded(
                            child: Text(
                              "I have read, understood and agreed to UNO Digital Bank's Terms & Conditions",
                              style: TextStyle(fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Checkbox(
                            value: checkBox2,
                            onChanged: (value) {
                              _showInfoDialog(
                                title: consentPrivacyTitle,
                                content: consentPrivacyDesc,
                                onAgree: () {
                                  setState(() => checkBox2 = true);
                                },
                              );
                            },
                          ),
                          const Expanded(
                            child: Text(
                              "I have read, understood and agreed to UNO Digital Bank's Data Privacy Statement",
                              style: TextStyle(fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Checkbox(
                            value: checkBox3,
                            onChanged: (value) {
                              setState(() => checkBox3 = value ?? false);
                            },
                          ),
                          const Expanded(
                            child: Text(
                              "I agree to recive promotional and marketing content from UNO Digital Bank and its affiliates.(Optional)",
                              style: TextStyle(fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.05,
                      ),
                      Visibility(
                        visible:
                            !showOtpSection, // Hide button when OTP section is visible
                        child: GestureDetector(
                          onTap: () {
                            if (checkBox1 && checkBox2) {
                              setState(() {
                                showOtpSection = true; // Show OTP section
                              });
                              _sendOtp(); // Call your OTP sending method
                            } else {
                              showTopSnackBar(
                                Overlay.of(context),
                                CustomSnackBar.info(
                                  backgroundColor: const Color(0xFF640D78),
                                  message:
                                      "Please agree to both the Terms & Conditions and the Data Privacy Statement before proceeding.",
                                  textStyle: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              );
                            }
                          },
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            child: Center(
                              child: Text(
                                "Get OTP",
                                style: WidgetSupport.LoginButtonTextColor(),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Visibility(
                  visible: showOtpSection, // controls visibility
                  child: Column(
                    children: [
                      (AppConfig.flavour != 'prod')
                          ? Text(
                              'Enter OTP sent to your phone OTP [${recivedOtp}]',
                              style: const TextStyle(fontSize: 16),
                              textAlign: TextAlign.center,
                            )
                          : const Text(
                              'Enter OTP sent to your phone',
                              style: TextStyle(fontSize: 16),
                              textAlign: TextAlign.center,
                            ),
                      const SizedBox(height: 10),
                      Text(
                        _timerText,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(
                          height: MediaQuery.of(context).size.height * 0.05),
                      Form(
                        key: _formKey,
                        child: _buildOtpBox(),
                      ),
                      SizedBox(
                          height: MediaQuery.of(context).size.height * 0.02),
                      Container(
                        width: MediaQuery.of(context).size.width * 0.60,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            GestureDetector(
                              onTap: _verifyOtp,
                              child: Container(
                                color: Colors.transparent,
                                child: Center(
                                  child: Text(
                                    "Verify OTP",
                                    style: WidgetSupport.LoginButtonTextColor(),
                                  ),
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                if (resendTimer) {
                                  _resendOtp(); // Only call when allowed
                                }
                              },
                              child: Container(
                                color: Colors.transparent,
                                child: Center(
                                  child: Text(
                                    "Resend OTP",
                                    style: WidgetSupport.LoginButtonTextColor()
                                        .copyWith(
                                      color: resendTimer
                                          ? Colors.purple
                                          : Colors.grey,
                                    ),
                                  ),
                                ),
                              ),
                            ),

                          ],
                          
                        ),
                      ),
                      
                     
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.transparent,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }

  void _showInfoDialog({
    required String title,
    required String content,
    required VoidCallback onAgree,
  }) {
    showDialog(
      context: context,
      builder: (context) {
        // Fix HTML line breaks
        String fixedHtml = content.replaceAll('</br>', '<br>');

        return AlertDialog(
          insetPadding: EdgeInsets.only(
            top: MediaQuery.of(context).size.height * 0.09,
          ),
          backgroundColor: const Color(0xFF640D78),
          //title: Text(title,),
          title: Text(
            title,
            style: TextStyle(color: Colors.white),
          ),
          content: SingleChildScrollView(
            child: Html(
              data: fixedHtml,
              style: {
                "body": Style(
                  color: Colors.white,
                  fontSize: FontSize(16),
                ),
                "p": Style(
                  color: Colors.white,
                ),
                "strong": Style(
                  color: Colors.white,
                ),
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                onAgree();
              },
              child: const Text(
                "Agree",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildOtpBox() {
    return Container(
      width: MediaQuery.of(context).size.width * 0.60,
      child: SizedBox(
        child: TextFormField(
          controller: _otpController,
          focusNode: _focusNode,
          keyboardType: TextInputType.number,
          maxLength: 4,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            counterText: "",
            hintText: "-   -   -   -",
            hintStyle: TextStyle(color: Colors.grey),
            contentPadding: EdgeInsets.symmetric(vertical: 10),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.purple),
            ),
          ),
          validator: (value) {
            if (value == null || value.length != 4) {
              return 'Please enter a 4-digit OTP';
            }
            return null;
          },
          autocorrect: false,
          enableSuggestions: false,
        ),
      ),
    );
  }

  Widget _buildTextbox() {
    return Container(
      width: MediaQuery.of(context).size.width * 0.90,
      child: SizedBox(
        child: TextFormField(
          enabled: false,
          //readOnly: true,
          controller: _phoneController,
          maxLength: 4,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            fillColor: Colors.grey,
            counterText: "",
            label: Container(
              padding: EdgeInsets.only(left: 20),
              child: Text(widget.phoneNumber, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900),)),
            
            hintStyle: TextStyle(color: Colors.grey),
            contentPadding: EdgeInsets.symmetric(vertical: 10),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.black12),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.purple),
            ),
          ),
          autocorrect: false,
          enableSuggestions: false,
        ),
      ),
    );
  }
}




 //Uri.parse('${AppConfig.dynamicBaseUrl}/api/leads/los-access-token/'),

