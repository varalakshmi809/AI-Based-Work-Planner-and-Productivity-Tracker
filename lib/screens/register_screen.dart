import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController whatsappController = TextEditingController();

  bool loading = false;
  bool obscurePassword = true;

  static const Color primaryBlue = Color(0xFF17175F);

  // ============================================================
  // PASSWORD VALIDATION
  // ============================================================

  bool isPasswordValid(String password) {
    return password.length >= 10 &&
        RegExp(r'[A-Z]').hasMatch(password) &&
        RegExp(r'[a-z]').hasMatch(password) &&
        RegExp(r'[0-9]').hasMatch(password) &&
        RegExp(r'[!@#$%^&*(),.?":{}|<>_\-\\/\[\]]').hasMatch(password);
  }

  // ============================================================
  // REGISTER
  // ============================================================

  Future<void> register() async {
    final String name = nameController.text.trim();
    final String email = emailController.text.trim();
    final String password = passwordController.text;

    final String whatsappNumber = whatsappController.text.replaceAll(
      RegExp(r'[^0-9]'),
      '',
    );

    // ----------------------------------------------------------
    // BASIC VALIDATION
    // ----------------------------------------------------------

    if (name.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        whatsappNumber.isEmpty) {
      _showMessage('Please fill all fields.', isError: true);
      return;
    }

    // ----------------------------------------------------------
    // EMAIL VALIDATION
    // ----------------------------------------------------------

    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      _showMessage('Please enter a valid email address.', isError: true);
      return;
    }

    // ----------------------------------------------------------
    // WHATSAPP VALIDATION
    // ----------------------------------------------------------

    if (!RegExp(r'^\d{8,15}$').hasMatch(whatsappNumber)) {
      _showMessage(
        'Enter a valid WhatsApp number with country code.',
        isError: true,
      );
      return;
    }

    // ----------------------------------------------------------
    // PASSWORD VALIDATION
    // ----------------------------------------------------------

    if (!isPasswordValid(password)) {
      _showMessage(
        'Password does not meet the required conditions.',
        isError: true,
      );
      return;
    }

    setState(() {
      loading = true;
    });

    try {
      // --------------------------------------------------------
      // CREATE FIREBASE AUTH ACCOUNT
      // --------------------------------------------------------

      final UserCredential credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      final User? user = credential.user;

      if (user == null) {
        throw Exception('Registration failed.');
      }

      // --------------------------------------------------------
      // SAVE DISPLAY NAME
      // --------------------------------------------------------

      await user.updateDisplayName(name);

      // --------------------------------------------------------
      // SAVE USER DATA IN FIRESTORE
      // --------------------------------------------------------

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'name': name,
        'email': email,
        'whatsappNumber': whatsappNumber,
        'role': 'user',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // --------------------------------------------------------
      // SIGN OUT AFTER REGISTRATION
      // --------------------------------------------------------
      //
      // Firebase automatically signs in the newly created user.
      // We sign them out because your requirement is:
      //
      // REGISTER → LOGIN PAGE → MANUAL LOGIN → HOME
      //
      // --------------------------------------------------------

      await FirebaseAuth.instance.signOut();

      if (!mounted) return;

      // --------------------------------------------------------
      // SUCCESS MESSAGE
      // --------------------------------------------------------

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Registration successful. Please login with your registered email and password.',
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 4),
        ),
      );

      // --------------------------------------------------------
      // GO TO LOGIN PAGE
      // --------------------------------------------------------

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      String message = 'Registration failed.';

      switch (e.code) {
        case 'email-already-in-use':
          message = 'This email is already registered.';
          break;

        case 'invalid-email':
          message = 'Please enter a valid email address.';
          break;

        case 'weak-password':
          message = 'Password is too weak. Follow all password requirements.';
          break;

        case 'network-request-failed':
          message = 'Network error. Check your internet connection.';
          break;

        case 'operation-not-allowed':
          message = 'Email/password authentication is not enabled in Firebase.';
          break;

        default:
          message = 'Registration failed. Please try again.';
      }

      _showMessage(message, isError: true);
    } catch (e) {
      _showMessage('Registration failed. Please try again.', isError: true);
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

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 3),
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

      appBar: AppBar(
        title: const Text(
          'Create Account',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),

        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),

          child: Column(
            children: [
              const SizedBox(height: 15),

              // ------------------------------------------------
              // ICON
              // ------------------------------------------------
              const Icon(Icons.person_add_alt_1, size: 75, color: primaryBlue),

              const SizedBox(height: 20),

              const Text(
                'Create Your Account',
                style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 8),

              const Text(
                'Register to start managing your tasks.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),

              const SizedBox(height: 30),

              // ------------------------------------------------
              // FULL NAME
              // ------------------------------------------------
              TextField(
                controller: nameController,

                textCapitalization: TextCapitalization.words,

                decoration: InputDecoration(
                  labelText: 'Full Name',
                  hintText: 'Enter your full name',
                  prefixIcon: const Icon(Icons.person_outline),

                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),

                  filled: true,
                  fillColor: Colors.white,
                ),
              ),

              const SizedBox(height: 16),

              // ------------------------------------------------
              // EMAIL
              // ------------------------------------------------
              TextField(
                controller: emailController,

                keyboardType: TextInputType.emailAddress,

                decoration: InputDecoration(
                  labelText: 'Email',
                  hintText: 'example@gmail.com',

                  prefixIcon: const Icon(Icons.email_outlined),

                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),

                  filled: true,
                  fillColor: Colors.white,
                ),
              ),

              const SizedBox(height: 16),

              // ------------------------------------------------
              // PASSWORD
              // ------------------------------------------------
              TextField(
                controller: passwordController,

                obscureText: obscurePassword,

                decoration: InputDecoration(
                  labelText: 'Password',
                  hintText: 'Enter a strong password',

                  prefixIcon: const Icon(Icons.lock_outline),

                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(() {
                        obscurePassword = !obscurePassword;
                      });
                    },

                    icon: Icon(
                      obscurePassword ? Icons.visibility : Icons.visibility_off,
                    ),
                  ),

                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),

                  filled: true,
                  fillColor: Colors.white,
                ),
              ),

              const SizedBox(height: 10),

              // ------------------------------------------------
              // PASSWORD REQUIREMENTS
              // ------------------------------------------------
              Container(
                width: double.infinity,

                padding: const EdgeInsets.all(14),

                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade100),
                ),

                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    Text(
                      'Password must contain:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),

                    SizedBox(height: 7),

                    Text(
                      '• Minimum 10 characters',
                      style: TextStyle(fontSize: 13),
                    ),

                    Text(
                      '• At least one uppercase letter (A-Z)',
                      style: TextStyle(fontSize: 13),
                    ),

                    Text(
                      '• At least one lowercase letter (a-z)',
                      style: TextStyle(fontSize: 13),
                    ),

                    Text(
                      '• At least one number (0-9)',
                      style: TextStyle(fontSize: 13),
                    ),

                    Text(
                      '• At least one special character (!@#\$%^&*)',
                      style: TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ------------------------------------------------
              // WHATSAPP NUMBER
              // ------------------------------------------------
              TextField(
                controller: whatsappController,

                keyboardType: TextInputType.phone,

                decoration: InputDecoration(
                  labelText: 'WhatsApp Number',
                  hintText: '+91 9876543210',

                  prefixIcon: const Icon(Icons.chat_outlined),

                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),

                  filled: true,
                  fillColor: Colors.white,
                ),
              ),

              const SizedBox(height: 25),

              // ------------------------------------------------
              // REGISTER BUTTON
              // ------------------------------------------------
              SizedBox(
                width: double.infinity,
                height: 52,

                child: ElevatedButton(
                  onPressed: loading ? null : register,

                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    foregroundColor: Colors.white,

                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),

                  child: loading
                      ? const SizedBox(
                          height: 24,
                          width: 24,

                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Register',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 15),

              // ------------------------------------------------
              // LOGIN LINK
              // ------------------------------------------------
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Already have an account? ',
                    style: TextStyle(color: Colors.grey),
                  ),

                  TextButton(
                    onPressed: loading
                        ? null
                        : () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const LoginScreen(),
                              ),
                            );
                          },

                    child: const Text(
                      'Login',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              const Text(
                'Your account information is securely stored using Firebase.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
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
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    whatsappController.dispose();

    super.dispose();
  }
}
