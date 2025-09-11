class TimetableEntry {
  final String id;
  final String subject;
  final String day;
  final String startTime;
  final String endTime;

  TimetableEntry({
    required this.id,
    required this.subject,
    required this.day,
    required this.startTime,
    required this.endTime,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'subject': subject,
      'day': day,
      'startTime': startTime,
      'endTime': endTime,
    };
  }

  factory TimetableEntry.fromMap(Map<String, dynamic> map) {
    return TimetableEntry(
      id: map['id'],
      subject: map['subject'],
      day: map['day'],
      startTime: map['startTime'],
      endTime: map['endTime'],
    );
  }
}
