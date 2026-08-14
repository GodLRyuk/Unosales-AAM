import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:unosfa/pages/generalscreens/login.dart';
import 'package:unosfa/pages/services/api_service.dart';
import 'package:unosfa/pages/splash_screen.dart';
import 'package:unosfa/widgetSupport/widgetstyle.dart';

class ForgotPassword extends StatefulWidget {
  const ForgotPassword({super.key});

  @override
  State<ForgotPassword> createState() => _ForgotPasswordState();
}

class _ForgotPasswordState extends State<ForgotPassword> {
  final _formKeyEmail = GlobalKey<FormState>();
  final _formKeyPassword = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmpasswordController = TextEditingController();
  final _emailcode = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isPasswordFormVisible = false;
  bool _isemailFormVisible = true;
  String apiUrl = "";
  bool _isloading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
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
                Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) => LoginPage(
                              loginWith: '',
                            )));
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
                      Padding(
                        padding: const EdgeInsets.only(
                            top: 100, left: 15, right: 15),
                        child: Image(
                          image: AssetImage("images/logo.PNG"),
                          width: MediaQuery.of(context).size.width * 0.70,
                        ),
                      ),
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.15,
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: MediaQuery.of(context).size.width * 0.1,
                        ),
                        child: Column(
                          children: [
                            // Email Form
                            if (_isemailFormVisible) ...[
                              _buildEmailForm(),
                            ],
                            if (_isPasswordFormVisible) ...[
                              SizedBox(height: 20),
                              // Password Form
                              _buildPasswordForm(),
                            ],
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (_isloading)
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

  Widget _buildEmailForm() {
    return Form(
      key: _formKeyEmail,
      child: Column(
        children: [
          TextFormField(
            controller: _emailController,
            decoration: InputDecoration(
              hintText: "Enter your email",
              hintStyle: WidgetSupport.inputLabel(),
              suffixIcon: FaIcon(FontAwesomeIcons.envelope),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your email';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () {
              if (_formKeyEmail.currentState!.validate()) {
                _sendEmailToAPI();
              }
              setState(() {
                _isloading = true;
              });
            },
            child: Container(
              padding: EdgeInsets.symmetric(
                vertical: MediaQuery.of(context).size.height * 0.01,
              ),
              child: Center(
                child: Text(
                  "Submit",
                  style: WidgetSupport.LoginButtonTextColor(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordForm() {
    return Form(
      key: _formKeyPassword,
      child: Column(
        children: [
          _buildPasswordTextField(
            _passwordController,
            "New Password",
            obscureText: !_isPasswordVisible,
            onVisibilityToggle: () {
              setState(() {
                _isPasswordVisible = !_isPasswordVisible;
              });
            },
          ),
          const SizedBox(height: 20),
          _buildPasswordTextField(
            _confirmpasswordController,
            "Confirm Password",
            obscureText: !_isConfirmPasswordVisible,
            isConfirmPassword: true,
            onVisibilityToggle: () {
              setState(() {
                _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
              });
            },
          ),
          _buildCodeTextField(
            _emailcode,
            "6 Digit Code",
          ),
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.02,
          ),
          GestureDetector(
            onTap: () {
              if (_formKeyPassword.currentState!.validate()) {
                _submitNewPassword();
              }
              setState(() {
                _isloading = true;
              });
            },
            child: Container(
              padding: EdgeInsets.symmetric(
                vertical: MediaQuery.of(context).size.height * 0.01,
              ),
              child: Center(
                child: Text(
                  "Submit",
                  style: WidgetSupport.LoginButtonTextColor(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordTextField(
    TextEditingController controller,
    String hintText, {
    bool obscureText = false,
    bool isConfirmPassword = false,
    required VoidCallback onVisibilityToggle,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      maxLength: 10,
      enableInteractiveSelection: false,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: WidgetSupport.inputLabel(),
        suffixIcon: IconButton(
          icon: FaIcon(
            obscureText ? FontAwesomeIcons.eye : FontAwesomeIcons.eyeSlash,
            color: Colors.purple,
            size: 20,
          ),
          onPressed: onVisibilityToggle,
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Enter $hintText';
        }
        if (value.length < 8) {
          return 'Password must be at least 8 characters long.';
        }
        if (value.length > 10) {
          return 'Password must not exceed 10 characters.';
        }
        if (value.length > 10) {
          return 'Password must not exceed 10 characters.';
        }
        if (!RegExp(r'^[A-Z]').hasMatch(value)) {
          return 'Password must start with an uppercase letter.';
        }
        if (!RegExp(r'[a-z]').hasMatch(value)) {
          return 'Password must include at least one lowercase letter.';
        }
        if (!RegExp(r'[0-9]').hasMatch(value)) {
          return 'Password must include at least one number.';
        }
        if (!RegExp(r'[!@#\$%\^&\*\(\)_\+\-=\[\]\{\};:"\\|,.<>\/?]')
            .hasMatch(value)) {
          return 'Password must include one special character.';
        }
        if (RegExp(r'[ &\\/?,]').hasMatch(value)) {
          return 'Special characters like &, \\ / ? , Space are not allowed.';
        }
        if (RegExp(r'(.)\1{2,}|(012|123|234|345|456|567|678|789)')
            .hasMatch(value)) {
          return 'Repeating or sequential values are not allowed.';
        }
        if (isConfirmPassword && value != _passwordController.text) {
          return 'Passwords do not match';
        }
        return null;
      },
    );
  }

  Widget _buildCodeTextField(
    TextEditingController controller,
    String hintText,
  ) {
    return TextFormField(
      controller: controller,
      maxLength: 6,
      enableInteractiveSelection: false,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: WidgetSupport.inputLabel(),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Enter $hintText';
        }
        if (value.length != 6) {
          return 'Code must be exactly 6 characters';
        }
        return null;
      },
    );
  }

  Future<void> _sendEmailToAPI() async {
    final email = _emailController.text;

    // Construct the API request body
    final Map<String, dynamic> data = {"email": email};
    try {
      String url = '/api/users/forgot-password/';
      final headers = {
        'Content-Type': 'application/json',
        'User-Agent':
            'Mozilla/5.0 (Linux; Android 11; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36',
      };
      final response = await ApiService.postJsonWithHeaders(url, data, headers);
      final responseData = json.decode(response!.data);
      if (response.statusCode == 200) {
        setState(() {
          _isloading = false;
          _isPasswordFormVisible = true;
          _isemailFormVisible = false;
          apiUrl = '/api/users/reset-password/';
        });
      } else {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: Text("Info"),
            content: Text(
              "${responseData['detail']}",
              style: WidgetSupport.TextFillColorlight(),
            ),
          ),
        );
        setState(() {
          _isloading = false;
        });
      }
    } catch (error) {
      // Handle network or other errors
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred. Please try again later.')),
      );
    }
  }

  Future<void> _submitNewPassword() async {
    final new_password = _passwordController.text;
    final confirm_password = _confirmpasswordController.text;

    try {
      final response = await ApiService.post(
        "$apiUrl",
        {
          'email': _emailController.text,
          'code': _emailcode.text,
          'new_password': new_password,
          'confirm_password': confirm_password,
        },
      );

      if (response != null) {
        final data = response.data;

        if (response.statusCode == 200) {
          setState(() {
            _isloading = false;
          });
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text("Success"),
              content: Text(data['detail'] ?? 'Password changed successfully!'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => SplashScreen()),
                    );
                  },
                  child: Text("OK"),
                ),
              ],
            ),
          );
        } else {
          setState(() {
            _isloading = false;
          });
          String errorMessage = data['detail'];

          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text("Error"),
              content: Text(errorMessage),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text("OK"),
                ),
              ],
            ),
          );
        }
      } else {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text("Network Error"),
            content: Text("Failed to connect to server."),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text("OK"),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      print("Exception: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Unexpected error occurred")),
      );
    }
  }
}
