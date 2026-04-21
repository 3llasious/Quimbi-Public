import 'subtask_model.dart';
import 'recurrence_model.dart';
import 'alert_model.dart';
import 'link_model.dart';
import 'location_model.dart';
import 'person_model.dart';

class TaskModel {
  final int id;
  final String title;
  final bool isTimeSensitive;
  final String? dueTime;
  final bool isCompleted;
  final String createdAt;
  final int? locationId;
  final List<SubtaskModel> subtasks;
  final List<AlertModel> alerts;
  final RecurrenceModel? recurrence;
  final List<LinkModel> links;
  final LocationModel? location;
  final List<PersonModel> people;

  const TaskModel({
    required this.id,
    required this.title,
    required this.isTimeSensitive,
    this.dueTime,
    required this.isCompleted,
    required this.createdAt,
    this.locationId,
    this.subtasks = const [],
    this.alerts = const [],
    this.recurrence,
    this.links = const [],
    this.location,
    this.people = const [],
  });
}