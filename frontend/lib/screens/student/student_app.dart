import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void runStudentApp() {
  runApp(const LeaveApp());
}

const String baseUrl =
    'https://student-leave-request-system.onrender.com/api/leaves';

class LeaveApp extends StatelessWidget {
  const LeaveApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Student Leave Request',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.blue,
        useMaterial3: true,
      ),
      home: const LeaveHome(),
    );
  }
}

class LeaveHome extends StatefulWidget {
  const LeaveHome({super.key});

  @override
  State<LeaveHome> createState() => _LeaveHomeState();
}

class _LeaveHomeState extends State<LeaveHome> {
  final name = TextEditingController();
  final roll = TextEditingController();
  final reason = TextEditingController();

  String branch = 'CSE';
  String? detectedYear;

  DateTime? fromDate;
  DateTime? toDate;

  int page = 0;
  bool loading = false;

  List<dynamic> leaves = [];

  // ------------------------------------------------------------
  // ROLL NUMBER VALIDATION
  // ------------------------------------------------------------

  String? getYearFromRollNumber(String input) {
    final rollNo = input.trim().toUpperCase();

    // Expected basic structure:
    // 25XZ1A0501
    // 24XZ5A0501
    //
    // YY + two characters + 1A/5A + four digits

    final pattern = RegExp(r'^\d{2}[A-Z]{2}[15]A\d{4}$');

    if (!pattern.hasMatch(rollNo)) {
      return null;
    }

    final admissionYear = int.tryParse(rollNo.substring(0, 2));

    if (admissionYear == null) {
      return null;
    }

    String? year;

    switch (admissionYear) {
      case 26:
        year = '1st Year';
        break;

      case 25:
        year = '2nd Year';
        break;

      case 24:
        year = '3rd Year';
        break;

      case 23:
        year = '4th Year';
        break;

      default:
        return null;
    }

    // 5A = lateral entry
    final isLateralEntry = rollNo.substring(4, 6) == '5A';

    if (isLateralEntry) {
      switch (year) {
        case '1st Year':
          year = '2nd Year';
          break;

        case '2nd Year':
          year = '3rd Year';
          break;

        case '3rd Year':
          year = '4th Year';
          break;

        case '4th Year':
          return null;
      }
    }

    return year;
  }

  void validateRollNumber(String value) {
    final result = getYearFromRollNumber(value);

    setState(() {
      detectedYear = result;
    });
  }

  // ------------------------------------------------------------
  // SUBMIT LEAVE
  // ------------------------------------------------------------

  Future<void> submitLeave() async {
    final studentName = name.text.trim();
    final rollNo = roll.text.trim().toUpperCase();
    final leaveReason = reason.text.trim();

    if (studentName.isEmpty ||
        rollNo.isEmpty ||
        leaveReason.isEmpty ||
        fromDate == null ||
        toDate == null) {
      message('Please complete all fields.');
      return;
    }

    final calculatedYear = getYearFromRollNumber(rollNo);

    if (calculatedYear == null) {
      message(
        'Invalid roll number or roll number does not match a valid year.',
      );
      return;
    }

    if (toDate!.isBefore(fromDate!)) {
      message('End date cannot be before start date.');
      return;
    }

    setState(() {
      loading = true;
    });

    try {
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'studentName': studentName,
          'rollNo': rollNo,
          'branch': branch,
          'yearOfStudy': calculatedYear,
          'fromDate': dateString(fromDate!),
          'toDate': dateString(toDate!),
          'reason': leaveReason,
        }),
      );

      if (response.statusCode == 201) {
        message('Leave request submitted!');

        name.clear();
        roll.clear();
        reason.clear();

        setState(() {
          detectedYear = null;
          fromDate = null;
          toDate = null;
        });

        await fetchLeaves();

        setState(() {
          page = 1;
        });
      } else {
        try {
          final data = jsonDecode(response.body);
          message(data['error'] ?? 'Submission failed.');
        } catch (_) {
          message('Submission failed: ${response.body}');
        }
      }
    } catch (e) {
      message('Cannot connect to the backend.');
    } finally {
      setState(() {
        loading = false;
      });
    }
  }

  // ------------------------------------------------------------
  // DATE
  // ------------------------------------------------------------

  String dateString(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> chooseDate(bool isFrom) async {
    final selected = await showDatePicker(
      context: context,
      initialDate: isFrom
          ? (fromDate ?? DateTime.now())
          : (toDate ?? fromDate ?? DateTime.now()),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );

    if (selected != null) {
      setState(() {
        if (isFrom) {
          fromDate = selected;

          if (toDate != null && toDate!.isBefore(selected)) {
            toDate = null;
          }
        } else {
          toDate = selected;
        }
      });
    }
  }

  // ------------------------------------------------------------
  // GET LEAVES
  // ------------------------------------------------------------

  Future<void> fetchLeaves() async {
    try {
      final response = await http.get(Uri.parse(baseUrl));

      if (response.statusCode == 200) {
        setState(() {
          leaves = jsonDecode(response.body);
        });
      }
    } catch (e) {
      message('Could not load leave requests.');
    }
  }

  // ------------------------------------------------------------
  // MESSAGE
  // ------------------------------------------------------------

  void message(String text) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    name.dispose();
    roll.dispose();
    reason.dispose();
    super.dispose();
  }

  // ------------------------------------------------------------
  // DATE BUTTON
  // ------------------------------------------------------------

  Widget dateButton(
    String label,
    DateTime? date,
    VoidCallback onPressed,
  ) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.calendar_month),
      label: Text(
        date == null ? label : dateString(date),
      ),
    );
  }

  // ------------------------------------------------------------
  // APPLICATION FORM
  // ------------------------------------------------------------

  Widget applicationForm() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          'Leave Application',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 20),

        TextField(
          controller: name,
          decoration: const InputDecoration(
            labelText: 'Student Name',
            border: OutlineInputBorder(),
          ),
        ),

        const SizedBox(height: 14),

        TextField(
          controller: roll,
          textCapitalization: TextCapitalization.characters,
          onChanged: validateRollNumber,
          decoration: InputDecoration(
            labelText: 'Roll Number',
            hintText: 'Example: 25XZ1A0501',
            border: const OutlineInputBorder(),
            suffixIcon: detectedYear != null
                ? const Icon(
                    Icons.check_circle,
                    color: Colors.green,
                  )
                : null,
          ),
        ),

        const SizedBox(height: 8),

        if (roll.text.isNotEmpty && detectedYear == null)
          const Text(
            'Enter a valid roll number.',
            style: TextStyle(
              color: Colors.red,
            ),
          ),

        if (detectedYear != null)
          Card(
            child: ListTile(
              leading: const Icon(
                Icons.school,
                color: Colors.blue,
              ),
              title: const Text('Detected Year'),
              subtitle: Text(
                detectedYear!,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

        const SizedBox(height: 14),

        DropdownButtonFormField<String>(
          initialValue: branch,
          decoration: const InputDecoration(
            labelText: 'Branch',
            border: OutlineInputBorder(),
          ),
          items: [
            'CSE',
            'IT',
            'ECE',
            'EEE',
            'MECH',
            'CIVIL',
          ]
              .map(
                (b) => DropdownMenuItem(
                  value: b,
                  child: Text(b),
                ),
              )
              .toList(),
          onChanged: (v) {
            setState(() {
              branch = v!;
            });
          },
        ),

        const SizedBox(height: 14),

        Wrap(
          spacing: 10,
          children: [
            dateButton(
              'From Date',
              fromDate,
              () => chooseDate(true),
            ),
            dateButton(
              'To Date',
              toDate,
              () => chooseDate(false),
            ),
          ],
        ),

        const SizedBox(height: 14),

        TextField(
          controller: reason,
          maxLines: 4,
          decoration: const InputDecoration(
            labelText: 'Reason for Leave',
            border: OutlineInputBorder(),
          ),
        ),

        const SizedBox(height: 20),

        FilledButton(
          onPressed: loading ? null : submitLeave,
          child: Text(
            loading ? 'Submitting...' : 'Submit Request',
          ),
        ),
      ],
    );
  }

  // ------------------------------------------------------------
  // MY REQUESTS
  // ------------------------------------------------------------

  Widget requestsPage() {
    final enteredRoll = roll.text.trim().toUpperCase();

    final visible = enteredRoll.isEmpty
        ? <dynamic>[]
        : leaves.where((a) {
            return a['rollNo']
                    .toString()
                    .toUpperCase() ==
                enteredRoll;
          }).toList();

    return RefreshIndicator(
      onRefresh: fetchLeaves,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'My Leave Requests',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 15),

          TextField(
            controller: roll,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(
              labelText: 'Enter your roll number',
              border: OutlineInputBorder(),
            ),
            onChanged: (_) {
              setState(() {});
            },
          ),

          const SizedBox(height: 15),

          if (visible.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'No leave requests found.',
                ),
              ),
            ),

          ...visible.map(
            (a) {
              final status = a['status'].toString();

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        a['studentName'],
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      Text(
                        'Roll No: ${a['rollNo']}',
                      ),

                      Text(
                        'Branch: ${a['branch']}',
                      ),

                      Text(
                        'Year: ${a['yearOfStudy']}',
                      ),

                      Text(
                        'Dates: ${a['fromDate']} to ${a['toDate']}',
                      ),

                      Text(
                        'Reason: ${a['reason']}',
                      ),

                      const SizedBox(height: 8),

                      Text(
                        'Status: $status',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: status == 'Approved'
                              ? Colors.green
                              : status == 'Rejected'
                                  ? Colors.red
                                  : Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // BUILD
  // ------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Student Leave System',
        ),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: fetchLeaves,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),

      body: IndexedStack(
        index: page,
        children: [
          applicationForm(),
          requestsPage(),
        ],
      ),

      bottomNavigationBar: NavigationBar(
        selectedIndex: page,
        onDestinationSelected: (index) {
          setState(() {
            page = index;
          });

          if (index == 1) {
            fetchLeaves();
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.edit_document),
            label: 'Apply',
          ),
          NavigationDestination(
            icon: Icon(Icons.history),
            label: 'My Requests',
          ),
        ],
      ),
    );
  }
}