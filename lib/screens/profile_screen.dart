import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

import '../services/notification_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const Color navy = Color(0xFF17175F);
  static const Color mint = Color(0xFF55D5C3);
  static const Color pageBackground = Color(0xFFF5F6FA);

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Map<String, dynamic> userData = {};

  bool isLoading = true;
  bool isUploadingPhoto = false;
  bool isPickingPhoto = false;
  bool notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    loadProfile();
  }

  Future<void> loadProfile() async {
    try {
      final user = _auth.currentUser;

      if (user == null) {
        if (mounted) {
          setState(() {
            isLoading = false;
          });
        }
        return;
      }

      final document = await _firestore.collection('users').doc(user.uid).get();

      if (document.exists) {
        userData = document.data() ?? {};
        notificationsEnabled = userData['notificationsEnabled'] != false;
      }

      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> logout() async {
    await _auth.signOut();

    if (!mounted) return;

    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  Future<void> editWhatsAppNumber() async {
    final controller = TextEditingController(
      text: userData['whatsappNumber']?.toString() ?? '',
    );

    final number = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('WhatsApp number'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            labelText: 'International number',
            hintText: '919876543210',
            prefixIcon: Icon(Icons.phone),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();

    final normalizedNumber = number?.replaceAll(RegExp(r'[^0-9]'), '');

    if (normalizedNumber == null ||
        !RegExp(r'^\d{8,15}$').hasMatch(normalizedNumber)) {
      if (number != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Enter a valid number with country code.'),
          ),
        );
      }
      return;
    }

    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore.collection('users').doc(user.uid).set({
        'whatsappNumber': normalizedNumber,
      }, SetOptions(merge: true));

      if (!mounted) return;
      setState(() {
        userData['whatsappNumber'] = normalizedNumber;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('WhatsApp number saved.'),
          backgroundColor: Colors.green,
        ),
      );
    } on FirebaseException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not save WhatsApp number: ${error.message ?? error.code}',
          ),
          backgroundColor: Colors.red,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not save WhatsApp number. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> uploadProfilePicture() async {
    final user = _auth.currentUser;
    if (user == null || isUploadingPhoto || isPickingPhoto) return;

    setState(() {
      isPickingPhoto = true;
    });

    XFile? image;
    try {
      image = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 900,
      );
    } on PlatformException catch (error) {
      if (mounted && error.code != 'already_active') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Unable to open photo picker: ${error.message ?? error.code}',
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isPickingPhoto = false;
        });
      }
    }

    if (image == null || !mounted) return;

    setState(() {
      isUploadingPhoto = true;
    });

    try {
      final reference = FirebaseStorage.instance
          .ref()
          .child('users')
          .child(user.uid)
          .child('profile.jpg');
      await reference.putData(
        await image.readAsBytes(),
        SettableMetadata(contentType: 'image/jpeg'),
      );
      final photoUrl = await reference.getDownloadURL();

      await _firestore.collection('users').doc(user.uid).set({
        'photoUrl': photoUrl,
      }, SetOptions(merge: true));
      await loadProfile();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to upload picture: $error')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isUploadingPhoto = false;
        });
      }
    }
  }

  Future<void> updateNotifications(bool enabled) async {
    final user = _auth.currentUser;
    if (user == null) return;

    setState(() {
      notificationsEnabled = enabled;
    });

    await _firestore.collection('users').doc(user.uid).set({
      'notificationsEnabled': enabled,
    }, SetOptions(merge: true));

    if (!enabled) {
      await NotificationService.cancelAllNotifications();
    }
  }

  String getValue(String field, String defaultValue) {
    final value = userData[field];

    if (value == null || value.toString().trim().isEmpty) {
      return defaultValue;
    }

    return value.toString();
  }

  @override
  Widget build(BuildContext context) {
    final User? firebaseUser = _auth.currentUser;

    final String name = getValue('name', 'User');

    final String email = getValue('email', firebaseUser?.email ?? '');

    final String role = getValue('role', 'Student');

    final String photoUrl = getValue('photoUrl', '');

    return Scaffold(
      backgroundColor: pageBackground,

      appBar: AppBar(
        backgroundColor: navy,
        foregroundColor: Colors.white,
        title: const Text(
          'Profile',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),

      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: loadProfile,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const SizedBox(height: 10),

                    // PROFILE IMAGE
                    GestureDetector(
                      onTap: isUploadingPhoto || isPickingPhoto
                          ? null
                          : uploadProfilePicture,
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          CircleAvatar(
                            radius: 58,
                            backgroundColor: const Color(0xFFE7E7F8),
                            backgroundImage: photoUrl.isNotEmpty
                                ? NetworkImage(photoUrl)
                                : null,
                            child: isUploadingPhoto || isPickingPhoto
                                ? const CircularProgressIndicator()
                                : photoUrl.isEmpty
                                ? const Icon(
                                    Icons.person,
                                    size: 58,
                                    color: navy,
                                  )
                                : null,
                          ),
                          if (!isUploadingPhoto)
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: mint,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.camera_alt_outlined,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 8),
                    const Text(
                      'Tap the camera to change your picture',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),

                    const SizedBox(height: 16),

                    // NAME
                    Text(
                      name,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 5),

                    // EMAIL
                    Text(
                      email,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.grey, fontSize: 14),
                    ),

                    const SizedBox(height: 10),

                    // ROLE
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: role.toLowerCase() == 'admin'
                            ? Colors.orange.shade50
                            : const Color(0xFFE7E7F8),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Text(
                        role,
                        style: TextStyle(
                          color: role.toLowerCase() == 'admin'
                              ? Colors.orange.shade800
                              : navy,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    const SizedBox(height: 25),

                    // INFORMATION CARD
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          profileItem(
                            icon: Icons.person_outline,
                            title: 'Full Name',
                            value: name,
                          ),

                          const Divider(height: 28),

                          profileItem(
                            icon: Icons.email_outlined,
                            title: 'Email',
                            value: email,
                          ),

                          const Divider(height: 28),

                          profileItem(
                            icon: Icons.chat_outlined,
                            title: 'WhatsApp',
                            value: getValue('whatsappNumber', 'Not provided'),
                            onTap: editWhatsAppNumber,
                          ),

                          const Divider(height: 28),

                          profileItem(
                            icon: Icons.admin_panel_settings_outlined,
                            title: 'Account Type',
                            value: role,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // SETTINGS
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 5,
                        ),
                        leading: Container(
                          height: 45,
                          width: 45,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE7E7F8),
                            borderRadius: BorderRadius.circular(13),
                          ),
                          child: const Icon(
                            Icons.settings_outlined,
                            color: navy,
                          ),
                        ),
                        title: const Text(
                          'Settings',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: const Text('App preferences'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () async {
                          await showDialog<void>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Settings'),
                              content: SwitchListTile(
                                contentPadding: EdgeInsets.zero,
                                title: const Text('Task notifications'),
                                subtitle: const Text(
                                  'Receive reminders before tasks are due',
                                ),
                                value: notificationsEnabled,
                                onChanged: (value) {
                                  updateNotifications(value);
                                  Navigator.pop(context);
                                },
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 20),

                    // LOGOUT
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton.icon(
                        onPressed: logout,
                        icon: const Icon(Icons.logout),
                        label: const Text(
                          'Logout',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
    );
  }

  Widget profileItem({
    required IconData icon,
    required String title,
    required String value,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(13),
      child: Row(
        children: [
          Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFE7E7F8),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: navy),
          ),

          const SizedBox(width: 15),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
