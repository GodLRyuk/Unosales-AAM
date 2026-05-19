import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pointycastle/api.dart' hide Padding;
import 'package:pointycastle/random/fortuna_random.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unosfa/pages/config/config.dart';
import 'package:unosfa/pages/generalscreens/forcepasswordchange.dart';
import 'package:unosfa/pages/services/api_service.dart';
import 'package:unosfa/pages/services/secret_key.dart';
import 'package:unosfa/pages/splash_screen.dart';
import '../../widgetSupport/widgetstyle.dart';
import 'package:crypto/crypto.dart';

class Changepasswordotp extends StatefulWidget {
  final String newpassword;
  final String oldpassword;
  final String confirmpassword;
  final token;
  final String phone_number;
  const Changepasswordotp({
    super.key,
    required this.newpassword,
    required this.oldpassword,
    required this.confirmpassword,
    required this.token,
    required this.phone_number,
  });

  @override
  State<Changepasswordotp> createState() => _ChangepasswordotpState();
}

class _ChangepasswordotpState extends State<Changepasswordotp> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _otpController = TextEditingController();
  bool _isLoading = false;

  final FocusNode _focusNode = FocusNode();
  Timer? _timer;
  int _start = 120;
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
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? authToken = prefs.getString('accessToken');
    String otp = generateSecureTransactionId();
    setState(() {
      recivedOtp = otp.toString();
    });
    // // Step 1: Get access token
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
                {"to": "63${widget.phone_number}"}
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
                  {"to": "63${widget.phone_number}"}
                ],
                "text":
                    """Your One-Time PIN is ${otp}. NEVER SHARE YOUR OTP. UNO will never request OTP from customers. If you did not request an OTP, please contact us."""
              }
            ]
          }),
          "status_code": smsResponse.statusCode,
          "response_body": json.decode(smsResponse.body),
        };
        final logUrl = Uri.parse("${AppConfig.otpUrl}/api/logs/");
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
        print('Failed to send SMS. Status: ${smsResponse.statusCode}');
        print('Response: ${smsResponse.body}');
      }
    } else {
      print('Failed to fetch token. Status: ${response.statusCode}');
      print('Response: ${response.body}');
    }
  }

  void _verifyOtp() async {
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
      final url = '/api/users/change-password/';
      if (_formKey.currentState?.validate() ?? false) {
        if (widget.token == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text(
                    'Authentication token not found. Please log in again.')),
          );
          return;
        }

        setState(() {
          _isLoading = true;
        });

        try {
          Map<String, String> mappedData = {
            'old_password': widget.oldpassword,
            'new_password': widget.newpassword,
            'confirm_password': widget.confirmpassword,
          };
          final headers = {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${widget.token}',
            'User-Agent':
                'Mozilla/5.0 (Linux; Android 11; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36',
          };

          final response = await ApiService.postJsonWithHeaders(
            "$url",
            mappedData,
            headers,
          );
          if (response != null) {
            if (response.statusCode == 200) {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: Text("Info"),
                    content: Text(
                        "Your password has been successfully changed. If you did not ask to change your password, please contact us."),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => SplashScreen(),
                            ),
                          );
                        },
                        child: Text("OK"),
                      ),
                    ],
                  );
                },
              );
            } else if (response.statusCode == 400) {
              final data = json.decode(response.data.body);
              String errorMessage = '';

              if (data['non_field_errors'] is List) {
                errorMessage = (data['non_field_errors'] as List).join("\n");
              } else if (data['detail'] != null) {
                errorMessage = data['detail'].toString();
              } else {
                errorMessage = "Unknown error occurred.";
              }

              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: Text("Info"),
                    content: Text(errorMessage),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => ForcePasswordChange(
                                  accesToken: widget.token!,
                                  phone_number: widget.phone_number),
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
          } else {
            // Null response due to SSL failure or connection issue
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Failed to connect to the server.")),
            );
          }
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${e.toString()}')),
          );
        } finally {
          setState(() {
            _isLoading = false;
          });
        }
      }
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
                  Row(
                    children: [
                      ElevatedButton(
                        onPressed: _verifyOtp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: EdgeInsets.symmetric(
                            horizontal:
                                MediaQuery.of(context).size.width * 0.18,
                            vertical: MediaQuery.of(context).size.height * 0.01,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                        ),
                        child: Text(
                          "Verify OTP",
                          style: WidgetSupport.LoginButtonTextColor(),
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
                            horizontal: MediaQuery.of(context).size.width * 0.0,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                          ),
                          child: Center(
                            child: Text(
                              "Resend OTP",
                              style:
                                  WidgetSupport.LoginButtonTextColor().copyWith(
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 7),
      child: SizedBox(
        width: 230,
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
