import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

import '../Admin/timing/SchoolTimingEntry.dart';

class TeacherSchoolTimingPage extends StatefulWidget {
  const TeacherSchoolTimingPage({super.key});

  @override
  State<TeacherSchoolTimingPage> createState() => _TeacherSchoolTimingPageState();
}

class _TeacherSchoolTimingPageState extends State<TeacherSchoolTimingPage> {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref('schoolTime');

  final List<String> allClasses = [
    'P.G',
    'Nursery',
    'Prep',
    ...List.generate(10, (i) => 'Class ${i + 1}')
  ];
  Map<String, SchoolTimingEntry> timings = {};

  @override
  void initState() {
    super.initState();
    _loadTimings();
  }

  void _loadTimings() {
    _dbRef.onValue.listen((event) {
      final data = event.snapshot.value as Map?;
      if (data != null) {
        timings = data.map((key, value) {
          return MapEntry(
              key, SchoolTimingEntry.fromMap(key, Map<String, dynamic>.from(value)));
        });
        setState(() {});
      }
    });
  }

  String _formatClassName(String raw) {
    if (raw == 'pg') return 'P.G';
    if (raw == 'nursery') return 'Nursery';
    if (raw == 'prep') return 'Prep';
    if (raw.startsWith('class')) {
      return 'Class ${raw.replaceAll('class', '')}';
    }
    return raw;
  }

  String _keyFromClassName(String name) {
    if (name == 'P.G') return 'pg';
    if (name == 'Nursery') return 'nursery';
    if (name == 'Prep') return 'prep';
    return name.toLowerCase().replaceAll(' ', '');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("School Timings",
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.teal,
      ),
      body: ListView.builder(
        itemCount: allClasses.length,
        itemBuilder: (context, index) {
          final name = allClasses[index];
          final key = _keyFromClassName(name);
          final timing = timings[key];

          return Card(
            elevation: 3,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: ListTile(
              contentPadding: const EdgeInsets.all(12),
              title: Text(
                name,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                timing == null
                    ? 'Not Set'
                    : '${timing.timeIn} - ${timing.timeOut}',
                style: const TextStyle(fontSize: 15, color: Colors.black87),
              ),
              // 🔹 No edit button here
            ),
          );
        },
      ),
    );
  }
}
