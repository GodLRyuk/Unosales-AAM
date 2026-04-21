import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unosfa/pages/FSAModule/fsadashboard.dart';
import 'package:unosfa/pages/generalscreens/entrypage.dart';
import 'package:unosfa/pages/generalscreens/forcepasswordchange.dart';
import 'package:unosfa/pages/generalscreens/forgotpassword.dart';
import 'package:unosfa/pages/otpscreens/login_otp.dart';
import 'package:unosfa/pages/FRModule/salesdashboard.dart';
import 'package:unosfa/pages/services/api_service.dart';
import '../../widgetSupport/widgetstyle.dart';

class LoginPage extends StatefulWidget {
  final String loginWith;
  const LoginPage({super.key, required this.loginWith});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

    if (isLoggedIn) {
      if (widget.loginWith == "FSA") {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const Fsadashboard()),
        );
      } else if (widget.loginWith == "FR") {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const Salesdashboard()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const EntryPage()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          Column(
            children: [
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(
                            top: 150, left: 15, right: 15),
                        child: Image(
                          image: AssetImage("images/logo.PNG"),
                          width: MediaQuery.of(context).size.width * 0.70,
                        ),
                      ),
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.05,
                      ),
                      Column(
                        children: [
                          Text(
                            "WELCOME TO THE",
                            style: WidgetSupport.entrywelcome1(),
                          ),
                          Text(
                            "WORLD OF",
                            style: WidgetSupport.entrywelcome1(),
                          ),
                          Text(
                            "ELEVATED BANKING",
                            style: WidgetSupport.entrywelcome2(),
                          ),
                        ],
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
                                _usernameController,
                                "Agent Id",
                                '',
                                'username',
                                icon: FontAwesomeIcons.envelope,
                              ),
                              const SizedBox(height: 20),
                              _buildPasswordTextField(
                                _passwordController,
                                "Password",
                                '',
                                'password',
                                icon: FontAwesomeIcons.lock,
                                obscureText: !_isPasswordVisible,
                              ),
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
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    GestureDetector(
                                      onTap: () {
                                        if (_formKey.currentState!.validate()) {
                                          userlogin();
                                        }
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
                                            "LOGIN",
                                            style: WidgetSupport
                                                .LoginButtonTextColor(),
                                          ),
                                        ),
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        Navigator.pushReplacement(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                ForgotPassword(),
                                          ),
                                        );
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
                                            "FORGOT PASSWORD?",
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
    IconData icon = FontAwesomeIcons.solidCircleUser,
    bool obscureText = false,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
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
        if (value == null || value.isEmpty) {
          return '$hintText is required';
        }
        return null;
      },
    );
  }

  Widget _buildPasswordTextField(
    TextEditingController controller,
    String hintText,
    String validationMessage,
    String validationKey, {
    IconData icon = FontAwesomeIcons.solidCircleUser,
    bool obscureText = false,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: WidgetSupport.inputLabel(),
        suffixIcon: Padding(
          padding: const EdgeInsets.all(0),
          child: IconButton(
            icon: Icon(
              _isPasswordVisible
                  ? FontAwesomeIcons.eyeSlash
                  : FontAwesomeIcons.eye,
              color: Colors.purple,
              size: 20,
            ),
            onPressed: () {
              setState(() {
                _isPasswordVisible = !_isPasswordVisible;
              });
            },
          ),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return '$hintText is required';
        }
        return null;
      },
    );
  }

  Future<void> userlogin() async {
    setState(() {
      _isLoading = true;
    });

    if (_formKey.currentState!.validate()) {
      final url = '/api/users/login/';
      final Map<String, String> mapeddata = {
        'username': _usernameController.text,
        'password': _passwordController.text,
      };
        final response = await ApiService.post(url, mapeddata);
        print("Resp: $response");
      try {
        if (response != null) {
          final statusCode = response.statusCode;
          if (response.body.isNotEmpty) {
            try {
              final data = json.decode(response.body);

              if (statusCode == 200) {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setString('accessToken', data['access']);
                await prefs.setString('refreshToken', data['refresh']);
                final role = data['roles'][0];
                if (widget.loginWith == role && data['access'] != null) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => LoginOtp(
                        _usernameController.text,
                        _passwordController.text,
                        data['user']['phone_number'],
                      ),
                    ),
                  );
                } else {
                  _showAlert("Invalid credentials.", redirectToEntry: true);
                }
              } else if (statusCode == 401) {
                final detail = data['detail'];
                final accessToken = data['access'] ?? "";
                final phone = data['user']?['phone_number'] ?? "";

                if (data['force_password_change'] == true ||
                    detail == "Your password has expired. Please change it." ||
                    detail ==
                        "You must change your password before proceeding.") {
                  _showAlert(
                    detail ?? "Password change required.",
                    onOk: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ForcePasswordChange(
                            accesToken: accessToken,
                            phone_number: phone,
                          ),
                        ),
                      );
                    },
                  );
                } else if (detail == "Invalid credentials.") {
                  _showAlert("Invalid username or password.");
                } else {
                  _showAlert(detail ?? "Login failed. Please try again.");
                }
              } else {
                _showAlert("Login failed: ${statusCode}");
              }
            } catch (e) {
              print("JSON decode error: $e");
              _showAlert("Invalid server response.");
            }
          } else {
            _showAlert("Empty response from server.");
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
