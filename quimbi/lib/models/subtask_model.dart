class SubtaskModel {
  final int id;
  final int taskId;
  final String title;
  // not final — toggled in the UI when user taps the dot
  bool isCompleted;
  final int? position;
 
  SubtaskModel({
    required this.id,
    required this.taskId,
    required this.title,
    required this.isCompleted,
    this.position,
  });

  factory SubtaskModel.fromMap(Map<String, dynamic> map) {
    return SubtaskModel(
      id: map['id'] as int,
      taskId: map['task_id'] as int,
      title: map['title'] as String,
      isCompleted: (map['completed'] as int) == 1,
      position: map['position'] as int?,
    );
  }
}
 