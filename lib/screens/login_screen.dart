import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'home_screen.dart';
import 'register_screen.dart';
import 'admin_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();

  final TextEditingController passwordController = TextEditingController();

  bool loading = false;
  bool obscurePassword = true;

  static const Color primaryBlue = Color(0xFF17175F);

  // ============================================================
  // LOGIN
  // ============================================================

  Future<void> login() async {
    if (loading) return;

    final String email = emailController.text.trim();

    final String password = passwordController.text;

    if (email.isEmpty) {
      showMessage('Please enter your email.');
      return;
    }

    if (password.isEmpty) {
      showMessage('Please enter your password.');
      return;
    }

    setState(() {
      loading = true;
    });

    try {
      // ----------------------------------------------------------
      // FIREBASE AUTHENTICATION
      // ----------------------------------------------------------

      final UserCredential credential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      final User? user = credential.user;

      if (user == null) {
        throw Exception('Firebase did not return a user.');
      }

      // ----------------------------------------------------------
      // GET USER ROLE
      // ----------------------------------------------------------

      final DocumentSnapshot<Map<String, dynamic>> userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();

      String role = 'user';

      if (userDoc.exists && userDoc.data() != null) {
        role = userDoc.data()?['role']?.toString().toLowerCase() ?? 'user';
      } else {
        // If the user exists in Authentication
        // but Firestore document is missing,
        // create a basic user document.
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'email': user.email ?? email,
          'name': user.displayName ?? 'User',
          'role': 'user',
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      if (!mounted) return;

      // ----------------------------------------------------------
      // ADMIN
      // ----------------------------------------------------------

      if (role == 'admin') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AdminScreen()),
        );
      }
      // ----------------------------------------------------------
      // NORMAL USER
      // ----------------------------------------------------------
      else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } on FirebaseAuthException catch (e) {
      String message;

      switch (e.code) {
        case 'invalid-email':
          message = 'Invalid email address.';
          break;

        case 'user-not-found':
          message = 'No account found with this email.';
          break;

        case 'wrong-password':
          message = 'Incorrect password.';
          break;

        case 'invalid-credential':
          message = 'Incorrect email or password.';
          break;

        case 'user-disabled':
          message = 'This account has been disabled.';
          break;

        case 'too-many-requests':
          message = 'Too many login attempts. Please try again later.';
          break;

        case 'network-request-failed':
          message = 'Network error. Check your internet connection.';
          break;

        case 'operation-not-allowed':
          message = 'Email/password login is not enabled in Firebase.';
          break;

        default:
          message = 'Firebase error: ${e.code}\n${e.message ?? ''}';
      }

      showMessage(message);
    } on FirebaseException catch (e) {
      showMessage('Firebase error: ${e.code}\n${e.message ?? ''}');
    } catch (e) {
      showMessage('Login failed: $e');
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),

      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),

            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),

              child: Column(
                children: [
                  const SizedBox(height: 20),

                  // ------------------------------------------------
                  // LOGO
                  // ------------------------------------------------
                  Container(
                    height: 90,
                    width: 90,
                    decoration: BoxDecoration(
                      color: primaryBlue,
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: const Icon(
                      Icons.task_alt,
                      size: 55,
                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 20),

                  const Text(
                    'AI Work Planner',
                    style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    'Plan smarter. Work better.',
                    style: TextStyle(color: Colors.grey, fontSize: 15),
                  ),

                  const SizedBox(height: 35),

                  // ------------------------------------------------
                  // EMAIL
                  // ------------------------------------------------
                  TextField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,

                    decoration: InputDecoration(
                      labelText: 'Email',
                      hintText: 'Enter your registered email',
                      prefixIcon: const Icon(Icons.email_outlined),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ------------------------------------------------
                  // PASSWORD
                  // ------------------------------------------------
                  TextField(
                    controller: passwordController,
                    obscureText: obscurePassword,
                    textInputAction: TextInputAction.done,

                    onSubmitted: (_) {
                      if (!loading) {
                        login();
                      }
                    },

                    decoration: InputDecoration(
                      labelText: 'Password',
                      hintText: 'Enter your password',
                      prefixIcon: const Icon(Icons.lock_outline),

                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() {
                            obscurePassword = !obscurePassword;
                          });
                        },
                        icon: Icon(
                          obscurePassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                      ),

                      filled: true,
                      fillColor: Colors.white,

                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),

                  const SizedBox(height: 25),

                  // ------------------------------------------------
                  // LOGIN BUTTON
                  // ------------------------------------------------
                  SizedBox(
                    width: double.infinity,
                    height: 52,

                    child: ElevatedButton(
                      onPressed: loading ? null : login,

                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryBlue,
                        foregroundColor: Colors.white,

                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),

                      child: loading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : const Text(
                              'Login',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  // ------------------------------------------------
                  // REGISTER
                  // ------------------------------------------------
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Don't have an account? ",
                        style: TextStyle(color: Colors.grey),
                      ),

                      TextButton(
                        onPressed: loading
                            ? null
                            : () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const RegisterScreen(),
                                  ),
                                );
                              },
                        child: const Text(
                          'Register',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  const Text(
                    'Use the email and password you registered with.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}
