import 'package:flutter/material.dart';
import '../widgets/date_selector_header.dart';
import '../widgets/task_list.dart';

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  DateTime _selectedDate = DateTime.now();

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, Color(0xFFF4EBD2)],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  _greeting,
                  style: const TextStyle(
                    fontFamily: 'CanelaTrialMedium',
                    fontSize: 24,
                  ),
                ),
              ),
              DateSelectorHeader(
                onDateSelected: (date) => setState(() => _selectedDate = date),
              ),
              const SizedBox(height: 8),
              const Expanded(child: TaskList()),
            ],
          ),
        ),
      ),
    );
  }
}
