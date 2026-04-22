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

  factory AlertModel.fromMap(Map<String, dynamic> map) {
    return AlertModel(
      id: map['id'] as int,
      taskId: map['task_id'] as int,
      alertTime: map['alert_time'] as String,
      alertType: map['alert_type'] as String,
      isActive: (map['is_active'] as int) == 1,
    );
  }
}