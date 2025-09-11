import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class AdminTeacherLeavePage extends StatefulWidget {
  const AdminTeacherLeavePage({super.key});

  @override
  State<AdminTeacherLeavePage> createState() => _AdminTeacherLeavePageState();
}

class _AdminTeacherLeavePageState extends State<AdminTeacherLeavePage> {
  final DatabaseReference _leaveRef =
  FirebaseDatabase.instance.ref("teacherLeaves");

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Teacher Leave Requests"),
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
      body: StreamBuilder(
        stream: _leaveRef.onValue,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data?.snapshot.value == null) {
            return const Center(
              child: Text("No leave requests found."),
            );
          }

          final data =
          Map<String, dynamic>.from(snapshot.data!.snapshot.value as Map);

          return ListView(
            children: data.entries.map((entry) {
              final leaveId = entry.key;
              final leaveData = Map<String, dynamic>.from(entry.value);

              final teacherName = leaveData['teacherName'] ?? "Unknown";
              final date = leaveData['date'] ?? "N/A";
              final type = leaveData['leaveType'] ?? "N/A";
              final reason = leaveData['reason'] ?? "N/A";
              final status = leaveData['status'] ?? "Pending";

              return Card(
                margin: const EdgeInsets.all(10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15)),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.deepPurple,
                    child: Text(
                      teacherName.isNotEmpty ? teacherName[0] : "?",
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  title: Text(
                    "$teacherName ($type)",
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Date: $date"),
                      Text("Reason: $reason"),
                      Text("Status: $status"),
                    ],
                  ),
                  trailing: status == "Pending"
                      ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.check_circle,
                            color: Colors.green),
                        onPressed: () {
                          _updateStatus(leaveId, "Approved");
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.cancel, color: Colors.red),
                        onPressed: () {
                          _updateStatus(leaveId, "Rejected");
                        },
                      ),
                    ],
                  )
                      : Text(
                    status,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: status == "Approved"
                          ? Colors.green
                          : Colors.red,
                    ),
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }

  void _updateStatus(String leaveId, String newStatus) {
    _leaveRef.child(leaveId).update({
      "status": newStatus,
      "approvedBy": "Admin", // later you can set admin name/id
    });
  }
}
