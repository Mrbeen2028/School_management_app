import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

import 'SchoolTimingEntry.dart';

class SchoolTimingPage extends StatefulWidget {
  const SchoolTimingPage({super.key});

  @override
  State<SchoolTimingPage> createState() => _SchoolTimingPageState();
}

class _SchoolTimingPageState extends State<SchoolTimingPage> {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref('schoolTime');

  final List<String> allClasses = [
    'P.G',
    'Nursery',
    'Prep',
    ...List.generate(10, (i) => 'Class ${i + 1}')
  ];
  Map<String, SchoolTimingEntry> timings = {};

  @override
  void initState() {
    super.initState();
    _loadTimings();
  }

  void _loadTimings() {
    _dbRef.onValue.listen((event) {
      final data = event.snapshot.value as Map?;
      if (data != null) {
        timings = data.map((key, value) {
          return MapEntry(
              key, SchoolTimingEntry.fromMap(key, Map<String, dynamic>.from(value)));
        });
        setState(() {});
      }
    });
  }

  Future<void> _pickTime(
      BuildContext context, TextEditingController controller) async {
    final initialTime = TimeOfDay.now();
    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );
    if (picked != null) {
      final formatted =
      picked.format(context); // e.g. 08:00 AM
      controller.text = formatted;
    }
  }

  void _editTiming(String classKey) {
    final entry = timings[classKey];
    final timeInController = TextEditingController(text: entry?.timeIn ?? '');
    final timeOutController = TextEditingController(text: entry?.timeOut ?? '');

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Set Timing - ${_formatClassName(classKey)}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: timeInController,
              readOnly: true,
              decoration: InputDecoration(
                labelText: 'Time In',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.access_time),
                  onPressed: () => _pickTime(context, timeInController),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: timeOutController,
              readOnly: true,
              decoration: InputDecoration(
                labelText: 'Time Out',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.access_time),
                  onPressed: () => _pickTime(context, timeOutController),
                ),
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
                  borderRadius: BorderRadius.circular(12)),
            ),
            label: const Text("Save"),
            onPressed: () {
              _dbRef.child(classKey).set({
                'timeIn': timeInController.text.trim(),
                'timeOut': timeOutController.text.trim(),
              });
              Navigator.pop(context);
            },
          )
        ],
      ),
    );
  }

  String _formatClassName(String raw) {
    if (raw == 'pg') return 'P.G';
    if (raw == 'nursery') return 'Nursery';
    if (raw == 'prep') return 'Prep';
    if (raw.startsWith('class')) {
      return 'Class ${raw.replaceAll('class', '')}';
    }
    return raw;
  }

  String _keyFromClassName(String name) {
    if (name == 'P.G') return 'pg';
    if (name == 'Nursery') return 'nursery';
    if (name == 'Prep') return 'prep';
    return name.toLowerCase().replaceAll(' ', '');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("School Timing Manager",
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.teal,
      ),
      body: ListView.builder(
        itemCount: allClasses.length,
        itemBuilder: (context, index) {
          final name = allClasses[index];
          final key = _keyFromClassName(name);
          final timing = timings[key];

          return Card(
            elevation: 3,
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: ListTile(
              contentPadding: const EdgeInsets.all(12),
              title: Text(
                name,
                style:
                const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                timing == null
                    ? 'Not Set'
                    : '${timing.timeIn} - ${timing.timeOut}',
                style: const TextStyle(fontSize: 15, color: Colors.black87),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.edit, color: Colors.teal),
                onPressed: () => _editTiming(key),
              ),
            ),
          );
        },
      ),
    );
  }
}
