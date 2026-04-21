import 'package:sqflite/sqflite.dart';
import 'database_helper.dart';
import 'tasks_data.dart';
import 'subtasks_data.dart';
import 'recurrence_patterns_data.dart';

Future<void> seedDatabase() async {
  final db = await DatabaseHelper().database;

  await clearAllTables(db);
  await insertAllTasks(db);
  await insertAllSubtasks(db);
  await insertAllRecurrencePatterns(db);
}

Future<void> clearAllTables(Database db) async {
  await db.execute('DELETE FROM recurrence_patterns');
  await db.execute('DELETE FROM subtasks');
  await db.execute('DELETE FROM tasks');
}

Future<void> insertAllTasks(Database db) async {
  for (final task in testTasks) {
    await db.insert('tasks', task);
  }
}

Future<void> insertAllSubtasks(Database db) async {
  for (final subtask in testSubtasks) {
    await db.insert('subtasks', subtask);
  }
}

Future<void> insertAllRecurrencePatterns(Database db) async {
  for (final pattern in testRecurrencePatterns) {
    await db.insert('recurrence_patterns', pattern);
  }
}