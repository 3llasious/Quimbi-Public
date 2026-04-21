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
}
 