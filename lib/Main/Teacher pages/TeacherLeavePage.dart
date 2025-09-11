import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';

class TeacherLeavePage extends StatefulWidget {
  final String teacherId;
  final String teacherName;

  const TeacherLeavePage({
    super.key,
    required this.teacherId,
    required this.teacherName,
  });

  @override
  State<TeacherLeavePage> createState() => _TeacherLeavePageState();
}

class _TeacherLeavePageState extends State<TeacherLeavePage> {
  final DatabaseReference _leaveRef =
  FirebaseDatabase.instance.ref("teacherLeaves");

  final _formKey = GlobalKey<FormState>();
  String? _leaveType;
  String? _reason;
  DateTime? _selectedDate;

  final List<String> leaveTypes = [
    "Casual Leave",
    "Sick Leave",
    "Emergency Leave",
    "Other"
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Apply Leave"),
        centerTitle: true,
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
            // Leave Form
            Form(
              key: _formKey,
              child: Column(
                children: [
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: "Leave Type",
                      border: OutlineInputBorder(),
                    ),
                    value: _leaveType,
                    items: leaveTypes
                        .map((type) =>
                        DropdownMenuItem(value: type, child: Text(type)))
                        .toList(),
                    onChanged: (value) => setState(() => _leaveType = value),
                    validator: (value) =>
                    value == null ? "Please select leave type" : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: "Reason",
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                    onChanged: (val) => _reason = val,
                    validator: (val) =>
                    val == null || val.isEmpty ? "Enter reason" : null,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _selectedDate == null
                              ? "No date selected"
                              : "Date: ${DateFormat('yyyy-MM-dd').format(_selectedDate!)}",
                        ),
                      ),
                      ElevatedButton(
                        onPressed: _pickDate,
                        child: const Text("Pick Date"),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: _submitLeave,
                    icon: const Icon(Icons.send),
                    label: const Text("Submit Leave"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // Leave History
            const Text(
              "My Leave Requests",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            _buildLeaveHistory(),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now.subtract(const Duration(days: 0)),
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  void _submitLeave() {
    if (!_formKey.currentState!.validate() || _selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please complete all fields")),
      );
      return;
    }

    final leaveId = _leaveRef.push().key;
    final leaveData = {
      "teacherId": widget.teacherId,
      "teacherName": widget.teacherName,
      "date": DateFormat('yyyy-MM-dd').format(_selectedDate!),
      "leaveType": _leaveType,
      "reason": _reason,
      "status": "Pending",
    };

    _leaveRef.child(leaveId!).set(leaveData);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Leave request submitted")),
    );

    setState(() {
      _leaveType = null;
      _reason = null;
      _selectedDate = null;
    });
  }

  Widget _buildLeaveHistory() {
    return StreamBuilder(
      stream: _leaveRef
          .orderByChild("teacherId")
          .equalTo(widget.teacherId)
          .onValue,
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data?.snapshot.value == null) {
          return const Text("No leave requests yet.");
        }

        final data =
        Map<String, dynamic>.from(snapshot.data!.snapshot.value as Map);

        return Column(
          children: data.entries.map((entry) {
            final leave = Map<String, dynamic>.from(entry.value);
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 6),
              child: ListTile(
                title: Text("${leave['leaveType']} - ${leave['date']}"),
                subtitle: Text("Reason: ${leave['reason']}"),
                trailing: Text(
                  leave['status'] ?? "Pending",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: leave['status'] == "Approved"
                        ? Colors.green
                        : leave['status'] == "Rejected"
                        ? Colors.red
                        : Colors.orange,
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
