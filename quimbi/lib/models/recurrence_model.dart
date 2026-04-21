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
}
 