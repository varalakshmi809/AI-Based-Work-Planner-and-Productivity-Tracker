import 'dart:async';

import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();

    _timer = Timer(const Duration(seconds: 3), () {
      if (!mounted) return;

      Navigator.pushReplacementNamed(context, '/login');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF17175F),

      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.task_alt, color: Colors.white, size: 100),

            SizedBox(height: 20),

            Text(
              'AI Work Planner',
              style: TextStyle(
                color: Colors.white,
                fontSize: 30,
                fontWeight: FontWeight.bold,
              ),
            ),

            SizedBox(height: 10),

            Text(
              'Boost Your Productivity',
              style: TextStyle(color: Colors.white70, fontSize: 18),
            ),

            SizedBox(height: 30),

            CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
