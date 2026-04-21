import 'database_setup.dart';
import 'task_model.dart'; 

class TaskRepository {

//Future<   - this is async, it will resolve eventually
//List<    - to a list
//TaskModel  - of TaskModel objects

  
Future<List<TaskModel>> fetchAllTasks() async {
  final db = await DatabaseHelper().database;
  final rows = await db.rawQuery(_buildTaskQuery());
  return _groupRowsIntoTasks(rows);
}

String _buildTaskQuery() => '''
  SELECT 
    tasks.*,
    subtasks.id         AS subtask_id,
    subtasks.title      AS subtask_title,
    subtasks.completed  AS subtask_completed,
    subtasks.position   AS subtask_position,
    recurrence_patterns.recurrence_type,
    recurrence_patterns.weekdays,
    recurrence_patterns.day_of_month,
    recurrence_patterns.interval_count,
    recurrence_patterns.starts_on,
    recurrence_patterns.ends_on
  FROM tasks
  LEFT JOIN subtasks 
    ON subtasks.task_id = tasks.id
  LEFT JOIN recurrence_patterns 
    ON recurrence_patterns.task_id = tasks.id
''';

List<TaskModel> _groupRowsIntoTasks(List<Map<String, dynamic>> rows) {
  final groupedTasks = <int, Map<String, dynamic>>{};
  final groupedSubtasks = <int, List<Map<String, dynamic>>>{};

  for (final row in rows) {
    _accumulateRow(row, groupedTasks, groupedSubtasks);
  }

  return groupedTasks.entries
      .map((entry) => _buildTaskModel(entry, groupedSubtasks))
      .toList();
}

void _accumulateRow(
  Map<String, dynamic> row,
  Map<int, Map<String, dynamic>> groupedTasks,
  Map<int, List<Map<String, dynamic>>> groupedSubtasks,
) {
  final taskId = row['id'] as int;
  groupedTasks[taskId] ??= row;

  if (row['subtask_id'] != null) {
    groupedSubtasks[taskId] ??= [];
    groupedSubtasks[taskId]!.add(row);
  }
}

TaskModel _buildTaskModel(
  MapEntry<int, Map<String, dynamic>> entry,
  Map<int, List<Map<String, dynamic>>> groupedSubtasks,
) {
  final subtasks = (groupedSubtasks[entry.key] ?? [])
      .map((row) => SubtaskModel.fromMap(row))
      .toList();

  return TaskModel.fromMap(entry.value, subtasks);
}
// what fromMap turns it INTO 
// TaskModel(
//   id: 1,
//   title: 'Therapy',
//   isCompleted: false,   // 0 converted to bool
//   isTimeSensitive: true // 1 converted to bool
// )


  Future<int> addTask(TaskModel task) async {
    final db = await DatabaseHelper().database;
    // insert returns the new row's id — same as RETURNING id in postgres
    return db.insert('tasks', {
      'title': task.title,
      'time_sensitive': task.isTimeSensitive ? 1 : 0,
      'due_time': task.dueTime,
      'alert_time': task.alertTime,
      'completed': 0,
    });
  }

  Future<void> completeTask(int taskId) async {
    final db = await DatabaseHelper().database;
    await db.update(
      'tasks',
      {'completed': 1},
      where: 'id = ?',
      whereArgs: [taskId],
    );
  }

  Future<void> deleteTask(int taskId) async {
    final db = await DatabaseHelper().database;
    // CASCADE handles subtasks and recurrence_patterns automatically
    await db.delete('tasks', where: 'id = ?', whereArgs: [taskId]);
  }
}