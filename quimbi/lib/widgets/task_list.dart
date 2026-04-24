import 'package:flutter/material.dart';
import '../models/task_model.dart';
import '../logic/task_manager.dart';
import 'task_card.dart';

class TaskList extends StatefulWidget {
  final DateTime selectedDate;
  final int refreshKey;
  final void Function(List<TaskModel> tasks)? onTasksLoaded;
  final void Function(int taskId)? onTaskCompleted;
  final void Function(List<int> completedIds, String date)? onAllResolvedToday;
  final VoidCallback? onTaskUncompleted;
  final Widget? header;

  const TaskList({
    super.key,
    required this.selectedDate,
    this.refreshKey = 0,
    this.onTasksLoaded,
    this.onTaskCompleted,
    this.onAllResolvedToday,
    this.onTaskUncompleted,
    this.header,
  });

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
      if (mounted) {
        setState(() => _tasks = tasks);
        widget.onTasksLoaded?.call(tasks);
        _checkPotionAward(tasks);
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  void _checkPotionAward(List<TaskModel> tasks) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final sel = DateTime(widget.selectedDate.year, widget.selectedDate.month, widget.selectedDate.day);
    if (sel != today) return;

    final dateStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    final todayTasks = tasks.where((t) => _occursOn(t, now)).toList();
    if (todayTasks.isEmpty) return;

    final allResolved = todayTasks.every((t) => t.isCompletedOn(dateStr) || t.isMissedOn(dateStr));
    if (!allResolved) return;

    final completedIds = todayTasks
        .where((t) => t.isCompletedOn(dateStr))
        .map((t) => t.id)
        .toList();
    widget.onAllResolvedToday?.call(completedIds, dateStr);
  }

  Future<void> _completeTask(int taskId) async {
    widget.onTaskCompleted?.call(taskId);
    final d = widget.selectedDate;
    final dateStr =
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    await _manager.completeTask(taskId, dateStr);
    if (mounted) _loadTasks();
  }

  bool _occursOn(task, DateTime date) {
    final r = task.recurrence;

    if (r == null) {
      final anchor = task.dueTime ?? task.createdAt;
      final due = DateTime.tryParse(anchor);
      if (due == null) return false;
      return due.year == date.year && due.month == date.month && due.day == date.day;
    }

    // Always show a recurring task on the specific date it was added for
    if (task.dueTime != null) {
      final due = DateTime.tryParse(task.dueTime!);
      if (due != null && due.year == date.year && due.month == date.month && due.day == date.day) {
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

  Future<void> _completeMissedTask(int taskId) async {
    widget.onTaskCompleted?.call(taskId);
    final d = widget.selectedDate;
    final dateStr =
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    await _manager.completeTask(taskId, dateStr);
    await _manager.unmissTask(taskId, dateStr);
    if (mounted) _loadTasks();
  }

  Future<void> _uncompleteTask(int taskId) async {
    widget.onTaskUncompleted?.call();
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

    final missed = _tasks!
        .where((t) => t.isMissedOn(dateStr) && _occursOn(t, d))
        .toList();
    final active = _tasks!
        .where((t) => !t.isCompletedOn(dateStr) && !t.isMissedOn(dateStr) && _occursOn(t, d))
        .toList();
    final done = _tasks!
        .where((t) => t.isCompletedOn(dateStr) && !t.isMissedOn(dateStr) && _occursOn(t, d))
        .toList();

    final items = <Object>[
      ...active,
      if (done.isNotEmpty) 'completed_header',
      ...done,
      if (missed.isNotEmpty) 'missed_header',
      ...missed,
      'footer',
    ];

    if (items.isEmpty) {
      return Center(
        child: Text(
          'wow so empty',
          style: TextStyle(
            fontFamily: 'Anonymous Pro',
            fontSize: 15,
            color: Colors.grey.shade400,
          ),
        ),
      );
    }

    final hasHeader = widget.header != null;
    final totalCount = items.length + (hasHeader ? 1 : 0);

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
      itemCount: totalCount,
      itemBuilder: (context, index) {
        if (hasHeader && index == 0) return widget.header!;
        final item = items[hasHeader ? index - 1 : index];

        if (item == 'completed_header') {
          return Padding(
            padding: const EdgeInsets.fromLTRB(4, 8, 0, 8),
            child: Text(
              'Completed',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF888888),
              ),
            ),
          );
        }

        if (item == 'footer') {
          return Padding(
            padding: const EdgeInsets.only(top: 24),
            child: Center(
              child: Text(
                active.isEmpty ? 'you\'re all caught up' : 'keep going, you\'ve got this',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade400,
                ),
              ),
            ),
          );
        }

        if (item == 'missed_header') {
          return Padding(
            padding: const EdgeInsets.fromLTRB(4, 8, 0, 8),
            child: Text(
              'Missed',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF888888),
              ),
            ),
          );
        }

        final task = item as TaskModel;
        final isCompleted = done.contains(task);
        final isMissed = missed.contains(task);
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: TaskCard(
            key: Key('${isCompleted ? "done" : isMissed ? "missed" : "active"}_${task.id}'),
            task: task,
            selectedDate: widget.selectedDate,
            isCompleted: isCompleted,
            isMissed: isMissed,
            onComplete: isMissed ? () => _completeMissedTask(task.id) : () => _completeTask(task.id),
            onDelete: () => _deleteTask(task.id),
            onUndo: isCompleted ? () => _uncompleteTask(task.id) : null,
            onRefresh: _loadTasks,
          ),
        );
      },
    );
  }
}
