class SchoolTimingEntry {
  final String className;
  final String timeIn;
  final String timeOut;

  SchoolTimingEntry({required this.className, required this.timeIn, required this.timeOut});

  Map<String, dynamic> toMap() {
    return {
      'timeIn': timeIn,
      'timeOut': timeOut,
    };
  }

  factory SchoolTimingEntry.fromMap(String key, Map<String, dynamic> map) {
    return SchoolTimingEntry(
      className: key,
      timeIn: map['timeIn'] ?? '',
      timeOut: map['timeOut'] ?? '',
    );
  }
}
