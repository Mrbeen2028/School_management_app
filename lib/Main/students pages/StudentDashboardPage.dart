import 'package:flutter/material.dart';

import 'AcademicsPage.dart';
import 'DiaryPageForStudent.dart';
import 'EventsPageForStudent.dart';
import 'ProfilePageForStudent.dart';
import 'StudentHomePage.dart';

class StudentPanel extends StatefulWidget {
  const StudentPanel({Key? key}) : super(key: key);

  @override
  _StudentPanelState createState() => _StudentPanelState();
}

class _StudentPanelState extends State<StudentPanel> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    StudentHomePage(),
    AcademicsPage(),
    DiaryPageForStudent(),
    EventsPageForStudent(),
    ProfilePageForStudent(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.school),
            label: "Academics",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.book),
            label: "Diary",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.event),
            label: "Events",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: "Profile",
          ),
        ],
      ),
    );
  }
}

