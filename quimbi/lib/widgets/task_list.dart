import 'package:flutter/material.dart';
import '../models/task_model.dart';
import '../logic/task_manager.dart';
import '../utils/date_time_utils.dart';
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
        _checkAllResolvedToday(tasks);
      }
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    }
  }

  void _checkAllResolvedToday(List<TaskModel> tasks) {
    final now = DateTime.now();
    final today = now.dateOnly;
    final selectedDay = widget.selectedDate.dateOnly;
    if (selectedDay != today) return;

    final dateString = todayDateString();
    final todayTasks = tasks.where((task) => task.occursOn(now)).toList();
    if (todayTasks.isEmpty) return;

    final allResolved = todayTasks.every(
      (task) => task.isCompletedOn(dateString) || task.isMissedOn(dateString),
    );
    if (!allResolved) return;

    final completedIds = todayTasks
        .where((task) => task.isCompletedOn(dateString))
        .map((task) => task.id)
        .toList();
    widget.onAllResolvedToday?.call(completedIds, dateString);
  }

  Future<void> _completeTask(int taskId) async {
    widget.onTaskCompleted?.call(taskId);
    final dateString = formatDate(widget.selectedDate);
    await _manager.completeTask(taskId, dateString);
    if (mounted) _loadTasks();
  }

  Future<void> _completeMissedTask(int taskId) async {
    widget.onTaskCompleted?.call(taskId);
    final dateString = formatDate(widget.selectedDate);
    await _manager.completeTask(taskId, dateString);
    await _manager.unmissTask(taskId, dateString);
    if (mounted) _loadTasks();
  }

  Future<void> _uncompleteTask(int taskId) async {
    widget.onTaskUncompleted?.call();
    final dateString = formatDate(widget.selectedDate);
    await _manager.uncompleteTask(taskId, dateString);
    if (mounted) _loadTasks();
  }

  Future<void> _deleteTask(int taskId) async {
    await _manager.deleteTask(taskId);
    if (mounted) setState(() => _tasks!.removeWhere((task) => task.id == taskId));
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) return Center(child: Text('Error: $_error'));
    if (_tasks == null) return const Center(child: CircularProgressIndicator());

    final selectedDay = widget.selectedDate;
    final dateString = formatDate(selectedDay);

    final missed = _tasks!
        .where((task) => task.isMissedOn(dateString) && task.occursOn(selectedDay))
        .toList();
    final active = _tasks!
        .where((task) =>
            !task.isCompletedOn(dateString) &&
            !task.isMissedOn(dateString) &&
            task.occursOn(selectedDay))
        .toList();
    final done = _tasks!
        .where((task) =>
            task.isCompletedOn(dateString) &&
            !task.isMissedOn(dateString) &&
            task.occursOn(selectedDay))
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
          return const Padding(
            padding: EdgeInsets.fromLTRB(4, 8, 0, 8),
            child: Text(
              'Completed',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF888888)),
            ),
          );
        }

        if (item == 'missed_header') {
          return const Padding(
            padding: EdgeInsets.fromLTRB(4, 8, 0, 8),
            child: Text(
              'Missed',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF888888)),
            ),
          );
        }

        if (item == 'footer') {
          return Padding(
            padding: const EdgeInsets.only(top: 24),
            child: Center(
              child: Text(
                active.isEmpty ? 'you\'re all caught up' : 'keep going, you\'ve got this',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
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
            onComplete: isMissed
                ? () => _completeMissedTask(task.id)
                : () => _completeTask(task.id),
            onDelete: () => _deleteTask(task.id),
            onUndo: isCompleted ? () => _uncompleteTask(task.id) : null,
            onRefresh: _loadTasks,
          ),
        );
      },
    );
  }
}
