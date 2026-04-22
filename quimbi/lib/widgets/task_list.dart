import 'package:flutter/material.dart';
import '../models/task_model.dart';
import '../logic/task_manager.dart';
import 'task_card.dart';

class TaskList extends StatefulWidget {
  final DateTime selectedDate;

  const TaskList({super.key, required this.selectedDate});

  @override
  State<TaskList> createState() => _TaskListState();
}

class _TaskListState extends State<TaskList> {
  final _manager = TaskManager();
  List<TaskModel>? _tasks;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    try {
      final tasks = await _manager.getTasks();
      if (mounted) setState(() => _tasks = tasks);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  Future<void> _completeTask(int taskId) async {
    await _manager.completeTask(taskId);
    if (mounted) setState(() => _tasks!.removeWhere((t) => t.id == taskId));
  }

  bool _occursOn(task, DateTime date) {
    final r = task.recurrence;

    if (r == null) {
      if (task.dueTime == null) return true;
      final due = DateTime.parse(task.dueTime!);
      return due.year == date.year && due.month == date.month && due.day == date.day;
    }

    final d = DateTime(date.year, date.month, date.day);

    if (r.startsOn != null) {
      final start = DateTime.parse(r.startsOn!);
      if (d.isBefore(DateTime(start.year, start.month, start.day))) return false;
    }
    if (r.endsOn != null) {
      final end = DateTime.parse(r.endsOn!);
      if (d.isAfter(DateTime(end.year, end.month, end.day))) return false;
    }

    switch (r.recurrenceType) {
      case 'daily':
        return true;
      case 'weekly':
        if (r.weekdays == null) return false;
        final days = r.weekdays!.split(',').map(int.parse).toList();
        return days.contains(date.weekday);
      case 'monthly':
        return r.dayOfMonth != null && date.day == r.dayOfMonth;
      default:
        return false;
    }
  }

  Future<void> _deleteTask(int taskId) async {
    await _manager.deleteTask(taskId);
    if (mounted) setState(() => _tasks!.removeWhere((t) => t.id == taskId));
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) return Center(child: Text('Error: $_error'));
    if (_tasks == null) return const Center(child: CircularProgressIndicator());

    final filtered = _tasks!.where((t) => _occursOn(t, widget.selectedDate)).toList();

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final task = filtered[index];
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
