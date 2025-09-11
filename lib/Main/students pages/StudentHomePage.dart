import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class StudentHomePage extends StatefulWidget {
  const StudentHomePage({Key? key}) : super(key: key);

  @override
  _StudentHomePage createState() => _StudentHomePage();
}

class _StudentHomePage extends State<StudentHomePage> {
  final _db = FirebaseDatabase.instance.ref();
  String? _email;
  Map<String, dynamic>? _studentData;

  @override
  void initState() {
    super.initState();
    _loadStudentData();
  }

  Future<void> _loadStudentData() async {
    _email = FirebaseAuth.instance.currentUser?.email;
    if (_email == null) return;

    final snapshot = await _db.child("users").child(_email!.replaceAll(".", "_")).get();

    if (snapshot.exists) {
      setState(() {
        _studentData = Map<String, dynamic>.from(snapshot.value as Map);
      });
    }
  }

  Widget _buildCard(String title, String subtitle, IconData icon) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, size: 32, color: Colors.blueAccent),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_studentData == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final todayTimetable = _studentData?["timetable"]?["monday"] ?? []; // example
    final attendance = _studentData?["attendance"]?["percentage"] ?? "N/A";
    final homework = _studentData?["homework"]?.entries.first.value ?? "No homework";
    final event = _studentData?["events"]?.entries.first.value ?? "No upcoming event";

    return Scaffold(
      appBar: AppBar(title: const Text("Student Dashboard")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildCard("Today's Timetable", todayTimetable.toString(), Icons.schedule),
            _buildCard("Attendance", "$attendance%", Icons.check_circle),
            _buildCard("Latest Homework", homework.toString(), Icons.book),
            _buildCard("Upcoming Event", event.toString(), Icons.event),
          ],
        ),
      ),
    );
  }
}
