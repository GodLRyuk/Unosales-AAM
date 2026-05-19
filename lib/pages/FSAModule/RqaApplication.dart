import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unosfa/pages/config/config.dart';
import 'package:unosfa/pages/otpscreens/dedupeCheck.dart';
import 'package:unosfa/pages/services/api_service.dart';
import 'package:unosfa/widgetSupport/widgetstyle.dart';

class RQAApplication extends StatefulWidget {
  const RQAApplication({super.key});

  @override
  State<RQAApplication> createState() => _RQAApplicationState();
}

class _RQAApplicationState extends State<RQAApplication> {
  String gender = "";
  String? selectedValue;
  String? creditCardSelectedValue;
  String? selectedzipValue;
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  List<Map<String, dynamic>> industryList = [];
  List<Map<String, dynamic>> sourceofFundList = [];
  List<Map<String, dynamic>> empStatusList = [];
  List<Map<String, dynamic>> empList = [];
  List<Map<String, dynamic>> empWorkNatureList = [];

  bool _isFieldFocused = false;
  TextEditingController _searchController = TextEditingController();
  late List<Map<String, String>> _filteredCompanies; // Store filtered companies
  late Map<String, String> _ComIdOptions; // Store the fetched companies
  String? _selectedCompany;
  bool _showOtherCompanyField = false;

  final firstName = TextEditingController();
  final middlename = TextEditingController();
  final lastName = TextEditingController();
  final dob = TextEditingController();
  final zip = TextEditingController();
  final employee = TextEditingController();
  final emp_Indus_Type = TextEditingController();
  final genderFocusNode = FocusNode();
  final emp_Indus_Type_Code = TextEditingController();
  final fin_Src_Of_Funds_Code = TextEditingController();
  final _otherCompanyController = TextEditingController();
  final mobileController = TextEditingController();
  final incomeController = TextEditingController();
  final emp_Status_Code = TextEditingController();
  final emp_Status = TextEditingController();
  final emp_Work_Nature = TextEditingController();
  final emp_Work_Nature_Code = TextEditingController();
  final credit_loan_amount = TextEditingController();
  final emp_Type_Code = TextEditingController();
  final emp_Type = TextEditingController();

  void initState() {
    super.initState();
    _initializeIndustryTypeList();
    _initializeEmpStatusList();
    _initializeEmpTypeList();
    _initializeEmpWorkNatureList();
    _loadData();
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
            if (!mounted) return;
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
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load EMP Status list')),
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
            if (!mounted) return;
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
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load Industry Type list')),
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

  Future<Map<String, String>> _getAuthHeader() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('accessToken');
    return {'Authorization': 'Bearer $token'};
  }

  Future<void> _searchCompany(String query) async {
    print("search is $query");
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (query.isEmpty) {
      if (!mounted) return;
      setState(() {
        _filteredCompanies = _ComIdOptions.entries
            .map((e) => {'id': e.value, 'company_name': e.value})
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
          final Map<String, dynamic> data = json.decode(response.data);
          if (data['results'] != null && data['results'] is List) {
            List<dynamic> companies = data['results'];
            if (!mounted) return;

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
            final data = json.decode(response2.data);
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
          final Map<String, dynamic> data = json.decode(response.data);
          if (data['results'] != null && data['results'] is List) {
            List<dynamic> companies = data['results'];

            Map<String, String> fetchedData = {};
            for (var item in companies) {
              fetchedData[item['id'].toString()] =
                  item['company_name'].toString();
            }

            if (!mounted) return;
            setState(() {
              _ComIdOptions = fetchedData;
              _filteredCompanies = fetchedData.entries
                  .map((e) => {'id': e.key, 'company_name': e.value})
                  .toList();

              // Append "Others" option
              _filteredCompanies
                  .add({'id': 'others', 'company_name': 'Others'});
            });
          }
        } else if (response.statusCode == 401) {
          SharedPreferences prefs = await SharedPreferences.getInstance();
          Map<String, String> mappedData = {
            'refresh': refresh ?? '',
          };
          String refressToken = '/api/users/token-refresh/';
          final response2 = await ApiService.post(refressToken, mappedData);
          if (response2 != null) {
            final data = json.decode(response2.data);
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

  // Random Application ID create
  String generateApplicationId() {
    final random = Random();

    // 6 digit random number
    int randomNumber = 100000 + random.nextInt(900000);

    // current date time (yyyyMMddHHmmss)
    String dateTime = DateFormat('yyyyMMddHHmmss').format(DateTime.now());

    return "FSA_$randomNumber$dateTime";
  }

   bool databaseUpdate_value = false; 
  // Store data in UNO Data Base
  Future<bool> submitDataUnoDB(String lostoken,
      Map<String, dynamic> responseData, String CWTransactionID) async {
    String url = "/save/external-response";
    final header1 = {
      'Authorization': 'Bearer $lostoken',
      'Correlation-Id': '3b2d2c13-4e48-4c6d-8b5d-dbdba6c3c0a8',
      'Channel': 'FSA',
      'Content-Type': 'application/json'
    };

    Map<String, dynamic> formData1 = {
      "applicationId": CWTransactionID,
      "externalSourceSystem": "RQA",
      "workFlowStage": "ACTICO_RQA_CHECK",
      "requestBody": {
        "rqa": {
          "q1_id": selectedValue,
          "q2_dob": dob.text,
          "q3_zipcode": zip.text,
          "q4_source_income": emp_Status.text,
          "q4a_emp_status":
              emp_Type.text.trim().isEmpty ? null : emp_Type.text.trim(),
          "q5_comp_name": _selectedCompany,
          "q5a_oth_comp_name": _otherCompanyController.text.trim().isEmpty
              ? null
              : _otherCompanyController.text.trim(),
          "q6_nat_business": emp_Work_Nature.text,
          "q7_monthly_income": incomeController.text,
          "q8_exist_cc_loan": creditCardSelectedValue,
          "q8a_cc_loan_amt": credit_loan_amount.text.trim().isEmpty
              ? null
              : credit_loan_amount.text.trim()
        }
      },
      "responseBody": responseData
    };

    try {
      final response =
          await ApiService.postJsonWithUNOApiHeaders(url, formData1, header1);

      if (response != null) {
        if (response.statusCode == 200) {
          databaseUpdate_value=true;
          print("Data submitted successfully in UNO DB");          
           
        } 
        else {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                title: Row(
                  children: const [
                    Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 28,
                    ),
                    SizedBox(width: 10),
                    Text(
                      "Something Went Wrong",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
                content: Text(
                  "Failed to connect with server.\nStatus Code: ${response.statusCode}",
                  style: const TextStyle(fontSize: 16),
                ),
                actionsPadding: const EdgeInsets.only(bottom: 10, right: 10),
                actions: [
                  Center(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: const Text(
                        "OK",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              );
            },
          );
          databaseUpdate_value=false;
        }
      }
    } catch (e) {
      print("error is $e");
     
    }
    return databaseUpdate_value;
   
  }

  //******************************************* */

  Future<void> submitData() async {
    setState(() {
      _isLoading = true;
    });
    String CWTransactionID = generateApplicationId();

    String token = "";
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString('accessToken');
    try {
      String tokenUrl = "/api/leads/los-access-token/";
      final headers = {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
        // 'User-Agent':
        //     'Mozilla/5.0 (Linux; Android 11; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36',
      };
      final Tokenresponse = await ApiService.getWithHeaders(tokenUrl, headers);
      if (Tokenresponse != null) {
        final data = json.decode(Tokenresponse.data);
        token = data['access_token'];
      }
    } catch (e) {
      print("HTTP Request Failed: $e");
    }

    String rqaUrl =
        '/engine/v1/executions/loans-interface/1.x/rqa-check/rqa_check/RQA_Check';
    final headers = {
      'Authorization': 'Bearer $token',
      // 'User-Agent':
      //     'Mozilla/5.0 (Linux; Android 11; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36',
      'Content-Type': 'application/json'
    };

    Map<String, dynamic> formData = {
      "rqa": {
        "q1_id": selectedValue,
        "q2_dob": dob.text,
        "q3_zipcode": zip.text,
        "q4_source_income": emp_Status.text,
        "q4a_emp_status":
            emp_Type.text.trim().isEmpty ? null : emp_Type.text.trim(),
        "q5_comp_name": _selectedCompany,
        "q5a_oth_comp_name": _otherCompanyController.text.trim().isEmpty
            ? null
            : _otherCompanyController.text.trim(),
        "q6_nat_business": emp_Work_Nature.text,
        "q7_monthly_income": incomeController.text,
        "q8_exist_cc_loan": creditCardSelectedValue,
        "q8a_cc_loan_amt": credit_loan_amount.text.trim().isEmpty
            ? null
            : credit_loan_amount.text.trim()
      }
    };

    try {
      final response =
          await ApiService.postJsonWithUNOApiHeaders(rqaUrl, formData, headers);

      if (response != null && response.statusCode == 200) {
        final data = jsonDecode(response.data);
        print("response body $data");

        String? status = data['output']['response']['status'];
        print("status is $status");

        //  ****************************************************
        print("status is $status");
        bool dataUpdatedValue = await submitDataUnoDB(token, data, CWTransactionID);
        // ***************************************************
        if (status != null && status.toLowerCase() == "pass" && dataUpdatedValue == true) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DedupeCheck(
                  CWTranscationID: CWTransactionID,
                  firstName: firstName.text,
                  middleName: middlename.text,
                  lastName: lastName.text,
                  dob: dob.text,
                  mobilePhone: mobileController.text,
                  zipCode: zip.text,
                  idCard: selectedValue.toString(),
                  source_of_income: emp_Status_Code
                      .text, //*********************** */  emp_status_code
                  emp_Status: emp_Type_Code
                      .text, //***************************** */ emp_type_code
                  companyName: _selectedCompany.toString(),
                  otherCompanyName: _otherCompanyController.text,
                  natureofBusiness: emp_Work_Nature_Code
                      .text, //********************** */ emp_work_nature_code
                  monthlyIncome: incomeController.text,
                  existingLoan: creditCardSelectedValue.toString(),
                  creditLoanAmount: credit_loan_amount.text),
            ),
          );
        } else {
          List reason = data['output']['response']['reject_reasons'];
          String allReasons = reason.map((e) => e['reason']).join('\n');
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                title: Row(
                  children: const [
                    Icon(
                      Icons.info_outline,
                      color: Colors.red,
                      size: 28,
                    ),
                    SizedBox(width: 10),
                    Text(
                      "Application Status",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
                content: Text(
                  "RQA Check Failed.Reason:\n$allReasons",
                  style: const TextStyle(
                    fontSize: 16,
                  ),
                ),
                actionsPadding: const EdgeInsets.only(bottom: 10, right: 10),
                actions: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text(
                      "OK",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              );
            },
          );
        }
      } else {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Row(
                children: const [
                  Icon(
                    Icons.error_outline,
                    color: Colors.red,
                    size: 28,
                  ),
                  SizedBox(width: 10),
                  Text(
                    "Something Went Wrong",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
              content: Text(
                "Failed to connect with server.\nStatus Code: ${response!.statusCode}",
                style: const TextStyle(fontSize: 16),
              ),
              actionsPadding: const EdgeInsets.only(bottom: 10, right: 10),
              actions: [
                Center(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text(
                      "OK",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      }
    } catch (e) {
      print("error is $e");
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(60.0), // Adjusted height for TabBar
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
                Navigator.pop(context);
              },
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Heading
                    Container(
                      color: Colors.purple,
                      width: 500,
                      height: 50,
                      child: Center(
                        child: Text(
                          "RQA Application",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),

                    // ID Card Question
                    _buildTextField(
                      firstName,
                      "First Name",
                      "Enter your First Name",
                    ),
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.02,
                    ),

                    _buildTextField(
                      middlename,
                      "Middle Name",
                      "Enter your Middle Name",
                    ),

                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.02,
                    ),
                    _buildTextField(
                      lastName,
                      "Last Name",
                      "Enter your Last Name",
                    ),
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.02,
                    ),

                    _buildMobileTextField(
                      controller: mobileController,
                      isPhoneNumber: true,
                    ),
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.02,
                    ),

                    _buildDobField(dob, "Date of Birth"),
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.02,
                    ),

                    Text(
                      "Zip Code",
                      style: WidgetSupport.Questionblack(),
                    ),

                    _buildZipCodeField(),
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.02,
                    ),

                    Text(
                      "Do you have ID Card ?",
                      style: WidgetSupport.Questionblack(),
                    ),

                    _buildIDCardDropDown(),

                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.02,
                    ),
                    Text(
                      "What Is The Source of Income",
                      style: WidgetSupport.Questionblack(),
                    ),

                    _buildEmpStatusDropdown(
                      controller: emp_Status,
                      label: "Select Income Source",
                    ),

                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.02,
                    ),

                    if (emp_Status.text == "Employed - Government" ||
                        emp_Status.text == "Employed - Private") ...[
                      Text(
                        "Employee Type",
                        style: WidgetSupport.Questionblack(),
                      ),
                      _buildEmpTypeDropdown(
                        controller: emp_Type,
                        label: "Select Employee Status",
                      ),
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.02,
                      ),
                    ],

                    // Text(
                    //   "Employe Type",
                    //   style: WidgetSupport.Questionblack(),
                    // ),
                    // _buildEmpTypeDropdown(
                    //   controller: emp_Type,
                    //   label: "Select Employe Status",
                    // ),

                    Text(
                      "Company Name",
                      style: WidgetSupport.Questionblack(),
                    ),
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
                              decoration: InputDecoration(
                                contentPadding: EdgeInsets.only(left: 15),
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
                                            color: Colors.red, fontSize: 20),
                                      ),
                                    ],
                                  ),
                                ),
                                suffixIcon: IconButton(
                                  icon: const Icon(Icons.search),
                                  onPressed: () {
                                    _searchCompany(_searchController.text);
                                  },
                                ),
                              ),
                              onChanged: (query) {
                                if (query.isEmpty) {
                                  setState(() {
                                    _filteredCompanies = _ComIdOptions.entries
                                        .map((e) => {
                                              'id': e.value,
                                              'company_name': e.value,
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
                              borderRadius: BorderRadius.circular(8.0),
                              child: Container(
                                height: 200,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                child: ListView.builder(
                                  itemCount: _filteredCompanies.length,
                                  itemBuilder: (context, index) {
                                    return ListTile(
                                      title: Text(_filteredCompanies[index]
                                          ['company_name']!),
                                      onTap: () {
                                        // Set the selected company
                                        setState(() {
                                          _selectedCompany =
                                              _filteredCompanies[index]
                                                  ['company_name'];
                                          _searchController.text =
                                              _filteredCompanies[index]
                                                  ['company_name']!;
                                          _isFieldFocused = false;
                                          _showOtherCompanyField =
                                              _selectedCompany!.toLowerCase() ==
                                                  'others';
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
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.02,
                    ),
                    if (_showOtherCompanyField) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 0.0),
                        child: TextFormField(
                          controller: _otherCompanyController,
                          decoration: InputDecoration(
                            hintText: "Enter Employer/Business Name",
                          ),
                          validator: (value) {
                            // if (value == null ||
                            //     value.isEmpty ||
                            //     _selectedCompany == 'others') {
                            //   return 'Company name is required';
                            // }
                            if (_selectedCompany == 'others' &&
                                (value == null || value.isEmpty)) {
                              return 'Company name is required';
                            }
                            return null;
                          },
                          onChanged: (value) {},
                        ),
                      ),
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.04,
                      ),
                    ],
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.02,
                    ),
                    Text(
                      "Please Provide company's nature of business",
                      style: WidgetSupport.Questionblack(),
                    ),
                    _buildEmpWorkNatureDropdown(
                      controller: emp_Work_Nature,
                      label: "Select nature of business",
                    ),

                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.02,
                    ),

                    Text(
                      "How much is your monthly income",
                      style: WidgetSupport.Questionblack(),
                    ),
                    _buildIncomeTextField(
                        controller: incomeController, isRequired: true),
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.02,
                    ),
                    Text(
                      "Do you have a credit card or loan with other bank?",
                      style: WidgetSupport.Questionblack(),
                    ),

                    _buildcreditDropDown(),
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.02,
                    ),

                    if (creditCardSelectedValue == "Yes") ...[
                      Text(
                        "Please provide loan amount or credit card limit",
                        style: WidgetSupport.Questionblack(),
                      ),
                      // _buildTextField(
                      //   credit_loan_amount,
                      //   "Loan Amount/ Credit Limit",
                      //   "Please enter Loan Amount/ Credit Limit",
                      // ),

                      _buildIncomeTextField(
                        controller: credit_loan_amount,
                      )
                    ],

                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.01,
                    ),
                    Center(
                        child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.purple,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 35),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: () {
                              print("press");
                              if (_formKey.currentState!.validate()) {
                                submitData();
                              }
                            },
                            child: Text(
                              "SUBMIT",
                              style: TextStyle(color: Colors.white),
                            ))),
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.05,
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.4),
              child: const Center(
                child: CircularProgressIndicator(
                  color: Colors.purple,
                ),
              ),
            ),
        ],
      ),
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
            //_initializeSourceFundList();
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

  Widget _buildTextField(
    TextEditingController controller,
    String hintText,
    String validationMessage, {
    IconData icon = FontAwesomeIcons.solidCircleUser,
    bool obscureText = false,
  }) {
    bool isMiddleName = hintText == "Middle Name";

    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        label: RichText(
          text: TextSpan(
            text: hintText,
            style: WidgetSupport.inputLabel(),
            children: isMiddleName
                ? []
                : const [
                    TextSpan(
                      text: " *",
                      style: TextStyle(color: Colors.red, fontSize: 25),
                    ),
                  ],
          ),
        ),
        suffixIcon: Padding(
          padding: const EdgeInsets.all(0),
          child: Icon(
            icon,
            color: Colors.purple,
            size: 20,
          ),
        ),
      ),
      validator: (value) {
        if (isMiddleName) return null;

        if (value == null || value.isEmpty) {
          return '$hintText is required';
        }
        return null;
      },
    );
  }

  Widget _buildIDCardDropDown() {
    return DropdownButtonFormField<String>(
      value: selectedValue,
      items: ["Yes", "No"].map((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value),
        );
      }).toList(),
      onChanged: (String? newValue) {
        setState(() {
          selectedValue = newValue;
        });
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return "Please select an option";
        }
        return null;
      },
      decoration: InputDecoration(
        label: RichText(
          text: TextSpan(
            text: "Select Option",
            style: WidgetSupport.inputLabel(),
            children: const [
              TextSpan(
                text: " *",
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 25,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildcreditDropDown() {
    return DropdownButtonFormField<String>(
      value: creditCardSelectedValue,
      items: ["Yes", "No"].map((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value),
        );
      }).toList(),
      onChanged: (String? newValue) {
        setState(() {
          creditCardSelectedValue = newValue;
        });
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return "Please select an option";
        }
        return null;
      },
      decoration: InputDecoration(
        label: RichText(
          text: TextSpan(
            text: "Select Option",
            style: WidgetSupport.inputLabel(),
            children: const [
              TextSpan(
                text: " *",
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 25,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildZipCodeField() {
    return TextFormField(
      controller: zip,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly, // Only numbers
        LengthLimitingTextInputFormatter(4), // Max 4 digits
      ],
      validator: (value) {
        if (value == null || value.isEmpty) {
          return "Please enter zip code";
        }
        if (value.length != 4) {
          return "Zip code must be 4 digits";
        }
        return null;
      },
      decoration: InputDecoration(
        label: RichText(
          text: TextSpan(
            text: "Zip Code",
            style: WidgetSupport.inputLabel(),
            children: const [
              TextSpan(
                text: " *",
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 25,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDobField(TextEditingController controller, String labelText) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      decoration: InputDecoration(
        label: RichText(
          text: TextSpan(
            text: labelText,
            style: WidgetSupport.inputLabel(),
            children: const [
              TextSpan(
                text: " *",
                style: TextStyle(color: Colors.red, fontSize: 25),
              ),
            ],
          ),
        ),
        suffixIcon: const Icon(
          FontAwesomeIcons.calendar,
          color: Colors.purple,
          size: 18,
        ),
      ),
      onTap: () async {
        FocusScope.of(context).requestFocus(FocusNode());
        DateTime? pickedDate = await showDatePicker(
          context: context,
          initialDate: DateTime(2000),
          firstDate: DateTime(1500),
          lastDate: DateTime.now(),
        );

        if (pickedDate != null) {
          setState(() {
            controller.text =
                "${pickedDate.day}/${pickedDate.month}/${pickedDate.year}";
          });
        }
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Date of Birth is required';
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
          // filled: true,
          // fillColor: readOnly
          //     ? Colors.grey.shade200 // visually indicate read-only
          //     : Colors.white,
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

  Widget _buildIncomeTextField({
    required TextEditingController controller,
    bool isRequired = true,
    IconData icon = FontAwesomeIcons.moneyBill,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(10),
      ],
      validator: (value) {
        if (isRequired && (value == null || value.trim().isEmpty)) {
          return "Please enter monthly income";
        }

        if (value != null && value.isNotEmpty) {
          int income = int.tryParse(value) ?? 0;
          if (income <= 0) {
            return "Income must be greater than 0";
          }
        }

        return null;
      },
      decoration: InputDecoration(
        label: isRequired
            ? RichText(
                text: TextSpan(
                  text: "Monthly Income",
                  style: WidgetSupport.inputLabel(),
                  children: const [
                    TextSpan(
                      text: ' *',
                      style: TextStyle(color: Colors.red, fontSize: 25),
                    )
                  ],
                ),
              )
            : Text("Monthly Income", style: WidgetSupport.inputLabel()),
        suffixIcon: Icon(icon, color: Colors.purple, size: 15),
      ),
    );
  }

  Widget _buildMobileTextField({
    required TextEditingController controller,
    bool isRequired = true,
    IconData icon = FontAwesomeIcons.solidCircleUser,
    bool isPhoneNumber = false,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 1, vertical: 8),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(width: 2)),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(4),
              bottomLeft: Radius.circular(4),
            ),
          ),
          child: const Padding(
            padding: EdgeInsets.only(top: 16.0),
            child: Text(
              '   63',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
        Expanded(
          child: TextFormField(
            controller: controller,
            keyboardType:
                isPhoneNumber ? TextInputType.phone : TextInputType.text,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              if (isPhoneNumber) LengthLimitingTextInputFormatter(10),
            ],
            validator: (value) {
              if (isRequired && (value == null || value.isEmpty)) {
                return "Phone number is required";
              }

              if (isPhoneNumber && value!.length != 10) {
                return "Phone number must be 10 digits";
              }

              return null;
            },
            decoration: InputDecoration(
              label: isRequired
                  ? RichText(
                      text: TextSpan(
                        text: "Phone Number",
                        style: WidgetSupport.inputLabel(),
                        children: const [
                          TextSpan(
                            text: ' *',
                            style: TextStyle(color: Colors.red, fontSize: 25),
                          )
                        ],
                      ),
                    )
                  : Text("Phone Number", style: WidgetSupport.inputLabel()),
              suffixIcon: Icon(icon, color: Colors.purple, size: 15),
            ),
          ),
        ),
      ],
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
            //_initializeSourceFundList();
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
}
