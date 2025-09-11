import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Attendanceby extends StatefulWidget {
  final String role; // "admin" or "teacher"
  final String userName; // teacher/admin name
  final String userUid;  // unique id of logged in user (admin/teacher)

  const Attendanceby({
    super.key,
    required this.role,
    required this.userName,
    required this.userUid,
  });

  @override
  State<Attendanceby> createState() => _AttendancebyState();
}

class _AttendancebyState extends State<Attendanceby> {
  final DatabaseReference _dbRef =
  FirebaseDatabase.instance.ref().child('users');

  String? selectedClass;
  String? selectedSection;
  List<String> sections = [];
  List<Map<String, dynamic>> filteredStudents = [];
  Map<String, Map<String, dynamic>> attendance = {};
  bool isLoading = false;

  final List<String> classes = [
    'PG', 'Nursery', 'KG', '1', '2', '3', '4', '5',
    '6', '7', '8', '9', '10'
  ];

  DateTime selectedDate = DateTime.now();

  String get formattedDate =>
      "${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}";

  void _loadSectionsForClass(String className) async {
    setState(() {
      isLoading = true;
      selectedSection = null;
      filteredStudents = [];
      sections = [];
    });

    final snapshot = await _dbRef.once();
    final data = snapshot.snapshot.value as Map?;

    if (data != null) {
      Set<String> sectionSet = {};

      data.forEach((key, value) {
        final student = Map<String, dynamic>.from(value);
        if (student['role'] == 'student' &&
            (student['class']?.toString().toLowerCase() ?? '') ==
                className.toLowerCase()) {
          sectionSet.add(student['section'] ?? 'A');
        }
      });

      setState(() {
        selectedClass = className;
        sections = sectionSet.toList()..sort();
        isLoading = false;
      });
    }
  }

  void _loadStudentsByClassAndSection(String className, String sectionName) async {
    setState(() {
      isLoading = true;
    });

    final snapshot = await _dbRef.once();
    final data = snapshot.snapshot.value as Map?;

    if (data != null) {
      List<Map<String, dynamic>> students = [];

      data.forEach((key, value) {
        final student = Map<String, dynamic>.from(value);
        if (student['role'] == 'student' &&
            (student['class']?.toString().toLowerCase() ?? '') ==
                className.toLowerCase() &&
            (student['section']?.toString().toLowerCase() ?? '') ==
                sectionName.toLowerCase()) {
          students.add(student);
        }
      });

      setState(() {
        filteredStudents = students;
        attendance = {
          for (var s in students)
            '${s['rollNumber'] ?? s['name']}_${s['name']}': {
              'status': 'absent',
              'createdBy': widget.userName,
              'createdByUid': widget.userUid,
              'role': widget.role,
            },
        };
        isLoading = false;
      });

      _loadPreviousAttendance();
    } else {
      setState(() {
        filteredStudents = [];
        isLoading = false;
      });
    }
  }

  void _loadPreviousAttendance() async {
    if (selectedClass == null || selectedSection == null) return;

    final snapshot = await FirebaseDatabase.instance
        .ref()
        .child('attendance')
        .child(formattedDate)
        .child(selectedClass!)
        .child(selectedSection!)
        .once();

    final data = snapshot.snapshot.value as Map?;

    if (data != null) {
      setState(() {
        data.forEach((key, value) {
          attendance[key] = {
            'status': value['status'],
            'createdBy': value['createdBy'] ?? "Unknown",
            'createdByUid': value['createdByUid'] ?? "Unknown",
            'role': value['role'] ?? "Unknown",
          };
        });
      });
    }
  }

  void _selectDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2023),
      lastDate: DateTime(2100),
    );

    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });

      if (selectedClass != null && selectedSection != null) {
        _loadStudentsByClassAndSection(selectedClass!, selectedSection!);
      }
    }
  }

  void _submitAttendanceConfirmed() async {
    if (selectedClass == null || selectedSection == null) return;

    final attendanceRef = FirebaseDatabase.instance
        .ref()
        .child('attendance')
        .child(formattedDate)
        .child(selectedClass!)
        .child(selectedSection!);

    for (var entry in attendance.entries) {
      await attendanceRef.child(entry.key).set({
        'status': entry.value['status'],
        'createdBy': widget.userName,
        'createdByUid': widget.userUid,
        'role': widget.role,
        'timestamp': ServerValue.timestamp,
      });
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Attendance submitted successfully.")),
    );
  }

  void _submitAttendance() {
    if (selectedClass == null || selectedSection == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select class and section.")),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Confirm Submission"),
        content: const Text("Are you sure you want to submit this attendance?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _submitAttendanceConfirmed();
            },
            child: const Text("Submit"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.role == "admin"
            ? "Admin Attendance Panel"
            : "Take Attendance"),
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              value: selectedClass,
              items: classes.map((cls) {
                return DropdownMenuItem(value: cls, child: Text("Class $cls"));
              }).toList(),
              onChanged: (value) {
                if (value != null) _loadSectionsForClass(value);
              },
              decoration: const InputDecoration(
                labelText: "Select Class",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            if (sections.isNotEmpty)
              DropdownButtonFormField<String>(
                value: selectedSection,
                items: sections.map((sec) {
                  return DropdownMenuItem(
                      value: sec, child: Text("Section $sec"));
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => selectedSection = value);
                    _loadStudentsByClassAndSection(selectedClass!, value);
                  }
                },
                decoration: const InputDecoration(
                  labelText: "Select Section",
                  border: OutlineInputBorder(),
                ),
              ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Text("Selected Date: $formattedDate",
                      style: const TextStyle(fontSize: 16)),
                ),
                TextButton.icon(
                  onPressed: _selectDate,
                  icon: const Icon(Icons.calendar_month),
                  label: const Text("Pick Date"),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : filteredStudents.isEmpty
                  ? const Center(child: Text("No students to show."))
                  : ListView.builder(
                itemCount: filteredStudents.length,
                itemBuilder: (context, index) {
                  final student = filteredStudents[index];
                  final studentKey =
                      '${student['rollNumber'] ?? student['name']}_${student['name']}';

                  return Card(
                    child: ListTile(
                      title: Text(student['name'] ?? 'No Name'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Roll: ${student['rollNumber'] ?? 'N/A'}"),
                          Text("Date: $formattedDate"),
                          if (attendance[studentKey]?['createdBy'] != null)
                            Text(
                              "Marked By: ${attendance[studentKey]!['createdBy']} "
                                  "(${attendance[studentKey]!['role']})",
                              style: const TextStyle(
                                  fontStyle: FontStyle.italic,
                                  fontSize: 12),
                            ),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ChoiceChip(
                            label: const Text("Present"),
                            selected:
                            attendance[studentKey]?['status'] ==
                                'present',
                            selectedColor: Colors.green,
                            onSelected: (_) {
                              setState(() {
                                attendance[studentKey] = {
                                  'status': 'present',
                                  'createdBy': widget.userName,
                                  'createdByUid': widget.userUid,
                                  'role': widget.role,
                                };
                              });
                            },
                          ),
                          const SizedBox(width: 8),
                          ChoiceChip(
                            label: const Text("Absent"),
                            selected:
                            attendance[studentKey]?['status'] ==
                                'absent',
                            selectedColor: Colors.redAccent,
                            onSelected: (_) {
                              setState(() {
                                attendance[studentKey] = {
                                  'status': 'absent',
                                  'createdBy': widget.userName,
                                  'createdByUid': widget.userUid,
                                  'role': widget.role,
                                };
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: _submitAttendance,
              icon: const Icon(Icons.check),
              label: const Text("Submit Attendance"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                minimumSize: const Size.fromHeight(50),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
