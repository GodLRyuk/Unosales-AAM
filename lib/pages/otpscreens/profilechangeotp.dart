// Add these fields
import 'package:flutter/material.dart';

// Your flags/data (adjust as per your app)
bool isOtpExpired = false;
String recivedOtp = ""; // set this when you get OTP from backend
bool isOtpVerified = false;

// Add this method INSIDE _ProfileUpdateState
Future<bool> verifyOtp({
  required BuildContext context,
  required bool isOtpExpired,
  required String receivedOtp,
  required String enteredOtp,
  required GlobalKey<FormState> formKey,
  required VoidCallback onStartLoading,
  required VoidCallback onStopLoading,
}) async {
  if (isOtpExpired) {
    await showDialog(
      context: context,
      builder: (_) => const AlertDialog(
        title: Text("Invalid OTP"),
        content: Text("The OTP has expired."),
      ),
    );
    return false;
  }

  if (!(formKey.currentState?.validate() ?? false)) return false;

  onStartLoading();
  try {
    if (receivedOtp == enteredOtp) {
      return true;
    }

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Info"),
        content: const Text("Invalid OTP"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
    return false;
  } finally {
    onStopLoading();
  }
}
