import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:circle_progress_bar/circle_progress_bar.dart';
import 'package:unosfa/widgetSupport/widgetstyle.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
 
  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      backgroundColor: Colors.grey[50]!,
      body: SingleChildScrollView(
        child: Align(
          alignment: Alignment.topCenter,
          child: Column(
            children: [
              const SizedBox(height: 50),
              Image.asset(
                "images/logo.jpg",
                width: 200,
                height: 70,
              ),
              const Text(
                "Sylvester Rajesh Mondal",
                style:
                    TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const Text(
                "Id: PIH-10000",
                style:
                    TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              //Start oF My Activities

              Stack(
                children: [
                  Container(
                    width: MediaQuery.of(context).size.width * 0.93,
                    //height: MediaQuery.of(context).size.height * 0.16,
                    decoration: const BoxDecoration(
                        gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                          Color(0xFFb600da),
                          Color(0xFF6c0481),
                        ])),
                    child: Padding(
                      padding: const EdgeInsets.only(top: 25, bottom: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                height: 80.0,
                                child: CircleProgressBar(
                                  foregroundColor: Colors.white,
                                  backgroundColor: Colors.black12,
                                  value: 0.5, // Example progress value
                                  child: Center(
                                    child: Text(
                                      '50%', // Example percentage text
                                      style:
                                          WidgetSupport.progressBarInnerText(),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(
                                height: 10,
                              ),
                              Text(
                                "Planned Activities",
                                style: WidgetSupport.normalText(),
                              )
                            ],
                          ),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                height: 80.0,
                                child: CircleProgressBar(
                                  foregroundColor: Colors.yellow,
                                  backgroundColor: Colors.black12,
                                  value: 0.7, // Example progress value
                                  child: Center(
                                    child: Text(
                                      '70%', // Example percentage text
                                      style:
                                          WidgetSupport.progressBarInnerText(),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(
                                height: 10,
                              ),
                              Text(
                                "Pending Activities",
                                style: WidgetSupport.normalText(),
                              ),
                            ],
                          ),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                height: 80.0,
                                child: CircleProgressBar(
                                  foregroundColor: Colors.lightGreen,
                                  backgroundColor: Colors.black12,
                                  value: 0.3, // Example progress value
                                  child: Center(
                                    child: Text(
                                      '30%', // Example percentage text
                                      style:
                                          WidgetSupport.progressBarInnerText(),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(
                                height: 10,
                              ),
                              Text(
                                "Completed Activities",
                                style: WidgetSupport.normalText(),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              //End Of My Activities
              const SizedBox(
                height: 10,
              ),
              //Start Of Small Icon Box
              Padding(
                padding: const EdgeInsets.all(0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Column(
                      children: [
                        SizedBox(
                          child: Container(
                            width: screenWidth * 0.2,
                            height: screenHeight * 0.09,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(5),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey[300]!,
                                  spreadRadius: 2,
                                  blurRadius: 2,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                const Padding(
                                  padding: EdgeInsets.only(top: 10),
                                ),
                                const Icon(
                                  Icons.school,
                                  size: 30,
                                  color: Colors.purple,
                                ),
                                const SizedBox(
                                  height: 5,
                                ),
                                Text(
                                  "Training",
                                  style: WidgetSupport.normalblackText(),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        SizedBox(
                          child: Container(
                            width: screenWidth * 0.2,
                            height: screenHeight * 0.09,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(5),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey[300]!,
                                  spreadRadius: 2,
                                  blurRadius: 2,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                const Padding(
                                  padding: EdgeInsets.only(top: 10),
                                ),
                                const FaIcon(
                                  FontAwesomeIcons.handshake,
                                  size: 30,
                                  color: Colors.orange,
                                ),
                                const SizedBox(
                                  height: 5,
                                ),
                                Text(
                                  "My Leads",
                                  style: WidgetSupport.normalblackText(),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        SizedBox(
                          child: Container(
                            width: screenWidth * 0.2,
                            height: screenHeight * 0.09,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(5),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey[300]!,
                                  spreadRadius: 2,
                                  blurRadius: 2,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                const Padding(
                                  padding: EdgeInsets.only(top: 10),
                                ),
                                const FaIcon(
                                  FontAwesomeIcons.bullhorn,
                                  size: 30,
                                  color: Colors.blue,
                                ),
                                const SizedBox(
                                  height: 5,
                                ),
                                Text(
                                  "Campaigns",
                                  style: WidgetSupport.normalblackText(),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        SizedBox(
                          child: Container(
                            width: screenWidth * 0.2,
                            height: screenHeight * 0.09,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(5),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey[300]!,
                                  spreadRadius: 2,
                                  blurRadius: 2,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                const Padding(
                                  padding: EdgeInsets.only(top: 10),
                                ),
                                const FaIcon(
                                  FontAwesomeIcons.trophy,
                                  size: 30,
                                  color: Colors.green,
                                ),
                                const SizedBox(
                                  height: 5,
                                ),
                                Text(
                                  "Incentives",
                                  style: WidgetSupport.normalblackText(),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Column(
                      children: [
                        SizedBox(
                          child: Container(
                            width: screenWidth * 0.2,
                            height: screenHeight * 0.09,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(5),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey[300]!,
                                  spreadRadius: 2,
                                  blurRadius: 2,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                const Padding(
                                  padding: EdgeInsets.only(top: 10),
                                ),
                                const FaIcon(
                                  FontAwesomeIcons.userCheck,
                                  size: 30,
                                  color: Colors.orangeAccent,
                                ),
                                const SizedBox(
                                  height: 5,
                                ),
                                Text(
                                  "Engagements",
                                  style: WidgetSupport.normalblackText(),
                                  //maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                  //softWrap: true,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        SizedBox(
                          child: Container(
                            width: screenWidth * 0.2,
                            height: screenHeight * 0.09,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(5),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey[300]!,
                                  spreadRadius: 2,
                                  blurRadius: 2,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                const Padding(
                                  padding: EdgeInsets.only(top: 10),
                                ),
                                const FaIcon(
                                  FontAwesomeIcons.bullseye,
                                  size: 30,
                                  color: Colors.red,
                                ),
                                const SizedBox(
                                  height: 5,
                                ),
                                Text(
                                  "Target",
                                  style: WidgetSupport.normalblackText(),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        SizedBox(
                          child: Container(
                            width: screenWidth * 0.2,
                            height: screenHeight * 0.09,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(5),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey[300]!,
                                  spreadRadius: 2,
                                  blurRadius: 2,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                const Padding(
                                  padding: EdgeInsets.only(top: 10),
                                ),
                                const FaIcon(
                                  FontAwesomeIcons
                                      // ignore: deprecated_member_use
                                      .mapMarkerAlt, // Map marker icon
                                  size: 30,
                                  color: Colors.red,
                                ),
                                const SizedBox(
                                  height: 5,
                                ),
                                Text(
                                  "Map",
                                  style: WidgetSupport.normalblackText(),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        SizedBox(
                          child: Container(
                            width: screenWidth * 0.2,
                            height: screenHeight * 0.09,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(5),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey[300]!,
                                  spreadRadius: 2,
                                  blurRadius: 2,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                const Padding(
                                  padding: EdgeInsets.only(top: 10),
                                ),
                                const FaIcon(
                                  // ignore: deprecated_member_use
                                  FontAwesomeIcons.thLarge,
                                  size: 30,
                                  color: Colors.deepPurple,
                                ),
                                const SizedBox(
                                  height: 5,
                                ),
                                Text(
                                  "Others",
                                  style: WidgetSupport.normalblackText(),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              //End Of Small Icon Box
              const SizedBox(
                height: 13,
              ),
              //nudges Block Start
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Column(
                      children: [
                        SizedBox(
                          child: Container(
                            width: MediaQuery.of(context).size.width * 0.10,
                            height: 35,
                            decoration: BoxDecoration(
                              color: Colors.purple,
                              borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(10),
                                  bottomLeft: Radius.circular(10)),
                              boxShadow: [
                                BoxShadow(
                                    color: Colors.grey[300]!,
                                    spreadRadius: 2,
                                    blurRadius: 2,
                                    offset: const Offset(0, 2))
                              ],
                            ),
                            child: const Column(
                              children: [
                                Padding(padding: EdgeInsets.all(4)),
                                FaIcon(
                                  FontAwesomeIcons.handPointRight,
                                  size: 20,
                                  color: Colors.white,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        SizedBox(
                          child: Container(
                            width: MediaQuery.of(context).size.width * 0.35,
                            height: 35,
                            decoration: const BoxDecoration(
                              color: Color.fromARGB(52, 33, 219, 243),
                              borderRadius: BorderRadius.only(
                                topRight: Radius.circular(10),
                                bottomRight: Radius.circular(10),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text("Nudges",
                                      style:
                                          WidgetSupport.verticalBarInnerText()),
                                ),
                                SizedBox(
                                  width:
                                      MediaQuery.of(context).size.width * 0.095,
                                ),
                                Transform.rotate(
                                  angle: 3.14159,
                                  alignment: Alignment.centerRight,
                                  child: const Icon(
                                    Icons.arrow_back_ios_new_outlined,
                                    size: 20,
                                    color: Colors.purple,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(
                      width: 10,
                    ),
                    Column(
                      children: [
                        SizedBox(
                          child: Container(
                            width: MediaQuery.of(context).size.width * 0.10,
                            height: 35,
                            decoration: BoxDecoration(
                              color: Colors.purple,
                              borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(10),
                                  bottomLeft: Radius.circular(10)),
                              boxShadow: [
                                BoxShadow(
                                    color: Colors.grey[300]!,
                                    spreadRadius: 2,
                                    blurRadius: 2,
                                    offset: const Offset(0, 2))
                              ],
                            ),
                            child: const Column(
                              children: [
                                Padding(padding: EdgeInsets.all(4)),
                                FaIcon(
                                  FontAwesomeIcons.handPointRight,
                                  size: 20,
                                  color: Colors.white,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        SizedBox(
                          child: Container(
                            width: MediaQuery.of(context).size.width * 0.35,
                            height: 35,
                            decoration: const BoxDecoration(
                              color: Color.fromARGB(52, 33, 219, 243),
                              borderRadius: BorderRadius.only(
                                topRight: Radius.circular(10),
                                bottomRight: Radius.circular(10),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text("Cheerworthy",
                                      style:
                                          WidgetSupport.verticalBarInnerText()),
                                ),
                                SizedBox(
                                  width:
                                      MediaQuery.of(context).size.width * 0.045,
                                ),
                                Transform.rotate(
                                  angle: 3.14159,
                                  alignment: Alignment.centerRight,
                                  child: const Icon(
                                    Icons.arrow_back_ios_new_outlined,
                                    size: 20,
                                    color: Colors.purple,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(
                height: 5,
              ),
              Container(
                child: _buildTopContainer(),
              ),
              //Nudges Block Ends
              //Perfomance Block start
              const SizedBox(
                height: 25,
              ),
              Container(
                child: _buildMidContainerWithButton(),
              ),
              Container(
                child: _buildBottomContainer(),
              )
              //perfomance Block Ends
            ],
          ),
        ),
      ),
      // bottomNavigationBar: CustomBottomNavigationBar(
      //     currentIndex: currentIndex, // Set current index here
      //     onTap: (index) => _onTap(index, context), // Handle tap
      //   ),
    );
  }

  Widget _buildTopContainer() => Flexible(
        flex: 0,
        child: Padding(
          padding: const EdgeInsets.only(top: 5, left: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Column(
                children: [
                  SizedBox(
                    child: Container(
                      width: MediaQuery.of(context).size.width * 0.10,
                      height: 35,
                      decoration: BoxDecoration(
                        color: Colors.purple,
                        borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(10),
                            bottomLeft: Radius.circular(10)),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.grey[300]!,
                              spreadRadius: 2,
                              blurRadius: 2,
                              offset: const Offset(0, 2))
                        ],
                      ),
                      child: const Column(
                        children: [
                          Padding(padding: EdgeInsets.all(4)),
                          Icon(
                            Icons.calendar_month,
                            size: 20,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              Column(
                children: [
                  SizedBox(
                    child: Container(
                      width: MediaQuery.of(context).size.width * 0.35,
                      height: 35,
                      decoration: const BoxDecoration(
                        color: Color.fromARGB(52, 33, 219, 243),
                        borderRadius: BorderRadius.only(
                          topRight: Radius.circular(10),
                          bottomRight: Radius.circular(10),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text("Calender",
                                style: WidgetSupport.verticalBarInnerText()),
                          ),
                          SizedBox(
                            width: MediaQuery.of(context).size.width * 0.095,
                          ),
                          Transform.rotate(
                            angle: 3.14159,
                            alignment: Alignment.centerRight,
                            child: const Icon(
                              Icons.arrow_back_ios_new_outlined,
                              size: 20,
                              color: Colors.purple,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(
                width: 10,
              ),
              Column(
                children: [
                  SizedBox(
                    child: Container(
                      width: MediaQuery.of(context).size.width * 0.45,
                      height: 35,
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: MediaQuery.of(context).size.width * 0.10,
                            height: 35,
                            decoration: BoxDecoration(
                              color: Colors.purple,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(10),
                                bottomLeft: Radius.circular(10),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey[300]!,
                                  spreadRadius: 2,
                                  blurRadius: 2,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.menu,
                                size: 20,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          Container(
                            width: MediaQuery.of(context).size.width * 0.35,
                            height: 35,
                            decoration: const BoxDecoration(
                              color: Color.fromARGB(52, 33, 219, 243),
                              borderRadius: BorderRadius.only(
                                topRight: Radius.circular(10),
                                bottomRight: Radius.circular(10),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text(
                                    "More                    ",
                                    style: WidgetSupport.verticalBarInnerText(),
                                  ),
                                ),
                                Transform.rotate(
                                  angle: 3.14159,
                                  alignment: Alignment.centerRight,
                                  child: const Icon(
                                    Icons.arrow_back_ios_new_outlined,
                                    size: 20,
                                    color: Colors.purple,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      );
  Widget _buildMidContainerWithButton() {
    const buttonHeight = 30.0;
    return Stack(
      children: [
        // Translate the button
        Transform.translate(
          offset: const Offset(0.0, -buttonHeight / 2.0),
          child: Center(
            child: GestureDetector(
              onTap: () {/* do stuff */},
              child: Container(
                height: buttonHeight,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(buttonHeight / 2.0),
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 16.0,
                      offset: const Offset(0.0, 6.0),
                      color: Colors.black.withOpacity(0.16),
                    ),
                  ],
                ),
                padding: const EdgeInsets.fromLTRB(24.0, 3.0, 24.0, 0.0),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(left: 8.0),
                      child: Text(
                        'Perfomance',
                        style: TextStyle(
                          fontSize: 17.0,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomContainer() => Flexible(
        flex: 0,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.93,
          height: MediaQuery.of(context).size.height * 0.16,
          color: Colors.blue,
          child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Bottom container',
                  style: TextStyle(
                    fontSize: 17.0,
                    fontWeight: FontWeight.w600,
                    color: Colors.black54,
                  ),
                ),
              ]),
        ),
      );
}
