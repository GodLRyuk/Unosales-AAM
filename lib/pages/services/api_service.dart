import 'dart:io';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:http_certificate_pinning/http_certificate_pinning.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

CertificateState parseCertificateState(String value) {
  return CertificateState.values.firstWhere(
    (e) => e.name == value,
    orElse: () => CertificateState.ERROR_CHECKING_CERTIFICATE,
  );
}

final certificate = AppConfig.certificateChecks;

// ─── SSL Pinning Interceptor ──────────────────────
class SSLPinningInterceptor extends Interceptor {
  final String baseUrl;

  SSLPinningInterceptor({required this.baseUrl});

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final baseUri = Uri.parse(baseUrl);
    final isHttps = baseUri.scheme == 'https';

    if (!isHttps) {
      print("🌐 Non-HTTPS endpoint, skipping pinning");
      return handler.next(options);
    }

    final result = await HttpCertificatePinning.check(
      serverURL: baseUri.origin,
      headerHttp: {},
      timeout: 50,
      sha: SHA.SHA256,
      allowedSHAFingerprints: [certificate],
    );

    final state = parseCertificateState(result);

    if (state == CertificateState.CONNECTION_SECURE) {
      print("✅ SSL pinning succeeded");
      return handler.next(options);
    } else {
      print("❌ SSL pinning failed: $result");
      return handler.reject(
        DioException(
          requestOptions: options,
          type: DioExceptionType.connectionError,
          error: "SSL pinning failed: $state",
          message: "SSL pinning failed with state: ${state.name}",
        ),
        true,
      );
    }
  }
}

// ─── Token Interceptor ───────────────────────────────────

class TokenInterceptor extends Interceptor {
  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Skip token attachment for public endpoints
    if (options.path.contains('/users/login/') ||
        options.path.contains('/register')) {
      return handler.next(options);
    }

    // Added by papri
    if (options.headers.containsKey('Authorization')) {
      print("🔑 Authorization already set, skipping TokenInterceptor");
      return handler.next(options);
    }
    // Done

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('accessToken');
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    return handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == 401) {
      try {
        final newToken = await _refreshToken();
        if (newToken != null) {
          final opts = err.requestOptions;
          opts.headers['Authorization'] = 'Bearer $newToken';
          final response = await DioClient.dynamic.fetch(opts);
          return handler.resolve(response);
        }
      } catch (e) {
        print("🔴 Token refresh failed: $e");
      }
    }
    return handler.next(err);
  }

  Future<String?> _refreshToken() async {
    // Replace with your token refresh logic
    return null;
  }
}

// ─── Shared headers ───────────────────────────────────────────────────────────

const _kUserAgent = 'Mozilla/5.0 (Linux; Android 11; Mobile) AppleWebKit/537.36'
    ' (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36';

// ─── Dio Client Factory ───────────────────────────────────────────────────────

class DioClient {
  DioClient._();

  // Client for AppConfig.dynamicBaseUrl
  static final Dio dynamic = _build(AppConfig.dynamicBaseUrl);

  // Client for AppConfig.unoBaseApiUrl
  static final Dio uno = _build(AppConfig.unoBaseApiUrl);

  // Client for AppConfig.otpUrl
  static final Dio otp = _build(AppConfig.otpUrl);

  static Dio _build(String baseUrl) {
    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        headers: {
          'Accept': 'application/json',
          'User-Agent': _kUserAgent,
        },
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
      ),
    );

    dio.interceptors.addAll([
      SSLPinningInterceptor(baseUrl: baseUrl),
      TokenInterceptor(),
    ]);

    return dio;
  }
}

// ─── API Service ──────────────────────────────────────────────────────────────

class ApiService {
  ApiService._();

  // ── POST form-urlencoded ────────────────────────────────────────────────────

  static Future<Response?> post(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    try {
      return await DioClient.dynamic.post(
        endpoint,
        data: body,
        options: Options(contentType: 'application/x-www-form-urlencoded'),
      );
    } on DioException catch (e) {
      _handleError(e);
      return null;
    }
  }

  // ── POST multipart (file upload) ────────────────────────────────────────────

  static Future<Response?> uploadMultipart({
    required String endpoint,
    required Map<String, String> fields,
    Map<String, String>? headers,
    File? file,
    String fileField = 'image',
  }) async {
    try {
      final formData = await _buildFormData(fields, file, fileField);
      return await DioClient.dynamic.post(
        endpoint,
        data: formData,
        options: Options(headers: headers),
      );
    } on DioException catch (e) {
      _handleError(e);
      return null;
    }
  }

  // ── PUT multipart ───────────────────────────────────────────────────────────

  static Future<Response?> putuploadMultipart({
    required String endpoint,
    required Map<String, String> fields,
    Map<String, String>? headers,
    File? file,
    String fileField = 'image',
  }) async {
    try {
      final formData = await _buildFormData(fields, file, fileField);
      return await DioClient.dynamic.put(
        endpoint,
        data: formData,
        options: Options(headers: headers),
      );
    } on DioException catch (e) {
      _handleError(e);
      return null;
    }
  }

  // ── POST JSON with UNO API headers ──────────────────────────────────────────

  static Future<Response?> postJsonWithUNOApiHeaders(
    String endpoint,
    Map<String, dynamic> body,
    Map<String, String> headers,
  ) async {
    try {
      print("postJsonWithHeaders header ${AppConfig.unoBaseApiUrl}$endpoint");
      print("postJsonWithHeaders header $headers");
      print("Body $body");
      return await DioClient.uno.post(
        endpoint,
        data: jsonEncode(body),
        options: Options(
          contentType: 'application/json',
          headers: headers,
        ),
      );
    } on DioException catch (e) {
      _handleError(e);
      return null;
    }
  }

  // ── POST JSON with dynamic headers ──────────────────────────────────────────

  static Future<Response?> postJsonWithHeaders(
    String endpoint,
    Map<String, dynamic> body,
    Map<String, String> headers,
  ) async {
    try {
      return await DioClient.dynamic.post(
        endpoint,
        data: jsonEncode(body),
        options: Options(
          contentType: 'application/json',
          headers: headers,
        ),
      );
    } on DioException catch (e) {
      _handleError(e);
      return null;
    }
  }

  // ── GET with headers ────────────────────────────────────────────────────────

  static Future<Response?> getWithHeaders(
    String endpoint,
    Map<String, String> headers,
  ) async {
    try {
      print("getWithHeaders url is ${AppConfig.dynamicBaseUrl}$endpoint");
      print("getWithHeaders headers are $headers");
      return await DioClient.dynamic.get(
        endpoint,
        options: Options(headers: headers),
      );
    } on DioException catch (e) {
      _handleError(e);
      return null;
    }
  }

  // ── GET with UNO API headers ────────────────────────────────────────────────

  static Future<Response?> getWithUnoApiHeaders(
    String endpoint,
    Map<String, String> headers,
  ) async {
    try {
      return await DioClient.uno.get(
        endpoint,
        options: Options(headers: headers),
      );
    } on DioException catch (e) {
      _handleError(e);
      return null;
    }
  }

  // ── GET (no headers) ────────────────────────────────────────────────────────

  static Future<Response?> getWithsingleHeaders(String endpoint) async {
    try {
      return await DioClient.dynamic.get(endpoint);
    } on DioException catch (e) {
      _handleError(e);
      return null;
    }
  }

  // ── PATCH JSON ──────────────────────────────────────────────────────────────

  static Future<Response?> patchWithHeaders(
    String endpoint,
    Map<String, String> headers,
    Map<String, dynamic> body,
  ) async {
    try {
      return await DioClient.dynamic.patch(
        endpoint,
        data: jsonEncode(body),
        options: Options(
          contentType: 'application/json',
          headers: headers,
        ),
      );
    } on DioException catch (e) {
      _handleError(e);
      return null;
    }
  }

  // ── POST with OTP/UNO API (with headers) ────────────────────────────────────

  static Future<Response?> postWithHeadersUnoApi(
    String endpoint,
    Map<String, dynamic> body,
    Map<String, String> headers,
  ) async {
    try {
      return await DioClient.otp.post(
        endpoint,
        data: jsonEncode(body),
        options: Options(
          contentType: 'application/json',
          headers: headers,
        ),
      );
    } on DioException catch (e) {
      _handleError(e);
      return null;
    }
  }

  // ── GET with OTP/UNO API headers only ──────────────────────────────────────

  static Future<Response?> getWithHeadersOnlyUnoApi(
    String endpoint,
    Map<String, String> headers,
  ) async {
    try {
      return await DioClient.otp.get(
        endpoint,
        options: Options(headers: headers),
      );
    } on DioException catch (e) {
      _handleError(e);
      return null;
    }
  }

  // ── POST with body (OTP/UNO API, no custom headers) ────────────────────────

  static Future<Response?> postWithBodyUnoApi(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    try {
      return await DioClient.otp.post(
        endpoint,
        data: jsonEncode(body),
        options: Options(contentType: 'application/json'),
      );
    } on DioException catch (e) {
      _handleError(e);
      return null;
    }
  }

  // ── PATCH multipart (optional image) ────────────────────────────────────────

  static Future<Response?> patchWithHeadersUploadMultiPart(
    String endpoint,
    Map<String, String> headers,
    Map<String, dynamic> body, {
    File? imageFile,
    String imageField = 'upload_selfie',
  }) async {
    try {
      if (imageFile != null) {
        final fields = body.map((k, v) => MapEntry(k, v?.toString() ?? ''));
        final formData = await _buildFormData(fields, imageFile, imageField);
        return await DioClient.dynamic.patch(
          endpoint,
          data: formData,
          options: Options(headers: headers),
        );
      }
      // No image → plain JSON patch
      return await DioClient.dynamic.patch(
        endpoint,
        data: jsonEncode(body),
        options: Options(
          contentType: 'application/json',
          headers: headers,
        ),
      );
    } on DioException catch (e) {
      _handleError(e);
      return null;
    }
  }

  // ── POST multipart (optional image) ─────────────────────────────────────────

  static Future<Response?> postWithHeadersUploadMultiPart(
    String endpoint,
    Map<String, String> headers,
    Map<String, dynamic> body, {
    File? imageFile,
    String imageField = 'upload_selfie',
  }) async {
    try {
      if (imageFile != null) {
        final fields = body.map((k, v) => MapEntry(k, v?.toString() ?? ''));
        final formData = await _buildFormData(fields, imageFile, imageField);
        return await DioClient.dynamic.post(
          endpoint,
          data: formData,
          options: Options(headers: headers),
        );
      }
      // No image → plain JSON post
      return await DioClient.dynamic.post(
        endpoint,
        data: jsonEncode(body),
        options: Options(
          contentType: 'application/json',
          headers: headers,
        ),
      );
    } on DioException catch (e) {
      _handleError(e);
      return null;
    }
  }

  // ─── Shared helpers ─────────────────────────────────────────────────────────

  static Future<FormData> _buildFormData(
    Map<String, String> fields,
    File? file,
    String fileField,
  ) async {
    final formData = FormData.fromMap(fields);
    if (file != null) {
      formData.files.add(MapEntry(
        fileField,
        await MultipartFile.fromFile(file.path),
      ));
    }
    return formData;
  }

  static void _handleError(DioException e) {
    if (e.error?.toString().contains("SSL pinning failed") ?? false) {
      print("❌ SSL pinning failed");
    } else {
      print("🔴 Request failed: ${e.message}");
    }
  }

  // by papri
  static Future<Response?> getImageWithHeaders(
    String endpoint,
    Map<String, String> headers,
  ) async {
    try {
      print("getImageWithHeaders url is ${AppConfig.dynamicBaseUrl}$endpoint");
      print("getImageWithHeaders headers are $headers");
      return await DioClient.dynamic.get(
        endpoint,
        options: Options(
          headers: headers,
          responseType: ResponseType.bytes, // ✅ bytes for image
        ),
      );
    } on DioException catch (e) {
      _handleError(e);
      return null;
    }
  }
}
