import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_certificate_pinning/http_certificate_pinning.dart';
import 'package:pdf/widgets.dart';
import 'package:unosfa/pages/config/config.dart';

enum CertificateState {
  CERTIFICATE_VALID,
  CERTIFICATE_NOT_MATCH_PIN,
  CERTIFICATE_NOT_TRUSTED,
  HOST_NAME_NOT_MATCH,
  CERTIFICATE_EXPIRED,
  ERROR_CHECKING_CERTIFICATE,
  CONNECTION_SECURE,
}

final certificate = AppConfig.certificateChecks;

class ApiService {
  static Future<http.Response?> post(
      String endpoint, Map<String, String> body) async {
    final baseUri = Uri.parse(AppConfig.dynamicBaseUrl);
    final fullUrl = Uri.parse('${AppConfig.dynamicBaseUrl}$endpoint');
    final isHttps = baseUri.scheme == 'https';
    if (isHttps) {
      final result = await HttpCertificatePinning.check(
        serverURL: baseUri.origin,
        headerHttp: {},
        timeout: 50,
        sha: SHA.SHA256,
        allowedSHAFingerprints: [certificate],
      );
      if (result != CertificateState.CERTIFICATE_VALID) {
        print("✅ SSL pinning succeededs");
        return await http.post(
          fullUrl,
          body: body,
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/x-www-form-urlencoded',
            'User-Agent':
                'Mozilla/5.0 (Linux; Android 11; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36', // Override the default User-Agent
          },
        );
      }
    } else {
      print("🌐 Non-HTTPS endpoint, skipping pinning 1");
      return await http.post(fullUrl, body: body);
    }
    return null;
  }

  static Future<http.Response?> uploadMultipart({
    required String endpoint,
    required Map<String, String> fields,
    Map<String, String>? headers,
    File? file,
    String fileField = 'image',
  }) async {
    final fullUrl = Uri.parse('${AppConfig.dynamicBaseUrl}$endpoint');
    final baseUri = Uri.parse(AppConfig.dynamicBaseUrl);
    final isHttps = baseUri.scheme == 'https';
    if (isHttps) {
      final result = await HttpCertificatePinning.check(
        serverURL: baseUri.origin,
        headerHttp: {},
        timeout: 50,
        sha: SHA.SHA256,
        allowedSHAFingerprints: [certificate],
      );
      print("uploadMultipart url1 is $fullUrl"); //***********/
      print("uploadMultipart hearder1 is $headers"); //************** */

      if (result != CertificateState.CERTIFICATE_VALID) {
        print("✅ SSL pinning succeeded");
        final request = http.MultipartRequest('POST', fullUrl);
        request.headers.addAll(headers ??
            {
              'Accept': 'application/json',
              'User-Agent':
                  'Mozilla/5.0 (Linux; Android 11; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36', // Override the default User-Agent
            });
        request.fields.addAll(fields);

      print("uploadMultipart url2 is $fullUrl"); //***********/
      print("uploadMultipart hearder2 is $headers"); //**************** */

        if (file != null) {
          request.files
              .add(await http.MultipartFile.fromPath(fileField, file.path));
        }

        final streamedResponse = await request.send();
        return await http.Response.fromStream(streamedResponse);
      } else {
        print("❌ SSL pinning failed: ${result}");
        return null;
      }
    } else {
      print("🌐 Non-HTTPS endpoint, skipping pinning2");
      final request = http.MultipartRequest('POST', fullUrl);
      request.headers.addAll(headers ??
          {
            'Accept': 'application/json',
            'Content-Type': 'multipart/form-data',
            'User-Agent':
                'Mozilla/5.0 (Linux; Android 11; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36', // Override the default User-Agent
          });
        
      request.fields.addAll(fields);
      if (file != null) {
        request.files
            .add(await http.MultipartFile.fromPath(fileField, file.path));
      }
      print("uploadMultipart url3 is $fullUrl"); //***********/
      print("uploadMultipart hearder3 is $headers"); //************** */

      final streamedResponse = await request.send();
      return await http.Response.fromStream(streamedResponse);
      
    }
  }


  static Future<http.Response?> putuploadMultipart({
    required String endpoint,
    required Map<String, String> fields,
    Map<String, String>? headers,
    File? file,
    String fileField = 'image',
  }) async {
    final fullUrl = Uri.parse('${AppConfig.dynamicBaseUrl}$endpoint');
    final baseUri = Uri.parse(AppConfig.dynamicBaseUrl);
    final isHttps = baseUri.scheme == 'https';

    print("putuploadMultipart url1 is $fullUrl"); //********************* */
    print("putuploadMultipart hearder1 is $headers"); //********************** */

    if (isHttps) {
      final result = await HttpCertificatePinning.check(
        serverURL: baseUri.origin,
        headerHttp: {},
        timeout: 50,
        sha: SHA.SHA256,
        allowedSHAFingerprints: [certificate],
      );

      if (result != CertificateState.CERTIFICATE_VALID) {
        print("✅ SSL pinning succeeded");
        final request = http.MultipartRequest('PUT', fullUrl);
        request.headers.addAll(headers ??
            {
              'Accept': 'application/json',
              'Content-Type': 'multipart/form-data',
              'User-Agent':
                  'Mozilla/5.0 (Linux; Android 11; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36', // Override the default User-Agent
            });
        request.fields.addAll(fields);
        
        print("putuploadMultipart url2 is $fullUrl"); //********************* */
        print("putuploadMultipart hearder2 is $headers"); //********************** */

        if (file != null) {
          request.files
              .add(await http.MultipartFile.fromPath(fileField, file.path));
        }

        final streamedResponse = await request.send();
        return await http.Response.fromStream(streamedResponse);
      } else {
        print("❌ SSL pinning failed: ${result}");
        return null;
      }

    } else {
      print("🌐 Non-HTTPS endpoint, skipping pinning3");
      final request = http.MultipartRequest('PUT', fullUrl);
      request.headers.addAll(headers ??
          {
            'Accept': 'application/json',
            'Content-Type': 'multipart/form-data',
            'User-Agent':
                'Mozilla/5.0 (Linux; Android 11; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36', // Override the default User-Agent
          });
      request.fields.addAll(fields);

      print("putuploadMultipart url3 is $fullUrl"); //********************* */
      print("putuploadMultipart hearder3 is $headers"); //********************** */
   
      if (file != null) {
        request.files
            .add(await http.MultipartFile.fromPath(fileField, file.path));
      }

      final streamedResponse = await request.send();
      return await http.Response.fromStream(streamedResponse);
    }
  }



  static Future<http.Response?> postJsonWithHeaders(
    String endpoint,
    Map<String, dynamic> body,
    Map<String, String> headers,
  ) async {
    final baseUri = Uri.parse(AppConfig.unoBaseApiUrl);
    final fullUrl = Uri.parse('${AppConfig.unoBaseApiUrl}$endpoint');
    final isHttps = baseUri.scheme == 'https';

     print("postJsonWithHeaders header $fullUrl"); //********** */
     print("postJsonWithHeaders header $headers"); //********** */
    // headers['User-Agent'] =
    //     'Mozilla/5.0 (Linux; Android 11; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36';
    if (isHttps) {
      final result = await HttpCertificatePinning.check(
        serverURL: baseUri.origin,
        headerHttp: {},
        timeout: 50,
        sha: SHA.SHA256,
        allowedSHAFingerprints: [certificate],
      );
      if (result != CertificateState.CERTIFICATE_VALID) {
        print("✅ SSL pinning succeeded");
        return await http.post(
          fullUrl,
          headers: headers,
          body: jsonEncode(body),
        );        
      } else {
        print("❌ SSL pinning failed: ${result}");
        return null;
      }
      
    } else {
      print("🌐 Non-HTTPS endpoint, skipping pinning4");
      return await http.post(fullUrl, body: jsonEncode(body), headers: headers);
    }
    
  }



   static Future<http.Response?> postJsonWithUNOApiHeaders(
    String endpoint,
    Map<String, dynamic> body,
    Map<String, String> headers,
  ) async {
    final baseUri = Uri.parse(AppConfig.dynamicBaseUrl);
    final fullUrl = Uri.parse('${AppConfig.dynamicBaseUrl}$endpoint');
    final isHttps = baseUri.scheme == 'https';
    // print(fullUrl);
    // print(jsonEncode(body) );
     print("postJsonWithHeaders header $fullUrl"); //********** */
     print("postJsonWithHeaders header $headers"); //********** */
    // headers['User-Agent'] =
    //     'Mozilla/5.0 (Linux; Android 11; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36';
    if (isHttps) {
      final result = await HttpCertificatePinning.check(
        serverURL: baseUri.origin,
        headerHttp: {},
        timeout: 50,
        sha: SHA.SHA256,
        allowedSHAFingerprints: [certificate],
      );
      if (result != CertificateState.CERTIFICATE_VALID) {
        print("✅ SSL pinning succeeded");
        return await http.post(
          fullUrl,
          headers: headers,
          body: jsonEncode(body),
        );        
      } else {
        print("❌ SSL pinning failed: ${result}");
        return null;
      }
      
    } else {
      print("🌐 Non-HTTPS endpoint, skipping pinning4");
      return await http.post(fullUrl, body: jsonEncode(body), headers: headers);
    }
    
  }



  static Future<http.Response?> getWithHeaders(
    String endpoint,
    Map<String, String> headers,
  ) async {
    final baseUri = Uri.parse(AppConfig.dynamicBaseUrl);
    final fullUrl = Uri.parse('${AppConfig.dynamicBaseUrl}$endpoint');
    final isHttps = baseUri.scheme == 'https';
    headers['User-Agent'] =
        'Mozilla/5.0 (Linux; Android 11; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36';

     print("getWithHeaders url is $fullUrl"); //************** */
     print("getWithHeaders url is $headers"); //************** */

    if (isHttps) {
      final result = await HttpCertificatePinning.check(
        serverURL: baseUri.origin,
        headerHttp: {},
        timeout: 50,
        sha: SHA.SHA256,
        allowedSHAFingerprints: [certificate],
      );
      if (result != CertificateState.CERTIFICATE_VALID) {
        print("✅ SSL pinning succeeded");
        return await http.get(fullUrl, headers: headers);
      } else {
        print("❌ SSL pinning failed: ${result}");
        return null;
      }
    } else {
      return await http.get(fullUrl, headers: headers);
    }
  }



  static Future<http.Response?> getWithUnoApiHeaders(
    String endpoint,
    Map<String, String> headers,
  ) async {
    final baseUri = Uri.parse(AppConfig.unoBaseApiUrl);
    final fullUrl = Uri.parse('${AppConfig.unoBaseApiUrl}$endpoint');
    final isHttps = baseUri.scheme == 'https';
    headers['User-Agent'] =
        'Mozilla/5.0 (Linux; Android 11; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36';

     print("getWithUnoApiHeaders url is $fullUrl"); //************** */
     print("getWithUnoApiHeaders url is $headers"); //************** */

    if (isHttps) {
      final result = await HttpCertificatePinning.check(
        serverURL: baseUri.origin,
        headerHttp: {},
        timeout: 50,
        sha: SHA.SHA256,
        allowedSHAFingerprints: [certificate],
      );
      if (result != CertificateState.CERTIFICATE_VALID) {
        print("✅ SSL pinning succeeded");
        return await http.get(fullUrl, headers: headers);
      } else {
        print("❌ SSL pinning failed: ${result}");
        return null;
      }
    } else {
      return await http.get(fullUrl, headers: headers);
    }
  }

  static Future<http.Response?> getWithsingleHeaders(
    String endpoint,
  ) async {
    final baseUri = Uri.parse(AppConfig.dynamicBaseUrl);
    final fullUrl = Uri.parse('${AppConfig.dynamicBaseUrl}$endpoint');
    final isHttps = baseUri.scheme == 'https';

    print("getWithsingleHeaders url is $fullUrl"); //********* */

    if (isHttps) {
      final result = await HttpCertificatePinning.check(
        serverURL: baseUri.origin,
        headerHttp: {},
        timeout: 50,
        sha: SHA.SHA256,
        allowedSHAFingerprints: [certificate],
      );

      if (result != CertificateState.CERTIFICATE_VALID) {
        print("✅ SSL pinning succeeded");
        return await http.get(fullUrl);
      } else {
        print("❌ SSL pinning failed: ${result}");
        return null;
      }
    } else {
      print("🌐 Non-HTTPS endpoint, skipping pinning6");
      return await http.post(fullUrl);
    }
  }

  static Future<http.Response?> patchWithHeaders(
    String endpoint,
    Map<String, String> headers,
    Map<String, dynamic> body,
  ) async {
    final baseUri = Uri.parse(AppConfig.dynamicBaseUrl);
    final fullUrl = Uri.parse('${AppConfig.dynamicBaseUrl}$endpoint');
    final isHttps = baseUri.scheme == 'https';
    if (isHttps) {
      final result = await HttpCertificatePinning.check(
        serverURL: baseUri.origin,
        headerHttp: {},
        timeout: 50,
        sha: SHA.SHA256,
        allowedSHAFingerprints: [certificate],
      );
      if (result != CertificateState.CERTIFICATE_VALID) {
        print("patchWithHeaders url is $fullUrl"); //********************* */
        print("patchWithHeaders header is $headers"); //***************** */
        return await http.patch(
          fullUrl,
          headers: headers,
          body: json.encode(body),
        );
      } else {
        print("❌ SSL pinning failed: ${result}");
        return null;
      }
    } else {
      // print(fullUrl);
      // print("HEADERS $headers");
      // print(jsonEncode(body));
      print("🌐 Non-HTTPS endpoint, skipping pinning7sss");
      return await http.patch(
        fullUrl,
        headers: headers,
        body: jsonEncode(body),
      );
    }
    
  }

  static Future<http.Response?> postWithHeadersUnoApi(
    String endpoint,
    Map<String, dynamic> body,
    Map<String, String> headers,
  ) async {
    final baseUri = Uri.parse(AppConfig.otpUrl);
    final fullUrl = Uri.parse('${AppConfig.otpUrl}$endpoint');
    final isHttps = baseUri.scheme == 'https';
    headers['User-Agent'] =
        'Mozilla/5.0 (Linux; Android 11; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36';

     print("postWithHeadersUnoApi url $fullUrl"); //*********** */
     print("postWithHeadersUnoApi header $headers"); //************* */
    // print(jsonEncode(body) );
    if (isHttps) {
      final result = await HttpCertificatePinning.check(
        serverURL: baseUri.origin,
        headerHttp: {},
        timeout: 50,
        sha: SHA.SHA256,
        allowedSHAFingerprints: [certificate],
      );
      if (result != CertificateState.CERTIFICATE_VALID) {
        print("✅ SSL pinning succeeded");
        return await http.post(
          fullUrl,
          headers: headers,
          body: jsonEncode(body),
        );
      } else {
        print("❌ SSL pinning failed: ${result}");
        return null;
      }
    } else {
      print("🌐 Non-HTTPS endpoint, skipping pinnings8");
      return await http.post(fullUrl, body: jsonEncode(body));
    }
  }

static Future<http.Response?> getWithHeadersOnlyUnoApi(
    String endpoint,
    Map<String, String> headers,
  ) async {
    final baseUri = Uri.parse(AppConfig.otpUrl);
    final fullUrl = Uri.parse('${AppConfig.otpUrl}$endpoint');
    final isHttps = baseUri.scheme == 'https';
    headers['User-Agent'] =
        'Mozilla/5.0 (Linux; Android 11; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36';
     print("getWithHeadersOnlyUnoApi url $fullUrl"); //********** */
     print("getWithHeadersOnlyUnoApi header $headers");//********* */
    // print(jsonEncode(body) );
    if (isHttps) {
      final result = await HttpCertificatePinning.check(
        serverURL: baseUri.origin,
        headerHttp: {},
        timeout: 50,
        sha: SHA.SHA256,
        allowedSHAFingerprints: [certificate],
      );
      if (result != CertificateState.CERTIFICATE_VALID) {
        print("✅ SSL pinning succeeded");
        return await http.get(
          fullUrl,
          headers: headers,
        );
      } else {
        print("❌ SSL pinning failed: ${result}");
        return null;
      }
    } else {
      print("🌐 Non-HTTPS endpoint, skipping pinnings8");
      return await http.get(fullUrl);
    }
  }

  static Future<http.Response?> postWithBodyUnoApi(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    final baseUri = Uri.parse(AppConfig.otpUrl);
    final fullUrl = Uri.parse('${AppConfig.otpUrl}$endpoint');
    final isHttps = baseUri.scheme == 'https';
    if (isHttps) {
      final result = await HttpCertificatePinning.check(
        serverURL: baseUri.origin,
        headerHttp: {},
        timeout: 50,
        sha: SHA.SHA256,
        allowedSHAFingerprints: [certificate],
      );

      if (result != CertificateState.CERTIFICATE_VALID) {
        print("✅ SSL pinning succeeded");
        return await http.post(
          fullUrl,
          body: jsonEncode(body),
        );
      } else {
        print("❌ SSL pinning failed: ${result}");
        return null;
      }
    } else {
      print("🌐 Non-HTTPS endpoint, skipping pinning9");
      return await http.post(fullUrl, body: body);
    }
  }
}
