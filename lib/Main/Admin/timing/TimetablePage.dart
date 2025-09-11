import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:math';
import 'SchoolTimingPage.dart';
import 'TimetableEntry.dart';

class TimetablePage extends StatefulWidget {
  const TimetablePage({Key? key}) : super(key: key);

  @override
  State<TimetablePage> createState() => _TimetablePageState();
}

class _TimetablePageState extends State<TimetablePage>
    with SingleTickerProviderStateMixin {
  String selectedClass = 'P.G';
  String selectedDay = 'Monday';

  final List<String> classes = [
    'P.G',
    'Nursery',
    'Prep',
    ...List.generate(10, (index) => 'Class ${index + 1}'),
  ];

  final List<String> days = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday'
  ];

  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref('timetables');
  List<TimetableEntry> _entries = [];

  @override
  void initState() {
    super.initState();
    _loadEntries();
  }

  String get cleanClassKey =>
      selectedClass.toLowerCase().replaceAll(RegExp(r'[ .]'), '');

  void _loadEntries() {
    _dbRef.child(cleanClassKey).child(selectedDay).onValue.listen((event) {
      final data = event.snapshot.value as Map?;
      if (data != null) {
        _entries = data.entries.map((e) {
          final entryMap = Map<String, dynamic>.from(e.value);
          return TimetableEntry.fromMap(entryMap);
        }).toList();
      } else {
        _entries = [];
      }
      setState(() {});
    });
  }

  void _addOrUpdateEntry([TimetableEntry? entry]) {
    final subjectController = TextEditingController(text: entry?.subject ?? '');
    final startController =
    TextEditingController(text: entry?.startTime ?? '');
    final endController = TextEditingController(text: entry?.endTime ?? '');

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          entry == null ? 'Add Entry' : 'Update Entry',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'For $selectedClass - $selectedDay',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.teal,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: subjectController,
              decoration: const InputDecoration(
                labelText: 'Subject',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: startController,
              decoration: const InputDecoration(
                labelText: 'Start Time',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: endController,
              decoration: const InputDecoration(
                labelText: 'End Time',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton.icon(
            icon: const Icon(Icons.save),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            label: const Text("Save"),
            onPressed: () {
              final id = entry?.id ?? Random().nextInt(1000000).toString();
              final newEntry = TimetableEntry(
                id: id,
                subject: subjectController.text.trim(),
                day: selectedDay,
                startTime: startController.text.trim(),
                endTime: endController.text.trim(),
              );
              final path =
              _dbRef.child(cleanClassKey).child(selectedDay).child(id);
              path.set(newEntry.toMap());
              Navigator.pop(context);
            },
          )
        ],
      ),
    );
  }

  void _deleteEntry(String id) {
    final path = _dbRef.child(cleanClassKey).child(selectedDay).child(id);
    path.remove();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Class Timetables'),
        backgroundColor: Colors.teal,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.teal,
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              icon: const Icon(Icons.access_time),
              label: const Text(
                "School Timings",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const SchoolTimingPage()),
                );
              },
            ),
          )
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addOrUpdateEntry(),
        backgroundColor: Colors.teal,
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          // Class Dropdown
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: "Select Class",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              value: selectedClass,
              onChanged: (value) {
                setState(() {
                  selectedClass = value!;
                  _loadEntries();
                });
              },
              items: classes
                  .map((cls) => DropdownMenuItem(value: cls, child: Text(cls)))
                  .toList(),
            ),
          ),

          // Days Horizontal Chips
          SizedBox(
            height: 55,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: days.length,
              itemBuilder: (context, index) {
                final day = days[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: ChoiceChip(
                    label: Text(
                      day,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: selectedDay == day ? Colors.white : Colors.black,
                      ),
                    ),
                    selectedColor: Colors.teal,
                    selected: selectedDay == day,
                    onSelected: (_) {
                      setState(() {
                        selectedDay = day;
                        _loadEntries();
                      });
                    },
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 10),

          // Entry List
          Expanded(
            child: _entries.isEmpty
                ? const Center(
              child: Text(
                'No entries for this day.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            )
                : ListView.builder(
              itemCount: _entries.length,
              itemBuilder: (context, index) {
                final entry = _entries[index];
                return Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 3,
                  margin: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(12),
                    title: Text(
                      entry.subject,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 6.0),
                      child: Text(
                        '${entry.startTime}  -  ${entry.endTime}',
                        style: const TextStyle(
                          fontSize: 15,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.orange),
                          onPressed: () => _addOrUpdateEntry(entry),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteEntry(entry.id),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
