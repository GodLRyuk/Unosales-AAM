import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:pointycastle/api.dart' hide Padding;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unosfa/pages/config/config.dart';
import 'package:unosfa/pages/generalscreens/customNavigation.dart';
import 'package:unosfa/pages/services/api_service.dart';
import 'package:unosfa/pages/services/secret_key.dart';
import 'package:unosfa/widgetSupport/widgetstyle.dart';
import 'package:pointycastle/random/fortuna_random.dart';
import 'package:crypto/crypto.dart';
import 'dart:typed_data';

class ProfileUpdate extends StatefulWidget {
  const ProfileUpdate({super.key});

  @override
  State<ProfileUpdate> createState() => _ProfileUpdateState();
}

class _ProfileUpdateState extends State<ProfileUpdate> {
  Map<String, dynamic> userData = {};
  final _formKey = GlobalKey<FormState>();
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _email = TextEditingController();
  final _phoneNumber = TextEditingController();
  final TextEditingController _otpController = TextEditingController();

  final FocusNode _firstNameFocusNode = FocusNode();
  final FocusNode _lastNameFocusNode = FocusNode();
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _phoneFocusNode = FocusNode();
  final FocusNode _focusNode = FocusNode();

  String storedEmail = "";
  bool emailChanged = false;
  bool phoneChanged = false;
  bool isOtpVerified = false;
  bool resendTimer = false;
  bool isOtpExpired = false;
  String recivedOtp = "";
  Timer? _timer;
  int _start = 120;
  bool _showOtpField = false;

  @override
  void initState() {
    super.initState();
    _loadData();
    _startTimer();
    _emailFocusNode.addListener(_checkEmailChange);
    _phoneFocusNode.addListener(_checkPhoneChange);
  }

  void _checkEmailChange() {
    print("tttttttttttt");
    if (!_emailFocusNode.hasFocus && _email.text.trim() != storedEmail) {
      setState(() {
        emailChanged = true;
        _showOtpField = true;
      });
    }
  }

  void _checkPhoneChange() {
    if (!_phoneFocusNode.hasFocus &&
        _phoneNumber.text.trim() != userData['phone_number']?.substring(2)) {
      setState(() {
        phoneChanged = true;
        _showOtpField = true;
      });
    }
  }

  Future<void> _loadData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('accessToken');
    try {
      final response = await ApiService.getWithHeaders(
        "/api/users/profile/",
        {
          'Authorization': 'Bearer $token',
          'User-Agent':
              'Mozilla/5.0 (Linux; Android 11; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36',
        },
      );
      if (response != null && response.statusCode == 200) {
        userData = json.decode(response.data.body);
        setState(() {
          storedEmail = userData['email'];
          _firstName.text = userData['first_name'];
          _lastName.text = userData['last_name'];
          _email.text = userData['email'];
          _phoneNumber.text = userData['phone_number']?.substring(2) ?? "";
        });
      }
    } catch (e) {}
  }

  void _resendOtp() {
    _sendOtp();
    setState(() {
      _start = 120;
      _otpController.clear();
      resendTimer = false;
      isOtpExpired = false;
    });
    _startTimer();
  }

  @override
  void dispose() {
    _firstNameFocusNode.dispose();
    _lastNameFocusNode.dispose();
    _emailFocusNode.dispose();
    _phoneFocusNode.dispose();
    _focusNode.dispose();
    _timer?.cancel();
    super.dispose();
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

  String generateSecureTransactionId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final entropyInput = '$timestamp:UnoSecureSeed';
    final secureRandom = createSecureFortunaRandomFromEntropy(entropyInput);

    final digits = List.generate(4, (_) {
      final byte = secureRandom.nextUint8();
      return (byte % 10).toString();
    }).join();

    return digits;
  }

  FortunaRandom createSecureFortunaRandomFromEntropy(String entropySource) {
    final secureRandom = FortunaRandom();
    final entropy = sha256.convert(utf8.encode(entropySource)).bytes;
    secureRandom.seed(KeyParameter(Uint8List.fromList(entropy)));
    return secureRandom;
  }

  Future<void> _sendOtp() async {
    // String otp = generateSecureTransactionId();
    // setState(() {
    //   recivedOtp = otp;
    // });

    // if (emailChanged) {
    //   // API sends OTP to email when updating email
    //   _updateprofile(sendOtpOnly: true);
    // } else if (phoneChanged) {
    //   // OTP sent via SMS
    //   SharedPreferences prefs = await SharedPreferences.getInstance();
    //   String? authToken = prefs.getString('accessToken');

    //  Client Id and client secret changed. So use through firebase where it is updated
    // String clientId = await otpClientId();
    // String clientSecret = await otpClientSecret();

    // final body = {
    //   'client_id': clientId,
    //   'client_secret': clientSecret,
    //   'grant_type': 'client_credentials',
    // };

    // ********************************************************
    //
    //   final body = AppConfig.flavour == 'uat'
    //       ? {
    //           'client_id':
    //               'NP8bjuRa4l0BK71XatIfMfdNmKVXndaCoWOYXFeILmXTi2gT6N8p',
    //           'client_secret':
    //               'XRpjpMeThK8Q88wgsM7GAtIf5nVN0gTHjni7lmFKVD2AeGx9JJdWW5UEffqTQjOGgl',
    //           'grant_type': 'client_credentials',
    //         }
    //       : {
    //           'client_id':
    //               'Bm9CjuRa4l0BK71XatIGdHdNmKVXndaloWpYXFeILmXTi2re5f6v',
    //           'client_secret':
    //               'DswfeVuRhK8Q88wgsM7GAtIf7MCX0gTHjni7lmFKVD2AeGx9JJdWW5UERtsWEKYSD3',
    //           'grant_type': 'client_credentials',
    //         };

    //   final response = await http.post(
    //     Uri.parse('${AppConfig.otpUrl}/oauth2/token'),
    //     headers: {'Content-Type': 'application/x-www-form-urlencoded'},
    //     body: body,
    //   );

    //   if (response.statusCode == 200) {
    //     final accessToken = json.decode(response.data.body)['access_token'];
    //     await http.post(
    //       Uri.parse('${AppConfig.otpUrl}/fnf/api/v2/sms/sendSmsMessage'),
    //       headers: {
    //         'Content-Type': 'application/json',
    //         'Authorization': 'Bearer $accessToken',
    //       },
    //       body: json.encode({
    //         "messages": [
    //           {
    //             "from": "UnoBank",
    //             "destinations": [
    //               {"to": "+63${_phoneNumber.text}"}
    //             ],
    //             "text": "Your OTP is $otp. NEVER SHARE THIS OTP."
    //           }
    //         ]
    //       }),
    //     );
    //   }
    // }
    // _startTimer();
  }

  Future<void> _verifyOtp() async {
    if (isOtpExpired) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("OTP has expired")),
      );
      return;
    }

    if (recivedOtp == _otpController.text) {
      setState(() {
        isOtpVerified = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("OTP Verified")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Invalid OTP")),
      );
    }
  }

  Future<void> _updateprofile({bool sendOtpOnly = false}) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('accessToken');

    Map<String, dynamic> mappedData = {
      'first_name': _firstName.text,
      'last_name': _lastName.text,
      'email': _email.text,
      'phone_number': "63" + _phoneNumber.text,
      if (!sendOtpOnly) 'otp': _otpController.text,
    };

    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
      'User-Agent':
              'Mozilla/5.0 (Linux; Android 11; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36',
    };

    final response = await ApiService.patchWithHeaders(
        "/api/users/profile/", headers, mappedData);

    if (response != null && response.statusCode == 200) {
      setState(() {
        emailChanged = false;
        phoneChanged = false;
        _showOtpField = false;
        isOtpVerified = false;
      });

      if (!sendOtpOnly) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Profile updated successfully!")));
      }
    } else if (sendOtpOnly && response?.statusCode == 202) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("OTP sent to email")));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Failed to update profile. Check OTP.")));
    }
  }

  String capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                      builder: (context) => NavigationPage(initialIndex: 0)),
                );
              },
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 15.0),
          child: Column(
            children: [
              Stack(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(0),
                        border: Border.all(color: const Color(0xFF640D78))),
                    child: Row(
                      children: [
                        Image.asset("images/user.png", width: 70, height: 70),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${capitalize(userData['first_name'] ?? 'No First Name')} ${capitalize(userData['last_name'] ?? 'No Last Name')}',
                                style: const TextStyle(
                                    fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                "ID: ${userData['username'] ?? 'Guest User'}",
                                style: const TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 100),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _buildTextField(_firstName, "First Name",
                          "Please Enter Your Name", "first_name",
                          focusNode: _firstNameFocusNode,
                          isAlphabetic: true,
                          allowSpaces: true,
                          isRequired: true),
                      _buildTextField(_lastName, "Last Name",
                          "Please Enter Your Name", "last_name",
                          focusNode: _lastNameFocusNode,
                          isAlphabetic: true,
                          allowSpaces: true,
                          isRequired: true),
                      _buildTextField(
                          _email, "Email", "Please Enter Your Email", "email",
                          focusNode: _emailFocusNode,
                          isEmail: true,
                          icon: FontAwesomeIcons.envelope,
                          isRequired: true),
                      _buildMobileTextField(
                          controller: _phoneNumber,
                          isRequired: true,
                          onVerify: () {
                            if (_phoneNumber.text.length == 10) {
                              _sendOtp();
                            }
                          }),
                      const SizedBox(height: 20),
                      if (_showOtpField) ...[
                        _buildOtpBox(),
                        const SizedBox(height: 10),
                        Text(_timerText,
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            ElevatedButton(
                              onPressed: _verifyOtp,
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.purple),
                              child: const Text("Verify OTP"),
                            ),
                            ElevatedButton(
                              onPressed: resendTimer ? _resendOtp : null,
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.purple),
                              child: const Text("Resend OTP"),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          onPressed:
                              isOtpVerified ? () => _updateprofile() : null,
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.purple),
                          child: const Text("Submit"),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
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
    bool allowSpaces = false,
    bool isReferralCode = false,
    bool isRequired = false,
    required FocusNode focusNode,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      focusNode: focusNode,
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
      ],
      validator: (value) {
        if ((value == null || value.isEmpty) && isRequired) {
          return validationMessage;
        }
        if (isEmail &&
            !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value!)) {
          return 'Please enter valid email';
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
        suffix: Padding(
          padding: const EdgeInsets.all(0),
          child: Icon(icon, color: Colors.purple, size: 15),
        ),
      ),
    );
  }

  Widget _buildMobileTextField({
    required TextEditingController controller,
    bool isRequired = true,
    required VoidCallback onVerify, // verification callback
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
          child: TextFormField(
            controller: controller,
            keyboardType: TextInputType.number,
            inputFormatters: [
              LengthLimitingTextInputFormatter(10),
              FilteringTextInputFormatter.digitsOnly,
            ],
            validator: (value) {
              if (isRequired && (value == null || value.trim().isEmpty)) {
                return 'Phone number is required';
              }
              if (value!.length != 10) {
                return 'Enter a valid 10-digit phone number';
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
                            style: TextStyle(color: Colors.red, fontSize: 15),
                          ),
                        ],
                      ),
                    )
                  : Text("Phone Number", style: WidgetSupport.inputLabel()),
              suffixIcon: TextButton(
                onPressed: () {
                  if (!resendTimer) {
                    // Send OTP on Verify click
                    _sendOtp(); // Call your OTP sending function
                    setState(() {
                      _showOtpField = true; // Show OTP input box
                      _start = 120; // Reset timer
                    });
                    _startTimer(); // Start countdown
                  }
                },
                child: Text(
                  "Verify",
                  style: WidgetSupport.LoginButtonTextColor().copyWith(
                    color: resendTimer ? Colors.grey : Colors.purple,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
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
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            counterText: "",
            hintText: "-   -   -   -",
            hintStyle: const TextStyle(color: Colors.grey),
            contentPadding: const EdgeInsets.symmetric(vertical: 10),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.grey),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.purple),
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
