import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pointycastle/api.dart' hide Padding;
import 'package:pointycastle/random/fortuna_random.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unosfa/pages/config/config.dart';
import 'package:unosfa/pages/generalscreens/customNavigation.dart';
import 'package:unosfa/pages/services/api_service.dart';
import 'package:unosfa/pages/services/secret_key.dart';
import '../../widgetSupport/widgetstyle.dart';
import 'package:crypto/crypto.dart';

class LoginOtp extends StatefulWidget {
  final String uname;
  final String pwd;
  final String phone_number;
  const LoginOtp(this.uname, this.pwd, this.phone_number);

  @override
  State<LoginOtp> createState() => _LoginOtpState();
}

class _LoginOtpState extends State<LoginOtp> {
  bool _isLoading = false;
  final _formKey = GlobalKey<FormState>();
  List<String>? userInfo;
  final TextEditingController _otpController = TextEditingController();
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
    String phone = widget.phone_number.toString();
    if (phone.length == 12 && phone.startsWith("63")) {
      phone = phone.substring(2);
    }
    print("phone number $phone");

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? authToken = prefs.getString('accessToken');
    String otp = generateSecureTransactionId();
    setState(() {
      recivedOtp = otp.toString();
      print("OTP : $recivedOtp");
    });
    // Step 1: Get access token
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
        'User-Agent':
            'Mozilla/5.0 (Linux; Android 11; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36', // Override the default User-Agent
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
          'User-Agent':
              'Mozilla/5.0 (Linux; Android 11; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36', // Override the default User-Agent
        },
        body: json.encode({
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
        }),
      );
      if (smsResponse.statusCode == 200) {
        print('SMS sent successfully!');
        setState(() {
          recivedOtp = otp.toString();
        });
      } else {
        Map<String, dynamic> logmappedData = {
          "url": "${AppConfig.dynamicBaseUrl}/fnf/api/v2/sms/sendSmsMessage'",
          "request_body": json.encode({
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
          }),
          "status_code": smsResponse.statusCode,
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
        // ignore: unused_local_variable
        final LogResponse = await http.post(
          logUrl,
          headers: headers,
          body: json.encode(logmappedData),
        );
        print('Failed to send SMS. Status: ${smsResponse.statusCode}');
        print('Response: ${response.body}');
      }
    } else {
      print('Failed to fetch token. Status: ${response.statusCode}');
      print('Response: ${response.body}');
    }
  }
// Function to check location access

  Future<void> _verifyOtp() async {
    bool checkIndata = false;
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
      if (_formKey.currentState!.validate()) {
        if (recivedOtp == _otpController.text) {
          setState(() {
            _isLoading = true;
          });
          var url = "/api/users/login/";
          final Map<String, String> mapeddata = {
            'username': widget.uname,
            'password': widget.pwd,
          };
          final response = await ApiService.post(url, mapeddata);
          if (response != null) {
            if (response.statusCode == 200) {
              final data = response.data;
              if (data['access'] != null) {
                List<String> userInfo = [
                  data['user']['username'],
                  data['user']['first_name'],
                  data['user']['last_name'],
                  data['user']['email'],
                ];
                SharedPreferences prefs = await SharedPreferences.getInstance();
                await prefs.setStringList('userInfo', userInfo);
                // await prefs.setBool('isLoggedIn', true);
                await prefs.setString('accessToken', data['access']);
                await prefs.setString('refreshToken', data['refresh']);
                await prefs.setString('role', data['roles'][0]);
                String? token = prefs.getString('accessToken');
                final headers = {
                  'Authorization': 'Bearer $token',
                  'User-Agent':
                      'Mozilla/5.0 (Linux; Android 11; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36',
                };
                var checkInUserUrl = "/api/users/attendance/active/";
                final checkInUserResponse =
                    await ApiService.getWithHeaders(checkInUserUrl, headers);

                if (checkInUserResponse != null) {
                  final data2 = response.data;
                  if (data2['data'] is List && data2['data'].isNotEmpty) {
                    final firstItem = data2['data'][0];
                    checkIndata =
                        firstItem['is_checked_in']; // this will be a bool
                    await prefs.setBool('checkInStatus', checkIndata);
                  }
                }

                Future.delayed(const Duration(seconds: 2), () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const NavigationPage()),
                  );
                });
              }
            } else {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: Text("Info"),
                    content: Text("Invalid username or password."),
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
          } else {
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: Text("Info"),
                  content: Text("Server Error Please Try Again"),
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
        } else {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text("Info"),
                content: Text("Invalid OTP"),
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
              color: Colors.black.withOpacity(0.5),
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
