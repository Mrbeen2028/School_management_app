import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class TeacherStudentListPage extends StatefulWidget {
  const TeacherStudentListPage({super.key});

  @override
  State<TeacherStudentListPage> createState() => _TeacherStudentListPageState();
}

class _TeacherStudentListPageState extends State<TeacherStudentListPage> {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref().child('users');
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

    // Real-time listener for automatic updates
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

  int _classSortKey(String className) {
    final normalized = className.toLowerCase().trim();
    final aliases = {'pg': 'playgroup', 'kg': 'kindergarten', 'nur': 'nursery'};
    final cleaned = aliases[normalized] ?? normalized;

    final order = {
      'playgroup': 0, 'nursery': 1, 'kindergarten': 2,
      '1': 3, '2': 4, '3': 5, '4': 6, '5': 7,
      '6': 8, '7': 9, '8': 10, '9': 11, '10': 12,
    };
    return order[cleaned] ?? 100;
  }

  void _showStudentDetails(Map<String, dynamic> student) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          student['name'] ?? 'Student Details',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.teal,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Name', student['name']),
              _buildDetailRow('Class', student['class']),
              _buildDetailRow('Section', student['section']),
              _buildDetailRow('Roll Number', student['rollNumber']),
              _buildDetailRow('CNIC', student['cnic']),
              _buildDetailRow('guardianContactNumber', student['guardianContactNumber']),
              // _buildDetailRow('Emergency Contact', student['emergencyContactName']),
              // _buildDetailRow('Emergency Phone', student['emergencyContactNumber']),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.teal,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value?.toString() ?? 'N/A',
              style: const TextStyle(color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Map<String, List<MapEntry<String, Map<String, dynamic>>>> studentsByClassAndSection = {};

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

      studentsByClassAndSection.putIfAbsent(classKey, () => []).add(MapEntry(key, student));
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Students List'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      backgroundColor: const Color(0xFFF9F0FF),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: _isLoading
            ? const Center(
          child: CircularProgressIndicator(color: Colors.teal),
        )
            : Column(
          children: [
            // Search Bar
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.teal.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                onChanged: (value) => setState(() => _searchQuery = value),
                decoration: InputDecoration(
                  hintText: 'Search by name or roll number',
                  prefixIcon: Icon(Icons.search, color: Colors.teal.shade600),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Student Count
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.teal.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.teal.shade200),
              ),
              child: Text(
                'Total Students: ${_students.length}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal.shade800,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 12),

            // Students List
            Expanded(
              child: studentsByClassAndSection.isEmpty
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.people_outline,
                      size: 64,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _searchQuery.isNotEmpty
                          ? "No students found matching '$_searchQuery'"
                          : "No students available yet",
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey.shade600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
                  : ListView(
                children: (studentsByClassAndSection.entries.toList()
                  ..sort((a, b) => _classSortKey(a.key.split(' - ').first)
                      .compareTo(_classSortKey(b.key.split(' - ').first))))
                    .map((entry) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.teal.withOpacity(0.1),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ExpansionTile(
                      title: Row(
                        children: [
                          Icon(
                            Icons.class_,
                            color: Colors.teal.shade600,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            entry.key,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.teal.shade800,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      subtitle: Text(
                        '${entry.value.length} student${entry.value.length != 1 ? 's' : ''}',
                        style: TextStyle(
                          color: Colors.teal.shade600,
                          fontSize: 12,
                        ),
                      ),
                      children: entry.value.map((studentEntry) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 6,
                          ),
                          child: _buildStudentCard(
                            studentEntry.key,
                            studentEntry.value,
                          ),
                        );
                      }).toList(),
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
      decoration: BoxDecoration(
        color: Colors.teal.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.teal.shade100),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Student Photo
          ClipOval(
            child: imageBytes != null
                ? Image.memory(
              imageBytes,
              height: 60,
              width: 60,
              fit: BoxFit.cover,
            )
                : student['imageUrl'] != null
                ? Image.network(
              student['imageUrl'],
              height: 60,
              width: 60,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 60,
                  width: 60,
                  color: Colors.teal.shade100,
                  child: Icon(
                    Icons.person,
                    size: 35,
                    color: Colors.teal.shade600,
                  ),
                );
              },
            )
                : Container(
              height: 60,
              width: 60,
              color: Colors.teal.shade100,
              child: Icon(
                Icons.person,
                size: 35,
                color: Colors.teal.shade600,
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Student Information
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  student['name'] ?? 'No Name',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Roll No: ${student['rollNumber'] ?? 'N/A'}",
                  style: _infoStyle(),
                ),
                Text(
                  "Phone: ${student['phone'] ?? student['emergencyContactNumber'] ?? 'N/A'}",
                  style: _infoStyle(),
                ),
              ],
            ),
          ),

          // View Details Button
          ElevatedButton(
            onPressed: () => _showStudentDetails(student),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Details',
              style: TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  TextStyle _infoStyle() => TextStyle(
    color: Colors.teal.shade700,
    fontSize: 13,
  );

  @override
  void dispose() {
    super.dispose();
  }
}