import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import '../db/database_setup.dart';

typedef TaskRawData = ({
  List<Map<String, dynamic>> tasks,
  List<Map<String, dynamic>> subtasks,
  List<Map<String, dynamic>> alerts,
  List<Map<String, dynamic>> links,
  List<Map<String, dynamic>> locations,
  List<Map<String, dynamic>> recurrencePatterns,
  List<Map<String, dynamic>> people,
  List<Map<String, dynamic>> completions,
});

class TaskRepository {
  Future<TaskRawData> fetchRawTaskData() async {
    debugPrint('[REPO] fetchRawTaskData start');
    final db = await DatabaseHelper.instance.database;
    debugPrint('[REPO] db ready, querying tasks...');
    final tasks = await db.query('tasks');
    debugPrint('[REPO] tasks: ${tasks.length} rows');
    final subtasks = await db.query('subtasks');
    debugPrint('[REPO] subtasks: ${subtasks.length} rows');
    final alerts = await db.query('alerts');
    debugPrint('[REPO] alerts: ${alerts.length} rows');
    final links = await db.query('links');
    debugPrint('[REPO] links: ${links.length} rows');
    final locations = await db.query('locations');
    debugPrint('[REPO] locations: ${locations.length} rows');
    final recurrencePatterns = await db.query('recurrence_patterns');
    debugPrint('[REPO] recurrencePatterns: ${recurrencePatterns.length} rows');
    debugPrint('[REPO] running people JOIN query...');
    final people = await db.rawQuery('''
      SELECT people.*, task_people.task_id
      FROM people
      JOIN task_people ON people.id = task_people.person_id
    ''');
    debugPrint('[REPO] people: ${people.length} rows');
    final completions = await db.query('task_completions');
    debugPrint('[REPO] completions: ${completions.length} rows');
    return (
      tasks: tasks,
      subtasks: subtasks,
      alerts: alerts,
      links: links,
      locations: locations,
      recurrencePatterns: recurrencePatterns,
      people: people,
      completions: completions,
    );
  }

  Future<int> addTask({
    required String title,
    required bool isTimeSensitive,
    String? dueTime,
  }) async {
    final db = await DatabaseHelper.instance.database;
    return db.insert('tasks', {
      'title': title,
      'time_sensitive': isTimeSensitive ? 1 : 0,
      'due_time': dueTime,
      'completed': 0,
    });
  }

  Future<void> addFullTask({
    required String title,
    required bool isTimeSensitive,
    String? dueTime,
    String? recurrenceType,
    List<int>? weekdays,
    int? dayOfMonth,
    String? startsOn,
    List<Map<String, String>>? alerts,
    List<Map<String, String>>? links,
    List<String>? subtasks,
    String? locationLabel,
    List<String>? people,
  }) async {
    final db = await DatabaseHelper.instance.database;

    final taskId = await db.insert('tasks', {
      'title': title,
      'time_sensitive': isTimeSensitive ? 1 : 0,
      'due_time': dueTime,
      'completed': 0,
      'created_at': DateTime.now().toIso8601String(),
    });

    if (recurrenceType != null) {
      await db.insert('recurrence_patterns', {
        'task_id': taskId,
        'recurrence_type': recurrenceType,
        if (weekdays != null) 'weekdays': weekdays.join(','),
        if (dayOfMonth != null) 'day_of_month': dayOfMonth,
        if (startsOn != null) 'starts_on': startsOn,
      });
    }

    for (final alert in alerts ?? []) {
      await db.insert('alerts', {
        'task_id': taskId,
        'alert_time': alert['time']!,
        'alert_type': alert['type']!,
        'is_active': 1,
      });
    }

    for (final link in links ?? []) {
      await db.insert('links', {
        'task_id': taskId,
        'label': link['label']!,
        'url': link['url']!,
      });
    }

    for (int i = 0; i < (subtasks?.length ?? 0); i++) {
      await db.insert('subtasks', {
        'task_id': taskId,
        'title': subtasks![i],
        'completed': 0,
        'position': i,
      });
    }

    if (locationLabel != null && locationLabel.isNotEmpty) {
      final locId = await db.insert('locations', {'label': locationLabel});
      await db.update('tasks', {'location_id': locId},
          where: 'id = ?', whereArgs: [taskId]);
    }

    for (final name in people ?? []) {
      if (name.isNotEmpty) {
        final personId = await db.insert('people', {'name': name});
        await db.insert('task_people', {'task_id': taskId, 'person_id': personId});
      }
    }
  }

  Future<void> completeTask(int taskId, String doneDate) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert(
      'task_completions',
      {'task_id': taskId, 'done_date': doneDate},
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<void> uncompleteTask(int taskId, String doneDate) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete(
      'task_completions',
      where: 'task_id = ? AND done_date = ?',
      whereArgs: [taskId, doneDate],
    );
  }

  Future<void> deleteTask(int taskId) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('tasks', where: 'id = ?', whereArgs: [taskId]);
  }

  Future<String?> fetchUserName() async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.query('loggedInUser', limit: 1);
    if (result.isEmpty) return null;
    return result.first['name'] as String?;
  }
}
