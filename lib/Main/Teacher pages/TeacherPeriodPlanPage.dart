import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class TeacherPeriodPlanPage extends StatefulWidget {
  const TeacherPeriodPlanPage({Key? key}) : super(key: key);

  @override
  State<TeacherPeriodPlanPage> createState() => _TeacherPeriodPlanPageState();
}

class _TeacherPeriodPlanPageState extends State<TeacherPeriodPlanPage> {
  final DatabaseReference _dbRef =
  FirebaseDatabase.instance.ref().child('teacher_period_plans');

  String? teacherName;
  String? teacherUid;

  @override
  void initState() {
    super.initState();
    _fetchTeacherData();
  }

  Future<void> _fetchTeacherData() async {
    teacherUid = FirebaseAuth.instance.currentUser?.uid;

    if (teacherUid == null) return;

    final userSnapshot = await FirebaseDatabase.instance
        .ref()
        .child('users')
        .child(teacherUid!)
        .get();

    if (userSnapshot.exists && userSnapshot.value is Map) {
      final userData = Map<String, dynamic>.from(userSnapshot.value as Map);
      setState(() {
        teacherName = userData['name']?.toString() ?? 'Unknown Teacher';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Period Plan"),
        backgroundColor: Colors.blueAccent,
        centerTitle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
      ),
      body: teacherUid == null
          ? const Center(child: Text("Teacher not logged in"))
          : StreamBuilder(
        stream: _dbRef.onValue,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData ||
              snapshot.data?.snapshot.value == null) {
            return const Center(child: Text("No periods assigned yet."));
          }

          final data = Map<dynamic, dynamic>.from(
              snapshot.data!.snapshot.value as Map);

          // ✅ FIX: filter by teacherUid stored in Firebase
          final teacherPeriods = data.values
              .where((value) =>
          value is Map &&
              value['teacherUid'] != null &&
              value['teacherUid'] == teacherUid)
              .map((value) => Map<String, dynamic>.from(value))
              .toList();

          if (teacherPeriods.isEmpty) {
            return const Center(
                child: Text("No periods assigned to you yet."));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: teacherPeriods.length,
            itemBuilder: (context, index) {
              final period = teacherPeriods[index];
              return Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                elevation: 4,
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: CircleAvatar(
                    backgroundColor: Colors.blueAccent,
                    child: Text(
                      (period['classSection'] ?? '?')
                          .toString()
                          .characters
                          .first
                          .toUpperCase(),
                      style: const TextStyle(
                          color: Colors.white, fontSize: 18),
                    ),
                  ),
                  title: Text(
                    "${period['subjectName'] ?? 'Unknown Subject'} - ${period['classSection'] ?? 'N/A'}",
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text("🕒 ${period['timeSlot'] ?? 'Not set'}"),
                      Text("🏫 Room: ${period['roomNumber'] ?? 'N/A'}"),
                      if ((period['specialNotes'] ?? '')
                          .toString()
                          .isNotEmpty)
                        Text("📝 Notes: ${period['specialNotes']}"),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
