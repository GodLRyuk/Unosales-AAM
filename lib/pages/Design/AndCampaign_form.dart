import 'dart:convert';
import 'dart:io';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_datetime_picker_bdaya/flutter_datetime_picker_bdaya.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:http_certificate_pinning/http_certificate_pinning.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unosfa/pages/FSAModule/campaignlist.dart';
import 'package:unosfa/pages/FSAModule/leadsByCampaign.dart';
import 'package:unosfa/pages/config/config.dart';
import 'package:unosfa/pages/services/api_service.dart';
import 'package:unosfa/widgetSupport/widgetstyle.dart';

class Campaign_form extends StatefulWidget {
  final String campaign;
  String? id;
  Campaign_form({required this.campaign, this.id});

  @override
  State<Campaign_form> createState() => _Campaign_formState();
}

class _Campaign_formState extends State<Campaign_form> {
  final _customerName = TextEditingController();
  final _customerMobile = TextEditingController();
  final _customerAddress = TextEditingController();
  final _amount = TextEditingController();
  final _tenor = TextEditingController();
  final _interestrate = TextEditingController();
  final _agentId = TextEditingController();
  final _campaignId = TextEditingController();
  final callback_date = TextEditingController();
  final _feedback = TextEditingController();
  String _selectedDependentData = "";
  late Map<int, String> StatusCode = {};
  Map<String, dynamic> data = {};
  bool isLoading = true;
  int? _selectedStatusCode;
  String formSubmition = "";
  bool visibility = false;
  bool subDropDown = false;
  late Map<String, String> _dependentData = {};
  String? _selectedStatusSubCode;
  late Map<String, String> _subdependentData = {};
  String? featchCallBackStatus;
  String? selectedStatus;
  String? selectSubStatus;
  String? callbackDateIso;
  String? _networkImageUrl;
  String? _networkImageUrl1;
  bool fieldsDisabled = false;
  bool loaderDependentData = false;
  bool _isLoading = false;
  bool _isLoading1 = false;

  // ******************** Function for Image ********************
  Uint8List? _imageBytes;

  Future<void> loadImage(String fullUrl) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('accessToken');

    final response = await http.get(
      Uri.parse(fullUrl),
      headers: {
        "Authorization": "Bearer $token",
      },
    );

    if (response.statusCode == 200) {
      setState(() {
        _imageBytes = response.bodyBytes;
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // ************************ Done **************************
  Future<void> fetchAndLeadsData() async {
    setState(() {
      _isLoading = true;
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('accessToken');
    String apiUrl = "/api/campaigns/${widget.campaign}/and-leads/${widget.id}/";
    final headers = {
      'Authorization': 'Bearer $token',
      'User-Agent':
          'Mozilla/5.0 (Linux; Android 11; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36',
      'Content-Type': 'application/json'
    };
    try {
      final response = await ApiService.getWithHeaders(apiUrl, headers);

      if (response != null) {
        if (response.statusCode == 200) {
          data = json.decode(response.body);

          setState(() {
            _customerName.text = data['full_name'] ?? '';
            _customerMobile.text = data['mobile_phone'] ?? '';
            _customerAddress.text = data['address'] ?? '';
            _amount.text = data['approved_loan_amount'] ?? '';
            _tenor.text = data['tenor']?.toString() ?? '';
            _interestrate.text = data['interest_rate']?.toString() ?? '';
            _campaignId.text = data['campaign']?.toString() ?? '';
            _agentId.text = data['agent']?.toString() ?? '';
            //_feedback.text = data['customer_feedback'].toString() ?? '';
            _feedback.text = data['customer_feedback']?.toString() ?? '';

            _networkImageUrl1 = data['upload_selfie'];

            if (AppConfig.isDev != true) {
              _networkImageUrl = _networkImageUrl1!.replaceFirst(
                  "http://salesapp.${AppConfig.flavour}.ph.unobank.asia",
                  "https://unoapi.${AppConfig.flavour}.ph.unobank.asia");
              loadImage(_networkImageUrl!);
            } else {
              _networkImageUrl = _networkImageUrl1;
              loadImage(_networkImageUrl!);
            }

            _selectedStatusCode = data['disposition_status'];
            if (data["sub_disposition_status"] == null &&
                data["callback_date"] != null) {
              String original = data['callback_date'];

              List<String> parts = original.split('T');
              String time = parts[1].split(':00')[0];
              callback_date.text = "${parts[0]} $time";
              visibility = true;
            }

            String currentStatus = StatusCode[_selectedStatusCode] ?? "";

            if (currentStatus == "Customer Not Sure – Follow-up Needed") {
              fieldsDisabled = false;
              visibility = true; // show callback
              subDropDown = false; // hide sub-status
            } else if (currentStatus == "Not Interested") {
              fieldsDisabled = true;
              visibility = false; // hide callback
              subDropDown = true; // show sub-status
              if (_selectedStatusCode != null) {
                _loadDependentData(_selectedStatusCode!);
              }
            } else if (currentStatus == "Availed") {
              fieldsDisabled = true;
              visibility = false; // hide callback
              subDropDown = false; // hide sub-status
            } else {
              fieldsDisabled = false;
              visibility = false;
              subDropDown = false;
            }
          });
        } else {
          print("response status code is ${response.statusCode}");
        }
      } else {
        print("API response is null");
      }
    } catch (e) {
      print("Error found $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    // fetchAndLeadsData();
    // _loadStatusData();
    _initData();
  }

  Future<void> _initData() async {
    await _loadStatusData(); // ✅ FIRST
    await fetchAndLeadsData(); // ✅ SECOND
  }

  // ==================== Submit Data ==============================

  void _showAlert(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(message), // just normal text
        actions: [
          TextButton(
            child: Text("OK"),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

//****************************************** */

  Future<void> submitAndData() async {
    if (_captureImageField1 == null && _networkImageUrl == null) {
      _showAlert("Please take a selfie."); // alert if no image
      return;
    }

    if (_selectedStatusCode == null) {
      _showAlert("Please select a status.");
      return;
    }

    if (!fieldsDisabled && (_feedback.text.trim().isEmpty)) {
      _showAlert("Please enter feedback."); // alert if feedback required
      return;
    }

    setState(() {
      _isLoading1 = true;
    });
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('accessToken');
    String apiUrl = "/api/campaigns/${widget.campaign}/and-leads/${widget.id}/";

    final headers = {
      'Authorization': 'Bearer $token',
      'User-Agent':
          'Mozilla/5.0 (Linux; Android 11; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36',
      //'Content-Type':'application/json'
    };

    // Parse Callback Date (yyyy-MM-dd HH:mm)
    if (callback_date.text.isNotEmpty) {
      try {
        DateTime parsedDate =
            DateFormat('yyyy-MM-dd HH:mm').parse(callback_date.text);

        callbackDateIso = parsedDate.toIso8601String();
      } catch (e) {
        print("Error parsing callback date: $e");
        callbackDateIso = null;
      }
    } else {
      callbackDateIso = null;
    }

    final Map<String, dynamic> body = {
      "customer_feedback": _feedback.text.trim(),
      "disposition_status": _selectedStatusCode,
      "sub_disposition_status": _selectedStatusSubCode,
      "callback_date": callbackDateIso,
    };

    try {
      final response = await ApiService.patchWithHeadersUploadMultiPart(
        apiUrl,
        headers,
        body,
        imageFile: _captureImageField1, // optional selfie
      );

      if (response != null) {
        if (response.statusCode == 200) {
          // Success
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: Text("Success"),
              content: Text("Data submitted successfully"),
              actions: [
                TextButton(
                  child: const Text("OK"),
                  // onPressed: () => Navigator.of(context).pop(),
                  onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => LeadListByCampaign(
                                campaign: widget.campaign,
                              ))),
                ),
              ],
            ),
          );
        } else {
          // Failed
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: Text("Error"),
              content: Text(response.body),
              actions: [
                TextButton(
                  child: const Text("OK"),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          );
        }
      } else {
        print("API response is null");
      }
    } catch (e) {
      print("Error submitting data: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading1 = false;
        });
      }
    }
  }

  // ============================================GET DISPOSITION CODES =======================
  Future<void> _loadStatusData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('accessToken');
    try {
      String url = "/api/campaigns/and-leads-dispositions-statuses/";
      final headers = {
        'Authorization': 'Bearer $token',
        'User-Agent':
            'Mozilla/5.0 (Linux; Android 11; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36',
      };
      final response = await ApiService.getWithHeaders(url, headers);
      if (response != null) {
        if (response.statusCode == 200) {
          //var decodedResponse = json.decode(response.body);
          var decodedResponse = json.decode(utf8.decode(response.bodyBytes));

          if (decodedResponse is Map<String, dynamic> &&
              decodedResponse['results'] != null) {
            decodedResponse = decodedResponse['results'];
          }
          if (decodedResponse is List) {
            Map<int, String> fetchedData = {};
            for (var item in decodedResponse) {
              int id = item['id'];
              String desc =
                  item['description'].toString().replaceAll('â€“', '–');
              fetchedData[id] = desc;
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
            final data = json.decode(response2.body);
            await prefs.setBool('isLoggedIn', true);
            await prefs.setString('accessToken', data['access']);
            await prefs.setString('refreshToken', data['refresh']);
          }
        } else {
          throw Exception('Failed to load dependent data');
        }
      }
    } catch (e) {
      print('Error is this: $e');
    }
  }

  // =============================================================
  Future<void> _loadDependentData(int statusId) async {
    setState(() {
      loaderDependentData = true;
    });

    final prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('accessToken');

    if (token == null) return;

    try {
      final String url =
          "/api/campaigns/and-leads-dispositions-statuses/$statusId/";

      final headers = {
        'Authorization': 'Bearer $token',
        'User-Agent':
            'Mozilla/5.0 (Linux; Android 11; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36',
      };

      final response = await ApiService.getWithHeaders(url, headers);
      if (response == null) return;

      if (response.statusCode == 200) {
        final decodedResponse = json.decode(response.body);

        final Map<String, String> fetchedData = {};
        String? matchedStatusCode;
        String? matchedCallBackStatusCode;

        final String? existingSubId =
            data['sub_disposition_status']?.toString();

        if (decodedResponse is Map<String, dynamic>) {
          final List subDispositions =
              decodedResponse['and_sub_dispositions'] ?? [];

          for (final item in subDispositions) {
            final String id = item['id'].toString();
            final String description = item['description'].toString();

            fetchedData[id] = description;

            if (existingSubId == id) {
              matchedStatusCode = id;
              matchedCallBackStatusCode = description;
            }
          }
        }

        setState(() {
          _dependentData = fetchedData;
          _selectedStatusSubCode = matchedStatusCode;
          featchCallBackStatus = matchedCallBackStatusCode;
          isLoading = false;
        });
      }

      // 🔁 Token refresh
      else if (response.statusCode == 401) {
        final String? refresh = prefs.getString('refreshToken');
        if (refresh == null) return;

        final response2 = await ApiService.post(
          "/api/users/token-refresh/",
          {'refresh': refresh},
        );

        if (response2 != null && response2.statusCode == 200) {
          final tokenData = json.decode(response2.body);
          await prefs.setString('accessToken', tokenData['access']);
          await prefs.setString('refreshToken', tokenData['refresh']);
        }
      } else {
        throw Exception('Failed to load dependent data');
      }
    } catch (e) {
      debugPrint("Error loading dependent data: $e");
    } finally {
      if (mounted) {
        setState(() {
          loaderDependentData = false; // ✅ STOP loader
        });
      }
    }
  }

  // =============================================================

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
                Navigator.pop(context);
              },
            ),
          ),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Container(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: Color(0xFF640D78),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          "Campaign Loan Details",
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        ),
                      ),
                    ),
                    SizedBox(height: 30),
                    _buildTextField(_customerName, "Customer Full Name",
                        "Please Enter Your Name", "name",
                        isAlphabetic: true,
                        allowSpaces: true,
                        isRequired: true,
                        readOnly: true),
                    SizedBox(height: 20),
                    _buildTextField(_customerMobile, "Customer Mobile Number",
                        "Please Enter Mobile Number", "phone no",
                        isPhoneNumber: true,
                        allowSpaces: false,
                        isRequired: true,
                        icon: FontAwesomeIcons.phone,
                        readOnly: true),
                    SizedBox(height: 20),
                    _buildTextField(_customerAddress, "Customer Address",
                        "Address is Required", "Address",
                        isAlphabetic: true,
                        allowSpaces: true,
                        isRequired: true,
                        icon: FontAwesomeIcons.envelope,
                        readOnly: true),
                    SizedBox(height: 20),
                    _buildTextField(_amount, "Approved Loan Amount",
                        "Amount is required", "Amount",
                        isNumeric: true,
                        allowSpaces: false,
                        isRequired: true,
                        icon: FontAwesomeIcons.moneyBillWave,
                        readOnly: true),
                    SizedBox(height: 20),
                    _buildTextField(
                        _tenor, "Tenor", "Tenor is Required", "tenor",
                        isAlphabetic: true,
                        isRequired: true,
                        icon: FontAwesomeIcons.clock,
                        readOnly: true),
                    SizedBox(height: 20),
                    _buildTextField(_interestrate, "Interest Rate",
                        "Interest Rate is Required", "interest rate",
                        isNumeric: true,
                        isRequired: true,
                        icon: FontAwesomeIcons.percent,
                        readOnly: true),
                    SizedBox(height: 20),
                    _buildTextField(_agentId, "Agent Id",
                        "Agent Id is Required", "Agent Id",
                        isNumeric: true,
                        isRequired: true,
                        icon: FontAwesomeIcons.idBadge,
                        readOnly: true),
                    SizedBox(height: 20),
                    _buildTextField(_campaignId, "Campaign Id",
                        "Campaign Id is Required", "Campaign  Id",
                        isNumeric: true,
                        isRequired: true,
                        icon: FontAwesomeIcons.bullhorn,
                        readOnly: true),
                    SizedBox(height: 20),
                    _buildImageCaptureField(
                      context,
                      "Upload Selfie",
                      true,
                      _captureImageField1,
                      (file) => setState(() => _captureImageField1 = file),
                    ),
                    SizedBox(height: 20),
                    Text(
                      "Select Status",
                      style: WidgetSupport.Questionblack(),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(0.0),
                      child: Column(
                        children: [
                          //Text("visibility $visibility"),

                          _buildStatusDropdownField(),

                          if (subDropDown) ...[
                            loaderDependentData
                                ? const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 20),
                                    child: Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  )
                                : _builddispositionDropdownField(),
                          ],

                          if (visibility != false) ...[
                            _buildDateTimeField(
                              context: context,
                              controller: callback_date,
                              label: "Call Back Date",
                            ),
                          ],
                        ],
                      ),
                    ),
                    SizedBox(height: 25),
                    TextFormField(
                      controller: _feedback,
                      maxLines: 4,
                      readOnly: fieldsDisabled,
                      decoration: InputDecoration(
                        hint: Row(
                          children: [
                            Text("Feedback"),
                            Text("*", style: TextStyle(color: Colors.red))
                          ],
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(2),
                        ),
                        alignLabelWithHint: true,
                      ),
                      validator: (value) {
                        if (!fieldsDisabled &&
                            (value == null || value.trim().isEmpty)) {
                          return "Feedback is required";
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 30),
                    Center(
                      child: SizedBox(
                        width: 150,
                        height: 48,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          // onPressed:  () {
                          //   print("click");
                          //   submitAndData();
                          // } ,

                          onPressed: fieldsDisabled
                              ? null
                              : () {
                                  print("click");
                                  submitAndData();
                                },
                          child: _isLoading1
                              ? Center(
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                  ),
                                )
                              : Text(
                                  "Submit",
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                    ),
                    SizedBox(height: 50),
                  ],
                ),
              ),
            ),
    );
  }

// ==================================================================================

  Widget _buildStatusDropdownField() {
    return IgnorePointer(
      ignoring: fieldsDisabled,
      child: DropdownSearch<String>(
        popupProps: PopupProps.menu(
          showSearchBox: false,
          fit: FlexFit.loose,
        ),
        items: StatusCode.values.toList(),
        dropdownDecoratorProps: DropDownDecoratorProps(
          dropdownSearchDecoration: InputDecoration(
            hintText: "Select Status",
            hintStyle: WidgetSupport.inputLabel(),
          ),
        ),
        selectedItem: _selectedStatusCode != null
            ? StatusCode[_selectedStatusCode]
            : null,
        onChanged: (String? newValue) {
          if (fieldsDisabled) return;

          setState(() {
            if (newValue != null) {
              _selectedStatusCode = StatusCode.entries
                  .firstWhere((entry) => entry.value == newValue)
                  .key;

              // reset dependent fields
              _selectedStatusSubCode = null;
              callback_date.text = "";

              if (newValue == "Customer Not Sure – Follow-up Needed") {
                visibility = true;
                subDropDown = false;
              } else if (newValue == "Not Interested") {
                visibility = false;
                subDropDown = true;
                _loadDependentData(_selectedStatusCode!);
              } else if (newValue == "Availed") {
                visibility = false;
                subDropDown = false;
              } else {
                visibility = false;
                subDropDown = false;
              }
            }
          });
        },
        dropdownBuilder: (BuildContext context, String? selectedItem) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Expanded(
                child: Text(
                  selectedItem ?? "Select Status",
                  style: WidgetSupport.dropDownText(),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 2),
              const Text('*',
                  style: TextStyle(color: Colors.red, fontSize: 20)),
            ],
          );
        },
      ),
    );
  }

  Widget _builddispositionDropdownField() {
    return IgnorePointer(
      ignoring: fieldsDisabled,
      child: DropdownSearch<String>(
        popupProps: PopupProps.menu(
          showSearchBox: false,
          fit: FlexFit.loose,
        ),
        items: _dependentData.values.toList(),
        dropdownDecoratorProps: DropDownDecoratorProps(
          dropdownSearchDecoration: InputDecoration(
            hintText: "Select Sub Status",
            hintStyle: WidgetSupport.inputLabel(),
          ),
        ),
        selectedItem: _selectedStatusSubCode != null
            ? _dependentData[_selectedStatusSubCode]
            : null,
        onChanged: (String? newValue) {
          if (fieldsDisabled) return; // extra safety
          setState(() {
            if (newValue != null) {
              _selectedStatusSubCode = _dependentData.entries
                  .firstWhere((entry) => entry.value == newValue)
                  .key;
            }
          });
        },
        dropdownBuilder: (BuildContext context, String? selectedItem) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                selectedItem ?? "Select Sub Status",
                style: WidgetSupport.dropDownText(),
              ),
              const SizedBox(width: 2),
              const Text('*',
                  style: TextStyle(color: Colors.red, fontSize: 20)),
            ],
          );
        },
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
    Function(File) onImageSelected,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              hintText,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),

            // Red * for required field
            if (isRequired)
              const Text(
                " *",
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),

            const SizedBox(width: 8),

            IconButton(
              icon: const Icon(Icons.photo, color: Colors.purple),
              onPressed: fieldsDisabled
                  ? null
                  : () async {
                      final picker = ImagePicker();

                      final XFile? pickedFile = await picker.pickImage(
                        source: ImageSource.gallery,
                        imageQuality: 60,
                      );

                      if (pickedFile != null) {
                        onImageSelected(File(pickedFile.path));

                        setState(() {
                          _networkImageUrl = null; // Clear old network image
                        });
                      }
                    },
            ),
          ],
        ),

        const SizedBox(height: 10),

        // Show selected image from File
        if (captureImage != null)
          ClipOval(
            child: Image.file(
              captureImage,
              height: 110,
              width: 110,
              fit: BoxFit.cover,
            ),
          )

        // Show network image if exists
        else if (_imageBytes != null)
          ClipOval(
            child: _isLoading
                ? const SizedBox(
                    height: 110,
                    width: 110,
                    child: Center(child: CircularProgressIndicator()),
                  )
                : Image.memory(
                    _imageBytes!,
                    height: 110,
                    width: 110,
                    fit: BoxFit.cover,
                  ),
          ),
      ],
    );
  }

// =============================================================================

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
            //controller.text = DateFormat('dd-MM-yyyy HH:mm').format(date);
            controller.text = DateFormat('yyyy-MM-dd HH:mm').format(date);
          },
          currentTime: DateTime.now(),
          locale: LocaleType.en,
        );
      },
      child: AbsorbPointer(
        child: TextFormField(
          controller: controller,
          decoration: InputDecoration(
            hintText: 'YYYY-MM-DD HH:MM',
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

  // =================================================================================

  Widget _buildTextField(
    TextEditingController controller,
    String hintText,
    String validationMessage,
    String validationKey, {
    //IconData icon = FontAwesomeIcons.solidCircleUser,
    IconData? icon,
    bool obscureText = false,
    bool isEmail = false,
    bool isPhoneNumber = false,
    bool isAlphabetic = false,
    bool isNumeric = false,
    bool allowSpaces = false,
    bool isReferralCode = false,
    bool isRequired = false,
    bool readOnly = false,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      readOnly: readOnly,
      keyboardType: isPhoneNumber || isNumeric
          ? TextInputType.number
          : isEmail
              ? TextInputType.emailAddress
              : TextInputType.text,
      inputFormatters: [
        if (isPhoneNumber || isNumeric) ...[
          FilteringTextInputFormatter.digitsOnly,
          if (isPhoneNumber) LengthLimitingTextInputFormatter(12),
        ],
        if (isAlphabetic)
          FilteringTextInputFormatter.allow(
            allowSpaces ? RegExp(r'^[a-zA-Z\s]+$') : RegExp(r'^[a-zA-Z]+$'),
          ),
        if (isReferralCode)
          FilteringTextInputFormatter.allow(
            RegExp(r'^[a-zA-Z0-9]+$'),
          ),
      ],
      validator: (value) {
        if ((value == null || value.isEmpty) && isRequired && !isReferralCode) {
          return validationMessage;
        }

        if (isAlphabetic) {
          if (!RegExp(allowSpaces ? r'^[a-zA-Z\s]+$' : r'^[a-zA-Z]+$')
              .hasMatch(value!)) {
            return allowSpaces
                ? 'Only alphabets and spaces are allowed'
                : 'Only alphabets are allowed, no spaces';
          }
        }

        if (isEmail) {
          final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
          if (!emailRegex.hasMatch(value!)) {
            if (!value.contains('@')) return 'Email must contain "@"';
            if (!value.contains('.'))
              return 'Email must contain a domain (e.g., .com)';
            return 'Please enter a valid email address';
          }
        }

        if (isPhoneNumber) {
          if (value!.length != 12) return 'Phone number must be 12 digits';
          if (!value.startsWith('63'))
            return 'Phone number must start with "63"';
          if (!RegExp(r'^\d+$').hasMatch(value))
            return 'Phone number must contain only digits';
        }

        if (isNumeric && !RegExp(r'^\d+$').hasMatch(value!)) {
          return 'Only numbers are allowed';
        }

        if (isReferralCode && !RegExp(r'^[a-zA-Z0-9]+$').hasMatch(value!)) {
          return 'Referral code can only contain letters and numbers';
        }

        return null;
      },
      decoration: InputDecoration(
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
}
