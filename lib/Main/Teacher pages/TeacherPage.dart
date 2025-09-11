import 'package:flutter/material.dart';
import '../login and re and forget/LoginPage.dart';
import 'TeacherAttendancePage.dart';
import 'TeacherEventCalendarPage.dart';
import 'TeacherLeavePage.dart';
import 'TeacherSchoolTimingPage.dart';
import 'TeacherSettingsPage.dart';
import 'TeacherStudentListPage.dart';
import 'AttendancePage.dart';
import 'TeacherHomeworkDiaryPage.dart';
import 'TeacherPeriodPlanPage.dart';

class TeacherHomePage extends StatelessWidget {
  final String userName; // ✅ teacher name from login
  final String role;     // ✅ teacher role

  const TeacherHomePage({
    super.key,
    required this.userName,
    required this.role,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // 🎨 Dashboard theme (same as AdminPage)
    final tileColor = isDarkMode ? Colors.blueGrey[800] : Colors.teal[50];
    final iconColor = isDarkMode ? Colors.amber[200] : Colors.teal[700];
    final textColor = isDarkMode ? Colors.white : Colors.teal[900];

    final tiles = [
      {
        'icon': Icons.fact_check,
        'label': 'Attendance',
        'page': AttendancePage(
          role: role,
          userName: userName,
        ),
      },
      {
        'icon': Icons.book,
        'label': 'Homework Diary',
        'page': TeacherHomeworkDiaryPage(
          teacherName: userName,
        ),
      },
      {
        'icon': Icons.event,
        'label': 'Events',
        'page': const TeacherEventCalendarPage(),
      },
      {
        'icon': Icons.event,
        'label': 'Teacher Leave',
        'page': TeacherLeavePage(
          teacherId: userName,   // ⚡ using userName as temporary ID
          teacherName: userName, // 👈 pass teacherName
        ),
      },
      {
        'icon': Icons.people,
        'label': 'Student List',
        'page': const TeacherStudentListPage(),
      }, {
        'icon': Icons.fact_check,
        'label': 'Your Attendance',
        'page': TeacherAttendancePage(
          teacherId: userName,   // or use FirebaseAuth.instance.currentUser!.uid
          teacherName: userName,
        ),
      },

      {
        'icon': Icons.access_time_rounded,
        'label': 'School Timing',
        'page': const TeacherSchoolTimingPage(),
      },
      {
        'icon': Icons.schedule,
        'label': 'Period Plan',
        'page': const TeacherPeriodPlanPage(),
      },
      {
        'icon': Icons.settings,
        'label': 'Setting',
        'page': const TeacherSettingsPage(),
      },
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.teal,
        title: const Center(
          child: Text(
            "Teacher Dashboard",
            style: TextStyle(color: Colors.white),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.count(
          crossAxisCount: 2, // 📌 2 tiles per row
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: tiles.map((tile) {
            return GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => tile['page'] as Widget),
              ),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [tileColor!, Colors.white],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 6,
                      offset: const Offset(2, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(tile['icon'] as IconData,
                        size: 40, color: iconColor),
                    const SizedBox(height: 10),
                    Text(
                      tile['label'] as String,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
