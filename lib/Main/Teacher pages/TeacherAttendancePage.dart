import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';

class TeacherAttendancePage extends StatefulWidget {
  final String teacherId;
  final String teacherName;

  const TeacherAttendancePage({
    Key? key,
    required this.teacherId,
    required this.teacherName,
  }) : super(key: key);

  @override
  _TeacherAttendancePageState createState() => _TeacherAttendancePageState();
}

class _TeacherAttendancePageState extends State<TeacherAttendancePage> {
  final DatabaseReference _dbRef =
  FirebaseDatabase.instance.ref("teacherAttendance");

  String selectedDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
  String status = "Not Marked";
  List<Map<String, String>> history = [];

  @override
  void initState() {
    super.initState();
    _listenTodayAttendance();
    _loadHistory();
  }

  /// 🔥 Listen to today's attendance in realtime
  void _listenTodayAttendance() {
    _dbRef.child("$selectedDate/${widget.teacherId}").onValue.listen((event) {
      if (event.snapshot.exists && event.snapshot.value != null) {
        final data = event.snapshot.value as Map<dynamic, dynamic>;
        setState(() {
          status = data["status"]?.toString() ?? "Not Marked";
        });
      } else {
        setState(() {
          status = "Not Marked";
        });
      }
    });
  }

  /// Load full attendance history (one-time fetch)
  Future<void> _loadHistory() async {
    final snapshot = await _dbRef.get();
    List<Map<String, String>> tempHistory = [];

    if (snapshot.exists && snapshot.value != null) {
      Map data = snapshot.value as Map;
      data.forEach((date, teacherAttendance) {
        if (teacherAttendance is Map &&
            teacherAttendance.containsKey(widget.teacherId)) {
          var record = teacherAttendance[widget.teacherId] as Map<dynamic, dynamic>;
          tempHistory.add({
            "date": date.toString(),
            "status": record["status"]?.toString() ?? "Not Marked",
          });
        }
      });

      tempHistory.sort((a, b) => b["date"]!.compareTo(a["date"]!));
    }

    setState(() {
      history = tempHistory;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Attendance"),
        backgroundColor: Colors.teal,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Card(
              margin: const EdgeInsets.all(20),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text("Teacher: ${widget.teacherName}",
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Text("Date: $selectedDate",
                        style: const TextStyle(fontSize: 16)),
                    const SizedBox(height: 20),
                    Text("Status: $status",
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: status == "Present"
                                ? Colors.green
                                : status == "Absent"
                                ? Colors.red
                                : Colors.orange)),
                  ],
                ),
              ),
            ),

            const Padding(
              padding: EdgeInsets.all(12.0),
              child: Text("Attendance History",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            history.isEmpty
                ? const Center(child: Text("No history available"))
                : ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: history.length,
              itemBuilder: (context, index) {
                final record = history[index];
                return ListTile(
                  leading: Icon(
                    record["status"] == "Present"
                        ? Icons.check_circle
                        : record["status"] == "Absent"
                        ? Icons.cancel
                        : Icons.info,
                    color: record["status"] == "Present"
                        ? Colors.green
                        : record["status"] == "Absent"
                        ? Colors.red
                        : Colors.orange,
                  ),
                  title: Text("Date: ${record["date"]}"),
                  subtitle: Text("Status: ${record["status"]}"),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
