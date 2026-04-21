class AlertModel {
  final int id;
  final int taskId;
  final String alertTime;
  final String alertType;
  final bool isActive;

  const AlertModel({
    required this.id,
    required this.taskId,
    required this.alertTime,
    required this.alertType,
    required this.isActive,
  });
}