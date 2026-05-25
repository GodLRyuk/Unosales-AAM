import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:http_certificate_pinning/http_certificate_pinning.dart';
import 'package:pointycastle/api.dart' hide Padding;
import 'package:pointycastle/random/fortuna_random.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unosfa/pages/FSAModule/leadsByCampaign.dart';
import 'package:unosfa/pages/config/config.dart';
import 'package:unosfa/pages/services/api_service.dart';
import 'package:unosfa/widgetSupport/widgetstyle.dart';
import 'package:app_settings/app_settings.dart';
import 'package:crypto/crypto.dart';

class FSACampaignSingleLead extends StatefulWidget {
  final String leadId;
  final String campaign;
  const FSACampaignSingleLead(
      {super.key, required this.leadId, required this.campaign});

  @override
  State<FSACampaignSingleLead> createState() => _FSACampaignSingleLeadState();
}

class _FSACampaignSingleLeadState extends State<FSACampaignSingleLead> {
  final _formKey = GlobalKey<FormState>();
  bool _isEditing = true;
  final idmArnNo = TextEditingController();
  final clientType = TextEditingController();
  final firstName = TextEditingController();
  final lastName = TextEditingController();
  final middleName = TextEditingController();
  final mobilePhone = TextEditingController();
  final birthDate = TextEditingController();
  final gender = TextEditingController();
  final emailAddress = TextEditingController();
  final homePhoneNumber = TextEditingController();
  final branchId = TextEditingController();
  final branchKey = TextEditingController();
  final branch = TextEditingController();
  final ClientIP = TextEditingController();
  final Longitude = TextEditingController();
  final Latitude = TextEditingController();
  final line1 = TextEditingController();
  final line2 = TextEditingController();
  final city = TextEditingController();
  final region = TextEditingController();
  final postcode = TextEditingController();
  final country = TextEditingController();
  final idDocuments = TextEditingController();
  final perm_State = TextEditingController();
  final perm_City = TextEditingController();
  final perm_Street = TextEditingController();
  final perm_Country = TextEditingController();
  final perm_ZipCode = TextEditingController();
  final perm_Barangay = TextEditingController();
  final perm_Region = TextEditingController();
  final perm_countryCode = TextEditingController();
  final hra = TextEditingController();
  final fin_Mthly_Income = TextEditingController();
  final fin_Ownr_Car = TextEditingController();
  final fin_Ann_Income = TextEditingController();
  final fin_Ownr_Home = TextEditingController();
  final fin_Src_Of_Funds = TextEditingController();
  final fin_Src_Of_Funds_Code = TextEditingController();
  final fin_Salary_Period = TextEditingController();
  final fin_Salary_dates = TextEditingController();
  final identity_TinId = TextEditingController();
  final identity_GsisID = TextEditingController();
  final identity_SssID = TextEditingController();
  //Employee Start
  final emp_Work_Nature = TextEditingController();
  final emp_Mths_In_Cur_Comp = TextEditingController();
  final emp_Status = TextEditingController();
  final emp_Employer_Name = TextEditingController();
  final emp_Indus_Type = TextEditingController();
  final emp_Type = TextEditingController();
  final emp_Yrs_In_Cur_Comp = TextEditingController();
  final Office_phone_no = TextEditingController();
  final emp_Type_Code = TextEditingController();
  final emp_Status_Code = TextEditingController();
  final emp_Work_Nature_Code = TextEditingController();
  final emp_Indus_Type_Code = TextEditingController();
  final emp_email = TextEditingController();
  final companyCategorySegment = TextEditingController();
  final profession = TextEditingController();
  final emp_Street = TextEditingController();
  final emp_State = TextEditingController();
  final emp_City = TextEditingController();
  final emp_Country = TextEditingController();
  final emp_ZipCode = TextEditingController();
  final emp_Barangay = TextEditingController();
  final emp_Region = TextEditingController();
  final emp_countryCode = TextEditingController();
  //Employee End
  //Personal_Details Start
  final fatca_Cert_US_Non_US = TextEditingController();
  final fatca_W9_IdNumber = TextEditingController();
  final no_Of_Dependents = TextEditingController();
  final fatca_W9_IdType = TextEditingController();
  final civil_Status = TextEditingController();
  final yrs_In_Residence = TextEditingController();
  final nationality = TextEditingController();
  final marketing_Consent = TextEditingController();
  final mailing_Adrs = TextEditingController();
  final place_Of_Birth = TextEditingController();
  final my_Job = TextEditingController();
  final salutation = TextEditingController();
  final suffix = TextEditingController();
  final nom_Counter = TextEditingController();
  final cust_IdType = TextEditingController();
  final card_Issuance_Status = TextEditingController();
  final my_Job_Code = TextEditingController();
  final vcard_issueDt = TextEditingController();
  final data_Pvcy_Agrmt = TextEditingController();
  final is_Term_Cond_Accepted = TextEditingController();
  final is_Rcds_Edited = TextEditingController();
  final designation = TextEditingController();
  // Spouse_Details
  final spouse_Name = TextEditingController();
  final spouse_Nationality = TextEditingController();
  final spouse_DOB = TextEditingController();
  final spouse_Place_Of_Birth = TextEditingController();
  final spouse_Employment = TextEditingController();
  // Dosri_Check
  final dosriCheck = TextEditingController();
  final dosriName = TextEditingController();
  final dosriRelationship = TextEditingController();
  // rpt_Check
  final rptCheck = TextEditingController();
  final rptName = TextEditingController();
  final rptRelationship = TextEditingController();
  //sourcing customer
  final customerreferralPromoCodeFlag = TextEditingController();
  final customerreferralCode = TextEditingController();
  final customerpromotionalCode = TextEditingController();
  final customersourceCompany = TextEditingController();
  final customeragentCode = TextEditingController();
  //account
  final accountemp_Indus_Type = TextEditingController();
  final accountreferralCode = TextEditingController();
  final accountpromotionalCode = TextEditingController();
  final accountsourceCompany = TextEditingController();
  final accountagentCode = TextEditingController();
  //partner
  final partnerName = TextEditingController();
  final natureOfPartnership = TextEditingController();
  final partnerUserID = TextEditingController();
  final applicationNumber = TextEditingController();
  final expectedMonthlyTransaction = TextEditingController();
  final redirectionURL = TextEditingController();
  //docURL
  final selfieURL = TextEditingController();
  final idProofURL = TextEditingController();
  //partnerScore
  final partnerTelcoScore = TextEditingController();
  final partnerPrefilterScore = TextEditingController();
  final partnerBehaviourScore = TextEditingController();
  final partnerSocialScore = TextEditingController();
  final partnerAdditionalScore1 = TextEditingController();
  final partnerAdditionalScore2 = TextEditingController();
  final partnerAdditionalScore3 = TextEditingController();
  //partnerScreeningStages eKYC
  final emailVerification = TextEditingController();
  final incomeValidation = TextEditingController();
  final addressValidation = TextEditingController();
  final employmentValidation = TextEditingController();
  final referralPromoCodeFlag = TextEditingController();
  final referralCode = TextEditingController();
  final promotionalCode = TextEditingController();
  final sourceCompany = TextEditingController();
  final agentCode = TextEditingController();
  String IpAddress = "";
  String latitude = "";
  String longitude = "";
  bool _isLoading = true;
  bool isExpanded = false;
  List<String>? userInfo;

  Map<String, dynamic> leadDetails = {}; // To store the lead details

  @override
  void initState() {
    getPublicIP();
    super.initState();
    fetchLeadDetails(); // Fetch lead details when the screen is loaded
  }

// No need to change as it is used for fetching public IP
  Future<void> getPublicIP() async {
    final baseUri = Uri.parse('https://api64.ipify.org');

    try {
      final certCheck = await HttpCertificatePinning.check(
        serverURL: baseUri.origin,
        headerHttp: {},
        sha: SHA.SHA256,
        allowedSHAFingerprints: [
          'fdfbedf7bb343480848930c9cd7ed53d1c267fa12f282aedf57fc8cd8d7e5ea7' // ✅ SHA256 for api64.ipify.org
        ],
        timeout: 50,
      );

      if (certCheck == CertificateState.CERTIFICATE_VALID) {
        final response =
            await http.get(Uri.parse('${baseUri.toString()}?format=json'));

        if (response.statusCode == 200) {
          String ip = jsonDecode(response.body)['ip'];
          setState(() {
            IpAddress = ip;
          });
        }
      } else {
        print("❌ SSL Pinning failed. Public IP fetch blocked.");
      }
    } catch (e) {
      print("❌ Exception during SSL pinning or HTTP request: $e");
    }
  }

  // Function to check location access
  Future<void> getCurrentLocation(BuildContext context) async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await _showBlockedDialog(
        context,
        title: "Location Services Disabled",
        message: "Please enable GPS (Location Services) to use this feature.",
        actionText: "Open Settings",
        onAction: () {
          AppSettings.openAppSettings();
        },
      );
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      await _showBlockedDialog(
        context,
        title: "Location Permission Required",
        message:
            "This page needs location permission to work. Please allow it in settings.",
        actionText: "Open App Settings",
        onAction: () {
          AppSettings.openAppSettings();
        },
      );
      return;
    }

    // If permission is granted, continue
    debugPrint("✅ Location permission granted.");
  }

  // Non-dismissible dialog function
  Future<void> _showBlockedDialog(
    BuildContext context, {
    required String title,
    required String message,
    required String actionText,
    required VoidCallback onAction,
  }) async {
    await showDialog(
      context: context,
      barrierDismissible: false, // BLOCK user from closing it
      builder: (_) => WillPopScope(
        // BLOCK back button
        onWillPop: () async => false,
        child: AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: onAction,
              child: Text(actionText),
            ),
          ],
        ),
      ),
    );
  }

  // Function to fetch lead details by ID
  Future<void> fetchLeadDetails() async {
    getCurrentLocation(context);
    // getPublicIP();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('accessToken');
    String? refresh = prefs.getString('refreshToken');
    userInfo = prefs.getStringList('userInfo');
    try {
      String url = "/api/campaigns/${widget.campaign}/leads/${widget.leadId}/";
      final headers = {
        'Authorization': 'Bearer $token',
        'User-Agent':
            'Mozilla/5.0 (Linux; Android 11; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36',
      };
      final response = await ApiService.getWithHeaders(url, headers);
      if (response != null) {
        if (response.statusCode == 200) {
          // Parse the response body as JSON
          setState(() {
            leadDetails = response.data;
            // String jsonString = jsonEncode(leadDetails);
            // for (int i = 0; i < jsonString.length; i += 1000) {
            //   print(jsonString.substring(i,
            //       (i + 1000 > jsonString.length) ? jsonString.length : i + 1000));
            // }
            firstName.text = leadDetails['first_name'] ?? "";
            lastName.text = leadDetails['last_name'] ?? "";
            middleName.text = leadDetails['middle_name'] ?? "";
            mobilePhone.text = leadDetails['mobile_phone'] ?? "";
            birthDate.text = leadDetails['birth_date'] ?? "";
            gender.text = leadDetails['gender'] ?? "";
            emailAddress.text = leadDetails['emp_email'] ?? "";
            homePhoneNumber.text = "";
            branchId.text = "";
            branchKey.text = "";
            branch.text = "";
            ClientIP.text = IpAddress;
            // Address details
            line1.text = leadDetails['perm_street'] ??
                '' + leadDetails['perm_barangay'] ??
                "";
            line2.text = leadDetails['perm_state'] ?? "";
            city.text = leadDetails['perm_city'] ?? "";
            region.text = leadDetails['perm_region'] ?? "";
            postcode.text = leadDetails['perm_zip_code'] ?? "";
            country.text = leadDetails['perm_country'] ?? "";
            // Permanent Address
            perm_State.text = leadDetails['perm_state'] ?? "";
            perm_City.text = leadDetails['perm_city'] ?? "";
            perm_Street.text = leadDetails['perm_street'] ?? "";
            perm_Country.text = leadDetails['perm_country'] ?? "";
            perm_ZipCode.text = leadDetails['perm_zip_code'] ?? "";
            perm_Barangay.text = leadDetails['perm_barangay'] ?? "";
            perm_Region.text = leadDetails['perm_region'] ?? "";
            perm_countryCode.text = leadDetails['perm_country_code'] ?? "";
            hra.text = "";
            // Financial Details
            fin_Mthly_Income.text = leadDetails['fin_monthly_income'] ?? "";
            fin_Ann_Income.text = "";
            fin_Src_Of_Funds.text = leadDetails['fin_src_of_funds'] ?? "";
            fin_Src_Of_Funds_Code.text =
                leadDetails['fin_src_of_funds_code'] ?? "";
            fin_Salary_Period.text = "";
            fin_Salary_dates.text = "";

            // Identification Details
            identity_TinId.text = "";
            identity_GsisID.text = "";
            identity_SssID.text = "";
            // Employment Details
            emp_Work_Nature.text = leadDetails['emp_work_nature_code'] ?? "";
            emp_Mths_In_Cur_Comp.text =
                leadDetails['emp_mths_in_cur_comp'].toString();
            emp_Status.text = leadDetails['emp_status'] ?? "";
            emp_Employer_Name.text = leadDetails['emp_employer_name'] ?? "";
            emp_Indus_Type.text = leadDetails['emp_indus_type'] ?? "";
            emp_Type.text = leadDetails['emp_type'] ?? "";
            emp_Yrs_In_Cur_Comp.text =
                leadDetails['emp_yrs_in_cur_comp']?.toString() ?? "";
            Office_phone_no.text = "";
            emp_email.text = leadDetails['emp_email'] ?? "";
            // Employment Address
            emp_Street.text = leadDetails['emp_street'] ?? "";
            emp_State.text = leadDetails['emp_state'] ?? "";
            emp_City.text = leadDetails['emp_city'] ?? "";
            emp_Country.text = leadDetails['emp_country'] ?? "";
            emp_ZipCode.text = leadDetails['emp_zip_code'] ?? "";
            emp_Barangay.text = leadDetails['emp_barangay'] ?? "";
            emp_Region.text = leadDetails['emp_region'] ?? "";
            emp_countryCode.text = leadDetails['emp_country_code'] ?? "";
            emp_Type_Code.text = leadDetails['emp_type_code'] ?? "";
            emp_Status_Code.text = leadDetails['emp_status_code'] ?? "";
            emp_Work_Nature_Code.text =
                leadDetails['emp_work_nature_code'] ?? "";
            emp_Indus_Type_Code.text = leadDetails['emp_indus_type_code'] ?? "";
            customersourceCompany.text = leadDetails['source_company'] ?? "";
            accountsourceCompany.text = leadDetails['source_company'] ?? "";
            nationality.text = leadDetails['nationality'] ?? "";
            // Personal Details
            fatca_Cert_US_Non_US.text = "";
            no_Of_Dependents.text = "";
            civil_Status.text = leadDetails['civil_status'] ?? "";
            yrs_In_Residence.text = "";
            marketing_Consent.text = "";
            mailing_Adrs.text = "";
            place_Of_Birth.text = leadDetails['place_of_birth'] ?? "";
            my_Job.text = "";
            salutation.text = "";
            designation.text = "";
            // Spouse Details
            spouse_Name.text = "";
            spouse_Nationality.text = "";
            spouse_DOB.text = "";
            spouse_Place_Of_Birth.text = "";
            spouse_Employment.text = "";
            // Sourcing Customer
            referralPromoCodeFlag.text = "";
            promotionalCode.text = "";
            sourceCompany.text = leadDetails['source_company'] ?? "";
            // Partner Details
            partnerName.text = leadDetails['partner_name'] ?? "";
            natureOfPartnership.text =
                leadDetails['nature_of_partnership'] ?? "";
            // applicationNumber.text = applicationNum;
            partnerTelcoScore.text = leadDetails['partner_telco_score'] ?? "";
            emailVerification.text = leadDetails['email_verification'] ?? "";
            incomeValidation.text = leadDetails['income_validation'] ?? "";
            addressValidation.text = leadDetails['address_validation'] ?? "";
            employmentValidation.text =
                leadDetails['employment_validation'] ?? "";
            customeragentCode.text = userInfo![0];
            accountagentCode.text = userInfo![0];
            _isLoading = false; // Data loaded
          });
        } else if (response.statusCode == 401) {
          Map<String, String> mappedData = {
            'refresh': refresh ?? '',
          };
          String url = "/api/users/token-refresh/";
          final response2 = await ApiService.post(url, mappedData);
          if (response2 != null) {
            final data = json.decode(response2.data);
            await prefs.setBool('isLoggedIn', true);
            await prefs.setString('accessToken', data['access']);
            await prefs.setString('refreshToken', data['refresh']);
            fetchLeadDetails();
          }
        } else {
          throw Exception('Failed to load lead details');
        }
      }
    } catch (e) {
      print('Error fetching lead details: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(60.0),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFFc433e0),
                Color(0xFF9a37ae),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('images/logo.PNG', height: 30),
                SizedBox(width: 50),
              ],
            ),
            centerTitle: true,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => LeadListByCampaign(
                      campaign: widget.campaign,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Padding(
                padding: const EdgeInsets.all(0.0),
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : SingleChildScrollView(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 20),
                          key: _formKey,
                          child: Form(
                              child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildTextField(
                                firstName,
                                "First Name",
                                'Please Enter First Name',
                                'firstName',
                                isNumeric: false,
                                isBlankAlphabetic: true,
                                enabled: _isEditing,
                              ),
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.02,
                              ),
                              _buildTextField(
                                middleName,
                                "Middle Name",
                                'Please Enter Middle Name',
                                'middleName',
                                isNumeric: false,
                                isAlphabetic: true,
                                enabled: _isEditing,
                              ),
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.02,
                              ),
                              _buildTextField(
                                lastName,
                                "Last Name",
                                'Please Enter Last Name',
                                'lastName',
                                isNumeric: false,
                                isAlphabetic: true,
                                enabled: _isEditing,
                              ),
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.02,
                              ),
                              _buildTextField(
                                mobilePhone,
                                "(Please put country code e.g. 63XXXXXXXXXX)",
                                'Please Enter Mobile Number',
                                'mobileNumber',
                                isNumeric: true,
                                isPhoneNumber: true,
                                enabled: _isEditing,
                              ),
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.02,
                              ),
                              _buildTextField(
                                gender,
                                "Gender",
                                'Please Enter Gender',
                                'gender',
                                enabled: _isEditing,
                              ),
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.02,
                              ),
                              _buildTextField(
                                emailAddress,
                                "Email Address",
                                'Please Enter Email Address',
                                'emailAddress',
                                isEmail: true,
                                enabled: _isEditing,
                              ),
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.02,
                              ),
                              _buildTextField(
                                homePhoneNumber,
                                "Home Phone Number",
                                'Please Enter Phone Number',
                                'homePhoneNumber',
                                isPhoneNumber: true,
                                enabled: _isEditing,
                              ),
                              _buildTextField(
                                birthDate,
                                "DOB",
                                'Please Enter DOB',
                                'birthDate',
                                enabled: _isEditing,
                              ),
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.02,
                              ),
                              _buildTextField(
                                branchId,
                                "Branch Id",
                                'Please Enter Branch Id',
                                'branchId',
                                enabled: _isEditing,
                              ),
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.02,
                              ),
                              _buildTextField(
                                branchKey,
                                "Branch Key",
                                'Please Enter Branch Key',
                                'branchKey',
                                enabled: _isEditing,
                              ),
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.02,
                              ),
                              _buildTextField(
                                branch,
                                "Branch",
                                'Please Enter Branch',
                                'branch',
                                enabled: _isEditing,
                              ),
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.02,
                              ),
                              _buildTextField(
                                line1,
                                "Address Line 1",
                                'Please Enter Address Line 1',
                                'line1',
                                enabled: _isEditing,
                              ),
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.02,
                              ),
                              _buildTextField(
                                line2,
                                "Address Line 2",
                                'Please Enter Address Line 2',
                                'line2',
                                enabled: _isEditing,
                              ),
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.02,
                              ),
                              _buildTextField(
                                city,
                                "City ",
                                'Please Enter City',
                                'city',
                                enabled: _isEditing,
                              ),
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.02,
                              ),
                              _buildTextField(
                                region,
                                "Region ",
                                'Please Enter Region',
                                'region',
                                enabled: _isEditing,
                              ),
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.02,
                              ),
                              _buildTextField(
                                postcode,
                                "Post Code ",
                                'Please Enter Post Code',
                                'postcode',
                                isNumeric: true,
                                enabled: _isEditing,
                              ),
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.02,
                              ),
                              _buildTextField(
                                country,
                                "Country",
                                'Please Enter Cuntry',
                                'country',
                                enabled: _isEditing,
                              ),
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.02,
                              ),
                              _buildTextField(
                                perm_State,
                                "Permenent State",
                                'Please Enter Permenent State',
                                'perm_State',
                                enabled: _isEditing,
                              ),
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.02,
                              ),
                              _buildTextField(
                                perm_City,
                                "Permenent City",
                                'Please Enter Permenent City',
                                'perm_City',
                                enabled: _isEditing,
                              ),
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.02,
                              ),
                              _buildTextField(
                                perm_Street,
                                "Permenent Street",
                                'Please Enter Permenent Street',
                                'perm_Street',
                                enabled: _isEditing,
                              ),
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.02,
                              ),
                              _buildTextField(
                                perm_Country,
                                "Permenent Country",
                                'Please Enter Permenent Country',
                                'perm_Country',
                                enabled: _isEditing,
                              ),
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.02,
                              ),
                              _buildTextField(
                                perm_ZipCode,
                                "Permenent ZipCode",
                                'Please Enter Permenent ZipCode',
                                'perm_ZipCode',
                                enabled: _isEditing,
                              ),
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.02,
                              ),
                              _buildTextField(
                                perm_Barangay,
                                "Permenent Barangay",
                                'Please Enter Permenent Barangay',
                                'perm_Barangay',
                                enabled: _isEditing,
                              ),
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.02,
                              ),
                              _buildTextField(
                                perm_Region,
                                "Permenent Region",
                                'Please Enter Permenent Region',
                                'perm_Region',
                                enabled: _isEditing,
                              ),
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.02,
                              ),
                              _buildTextField(
                                perm_countryCode,
                                "Permenent Country Code",
                                'Please Enter Permenent Country Code',
                                'perm_countryCode',
                                enabled: _isEditing,
                              ),
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.02,
                              ),
                              _buildTextField(
                                fin_Mthly_Income,
                                "Monthly Income",
                                'Please Enter Monthly Income',
                                'fin_Mthly_Income',
                                isNumeric: true,
                                enabled: _isEditing,
                              ),
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.02,
                              ),
                              _buildTextField(
                                fin_Ownr_Car,
                                "Car Owner",
                                'Please Enter Car Owner',
                                'fin_Ownr_Car',
                                enabled: _isEditing,
                              ),
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.02,
                              ),
                              _buildTextField(
                                fin_Ann_Income,
                                "Annual Income",
                                'Please Enter Annual Income',
                                'fin_Ann_Income',
                                isNumeric: true,
                                enabled: _isEditing,
                              ),
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.02,
                              ),
                              _buildTextField(
                                fin_Ownr_Home,
                                "Home Owner",
                                'Please Enter Home Owner',
                                'fin_Ownr_Home',
                                enabled: _isEditing,
                              ),
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.02,
                              ),
                              _buildTextField(
                                fin_Src_Of_Funds,
                                "Source Of Fund",
                                'Please Enter Source Of Fund',
                                'fin_Src_Of_Funds',
                                enabled: _isEditing,
                              ),
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.02,
                              ),
                              _buildTextField(
                                fin_Src_Of_Funds_Code,
                                "Source Of Fund Code",
                                'Please Enter Source Of Fund Code',
                                'fin_Src_Of_Funds_Code',
                                enabled: _isEditing,
                              ),
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.02,
                              ),
                              _buildTextField(
                                fin_Salary_Period,
                                "Salary Period",
                                'Please Enter Salary Period',
                                'fin_Salary_Period',
                                enabled: _isEditing,
                              ),
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.02,
                              ),
                              _buildTextField(
                                fin_Salary_dates,
                                "Salary Dates",
                                'Please Enter Salary Dates',
                                'fin_Salary_dates',
                                enabled: _isEditing,
                              ),
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.02,
                              ),
                              _buildTextField(
                                identity_TinId,
                                "Identity Tin Id",
                                'Please Enter Identity Tin Id',
                                'identity_TinId',
                                enabled: _isEditing,
                              ),
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.02,
                              ),
                              _buildTextField(
                                identity_GsisID,
                                "Identity Gsis Id",
                                'Please Enter Identity Gsis Id',
                                'identity_GsisID',
                                enabled: _isEditing,
                              ),
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.02,
                              ),
                              _buildTextField(
                                identity_SssID,
                                "Identity Sss Id",
                                'Please Enter Identity Sss Id',
                                'identity_SssID',
                                enabled: _isEditing,
                              ),
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.02,
                              ),
                              _buildTextField(
                                emp_Work_Nature,
                                "Employee Work Nature",
                                'Please Enter Employee Work Nature',
                                'emp_Work_Nature',
                                enabled: _isEditing,
                              ),
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.02,
                              ),
                              _buildTextField(
                                emp_Mths_In_Cur_Comp,
                                "Employee Months In Current Company",
                                'Please Enter Employee Months In Current Company',
                                'emp_Mths_In_Cur_Comp',
                                enabled: _isEditing,
                              ),
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.02,
                              ),
                              _buildTextField(
                                emp_Status,
                                "Employee Status",
                                'Please Enter Employee Status',
                                'emp_Status',
                                enabled: _isEditing,
                              ),
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.02,
                              ),
                              _buildTextField(
                                emp_Employer_Name,
                                "Employee    Name",
                                'Please Enter Employer Name',
                                'emp_Employer_Name',
                                enabled: _isEditing,
                              ),
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.02,
                              ),
                              _buildTextField(
                                emp_Indus_Type,
                                "Employee Industry Type",
                                'Please Enter Industry Type',
                                'emp_Indus_Type',
                                enabled: _isEditing,
                              ),
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.02,
                              ),
                              _buildTextField(
                                emp_Type,
                                "Employee Type",
                                'Please Enter Employee Type',
                                'emp_Type',
                                enabled: _isEditing,
                              ),
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.02,
                              ),
                              _buildTextField(
                                emp_Yrs_In_Cur_Comp,
                                "Employee Years In Current Company",
                                'Please Enter Employee Years In Current Company',
                                'emp_Yrs_In_Cur_Comp',
                                enabled: _isEditing,
                              ),
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.02,
                              ),
                              _buildTextField(
                                Office_phone_no,
                                "Office Phone Number",
                                'Please Enter Office Phone Number',
                                'Office_phone_no',
                                isPhoneNumber: true,
                                enabled: _isEditing,
                              ),
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.02,
                              ),
                              _buildTextField(
                                emp_Type_Code,
                                "Employee Type Code",
                                'Please Enter Employee Type Code',
                                'emp_Type_Code',
                                enabled: _isEditing,
                              ),
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.02,
                              ),
                              _buildTextField(
                                emp_Status_Code,
                                "Employee Status Code",
                                'Please Enter Employee Status Code',
                                'emp_Status_Code',
                                enabled: _isEditing,
                              ),
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.02,
                              ),
                              _buildTextField(
                                emp_Work_Nature_Code,
                                "Employee Work Nature Code",
                                'Please Enter Employee Work Nature Code',
                                'emp_Work_Nature_Code',
                                enabled: _isEditing,
                              ),
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.02,
                              ),
                              _buildTextField(
                                emp_Indus_Type_Code,
                                "Employee Industry Type Code",
                                'Please Enter Employee Industry Type Code',
                                'emp_Indus_Type_Code',
                                enabled: _isEditing,
                              ),
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.02,
                              ),
                              _buildTextField(
                                emp_email,
                                "Employee Email",
                                'Please Enter Employee Email',
                                'emp_email',
                                isEmail: true,
                                enabled: _isEditing,
                              ),
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.02,
                              ),
                              _buildTextField(
                                companyCategorySegment,
                                "Company Category Segment",
                                'Please Enter Company Category Segment',
                                'companyCategorySegment',
                                enabled: _isEditing,
                              ),
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.02,
                              ),
                              _buildTextField(
                                profession,
                                "Profession",
                                'Please Enter Profession',
                                'profession',
                                enabled: _isEditing,
                              ),
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.02,
                              ),
                              _buildTextField(
                                emp_Street,
                                "Employee Street",
                                'Please Enter Employee Street',
                                'emp_Street',
                                enabled: _isEditing,
                              ),
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.02,
                              ),
                              _buildTextField(
                                emp_State,
                                "Employee State",
                                'Please Enter Employee State',
                                'emp_State',
                                enabled: _isEditing,
                              ),
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.02,
                              ),
                              _buildTextField(
                                emp_City,
                                "Employee City",
                                'Please Enter Employee City',
                                'emp_City',
                                enabled: _isEditing,
                              ),
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.02,
                              ),
                              _buildTextField(
                                emp_Country,
                                "Employee Country",
                                'Please Enter Employee Country',
                                'emp_Country',
                                enabled: _isEditing,
                              ),
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.02,
                              ),
                              _buildTextField(
                                emp_ZipCode,
                                "Employee Zip Code",
                                'Please Enter Zip Code',
                                'emp_ZipCode',
                                enabled: _isEditing,
                              ),
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.02,
                              ),
                              _buildTextField(
                                emp_Barangay,
                                "Employee Barangay",
                                'Please Enter Barangay',
                                'emp_Barangay',
                                enabled: _isEditing,
                              ),
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.02,
                              ),
                              _buildTextField(
                                emp_Region,
                                "Employee Region",
                                'Please Enter Region',
                                'emp_Region',
                                enabled: _isEditing,
                              ),
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.02,
                              ),
                              _buildTextField(
                                emp_countryCode,
                                "Employee Country Code",
                                'Please Enter Country Code',
                                'emp_countryCode',
                                enabled: _isEditing,
                              ),
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.02,
                              ),
                              _buildTextField(
                                fatca_Cert_US_Non_US,
                                "Fatca Certificate",
                                'Please Enter Fatca Certificate',
                                'fatca_Cert_US_Non_US',
                                enabled: _isEditing,
                              ),
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.02,
                              ),
                              _buildTextField(
                                fatca_W9_IdNumber,
                                "Fatca Id Number",
                                'Please Enter Fatca Id Number',
                                'fatca_W9_IdNumber',
                                enabled: _isEditing,
                              ),
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.02,
                              ),
                              _buildTextField(
                                no_Of_Dependents,
                                "No Of Dependents",
                                'Please Enter No Of Dependents',
                                'no_Of_Dependents',
                                enabled: _isEditing,
                              ),
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.02,
                              ),
                              _buildTextField(
                                fatca_W9_IdType,
                                "Fatca Id Type",
                                'Please Enter Fatca Id Type',
                                'fatca_W9_IdType',
                                enabled: _isEditing,
                              ),
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.02,
                              ),
                              _buildTextField(
                                civil_Status,
                                "Civil Status",
                                'Please Enter Civil Status',
                                'civil_Status',
                                enabled: _isEditing,
                              ),
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.02,
                              ),
                              _buildTextField(
                                yrs_In_Residence,
                                "Years In Residence",
                                'Please Enter Years In Residence',
                                'yrs_In_Residence',
                                enabled: _isEditing,
                              ),
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.02,
                              ),
                              _buildTextField(
                                nationality,
                                "Nationality",
                                'Please Enter Nationality',
                                'nationality',
                                enabled: _isEditing,
                              ),
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.02,
                              ),
                              _buildTextField(
                                marketing_Consent,
                                "Marketing Consent",
                                'Please Enter Marketing Consent',
                                'marketing_Consent',
                                enabled: _isEditing,
                              ),
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.02,
                              ),
                              _buildTextField(
                                place_Of_Birth,
                                "Place Of Birth",
                                'Please Enter Place Of Birth',
                                'place_Of_Birth',
                                enabled: _isEditing,
                              ),
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.02,
                              ),
                              _buildTextField(
                                my_Job,
                                "Job",
                                'Please Enter Job',
                                'my_Job',
                                enabled: _isEditing,
                              ),
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.02,
                              ),
                              _buildTextField(
                                salutation,
                                "Salutation",
                                'Please Enter Salutation',
                                'salutation',
                                enabled: _isEditing,
                              ),
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.02,
                              ),
                              _buildTextField(
                                suffix,
                                "Suffix",
                                'Please Enter Suffix',
                                'suffix',
                                enabled: _isEditing,
                              ),
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.02,
                              ),
                              _buildTextField(
                                nom_Counter,
                                "Nom Counter",
                                'Please Enter Nom Counter',
                                'nom_Counter',
                                enabled: _isEditing,
                              ),
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.02,
                              ),
                              _buildTextField(
                                cust_IdType,
                                "Customer Id Type",
                                'Please Enter Customer Id Type',
                                'cust_IdType',
                                enabled: _isEditing,
                              ),
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.02,
                              ),
                              _buildTextField(
                                card_Issuance_Status,
                                "Card Issuance Status",
                                'Please Enter Card Issuance Status',
                                'card_Issuance_Status',
                                enabled: _isEditing,
                              ),
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.02,
                              ),
                              _buildTextField(
                                my_Job_Code,
                                "Job Code",
                                'Please Enter Job Code',
                                'my_Job_Code',
                                enabled: _isEditing,
                              ),
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.02,
                              ),
                              _buildTextField(
                                vcard_issueDt,
                                "Visiting Card Issue Date",
                                'Please Enter Visiting Card Issue Date',
                                'vcard_issueDt',
                                enabled: _isEditing,
                              ),
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.02,
                              ),
                              _buildTextField(
                                data_Pvcy_Agrmt,
                                "Data Privacy Agreement",
                                'Please Enter Data Privacy Agreement',
                                'data_Pvcy_Agrmt',
                                enabled: _isEditing,
                              ),
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.02,
                              ),
                              _buildTextField(
                                is_Term_Cond_Accepted,
                                "Terms & Condition Accepted",
                                'Please Enter Terms & Condition Accepted',
                                'is_Term_Cond_Accepted',
                                enabled: _isEditing,
                              ),
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.02,
                              ),
                              _buildTextField(
                                is_Rcds_Edited,
                                "Rcds Edited",
                                'Please Enter Rcds Edited',
                                'is_Rcds_Edited',
                                enabled: _isEditing,
                              ),
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.02,
                              ),
                              _buildTextField(
                                designation,
                                "Designation",
                                'Please Enter Designation',
                                'designation',
                                enabled: _isEditing,
                              ),
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.02,
                              ),
                              _buildTextField(
                                spouse_Name,
                                "Spouse Name",
                                'Please Enter Spouse Name',
                                'spouse_Name',
                                enabled: _isEditing,
                              ),
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.02,
                              ),
                              _buildTextField(
                                spouse_Nationality,
                                "Spouse Nationality",
                                'Please Enter Spouse Nationality',
                                'spouse_Nationality',
                                enabled: _isEditing,
                              ),
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.02,
                              ),
                              _buildTextField(
                                spouse_DOB,
                                "Spouse DOB",
                                'Please Enter Spouse DOB',
                                'spouse_DOB',
                                enabled: _isEditing,
                              ),
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.02,
                              ),
                              _buildTextField(
                                spouse_Place_Of_Birth,
                                "Spouse Place Of Birth",
                                'Please Enter Spouse Place Of Birth',
                                'spouse_Place_Of_Birth',
                                enabled: _isEditing,
                              ),
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.02,
                              ),
                              _buildTextField(
                                spouse_Employment,
                                "Spouse Employment",
                                'Please Enter Spouse Employment',
                                'spouse_Employment',
                                enabled: _isEditing,
                              ),
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.02,
                              ),
                              _buildTextField(
                                dosriCheck,
                                "Dosri Check",
                                'Please Enter Dosri Check',
                                'dosriCheck',
                                enabled: _isEditing,
                              ),
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.02,
                              ),
                              _buildTextField(
                                dosriName,
                                "Dosri Name",
                                'Please Enter Dosri Name',
                                'dosriName',
                                enabled: _isEditing,
                              ),
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.02,
                              ),
                              _buildTextField(
                                dosriRelationship,
                                "Dosri Relationship",
                                'Please Enter Dosri Relationship',
                                'dosriRelationship',
                                enabled: _isEditing,
                              ),
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.02,
                              ),
                              _buildTextField(
                                rptCheck,
                                "RPT Check",
                                'Please Enter RPT Check',
                                'rptCheck',
                                enabled: _isEditing,
                              ),
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.02,
                              ),
                              _buildTextField(
                                rptName,
                                "RPT Name",
                                'Please Enter RPT Name',
                                'rptName',
                                enabled: _isEditing,
                              ),
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.02,
                              ),
                              _buildTextField(
                                rptRelationship,
                                "RPT Relationship",
                                'Please Enter RPT Relationship',
                                'rptRelationship',
                                enabled: _isEditing,
                              ),
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.02,
                              ),
                              _buildTextField(
                                customerreferralPromoCodeFlag,
                                "Customer Referral PromoCode",
                                'Please Enter Customer Referral PromoCode',
                                'customerreferralCode',
                                enabled: _isEditing,
                              ),
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.02,
                              ),
                              _buildTextField(
                                customerreferralCode,
                                "Customer Referral Code",
                                'Please Enter Customer Referral Code',
                                'customerreferralCode',
                                enabled: _isEditing,
                              ),
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.02,
                              ),
                              _buildTextField(
                                customerpromotionalCode,
                                "Customer Promotional Code",
                                'Please Enter Customer Promotional Code',
                                'customerpromotionalCode',
                                enabled: _isEditing,
                              ),
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.02,
                              ),
                              _buildTextField(
                                customersourceCompany,
                                "Customer Source Company",
                                'Please Enter Customer Source Company',
                                'customersourceCompany',
                                enabled: _isEditing,
                              ),
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.02,
                              ),
                              _buildTextField(
                                customeragentCode,
                                "Customer Agent Code",
                                'Please Enter Customer Agent Code',
                                'customeragentCode',
                                enabled: _isEditing,
                              ),
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.02,
                              ),
                              _buildTextField(
                                accountpromotionalCode,
                                "Account Promo Code",
                                'Please Enter Customer Promo Code',
                                'accountpromotionalCode',
                                enabled: _isEditing,
                              ),
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.02,
                              ),
                              _buildTextField(
                                accountreferralCode,
                                "Account Referral Code",
                                'Please Enter Account Promo Code',
                                'accountreferralCode',
                                enabled: _isEditing,
                              ),
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.02,
                              ),
                              _buildTextField(
                                accountsourceCompany,
                                "Account Source Company",
                                'Please Enter Account Source Company',
                                'accountsourceCompany',
                                enabled: _isEditing,
                              ),
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.02,
                              ),
                              _buildTextField(
                                accountagentCode,
                                "Agent Code",
                                'Please Enter Agent Code',
                                'accountagentCode',
                                enabled: _isEditing,
                              ),
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.02,
                              ),
                              _buildTextField(
                                partnerName,
                                "Partner Name",
                                'Please Enter Partner Name',
                                'partnerName',
                                enabled: _isEditing,
                              ),
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.02,
                              ),
                              _buildTextField(
                                natureOfPartnership,
                                "Nature Of Partnership",
                                'Please Enter Nature Of Partnership',
                                'natureOfPartnership',
                                enabled: _isEditing,
                              ),
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.02,
                              ),
                              _buildTextField(
                                partnerUserID,
                                "Partner User ID",
                                'Please Enter Partner User ID',
                                'partnerUserID',
                                enabled: _isEditing,
                              ),
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.02,
                              ),
                              _buildTextField(
                                applicationNumber,
                                "Application Number",
                                'Please Enter Application Numbera',
                                'applicationNumber',
                                enabled: _isEditing,
                              ),
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.02,
                              ),
                              _buildTextField(
                                expectedMonthlyTransaction,
                                "Expected Monthly Transaction",
                                'Please Enter Expected Monthly Transaction',
                                'expectedMonthlyTransaction',
                                enabled: _isEditing,
                              ),
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.02,
                              ),
                              _buildTextField(
                                redirectionURL,
                                "Redirection URL",
                                'Please Enter Redirection URL',
                                'redirectionURL',
                                enabled: _isEditing,
                              ),
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.02,
                              ),
                              _buildTextField(
                                selfieURL,
                                "Selfie URL",
                                'Please Enter Selfie URL',
                                'selfieURL',
                                enabled: _isEditing,
                              ),
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.02,
                              ),
                              _buildTextField(
                                idProofURL,
                                "Id Proof URL",
                                'Please Enter Id Proof URL',
                                'idProofURL',
                                enabled: _isEditing,
                              ),
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.02,
                              ),
                              _buildTextField(
                                partnerTelcoScore,
                                "Partner Telco Score",
                                'Please Enter Partner Telco Score',
                                'partnerTelcoScore',
                                enabled: _isEditing,
                              ),
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.02,
                              ),
                              _buildTextField(
                                partnerPrefilterScore,
                                "Partner Prefilter Score",
                                'Please Enter Partner Prefilter Scoree',
                                'partnerPrefilterScore',
                                enabled: _isEditing,
                              ),
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.02,
                              ),
                              _buildTextField(
                                partnerBehaviourScore,
                                "Partner Behaviour Score",
                                'Please Enter Partner Behaviour Score',
                                'partnerBehaviourScore',
                                enabled: _isEditing,
                              ),
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.02,
                              ),
                              _buildTextField(
                                partnerSocialScore,
                                "Partner Social Score",
                                'Please Enter Partner Social Score',
                                'partnerSocialScore',
                                enabled: _isEditing,
                              ),
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.02,
                              ),
                              _buildTextField(
                                partnerAdditionalScore1,
                                "Partner Additional Score 1",
                                'Please Enter Partner Additional Score 1',
                                'partnerAdditionalScore1',
                                enabled: _isEditing,
                              ),
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.02,
                              ),
                              _buildTextField(
                                partnerAdditionalScore2,
                                "Partner Additional Score 2",
                                'Please Enter Partner Additional Score 2',
                                'partnerAdditionalScore2',
                                enabled: _isEditing,
                              ),
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.02,
                              ),
                              _buildTextField(
                                partnerAdditionalScore3,
                                "Partner Additional Score 3",
                                'Please Enter Partner Additional Score 3',
                                'partnerAdditionalScore3',
                                enabled: _isEditing,
                              ),
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.02,
                              ),
                              _buildTextField(
                                emailVerification,
                                "Email Verification",
                                'Please Enter Email Verification',
                                'emailVerification',
                                enabled: _isEditing,
                              ),
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.02,
                              ),
                              _buildTextField(
                                incomeValidation,
                                "Income Verification",
                                'Please Enter Income Verification',
                                'incomeValidation',
                                enabled: _isEditing,
                              ),
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.02,
                              ),
                              _buildTextField(
                                addressValidation,
                                "Address Verification",
                                'Please Enter Address Verification',
                                'addressValidation',
                                enabled: _isEditing,
                              ),
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.02,
                              ),
                              _buildTextField(
                                employmentValidation,
                                "Employment Verification",
                                'Please Enter Employment Verification',
                                'employmentValidation',
                                enabled: _isEditing,
                              ),
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.02,
                              ),
                            ],
                          )),
                        ),
                      )),
          ),
          ElevatedButton.icon(
            onPressed: () {
              submitLos();
            },
            icon: Icon(Icons.rocket_launch, color: Colors.white),
            label: Text(
              "SUBMIT",
              style: TextStyle(color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF6e0386),
              padding: EdgeInsets.symmetric(horizontal: 70, vertical: 10),
            ),
          ),
          SizedBox(
            height: 5,
          )
        ],
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String hintText,
    String validationMessage,
    String validationKey, {
    bool obscureText = false,
    bool isEmail = false,
    bool isPhoneNumber = false,
    bool isNumeric = false,
    bool isZipNumber = false,
    bool enabled = true,
    bool nameMax = false,
    bool allowSpaces = false,
    bool isBlankAlphabetic = false,
    bool isAlphabetic = false,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      enabled: enabled,
      keyboardType: isPhoneNumber
          ? TextInputType.phone
          : isEmail
              ? TextInputType.emailAddress
              : isNumeric || isZipNumber
                  ? TextInputType.number
                  : TextInputType.text,
      inputFormatters: isPhoneNumber
          ? [
              if (nameMax) LengthLimitingTextInputFormatter(20),
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(12),
              if (isAlphabetic)
                FilteringTextInputFormatter.allow(
                  allowSpaces
                      ? RegExp(r'^[a-zA-Z\s]+$') // Allow alphabets and spaces
                      : RegExp(
                          r'^[a-zA-Z]+$'), // Allow alphabets only (no spaces)
                ),
            ]
          : null,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: WidgetSupport.inputLabel(),
      ),
      style: TextStyle(color: Colors.black),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return validationMessage;
        }
        if (isEmail && value.isNotEmpty) {
          final emailRegex = RegExp(
              r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'); // Valid email format
          if (!emailRegex.hasMatch(value)) {
            return 'Please enter a valid email address';
          }
        }

        if (value.length != 12) {
          return 'Phone number must be exactly 12 digits';
        }
        if (!RegExp(r'^\d+$').hasMatch(value)) {
          return 'Phone number must contain only digits';
        }
        if (!value.startsWith('63')) {
          return 'Phone number must start with "63"';
        }
        if (isBlankAlphabetic && value.isNotEmpty) {
          if (!RegExp(r'^[a-zA-Z]*$').hasMatch(value)) {
            return 'Only alphabets are allowed';
          }
        }
        // Add other validations as needed
        return null;
      },
    );
  }

  FortunaRandom createSecureFortunaRandomFromEntropy(String entropySource) {
    final secureRandom = FortunaRandom();
    final entropy = sha256.convert(utf8.encode(entropySource)).bytes;
    secureRandom.seed(KeyParameter(Uint8List.fromList(entropy)));
    return secureRandom;
  }

  String generateSecureTransactionId({int length = 7}) {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final entropyInput = timestamp + 'UnoSecureEntropy'; // Custom string
    final secureRandom = createSecureFortunaRandomFromEntropy(entropyInput);

    final digits = List.generate(length, (_) {
      final byte = secureRandom.nextUint8();
      return (byte % 10).toString();
    }).join();

    return '$timestamp$digits';
  }

  void submitLos() {
    String CWTransactionID = generateSecureTransactionId();

    Map<String, dynamic> requestData = {
      "CWTransactionID": CWTransactionID,
      "clientDetails": {
        "ARN": "723561430000",
        "idmArnNo": idmArnNo.text.trim(),
        "clientType": clientType.text.trim(),
        "firstName":
            firstName.text.trim().isNotEmpty ? firstName.text.trim() : null,
        "lastName": lastName.text.trim(),
        "middleName": middleName.text.trim(),
        "mobilePhone": mobilePhone.text.trim(),
        "birthDate": birthDate.text.trim(),
        "gender": gender.text.trim(),
        "emailAddress": emailAddress.text.trim(),
        "homePhoneNumber": homePhoneNumber.text.trim(),
        "branchId": branchId.text.trim(),
        "branchKey": branchKey.text.trim(),
        "branch": branch.text.trim(),
        "ClientIP": ClientIP.text.trim(),
        "Longitude": Longitude.text.trim(),
        "Latitude": Latitude.text.trim(),
        "addresses": [
          {
            "line1": line1.text.trim(),
            "line2": line2.text.trim(),
            "city": city.text.trim(),
            "region": region.text.trim(),
            "postcode": postcode.text.trim(),
            "country": country.text.trim()
          }
        ],
        "idDocuments": null,
        "_Perm_Address": {
          "perm_State": perm_State.text.trim(),
          "perm_City": perm_City.text.trim(),
          "perm_Street": perm_Street.text.trim(),
          "perm_Country": perm_Country.text.trim(),
          "perm_ZipCode": perm_ZipCode.text.trim(),
          "perm_Barangay": perm_Barangay.text.trim(),
          "perm_Region": perm_Region.text.trim(),
          "perm_countryCode": perm_countryCode.text.trim(),
          "hra": hra.text.trim()
        },
        "_Fin_Details": {
          "fin_Mthly_Income": int.tryParse(fin_Mthly_Income.text) ?? 0,
          "fin_Ownr_Car": "",
          "fin_Ann_Income": fin_Ann_Income.text.trim(),
          "fin_Ownr_Home": "",
          "fin_Src_Of_Funds": fin_Src_Of_Funds.text.trim(),
          "fin_Src_Of_Funds_Code": fin_Src_Of_Funds_Code.text.trim(),
          "fin_Salary_Period": fin_Salary_Period.text.trim(),
          "fin_Salary_dates": fin_Salary_dates.text.trim(),
        },
        "_Identification_Details": {
          "identity_TinId": identity_TinId.text.trim(),
          "identity_GsisID": identity_GsisID.text.trim(),
          "identity_SssID": identity_SssID.text.trim()
        },
        "_Emp_Details": {
          "emp_Work_Nature": emp_Work_Nature.text.trim(),
          "emp_Mths_In_Cur_Comp": emp_Mths_In_Cur_Comp.text.trim(),
          "emp_Status": emp_Status.text.trim(),
          "emp_Employer_Name": emp_Employer_Name.text.trim(),
          "emp_Indus_Type": emp_Indus_Type.text.trim(),
          "emp_Type": emp_Type.text.trim(),
          "emp_Yrs_In_Cur_Comp": emp_Yrs_In_Cur_Comp.text.trim(),
          "Office_phone_no": Office_phone_no.text.trim(),
          "emp_Type_Code": emp_Type_Code.text.trim(),
          "emp_Status_Code": emp_Status_Code.text.trim(),
          "emp_Work_Nature_Code": emp_Work_Nature_Code.text.trim(),
          "emp_Indus_Type_Code": emp_Indus_Type_Code.text.trim(),
          "emp_email": emp_email.text.trim(),
          "companyCategorySegment": companyCategorySegment.text.trim(),
          "profession": profession.text.trim()
        },
        "_Emp_Address": {
          "emp_Street": emp_Street.text.trim(),
          "emp_State": emp_State.text.trim(),
          "emp_City": emp_City.text.trim(),
          "emp_Country": emp_Country.text.trim(),
          "emp_ZipCode": emp_ZipCode.text.trim(),
          "emp_Barangay": emp_Barangay.text.trim(),
          "emp_Region": emp_Region.text.trim(),
          "emp_countryCode": emp_countryCode.text.trim()
        },
        "_Personal_Details": {
          "fatca_Cert_US_Non_US": fatca_Cert_US_Non_US.text.trim(),
          "fatca_W9_IdNumber": fatca_W9_IdNumber.text.trim(),
          "no_Of_Dependents": int.tryParse(no_Of_Dependents.text) ?? 0,
          "fatca_W9_IdType": fatca_W9_IdType.text.trim(),
          "civil_Status": civil_Status.text.trim(),
          "yrs_In_Residence": yrs_In_Residence.text.trim(),
          "nationality": nationality.text.trim(),
          "marketing_Consent": marketing_Consent.text.trim(),
          "mailing_Adrs": mailing_Adrs.text.trim(),
          "place_Of_Birth": place_Of_Birth.text.trim(),
          "my_Job": my_Job.text.trim(),
          "suffix": suffix.text.trim(),
          "nom_Counter": nom_Counter.text.trim(),
          "cust_IdType": cust_IdType.text.trim(),
          "card_Issuance_Status": card_Issuance_Status.text.trim(),
          "my_Job_Code": my_Job_Code.text.trim(),
          "vcard_issueDt": vcard_issueDt.text.trim(),
          "data_Pvcy_Agrmt": data_Pvcy_Agrmt.text.trim(),
          "is_Term_Cond_Accepted": is_Term_Cond_Accepted.text.trim(),
          "is_Rcds_Edited": is_Rcds_Edited.text.trim(),
          "designation": designation.text.trim(),
        },
        "_Spouse_Details": {
          "spouse_Name": spouse_Name.text.trim(),
          "spouse_Nationality": spouse_Nationality.text.trim(),
          "spouse_DOB": spouse_DOB.text.trim(),
          "spouse_Place_Of_Birth": spouse_Place_Of_Birth.text.trim(),
          "spouse_Employment": spouse_Employment.text.trim(),
        },
        "dosri_Check": {
          "dosriCheck": dosriCheck.text.trim(),
          "dosriName": dosriName.text.trim(),
          "dosriRelationship": dosriRelationship.text.trim(),
        },
        "rpt_Check": {
          "rptCheck": rptCheck.text.trim(),
          "rptName": rptName.text.trim(),
          "rptRelationship": rptRelationship.text.trim(),
        }
      },
      "sourcing": {
        "customer": {
          "referralPromoCodeFlag": customerreferralPromoCodeFlag.text.trim(),
          "referralCode": customerreferralCode.text.trim(),
          "promotionalCode": customerpromotionalCode.text.trim(),
          "sourceCompany": customersourceCompany.text.trim(),
          "agentCode": customeragentCode.text.trim(),
        },
        "account": {
          "referralPromoCodeFlag": referralPromoCodeFlag.text.trim(),
          "referralCode": accountreferralCode.text.trim(),
          "promotionalCode": accountpromotionalCode.text.trim(),
          "sourceCompany": accountsourceCompany.text.trim(),
          "agentCode": accountagentCode.text.trim(),
        }
      },
      "partner": {
        "partnerName": partnerName.text.trim(),
        "natureOfPartnership": natureOfPartnership.text.trim(),
        "partnerUserID": partnerUserID.text.trim(),
        "applicationNumber": applicationNumber.text.trim(),
        "expectedMonthlyTransaction": expectedMonthlyTransaction.text.trim(),
        "redirectionURL": "N",
        "docURL": {
          "selfieURL": "",
          "idProofURL": "",
        },
        "partnerScore": {
          "partnerTelcoScore": partnerTelcoScore.text.trim(),
          "partnerPrefilterScore": partnerPrefilterScore.text.trim(),
          "partnerBehaviourScore": partnerBehaviourScore.text.trim(),
          "partnerSocialScore": partnerSocialScore.text.trim(),
          "partnerAdditionalScore1": partnerAdditionalScore1.text.trim(),
          "partnerAdditionalScore2": partnerAdditionalScore2.text.trim(),
          "partnerAdditionalScore3": partnerAdditionalScore3.text.trim(),
        },
        "partnerScreeningStages": {
          "eKYC": {
            "emailVerification": emailVerification.text.trim(),
            "incomeValidation": incomeValidation.text.trim(),
            "addressValidation": addressValidation.text.trim(),
            "employmentValidation": employmentValidation.text.trim(),
          }
        }
      }
    };

    postLoanCheck(requestData);
  }

  Future<void> postLoanCheck(Map<String, dynamic> requestData) async {
    // String jsonString = jsonEncode(requestData);
    //       for (int i = 0; i < jsonString.length; i += 1000) {
    //         print(jsonString.substring(i,
    //             (i + 1000 > jsonString.length) ? jsonString.length : i + 1000));
    //       }
    setState(() {
      _isLoading = true;
    });
    String tokens = "";
    try {
      // final Tokenresponse = await http.get(tokenUrl);
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('accessToken');
      String url = "/api/leads/los-access-token/";
      final headers = {
        'Authorization': 'Bearer $token',
        //'User-Agent':
        //  'Mozilla/5.0 (Linux; Android 11; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36',
      };
      final Tokenresponse = await ApiService.getWithHeaders(url, headers);
      if (Tokenresponse != null) {
        final data = json.decode(Tokenresponse.data);
        tokens = data['access_token'];
      }
    } catch (e) {
      print("HTTP Request Failed: $e");
    }
    final url = "/partner/loans/check";

    final headers = {
      "Idempotency-Key": "th37per9-185d-4e22-83fb-18gf96g0g861",
      "Content-Type": "application/json",
      "Accept": "application/json",
      "Authorization": "Bearer $tokens",
      'User-Agent':
          'Mozilla/5.0 (Linux; Android 11; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36',
    };

    try {
      final response =
          await ApiService.postWithHeadersUnoApi(url, requestData, headers);
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('accessToken');
      if (response != null) {
        if (response.statusCode == 201) {
          String url1 =
              "/api/campaigns/${widget.campaign}/leads/${widget.leadId}/";
          final headers2 = {
            "Content-Type": "application/json",
            "Accept": "application/json",
            "Authorization": "Bearer $token",
            'User-Agent':
                'Mozilla/5.0 (Linux; Android 11; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36',
          };
          final LosStatusUrl = await ApiService.getWithHeaders(url1, headers2);

          Map<String, String> mappedLOsData = {
            "cwtransection_id": "${requestData['CWTransactionID']}",
            "los_status": "submitted"
          };
          // ignore: unused_local_variable
          final responseLOS = await ApiService.patchWithHeaders(
              LosStatusUrl as String, headers2, mappedLOsData);

          final LoSResponcedata = response.data;

          //LOS Application Status Check
          Map<String, dynamic> mappedData = {
            "mobileNo": "",
            "agentCode": "",
            "applicationNo": "${LoSResponcedata['applicationNumber']}",
            "channel": "",
            "source": ""
          };
          final url = "/api/app/fetch/application/status";

          final headers = {
            'Content-Type': 'application/json',
            "Idempotency-Key": "jbkjdbjkjk",
            "Authorization": "Bearer $tokens",
            'User-Agent':
                'Mozilla/5.0 (Linux; Android 11; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36',
          };
          try {
            // Show loading dialog
            showDialog(
              context: context,
              barrierDismissible:
                  false, // Prevents dismissing the dialog by tapping outside
              builder: (BuildContext context) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              },
            );

            // Make the API call
            final Statusresponse = await ApiService.postWithHeadersUnoApi(
                url, mappedData, headers);

            // Close the loading dialog
            Navigator.of(context).pop();
            if (Statusresponse != null) {
              if (Statusresponse.statusCode == 200) {
                final data = json.decode(Statusresponse.data);
                var result = data['result'];

                if (result != null && result.isNotEmpty) {
                  var application = result[0]; // Access the first application

                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Text("Application Status"),
                        content: Text(
                          "Offer Status: ${application['offerStatus']}\nUnderWriting Status: ${application['uwStatus']}",
                        ),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => LeadListByCampaign(
                                    campaign: widget.campaign,
                                  ),
                                ),
                              );
                            },
                            child: Text("OK"),
                          ),
                        ],
                      );
                    },
                  );
                }
              }
            }
          } catch (e) {
            Navigator.of(context)
                .pop(); // Ensure the loader is closed if an error occurs
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Something went wrong: $e')),
            );
          }
        } else {
          SharedPreferences prefs = await SharedPreferences.getInstance();
          String? authToken = prefs.getString('accessToken');
          Map<String, dynamic> logmappedData = {
            "url": "${AppConfig.unoApiurluat}/partner/loans/check",
            "request_body": requestData,
            "status_code": response.statusCode,
            "response_body": json.decode(response.data),
          };
          final logUrl = "/api/logs/";

          final headers = {
            "Content-Type": "application/json",
            "Accept": "application/json",
            "Authorization": "Bearer $authToken",
            'User-Agent':
                'Mozilla/5.0 (Linux; Android 11; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36',
          };
          final LogResponse = await ApiService.postJsonWithHeaders(
              logUrl, logmappedData, headers);
          if (LogResponse != null) {
            if (LogResponse.statusCode == 201) {
              print("Log Created");
            }
            final data = response.data;

            // Extracting the message
            String message = data['message'] ?? "Validation Error";

            // Extracting and formatting the errors
            Map<String, dynamic> errors = data['errors'] ?? {};
            String errorMessages = errors.entries
                .map((entry) => "${entry.value}")
                .join("\n"); // Joins all errors with a new line

            // Show the AlertDialog
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: Text("Error"),
                  content: Text("$message\n\n$errorMessages"),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: Text("OK"),
                    ),
                  ],
                );
              },
            );
          }
        }
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print("HTTP Request Failed: $e");

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("Error"),
            content: Text("An error occurred. Please try again."),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text("OK"),
              ),
            ],
          );
        },
      );

      setState(() {
        _isLoading = false;
      });
    }
  }
}
