class RecurrenceModel {
  final int id;
  final int taskId;
  final String recurrenceType;
  final String? weekdays;
  final int? dayOfMonth;
  final int? intervalCount;
  final String? startsOn;
  final String? endsOn;
 
  const RecurrenceModel({
    required this.id,
    required this.taskId,
    required this.recurrenceType,
    this.weekdays,
    this.dayOfMonth,
    this.intervalCount,
    this.startsOn,
    this.endsOn,
  });

  factory RecurrenceModel.fromMap(Map<String, dynamic> map) {
    return RecurrenceModel(
      id: map['id'] as int,
      taskId: map['task_id'] as int,
      recurrenceType: map['recurrence_type'] as String,
      weekdays: map['weekdays'] as String?,
      dayOfMonth: map['day_of_month'] as int?,
      intervalCount: map['interval_count'] as int?,
      startsOn: map['starts_on'] as String?,
      endsOn: map['ends_on'] as String?,
    );
  }
}
 