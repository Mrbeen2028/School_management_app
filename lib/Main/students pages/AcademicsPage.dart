import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class AcademicsPage extends StatefulWidget {
  const AcademicsPage({Key? key}) : super(key: key);

  @override
  _AcademicsPageState createState() => _AcademicsPageState();
}

class _AcademicsPageState extends State<AcademicsPage> {
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

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_studentData == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final className = _studentData?["class"];
    final section = _studentData?["section"];
    final rollNumber = _studentData?["rollNumber"];

    return Scaffold(
      appBar: AppBar(title: const Text("Academics")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle("Subjects & Timetable"),
            FutureBuilder(
              future: _db.child("timetables/$className$section").get(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const CircularProgressIndicator();
                if (!snapshot.data!.exists) return const Text("No timetable available");

                final timetable = Map<String, dynamic>.from(snapshot.data!.value as Map);
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: timetable.entries.map((day) {
                    return ExpansionTile(
                      title: Text(day.key.toUpperCase()),
                      children: (day.value as List).map((subj) {
                        final subject = subj["subject"];
                        final time = subj["time"];
                        final teacher = subj["teacher"];
                        return ListTile(
                          title: Text(subject),
                          subtitle: Text("$time | $teacher"),
                        );
                      }).toList(),
                    );
                  }).toList(),
                );
              },
            ),
            const Divider(),
            _buildSectionTitle("Results"),
            FutureBuilder(
              future: _db.child("results/$rollNumber").get(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const CircularProgressIndicator();
                if (!snapshot.data!.exists) return const Text("No results yet");

                final results = Map<String, dynamic>.from(snapshot.data!.value as Map);
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: results.entries.map((exam) {
                    final examName = exam.key;
                    final subjects = Map<String, dynamic>.from(exam.value);
                    return ExpansionTile(
                      title: Text(examName.toUpperCase()),
                      children: subjects.entries.map((s) {
                        return ListTile(
                          title: Text("${s.key}"),
                          trailing: Text("${s.value} marks"),
                        );
                      }).toList(),
                    );
                  }).toList(),
                );
              },
            ),
            const Divider(),
            _buildSectionTitle("Performance"),
            FutureBuilder(
              future: _db.child("performance/$rollNumber").get(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const CircularProgressIndicator();
                if (!snapshot.data!.exists) return const Text("No performance data");

                final perf = Map<String, dynamic>.from(snapshot.data!.value as Map);
                return Card(
                  child: ListTile(
                    title: Text("Grade: ${perf["overallGrade"]}"),
                    subtitle: Text("Attendance: ${perf["attendancePercentage"]}%\nRemarks: ${perf["remarks"]}"),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
