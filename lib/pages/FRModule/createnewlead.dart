import 'dart:convert';
import 'dart:io';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unosfa/pages/FRModule/leaddashboard.dart';
import 'package:unosfa/pages/generalscreens/customNavigation.dart';
import 'package:unosfa/pages/services/api_service.dart';
import 'package:unosfa/widgetSupport/widgetstyle.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as path;

class LeadGenerate extends StatefulWidget {
  final String edit;
  const LeadGenerate({Key? key, required this.edit}) : super(key: key);
  @override
  _LeadGenerateState createState() => _LeadGenerateState();
}

class _LeadGenerateState extends State<LeadGenerate> {
  final _formKey = GlobalKey<FormState>();
  // final _companyName = TextEditingController();
  final _fname = TextEditingController();
  final _mname = TextEditingController();
  final _lname = TextEditingController();
  final _phoneNumber = TextEditingController();
  final _address1 = TextEditingController();
  final _address2 = TextEditingController();
  final _zip = TextEditingController();
  final _email = TextEditingController();
  final _location = TextEditingController();
  final _area = TextEditingController();
  final _income = TextEditingController();
  final _loanamount = TextEditingController();
  final _businessNameController = TextEditingController();
  final _imageController = TextEditingController();
  final _externalId = TextEditingController();

  bool _isLoading = false;
  late Map<String, String> _ComIdOptions;
  late Map<String, String> _TenorIdOptions;

  late List<Map<String, String>> _Tenor = [];

// Initialize as an empty map
  late List<Map<String, String>> _filteredCompanies;
  late Map<String, String> _CityIdOptions;
  late List<Map<String, String>> _filteredCity;

  late List<Map<String, String>> _barangay = [];
  String? _selectedDocument;
  TextEditingController _searchController = TextEditingController();
  TextEditingController _citysearchController = TextEditingController();
  String? _selectedCompany;
  bool _isFieldFocused = false;
  String? _selectedGId;
  bool _selectedKycId = false;
  final _otherCompanyController = TextEditingController();
  bool _showOtherCompanyField = false;
  String? _cityError;
  String _imageUrl = "";
  Uint8List? _imageBytes;
  bool _isCityDropdownVisible = false;
  final FocusNode _dummyFocusNode = FocusNode();
  final FocusNode _dropdownFocusNode = FocusNode();
  bool _isDropdownVisible = false;
  final FocusNode _cityDropdownFocusNode = FocusNode();

  final Map<String, String> _gIdOptions = {
    'passport': 'Philippines Passport',
    'national_id': 'Philippine National ID (PhilSys ID)',
    'drivers_license': 'Driver\'s License',
    'umid': 'Unified Multi-Purpose ID (UMID)',
    'sss_id': 'Social Security System (SSS) ID',
    'prc_id': 'Professional Regulation Commission (PRC) ID'
  };
  String _getIdHintText() {
    switch (_selectedGId) {
      case 'passport':
        return 'Enter your Philippines Passport Number';
      case 'national_id':
        return 'Enter your PhilSys ID';
      case 'drivers_license':
        return 'Enter your Driver’s License Number';
      case 'umid':
        return 'Enter your Unified Multi-Purpose ID';
      case 'sss_id':
        return 'Enter your Social Security System (SSS) ID';
      case 'prc_id':
        return 'Enter your Professional Regulation Commission (PRC) ID';
      default:
        return 'Enter ID Number';
    }
  }

  String? _selectedCustType;
  final Map<String, String> _CustomerType = {
    'salaried': 'Salaried ',
    'self_employed': 'Self-employed',
  };
  @override
  void initState() {
    super.initState();
    _ComIdOptions = {};
    _filteredCompanies = [];
    _Tenor = [];
    _ComIdOptions = {};
    _filteredCity = [];
    _loadData();
    _loadTenorData();
    _loadDocData();
    _loadCityData();
    if (widget.edit != "") {
      _loadEditLead();
    }
    _dropdownFocusNode.addListener(() {
      if (!_dropdownFocusNode.hasFocus) {
        setState(() {
          _isDropdownVisible = false;
        });
      }
    });
    _cityDropdownFocusNode.addListener(() {
      if (!_cityDropdownFocusNode.hasFocus) {
        setState(() {
          _isCityDropdownVisible = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _dropdownFocusNode.dispose();
    _searchController.dispose();
    _dummyFocusNode.dispose();
    _citysearchController.dispose();
    super.dispose();
  }

  // Load initial company data
  Future<void> _loadData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('accessToken');
    String? refresh = prefs.getString('refreshToken');
    try {
      String url = "/api/leads/companies/?page_size=10";
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
          String url2 = "/api/users/token-refresh/";
          final response2 = await ApiService.post(url2, mappedData);
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
      String url = "/api/leads/companies/?search=$query";
      final headers = await _getAuthHeader();
      final response = await ApiService.getWithHeaders(url, headers);
      if (response != null) {
        if (response.statusCode == 200) {
          final Map<String, dynamic> data = json.decode(response.data);
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
          String url2 = "/api/users/token-refresh/";
          final response2 = await ApiService.post(url2, mappedData);
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

  Future<Map<String, String>> _getAuthHeader() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('accessToken');
    return {'Authorization': 'Bearer $token'};
  }

  String? _selectedTenor;
  Future<void> _loadTenorData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.getString('accessToken');
    String? refresh = prefs.getString('refreshToken');
    try {
      String url = "/api/leads/tenors/";
      final headers = await _getAuthHeader();
      final response = await ApiService.getWithHeaders(url, headers);
      if (response != null) {
        if (response.statusCode == 200) {
          final Map<String, dynamic> data = json.decode(response.data);
          if (data['results'] != null && data['results'] is List) {
            List<dynamic> tenor = data['results'];

            Map<String, String> fetchedData = {};
            for (var item in tenor) {
              fetchedData[item['id'].toString()] =
                  item['description'].toString();
            }

            setState(() {
              _ComIdOptions = fetchedData;
              // Initially, show all companies in the list
              _Tenor = fetchedData.entries
                  .map((e) => {'id': e.key, 'description': e.value})
                  .toList();
            });
          }
        } else if (response.statusCode == 401) {
          Map<String, String> mappedData = {
            'refresh': refresh ?? '',
          };
          String url2 = "/api/users/token-refresh/";
          final response2 = await ApiService.post(url2, mappedData);
          if (response2 != null) {
            final data = json.decode(response2.body);
            await prefs.setBool('isLoggedIn', true);
            await prefs.setString('accessToken', data['access']);
            await prefs.setString('refreshToken', data['refresh']);
            _loadTenorData();
          }
        } else {
          throw Exception('Failed to load location types');
        }
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  String? _selectedPricing;
  final Map<String, String> _pricing = {'1.99': '1.99%'};
  Future<void> _loadDocData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.getString('accessToken');
    String? refresh = prefs.getString('refreshToken');
    try {
      String url = "/api/leads/document-types/";
      final headers = await _getAuthHeader();
      final response = await ApiService.getWithHeaders(url, headers);
      if (response != null) {
        if (response.statusCode == 200) {
          final Map<String, dynamic> data = json.decode(response.data);
          if (data['results'] != null && data['results'] is List) {
            List<dynamic> docs = data['results'];

            Map<String, String> fetchedData = {};
            for (var item in docs) {
              fetchedData[item['id'].toString()] =
                  item['description'].toString();
            }

            setState(() {
              _ComIdOptions = fetchedData;
              // Initially, show all companies in the list
            });
          }
        } else if (response.statusCode == 401) {
          Map<String, String> mappedData = {
            'refresh': refresh ?? '',
          };
          String url2 = "/api/users/token-refresh/";
          final response2 = await ApiService.post(url2, mappedData);
          if (response2 != null) {
            final data = json.decode(response2.body);
            await prefs.setBool('isLoggedIn', true);
            await prefs.setString('accessToken', data['access']);
            await prefs.setString('refreshToken', data['refresh']);
            _loadDocData();
          }
        } else {
          throw Exception('Failed to load document type');
        }
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  String? _selectedCity; // To store the selected city

  // Map to hold the city value (key) and display text (value)
  Future<void> _loadCityData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.getString('accessToken');
    String? refresh = prefs.getString('refreshToken');
    try {
      String url = "/api/leads/cities/";
      final headers = await _getAuthHeader();
      final response = await ApiService.getWithHeaders(url, headers);
      if (response != null) {
        if (response.statusCode == 200) {
          final Map<String, dynamic> data = json.decode(response.data);
          if (data['results'] != null && data['results'] is List) {
            List<dynamic> citydata = data['results'];
            Map<String, String> fetchedData = {};
            for (var item in citydata) {
              fetchedData[item['id'].toString()] = item['city_name'].toString();
            }

            setState(() {
              _CityIdOptions = fetchedData;
              _filteredCity = _CityIdOptions.entries
                  .map((e) => {'id': e.key, 'city_name': e.value})
                  .toList();
            });
          }
        } else if (response.statusCode == 401) {
          String url2 = "/api/users/token-refresh/";
          Map<String, String> mappedData = {'refresh': refresh ?? ''};
          final response2 = await ApiService.post(url2, mappedData);
          if (response2 != null) {
            final data = json.decode(response2.body);
            await prefs.setBool('isLoggedIn', true);
            await prefs.setString('accessToken', data['access']);
            await prefs.setString('refreshToken', data['refresh']);
            _loadCityData();
          }
        } else {
          throw Exception('Failed to load cities');
        }
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  // Search for companies based on the query
  Future<void> _filterCity(String query) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (query.isEmpty) {
      setState(() {
        _filteredCity = _CityIdOptions.entries
            .map((e) => {'id': e.key, 'city_name': e.value})
            .toList();
      });
      return;
    }

    try {
      String url = '/api/leads/cities/?search=$query';
      final headers = await _getAuthHeader();
      final response = await ApiService.getWithHeaders(url, headers);
      if (response != null) {
        if (response.statusCode == 200) {
          final Map<String, dynamic> data = json.decode(response.data);
          if (data['results'] != null && data['results'] is List) {
            List<dynamic> cityData = data['results'];

            setState(() {
              _filteredCity = cityData
                  .map((e) => {
                        'id': e['id'].toString(),
                        'city_name': e['city_name'].toString(),
                      })
                  .toList();
              _loadBarangayData(query);
            });
          }
        } else if (response.statusCode == 401) {
          String? refresh = prefs.getString('refreshToken');
          Map<String, String> mappedData = {
            'refresh': refresh ?? '',
          };
          String url2 = "/api/users/token-refresh/";
          final response2 = await ApiService.post(url2, mappedData);
          if (response2 != null) {
            final data = json.decode(response2.body);
            await prefs.setBool('isLoggedIn', true);
            await prefs.setString('accessToken', data['access']);
            await prefs.setString('refreshToken', data['refresh']);
            _filterCity(query);
          }
        } else {
          throw Exception('Failed to search City');
        }
      }
    } catch (e) {
      print('Search Error: $e');
    }
  }

  String? _selectedBarangayType;

  Future<void> _loadBarangayData(String query2) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.getString('accessToken');
    String? refresh = prefs.getString('refreshToken');
    try {
      String url = "/api/leads/cities/${_selectedCity}/";
      final headers = await _getAuthHeader();
      final response = await ApiService.getWithHeaders(url, headers);
      if (response != null) {
        if (response.statusCode == 200) {
          final Map<String, dynamic> data = json.decode(response.data);
          if (data['barangays'] != null && data['barangays'] is List) {
            List<dynamic> barangays = data['barangays'];

            Map<String, String> fetchedData = {};
            for (var item in barangays) {
              fetchedData[item['id'].toString()] =
                  item['barangay_name'].toString();
            }

            setState(() {
              _ComIdOptions = fetchedData;
              // Initially, show all companies in the list
              _barangay = fetchedData.entries
                  .map((e) => {'id': e.key, 'barangay_name': e.value})
                  .toList();
            });
          }
        } else if (response.statusCode == 401) {
          Map<String, String> mappedData = {
            'refresh': refresh ?? '',
          };
          String url2 = "/api/users/token-refresh/";
          final response2 = await ApiService.post(url2, mappedData);
          if (response2 != null) {
            final data = json.decode(response2.body);
            await prefs.setBool('isLoggedIn', true);
            await prefs.setString('accessToken', data['access']);
            await prefs.setString('refreshToken', data['refresh']);
            _getAuthHeader();
          }
        } else {
          throw Exception('Failed to load baragay');
        }
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  String numericCommaInputFormatter(dynamic value) {
    if (value == null || value.toString().isEmpty) {
      return '';
    }

    // Parse the value to a number
    final number = double.tryParse(value.toString());
    if (number == null) {
      return '';
    }

    // Format the number without trailing .00
    final formatted = number.toStringAsFixed(2).replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+(\.\d{0,2})?$)'),
          (Match match) => '${match[1]},',
        );

    // Remove unnecessary .00 at the end
    return formatted.endsWith('.00') ? formatted.split('.')[0] : formatted;
  }

  Future<File> urlToFile(String imageUrl) async {
    final response = await http.get(Uri.parse(imageUrl));
    final documentDirectory = await getTemporaryDirectory();
    final fileName = imageUrl.split('/').last;

    final file = File('${documentDirectory.path}/$fileName');
    print(file);
    file.writeAsBytesSync(response.bodyBytes);
    return file;
  }

  Future<void> _loadEditLead() async {
    _isLoading = true;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.getString('refreshToken');
    try {
      String url = "/api/leads/${widget.edit}/";
      final headers = await _getAuthHeader();
      final response = await ApiService.getWithHeaders(url, headers);
      if (response != null) {
        final data = json.decode(response.data);
        String cityUrl = "/api/leads/cities/?search=${data['city_name']}";
        final cityresponse = await ApiService.getWithHeaders(cityUrl, headers);
        if (cityresponse != null) {
          final Map<String, dynamic> data44 = json.decode(cityresponse.data);
          if (data44['results'] != null && data44['results'] is List) {
            List<dynamic> citydata = data44['results'];
            Map<String, String> fetchedData = {};
            // Map<String, String> fetchedData2 = {};

            for (var item in citydata) {
              fetchedData[item['id'].toString()] = item['city_name'].toString();
            }
            setState(() {
              _CityIdOptions = fetchedData;
              _filteredCity = _CityIdOptions.entries
                  .map((e) => {'id': e.key, 'city_name': e.value})
                  .toList();

              _selectedCity = data['city'].toString();
              _citysearchController.text = _CityIdOptions[_selectedCity] ?? '';
              //  _selectedCity = data['city'].toString();
              // _barangay = _CityIdOptions[_selectedCity] ?? '';
            });
          }
          String locationUrl = "/api/leads/location-types/";
          final locationresponse =
              await ApiService.getWithHeaders(locationUrl, headers);
          if (locationresponse != null) {
            final Map<String, dynamic> data2 =
                json.decode(locationresponse.data);
            if (data2['results'] != null && data2['results'] is List) {
              List<dynamic> location = data2['results'];
              Map<String, String> fetchedData2 = {};
              for (var item in location) {
                fetchedData2[item['id'].toString()] = item['id'].toString();
              }
              _ComIdOptions = fetchedData2;
            }
            String activityUrl = "/api/leads/activities/";
            final activityresponse =
                await ApiService.getWithHeaders(activityUrl, headers);
            if (activityresponse != null) {
              final Map<String, dynamic> data3 =
                  json.decode(activityresponse.data);
              if (data3['results'] != null && data3['results'] is List) {
                List<dynamic> activity = data3['results'];
                Map<String, String> fetchedData3 = {};
                for (var item in activity) {
                  fetchedData3[item['id'].toString()] = item['id'].toString();
                }
                _ComIdOptions = fetchedData3;
              }
              String tenorUrl = "/api/leads/tenors/";
              final tenorsresponse =
                  await ApiService.getWithHeaders(tenorUrl, headers);
              if (tenorsresponse != null) {
                final Map<String, dynamic> data4 =
                    json.decode(tenorsresponse.data);
                if (data4['results'] != null && data4['results'] is List) {
                  List<dynamic> tenor = data4['results'];
                  Map<String, String> fetchedData4 = {};
                  for (var item in tenor) {
                    fetchedData4[item['id'].toString()] = item['id'].toString();
                  }
                  _TenorIdOptions = fetchedData4;
                }
                // final Map<String, dynamic> kycIdata = _gIdOptions;
                final String? kycIdType = data['kyc_id_type'];
                if (kycIdType != null && _gIdOptions.containsKey(kycIdType)) {
                  _selectedGId =
                      kycIdType; // Assign the key instead of the value
                }
                String barangayUrl = "/api/leads/cities/${data['city']}/";
                final barangayresponse =
                    await ApiService.getWithHeaders(barangayUrl, headers);
                if (barangayresponse != null) {
                  final Map<String, dynamic> data6 =
                      json.decode(barangayresponse.data);

                  if (data6['barangays'] != null &&
                      data6['barangays'] is List) {
                    setState(() {
                      _barangay = List<Map<String, String>>.from(
                          data6['barangays'].map((item) {
                        return {
                          'id': item['id'].toString(),
                          'barangay_name': item['barangay_name'].toString(),
                        };
                      }));

                      // Ensure the selected barangay is correctly set
                      _selectedBarangayType = data['barangay']?.toString();
                    });
                  }
                  String companyUrl = "/api/leads/companies/?page_size=100/";
                  final companyResponse =
                      await ApiService.getWithHeaders(companyUrl, headers);
                  if (companyResponse != null) {
                    final Map<String, dynamic> dataComp =
                        json.decode(companyResponse.data);

                    if (dataComp['results'] != null &&
                        dataComp['results'] is List) {
                      List<dynamic> companies = dataComp['results'];

                      Map<String, String> fetchedDataComp = {};
                      for (var item in companies) {
                        fetchedDataComp[item['id'].toString()] =
                            item['company_name'].toString();
                      }

                      setState(() {
                        _ComIdOptions = fetchedDataComp;

                        // Ensure the selected company is set correctly
                        _selectedCompany = data['company']?.toString() ?? '';

                        // Populate the search field with the selected company's name
                        _searchController.text =
                            _ComIdOptions[_selectedCompany] ?? '';

                        // Initialize filtered company list
                        _filteredCompanies = _ComIdOptions.entries
                            .map((e) => {'id': e.key, 'company_name': e.value})
                            .toList();
                      });
                    }
                    if (response.statusCode == 200) {
                      setState(() {
                        _fname.text = data['first_name'];
                        _mname.text = data['middle_name'];
                        _lname.text = data['last_name'];
                        _phoneNumber.text = data['phone_number'];
                        _address1.text = data['address1'];
                        _address2.text = data['address2'];
                        _email.text = data['email'];
                        _zip.text = data['zip'];
                        _area.text = data['area'] ?? '';
                        _income.text = numericCommaInputFormatter(
                            double.parse(data['income']));
                        if (data != null &&
                            data['loan_amount_requested'] != null) {
                          final loanAmount = double.tryParse(
                              data['loan_amount_requested'].toString());
                          if (loanAmount != null) {
                            _loanamount.text =
                                numericCommaInputFormatter(loanAmount);
                          } else {
                            _loanamount.text = '';
                          }
                        } else {
                          _loanamount.text = '';
                        }
                        _businessNameController.text =
                            data['business_name'] ?? '';
                        _location.text = data['location'];
                        _externalId.text = data['kyc_id_number'] ?? '';
                        _imageController.text = data['kyc_document'] ?? '';
                        for (var entry2 in _ComIdOptions.entries) {
                          if (data['location_type'].toString() ==
                              entry2.value) {
                            break;
                          }
                        }
                        for (var entry3 in _ComIdOptions.entries) {
                          if (data['activity'].toString() == entry3.value) {
                            break;
                          }
                        }
                        for (var entry4 in _TenorIdOptions.entries) {
                          if (data['tenor'].toString() == entry4.value) {
                            _selectedTenor = entry4.key;
                            break;
                          }
                        }
                        if (data['customer_type'] == 'salaried') {
                          _selectedCustType = "salaried";
                        } else {
                          _selectedCustType = "self_employed";
                        }
                        for (var entry7 in _ComIdOptions.entries) {
                          if (data['company'].toString() == entry7.value) {
                            _selectedCompany = entry7.key;
                            break;
                          }
                        }
                        if (data['kyc_document'] != null &&
                            data['kyc_document'].isNotEmpty) {
                          _imageUrl = data['kyc_document'];
                          _fetchImage(_imageUrl);

                          downloadFile(data['kyc_document']).then((file) {
                            if (file != null) {
                              setState(() {
                                _image = file; // Now _image is a File object
                              });
                            }
                          });
                        }
                        _isLoading = false;
                      });
                    } else {
                      throw Exception('Failed to load');
                    }
                  }
                }
              }
            }
          }
        }
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  Future<void> _fetchImage(String imageUrl) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('accessToken');

    try {
      final headers = {
      'Authorization': 'Bearer $token',
      'User-Agent':
          'Mozilla/5.0 (Linux; Android 11; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36',
    };
      final response = await ApiService.getWithHeaders(imageUrl, headers);
      if (response != null) {
        if (response.statusCode == 200) {
          Uint8List imageBytes = response.data;
          if (imageBytes.isNotEmpty) {
            setState(() {
              _imageBytes = imageBytes;
              _isLoading = false;
            });
            downloadFile(_imageUrl);
          } else {
            _handleImageError();
          }
        } else {
          _handleImageError();
        }
      }
    } catch (e) {
      print("Image loading error: $e");
      _handleImageError();
    }
  }

  Future<File?> downloadFile(String imageUrl) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('accessToken'); // Retrieve access token

    if (token == null || token.isEmpty) {
      print("Error: Missing access token");
      return null;
    }

    try {
      final headers = {
        'Authorization': 'Bearer $token',
        'User-Agent':
                'Mozilla/5.0 (Linux; Android 11; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36',
      };
      final response = await ApiService.getWithHeaders(imageUrl, headers);
      if (response != null) {
        if (response.statusCode == 200) {
          final tempDir = await getTemporaryDirectory();
          final fileName = Uri.parse(imageUrl).pathSegments.last;
          final filePath = '${tempDir.path}/$fileName';
          final _image = File(filePath);
          await _image.writeAsBytes(response.data);

          return _image;
        } else {
          print("Failed to download image: ${response.statusCode}");
          return null;
        }
      }
    } catch (e) {
      print("Error downloading image: $e");
      return null;
    }
    return null;
  }

  void _handleImageError() {
    setState(() {
      _isLoading = false;
      _imageBytes = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(60.0), // Adjust the height as needed
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFFc433e0), // Start color of the gradient
                Color(0xFF9a37ae), // End color of the gradient
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: AppBar(
            backgroundColor: Colors.transparent, // Make AppBar transparent
            elevation: 0, // Remove shadow
            title: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'images/logo.PNG', // Path to your image
                  height: 30,
                ),
                SizedBox(width: 10),
              ],
            ),
            centerTitle: true, // Center the title
            leading: IconButton(
              icon: Icon(Icons.arrow_back,
                  color: Colors.white), // Leading arrow icon
              onPressed: () {
                Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) => LeadDashBoard(
                              searchQuery: '',
                            ))); // Go back to the previous screen
              },
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                  image: AssetImage("images/AppBg2.PNG"), fit: BoxFit.fill),
            ),
            child: Column(
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 10, horizontal: 50),
                  child: Image(
                    image: const AssetImage(
                      "images/logo.PNG",
                    ),
                    width: MediaQuery.of(context).size.width * 0.7,
                    height: MediaQuery.of(context).size.height * 0.2,
                  ),
                ),
                Flexible(
                    child: SingleChildScrollView(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildTextField(
                            _fname,
                            "Customer First Name",
                            'Please Enter Your Customer First Name',
                            'name',
                            isNumeric: false,
                            icon: FontAwesomeIcons.solidCircleUser,
                            isBlankAlphabetic: true,
                            isRequired: true,
                            allowSpaces: false,
                          ),
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.03,
                          ),
                          _buildTextField(
                            _mname,
                            "Customer Middle Name",
                            'Please Enter Your Customer Middle Name',
                            'name',
                            isNumeric: false,
                            icon: FontAwesomeIcons.solidCircleUser,
                            isBlankAlphabetic: true,
                            isRequired: false,
                            allowSpaces: false,
                          ),
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.03,
                          ),
                          _buildTextField(
                            _lname,
                            "Customer Last Name",
                            'Please Enter Your Customer Last Name',
                            'name',
                            isNumeric: false,
                            icon: FontAwesomeIcons.solidCircleUser,
                            isBlankAlphabetic: true,
                            isAlphabetic: true,
                            allowSpaces: true,
                          ),
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.03,
                          ),
                          _buildMobileTextField(
                            controller: _phoneNumber,
                            isPhoneNumber: true,
                            isNumeric: true,
                          ),
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.03,
                          ),
                          _buildCtypeDropdownField(),
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.03,
                          ),
                          if (_selectedCustType == 'salaried') ...[
                            FocusScope(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Main input field
                                  TextField(
                                    controller: _searchController,
                                    readOnly: true,
                                    decoration: InputDecoration(
                                      label: RichText(
                                        text: TextSpan(
                                          text: "Type of Company",
                                          style: WidgetSupport.inputLabel(),
                                          children: const [
                                            TextSpan(
                                              text: ' *',
                                              style: TextStyle(
                                                  color: Colors.red,
                                                  fontSize: 15),
                                            ),
                                          ],
                                        ),
                                      ),
                                      hintText: "Type of Company",
                                      suffixIcon: IconButton(
                                        icon: const Icon(Icons.search,
                                            color: Colors.purple, size: 20),
                                        onPressed: () {
                                          FocusScope.of(context)
                                              .requestFocus(_dropdownFocusNode);
                                          setState(() {
                                            _isDropdownVisible =
                                                !_isDropdownVisible;
                                          });
                                        },
                                      ),
                                    ),
                                    onTap: () {
                                      FocusScope.of(context)
                                          .requestFocus(_dropdownFocusNode);
                                      setState(() {
                                        _isDropdownVisible = true;
                                      });
                                    },
                                  ),

                                  // Dropdown
                                  if (_isDropdownVisible)
                                    Focus(
                                      focusNode: _dropdownFocusNode,
                                      child: Container(
                                        margin: EdgeInsets.only(top: 8),
                                        padding: EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          border: Border.all(
                                              color: Colors.grey.shade300),
                                          borderRadius:
                                              BorderRadius.circular(8.0),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black12,
                                              blurRadius: 4,
                                              offset: Offset(0, 2),
                                            )
                                          ],
                                        ),
                                        child: Column(
                                          children: [
                                            TextField(
                                              autofocus: true,
                                              decoration: InputDecoration(
                                                hintText:
                                                    "Search company type...",
                                                prefixIcon: Icon(Icons.search),
                                              ),
                                              onChanged: _searchCompany,
                                            ),
                                            SizedBox(height: 8),
                                            Container(
                                              height: 150,
                                              child: ListView.builder(
                                                itemCount:
                                                    _filteredCompanies.length,
                                                itemBuilder: (context, index) {
                                                  final item =
                                                      _filteredCompanies[index];
                                                  return ListTile(
                                                    title: Text(
                                                        item['company_name']!),
                                                    onTap: () {
                                                      setState(() {
                                                        _searchController.text =
                                                            item[
                                                                'company_name']!;
                                                        _selectedCompany =
                                                            item['id']!;
                                                        _isDropdownVisible =
                                                            false;
                                                      });
                                                      _dropdownFocusNode
                                                          .unfocus();
                                                    },
                                                  );
                                                },
                                              ),
                                            ),
                                          ],
                                        ),
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
                                          borderRadius:
                                              BorderRadius.circular(8.0),
                                        ),
                                        child: ListView.builder(
                                          itemCount: _filteredCompanies.length,
                                          itemBuilder: (context, index) {
                                            return ListTile(
                                              title: Text(
                                                  _filteredCompanies[index]
                                                      ['company_name']!),
                                              onTap: () {
                                                // Set the selected company
                                                setState(() {
                                                  _selectedCompany =
                                                      _filteredCompanies[index]
                                                          ['id'];
                                                  _searchController.text =
                                                      _filteredCompanies[index]
                                                          ['company_name']!;
                                                  _isFieldFocused = false;
                                                  _showOtherCompanyField =
                                                      _selectedCompany ==
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
                              height: MediaQuery.of(context).size.height * 0.03,
                            ),
                          ],
                          if (_showOtherCompanyField) ...[
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 0.0),
                              child: TextFormField(
                                controller: _otherCompanyController,
                                decoration: InputDecoration(
                                  hintText: "Enter company name",
                                ),
                                validator: (value) {
                                  if (value == "" &&
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
                          if (_selectedCustType == 'self_employed') ...[
                            TextFormField(
                              controller: _businessNameController,
                              validator: (value) {
                                if (_selectedCustType == "self_employed" &&
                                    (value == null || value.trim().isEmpty)) {
                                  return "Business Name is required for self-employed customers";
                                }
                                return null;
                              },
                              decoration: InputDecoration(
                                hintText: "Business Name",
                                label: _selectedCustType == "self_employed"
                                    ? RichText(
                                        text: TextSpan(
                                          text: 'Business Name',
                                          style: WidgetSupport.inputLabel(),
                                          children: const [
                                            TextSpan(
                                              text: ' *',
                                              style: TextStyle(
                                                  color: Colors.red,
                                                  fontSize: 15),
                                            ),
                                          ],
                                        ),
                                      )
                                    : Text('Business Name',
                                        style: WidgetSupport.inputLabel()),
                                maintainHintHeight: true,
                              ),
                            ),
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.03,
                            ),
                          ],
                          _buildTextField(
                            _address1,
                            "Address line 1",
                            'Please Enter Your Address line 1',
                            'address',
                            isEmail: false,
                            isNumeric: false,
                            icon: FontAwesomeIcons.mapLocation,
                            allowSpaces: true,
                          ),
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.04,
                          ),
                          _buildTextField(
                            _address2,
                            "Address line 2",
                            'Please Enter Your Address line 2',
                            'address',
                            isEmail: false,
                            isNumeric: false,
                            icon: FontAwesomeIcons.mapLocationDot,
                            isRequired: true,
                            allowSpaces: true,
                          ),
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.04,
                          ),
                          _buildTextField(
                            _zip,
                            "Zip",
                            'Please Enter Zip Code',
                            'zip',
                            isZipNumber: true,
                            icon: FontAwesomeIcons.mapPin,
                          ),
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.04,
                          ),
                          // _buildCityDropdownField(),
                          FocusScope(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Search City TextField
                                TextField(
                                  controller: _citysearchController,
                                  readOnly: true,
                                  decoration: InputDecoration(
                                    label: RichText(
                                      text: TextSpan(
                                        text: "Select City",
                                        style: WidgetSupport.inputLabel(),
                                        children: const [
                                          TextSpan(
                                            text: ' *',
                                            style: TextStyle(
                                                color: Colors.red,
                                                fontSize: 15),
                                          ),
                                        ],
                                      ),
                                    ),
                                    hintText: "Search City",
                                    errorText: _cityError,
                                    suffixIcon: IconButton(
                                      icon: Icon(Icons.search),
                                      onPressed: () {
                                        FocusScope.of(context).requestFocus(
                                            _cityDropdownFocusNode);
                                        setState(() {
                                          _isCityDropdownVisible =
                                              !_isCityDropdownVisible;
                                        });
                                      },
                                    ),
                                  ),
                                  onTap: () {
                                    FocusScope.of(context)
                                        .requestFocus(_cityDropdownFocusNode);
                                    setState(() {
                                      _isCityDropdownVisible = true;
                                    });
                                  },
                                ),

                                // Dropdown (focus-aware)
                                if (_isCityDropdownVisible)
                                  Focus(
                                    focusNode: _cityDropdownFocusNode,
                                    child: Container(
                                      margin: EdgeInsets.only(top: 8),
                                      padding: EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        border: Border.all(
                                            color: Colors.grey.shade300),
                                        borderRadius:
                                            BorderRadius.circular(8.0),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black12,
                                            blurRadius: 4,
                                            offset: Offset(0, 2),
                                          )
                                        ],
                                      ),
                                      child: Column(
                                        children: [
                                          TextField(
                                            autofocus: true,
                                            decoration: InputDecoration(
                                              hintText: "Search city...",
                                              prefixIcon: Icon(Icons.search),
                                            ),
                                            onChanged: _filterCity,
                                          ),
                                          SizedBox(height: 8),
                                          Container(
                                            height: 150,
                                            child: ListView.builder(
                                              itemCount: _filteredCity.length,
                                              itemBuilder: (context, index) {
                                                final city =
                                                    _filteredCity[index];
                                                return ListTile(
                                                  title:
                                                      Text(city['city_name']!),
                                                  onTap: () {
                                                    setState(() {
                                                      _selectedCity =
                                                          city['id'];
                                                      _citysearchController
                                                              .text =
                                                          city['city_name']!;
                                                      _isCityDropdownVisible =
                                                          false;
                                                    });
                                                    _cityDropdownFocusNode
                                                        .unfocus();
                                                    _loadBarangayData(
                                                        _selectedCity!);
                                                  },
                                                );
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.04,
                          ),
                          _buildBarangayDropdownField(),
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.04,
                          ),
                          _buildTextField(
                            _location, // Use the controller here
                            "Location",
                            'Please Enter Location',
                            'location',
                            isNumeric: false,
                            icon: FontAwesomeIcons.locationPin,
                            allowSpaces: true,
                          ),
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.04,
                          ),
                          _buildTextField(
                            _income,
                            "Monthly Income",
                            'Please Enter Income',
                            'mincome',
                            isNumeric: true,
                            icon: FontAwesomeIcons.moneyBillWave,
                          ),
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.04,
                          ),
                          _buildTextField(
                            _loanamount,
                            "Loan Amount Requested",
                            'Please Enter Loan Amount',
                            'loan',
                            isNumeric: true,
                            // ignore: deprecated_member_use
                            icon: FontAwesomeIcons.handHoldingUsd,
                          ),
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.04,
                          ),
                          _buildTenorDropdownField(),
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.04,
                          ),
                          _buildPricingDropdownField(),
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.04,
                          ),
                          _buildTextField(
                            _email,
                            "Contact Person Email ID",
                            'Please Enter Your Email',
                            'email',
                            isNumeric: false,
                            icon: FontAwesomeIcons.mailchimp,
                            isRequired: true,
                            isEmail: true,
                          ),
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.03,
                          ),
                          _buildDropdownField(),
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.04,
                          ),
                          _buildKydIdTextField(
                            _externalId,
                            _getIdHintText(),
                            'Please Enter External ID',
                            '',
                            icon: FontAwesomeIcons.idCard,
                            isRequired: false,
                          ),
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.04,
                          ),
                          _buildImageUploadField(
                              _imageController, "Select Image"),
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.02,
                          ),
                          Container(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                ElevatedButton(
                                  onPressed: () {
                                    setState(() {
                                      if (_citysearchController.text.isEmpty) {
                                        _cityError = "City name is required";
                                      } else {
                                        _cityError = null;
                                      }
                                      if (_selectedBarangayType == null) {}
                                      if (_formKey.currentState!.validate()) {
                                        leadSubmit();
                                      }
                                    });
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    padding: EdgeInsets.symmetric(
                                      horizontal:
                                          MediaQuery.of(context).size.width *
                                              0.1,
                                      vertical:
                                          MediaQuery.of(context).size.height *
                                              0.01,
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
                          SizedBox(height: 380),
                        ],
                      ),
                    ),
                  ),
                ))
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

  Future<void> leadSubmit() async {
    // Check if the form is valid
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      String first_name = _fname.text.trim();
      String middle_name = _mname.text.trim();
      String last_name = _lname.text.trim();
      String phone_number = _phoneNumber.text.trim();
      String address1 = _address1.text.trim();
      String address2 = _address2.text.trim();
      String email = _email.text.trim();
      String zip = _zip.text.trim();
      String city = _selectedCity!;
      String location = _location.text.trim();
      String location_type = "";
      String area = "";
      String income = _income.text.trim().replaceAll(',', '');
      String loan_amount_requested =
          _loanamount.text.trim().replaceAll(',', '');
      bool submitted_on_uno_app = true;
      bool need_to_follow_up = false;
      String customer_type = _selectedCustType!;
      String activity = "";
      String interest = _selectedPricing!;
      String business_name = _businessNameController.text.isNotEmpty
          ? _businessNameController.text.trim()
          : '';
      String tenor = _selectedTenor!;
      String document_type = _selectedDocument ?? '';
      String finalOtherCompanyName = _selectedCompany == 'others'
          ? _otherCompanyController.text.trim()
          : '';
      String company =
          _selectedCompany == 'others' ? '' : (_selectedCompany ?? '');
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('accessToken');
      String? refresh = prefs.getString('refreshToken');
      String selectedGId = _selectedGId ?? "";
      String externalId = _externalId.text.trim();
      String barangay = _selectedBarangayType ?? '';
      // Map the collected data to be sent in the request body
      Map<String, String> mappedData = {
        'company': company,
        'first_name': first_name,
        'middle_name': middle_name,
        'last_name': last_name,
        'phone_number': phone_number,
        'address1': address1,
        'address2': address2,
        'email': email,
        'zip': zip,
        'city': city,
        'barangay': barangay,
        'location': location,
        'area': area,
        'income': income,
        'loan_amount_requested': loan_amount_requested,
        'submitted_on_uno_app': submitted_on_uno_app.toString(),
        'need_to_follow_up': need_to_follow_up.toString(),
        'customer_type': customer_type,
        'location_type': location_type,
        'activity': activity,
        'interest': interest,
        'business_name': business_name,
        'tenor': tenor,
        'document_type': document_type,
        'kyc_id_type': selectedGId,
        'kyc_id_number': externalId,
        'others_company': finalOtherCompanyName
      };
      if (_image == null && _imageUrl.isNotEmpty) {
        mappedData['kyc_document'] = _imageUrl;
      }
      if (widget.edit == "") {
        try {
          String url = "/api/leads/";

          final response = await ApiService.uploadMultipart(
            endpoint: url,
            fields: mappedData,
            headers: {
              'Authorization': 'Bearer $token',
            },
            file: _image,
            fileField: 'kyc_document',
          );
          if (response != null) {
            if (response.statusCode == 201) {
              json.decode(response.data);
              showDialog(
                context: context,
                barrierDismissible:
                    true, // Allow dismissing by clicking outside
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: Text('Success'),
                    content: Text('Lead submitted successfully!'),
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
                        child: Text('OK'),
                      ),
                    ],
                  );
                },
              );
            } else if (response.statusCode == 401) {
              setState(() {
                _isLoading = false;
              });
              // Refresh token
              Map<String, String> refreshData = {'refresh': refresh ?? ''};
              String url3 = "/api/users/token-refresh/";
              final response2 = await ApiService.post(url3, refreshData);
              if (response2 != null) {
                final data = json.decode(response2.data);
                SharedPreferences prefs = await SharedPreferences.getInstance();
                await prefs.setBool('isLoggedIn', true);
                await prefs.setString('accessToken', data['access']);
                await prefs.setString('refreshToken', data['refresh']);
                leadSubmit(); // Retry the submission
              }
            } else {
              // final data = json.decode(response.data);
              // Handle API errors
              final Map<String, dynamic> bodyJson = json.decode(response.data);
              String errorMessage = "";

              if (bodyJson.containsKey("company") &&
                  bodyJson["company"] is List) {
                errorMessage = bodyJson["company"].first;
              } else {
                errorMessage = "Validation failed.";
              }

              showDialog(
                context: context,
                barrierDismissible: true,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: Text('Validation Message'),
                    content: Text(errorMessage),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: Text('OK'),
                      ),
                    ],
                  );
                },
              );
            }
          }
        } catch (e) {
          // Handle network errors
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("An error occurred: $e"),
            ),
          );
        }
      } else {
        _image = await urlToFile(_imageUrl);
        try {
          String url2 = "/api/leads/${widget.edit}/";
          var response = await ApiService.putuploadMultipart(
            endpoint: url2,
            fields: mappedData,
            headers: {
              'Authorization': 'Bearer $token',
            },
            file: _image,
            fileField: 'kyc_document',
          );
          if (response != null) {
            if (response.statusCode == 200) {
              json.decode(response.data);
              showDialog(
                context: context,
                barrierDismissible:
                    true, // Allow dismissing by clicking outside
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: Text('Success'),
                    content: Text('Lead Updated successfully!'),
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
                        child: Text('OK'),
                      ),
                    ],
                  );
                },
              );
            } else if (response.statusCode == 401) {
              setState(() {
                _isLoading = false;
              });
              Map<String, String> mappedData = {
                'refresh': refresh ?? '',
              };
              String url2 = "/api/users/token-refresh/";
              final response2 = await ApiService.post(url2, mappedData);
              if (response2 != null) {
                final data = json.decode(response2.data);
                SharedPreferences prefs = await SharedPreferences.getInstance();
                await prefs.setBool('isLoggedIn', true);
                await prefs.setString('accessToken', data['access']);
                await prefs.setString('refreshToken', data['refresh']);
                leadSubmit();
              }
            } else {
              showDialog(
                context: context,
                barrierDismissible:
                    true, // Allow dismissing by clicking outside
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: Text('Validation'),
                    content: Text(response.data),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: Text('OK'),
                      ),
                    ],
                  );
                },
              );
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content:
                      Text("Failed to update lead. Error: ${response.data}"),
                ),
              );
            }
          }
        } catch (e) {
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("An error occurred: $e"),
            ),
          );
        }
      }
    } else {
      // Show a snackbar or other UI indication if validation fails
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Form validation failed"),
        ),
      );
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
    bool isBlankAlphabetic = false,
    bool isNumeric = false,
    bool isZipNumber = false,
    bool isRequired = true, // Add a flag to make the field optional
    bool allowSpaces = false, // New flag to allow spaces
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: isPhoneNumber
          ? TextInputType.phone
          : isEmail
              ? TextInputType.emailAddress
              : isNumeric || isZipNumber
                  ? TextInputType.number
                  : TextInputType.text,
      inputFormatters: [
        if (isNumeric) NumericCommaInputFormatter(),
        if (isZipNumber) ...[
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(4), // Limit to 4 digits
        ],
        if (isPhoneNumber)
          LengthLimitingTextInputFormatter(12), // Limit to 12 digits
        if (isAlphabetic)
          FilteringTextInputFormatter.allow(
            allowSpaces
                ? RegExp(r'^[a-zA-Z\s]+$') // Allow alphabets and spaces
                : RegExp(r'^[a-zA-Z]+$'), // Allow alphabets only (no spaces)
          ),
      ],
      validator: (value) {
        if (isRequired && (value == null || value.trim().isEmpty)) {
          return validationMessage;
        }
        if (isEmail && value != null && value.isNotEmpty) {
          final emailRegex = RegExp(
              r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'); // Valid email format
          if (!emailRegex.hasMatch(value)) {
            return 'Please enter a valid email address';
          }
        }

        if (isNumeric && value != null && value.isNotEmpty) {
          final cleanedValue = value.replaceAll(',', '');
          if (!RegExp(r'^\d+$').hasMatch(cleanedValue)) {
            return 'Please enter a valid number';
          }
        }

        if (isBlankAlphabetic && value != null && value.isNotEmpty) {
          if (!RegExp(r'^[a-zA-Z]*$').hasMatch(value)) {
            return 'Only alphabets are allowed';
          }
        }
        if (isPhoneNumber) {
          if (value == null || value.isEmpty) {
            return validationMessage;
          }
          if (value.length != 12) {
            return 'Phone number must be exactly 12 digits';
          }
          if (!RegExp(r'^\d+$').hasMatch(value)) {
            return 'Phone number must contain only digits';
          }
          if (!value.startsWith('63')) {
            return 'Phone number must start with "63"';
          }
        }

        return null;
      },
      decoration: InputDecoration(
        maintainHintHeight: true,
        label: isRequired
            ? RichText(
                text: TextSpan(
                  text: hintText,
                  style: WidgetSupport.inputLabel(),
                  children: const [
                    TextSpan(
                      text: ' *',
                      style: TextStyle(color: Colors.red, fontSize: 15),
                    ),
                  ],
                ),
              )
            : Text(hintText, style: WidgetSupport.inputLabel()),
        suffixIcon: Padding(
          padding: const EdgeInsets.all(0),
          child: Icon(
            icon,
            color: Colors.purple,
            size: 15,
          ),
        ),
      ),
    );
  }

  Widget _buildKydIdTextField(
    TextEditingController controller,
    String hintText,
    String validationMessage,
    String validationKey, {
    IconData icon = FontAwesomeIcons.solidCircleUser,
    bool obscureText = false,
    bool isNumeric = false,
    bool isRequired = true,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
      validator: (_selectedKycId) {
        if (_selectedKycId == "" && _selectedGId != null) {
          return 'Please Enter Id'; // Validation message if KYC ID is selected but no image uploaded
        }
        if (_selectedKycId != null && _selectedKycId.isNotEmpty) {
          if (_selectedKycId.length < 6) {
            return 'ID must be at least 6 characters long';
          }
          if (!RegExp(r'^[a-zA-Z0-9]+$').hasMatch(_selectedKycId)) {
            return 'Special characters are not allowed';
          }
        }
        return null;
      },
      decoration: InputDecoration(
        maintainHintHeight: true,
        label: isRequired
            ? RichText(
                text: TextSpan(
                  text: hintText,
                  style: WidgetSupport.inputLabel(),
                  children: const [
                    TextSpan(
                      text: ' *',
                      style: TextStyle(color: Colors.red, fontSize: 15),
                    ),
                  ],
                ),
              )
            : Text(hintText, style: WidgetSupport.inputLabel()),
        suffixIcon: Padding(
          padding: const EdgeInsets.all(0),
          child: Icon(
            icon,
            color: Colors.purple,
            size: 15,
          ),
        ),
      ),
    );
  }

  Widget _buildCtypeDropdownField() {
    return DropdownSearch<String>(
      popupProps: PopupProps.menu(
        showSearchBox: false,
        fit: FlexFit.loose,
      ),
      items: _CustomerType.values.toList(),
      dropdownDecoratorProps: DropDownDecoratorProps(
        dropdownSearchDecoration: InputDecoration(
          labelText: "Customer Type", // Floating label
          labelStyle: WidgetSupport.inputLabel(),
        ),
      ),
      selectedItem:
          _selectedCustType != null ? _CustomerType[_selectedCustType] : null,
      onChanged: (String? newValue) {
        setState(() {
          _selectedCustType = _CustomerType.entries
              .firstWhere((entry) => entry.value == newValue)
              .key;
          clearbusinessname();
        });
        FocusScope.of(context).requestFocus(FocusNode());
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please Select Customer Type';
        }
        return null;
      },
      dropdownBuilder: (BuildContext context, String? selectedItem) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              selectedItem ?? "Select Customer Type",
              style: WidgetSupport.dropDownText(),
            ),
            const SizedBox(width: 2),
            const Text('*', style: TextStyle(color: Colors.red, fontSize: 25)),
          ],
        );
      },
    );
  }

  Widget _buildTenorDropdownField() {
    return DropdownSearch<String>(
      popupProps: PopupProps.menu(
        showSearchBox: false,
        fit: FlexFit.loose,
      ),
      items: _Tenor.map((e) => e['description'].toString()).toList(),
      dropdownDecoratorProps: DropDownDecoratorProps(
        dropdownSearchDecoration: InputDecoration(
          labelText: "Tenor", // ✅ Floating label
          labelStyle: WidgetSupport.inputLabelDropdown(),
        ),
      ),
      selectedItem: _selectedTenor != null
          ? _Tenor.firstWhere((e) => e['id'] == _selectedTenor)['description']
          : null,
      onChanged: (String? newValue) {
        setState(() {
          _selectedTenor =
              _Tenor.firstWhere((e) => e['description'] == newValue)['id']
                  .toString();
        });
        FocusScope.of(context).requestFocus(FocusNode());
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please select Tenor';
        }
        return null;
      },
      dropdownBuilder: (BuildContext context, String? selectedItem) {
        return Text(
          selectedItem ?? "",
          style: WidgetSupport.dropDownText(),
        );
      },
    );
  }

  Widget _buildBarangayDropdownField() {
    return FormField<String>(
      validator: (value) {
        if (_selectedBarangayType == null || _selectedBarangayType!.isEmpty) {
          return 'Please select Barangay';
        }
        return null;
      },
      builder: (FormFieldState<String> fieldState) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownSearch<String>(
              popupProps: PopupProps.menu(
                showSearchBox: false,
                fit: FlexFit.loose,
              ),
              items:
                  _barangay.map((e) => e['barangay_name'].toString()).toList(),
              dropdownDecoratorProps: DropDownDecoratorProps(
                dropdownSearchDecoration: InputDecoration(
                  labelText: "Barangay", // ✅ Floating label
                  labelStyle: WidgetSupport.inputLabelDropdown(),
                  errorText: fieldState.errorText,
                ),
              ),
              selectedItem: _barangay.isNotEmpty
                  ? _barangay.firstWhere(
                      (e) => e['id'] == _selectedBarangayType,
                      orElse: () => {'barangay_name': "Select Barangay"},
                    )['barangay_name']
                  : null,
              onChanged: (String? newValue) {
                setState(() {
                  final selectedBarangay = _barangay.firstWhere(
                    (e) => e['barangay_name'] == newValue,
                  );
                  _selectedBarangayType = selectedBarangay['id']?.toString();
                  fieldState.didChange(newValue);
                });
                FocusScope.of(context).requestFocus(FocusNode());
              },
              dropdownBuilder: (BuildContext context, String? selectedItem) {
                return Text(
                  selectedItem ?? "",
                  style: WidgetSupport.dropDownText(),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildPricingDropdownField() {
    // Ensure _selectedPricing is initialized to a valid key in _pricing
    if (_selectedPricing == null && _pricing.isNotEmpty) {
      _selectedPricing =
          _pricing.keys.first; // Set a default key if none is selected
    }

    return DropdownSearch<String>(
      popupProps: PopupProps.menu(
        showSearchBox: false, // Disable the search box
        fit: FlexFit.loose,
      ),
      items: _pricing.values.toList(),
      dropdownDecoratorProps: DropDownDecoratorProps(
        dropdownSearchDecoration: InputDecoration(
          labelText: "Select Interest",
          hintStyle: WidgetSupport.inputLabelDropdown(),
        ),
      ),
      selectedItem: _selectedPricing != null
          ? _pricing[_selectedPricing]
          : null, // Ensure default value is selected
      onChanged: (String? newValue) {
        setState(() {
          _selectedPricing = _pricing.entries
              .firstWhere((entry) => entry.value == newValue)
              .key;
        });
        FocusScope.of(context).requestFocus(FocusNode());
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please Select Interest';
        }
        return null;
      },
      dropdownBuilder: (BuildContext context, String? selectedItem) {
        return Text(
          selectedItem ?? "Select Interest",
          style: WidgetSupport.dropDownText(),
        );
      },
    );
  }

  void clearbusinessname() {
    _businessNameController.clear();
    _searchController.clear();
    _selectedCompany = null;
  }

  Widget _buildDropdownField() {
    return DropdownSearch<String>(
      popupProps: PopupProps.menu(
        showSearchBox: false, // Disable the search box
        fit: FlexFit.loose,
      ),
      items: _gIdOptions.values.toList(),
      dropdownDecoratorProps: DropDownDecoratorProps(
        dropdownSearchDecoration: InputDecoration(
          hintText: "Select a KYC ID",
          hintStyle: WidgetSupport.inputLabel(),
        ),
      ),
      selectedItem: _selectedGId != null ? _gIdOptions[_selectedGId] : null,
      onChanged: (String? newValue) {
        setState(() {
          _selectedGId = _gIdOptions.entries
              .firstWhere((entry) => entry.value == newValue)
              .key;
          _selectedKycId == true;
        });
        FocusScope.of(context).requestFocus(FocusNode());
      },
      dropdownBuilder: (BuildContext context, String? _selectedGId) {
        return Text(
          _selectedGId ?? "Select KYC ID",
          style: WidgetSupport.dropDownText(),
        );
      },
    );
  }

  File? _image;

  Widget _buildImageUploadField(
      TextEditingController controller, String hintText) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: controller,
          readOnly: true,
          decoration: InputDecoration(
            labelText: hintText, // Shows label that floats when filled
            suffixIcon: IconButton(
              icon: const Icon(Icons.upload_file),
              onPressed: () async {
                showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: const Text("Select Image Source"),
                      actions: <Widget>[
                        TextButton(
                          onPressed: () async {
                            await _pickImage(ImageSource.camera, controller);
                            Navigator.of(context).pop();
                          },
                          child: const Text("Camera"),
                        ),
                        TextButton(
                          onPressed: () async {
                            final ImagePicker picker = ImagePicker();
                            final XFile? image = await picker.pickImage(
                                source: ImageSource.gallery);
                            if (image != null) {
                              // Copy image to internal app storage
                              final appDir =
                                  await getApplicationDocumentsDirectory();
                              final fileName =
                                  path.basename(image.path); // ✅ Now works
                              final secureImage = await File(image.path)
                                  .copy('${appDir.path}/$fileName');

                              _image = secureImage;
                              controller.text = secureImage.path;
                              final tempFile = File(image.path);
                              if (await tempFile.exists()) {
                                await tempFile.delete(); // ✅ Secure cleanup
                              }
                            }
                            Navigator.of(context).pop();
                          },
                          child: const Text("Gallery"),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.black45),
            ),
          ),
          validator: (_) {
            if (_selectedGId != null && _image == null && (_imageUrl.isEmpty)) {
              return 'Please upload an image';
            }
            return null;
          },
        ),
        Padding(
          padding: const EdgeInsets.only(top: 16.0),
          child: _imageBytes != null
              ? Image.memory(
                  _imageBytes!,
                  width: 300,
                  height: 150,
                  fit: BoxFit.fill,
                )
              : Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
        ),
      ],
    );
  }

// Function to handle image selection and replacement

  Future<void> _pickImage(
      ImageSource source, TextEditingController controller) async {
    // Only request permission if using camera
    if (source == ImageSource.camera) {
      final status = await Permission.camera.request();

      if (status.isDenied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Camera permission denied")),
        );
        return;
      }

      if (status.isPermanentlyDenied) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
                "Camera permission permanently denied. Please enable it in settings."),
            action: SnackBarAction(
              label: 'Open Settings',
              onPressed: () => openAppSettings(),
            ),
          ),
        );
        return;
      }

      if (!status.isGranted) {
        return; // Don’t proceed if not granted
      }
    }

    // Proceed to pick image
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: source);

    if (image != null) {
      final Uint8List imageBytes = await File(image.path).readAsBytes();

      setState(() {
        _image = File(image.path);
        _imageBytes = imageBytes;
        controller.text = image.path;
      });
       final tempFile = File(image.path);
      if (await tempFile.exists()) {
        await tempFile.delete(); // ✅ Secure cleanup
      }
    }
  }

  Widget _buildMobileTextField({
    required TextEditingController controller,
    bool isRequired = true,
    IconData icon = FontAwesomeIcons.solidCircleUser,
    bool isPhoneNumber = false,
    bool isNumeric = false,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 1, vertical: 8),
          decoration: BoxDecoration(
            border: const Border(bottom: BorderSide(width: 2)),
            borderRadius: const BorderRadius.only(
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
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            inputFormatters: [
              LengthLimitingTextInputFormatter(10),
              FilteringTextInputFormatter.digitsOnly,
            ],
            decoration: InputDecoration(
              label: isRequired
                  ? RichText(
                      text: TextSpan(
                        text: "Phone Number",
                        style: WidgetSupport.inputLabel(),
                        children: const [
                          TextSpan(
                            text: ' *',
                            style: TextStyle(color: Colors.red, fontSize: 15),
                          ),
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
}

class NumericCommaInputFormatter extends TextInputFormatter {
  final NumberFormat _formatter = NumberFormat('#,##0', 'en_US');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }
    // Remove existing commas
    final cleanedValue = newValue.text.replaceAll(',', '');
    if (cleanedValue.isEmpty) {
      return newValue.copyWith(text: '');
    }

    // Format number with commas
    final number = int.tryParse(cleanedValue) ?? 0;
    final formattedValue = _formatter.format(number);

    // Update the selection to match the formatted value
    return TextEditingValue(
      text: formattedValue,
      selection: TextSelection.collapsed(offset: formattedValue.length),
    );
  }
}
