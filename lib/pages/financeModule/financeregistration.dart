import 'package:flutter/material.dart';
import 'package:unosfa/pages/generalscreens/entrypage.dart';
import 'package:unosfa/pages/otpscreens/registration_otp.dart';
import 'package:unosfa/widgetSupport/widgetstyle.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter/services.dart';

class Financeregistration extends StatefulWidget {
  final String loginWith;
  const Financeregistration({super.key, required this.loginWith});

  @override
  State<Financeregistration> createState() => _FinanceregistrationState();
}

class _FinanceregistrationState extends State<Financeregistration> {
  final _formKey = GlobalKey<FormState>();
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _emailId = TextEditingController();
  final _externalId = TextEditingController();
  final _office = TextEditingController();
  final _staff = TextEditingController();
  final _phoneNumber = TextEditingController();

  String? _selectedGId;
  final Map<String, String> _gIdOptions = {
    'passport': 'Passport',
    'national_id': 'Philippine National ID (PhilSys ID)',
    'drivers_license': 'Driver\'s License',
    'barangay_id': 'Barangay ID',
    'voter_id': 'Voter\'s ID',
    'school_id': 'School ID',
    'senior_citizen_id': 'Senior Citizen ID',
    'pwd_id': 'Persons with Disability (PWD) ID',
    'postal_id': 'Postal ID',
    'government_id': 'Other Government Issued ID'
  };

  String _getIdHintText() {
    switch (_selectedGId) {
      case 'passport':
        return 'Enter your Passport Number';
      case 'national_id':
        return 'Enter your PhilSys ID';
      case 'drivers_license':
        return 'Enter your Driver’s License Number';
      case 'barangay_id':
        return 'Enter your Barangay ID';
      case 'voter_id':
        return 'Enter your Voter\'s ID';
      case 'school_id':
        return 'Enter your School ID';
      case 'senior_citizen_id':
        return 'Enter your Senior Citizen ID';
      case 'pwd_id':
        return 'Enter your (PWD) ID';
      case 'postal_id':
        return 'Enter your Postal ID';
      case 'government_id':
        return 'Enter your Other Government Issued ID';
      default:
        return 'Enter ID Number';
    }
  }

  @override
  Widget build(BuildContext context) {
    // ignore: deprecated_member_use
    return WillPopScope(
      onWillPop: () async {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const EntryPage(),
          ),
        );
        return false; // Prevents default pop behavior
      },
      child: GestureDetector(
        child: Scaffold(
          resizeToAvoidBottomInset: false,
          body: Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                  image: AssetImage("images/AppBg2.PNG"), fit: BoxFit.fill),
            ),
            child: Column(
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 10, horizontal: 50),
                  child: Image(
                    image: const AssetImage(
                      "images/logo.PNG",
                    ),
                    width: MediaQuery.of(context).size.width * 0.7,
                    height: MediaQuery.of(context).size.height * 0.2,
                  ),
                ),
                Flexible(
                  child: SingleChildScrollView(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 30, vertical: 0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildTextField(
                              _firstName,
                              "First Name",
                              'Please Enter Your Name',
                              'name',
                              icon: FontAwesomeIcons.solidCircleUser,
                              isAlphabetic: true,
                            ),
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.04,
                            ),
                            _buildTextField(
                              _lastName,
                              "Last Name",
                              'Please Enter Your Last Name',
                              'lname',
                              icon: FontAwesomeIcons.solidCircleUser,
                              isAlphabetic: true,
                            ),
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.03,
                            ),
                            _buildTextField(
                              _emailId,
                              "Email Id",
                              'Please Enter Your Email',
                              'email',
                              isEmail: true,
                              icon: FontAwesomeIcons.envelope,
                            ),
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.04,
                            ),
                            _buildDropdownField(),
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.04,
                            ),
                            _buildTextField(
                              _externalId,
                              _getIdHintText(),
                              '',
                              '',
                              icon: FontAwesomeIcons.idCard,
                              obscureText: false,
                            ),
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.04,
                            ),
                            _buildTextField(
                              _office,
                              "Office",
                              'Please Enter Office ',
                              'office',
                              icon: FontAwesomeIcons.locationDot,
                            ),
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.04,
                            ),
                            _buildTextField(
                              _staff,
                              "Staff",
                              'Please Enter Staff',
                              'staff',
                              icon: FontAwesomeIcons.city,
                            ),
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.04,
                            ),
                            _buildTextField(
                              _phoneNumber,
                              "Phone Number",
                              'Please Enter Your Phone Number',
                              'phone',
                              isPhoneNumber: true,
                              icon: FontAwesomeIcons.phoneVolume,
                            ),
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.02,
                            ),
                            Container(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  ElevatedButton(
                                    onPressed: () {
                                      if (_formKey.currentState!.validate()) {
                                        registerUser();
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      shadowColor: Colors.transparent,
                                      padding: EdgeInsets.symmetric(
                                        horizontal:
                                            MediaQuery.of(context).size.width *
                                                0.1,
                                        vertical:
                                            MediaQuery.of(context).size.height *
                                                0.01,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(8.0),
                                      ),
                                    ),
                                    child: Text(
                                      "REGISTER",
                                      style:
                                          WidgetSupport.LoginButtonTextColor(),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 180),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
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
    FaIconData icon = FontAwesomeIcons.solidCircleUser,
    bool obscureText = false,
    bool isEmail = false,
    bool isPhoneNumber = false,
    bool isAlphabetic = false, // Add a parameter to validate alphabetic input
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: isPhoneNumber
          ? TextInputType.phone
          : isEmail
              ? TextInputType.emailAddress
              : TextInputType.text,
      inputFormatters: isAlphabetic
          ? <TextInputFormatter>[
              FilteringTextInputFormatter.allow(
                  RegExp(r'^[a-zA-Z\s]+$')), // Allow only alphabets and spaces
            ]
          : null,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return validationMessage; // Default validation message for empty fields
        }

        if (isAlphabetic) {
          if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value)) {
            return 'Only alphabets are allowed';
          }
        }

        if (isEmail) {
          // Basic email validation regex
          final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
          if (!emailRegex.hasMatch(value)) {
            if (!value.contains('@')) {
              return 'Email must contain "@"';
            }
            if (!value.contains('.')) {
              return 'Email must contain a domain (e.g., .com)';
            }
            return 'Please enter a valid email address';
          }
        }

        if (isPhoneNumber) {
          if (value.length != 12) {
            return 'Phone number must be 12 digits';
          }
          if (!value.startsWith('63')) {
            return 'Phone number must start with "63"';
          }
          if (!RegExp(r'^\d+$').hasMatch(value)) {
            return 'Phone number must contain only digits';
          }
        }

        return null; // Return null if all validations pass
      },
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: WidgetSupport.inputLabel(),
        suffixIcon: Padding(
          padding: const EdgeInsets.all(0),
          child: FaIcon(
            icon,
            color: Colors.purple,
            size: 15,
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownField() {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        hintText: "Select a valid ID",
        hintStyle: WidgetSupport.inputLabel(),
      ),
      value: _selectedGId,
      items: _gIdOptions.entries.map((entry) {
        return DropdownMenuItem<String>(
          value: entry.key,
          child: Text(entry.value),
        );
      }).toList(),
      onChanged: (String? newValue) {
        setState(() {
          _selectedGId = newValue;
        });
      },
      validator: (value) {
        if (value == null) {
          return 'Please select an ID';
        }
        return null;
      },
    );
  }

  Future<void> registerUser() async {
    // Check if the form is valid
    if (_formKey.currentState!.validate()) {
      String firstName = _firstName.text.trim();
      String lastName = _lastName.text.trim();
      String emailId = _emailId.text.trim();
      String office = _office.text.trim();
      String phoneNumber = _phoneNumber.text.trim();
      String kyc_id_number = _externalId.text.trim();
      String kyc_id_type = _selectedGId!;
      // Show a success dialog without sending data to the API
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => RegistrationOtpPage(
            loginWith: 'Sal',
            firstName: firstName,
            lastName: lastName,
            emailId: emailId,
            offic: office,
            phoneNumber: phoneNumber,
            kyc_id_type: kyc_id_type,
            kyc_id_number: kyc_id_number,
            referral_code: '',
          ),
        ),
      );
    } else {
      // Show a snackbar or other UI indication if validation fails
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Form validation failed"),
        ),
      );
    }
  }
}
