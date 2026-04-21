import 'package:flutter/material.dart';
import '../models/task_model.dart';
import '../models/subtask_model.dart';
import '../models/alert_model.dart';
import '../models/link_model.dart';
import '../models/recurrence_model.dart';

import 'task_card.dart';

class TaskList extends StatefulWidget {
  const TaskList({super.key});

  @override
  State<TaskList> createState() => _TaskListState();
}

class _TaskListState extends State<TaskList> {

//fake tasks so we don't hae to red from db yet
List<TaskModel> _tasks = [
  TaskModel(
    id: 1,
    title: 'Therapy Appointment',
    isTimeSensitive: true,
    dueTime: '23:30',
    isCompleted: false,
    createdAt: '2024-01-15 09:00:00',
    subtasks: [
      SubtaskModel(id: 1, taskId: 1, title: 'bring journal', isCompleted: false, position: 1),
      SubtaskModel(id: 2, taskId: 1, title: 'house keys', isCompleted: true, position: 2),
      SubtaskModel(id: 3, taskId: 1, title: 'bring water', isCompleted: true, position: 3),
    ],
    alerts: [
      AlertModel(id: 1, taskId: 1, alertTime: '14:00', alertType: 'notification', isActive: true),
      AlertModel(id: 2, taskId: 1, alertTime: '23:00', alertType: 'phone_alarm', isActive: true),
    ],
    links: [
      LinkModel(id: 1, taskId: 1, label: 'playlist', url: 'https://open.spotify.com/playlist/example'),
      LinkModel(id: 2, taskId: 1, label: 'notes', url: 'https://notion.so/therapy-notes'),
    ],
  ),
TaskModel(
    id: 2,
    title: 'Screen Break: Walk',
    isTimeSensitive: false,
    dueTime: '19:00',
    isCompleted: false,
    createdAt: '2024-01-15 09:00:00',
    subtasks: [],
    alerts: [
      AlertModel(id: 3, taskId: 2, alertTime: '18:45', alertType: 'notification', isActive: true),
    ],
    links: [],
    recurrence: RecurrenceModel(
      id: 2,
      taskId: 2,
      recurrenceType: 'weekly',
      weekdays: '6',
      intervalCount: 1,
      startsOn: '2024-01-15',
    ),
  ),
];

  void _completeTask(int taskId) {
    setState(() => _tasks.removeWhere((task) => task.id == taskId));
  }

  void _deleteTask(int taskId) {
    setState(() => _tasks.removeWhere((task) => task.id == taskId));
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _tasks.length,
      itemBuilder: (context, index) {
        final task = _tasks[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: TaskCard(
            task: task,
            onComplete: () => _completeTask(task.id),
            onDelete: () => _deleteTask(task.id),
          ),
        );
      },
    );
  }
}