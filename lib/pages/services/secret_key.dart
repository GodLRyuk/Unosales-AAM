import 'dart:convert';
import 'dart:developer';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unosfa/pages/config/config.dart';
import 'package:unosfa/pages/services/api_global_key.dart';
import 'package:unosfa/pages/services/api_service.dart';

Future<void> globalKeys() async {
  final endpoint = '/api/secrets/';
  SharedPreferences prefs = await SharedPreferences.getInstance();
  final accessToken = prefs.getString('accessToken') ?? '';
  print("Access Token: $accessToken");
  try {
    final response = await ApiService.getWithHeaders(endpoint, {
      'Authorization': 'Bearer $accessToken',
      'Content-Type': 'application/json',
    });

    print("response is ${response!.data}");

    if (response!.statusCode == 200) {
      final data = response.data;

      // 1. Extract the 'results' list
      List<dynamic> resultsList = data['results'];

      // 2. Transform the list into a single Map
      Map<String, dynamic> mappedData = Map.fromEntries(
        resultsList.map((item) => MapEntry(item['key'], item['value'])),
      );

      // 3. Wrap the transformed data in the final "result"
      Map<String, dynamic> finalOutput = {"result": mappedData};

      // 4. Assign values to global variables based on the current environment
      ApiGlobalKeys.ssl_certificate =
          finalOutput['result']['ssl_certificate'][AppConfig.flavour];
      ApiGlobalKeys.otp_client_id =
          finalOutput['result']['otp_client_id'][AppConfig.flavour];
      ApiGlobalKeys.otp_client_secret =
          finalOutput['result']['otp_client_secret'][AppConfig.flavour];
      ApiGlobalKeys.public_key =
          finalOutput['result']['public_key'][AppConfig.flavour];

      print("Pubic key is this ${ApiGlobalKeys.public_key}");
      ApiGlobalKeys.security_check =
          finalOutput['result']['security_check'][AppConfig.flavour];
      
      
      ApiGlobalKeys.openroute_apiKey =
          finalOutput['result']['openroute_apiKey'][AppConfig.flavour];
      ApiGlobalKeys.save_payload_cookie =
          finalOutput['result']['save_payload'][AppConfig.flavour];
      ApiGlobalKeys.dedupe_payload_cookie =
          finalOutput['result']['dedupe'][AppConfig.flavour];
      ApiGlobalKeys.google_map_key =
          finalOutput['result']['google_map_key'][AppConfig.flavour];
    } else {
      throw Exception("Failed to fetch secret key: ${response.statusCode}");
    }
  } catch (e) {
    throw Exception("Failed to fetch secret key: $e");
  }
}

Future<String> setupSslKeys() async {
  final remoteConfig = FirebaseRemoteConfig.instance;

  await remoteConfig.setConfigSettings(RemoteConfigSettings(
    fetchTimeout: const Duration(seconds: 10),
    minimumFetchInterval: const Duration(hours: 1),
  ));

  await remoteConfig.fetchAndActivate();

  final jsonString = remoteConfig.getString('ssl_certificate');
  if (jsonString.isEmpty) {
    throw Exception("No SSL keys found in Remote Config");
  }

  final Map<String, dynamic> sslKeys = json.decode(jsonString);

  // // Choose SSL hash based on environment
  String certHash;
  if (AppConfig.isProd) {
    certHash = sslKeys['prod_ssl'];
  } else if (AppConfig.isDev) {
    certHash = sslKeys['dev_ssl'];
  } else {
    certHash = sslKeys['uat_ssl'];
  }

  return certHash;
}

Future<String> otpClientId() async {
  // If dev, return empty cert hash directly
  if (AppConfig.isDev) {
    return ''; // blank key for development
  }

  // final remoteConfig = FirebaseRemoteConfig.instance;

  // await remoteConfig.setConfigSettings(RemoteConfigSettings(
  //   fetchTimeout: const Duration(seconds: 10),
  //   minimumFetchInterval: const Duration(hours: 1),
  // ));

  // await remoteConfig.fetchAndActivate();

  // final jsonString = remoteConfig.getString('otp_client_id');
  // if (jsonString.isEmpty) {
  //   throw Exception("No Client Id found in Remote Config");
  // }

  // final Map<String, dynamic> sslKeys = json.decode(jsonString);
  // final bool isProd = AppConfig.isProd;
  // final String otpClientId =
  //     isProd ? sslKeys['prod_otp_client_id'] : sslKeys['uat_otp_client_id'];
  final String otpClientId = ApiGlobalKeys.otp_client_id;

  return otpClientId;
}

Future<String> otpClientSecret() async {
  // If dev, return empty cert hash directly
  if (AppConfig.isDev) {
    return ''; // blank key for development
  }

  // final remoteConfig = FirebaseRemoteConfig.instance;

  // await remoteConfig.setConfigSettings(RemoteConfigSettings(
  //   fetchTimeout: const Duration(seconds: 10),
  //   minimumFetchInterval: const Duration(hours: 1),
  // ));

  // await remoteConfig.fetchAndActivate();

  // final jsonString = remoteConfig.getString('otp_client_secret');
  // if (jsonString.isEmpty) {
  //   throw Exception("No Client Secret found in Remote Config");
  // }

  // final Map<String, dynamic> sslKeys = json.decode(jsonString);
  // final bool isProd = AppConfig.isProd;
  // final String otpClientSecret = isProd
  //     ? sslKeys['prod_otp_client_secret']
  //     : sslKeys['uat_otp_client_secret'];
  final String otpClientSecret = ApiGlobalKeys.otp_client_secret;
  return otpClientSecret;
}

Future<String> otpRegistrationClientSecret() async {
  // If dev, return empty cert hash directly
  if (AppConfig.isDev) {
    return ''; // blank key for development
  }

  final remoteConfig = FirebaseRemoteConfig.instance;

  await remoteConfig.setConfigSettings(RemoteConfigSettings(
    fetchTimeout: const Duration(seconds: 10),
    minimumFetchInterval: const Duration(hours: 1),
  ));

  await remoteConfig.fetchAndActivate();

  final jsonString = remoteConfig.getString('otp_client_secret');
  if (jsonString.isEmpty) {
    throw Exception("No Client Secret found in Remote Config");
  }

  final Map<String, dynamic> sslKeys = json.decode(jsonString);
  final bool isProd = AppConfig.isProd;
  final String otpClientSecret = isProd
      ? sslKeys['prod_otp_client_secret']
      : sslKeys['uat_otp_client_secret'];
  // final String otpClientSecret = ApiGlobalKeys.otp_client_secret;
  return otpClientSecret;
}

Future<String> otpRegistrationClientId() async {
  // If dev, return empty cert hash directly
  if (AppConfig.isDev) {
    return ''; // blank key for development
  }

  final remoteConfig = FirebaseRemoteConfig.instance;

  await remoteConfig.setConfigSettings(RemoteConfigSettings(
    fetchTimeout: const Duration(seconds: 10),
    minimumFetchInterval: const Duration(hours: 1),
  ));

  await remoteConfig.fetchAndActivate();

  final jsonString = remoteConfig.getString('otp_client_id');
  if (jsonString.isEmpty) {
    throw Exception("No Client Id found in Remote Config");
  }

  final Map<String, dynamic> sslKeys = json.decode(jsonString);
  final bool isProd = AppConfig.isProd;
  final String otpClientId =
      isProd ? sslKeys['prod_otp_client_id'] : sslKeys['uat_otp_client_id'];
  // final String otpClientId = ApiGlobalKeys.otp_client_id;

  return otpClientId;
}

Future<String> googleApiKey() async {
  // // If dev, return empty cert hash directly
  // final remoteConfig = FirebaseRemoteConfig.instance;

  // await remoteConfig.setConfigSettings(RemoteConfigSettings(
  //   fetchTimeout: const Duration(seconds: 10),
  //   minimumFetchInterval: const Duration(hours: 1),
  // ));

  // await remoteConfig.fetchAndActivate();

  // final jsonString = remoteConfig.getString('google_map_key');
  // if (jsonString.isEmpty) {
  //   throw Exception("No Api Key found in Remote Config");
  // }

  // final Map<String, dynamic> sslKeys = json.decode(jsonString);
  // final bool isProd = AppConfig.isProd;
  // final String googleMapApiKey =
  //     isProd ? sslKeys['map_key'] : sslKeys['map_key'];
  final String googleMapApiKey = ApiGlobalKeys.google_map_key;
  return googleMapApiKey;
}

Future<String> getPublicKey() async {
  // final remoteConfig = FirebaseRemoteConfig.instance;
  // await remoteConfig.fetchAndActivate();
  // String publicKey = remoteConfig.getString('public_key');

  // if (publicKey.isEmpty) {
  //   throw Exception("Public key not found in Remote Config");
  // }
  String publicKey = ApiGlobalKeys.public_key;
  print("Public Key is this $publicKey");
  return publicKey;
}

Future<String> enableSecurityChecks() async {
  // final remoteConfig = FirebaseRemoteConfig.instance;

  // await remoteConfig.setConfigSettings(RemoteConfigSettings(
  //   fetchTimeout: const Duration(seconds: 10),
  //   minimumFetchInterval: const Duration(hours: 1),
  // ));

  // await remoteConfig.fetchAndActivate();

  // final jsonString = remoteConfig.getString('security_check');
  // if (jsonString.isEmpty) {
  //   throw Exception("No Security check found");
  // }

  // final Map<String, dynamic> securityCheck = json.decode(jsonString);
  // final bool isProd = AppConfig.isProd;
  // final String getSecurityCheck = AppConfig.isDev
  //     ? securityCheck['dev_security_check']
  //     : isProd
  //         ? securityCheck['prod_security_check']
  //         : securityCheck['uat_security_check'];
  
  final String getSecurityCheck = ApiGlobalKeys.security_check;
  return getSecurityCheck;
}

Future<String> openrouteApiKey() async {
  // final remoteConfig = FirebaseRemoteConfig.instance;

  // await remoteConfig.fetchAndActivate();

  // final jsonString = remoteConfig.getString('openroute_apiKey');

  // if (jsonString.isEmpty) {
  //   throw Exception("Key not found in Remote Config");
  // }

  // final Map<String, dynamic> data = jsonDecode(jsonString);

  // final String apiKey = data['api_key'] ?? '';

  // if (apiKey.isEmpty) {
  //   throw Exception("api_key missing in JSON");
  // }
  final String apiKey = ApiGlobalKeys.openroute_apiKey;

  return apiKey;
}

Future<Map<String, String>> cookie() async {
  // final remoteConfig = FirebaseRemoteConfig.instance;

  // await remoteConfig.fetchAndActivate();

  // final jsonString = remoteConfig.getString('cookie');

  // if (jsonString.isEmpty) {
  //   throw Exception("Key not found in Remote Config");
  // }

  // final Map<String, dynamic> data = jsonDecode(jsonString);

  // final String savePayloadCookie = data['save_payload'] ?? '';

  // final String dedupePayloadCookie = data['dedupe'] ?? '';

  // if (savePayloadCookie.isEmpty) {
  //   throw Exception("save_payload missing in JSON");
  // }

  // if (dedupePayloadCookie.isEmpty) {
  //   throw Exception("dedupe missing in JSON");
  // }
  final String savePayloadCookie = ApiGlobalKeys.save_payload_cookie;
  final String dedupePayloadCookie = ApiGlobalKeys.dedupe_payload_cookie;

  return {
    "save_payload": savePayloadCookie,
    "dedupe": dedupePayloadCookie,
  };
}
