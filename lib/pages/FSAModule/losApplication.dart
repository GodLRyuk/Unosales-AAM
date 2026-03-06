import 'dart:convert';
import 'package:app_settings/app_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_datetime_picker_bdaya/flutter_datetime_picker_bdaya.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:hyperkyc_flutter/hyperkyc_result.dart';
import 'package:pointycastle/api.dart' hide Padding;
import 'package:pointycastle/random/fortuna_random.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unosfa/pages/FSAModule/LosApplicationModel.dart';
import 'package:unosfa/pages/FSAModule/fsaleaddashboard.dart';
import 'package:unosfa/pages/FSAModule/leadsByCampaign.dart';
import 'package:unosfa/pages/Form/FormList/daily_sales_report_list.dart';
import 'package:unosfa/pages/config/config.dart';
import 'package:intl/intl.dart';
import 'package:unosfa/pages/generalscreens/customNavigation.dart';
import 'package:unosfa/pages/otpscreens/otpConcent.dart';
import 'package:unosfa/pages/services/api_service.dart';
import 'package:unosfa/pages/services/transactionId.dart';
import 'package:unosfa/widgetSupport/widgetstyle.dart';
import 'package:crypto/crypto.dart';

class LosApplicationPage extends StatefulWidget {
  final String leadId;
  final String campaign;
  final String pagemode;
  final String dsrId;

  // New add
  final HyperKycResult? ekycResult;
  final dynamic customerDetails;
  final String? isandcampaign;

  const LosApplicationPage({
    super.key,
    required this.leadId,
    required this.campaign,
    required this.pagemode,
    required this.dsrId,

    // New add
    this.ekycResult, // For hyperverser data
    this.customerDetails,
    this.isandcampaign, // For ETB details
  });

  @override
  State<LosApplicationPage> createState() => _LosApplicationPageState();
}

enum IdType { tin, sss, gsis }

class _LosApplicationPageState extends State<LosApplicationPage> {
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
  final emp_Work_Exp = TextEditingController();
  final emp_position = TextEditingController();
  final ClientIP = TextEditingController();
  final disclaimerCheck = TextEditingController();

  // Done by 9/12/2025
  final issuingAuthority = TextEditingController();
  final address = TextEditingController();
  final documentType = TextEditingController();
  final validUntil = TextEditingController();
  final documentId = TextEditingController();
  // done
  
  bool _isChecked = false;
  String IpAddress = "";
  String latitude = "";
  String longitude = "";
  IdType? _selectedIdType;
  //bool EmpStatus = false;
  bool EmpStatus = true;
  Map<String, dynamic> leadDetails = {}; // To store the lead details
  bool _isLoading = false;
  bool _isFieldFocused = false;
  TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    _loadData();
    if (widget.pagemode == "edit" || widget.pagemode == 'view') {
      fetchLeadDetails();
    }

    _ComIdOptions = {};
    super.initState();
    if (widget.pagemode == "fromDSR") {
      setDsrdata();
    }

    if (widget.pagemode == "fromHYPERVERSER") {
      setHyperverserData();
    }

    if (widget.pagemode == "fromETBStartFresh") {
      setEtbFreshCandidate();
    }

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
  late List<Map<String, String>> _filteredCompanies; // Store filtered companies
  late Map<String, String> _ComIdOptions; // Store the fetched companies
  String? _selectedCompany;
  bool _showOtherCompanyField = false;
  final _otherCompanyController = TextEditingController();
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

  Future<void> _loadData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('accessToken');
    String? refresh = prefs.getString('refreshToken');
    try {
      String url = '/api/leads/companies/?page_size=10';
      final headers = {
        'Authorization': 'Bearer $token',
        'User-Agent':
            'Mozilla/5.0 (Linux; Android 11; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36',
      };
      final response = await ApiService.getWithHeaders(url, headers);
      if (response != null) {
        if (response.statusCode == 200) {
          final Map<String, dynamic> data = json.decode(response.body);
          if (data['results'] != null && data['results'] is List) {
            List<dynamic> companies = data['results'];

            Map<String, String> fetchedData = {};
            for (var item in companies) {
              fetchedData[item['id'].toString()] =
                  item['company_name'].toString();
            }

            setState(() {
              _ComIdOptions = fetchedData;
              _filteredCompanies = fetchedData.entries
                  .map((e) => {'id': e.key, 'company_name': e.value})
                  .toList();

              // Append "Others" option
              _filteredCompanies
                  .add({'id': 'others', 'company_name': 'Others'});
            });
            // print(_ComIdOptions);
          }
        } else if (response.statusCode == 401) {
          SharedPreferences prefs = await SharedPreferences.getInstance();
          Map<String, String> mappedData = {
            'refresh': refresh ?? '',
          };
          String refressToken = '/api/users/token-refresh/';
          final response2 = await ApiService.post(refressToken, mappedData);
          if (response2 != null) {
            final data = json.decode(response2.body);
            await prefs.setBool('isLoggedIn', true);
            await prefs.setString('accessToken', data['access']);
            await prefs.setString('refreshToken', data['refresh']);
            _loadData();
          }
        } else {
          throw Exception('Failed to load companies');
        }
      }
    } catch (e) {
      print('Error: $e');
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

  Future<void> _searchCompanyGetDSR(String query) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (query.isEmpty) {
      setState(() {
        _filteredCompanies = _ComIdOptions.entries
            .map((e) => {'id': e.key, 'company_name': e.value})
            .toList();

        // Append "Others" option
        _filteredCompanies.add({'id': 'others', 'company_name': 'Others'});
      });
      return;
    }
    try {
      String url = '/api/leads/companies/?search=$query';
      final headers = await _getAuthHeader();
      final response = await ApiService.getWithHeaders(url, headers);

      if (response != null) {
        if (response.statusCode == 200) {
          // Your API is returning a single company object, not a list
          final Map<String, dynamic> data = json.decode(response.body);

          // Directly use the API response instead of _ComIdOptions
          if (data.containsKey('id')) {
            final companyId = data['id'].toString();
            final companyName = data['company_name'].toString();

            setState(() {
              _searchController.text = companyName;
              emp_Employer_Name.text = companyName;
              _selectedCompany = companyName;
            });
          }

          // If your API also returns a 'results' list, you can still handle it
          if (data['results'] != null && data['results'] is List) {
            List<dynamic> companies = data['results'];
            setState(() {
              _filteredCompanies = companies
                  .map((e) => {
                        'id': e['id'].toString(),
                        'company_name': e['company_name'].toString(),
                      })
                  .toList();

              // Append "Others" option
              _filteredCompanies
                  .add({'id': 'others', 'company_name': 'Others'});
            });
          }
        } else if (response.statusCode == 401) {
          String? refresh = prefs.getString('refreshToken');
          Map<String, String> mappedData = {
            'refresh': refresh ?? '',
          };
          String refressToken = '/api/users/token-refresh/';
          final response2 = await ApiService.post(refressToken, mappedData);
          if (response2 != null) {
            final data = json.decode(response2.body);
            await prefs.setBool('isLoggedIn', true);
            await prefs.setString('accessToken', data['access']);
            await prefs.setString('refreshToken', data['refresh']);
            _searchCompany(query);
          }
        } else {
          throw Exception('Failed to search companies');
        }
      }
    } catch (e) {
      print('Search Error: $e');
    }
  }

  void _searchCompany(String companyId) {
    // companyId here is the ID from the search result or API
    if (_ComIdOptions.containsKey(companyId)) {
      setState(() {
        // store the ID internally
        _selectedCompany = companyId;

        // show the name in the textfield
        _searchController.text = _ComIdOptions[companyId] ?? '';
      });
    } else {
      // no match found
      print('Company ID not found');
    }
  }

  Future<Map<String, String>> _getAuthHeader() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('accessToken');
    return {'Authorization': 'Bearer $token'};
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
      final response = await http.get(
        Uri.parse(
            '${AppConfig.dynamicBaseUrl}/api/campaigns/${widget.campaign}/leads/${widget.leadId}/'), // Using leadId in the API URL
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'multipart/form-data',
          'User-Agent':
              'Mozilla/5.0 (Linux; Android 11; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36',
        },
      );
      if (response.statusCode == 200) {
        setState(() {
          leadDetails = json.decode(response.body);
          print("lead details is this........");
          // String jsonString = jsonEncode(leadDetails);
          // for (int i = 0; i < jsonString.length; i += 1000) {
          //   print(jsonString.substring(i,
          //       (i + 1000 > jsonString.length) ? jsonString.length : i + 1000));
                
          // }
          //****************************************************** */
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
        Map<String, dynamic> mappedData = {
          'refresh': refresh,
        };
        final response2 = await http.post(
          Uri.parse(
              '${AppConfig.dynamicBaseUrl}/api/users/token-refresh/'), // Using leadId in the API URL
          body: mappedData,
        );
        final data = json.decode(response2.body);
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

  Future<void> setDsrdata() async {
    setState(() {
      _isLoading = true;
    });
    // getCurrentLocation(context);
    // getPublicIP();\
    // _initializeSourceFundList();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('accessToken');
    String? refresh = prefs.getString('refreshToken');
    userInfo = prefs.getStringList('userInfo');
    try {
      final response = await http.get(
        Uri.parse(
            '${AppConfig.dynamicBaseUrl}/api/timesheet/agent-daily-sales/${widget.dsrId}/'), // Using leadId in the API URL
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'User-Agent':
              'Mozilla/5.0 (Linux; Android 11; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36',
        },
      );
      if (response.statusCode == 200) {
        setState(() {
          leadDetails = json.decode(response.body);
          // String jsonString = jsonEncode(leadDetails);
          // for (int i = 0; i < jsonString.length; i += 1000) {
          //   print(jsonString.substring(i,
          //       (i + 1000 > jsonString.length) ? jsonString.length : i + 1000));
          // }
          firstName.text = leadDetails['first_name'] ?? "";
          lastName.text = leadDetails['last_name'] ?? "";
          middlename.text = leadDetails['middle_name'] ?? "";
          mobilePhone.text = leadDetails['phone_number'].substring(2) ?? "";
          email.text = leadDetails['email'] ?? "";
          // Permanent Address
          perm_State.text = leadDetails['province'] ?? "";
          perm_City.text = leadDetails['city'] ?? "";
          perm_Street.text = leadDetails['house_street'] ?? "";
          perm_ZipCode.text = leadDetails['zip_code'] ?? "";
          getZipCodeEntered(leadDetails['zip_code']);
          perm_Barangay.text = leadDetails['barangay'] ?? "";
          setState(() {
            _selectedBarangay = leadDetails['barangay'];
          });
          perm_Region.text = leadDetails['region'] ?? "";
          fin_Mthly_Income.text = leadDetails['monthly_income'] ?? "";
          String employerId = leadDetails['employer'].toString();

          if (employerId.isEmpty ||
              employerId.trim().isEmpty ||
              employerId == "null") {
            setState(() {
              _showOtherCompanyField = true;
              _selectedCompany = 'others'; // 👈 mark dropdown as "Others"
              _searchController.text = 'Others';
              _otherCompanyController.text = leadDetails['other_employer'];
            });
          } else {
            setState(() {
              _showOtherCompanyField = false;
              _selectedCompany = employerId;
              _searchCompanyGetDSR(employerId);
            });
          }
          setState(() {
            // print(leadDetails['employer']);
            // print(_ComIdOptions);
            // _searchController is the TextField controller
            // If the ID exists, set the corresponding company name
            // print("null check start");
            // _searchController.text = _ComIdOptions[employerId]!;
            // emp_Employer_Name.text = _ComIdOptions[employerId]!;
            // print(emp_Employer_Name.text);
            // print("null check start2");

            // _selectedCompany =
            //     _ComIdOptions[employerId]!; // optional, if you track selection

            // print("null check start3");

            identity_TinId.text = leadDetails['tin_id'] ?? "";
            identity_GsisID.text = leadDetails['gsis_id'] ?? "";
            identity_SssID.text = leadDetails['sss_id'] ?? "";

            // Auto-select the ID type based on which field is filled
            if (identity_TinId.text.isNotEmpty) {
              _selectedIdType = IdType.tin;
            } else if (identity_SssID.text.isNotEmpty) {
              _selectedIdType = IdType.sss;
            } else if (identity_GsisID.text.isNotEmpty) {
              _selectedIdType = IdType.gsis;
            } else {
              _selectedIdType = null; // or default value
            }
          });

          emp_Indus_Type.text = leadDetails['industry_type'] ?? "";
          emp_Indus_Type_Code.text = leadDetails['industry_code'] ?? "";

          Future.delayed(Duration(seconds: 10), () {
            setState(() {
              _isLoading = false; // Data loaded after 5 seconds
            });
          });
        });
      } else if (response.statusCode == 401) {
        Map<String, dynamic> mappedData = {
          'refresh': refresh,
        };
        final response2 = await http.post(
          Uri.parse(
              '${AppConfig.dynamicBaseUrl}/api/users/token-refresh/'), // Using leadId in the API URL
          body: mappedData,
        );
        final data = json.decode(response2.body);
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
    Map<String, dynamic> mappedData = {
      'refresh': refresh,
    };
    final response2 = await http.post(
      Uri.parse('${AppConfig.dynamicBaseUrl}/api/users/token-refresh/'),
      body: mappedData,
    );
    final data = json.decode(response2.body);
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

      final tokenResponse = await http.get(
        Uri.parse('${AppConfig.dynamicBaseUrl}/api/leads/los-access-token/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'multipart/form-data',
          'User-Agent':
              'Mozilla/5.0 (Linux; Android 11; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36',
        },
      );

      final tokenData = json.decode(tokenResponse.body);
      tokens = tokenData['access_token'];
    } catch (e) {
      print("HTTP Request Failed: $e");
    }

    try {
      final response = await http.post(
        Uri.parse('${AppConfig.otpUrl}/api/app/address'),
        headers: {
          'Authorization': 'Bearer $tokens',
          'Content-Type': 'application/json',
          'Idempotency-Key': 'sfsggdhsdgdgdg',
          'User-Agent':
              'Mozilla/5.0 (Linux; Android 11; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36',
        },
        body: jsonEncode({"zipcode": "$zipCode"}),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          perm_Region.text = data['region'];
          perm_State.text = data['province'];
          perm_City.text = data['cityMunicipality'];
        });

        final Map<String, dynamic> responseBody = jsonDecode(response.body);
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

      final tokenResponse = await http.get(
        Uri.parse('${AppConfig.dynamicBaseUrl}/api/leads/los-access-token/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'multipart/form-data',
          'User-Agent':
              'Mozilla/5.0 (Linux; Android 11; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36',
        },
      );

      final tokenData = json.decode(tokenResponse.body);
      tokens = tokenData['access_token'];
    } catch (e) {
      print("HTTP Request Failed: $e");
    }

    try {
      final response = await http.post(
        Uri.parse('${AppConfig.otpUrl}/api/app/address'),
        headers: {
          'Authorization': 'Bearer $tokens',
          'Content-Type': 'application/json',
          'Idempotency-Key': 'sfsggdhsdgdgdg',
        },
        body: jsonEncode({"zipcode": "$zipCode"}),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          perm_Region.text = data['region'];
          perm_State.text = data['province'];
          perm_City.text = data['cityMunicipality'];
        });

        final Map<String, dynamic> responseBody = jsonDecode(response.body);
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

  Future<void> getZipCodeEntered(String zipCode) async {
    String tokens = "";

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('accessToken');

      final tokenResponse = await http.get(
        Uri.parse('${AppConfig.dynamicBaseUrl}/api/leads/los-access-token/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'multipart/form-data',
          'User-Agent':
              'Mozilla/5.0 (Linux; Android 11; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36',
        },
      );

      final tokenData = json.decode(tokenResponse.body);
      tokens = tokenData['access_token'];
    } catch (e) {
      print("HTTP Request Failed: $e");
    }

    try {
      final response = await http.post(
        Uri.parse('${AppConfig.otpUrl}/api/app/address'),
        headers: {
          'Authorization': 'Bearer $tokens',
          'Content-Type': 'application/json',
          'Idempotency-Key': 'sfsggdhsdgdgdg',
        },
        body: jsonEncode({"zipcode": "$zipCode"}),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          perm_Region.text = data['region'];
          perm_State.text = data['province'];
          perm_City.text = data['cityMunicipality'];
        });

        final Map<String, dynamic> responseBody = jsonDecode(response.body);
        if (responseBody['barangays'] is List &&
            responseBody['barangays'].isNotEmpty) {
          final barangays = responseBody['barangays'];

          if (barangays is List) {
            setState(() {
              PermbarangayList = List<String>.from(barangays);
              if (widget.pagemode == "fromDSR") {
                _selectedBarangay = _selectedBarangay;
                // perm_Barangay.text = '';
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

      final tokenResponse = await http.get(
        Uri.parse('${AppConfig.dynamicBaseUrl}/api/leads/los-access-token/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'multipart/form-data',
          'User-Agent':
              'Mozilla/5.0 (Linux; Android 11; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36',
        },
      );

      final tokenData = json.decode(tokenResponse.body);
      tokens = tokenData['access_token'];
    } catch (e) {
      print("HTTP Request Failed: $e");
    }
    try {
      final response = await http.post(
        Uri.parse('${AppConfig.otpUrl}/api/app/address'),
        headers: {
          'Authorization': 'Bearer $tokens',
          'Content-Type': 'application/json',
          'Idempotency-Key': 'sfsggdhsdgdgdg',
          'User-Agent':
              'Mozilla/5.0 (Linux; Android 11; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36',
        },
        body: jsonEncode({"zipcode": "$zipCode"}),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        setState(() {
          emp_Region.text = data['region'];
          emp_State.text = data['province'];
          emp_City.text = data['cityMunicipality'];
        });

        final Map<String, dynamic> responseBody = jsonDecode(response.body);

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

      final tokenResponse = await http.get(
        Uri.parse('${AppConfig.dynamicBaseUrl}/api/leads/los-access-token/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'multipart/form-data',
          'User-Agent':
              'Mozilla/5.0 (Linux; Android 11; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36',
        },
      );

      final tokenData = json.decode(tokenResponse.body);
      tokens = tokenData['access_token'];
    } catch (e) {
      print("HTTP Request Failed: $e");
    }

    try {
      final response = await http.post(
        Uri.parse('${AppConfig.otpUrl}/api/app/address'),
        headers: {
          'Authorization': 'Bearer $tokens',
          'Content-Type': 'application/json',
          'Idempotency-Key': 'sfsggdhsdgdgdg',
        },
        body: jsonEncode({"zipcode": "$zipCode"}),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        setState(() {
          emp_Region.text = data['region'];
          emp_State.text = data['province'];
          emp_City.text = data['cityMunicipality'];
        });

        final Map<String, dynamic> responseBody = jsonDecode(response.body);

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

      final tokenResponse = await http.get(
        Uri.parse('${AppConfig.dynamicBaseUrl}/api/leads/los-access-token/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'multipart/form-data',
          'User-Agent':
              'Mozilla/5.0 (Linux; Android 11; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36',
        },
      );

      

      if (tokenResponse.statusCode != 200) {
        throw Exception('Failed to fetch LOS access token');
      }

      final tokenData = json.decode(tokenResponse.body);
      tokens = tokenData['access_token'];

      final response = await http.post(
        Uri.parse('${AppConfig.otpUrl}/api/app/fetch/LOV/details'),
        headers: {
          'Authorization': 'Bearer $tokens',
          'Content-Type': 'application/json',
          'Idempotency-Key': 'sfsggdhsdgdgdg',
          'User-Agent':
              'Mozilla/5.0 (Linux; Android 11; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36',
        },
        body: jsonEncode({
          "filters": [
            {"id": "3"}
          ]
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseBody = jsonDecode(response.body);

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

      final tokenResponse = await http.get(
        Uri.parse('${AppConfig.dynamicBaseUrl}/api/leads/los-access-token/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'multipart/form-data',
          'User-Agent':
              'Mozilla/5.0 (Linux; Android 11; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36',
        },
      );

      final tokenData = json.decode(tokenResponse.body);
      tokens = tokenData['access_token'];
    } catch (e) {
      print("HTTP Request Failed: $e");
    }
    final response = await http.post(
      Uri.parse('${AppConfig.otpUrl}/api/app/fetch/LOV/details'),
      headers: {
        'Authorization': 'Bearer $tokens',
        'Content-Type': 'application/json',
        'Idempotency-Key': 'sfsggdhsdgdgdg',
        'User-Agent':
            'Mozilla/5.0 (Linux; Android 11; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36',
      },
      body: jsonEncode({
        "filters": [
          {"id": "20"}
        ]
      }),
    );

    try {
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseBody = jsonDecode(response.body);

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

      final tokenResponse = await http.get(
        Uri.parse('${AppConfig.dynamicBaseUrl}/api/leads/los-access-token/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'multipart/form-data',
          'User-Agent':
              'Mozilla/5.0 (Linux; Android 11; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36',
        },
      );

      final tokenData = json.decode(tokenResponse.body);
      tokens = tokenData['access_token'];
    } catch (e) {
      print("HTTP Request Failed: $e");
    }
    try {
      final response = await http.post(
        Uri.parse('${AppConfig.otpUrl}/api/app/fetch/LOV/details'),
        headers: {
          'Authorization': 'Bearer $tokens',
          'Content-Type': 'application/json',
          'Idempotency-Key': 'sfsggdhsdgdgdg',
          'User-Agent':
              'Mozilla/5.0 (Linux; Android 11; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36',
        },
        body: jsonEncode({
          "filters": [
            {"id": "9"}
          ]
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseBody = jsonDecode(response.body);

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

      final tokenResponse = await http.get(
        Uri.parse('${AppConfig.dynamicBaseUrl}/api/leads/los-access-token/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'multipart/form-data',
          'User-Agent':
              'Mozilla/5.0 (Linux; Android 11; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36',
        },
      );

      final tokenData = json.decode(tokenResponse.body);
      tokens = tokenData['access_token'];
    } catch (e) {
      print("HTTP Request Failed: $e");
    }
    try {
      final response = await http.post(
        Uri.parse('${AppConfig.otpUrl}/api/app/fetch/LOV/details'),
        headers: {
          'Authorization': 'Bearer $tokens',
          'Content-Type': 'application/json',
          'Idempotency-Key': 'sfsggdhsdgdgdg',
          'User-Agent':
              'Mozilla/5.0 (Linux; Android 11; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36',
        },
        body: jsonEncode({
          "filters": [
            {"id": "8"}
          ]
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseBody = jsonDecode(response.body);

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

      final tokenResponse = await http.get(
        Uri.parse('${AppConfig.dynamicBaseUrl}/api/leads/los-access-token/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'multipart/form-data',
          'User-Agent':
              'Mozilla/5.0 (Linux; Android 11; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36',
        },
      );

      final tokenData = json.decode(tokenResponse.body);
      tokens = tokenData['access_token'];
    } catch (e) {
      print("HTTP Request Failed: $e");
    }
    try {
      final response = await http.post(
        Uri.parse('${AppConfig.otpUrl}/api/app/fetch/LOV/details'),
        headers: {
          'Authorization': 'Bearer $tokens',
          'Content-Type': 'application/json',
          'Idempotency-Key': 'sfsggdhsdgdgdg',
          'User-Agent':
              'Mozilla/5.0 (Linux; Android 11; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36',
        },
        body: jsonEncode({
          "filters": [
            {"id": "1"}
          ]
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseBody = jsonDecode(response.body);

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

      final tokenResponse = await http.get(
        Uri.parse('${AppConfig.dynamicBaseUrl}/api/leads/los-access-token/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'multipart/form-data',
          'User-Agent':
              'Mozilla/5.0 (Linux; Android 11; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36',
        },
      );

      final tokenData = json.decode(tokenResponse.body);
      tokens = tokenData['access_token'];
    } catch (e) {
      print("HTTP Request Failed: $e");
    }
    try {
      final response = await http.post(
        Uri.parse('${AppConfig.otpUrl}/api/app/fetch/LOV/details'),
        headers: {
          'Authorization': 'Bearer $tokens',
          'Content-Type': 'application/json',
          'Idempotency-Key': 'sfsggdhsdgdgdg',
          'User-Agent':
              'Mozilla/5.0 (Linux; Android 11; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36',
        },
        body: jsonEncode({
          "filters": [
            {"id": "22"}
          ]
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseBody = jsonDecode(response.body);

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

      final tokenResponse = await http.get(
        Uri.parse('${AppConfig.dynamicBaseUrl}/api/leads/los-access-token/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'multipart/form-data',
          'User-Agent':
              'Mozilla/5.0 (Linux; Android 11; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36',
        },
      );

      final tokenData = json.decode(tokenResponse.body);
      tokens = tokenData['access_token'];
    } catch (e) {
      print("HTTP Request Failed: $e");
    }
    try {
      final response = await http.post(
        Uri.parse('${AppConfig.otpUrl}/api/app/fetch/LOV/details'),
        headers: {
          'Authorization': 'Bearer $tokens',
          'Content-Type': 'application/json',
          'Idempotency-Key': 'sfsggdhsdgdgdg',
          'User-Agent':
              'Mozilla/5.0 (Linux; Android 11; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36',
        },
        body: jsonEncode({
          "filters": [
            {"id": "11"}
          ]
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseBody = jsonDecode(response.body);

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

      final tokenResponse = await http.get(
        Uri.parse('${AppConfig.dynamicBaseUrl}/api/leads/los-access-token/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'multipart/form-data',
          'User-Agent':
              'Mozilla/5.0 (Linux; Android 11; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36',
        },
      );

      final tokenData = json.decode(tokenResponse.body);
      tokens = tokenData['access_token'];
    } catch (e) {
      print("HTTP Request Failed: $e");
    }
    try {
      final response = await http.post(
        Uri.parse('${AppConfig.otpUrl}/api/app/fetch/LOV/details'),
        headers: {
          'Authorization': 'Bearer $tokens',
          'Content-Type': 'application/json',
          'Idempotency-Key': 'sfsggdhsdgdgdg',
          'User-Agent':
              'Mozilla/5.0 (Linux; Android 11; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36',
        },
        body: jsonEncode({
          "filters": [
            {"id": "18"}
          ]
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseBody = jsonDecode(response.body);

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

      final tokenResponse = await http.get(
        Uri.parse('${AppConfig.dynamicBaseUrl}/api/leads/los-access-token/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'multipart/form-data',
          'User-Agent':
              'Mozilla/5.0 (Linux; Android 11; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36',
        },
      );

      final tokenData = json.decode(tokenResponse.body);
      tokens = tokenData['access_token'];
    } catch (e) {
      print("HTTP Request Failed: $e");
    }
    try {
      final response = await http.post(
        Uri.parse('${AppConfig.otpUrl}/api/app/fetch/LOV/details'),
        headers: {
          'Authorization': 'Bearer $tokens',
          'Content-Type': 'application/json',
          'Idempotency-Key': 'sfsggdhsdgdgdg',
          'User-Agent':
              'Mozilla/5.0 (Linux; Android 11; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36',
        },
        body: jsonEncode({
          "filters": [
            {"id": "15"}
          ]
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseBody = jsonDecode(response.body);

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

      final tokenResponse = await http.get(
        Uri.parse('${AppConfig.dynamicBaseUrl}/api/leads/los-access-token/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'multipart/form-data',
          'User-Agent':
              'Mozilla/5.0 (Linux; Android 11; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36',
        },
      );

      final tokenData = json.decode(tokenResponse.body);
      tokens = tokenData['access_token'];
    } catch (e) {
      print("HTTP Request Failed: $e");
    }
    try {
      final response = await http.post(
        Uri.parse('${AppConfig.otpUrl}/api/app/fetch/LOV/details'),
        headers: {
          'Authorization': 'Bearer $tokens',
          'Content-Type': 'application/json',
          'Idempotency-Key': 'sfsggdhsdgdgdg',
          'User-Agent':
              'Mozilla/5.0 (Linux; Android 11; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36',
        },
        body: jsonEncode({
          "filters": [
            {"id": "4"}
          ]
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseBody = jsonDecode(response.body);

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

      final tokenResponse = await http.get(
        Uri.parse('${AppConfig.dynamicBaseUrl}/api/leads/los-access-token/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'multipart/form-data',
          'User-Agent':
              'Mozilla/5.0 (Linux; Android 11; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36',
        },
      );

      final tokenData = json.decode(tokenResponse.body);
      tokens = tokenData['access_token'];
    } catch (e) {
      print("HTTP Request Failed: $e");
    }
    try {
      final response = await http.post(
        Uri.parse('${AppConfig.otpUrl}/api/lov/mapping/sequence'),
        headers: {
          'Authorization': 'Bearer $tokens',
          'Content-Type': 'application/json',
          'Idempotency-Key': 'sfsggdhsdgdgdg',
          'User-Agent':
              'Mozilla/5.0 (Linux; Android 11; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36',
        },
        body: jsonEncode({
          "category": "Source_of_Fund",
          "empStatusId": emp_Status_Code.text.replaceFirst(RegExp(r'^0+'), ''),
          "nowId": emp_Work_Nature_Code.text.replaceFirst(RegExp(r'^0+'), ''),
          "positionId": emp_position.text.replaceFirst(RegExp(r'^0+'), ''),
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseBody = jsonDecode(response.body);

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

  // For hyperverser use method

  Future<void> setHyperverserData() async {
    final details = widget.ekycResult?.details;

    setState(() {
      firstName.text = details?['ocr_firstName']?.trim() ?? '';
      middlename.text = details?['ocr_middleName']?.trim() ?? '';
      lastName.text = details?['ocr_lastName']?.trim() ?? '';

      if (details?['ocr_gender'] == "M") {
        gender.text = "Male";
      } else {
        gender.text = "Female";
      }
      birthDate.text = details?['ocr_dateOfBirth']?.trim() ?? '';
      issuingAuthority.text="";
      address.text=details?['ocr_address']?? '';
      documentType.text=details?['ocr_documentId']?? '';
      validUntil.text=details?['ocr_dateOfExpiry']?? '';
      documentId.text=details?['ocr_documentId']?? '';

    });
  }

  // ***************** ETB FRESH APPLICATION ********************
  Future<void> setEtbFreshCandidate() async {
    final etbDetails = widget.customerDetails;

    if (etbDetails is List && etbDetails.isNotEmpty) {
      final customer = etbDetails[0];
      final address = customer['addresses']?[0]; 
      final empAddress = customer['_Emp_Address'];
      final iddocuments = customer['idDocuments']?[0];
      final empMonthlyIncome = customer['_Fin_Details'];
      final empDetails = customer['_Emp_Details'];

      setState(() {
        firstName.text = customer['firstName']?.trim() ?? '';
        lastName.text = customer['lastName']?.trim() ?? '';
        middlename.text = customer['middleName'] ?? "";
        mobilePhone.text = customer['mobilePhone'].substring(2) ?? "";
        email.text = customer['emailAddress'] ?? "";
        birthDate.text = customer['birthDate'] ?? "";

        if (customer?['gender'] == "M") {
          gender.text = "Male";
        } else {
          gender.text = "Female";
        }

        // address
        perm_ZipCode.text = address?['postcode'] ?? "";
        perm_Street.text = address?['line1'] ?? "";

        // document
        documentType.text = iddocuments?['documentType'] ?? "";
        documentId.text = iddocuments?['documentId'] ?? "";

        //Employee monthly income
        fin_Mthly_Income.text = empMonthlyIncome?['fin_Mthly_Income'] ?? "";
      });

      // zip function customer
      if (address != null && address['postcode'] != null) {
        await onZipCodeEntered(address['postcode']);
      }

      // zip for employee
      if(empAddress != null && empAddress['emp_ZipCode'] != null)
      {
        await  onEmpZipCodeEntered(address['emp_ZipCode']);
      }

      // employee work nature   

      if (empDetails != null && empDetails['emp_Work_Nature_Code'] != null) {
          String code = empDetails['emp_Work_Nature_Code'].toString();

          final selectedItem = empWorkNatureList.firstWhere(
            (item) => item['key'] == code,
            orElse: () => {},
          );

          setState(() {
            emp_Work_Nature_Code.text = code;
            emp_Work_Nature.text = selectedItem['value'] ?? '';
            
            
          });
      }

    }
  }
  // *************** done  **********************

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
                        builder: (context) => DailySalesReportList(
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
                              _buildTextField(
                                firstName,
                                "First Name",
                                "Please Enter First Name",
                                "firstName",
                                isRequired: true,
                                readOnly: (widget.pagemode == "fromDSR")
                                    ? true
                                    : false,
                              ),
                              SizedBox(height: 6),
                              _buildTextField(
                                middlename,
                                "Middle name",
                                "Please Enter Middle Name",
                                "middlename",
                                isRequired: false,
                                readOnly: (widget.pagemode == "fromDSR" )
                                    ? true
                                    : false,
                              ),
                              SizedBox(height: 6),
                              _buildTextField(
                                lastName,
                                "Last Name",
                                "Please Enter Last Name",
                                "lastName",
                                isRequired: true,
                                readOnly: (widget.pagemode == "fromDSR" )
                                    ? true
                                    : false,
                              ),
                              SizedBox(height: 6),
                              _buildMobileTextField(
                                controller: mobilePhone,
                                isPhoneNumber: true,
                                readOnly: (widget.pagemode == "fromDSR" )
                                    ? true
                                    : false,
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
                              _buildTextField(
                                email,
                                "Email Address",
                                "Please Enter Email Address",
                                "email",
                                isRequired: true,
                                readOnly:
                                    widget.pagemode == "fromDSR" ? true : false,
                              ),
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
                                "Zip Code",
                                "Please Enter Zip Code",
                                "perm_ZipCode",
                                isRequired: true,
                                isZip: true,
                                readOnly:
                                    widget.pagemode == "fromDSR" ? true : false,
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
                                label: "Select Barangay",
                                readOnly:
                                    widget.pagemode == "fromDSR" ? true : false,
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
                                readOnly: (widget.pagemode == "fromDSR" )
                                    ? true
                                    : false,
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
                      title: Text("Employer Details",
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
                                label: "Select Status",
                              ),
                              SizedBox(height: 6),
                              _buildEmpWorkNatureDropdown(
                                controller: emp_Work_Nature,
                                label: "Select Emp Work Nature",
                              ),
                              SizedBox(height: 6),
                              _buildPositionDropdown(
                                controller: emp_position,
                                label: "Select Emp Position",
                              ),
                              SizedBox(height: 6),
                              _buildWorkExpDropdown(
                                controller: emp_Mths_In_Cur_Comp,
                                label: "Work Experience",
                              ),
                              if (EmpStatus == true)
                                _buildEmpPrefessionDropdown(
                                  controller: profession,
                                  label: "Select Emp Profession",
                                ),
                              SizedBox(height: 6),
                              // _buildTextField(
                              //   emp_Employer_Name,
                              //   "Employers Name",
                              //   "Please Enter Employers Name",
                              //   "emp_Employer_Name",
                              //   isRequired: true,
                              // ),
                              Padding(
                                padding: EdgeInsets.all(0.0),
                                child: Column(
                                  children: [
                                    // TextField for searching companies
                                    Focus(
                                      onFocusChange: (hasFocus) {
                                        setState(() {
                                          _isFieldFocused = hasFocus;
                                        });
                                      },
                                      child: TextField(
                                        controller: _searchController,
                                        enabled: widget.pagemode != "fromDSR",
                                        decoration: InputDecoration(
                                          contentPadding:
                                              EdgeInsets.only(left: 5),
                                          filled: true,
                                          fillColor:
                                              widget.pagemode == "fromDSR"
                                                  ? Colors.grey.shade200
                                                  : Colors.white,
                                          label: RichText(
                                            text: const TextSpan(
                                              text: 'Company',
                                              style: TextStyle(
                                                color: Colors.black,
                                                fontSize: 15,
                                              ),
                                              children: [
                                                TextSpan(
                                                  text: ' *',
                                                  style: TextStyle(
                                                      color: Colors.red,
                                                      fontSize: 20),
                                                ),
                                              ],
                                            ),
                                          ),
                                          suffixIcon: IconButton(
                                            icon: const Icon(Icons.search),
                                            onPressed: () {
                                              // Trigger the search when the search icon is pressed
                                              _searchCompanyGetDSR(
                                                  _searchController.text);
                                            },
                                          ),
                                        ),
                                        onChanged: (query) {
                                          if (query.isEmpty) {
                                            setState(() {
                                              _filteredCompanies =
                                                  _ComIdOptions.entries
                                                      .map((e) => {
                                                            'id': e.key,
                                                            'company_name':
                                                                e.value,
                                                          })
                                                      .toList();
                                            });
                                          }
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (_isFieldFocused)
                                Stack(
                                  children: [
                                    Positioned(
                                      child: Material(
                                        elevation: 4,
                                        borderRadius:
                                            BorderRadius.circular(8.0),
                                        child: Container(
                                          height: 200,
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius:
                                                BorderRadius.circular(8.0),
                                          ),
                                          child: ListView.builder(
                                            itemCount:
                                                _filteredCompanies.length,
                                            itemBuilder: (context, index) {
                                              return ListTile(
                                                title: Text(
                                                    _filteredCompanies[index]
                                                        ['company_name']!),
                                                onTap: () {
                                                  // Set the selected company
                                                  setState(() {
                                                    _selectedCompany =
                                                        _filteredCompanies[
                                                            index]['id'];
                                                    _searchController.text =
                                                        _filteredCompanies[
                                                                index]
                                                            ['company_name']!;
                                                    _isFieldFocused = false;
                                                    _showOtherCompanyField =
                                                        _selectedCompany ==
                                                            'others';
                                                    emp_Employer_Name.text =
                                                        _filteredCompanies[
                                                                index]
                                                            ['company_name']!;
                                                  });
                                                },
                                              );
                                            },
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                              if (_showOtherCompanyField) ...[
                                Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 0.9),
                                  child: TextFormField(
                                    enabled: widget.pagemode != "fromDSR",
                                    controller: _otherCompanyController,
                                    decoration: InputDecoration(
                                      filled: true,
                                      fillColor: widget.pagemode == "fromDSR"
                                          ? Colors.grey.shade200
                                          : Colors.white,
                                      contentPadding: EdgeInsets.only(left: 10),
                                      hintText: "Enter company name",
                                    ),
                                    validator: (value) {
                                      if (value == null ||
                                          value.isEmpty ||
                                          _selectedCompany == 'others') {
                                        return 'Company name is required';
                                      }
                                      return null;
                                    },
                                    onChanged: (value) {},
                                  ),
                                ),
                              ],
                              _buildEmpIndusTypeDropdown(
                                controller: emp_Indus_Type,
                                label: "Industry Type",
                                readOnly:
                                    widget.pagemode == "fromDSR" ? true : false,
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
                                isRequired: true,
                                readOnly:
                                    widget.pagemode == "fromDSR" ? true : false,
                              ),
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
                                    child: AbsorbPointer(
                                      absorbing: widget.pagemode == "fromDSR"
                                          ? true
                                          : false,
                                      child: _buildRadioField<IdType>(
                                        value: IdType.tin,
                                        groupValue: _selectedIdType,
                                        onChanged: (val) => setState(
                                            () => _selectedIdType = val),
                                        label: "TIN ID",
                                        isRequired: false,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: AbsorbPointer(
                                      absorbing: widget.pagemode == "fromDSR"
                                          ? true
                                          : false,
                                      child: _buildRadioField<IdType>(
                                        value: IdType.sss,
                                        groupValue: _selectedIdType,
                                        onChanged: (val) => setState(
                                            () => _selectedIdType = val),
                                        label: "SSS ID",
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: AbsorbPointer(
                                      absorbing: widget.pagemode == "fromDSR"
                                          ? true
                                          : false,
                                      child: _buildRadioField<IdType>(
                                        value: IdType.gsis,
                                        groupValue: _selectedIdType,
                                        onChanged: (val) => setState(
                                            () => _selectedIdType = val),
                                        label: "GSIS ID",
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 6),
                              if (_selectedIdType == IdType.tin)
                                _buildTextField2(
                                    identity_TinId, "TIN Id", "identity_TinId",
                                    maxDigits: 9,
                                    isRequired: false,
                                    readOnly: widget.pagemode == "fromDSR"
                                        ? true
                                        : false),
                              if (_selectedIdType == IdType.sss)
                                _buildTextField2(
                                    identity_SssID, "SSS ID", "identity_SssID",
                                    maxDigits: 10,
                                    isRequired: false,
                                    readOnly: widget.pagemode == "fromDSR"
                                        ? true
                                        : false),
                              if (_selectedIdType == IdType.gsis)
                                _buildTextField2(identity_GsisID, "GSIS ID",
                                    "identity_GsisID",
                                    maxDigits: 11,
                                    isRequired: false,
                                    readOnly: widget.pagemode == "fromDSR"
                                        ? true
                                        : false),
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
                      title: Text("Employer Address",
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
                                label: "Select Barangay",
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
                  onPressed: () {
                    if (_isChecked) {
                      // validateAndSubmit();
                      bool valid = validateAndSubmit();
                      print("valid $valid");

                      if(!valid)
                      {
                        return;
                      }

                      


                      print("cw1");
                      print("id ${widget.ekycResult?.transactionId}");

                        String CWTransactionIdNo =
                            widget.ekycResult?.transactionId?.isNotEmpty == true
                                ? widget.ekycResult!.transactionId!
                                : generateSecureTransactionId();


                      print("cw4");                 

                      LosApplicationModel losData = LosApplicationModel(
                          firstName: firstName.text,
                          middleName: middlename.text,
                          lastName: lastName.text,
                          mobilePhone: mobilePhone.text,
                          birthDate: birthDate.text,
                          gender: gender.text,
                          email: email.text,
                          permState: perm_State.text,
                          permCity: perm_City.text,
                          permStreet: perm_Street.text,
                          permZipCode: perm_ZipCode.text,
                          permBarangay: perm_Barangay.text,
                          permRegion: perm_Region.text,
                          permCountryCode: perm_countryCode.text,
                          finMonthlyIncome: fin_Mthly_Income.text,
                          finSourceOfFunds: fin_Src_Of_Funds.text,
                          finSourceOfFundsCode: fin_Src_Of_Funds_Code.text,
                          tinId: identity_TinId.text,
                          sssId: identity_SssID.text,
                          gsisId: identity_GsisID.text,
                          empWorkNature: emp_Work_Nature.text,
                          empMonthsInCompany: emp_Mths_In_Cur_Comp.text,
                          empStatus: emp_Status.text,
                          empEmployerName: emp_Employer_Name.text,
                          empIndustryType: emp_Indus_Type.text,
                          empType: emp_Type.text,
                          empYearsInCompany: emp_Yrs_In_Cur_Comp.text,
                          empTypeCode: emp_Type_Code.text,
                          empStatusCode: emp_Status_Code.text,
                          empWorkNatureCode: emp_Work_Nature_Code.text,
                          empIndustryTypeCode: emp_Indus_Type_Code.text,
                          empEmail: emp_email.text,
                          profession: profession.text,
                          empStreet: emp_Street.text,
                          empState: emp_State.text,
                          empCity: emp_City.text,
                          empCountry: nationality.text,
                          empZipCode: emp_ZipCode.text,
                          empBarangay: emp_Barangay.text,
                          empRegion: emp_Region.text,
                          empCountryCode: nationality.text,
                          civilStatus: civil_Status.text,
                          nationality: nationality.text,
                          placeOfBirth: place_Of_Birth.text,
                          sourceCompany: sourceCompany.text,
                          agentCode: agentCode.text,
                          partnerName: partnerName.text,
                          natureOfPartnership: natureOfPartnership.text,
                          applicationNumber: CWTransactionIdNo,
                          cwTransactionID: CWTransactionIdNo,
                          empWorkExperience: emp_Work_Exp.text,
                          empPosition: emp_position.text,
                          clientIp: IpAddress,
                          isChecked: _isChecked,
                          ipAddress: IpAddress,
                          latitude: latitude,
                          longitude: longitude,
                          address:address.text.toString(),
                          documentType:documentType.text.toString(),
                          validUntil:validUntil.text.toString(),
                          documentId:documentId.text.toString(),
                          //selectedIdType: _selectedIdType,
                          empStatusFlag: EmpStatus,
                          leadDetails: leadDetails,
                          dsrId: widget.dsrId);

                      print("losData from model is coming ${CWTransactionIdNo}");
                      

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => Otpconcent(
                                phoneNumber: mobilePhone.text,
                                losData: losData,
                                campaign: "",
                                leadId: widget.leadId,
                                pagemode: "edit")),
                      );
                    } else {
                      return null;
                    }
                  },

                  //onPressed: _isChecked ? validateAndSubmit : null,
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

  // void _showValidationDialog(String message) {
  //   showDialog(
  //     context: context,
  //     builder: (context) => AlertDialog(
  //       title: const Text("Validation Error"),
  //       content: Text(message),
  //       actions: [
  //         TextButton(
  //           onPressed: () => Navigator.pop(context),
  //           child: const Text("OK"),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  // Newly Added

   void _showValidationDialog(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: Color(0xFF9a37ae),
              content: Text(message, style: TextStyle(fontSize: 15),)),
          );
  }



// newly added code
  bool validateAndSubmit() {
    // Basic required fields (client details)
    final nameRegex = RegExp(r"^[a-zA-Z\s]+$");
    final specialCharRegex =
        RegExp(r'''[!@#\$%\^&\*\(\)_\+\=\{\}\[\]:;"'<>,\.\?/\\|~`-]''');

    if (firstName.text.trim().isEmpty) {
      _showValidationDialog("Please enter First Name.");
      return false;
    } else if (!nameRegex.hasMatch(firstName.text.trim())) {
      _showValidationDialog("First Name must not contain special characters.");
      return false;
    }
    // Define a regex to detect special characters
    String middleName = middlename.text.trim();
    // Check if middle name is not empty and contains any special characters
    if (middleName.isNotEmpty && specialCharRegex.hasMatch(middleName)) {
      _showValidationDialog("Middle Name must not contain special characters.");
      return false;
    }
    if (lastName.text.trim().isEmpty) {
      _showValidationDialog("Please enter Last Name.");
      return false;
    } else if (!nameRegex.hasMatch(lastName.text.trim())) {
      _showValidationDialog("Last Name must not contain special characters.");
      return false;
    }

    if (mobilePhone.text.trim().isEmpty) {
      _showValidationDialog("Please enter Mobile Number.");
      return false;
    }
    if (mobilePhone.text.length != 10) {
      _showValidationDialog("Mobile number must be 10 digits.");
      return false;
    }
    if (birthDate.text.trim().isEmpty) {
      _showValidationDialog("Please select Birth Date.");
      return false;
    }

    if (gender.text.trim().isEmpty) {
      _showValidationDialog("Please select Gender.");
      return false;
    }
    if (email.text.trim().isEmpty) {
      _showValidationDialog("Please enter Email Address.");
      return false;
    }

    if (!_isValidEmail(email.text.trim())) {
      _showValidationDialog("Please enter a valid Email Address.");
      return false;
    }
    if (!RegExp(r"^[\w\.-]+@[\w\.-]+\.\w+$").hasMatch(email.text.trim())) {
      _showValidationDialog("Please enter a valid Email Address.");
      return false;
    }
    if (civil_Status.text.trim().isEmpty) {
      _showValidationDialog("Please select Civil Status.");
      return false;
    }

    if (nationality.text.trim().isEmpty) {
      _showValidationDialog("Please select Nationality.");
      return false;
    }
    if (place_Of_Birth.text.trim().isEmpty) {
      _showValidationDialog("Please enter Place of Birth.");
      return false;
    }

    // Address validation
    if (!_isValidStreet(perm_Street.text)) {
      _showValidationDialog(
          "Permanent Street must be at least 10 characters and 3 words.");
      return false;
    }
    if (!_isValidStreet(emp_Street.text)) {
      _showValidationDialog(
          "Employee Street must be at least 10 characters and 3 words.");
      return false;
    }

    // Work validation
    if (emp_position.text.trim().isEmpty) {
      _showValidationDialog("Please enter Position.");
      return false;
    }
    if (emp_Mths_In_Cur_Comp.text.isEmpty) {
      _showValidationDialog(
          "Please enter both Years and Months of Work Experience.");
      return false;
    }
    if (emp_Yrs_In_Cur_Comp.text.isEmpty) {
      _showValidationDialog(
          "Please enter both Years and Months of Work Experience.");
      return false;
    }

    if (perm_ZipCode.text.trim().isEmpty) {
      _showValidationDialog("Please enter Zip Code.");
      return false;
    } else if (!RegExp(r'^\d{4}$').hasMatch(perm_ZipCode.text.trim())) {
      _showValidationDialog("Zip Code must be exactly 4 digits.");
      return false;
    }
// Region
    if (perm_Region.text.trim().isEmpty) {
      _showValidationDialog("Please enter/select Region.");
      return false;
    }

// Province
    if (perm_State.text.trim().isEmpty) {
      _showValidationDialog("Please enter/select Province.");
      return false;
    }

// City
    if (perm_City.text.trim().isEmpty) {
      _showValidationDialog("Please enter/select City.");
      return false;
    }

// Barangay
    if (perm_Barangay.text.trim().isEmpty) {
      _showValidationDialog("Please select Barangay.");
     return false;
    }

// Street - Minimum 10 characters & 3 words
    if (!_isValidStreet(perm_Street.text)) {
      _showValidationDialog(
          "Street must be at least 10 characters and 3 words.");
      return false;
    }

    // ID Type & specific ID validations
    if (_selectedIdType == null) {
      _showValidationDialog("Please select an Identification ID Type.");
      return false;
    }
    // Employment Status
    if (emp_Status.text.trim().isEmpty) {
      _showValidationDialog("Please select Employment Status.");
      return false;
    }

// Work Nature
    if (emp_Work_Nature.text.trim().isEmpty) {
      _showValidationDialog("Please select Employment Work Nature.");
     return false;
    }

// Profession (if applicable)
    if (EmpStatus == true && profession.text.trim().isEmpty) {
      _showValidationDialog("Please select Profession.");
      return false;
    }

// Employer Name
// print("EMPLOYES ${emp_Employer_Name.text.trim()}");
//     if (emp_Employer_Name.text.trim().isEmpty) {
//       _showValidationDialog("Please enter Employer's Name.");
//       return;
//     } else if (!_isValidName(emp_Employer_Name.text)) {
//       _showValidationDialog(
//           "Employer's Name must not contain special characters or numbers.");
//       return;
//     }

// Industry Type
    if (emp_Indus_Type.text.trim().isEmpty) {
      _showValidationDialog("Please select Industry Type.");
      return false;
    }

// Employee Type
    if (emp_Type.text.trim().isEmpty) {
      _showValidationDialog("Please select Employee Type.");
      return false;
    }

// Employee Email
    if (emp_email.text.trim().isEmpty) {
      _showValidationDialog("Please enter Employee Email.");
      return false;
    } else if (!RegExp(r"^[\w\.-]+@[\w\.-]+\.\w+$")
        .hasMatch(emp_email.text.trim())) {
      _showValidationDialog("Please enter a valid Employee Email Address.");
      return false;
    }
    // Monthly Income
    if (fin_Mthly_Income.text.trim().isEmpty) {
      _showValidationDialog("Please enter Monthly Income.");
      return false;
    } else if (!_isValidIncome(fin_Mthly_Income.text)) {
      _showValidationDialog("Monthly Income must be a valid positive number.");
      return false;
    }

// Source of Funds
    if (fin_Src_Of_Funds.text.trim().isEmpty) {
      _showValidationDialog("Please select Source of Funds.");
      return false;
    }
    // Employment Zip Code - Required, 4 digits
    if (emp_ZipCode.text.trim().isEmpty) {
      _showValidationDialog("Please enter Employment Zip Code.");
      return false;
    } else if (!RegExp(r'^\d{4}$').hasMatch(emp_ZipCode.text.trim())) {
      _showValidationDialog("Employment Zip Code must be exactly 4 digits.");
      return false;
    }

// Region
    if (emp_Region.text.trim().isEmpty) {
      _showValidationDialog("Please enter/select Employment Region.");
      return false;
    }

// Province
    if (emp_State.text.trim().isEmpty) {
      _showValidationDialog("Please enter/select Employment Province.");
      return false;
    }

// City
    if (emp_City.text.trim().isEmpty) {
      _showValidationDialog("Please enter/select Employment City.");
      return false;
    }

// Barangay
    if (emp_Barangay.text.trim().isEmpty) {
      _showValidationDialog("Please select Employment Barangay.");
      return false;
    }

// Street - Minimum 10 characters & 3 words, no special characters
    if (!_isValidStreet(emp_Street.text)) {
      _showValidationDialog(
          "Employment Street must be at least 10 characters and 3 words with no special characters.");
     return false;
    }

    if (_selectedIdType == IdType.tin) {
      if (identity_TinId.text.trim().isEmpty) {
        _showValidationDialog("TIN ID cannot be blank.");
        return false;
      } else if (!_isValidIdtin(identity_TinId.text)) {
        _showValidationDialog("TIN ID must be 9 digits.");
       return false;
      }
    } else if (_selectedIdType == IdType.sss) {
      if (identity_SssID.text.trim().isEmpty) {
        _showValidationDialog("SSS ID cannot be blank.");
        return false;
      } else if (!_isValidIdsssid(identity_SssID.text)) {
        _showValidationDialog("SSS ID must be 10 digits.");
        return false;
      }
    } else if (_selectedIdType == IdType.gsis) {
      if (identity_GsisID.text.trim().isEmpty) {
        _showValidationDialog("GSIS ID cannot be blank.");
       return false;
      } else if (!_isValidIdGsisId(identity_GsisID.text)) {
        _showValidationDialog("GSIS ID must be 11 digits.");
        return false;
      }
    }

    return true;

    // All validations passed
    // FocusScope.of(context).unfocus();
    // submitLos();
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

 

 


  String convertMonthsToReadableFormat(String monthsStr) {
    int months = int.tryParse(monthsStr) ?? 0;
    int years = months ~/ 12;

    return "$years";
  }

  Future<void> postLoanCheck(Map<String, dynamic> requestData) async {
    
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
    final url = Uri.parse("${AppConfig.otpUrl}/partner/loans/check");
    final headers = {
      "Idempotency-Key": "th37per9-185d-4e22-83fb-18gf96g0g861",
      "Content-Type": "application/json",
      "Accept": "application/json",
      "Authorization": "Bearer $tokens",
      'User-Agent':
          'Mozilla/5.0 (Linux; Android 11; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36',
    };

    print("position 4");
    try {
      print("position 5dddd");
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
      if (response.statusCode == 201) {
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

          int retryCount = 0;
          Map<String, dynamic>? data;
          List<dynamic>? result;

          while (retryCount < 3) {
            final Statusresponse = await http.post(
              fetchStatusUrl,
              headers: fetchStatusHeaders,
              body: json.encode(mappedData),
            );

            await Future.delayed(const Duration(seconds: 2)); // 2-second delay

            if (Statusresponse.statusCode == 200) {
              data = json.decode(Statusresponse.body);
              result = data?['result'];
              if (result != null && result.isNotEmpty) {
                break; // Success, exit retry loop
              }
            }
            retryCount++;
          }

          Navigator.of(context).pop(); // close loader

          print("Result status is show like that $result");

          if (result == null || result.isEmpty) {
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return const AlertDialog(
                  title: Text("No Application Data"),
                  content: Text(
                      "The application status response returned null after retries."),
                );
              },
            );
            return;
          }

          var application = result[0]; // Safe to access now
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
              ..["declaration"] = true;
          } else {
            finalRequestData = Map<String, dynamic>.from(requestData)
              ..["lead_type"] = "fresh_lead"
              ..["declaration"] = true
              ..["dsr"] = "${widget.dsrId}";
          }

          final backendresponseLOS = await http.post(
            LosbackendStatusUrl,
            headers: headers3,
            body: json.encode(finalRequestData),
          );

          print(LosbackendStatusUrl);
          print(headers3);
          String jsonString = jsonEncode(finalRequestData);
          for (int i = 0; i < jsonString.length; i += 1000) {
            print(jsonString.substring(i,
                (i + 1000 > jsonString.length) ? jsonString.length : i + 1000));
          }

          if (backendresponseLOS.statusCode == 201) {
            final data = json.decode(backendresponseLOS.body);
            final LosBackendResponseUrl = Uri.parse(
                '${AppConfig.dynamicBaseUrl}/api/leads/los-details/${data['id']}/');
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
            final responseLOS = await http.patch(
              LosBackendResponseUrl,
              headers: headers4,
              body: json.encode(mappedResponseLOsData),
            );
          }

          if (application['offerStatus'] == "IN-PROGRESS") {
            print("position 11");
            checkApplicationStatusLoop(application);
          } else {
            print("position 12");
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
                            builder: (context) =>
                                LeadListByCampaign(campaign: widget.campaign),
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
        print("------------------");
        print(logUrl);
        print(headers);
        print(json.encode(logmappedData));
        final LogResponse = await http.post(
          logUrl,
          headers: headers,
          body: json.encode(logmappedData),
        );
        
        print(LogResponse.statusCode);
        print(LogResponse.body);
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
    Function(String)? onChanged,
    bool readOnly = false, // <-- dynamic from outside
  }) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly, // <-- important
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
      onChanged: onChanged,
      onFieldSubmitted: onSubmitted,
      decoration: InputDecoration(
        contentPadding: EdgeInsets.only(left: 5),
        filled: true,
        fillColor: readOnly
            ? Colors.grey.shade200 // Light grey for read-only
            : Colors.white,
        labelText: label, // just use labelText directly
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String hintText,
    String validationMessage,
    String validationKey, {
    IconData icon = FontAwesomeIcons.solidCircleUser,
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
        contentPadding: EdgeInsets.only(left: 5),
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
        suffixIcon: Icon(icon, color: Colors.purple, size: 15),
      ),
    );
  }

  Widget _buildMobileTextField({
    required TextEditingController controller,
    bool isRequired = true,
    IconData icon = FontAwesomeIcons.solidCircleUser,
    bool isPhoneNumber = false,
    bool readOnly = false,
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
            readOnly: readOnly,
            keyboardType:
                isPhoneNumber ? TextInputType.phone : TextInputType.text,
            inputFormatters: [
              if (isPhoneNumber) LengthLimitingTextInputFormatter(10),
            ],
            // maxLength: 10,
            decoration: InputDecoration(
              filled: true,
              fillColor: readOnly
                  ? Colors.grey.shade200 // visually indicate read-only
                  : Colors.white,
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
              suffixIcon: Icon(icon, color: Colors.purple, size: 15),
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
    IconData icon = FontAwesomeIcons.solidCircleUser,
    int? maxDigits, // Maximum digits allowed (TIN=9, SSS=10, GSIS=11)
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly, // Allow only digits
        if (maxDigits != null) LengthLimitingTextInputFormatter(maxDigits),
      ],
      decoration: InputDecoration(
        filled: true,
        fillColor: readOnly ? Colors.grey.shade200 : Colors.white,
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
        suffixIcon: Icon(icon, color: Colors.purple, size: 15),
      ),
      validator: (value) {
        if (isRequired && (value == null || value.trim().isEmpty)) {
          return "$hintText cannot be empty";
        }
        if (maxDigits != null && value!.trim().length != maxDigits) {
          return "$hintText must be exactly $maxDigits digits";
        }
        return null; // valid
      },
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
            print("date is ${controller.text}");
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
            contentPadding: const EdgeInsets.only(left: 9),
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
    bool readOnly = false, // 🔹 new param
  }) {
    return AbsorbPointer(
      // 🔹 prevents tapping if readOnly true
      absorbing: readOnly,
      child: DropdownButtonFormField<String>(
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
          contentPadding: EdgeInsets.only(left: 5),
          filled: true,
          fillColor: readOnly
              ? Colors.grey.shade200 // visually indicate read-only
              : Colors.white,
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
      ),
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
        contentPadding: EdgeInsets.only(left: 9),
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
        contentPadding: EdgeInsets.only(left: 5),
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
            padding: const EdgeInsets.symmetric(horizontal: 0.0),
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
        contentPadding: EdgeInsets.only(left: 5),
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
            padding: const EdgeInsets.symmetric(horizontal: 0.0),
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
        contentPadding: EdgeInsets.only(left: 5),
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
    bool readOnly = false,
  }) {
    return AbsorbPointer(
      absorbing: readOnly,
      child: DropdownButtonFormField<String>(
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
              padding: const EdgeInsets.symmetric(horizontal: 0.0),
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
          contentPadding: EdgeInsets.only(left: 5),
          // prefix: SizedBox(width: 5,),
          filled: true,
          fillColor: readOnly
              ? Colors.grey.shade200 // visually indicate read-only
              : Colors.white,
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
      ),
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
            padding: const EdgeInsets.symmetric(horizontal: 0.0),
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
        contentPadding: EdgeInsets.only(left: 5),
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
            padding: const EdgeInsets.symmetric(horizontal: 0.0),
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
        contentPadding: EdgeInsets.only(left: 5),
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
