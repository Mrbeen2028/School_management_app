import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:firebase_database/firebase_database.dart';

class EventCalendarPage extends StatefulWidget {
  const EventCalendarPage({Key? key}) : super(key: key);

  @override
  State<EventCalendarPage> createState() => _EventCalendarPageState();
}

class _EventCalendarPageState extends State<EventCalendarPage> {
  CalendarFormat _calendarFormat = CalendarFormat.month;

  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay = DateTime.now();

  final _eventController = TextEditingController();
  final _dbRef = FirebaseDatabase.instance.ref().child('events');

  Map<DateTime, List<String>> _events = {};

  @override
  void initState() {
    super.initState();
    _loadEventsFromFirebase();
  }

  void _loadEventsFromFirebase() async {
    final snapshot = await _dbRef.get();
    if (snapshot.exists) {
      final data = Map<String, dynamic>.from(snapshot.value as dynamic);
      final loadedEvents = <DateTime, List<String>>{};

      data.forEach((dateString, eventList) {
        final parsedDate = DateTime.parse(dateString);
        final normalized =
        DateTime(parsedDate.year, parsedDate.month, parsedDate.day);
        final events = List<String>.from(eventList);
        loadedEvents[normalized] = events;
      });

      setState(() {
        _events = loadedEvents;
      });
    }
  }

  List<String> _getEventsForDay(DateTime day) {
    final normalized = DateTime(day.year, day.month, day.day);
    return _events[normalized] ?? [];
  }

  void _addEvent(String title) {
    final selected =
    DateTime(_selectedDay!.year, _selectedDay!.month, _selectedDay!.day);

    if (_events[selected] == null) {
      _events[selected] = [];
    }
    _events[selected]!.add(title);

    _dbRef
        .child(selected.toIso8601String().split("T")[0])
        .set(_events[selected]);
    setState(() {});
    _eventController.clear();
  }

  void _editEvent(int index, String newTitle) {
    final selected =
    DateTime(_selectedDay!.year, _selectedDay!.month, _selectedDay!.day);

    _events[selected]![index] = newTitle;
    _dbRef
        .child(selected.toIso8601String().split("T")[0])
        .set(_events[selected]);
    setState(() {});
  }

  void _deleteEvent(int index) {
    final selected =
    DateTime(_selectedDay!.year, _selectedDay!.month, _selectedDay!.day);

    _events[selected]!.removeAt(index);
    if (_events[selected]!.isEmpty) {
      _dbRef.child(selected.toIso8601String().split("T")[0]).remove();
      _events.remove(selected);
    } else {
      _dbRef
          .child(selected.toIso8601String().split("T")[0])
          .set(_events[selected]);
    }
    setState(() {});
  }

  void _showAddEventDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Add New Event"),
        content: SizedBox(
          height: 100,
          child: SingleChildScrollView(
            child: TextField(
              controller: _eventController,
              maxLines: null,
              keyboardType: TextInputType.multiline,
              decoration: const InputDecoration(
                hintText: "Enter event title",
                border: OutlineInputBorder(),
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            child: const Text("Cancel"),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            child: const Text("Add"),
            onPressed: () {
              if (_eventController.text.trim().isNotEmpty) {
                _addEvent(_eventController.text.trim());
                Navigator.pop(context);
              }
            },
          ),
        ],
      ),
    );
  }

  void _showEditEventDialog(int index, String event) {
    _eventController.text = event;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Edit Event"),
        content: SizedBox(
          height: 100,
          child: TextField(
            controller: _eventController,
            maxLines: null,
            keyboardType: TextInputType.multiline,
            decoration: const InputDecoration(
              hintText: "Update event title",
              border: OutlineInputBorder(),
            ),
          ),
        ),
        actions: [
          TextButton(
            child: const Text("Cancel"),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            child: const Text("Save"),
            onPressed: () {
              if (_eventController.text.trim().isNotEmpty) {
                _editEvent(index, _eventController.text.trim());
                Navigator.pop(context);
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text("📅 Event Calendar",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.teal, Colors.blueAccent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 5,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Calendar
              Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                elevation: 4,
                child: TableCalendar(
                  focusedDay: _focusedDay,
                  firstDay: DateTime.utc(2020, 1, 1),
                  lastDay: DateTime.utc(2030, 12, 31),
                  calendarFormat: _calendarFormat,
                  eventLoader: _getEventsForDay,
                  selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                  onDaySelected: (selectedDay, focusedDay) {
                    setState(() {
                      _selectedDay = DateTime(
                          selectedDay.year, selectedDay.month, selectedDay.day);
                      _focusedDay = focusedDay;
                    });
                  },
                  onFormatChanged: (format) {
                    setState(() => _calendarFormat = format);
                  },
                  calendarStyle: CalendarStyle(
                    todayDecoration: BoxDecoration(
                        color: Colors.blueAccent.shade200,
                        shape: BoxShape.circle),
                    selectedDecoration: const BoxDecoration(
                        color: Colors.teal, shape: BoxShape.circle),
                    markerDecoration: const BoxDecoration(
                        color: Colors.red, shape: BoxShape.circle),
                    defaultTextStyle:
                    TextStyle(color: isDark ? Colors.white : Colors.black),
                    weekendTextStyle: TextStyle(
                        color: isDark ? Colors.white70 : Colors.black),
                  ),
                  headerStyle: const HeaderStyle(
                      formatButtonVisible: false, titleCentered: true),
                ),
              ),

              // Add Event Button
              if (_selectedDay != null)
                Padding(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 4.0, vertical: 12),
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.add),
                    label: const Text("Add Event"),
                    onPressed: _showAddEventDialog,
                  ),
                ),

              // Events List
              if (_selectedDay != null) ...[
                Text(
                  "Events on ${_selectedDay!.toIso8601String().split("T")[0]}",
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),

                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _getEventsForDay(_selectedDay!).length,
                  itemBuilder: (context, index) {
                    final event = _getEventsForDay(_selectedDay!)[index];
                    return Card(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15)),
                      elevation: 3,
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: ListTile(
                        leading: const Icon(Icons.event_note, color: Colors.teal),
                        title: Text(event,
                            style: const TextStyle(fontSize: 16)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.orange),
                              onPressed: () =>
                                  _showEditEventDialog(index, event),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteEvent(index),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _eventController.dispose();
    super.dispose();
  }
}
