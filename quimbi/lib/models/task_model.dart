// model is purely a shape — no conversion logic
class TaskModel {
  final int id;
  final String title;
  final bool isTimeSensitive;
  final String? dueTime;
  final String? alertTime;
  final bool isCompleted;
  final String createdAt;
  final int? locationId;
  final List<SubtaskModel> subtasks;
  final RecurrenceModel? recurrence;

  const TaskModel({
    required this.id,
    required this.title,
    required this.isTimeSensitive,
    this.dueTime,
    this.alertTime,
    required this.isCompleted,
    required this.createdAt,
    this.locationId,
    this.subtasks = const [],
    this.recurrence,
  });
}