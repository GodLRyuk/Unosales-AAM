import 'package:unosfa/pages/Form/daily_sales_report.dart';
 // If you need IdType, update path accordingly

class LosApplicationModel {
  String? firstName;
  String? middleName;
  String? lastName;
  String? mobilePhone;
  String? birthDate;
  String? gender;
  String? email;

  String? permState;
  String? permCity;
  String? permStreet;
  String? permZipCode;
  String? permBarangay;
  String? permRegion;
  String? permCountryCode;

  String? finMonthlyIncome;
  String? finSourceOfFunds;
  String? finSourceOfFundsCode;

  String? tinId;
  String? sssId;
  String? gsisId;

  String? empWorkNature;
  String? empMonthsInCompany;
  String? empStatus;
  String? empEmployerName;
  String? empEmployerOtherName; //********************************** */
  


  String? empIndustryType;
  String? empType;
  String? empYearsInCompany;
  String? empTypeCode;
  String? empStatusCode;
  String? empWorkNatureCode;
  String? empIndustryTypeCode;
  String? empEmail;
  String? profession;

  String? empStreet;
  String? empState;
  String? empCity;
  String? empCountry;
  String? empZipCode;
  String? empBarangay;
  String? empRegion;
  String? empCountryCode;

  String? civilStatus;
  String? nationality;
  String? placeOfBirth;

  String? sourceCompany;
  String? agentCode;

  String? partnerName;
  String? natureOfPartnership;
  String? applicationNumber;
  String? cwTransactionID;
  String? empWorkExperience;
  String? empPosition;
  String? clientIp;

  bool? isChecked;
  String? ipAddress;
  String? latitude;
  String? longitude;

  IdType? selectedIdType;
  bool? empStatusFlag;
  String?  dsrId;
  
  // 9.12.2025
  String? issuingAuthority;
  String? address;
  String? documentType;
  String? validUntil;
  String? documentId;

  Map<String, dynamic>? leadDetails;

  LosApplicationModel({
    this.firstName,
    this.middleName,
    this.lastName,
    this.mobilePhone,
    this.birthDate,
    this.gender,
    this.email,
    this.permState,
    this.permCity,
    this.permStreet,
    this.permZipCode,
    this.permBarangay,
    this.permRegion,
    this.permCountryCode,
    this.finMonthlyIncome,
    this.finSourceOfFunds,
    this.finSourceOfFundsCode,
    this.tinId,
    this.sssId,
    this.gsisId,
    this.empWorkNature,
    this.empMonthsInCompany,
    this.empStatus,
    this.empEmployerName,
    this.empEmployerOtherName, //******************************/
    this.empIndustryType,
    this.empType,
    this.empYearsInCompany,
    this.empTypeCode,
    this.empStatusCode,
    this.empWorkNatureCode,
    this.empIndustryTypeCode,
    this.empEmail,
    this.profession,
    this.empStreet,
    this.empState,
    this.empCity,
    this.empCountry,
    this.empZipCode,
    this.empBarangay,
    this.empRegion,
    this.empCountryCode,
    this.civilStatus,
    this.nationality,
    this.placeOfBirth,
    this.sourceCompany,
    this.agentCode,
    this.partnerName,
    this.natureOfPartnership,
    this.applicationNumber,
    this.cwTransactionID,
    this.empWorkExperience,
    this.empPosition,
    this.clientIp,
    this.isChecked,
    this.ipAddress,
    this.latitude,
    this.longitude,
    this.selectedIdType,
    this.empStatusFlag,
    this.leadDetails,
    this.dsrId,

    // 9.12.2025
    this.issuingAuthority,
    this.address,
    this.documentType,
    this.validUntil,
    this.documentId,
  });

  factory LosApplicationModel.fromJson(Map<String, dynamic> json) {
    return LosApplicationModel(
      firstName: json['firstName'],
      middleName: json['middleName'],
      lastName: json['lastName'],
      mobilePhone: json['mobilePhone'],
      birthDate: json['birthDate'],
      gender: json['gender'],
      email: json['email'],
      permState: json['permState'],
      permCity: json['permCity'],
      permStreet: json['permStreet'],
      permZipCode: json['permZipCode'],
      permBarangay: json['permBarangay'],
      permRegion: json['permRegion'],
      permCountryCode: json['permCountryCode'],
      finMonthlyIncome: json['finMonthlyIncome'],
      finSourceOfFunds: json['finSourceOfFunds'],
      finSourceOfFundsCode: json['finSourceOfFundsCode'],
      tinId: json['tinId'],
      sssId: json['sssId'],
      gsisId: json['gsisId'],
      empWorkNature: json['empWorkNature'],
      empMonthsInCompany: json['empMonthsInCompany'],
      empStatus: json['empStatus'],
      empEmployerName: json['empEmployerName'],
      empEmployerOtherName: json['other_employer'], //***************************** */
      empIndustryType: json['empIndustryType'],
      empType: json['empType'],
      empYearsInCompany: json['empYearsInCompany'],
      empTypeCode: json['empTypeCode'],
      empStatusCode: json['empStatusCode'],
      empWorkNatureCode: json['empWorkNatureCode'],
      empIndustryTypeCode: json['empIndustryTypeCode'],
      empEmail: json['empEmail'],
      profession: json['profession'],
      empStreet: json['empStreet'],
      empState: json['empState'],
      empCity: json['empCity'],
      empCountry: json['empCountry'],
      empZipCode: json['empZipCode'],
      empBarangay: json['empBarangay'],
      empRegion: json['empRegion'],
      empCountryCode: json['empCountryCode'],
      civilStatus: json['civilStatus'],
      nationality: json['nationality'],
      placeOfBirth: json['placeOfBirth'],
      sourceCompany: json['sourceCompany'],
      agentCode: json['agentCode'],
      partnerName: json['partnerName'],
      natureOfPartnership: json['natureOfPartnership'],
      applicationNumber: json['applicationNumber'],
      cwTransactionID: json['cwTransactionID'],
      empWorkExperience: json['empWorkExperience'],
      empPosition: json['empPosition'],
      clientIp: json['clientIp'],
      isChecked: json['isChecked'],
      ipAddress: json['ipAddress'],
      latitude: json['latitude'],
      longitude: json['longitude'],
      selectedIdType: json['selectedIdType'] != null
          ? IdType.values[json['selectedIdType']]
          : null,
      empStatusFlag: json['empStatusFlag'],
      leadDetails: json['leadDetails'],
       dsrId: json['dsrId'],

       // 9.12.2025
        issuingAuthority: json['issuingAuthority'],
        address: json['address'],
        documentType: json['documentType'],
        validUntil: json['validUntil'],
        documentId: json['documentId'],


    );
  }

  Map<String, dynamic> toJson() {
    return {
      'firstName': firstName,
      'middleName': middleName,
      'lastName': lastName,
      'mobilePhone': mobilePhone,
      'birthDate': birthDate,
      'gender': gender,
      'email': email,
      'permState': permState,
      'permCity': permCity,
      'permStreet': permStreet,
      'permZipCode': permZipCode,
      'permBarangay': permBarangay,
      'permRegion': permRegion,
      'permCountryCode': permCountryCode,
      'finMonthlyIncome': finMonthlyIncome,
      'finSourceOfFunds': finSourceOfFunds,
      'finSourceOfFundsCode': finSourceOfFundsCode,
      'tinId': tinId,
      'sssId': sssId,
      'gsisId': gsisId,
      'empWorkNature': empWorkNature,
      'empMonthsInCompany': empMonthsInCompany,
      'empStatus': empStatus,
      'empEmployerName': empEmployerName,
      'empEmployerOtherName':  empEmployerOtherName, //************************************* */
      'empIndustryType': empIndustryType,
      'empType': empType,
      'empYearsInCompany': empYearsInCompany,
      'empTypeCode': empTypeCode,
      'empStatusCode': empStatusCode,
      'empWorkNatureCode': empWorkNatureCode,
      'empIndustryTypeCode': empIndustryTypeCode,
      'empEmail': empEmail,
      'profession': profession,
      'empStreet': empStreet,
      'empState': empState,
      'empCity': empCity,
      'empCountry': empCountry,
      'empZipCode': empZipCode,
      'empBarangay': empBarangay,
      'empRegion': empRegion,
      'empCountryCode': empCountryCode,
      'civilStatus': civilStatus,
      'nationality': nationality,
      'placeOfBirth': placeOfBirth,
      'sourceCompany': sourceCompany,
      'agentCode': agentCode,
      'partnerName': partnerName,
      'natureOfPartnership': natureOfPartnership,
      'applicationNumber': applicationNumber,
      'cwTransactionID': cwTransactionID,
      'empWorkExperience': empWorkExperience,
      'empPosition': empPosition,
      'clientIp': clientIp,
      'isChecked': isChecked,
      'ipAddress': ipAddress,
      'latitude': latitude,
      'longitude': longitude,
      'selectedIdType': selectedIdType?.index,
      'empStatusFlag': empStatusFlag,
      'leadDetails': leadDetails,
      'dsrId': dsrId,

      // 9.12.2025
      'issuingAuthority': issuingAuthority,
      'address': address,
      'documentType': documentType,
      'validUntil': validUntil,
      'documentId':documentId,

    };
  }
}
