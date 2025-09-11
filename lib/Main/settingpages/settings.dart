import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../login and re and forget/LoginPage.dart';
import 'ThemeProvider.dart';
import 'ChangePasswordPage.dart';
import 'package:firebase_database/firebase_database.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late Future<Map<String, dynamic>> _userDataFuture;
  static const String appVersion = "1.1.1.0";

  @override
  void initState() {
    super.initState();
    _userDataFuture = _fetchUserData();
  }

  Future<Map<String, dynamic>> _fetchUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return {}; // No user logged in
    final dbRef = FirebaseDatabase.instance.ref().child("users").child(user.uid);
    final snapshot = await dbRef.get();

    if (snapshot.exists && snapshot.value is Map) {
      return Map<String, dynamic>.from(snapshot.value as Map);
    } else {
      return {};
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("⚙️ Settings"),
        backgroundColor: Colors.teal,
        elevation: 2,
        centerTitle: true,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _userDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error loading user data: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildContent(context, themeProvider, userName: "User");
          } else {
            return _buildContent(
              context,
              themeProvider,
              userName: snapshot.data!["name"]?.toString() ?? "User",
            );
          }
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, ThemeProvider themeProvider,
      {required String userName}) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 👤 User Info
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 2,
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            leading: CircleAvatar(
              radius: 28,
              backgroundColor: Colors.teal.shade100,
              child: const Icon(Icons.person, size: 32, color: Colors.teal),
            ),
            title: Text(
              userName,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              FirebaseAuth.instance.currentUser?.email ?? "",
              style: const TextStyle(color: Colors.grey),
            ),
          ),
        ),
        const SizedBox(height: 20),

        // 🌙 Dark Mode Toggle
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: SwitchListTile(
            title: const Text("Dark Mode"),
            value: themeProvider.isDarkMode,
            activeColor: Colors.teal,
            onChanged: (val) {
              themeProvider.setDarkMode(val); // ✅ works now
            },
            secondary: const Icon(Icons.dark_mode, color: Colors.teal),
          ),
        ),
        const SizedBox(height: 16),

        // 🔒 Change Password
        _buildSettingTile(
          context,
          icon: Icons.lock,
          title: "Change Password",
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ChangePasswordPage()),
            );
          },
        ),

        // 🚪 Logout
        _buildSettingTile(
          context,
          icon: Icons.logout,
          title: "Logout",
          color: Colors.red,
          onTap: () async {
            await FirebaseAuth.instance.signOut();
            if (context.mounted) {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const LoginPage()),
                    (route) => false,
              );
            }
          },
        ),

        const SizedBox(height: 16),

        // ℹ️ App Info
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: const Icon(Icons.info_outline, color: Colors.teal),
            title: const Text("App Info"),
            subtitle: Text("Version $appVersion"),
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: "School Admin App",
                applicationVersion: appVersion,
                applicationLegalese: "© 2025 ＰＡＮＴＨＥＲＴＥＣＴ Pvt. Ltd.",
              );
            },
          ),
        ),
      ],
    );
  }

  /// 🔹 Helper widget for clean tiles
  Widget _buildSettingTile(BuildContext context,
      {required IconData icon,
        required String title,
        Color color = Colors.teal,
        required VoidCallback onTap}) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 1.5,
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}
