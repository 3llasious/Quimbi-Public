import 'package:flutter/material.dart';
import '../models/task_model.dart';
import '../db/data/task_seed_loader.dart';
import 'task_card.dart';

class TaskList extends StatefulWidget {
  const TaskList({super.key});

  @override
  State<TaskList> createState() => _TaskListState();
}

class _TaskListState extends State<TaskList> {
  List<TaskModel> _tasks = loadTestTasks()
    ..sort((a, b) {
      if (a.dueTime == null && b.dueTime == null) return 0;
      if (a.dueTime == null) return 1;
      if (b.dueTime == null) return -1;
      return a.dueTime!.compareTo(b.dueTime!);
    });

  void _completeTask(int taskId) {
    setState(() => _tasks.removeWhere((task) => task.id == taskId));
  }

  void _deleteTask(int taskId) {
    setState(() => _tasks.removeWhere((task) => task.id == taskId));
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _tasks.length,
      itemBuilder: (context, index) {
        final task = _tasks[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: TaskCard(
            task: task,
            onComplete: () => _completeTask(task.id),
            onDelete: () => _deleteTask(task.id),
          ),
        );
      },
    );
  }
}