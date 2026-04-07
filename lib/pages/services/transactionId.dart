import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pointycastle/api.dart' hide Padding;
import 'package:pointycastle/random/fortuna_random.dart';
import 'package:crypto/crypto.dart';

FortunaRandom createSecureFortunaRandomFromEntropy(String entropySource) {
  final secureRandom = FortunaRandom();
  final entropy = sha256.convert(utf8.encode(entropySource)).bytes;
  secureRandom.seed(KeyParameter(Uint8List.fromList(entropy)));
  return secureRandom;
}

String generateSecureTransactionId() {
  final random = Random();

  // 6 digit random number
  int randomNumber = 100000 + random.nextInt(900000);

  // current date time (yyyyMMddHHmmss)
  String dateTime = DateFormat('yyyyMMddHHmmss').format(DateTime.now());

  return "FSA_$randomNumber$dateTime";
}
 
 
  // String generateSecureTransactionId() {
  //   final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
  //   final entropyInput = '$timestamp:UnoSecureSeed';
  //   final secureRandom = createSecureFortunaRandomFromEntropy(entropyInput);

  //   // generate 4 random digits
  //   final digits = List.generate(6, (_) {
  //     final byte = secureRandom.nextUint8();
  //     return (byte % 10).toString();
  //   }).join();

  //   final now = DateTime.now();
  //   // final formattedDate =
  //   //     "${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}";

  //   final formattedDate =
  //     "${now.year}"
  //     "${now.month.toString().padLeft(2, '0')}"
  //     "${now.day.toString().padLeft(2, '0')}"
  //     "${now.hour.toString().padLeft(2, '0')}"
  //     "${now.minute.toString().padLeft(2, '0')}"
  //     "${now.second.toString().padLeft(2, '0')}";

  //   return "FSA_$digits$formattedDate"; 
  // }


