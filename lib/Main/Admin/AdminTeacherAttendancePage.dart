import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';

class AdminTeacherAttendancePage extends StatefulWidget {
  const AdminTeacherAttendancePage({Key? key}) : super(key: key);

  @override
  _AdminTeacherAttendancePageState createState() =>
      _AdminTeacherAttendancePageState();
}

class _AdminTeacherAttendancePageState
    extends State<AdminTeacherAttendancePage> {
  final DatabaseReference _dbRef =
  FirebaseDatabase.instance.ref("teacherAttendance");

  final DatabaseReference _usersRef =
  FirebaseDatabase.instance.ref("users"); // Teachers are here

  String selectedDate = DateFormat('yyyy-MM-dd').format(DateTime.now());

  Map<String, String> teachers = {}; // teacherId → teacherName
  Map<String, String> attendanceStatus = {}; // teacherId → status

  @override
  void initState() {
    super.initState();
    _loadTeachers();
  }

  /// Load teachers (only role = 2)
  Future<void> _loadTeachers() async {
    final snapshot = await _usersRef.get();
    if (snapshot.exists && snapshot.value != null) {
      final data = snapshot.value as Map<dynamic, dynamic>;
      Map<String, String> loadedTeachers = {};

      data.forEach((key, value) {
        if (value is Map &&
            value.containsKey("role") &&
            value["role"].toString() == "2") {
          loadedTeachers[key.toString()] =
              value["name"]?.toString() ?? "Unknown";
        }
      });

      setState(() {
        teachers = loadedTeachers;
      });

      _loadAttendance(); // load attendance after teachers
    }
  }

  /// Load attendance for selected date
  Future<void> _loadAttendance() async {
    final snapshot = await _dbRef.child(selectedDate).get();
    if (snapshot.exists && snapshot.value != null) {
      final data = snapshot.value as Map<dynamic, dynamic>;
      setState(() {
        attendanceStatus = data.map((key, value) {
          if (value is Map && value.containsKey("status")) {
            return MapEntry(key.toString(), value["status"].toString());
          }
          return MapEntry(key.toString(), "Not Marked");
        });
      });
    } else {
      setState(() {
        attendanceStatus = {};
      });
    }
  }

  /// Mark teacher attendance (Present / Absent / Leave)
  Future<void> _markAttendance(String teacherId, String status) async {
    await _dbRef.child("$selectedDate/$teacherId").set({
      "teacherName": teachers[teacherId],
      "status": status,
    });
    setState(() {
      attendanceStatus[teacherId] = status;
    });
  }

  /// Date picker
  Future<void> _pickDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.parse(selectedDate),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        selectedDate = DateFormat('yyyy-MM-dd').format(picked);
      });
      _loadAttendance();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Teacher Attendance"),
        backgroundColor: Colors.teal,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month),
            onPressed: _pickDate,
          ),
        ],
      ),
      body: teachers.isEmpty
          ? const Center(child: Text("No Teachers Found"))
          : ListView(
        padding: const EdgeInsets.all(12),
        children: teachers.keys.map((teacherId) {
          String teacherName = teachers[teacherId] ?? "  ";
          String status = attendanceStatus[teacherId] ?? "Not Marked";

          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: ListTile(
              title: Text(teacherName),
              subtitle: Text("Status: $status"),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.check_circle,
                        color: Colors.green),
                    tooltip: "Present",
                    onPressed: () =>
                        _markAttendance(teacherId, "Present"),
                  ),
                  IconButton(
                    icon: const Icon(Icons.cancel, color: Colors.red),
                    tooltip: "Absent",
                    onPressed: () =>
                        _markAttendance(teacherId, "Absent"),
                  ),
                  IconButton(
                    icon: const Icon(Icons.beach_access,
                        color: Colors.orange),
                    tooltip: "Leave",
                    onPressed: () =>
                        _markAttendance(teacherId, "Leave"),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
