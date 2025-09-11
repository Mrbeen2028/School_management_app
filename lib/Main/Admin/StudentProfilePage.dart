import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';

class StudentProfilePage extends StatelessWidget {
  final Map<String, dynamic> student;

  const StudentProfilePage({super.key, required this.student});

  @override
  Widget build(BuildContext context) {
    Uint8List? imageBytes;
    if (student['photoBase64'] != null) {
      try {
        imageBytes = base64Decode(student['photoBase64']);
      } catch (_) {}
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F9),
      appBar: AppBar(
        title: const Text(
          "Student Profile",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.deepPurple, Colors.indigo],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Profile Picture Card
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 6,
              margin: const EdgeInsets.symmetric(vertical: 10),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundImage:
                      imageBytes != null ? MemoryImage(imageBytes) : null,
                      backgroundColor: Colors.deepPurple.shade100,
                      child: imageBytes == null
                          ? const Icon(Icons.person,
                          size: 70, color: Colors.white)
                          : null,
                    ),
                    const SizedBox(height: 15),
                    Text(
                      student['name'] ?? "N/A",
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      "Roll No: ${student['rollNumber'] ?? "N/A"}",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Info Cards
            _buildInfoCard(Icons.family_restroom, "Father's Name", student['fatherName']),
            _buildInfoCard(Icons.class_, "Class", student['class']),
            _buildInfoCard(Icons.group, "Section", student['section']),
            _buildInfoCard(Icons.medical_services, "Medical Disorder", student['medicalDisorder']),
            _buildInfoCard(Icons.attach_money, "Monthly Fees", student['monthlyFees']),
            _buildInfoCard(Icons.phone, "Guardian Contact", student['guardianContactNumber']),
            _buildInfoCard(Icons.badge, "CNIC", student['cnic']),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(IconData icon, String label, dynamic value) {
    final displayValue = (value == null || value.toString().trim().isEmpty)
        ? "N/A"
        : value.toString();

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.deepPurple.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.deepPurple, size: 26),
        ),
        title: Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          displayValue,
          style: const TextStyle(fontSize: 15, color: Colors.black87),
        ),
      ),
    );
  }
}
