import 'package:flutter/material.dart';
import 'widgets/task_list.dart';

void main() {
  runApp(const QuimbiApp());
}

class QuimbiApp extends StatelessWidget {
  const QuimbiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quimbi',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Anonymous Pro',
        scaffoldBackgroundColor: const Color(0xFFF5F0EA),
      ),
      home: Scaffold(
        body: TaskList(),
      ),
    );
  }
}