/// Domain model placeholder for the leave request API contract.
///
/// The current application implementation remains in the screen files to preserve
/// its working behavior. This file is the intended home for the shared LeaveRequest
/// model during future incremental refactoring.
class LeaveRequestModel {
  const LeaveRequestModel({
    required this.id,
    required this.name,
    required this.rollNo,
    required this.branch,
    required this.year,
    required this.fromDate,
    required this.toDate,
    required this.reason,
    required this.status,
  });

  final int id;
  final String name;
  final String rollNo;
  final String branch;
  final String year;
  final String fromDate;
  final String toDate;
  final String reason;
  final String status;
}
