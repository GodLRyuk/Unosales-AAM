import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unosfa/pages/FSAModule/todolist.dart';
import 'package:unosfa/pages/Form/FormList/daily_sales_report_list.dart';
import 'package:unosfa/pages/generalscreens/customNavigation.dart';
import 'package:unosfa/pages/services/api_service.dart';

class TodoPage extends StatefulWidget {
  const TodoPage({Key? key}) : super(key: key);

  @override
  State<TodoPage> createState() => _TodoPageState();
}

class _TodoPageState extends State<TodoPage> {
  int selectedDayIndex = 0;
  late List<String> days;
  late List<String> dates;
  late List<DateTime> weekDates;
  bool isLoading = false;
  int dsrCount = 0;
  int assignleadCount = 0;

  DateTime currentWeekStart = DateTime.now();
  DateTime selectedDate = DateTime.now(); // ✅ for current/selected date

  @override
  void initState() {
    super.initState();
    _setCurrentWeekStart();
    _generateWeekDates();
    selectedDate = DateTime.now();
    getAllToDoData();
    getAsignLeadData();
  }

  /// 🔹 Set start of current week (Sunday)
  void _setCurrentWeekStart() {
    DateTime now = DateTime.now();
    int weekday = now.weekday % 7;
    currentWeekStart = now.subtract(Duration(days: weekday));
  }

  /// 🔹 Format date for API (yyyy-MM-dd)
  String _formatDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  /// 🔹 Generate week days/dates
  void _generateWeekDates() {
    weekDates = List.generate(
        7, (index) => currentWeekStart.add(Duration(days: index)));

    days =
        weekDates.map((d) => DateFormat('E').format(d).toUpperCase()).toList();
    dates = weekDates.map((d) => DateFormat('d').format(d)).toList();

    DateTime today = DateTime.now();
    selectedDayIndex = weekDates.indexWhere((date) =>
        DateFormat('yyyy-MM-dd').format(date) ==
        DateFormat('yyyy-MM-dd').format(today));
    if (selectedDayIndex == -1) selectedDayIndex = 0;
  }

  /// 🔸 Previous week
  void _goToPreviousWeek() {
    setState(() {
      currentWeekStart = currentWeekStart.subtract(const Duration(days: 7));
      _generateWeekDates();
    });
  }

  /// 🔸 Next week
  void _goToNextWeek() {
    setState(() {
      currentWeekStart = currentWeekStart.add(const Duration(days: 7));
      _generateWeekDates();
    });
  }

  /// 🔹 Calendar picker
  Future<void> _pickDateFromCalendar() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2023),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        selectedDate = picked;
        currentWeekStart = picked.subtract(Duration(days: picked.weekday % 7));
        _generateWeekDates();
        selectedDayIndex = weekDates.indexWhere(
          (d) =>
              d.day == picked.day &&
              d.month == picked.month &&
              d.year == picked.year,
        );
      });

      await Future.wait([
        getAllToDoData(),
        getAsignLeadData(),
      ]);
    }
  }

  /// 🔹 Daily Sales API
  Future<void> getAllToDoData() async {
    setState(() {
      isLoading = true;
    });
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('accessToken');
    String formattedDate = _formatDate(selectedDate);
    String url =
        "/api/timesheet/agent-daily-sales/?follow_up_date__gte=${formattedDate}T00:00:00&follow_up_date__lte=${formattedDate}T23:59:59";

    final headers = {
      'Authorization': 'Bearer $token',
      'User-Agent':
          'Mozilla/5.0 (Linux; Android 11; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36',
    };
    try {
      final response = await ApiService.getWithHeaders(url, headers);
      if (response != null) {
        final data = response.data;
        setState(() {
          dsrCount = data['count'];
        });
      }
    } catch (e) {
      print('Error fetching DSR: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  /// 🔹 Assigned Leads API
  Future<void> getAsignLeadData() async {
    setState(() {
      isLoading = true;
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('accessToken');
    String formattedDate = _formatDate(selectedDate);
    // String url = "/api/agents/todos/";
    String url =
        "/api/agents/todos/?created_at__gte=${formattedDate}T00:00:00&created_at__lte=${formattedDate}T23:59:59";

    final headers = {
      'Authorization': 'Bearer $token',
      'User-Agent':
          'Mozilla/5.0 (Linux; Android 11; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36',
    };
    try {
      final response = await ApiService.getWithHeaders(url, headers);
      if (response != null && response.statusCode == 200) {
        final data = response.data;
        setState(() {
          assignleadCount = data['count'];
        });
      }
    } catch (e) {
      print('Error fetching leads: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  /// ✅ UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60.0),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFc433e0), Color(0xFF9a37ae)],
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
                const SizedBox(width: 50),
              ],
            ),
            centerTitle: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NavigationPage(),
                  ),
                );
              },
            ),
          ),
        ),
      ),
      backgroundColor: Colors.white,
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Today's Task List",
                      style: TextStyle(
                          color: Colors.black,
                          fontSize: 20,
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 15),

                    // 🔹 Week Navigation
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_left, size: 30),
                          onPressed: _goToPreviousWeek,
                        ),
                        Text(
                          "${DateFormat('MMM dd').format(weekDates.first)} - ${DateFormat('MMM dd, yyyy').format(weekDates.last)}",
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                        IconButton(
                          icon: const Icon(Icons.arrow_right, size: 30),
                          onPressed: _goToNextWeek,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // 🔹 Dynamic Week Dates
                    SizedBox(
                      height: 80,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: days.length,
                        itemBuilder: (context, index) {
                          final isSelected = index == selectedDayIndex;
                          return GestureDetector(
                            onTap: () async {
                              setState(() {
                                selectedDayIndex = index;
                                selectedDate = weekDates[index]; // ✅ important
                                isLoading = true;
                              });

                              await Future.wait([
                                getAllToDoData(),
                                getAsignLeadData(),
                              ]);

                              setState(() {
                                isLoading = false;
                              });
                            },
                            child: Container(
                              margin: const EdgeInsets.only(right: 12),
                              width: 65,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFFac00d0)
                                    : const Color.fromARGB(255, 200, 68, 226),
                                borderRadius: BorderRadius.circular(12),
                                border: isSelected
                                    ? Border.all(color: Colors.white, width: 2)
                                    : null,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    days[index],
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    dates[index],
                                    style: const TextStyle(
                                        color: Colors.white, fontSize: 16),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 20),

                    // 🔹 Task Cards
                    Expanded(
                      child: ListView(
                        children: [
                          GestureDetector(
                            child: _taskCard(
                              title: "Daily Sales Report",
                              status: "Follow Up Leads",
                              statusColor: Colors.white,
                              participants: dsrCount,
                              count: dsrCount,
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => DailySalesReportList(
                                      searchQuery: DateFormat('yyyy-MM-dd')
                                          .format(selectedDate)),
                                ),
                              );
                            },
                          ),
                          GestureDetector(
                            child: _taskCard(
                              title: "Your Assigned Leads",
                              status: "Assigned Leads",
                              statusColor: Colors.white,
                              participants: assignleadCount,
                              count: assignleadCount,
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => TodoListDateWise(
                                    searchQuery: DateFormat('yyyy-MM-dd')
                                        .format(selectedDate),
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  /// 🔹 Task Card Widget
  Widget _taskCard({
    required String title,
    required String status,
    required Color statusColor,
    required int participants,
    required int count,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(
                  "$count",
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                const Text(
                  "Pending",
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ],
            ),
          ),
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
                Row(
                  children: List.generate(
                    min(participants, 10),
                    (index) => Align(
                      widthFactor: 0.6,
                      child: CircleAvatar(
                        radius: 12,
                        backgroundColor:
                            Colors.primaries[index % Colors.primaries.length],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(status,
                style: const TextStyle(color: Colors.black, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}
