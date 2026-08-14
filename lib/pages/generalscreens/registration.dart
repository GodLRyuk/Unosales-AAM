import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:unosfa/pages/generalscreens/entrypage.dart';
import 'package:unosfa/pages/otpscreens/registration_otp.dart';
import 'package:unosfa/widgetSupport/widgetstyle.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:path/path.dart' as path;

class Registration extends StatefulWidget {
  final String loginWith;
  const Registration({super.key, required this.loginWith});

  @override
  State<Registration> createState() => _RegistrationState();
}

class _RegistrationState extends State<Registration> {
  final _formKey = GlobalKey<FormState>();
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _emailId = TextEditingController();
  final _externalId = TextEditingController();
  final _office = TextEditingController();
  final _phoneNumber = TextEditingController();
  final _referralCode = TextEditingController();
  bool _isLoading = false;
  final _imageController = TextEditingController();

  String? _selectedGId;
  final Map<String, String> _gIdOptions = {
    'passport': 'Philippines Passport',
    'national_id': 'Philippine National ID (PhilSys ID)',
    'drivers_license': 'Driver\'s License',
    'umid': 'Unified Multi-Purpose ID (UMID)',
    'sss_id': 'Social Security System (SSS) ID',
    'prc_id': 'Professional Regulation Commission (PRC) ID'
  };

  String _getIdHintText() {
    switch (_selectedGId) {
      case 'passport':
        return 'Enter your Philippines Passport Number';
      case 'national_id':
        return 'Enter your PhilSys ID';
      case 'drivers_license':
        return 'Enter your Driver’s License Number';
      case 'umid':
        return 'Enter your Unified Multi-Purpose ID';
      case 'sss_id':
        return 'Enter your Social Security System (SSS) ID';
      case 'prc_id':
        return 'Enter your Professional Regulation Commission (PRC) ID';
      default:
        return 'Enter ID Number';
    }
  }

  String _getIdUplpadHintText() {
    switch (_selectedGId) {
      case 'passport':
        return 'Upload your Philippines Passport Number';
      case 'national_id':
        return 'Upload your PhilSys ID';
      case 'drivers_license':
        return 'Upload your Driver’s License Number';
      case 'umid':
        return 'Upload your Unified Multi-Purpose ID';
      case 'sss_id':
        return 'Upload your Social Security System (SSS) ID';
      case 'prc_id':
        return 'Upload your Professional Regulation Commission (PRC) ID';
      default:
        return 'Upload ID Number';
    }
  }

  String _getIdUplpadHintTFileext() {
    switch (_selectedGId) {
      case 'passport':
        return 'Upload your Philippines Passport';
      case 'national_id':
        return 'Upload your PhilSys ID';
      case 'drivers_license':
        return 'Upload your Driver’s License';
      case 'umid':
        return 'Upload your Unified Multi-Purpose ID';
      case 'sss_id':
        return 'Upload your Social Security System (SSS) ID';
      case 'prc_id':
        return 'Upload your Professional Regulation Commission (PRC) ID';
      default:
        return 'Upload ID';
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
        return false;
      },
      child: GestureDetector(
        child: Scaffold(
          resizeToAvoidBottomInset: false,
          body: Stack(
            children: [
              Container(
                decoration: const BoxDecoration(
                  image: DecorationImage(
                      image: AssetImage("images/AppBg2.PNG"), fit: BoxFit.fill),
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 10, horizontal: 50),
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
                              horizontal: 30, vertical: 10),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildTextField(
                                  _firstName,
                                  "First Name",
                                  "Please Enter Your Name",
                                  "name",
                                  isAlphabetic: false,
                                  allowSpaces: true,
                                  isRequired: true,
                                ),
                                SizedBox(
                                  height:
                                      MediaQuery.of(context).size.height * 0.03,
                                ),
                                _buildTextField(
                                  _lastName,
                                  "Last Name",
                                  'Please Enter Your Last Name',
                                  'lname',
                                  icon: FontAwesomeIcons.solidCircleUser,
                                  isAlphabetic: true,
                                  allowSpaces: true,
                                  isRequired: true,
                                ),
                                SizedBox(
                                  height:
                                      MediaQuery.of(context).size.height * 0.03,
                                ),
                                _buildTextField(
                                  _emailId,
                                  "Email Id",
                                  'Please Enter Your Email',
                                  'email',
                                  isEmail: true,
                                  icon: FontAwesomeIcons.envelope,
                                  allowSpaces: false,
                                  isRequired: true,
                                ),
                                SizedBox(
                                  height:
                                      MediaQuery.of(context).size.height * 0.03,
                                ),
                                _buildDropdownField(),
                                SizedBox(
                                  height:
                                      MediaQuery.of(context).size.height * 0.03,
                                ),
                                _buildKydIdTextField(
                                  _externalId,
                                  _getIdHintText(),
                                  _getIdHintText(),
                                  'external_id',
                                  icon: FontAwesomeIcons.idCard,
                                  isRequired: _selectedGId !=
                                      null, // 👈 Dynamic requirement
                                  isNumeric: false,
                                ),
                                SizedBox(
                                  height:
                                      MediaQuery.of(context).size.height * 0.03,
                                ),
                                _buildImageUploadField(
                                  context,
                                  _imageController,
                                  _getIdUplpadHintTFileext(),
                                  _getIdUplpadHintText(),
                                  _selectedGId !=
                                      null, // 👈 Dynamic requirement
                                  Icons.upload_file,
                                ),
                                SizedBox(
                                  height:
                                      MediaQuery.of(context).size.height * 0.03,
                                ),
                                _buildTextField(
                                  _office,
                                  "Company Name",
                                  'Please Enter Company Name',
                                  'office',
                                  icon: FontAwesomeIcons.locationDot,
                                  allowSpaces: true,
                                  isRequired: true,
                                ),
                                SizedBox(
                                  height:
                                      MediaQuery.of(context).size.height * 0.03,
                                ),
                                Stack(
                                  children: [
                                    _buildMobileTextField(
                                      controller: _phoneNumber,
                                      isPhoneNumber: true,
                                      isNumeric: true,
                                    ),
                                  ],
                                ),
                                SizedBox(
                                  height:
                                      MediaQuery.of(context).size.height * 0.03,
                                ),
                                _buildReferalTextField(
                                  _referralCode,
                                  "Referral Code (Optional)",
                                  '',
                                  'referralCode',
                                  isReferralCode:
                                      true, // Set referral code flag
                                  icon: FontAwesomeIcons.idCard,
                                ),
                                SizedBox(
                                  height:
                                      MediaQuery.of(context).size.height * 0.02,
                                ),
                                Container(
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      ElevatedButton(
                                        onPressed: () {
                                          setState(() {});
                                          // if (_isDropdownValid /* && other validations */) {
                                          if (_formKey.currentState!
                                              .validate()) {
                                            registerUser();
                                          }
                                          // }
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.transparent,
                                          shadowColor: Colors.transparent,
                                          padding: EdgeInsets.symmetric(
                                            horizontal: MediaQuery.of(context)
                                                        .orientation ==
                                                    Orientation.portrait
                                                ? (MediaQuery.of(context)
                                                            .size
                                                            .width <
                                                        600
                                                    ? MediaQuery.of(context)
                                                            .size
                                                            .width *
                                                        0.00 // For phones in portrait
                                                    : MediaQuery.of(context)
                                                            .size
                                                            .width *
                                                        0.03) // For tablets in portrait
                                                : (MediaQuery.of(context)
                                                            .size
                                                            .width <
                                                        600
                                                    ? MediaQuery.of(context)
                                                            .size
                                                            .width *
                                                        0.03 // For phones in landscape
                                                    : MediaQuery.of(context)
                                                            .size
                                                            .width *
                                                        0.02), // For tablets in landscape
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(8.0),
                                          ),
                                        ),
                                        child: Text(
                                          "REGISTER",
                                          style: WidgetSupport
                                              .LoginButtonTextColor(),
                                        ),
                                      ),
                                      ElevatedButton(
                                        onPressed: () {
                                          Navigator.pushReplacement(
                                              context,
                                              MaterialPageRoute(
                                                  builder: (context) =>
                                                      EntryPage()));
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.transparent,
                                          shadowColor: Colors.transparent,
                                          padding: EdgeInsets.symmetric(
                                            horizontal: MediaQuery.of(context)
                                                        .orientation ==
                                                    Orientation.portrait
                                                ? (MediaQuery.of(context)
                                                            .size
                                                            .width <
                                                        600
                                                    ? MediaQuery.of(context)
                                                            .size
                                                            .width *
                                                        0.00 // For phones in portrait
                                                    : MediaQuery.of(context)
                                                            .size
                                                            .width *
                                                        0.02) // For tablets in portrait
                                                : (MediaQuery.of(context)
                                                            .size
                                                            .width <
                                                        600
                                                    ? MediaQuery.of(context)
                                                            .size
                                                            .width *
                                                        0.02 // For phones in landscape
                                                    : MediaQuery.of(context)
                                                            .size
                                                            .width *
                                                        0.02), // For tablets in landscape
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(8.0),
                                          ),
                                        ),
                                        child: Text(
                                          "BACK",
                                          style: WidgetSupport
                                              .LoginButtonTextColor(),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(
                                    height: MediaQuery.of(context).size.height *
                                        0.30),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
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
    bool isAlphabetic = false,
    bool isNumeric = false,
    bool allowSpaces = false,
    bool isReferralCode = false,
    bool isRequired = false, // NEW
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
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
          child: FaIcon(
            icon,
            color: Colors.purple,
            size: 15,
          ),
        ),
      ),
    );
  }

  Widget _buildReferalTextField(
    TextEditingController controller,
    String hintText,
    String validationMessage,
    String validationKey, {
    FaIconData icon = FontAwesomeIcons.solidCircleUser,
    bool obscureText = false,
    bool isEmail = false,
    bool isPhoneNumber = false,
    bool isAlphabetic = false,
    bool isNumeric = false, // NEW
    bool allowSpaces = false,
    bool isReferralCode = false,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: isPhoneNumber || isNumeric
          ? TextInputType.number
          : isEmail
              ? TextInputType.emailAddress
              : TextInputType.text,
      inputFormatters: [
        if (isPhoneNumber || isNumeric) ...[
          FilteringTextInputFormatter.digitsOnly,
          if (isPhoneNumber)
            LengthLimitingTextInputFormatter(12), // Only limit for phone
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
        if (value == null || value.isEmpty) {
          return isReferralCode ? null : validationMessage;
        }

        if (isAlphabetic) {
          if (!RegExp(allowSpaces ? r'^[a-zA-Z\s]+$' : r'^[a-zA-Z]+$')
              .hasMatch(value)) {
            return allowSpaces
                ? 'Only alphabets and spaces are allowed'
                : 'Only alphabets are allowed, no spaces';
          }
        }

        if (isEmail) {
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

        if (isNumeric) {
          if (!RegExp(r'^\d+$').hasMatch(value)) {
            return 'Only numbers are allowed';
          }
        }

        if (isReferralCode && !RegExp(r'^[a-zA-Z0-9]+$').hasMatch(value)) {
          return 'Referral code can only contain letters and numbers';
        }

        return null;
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

  Widget _buildKydIdTextField(
    TextEditingController controller,
    String hintText,
    String validationMessage,
    String validationKey, {
    FaIconData icon = FontAwesomeIcons.solidCircleUser,
    bool obscureText = false,
    bool isNumeric = false,
    bool isRequired = true,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
      validator: (value) {
        if (isRequired && (value == null || value.trim().isEmpty)) {
          return validationMessage; // Custom message like "Please Enter External ID"
        }
        if (value != null && value.isNotEmpty) {
          if (value.length < 6) {
            return 'ID must be at least 6 characters long';
          }
          // if (!RegExp(r'^(?=.*[a-zA-Z0-9])[a-zA-Z0-9\-]+$').hasMatch(value)) {
          //   return 'Only letters, numbers, and dashes (-) are allowed';
          // }
        }
        return null;
      },
      decoration: InputDecoration(
        label: RichText(
          text: TextSpan(
            text: hintText,
            style: WidgetSupport.inputLabel(),
            children: isRequired
                ? const [
                    TextSpan(
                      text: ' *',
                      style: TextStyle(color: Colors.red, fontSize: 15),
                    ),
                  ]
                : [],
          ),
        ),
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
    return DropdownSearch<String>(
      popupProps: PopupProps.menu(
        showSearchBox: false,
        fit: FlexFit.loose,
      ),
      items: _gIdOptions.values.toList(),
      dropdownDecoratorProps: DropDownDecoratorProps(
        dropdownSearchDecoration: InputDecoration(
          labelText: "Select a KYC ID Type",
          hintStyle: WidgetSupport.inputLabel(),
          //errorText: _isDropdownValid ? null : 'Please select a KYC ID',
        ),
      ),
      selectedItem: _selectedGId != null ? _gIdOptions[_selectedGId] : null,
      onChanged: (String? newValue) {
        setState(() {
          _selectedGId = _gIdOptions.entries
              .firstWhere((entry) => entry.value == newValue)
              .key;
// Reset error when selection is made
        });
      },
      dropdownBuilder: (BuildContext context, String? selectedItem) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              selectedItem ?? "Select KYC ID",
              style: WidgetSupport.inputLabel(),
            ),
            const SizedBox(width: 2),
          ],
        );
      },
    );
  }

  File? _image;

  Widget _buildImageUploadField(
    BuildContext context,
    TextEditingController controller,
    String hintText,
    String validationMessage,
    bool isRequired,
    IconData icon,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: controller,
          readOnly: true,
          decoration: InputDecoration(
            label: RichText(
              text: TextSpan(
                text: hintText,
                style: const TextStyle(fontSize: 16, color: Colors.black),
                children: isRequired
                    ? const [
                        TextSpan(
                          text: ' *',
                          style: TextStyle(color: Colors.red, fontSize: 15),
                        ),
                      ]
                    : [],
              ),
            ),
            suffixIcon: IconButton(
              icon: Icon(icon, color: Colors.purple, size: 20),
              onPressed: () async {
                showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: const Text("Select Image Source"),
                      actions: <Widget>[
                        TextButton(
                          onPressed: () async {
                            final ImagePicker picker = ImagePicker();
                            final XFile? image = await picker.pickImage(
                                source: ImageSource.gallery);
                            if (image != null) {
                              // Copy to internal app storage
                              final appDir =
                                  await getApplicationDocumentsDirectory();
                              final fileName = path.basename(image.path);
                              final secureImage = await File(image.path)
                                  .copy('${appDir.path}/$fileName');

                              _image = secureImage;
                              controller.text =
                                  secureImage.path; // ✅ Secure path

                              final tempFile = File(image.path);
                              if (await tempFile.exists()) {
                                await tempFile.delete(); // ✅ Secure cleanup
                              }
                            }
                            Navigator.of(context).pop();
                          },
                          child: const Text("Gallery"),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
            enabledBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.black45),
            ),
          ),
          validator: (_) {
            if (_image == null && isRequired) {
              return validationMessage;
            }
            return null;
          },
        ),
        if (_image != null)
          Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: ClipOval(
              child: Image.file(
                _image!,
                height: 110,
                width: 110,
                fit: BoxFit.cover,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildMobileTextField({
    required TextEditingController controller,
    bool isRequired = true,
    FaIconData icon = FontAwesomeIcons.solidCircleUser,
    bool isPhoneNumber = false,
    bool isNumeric = false,
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
              suffixIcon: FaIcon(icon, color: Colors.purple, size: 15),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> registerUser() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      try {
        String firstName = _firstName.text.trim();
        String lastName = _lastName.text.trim();
        String emailId = _emailId.text.trim();
        String office = _office.text.trim();
        String phoneNumber = _phoneNumber.text.trim();
        String selectedGId = _selectedGId ?? '';
        String referralCode = _referralCode.text.trim();
        String externalId = _externalId.text.trim();
        // Perform registration logic here, e.g., API call
        await Future.delayed(const Duration(seconds: 2)); // Simulating API call

        // On success, navigate to OTP page and pass the image
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => RegistrationOtpPage(
              loginWith: widget.loginWith,
              firstName: firstName,
              lastName: lastName,
              emailId: emailId,
              offic: office,
              phoneNumber: phoneNumber,
              kyc_id_type: selectedGId,
              kyc_id_number: externalId,
              kycDocument: _image,
              referral_code: referralCode,
            ),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Registration failed: $e')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
