// student_upload_page.dart
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class StudentUploadPage extends StatefulWidget {
  final bool isUpdateMode;
  final String? studentKey;
  final Map<String, dynamic>? studentData;

  const StudentUploadPage({
    Key? key,
    this.isUpdateMode = false,
    this.studentKey,
    this.studentData,
  }) : super(key: key);

  @override
  _StudentUploadPageState createState() => _StudentUploadPageState();
}

class _StudentUploadPageState extends State<StudentUploadPage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _nameController = TextEditingController();
  final _fatherNameController = TextEditingController();
  final _cnicController = TextEditingController();
  final _medicalDisorderController = TextEditingController();
  final _guardianContactNumberController = TextEditingController();
  final _rollNumberController = TextEditingController();
  final _monthlyFeesController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  String? _imageUrl;
  Uint8List? _imageBytes;
  bool _isLoading = false;

  String? _selectedClass;
  String? _selectedSection;

  final List<String> _classes = [
    'PG',
    'Nursery',
    'KG',
    '1',
    '2',
    '3',
    '4',
    '5',
    '6',
    '7',
    '8',
    '9',
    '10'
  ];
  final List<String> _sections = ['A', 'B', 'C'];

  @override
  void initState() {
    super.initState();
    if (widget.studentData != null) {
      final data = widget.studentData!;
      _nameController.text = data['name'] ?? '';
      _fatherNameController.text = data['fatherName'] ?? '';
      _cnicController.text = data['cnic'] ?? '';
      _medicalDisorderController.text = data['medicalDisorder'] ?? '';
      _guardianContactNumberController.text =
          data['guardianContactNumber'] ?? '';
      _rollNumberController.text = data['rollNumber'] ?? '';
      _monthlyFeesController.text = data['monthlyFees'] ?? '';
      _imageUrl = data['imageUrl'];
      _selectedClass = data['class'];
      _selectedSection = data['section'];
      _emailController.text = data['email'] ?? '';

      if (data['photoBase64'] != null && (data['photoBase64'] as String).isNotEmpty) {
        try {
          _imageBytes = base64Decode(data['photoBase64']);
        } catch (e) {
          debugPrint('Failed to decode base64 image: $e');
        }
      }
    }
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 70,
      );

      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _imageBytes = bytes;
          _imageUrl = null;
        });
      }
    } catch (e) {
      _showErrorMessage('Failed to pick image: $e');
    }
  }

  Future<void> _uploadImage() async {
    if (_imageBytes != null && !kIsWeb) {
      try {
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('student_images')
            .child('${DateTime.now().millisecondsSinceEpoch}.jpg');

        final uploadTask = storageRef.putData(
          _imageBytes!,
          SettableMetadata(contentType: 'image/jpeg'),
        );

        await uploadTask;
        _imageUrl = await storageRef.getDownloadURL();
      } catch (e) {
        throw Exception('Image upload failed: $e');
      }
    }
  }

  String? _validateCNIC(String? value) {
    if (value == null || value.isEmpty) return 'CNIC is required';
    final cleanValue = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanValue.length != 13) return 'CNIC must be 13 digits';
    return null;
  }

  String? _validatePhoneNumber(String? value) {
    if (value == null || value.isEmpty) return 'Contact number is required';
    final cleanValue = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanValue.length < 11) return 'Please enter a valid phone number';
    return null;
  }

  String? _validateFees(String? value) {
    if (value == null || value.isEmpty) return 'Monthly fees is required';
    final numValue = double.tryParse(value);
    if (numValue == null || numValue <= 0) return 'Please enter a valid amount';
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) return 'Email is required';
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    if (!emailRegex.hasMatch(value)) return 'Enter a valid email';
    return null;
  }

  void _showErrorMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showSuccessMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Widget buildTextField({
    required TextEditingController controller,
    required String label,
    IconData? icon,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    bool obscureText = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        obscureText: obscureText,
        validator:
        validator ?? (v) => (v?.isEmpty ?? true) ? "Required" : null,
        decoration: InputDecoration(
          prefixIcon: icon != null ? Icon(icon, color: Colors.teal) : null,
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.teal[50],
        ),
      ),
    );
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final studentRef = FirebaseDatabase.instance.ref().child('users');
      final rollNumber = _rollNumberController.text.trim();
      final email = _emailController.text.trim();

      // Duplicate roll check
      final snapshot =
      await studentRef.orderByChild("rollNumber").equalTo(rollNumber).get();

      bool rollExists = false;
      if (snapshot.exists) {
        for (final child in snapshot.children) {
          if (!widget.isUpdateMode || child.key != widget.studentKey) {
            rollExists = true;
            break;
          }
        }
      }

      if (rollExists) {
        // stop loading before returning
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
        _showErrorMessage("This Roll Number is already taken!");
        return;
      }

      // Optional: Check duplicate email
      // (We won't query DB by email here; firebase auth createUser will fail if email already exists)
      // Upload image when not web
      if (!kIsWeb && _imageBytes != null) {
        await _uploadImage();
      }

      final studentData = <String, Object?>{
        'name': _nameController.text.trim(),
        'fatherName': _fatherNameController.text.trim(),
        'cnic': _cnicController.text.replaceAll(RegExp(r'[^0-9]'), ''),
        'medicalDisorder': _medicalDisorderController.text.trim(),
        'guardianContactNumber': _guardianContactNumberController.text.trim(),
        'monthlyFees': _monthlyFeesController.text.trim(),
        'class': _selectedClass ?? "",
        'section': _selectedSection ?? "",
        'rollNumber': rollNumber,
        'email': email,
        'role': 'student',
        'createdAt': ServerValue.timestamp,
        'updatedAt': ServerValue.timestamp,
      };

      if (kIsWeb && _imageBytes != null) {
        studentData['photoBase64'] = base64Encode(_imageBytes!);
        studentData['imageUrl'] = "";
      } else if (_imageUrl != null && _imageUrl!.isNotEmpty) {
        studentData['imageUrl'] = _imageUrl!;
        studentData['photoBase64'] = "";
      } else {
        studentData['imageUrl'] = "";
        studentData['photoBase64'] = "";
      }

      // If creating new student -> create auth user (optional)
      if (!widget.isUpdateMode) {
        // create a FirebaseAuth user for the student using provided email and password
        if (email.isNotEmpty) {
          final password = _passwordController.text.trim().isNotEmpty
              ? _passwordController.text.trim()
              : '123456'; // default password if admin didn't provide
          try {
            await FirebaseAuth.instance.createUserWithEmailAndPassword(
              email: email,
              password: password,
            );
            // Note: we are not signing-in as that new user, just creating the account
          } on FirebaseAuthException catch (authErr) {
            // If account exists, just continue (or you can show error)
            if (authErr.code == 'email-already-in-use') {
              // continue but warn admin
              _showErrorMessage(
                  'Email already in use in Firebase Auth. Student record will still be saved in DB.');
            } else {
              // stop and show error
              if (mounted) {
                setState(() {
                  _isLoading = false;
                });
              }
              _showErrorMessage('Auth error: ${authErr.message}');
              return;
            }
          } catch (e) {
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
            }
            _showErrorMessage('Auth error: $e');
            return;
          }
        }
      }

      if (widget.isUpdateMode && widget.studentKey != null) {
        await studentRef.child(widget.studentKey!).update(studentData);
      } else {
        await studentRef.push().set(studentData);
      }


      _showSuccessMessage(
          'Student ${widget.isUpdateMode ? 'updated' : 'added'} successfully!');

      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) Navigator.pop(context, true);
    } catch (e, stack) {
      debugPrint("❌ Error submitting form: $e");
      debugPrint("$stack");
      _showErrorMessage("Error: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _fatherNameController.dispose();
    _cnicController.dispose();
    _medicalDisorderController.dispose();
    _guardianContactNumberController.dispose();
    _rollNumberController.dispose();
    _monthlyFeesController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final imageProvider = _imageBytes != null
        ? MemoryImage(_imageBytes!)
        : (_imageUrl != null && _imageUrl!.isNotEmpty
        ? NetworkImage(_imageUrl!)
        : null) as ImageProvider<Object>?;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isUpdateMode ? "Update Student" : "Add Student"),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _isLoading ? null : _pickImage,
                    child: CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.teal[100],
                      backgroundImage: imageProvider,
                      child: imageProvider == null
                          ? Icon(Icons.person, size: 60, color: Colors.teal[700])
                          : null,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextButton.icon(
                    onPressed: _isLoading ? null : _pickImage,
                    icon: const Icon(Icons.photo, color: Colors.teal),
                    label: const Text("Choose Photo",
                        style: TextStyle(color: Colors.teal)),
                  ),
                  const SizedBox(height: 20),

                  // Personal Info Card
                  Card(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          buildTextField(
                            controller: _nameController,
                            label: "Full Name",
                            icon: Icons.person,
                          ),
                          buildTextField(
                            controller: _fatherNameController,
                            label: "Father Name",
                            icon: Icons.man,
                          ),
                          buildTextField(
                            controller: _cnicController,
                            label: "CNIC (13 digits)",
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(13),
                            ],
                            validator: _validateCNIC,
                            icon: Icons.credit_card,
                          ),
                          buildTextField(
                            controller: _medicalDisorderController,
                            label: "Medical Disorder (Optional)",
                            icon: Icons.local_hospital,
                            validator: null,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 15),

                  // Contact & Fees Card
                  Card(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          buildTextField(
                            controller: _guardianContactNumberController,
                            label: "Guardian Contact",
                            icon: Icons.phone,
                            keyboardType: TextInputType.phone,
                            validator: _validatePhoneNumber,
                          ),
                          buildTextField(
                            controller: _monthlyFeesController,
                            label: "Monthly Fees",
                            keyboardType: TextInputType.number,
                            icon: Icons.attach_money,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                  RegExp(r'^\d+\.?\d{0,2}')),
                            ],
                            validator: _validateFees,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 15),

                  // Class & Section
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedClass,
                          decoration: InputDecoration(
                            labelText: 'Class',
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12)),
                            filled: true,
                            fillColor: Colors.teal[50],
                          ),
                          items: _classes.map((cls) {
                            return DropdownMenuItem<String>(
                                value: cls, child: Text(cls));
                          }).toList(),
                          onChanged:
                          _isLoading ? null : (v) => setState(() => _selectedClass = v),
                          validator: (v) => v == null ? "Required" : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedSection,
                          decoration: InputDecoration(
                            labelText: 'Section',
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12)),
                            filled: true,
                            fillColor: Colors.teal[50],
                          ),
                          items: _sections.map((sec) {
                            return DropdownMenuItem<String>(
                                value: sec, child: Text(sec));
                          }).toList(),
                          onChanged:
                          _isLoading ? null : (v) => setState(() => _selectedSection = v),
                          validator: (v) => v == null ? "Required" : null,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),
                  buildTextField(
                    controller: _rollNumberController,
                    label: "Roll Number",
                    icon: Icons.numbers,
                  ),

                  const SizedBox(height: 12),

                  // Email & Optional Password
                  Card(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 1,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          buildTextField(
                            controller: _emailController,
                            label: "Student Email (for login)",
                            icon: Icons.email,
                            keyboardType: TextInputType.emailAddress,
                            validator: _validateEmail,
                          ),
                          const SizedBox(height: 8),
                          buildTextField(
                            controller: _passwordController,
                            label:
                            "Password (optional — default: 123456 if empty)",
                            icon: Icons.lock,
                            obscureText: true,
                            validator: null,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),

          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.teal),
                ),
              ),
            ),
        ],
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isLoading ? null : _submitForm,
        backgroundColor: _isLoading ? Colors.grey : Colors.teal,
        icon: _isLoading
            ? const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        )
            : const Icon(Icons.save),
        label: Text(_isLoading ? "Saving..." : (widget.isUpdateMode ? "Update" : "Save")),
      ),
    );
  }
}
