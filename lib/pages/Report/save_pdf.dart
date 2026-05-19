
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:unosfa/pages/services/api_service.dart';

class ExcelService {

  String fromDateforApi="";
  String toDateforApi = "";
  String selectValue ="";
  String textValue ="";
  static final Map<String, String> apiKeyMap = {
  'Agency': 'agency',
  'Supervisor': 'supervisor',
  'Team': 'team',

};

  
  static Future<String?> getToken() async {
    String token = "";
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString('accessToken');
    try {
      String tokenUrl = "/api/leads/los-access-token/";
      final headers = {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
        //'User-Agent':
         //   'Mozilla/5.0 (Linux; Android 11; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36',
      };
      final Tokenresponse = await ApiService.getWithHeaders(tokenUrl, headers);
      if (Tokenresponse != null) {
        final data = json.decode(Tokenresponse.data);
        //token = data['access_token'];
        print('token is $accessToken');  //Uno server access token
        return accessToken;

      
      }
    } catch (e) {
      print("HTTP Request Failed: $e");
    }
  }



  static Future<void> downloadExcel(
    BuildContext context, String fromDateforApi, String toDateforApi, String selectValue, String textValue ) async {
      print("text value is $textValue");
  String? unotoken = await getToken();
  print("API call starts ");
  print(unotoken);

  if (unotoken == null) {
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Failed to get token')));
    return;
  }

  try {
    // final url =
    //     "/api/timesheet/agent/hourly-report/?start_date=$fromDateforApi&end_date=$toDateforApi&$selectValue=$textValue";
 
     String key = apiKeyMap[selectValue] ?? selectValue.toLowerCase();

    final url =
    "/api/timesheet/agent/hourly-report/?start_date=$fromDateforApi&end_date=$toDateforApi&$key=$textValue";


    final headers = {
      'Authorization': 'Bearer $unotoken',
    };

    final response = await ApiService.getWithHeaders(url, headers);

    print("API response status: ${response?.statusCode}");

    if (response?.statusCode == 200) {
      Directory? directory;

      // Pick folder based on platform
      if (Platform.isAndroid) {
        directory = Directory("/storage/emulated/0/Download");
      } else {
        directory = await getApplicationDocumentsDirectory();
      }

      final now = DateTime.now();
      final formatted =
          "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}_"
          "${now.hour.toString().padLeft(2, '0')}-${now.minute.toString().padLeft(2, '0')}-${now.second.toString().padLeft(2, '0')}";

      final filePath =
          '${directory.path}/Agent_Hourly_Report_$formatted.xlsx';
      final file = File(filePath);

      await file.writeAsBytes(response!.data.bodyBytes, flush: true);

      // iOS → Share dialog (since iOS cannot save to Downloads)
      if (Platform.isIOS) {
        await Share.shareXFiles([XFile(file.path)],
            text: "Your Excel Report");
        return;
      }

      // ANDROID → Save directly
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Color(0xFFa604ad),
          content: Text('Excel downloaded successfully!\nSaved in Downloads'),
        ),
      );

      print("Saved at: $filePath");
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: Status ${response?.statusCode}')),
      );
    }
  } catch (e) {
    print('Error: $e');
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('Error: $e')));
  }
}





























// static Future<void> downloadExcel(
//     BuildContext context, String fromDateforApi, String toDateforApi, ) async {
//   String? unotoken = await getToken();
//   print("API call starts");

//   if (unotoken == null) {
//     ScaffoldMessenger.of(context)
//         .showSnackBar(const SnackBar(content: Text('Failed to get token')));
//     return;
//   }

//   try {
//     final url =
//         "/api/timesheet/agent/hourly-report/?start_date=$fromDateforApi&end_date=$toDateforApi";

//     final headers = {
//       'Authorization': 'Bearer $unotoken',
//     };

//     final response = await ApiService.getWithHeaders(url, headers);

//     print("API response status: ${response?.statusCode}");

//     if (response?.statusCode == 200) {
//       Directory? directory;

//       // Pick folder based on platform
//       if (Platform.isAndroid) {
//         directory = Directory("/storage/emulated/0/Download");
//       } else {
//         directory = await getApplicationDocumentsDirectory();
//       }

//       final now = DateTime.now();
//       final formatted =
//           "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}_"
//           "${now.hour.toString().padLeft(2, '0')}-${now.minute.toString().padLeft(2, '0')}-${now.second.toString().padLeft(2, '0')}";

//       final filePath =
//           '${directory.path}/Agent_Hourly_Report_$formatted.xlsx';
//       final file = File(filePath);

//       await file.writeAsBytes(response!.bodyBytes, flush: true);

//       // iOS → Share dialog (since iOS cannot save to Downloads)
//       if (Platform.isIOS) {
//         await Share.shareXFiles([XFile(file.path)],
//             text: "Your Excel Report");
//         return;
//       }

//       // ANDROID → Save directly
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           backgroundColor: Color(0xFFa604ad),
//           content: Text('Excel downloaded successfully!\nSaved in Downloads'),
//         ),
//       );

//       print("Saved at: $filePath");
//     } else {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Failed: Status ${response?.statusCode}')),
//       );
//     }
//   } catch (e) {
//     print('Error: $e');
//     ScaffoldMessenger.of(context)
//         .showSnackBar(SnackBar(content: Text('Error: $e')));
//   }
// }


}
