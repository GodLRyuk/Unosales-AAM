import 'package:flutter/material.dart';

class CheckInOverlay extends StatelessWidget {
  final VoidCallback onCheckIn;

  const CheckInOverlay({Key? key, required this.onCheckIn}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    final titleFontSize = screenWidth * 0.075; // dynamic font size
    final subTitleFontSize = screenWidth * 0.04;
    final bodyFontSize = screenWidth * 0.045;
    final buttonFontSize = screenWidth * 0.06;

    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.5),
      body: Center(
        child: SizedBox(
          width: screenWidth * 0.85,
          height: screenHeight * 0.5,
          child: Card(
            elevation: 10,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            color: const Color(0xFF8f1792),
            child: Padding(
              padding: EdgeInsets.all(screenWidth * 0.06),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(height: screenHeight * 0.02),
                  Text(
                    "Welcome Back".toUpperCase(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: titleFontSize,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    "You're doing great!",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: subTitleFontSize,
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.02),
                  Text(
                    "Tap the button below to\ncheck in for today.",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: bodyFontSize,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: screenHeight * 0.03),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFe88731),
                      padding: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.15,
                        vertical: screenHeight * 0.015,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    child: Text(
                      "CHECK IN",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: buttonFontSize,
                      ),
                    ),
                    onPressed: () {
                      onCheckIn();
                      Navigator.of(context).pop();
                    },
                  ),
                  SizedBox(height: screenHeight * 0.03),
                  Text(
                    "Remember to check out at\nthe end of the day.",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: bodyFontSize,
                    ),
                    textAlign: TextAlign.center,
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
