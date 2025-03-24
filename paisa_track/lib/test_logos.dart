import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Logo Test',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const LogoTestScreen(),
    );
  }
}

class LogoTestScreen extends StatelessWidget {
  const LogoTestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final logoFiles = [
      'assets/banks/adbl.png',
      'assets/banks/bfc.png',
      'assets/banks/cfcl.png',
      'assets/banks/citizens.png',
      'assets/banks/corbl.png',
      'assets/banks/everest.png',
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Logo Test'),
      ),
      body: ListView.builder(
        itemCount: logoFiles.length,
        itemBuilder: (context, index) {
          final logoPath = logoFiles[index];
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Text(logoPath),
                const SizedBox(height: 8),
                Image.asset(
                  logoPath,
                  width: 100,
                  height: 100,
                  errorBuilder: (context, error, stackTrace) {
                    print('Error loading asset: $logoPath - $error');
                    return Container(
                      width: 100,
                      height: 100,
                      color: Colors.red,
                      child: const Center(
                        child: Text(
                          'Error',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
} 