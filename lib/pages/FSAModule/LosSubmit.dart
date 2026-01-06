import 'package:intl/intl.dart';

class LosSubmitService {
  static Future<void> submitLos({
    required dynamic state,         
    required Function(Map<String, dynamic>) postLoanCheck,
  }) async {
    // Turn loading ON
    state.setState(() => state._isLoading = true);

    String CWTransactionID = state.generateSecureTransactionId();

    // Format birthdate
    final parsedDate = DateFormat('dd-MM-yyyy').parse(state.birthDate.text);
    String formattedBirthDate = DateFormat('yyyy-MM-dd').format(parsedDate);

    // Short variable mappings
    String phoneNumber = "63" + state.mobilePhone.text.trim();
    String permZip = state.perm_ZipCode.text.trim();
    String empStatus = state.emp_State.text;
    String empStreet = state.emp_Street.text.trim();
    String montlyIncome = state.fin_Mthly_Income.text;

    Map<String, dynamic> requestData = {
      "CWTransactionID": CWTransactionID,
      "clientDetails": {
        "ARN": "1513411334533400",
        "firstName": state.firstName.text.trim(),
        "lastName": state.lastName.text.trim(),
        "middleName": state.middlename.text.trim(),
        "mobilePhone": phoneNumber,
        "birthDate": formattedBirthDate,
        "gender": state.gender.text.trim(),
        "emailAddress": state.email.text.trim(),
        "ClientIP": state.IpAddress.trim(),
        "addresses": [
          {
            "city": state.perm_City.text.trim(),
            "region": state.perm_Region.text.trim(),
            "postcode": permZip,
            "country": state.nationality.text.trim(),
          }
        ],

        "_Perm_Address": {
          "perm_State": state.perm_State.text.trim(),
          "perm_City": state.perm_City.text.trim(),
          "perm_Street": state.perm_Street.text.trim(),
          "perm_ZipCode": permZip,
          "perm_Barangay": state.perm_Barangay.text.trim(),
          "perm_Region": state.perm_Region.text.trim(),
          "perm_Country": state.nationality.text.trim(),
          "perm_countryCode": state.nationality.text.trim(),
        },

        "_Fin_Details": {
          "fin_Mthly_Income":
              double.tryParse(montlyIncome)?.toInt().toString(),
          "fin_Src_Of_Funds": state.fin_Src_Of_Funds.text.trim(),
          "fin_Src_Of_Funds_Code": state.fin_Src_Of_Funds_Code.text.trim(),
        },

        "_Identification_Details": {
          "identity_TinId": state.identity_TinId.text.trim(),
          "identity_GsisID": state.identity_GsisID.text.trim(),
          "identity_SssID": state.identity_SssID.text.trim(),
        },

        "_Emp_Details": {
          "emp_Work_Nature": state.emp_Work_Nature.text.trim(),
          "emp_Mths_In_Cur_Comp": state.emp_Mths_In_Cur_Comp.text.trim(),
          "emp_Status": state.emp_Status.text.trim(),
          "emp_Employer_Name": state.emp_Employer_Name.text.trim(),
          "emp_Indus_Type": state.emp_Indus_Type.text.trim(),
          "emp_Type": state.emp_Type.text.trim(),
          "emp_Yrs_In_Cur_Comp": state.emp_Yrs_In_Cur_Comp.text.trim(),
          "emp_Type_Code":
              state.emp_Type_Code.text.trim().replaceFirst(RegExp(r'^0+'), ''),
          "emp_Status_Code":
              state.emp_Status_Code.text.trim().replaceFirst(RegExp(r'^0+'), ''),
          "emp_Work_Nature_Code": state.emp_Work_Nature_Code.text
              .trim()
              .replaceFirst(RegExp(r'^0+'), ''),
          "emp_Indus_Type_Code": state.emp_Indus_Type_Code.text
              .trim()
              .replaceFirst(RegExp(r'^0+'), ''),
          "emp_email": state.emp_email.text.trim(),
          "profession": state.profession.text.trim(),
        },

        "_Emp_Address": {
          "emp_Street": empStreet,
          "emp_State": empStatus,
          "emp_City": state.emp_City.text.trim(),
          "emp_Country":
              state.nationality.text.trim().replaceFirst(RegExp(r'^0+'), ''),
          "emp_ZipCode": state.emp_ZipCode.text.trim(),
          "emp_Barangay": state.emp_Barangay.text.trim(),
          "emp_Region": state.emp_Region.text.trim(),
          "emp_countryCode": state.nationality.text.trim(),
        },

        "_Personal_Details": {
          "civil_Status": state.civil_Status.text.trim(),
          "place_Of_Birth": state.place_Of_Birth.text.trim(),
          "nationality": state.nationality.text.trim(),
        },
      },

      "sourcing": {
        "customer": {
          "sourceCompany": "UnoSales",
          "agentCode": state.agentCode.text.trim(),
        },
        "account": {
          "sourceCompany": "UnoSales",
          "agentCode": state.agentCode.text.trim(),
        }
      },

      "partner": {
        "partnerName": "USA FSA",
        "natureOfPartnership": "USA FSA",
        "applicationNumber": CWTransactionID,
        "docURL": {
          "selfieURL": "",
          "idProofURL": "",
        },
      }
    };

  

    /// Turn loading OFF
    state.setState(() => state._isLoading = false);
  }
}
