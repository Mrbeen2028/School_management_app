import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';

class HomeworkDiaryPage extends StatefulWidget {
  @override
  _HomeworkDiaryPageState createState() => _HomeworkDiaryPageState();
}

class _HomeworkDiaryPageState extends State<HomeworkDiaryPage> {
  final Map<String, String> classNameMap = {
    "PG": "P.G",
    "Nursery": "Nursery",
    "Prep": "Prep",
    "One": "One",
    "Two": "Two",
    "Three": "Three",
    "Four": "Four",
    "Five": "Five",
    "Six": "Six",
    "Seven": "Seven",
    "Eight": "Eight",
    "Nine": "Nine",
    "Ten": "Ten",
  };

  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  DateTime selectedDate = DateTime.now();
  String selectedClass = 'PG';
  String? _editingId;
  bool showFullHistory = false;

  Future<List<Map<String, dynamic>>> _fetchHomework(String className) async {
    final ref = FirebaseDatabase.instance.ref().child("homework").child(className);
    final snapshot = await ref.get();

    List<Map<String, dynamic>> list = [];

    if (snapshot.exists && snapshot.value is Map) {
      final allDates = Map<String, dynamic>.from(snapshot.value as Map);
      allDates.forEach((dateKey, entriesMap) {
        if (!showFullHistory && dateKey != DateFormat('yyyy-MM-dd').format(selectedDate)) return;

        if (entriesMap is Map) {
          final entries = Map<String, dynamic>.from(entriesMap);
          entries.forEach((key, value) {
            if (value is Map) {
              list.add({
                "id": key,
                "subject": value['subject'] ?? '',
                "description": value['description'] ?? '',
                "date": dateKey,
                "createdBy": value['createdBy'] ?? '',
              });
            }
          });
        }
      });
    }

    list.sort((a, b) => b['date'].compareTo(a['date']));
    return list;
  }

  Future<void> _uploadHomework() async {
    if (_formKey.currentState!.validate()) {
      final String dateKey = DateFormat('yyyy-MM-dd').format(selectedDate);
      final DatabaseReference baseRef = FirebaseDatabase.instance
          .ref()
          .child("homework")
          .child(selectedClass)
          .child(dateKey);

      if (_editingId != null) {
        await baseRef.child(_editingId!).update({
          "subject": _subjectController.text.trim(),
          "description": _descriptionController.text.trim(),
          "createdBy": "admin",
        });
      } else {
        await baseRef.push().set({
          "subject": _subjectController.text.trim(),
          "description": _descriptionController.text.trim(),
          "createdBy": "admin",
        });
      }

      _subjectController.clear();
      _descriptionController.clear();
      setState(() => _editingId = null);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("✅ Homework saved for $selectedClass")),
      );
    }
  }

  Future<void> _deleteHomework(String className, String entryId, String dateKey) async {
    await FirebaseDatabase.instance
        .ref()
        .child("homework")
        .child(className)
        .child(dateKey)
        .child(entryId)
        .remove();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("🗑️ Homework deleted")),
    );

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text("📓 Homework Diary", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 2,
        backgroundColor: Colors.deepPurple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // FORM CARD
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 4,
              margin: const EdgeInsets.only(bottom: 20),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: selectedClass,
                              items: classNameMap.entries
                                  .map((entry) => DropdownMenuItem(
                                value: entry.key,
                                child: Text(entry.value),
                              ))
                                  .toList(),
                              onChanged: (value) => setState(() => selectedClass = value!),
                              decoration: InputDecoration(
                                labelText: "Select Class",
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: selectedDate,
                                  firstDate: DateTime(2000),
                                  lastDate: DateTime(2100),
                                );
                                if (picked != null) {
                                  setState(() {
                                    selectedDate = picked;
                                    _editingId = null;
                                    _subjectController.clear();
                                    _descriptionController.clear();
                                  });
                                }
                              },
                              child: InputDecorator(
                                decoration: InputDecoration(
                                  labelText: 'Select Date',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(DateFormat('yyyy-MM-dd').format(selectedDate)),
                                    Icon(Icons.calendar_today, color: Colors.deepPurple),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Checkbox(
                            value: showFullHistory,
                            onChanged: (value) {
                              setState(() {
                                showFullHistory = value!;
                              });
                            },
                          ),
                          Text("Show Full History"),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _subjectController,
                        decoration: InputDecoration(
                          labelText: "Subject",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: Icon(Icons.book_outlined),
                        ),
                        validator: (value) => value!.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _descriptionController,
                        decoration: InputDecoration(
                          labelText: "Description",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: Icon(Icons.description_outlined),
                        ),
                        validator: (value) => value!.isEmpty ? 'Required' : null,
                        maxLines: 2,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: EdgeInsets.symmetric(vertical: 14),
                                backgroundColor: Colors.blueAccent,
                              ),
                              icon: Icon(Icons.save),                              label: Text(
                                _editingId != null ? "Update" : "Upload",
                                style: TextStyle(
                                  fontWeight: _editingId != null ? FontWeight.bold : FontWeight.bold,
                                ),
                              ),
                              onPressed: _uploadHomework,
                            ),
                          ),

                          if (_editingId != null) ...[
                            const SizedBox(width: 10),
                            Expanded(
                              child: OutlinedButton.icon(
                                icon: Icon(Icons.cancel, color: Colors.red),
                                label: Text("Cancel"),
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: Colors.red),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: EdgeInsets.symmetric(vertical: 14),
                                ),
                                onPressed: () {
                                  setState(() => _editingId = null);
                                  _subjectController.clear();
                                  _descriptionController.clear();
                                },
                              ),
                            )
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // TABLE SECTION
            Expanded(
              child: Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: FutureBuilder<List<Map<String, dynamic>>>(
                    future: _fetchHomework(selectedClass),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting)
                        return Center(child: CircularProgressIndicator());

                      final entries = snapshot.data ?? [];

                      if (entries.isEmpty) return Center(child: Text("No homework found."));

                      return SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.vertical,
                            child: DataTable(
                              columnSpacing: 20,
                              headingRowColor: MaterialStateColor.resolveWith(
                                    (states) => Colors.deepPurple.shade100,
                              ),
                              border: TableBorder.all(color: Colors.grey.shade300, width: 1),
                              columns: const [
                                DataColumn(label: Text('📅 Date')),
                                DataColumn(label: Text('📘 Subject')),
                                DataColumn(label: Text('📝 Description')),
                                DataColumn(label: Text('⚙️ Actions')),
                              ],
                              rows: entries.map((entry) {
                                return DataRow(cells: [
                                  DataCell(Text(entry['date'])),
                                  DataCell(Text(entry['subject'])),
                                  DataCell(
                                    Container(
                                      width: 250, // 👈 yahan width fix kar lo jisse column bada ho jaye
                                      child: Text(
                                        entry['description'],
                                        softWrap: true,
                                        overflow: TextOverflow.visible,
                                      ),
                                    ),
                                  ),
                                  DataCell(Row(
                                    children: [
                                      Text(
                                        'By: ${entry['createdBy']}',
                                        style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                                      ),
                                      const SizedBox(width: 8),
                                      IconButton(
                                        icon: Icon(Icons.edit, color: Colors.blue),
                                        onPressed: () {
                                          _subjectController.text = entry['subject'];
                                          _descriptionController.text = entry['description'];
                                          setState(() {
                                            _editingId = entry['id'];
                                            selectedDate = DateFormat('yyyy-MM-dd').parse(entry['date']);
                                          });
                                        },
                                      ),
                                      IconButton(
                                        icon: Icon(Icons.delete, color: Colors.red),
                                        onPressed: () =>
                                            _deleteHomework(selectedClass, entry['id'], entry['date']),
                                      ),
                                    ],
                                  )),
                                ]);
                              }).toList(),
                            ),
                          ),
                        ),
                      );

                    },
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
