import 'package:flutter/material.dart';

void main() {
  runApp(const VerbaApp());
}

class VerbaApp extends StatelessWidget {
  const VerbaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Verba',
      debugShowCheckedModeBanner: false,
      home: Scaffold(),
    );
  }
}
