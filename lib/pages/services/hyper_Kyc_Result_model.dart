// class HyperKycResult {
//   final HyperKycStatus status;
//   final String transactionId;
//   final HyperKycDetails details;

//   HyperKycResult({
//     required this.status,
//     required this.transactionId,
//     required this.details,
//   });

//   factory HyperKycResult.fromJson(Map<String, dynamic> json) {
//     return HyperKycResult(
//       status: HyperKycStatusValues.map[json['status']] ?? HyperKycStatus.unknown,
//       transactionId: json['transactionId'] ?? '',
//       details: HyperKycDetails.fromJson(json['details'] ?? {}),
//     );
//   }

//   Map<String, dynamic> toJson() {
//     return {
//       'status': HyperKycStatusValues.reverseMap[status],
//       'transactionId': transactionId,
//       'details': details.toJson(),
//     };
//   }
// }

// class HyperKycDetails {
//   final String ocrAddress;
//   final String ocrDateOfBirth;
//   final String ocrPlaceOfBirth;
//   final String ocrDateOfExpiry;
//   final String ocrDateOfIssue;
//   final String ocrDocumentId;
//   final String ocrFirstName;
//   final String ocrFullName;
//   final String ocrGender;
//   final String ocrIdFrontImage;

//   HyperKycDetails({
//     required this.ocrAddress,
//     required this.ocrDateOfBirth,
//     required this.ocrPlaceOfBirth,
//     required this.ocrDateOfExpiry,
//     required this.ocrDateOfIssue,
//     required this.ocrDocumentId,
//     required this.ocrFirstName,
//     required this.ocrFullName,
//     required this.ocrGender,
//     required this.ocrIdFrontImage,
//   });

//   factory HyperKycDetails.fromJson(Map<String, dynamic> json) {
//     return HyperKycDetails(
//       ocrAddress: json['ocr_address'] ?? '',
//       ocrDateOfBirth: json['ocr_dateOfBirth'] ?? '',
//       ocrPlaceOfBirth: json['ocr_placeOfBirth'] ?? '',
//       ocrDateOfExpiry: json['ocr_dateOfExpiry'] ?? '',
//       ocrDateOfIssue: json['ocr_dateOfIssue'] ?? '',
//       ocrDocumentId: json['ocr_documentId'] ?? '',
//       ocrFirstName: json['ocr_firstName'] ?? '',
//       ocrFullName: json['ocr_fullName'] ?? '',
//       ocrGender: json['ocr_gender'] ?? '',
//       ocrIdFrontImage: json['ocr_idFrontImage'] ?? '',
//     );
//   }

//   Map<String, dynamic> toJson() {
//     return {
//       'ocr_address': ocrAddress,
//       'ocr_dateOfBirth': ocrDateOfBirth,
//       'ocr_placeOfBirth': ocrPlaceOfBirth,
//       'ocr_dateOfExpiry': ocrDateOfExpiry,
//       'ocr_dateOfIssue': ocrDateOfIssue,
//       'ocr_documentId': ocrDocumentId,
//       'ocr_firstName': ocrFirstName,
//       'ocr_fullName': ocrFullName,
//       'ocr_gender': ocrGender,
//       'ocr_idFrontImage': ocrIdFrontImage,
//     };
//   }
// }

// enum HyperKycStatus { autoDeclined, approved, pending, unknown }

// class HyperKycStatusValues {
//   static const Map<String, HyperKycStatus> map = {
//     'autoDeclined': HyperKycStatus.autoDeclined,
//     'approved': HyperKycStatus.approved,
//     'pending': HyperKycStatus.pending,
//   };

//   static const Map<HyperKycStatus, String> reverseMap = {
//     HyperKycStatus.autoDeclined: 'autoDeclined',
//     HyperKycStatus.approved: 'approved',
//     HyperKycStatus.pending: 'pending',
//     HyperKycStatus.unknown: 'unknown',
//   };
// }

