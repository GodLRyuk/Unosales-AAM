//New design for download excel

//import 'dart:math';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
//import 'package:flutter_html/flutter_html.dart';
import 'package:unosfa/pages/Report/save_pdf.dart';
import 'package:unosfa/widgetSupport/widgetstyle.dart';

class FormReport extends StatefulWidget {
  const FormReport({super.key});

  @override
  State<FormReport> createState() => _FormReportState();
}

class _FormReportState extends State<FormReport> {
  final _searchFilter = TextEditingController();
  TextEditingController fromDate = TextEditingController();
  TextEditingController toDate = TextEditingController();
  final subText = TextEditingController();
  //final TextEditingController dropdownController = TextEditingController();

  bool _isLoading = false;
  String formatDateForApi(String input) {
    final parts = input.split('/');
    return "${parts[2]}-${parts[1].padLeft(2, '0')}-${parts[0].padLeft(2, '0')}";
  }

  String? mainValue;
  final List<String> mainItems = [
    'Agency',
    'Supervisor',
    'Team',
    //'Mob'
  ];

  Widget _buildfromDateField(
      TextEditingController controller, String labelText) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      decoration: InputDecoration(
        labelText: "From Date",
        hintText: labelText,
        hintStyle: WidgetSupport.inputLabel(),
        suffixIcon: const FaIcon(
          FontAwesomeIcons.calendar, // ✅ calendar icon here
          color: Colors.purple,
          size: 18,
        ),
      ),
      onTap: () async {
        FocusScope.of(context).requestFocus(FocusNode());
        DateTime? pickedDate = await showDatePicker(
          context: context,
          initialDate: DateTime(2025),
          firstDate: DateTime(1500),
          lastDate: DateTime.now(),
        );
        if (pickedDate != null) {
          setState(() {
            controller.text =
                "${pickedDate.day}/${pickedDate.month}/${pickedDate.year}";
          });
        }
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'From Date is required';
        }
        return null;
      },
    );
  }

  // For To Date
  Widget _buildtoDateField(TextEditingController controller, String labelText) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      decoration: InputDecoration(
        labelText: "To Date",
        hintText: labelText,
        hintStyle: WidgetSupport.inputLabel(),
        suffixIcon: const FaIcon(
          FontAwesomeIcons.calendar, // ✅ calendar icon here
          color: Colors.purple,
          size: 18,
        ),
      ),
      onTap: () async {
        FocusScope.of(context).requestFocus(FocusNode());
        DateTime? pickedDate = await showDatePicker(
          context: context,
          initialDate: DateTime(2025),
          firstDate: DateTime(1500),
          lastDate: DateTime.now(),
        );
        if (pickedDate != null) {
          setState(() {
            controller.text =
                "${pickedDate.day}/${pickedDate.month}/${pickedDate.year}";
          });
        }
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'To Date is required';
        }
        return null;
      },
    );
  }

  void _handleDownload() async {
    if (fromDate.text.isEmpty || toDate.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            backgroundColor: Color(0xFFc433e0),
            content: Text(
              "Please select both dates",
              style: TextStyle(fontSize: 16),
            )),
      );
      return;
    }

    // Newly Added
    if (selectedDayIndex != 0) {
      if (mainValue == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Color(0xFFc433e0),
            content:
                Text("Please select Category", style: TextStyle(fontSize: 16)),
          ),
        );
        return;
      }

      if (subText.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Color(0xFFc433e0),
            content:
                Text("Please write subfield", style: TextStyle(fontSize: 16)),
          ),
        );
        return;
      }

// if (subText.text[0] != subText.text[0].toUpperCase()) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         backgroundColor: Color(0xFFc433e0),
//         content: Text("First letter must be capital", style: TextStyle(fontSize: 16)),
//       ),
//     );
//     return;
//   }
    }
    // Done

    setState(() => _isLoading = true);

    await ExcelService.downloadExcel(
        context,
        formatDateForApi(fromDate.text),
        formatDateForApi(toDate.text),
        // mainValue!,
        mainValue ?? '',
        subText.text);

    setState(() => _isLoading = false);
    // For clear form
    //   fromDate.clear();
    //   toDate.clear();
    //  // mainValue = null;
    //   subText.clear();
  }

  int selectedDayIndex = 0;
  int dsrCount = 0;
  int assignleadCount = 0;

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
                  Image.asset(
                    'images/logo.PNG',
                    height: 30,
                  ),
                  SizedBox(width: 50),
                ],
              ),
              centerTitle: true,
              leading: IconButton(
                icon: Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () {
                  Navigator.pop(context);

                  // Navigator.pushReplacement(context,
                  //     MaterialPageRoute(builder: (context) => Fsadashboard()));
                },
              ),
            ),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(
                  top: 10.0,
                ),
                child: SizedBox(
                  height: 80,
                  //width: 90,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: 3, // box
                    itemBuilder: (context, index) {
                      final isSelected = index == selectedDayIndex;
                      final List<String> labels = [
                        "Supervisor",
                        "Agents Hourly",
                        "Agent Funnel"
                      ];
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedDayIndex = index;
                            print("selectedDayIndex is $selectedDayIndex");
                          });
                        },
                        child: Container(
                          margin: EdgeInsets.only(
                            right: MediaQuery.of(context).size.width * 0.045,
                          ),
                          width: 120,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFFac00d0)
                                : const Color.fromARGB(255, 200, 68, 226),
                            borderRadius: BorderRadius.circular(12),
                            border: isSelected
                                ? Border.all(color: Colors.white, width: 2)
                                : null,
                          ),
                          child: Center(
                            child: Text(
                              labels[index],
                              textAlign: TextAlign.center,
                              style:
                                  TextStyle(color: Colors.white, fontSize: 14),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

              // Select Date

              //const SizedBox(height: 30,),
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.04,
              ),

              Row(children: [
                Expanded(child: _buildfromDateField(fromDate, "From date")),
                SizedBox(
                  width: 30,
                ),
                Expanded(child: _buildtoDateField(toDate, "To date")),
              ]),

              // Drop drown list
              if (selectedDayIndex != 0) ...[
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.05,
                ),
                Container(
                  child: Column(
                    children: [
                      DropdownButtonFormField2<String>(
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          labelText: "Select",
                        ),
                        isExpanded: true,
                        items: mainItems.map((item) {
                          return DropdownMenuItem(
                            value: item,
                            child: Text(item),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            mainValue = value;
                            print(mainValue);
                          });
                        },
                        dropdownStyleData: DropdownStyleData(
                          maxHeight: 300,
                          offset: const Offset(0, 4),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Text Field
                      _buildTextField(
                        subText,
                        "Sub Category",
                        '',
                        'Sub Category',
                      ),
                    ],
                  ),
                ),
              ],

              SizedBox(
                height: MediaQuery.of(context).size.height * 0.05,
              ),

              // Task Cards
              Expanded(
                child: ListView(
                  children: [
                    _taskCard(
                      title: "Daily Sales Report",
                      status: "Download Excel Sheet",
                      statusColor: Colors.white,
                      //participants: dsrCount,
                      // count: dsrCount,
                      onStatusTap: () async {
                        // showDialog(
                        //   context: context,
                        //   barrierDismissible: false,
                        //   builder: (context) =>
                        //   const Center(
                        //     child: CircularProgressIndicator(),
                        //   ),
                        // );
                        print("No date is select");

                        _handleDownload();

                        //Navigator.of(context).pop();
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ));
  }

  // for Text feild
  Widget _buildTextField(
    TextEditingController controller,
    String hintText,
    String validationMessage,
    String validationKey, {
    bool obscureText = false,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: WidgetSupport.inputLabel(),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return '$hintText is required';
        }
        return null;
      },
    );
  }

  //Task Card Widget
  Widget _taskCard({
    required String title,
    required String status,
    required Color statusColor,
    //required int participants,
    //required int count,

    // New add
    VoidCallback? onStatusTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(
        bottom: 16,
      ),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color.fromARGB(255, 50, 91, 228),
            Color.fromARGB(255, 40, 70, 160)
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                // Row(
                //   children: List.generate(
                //     min(participants, 10),
                //     (index) => Align(
                //       widthFactor: 0.6,
                //       child: CircleAvatar(
                //         radius: 12,
                //         backgroundColor:
                //             Colors.primaries[index % Colors.primaries.length],
                //       ),
                //     ),
                //   ),
                // ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onStatusTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: statusColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(status,
                  style: const TextStyle(color: Colors.black, fontSize: 12)),
            ),
          ),
        ],
      ),
    );
  }
}
