import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:project_final/Main/Teacher%20pages/TeacherPage.dart';
import 'package:provider/provider.dart';
import 'package:project_final/Main/settingpages/ThemeProvider.dart';
import 'package:project_final/Main/settingpages/settings.dart';
import 'package:project_final/firebase_options.dart';
import 'Admin/AdminPage.dart';
import 'Admin/StudentListPage.dart';
import 'login and re and forget/LoginPage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: 'School App',
      debugShowCheckedModeBanner: false,
      theme: themeProvider.isDarkMode ? ThemeData.dark() : ThemeData.light(),
      home: const LoginPage(), // You can also use LoginPage() or SettingsPage() here
    );
  }
}
