class LinkModel {
  final int id;
  final int taskId;
  final String label;
  final String url;

  const LinkModel({
    required this.id,
    required this.taskId,
    required this.label,
    required this.url,
  });

  factory LinkModel.fromMap(Map<String, dynamic> map) {
    return LinkModel(
      id: map['id'] as int,
      taskId: map['task_id'] as int,
      label: map['label'] as String,
      url: map['url'] as String,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'task_id': taskId,
    'label': label,
    'url': url,
  };
}
