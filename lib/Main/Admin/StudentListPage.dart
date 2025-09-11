import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'StudentProfilePage.dart';
import 'StudentUploadPage.dart';

class StudentListPage extends StatefulWidget {
  const StudentListPage({super.key});

  @override
  State<StudentListPage> createState() => _StudentListPageState();
}

class _StudentListPageState extends State<StudentListPage> {
  final DatabaseReference _dbRef =
  FirebaseDatabase.instance.ref().child('users');
  Map<String, Map<String, dynamic>> _students = {};
  String _searchQuery = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchStudents();
  }

  void _fetchStudents() {
    setState(() => _isLoading = true);

    _dbRef.onValue.listen((event) {
      final data = event.snapshot.value as Map?;
      if (data == null) {
        setState(() {
          _students = {};
          _isLoading = false;
        });
        return;
      }

      final Map<String, Map<String, dynamic>> loaded = {};
      data.forEach((key, value) {
        final student = Map<String, dynamic>.from(value);
        if (student['role'] == 'student') {
          loaded[key] = student;
        }
      });

      setState(() {
        _students = loaded;
        _isLoading = false;
      });
    });
  }

  void _confirmDelete(String key) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete this student?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel')),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(ctx).pop();
              _deleteStudent(key);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            icon: const Icon(Icons.delete, size: 18),
            label: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _deleteStudent(String key) async {
    await _dbRef.child(key).remove();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            '🗑️ Student deleted successfully!',
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          backgroundColor: Colors.teal,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 3),
          elevation: 10,
        ),
      );
    }
  }

  int _classSortKey(String className) {
    final normalized = className.toLowerCase().trim();
    final aliases = {'pg': 'playgroup', 'kg': 'kindergarten', 'nur': 'nursery'};
    final cleaned = aliases[normalized] ?? normalized;

    final order = {
      'playgroup': 0,
      'nursery': 1,
      'kindergarten': 2,
      '1': 3,
      '2': 4,
      '3': 5,
      '4': 6,
      '5': 7,
      '6': 8,
      '7': 9,
      '8': 10,
      '9': 11,
      '10': 12,
    };
    return order[cleaned] ?? 100;
  }

  @override
  Widget build(BuildContext context) {
    Map<String, List<MapEntry<String, Map<String, dynamic>>>>
    studentsByClassAndSection = {};

    _students.forEach((key, student) {
      final name = (student['name'] ?? '').toString().toLowerCase();
      final roll = (student['rollNumber'] ?? '').toString().toLowerCase();

      if (_searchQuery.isNotEmpty &&
          !name.contains(_searchQuery.toLowerCase()) &&
          !roll.contains(_searchQuery.toLowerCase())) {
        return;
      }

      final className = student['class'] ?? 'Unknown';
      final section = student['section'] ?? 'N/A';
      final classKey = "$className - Section $section";

      studentsByClassAndSection.putIfAbsent(classKey, () => [])
          .add(MapEntry(key, student));
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Student List'),
        backgroundColor: Colors.teal.shade700,
        foregroundColor: Colors.white,
        elevation: 3,
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: _isLoading
            ? const Center(
          child: CircularProgressIndicator(color: Colors.teal),
        )
            : Column(
          children: [
            TextField(
              onChanged: (value) =>
                  setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: 'Search by name or roll number',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: studentsByClassAndSection.isEmpty
                  ? const Center(
                child: Text(
                  "No students found.",
                  style:
                  TextStyle(fontSize: 18, color: Colors.grey),
                ),
              )
                  : ListView(
                children: (studentsByClassAndSection.entries
                    .toList() // ✅ FIX: Iterable → List
                  ..sort((a, b) => _classSortKey(
                      a.key.split(' - ').first)
                      .compareTo(_classSortKey(
                      b.key.split(' - ').first))))
                    .map((entry) {
                  return Card(
                    margin:
                    const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    elevation: 3,
                    child: ExpansionTile(
                      title: Text(
                        entry.key,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.teal.shade800,
                          fontSize: 18,
                        ),
                      ),
                      children: entry.value
                          .map((studentEntry) => _buildStudentCard(
                          studentEntry.key,
                          studentEntry.value))
                          .toList(),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentCard(String key, Map<String, dynamic> student) {
    Uint8List? imageBytes;
    if (student['photoBase64'] is String) {
      try {
        imageBytes = base64Decode(student['photoBase64']);
      } catch (_) {
        imageBytes = null;
      }
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.teal.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.teal.withOpacity(0.08),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(35),
            child: imageBytes != null
                ? Image.memory(imageBytes,
                height: 70, width: 70, fit: BoxFit.cover)
                : Container(
              height: 70,
              width: 70,
              color: Colors.grey.shade300,
              child: const Icon(Icons.person,
                  size: 40, color: Colors.white),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  student['name'] ?? 'No Name',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal,
                  ),
                ),
                const SizedBox(height: 6),
                Text("Class: ${student['class'] ?? 'N/A'}",
                    style: _infoStyle()),
                Text("Section: ${student['section'] ?? 'N/A'}",
                    style: _infoStyle()),
                Text("Roll No: ${student['rollNumber'] ?? 'N/A'}",
                    style: _infoStyle()),
                Text("Phone: ${student['phone'] ?? 'N/A'}",
                    style: _infoStyle()),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 6,
                  children: [
                    _actionButton(
                      label: 'Delete',
                      color: Colors.redAccent,
                      icon: Icons.delete,
                      onPressed: () => _confirmDelete(key),
                    ),
                    _actionButton(
                      label: 'Update',
                      color: Colors.amber,
                      icon: Icons.edit,
                      textColor: Colors.black,
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                StudentUploadPage(studentData: student),
                          ),
                        );
                      },
                    ),
                    _actionButton(
                      label: 'Profile',
                      color: Colors.teal,
                      icon: Icons.person,
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                StudentProfilePage(student: student),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  TextStyle _infoStyle() => TextStyle(color: Colors.grey.shade700);

  Widget _actionButton({
    required String label,
    required Color color,
    required IconData icon,
    required VoidCallback onPressed,
    Color textColor = Colors.white,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: textColor,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        elevation: 2,
      ),
      icon: Icon(icon, size: 18),
      label: Text(label),
    );
  }
}
