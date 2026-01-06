
class AppConfig {
  /// Active flavor (defaults to 'dev' if not passed via --dart-define)
  static final String flavour =
      const String.fromEnvironment('FLAVOR', defaultValue: 'dev');

  /// Base URLs
  static const String unoApiurluat = "https://unoapi.uat.ph.unobank.asia";
  static const String unoApiurlprod = "https://unoapi.prod.ph.unobank.asia";
  static const String unoApiurldev = "http://167.88.160.87";
  // static const String unoApiurldev = "http://192.168.29.239";

  static const String baseUrlUat = "$unoApiurluat/unosales";
  static const String baseUrlProd = "$unoApiurlprod/unosales";
  static const String baseUrlDev = "$unoApiurldev";
  static const String unoBaseUrlUat= "$unoApiurluat";
  static const String unoBaseUrlProd= "$unoApiurlprod";


// Redirection base Url
 // SIT/UAT Redirect URL: https://partneragent.sit.ph.unobank.asia/fsa-aam-auth?token=<<token>>&sales_app=<<applicationId>>
 //PROD Redirect URL: https://partneragent.prod.ph.unobank.asia/fsa-aam-auth?token=<<token>>&sales_app=<<applicationId>>
  static const String baseURlRedirectUat = "https://partneragent.sit.ph.unobank.asia";
  static const String baseURlRedirectProd = "https://partneragent.prod.ph.unobank.asia";
  


  /// Dynamic base URL
  static String get dynamicBaseUrl {
    switch (flavour) {
      case 'uat':
        return baseUrlUat;
      case 'prod':
        return baseUrlProd;
      case 'dev':
      default:
        return baseUrlDev;
    }
  }

  /// OTP URL
  static String get otpUrl {
    switch (flavour) {
      case 'prod':
        return "$unoApiurlprod";
      case 'uat':
        return "$unoApiurluat";
      case 'dev':
        return "$unoApiurluat";
      default:
        return "$unoApiurluat";
    }
  }
 static String certificateChecks = '';


 //  Redirect AAM Url

   static String get aamredictUrl {
    switch (flavour) {
      case 'uat':
        return baseURlRedirectUat;
      case 'prod':
        return baseURlRedirectProd;
      case 'dev':
      default:
        return baseURlRedirectProd;
    }
  }


   static String get unoBaseApiUrl {
    switch (flavour) {
      case 'uat':
        return unoBaseUrlUat;
      case 'prod':
        return unoBaseUrlProd;
      case 'dev':
      default:
        return unoBaseUrlUat;
    }
  }

  // /// Certificate Pinning
  // static const String certificateProd =
  //     "87cbd75a4d733f1e4dce1f8d557c2b6e888e4df4ae601e0a256a37cb64c753cf";
  // static const String certificateUat =
  //     "1964204cb817157cfb522938df5258e615b9c2362131a539a62a89bcb30f1dad";

  // static String? get certificateChecks {
  //   switch (flavour) {
  //     case 'prod':
  //       return certificateProd;
  //     case 'uat':
  //       return certificateUat;
  //     case 'dev':
  //     default:
  //       return certificateUat;
  //   }
  // }

  static bool get isScreenshotDisabled => flavour == 'prod';

  static bool get enableSecurityChecks => isProd;

  static bool get isUat => flavour == 'uat';
  static bool get isProd => flavour == 'prod';
  static bool get isDev => flavour == 'dev';
}
