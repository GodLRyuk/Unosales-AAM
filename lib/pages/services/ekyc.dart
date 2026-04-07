import 'dart:convert';
import 'dart:math';
import 'package:hyperkyc_flutter/hyperkyc_config.dart';
import 'package:hyperkyc_flutter/hyperkyc_flutter.dart';
import 'package:hyperkyc_flutter/hyperkyc_result.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unosfa/pages/services/api_service.dart';
import 'package:unosfa/pages/services/transactionId.dart';

class EkycService {
  static final String _chars =
      'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
  static final Random _rnd = Random();

  static String _randomString(int length) => String.fromCharCodes(
        Iterable.generate(length,
            (_) => _chars.codeUnitAt(_rnd.nextInt(_chars.length))),
      );

  /// MAIN FUNCTION TO START HYPERVERGE EKYC
  static Future<HyperKycResult> startKyc(cwTranscationID) async {
    String token = "";
    String finalToken = "";


  // final transactionId =  generateSecureTransactionId();
  final transactionId =cwTranscationID;
    
    print("Transaction Id for eKyc is $transactionId");

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString("accessToken");
    /// Step 1 → Fetch LOS Access Token
    final tokenResponse = await ApiService.getWithHeaders(
      "/api/leads/los-access-token/",
      {
        "Authorization": "Bearer $accessToken",
        "Content-Type": "application/json",
      },
    );

    token = json.decode(tokenResponse!.body)["access_token"];
    /// Step 2 → Fetch Hyperverge Token
    final hvResponse = await ApiService.getWithHeadersOnlyUnoApi(
      "/hv/token",
      {
        "Authorization": "Bearer $token",
        "Accept": "application/json",
        "Content-Type": "application/json",
        "channel": "AAM_FSA",
        "Correlation-ID": "Correlation-Id-3b2d2c13-4e48-4c6d-8b5d-dbdba6c3c0a8",
      },
    );
    print("HV response ${hvResponse!.statusCode}");
    print("HV response ${hvResponse.body}");
    finalToken = json.decode(hvResponse!.body)['token'];
    print("Final token $finalToken");
    print(hvResponse.body);
    /// Step 3 → Build HyperKYC Config
    var config = HyperKycConfig.fromAccessToken(
      accessToken: finalToken,
      workflowId: "ekyc",
      transactionId: transactionId,
    );
    print("Config print $config");
    config.setInputs(inputs: {});
    // Step 4 → Launch HyperKYC`
    HyperKycResult result =
        await HyperKyc.launch(hyperKycConfig: config);
      print("Result Hyperverser Print $result");

        Map<String, dynamic> responseMap = {
        "status": result.status.toString(),
        "transactionId": result.transactionId,
        "details": result.details,   // already a Map<String, dynamic>
      };

      
      String jsonString = jsonEncode(responseMap);
      for (int i = 0; i < jsonString.length; i += 1000) {
      print(jsonString.substring(
          i, (i + 1000 > jsonString.length) ? jsonString.length : i + 1000));
    }

      
      
      return result; // return result to caller

  

  }

}
