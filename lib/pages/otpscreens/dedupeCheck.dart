import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hyperkyc_flutter/hyperkyc_result.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';
import 'package:unosfa/pages/FSAModule/fsaleaddashboard.dart';
import 'package:unosfa/pages/FSAModule/losApplication.dart';
import 'package:unosfa/pages/commingSoon.dart';
import 'package:unosfa/pages/generalscreens/customNavigation.dart';
import 'package:unosfa/pages/generalscreens/entrypage.dart';
import 'package:unosfa/pages/generalscreens/profile.dart';
import 'package:unosfa/pages/services/api_service.dart';
import 'package:unosfa/pages/services/ekyc.dart';
import '../../widgetSupport/widgetstyle.dart';

class DedupeCheck extends StatefulWidget {
  final String firstName;
  final String? middleName;
  final String lastName;
  final String dob;
  final String mobilePhone;

  const DedupeCheck({
    super.key,
    required this.firstName,
    this.middleName,
    required this.lastName,
    required this.dob,
    required this.mobilePhone,
  });
  @override
  State<DedupeCheck> createState() => _DedupeCheckState();
}

class _DedupeCheckState extends State<DedupeCheck> {
  final _formKey = GlobalKey<FormState>();
  final firstName = TextEditingController();
  final middlename = TextEditingController();
  final lastName = TextEditingController();
  final mobilePhone = TextEditingController();
  final email = TextEditingController();
  final dob = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // _checkLoginStatus();
    firstName.text = widget.firstName;
    middlename.text = widget.middleName ?? "";
    lastName.text = widget.lastName;
    dob.text = widget.dob;
    mobilePhone.text = widget.mobilePhone;
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
                  MaterialPageRoute(builder: (context) => NavigationPage()),
                );
              },
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.05,
                      ),
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle, // Makes it perfectly circular
                          border: Border.all(
                            width: 4,
                            color: Color(
                                0xFF6e0386), // Optional: add color for clarity
                          ),
                        ),
                        padding: const EdgeInsets.all(
                            30), // Equal padding on all sides
                        child: Image.asset(
                          "images/user_info.PNG",
                          width: MediaQuery.of(context).size.width * 0.15,
                          fit: BoxFit.cover,
                        ),
                      ),
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.05,
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: MediaQuery.of(context).size.width * 0.1,
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              _buildTextField(
                                firstName,
                                "First Name",
                                '',
                                'firstName',
                                icon: FontAwesomeIcons.user,
                              ),
                              const SizedBox(height: 20),
                              _buildTextField(
                                middlename,
                                "Middle Name",
                                '',
                                'middleName',
                                icon: FontAwesomeIcons.user,
                              ),
                              const SizedBox(height: 20),
                              _buildTextField(
                                lastName,
                                "Last Name",
                                '',
                                'lastName',
                                icon: FontAwesomeIcons.user,
                              ),
                              const SizedBox(height: 5),
                              _buildMobileTextField(
                                controller: mobilePhone,
                                isPhoneNumber: true,
                                readOnly: true
                              ),
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.02,
                              ),

                              
                              _buildDobField(dob, "Date of Birth"),
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.02,
                              ),

                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal:
                                      MediaQuery.of(context).size.width * 0.00,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    GestureDetector(
                                      onTap: () {
                                        userDetailsSubmit();
                                      },
                                      child: Container(
                                        padding: EdgeInsets.symmetric(
                                          vertical: MediaQuery.of(context)
                                                  .size
                                                  .height *
                                              0.01,
                                        ),
                                        child: Center(
                                          child: Text(
                                            "Submit".toUpperCase(),
                                            style: WidgetSupport
                                                .LoginButtonTextColor(),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 40),
                            ],
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ],
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

  Widget _buildTextField(
    TextEditingController controller,
    String hintText,
    String validationMessage,
    String validationKey, {
    //bool isRequired = true,
    IconData icon = FontAwesomeIcons.solidCircleUser,
    bool obscureText = false,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      readOnly: true,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: WidgetSupport.inputLabel(),
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
        if (hintText == "Middle Name") {
          return null;
        }
        if (value == null || value.isEmpty) {
          return '$hintText is required';
        }
        return null;
      },
    );
  }

  // Widget _buildDobField(TextEditingController controller, String labelText) {
  //   return TextFormField(
  //     controller: controller,
  //     readOnly: true,
  //     decoration: InputDecoration(
  //       hintText: labelText,
  //       hintStyle: WidgetSupport.inputLabel(),
  //       suffixIcon: const Icon(
  //         FontAwesomeIcons.calendar, // ✅ calendar icon here
  //         color: Colors.purple,
  //         size: 18,
  //       ),
  //     ),
  //     onTap: () async {
  //       FocusScope.of(context).requestFocus(FocusNode());
  //       DateTime? pickedDate = await showDatePicker(
  //         context: context,
  //         initialDate: DateTime(2000),
  //         firstDate: DateTime(1500),
  //         lastDate: DateTime.now(),
  //       );
  //       if (pickedDate != null) {
  //         setState(() {
  //           controller.text =
  //               "${pickedDate.day}/${pickedDate.month}/${pickedDate.year}";
  //         });
  //       }
  //     },
  //     validator: (value) {
  //       if (value == null || value.isEmpty) {
  //         return 'Date of Birth is required';
  //       }
  //       return null;
  //     },
  //   );
  // }

  Widget _buildDobField(TextEditingController controller, String labelText) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      decoration: InputDecoration(
        hintText: labelText,
        hintStyle: WidgetSupport.inputLabel(),
        suffixIcon: const Icon(
          FontAwesomeIcons.calendar,
          color: Colors.purple,
          size: 18,
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return "Date of Birth is required";
        }
        return null;
      },
    );
  }

  Widget _buildMobileTextField({
    required TextEditingController controller,
    bool isRequired = true,
    IconData icon = FontAwesomeIcons.phoneVolume,
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

  Future<void> userDetailsSubmit() async {
    print("Hello world");
    setState(() {
      _isLoading = true;
    });
    String token = "";
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString('accessToken');
    try {
      String tokenUrl = "/api/leads/los-access-token/";
      final headers = {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
        'User-Agent':
            'Mozilla/5.0 (Linux; Android 11; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36',
      };
      final Tokenresponse = await ApiService.getWithHeaders(tokenUrl, headers);
      if (Tokenresponse != null) {
        final data = json.decode(Tokenresponse.body);
        token = data['access_token'];
      }
    } catch (e) {
      print("HTTP Request Failed: $e");
    }

    if (_formKey.currentState!.validate()) {
      // for date
      DateTime parsedDate = DateFormat('d/M/yyyy').parse(dob.text);
      String formattedDate = DateFormat('yyyy-MM-dd').format(parsedDate);
      final url = "/dedupe/check";
      final Map<String, dynamic> mapeddata = {
        "firstName": firstName.text,
        "lastName": lastName.text,
        "dateOfBirth": formattedDate,
        "mobileNumber": "63" + mobilePhone.text
      };
      print("data is ${mapeddata}");

      final headers = {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'Correlation-Id': '3fa85f64-5717-4562-b3fc-2c963f66afa6',
        'Cookie':
            'AWSALB=SsezDH7Q4QiKN438NtO/HC1sdemLNqTbSxUTsxitbCuhbKjGbD5T00rWZBWky9HiAmeoFHAM/W6bNouDd1TtsYS9PUuJgXh+s/kbdFg0GOKuq4VzW3lqZgkP5Wcg; AWSALBCORS=SsezDH7Q4QiKN438NtO/HC1sdemLNqTbSxUTsxitbCuhbKjGbD5T00rWZBWky9HiAmeoFHAM/W6bNouDd1TtsYS9PUuJgXh+s/kbdFg0GOKuq4VzW3lqZgkP5Wcg',
        'channel': 'fsa',
      };

      // final headers = {
      //   'Authorization': 'Bearer $token',
      //   'Accept': 'application/json',
      //   'Content-Type': 'application/json',
      //   //'Cookie':'METADATA=ed00e3be-2009-4f02-a8e7-034c6b5ef516; AWSALB=5HnvCHbXFgiKQuUxHH8jpw0zVpH1nkb4q+iTptJEEy8J04v/7blP3ilmKCy4kFPrvUNDeIqse1CO2uR8FivWWU1hO8xQoMz+LnCtrcR0RCJkChBqhN8+jGZAMrDO; AWSALBCORS=5HnvCHbXFgiKQuUxHH8jpw0zVpH1nkb4q+iTptJEEy8J04v/7blP3ilmKCy4kFPrvUNDeIqse1CO2uR8FivWWU1hO8xQoMz+LnCtrcR0RCJkChBqhN8+jGZAMrDO; METADATA=3c6749d5-60ea-4486-aede-fd4538d2fe39',
      //   'User-Agent':
      //       'Mozilla/5.0 (Linux; Android 11; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36',
      //   'Correlation-Id': '3fa85f64-5717-4562-b3fc-2c963f66afa6',
      //   'Cookie': 'METADATA=3c6749d5-60ea-4486-aede-fd4538d2fe39',
      //   'Idempotency-Key': 'djbcjkdnd',
      //   //'channel': 'salesapp',
      //   'channel': 'fsa',
      // };
      try {
        final response =
            await ApiService.postWithHeadersUnoApi(url, mapeddata, headers);
        if (response != null) {
          print("response is ${response.body}");
          final responseBody = json.decode(response.body);
          final message = responseBody["message"] ?? "";
          if (message == "No Client Found") {
            await userDetailsMatch(token, "63${mobilePhone.text}");
          } else {
            // NTB
            // if (responseBody["customerDetails"] == null && responseBody["decision"].toUpperCase() == "START_FRESH")
            if ((responseBody["customerDetails"] == null ||
                    responseBody["customerDetails"].isEmpty) &&
                responseBody["decision"].toUpperCase() == "START_FRESH") {
              print("I am NTB user");
              showDialog(
                context: context,
                barrierDismissible:
                    false, // User cannot close without choosing an option
                builder: (context) => AlertDialog(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18)),
                  titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                  contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                  title: Row(
                    children: const [
                      Icon(Icons.info_outline, color: Colors.blue, size: 28),
                      SizedBox(width: 10),
                      Text(
                        "KYC Required",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  content: const Text(
                    "To continue your onboarding, we need to verify your identity.\n\n"
                    "Tap **Proceed** to start the eKYC verification process. This will take only a few minutes.",
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.4,
                    ),
                  ),
                  actionsPadding: const EdgeInsets.only(right: 16, bottom: 16),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text(
                        "Cancel",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.black54,
                        ),
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                      ),
                      onPressed: () async {
                        if (!mounted) return;
                        HyperKycResult result = await EkycService.startKyc();
                        final statusStr = result.status.toString();
                        print("result for hyperverser is $result");
                        if (statusStr.contains("autoDeclined")) {
                          print("Decline");
                          showDialog(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: Text("Info"),
                              content: Text(
                                  "Your KYC result  ${result.status.toString().split('.').last}"),
                              actions: [
                                TextButton(
                                  child: const Text("OK"),
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                ),
                              ],
                            ),
                          );
                        } else if ((statusStr.contains("autoApproved")) ||
                            (statusStr.contains("needsReview"))) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => LosApplicationPage(
                                leadId: "",
                                campaign: "",
                                pagemode: "fromHYPERVERSER",
                                dsrId: "",
                                ekycResult: result,
                              ),
                            ),
                          );
                        } else {
                          print("Nothing: $statusStr");
                          showDialog(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: Text("Info"),
                              content: Text(
                                  "Your KYC result  ${result.status.toString().split('.').last}"),
                              actions: [
                                TextButton(
                                  child: const Text("OK"),
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                ),
                              ],
                            ),
                          );
                        }
                      },
                      child: const Text(
                        "Proceed",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }

            // ETB Block
            else {
              print("I am ETB user");

              if (responseBody["decision"] == "Reject") {
                print("REJECT BLOCK HIT");

                String reason = responseBody["reason"] ?? "No reason provided";

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: const Color(0xFFa604ad),
                    content: Text(reason, style: TextStyle(fontSize: 15)),
                  ),
                );

                Navigator.pop(context);
              } else if (responseBody["decision"].toUpperCase() ==
                      "START_FRESH" ||
                  responseBody["decision"] == "Resume") {
                print("I am ETB user in start fresh");

                var Etbdetails = responseBody["customerDetails"];
                // print(const JsonEncoder.withIndent('  ').convert(Etbdetails));
                print("details is $Etbdetails");
                //print(responseBody["customerDetails"]);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => LosApplicationPage(
                      leadId: "",
                      campaign: "",
                      pagemode: "fromETBStartFresh",
                      dsrId: "",
                      customerDetails: Etbdetails,
                    ),
                  ),
                );
              }
            }

            //    // REJECT block
            //     else if (responseBody["decision"] == "Reject" &&
            //         (responseBody["customerDetails"] == null ||
            //         (responseBody["customerDetails"] is Map && responseBody["customerDetails"].isEmpty) ||
            //         (responseBody["customerDetails"] is List && responseBody["customerDetails"].isEmpty))) {

            //         print("REJECT BLOCK HIT");

            //         String reason = responseBody["reason"] ?? "No reason provided";

            //         ScaffoldMessenger.of(context).showSnackBar(
            //           SnackBar(
            //             backgroundColor: const Color(0xFFa604ad),
            //             content: Text(reason, style: TextStyle(fontSize: 15)),
            //           ),
            //         );

            //         Future.delayed(const Duration(seconds: 3), () {
            //           if (!context.mounted) return;

            //           print("NAVIGATING NOW...");

            //           Navigator.of(context, rootNavigator: true).push(
            //             MaterialPageRoute(builder: (_) => NavigationPage()),
            //           );
            //         });
            //     }

            // //ETB START

            //  else if (responseBody["customerDetails"] != null)

            // {
            //   print("I am a etb customer");
            //   if(responseBody["decision"] == "Resume")
            //   {
            //       // Redirect to AAM
            //       print("Decision is Resume");
            //   }

            //   else if(responseBody["decision"] == "Start_Fresh")
            //   {
            //     var Etbdetails = responseBody["customerDetails"];
            //     print(const JsonEncoder.withIndent('  ').convert(Etbdetails));
            //     print("details is $Etbdetails");
            //     //print(responseBody["customerDetails"]);
            //       Navigator.push(
            //                 context,
            //                 MaterialPageRoute(
            //                   builder: (context) => LosApplicationPage(
            //                     leadId: "",
            //                     campaign: "",
            //                     pagemode: "fromETBStartFresh",
            //                     dsrId: "",
            //                     customerDetails: Etbdetails,

            //                   ),
            //                 ),
            //               );
            //   }
            // }

            print("I am in else block");
          }
        } else {
          _showAlert("No response from server.");
        }
      } catch (e) {
        print("Login error: $e");
        _showAlert("Network or server error.");
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    } else {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in all fields.")),
      );
    }
  }

  // call the next api
  Future<void> userDetailsMatch(String token, String mobileNo) async {
    try {
      final url = "/api/v2/app/offer";
      final headers = {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'User-Agent':
            'Mozilla/5.0 (Linux; Android 11; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36',
      };

      final body = {
        "mobileNo": mobileNo,
        "applicationId": "",
        "leadId": "",
        "clientId": "",
        "cwTransactionId": "",
        "extAppNumber": "",
        "sourceCompany": "",
        "sourcingChannel": "",
        "isActive": "Y"
      };

      print("Body : $body");

      final response =
          await ApiService.postWithHeadersUnoApi(url, body, headers);

      if (response != null) {
        print("Status code: ${response.statusCode}");
        final responseBody = jsonDecode(response.body);
        print("Response body: $responseBody");

        if (response.statusCode == 200) {
          print("ETB user data fetch API from UNO");

          if (responseBody is List && responseBody.isNotEmpty) {
            final firstOffer = responseBody[0];
            final mobile = firstOffer['mobilePhone'] ?? "N/A";
            final appId = firstOffer['applicationId'] ?? "N/A";
            print("Mobile No: $mobile");
            print("Application ID: $appId");
          } else {
            print("No offers found in response.");
          }
        } else {
          print("Failed: ${response.statusCode}");
        }
      } else {
        print("No response from server");
      }
    } catch (e) {
      print("Error in userDetailsMatch: $e");
    }
  }

  void _showAlert(String message,
      {VoidCallback? onOk, bool redirectToEntry = false}) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Info"),
        content: Text(message),
        actions: [
          TextButton(
            child: const Text("OK"),
            onPressed: () {
              Navigator.of(context).pop();
              if (redirectToEntry) {
                Navigator.of(context)
                    .push(MaterialPageRoute(builder: (_) => EntryPage()));
              } else if (onOk != null) {
                onOk();
              }
            },
          ),
        ],
      ),
    );
  }
}
