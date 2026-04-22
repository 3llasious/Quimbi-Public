import 'package:flutter/material.dart';
import '../models/task_model.dart';
import '../logic/task_manager.dart';
import 'task_card.dart';

class TaskList extends StatefulWidget {
  final DateTime selectedDate;
  final int refreshKey;

  const TaskList({super.key, required this.selectedDate, this.refreshKey = 0});

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

  @override
  void didUpdateWidget(TaskList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshKey != widget.refreshKey) _loadTasks();
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
    final d = widget.selectedDate;
    final dateStr =
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    await _manager.completeTask(taskId, dateStr);
    if (mounted) _loadTasks();
  }

  bool _occursOn(task, DateTime date) {
    final r = task.recurrence;

    if (r == null) {
      if (task.dueTime == null) return true;
      final due = DateTime.parse(task.dueTime!);
      return due.year == date.year && due.month == date.month && due.day == date.day;
    }

    // Always show a recurring task on the specific date it was added for
    if (task.dueTime != null) {
      final due = DateTime.parse(task.dueTime!);
      if (due.year == date.year && due.month == date.month && due.day == date.day) {
        return true;
      }
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

  Future<void> _uncompleteTask(int taskId) async {
    final d = widget.selectedDate;
    final dateStr =
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    await _manager.uncompleteTask(taskId, dateStr);
    if (mounted) _loadTasks();
  }

  Future<void> _deleteTask(int taskId) async {
    await _manager.deleteTask(taskId);
    if (mounted) setState(() => _tasks!.removeWhere((t) => t.id == taskId));
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) return Center(child: Text('Error: $_error'));
    if (_tasks == null) return const Center(child: CircularProgressIndicator());

    final d = widget.selectedDate;
    final dateStr =
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

    final active = _tasks!
        .where((t) => !t.isCompletedOn(dateStr) && _occursOn(t, d))
        .toList();
    final done = _tasks!
        .where((t) => t.isCompletedOn(dateStr) && _occursOn(t, d))
        .toList();

    final items = <Object>[
      ...active,
      if (done.isNotEmpty) 'completed_header',
      ...done,
    ];

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];

        if (item == 'completed_header') {
          return Padding(
            padding: const EdgeInsets.fromLTRB(4, 8, 0, 8),
            child: Text(
              'Completed',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4D5B71),
              ),
            ),
          );
        }

        final task = item as TaskModel;
        final isCompleted = done.contains(task);
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: TaskCard(
            key: Key('${isCompleted ? "done" : "active"}_${task.id}'),
            task: task,
            selectedDate: widget.selectedDate,
            isCompleted: isCompleted,
            onComplete: () => _completeTask(task.id),
            onDelete: () => _deleteTask(task.id),
            onUndo: isCompleted ? () => _uncompleteTask(task.id) : null,
          ),
        );
      },
    );
  }
}
