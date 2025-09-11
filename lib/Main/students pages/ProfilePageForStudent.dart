import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class ProfilePageForStudent extends StatefulWidget {
  const ProfilePageForStudent({Key? key}) : super(key: key);

  @override
  _ProfilePageForStudent createState() => _ProfilePageForStudent();
}

class _ProfilePageForStudent extends State<ProfilePageForStudent> {
  final _db = FirebaseDatabase.instance.ref();
  Map<String, dynamic>? _studentData;
  Uint8List? _imageBytes;

  @override
  void initState() {
    super.initState();
    _loadStudentData();
  }

  Future<void> _loadStudentData() async {
    final email = FirebaseAuth.instance.currentUser?.email;
    if (email == null) return;

    final snapshot =
    await _db.child("users").child(email.replaceAll(".", "_")).get();

    if (snapshot.exists) {
      final data = Map<String, dynamic>.from(snapshot.value as Map);

      if (data['photoBase64'] != null) {
        try {
          _imageBytes = base64Decode(data['photoBase64']);
        } catch (e) {
          print("Image decode failed: $e");
        }
      }

      setState(() {
        _studentData = data;
      });
    }
  }

  Widget _buildInfoTile(String label, String? value) {
    return ListTile(
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(value ?? "N/A"),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_studentData == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("My Profile")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            CircleAvatar(
              radius: 60,
              backgroundImage: _imageBytes != null ? MemoryImage(_imageBytes!) : null,
              child: _imageBytes == null
                  ? const Icon(Icons.person, size: 60)
                  : null,
            ),
            const SizedBox(height: 20),
            _buildInfoTile("Name", _studentData?['name']),
            _buildInfoTile("Father's Name", _studentData?['fatherName']),
            _buildInfoTile("Class", _studentData?['class']),
            _buildInfoTile("Section", _studentData?['section']),
            _buildInfoTile("Roll Number", _studentData?['rollNumber']),
            _buildInfoTile("Email", _studentData?['email']),
            _buildInfoTile("Guardian Contact", _studentData?['guardianContactNumber']),
            _buildInfoTile("CNIC", _studentData?['cnic']),
            _buildInfoTile("Medical Disorder", _studentData?['medicalDisorder']),
            _buildInfoTile("Monthly Fees", _studentData?['monthlyFees']),
          ],
        ),
      ),
    );
  }
}
