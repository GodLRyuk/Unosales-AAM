import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pointycastle/api.dart' hide Padding;
import 'package:pointycastle/random/fortuna_random.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unosfa/pages/config/config.dart';
import 'package:unosfa/pages/generalscreens/login.dart';
import 'package:unosfa/pages/generalscreens/registration.dart';
import 'package:unosfa/pages/services/api_service.dart';
import 'package:unosfa/pages/services/secret_key.dart';
import '../../widgetSupport/widgetstyle.dart';
import 'package:crypto/crypto.dart';

class RegistrationOtpPage extends StatefulWidget {
  final String loginWith;
  final String firstName;
  final String lastName;
  final String emailId;
  final String offic;
  final String phoneNumber;
  final dynamic kyc_id_number;
  final dynamic kyc_id_type;
  final File? kycDocument;
  final String referral_code;

  const RegistrationOtpPage(
      {super.key,
      required this.loginWith,
      required this.firstName,
      required this.lastName,
      required this.emailId,
      required this.offic,
      required this.phoneNumber,
      this.kyc_id_type,
      this.kyc_id_number,
      this.kycDocument,
      required this.referral_code});

  @override
  State<RegistrationOtpPage> createState() => RegistrationOtpPageState();
}

class RegistrationOtpPageState extends State<RegistrationOtpPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _otpController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  Timer? _timer;
  int _start = 120;
  bool _isLoading = false;
  String recivedOtp = "";
  bool resendTimer = false;
  bool isOtpExpired = false;
  @override
  void initState() {
    super.initState();
    _start = 120; // 🔥 Add this line to initialize the countdown
    resendTimer = false;
    isOtpExpired = false;
    _sendOtp();
    _startTimer();
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

    final digits = List.generate(4, (_) {
      final byte = secureRandom.nextUint8();
      return (byte % 10).toString();
    }).join();

    return digits; // e.g., "482739"
  }

  Future<void> _sendOtp() async {
    String phone = widget.phoneNumber.toString();
    if (phone.length == 12 && phone.startsWith("63")) {
      phone = phone.substring(2);
    }
    print("phone number $phone");
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? authToken = prefs.getString('accessToken');
    String otp = generateSecureTransactionId();
    setState(() {
      recivedOtp = otp.toString();
    });
    // Step 1: Get access token
    String clientId = await otpRegistrationClientId();
    String clientSecret = await otpRegistrationClientSecret();

    final body = {
      'client_id': clientId,
      'client_secret': clientSecret,
      'grant_type': 'client_credentials',
    };
    final headers = {
      'Content-Type': 'application/x-www-form-urlencoded',
    };
    final response = await ApiService.postWithHeadersUnoApi(
      '/oauth2/token',
      headers,
      body,
    );
    if (response!.statusCode == 200) {
      final data = response.data;
      final accessToken = data['access_token'];
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      };
      // Step 2: Send SMS using the access token
      final smsResponse = await ApiService.postWithHeadersUnoApi(
          '/fnf/api/v2/sms/sendSmsMessage',
          {
            "messages": [
              {
                "from": "UnoBank",
                "destinations": [
                  {"to": "+63${phone}"}
                ],
                "text":
                    """Your One-Time PIN is ${otp}. NEVER SHARE YOUR OTP. UNO will never request OTP from customers. If you did not request an OTP, please contact us."""
              }
            ]
          },
          headers);
      if (smsResponse!.statusCode == 200) {
        print('SMS sent successfully!');
        setState(() {
          recivedOtp = otp.toString();
        });
      } else {
        Map<String, dynamic> logmappedData = {
          "url": "${AppConfig.otpUrl}/fnf/api/v2/sms/sendSmsMessage'",
          "request_body": {
            "messages": [
              {
                "from": "UnoBank",
                "destinations": [
                  {"to": "63${phone}"}
                ],
                "text":
                    """Your One-Time PIN is ${otp}. NEVER SHARE YOUR OTP. UNO will never request OTP from customers. If you did not request an OTP, please contact us."""
              }
            ]
          },
          "status_code": smsResponse.statusCode,
          "response_body": json.decode(smsResponse.data),
        };
        final logUrl = "/api/logs/";
        // ignore: unused_local_variable
        final LogResponse = await ApiService.post(
          logUrl,
          logmappedData,
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
          try {
            final Map<String, String> fields = {
              'first_name': widget.firstName,
              'last_name': widget.lastName,
              'email': widget.emailId,
              'phone_number': "63${widget.phoneNumber}",
              'agency_name': widget.offic,
              'referral_code': widget.referral_code,
              'role_name': widget.loginWith,
            };

            if (widget.kyc_id_type != null &&
                widget.kyc_id_type.toString().trim().isNotEmpty) {
              fields['government_id_type'] = widget.kyc_id_type.toString();
              fields['government_id_number'] = widget.kyc_id_number.toString();
            }
            final response = await ApiService.uploadMultipart(
              endpoint: '/api/agents/',
              fields: fields,
              file: (widget.kyc_id_type != null &&
                      widget.kyc_id_type.toString().trim().isNotEmpty)
                  ? widget.kycDocument
                  : null,
            );
            print(response!.data);
            if (response.statusCode == 201) {
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: Text("Success"),
                  content: Text(
                      // "You have successfully registered.\nYou will receive your ID and Password in the registered Email ID."),
                      "Please contact your supervisor or administrator for further approval"),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (_) => LoginPage(
                                    loginWith: widget.loginWith == "Sal"
                                        ? "Sal"
                                        : "Fin",
                                  )),
                        );
                      },
                      child: Text("OK"),
                    ),
                  ],
                ),
              );
            } else {
              final body = response.data;
              dynamic data;
              try {
                data = json.decode(body ?? '{}');
              } catch (e) {
                data = {
                  'message': 'Unexpected server response',
                  'errors': [body], // show raw message
                };
              }
              final errorMessage = data['errors'] is List
                  ? (data['errors'] as List).join('\n')
                  : data['errors']?.values.join('\n') ?? "Unknown error";

              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: Text(data['message'] ?? "Error"),
                  content: Text(errorMessage),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  const Registration(loginWith: 'Sal')),
                        );
                      },
                      child: Text("OK"),
                    ),
                  ],
                ),
              );
            }
          } catch (e) {
            if (mounted) {
              print("Error: ${e.toString()}");
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Error: ${e.toString()}")),
              );
            }
          }
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
      body: Stack(
        children: [
          Center(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Padding(
                    padding: EdgeInsets.only(top: 0, left: 15, right: 15),
                    child: Image(
                      image: AssetImage("images/logo.PNG"),
                      width: MediaQuery.of(context).size.width * 0.70,
                    ),
                  ),
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.10,
                  ),
                  (AppConfig.flavour != 'prod')
                      ? Text(
                          'Enter OTP sent to your phone OTP [${recivedOtp}]',
                          style: TextStyle(fontSize: 16),
                          textAlign: TextAlign.center,
                        )
                      : Text(
                          'Enter OTP sent to your phone',
                          style: TextStyle(fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                  SizedBox(height: 10),
                  Text(
                    _timerText,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.05,
                  ),
                  Form(
                    key: _formKey,
                    child: _buildOtpBox(),
                  ),
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.02,
                  ),
                  Container(
                    //color: Colors.red,
                    width: MediaQuery.of(context).size.width * 0.60,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap: _verifyOtp,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal:
                                  MediaQuery.of(context).size.width * 0.0,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                            ),
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
                            if (resendTimer != false) {
                              _resendOtp(); // Only call when allowed
                            }
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal:
                                  MediaQuery.of(context).size.width * 0.0,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                            ),
                            child: Center(
                              child: Text(
                                "Resend OTP",
                                style: WidgetSupport.LoginButtonTextColor()
                                    .copyWith(
                                  color: resendTimer
                                      ? Colors.purple
                                      : Colors.grey, // Adjust active color
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
}
