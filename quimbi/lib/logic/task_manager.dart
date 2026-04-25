import 'package:flutter/foundation.dart';
import '../models/task_model.dart';
import '../models/subtask_model.dart';
import '../models/alert_model.dart';
import '../models/link_model.dart';
import '../models/location_model.dart';
import '../models/person_model.dart';
import '../models/recurrence_model.dart';
import '../repositories/task_repository.dart';
import '../db/data/task_seed_loader.dart';

class TaskManager {
  final _repository = TaskRepository();

  Future<List<TaskModel>> getTasks() async {
    if (kIsWeb) {
      final tasks = loadTestTasks();
      tasks.sort(_compareTask);
      return tasks;
    }
    final raw = await _repository.fetchRawTaskData();
    final tasks = _assembleTaskModels(raw);
    tasks.sort(_compareTask);
    return tasks;
  }

  // Returns the time-of-day portion as "HH:MM:SS" for sort comparison, or null if absent/midnight.
  String? _sortableTimePart(TaskModel task) {
    if (task.dueTime == null) return null;
    final part = task.dueTime!.contains(' ') ? task.dueTime!.split(' ').last : task.dueTime!;
    if (part.startsWith('00:00')) return null;
    return part;
  }

  int _compareTask(TaskModel a, TaskModel b) {
    final timeA = _sortableTimePart(a);
    final timeB = _sortableTimePart(b);
    // group: 0 = time-sensitive with time, 1 = non-sensitive with time, 2 = no time
    int groupOf(TaskModel task, String? time) {
      if (time == null) return 2;
      return task.isTimeSensitive ? 0 : 1;
    }
    final groupA = groupOf(a, timeA);
    final groupB = groupOf(b, timeB);
    if (groupA != groupB) return groupA.compareTo(groupB);
    if (timeA == null || timeB == null) return 0;
    return timeA.compareTo(timeB);
  }

  List<TaskModel> _assembleTaskModels(TaskRawData raw) {
    return raw.tasks.map((row) {
      final taskId = row['id'] as int;
      final locationId = row['location_id'] as int?;
      final recurrenceMatches = raw.recurrencePatterns
          .where((r) => r['task_id'] == taskId)
          .toList();

      return TaskModel.fromMap(
        row,
        subtasks: raw.subtasks
            .where((s) => s['task_id'] == taskId)
            .map(SubtaskModel.fromMap)
            .toList(),
        alerts: raw.alerts
            .where((a) => a['task_id'] == taskId)
            .map(AlertModel.fromMap)
            .toList(),
        links: raw.links
            .where((l) => l['task_id'] == taskId)
            .map(LinkModel.fromMap)
            .toList(),
        location: locationId != null
            ? LocationModel.fromMap(
                raw.locations.firstWhere((l) => l['id'] == locationId))
            : null,
        recurrence: recurrenceMatches.isEmpty
            ? null
            : RecurrenceModel.fromMap(recurrenceMatches.first),
        people: raw.people
            .where((p) => p['task_id'] == taskId)
            .map(PersonModel.fromMap)
            .toList(),
        completedDates: raw.completions
            .where((c) => c['task_id'] == taskId)
            .map((c) => c['done_date'] as String)
            .toList(),
        missedDates: raw.missed
            .where((m) => m['task_id'] == taskId)
            .map((m) => m['missed_date'] as String)
            .toList(),
      );
    }).toList();
  }

  Future<int> addTask(TaskModel task) => _repository.addTask(
        title: task.title,
        isTimeSensitive: task.isTimeSensitive,
        dueTime: task.dueTime,
      );

  Future<void> completeTask(int taskId, String doneDate) =>
      _repository.completeTask(taskId, doneDate);

  Future<void> uncompleteTask(int taskId, String doneDate) =>
      _repository.uncompleteTask(taskId, doneDate);

  Future<void> unmissTask(int taskId, String date) =>
      _repository.unmissTask(taskId, date);

  Future<void> deleteTask(int taskId) => _repository.deleteTask(taskId);
}
