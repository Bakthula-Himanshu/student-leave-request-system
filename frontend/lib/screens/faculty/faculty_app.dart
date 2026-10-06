import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void runFacultyApp() {
  runApp(const FacultyApp());
}

const String baseUrl =
    'https://student-leave-request-system.onrender.com/api/leaves';

class FacultyApp extends StatelessWidget {
  const FacultyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Faculty Leave Management',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        useMaterial3: true,
      ),
      home: const FacultyLogin(),
    );
  }
}

// ============================================================
// FACULTY LOGIN
// ============================================================

class FacultyLogin extends StatefulWidget {
  const FacultyLogin({super.key});

  @override
  State<FacultyLogin> createState() => _FacultyLoginState();
}

class _FacultyLoginState extends State<FacultyLogin> {
  final username = TextEditingController();
  final password = TextEditingController();

  bool obscurePassword = true;

  void login() {
    /*
      TEMPORARY PROJECT LOGIN

      Username: faculty
      Password: faculty123

      We will move this to the backend later.
    */

    if (username.text.trim() == 'faculty' &&
        password.text == 'faculty123') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const FacultyDashboard(),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Invalid faculty username or password.',
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    username.dispose();
    password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 450,
          ),
          child: Card(
            margin: const EdgeInsets.all(24),
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.school,
                    size: 60,
                  ),

                  const SizedBox(height: 15),

                  const Text(
                    'Faculty Login',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 25),

                  TextField(
                    controller: username,
                    decoration: const InputDecoration(
                      labelText: 'Username',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                  ),

                  const SizedBox(height: 15),

                  TextField(
                    controller: password,
                    obscureText: obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() {
                            obscurePassword =
                                !obscurePassword;
                          });
                        },
                        icon: Icon(
                          obscurePassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                      ),
                    ),
                    onSubmitted: (_) => login(),
                  ),

                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: login,
                      child: const Text(
                        'Login',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// FACULTY DASHBOARD
// ============================================================

class FacultyDashboard extends StatefulWidget {
  const FacultyDashboard({super.key});

  @override
  State<FacultyDashboard> createState() =>
      _FacultyDashboardState();
}

class _FacultyDashboardState
    extends State<FacultyDashboard> {
  List<dynamic> leaves = [];

  bool loading = true;

  String selectedStatus = 'All';

  int total = 0;
  int pending = 0;
  int approved = 0;
  int rejected = 0;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  // ----------------------------------------------------------
  // LOAD DATA
  // ----------------------------------------------------------

  Future<void> loadData() async {
    await Future.wait([
      fetchLeaves(),
      fetchStats(),
    ]);
  }

  Future<void> fetchLeaves() async {
    try {
      final response = await http.get(
        Uri.parse(baseUrl),
      );

      if (response.statusCode == 200) {
        setState(() {
          leaves = jsonDecode(response.body);
        });
      }
    } catch (e) {
      showMessage(
        'Could not connect to backend.',
      );
    } finally {
      setState(() {
        loading = false;
      });
    }
  }

  // ----------------------------------------------------------
  // STATISTICS
  // ----------------------------------------------------------

  Future<void> fetchStats() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/stats'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        setState(() {
          total = data['total'] ?? 0;
          pending = data['pending'] ?? 0;
          approved = data['approved'] ?? 0;
          rejected = data['rejected'] ?? 0;
        });
      }
    } catch (e) {
      // Statistics failure shouldn't stop the dashboard.
    }
  }

  // ----------------------------------------------------------
  // APPROVE / REJECT
  // ----------------------------------------------------------

  Future<void> updateStatus(
    int id,
    String status,
  ) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/$id/status'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'status': status,
        }),
      );

      if (response.statusCode == 200) {
        showMessage(
          'Request $status.',
        );

        await loadData();
      } else {
        showMessage(
          'Could not update request.',
        );
      }
    } catch (e) {
      showMessage(
        'Backend connection error.',
      );
    }
  }

  // ----------------------------------------------------------
  // MESSAGE
  // ----------------------------------------------------------

  void showMessage(String text) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
      ),
    );
  }

  // ----------------------------------------------------------
  // FILTER
  // ----------------------------------------------------------

  List<dynamic> get filteredLeaves {
    if (selectedStatus == 'All') {
      return leaves;
    }

    return leaves.where((leave) {
      return leave['status'] == selectedStatus;
    }).toList();
  }

  // ----------------------------------------------------------
  // STAT CARD
  // ----------------------------------------------------------

  Widget statCard(
    String title,
    int value,
    IconData icon,
  ) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            children: [
              Icon(
                icon,
                size: 32,
              ),

              const SizedBox(height: 8),

              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                ),
              ),

              const SizedBox(height: 5),

              Text(
                value.toString(),
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ----------------------------------------------------------
  // REQUEST CARD
  // ----------------------------------------------------------

  Widget requestCard(dynamic leave) {
    final status = leave['status'].toString();

    final id = leave['id'] as int;

    return Card(
      margin: const EdgeInsets.only(
        bottom: 12,
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    leave['studentName'],
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                Chip(
                  label: Text(status),
                ),
              ],
            ),

            const SizedBox(height: 8),

            Text(
              'Roll No: ${leave['rollNo']}',
            ),

            Text(
              'Branch: ${leave['branch']}',
            ),

            Text(
              'Year: ${leave['yearOfStudy']}',
            ),

            Text(
              'From: ${leave['fromDate']}',
            ),

            Text(
              'To: ${leave['toDate']}',
            ),

            const SizedBox(height: 5),

            Text(
              'Reason: ${leave['reason']}',
            ),

            if (status == 'Pending') ...[
              const SizedBox(height: 15),

              Row(
                mainAxisAlignment:
                    MainAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    onPressed: () {
                      updateStatus(
                        id,
                        'Rejected',
                      );
                    },
                    icon: const Icon(
                      Icons.close,
                    ),
                    label: const Text(
                      'Reject',
                    ),
                  ),

                  const SizedBox(width: 10),

                  FilledButton.icon(
                    onPressed: () {
                      updateStatus(
                        id,
                        'Approved',
                      );
                    },
                    icon: const Icon(
                      Icons.check,
                    ),
                    label: const Text(
                      'Approve',
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ----------------------------------------------------------
  // BUILD
  // ----------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final visibleLeaves = filteredLeaves;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Faculty Leave Management',
        ),
        actions: [
          IconButton(
            onPressed: loadData,
            icon: const Icon(
              Icons.refresh,
            ),
          ),

          IconButton(
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      const FacultyLogin(),
                ),
              );
            },
            icon: const Icon(
              Icons.logout,
            ),
          ),
        ],
      ),

      body: loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : RefreshIndicator(
              onRefresh: loadData,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  const Text(
                    'Dashboard',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 15),

                  Row(
                    children: [
                      statCard(
                        'Total',
                        total,
                        Icons.list_alt,
                      ),
                      statCard(
                        'Pending',
                        pending,
                        Icons.pending_actions,
                      ),
                      statCard(
                        'Approved',
                        approved,
                        Icons.check_circle,
                      ),
                      statCard(
                        'Rejected',
                        rejected,
                        Icons.cancel,
                      ),
                    ],
                  ),

                  const SizedBox(height: 25),

                  DropdownButtonFormField<String>(
                    initialValue: selectedStatus,
                    decoration:
                        const InputDecoration(
                      labelText: 'Filter by status',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      'All',
                      'Pending',
                      'Approved',
                      'Rejected',
                    ]
                        .map(
                          (status) =>
                              DropdownMenuItem(
                            value: status,
                            child: Text(status),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedStatus = value!;
                      });
                    },
                  ),

                  const SizedBox(height: 20),

                  Text(
                    'Leave Requests (${visibleLeaves.length})',
                    style: const TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 12),

                  if (visibleLeaves.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(25),
                        child: Center(
                          child: Text(
                            'No leave requests found.',
                          ),
                        ),
                      ),
                    ),

                  ...visibleLeaves.map(
                    requestCard,
                  ),
                ],
              ),
            ),
    );
  }
}