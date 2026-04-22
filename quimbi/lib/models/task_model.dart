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
  final List<String> completedDates;

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
    this.completedDates = const [],
  });

  bool isCompletedOn(String date) => completedDates.contains(date);

  factory TaskModel.fromMap(
    Map<String, dynamic> map, {
    List<SubtaskModel> subtasks = const [],
    List<AlertModel> alerts = const [],
    RecurrenceModel? recurrence,
    List<LinkModel> links = const [],
    LocationModel? location,
    List<PersonModel> people = const [],
    List<String> completedDates = const [],
  }) {
    return TaskModel(
      id: map['id'] as int,
      title: map['title'] as String,
      isTimeSensitive: (map['time_sensitive'] as int) == 1,
      dueTime: map['due_time'] as String?,
      isCompleted: (map['completed'] as int) == 1,
      createdAt: map['created_at'] as String,
      locationId: map['location_id'] as int?,
      subtasks: subtasks,
      alerts: alerts,
      recurrence: recurrence,
      links: links,
      location: location,
      people: people,
      completedDates: completedDates,
    );
  }
}