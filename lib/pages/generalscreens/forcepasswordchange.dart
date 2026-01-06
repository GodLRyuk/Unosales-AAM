import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:unosfa/pages/otpscreens/changepasswordotp.dart';
import 'package:unosfa/widgetSupport/widgetstyle.dart';

class ForcePasswordChange extends StatefulWidget {
  final String accesToken; // Lead ID passed from the previous screen
final  String phone_number;
  const ForcePasswordChange({super.key, required this.accesToken, required this.phone_number});

  @override
  State<ForcePasswordChange> createState() => _ForcePasswordChangeState();
}

class _ForcePasswordChangeState extends State<ForcePasswordChange> {
  final _formKey = GlobalKey<FormState>();
  final _newpasswordController = TextEditingController();
  final _oldpasswordController = TextEditingController();
  final _confirmpasswordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isoldPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Center(
          child: Text("Change Password", style: WidgetSupport.titleText()),
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
                        child: Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              const SizedBox(height: 20),
                              _buildoldPasswordTextField(
                                _oldpasswordController,
                                "Old Password",
                                icon: FontAwesomeIcons.lock,
                                obscureText: !_isoldPasswordVisible,
                              ),
                              const SizedBox(height: 20),
                              _buildPasswordTextField(
                                _newpasswordController,
                                "Password",
                                icon: FontAwesomeIcons.lock,
                                obscureText: !_isPasswordVisible,
                              ),
                              const SizedBox(height: 20),
                              _buildConfirmPasswordTextField(
                                _confirmpasswordController,
                                "Confirm Password",
                                icon: FontAwesomeIcons.lock,
                                obscureText: !_isConfirmPasswordVisible,
                                isConfirmPassword: true,
                              ),
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.02,
                              ),
                              GestureDetector(
                                onTap: () {
                                  if (_formKey.currentState!.validate()) {
                                    changePassword();
                                  }
                                },
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    vertical:
                                        MediaQuery.of(context).size.height *
                                            0.01,
                                  ),
                                  child: Center(
                                    child: Text(
                                      "SUBMIT",
                                      style:
                                          WidgetSupport.LoginButtonTextColor(),
                                    ),
                                  ),
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
              color: Colors.transparent,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildoldPasswordTextField(
    TextEditingController controller,
    String hintText, {
    IconData icon = FontAwesomeIcons.solidCircleUser,
    bool obscureText = false,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      enableInteractiveSelection: true,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: WidgetSupport.inputLabel(),
        suffixIcon: Padding(
          padding: const EdgeInsets.all(0),
          child: IconButton(
            icon: Icon(
              _isoldPasswordVisible
                  ? FontAwesomeIcons.eyeSlash
                  : FontAwesomeIcons.eye,
              color: Colors.purple,
              size: 20,
            ),
            onPressed: () {
              setState(() {
                _isoldPasswordVisible = !_isoldPasswordVisible;
              });
            },
          ),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Enter $hintText';
        }
        return null;
      },
    );
  }

  Widget _buildPasswordTextField(
    TextEditingController controller,
    String hintText, {
    IconData icon = FontAwesomeIcons.solidCircleUser,
    bool obscureText = false,
    bool isConfirmPassword = false,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      enableInteractiveSelection: true,
      maxLength: 10, // Restrict to 10 characters
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: WidgetSupport.inputLabel(),
        counterText: '', // Hides the counter below the input field
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
          return 'Enter $hintText';
        }
        if (value.length < 8) {
          return 'Password must be at least 8 characters long.';
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
        if (isConfirmPassword && value != _newpasswordController.text) {
          return 'Passwords do not match';
        }
        return null;
      },
    );
  }

  Widget _buildConfirmPasswordTextField(
    TextEditingController controller,
    String hintText, {
    IconData icon = FontAwesomeIcons.solidCircleUser,
    bool obscureText = false,
    bool isConfirmPassword = false,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      enableInteractiveSelection: true,
      maxLength: 10,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: WidgetSupport.inputLabel(),
        suffixIcon: Padding(
          padding: const EdgeInsets.all(0),
          child: IconButton(
            icon: Icon(
              _isConfirmPasswordVisible
                  ? FontAwesomeIcons.eyeSlash
                  : FontAwesomeIcons.eye,
              color: Colors.purple,
              size: 20,
            ),
            onPressed: () {
              setState(() {
                _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
              });
            },
          ),
        ),
        counterText: '',
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Enter $hintText';
        }
        if (isConfirmPassword && value != _newpasswordController.text) {
          return 'Passwords do not match';
        }
        return null;
      },
    );
  }

  Future<void> changePassword() async {
    setState(() {
      _isLoading = true;
    });
    try {
      if (_formKey.currentState!.validate()) {
        // Simulate network delay for demonstration
        await Future.delayed(const Duration(seconds: 2));

        // Navigate to OTP page
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => Changepasswordotp(
              oldpassword: _oldpasswordController.text,
              newpassword: _newpasswordController.text,
              confirmpassword: _confirmpasswordController.text,
              token: widget.accesToken,
              phone_number: widget.phone_number
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Please fill in all fields."),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
