import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pointycastle/asymmetric/api.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unosfa/pages/config/config.dart';
import 'package:unosfa/pages/services/api_service.dart';
import 'package:encrypt/encrypt.dart' as encrypt;

class ComingSoon extends StatefulWidget {
  const ComingSoon({super.key});

  @override
  State<ComingSoon> createState() => _ComingSoonState();
}

class _ComingSoonState extends State<ComingSoon> {
  void initState() {
    super.initState();
    callSosLogoin();
  }
  List<String>? userInfo;


  Future<void> callSosLogoin() async {
  try {
    final payload = await buildPayload();
    print("Payload value is ${jsonEncode(payload)}");
    

    final url = Uri.parse("${AppConfig.otpUrl}/auth/sso-login");   //https://unoapi.uat.ph.unobank.asia/auth/sso-login

    final headers = {
      "Content-Type": "application/json",
      "Accept": "application/json",
      "User-Agent":
          "Mozilla/5.0 (Linux; Android 11; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36",

    };

    final response = await http.post(
      url,
      headers: headers,
      body: jsonEncode(payload),
    );

    print("API response is ${response.body}");

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final sostoken = data["token"];

      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString("ssoToken", sostoken);

      print("Token saved successfully");
      //return sostoken;
    } else {
      print("Error happened → Status: ${response.statusCode}");
     // return null;
    }
  } catch (e) {
    print("Error is this: $e");
    //return null;
  }
}
String publicKeyP1 = """
-----BEGIN PUBLIC KEY-----
MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAibVtzmmpQ8OpmWzF3M3Z
KPDURcq55io/K5K0OJaoHrkVfEaDTy+irLoqvwaQc80jFJtbQRjYSIezK8gYnRM6
e4MlSw+Wojr9NSjBMYRZ7mr+WDXNqdVI36ml9IXl4e0xAD/4Gm/IhaQCZFCxWl35
VeKdfNI1YdfMp2vYRLgGDWfeSFf87REIUCfOv6pUeG5cwE8ittGFh6M+k5ZXdB5O
Vs7yVx5vqbrIzL+ucHlys2K5PDgPJ5VDBZ6GeyoS7+PlC/JOp9OH5kS/53KUTgs+
ZEFCBwjHh4gEzA2LBumOEHpxOTV42d0zLDlr1qmLXuLVbKIoVn1/9mhyf2a5L63N
AQIDAQAB
-----END PUBLIC KEY-----
""";

Future<Map<String, dynamic>> buildPayload() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
    userInfo = prefs.getStringList('userInfo');
  //String agentCode = "testFSA";
  print("agent code is $userInfo[0]");

  if (userInfo![0] == null || userInfo![0].isEmpty) {
    throw Exception("Agent code not found in SharedPreferences");
  }

  // Parse RSA Public Key
  final parser = encrypt.RSAKeyParser();
  final RSAPublicKey rsaPublicKey = parser.parse(publicKeyP1) as RSAPublicKey;

  final encrypter = encrypt.Encrypter(
    encrypt.RSA(publicKey: rsaPublicKey),
  );

  // 1️⃣ JSON object to encrypt
  final jsonObject = 
  {
    "userId": userInfo![0], 
    "appId": "Sales_App",

  };

  // 2️⃣ Convert to JSON string
  final jsonString = json.encode(jsonObject);

  print("JSON Before Encryption: $jsonString");

  // 3️⃣ Encrypt JSON once
  final encrypted = encrypter.encrypt(jsonString).base64;

  print("Encrypted JSON: $encrypted");

  // 4️⃣ Final payload
  return {
    "data": encrypted,
    "keyId": "v1",
  };
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFFc433e0),
                Color(0xFF9a37ae),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        centerTitle: true,
        title: Image.asset(
          'images/logo.PNG',
          height: 30,
        ),
      ),
      body: Container(
        color: Colors.white,
        child: Center(
          child: Image.asset(
            'images/commingSoon.jpg',
            fit: BoxFit.fill,
            // width: double.infinity,
            // height: double.infinity,
          ),
        ),
        
      ),
    );
  }
}
