import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'login_screen.dart';
import 'api_debug_screen.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  static const Color primaryBlue = Color(0xFF17175F);
  static const Color pageBackground = Color(0xFFF5F6FA);
  static const Color ink = Color(0xFF24262C);

  Future<void> logout() async {
    await FirebaseAuth.instance.signOut();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  Future<void> deleteUserRecord(String uid) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete User'),
          content: const Text('Delete this user record from Firestore?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).delete();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User record deleted.'),
          backgroundColor: Colors.green,
        ),
      );
    } on FirebaseException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not delete user: ${error.message ?? error.code}',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: pageBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: ink,
        surfaceTintColor: Colors.transparent,
        title: const Row(
          children: [
            Icon(Icons.admin_panel_settings, color: primaryBlue),
            SizedBox(width: 10),
            Text(
              'Admin Dashboard',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'API Debug',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ApiDebugScreen()),
              );
            },
            icon: const Icon(Icons.api),
          ),
          IconButton(
            tooltip: 'Logout',
            onPressed: logout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error loading users:\n${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            );
          }

          final users = snapshot.data?.docs ?? [];

          return Column(
            children: [
              Container(
                margin: const EdgeInsets.fromLTRB(22, 22, 22, 18),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFE7E7F8),
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.people, color: primaryBlue, size: 30),
                    ),
                    const SizedBox(width: 15),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Registered Users',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF68718A),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          users.length.toString(),
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: ink,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              Expanded(
                child: users.isEmpty
                    ? const Center(child: Text('No users found'))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 22),
                        itemCount: users.length,
                        itemBuilder: (context, index) {
                          final doc = users[index];
                          final data = doc.data();

                          final name =
                              data['name']?.toString() ?? 'Unknown User';

                          final email = data['email']?.toString() ?? 'No email';

                          final role = data['role']?.toString() ?? 'user';

                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: primaryBlue.withValues(
                                  alpha: 0.12,
                                ),
                                child: const Icon(
                                  Icons.person,
                                  color: primaryBlue,
                                ),
                              ),
                              title: Text(
                                name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(email),
                                  const SizedBox(height: 3),
                                  Text(
                                    'Role: $role',
                                    style: TextStyle(
                                      color: role == 'admin'
                                          ? Colors.red
                                          : Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                              trailing: role == 'admin'
                                  ? const Icon(
                                      Icons.admin_panel_settings,
                                      color: Colors.red,
                                    )
                                  : IconButton(
                                      tooltip: 'Delete user record',
                                      icon: const Icon(
                                        Icons.delete_outline,
                                        color: Colors.red,
                                      ),
                                      onPressed: () {
                                        deleteUserRecord(doc.id);
                                      },
                                    ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
