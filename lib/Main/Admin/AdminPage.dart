import 'package:flutter/material.dart';
import 'package:project_final/Main/Admin/timing/TimetablePage.dart';
import '../Teacher pages/AttendancePage.dart';
import '../settingpages/settings.dart';
import 'AdminTeacherAttendancePage.dart';
import 'AdminTeacherLeavePage.dart';
import 'AttendancePage2.dart';
import 'DailyDiaryPage.dart';
import 'SchoolEventsPage.dart';
import 'StudentListPage.dart';
import 'StudentUploadPage.dart';
import 'TeacherPeriodPlanAdminPage.dart';
import 'superadmin.dart';

class AdminPage extends StatelessWidget {
  const AdminPage({super.key});

  final String _superAdminPassword = '12345';

  void navigateToSuperAdminPage(BuildContext context) {
    final passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Enter Super Admin Password'),
        content: TextField(
          controller: passwordController,
          obscureText: true,
          decoration: const InputDecoration(
            hintText: 'Password',
            prefixIcon: Icon(Icons.lock_outline),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              if (passwordController.text == _superAdminPassword) {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SuperAdminPage(),
                  ),
                );
              } else {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Wrong password')),
                );
              }
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // 🎨 Admin dashboard theme
    final tileColor = isDarkMode ? Colors.blueGrey[800] : Colors.indigo[50];
    final iconColor = isDarkMode ? Colors.amber[200] : Colors.indigo[700];
    final textColor = isDarkMode ? Colors.white : Colors.indigo[900];

    final tiles = [
      {
        'icon': Icons.upload_file,
        'label': 'Upload',
        'page': const StudentUploadPage(studentKey: '', studentData: {})
      },
      {'icon': Icons.list, 'label': 'Students', 'page': const StudentListPage()},
      {'icon': Icons.event, 'label': 'Events', 'page': const EventCalendarPage()},
      {'icon': Icons.book, 'label': 'Diary', 'page': HomeworkDiaryPage()},
      {'icon': Icons.schedule, 'label': 'Timetable', 'page': const TimetablePage()},
      {'icon': Icons.event, 'label': 'Teacher Attendance', 'page': const AdminTeacherAttendancePage ()},
      {'icon': Icons.backpack_outlined, 'label': 'Teacher Leaves', 'page': const AdminTeacherLeavePage()},
      {
        'icon': Icons.calendar_view_week,
        'label': 'Period Plan',
        'page': const TeacherPeriodPlanAdminPage(),
      },
      {
        'icon': Icons.check_circle,
        'label': 'Student Attendance',
        'page': Attendanceby(
          role: "admin",        // ✅ role passed
          userName: "Admin",    // ✅ admin name
          userUid: "adminUid",  // ✅ admin UID added
        ),
      },
      {'icon': Icons.settings, 'label': 'Settings', 'page': const SettingsPage()},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Teacher Dashboard'),
        backgroundColor: Colors.indigo,
        elevation: 4,
        actions: [
          IconButton(
            icon: const Icon(Icons.admin_panel_settings),
            onPressed: () => navigateToSuperAdminPage(context),
          ),
        ],
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
