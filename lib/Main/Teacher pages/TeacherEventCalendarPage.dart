import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:firebase_database/firebase_database.dart';

class TeacherEventCalendarPage extends StatefulWidget {
  const TeacherEventCalendarPage({Key? key}) : super(key: key);

  @override
  State<TeacherEventCalendarPage> createState() =>
      _TeacherEventCalendarPageState();
}

class _TeacherEventCalendarPageState extends State<TeacherEventCalendarPage> {
  CalendarFormat _calendarFormat = CalendarFormat.month;

  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay = DateTime.now();

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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text("📅 School Events",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.deepPurple, Colors.indigo],
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
                        color: Colors.deepPurple.shade300,
                        shape: BoxShape.circle),
                    selectedDecoration: const BoxDecoration(
                        color: Colors.indigo, shape: BoxShape.circle),
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

              const SizedBox(height: 20),

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
                        leading: const Icon(Icons.event_note,
                            color: Colors.deepPurple),
                        title: Text(event,
                            style: const TextStyle(fontSize: 16)),
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
}
