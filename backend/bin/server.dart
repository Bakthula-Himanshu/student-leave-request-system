import 'dart:convert';
import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';
import 'package:sqlite3/sqlite3.dart';

late Database db;

// ------------------------------------------------------------
// JSON RESPONSE
// ------------------------------------------------------------

Response jsonResponse(
  Object data, {
  int status = 200,
}) {
  return Response(
    status,
    body: jsonEncode(data),
    headers: {
      'Content-Type': 'application/json',
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Headers': 'Content-Type',
      'Access-Control-Allow-Methods': 'GET, POST, PUT, OPTIONS',
    },
  );
}

// ------------------------------------------------------------
// ROLL NUMBER → YEAR
// ------------------------------------------------------------

String? getYearFromRollNumber(String input) {
  final rollNo = input.trim().toUpperCase();

  final pattern = RegExp(
    r'^\d{2}[A-Z]{2}[15]A\d{4}$',
  );

  if (!pattern.hasMatch(rollNo)) {
    return null;
  }

  final admissionYear =
      int.tryParse(rollNo.substring(0, 2));

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
  final isLateralEntry =
      rollNo.substring(4, 6) == '5A';

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

// ------------------------------------------------------------
// CREATE TABLE
// ------------------------------------------------------------

void createDatabase() {
  db.execute('''
    CREATE TABLE IF NOT EXISTS leave_requests (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      student_name TEXT NOT NULL,
      roll_no TEXT NOT NULL,
      branch TEXT NOT NULL,
      year_of_study TEXT NOT NULL,
      from_date TEXT NOT NULL,
      to_date TEXT NOT NULL,
      reason TEXT NOT NULL,
      status TEXT NOT NULL DEFAULT 'Pending'
    )
  ''');
}

// ------------------------------------------------------------
// SUBMIT LEAVE
// ------------------------------------------------------------

Future<Response> submitLeave(
  Request request,
) async {
  try {
    final data =
        jsonDecode(await request.readAsString());

    final name =
        data['studentName']?.toString().trim() ?? '';

    final roll =
        data['rollNo']?.toString().trim().toUpperCase() ??
            '';

    final branch =
        data['branch']?.toString().trim() ?? '';

    final from =
        data['fromDate']?.toString() ?? '';

    final to =
        data['toDate']?.toString() ?? '';

    final reason =
        data['reason']?.toString().trim() ?? '';

    if (name.isEmpty ||
        roll.isEmpty ||
        branch.isEmpty ||
        from.isEmpty ||
        to.isEmpty ||
        reason.isEmpty) {
      return jsonResponse(
        {
          'error': 'All fields are required',
        },
        status: 400,
      );
    }

    // Calculate year from roll number.
    final calculatedYear =
        getYearFromRollNumber(roll);

    if (calculatedYear == null) {
      return jsonResponse(
        {
          'error':
              'Invalid roll number or invalid year for this roll number',
        },
        status: 400,
      );
    }

    final startDate = DateTime.tryParse(from);
    final endDate = DateTime.tryParse(to);

    if (startDate == null ||
        endDate == null ||
        endDate.isBefore(startDate)) {
      return jsonResponse(
        {
          'error': 'Invalid leave dates',
        },
        status: 400,
      );
    }

    db.execute(
      '''
      INSERT INTO leave_requests
      (
        student_name,
        roll_no,
        branch,
        year_of_study,
        from_date,
        to_date,
        reason
      )
      VALUES (?, ?, ?, ?, ?, ?, ?)
      ''',
      [
        name,
        roll,
        branch,
        calculatedYear,
        from,
        to,
        reason,
      ],
    );

    final id = db.lastInsertRowId;

    return jsonResponse(
      {
        'message': 'Leave request submitted',
        'id': id,
        'status': 'Pending',
        'yearOfStudy': calculatedYear,
      },
      status: 201,
    );
  } catch (e) {
    print('Submit error: $e');

    return jsonResponse(
      {
        'error': 'Could not submit request',
      },
      status: 500,
    );
  }
}

// ------------------------------------------------------------
// GET LEAVES
// ------------------------------------------------------------

Future<Response> getLeaves(
  Request request,
) async {
  try {
    final roll =
        request.url.queryParameters['rollNo'];

    late ResultSet results;

    if (roll != null && roll.isNotEmpty) {
      results = db.select(
        '''
        SELECT *
        FROM leave_requests
        WHERE roll_no = ?
        ORDER BY id DESC
        ''',
        [roll.trim().toUpperCase()],
      );
    } else {
      results = db.select(
        '''
        SELECT *
        FROM leave_requests
        ORDER BY id DESC
        ''',
      );
    }

    final leaves = results.map(
      (row) {
        return {
          'id': row['id'],
          'studentName': row['student_name'],
          'rollNo': row['roll_no'],
          'branch': row['branch'],
          'yearOfStudy': row['year_of_study'],
          'fromDate': row['from_date'].toString(),
          'toDate': row['to_date'].toString(),
          'reason': row['reason'],
          'status': row['status'],
        };
      },
    ).toList();

    return jsonResponse(leaves);
  } catch (e) {
    print('Fetch error: $e');

    return jsonResponse(
      {
        'error': 'Could not fetch requests',
      },
      status: 500,
    );
  }
}

// ------------------------------------------------------------
// UPDATE STATUS
// ------------------------------------------------------------

Future<Response> updateStatus(
  Request request,
  String id,
) async {
  try {
    final data =
        jsonDecode(await request.readAsString());

    final status =
        data['status']?.toString();

    if (status != 'Approved' &&
        status != 'Rejected') {
      return jsonResponse(
        {
          'error': 'Invalid status',
        },
        status: 400,
      );
    }

    final requestId = int.tryParse(id);

    if (requestId == null) {
      return jsonResponse(
        {
          'error': 'Invalid request ID',
        },
        status: 400,
      );
    }

    db.execute(
      '''
      UPDATE leave_requests
      SET status = ?
      WHERE id = ?
      ''',
      [
        status,
        requestId,
      ],
    );

    if (db.updatedRows == 0) {
      return jsonResponse(
        {
          'error': 'Request not found',
        },
        status: 404,
      );
    }

    return jsonResponse(
      {
        'message': 'Status updated',
        'status': status,
      },
    );
  } catch (e) {
    print('Status update error: $e');

    return jsonResponse(
      {
        'error': 'Could not update status',
      },
      status: 500,
    );
  }
}

// ------------------------------------------------------------
// STATISTICS
// ------------------------------------------------------------

Future<Response> getStats(
  Request request,
) async {
  try {
    final results = db.select('''
      SELECT
        COUNT(*) AS total,
        SUM(
          CASE
            WHEN status = 'Pending' THEN 1
            ELSE 0
          END
        ) AS pending,
        SUM(
          CASE
            WHEN status = 'Approved' THEN 1
            ELSE 0
          END
        ) AS approved,
        SUM(
          CASE
            WHEN status = 'Rejected' THEN 1
            ELSE 0
          END
        ) AS rejected
      FROM leave_requests
    ''');

    final row = results.first;

    return jsonResponse({
      'total': row['total'] ?? 0,
      'pending': row['pending'] ?? 0,
      'approved': row['approved'] ?? 0,
      'rejected': row['rejected'] ?? 0,
    });
  } catch (e) {
    print('Stats error: $e');

    return jsonResponse(
      {
        'error': 'Could not fetch statistics',
      },
      status: 500,
    );
  }
}

// ------------------------------------------------------------
// MAIN
// ------------------------------------------------------------

void main() async {
  db = sqlite3.open('student_leave.db');

  createDatabase();

  print('SQLite database ready.');

  final router = Router();

  router.post(
    '/api/leaves',
    submitLeave,
  );

  router.get(
    '/api/leaves',
    getLeaves,
  );

  router.put(
    '/api/leaves/<id>/status',
    updateStatus,
  );

  router.get(
    '/api/leaves/stats',
    getStats,
  );

  final handler = Pipeline()
      .addMiddleware(logRequests())
      .addHandler(
    (request) {
      if (request.method == 'OPTIONS') {
        return Response.ok(
          '',
          headers: {
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Headers':
                'Content-Type',
            'Access-Control-Allow-Methods':
                'GET, POST, PUT, OPTIONS',
          },
        );
      }

      return router(request);
    },
  );

  final port = int.parse(Platform.environment['PORT'] ?? '8080');

final server = await shelf_io.serve(
  handler,
  InternetAddress.anyIPv4,
  port,
);
  
  print(
    'Dart backend running at http://localhost:${server.port}',
  );
}
