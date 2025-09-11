import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';

class DiaryPageForStudent extends StatefulWidget {
  const DiaryPageForStudent({Key? key}) : super(key: key);

  @override
  _DiaryPageForStudent createState() => _DiaryPageForStudent();
}

class _DiaryPageForStudent extends State<DiaryPageForStudent> {
  final _db = FirebaseDatabase.instance.ref();
  String? _email;
  Map<String, dynamic>? _studentData;

  DateTime _selectedDate = DateTime.now();

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

  Future<Map<String, dynamic>?> _fetchDiary(String classSection, String date) async {
    final snapshot = await _db.child("homeworkDiary/$classSection/$date").get();
    if (snapshot.exists) {
      return Map<String, dynamic>.from(snapshot.value as Map);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (_studentData == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final classSection = "${_studentData?['class']}${_studentData?['section']}";
    final dateKey = DateFormat("yyyy-MM-dd").format(_selectedDate);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Homework Diary"),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime(2024, 1, 1),
                lastDate: DateTime(2026, 12, 31),
              );
              if (picked != null) {
                setState(() => _selectedDate = picked);
              }
            },
          )
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _fetchDiary(classSection, dateKey),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final diaryData = snapshot.data;

          if (diaryData == null) {
            return const Center(child: Text("No homework for this date"));
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: diaryData.entries.map((entry) {
              final subject = entry.key;
              final details = Map<String, dynamic>.from(entry.value);

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: ListTile(
                  title: Text(subject, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(details["task"] ?? ""),
                  trailing: Text(
                    details["addedBy"] ?? "Unknown",
                    style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
