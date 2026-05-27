import 'dart:convert';
import 'dart:io';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_datetime_picker_bdaya/flutter_datetime_picker_bdaya.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unosfa/pages/FSAModule/losApplication.dart';
import 'package:unosfa/pages/Form/FormList/daily_sales_report_list.dart';
import 'package:unosfa/pages/config/config.dart';
import 'package:unosfa/pages/services/api_service.dart';
import 'package:unosfa/widgetSupport/widgetstyle.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:intl/intl.dart';

class DailySalesReport extends StatefulWidget {
  final String pagemode;
  final String dsrId;
  const DailySalesReport(
      {super.key, required this.pagemode, required this.dsrId});

  @override
  State<DailySalesReport> createState() => _DailyAgentPlanerState();
}

enum IdType { tin, sss, gsis }

class _DailyAgentPlanerState extends State<DailySalesReport> {
  final firstName = TextEditingController();
  final middleName = TextEditingController();
  final lastName = TextEditingController();
  final mobileNumber = TextEditingController();
  final emailId = TextEditingController();
  final companyName = TextEditingController();
  final industryType = TextEditingController();
  final industryCode = TextEditingController();
  final idType = TextEditingController();
  final incomeDocType = TextEditingController();
  final monthlySalary = TextEditingController();
  final loanAmount = TextEditingController();
  final activityType = TextEditingController();
  final status = TextEditingController();
  final subStatus = TextEditingController();
  final TextEditingController perm_ZipCode = TextEditingController();
  final perm_Street = TextEditingController();
  final callback_date = TextEditingController();
  Map<String, dynamic> leadDetails = {}; // To store the lead details

  IdType? _selectedIdType;
  bool _isLoading = false;
  bool _showNextButton = true;
  List<int> _locationBlocks = [];
  List<LatLng?> _selectedLocations = [];
  bool _loadingCurrentLocation = true;
  LatLng? _currentLocation; // store current location
  Map<int, GoogleMapController> _mapControllers =
      {}; // map controllers per block
  List<String> PermbarangayList = [];
  String? _selectedBarangay;
  final perm_Region = TextEditingController();
  final perm_State = TextEditingController();
  final perm_City = TextEditingController();
  final perm_Barangay = TextEditingController();

  final identity_TinId = TextEditingController();
  final identity_SssID = TextEditingController();
  final identity_GsisID = TextEditingController();
  List<Map<String, dynamic>> docTypelist = [];
  int? selectedDocId;
  int? selectedActivityId;
  bool _isFieldFocused = false;
  TextEditingController _searchController = TextEditingController();
  late List<Map<String, String>> _filteredCompanies; // Store filtered companies
  late Map<String, String> _ComIdOptions; // Store the fetched companies
  String? _selectedCompany;
  bool _showOtherCompanyField = false;
  final _otherCompanyController = TextEditingController();
  List<Map<String, dynamic>> industryList = [];
  final emp_Indus_Type_Code = TextEditingController();
  List<Map<String, dynamic>> activityTypelist = [];
  final activity_Type_Code = TextEditingController();
  late Map<String, String> StatusCode = {}; // Initialize as an empty map
  String? _selectedStatusCode;
  late Map<String, String> _dependentData = {}; // List for second dropdown data
  String? _selectedStatusSubCode;
  bool isLoading = true;
  late Map<String, String> _subdependentData =
      {}; // List for second dropdown data
  double? _latitude;
  double? _longitude;
  String _currentAddress = "";
  String startTime = "";
  String endTime = "";
  bool visibility = false;
  String featchCallBackStatus = "";
  String formSubmition = "";

  bool fieldsDisabled = false;
  String? _networkImageUrl;
  String? _networkImageUrl1;

  // ******************** Function for Image ********************
  Uint8List? _imageBytes;

  // Future<void> loadImage(String fullUrl) async {
  //   print("full url is $fullUrl");
  //   SharedPreferences prefs = await SharedPreferences.getInstance();
  //   String? token = prefs.getString('accessToken');

  //   final response = await http.get(
  //     Uri.parse(fullUrl),
  //     headers: {
  //       "Authorization": "Bearer $token",
  //     },
  //   );

  //   if (response.statusCode == 200) {
  //     setState(() {
  //       _imageBytes = response.bodyBytes;
  //       _isLoading = false;
  //     });
  //   } else {
  //     setState(() {
  //       _isLoading = false;
  //     });
  //   }
  // }
  // correct code
  //************************************************* */

  Future<void> loadImage(String fullUrl) async {
 
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? token = prefs.getString('accessToken');

  final path = '/' + fullUrl.split('/unosales/').last;
  // path = "/media/uploads/images/xxx.jpg"

  final headers = {
    'Authorization': 'Bearer $token',
    'User-Agent':
        'Mozilla/5.0 (Linux; Android 11; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36',
  };

  final response = await ApiService.getImageWithHeaders(path, headers);

  if (response != null && response.statusCode == 200) {
    setState(() {
      _imageBytes = Uint8List.fromList(response.data);
      _isLoading = false;
    });
  } else {
    setState(() {
      _isLoading = false;
    });
  }
}
  //************************************************** */

  @override
  void initState() {
    if (widget.pagemode == 'edit') {
      setDsrdata();
    }
    super.initState();
    _ComIdOptions = {};
    DateTime now = DateTime.now();
    setState(() {
      startTime = now.toIso8601String();
    });
    _fetchCurrentLocation();
    _incomeDocumentType();
    _loadData();
    _initializeIndustryTypeList();
    _initializeActivityTypeList();
    _loadStatusData();
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
    try {
      String url = "/api/timesheet/agent-daily-sales/${widget.dsrId}/";
      final headers = {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'User-Agent':
            'Mozilla/5.0 (Linux; Android 11; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36',
      };
      final response = await ApiService.getWithHeaders(url, headers);
      // final response = await http.get(
      //   Uri.parse(
      //       '${AppConfig.dynamicBaseUrl}/api/timesheet/agent-daily-sales/${widget.dsrId}/'), // Using leadId in the API URL
      //   headers: {
      //     'Authorization': 'Bearer $token',
      //     'Accept': 'application/json',
      //     'Content-Type': 'application/json',
      //     'User-Agent':
      //         'Mozilla/5.0 (Linux; Android 11; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36',
      //   },
      // );
      if (response!.statusCode == 200) {
        setState(() {
          leadDetails = response.data;

          firstName.text = leadDetails['first_name'] ?? "";
          lastName.text = leadDetails['last_name'] ?? "";
          middleName.text = leadDetails['middle_name'] ?? "";
          mobileNumber.text = leadDetails['phone_number'].substring(2) ?? "";
          emailId.text = leadDetails['email'] ?? "";
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
          selectedDocId = leadDetails['income_document_type'];
          loanAmount.text = leadDetails['desired_loan_amount'];
          selectedActivityId = leadDetails['activity'];
          _selectedStatusCode = leadDetails['disposition_code'].toString();
          perm_Region.text = leadDetails['region'] ?? "";
          monthlySalary.text = leadDetails['monthly_income'] ?? "";
          String employerId = leadDetails['employer'].toString();
          _selectedStatusSubCode =
              leadDetails['sub_disposition_code'].toString();

          // visibility
          _loadDependentData(_selectedStatusCode!, formSubmition);
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

            // Industry Type
            industryType.text = leadDetails['industry_type'] ?? "";
            industryCode.text = leadDetails['industry_code'] ?? "";
            emp_Indus_Type_Code.text = leadDetails['industry_code'] ?? "";

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
          if (leadDetails['follow_up_date'] != null &&
              leadDetails['follow_up_date'].toString().isNotEmpty) {
            String followUpStr = leadDetails['follow_up_date'].toString();
            String formattedDate =
                followUpStr.replaceFirst('T', ' ').split('+')[0].split('.')[0];

            callback_date.text = formattedDate.substring(0, 16);
            setState(() {
              visibility = true;
            });
          }

          // For image

          _networkImageUrl = leadDetails['upload_selfie'];
          if (_networkImageUrl != null && _networkImageUrl!.isNotEmpty) {
            loadImage(_networkImageUrl!);
          }

          // Correct code ************************
          // if (_networkImageUrl1 != null && _networkImageUrl1!.isNotEmpty) {
          //   if (AppConfig.isDev != true) {
          //     _networkImageUrl = _networkImageUrl1!.replaceFirst(
          //       "http://salesapp.${AppConfig.flavour}.ph.unobank.asia",
          //       "https://unoapi.${AppConfig.flavour}.ph.unobank.asia",
          //     );
          //   } else {
          //     _networkImageUrl = _networkImageUrl1;
          //   }

          //   loadImage(_networkImageUrl!);
          // }
          // done***************************************

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

  Future<void> getZipCodeEntered(String zipCode) async {
    String tokens = "";

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('accessToken');

      String url = "/api/leads/los-access-token/";
      final headers = {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Content-Type': 'multipart/form-data',
        'User-Agent':
            'Mozilla/5.0 (Linux; Android 11; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36',
      };
      final tokenResponse = await ApiService.getWithHeaders(url, headers);

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

      final tokenData = tokenResponse!.data;
      tokens = tokenData['access_token'];
    } catch (e) {
      print("HTTP Request Failed: $e");
    }

    try {
      String url = "/api/app/address";
      final headers = {
        'Authorization': 'Bearer $tokens',
        'Content-Type': 'application/json',
        'Idempotency-Key': 'sfsggdhsdgdgdg',
      };

      final body = {
        "zipcode": "$zipCode",
      };

      final response =
          await ApiService.postWithHeadersUnoApi(url, body, headers);
      // final response = await http.post(
      //   Uri.parse('${AppConfig.otpUrl}/api/app/address'),
      //   headers: {
      //     'Authorization': 'Bearer $tokens',
      //     'Content-Type': 'application/json',
      //     'Idempotency-Key': 'sfsggdhsdgdgdg',
      //   },
      //   body: jsonEncode({"zipcode": "$zipCode"}),
      // );
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
      String url = '/api/leads/companies/$query/';
      final headers = await _getAuthHeader();
      final response = await ApiService.getWithHeaders(url, headers);

      if (response != null) {
        if (response.statusCode == 200) {
          // Your API is returning a single company object, not a list
          final Map<String, dynamic> data = response.data;

          // Directly use the API response instead of _ComIdOptions
          if (data.containsKey('id')) {
            final companyId = data['id'].toString();
            final companyName = data['company_name'].toString();

            setState(() {
              _searchController.text = companyName;
              _selectedCompany = companyId;
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

  Future<void> _loadStatusData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('accessToken');

    try {
      String url = "/api/leads/disposition-codes/";
      final headers = {
        'Authorization': 'Bearer $token',
        'User-Agent':
            'Mozilla/5.0 (Linux; Android 11; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36',
      };
      final response = await ApiService.getWithHeaders(url, headers);
      if (response != null) {
        if (response.statusCode == 200) {
          var decodedResponse = response.data;
          if (decodedResponse is Map<String, dynamic> &&
              decodedResponse['results'] != null) {
            decodedResponse = decodedResponse['results'];
          }
          if (decodedResponse is List) {
            Map<String, String> fetchedData = {};
            for (var item in decodedResponse) {
              fetchedData[item['id'].toString()] =
                  item['description'].toString();
            }

            setState(() {
              StatusCode = fetchedData;
              isLoading = false;
            });
          } else {
            throw Exception('Unexpected response format');
          }
        } else if (response.statusCode == 401) {
          SharedPreferences prefs = await SharedPreferences.getInstance();
          String? refresh = prefs.getString('refreshToken');
          prefs.getString('accessToken');
          Map<String, String> mappedData = {
            'refresh': refresh ?? '',
          };
          String url2 = "/api/users/token-refresh/";
          final response2 = await ApiService.post(url2, mappedData);
          if (response2 != null) {
            final data = json.decode(response2.data);
            await prefs.setBool('isLoggedIn', true);
            await prefs.setString('accessToken', data['access']);
            await prefs.setString('refreshToken', data['refresh']);
          }
        } else {
          throw Exception('Failed to load dependent data');
        }
      }
    } catch (e) {
      print('Error: $e');
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
          final Map<String, dynamic> data = response.data;
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

  Future<void> _fetchCurrentLocation() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Location permission denied")),
        );
        return; // Stop here if still denied
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Enable location permission from settings")),
      );
      return;
    }
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      _latitude = position.latitude;
      _longitude = position.longitude;
      _currentLocation = LatLng(_latitude!, _longitude!);

      List<Placemark> placemarks =
          await placemarkFromCoordinates(_latitude!, _longitude!);

      String address = "";
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        address =
            "${place.name}, ${place.locality}, ${place.administrativeArea}, ${place.country}";
      }

      setState(() {
        _loadingCurrentLocation = false;
        _currentAddress = address;

        if (_locationBlocks.isEmpty) {
          _locationBlocks.add(0);
          _selectedLocations.add(_currentLocation);
        }
      });
    } catch (e) {
      setState(() {
        _loadingCurrentLocation = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Could not get current location")),
      );
    }
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

      String url = "/api/leads/los-access-token/";
      final header = {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Content-Type': 'multipart/form-data',
        'User-Agent':
            'Mozilla/5.0 (Linux; Android 11; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36',
      };
      final tokenResponse = await ApiService.getWithHeaders(url, header);

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

      final tokenData = tokenResponse!.data;
      tokens = tokenData['access_token'];
    } catch (e) {
      print("HTTP Request Failed: $e");
    }
    try {
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
              _selectedBarangay = null; // ✅ Reset again when new list loads
              perm_Barangay.text = '';
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

  Future<void> _incomeDocumentType() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('accessToken');

    try {
      String url = "/api/leads/document-types/";
      final headers = {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'User-Agent':
            'Mozilla/5.0 (Linux; Android 11; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36',
      };
      // final response = await http.get(
      //   Uri.parse('${AppConfig.dynamicBaseUrl}/api/leads/document-types/'),
      //   headers: {
      //     'Authorization': 'Bearer $token',
      //     'Content-Type': 'application/json',
      //     'User-Agent':
      //         'Mozilla/5.0 (Linux; Android 11; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36',
      //   },
      // );

      final response = await ApiService.getWithHeaders(url, headers);
      if (response!.statusCode == 200) {
        final Map<String, dynamic> responseBody = response.data;

        if (responseBody['results'] is List) {
          final List<dynamic> results = responseBody['results'];
          setState(() {
            // Only take id and name from each map
            docTypelist = results.map<Map<String, dynamic>>((item) {
              return {
                'id': item['id'],
                'name': item['description'],
              };
            }).toList();
          });
        } else {
          print("No results found");
        }
      } else {
        throw Exception('Failed to load Income Document list');
      }
    } catch (e) {
      print("Error loading Income Document list: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load Income Document list')),
      );
    }
  }

  Future<void> _searchCompany(String query) async {
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
      // print("api is $url");
      // print("header $headers");

      if (response != null) {
        if (response.statusCode == 200) {
          //print("response is ${response.data.body}");
          final Map<String, dynamic> data = response.data;
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
      print('Search Error is this: $e');
    }
  }

  Future<void> _initializeIndustryTypeList() async {
    String tokens = "";
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('accessToken');

      String url = "/api/leads/los-access-token/";
      final headers = {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Content-Type': 'multipart/form-data',
        'User-Agent':
            'Mozilla/5.0 (Linux; Android 11; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36',
      };

      final tokenResponse = await ApiService.getWithHeaders(url, headers);

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

      final tokenData = tokenResponse!.data;
      tokens = tokenData['access_token'];
    } catch (e) {
      print("HTTP Request Failed: $e");
    }
    try {
      String url = "/api/app/fetch/LOV/details";
      final headers = {
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
          await ApiService.postWithHeadersUnoApi(url, body, headers);

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

  Future<void> _initializeActivityTypeList() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('accessToken');

    try {
      String url = "/api/leads/activities/";
      final header = {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'User-Agent':
            'Mozilla/5.0 (Linux; Android 11; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36',
      };
      final response = await ApiService.getWithHeaders(url, header);
      // final response = await http.get(
      //   Uri.parse('${AppConfig.dynamicBaseUrl}/api/leads/activities/'),
      //   headers: {
      //     'Authorization': 'Bearer $token',
      //     'Content-Type': 'application/json',
      //     'User-Agent':
      //         'Mozilla/5.0 (Linux; Android 11; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36',
      //   },
      // );

      if (response!.statusCode == 200) {
        final Map<String, dynamic> responseBody = response.data;
        if (responseBody['results'] is List) {
          final List<dynamic> results = responseBody['results'];
          // print(results);
          setState(() {
            activityTypelist = results.map<Map<String, dynamic>>((item) {
              return {
                'id': item['id'] ?? 0,
                // Use description or name safely
                'name': (item['description'] ?? item['name'] ?? '').toString(),
              };
            }).toList();
          });
        } else {
          print("No results found");
        }
      } else {
        throw Exception('Failed to load Activity Type list');
      }
    } catch (e) {
      print("Error loading Activity Type list: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load Activity Type list')),
      );
    }
  }

  Future<Map<String, String>> _getAuthHeader() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('accessToken');
    return {'Authorization': 'Bearer $token'};
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60.0),
        child: Container(
          decoration: const BoxDecoration(
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
                const SizedBox(width: 50),
              ],
            ),
            centerTitle: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (context) => DailySalesReportList(
                            searchQuery: '',
                          )),
                );
              },
            ),
          ),
        ),
      ),
      body: _loadingCurrentLocation
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Text(
                      "Daily Sales Report".toUpperCase(),
                      style: WidgetSupport.HeaderBoldBlack(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "First Name",
                    style: WidgetSupport.Questionblack(),
                  ),
                  _buildTextField(
                    firstName,
                    "First Name",
                    "Please Enter First Name",
                    "fullName",
                  ),
                  const SizedBox(height: 15),
                  Text(
                    "Middle Name",
                    style: WidgetSupport.Questionblack(),
                  ),
                  _buildTextField(
                    middleName,
                    "Middle Name",
                    "Please Enter Middle Name",
                    "middleName",
                    isRequired: false,
                  ),
                  const SizedBox(height: 15),
                  Text(
                    "Last Name",
                    style: WidgetSupport.Questionblack(),
                  ),
                  _buildTextField(
                    lastName,
                    "Last Name",
                    "Please Enter Last Name",
                    "lastName",
                  ),
                  const SizedBox(height: 15),
                  Text(
                    "Mobile Number",
                    style: WidgetSupport.Questionblack(),
                  ),
                  _buildMobileTextField(
                    controller: mobileNumber,
                    isPhoneNumber: true,
                  ),
                  const SizedBox(height: 15),
                  Text(
                    "Email ID",
                    style: WidgetSupport.Questionblack(),
                  ),
                  _buildTextField(
                    emailId,
                    "Email Id",
                    "Please Enter Email Id",
                    "mobileNumber",
                    isEmail: true,
                  ),
                  const SizedBox(height: 15),
                  Text(
                    "Zip Code",
                    style: WidgetSupport.Questionblack(),
                  ),
                  _buildZipTextField(
                    perm_ZipCode,
                    "   Zip Code",
                    "Please Enter Zip Code",
                    "perm_ZipCode",
                    isRequired: true,
                    isNumeric: true,
                    isZip: true,
                    onChanged: (value) async {
                      if (value.length == 4) {
                        onZipCodeEntered(value);
                      }
                    },
                  ),
                  const SizedBox(height: 15),
                  Text(
                    "Region",
                    style: WidgetSupport.Questionblack(),
                  ),
                  _buildTextField(perm_Region, "Region", "Please Enter Region",
                      "perm_Region",
                      isRequired: true, readOnly: true),
                  const SizedBox(height: 15),
                  Text(
                    "Province",
                    style: WidgetSupport.Questionblack(),
                  ),
                  _buildTextField(
                    perm_State,
                    "Province",
                    "Please Enter Province",
                    "perm_State",
                    isRequired: true,
                    readOnly: true,
                  ),
                  const SizedBox(height: 15),
                  Text(
                    "City",
                    style: WidgetSupport.Questionblack(),
                  ),
                  _buildTextField(
                    perm_City,
                    "City",
                    "Please Enter City",
                    "perm_City",
                    isRequired: true,
                    readOnly: true,
                  ),
                  const SizedBox(height: 15),
                  Text(
                    "Barangay",
                    style: WidgetSupport.Questionblack(),
                  ),
                  _buildPermBarangayDropdown(
                    controller: perm_Barangay,
                    label: "   Select Barangay",
                  ),
                  const SizedBox(height: 15),
                  Text(
                    "House no. & Street",
                    style: WidgetSupport.Questionblack(),
                  ),
                  _buildTextField(
                    perm_Street,
                    "House no. & Street",
                    "Please Enter House no. & Street",
                    "perm_Street",
                    isRequired: true,
                    readOnly: false,
                  ),
                  const SizedBox(height: 15),
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
                                  // Trigger the search when the search icon is pressed
                                  _searchCompany(_searchController.text);
                                },
                              ),
                            ),
                            onChanged: (query) {
                              if (query.isEmpty) {
                                setState(() {
                                  _filteredCompanies = _ComIdOptions.entries
                                      .map((e) => {
                                            'id': e.key,
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
                                            _filteredCompanies[index]['id'];
                                        _searchController.text =
                                            _filteredCompanies[index]
                                                ['company_name']!;
                                        _isFieldFocused = false;
                                        _showOtherCompanyField =
                                            _selectedCompany == 'others';
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
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.04,
                    ),
                  ],
                  const SizedBox(height: 15),
                  Text(
                    "Identification Details",
                    style: WidgetSupport.Questionblack(),
                  ),
                  Container(
                    child: Theme(
                      data: Theme.of(context)
                          .copyWith(dividerColor: Colors.transparent),
                      child: Container(
                        color: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 0.0, vertical: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                                  maxDigits: 9, isRequired: false),
                            if (_selectedIdType == IdType.sss)
                              _buildTextField2(
                                  identity_SssID, "SSS ID", "identity_SssID",
                                  maxDigits: 10, isRequired: false),
                            if (_selectedIdType == IdType.gsis)
                              _buildTextField2(
                                  identity_GsisID, "GSIS ID", "identity_GsisID",
                                  maxDigits: 11, isRequired: false),
                            // SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  Text(
                    "Income Document Type",
                    style: WidgetSupport.Questionblack(),
                  ),
                  _buildDocTypeDropdown(
                    label: "   Select Income Document",
                  ),
                  const SizedBox(height: 15),
                  Text(
                    "Montly Income (Php)",
                    style: WidgetSupport.Questionblack(),
                  ),
                  _buildTextField(monthlySalary, "Monthly Income",
                      "Please Enter Montly Salary", "monthlySalary",
                      isNumeric: true, isAlphabetic: false),
                  const SizedBox(height: 15),
                  Text(
                    "Desired Loan Amount",
                    style: WidgetSupport.Questionblack(),
                  ),
                  _buildTextField(
                    loanAmount,
                    "Loan Amount",
                    "Please Enter Loan Amount",
                    "loanAmount",
                    isNumeric: true,
                  ),
                  const SizedBox(height: 15),
                  Text(
                    "Industry Type",
                    style: WidgetSupport.Questionblack(),
                  ),
                  _buildEmpIndusTypeDropdown(
                    controller: industryType,
                    label: "   Industry Type",
                  ),
                  const SizedBox(height: 15),
                  Text(
                    "Activity Type",
                    style: WidgetSupport.Questionblack(),
                  ),
                  _buildEmpActivityTypeDropdown(
                    controller: activityType,
                    label: "   Activity Type",
                  ),
                  const SizedBox(height: 15),
                  _buildImageCaptureField(
                    context,
                    "Upload Selfie",
                    true,
                    _captureImageField1,
                    (file) => setState(() => _captureImageField1 = file),
                  ),
                  SizedBox(height: 15),
                  Text(
                    "Select Status",
                    style: WidgetSupport.Questionblack(),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(0.0),
                    child: Column(
                      children: [
                        _buildStatusDropdownField(),
                        if (formSubmition != "Interested & Eligible")
                          _builddispositionDropdownField(),
                        if (visibility != false) ...[
                          _buildDateTimeField(
                            context: context,
                            controller: callback_date,
                            label: "Follow Up Date",
                          ),
                        ],
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            leadSubmit();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            padding: EdgeInsets.symmetric(
                              horizontal:
                                  MediaQuery.of(context).size.width * 0.1,
                              vertical:
                                  MediaQuery.of(context).size.height * 0.01,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                          ),
                          child: Text(
                            "SUBMIT",
                            style: WidgetSupport.LoginButtonTextColor(),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
    );
  }

  // ===========================================================================
  File? _captureImageField1;
  Widget _buildImageCaptureField(
    BuildContext context,
    String hintText,
    bool isRequired,
    File? captureImage,
    Function(File) onImageSelected, {
    CameraDevice cameraDevice = CameraDevice.front,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: hintText,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  if (isRequired)
                    const TextSpan(
                      text: " *",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.camera_alt, color: Colors.purple),
              onPressed: fieldsDisabled
                  ? null // disables the button
                  : () async {
                      final picker = ImagePicker();
                      final XFile? pickedFile = await picker.pickImage(
                        source: ImageSource.camera,
                        preferredCameraDevice: cameraDevice,
                        // imageQuality: 85,
                        imageQuality: 60,
                      );
                      if (pickedFile != null) {
                        onImageSelected(File(pickedFile.path));
                        setState(() {
                          _networkImageUrl = null; // clear old network image
                        });
                      }
                    },
            ),
          ],
        ),
        SizedBox(height: 10),
        if (captureImage != null)
          ClipOval(
            child: Image.file(
              captureImage,
              height: 110,
              width: 110,
              fit: BoxFit.cover,
            ),
          )
        else if (_imageBytes != null)
          ClipOval(
            child: _isLoading
                ? const SizedBox(
                    height: 110,
                    width: 110,
                    child: Center(child: CircularProgressIndicator()),
                  )
                : _imageBytes != null
                    ? Image.memory(
                        _imageBytes!,
                        height: 110,
                        width: 110,
                        fit: BoxFit.cover,
                      )
                    : const SizedBox(
                        height: 110,
                        width: 110,
                        child: Icon(Icons.error, size: 60, color: Colors.red),
                      ),
          ),
      ],
    );
  }

// ============================================================

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

  bool _isValidEmail(String email) {
    final trimmed = email.trim();
    // Basic email pattern (user@domain.extension)
    final emailRegex = RegExp(
      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
    );
    return emailRegex.hasMatch(trimmed);
  }

  Future<void> leadSubmit() async {
    setState(() {
      isLoading = true;
    });

    List<String> errors = [];

    // 🔹 ID-specific validations
    if (_selectedIdType == IdType.tin) {
      if (identity_TinId.text.trim().isEmpty) {
        errors.add("TIN ID cannot be blank.");
      } else if (!_isValidIdtin(identity_TinId.text)) {
        errors.add("TIN ID must be 9 digits.");
      }
    } else if (_selectedIdType == IdType.sss) {
      if (identity_SssID.text.trim().isEmpty) {
        errors.add("SSS ID cannot be blank.");
      } else if (!_isValidIdsssid(identity_SssID.text)) {
        errors.add("SSS ID must be 10 digits.");
      }
    } else if (_selectedIdType == IdType.gsis) {
      if (identity_GsisID.text.trim().isEmpty) {
        errors.add("GSIS ID cannot be blank.");
      } else if (!_isValidIdGsisId(identity_GsisID.text)) {
        errors.add("GSIS ID must be 11 digits.");
      }
    }

    // 🔹 Email validation
    if (emailId.text.isEmpty) {
      errors.add("Email cannot be empty.");
    } else if (!_isValidEmail(emailId.text)) {
      errors.add("Please enter a valid email address.");
    }

    // 🔹 Name validation
    if (firstName.text.isEmpty) errors.add("First Name cannot be empty.");
    if (lastName.text.isEmpty) errors.add("Last Name cannot be empty.");

    // 🔹 Phone validation
    bool _isValidPhoneNumber(String text) {
      final trimmed = text.trim();
      final isDigitsOnly = RegExp(r'^[0-9]+$').hasMatch(trimmed);
      return isDigitsOnly && trimmed.length == 10;
    }

    if (mobileNumber.text.isEmpty) {
      errors.add("Mobile Number cannot be empty.");
    } else if (!_isValidPhoneNumber(mobileNumber.text)) {
      errors.add("Please enter a valid 10-digit Mobile Number.");
    }

    // 🔹 Address validation
    if (perm_ZipCode.text.isEmpty) errors.add("Zip Code cannot be empty.");
    if (perm_Barangay.text.isEmpty) errors.add("Barangay cannot be empty.");

    // 🔹 Work validation
    if (_selectedCompany == null) errors.add("Company Name cannot be empty.");
    if (selectedDocId == null) errors.add("Income Doc cannot be empty.");
    if (monthlySalary.text.isEmpty)
      errors.add("Monthly Salary cannot be empty.");
    if (loanAmount.text.isEmpty)
      errors.add("Desired Loan Amount cannot be empty.");
    if (industryType.text.isEmpty) errors.add("Industry Type cannot be empty.");

    // Image Validation
    if (_captureImageField1 == null && _networkImageUrl == null)
      errors.add("Selfie cannot be empty.");

    // 🔹 Status validation
    if (_selectedStatusCode == null) errors.add("Status must be selected.");
    // print("FFFFFF $formSubmition");
    // // Eligible-Not yet Submitted
    // if (formSubmition == "Eligible-Not yet Submitted") errors.add("Sub Status must be selected.");
    // if (_select == null) errors.add("Status must be selected.");

    // 🔹 If there are errors, show them all together
    if (errors.isNotEmpty) {
      setState(() {
        _isFieldFocused = false;
        _isLoading = false;
        isLoading = false;
      });
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Validation Errors"),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: errors.map((e) => Text("• $e")).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"),
            ),
          ],
        ),
      );
      return;
    }
    // ✅ Get trimmed values
    String first_name = firstName.text.trim();
    String middle_name = middleName.text.trim();
    String last_name = lastName.text.trim();
    String phone_number = mobileNumber.text.trim();
    String email = emailId.text.trim();
    String employer = _selectedCompany!;
    String industry_type = industryType.text.trim();
    String industry_code = industryCode.text.trim();
    String sss_id = identity_SssID.text.trim();
    String gsis_id = identity_GsisID.text.trim();
    String tin_id = identity_TinId.text.trim();
    String income_document_type = selectedDocId.toString();
    String monthly_income = monthlySalary.text.trim();
    String desired_loan_amount = loanAmount.text.trim();
    String activity = selectedActivityId.toString();
    String disposition_code = _selectedStatusCode ?? '';
    String sub_disposition_code = _selectedStatusSubCode ?? '';
    String zip_code = perm_ZipCode.text.trim();
    String region = perm_Region.text.trim();
    String province = perm_State.text.trim();
    String city = perm_City.text.trim();
    String barangay = perm_Barangay.text.trim();
    String house_street = perm_Street.text.trim();
    String _other_company_controller = _otherCompanyController.text.trim();
    String follow_up_date = callback_date.text.trim();
    // ✅ Map of field labels → values

    final Map<String, String> fieldMap = {
      "First Name": first_name,
      "Last Name": last_name,
      "Phone Number": phone_number,
      "Email": email,
      "Employer": employer,
      "Industry Type": industry_type,
      "Industry Code": industry_code,
      "Income Document Type": income_document_type,
      "Monthly Income": monthly_income,
      "Desired Loan Amount": desired_loan_amount,
      "Activity": activity,
      "Disposition Code": disposition_code,
      "Sub Disposition Code": sub_disposition_code,
      "ZIP Code": zip_code,
      "Region": region,
      "Province": province,
      "City": city,
      "Barangay": barangay,
      "House/Street": house_street,
      "Follow Up Date": follow_up_date,
    };
    setState(() {
      _isFieldFocused = false;
      _isLoading = false;
    });
    if (formSubmition == "Interested & Eligible") {
      fieldMap.remove("Sub Disposition Code");
      fieldMap.remove("Follow Up Date");
    }
    if (formSubmition == "Not Interested") {
      fieldMap.remove("Follow Up Date");
    }
    if (formSubmition == "Ineligible") {
      fieldMap.remove("Follow Up Date");
    }
    if (employer == 'others') {
      fieldMap.remove("Employer");
      employer = "";
    }

// ✅ Find all blank fields
    final blankFields = fieldMap.entries
        .where((entry) => entry.value.isEmpty)
        .map((e) => e.key)
        .toList();

    if (blankFields.isNotEmpty) {
      setState(() {
        _isFieldFocused = false;
        _isLoading = false;
        isLoading = false;
      });
      // ✅ Show alert listing all missing fields
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Missing Information"),
          content: Text(
            "Please fill the following fields:\n\n${blankFields.join(", ")}",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"),
            ),
          ],
        ),
      );
      return;
    }
    // ✅ Location check
    // if (_latitude == null || _longitude == null || _currentAddress.isEmpty) {
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     const SnackBar(
    //       content: Text("Unable to fetch location. Please try again."),
    //       backgroundColor: Colors.red,
    //     ),
    //   );
    //   return;
    // }
    DateTime now = DateTime.now();
    String ended_at = now.toIso8601String();
    String? callBackDate;

    if (visibility == false) {
      callBackDate = null; // explicitly set null
    } else {
      callBackDate = callback_date.text.isNotEmpty ? callback_date.text : null;
    }
    String formattedBirthDate;
    if (callBackDate != null && callBackDate.isNotEmpty) {
      try {
        // Adjust to match your actual incoming string
        final parsedDate = DateFormat('dd-MM-yyyy HH:mm').parse(callBackDate);

        // Now format to the desired output
        formattedBirthDate =
            DateFormat("yyyy-MM-dd'T'HH:mm:ss").format(parsedDate);

        print("Formatted Date: $formattedBirthDate");
      } catch (e) {
        print("❌ Date parsing error: $e");
        formattedBirthDate = '';
      }
    } else {
      formattedBirthDate = "";
    }

    // ✅ Proceed with your mappedData
    Map<String, String> mappedData = {
      'first_name': first_name,
      'middle_name': middle_name,
      'last_name': last_name,
      'phone_number': '63' + phone_number,
      'email': email,
      'employer': employer,
      'industry_type': industry_type,
      'industry_code': industry_code,
      'sss_id': sss_id,
      'gsis_id': gsis_id,
      'tin_id': tin_id,
      'income_document_type': income_document_type,
      'monthly_income': monthly_income,
      'desired_loan_amount': desired_loan_amount,
      'activity': activity,
      'disposition_code': disposition_code,
      'sub_disposition_code': sub_disposition_code,
      'zip_code': zip_code,
      'region': region,
      'province': province,
      'city': city,
      'barangay': barangay,
      'house_street': house_street,
      'other_employer': _other_company_controller.toString(),
      'other_activity': "",
      'location_name': _currentAddress,
      'latitude': _latitude?.toStringAsFixed(10) ?? '00.00',
      'longitude': _longitude?.toStringAsFixed(10) ?? '00.00',
      if (widget.pagemode != "edit") 'started_at': startTime,
      if (widget.pagemode != "edit") 'ended_at': ended_at,
    };
    if (formattedBirthDate != "" && formattedBirthDate.isNotEmpty) {
      mappedData["follow_up_date"] = formattedBirthDate;
    }
    // ✅ Post the data
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('accessToken');
    var url = "";
    if (widget.pagemode == 'edit') {
      url = '/api/timesheet/agent-daily-sales/${widget.dsrId}/';
    } else {
      url = '/api/timesheet/agent-daily-sales/';
    }
    final headers = {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      'User-Agent':
          'Mozilla/5.0 (Linux; Android 11; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36',
    };
    String jsonString = jsonEncode(mappedData);

    // for (int i = 0; i < jsonString.length; i += 1000) {
    //   print(jsonString.substring(i,
    //       (i + 1000 > jsonString.length) ? jsonString.length : i + 1000));
    // }

    if (widget.pagemode != "edit") {
      // final response =
      //     await ApiService.postJsonWithHeaders(url, mappedData, headers);

      final response = await ApiService.postWithHeadersUploadMultiPart(
          url, headers, mappedData,
          imageFile: _captureImageField1);
      //print("response body no edit is ${response?.body}");
      try {
        String dsrId = "";
        if (response != null && (response.statusCode == 201)) {
          final data = response.data;

          dsrId = data['id'].toString();
          // ✅ Show success dialog
          if (formSubmition == "Interested & Eligible") {
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: const Text("Application"),
                  content: const Text(
                    "Form Submitted Successfully",
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => LosApplicationPage(
                              leadId: "",
                              campaign: "",
                              pagemode: "fromDSR",
                              dsrId: dsrId,
                              CWTransactionID: '',
                            ),
                          ),
                        );
                      },
                      child: const Text("OK"),
                    ),
                  ],
                );
              },
            );
          } else {
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: const Text("Application"),
                  content: const Text(
                    "Form Submitted Successfully",
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DailySalesReportList(
                              searchQuery: '',
                            ),
                          ),
                        );
                      },
                      child: const Text("OK"),
                    ),
                  ],
                );
              },
            );
          }
        } else if (response != null && response.statusCode == 401) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text("Session expired. Please login again.")),
          );
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("An error occurred: ${response?.data}")),
        );
      }
    } else {
      // final response =
      //     await ApiService.patchWithHeaders(url, headers, mappedData);

      final response = await ApiService.patchWithHeadersUploadMultiPart(
          url, headers, mappedData,
          imageFile: _captureImageField1);
      //print("response body edit is ${response?.body}");
      try {
        String dsrId = "";
        if (response != null && (response.statusCode == 200)) {
          final data = response.data;
          dsrId = data['id'].toString();
          // ✅ Show success dialog
          if (formSubmition == "Interested & Eligible") {
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: const Text("Application"),
                  content: const Text(
                    "Form Update Successfully",
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => LosApplicationPage(
                              leadId: "",
                              campaign: "",
                              pagemode: "fromDSR",
                              dsrId: dsrId,
                              CWTransactionID: '',
                            ),
                          ),
                        );
                      },
                      child: const Text("OK"),
                    ),
                  ],
                );
              },
            );
          } else {
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: const Text("Application"),
                  content: const Text(
                    "Form Update Successfully",
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DailySalesReportList(
                              searchQuery: '',
                            ),
                          ),
                        );
                      },
                      child: const Text("OK"),
                    ),
                  ],
                );
              },
            );
          }
        } else if (response != null && response.statusCode == 401) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text("Session expired. Please login again.")),
          );
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("An error occurred: $e")),
        );
      }
    }

    setState(() {
      _isLoading = false;
    });
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
      enableInteractiveSelection: !readOnly,
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
              suffixIcon: Icon(icon, color: Colors.purple, size: 15),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildZipTextField(
    TextEditingController controller,
    String label,
    String validationMessage,
    String fieldKey, {
    bool isRequired = false,
    bool isZip = false,
    bool isNumeric = false,
    Function(String)? onSubmitted,
    Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        contentPadding: const EdgeInsets.only(left: 5),
        prefix: const SizedBox(width: 10),
      ),
      keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
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
        contentPadding: const EdgeInsets.only(left: 5),
        prefix: const SizedBox(width: 9),
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
        contentPadding: EdgeInsets.only(left: 12),
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

  Widget _buildDocTypeDropdown({
    required String label,
    bool isRequired = true,
  }) {
    return DropdownButtonFormField<int>(
      isExpanded: true,
      value: selectedDocId, // must be int? (nullable)
      items: docTypelist.map((item) {
        return DropdownMenuItem<int>(
          value: item['id'] as int,
          child: Text(item['name'] ?? ''),
        );
      }).toList(),
      onChanged: (int? newValue) {
        setState(() {
          selectedDocId = newValue;
          // If you want to set a TextController too:
          // controller.text = docTypelist.firstWhere((e) => e['id']==newValue)['name'];
        });
      },
      decoration: InputDecoration(
        prefix: SizedBox(
          width: 9,
        ),
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
      ),
      validator: (value) {
        if (isRequired && value == null) {
          return "Please select $label";
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
            industryCode.text = selectedItem['key'] ?? '';
          });
        }
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

  Widget _buildEmpActivityTypeDropdown({
    required TextEditingController controller,
    required String label,
    bool isRequired = true,
  }) {
    return DropdownButtonFormField<int>(
      isExpanded: true,
      value: selectedActivityId, // must be int? (nullable)
      items: activityTypelist.map((item) {
        return DropdownMenuItem<int>(
          value: item['id'] as int,
          child: Text(item['name'] ?? ''),
        );
      }).toList(),
      onChanged: (int? newValue) {
        setState(() {
          selectedActivityId = newValue;
          // If you want to set a TextController too:
          // controller.text = docTypelist.firstWhere((e) => e['id']==newValue)['name'];
        });
      },
      decoration: InputDecoration(
        contentPadding: EdgeInsets.only(left: 9),
        prefix: SizedBox(
          width: 7,
        ),
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
      ),
      validator: (value) {
        if (isRequired && value == null) {
          return "Please select $label";
        }
        return null;
      },
    );
  }

  Widget _buildStatusDropdownField() {
    return Stack(
      alignment: Alignment.centerRight,
      children: [
        DropdownSearch<String>(
          popupProps: PopupProps.menu(
            showSearchBox: false,
            fit: FlexFit.loose,
          ),
          items: StatusCode.values.toList(),
          dropdownDecoratorProps: DropDownDecoratorProps(
            dropdownSearchDecoration: InputDecoration(
              // contentPadding: EdgeInsets.only(left: 17),
              prefix: SizedBox(
                width: 10,
              ),
              hintText: "Select Status",
              hintStyle: WidgetSupport.inputLabel(),
            ),
          ),
          selectedItem: _selectedStatusCode != null
              ? StatusCode[_selectedStatusCode]
              : null,
          onChanged: (String? newValue) {
            if (newValue != null) {
              setState(() {
                _selectedStatusCode = StatusCode.entries
                    .firstWhere((entry) => entry.value == newValue)
                    .key;
                isLoading = true; // start loader
              });
            }
            setState(() {
              formSubmition = newValue.toString();
              _loadDependentData(_selectedStatusCode!, formSubmition);
              visibility = newValue == "Eligible-Not yet Submitted";
              if (newValue == "Eligible-Not yet Submitted") {
                visibility = true;
                isLoading = false;
              } else {
                setState(() {
                  visibility = false;
                  isLoading = false;
                });
              }
            });
          },
          validator: (value) {
            if (value == null || value.isEmpty) return '   Select Status';
            return null;
          },
          dropdownBuilder: (BuildContext context, String? selectedItem) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  selectedItem ?? "Select Status",
                  style: WidgetSupport.dropDownText(),
                ),
                const SizedBox(width: 2),
                const Text('*',
                    style: TextStyle(color: Colors.red, fontSize: 25)),
              ],
            );
          },
        ),
        // Loader on the right side of dropdown
        if (isLoading)
          Container(
            color: Colors.white
                .withOpacity(0.7), // optional semi-transparent overlay
            child: const Center(
              child: SizedBox(
                width: 25,
                height: 25,
                child: CircularProgressIndicator(strokeWidth: 3),
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _loadDependentData(statusId, formSubmition) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('accessToken');
    try {
      String url = "/api/leads/disposition-codes/$statusId/";
      final headers = {
        'Authorization': 'Bearer $token',
        'User-Agent':
            'Mozilla/5.0 (Linux; Android 11; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36',
      };
      final response = await ApiService.getWithHeaders(url, headers);

      if (response != null) {
        if (response.statusCode == 200) {
          var decodedResponse = response.data;

          // ✅ If API returns a Map with sub_disposition_codes
          if (decodedResponse is Map<String, dynamic>) {
            if (decodedResponse.containsKey('sub_disposition_codes')) {
              decodedResponse = decodedResponse['sub_disposition_codes'];
            } else if (decodedResponse.containsKey('results')) {
              decodedResponse = decodedResponse['results'];
            }
          }
          if (decodedResponse is List) {
            Map<String, String> fetchedData = {};
            String? matchedStatusCode;
            String? matchedCallBackStatusCode;

            for (var item in decodedResponse) {
              final id = (item['id'] ?? '').toString();
              final description = (item['description'] ?? '').toString();
              fetchedData[id] = description;
              if (leadDetails['sub_disposition_code']?.toString() == id) {
                matchedStatusCode = id;
                matchedCallBackStatusCode = description;
              }
            }

            setState(() {
              isLoading = false;
              _dependentData = fetchedData;
              _selectedStatusSubCode = matchedStatusCode;
              if (matchedCallBackStatusCode != null) {
                featchCallBackStatus = matchedCallBackStatusCode;
              }
              if (formSubmition == "Eligible-Not yet Submitted") {
                if (featchCallBackStatus == "Call Back") {
                  String rawDate = leadDetails['follow_up_date'];
                  DateTime originalDate =
                      DateTime.parse(rawDate).toUtc().add(Duration(hours: 8));
                  String formattedDate =
                      DateFormat('yyyy-MM-dd HH:mm').format(originalDate);
                  callback_date.text = formattedDate;
                }
                print(callback_date.text);
                visibility = true;
              }
              isLoading = false;
              print(visibility);
            });
          } else {
            throw Exception('Unexpected response format');
          }
        } else if (response.statusCode == 401) {
          // refresh token logic...
        } else {
          throw Exception('Failed to load dependent data');
        }
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  Widget _builddispositionDropdownField() {
    return Stack(
      alignment: Alignment.centerRight,
      children: [
        DropdownSearch<String>(
          popupProps: PopupProps.menu(
            showSearchBox: false,
            fit: FlexFit.loose,
          ),
          items: _dependentData.values.toList(),
          dropdownDecoratorProps: DropDownDecoratorProps(
            dropdownSearchDecoration: InputDecoration(
              contentPadding: EdgeInsets.only(left: 10, top: 5),
              hintText: "Select Sub Status",
              hintStyle: WidgetSupport.inputLabel(),
            ),
          ),
          selectedItem: _selectedStatusSubCode != null
              ? _dependentData[_selectedStatusSubCode]
              : null,
          onChanged: (String? newValue) {
            if (newValue != null) {
              setState(() {
                _selectedStatusSubCode = _dependentData.entries
                    .firstWhere((entry) => entry.value == newValue)
                    .key;
                _subdependentData = {};
                // Additional logic for visibility if needed
              });
            }
          },
          validator: (value) {
            if (value == null || value.isEmpty) return '   Select Sub Status';
            return null;
          },
          dropdownBuilder: (BuildContext context, String? selectedItem) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  selectedItem ?? "   Select Sub Status",
                  style: WidgetSupport.dropDownText(),
                ),
                const SizedBox(width: 2),
                if (formSubmition != "Interested & Eligible")
                  const Text('*',
                      style: TextStyle(color: Colors.red, fontSize: 25)),
              ],
            );
          },
        ),
        // Loader on the right side
        if (isLoading)
          Container(
            color: Colors.white
                .withOpacity(0.7), // optional semi-transparent overlay
            child: const Center(
              child: SizedBox(
                width: 25,
                height: 25,
                child: CircularProgressIndicator(strokeWidth: 3),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDateTimeField({
    required BuildContext context,
    required TextEditingController controller,
    required String label,
    bool isRequired = true,
  }) {
    return GestureDetector(
      onTap: () {
        DatePickerBdaya.showDateTimePicker(
          context,
          showTitleActions: true,
          minTime: DateTime(1900),
          maxTime: DateTime.now(),
          onConfirm: (date) {
            controller.text = DateFormat('dd-MM-yyyy HH:mm').format(date);
          },
          currentTime: DateTime.now(),
          locale: LocaleType.en,
        );
      },
      child: AbsorbPointer(
        child: TextFormField(
          controller: controller,
          decoration: InputDecoration(
            hintText: 'DD-MM-YYYY HH:MM',
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
            suffixIcon:
                const Icon(Icons.access_time, color: Colors.purple, size: 15),
          ),
          validator: (value) {
            if (isRequired && (value == null || value.trim().isEmpty)) {
              return "Please select date and time";
            }
            return null;
          },
        ),
      ),
    );
  }
}
