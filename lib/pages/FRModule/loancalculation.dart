import 'dart:convert';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unosfa/pages/generalscreens/customNavigation.dart';
import 'package:unosfa/pages/FRModule/createnewlead.dart';
import 'package:unosfa/pages/services/api_service.dart';
import 'package:unosfa/widgetSupport/widgetstyle.dart';

class Loancalculation extends StatefulWidget {
  final loanAmountRequested;
  final tenorDescription;
  final monthlyInstallment;
  final interest;
  final id;

  const Loancalculation({
    super.key,
    required this.loanAmountRequested,
    required this.tenorDescription,
    required this.monthlyInstallment,
    required this.interest,
    required this.id,
  });
  @override
  State<Loancalculation> createState() => _LoancalculationState();
}

class _LoancalculationState extends State<Loancalculation> {
  final _formKey = GlobalKey<FormState>();
  final _lamount = TextEditingController();
  final _tenor = TextEditingController();
  final _minstallment = TextEditingController();
  final _intrest = TextEditingController();
  bool _isLoading = false;
  bool isSubmittedPresent = false;
  late Map<String, String> dispositionCode = {}; // Initialize as an empty map
  late Map<String, String> _dependentData = {}; // List for second dropdown data

  String? _selectedDispositionCode;
  String? _selectedDependentData;

  @override
  void initState() {
    super.initState();
    _lamount.text = widget.loanAmountRequested.toString();
    _tenor.text = widget.tenorDescription;
    _minstallment.text = widget.monthlyInstallment.toString();
    _intrest.text = widget.interest.toString();
    _loadLocationData();
  }

  Future<void> _loadLocationData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('accessToken');
    String? refresh = prefs.getString('refreshToken');
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
          var decodedResponse = json.decode(response.body);
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
              dispositionCode = fetchedData;
            });
          } else {
            throw Exception('Unexpected response format');
          }
        } else if (response.statusCode == 401) {
          Map<String, String> mappedData = {
            'refresh': refresh ?? '',
          };
          String url2 = "/api/users/token-refresh/";
          final response2 = await ApiService.post(url2, mappedData);
          if (response2 != null) {
            final data = json.decode(response2.body);
            SharedPreferences prefs = await SharedPreferences.getInstance();
            await prefs.setBool('isLoggedIn', true);
            await prefs.setString('accessToken', data['access']);
            await prefs.setString('refreshToken', data['refresh']);
            _loadLocationData();
          }
        } else {
          throw Exception('Failed to load location types');
        }
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  Future<void> _loadDependentData(String locationId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('accessToken');
    setState(() {
      _isLoading = true;
    });
    try {
      String url = "/api/leads/disposition-codes/$locationId/";
      final headers = {
        'Authorization': 'Bearer $token',
        'User-Agent':
            'Mozilla/5.0 (Linux; Android 11; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36',
      };
      final response = await ApiService.getWithHeaders(url, headers);
      if (response != null) {
        if (response.statusCode == 200) {
          var decodedResponse = json.decode(response.body);
          if (decodedResponse['description'] == 'Submitted') {
            isSubmittedPresent = true;
            _selectedDependentData = "";
          } else {
            isSubmittedPresent = false;
          }
          if (decodedResponse is Map<String, dynamic> &&
              decodedResponse['sub_disposition_codes'] != null) {
            decodedResponse = decodedResponse['sub_disposition_codes'];
          }
          if (decodedResponse is List) {
            Map<String, String> fetchedData = {};
            for (var item in decodedResponse) {
              fetchedData[item['id'].toString()] =
                  item['description'].toString();
            }

            setState(() {
              _dependentData = fetchedData;
            });
            setState(() {
              _isLoading = false;
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
          String url3 = "/api/users/token-refresh/";
          final response2 = await ApiService.post(url3, mappedData);
          if (response2 != null) {
            final data = json.decode(response2.body);
            await prefs.setBool('isLoggedIn', true);
            await prefs.setString('accessToken', data['access']);
            await prefs.setString('refreshToken', data['refresh']);
            _loadLocationData();
          }
        } else {
          throw Exception('Failed to load dependent data');
        }
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  Future<bool?> _showExitConfirmationDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Form is not completed"),
        content: Text("Are you sure you want to leave this page?"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(false); // Stay on the page
            },
            child: Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(true); // Exit the page
            },
            child: Text("Leave"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ignore: deprecated_member_use
    return WillPopScope(
      onWillPop: () async {
        final shouldLeave = await _showExitConfirmationDialog(context);
        return shouldLeave ?? false;
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          // leading: IconButton(
          //   icon: const Icon(Icons.arrow_back),
          //   onPressed: () => Navigator.pop(context),
          // ),
          title: Center(
            child: Text("Loan Calculation        ",
                style: WidgetSupport.titleText()),
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
                    padding: const EdgeInsets.symmetric(
                        vertical: 10, horizontal: 50),
                    child: Image(
                      image: const AssetImage("images/logo.PNG"),
                      width: MediaQuery.of(context).size.width * 0.7,
                      height: MediaQuery.of(context).size.height * 0.2,
                    ),
                  ),
                  Flexible(
                    child: SingleChildScrollView(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 0),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildTextField(
                                _lamount,
                                "Loan Amount",
                                '',
                                'lamount',
                                isReadOnly: true,
                              ),
                              SizedBox(
                                  height: MediaQuery.of(context).size.height *
                                      0.03),
                              _buildTextField(
                                _tenor,
                                "Tenor",
                                '',
                                'tenor',
                                isReadOnly: true,
                              ),
                              SizedBox(
                                  height: MediaQuery.of(context).size.height *
                                      0.03),
                              _buildTextField(
                                _minstallment,
                                "Monthly Installment",
                                '',
                                'minstallment',
                                isReadOnly: true,
                              ),
                              SizedBox(
                                  height: MediaQuery.of(context).size.height *
                                      0.03),
                              _buildTextField(
                                _intrest,
                                "Interest",
                                '',
                                'intrest',
                                isReadOnly: true,
                              ),
                              SizedBox(
                                  height: MediaQuery.of(context).size.height *
                                      0.03),
                              _builddispositionDropdownField(),
                              SizedBox(
                                  height: MediaQuery.of(context).size.height *
                                      0.03),
                              if (!isSubmittedPresent)
                                _buildDependentDropdownField(),
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.04,
                              ),
                              SizedBox(
                                  height: MediaQuery.of(context).size.height *
                                      0.02),
                              Container(
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    ElevatedButton(
                                      onPressed: () {
                                        Navigator.pushReplacement(
                                            context,
                                            MaterialPageRoute(
                                                builder: (context) =>
                                                    LeadGenerate(
                                                        edit: widget.id
                                                            .toString())));
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.transparent,
                                        shadowColor: Colors.transparent,
                                        padding: EdgeInsets.symmetric(
                                          horizontal: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              0.0,
                                          vertical: MediaQuery.of(context)
                                                  .size
                                                  .height *
                                              0.00,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(0.0),
                                        ),
                                      ),
                                      child: Text(
                                        "BACK",
                                        style: WidgetSupport
                                            .LoginButtonTextColor(),
                                      ),
                                    ),
                                    ElevatedButton(
                                      onPressed: () {
                                        if (_formKey.currentState!.validate()) {
                                          leadSubmit();
                                        }
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.transparent,
                                        shadowColor: Colors.transparent,
                                        padding: EdgeInsets.symmetric(
                                          horizontal: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              0.0,
                                          vertical: MediaQuery.of(context)
                                                  .size
                                                  .height *
                                              0.01,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8.0),
                                        ),
                                      ),
                                      child: Text(
                                        "COMPLETE",
                                        style: WidgetSupport
                                            .LoginButtonTextColor(),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: 180),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
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
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String hintText,
    String validationMessage,
    String validationKey, {
    bool obscureText = false,
    bool isReadOnly = false,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: WidgetSupport.inputLabel(),
      ),
      readOnly: isReadOnly,
    );
  }

  Widget _builddispositionDropdownField() {
    return DropdownSearch<String>(
      popupProps: PopupProps.menu(
        showSearchBox: false,
        fit: FlexFit.loose,
      ),
      items: dispositionCode.values.toList(),
      dropdownDecoratorProps: DropDownDecoratorProps(
        dropdownSearchDecoration: InputDecoration(
          hintText: "Select Disposition",
          hintStyle: WidgetSupport.inputLabel(),
        ),
      ),
      selectedItem: _selectedDispositionCode != null
          ? dispositionCode[_selectedDispositionCode]
          : null,
      onChanged: (String? newValue) {
        setState(() {
          if (newValue != null) {
            _selectedDispositionCode = dispositionCode.entries
                .firstWhere((entry) => entry.value == newValue)
                .key;
            _loadDependentData(_selectedDispositionCode!);
          }
        });
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Select Disposition';
        }
        return null;
      },
      dropdownBuilder: (BuildContext context, String? selectedItem) {
        return Text(
          selectedItem ?? "Select Disposition",
          style: WidgetSupport.dropDownText(),
        );
      },
    );
  }

  Widget _buildDependentDropdownField() {
    return DropdownSearch<String>(
      popupProps: PopupProps.menu(
        showSearchBox: false,
        fit: FlexFit.loose,
      ),
      items: _dependentData.values.toList(),
      dropdownDecoratorProps: DropDownDecoratorProps(
        dropdownSearchDecoration: InputDecoration(
          hintText: "Sub Disposition Code",
          hintStyle: WidgetSupport.inputLabel(),
        ),
      ),
      selectedItem: _selectedDependentData != null
          ? _dependentData[_selectedDependentData]
          : null,
      onChanged: (String? newValue) {
        setState(() {
          if (newValue != null) {
            _selectedDependentData = _dependentData.entries
                .firstWhere((entry) => entry.value == newValue)
                .key;
          }
        });
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Sub Disposition Code';
        }
        return null;
      },
      dropdownBuilder: (BuildContext context, String? selectedItem) {
        return Text(
          selectedItem ?? "Sub Disposition Code",
          style: WidgetSupport.dropDownText(),
        );
      },
    );
  }

  Future<void> leadSubmit() async {
    setState(() {
      _isLoading = true;
    });
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('accessToken');

    if (_formKey.currentState!.validate()) {
      // Directly assign disposition_code and sub_disposition_code
      String? disposition_code = _selectedDispositionCode;
      String? sub_disposition_code = _selectedDependentData?.isNotEmpty ?? false
          ? _selectedDependentData
          : null;

      Map<String, dynamic> mappedData = {
        'disposition_code': disposition_code,
        'sub_disposition_code': sub_disposition_code, // This can be null
      };

      try {
        String url = "/api/leads/${widget.id}/";
        final headers = {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'User-Agent':
              'Mozilla/5.0 (Linux; Android 11; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36',
        };
        final response =
            await ApiService.patchWithHeaders(url, headers, mappedData);
        if (response != null) {
          if (response.statusCode == 200) {
            json.decode(response.body);
            showDialog(
              context: context,
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
          } else {
            setState(() {
              _isLoading = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("Failed to submit lead. Error: ${response.body}"),
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
    } else {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Form validation failed"),
        ),
      );
    }
  }
}
