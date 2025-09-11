import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class TeacherPeriodPlanAdminPage extends StatefulWidget {
  const TeacherPeriodPlanAdminPage({Key? key}) : super(key: key);

  @override
  State<TeacherPeriodPlanAdminPage> createState() => _TeacherPeriodPlanAdminPageState();
}

class _TeacherPeriodPlanAdminPageState extends State<TeacherPeriodPlanAdminPage> {
  final DatabaseReference _plansRef = FirebaseDatabase.instance.ref('teacher_period_plans');

  /// fetch all teachers where role == "Teacher"
  final Query _teachersQuery = FirebaseDatabase.instance.ref('users').orderByChild('role').equalTo('2');

  final _formKey = GlobalKey<FormState>();

  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _classSectionController = TextEditingController();
  final TextEditingController _timeSlotController = TextEditingController();
  final TextEditingController _roomNumberController = TextEditingController();
  final TextEditingController _specialNotesController = TextEditingController();

  String? _editingKey;

  // Selected teacher
  String? _selectedTeacherUid;
  String? _selectedTeacherName;

  @override
  void dispose() {
    _subjectController.dispose();
    _classSectionController.dispose();
    _timeSlotController.dispose();
    _roomNumberController.dispose();
    _specialNotesController.dispose();
    super.dispose();
  }

  void _savePeriod() {
    final isFormOk = _formKey.currentState?.validate() ?? false;
    if (!isFormOk) return;

    if (_selectedTeacherUid == null || _selectedTeacherName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a teacher')),
      );
      return;
    }

    final periodData = {
      'subjectName': _subjectController.text.trim(),
      'classSection': _classSectionController.text.trim(),
      'timeSlot': _timeSlotController.text.trim(),
      'roomNumber': _roomNumberController.text.trim(),
      'specialNotes': _specialNotesController.text.trim(),
      'teacherUid': _selectedTeacherUid,
      'teacherName': _selectedTeacherName,
    };

    if (_editingKey == null) {
      _plansRef.push().set(periodData);
    } else {
      _plansRef.child(_editingKey!).set(periodData);
    }

    _clearForm();
  }

  void _editPeriod(String key, Map<dynamic, dynamic> data) {
    final period = Map<String, dynamic>.from(data);
    setState(() {
      _editingKey = key;
      _subjectController.text = period['subjectName'] ?? '';
      _classSectionController.text = period['classSection'] ?? '';
      _timeSlotController.text = period['timeSlot'] ?? '';
      _roomNumberController.text = period['roomNumber'] ?? '';
      _specialNotesController.text = period['specialNotes'] ?? '';
      _selectedTeacherUid = period['teacherUid'];
      _selectedTeacherName = period['teacherName'];
    });
  }

  void _deletePeriod(String key) {
    _plansRef.child(key).remove();
  }

  void _clearForm() {
    setState(() {
      _editingKey = null;
      _subjectController.clear();
      _classSectionController.clear();
      _timeSlotController.clear();
      _roomNumberController.clear();
      _specialNotesController.clear();
      _selectedTeacherUid = null;
      _selectedTeacherName = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Teacher Period Plan',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue.shade600,
        centerTitle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              // ---------- FORM ----------
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildTextField(_subjectController, 'Subject', Icons.book),
                    _buildTextField(_classSectionController, 'Class/Section', Icons.group),
                    _buildTextField(_timeSlotController, 'Time Slot', Icons.access_time),
                    _buildTextField(_roomNumberController, 'Room Number', Icons.meeting_room),
                    _buildTextField(_specialNotesController, 'Special Notes', Icons.note_alt),

                    // ---------- TEACHER DROPDOWN ----------
                    StreamBuilder<DatabaseEvent>(
                      stream: _teachersQuery.onValue,
                      builder: (context, snap) {
                        if (snap.connectionState == ConnectionState.waiting) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: LinearProgressIndicator(),
                          );
                        }

                        // Debug print for data received
                        print('Teacher Stream snapshot value: ${snap.data?.snapshot.value}');

                        if (!snap.hasData || snap.data?.snapshot.value == null) {
                          return DropdownButtonFormField<String>(
                            value: null,
                            items: const [],
                            onChanged: null,
                            decoration: InputDecoration(
                              labelText: 'Select Teacher',
                              prefixIcon: const Icon(Icons.person, color: Colors.blue),
                              filled: true,
                              fillColor: Colors.grey.shade100,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            validator: (_) => 'Please select a teacher',
                          );
                        }

                        final rawData = snap.data!.snapshot.value;

                        if (rawData is! Map) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: Text('Unexpected data format for teachers'),
                          );
                        }

                        final raw = Map<dynamic, dynamic>.from(rawData);

                        // Build list of teachers
                        final teachers = raw.entries.map((e) {
                          final uid = e.key.toString();
                          final v = Map<dynamic, dynamic>.from(e.value as Map);
                          final name = (v['name'] ?? 'Unnamed Teacher').toString();
                          return MapEntry(uid, name);
                        }).toList()
                          ..sort((a, b) => a.value.compareTo(b.value));

                        final items = teachers
                            .map((e) => DropdownMenuItem<String>(
                          value: e.key,
                          child: Text(e.value),
                        ))
                            .toList();

                        return DropdownButtonFormField<String>(
                          value: _selectedTeacherUid,
                          decoration: InputDecoration(
                            labelText: 'Select Teacher',
                            prefixIcon: const Icon(Icons.person, color: Colors.blue),
                            filled: true,
                            fillColor: Colors.grey.shade100,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          items: items,
                          onChanged: (uid) {
                            if (uid == null) return;
                            final found = teachers.firstWhere((e) => e.key == uid);
                            setState(() {
                              _selectedTeacherUid = uid;
                              _selectedTeacherName = found.value;
                            });
                          },
                          validator: (val) => val == null ? 'Please select a teacher' : null,
                        );
                      },
                    ),

                    const SizedBox(height: 14),
                    ElevatedButton.icon(
                      icon: Icon(_editingKey == null ? Icons.add : Icons.update),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _editingKey == null ? Colors.green : Colors.orange,
                        minimumSize: const Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      label: Text(_editingKey == null ? 'Add Period' : 'Update Period', style: const TextStyle(fontSize: 16)),
                      onPressed: _savePeriod,
                    ),
                  ],
                ),
              ),

              const Divider(),

              // ---------- PERIOD LIST ----------
              StreamBuilder<DatabaseEvent>(
                stream: _plansRef.onValue,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: LinearProgressIndicator(),
                    );
                  }
                  if (!snapshot.hasData || snapshot.data?.snapshot.value == null) {
                    return const Padding(
                      padding: EdgeInsets.only(top: 12),
                      child: Text('No periods added yet.', style: TextStyle(fontSize: 16, color: Colors.black54)),
                    );
                  }

                  final periodsMap = Map<String, dynamic>.from(snapshot.data!.snapshot.value as Map);

                  final cards = periodsMap.entries.map((entry) {
                    final period = Map<String, dynamic>.from(entry.value as Map);
                    return Card(
                      elevation: 3,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(14),
                        title: Text(
                          period['subjectName'] ?? '',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("${period['classSection'] ?? ''} | ${period['timeSlot'] ?? ''}", style: const TextStyle(fontSize: 15)),
                              Text("Room: ${period['roomNumber'] ?? ''}"),
                              Text("Teacher: ${period['teacherName'] ?? ''}"),
                              if ((period['specialNotes'] ?? '').toString().isNotEmpty)
                                Text("Notes: ${period['specialNotes']}"),
                            ],
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _editPeriod(entry.key, entry.value)),
                            IconButton(icon: const Icon(Icons.delete, color: Colors.redAccent), onPressed: () => _deletePeriod(entry.key)),
                          ],
                        ),
                      ),
                    );
                  }).toList();

                  return Column(children: cards);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Colors.blue),
          filled: true,
          fillColor: Colors.grey.shade100,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        validator: (value) => value == null || value.isEmpty ? 'Enter $label' : null,
      ),
    );
  }
}
