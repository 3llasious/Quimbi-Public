import '../../models/task_model.dart';
import '../../models/subtask_model.dart';
import '../../models/recurrence_model.dart';
import '../../models/alert_model.dart';
import '../../models/location_model.dart';
import '../../models/person_model.dart';
import 'tasks.dart';
import 'subtasks.dart';
import 'recurrence_patterns_data.dart';
import 'alerts_data.dart';
import 'links_data.dart';
import 'locations_data.dart';
import 'people_data.dart';
import 'task_people_data.dart';

List<TaskModel> loadTestTasks() {
  return List.generate(testTasks.length, (index) {
    final id = index + 1;
    final taskMap = testTasks[index];

    final subtasks = testSubtasks
        .where((s) => s['task_id'] == id)
        .toList()
        .asMap()
        .entries
        .map((e) => SubtaskModel(
              id: e.key + 1,
              taskId: id,
              title: e.value['title'] as String,
              isCompleted: (e.value['completed'] as int) == 1,
              position: e.value['position'] as int?,
            ))
        .toList();

    final recurrenceMatches =
        testRecurrencePatterns.where((r) => r['task_id'] == id).toList();

    final recurrence = recurrenceMatches.isNotEmpty
        ? RecurrenceModel(
            id: id,
            taskId: id,
            recurrenceType: recurrenceMatches[0]['recurrence_type'] as String,
            weekdays: recurrenceMatches[0]['weekdays'] as String?,
            dayOfMonth: recurrenceMatches[0]['day_of_month'] as int?,
            intervalCount: recurrenceMatches[0]['interval_count'] as int?,
            startsOn: recurrenceMatches[0]['starts_on'] as String?,
            endsOn: recurrenceMatches[0]['ends_on'] as String?,
          )
        : null;

    final alerts = testAlerts
        .where((a) => a['task_id'] == id)
        .toList()
        .asMap()
        .entries
        .map((e) => AlertModel(
              id: e.key + 1,
              taskId: id,
              alertTime: e.value['alert_time'] as String,
              alertType: e.value['alert_type'] as String,
              isActive: (e.value['is_active'] as int) == 1,
            ))
        .toList();

    final links = linksData.where((l) => l.taskId == id).toList();

    final locationId = taskMap['location_id'] as int?;
    LocationModel? location;
    if (locationId != null) {
      final locIndex = locationId - 1;
      final locMap = testLocations[locIndex];
      location = LocationModel(
        id: locationId,
        label: locMap['label'] as String,
        address: locMap['address'] as String?,
        latitude: locMap['latitude'] as double?,
        longitude: locMap['longitude'] as double?,
      );
    }

    final personIds = testTaskPeople
        .where((tp) => tp['task_id'] == id)
        .map((tp) => tp['person_id'] as int)
        .toList();

    final people = personIds.map((personId) {
      final personIndex = personId - 1;
      final personMap = testPeople[personIndex];
      return PersonModel(
        id: personId,
        name: personMap['name'] as String,
        phone: personMap['phone'] as String?,
        contactId: personMap['contact_id'] as String?,
      );
    }).toList();

    return TaskModel(
      id: id,
      title: taskMap['title'] as String,
      isTimeSensitive: (taskMap['time_sensitive'] as int) == 1,
      dueTime: taskMap['due_time'] as String?,
      isCompleted: (taskMap['completed'] as int) == 1,
      createdAt: taskMap['created_at'] as String,
      locationId: locationId,
      subtasks: subtasks,
      alerts: alerts,
      recurrence: recurrence,
      links: links,
      location: location,
      people: people,
    );
  });
}
