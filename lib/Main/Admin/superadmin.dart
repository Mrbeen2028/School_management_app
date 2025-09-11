import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class SuperAdminPage extends StatefulWidget {
  const SuperAdminPage({super.key});

  @override
  State<SuperAdminPage> createState() => _SuperAdminPageState();
}

class _SuperAdminPageState extends State<SuperAdminPage> {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref("users");
  final TextEditingController _searchController = TextEditingController();

  Map<String, dynamic> _users = {};
  Map<String, dynamic> _filteredUsers = {};
  bool _isLoading = true;
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _fetchUsers();

    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
        _filterUsers();
      });
    });
  }

  Future<void> _fetchUsers() async {
    try {
      final snapshot = await _dbRef.get();

      if (snapshot.exists) {
        final rawData = snapshot.value as Map<dynamic, dynamic>;
        final Map<String, dynamic> data = {};

        rawData.forEach((key, value) {
          if (value is Map) {
            data[key.toString()] = Map<String, dynamic>.from(value as Map);
          }
        });

        setState(() {
          _users = data;
          _filterUsers();
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching users: $e')),
      );
    }
  }

  void _filterUsers() {
    final allUsers = _users.entries.where((entry) {
      final user = entry.value;
      final email = user['email']?.toString();
      return email != null && email.isNotEmpty;
    });

    if (_searchQuery.isEmpty) {
      _filteredUsers = Map.fromEntries(allUsers);
    } else {
      _filteredUsers = Map.fromEntries(
        allUsers.where((entry) {
          final name = (entry.value['name'] ?? '').toString().toLowerCase();
          final email = (entry.value['email'] ?? '').toString().toLowerCase();
          return name.contains(_searchQuery) || email.contains(_searchQuery);
        }),
      );
    }
  }

  Future<void> _updateRole(String userId, String newRole) async {
    try {
      await _dbRef.child(userId).update({'role': newRole});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("✅ Role updated to ${getRoleText(newRole)}"),
        ),
      );
      _fetchUsers(); // Refresh
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update role: $e')),
      );
    }
  }

  String getRoleText(dynamic role) {
    switch (role.toString()) {
      case '0':
        return "Admin";
      case '1':
        return "Student";
      case '2':
        return "Teacher";
      default:
        return "Unknown";
    }
  }

  Color getRoleColor(dynamic role) {
    switch (role.toString()) {
      case '0':
        return Colors.redAccent;
      case '1':
        return Colors.blueAccent;
      case '2':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Super Admin Panel'),
        backgroundColor: Colors.deepPurple,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchUsers,
            tooltip: "Refresh Users",
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          // 🔍 Search bar
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by name or email...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
            ),
          ),

          // 📋 Users list
          Expanded(
            child: _filteredUsers.isEmpty
                ? const Center(
                child: Text("No users found.",
                    style: TextStyle(fontSize: 16)))
                : ListView.builder(
              itemCount: _filteredUsers.length,
              itemBuilder: (context, index) {
                final userId =
                _filteredUsers.keys.elementAt(index);
                final user = _filteredUsers[userId] ?? {};

                return Card(
                  margin: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor:
                      getRoleColor(user['role']),
                      child: Text(
                        (user['name'] != null &&
                            user['name'].isNotEmpty)
                            ? user['name'][0].toUpperCase()
                            : "?",
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                    title: Text(
                      user['name'] ?? 'No Name',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                            '📧 ${user['email'] ?? 'No Email'}'),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Text("Role: "),
                            Chip(
                              label: Text(
                                getRoleText(user['role']),
                                style: const TextStyle(
                                    color: Colors.white),
                              ),
                              backgroundColor:
                              getRoleColor(user['role']),
                            ),
                          ],
                        ),
                      ],
                    ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) {
                        _updateRole(userId, value);
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(
                            value: '0',
                            child: Text('Set as Admin')),
                        PopupMenuItem(
                            value: '1',
                            child: Text('Set as Student')),
                        PopupMenuItem(
                            value: '2',
                            child: Text('Set as Teacher')),
                      ],
                      icon: const Icon(Icons.edit,
                          color: Colors.deepPurple),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
