import 'dart:convert';
import 'package:app_settings/app_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_datetime_picker_bdaya/flutter_datetime_picker_bdaya.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:pointycastle/api.dart' hide Padding;
import 'package:pointycastle/random/fortuna_random.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unosfa/pages/FSAModule/fsaleaddashboard.dart';
import 'package:unosfa/pages/FSAModule/leadsByCampaign.dart';
import 'package:unosfa/pages/config/config.dart';
import 'package:intl/intl.dart';
import 'package:unosfa/pages/generalscreens/customNavigation.dart';
import 'package:unosfa/pages/services/api_service.dart';
import 'package:unosfa/widgetSupport/widgetstyle.dart';
import 'package:crypto/crypto.dart';

class FrLosApplicationPage extends StatefulWidget {
  final String leadId;
  final String campaign;
  final String pagemode;
  const FrLosApplicationPage(
      {super.key,
      required this.leadId,
      required this.campaign,
      required this.pagemode});

  @override
  State<FrLosApplicationPage> createState() => _FrLosApplicationPageState();
}

enum IdType { tin, sss, gsis }

class _FrLosApplicationPageState extends State<FrLosApplicationPage> {
  final firstName = TextEditingController();
  final middlename = TextEditingController();
  final lastName = TextEditingController();
  final mobilePhone = TextEditingController();
  final birthDate = TextEditingController();
  final gender = TextEditingController();
  final email = TextEditingController();
  final perm_State = TextEditingController();
  final perm_City = TextEditingController();
  final perm_Street = TextEditingController();
  // final perm_ZipCode = TextEditingController();
  final TextEditingController perm_ZipCode = TextEditingController();

  final perm_Barangay = TextEditingController();
  final perm_Region = TextEditingController();
  final perm_countryCode = TextEditingController();

  final genderFocusNode = FocusNode();

  final fin_Mthly_Income = TextEditingController();
  final fin_Src_Of_Funds = TextEditingController();
  final fin_Src_Of_Funds_Code = TextEditingController();

  final identity_TinId = TextEditingController();
  final identity_SssID = TextEditingController();
  final identity_GsisID = TextEditingController();

  final emp_Work_Nature = TextEditingController();
  final emp_Mths_In_Cur_Comp = TextEditingController();
  final emp_Status = TextEditingController();
  final emp_Employer_Name = TextEditingController();
  final emp_Indus_Type = TextEditingController();
  final emp_Type = TextEditingController();
  final emp_Yrs_In_Cur_Comp = TextEditingController();
  final emp_Type_Code = TextEditingController();
  final emp_Status_Code = TextEditingController();
  final emp_Work_Nature_Code = TextEditingController();
  final emp_Indus_Type_Code = TextEditingController();
  final emp_email = TextEditingController();
  final profession = TextEditingController();

  final emp_Street = TextEditingController();
  final emp_State = TextEditingController();
  final emp_City = TextEditingController();
  final emp_Country = TextEditingController();
  final emp_ZipCode = TextEditingController();
  final emp_Barangay = TextEditingController();
  final emp_Region = TextEditingController();
  final emp_countryCode = TextEditingController();

  final civil_Status = TextEditingController();
  final nationality = TextEditingController();
  final place_Of_Birth = TextEditingController();

  final sourceCompany = TextEditingController();
  final agentCode = TextEditingController();

  final partnerName = TextEditingController();
  final natureOfPartnership = TextEditingController();
  final applicationNumber = TextEditingController();
  final CWTransactionID = TextEditingController();
  final emp_Work_Exp = TextEditingController();
  final emp_position = TextEditingController();
  final ClientIP = TextEditingController();
  final disclaimerCheck = TextEditingController();
  bool _isChecked = false;
  String IpAddress = "";
  String latitude = "";
  String longitude = "";
  IdType? _selectedIdType;
  bool EmpStatus = false;
  Map<String, dynamic> leadDetails = {}; // To store the lead details
  bool _isLoading = false;

  @override
  void initState() {
    if (widget.pagemode == "edit" || widget.pagemode == 'view') {
      fetchLeadDetails();
    }
    super.initState();
    _initializeGenderList();
    _initializeEmpWorkNatureList();
    _initializeEmpStatusList();
    _initializeEmpTypeList();
    _initializeEmpprofessionList();
    _initializeCivilList();
    _loadagent();
    getPublicIP();
    getCurrentLocation(context);
    _initializeEmpPositionList();
    _initializeIndustryTypeList();
    _initializeWorkExprienceList();
    _initializeNationalityList();
  }

  List<Map<String, dynamic>> genderList = [];
  List<Map<String, dynamic>> countryList = [];
  List<String> PermbarangayList = [];
  List<String> EmpbarangayList = [];
  List<Map<String, dynamic>> sourceofFundList = [];
  List<Map<String, dynamic>> empWorkNatureList = [];
  List<Map<String, dynamic>> empStatusList = [];
  List<Map<String, dynamic>> empList = [];
  List<Map<String, dynamic>> empProfessionList = [];
  List<Map<String, dynamic>> civilStatusList = [];
  List<Map<String, dynamic>> nationalityList = [];
  List<Map<String, dynamic>> position = [];
  List<Map<String, dynamic>> industryList = [];
  List<Map<String, dynamic>> workExperience = [];

  List<String>? userInfo;
  String? _selectedBarangay;
  String? _selectedEmpBarangay;

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

  // Function to check location access
  Future<void> getCurrentLocation(BuildContext context) async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await _showBlockedDialog(
        context,
        title: "Location Services Disabled",
        message: "Please enable GPS (Location Services) to use this feature.",
        actionText: "Open Settings",
        onAction: () {
          AppSettings.openAppSettings();
        },
      );
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      await _showBlockedDialog(
        context,
        title: "Location Permission Required",
        message:
            "This page needs location permission to work. Please allow it in settings.",
        actionText: "Open App Settings",
        onAction: () {
          AppSettings.openAppSettings();
        },
      );
      return;
    }

    // If permission is granted, continue
    debugPrint("✅ Location permission granted.");
  }

  // Non-dismissible dialog function
  Future<void> _showBlockedDialog(
    BuildContext context, {
    required String title,
    required String message,
    required String actionText,
    required VoidCallback onAction,
  }) async {
    await showDialog(
      context: context,
      barrierDismissible: false, // BLOCK user from closing it
      builder: (_) => WillPopScope(
        // BLOCK back button
        onWillPop: () async => false,
        child: AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: onAction,
              child: Text(actionText),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> fetchLeadDetails() async {
    setState(() {
      _isLoading = true;
    });
    getCurrentLocation(context);
    // getPublicIP();\
    _initializeSourceFundList();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('accessToken');
    String? refresh = prefs.getString('refreshToken');
    userInfo = prefs.getStringList('userInfo');
    try {
      // final response = await http.get(
      //   Uri.parse(
      //       '${AppConfig.dynamicBaseUrl}/api/campaigns/${widget.campaign}/leads/${widget.leadId}/'), // Using leadId in the API URL
      //   headers: {
      //     'Authorization': 'Bearer $token',
      //     'Accept': 'application/json',
      //     'Content-Type': 'multipart/form-data',
      //     'User-Agent':
      //         'Mozilla/5.0 (Linux; Android 11; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36',
      //   },
      // );

      String url = "/api/campaigns/${widget.campaign}/leads/${widget.leadId}/";
      final header = {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Content-Type': 'multipart/form-data',
        'User-Agent':
            'Mozilla/5.0 (Linux; Android 11; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36',
      };
      final response = await ApiService.getWithHeaders(url, header);
      if (response!.statusCode == 200) {
        setState(() {
          leadDetails = response.data;
          // String jsonString = jsonEncode(leadDetails);
          // for (int i = 0; i < jsonString.length; i += 1000) {
          //   print(jsonString.substring(i,
          //       (i + 1000 > jsonString.length) ? jsonString.length : i + 1000));
          // }
          firstName.text = leadDetails['first_name'] ?? "";
          lastName.text = leadDetails['last_name'] ?? "";
          middlename.text = leadDetails['middle_name'] ?? "";
          mobilePhone.text = leadDetails['mobile_phone'].substring(2) ?? "";
          birthDate.text = leadDetails['birth_date'] ?? "";
          gender.text = leadDetails['gender'] ?? "";
          email.text = leadDetails['emp_email'] ?? "";
          ClientIP.text = IpAddress;
          // Permanent Address
          perm_State.text = leadDetails['perm_state'] ?? "";
          perm_City.text = leadDetails['perm_city'] ?? "";
          perm_Street.text = leadDetails['perm_street'] ?? "";
          perm_ZipCode.text = leadDetails['perm_zip_code'] ?? "";
          onEditZipCodeEntered(perm_ZipCode.text);
          perm_Barangay.text = leadDetails['perm_barangay'] ?? "";
          setState(() {
            _selectedBarangay = perm_Barangay.text;
          });
          // print(_selectedBarangay);
          perm_Region.text = leadDetails['perm_region'] ?? "";
          perm_countryCode.text = leadDetails['perm_country_code'] ?? "";
          // Financial Details
          fin_Mthly_Income.text = leadDetails['fin_monthly_income'] ?? "";
          fin_Src_Of_Funds.text = leadDetails['fin_src_of_funds'] ?? "";
          fin_Src_Of_Funds_Code.text =
              leadDetails['fin_src_of_funds_code'] ?? "";

          // Identification Details
          identity_TinId.text = "";
          identity_GsisID.text = "";
          identity_SssID.text = "";
          // Employment Details
          emp_Work_Nature.text = leadDetails['emp_work_nature'] ?? "";
          emp_Work_Nature_Code.text = leadDetails['emp_work_nature_code'] ?? "";
          emp_Mths_In_Cur_Comp.text =
              leadDetails['emp_mths_in_cur_comp'].toString();
          // This should come from your lead details (as int or string)
          final int months =
              int.tryParse(emp_Mths_In_Cur_Comp.text.toString()) ?? 0;

// Find matching months from workExperience and assign that string value
          emp_Mths_In_Cur_Comp.text = getClosestWorkExperienceMonths(months);
          emp_Status.text = leadDetails['emp_status'] ?? "";
          emp_Status_Code.text = leadDetails['emp_status_code'];
          emp_Employer_Name.text = leadDetails['emp_employer_name'] ?? "";
          emp_Indus_Type.text = leadDetails['emp_indus_type'] ?? "";
          emp_Indus_Type_Code.text = leadDetails['emp_indus_type_code'] ?? "";
          emp_Type.text = leadDetails['emp_type'] ?? "";
          emp_Yrs_In_Cur_Comp.text =
              leadDetails['emp_yrs_in_cur_comp']?.toString() ?? "";

          emp_email.text = leadDetails['emp_email'] ?? "";
          // Employment Address
          emp_Street.text = leadDetails['emp_street'] ?? "";
          emp_State.text = leadDetails['emp_state'] ?? "";
          emp_City.text = leadDetails['emp_city'] ?? "";
          emp_Country.text = leadDetails['emp_country'] ?? "";
          emp_Barangay.text = leadDetails['emp_barangay'] ?? '';
          emp_ZipCode.text = leadDetails['emp_zip_code'] ?? "";
          onEditEmpZipCodeEntered(emp_ZipCode.text);
          setState(() {
            _selectedEmpBarangay = emp_Barangay.text;
          });
          emp_Region.text = leadDetails['emp_region'] ?? "";
          emp_countryCode.text = leadDetails['emp_country_code'] ?? "";
          emp_Type_Code.text = leadDetails['emp_type_code'] ?? "";
          emp_Status_Code.text = leadDetails['emp_status_code'] ?? "";
          emp_Work_Nature_Code.text = leadDetails['emp_work_nature_code'] ?? "";
          emp_Indus_Type_Code.text = leadDetails['emp_indus_type_code'] ?? "";
          nationality.text = leadDetails['nationality'] ?? "";
          // Personal Details
          civil_Status.text = leadDetails['civil_status'] ?? "";
          place_Of_Birth.text = leadDetails['place_of_birth'] ?? "";
          // Spouse Details
          // Sourcing Customer
          sourceCompany.text = "UnoSales";
          // Partner Details
          partnerName.text = "USA FSA";
          natureOfPartnership.text = "USA FSA";
          // applicationNumber.text = applicationNum;
          Future.delayed(Duration(seconds: 10), () {
            setState(() {
              _isLoading = false; // Data loaded after 5 seconds
            });
          });
        });
      } else if (response.statusCode == 401) {
        // Map<String, dynamic> mappedData = {
        //   'refresh': refresh,
        // };
        // final response2 = await http.post(
        //   Uri.parse(
        //       '${AppConfig.dynamicBaseUrl}/api/users/token-refresh/'), // Using leadId in the API URL
        //   body: mappedData,
        // );

        String url = "/api/users/token-refresh/";
        final body = {
          'refresh': refresh,
        };
        final response2 = await ApiService.post(url, body);
        final data = response2!.data;
        await prefs.setBool('isLoggedIn', true);
        await prefs.setString('accessToken', data['access']);
        await prefs.setString('refreshToken', data['refresh']);
        fetchLeadDetails();
      } else {
        throw Exception('Failed to load lead details');
      }
    } catch (e) {
      print('Error fetching lead details: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> refressToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.getString('accessToken');
    String? refresh = prefs.getString('refreshToken');
    // Map<String, dynamic> mappedData = {
    //   'refresh': refresh,
    // };
    // final response2 = await http.post(
    //   Uri.parse('${AppConfig.dynamicBaseUrl}/api/users/token-refresh/'),
    //   body: mappedData,
    // );
    String url = "/api/users/token-refresh/";
    final body = {
      'refresh': refresh,
    };
    final response2 = await ApiService.post(url, body);
    final data = response2!.data;
    await prefs.setBool('isLoggedIn', true);
    await prefs.setString('accessToken', data['access']);
    await prefs.setString('refreshToken', data['refresh']);
  }

  Future<void> onZipCodeEntered(String zipCode) async {
    String tokens = "";
    setState(() {
      perm_Region.text = '';
      perm_State.text = '';
      perm_City.text = '';
      PermbarangayList = [];
      perm_Barangay.text = '';
      _selectedBarangay = null; // ✅ Reset selected value
    });

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('accessToken');

      // final tokenResponse = await http.get(
      //   Uri.parse('${AppConfig.dynamicBaseUrl}/api/leads/los-access-token/'),
      //   headers: {
      //     'Authorization': 'Bearer $token',
      //     'Accept': 'application/json',
      //     'Content-Type': 'multipart/form-data',
      //     'User-Agent':
      //         'Mozilla/5.0 (Linux; Android 11; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36',
      //   },
      // );

      String url = "/api/leads/los-access-token/";
      final headers = {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Content-Type': 'multipart/form-data',
        'User-Agent':
            'Mozilla/5.0 (Linux; Android 11; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36',
      };

      final tokenResponse = await ApiService.getWithHeaders(url, headers);
      final tokenData = tokenResponse!.data;
      tokens = tokenData['access_token'];
    } catch (e) {
      print("HTTP Request Failed: $e");
    }

    try {
      // final response = await http.post(
      //   Uri.parse('${AppConfig.otpUrl}/api/app/address'),
      //   headers: {
      //     'Authorization': 'Bearer $tokens',
      //     'Content-Type': 'application/json',
      //     'Idempotency-Key': 'sfsggdhsdgdgdg',
      //     'User-Agent':
      //         'Mozilla/5.0 (Linux; Android 11; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36',
      //   },
      //   body: jsonEncode({"zipcode": "$zipCode"}),
      // );
      String url = "/api/app/address";
      final headers = {
        'Authorization': 'Bearer $tokens',
        'Content-Type': 'application/json',
        'Idempotency-Key': 'sfsggdhsdgdgdg',
        'User-Agent':
            'Mozilla/5.0 (Linux; Android 11; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36'
      };

      final body = {
        "zipcode": "$zipCode",
      };

      final response =
          await ApiService.postWithHeadersUnoApi(url, body, headers);

      if (response!.statusCode == 200) {
        final data = response.data;
        setState(() {
          perm_Region.text = data['region'];
          perm_State.text = data['province'];
          perm_City.text = data['cityMunicipality'];
        });

        final Map<String, dynamic> responseBody = response.data;

        if (responseBody['barangays'] is List &&
            responseBody['barangays'].isNotEmpty) {
          final barangays = responseBody['barangays'];

          if (barangays is List) {
            setState(() {
              PermbarangayList = List<String>.from(barangays);
              if (widget.pagemode != "edit") {
                _selectedBarangay = null; // ✅ Reset again when new list loads
                perm_Barangay.text = '';
              }
            });
          } else {
            print("Barangays list not found or invalid");
          }
        }
      }
    } catch (e) {
      refressToken();
      print("API call failed: $e");
    }
  }

  Future<void> onEditZipCodeEntered(String zipCode) async {
    String tokens = "";
    setState(() {
      PermbarangayList = [];
      _selectedBarangay = null; // ✅ Reset selected value
    });

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('accessToken');

      // final tokenResponse = await http.get(
      //   Uri.parse('${AppConfig.dynamicBaseUrl}/api/leads/los-access-token/'),
      //   headers: {
      //     'Authorization': 'Bearer $token',
      //     'Accept': 'application/json',
      //     'Content-Type': 'multipart/form-data',
      //     'User-Agent':
      //         'Mozilla/5.0 (Linux; Android 11; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36',
      //   },
      // );

      String url = "/api/leads/los-access-token/";
      final headers = {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Content-Type': 'multipart/form-data',
        'User-Agent':
            'Mozilla/5.0 (Linux; Android 11; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36',
      };

      final tokenResponse = await ApiService.getWithHeaders(url, headers);

      final tokenData = tokenResponse!.data;
      tokens = tokenData['access_token'];
    } catch (e) {
      print("HTTP Request Failed: $e");
    }

    try {
      // final response = await http.post(
      //   Uri.parse('${AppConfig.otpUrl}/api/app/address'),
      //   headers: {
      //     'Authorization': 'Bearer $tokens',
      //     'Content-Type': 'application/json',
      //     'Idempotency-Key': 'sfsggdhsdgdgdg',
      //   },
      //   body: jsonEncode({"zipcode": "$zipCode"}),
      // );
      String url = "/api/app/address";
      final headers = {
        'Authorization': 'Bearer $tokens',
        'Content-Type': 'application/json',
        'Idempotency-Key': 'sfsggdhsdgdgdg',
        'User-Agent':
            'Mozilla/5.0 (Linux; Android 11; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36'
      };

      final body = {
        "zipcode": "$zipCode",
      };

      final response =
          await ApiService.postWithHeadersUnoApi(url, body, headers);

      if (response!.statusCode == 200) {
        final data = response.data;
        setState(() {
          perm_Region.text = data['region'];
          perm_State.text = data['province'];
          perm_City.text = data['cityMunicipality'];
        });

        final Map<String, dynamic> responseBody = response.data;

        if (responseBody['barangays'] is List &&
            responseBody['barangays'].isNotEmpty) {
          final barangays = responseBody['barangays'];

          if (barangays is List) {
            setState(() {
              PermbarangayList = List<String>.from(barangays);
              if (widget.pagemode != "edit") {
                _selectedBarangay = null; // ✅ Reset again when new list loads
                perm_Barangay.text = '';
              }
            });
          } else {
            print("Barangays list not found or invalid");
          }
        }
      }
    } catch (e) {
      refressToken();
      print("API call failed: $e");
    }
  }

  Future<void> onEmpZipCodeEntered(String zipCode) async {
    String tokens = "";
    setState(() {
      emp_Region.text = '';
      emp_State.text = '';
      emp_City.text = '';
      EmpbarangayList = [];
      emp_Barangay.text = '';
      _selectedEmpBarangay = null; // ✅ Reset selected value
    });

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('accessToken');

      // final tokenResponse = await http.get(
      //   Uri.parse('${AppConfig.dynamicBaseUrl}/api/leads/los-access-token/'),
      //   headers: {
      //     'Authorization': 'Bearer $token',
      //     'Accept': 'application/json',
      //     'Content-Type': 'multipart/form-data',
      //     'User-Agent':
      //         'Mozilla/5.0 (Linux; Android 11; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36',
      //   },
      // );

      String url = "/api/leads/los-access-token/";
      final headers = {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Content-Type': 'multipart/form-data',
        'User-Agent':
            'Mozilla/5.0 (Linux; Android 11; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36',
      };

      final tokenResponse = await ApiService.getWithHeaders(url, headers);

      final tokenData = tokenResponse!.data;
      tokens = tokenData['access_token'];
    } catch (e) {
      print("HTTP Request Failed: $e");
    }
    print("zip");
    try {
      // final response = await http.post(
      //   Uri.parse('${AppConfig.otpUrl}/api/app/address'),
      //   headers: {
      //     'Authorization': 'Bearer $tokens',
      //     'Content-Type': 'application/json',
      //     'Idempotency-Key': 'sfsggdhsdgdgdg',
      //     'User-Agent':
      //         'Mozilla/5.0 (Linux; Android 11; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36',
      //   },
      //   body: jsonEncode({"zipcode": "$zipCode"}),
      // );

      String url = "/api/app/address";
      final headers = {
        'Authorization': 'Bearer $tokens',
        'Content-Type': 'application/json',
        'Idempotency-Key': 'sfsggdhsdgdgdg',
        'User-Agent':
            'Mozilla/5.0 (Linux; Android 11; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36',
      };

      final body = {
        "zipcode": "$zipCode",
      };

      final response =
          await ApiService.postWithHeadersUnoApi(url, body, headers);

      if (response!.statusCode == 200) {
        final data = response.data;

        setState(() {
          emp_Region.text = data['region'];
          emp_State.text = data['province'];
          emp_City.text = data['cityMunicipality'];
        });

        final Map<String, dynamic> responseBody = response.data;

        if (responseBody['barangays'] is List &&
            responseBody['barangays'].isNotEmpty) {
          final barangays = responseBody['barangays'];

          if (barangays is List) {
            setState(() {
              EmpbarangayList = List<String>.from(barangays);
              if (widget.pagemode != "edit") {
                _selectedEmpBarangay =
                    null; // ✅ Reset again when new list loads
                emp_Barangay.text = '';
              }
            });
          } else {
            print("Barangays list not found or invalid");
          }
        }
      }
    } catch (e) {
      refressToken();
      print("API call failed: $e");
    }
  }

  Future<void> onEditEmpZipCodeEntered(String zipCode) async {
    String tokens = "";
    setState(() {
      EmpbarangayList = [];
      _selectedEmpBarangay = null; // ✅ Reset selected value
    });

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('accessToken');

      // final tokenResponse = await http.get(
      //   Uri.parse('${AppConfig.dynamicBaseUrl}/api/leads/los-access-token/'),
      //   headers: {
      //     'Authorization': 'Bearer $token',
      //     'Accept': 'application/json',
      //     'Content-Type': 'multipart/form-data',
      //     'User-Agent':
      //         'Mozilla/5.0 (Linux; Android 11; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36',
      //   },
      // );
      String url = "/api/leads/los-access-token/";
      final headers = {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Content-Type': 'multipart/form-data',
        'User-Agent':
            'Mozilla/5.0 (Linux; Android 11; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36',
      };

      final tokenResponse = await ApiService.getWithHeaders(url, headers);

      final tokenData = tokenResponse!.data;
      tokens = tokenData['access_token'];
    } catch (e) {
      print("HTTP Request Failed: $e");
    }

    try {
      // final response = await http.post(
      //   Uri.parse('${AppConfig.otpUrl}/api/app/address'),
      //   headers: {
      //     'Authorization': 'Bearer $tokens',
      //     'Content-Type': 'application/json',
      //     'Idempotency-Key': 'sfsggdhsdgdgdg',
      //   },
      //   body: jsonEncode({"zipcode": "$zipCode"}),
      // );

      String url = "/api/app/address";
      final headers = {
        'Authorization': 'Bearer $tokens',
        'Content-Type': 'application/json',
        'Idempotency-Key': 'sfsggdhsdgdgdg',
        'User-Agent':
            'Mozilla/5.0 (Linux; Android 11; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36'
      };

      final body = {
        "zipcode": "$zipCode",
      };

      final response =
          await ApiService.postWithHeadersUnoApi(url, body, headers);
      if (response!.statusCode == 200) {
        final data = response.data;

        setState(() {
          emp_Region.text = data['region'];
          emp_State.text = data['province'];
          emp_City.text = data['cityMunicipality'];
        });

        final Map<String, dynamic> responseBody = response.data;

        if (responseBody['barangays'] is List &&
            responseBody['barangays'].isNotEmpty) {
          final barangays = responseBody['barangays'];

          if (barangays is List) {
            setState(() {
              EmpbarangayList = List<String>.from(barangays);
              if (widget.pagemode != "edit") {
                _selectedEmpBarangay =
                    null; // ✅ Reset again when new list loads
                emp_Barangay.text = '';
              }
            });
          } else {
            print("Barangays list not found or invalid");
          }
        }
      }
    } catch (e) {
      refressToken();
      print("API call failed: $e");
    }
  }

  Future<void> _loadagent() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    userInfo = prefs.getStringList('userInfo');
    setState(() {
      agentCode.text = userInfo![0];
    });
  }

  Future<void> _initializeGenderList() async {
    try {
      String tokens = "";
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('accessToken');

      // final tokenResponse = await http.get(
      //   Uri.parse('${AppConfig.dynamicBaseUrl}/api/leads/los-access-token/'),
      //   headers: {
      //     'Authorization': 'Bearer $token',
      //     'Accept': 'application/json',
      //     'Content-Type': 'multipart/form-data',
      //     'User-Agent':
      //         'Mozilla/5.0 (Linux; Android 11; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36',
      //   },
      // );

      String url = "/api/leads/los-access-token/";
      final headers = {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Content-Type': 'multipart/form-data',
        'User-Agent':
            'Mozilla/5.0 (Linux; Android 11; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36',
      };

      final tokenResponse = await ApiService.getWithHeaders(url, headers);

      if (tokenResponse!.statusCode != 200) {
        throw Exception('Failed to fetch LOS access token');
      }

      final tokenData = tokenResponse.data;
      tokens = tokenData['access_token'];

      // final response = await http.post(
      //   Uri.parse('${AppConfig.otpUrl}/api/app/fetch/LOV/details'),
      //   headers: {
      //     'Authorization': 'Bearer $tokens',
      //     'Content-Type': 'application/json',
      //     'Idempotency-Key': 'sfsggdhsdgdgdg',
      //     'User-Agent':
      //         'Mozilla/5.0 (Linux; Android 11; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36',
      //   },
      //   body: jsonEncode({
      //     "filters": [
      //       {"id": "3"}
      //     ]
      //   }),
      // );

      String lovUrl = "/api/app/fetch/LOV/details";
      final header = {
        'Authorization': 'Bearer $tokens',
        'Content-Type': 'application/json',
        'Idempotency-Key': 'sfsggdhsdgdgdg',
        'User-Agent':
            'Mozilla/5.0 (Linux; Android 11; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36',
      };

      final body = {
        "filters": [
          {"id": "3"}
        ]
      };

      final response =
          await ApiService.postWithHeadersUnoApi(lovUrl, body, header);

      if (response!.statusCode == 200) {
        final Map<String, dynamic> responseBody = response.data;

        if (responseBody['data'] is List && responseBody['data'].isNotEmpty) {
          final firstItem = responseBody['data'][0];

          final lovsDetails = firstItem['lovs_details'];
          if (lovsDetails != null && lovsDetails['Gender'] is List) {
            setState(() {
              genderList = (lovsDetails['Gender'] as List)
                  .map<Map<String, dynamic>>(
                      (item) => Map<String, dynamic>.from(item))
                  .toList();
            });
          } else {
            print("lovs_details or Gender list not found");
          }
        } else {
          print("Response data is empty or invalid");
        }
      } else {
        throw Exception('Failed to load gender list');
      }
    } catch (e) {
      print("Error loading gender list: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load gender list')),
      );
    }
  }

  Future<void> _initializeNationalityList() async {
    String tokens = "";
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('accessToken');

      // final tokenResponse = await http.get(
      //   Uri.parse('${AppConfig.dynamicBaseUrl}/api/leads/los-access-token/'),
      //   headers: {
      //     'Authorization': 'Bearer $token',
      //     'Accept': 'application/json',
      //     'Content-Type': 'multipart/form-data',
      //     'User-Agent':
      //         'Mozilla/5.0 (Linux; Android 11; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36',
      //   },
      // );

      String url = "/api/leads/los-access-token/";
      final headers = {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Content-Type': 'multipart/form-data',
        'User-Agent':
            'Mozilla/5.0 (Linux; Android 11; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36',
      };

      final tokenResponse = await ApiService.getWithHeaders(url, headers);

      final tokenData = tokenResponse!.data;
      tokens = tokenData['access_token'];
    } catch (e) {
      print("HTTP Request Failed: $e");
    }
    // final response = await http.post(
    //   Uri.parse('${AppConfig.otpUrl}/api/app/fetch/LOV/details'),
    //   headers: {
    //     'Authorization': 'Bearer $tokens',
    //     'Content-Type': 'application/json',
    //     'Idempotency-Key': 'sfsggdhsdgdgdg',
    //     'User-Agent':
    //         'Mozilla/5.0 (Linux; Android 11; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36',
    //   },
    //   body: jsonEncode({
    //     "filters": [
    //       {"id": "20"}
    //     ]
    //   }),
    // );

    String lovUrl = "/api/app/fetch/LOV/details";
    final header = {
      'Authorization': 'Bearer $tokens',
      'Content-Type': 'application/json',
      'Idempotency-Key': 'sfsggdhsdgdgdg',
      'User-Agent':
          'Mozilla/5.0 (Linux; Android 11; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36',
    };

    final body = {
      "filters": [
        {"id": "20"}
      ]
    };

    final response =
        await ApiService.postWithHeadersUnoApi(lovUrl, body, header);

    try {
      if (response!.statusCode == 200) {
        final Map<String, dynamic> responseBody = response.data;

        if (responseBody['data'] is List && responseBody['data'].isNotEmpty) {
          final firstItem =
              responseBody['data'][0]; // The first map in the list

          final lovsDetails = firstItem['lovs_details'];
          if (lovsDetails != null && lovsDetails['NATIONALITY'] is List) {
            setState(() {
              nationalityList = (lovsDetails['NATIONALITY'] as List)
                  .map<Map<String, dynamic>>(
                      (item) => Map<String, dynamic>.from(item))
                  .toList();
            });
          } else {
            print("lovs_details or NATIONALITY list not found");
          }
        } else {
          print("Response status not Success or data is invalid");
        }
      } else {
        throw Exception('Failed to load NATIONALITY list');
      }
    } catch (e) {
      print("Error loading EMP NATIONALITY list: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load NATIONALITY list')),
      );
    }
  }

  Future<void> _initializeEmpWorkNatureList() async {
    String tokens = "";
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('accessToken');

      // final tokenResponse = await http.get(
      //   Uri.parse('${AppConfig.dynamicBaseUrl}/api/leads/los-access-token/'),
      //   headers: {
      //     'Authorization': 'Bearer $token',
      //     'Accept': 'application/json',
      //     'Content-Type': 'multipart/form-data',
      //     'User-Agent':
      //         'Mozilla/5.0 (Linux; Android 11; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36',
      //   },
      // );

      String url = "/api/leads/los-access-token/";
      final headers = {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Content-Type': 'multipart/form-data',
        'User-Agent':
            'Mozilla/5.0 (Linux; Android 11; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36',
      };

      final tokenResponse = await ApiService.getWithHeaders(url, headers);

      final tokenData = tokenResponse!.data;
      tokens = tokenData['access_token'];
    } catch (e) {
      print("HTTP Request Failed: $e");
    }
    try {
      // final response = await http.post(
      //   Uri.parse('${AppConfig.otpUrl}/api/app/fetch/LOV/details'),
      //   headers: {
      //     'Authorization': 'Bearer $tokens',
      //     'Content-Type': 'application/json',
      //     'Idempotency-Key': 'sfsggdhsdgdgdg',
      //     'User-Agent':
      //         'Mozilla/5.0 (Linux; Android 11; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36',
      //   },
      //   body: jsonEncode({
      //     "filters": [
      //       {"id": "9"}
      //     ]
      //   }),
      // );

      String lovUrl = "/api/app/fetch/LOV/details";
      final header = {
        'Authorization': 'Bearer $tokens',
        'Content-Type': 'application/json',
        'Idempotency-Key': 'sfsggdhsdgdgdg',
        'User-Agent':
            'Mozilla/5.0 (Linux; Android 11; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36',
      };

      final body = {
        "filters": [
          {"id": "9"}
        ]
      };

      final response =
          await ApiService.postWithHeadersUnoApi(lovUrl, body, header);

      if (response!.statusCode == 200) {
        final Map<String, dynamic> responseBody = response.data;

        if (responseBody['data'] is List && responseBody['data'].isNotEmpty) {
          final firstItem =
              responseBody['data'][0]; // The first map in the list

          final lovsDetails = firstItem['lovs_details'];
          if (lovsDetails != null && lovsDetails['NatureOfWork'] is List) {
            setState(() {
              empWorkNatureList = (lovsDetails['NatureOfWork'] as List)
                  .map<Map<String, dynamic>>(
                      (item) => Map<String, dynamic>.from(item))
                  .toList();
            });
          } else {
            print("lovs_details or EMP Work Nature list not found");
          }
        } else {
          print("Response status not Success or data is invalid");
        }
      } else {
        throw Exception('Failed to load EMP Work Nature list');
      }
    } catch (e) {
      print("Error loading EMP Work Nature list: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load EMP Work Nature list')),
      );
    }
  }

  Future<void> _initializeEmpStatusList() async {
    String tokens = "";
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('accessToken');

      // final tokenResponse = await http.get(
      //   Uri.parse('${AppConfig.dynamicBaseUrl}/api/leads/los-access-token/'),
      //   headers: {
      //     'Authorization': 'Bearer $token',
      //     'Accept': 'application/json',
      //     'Content-Type': 'multipart/form-data',
      //     'User-Agent':
      //         'Mozilla/5.0 (Linux; Android 11; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36',
      //   },
      // );

      String url = "/api/leads/los-access-token/";
      final headers = {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Content-Type': 'multipart/form-data',
        'User-Agent':
            'Mozilla/5.0 (Linux; Android 11; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36',
      };

      final tokenResponse = await ApiService.getWithHeaders(url, headers);

      final tokenData = tokenResponse!.data;
      tokens = tokenData['access_token'];
    } catch (e) {
      print("HTTP Request Failed: $e");
    }
    try {
      // final response = await http.post(
      //   Uri.parse('${AppConfig.otpUrl}/api/app/fetch/LOV/details'),
      //   headers: {
      //     'Authorization': 'Bearer $tokens',
      //     'Content-Type': 'application/json',
      //     'Idempotency-Key': 'sfsggdhsdgdgdg',
      //     'User-Agent':
      //         'Mozilla/5.0 (Linux; Android 11; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36',
      //   },
      //   body: jsonEncode({
      //     "filters": [
      //       {"id": "8"}
      //     ]
      //   }),
      // );

      String lovUrl = "/api/app/fetch/LOV/details";
      final header = {
        'Authorization': 'Bearer $tokens',
        'Content-Type': 'application/json',
        'Idempotency-Key': 'sfsggdhsdgdgdg',
        'User-Agent':
            'Mozilla/5.0 (Linux; Android 11; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36',
      };

      final body = {
        "filters": [
          {"id": "8"}
        ]
      };

      final response =
          await ApiService.postWithHeadersUnoApi(lovUrl, body, header);

      if (response!.statusCode == 200) {
        final Map<String, dynamic> responseBody = response.data;

        if (responseBody['data'] is List && responseBody['data'].isNotEmpty) {
          final firstItem =
              responseBody['data'][0]; // The first map in the list

          final lovsDetails = firstItem['lovs_details'];
          if (lovsDetails != null && lovsDetails['EmploymentStatus'] is List) {
            setState(() {
              empStatusList = (lovsDetails['EmploymentStatus'] as List)
                  .map<Map<String, dynamic>>(
                      (item) => Map<String, dynamic>.from(item))
                  .toList();
            });
          } else {
            print("lovs_details or EMP Status list not found");
          }
        } else {
          print("Response status not Success or data is invalid");
        }
      } else {
        throw Exception('Failed to load EMP Status list');
      }
    } catch (e) {
      print("Error loading EMP Status list: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load EMP Status list')),
      );
    }
  }

  Future<void> _initializeEmpTypeList() async {
    String tokens = "";
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('accessToken');

      // final tokenResponse = await http.get(
      //   Uri.parse('${AppConfig.dynamicBaseUrl}/api/leads/los-access-token/'),
      //   headers: {
      //     'Authorization': 'Bearer $token',
      //     'Accept': 'application/json',
      //     'Content-Type': 'multipart/form-data',
      //     'User-Agent':
      //         'Mozilla/5.0 (Linux; Android 11; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36',
      //   },
      // );

      String url = "/api/leads/los-access-token/";
      final headers = {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Content-Type': 'multipart/form-data',
        'User-Agent':
            'Mozilla/5.0 (Linux; Android 11; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36',
      };

      final tokenResponse = await ApiService.getWithHeaders(url, headers);

      final tokenData = tokenResponse!.data;
      tokens = tokenData['access_token'];
    } catch (e) {
      print("HTTP Request Failed: $e");
    }
    try {
      // final response = await http.post(
      //   Uri.parse('${AppConfig.otpUrl}/api/app/fetch/LOV/details'),
      //   headers: {
      //     'Authorization': 'Bearer $tokens',
      //     'Content-Type': 'application/json',
      //     'Idempotency-Key': 'sfsggdhsdgdgdg',
      //     'User-Agent':
      //         'Mozilla/5.0 (Linux; Android 11; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36',
      //   },
      //   body: jsonEncode({
      //     "filters": [
      //       {"id": "1"}
      //     ]
      //   }),
      // );

      String lovUrl = "/api/app/fetch/LOV/details";
      final header = {
        'Authorization': 'Bearer $tokens',
        'Content-Type': 'application/json',
        'Idempotency-Key': 'sfsggdhsdgdgdg',
        'User-Agent':
            'Mozilla/5.0 (Linux; Android 11; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36',
      };

      final body = {
        "filters": [
          {"id": "1"}
        ]
      };

      final response =
          await ApiService.postWithHeadersUnoApi(lovUrl, body, header);

      if (response!.statusCode == 200) {
        final Map<String, dynamic> responseBody = response.data;

        if (responseBody['data'] is List && responseBody['data'].isNotEmpty) {
          final firstItem =
              responseBody['data'][0]; // The first map in the list

          final lovsDetails = firstItem['lovs_details'];
          if (lovsDetails != null && lovsDetails['Occupation'] is List) {
            setState(() {
              empList = (lovsDetails['Occupation'] as List)
                  .map<Map<String, dynamic>>(
                      (item) => Map<String, dynamic>.from(item))
                  .toList();
            });
          } else {
            print("lovs_details or EMP Type list not found");
          }
        } else {
          print("Response status not Success or data is invalid");
        }
      } else {
        throw Exception('Failed to load EMP Type list');
      }
    } catch (e) {
      print("Error loading EMP Type list: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load EMP Type list')),
      );
    }
  }

  Future<void> _initializeIndustryTypeList() async {
    String tokens = "";
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('accessToken');

      // final tokenResponse = await http.get(
      //   Uri.parse('${AppConfig.dynamicBaseUrl}/api/leads/los-access-token/'),
      //   headers: {
      //     'Authorization': 'Bearer $token',
      //     'Accept': 'application/json',
      //     'Content-Type': 'multipart/form-data',
      //     'User-Agent':
      //         'Mozilla/5.0 (Linux; Android 11; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36',
      //   },
      // );

      String url = "/api/leads/los-access-token/";
      final headers = {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Content-Type': 'multipart/form-data',
        'User-Agent':
            'Mozilla/5.0 (Linux; Android 11; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36',
      };

      final tokenResponse = await ApiService.getWithHeaders(url, headers);

      final tokenData = tokenResponse!.data;
      tokens = tokenData['access_token'];
    } catch (e) {
      print("HTTP Request Failed: $e");
    }
    try {
      // final response = await http.post(
      //   Uri.parse('${AppConfig.otpUrl}/api/app/fetch/LOV/details'),
      //   headers: {
      //     'Authorization': 'Bearer $tokens',
      //     'Content-Type': 'application/json',
      //     'Idempotency-Key': 'sfsggdhsdgdgdg',
      //     'User-Agent':
      //         'Mozilla/5.0 (Linux; Android 11; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36',
      //   },
      //   body: jsonEncode({
      //     "filters": [
      //       {"id": "22"}
      //     ]
      //   }),
      // );

      String lovUrl = "/api/app/fetch/LOV/details";
      final header = {
        'Authorization': 'Bearer $tokens',
        'Content-Type': 'application/json',
        'Idempotency-Key': 'sfsggdhsdgdgdg',
        'User-Agent':
            'Mozilla/5.0 (Linux; Android 11; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36',
      };

      final body = {
        "filters": [
          {"id": "22"}
        ]
      };

      final response =
          await ApiService.postWithHeadersUnoApi(lovUrl, body, header);

      if (response!.statusCode == 200) {
        final Map<String, dynamic> responseBody = response.data;

        if (responseBody['data'] is List && responseBody['data'].isNotEmpty) {
          final firstItem =
              responseBody['data'][0]; // The first map in the list

          final lovsDetails = firstItem['lovs_details'];
          if (lovsDetails != null && lovsDetails['IndustryType'] is List) {
            setState(() {
              industryList = (lovsDetails['IndustryType'] as List)
                  .map<Map<String, dynamic>>(
                      (item) => Map<String, dynamic>.from(item))
                  .toList();
            });
          } else {
            print("lovs_details or Industry Type list not found");
          }
        } else {
          print("Response status not Success or data is invalid");
        }
      } else {
        throw Exception('Failed to load Industry Type list');
      }
    } catch (e) {
      print("Error loading EMP Type list: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load Industry Type list')),
      );
    }
  }

  Future<void> _initializeWorkExprienceList() async {
    String tokens = "";
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('accessToken');

      // final tokenResponse = await http.get(
      //   Uri.parse('${AppConfig.dynamicBaseUrl}/api/leads/los-access-token/'),
      //   headers: {
      //     'Authorization': 'Bearer $token',
      //     'Accept': 'application/json',
      //     'Content-Type': 'multipart/form-data',
      //     'User-Agent':
      //         'Mozilla/5.0 (Linux; Android 11; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36',
      //   },
      // );

      String url = "/api/leads/los-access-token/";
      final headers = {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Content-Type': 'multipart/form-data',
        'User-Agent':
            'Mozilla/5.0 (Linux; Android 11; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36',
      };

      final tokenResponse = await ApiService.getWithHeaders(url, headers);

      final tokenData = tokenResponse!.data;
      tokens = tokenData['access_token'];
    } catch (e) {
      print("HTTP Request Failed: $e");
    }
    try {
      // final response = await http.post(
      //   Uri.parse('${AppConfig.otpUrl}/api/app/fetch/LOV/details'),
      //   headers: {
      //     'Authorization': 'Bearer $tokens',
      //     'Content-Type': 'application/json',
      //     'Idempotency-Key': 'sfsggdhsdgdgdg',
      //     'User-Agent':
      //         'Mozilla/5.0 (Linux; Android 11; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36',
      //   },
      //   body: jsonEncode({
      //     "filters": [
      //       {"id": "11"}
      //     ]
      //   }),
      // );

      String lovUrl = "/api/app/fetch/LOV/details";
      final header = {
        'Authorization': 'Bearer $tokens',
        'Content-Type': 'application/json',
        'Idempotency-Key': 'sfsggdhsdgdgdg',
        'User-Agent':
            'Mozilla/5.0 (Linux; Android 11; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36',
      };

      final body = {
        "filters": [
          {"id": "11"}
        ]
      };

      final response =
          await ApiService.postWithHeadersUnoApi(lovUrl, body, header);

      if (response!.statusCode == 200) {
        final Map<String, dynamic> responseBody = response.data;

        if (responseBody['data'] is List && responseBody['data'].isNotEmpty) {
          final firstItem =
              responseBody['data'][0]; // The first map in the list

          final lovsDetails = firstItem['lovs_details'];
          if (lovsDetails != null && lovsDetails['Tenure'] is List) {
            setState(() {
              workExperience = (lovsDetails['Tenure'] as List)
                  .map<Map<String, dynamic>>(
                      (item) => Map<String, dynamic>.from(item))
                  .toList();
            });
          } else {
            print("lovs_details or Work Exprience list not found");
          }
        } else {
          print("Response status not Success or data is invalid");
        }
      } else {
        throw Exception('Failed to load Work Exprience list');
      }
    } catch (e) {
      print("Error loading Work Exprience list: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load Work Exprience list')),
      );
    }
  }

  Future<void> _initializeEmpprofessionList() async {
    String tokens = "";
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('accessToken');

      // final tokenResponse = await http.get(
      //   Uri.parse('${AppConfig.dynamicBaseUrl}/api/leads/los-access-token/'),
      //   headers: {
      //     'Authorization': 'Bearer $token',
      //     'Accept': 'application/json',
      //     'Content-Type': 'multipart/form-data',
      //     'User-Agent':
      //         'Mozilla/5.0 (Linux; Android 11; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36',
      //   },
      // );

      String url = "/api/leads/los-access-token/";
      final headers = {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Content-Type': 'multipart/form-data',
        'User-Agent':
            'Mozilla/5.0 (Linux; Android 11; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36',
      };

      final tokenResponse = await ApiService.getWithHeaders(url, headers);

      final tokenData = tokenResponse!.data;
      tokens = tokenData['access_token'];
    } catch (e) {
      print("HTTP Request Failed: $e");
    }
    try {
      // final response = await http.post(
      //   Uri.parse('${AppConfig.otpUrl}/api/app/fetch/LOV/details'),
      //   headers: {
      //     'Authorization': 'Bearer $tokens',
      //     'Content-Type': 'application/json',
      //     'Idempotency-Key': 'sfsggdhsdgdgdg',
      //     'User-Agent':
      //         'Mozilla/5.0 (Linux; Android 11; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36',
      //   },
      //   body: jsonEncode({
      //     "filters": [
      //       {"id": "18"}
      //     ]
      //   }),
      // );

      String lovUrl = "/api/app/fetch/LOV/details";
      final header = {
        'Authorization': 'Bearer $tokens',
        'Content-Type': 'application/json',
        'Idempotency-Key': 'sfsggdhsdgdgdg',
        'User-Agent':
            'Mozilla/5.0 (Linux; Android 11; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36',
      };

      final body = {
        "filters": [
          {"id": "18"}
        ]
      };

      final response =
          await ApiService.postWithHeadersUnoApi(lovUrl, body, header);

      if (response!.statusCode == 200) {
        final Map<String, dynamic> responseBody = response.data;

        if (responseBody['data'] is List && responseBody['data'].isNotEmpty) {
          final firstItem =
              responseBody['data'][0]; // The first map in the list

          final lovsDetails = firstItem['lovs_details'];
          if (lovsDetails != null && lovsDetails['Profession'] is List) {
            setState(() {
              empProfessionList = (lovsDetails['Profession'] as List)
                  .map<Map<String, dynamic>>(
                      (item) => Map<String, dynamic>.from(item))
                  .toList();
            });
          } else {
            print("lovs_details or EMP Profession list not found");
          }
        } else {
          print("Response status not Success or data is invalid");
        }
      } else {
        throw Exception('Failed to load EMP Profession list');
      }
    } catch (e) {
      print("Error loading EMP Profession list: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load EMP Profession list')),
      );
    }
  }

  Future<void> _initializeEmpPositionList() async {
    String tokens = "";
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('accessToken');

      // final tokenResponse = await http.get(
      //   Uri.parse('${AppConfig.dynamicBaseUrl}/api/leads/los-access-token/'),
      //   headers: {
      //     'Authorization': 'Bearer $token',
      //     'Accept': 'application/json',
      //     'Content-Type': 'multipart/form-data',
      //     'User-Agent':
      //         'Mozilla/5.0 (Linux; Android 11; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36',
      //   },
      // );

      String url = "/api/leads/los-access-token/";
      final headers = {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Content-Type': 'multipart/form-data',
        'User-Agent':
            'Mozilla/5.0 (Linux; Android 11; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36',
      };

      final tokenResponse = await ApiService.getWithHeaders(url, headers);

      final tokenData = tokenResponse!.data;
      tokens = tokenData['access_token'];
    } catch (e) {
      print("HTTP Request Failed: $e");
    }
    try {
      // final response = await http.post(
      //   Uri.parse('${AppConfig.otpUrl}/api/app/fetch/LOV/details'),
      //   headers: {
      //     'Authorization': 'Bearer $tokens',
      //     'Content-Type': 'application/json',
      //     'Idempotency-Key': 'sfsggdhsdgdgdg',
      //     'User-Agent':
      //         'Mozilla/5.0 (Linux; Android 11; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36',
      //   },
      //   body: jsonEncode({
      //     "filters": [
      //       {"id": "15"}
      //     ]
      //   }),
      // );

      String lovUrl = "/api/app/fetch/LOV/details";
      final header = {
        'Authorization': 'Bearer $tokens',
        'Content-Type': 'application/json',
        'Idempotency-Key': 'sfsggdhsdgdgdg',
        'User-Agent':
            'Mozilla/5.0 (Linux; Android 11; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36',
      };

      final body = {
        "filters": [
          {"id": "15"}
        ]
      };

      final response =
          await ApiService.postWithHeadersUnoApi(lovUrl, body, header);

      if (response!.statusCode == 200) {
        final Map<String, dynamic> responseBody = response.data;

        if (responseBody['data'] is List && responseBody['data'].isNotEmpty) {
          final firstItem =
              responseBody['data'][0]; // The first map in the list

          final lovsDetails = firstItem['lovs_details'];
          if (lovsDetails != null && lovsDetails['Position'] is List) {
            setState(() {
              position = (lovsDetails['Position'] as List)
                  .map<Map<String, dynamic>>(
                      (item) => Map<String, dynamic>.from(item))
                  .toList();
            });
          } else {
            print("lovs_details or EMP Position list not found");
          }
        } else {
          print("Response status not Success or data is invalid");
        }
      } else {
        throw Exception('Failed to load EMP Position list');
      }
    } catch (e) {
      print("Error loading EMP Position list: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load EMP Position list')),
      );
    }
  }

  Future<void> _initializeCivilList() async {
    String tokens = "";
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('accessToken');

      // final tokenResponse = await http.get(
      //   Uri.parse('${AppConfig.dynamicBaseUrl}/api/leads/los-access-token/'),
      //   headers: {
      //     'Authorization': 'Bearer $token',
      //     'Accept': 'application/json',
      //     'Content-Type': 'multipart/form-data',
      //     'User-Agent':
      //         'Mozilla/5.0 (Linux; Android 11; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36',
      //   },
      // );
      String url = "/api/leads/los-access-token/";
      final headers = {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Content-Type': 'multipart/form-data',
        'User-Agent':
            'Mozilla/5.0 (Linux; Android 11; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36',
      };

      final tokenResponse = await ApiService.getWithHeaders(url, headers);

      final tokenData = tokenResponse!.data;
      tokens = tokenData['access_token'];
    } catch (e) {
      print("HTTP Request Failed: $e");
    }
    try {
      // final response = await http.post(
      //   Uri.parse('${AppConfig.otpUrl}/api/app/fetch/LOV/details'),
      //   headers: {
      //     'Authorization': 'Bearer $tokens',
      //     'Content-Type': 'application/json',
      //     'Idempotency-Key': 'sfsggdhsdgdgdg',
      //     'User-Agent':
      //         'Mozilla/5.0 (Linux; Android 11; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36',
      //   },
      //   body: jsonEncode({
      //     "filters": [
      //       {"id": "4"}
      //     ]
      //   }),
      // );

      String lovUrl = "/api/app/fetch/LOV/details";
      final header = {
        'Authorization': 'Bearer $tokens',
        'Content-Type': 'application/json',
        'Idempotency-Key': 'sfsggdhsdgdgdg',
        'User-Agent':
            'Mozilla/5.0 (Linux; Android 11; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36',
      };

      final body = {
        "filters": [
          {"id": "4"}
        ]
      };

      final response =
          await ApiService.postWithHeadersUnoApi(lovUrl, body, header);

      if (response!.statusCode == 200) {
        final Map<String, dynamic> responseBody = response.data;

        if (responseBody['data'] is List && responseBody['data'].isNotEmpty) {
          final firstItem =
              responseBody['data'][0]; // The first map in the list

          final lovsDetails = firstItem['lovs_details'];
          if (lovsDetails != null && lovsDetails['CivilStatus'] is List) {
            setState(() {
              civilStatusList = (lovsDetails['CivilStatus'] as List)
                  .map<Map<String, dynamic>>(
                      (item) => Map<String, dynamic>.from(item))
                  .toList();
            });
          } else {
            print("lovs_details or Civil Status list not found");
          }
        } else {
          print("Response status not Success or data is invalid");
        }
      } else {
        throw Exception('Failed to load Civil Status list');
      }
    } catch (e) {
      print("Error loading Civil Status list: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load Civil Status list')),
      );
    }
  }

  Future<void> _initializeSourceFundList() async {
    String tokens = "";
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('accessToken');

      // final tokenResponse = await http.get(
      //   Uri.parse('${AppConfig.dynamicBaseUrl}/api/leads/los-access-token/'),
      //   headers: {
      //     'Authorization': 'Bearer $token',
      //     'Accept': 'application/json',
      //     'Content-Type': 'multipart/form-data',
      //     'User-Agent':
      //         'Mozilla/5.0 (Linux; Android 11; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36',
      //   },
      // );
      String url = "/api/leads/los-access-token/";
      final headers = {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Content-Type': 'multipart/form-data',
        'User-Agent':
            'Mozilla/5.0 (Linux; Android 11; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36',
      };

      final tokenResponse = await ApiService.getWithHeaders(url, headers);

      final tokenData = tokenResponse!.data;
      tokens = tokenData['access_token'];
    } catch (e) {
      print("HTTP Request Failed: $e");
    }
    try {
      // final response = await http.post(
      //   Uri.parse('${AppConfig.otpUrl}/api/lov/mapping/sequence'),
      //   headers: {
      //     'Authorization': 'Bearer $tokens',
      //     'Content-Type': 'application/json',
      //     'Idempotency-Key': 'sfsggdhsdgdgdg',
      //     'User-Agent':
      //         'Mozilla/5.0 (Linux; Android 11; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36',
      //   },
      //   body: jsonEncode({
      //     "category": "Source_of_Fund",
      //     "empStatusId": emp_Status_Code.text.replaceFirst(RegExp(r'^0+'), ''),
      //     "nowId": emp_Work_Nature_Code.text.replaceFirst(RegExp(r'^0+'), ''),
      //     "positionId": emp_position.text.replaceFirst(RegExp(r'^0+'), ''),
      //   }),
      // );

      String lovMapUrl = "/api/lov/mapping/sequence";
      final header = {
        'Authorization': 'Bearer $tokens',
        'Content-Type': 'application/json',
        'Idempotency-Key': 'sfsggdhsdgdgdg',
        'User-Agent':
            'Mozilla/5.0 (Linux; Android 11; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36',
      };

      final body = {
        "category": "Source_of_Fund",
        "empStatusId": emp_Status_Code.text.replaceFirst(RegExp(r'^0+'), ''),
        "nowId": emp_Work_Nature_Code.text.replaceFirst(RegExp(r'^0+'), ''),
        "positionId": emp_position.text.replaceFirst(RegExp(r'^0+'), ''),
      };

      final response =
          await ApiService.postWithHeadersUnoApi(lovMapUrl, body, header);

      if (response!.statusCode == 200) {
        final Map<String, dynamic> responseBody = response.data;

        if (responseBody['data'] is List && responseBody['data'].isNotEmpty) {
          final dataList = responseBody['data'];

          setState(() {
            sourceofFundList = dataList
                .map<Map<String, dynamic>>(
                    (item) => {"key": item['key'], "value": item['value']})
                .toList();
          });
        } else {
          print("Data is not a valid list or is empty.");
        }
      } else {
        throw Exception('Failed to load Source Of Fund list');
      }
    } catch (e) {
      print("Error loading Source Of Fund list: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load Source Of Fund list')),
      );
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
                if (widget.pagemode == 'edit') {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) => LeadListByCampaign(
                              campaign: widget.campaign,
                            )),
                  );
                } else {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) => FsaLeadDashBoard(
                              searchQuery: '',
                            )),
                  );
                }
              },
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          Container(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Please Review If All Information Is Correct"
                          .toUpperCase(),
                      style: WidgetSupport.label(),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                Container(
                  decoration: BoxDecoration(
                    color: Color(0xFF640D78),
                    borderRadius: BorderRadius.circular(3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 6,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Theme(
                    data: Theme.of(context)
                        .copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      initiallyExpanded: true,
                      trailing: Icon(Icons.keyboard_arrow_down,
                          color: Colors.white, size: 30),
                      title: Text("Client Details",
                          style: WidgetSupport.normalTextTab()),
                      children: [
                        Container(
                          color: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16.0, vertical: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildTextField(firstName, "First Name",
                                  "Please Enter First Name", "firstName",
                                  isRequired: true),
                              SizedBox(height: 6),
                              _buildTextField(middlename, "Middle name",
                                  "Please Enter Middle Name", "middlename",
                                  isRequired: false),
                              SizedBox(height: 6),
                              _buildTextField(lastName, "Last Name",
                                  "Please Enter Last Name", "lastName",
                                  isRequired: true),
                              SizedBox(height: 6),
                              _buildMobileTextField(
                                controller: mobilePhone,
                                isPhoneNumber: true,
                              ),
                              SizedBox(height: 6),
                              _buildDateField(
                                controller: birthDate,
                                label: "Birth Date",
                              ),
                              SizedBox(height: 6),
                              _buildGenderDropdown(
                                  controller: gender,
                                  label: "   Select Gender"),
                              SizedBox(height: 6),
                              _buildTextField(email, "Email Address",
                                  "Please Enter Email Address", "email",
                                  isRequired: true),
                              SizedBox(height: 6),
                              _buildCivilStatusDropdown(
                                controller: civil_Status,
                                label: "   Select Civil Status",
                              ),
                              SizedBox(height: 6),
                              _buildNationalityDropdown(
                                controller: nationality,
                                label: "   Select Nationality",
                              ),
                              SizedBox(height: 6),
                              _buildTextField(
                                  place_Of_Birth,
                                  "Place Of Birth",
                                  "Please Enter Place Of Birth",
                                  "place_Of_Birth",
                                  isRequired: true),
                              SizedBox(height: 20),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 15),
                Container(
                  decoration: BoxDecoration(
                    color: Color(0xFF640D78),
                    borderRadius: BorderRadius.circular(3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 6,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Theme(
                    data: Theme.of(context)
                        .copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      initiallyExpanded: true,
                      trailing: Icon(Icons.keyboard_arrow_down,
                          color: Colors.white, size: 30),
                      title: Text("Current Residential Address",
                          style: WidgetSupport.normalTextTab()),
                      children: [
                        Container(
                          color: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16.0, vertical: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildZipTextField(
                                perm_ZipCode,
                                "   Zip Code",
                                "Please Enter Zip Code",
                                "perm_ZipCode",
                                isRequired: true,
                                isZip: true,
                                onChanged: (value) async {
                                  if (value.length == 4) {
                                    onZipCodeEntered(value);
                                  }
                                },
                              ),
                              SizedBox(height: 6),
                              _buildTextField(perm_Region, "Region",
                                  "Please Enter Region", "perm_Region",
                                  isRequired: true, readOnly: true),
                              SizedBox(height: 6),
                              _buildTextField(
                                perm_State,
                                "Province",
                                "Please Enter Province",
                                "perm_State",
                                isRequired: true,
                                readOnly: true,
                              ),
                              SizedBox(height: 6),
                              _buildTextField(
                                perm_City,
                                "City",
                                "Please Enter City",
                                "perm_City",
                                isRequired: true,
                                readOnly: true,
                              ),
                              SizedBox(height: 6),
                              _buildPermBarangayDropdown(
                                controller: perm_Barangay,
                                label: "   Select Barangay",
                              ),
                              SizedBox(
                                height: 6,
                              ),
                              _buildTextField(
                                perm_Street,
                                "House no. & Street",
                                "Please Enter House no. & Street",
                                "perm_Street",
                                isRequired: true,
                                readOnly: false,
                              ),
                              SizedBox(height: 20),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 15),
                Container(
                  decoration: BoxDecoration(
                    color: Color(0xFF640D78),
                    borderRadius: BorderRadius.circular(3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 6,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Theme(
                    data: Theme.of(context)
                        .copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      initiallyExpanded: true,
                      trailing: Icon(Icons.keyboard_arrow_down,
                          color: Colors.white, size: 30),
                      title: Text("Employee Details",
                          style: WidgetSupport.normalTextTab()),
                      children: [
                        Container(
                          color: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16.0, vertical: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildEmpStatusDropdown(
                                controller: emp_Status,
                                label: "   Select Status",
                              ),
                              SizedBox(height: 6),
                              _buildEmpWorkNatureDropdown(
                                controller: emp_Work_Nature,
                                label: "   Select Emp Work Nature",
                              ),
                              SizedBox(height: 6),
                              _buildPositionDropdown(
                                controller: emp_position,
                                label: "   Select Emp Position",
                              ),
                              SizedBox(height: 6),
                              _buildWorkExpDropdown(
                                controller: emp_Mths_In_Cur_Comp,
                                label: "   Work Experience",
                              ),
                              SizedBox(height: 6),
                              if (EmpStatus == true)
                                _buildEmpPrefessionDropdown(
                                  controller: profession,
                                  label: "   Select Emp Profession",
                                ),
                              SizedBox(height: 6),
                              _buildTextField(
                                emp_Employer_Name,
                                "Employers Name",
                                "Please Enter Employers Name",
                                "emp_Employer_Name",
                                isRequired: true,
                              ),
                              SizedBox(height: 6),
                              _buildEmpIndusTypeDropdown(
                                controller: emp_Indus_Type,
                                label: "   Industry Type",
                              ),
                              SizedBox(height: 6),
                              _buildEmpTypeDropdown(
                                controller: emp_Type,
                                label: "   Employee Type",
                              ),
                              SizedBox(height: 6),
                              _buildTextField(
                                emp_email,
                                "Employee Email Address",
                                "Please Enter Email Address",
                                "emp_email",
                                isEmail: true,
                              ),
                              SizedBox(height: 20),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 15),
                Container(
                  decoration: BoxDecoration(
                    color: Color(0xFF640D78),
                    borderRadius: BorderRadius.circular(3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 6,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Theme(
                    data: Theme.of(context)
                        .copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      initiallyExpanded: true,
                      trailing: Icon(Icons.keyboard_arrow_down,
                          color: Colors.white, size: 30),
                      title: Text("Financial Details",
                          style: WidgetSupport.normalTextTab()),
                      children: [
                        Container(
                          color: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16.0, vertical: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildTextField(
                                  fin_Mthly_Income,
                                  "Montly Income",
                                  "Please Enter Montly Income",
                                  "fin_Mthly_Income",
                                  isRequired: true),
                              SizedBox(height: 6),
                              _buildSourceFundDropdown(
                                controller: fin_Src_Of_Funds,
                                label: "   Select Source Of Funds",
                              ),
                              SizedBox(height: 20),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 15),
                Container(
                  decoration: BoxDecoration(
                    color: Color(0xFF640D78),
                    borderRadius: BorderRadius.circular(3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 6,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Theme(
                    data: Theme.of(context)
                        .copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      initiallyExpanded: true,
                      trailing: Icon(Icons.keyboard_arrow_down,
                          color: Colors.white, size: 30),
                      title: Text("Identification Details",
                          style: WidgetSupport.normalTextTab()),
                      children: [
                        Container(
                          color: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16.0, vertical: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: _buildRadioField<IdType>(
                                      value: IdType.tin,
                                      groupValue: _selectedIdType,
                                      onChanged: (val) =>
                                          setState(() => _selectedIdType = val),
                                      label: "TIN ID",
                                      isRequired: false,
                                    ),
                                  ),
                                  Expanded(
                                    child: _buildRadioField<IdType>(
                                      value: IdType.sss,
                                      groupValue: _selectedIdType,
                                      onChanged: (val) =>
                                          setState(() => _selectedIdType = val),
                                      label: "SSS ID",
                                    ),
                                  ),
                                  Expanded(
                                    child: _buildRadioField<IdType>(
                                      value: IdType.gsis,
                                      groupValue: _selectedIdType,
                                      onChanged: (val) =>
                                          setState(() => _selectedIdType = val),
                                      label: "GSIS ID",
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 6),
                              if (_selectedIdType == IdType.tin)
                                _buildTextField2(
                                    identity_TinId, "TIN Id", "identity_TinId",
                                    isRequired: false),
                              if (_selectedIdType == IdType.sss)
                                _buildTextField2(
                                    identity_SssID, "SSS ID", "identity_SssID",
                                    isRequired: false),
                              if (_selectedIdType == IdType.gsis)
                                _buildTextField2(identity_GsisID, "GSIS ID",
                                    "identity_GsisID",
                                    isRequired: false),
                              SizedBox(height: 20),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 15),
                Container(
                  decoration: BoxDecoration(
                    color: Color(0xFF640D78),
                    borderRadius: BorderRadius.circular(3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 6,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Theme(
                    data: Theme.of(context)
                        .copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      initiallyExpanded: true,
                      trailing: Icon(Icons.keyboard_arrow_down,
                          color: Colors.white, size: 30),
                      title: Text("Employee Address",
                          style: WidgetSupport.normalTextTab()),
                      children: [
                        Container(
                          color: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16.0, vertical: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildZipTextField(
                                emp_ZipCode,
                                "Zip Code",
                                "Please Enter Zip Code",
                                "emp_ZipCode",
                                isRequired: true,
                                isZip: true,
                                onChanged: (value) async {
                                  if (value.length == 4) {
                                    onEmpZipCodeEntered(value);
                                  }
                                },
                              ),
                              SizedBox(height: 6),
                              _buildTextField(
                                emp_Region,
                                "Region",
                                "Please Enter Region",
                                "emp_Region",
                                isRequired: true,
                                readOnly: true,
                              ),
                              SizedBox(height: 6),
                              _buildTextField(
                                emp_State,
                                "Province",
                                "Please Enter Province",
                                "perm_State",
                                isRequired: true,
                                readOnly: true,
                              ),
                              SizedBox(height: 6),
                              _buildTextField(
                                emp_City,
                                "City",
                                "Please Enter City",
                                "emp_City",
                                isRequired: true,
                                readOnly: true,
                              ),
                              SizedBox(height: 6),
                              _buildEmpBarangayDropdown(
                                controller: emp_Barangay,
                                label: "   Select Barangay",
                              ),
                              SizedBox(height: 6),
                              _buildTextField(
                                  emp_Street,
                                  "Building No./Street",
                                  "Please Enter Building No./Street",
                                  "emp_Street",
                                  isRequired: true),
                              SizedBox(height: 20),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 20),
                Container(
                  margin: EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Checkbox(
                        value: _isChecked,
                        onChanged: (value) {
                          setState(() {
                            _isChecked = value ?? false;
                            disclaimerCheck.text = "true";
                          });
                        },
                      ),
                      Expanded(
                        child: Text(
                          "I (The Customer) authorize UNO Digital Bank to debit Php100 from my savings as payment for loan application fee. "
                          "I further agree that this will be refunded to me should my loan be approved and disbursed.",
                          style: TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 50),
                ElevatedButton.icon(
                  // onPressed: () {

                  //   validateAndSubmit();
                  // },
                  onPressed: _isChecked ? validateAndSubmit : null,
                  icon: Icon(Icons.rocket_launch,
                      color: const Color.fromARGB(255, 34, 29, 29)),
                  label: Text(
                    "SUBMIT",
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF6e0386),
                    padding: EdgeInsets.symmetric(horizontal: 70, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(5), // Removes rounded corners
                    ),
                  ),
                ),
                SizedBox(height: 350),
              ],
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }

  bool _isValidStreet(String text) {
    final trimmed = text.trim();
    final wordCount =
        trimmed.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
    return trimmed.length >= 10 && wordCount >= 3;
  }

  bool _isValidIdtin(String text) {
    final trimmed = text.trim();
    final length = trimmed.length;
    final isDigitsOnly = RegExp(r'^\d+$').hasMatch(trimmed);
    return isDigitsOnly && length >= 9 && length <= 9;
  }

  bool _isValidIdsssid(String text) {
    final trimmed = text.trim();
    final length = trimmed.length;
    final isDigitsOnly = RegExp(r'^\d+$').hasMatch(trimmed);
    return isDigitsOnly && length >= 10 && length <= 10;
  }

  bool _isValidIdGsisId(String text) {
    final trimmed = text.trim();
    final length = trimmed.length;
    final isDigitsOnly = RegExp(r'^\d+$').hasMatch(trimmed);
    return isDigitsOnly && length >= 11 && length <= 11;
  }

  bool _isValidName(String name) {
    return RegExp(r"^[a-zA-Z\s]+$").hasMatch(name.trim());
  }

  bool _isValidIncome(String income) {
    final incomeValue = double.tryParse(income.replaceAll(',', ''));
    return incomeValue != null && incomeValue > 0;
  }

  bool _isValidEmail(String email) {
    final RegExp emailRegex = RegExp(
      r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$",
    );
    return emailRegex.hasMatch(email);
  }

  void _showValidationDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Validation Error"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  void validateAndSubmit() {
    // Basic required fields (client details)
    final nameRegex = RegExp(r"^[a-zA-Z\s]+$");
    final specialCharRegex =
        RegExp(r'''[!@#\$%\^&\*\(\)_\+\=\{\}\[\]:;"'<>,\.\?/\\|~`-]''');

    if (firstName.text.trim().isEmpty) {
      _showValidationDialog("Please enter First Name.");
      return;
    } else if (!nameRegex.hasMatch(firstName.text.trim())) {
      _showValidationDialog("First Name must not contain special characters.");
      return;
    }
    // Define a regex to detect special characters
    String middleName = middlename.text.trim();
// Check if middle name is not empty and contains any special characters
    if (middleName.isNotEmpty && specialCharRegex.hasMatch(middleName)) {
      _showValidationDialog("Middle Name must not contain special characters.");
      return;
    }
    if (lastName.text.trim().isEmpty) {
      _showValidationDialog("Please enter Last Name.");
      return;
    } else if (!nameRegex.hasMatch(lastName.text.trim())) {
      _showValidationDialog("Last Name must not contain special characters.");
      return;
    }

    if (mobilePhone.text.trim().isEmpty) {
      _showValidationDialog("Please enter Mobile Number.");
      return;
    }
    if (mobilePhone.text.length != 10) {
      _showValidationDialog("Mobile number must be 10 digits.");
      return;
    }
    if (birthDate.text.trim().isEmpty) {
      _showValidationDialog("Please select Birth Date.");
      return;
    }

    if (gender.text.trim().isEmpty) {
      _showValidationDialog("Please select Gender.");
      return;
    }
    if (email.text.trim().isEmpty) {
      _showValidationDialog("Please enter Email Address.");
      return;
    }

    if (!_isValidEmail(email.text.trim())) {
      _showValidationDialog("Please enter a valid Email Address.");
      return;
    }
    if (!RegExp(r"^[\w\.-]+@[\w\.-]+\.\w+$").hasMatch(email.text.trim())) {
      _showValidationDialog("Please enter a valid Email Address.");
      return;
    }
    if (civil_Status.text.trim().isEmpty) {
      _showValidationDialog("Please select Civil Status.");
      return;
    }

    if (nationality.text.trim().isEmpty) {
      _showValidationDialog("Please select Nationality.");
      return;
    }
    if (place_Of_Birth.text.trim().isEmpty) {
      _showValidationDialog("Please enter Place of Birth.");
      return;
    }

    // Address validation
    if (!_isValidStreet(perm_Street.text)) {
      _showValidationDialog(
          "Permanent Street must be at least 10 characters and 3 words.");
      return;
    }
    if (!_isValidStreet(emp_Street.text)) {
      _showValidationDialog(
          "Employee Street must be at least 10 characters and 3 words.");
      return;
    }

    // Work validation
    if (emp_position.text.trim().isEmpty) {
      _showValidationDialog("Please enter Position.");
      return;
    }
    if (emp_Mths_In_Cur_Comp.text.isEmpty) {
      _showValidationDialog(
          "Please enter both Years and Months of Work Experience.");
      return;
    }
    if (emp_Yrs_In_Cur_Comp.text.isEmpty) {
      _showValidationDialog(
          "Please enter both Years and Months of Work Experience.");
      return;
    }

    if (perm_ZipCode.text.trim().isEmpty) {
      _showValidationDialog("Please enter Zip Code.");
      return;
    } else if (!RegExp(r'^\d{4}$').hasMatch(perm_ZipCode.text.trim())) {
      _showValidationDialog("Zip Code must be exactly 4 digits.");
      return;
    }
// Region
    if (perm_Region.text.trim().isEmpty) {
      _showValidationDialog("Please enter/select Region.");
      return;
    }

// Province
    if (perm_State.text.trim().isEmpty) {
      _showValidationDialog("Please enter/select Province.");
      return;
    }

// City
    if (perm_City.text.trim().isEmpty) {
      _showValidationDialog("Please enter/select City.");
      return;
    }

// Barangay
    if (perm_Barangay.text.trim().isEmpty) {
      _showValidationDialog("Please select Barangay.");
      return;
    }

// Street - Minimum 10 characters & 3 words
    if (!_isValidStreet(perm_Street.text)) {
      _showValidationDialog(
          "Street must be at least 10 characters and 3 words.");
      return;
    }

    // ID Type & specific ID validations
    if (_selectedIdType == null) {
      _showValidationDialog("Please select an Identification ID Type.");
      return;
    }
    // Employment Status
    if (emp_Status.text.trim().isEmpty) {
      _showValidationDialog("Please select Employment Status.");
      return;
    }

// Work Nature
    if (emp_Work_Nature.text.trim().isEmpty) {
      _showValidationDialog("Please select Employment Work Nature.");
      return;
    }

// Profession (if applicable)
    if (EmpStatus == true && profession.text.trim().isEmpty) {
      _showValidationDialog("Please select Profession.");
      return;
    }

// Employer Name
    if (emp_Employer_Name.text.trim().isEmpty) {
      _showValidationDialog("Please enter Employer's Name.");
      return;
    } else if (!_isValidName(emp_Employer_Name.text)) {
      _showValidationDialog(
          "Employer's Name must not contain special characters or numbers.");
      return;
    }

// Industry Type
    if (emp_Indus_Type.text.trim().isEmpty) {
      _showValidationDialog("Please select Industry Type.");
      return;
    }

// Employee Type
    if (emp_Type.text.trim().isEmpty) {
      _showValidationDialog("Please select Employee Type.");
      return;
    }

// Employee Email
    if (emp_email.text.trim().isEmpty) {
      _showValidationDialog("Please enter Employee Email.");
      return;
    } else if (!RegExp(r"^[\w\.-]+@[\w\.-]+\.\w+$")
        .hasMatch(emp_email.text.trim())) {
      _showValidationDialog("Please enter a valid Employee Email Address.");
      return;
    }
    // Monthly Income
    if (fin_Mthly_Income.text.trim().isEmpty) {
      _showValidationDialog("Please enter Monthly Income.");
      return;
    } else if (!_isValidIncome(fin_Mthly_Income.text)) {
      _showValidationDialog("Monthly Income must be a valid positive number.");
      return;
    }

// Source of Funds
    if (fin_Src_Of_Funds.text.trim().isEmpty) {
      _showValidationDialog("Please select Source of Funds.");
      return;
    }
    // Employment Zip Code - Required, 4 digits
    if (emp_ZipCode.text.trim().isEmpty) {
      _showValidationDialog("Please enter Employment Zip Code.");
      return;
    } else if (!RegExp(r'^\d{4}$').hasMatch(emp_ZipCode.text.trim())) {
      _showValidationDialog("Employment Zip Code must be exactly 4 digits.");
      return;
    }

// Region
    if (emp_Region.text.trim().isEmpty) {
      _showValidationDialog("Please enter/select Employment Region.");
      return;
    }

// Province
    if (emp_State.text.trim().isEmpty) {
      _showValidationDialog("Please enter/select Employment Province.");
      return;
    }

// City
    if (emp_City.text.trim().isEmpty) {
      _showValidationDialog("Please enter/select Employment City.");
      return;
    }

// Barangay
    if (emp_Barangay.text.trim().isEmpty) {
      _showValidationDialog("Please select Employment Barangay.");
      return;
    }

// Street - Minimum 10 characters & 3 words, no special characters
    if (!_isValidStreet(emp_Street.text)) {
      _showValidationDialog(
          "Employment Street must be at least 10 characters and 3 words with no special characters.");
      return;
    }

    if (_selectedIdType == IdType.tin) {
      if (identity_TinId.text.trim().isEmpty) {
        _showValidationDialog("TIN ID cannot be blank.");
        return;
      } else if (!_isValidIdtin(identity_TinId.text)) {
        _showValidationDialog("TIN ID must be 9 digits.");
        return;
      }
    } else if (_selectedIdType == IdType.sss) {
      if (identity_SssID.text.trim().isEmpty) {
        _showValidationDialog("SSS ID cannot be blank.");
        return;
      } else if (!_isValidIdsssid(identity_SssID.text)) {
        _showValidationDialog("SSS ID must be 10 digits.");
        return;
      }
    } else if (_selectedIdType == IdType.gsis) {
      if (identity_GsisID.text.trim().isEmpty) {
        _showValidationDialog("GSIS ID cannot be blank.");
        return;
      } else if (!_isValidIdGsisId(identity_GsisID.text)) {
        _showValidationDialog("GSIS ID must be 11 digits.");
        return;
      }
    }

    // All validations passed
    FocusScope.of(context).unfocus();
    submitLos();
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
    // final Tokenresponse = await http.get(
    //   Uri.parse('${AppConfig.dynamicBaseUrl}/api/leads/los-access-token/'),
    //   headers: {
    //     'Authorization': 'Bearer $token',
    //     'User-Agent':
    //         'Mozilla/5.0 (Linux; Android 11; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36',
    //   },
    // );

    String url = "/api/leads/los-access-token/";
    final headers = {
      'Authorization': 'Bearer $token',
      'User-Agent':
          'Mozilla/5.0 (Linux; Android 11; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36',
    };

    final Tokenresponse = await ApiService.getWithHeaders(url, headers);
    final data = Tokenresponse!.data;
    tokens = data['access_token'];
    // String applicationN =application['applicationNo'];
    showDialog(
      barrierDismissible: false, // Prevent closing
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            Future<void> pollStatus(applicationN) async {
              while (retryCount < 3 &&
                  application['offerStatus'] == "IN-PROGRESS") {
                await Future.delayed(Duration(seconds: 30)); // Wait 10 seconds
                retryCount++;

                // Refresh status via API
                // final refreshedResponse = await http.post(
                //   Uri.parse(
                //       '${AppConfig.dynamicBaseUrl}/api/app/fetch/application/status'),
                //   headers: {
                //     'Content-Type': 'application/json',
                //     "Idempotency-Key": "jbkjdbjkjk",
                //     "Authorization": "Bearer $tokens",
                //     'User-Agent':
                //         'Mozilla/5.0 (Linux; Android 11; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36',
                //   },
                //   body: json.encode({
                //     "mobileNo": "",
                //     "agentCode": "",
                //     "applicationNo": "${application['applicationNo']}",
                //     "channel": "",
                //     "source": ""
                //   }),
                // );

                String url = "/api/app/fetch/application/status";
                final header = {
                  "Idempotency-Key": "jbkjdbjkjk",
                  "Authorization": "Bearer $tokens",
                  'User-Agent':
                      'Mozilla/5.0 (Linux; Android 11; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36',
                };

                final body = {
                  "mobileNo": "",
                  "agentCode": "",
                  "applicationNo": "${application['applicationNo']}",
                  "channel": "",
                  "source": ""
                };

                final refreshedResponse =
                    await ApiService.postJsonWithHeaders(url, body, header);
                if (refreshedResponse!.statusCode == 200) {
                  final refreshedData = refreshedResponse.data;
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

    final digits = List.generate(12, (_) {
      final byte = secureRandom.nextUint8();
      return (byte % 10).toString();
    }).join();

    return digits; // e.g., "482739"
  }

  void submitLos() {
    setState(() {
      _isLoading = true;
    });
    String CWTransactionID = generateSecureTransactionId();

    String formattedBirthDate;
    final parsedDate = DateFormat('dd-MM-yyyy').parse(birthDate.text);
    formattedBirthDate = DateFormat('yyyy-MM-dd').format(parsedDate);
    String identityTinId = identity_TinId.text.trim();
    String identityGsisID = identity_GsisID.text.trim();
    String identitySssID = identity_SssID.text.trim();
    String phoneNumber = "63" + mobilePhone.text.trim();
    String first_Name = "";
    String permZip = "";
    String empStatus = "";
    String montlyIncome = "";
    String empStreet = "";
    first_Name = firstName.text.trim();
    permZip = perm_ZipCode.text.trim();
    empStatus = emp_State.text;
    empStreet = emp_Street.text.trim();

    montlyIncome = fin_Mthly_Income.text;
    Map<String, dynamic> requestData = {
      "CWTransactionID": CWTransactionID,
      "clientDetails": {
        "ARN": "1513411334533400",
        "idmArnNo": "",
        "clientType": "",
        "firstName": first_Name,
        "lastName": lastName.text.trim(),
        "middleName": middlename.text.trim(),
        "mobilePhone": phoneNumber,
        "birthDate": formattedBirthDate,
        "gender": gender.text.trim(),
        "emailAddress": email.text.trim(),
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
            "city": perm_City.text.trim(),
            "region": perm_Region.text.trim(),
            "postcode": perm_ZipCode.text.trim(),
            "country": nationality.text.trim(),
          }
        ],
        "idDocuments": null,
        "_Perm_Address": {
          "perm_State": perm_State.text.trim(),
          "perm_City": perm_City.text.trim(),
          "perm_Street": perm_Street.text.trim(),
          "perm_ZipCode": permZip,
          "perm_Barangay": perm_Barangay.text.trim(),
          "perm_Region": perm_Region.text.trim(),
          "perm_Country":
              nationality.text.trim().replaceFirst(RegExp(r'^0+'), ''),
          "perm_countryCode": nationality.text.trim(),
          "hra": ""
        },
        "_Fin_Details": {
          "fin_Mthly_Income": double.tryParse(montlyIncome)?.toInt().toString(),
          "fin_Ownr_Car": "",
          "fin_Ann_Income": "",
          "fin_Ownr_Home": "",
          "fin_Src_Of_Funds": fin_Src_Of_Funds.text.trim(),
          "fin_Src_Of_Funds_Code": fin_Src_Of_Funds_Code.text.trim(),
          "fin_Salary_Period": "",
          "fin_Salary_dates": "",
        },
        "_Identification_Details": {
          "identity_TinId": identityTinId,
          "identity_GsisID": identityGsisID,
          "identity_SssID": identitySssID,
        },
        "Nom_Details": null,
        "_Emp_Details": {
          "emp_Work_Nature": emp_Work_Nature.text.trim(),
          "emp_Mths_In_Cur_Comp": emp_Mths_In_Cur_Comp.text.trim(),
          "emp_Status": emp_Status.text.trim(),
          "emp_Employer_Name": emp_Employer_Name.text.trim(),
          "emp_Indus_Type": emp_Indus_Type.text.trim(),
          "emp_Type": emp_Type.text.trim(),
          "emp_Yrs_In_Cur_Comp": emp_Yrs_In_Cur_Comp.text.trim(),
          "Office_phone_no": "",
          "emp_Type_Code":
              emp_Type_Code.text.trim().replaceFirst(RegExp(r'^0+'), ''),
          "emp_Status_Code":
              emp_Status_Code.text.trim().replaceFirst(RegExp(r'^0+'), ''),
          "emp_Work_Nature_Code":
              emp_Work_Nature_Code.text.trim().replaceFirst(RegExp(r'^0+'), ''),
          "emp_Indus_Type_Code":
              emp_Indus_Type_Code.text.trim().replaceFirst(RegExp(r'^0+'), ''),
          "emp_email": emp_email.text.trim(),
          "companyCategorySegment": "",
          "profession": profession.text.trim()
        },
        "_Emp_Address": {
          "emp_Street": empStreet,
          "emp_State": empStatus,
          "emp_City": emp_City.text.trim(),
          "emp_Country": nationality.text.replaceFirst(RegExp(r'^0+'), ''),
          "emp_ZipCode": emp_ZipCode.text.trim(),
          "emp_Barangay": emp_Barangay.text.trim(),
          "emp_Region": emp_Region.text.trim(),
          "emp_countryCode": nationality.text.trim()
        },
        "_Personal_Details": {
          "fatca_Cert_US_Non_US": "",
          "fatca_W9_IdNumber": "",
          "no_Of_Dependents": "",
          "fatca_W9_IdType": "",
          "civil_Status": civil_Status.text.trim(),
          "yrs_In_Residence": "",
          "nationality": nationality.text.trim(),
          "marketing_Consent": "",
          "mailing_Adrs": "",
          "place_Of_Birth": place_Of_Birth.text.trim(),
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
          "agentCode": agentCode.text.trim(),
        },
        "account": {
          "referralPromoCodeFlag": "",
          "referralCode": "",
          "promotionalCode": "",
          "sourceCompany": "UnoSales",
          "agentCode": agentCode.text.trim(),
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
      }
    };

    Future.delayed(Duration(seconds: 5), () {
      setState(() {
        _isLoading = false; // Data loaded after 5 seconds
      });
    });
    postLoanCheck(requestData);
  }

  String convertMonthsToReadableFormat(String monthsStr) {
    int months = int.tryParse(monthsStr) ?? 0;
    int years = months ~/ 12;

    return "$years";
  }

  Future<void> postLoanCheck(Map<String, dynamic> requestData) async {
    // String jsonString = jsonEncode(requestData);
    // for (int i = 0; i < jsonString.length; i += 1000) {
    //   print(jsonString.substring(
    //       i, (i + 1000 > jsonString.length) ? jsonString.length : i + 1000));
    // }
    setState(() {});
    String tokens = "";
    try {
      // final Tokenresponse = await http.get(tokenUrl);
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('accessToken');
      // final Tokenresponse = await http.get(
      //   Uri.parse('${AppConfig.dynamicBaseUrl}/api/leads/los-access-token/'),
      //   headers: {
      //     'Authorization': 'Bearer $token',
      //     'Accept': 'application/json',
      //     'Content-Type': 'multipart/form-data',
      //     'User-Agent':
      //         'Mozilla/5.0 (Linux; Android 11; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36',
      //   },
      // );

      String url = "/api/leads/los-access-token/";
      final headers = {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Content-Type': 'multipart/form-data',
        'User-Agent':
            'Mozilla/5.0 (Linux; Android 11; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36',
      };

      final Tokenresponse = await ApiService.getWithHeaders(url, headers);

      final data = Tokenresponse!.data;
      tokens = data['access_token'];
    } catch (e) {
      print("HTTP Request Failed: $e");
    }

    String url = "/partner/loans/check";
    final headers = {
      "Idempotency-Key": "th37per9-185d-4e22-83fb-18gf96g0g861",
      "Content-Type": "application/json",
      "Accept": "application/json",
      "Authorization": "Bearer $tokens",
      'User-Agent':
          'Mozilla/5.0 (Linux; Android 11; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36',
    };

    try {
      // final response = await http.post(
      //   url,
      //   headers: headers,
      //   body: json.encode(requestData),
      // );

      final response =
          await ApiService.postWithHeadersUnoApi(url, requestData, headers);
      if (response!.statusCode == 201) {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        String? token = prefs.getString('accessToken');
        // final LosStatusUrl = Uri.parse(
        //     '${AppConfig.dynamicBaseUrl}/api/campaigns/${widget.campaign}/leads/${widget.leadId}/');

        String LosStatusUrl =
            "/api/campaigns/${widget.campaign}/leads/${widget.leadId}/";

        final headers2 = {
          "Content-Type": "application/json",
          "Accept": "application/json",
          "Authorization": "Bearer $token",
          'User-Agent':
              'Mozilla/5.0 (Linux; Android 11; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36',
        };
        // Map<String, String> mappedLOsData = {
        //   "cwtransection_id": "${requestData['CWTransactionID']}",
        //   "los_status": "submitted"
        // };

        final body1 = {
          "cwtransection_id": "${requestData['CWTransactionID']}",
          "los_status": "submitted"
        };

        // ignore: unused_local_variable
        // final responseLOS = await http.patch(
        //   LosStatusUrl,
        //   headers: headers2,
        //   body: json.encode(mappedLOsData),
        // );
        // ignore: unused_local_variable
        final responseLOS =
            await ApiService.patchWithHeaders(LosStatusUrl, headers2, body1);
        final LoSResponcedata = response.data;

        //LOS Application Status Check
        // Map<String, dynamic> mappedData = {
        //   "mobileNo": "",
        //   "agentCode": "",
        //   "applicationNo": "${LoSResponcedata['applicationNumber']}",
        //   "channel": "",
        //   "source": ""
        // };
        // final url =
        //     Uri.parse("${AppConfig.otpUrl}/api/app/fetch/application/status");

        String url = "/api/app/fetch/application/status";
        final body = {
          "mobileNo": "",
          "agentCode": "",
          "applicationNo": "${LoSResponcedata['applicationNumber']}",
          "channel": "",
          "source": ""
        };

        final headers = {
          'Content-Type': 'application/json',
          "Idempotency-Key": "jbkjdbjkjk",
          "Authorization": "Bearer $tokens",
          'User-Agent':
              'Mozilla/5.0 (Linux; Android 11; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36',
        };
        try {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            },
          );

          // Make the API call
          // final Statusresponse = await http.post(
          //   url,
          //   headers: headers,
          //   body: json.encode(mappedData),
          // );

          final Statusresponse =
              await ApiService.postWithHeadersUnoApi(url, body, headers);
          // Close the loading dialog
          Navigator.of(context).pop();

          if (Statusresponse!.statusCode == 200) {
            final data = Statusresponse.data;
            var result = data['result'];

            if (result != null && result.isNotEmpty) {
              var application = result[0]; // Access the first application

              String LosbackendStatusUrl = "/api/leads/los-details/";
              final headers3 = {
                "Content-Type": "application/json",
                "Accept": "application/json",
                "Authorization": "Bearer $token",
                'User-Agent':
                    'Mozilla/5.0 (Linux; Android 11; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36',
              };
              final finalRequestData;
              if (widget.pagemode == 'edit') {
                finalRequestData = Map<String, dynamic>.from(requestData)
                  ..["lead_type"] = "campaign_lead"
                  ..["declaration"] = true;
              } else {
                finalRequestData = Map<String, dynamic>.from(requestData)
                  ..["lead_type"] = "fresh_lead"
                  ..["declaration"] = true;
              }
              // final backendresponseLOS = await http.post(
              //   LosbackendStatusUrl,
              //   headers: headers3,
              //   body: json.encode(finalRequestData),
              // );

              final backendresponseLOS = await ApiService.postJsonWithHeaders(
                  LosbackendStatusUrl, finalRequestData, headers3);
              if (backendresponseLOS!.statusCode == 201) {
                final data = backendresponseLOS.data;

                // final LosBackendResponseUrl = Uri.parse(
                //     '${AppConfig.dynamicBaseUrl}/api/leads/los-details/${data['id']}/');

                String LosBackendResponseUrl =
                    "/api/leads/los-details/${data['id']}/";
                final headers4 = {
                  "Content-Type": "application/json",
                  "Accept": "application/json",
                  "Authorization": "Bearer $token",
                  'User-Agent':
                      'Mozilla/5.0 (Linux; Android 11; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36',
                };
                Map<String, dynamic> mappedResponseLOsData = {
                  "los_status": {
                    "mobileNo": application['mobileNo'],
                    "applicationNo": application['applicationNo'],
                    "applicationId": application['applicationId'],
                    "source": application['source'],
                    "channel": application['channel'],
                    "offerStatus": application['offerStatus'],
                    "uwStatus": application['uwStatus'],
                    "lastScreen": application['lastScreen']
                  }
                };
                // ignore: unused_local_variable
                // final responseLOS = await http.patch(
                //   LosBackendResponseUrl,
                //   headers: headers4,
                //   body: json.encode(mappedResponseLOsData),
                // );

                final responseLOS = await ApiService.patchWithHeaders(
                    LosBackendResponseUrl, headers4, mappedResponseLOsData);
              }
              if (application['offerStatus'] == "IN-PROGRESS") {
                checkApplicationStatusLoop(application);
              } else {
                // Normal flow
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: Text("Application Status"),
                      content: Text(
                        "Offer Status: ${application['offerStatus']}\nUnderWriting Status: ${application['uwStatus']}",
                      ),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => LeadListByCampaign(
                                  campaign: widget.campaign,
                                ),
                              ),
                            );
                          },
                          child: Text("OK"),
                        ),
                      ],
                    );
                  },
                );
              }
            }
          }
        } catch (e) {
          Navigator.of(context)
              .pop(); // Ensure the loader is closed if an error occurs
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Something went wrong: $e')),
          );
        }
      } else {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        String? authToken = prefs.getString('accessToken');
        Map<String, dynamic> logmappedData = {
          "url": "${AppConfig.otpUrl}/partner/loans/check",
          "request_body": requestData,
          "status_code": response.statusCode,
          "response_body": response.data,
        };
        // final logUrl = Uri.parse("${AppConfig.dynamicBaseUrl}/api/logs/");
        String logUrl = "/api/logs/";

        final headers = {
          "Content-Type": "application/json",
          "Accept": "application/json",
          "Authorization": "Bearer $authToken",
          'User-Agent':
              'Mozilla/5.0 (Linux; Android 11; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36',
        };
        // final LogResponse = await http.post(
        //   logUrl,
        //   headers: headers,
        //   body: json.encode(logmappedData),
        // );
        final LogResponse = await ApiService.postJsonWithHeaders(
            logUrl, logmappedData, headers);

        if (LogResponse!.statusCode == 201) {
          print("Log Created");
        }
        final data = response.data;

        // Extracting the message
        String message = data['message'] ?? "Validation Error";

        // Extracting and formatting the errors
        Map<String, dynamic> errors = data['errors'] ?? {};
        String errorMessages = errors.entries
            .map((entry) => "${entry.value}")
            .join("\n"); // Joins all errors with a new line

        // Show the AlertDialog
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text("Error"),
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

  Widget _buildZipTextField(
    TextEditingController controller,
    String label,
    String validationMessage,
    String fieldKey, {
    bool isRequired = false,
    bool isZip = false,
    Function(String)? onSubmitted,
    Function(String)? onChanged, // Add this parameter
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(labelText: label),
      inputFormatters: [
        if (isZip) ...[
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(4),
        ],
      ],
      validator: (value) {
        if (isRequired && (value == null || value.isEmpty)) {
          return validationMessage;
        }
        return null;
      },
      onChanged: onChanged, // Use it here
      onFieldSubmitted: onSubmitted,
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String hintText,
    String validationMessage,
    String validationKey, {
    FaIconData icon = FontAwesomeIcons.solidCircleUser,
    bool obscureText = false,
    bool isEmail = false,
    bool isPhoneNumber = false,
    bool isAlphabetic = false,
    bool isNumeric = false,
    bool isZipNumber = false,
    bool isRequired = true,
    bool allowSpaces = false,
    bool readOnly = false,
    bool nameMax = false,
    bool isStreet = false,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      readOnly: readOnly,
      focusNode: readOnly ? NoFocusNode() : null, // prevent focus
      enableInteractiveSelection: !readOnly, // disable long-press select/copy
      keyboardType: isPhoneNumber
          ? TextInputType.phone
          : isEmail
              ? TextInputType.emailAddress
              : isNumeric || isZipNumber
                  ? TextInputType.number
                  : TextInputType.text,
      inputFormatters: [
        if (nameMax) LengthLimitingTextInputFormatter(20),
        if (isZipNumber) ...[
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(4),
        ],
        if (isPhoneNumber) LengthLimitingTextInputFormatter(12),
        if (isAlphabetic)
          FilteringTextInputFormatter.allow(
              allowSpaces ? RegExp(r'^[a-zA-Z\s]+$') : RegExp(r'^[a-zA-Z]+$')),
        if (isStreet) ...[
          LengthLimitingTextInputFormatter(4),
        ],
      ],
      validator: (value) {
        if (isRequired && (value == null || value.trim().isEmpty)) {
          return validationMessage;
        }
        if (isEmail &&
            value != null &&
            value.isNotEmpty &&
            !RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
                .hasMatch(value)) {
          return 'Please enter a valid email address';
        }
        if (isPhoneNumber &&
            (value == null || value.length != 10 || !value.startsWith('63'))) {
          print(isPhoneNumber);
          return 'Phone number must be 10 digits "';
        }
        return null;
      },
      decoration: InputDecoration(
        filled: true,
        fillColor: readOnly
            ? Colors.grey.shade200 // Light grey for read-only
            : Colors.white,
        label: isRequired
            ? RichText(
                text: TextSpan(
                  text: hintText,
                  style: WidgetSupport.inputLabel(),
                  children: const [
                    TextSpan(
                        text: ' *',
                        style: TextStyle(color: Colors.red, fontSize: 25))
                  ],
                ),
              )
            : Text(hintText, style: WidgetSupport.inputLabel()),
        suffixIcon: FaIcon(icon, color: Colors.purple, size: 15),
      ),
    );
  }

  Widget _buildMobileTextField({
    required TextEditingController controller,
    bool isRequired = true,
    FaIconData icon = FontAwesomeIcons.solidCircleUser,
    bool isPhoneNumber = false,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 1, vertical: 8),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(width: 2)),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              bottomLeft: Radius.circular(4),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: Text(
              '   63',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
        Expanded(
          child: TextField(
            controller: controller,
            keyboardType:
                isPhoneNumber ? TextInputType.phone : TextInputType.text,
            inputFormatters: [
              if (isPhoneNumber) LengthLimitingTextInputFormatter(10),
            ],
            // maxLength: 10,
            decoration: InputDecoration(
              label: isRequired
                  ? RichText(
                      text: TextSpan(
                        text: "Phone Number",
                        style: WidgetSupport.inputLabel(),
                        children: const [
                          TextSpan(
                              text: ' *',
                              style: TextStyle(color: Colors.red, fontSize: 25))
                        ],
                      ),
                    )
                  : Text(" Phone Number", style: WidgetSupport.inputLabel()),
              suffixIcon: FaIcon(icon, color: Colors.purple, size: 15),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField2(
    TextEditingController controller,
    String hintText,
    String validationKey, {
    bool isRequired = true,
    bool readOnly = false,
    FaIconData icon = FontAwesomeIcons.solidCircleUser,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        filled: true,
        fillColor: readOnly
            ? Colors.grey.shade200 // Light grey for read-only
            : Colors.white,
        label: isRequired
            ? RichText(
                text: TextSpan(
                  text: hintText,
                  style: WidgetSupport.inputLabel(),
                  children: const [
                    TextSpan(
                        text: ' *',
                        style: TextStyle(color: Colors.red, fontSize: 25))
                  ],
                ),
              )
            : Text(hintText, style: WidgetSupport.inputLabel()),
        suffixIcon: FaIcon(icon, color: Colors.purple, size: 15),
      ),
    );
  }

  Widget _buildRadioField<T>({
    required T value,
    required T? groupValue, // allow nullable here
    required void Function(T?) onChanged,
    required String label,
    bool isRequired = false,
  }) {
    return Row(
      children: [
        Radio<T>(
          value: value,
          groupValue: groupValue,
          onChanged: onChanged,
          activeColor: Colors.purple,
          visualDensity: VisualDensity.compact,
        ),
        Expanded(
          child: isRequired
              ? RichText(
                  text: TextSpan(
                    text: label,
                    style: WidgetSupport.inputLabel(),
                    children: const [
                      TextSpan(
                        text: ' *',
                        style: TextStyle(color: Colors.red, fontSize: 18),
                      ),
                    ],
                  ),
                )
              : Text(label, style: WidgetSupport.inputLabel()),
        ),
      ],
    );
  }

  Widget _buildDateField({
    required TextEditingController controller,
    required String label,
    bool isRequired = true,
  }) {
    return GestureDetector(
      onTap: () {
        DatePickerBdaya.showDatePicker(
          context,
          showTitleActions: true,
          minTime: DateTime(1900),
          maxTime: DateTime.now(),
          onConfirm: (date) {
            controller.text = DateFormat('dd-MM-yyyy').format(date);
          },
          currentTime: DateTime.now(),
          locale: LocaleType.en,
        );
      },
      child: AbsorbPointer(
        child: TextFormField(
          controller: controller,
          decoration: InputDecoration(
            hintText: 'DD-MM-YYYY',
            contentPadding: const EdgeInsets.symmetric(
              vertical: 12.0,
              horizontal: 16.0,
            ),
            label: isRequired
                ? RichText(
                    text: TextSpan(
                      text: label,
                      style: WidgetSupport.inputLabel(),
                      children: const [
                        TextSpan(
                          text: ' *',
                          style: TextStyle(color: Colors.red, fontSize: 25),
                        )
                      ],
                    ),
                  )
                : Text(label, style: WidgetSupport.inputLabel()),
            suffixIcon: const Icon(
              Icons.calendar_today,
              color: Colors.purple,
              size: 15,
            ),
          ),
          validator: (value) {
            if (isRequired && (value == null || value.trim().isEmpty)) {
              return "Please select your birth date";
            }
            return null;
          },
        ),
      ),
    );
  }

  Widget _buildGenderDropdown({
    required TextEditingController controller,
    required String label,
    bool isRequired = true,
  }) {
    return DropdownButtonFormField<String>(
      focusNode: genderFocusNode,
      value: genderList.any((item) => item['value'] == gender.text.trim())
          ? gender.text.trim()
          : null,
      items: genderList.map<DropdownMenuItem<String>>((item) {
        return DropdownMenuItem<String>(
          value: item['value'], // Use 'Male' or 'Female' for value
          child: Text(item['value'] ?? ''),
        );
      }).toList(),
      selectedItemBuilder: (BuildContext context) {
        return genderList.map<Widget>((item) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(
              item['value'] ?? '',
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          );
        }).toList();
      },
      onChanged: (String? newValue) {
        if (newValue != null) {
          controller.text = newValue; // Store value like "Male"
        }
      },
      icon: const SizedBox.shrink(),
      decoration: InputDecoration(
        label: isRequired
            ? RichText(
                text: TextSpan(
                  text: label,
                  style: WidgetSupport.inputLabel(),
                  children: const [
                    TextSpan(
                        text: ' *',
                        style: TextStyle(color: Colors.red, fontSize: 25))
                  ],
                ),
              )
            : Text(label, style: WidgetSupport.inputLabel()),
        suffixIcon:
            const Icon(Icons.arrow_drop_down, color: Colors.purple, size: 30),
      ),
      validator: (value) {
        if (isRequired && (value == null || value.isEmpty)) {
          return "Please select your gender";
        }
        return null;
      },
    );
  }

  Widget _buildPermBarangayDropdown({
    required TextEditingController controller,
    required String label,
    bool isRequired = true,
  }) {
    return DropdownButtonFormField<String>(
      value: PermbarangayList.contains(_selectedBarangay)
          ? _selectedBarangay
          : null,
      items: PermbarangayList.map((String region) {
        return DropdownMenuItem<String>(
          value: region,
          child: Text(region),
        );
      }).toList(),
      onChanged: (String? newValue) {
        setState(() {
          _selectedBarangay = newValue!;
          controller.text = newValue;
        });
      },
      icon: const SizedBox.shrink(),
      decoration: InputDecoration(
        label: isRequired
            ? RichText(
                text: TextSpan(
                  text: label,
                  style: WidgetSupport.inputLabel(),
                  children: const [
                    TextSpan(
                      text: ' *',
                      style: TextStyle(color: Colors.red, fontSize: 25),
                    ),
                  ],
                ),
              )
            : Text(label, style: WidgetSupport.inputLabel()),
        suffixIcon:
            const Icon(Icons.arrow_drop_down, color: Colors.purple, size: 30),
      ),
      validator: (value) {
        if (isRequired && (value == null || value.isEmpty)) {
          return "Please select Barangay";
        }
        return null;
      },
    );
  }

  Widget _buildEmpBarangayDropdown({
    required TextEditingController controller,
    required String label,
    bool isRequired = true,
  }) {
    return DropdownButtonFormField<String>(
      value: EmpbarangayList.contains(_selectedEmpBarangay)
          ? _selectedEmpBarangay
          : null,
      items: EmpbarangayList.map((String region) {
        return DropdownMenuItem<String>(
          value: region,
          child: Text(region),
        );
      }).toList(),
      onChanged: (String? newValue) {
        setState(() {
          _selectedEmpBarangay = newValue!;
          emp_Barangay.text = newValue;
        });
      },
      icon: const SizedBox.shrink(),
      decoration: InputDecoration(
        label: isRequired
            ? RichText(
                text: TextSpan(
                  text: label,
                  style: WidgetSupport.inputLabel(),
                  children: const [
                    TextSpan(
                      text: ' *',
                      style: TextStyle(color: Colors.red, fontSize: 25),
                    ),
                  ],
                ),
              )
            : Text(label, style: WidgetSupport.inputLabel()),
        suffixIcon: Icon(Icons.arrow_drop_down, color: Colors.purple, size: 30),
      ),
      validator: (value) {
        if (isRequired && (value == null || value.isEmpty)) {
          return "Please select Barangay";
        }
        return null;
      },
    );
  }

  Widget _buildSourceFundDropdown({
    required TextEditingController controller,
    required String label,
    bool isRequired = true,
  }) {
    return DropdownButtonFormField<String>(
      isExpanded: true,
      focusNode: genderFocusNode,
      value: sourceofFundList
              .any((item) => item['key'] == fin_Src_Of_Funds_Code.text.trim())
          ? fin_Src_Of_Funds_Code.text.trim()
          : null,
      items: sourceofFundList.map<DropdownMenuItem<String>>((item) {
        return DropdownMenuItem<String>(
          value: item['key']?.toString() ?? '',
          child: Text(
            item['value'] ?? '',
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        );
      }).toList(),
      selectedItemBuilder: (BuildContext context) {
        return sourceofFundList.map<Widget>((item) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(
              item['value'] ?? '',
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          );
        }).toList();
      },
      onChanged: (String? newValue) {
        if (newValue != null) {
          controller.text = newValue;
          // 🔍 Lookup selected item from the list
          final selectedItem =
              sourceofFundList.firstWhere((item) => item['key'] == newValue);
          setState(() {
            fin_Src_Of_Funds_Code.text = selectedItem['key'] ?? '';
          });
        }
      },
      icon: const SizedBox.shrink(),
      decoration: InputDecoration(
        label: isRequired
            ? RichText(
                text: TextSpan(
                  text: label,
                  style: WidgetSupport.inputLabel(),
                  children: const [
                    TextSpan(
                        text: ' *',
                        style: TextStyle(color: Colors.red, fontSize: 25))
                  ],
                ),
              )
            : Text(label, style: WidgetSupport.inputLabel()),
        suffixIcon:
            const Icon(Icons.arrow_drop_down, color: Colors.purple, size: 30),
      ),
      validator: (value) {
        if (isRequired && (value == null || value.isEmpty)) {
          return "Please Select Source Of Funds";
        }
        return null;
      },
    );
  }

  Widget _buildEmpWorkNatureDropdown({
    required TextEditingController controller,
    required String label,
    bool isRequired = true,
  }) {
    return DropdownButtonFormField<String>(
      isExpanded: true,
      focusNode: genderFocusNode,
      value: empWorkNatureList
              .any((item) => item['key'] == emp_Work_Nature_Code.text.trim())
          ? emp_Work_Nature_Code.text.trim()
          : null,
      items: empWorkNatureList.map((item) {
        return DropdownMenuItem<String>(
          value: item['key'],
          child: Text(item['value']),
        );
      }).toList(),
      selectedItemBuilder: (BuildContext context) {
        return empWorkNatureList.map<Widget>((item) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(
              item['value'] ?? '',
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          );
        }).toList();
      },
      onChanged: (String? newValue) {
        if (newValue != null) {
          final selectedItem =
              empWorkNatureList.firstWhere((item) => item['key'] == newValue);
          setState(() {
            controller.text = selectedItem['value'] ?? '';
            emp_Work_Nature_Code.text = selectedItem['key'] ?? '';
            _initializeSourceFundList();
          });
        }
      },
      icon: const SizedBox.shrink(),
      decoration: InputDecoration(
        label: isRequired
            ? RichText(
                text: TextSpan(
                  text: label,
                  style: WidgetSupport.inputLabel(),
                  children: const [
                    TextSpan(
                        text: ' *',
                        style: TextStyle(color: Colors.red, fontSize: 25))
                  ],
                ),
              )
            : Text(label, style: WidgetSupport.inputLabel()),
        suffixIcon:
            const Icon(Icons.arrow_drop_down, color: Colors.purple, size: 30),
      ),
      validator: (value) {
        if (isRequired && (value == null || value.isEmpty)) {
          return "Please Select Emp Work Nature";
        }
        return null;
      },
    );
  }

  Widget _buildPositionDropdown({
    required TextEditingController controller,
    required String label,
    bool isRequired = true,
  }) {
    return DropdownButtonFormField<String>(
      isExpanded: true,
      focusNode: genderFocusNode,
      value: controller.text.isNotEmpty ? controller.text : null,
      items: position.map<DropdownMenuItem<String>>((item) {
        return DropdownMenuItem<String>(
          value: item['key']?.toString() ?? '',
          child: Text(
            item['value'] ?? '',
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        );
      }).toList(),
      selectedItemBuilder: (BuildContext context) {
        return position.map<Widget>((item) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(
              item['value'] ?? '',
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          );
        }).toList();
      },
      onChanged: (String? newValue) {
        if (newValue != null) {
          controller.text = newValue;
          _initializeSourceFundList();
        }
      },
      icon: const SizedBox.shrink(),
      decoration: InputDecoration(
        label: isRequired
            ? RichText(
                text: TextSpan(
                  text: label,
                  style: WidgetSupport.inputLabel(),
                  children: const [
                    TextSpan(
                        text: ' *',
                        style: TextStyle(color: Colors.red, fontSize: 25))
                  ],
                ),
              )
            : Text(label, style: WidgetSupport.inputLabel()),
        suffixIcon:
            const Icon(Icons.arrow_drop_down, color: Colors.purple, size: 30),
      ),
      validator: (value) {
        if (isRequired && (value == null || value.isEmpty)) {
          return "Please Select Emp Position";
        }
        return null;
      },
    );
  }

  Widget _buildEmpStatusDropdown({
    required TextEditingController controller,
    required String label,
    bool isRequired = true,
  }) {
    return DropdownButtonFormField<String>(
      isExpanded: true,
      focusNode: genderFocusNode,
      value: empStatusList
              .any((item) => item['key'] == emp_Status_Code.text.trim())
          ? emp_Status_Code.text.trim()
          : null,
      items: empStatusList.map((item) {
        return DropdownMenuItem<String>(
          value: item['key'],
          child: Text(item['value']),
        );
      }).toList(),
      selectedItemBuilder: (BuildContext context) {
        return empStatusList.map<Widget>((item) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(
              item['value'] ?? '',
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          );
        }).toList();
      },
      onChanged: (String? newValue) {
        if (newValue != null) {
          final selectedItem =
              empStatusList.firstWhere((item) => item['key'] == newValue);
          setState(() {
            controller.text = selectedItem['value'] ?? '';
            emp_Status_Code.text = selectedItem['key'] ?? '';
            _initializeSourceFundList();
          });
        }
      },
      icon: const SizedBox.shrink(),
      decoration: InputDecoration(
        label: isRequired
            ? RichText(
                text: TextSpan(
                  text: label,
                  style: WidgetSupport.inputLabel(),
                  children: const [
                    TextSpan(
                        text: ' *',
                        style: TextStyle(color: Colors.red, fontSize: 25))
                  ],
                ),
              )
            : Text(label, style: WidgetSupport.inputLabel()),
        suffixIcon:
            const Icon(Icons.arrow_drop_down, color: Colors.purple, size: 30),
      ),
      validator: (value) {
        if (isRequired && (value == null || value.isEmpty)) {
          return "Please Select Emp Status";
        }
        return null;
      },
    );
  }

  Widget _buildEmpIndusTypeDropdown({
    required TextEditingController controller,
    required String label,
    bool isRequired = true,
  }) {
    return DropdownButtonFormField<String>(
      isExpanded: true,
      focusNode: genderFocusNode,
      value: industryList
              .any((item) => item['key'] == emp_Indus_Type_Code.text.trim())
          ? emp_Indus_Type_Code.text.trim()
          : null,
      items: industryList.map((item) {
        return DropdownMenuItem<String>(
          value: item['key'],
          child: Text(item['value']),
        );
      }).toList(),
      selectedItemBuilder: (BuildContext context) {
        return industryList.map<Widget>((item) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(
              item['value'] ?? '',
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          );
        }).toList();
      },
      onChanged: (String? newValue) {
        if (newValue != null) {
          final selectedItem =
              industryList.firstWhere((item) => item['key'] == newValue);
          setState(() {
            controller.text = selectedItem['value'] ?? '';
            emp_Indus_Type_Code.text = selectedItem['key'] ?? '';
          });
        }
      },
      icon: const SizedBox.shrink(),
      decoration: InputDecoration(
        label: isRequired
            ? RichText(
                text: TextSpan(
                  text: label,
                  style: WidgetSupport.inputLabel(),
                  children: const [
                    TextSpan(
                        text: ' *',
                        style: TextStyle(color: Colors.red, fontSize: 25))
                  ],
                ),
              )
            : Text(label, style: WidgetSupport.inputLabel()),
        suffixIcon:
            const Icon(Icons.arrow_drop_down, color: Colors.purple, size: 30),
      ),
      validator: (value) {
        if (isRequired && (value == null || value.isEmpty)) {
          return "Please Select Emp Insustry Type";
        }
        return null;
      },
    );
  }

  String getClosestWorkExperienceMonths(int months) {
    if (months < 12) {
      return "12";
    } else if (months < 24) {
      return "24";
    } else if (months < 36) {
      return "36";
    } else if (months < 60) {
      return "60";
    } else {
      return "61";
    }
  }

  Widget _buildWorkExpDropdown({
    required TextEditingController controller,
    required String label,
    bool isRequired = true,
  }) {
    return DropdownButtonFormField<String>(
      isExpanded: true,
      focusNode: genderFocusNode,
      value: workExperience
              .any((item) => item['months'] == emp_Mths_In_Cur_Comp.text.trim())
          ? emp_Mths_In_Cur_Comp.text.trim()
          : null,
      items: workExperience.map((item) {
        return DropdownMenuItem<String>(
          value: item['months'],
          child: Text(item['value']),
        );
      }).toList(),
      selectedItemBuilder: (BuildContext context) {
        return workExperience.map<Widget>((item) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(
              item['value'] ?? '',
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          );
        }).toList();
      },
      onChanged: (String? newValue) {
        if (newValue != null) {
          // Save raw months for API
          emp_Mths_In_Cur_Comp.text = newValue;

          // Convert months to years for UI display
          final months = int.tryParse(newValue);
          if (months != null) {
            final years = (months ~/ 12).toString(); // Integer division
            emp_Yrs_In_Cur_Comp.text = years;
          } else {
            controller.text = '';
            emp_Yrs_In_Cur_Comp.text = '';
          }
        }
      },
      icon: const SizedBox.shrink(),
      decoration: InputDecoration(
        label: isRequired
            ? RichText(
                text: TextSpan(
                  text: label,
                  style: WidgetSupport.inputLabel(),
                  children: const [
                    TextSpan(
                        text: ' *',
                        style: TextStyle(color: Colors.red, fontSize: 25))
                  ],
                ),
              )
            : Text(label, style: WidgetSupport.inputLabel()),
        suffixIcon:
            const Icon(Icons.arrow_drop_down, color: Colors.purple, size: 30),
      ),
      validator: (value) {
        if (isRequired && (value == null || value.isEmpty)) {
          return "Please select Work Experience";
        }
        return null;
      },
    );
  }

  Widget _buildEmpTypeDropdown({
    required TextEditingController controller,
    required String label,
    bool isRequired = true,
  }) {
    return DropdownButtonFormField<String>(
      isExpanded: true,
      focusNode: genderFocusNode,
      value: empList.any((item) => item['key'] == emp_Type_Code.text.trim())
          ? emp_Type_Code.text.trim()
          : null,
      items: empList.map((item) {
        return DropdownMenuItem<String>(
          value: item['key'],
          child: Text(item['value']),
        );
      }).toList(),
      selectedItemBuilder: (BuildContext context) {
        return empList.map<Widget>((item) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(
              item['value'] ?? '',
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          );
        }).toList();
      },
      onChanged: (String? newValue) {
        if (newValue != null) {
          final selectedItem =
              empList.firstWhere((item) => item['key'] == newValue);
          setState(() {
            controller.text = selectedItem['value'] ?? '';
            emp_Type_Code.text = selectedItem['key'] ?? '';
          });
        }
      },
      icon: const SizedBox.shrink(),
      decoration: InputDecoration(
        label: isRequired
            ? RichText(
                text: TextSpan(
                  text: label,
                  style: WidgetSupport.inputLabel(),
                  children: const [
                    TextSpan(
                        text: ' *',
                        style: TextStyle(color: Colors.red, fontSize: 25))
                  ],
                ),
              )
            : Text(label, style: WidgetSupport.inputLabel()),
        suffixIcon:
            const Icon(Icons.arrow_drop_down, color: Colors.purple, size: 30),
      ),
      validator: (value) {
        if (isRequired && (value == null || value.isEmpty)) {
          return "Please Select Emp Type";
        }
        return null;
      },
    );
  }

  Widget _buildEmpPrefessionDropdown({
    required TextEditingController controller,
    required String label,
    bool isRequired = true,
  }) {
    return DropdownButtonFormField<String>(
      isExpanded: true,
      focusNode: genderFocusNode,
      value: controller.text.isNotEmpty ? controller.text : null,
      items: empProfessionList.map<DropdownMenuItem<String>>((item) {
        return DropdownMenuItem<String>(
          value: item['key']?.toString() ?? '',
          child: Text(
            item['value'] ?? '',
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        );
      }).toList(),
      selectedItemBuilder: (BuildContext context) {
        return empProfessionList.map<Widget>((item) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(
              item['value'] ?? '',
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          );
        }).toList();
      },
      onChanged: (String? newValue) {
        if (newValue != null) {
          controller.text = newValue;
        }
      },
      icon: const SizedBox.shrink(),
      decoration: InputDecoration(
        label: isRequired
            ? RichText(
                text: TextSpan(
                  text: label,
                  style: WidgetSupport.inputLabel(),
                  children: const [
                    TextSpan(
                        text: ' *',
                        style: TextStyle(color: Colors.red, fontSize: 25))
                  ],
                ),
              )
            : Text(label, style: WidgetSupport.inputLabel()),
        suffixIcon:
            const Icon(Icons.arrow_drop_down, color: Colors.purple, size: 30),
      ),
      validator: (value) {
        if (isRequired && (value == null || value.isEmpty)) {
          return "Please Select Profession";
        }
        return null;
      },
    );
  }

  Widget _buildCivilStatusDropdown({
    required TextEditingController controller,
    required String label,
    bool isRequired = true,
  }) {
    return DropdownButtonFormField<String>(
      isExpanded: true,
      focusNode: genderFocusNode,
      value: controller.text.isNotEmpty ? controller.text : null,
      items: civilStatusList.map<DropdownMenuItem<String>>((item) {
        return DropdownMenuItem<String>(
          value: item['value']?.toString() ?? '',
          child: Text(
            item['value'] ?? '',
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        );
      }).toList(),

      /// Add padding to selected item
      selectedItemBuilder: (BuildContext context) {
        return civilStatusList.map<Widget>((item) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(
              item['value'] ?? '',
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          );
        }).toList();
      },

      onChanged: (String? newValue) {
        if (newValue != null) {
          controller.text = newValue;
        }
      },
      icon: const SizedBox.shrink(),
      decoration: InputDecoration(
        label: isRequired
            ? RichText(
                text: TextSpan(
                  text: label,
                  style: WidgetSupport.inputLabel(),
                  children: const [
                    TextSpan(
                        text: ' *',
                        style: TextStyle(color: Colors.red, fontSize: 25))
                  ],
                ),
              )
            : Text(label, style: WidgetSupport.inputLabel()),
        suffixIcon:
            const Icon(Icons.arrow_drop_down, color: Colors.purple, size: 30),
      ),
      validator: (value) {
        if (isRequired && (value == null || value.isEmpty)) {
          return "Please Select Civil Status";
        }
        return null;
      },
    );
  }

  Widget _buildNationalityDropdown({
    required TextEditingController controller,
    required String label,
    bool isRequired = true,
  }) {
    return DropdownButtonFormField<String>(
      isExpanded: true,
      focusNode: genderFocusNode,
      value: nationalityList
              .any((item) => item['value'] == nationality.text.trim())
          ? nationality.text.trim()
          : null,
      items: nationalityList.map((item) {
        return DropdownMenuItem<String>(
          value: item['value'],
          child: Text(item['value']),
        );
      }).toList(),
      selectedItemBuilder: (BuildContext context) {
        return nationalityList.map<Widget>((item) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(
              item['value'] ?? '',
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          );
        }).toList();
      },
      onChanged: (String? newValue) {
        if (newValue != null) {
          final selectedItem =
              nationalityList.firstWhere((item) => item['value'] == newValue);
          setState(() {
            controller.text = selectedItem['value'] ?? '';
            perm_countryCode.text = selectedItem['key'] ?? '';
            emp_countryCode.text = selectedItem['key'] ?? '';
            print(perm_countryCode.text);
            print(emp_countryCode.text);
          });
        }
      },
      icon: const SizedBox.shrink(),
      decoration: InputDecoration(
        label: isRequired
            ? RichText(
                text: TextSpan(
                  text: label,
                  style: WidgetSupport.inputLabel(),
                  children: const [
                    TextSpan(
                        text: ' *',
                        style: TextStyle(color: Colors.red, fontSize: 25))
                  ],
                ),
              )
            : Text(label, style: WidgetSupport.inputLabel()),
        suffixIcon:
            const Icon(Icons.arrow_drop_down, color: Colors.purple, size: 30),
      ),
      validator: (value) {
        if (isRequired && (value == null || value.isEmpty)) {
          return "Please Select Emp Nationality";
        }
        return null;
      },
    );
  }
}

class NoFocusNode extends FocusNode {
  @override
  bool get hasFocus => false;
}
