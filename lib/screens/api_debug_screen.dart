import 'package:flutter/material.dart';
import '../services/api_test_service.dart';

class ApiDebugScreen extends StatefulWidget {
  const ApiDebugScreen({super.key});

  @override
  State<ApiDebugScreen> createState() => _ApiDebugScreenState();
}

class _ApiDebugScreenState extends State<ApiDebugScreen> {
  Map<String, dynamic>? testResult;
  bool isLoading = false;

  Future<void> runApiTest() async {
    setState(() {
      isLoading = true;
      testResult = null;
    });

    final result = await ApiTestService.testApiConnection();

    if (mounted) {
      setState(() {
        testResult = result;
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('API Connection Test'),
        backgroundColor: const Color(0xFF17175F),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'OpenAI API Connection Test',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'This test will verify if your OpenAI API key is valid and the connection is working.',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: isLoading ? null : runApiTest,
                        icon: isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Icon(Icons.api),
                        label: Text(isLoading ? 'Testing...' : 'Run Test'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF17175F),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (testResult != null) ...[
              Card(
                color: testResult!['success'] == true
                    ? Colors.green.shade50
                    : Colors.red.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            testResult!['success'] == true
                                ? Icons.check_circle
                                : Icons.error_outline,
                            color: testResult!['success'] == true
                                ? Colors.green
                                : Colors.red,
                            size: 28,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              testResult!['success'] == true
                                  ? 'Connection Successful ✅'
                                  : 'Connection Failed ❌',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: testResult!['success'] == true
                                    ? Colors.green
                                    : Colors.red,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Message:',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        testResult!['message'] ?? 'No message',
                        style: const TextStyle(fontSize: 13),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Stage: ${testResult!['stage'] ?? 'Unknown'}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      if (testResult!['response'] != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          'AI Response:',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            testResult!['response'],
                            style: const TextStyle(
                              fontSize: 13,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ],
                      if (testResult!['statusCode'] != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          'Status Code: ${testResult!['statusCode']}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Debug Info',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Text(
                            testResult.toString(),
                            style: const TextStyle(
                              fontSize: 11,
                              fontFamily: 'Courier',
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            if (!isLoading && testResult == null)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 48,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Click the "Run Test" button to test API connection',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
