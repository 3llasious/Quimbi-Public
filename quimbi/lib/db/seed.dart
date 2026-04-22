import 'package:sqflite/sqflite.dart';
import 'database_setup.dart';
import 'data/tasks.dart';
import 'data/subtasks.dart';
import 'data/recurrence_patterns_data.dart';
import 'data/alerts_data.dart';
import 'data/locations_data.dart';
import 'data/people_data.dart';
import 'data/task_people_data.dart';

Future<void> seedDatabase() async {
  final db = await DatabaseHelper.instance.database;

  await clearAllTables(db);
  await insertAllLocations(db);
  await insertAllPeople(db);
  await insertAllTasks(db);
  await insertAllSubtasks(db);
  await insertAllRecurrencePatterns(db);
  await insertAllAlerts(db);
  await insertAllTaskPeople(db);
}

Future<void> clearAllTables(Database db) async {
  await db.execute('DELETE FROM task_people');
  await db.execute('DELETE FROM recurrence_patterns');
  await db.execute('DELETE FROM subtasks');
  await db.execute('DELETE FROM alerts');
  await db.execute('DELETE FROM links');
  await db.execute('DELETE FROM tasks');
  await db.execute('DELETE FROM people');
  await db.execute('DELETE FROM locations');
}

Future<void> insertAllLocations(Database db) async {
  for (final location in testLocations) {
    await db.insert('locations', location);
  }
}

Future<void> insertAllPeople(Database db) async {
  for (final person in testPeople) {
    await db.insert('people', person);
  }
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

Future<void> insertAllAlerts(Database db) async {
  for (final alert in testAlerts) {
    await db.insert('alerts', alert);
  }
}

Future<void> insertAllTaskPeople(Database db) async {
  for (final row in testTaskPeople) {
    await db.insert('task_people', row);
  }
}
