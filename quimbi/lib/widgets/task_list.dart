import 'package:flutter/material.dart';
import '../models/task_model.dart';
import '../logic/task_manager.dart';
import 'task_card.dart';

class TaskList extends StatefulWidget {
  const TaskList({super.key});

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

  Future<void> _deleteTask(int taskId) async {
    await _manager.deleteTask(taskId);
    if (mounted) setState(() => _tasks!.removeWhere((t) => t.id == taskId));
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) return Center(child: Text('Error: $_error'));
    if (_tasks == null) return const Center(child: CircularProgressIndicator());

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _tasks!.length,
      itemBuilder: (context, index) {
        final task = _tasks![index];
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
