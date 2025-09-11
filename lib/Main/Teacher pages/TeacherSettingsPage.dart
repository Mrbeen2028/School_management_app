import 'dart:typed_data';
import 'dart:io' show File;
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../login and re and forget/LoginPage.dart';
import '../settingpages/ThemeProvider.dart';

class TeacherSettingsPage extends StatefulWidget {
  const TeacherSettingsPage({super.key});

  @override
  State<TeacherSettingsPage> createState() => _TeacherSettingsPageState();
}

class _TeacherSettingsPageState extends State<TeacherSettingsPage> {
  final user = FirebaseAuth.instance.currentUser;
  final dbRef = FirebaseDatabase.instance.ref("teachers");
  File? _imageFile;           // Mobile only
  Uint8List? _webImageBytes;  // Web only
  Uint8List? _dbImageBytes;   // Decoded image from DB
  final picker = ImagePicker();
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    if (user == null) return;
    try {
      final snapshot = await dbRef.child(user!.uid).get();
      if (snapshot.exists && snapshot.value != null) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        final base64Str = data["profilePicBase64"] as String?;
        if (base64Str != null && base64Str.isNotEmpty) {
          setState(() {
            _dbImageBytes = base64Decode(base64Str);
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
    }
  }

  Future<void> _pickImage() async {
    try {
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile == null) return;

      Uint8List bytes;
      if (kIsWeb) {
        bytes = await pickedFile.readAsBytes();
        setState(() {
          _webImageBytes = bytes;
          _imageFile = null;
        });
      } else {
        bytes = await File(pickedFile.path).readAsBytes();
        setState(() {
          _imageFile = File(pickedFile.path);
          _webImageBytes = null;
        });
      }

      await _uploadProfilePic(bytes);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to pick image. Please try again.')),
        );
      }
    }
  }

  Future<void> _uploadProfilePic(Uint8List bytes) async {
    if (user == null) return;
    setState(() => _isUploading = true);

    try {
      final base64Image = base64Encode(bytes);
      await dbRef.child(user!.uid).update({
        "profilePicBase64": base64Image,
      });

      setState(() {
        _dbImageBytes = bytes;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile picture saved to Realtime Database')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving image: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _changePasswordDialog() async {
    TextEditingController newPassController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text("Change Password"),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: newPassController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: "New Password",
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) return 'Please enter a new password';
              if (value.length < 6) return 'Password must be at least 6 characters';
              return null;
            },
          ),
        ),
        actions: [
          TextButton(child: const Text("Cancel"), onPressed: () => Navigator.pop(context)),
          ElevatedButton(
            child: const Text("Update"),
            onPressed: () async {
              if (formKey.currentState?.validate() ?? false) {
                try {
                  await user?.updatePassword(newPassController.text);
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Password updated successfully")),
                    );
                  }
                } on FirebaseAuthException catch (e) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text("Error: ${e.message}")));
                } catch (e) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text("Error: $e")));
                }
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildUserInfo() {
    String name = user?.displayName ?? "User";
    String email = user?.email ?? "No Email";

    ImageProvider profileImage;
    if (kIsWeb && _webImageBytes != null) {
      profileImage = MemoryImage(_webImageBytes!);
    } else if (!kIsWeb && _imageFile != null) {
      profileImage = FileImage(_imageFile!);
    } else if (_dbImageBytes != null) {
      profileImage = MemoryImage(_dbImageBytes!);
    } else {
      profileImage = const NetworkImage("https://via.placeholder.com/150");
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          children: [
            CircleAvatar(radius: 50, backgroundImage: profileImage),
            if (_isUploading)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                      color: Colors.black38, borderRadius: BorderRadius.circular(50)),
                  child: const Center(child: CircularProgressIndicator(color: Colors.white)),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Text(name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text(email,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text("Settings",
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          children: [
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                child: GestureDetector(
                  onTap: _isUploading ? null : _pickImage,
                  child: _buildUserInfo(),
                ),
              ),
            ),
            const SizedBox(height: 30),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                secondary: const Icon(Icons.dark_mode_outlined),
                title: const Text("Dark Mode",
                    style: TextStyle(fontWeight: FontWeight.w600)),
                value: themeProvider.isDarkMode,
                onChanged: (val) => themeProvider.toggleTheme(val),
              ),
            ),
            const SizedBox(height: 20),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: ListTile(
                leading: const Icon(Icons.lock_outline),
                title: const Text("Change Password",
                    style: TextStyle(fontWeight: FontWeight.w600)),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: _changePasswordDialog,
              ),
            ),
            const SizedBox(height: 20),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: const ListTile(
                leading: Icon(Icons.info_outline),
                title: Text("App Info", style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle:
                Text("Version 1.0.0\nDeveloped by Moaz 😉", style: TextStyle(color: Colors.grey)),
              ),
            ),
            const SizedBox(height: 20),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: ListTile(
                leading: const Icon(Icons.logout, color: Colors.redAccent),
                title: const Text("Logout",
                    style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600)),
                onTap: () async {
                  await FirebaseAuth.instance.signOut();
                  if (!mounted) return;
                  Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const LoginPage()));
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
