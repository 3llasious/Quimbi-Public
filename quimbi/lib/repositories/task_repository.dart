import 'package:flutter/foundation.dart';
import '../db/database_setup.dart';

typedef TaskRawData = ({
  List<Map<String, dynamic>> tasks,
  List<Map<String, dynamic>> subtasks,
  List<Map<String, dynamic>> alerts,
  List<Map<String, dynamic>> links,
  List<Map<String, dynamic>> locations,
  List<Map<String, dynamic>> recurrencePatterns,
  List<Map<String, dynamic>> people,
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
    return (
      tasks: tasks,
      subtasks: subtasks,
      alerts: alerts,
      links: links,
      locations: locations,
      recurrencePatterns: recurrencePatterns,
      people: people,
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

  Future<void> completeTask(int taskId) async {
    final db = await DatabaseHelper.instance.database;
    await db.update('tasks', {'completed': 1}, where: 'id = ?', whereArgs: [taskId]);
  }

  Future<void> deleteTask(int taskId) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('tasks', where: 'id = ?', whereArgs: [taskId]);
  }
}
