import 'dart:convert';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:unosfa/pages/config/config.dart';

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

  // Choose SSL hash based on environment
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

  return otpClientId;
}

Future<String> otpClientSecret() async {
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

  return otpClientSecret;
}

Future<String> googleApiKey() async {
  // If dev, return empty cert hash directly
  final remoteConfig = FirebaseRemoteConfig.instance;

  await remoteConfig.setConfigSettings(RemoteConfigSettings(
    fetchTimeout: const Duration(seconds: 10),
    minimumFetchInterval: const Duration(hours: 1),
  ));

  await remoteConfig.fetchAndActivate();

  final jsonString = remoteConfig.getString('google_map_key');
  if (jsonString.isEmpty) {
    throw Exception("No Api Key found in Remote Config");
  }

  final Map<String, dynamic> sslKeys = json.decode(jsonString);
  final bool isProd = AppConfig.isProd;
  final String googleMapApiKey =
      isProd ? sslKeys['map_key'] : sslKeys['map_key'];

  return googleMapApiKey;
}


Future<String> getPublicKey() async{
  final remoteConfig = FirebaseRemoteConfig.instance;
  await remoteConfig.fetchAndActivate();
  String publicKey = remoteConfig.getString('public_key');

  if(publicKey.isEmpty)
  {
    throw Exception("Public key not found in Remote Config");
  }
  return publicKey;

}

