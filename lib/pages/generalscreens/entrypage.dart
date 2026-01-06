import 'package:flutter/material.dart';
import 'package:unosfa/pages/generalscreens/customNavigation.dart';
import 'package:unosfa/pages/generalscreens/login.dart';
import 'package:unosfa/pages/generalscreens/registration.dart';
import 'package:unosfa/widgetSupport/widgetstyle.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EntryPage extends StatefulWidget {
  const EntryPage({super.key});

  @override
  State<EntryPage> createState() => _EntryPageState();
}

class _EntryPageState extends State<EntryPage> {
  String? _selectedOption;
  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    if (isLoggedIn) {
      Navigator.pushReplacement(
        // ignore: use_build_context_synchronously
        context,
        MaterialPageRoute(
          builder: (context) => NavigationPage(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.only(top: 150, left: 15, right: 15),
            child: Image(
              image: AssetImage("images/logo.PNG"),
              width: MediaQuery.of(context).size.width * 0.70,
            ),
          ),
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.10,
          ),
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
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.07,
          ),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal:
                  MediaQuery.of(context).orientation == Orientation.portrait
                      ? (MediaQuery.of(context).size.width < 600
                          ? MediaQuery.of(context).size.width *
                              0.15 // For phones in portrait
                          : MediaQuery.of(context).size.width *
                              0.17) // For tablets in portrait
                      : (MediaQuery.of(context).size.width < 600
                          ? MediaQuery.of(context).size.width *
                              0.2 // For phones in landscape
                          : MediaQuery.of(context).size.width *
                              0.17), // For tablets in landscape
            ),
            child: DropdownButtonFormField<String>(
              value: _selectedOption,
              items: [
                DropdownMenuItem(
                  value: "FSA",
                  child: Text(
                    "Field Sales Agent",
                    style: WidgetSupport.dropDownText(),
                  ),
                ),
                DropdownMenuItem(
                  value: "FR",
                  child: Text(
                    "Field Referral",
                    style: WidgetSupport.dropDownText(),
                  ),
                ),
                DropdownMenuItem(
                  value: "Supervisor",
                  child: Text(
                    "Supervisor",
                    style: WidgetSupport.dropDownText(),
                  ),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedOption = value;
                });
              },
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              hint: const Text("Select Agent Type"),
            ),
          ),
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.03,
          ),
          Container(
            width: MediaQuery.of(context).size.width * 0.7,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () {
                    if (_selectedOption != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              LoginPage(loginWith: _selectedOption!),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Please select an option"),
                        ),
                      );
                    }
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: MediaQuery.of(context).orientation ==
                              Orientation.portrait
                          ? (MediaQuery.of(context).size.width < 600
                              ? MediaQuery.of(context).size.width *
                                  0.00 // For phones in portrait
                              : MediaQuery.of(context).size.width *
                                  0.02) // For tablets in portrait
                          : (MediaQuery.of(context).size.width < 600
                              ? MediaQuery.of(context).size.width *
                                  0.02 // For phones in landscape
                              : MediaQuery.of(context).size.width *
                                  0.02), // For tablets in landscape
                    ),
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(0),
                    ),
                    child: Text(
                      "LOGIN",
                      style: WidgetSupport.loginWithButtonText(),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    if (_selectedOption != null) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => Registration(
                            loginWith: _selectedOption!,
                          ),
                        ),
                      );
                    } 
                    else if (_selectedOption == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Please Select An Option"),
                        ),
                      );
                    }
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: MediaQuery.of(context).orientation ==
                              Orientation.portrait
                          ? (MediaQuery.of(context).size.width < 600
                              ? MediaQuery.of(context).size.width *
                                  0.01 // For phones in portrait
                              : MediaQuery.of(context).size.width *
                                  0.03) // For tablets in portrait
                          : (MediaQuery.of(context).size.width < 600
                              ? MediaQuery.of(context).size.width *
                                  0.03 // For phones in landscape
                              : MediaQuery.of(context).size.width *
                                  0.02), // For tablets in landscape
                    ),
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(0),
                    ),
                    child: Align(
                      alignment: Alignment.topRight,
                      child: Text(
                        "REGISTER NOW",
                        style: WidgetSupport.regsterNow(),
                      ),
                    ),
                  ),
                )
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal:
                  MediaQuery.of(context).orientation == Orientation.portrait
                      ? (MediaQuery.of(context).size.width < 600
                          ? MediaQuery.of(context).size.width *
                              0.16 // For phones in portrait
                          : MediaQuery.of(context).size.width *
                              0.17) // For tablets in portrait
                      : (MediaQuery.of(context).size.width < 600
                          ? MediaQuery.of(context).size.width *
                              0.03 // For phones in landscape
                          : MediaQuery.of(context).size.width *
                              0.17), // For tablets in landscape
            ),
            child: Align(
              alignment: Alignment.topRight,
              child: Text(
                "Dont Have An Account?",
                style: WidgetSupport.dontHaveAccount(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
