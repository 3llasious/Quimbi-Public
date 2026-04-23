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

  // Returns the time-of-day portion as "HH:MM:SS" for comparison, or null if absent/midnight.
  String? _timeOf(TaskModel t) {
    if (t.dueTime == null) return null;
    final part = t.dueTime!.contains(' ') ? t.dueTime!.split(' ').last : t.dueTime!;
    if (part.startsWith('00:00')) return null;
    return part;
  }

  int _compareTask(TaskModel a, TaskModel b) {
    final ta = _timeOf(a);
    final tb = _timeOf(b);
    // group: 0 = time-sensitive with time, 1 = non-sensitive with time, 2 = no time
    int groupOf(TaskModel t, String? time) {
      if (time == null) return 2;
      return t.isTimeSensitive ? 0 : 1;
    }
    final ga = groupOf(a, ta);
    final gb = groupOf(b, tb);
    if (ga != gb) return ga.compareTo(gb);
    if (ta == null || tb == null) return 0;
    return ta.compareTo(tb);
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

  Future<void> deleteTask(int taskId) => _repository.deleteTask(taskId);
}
