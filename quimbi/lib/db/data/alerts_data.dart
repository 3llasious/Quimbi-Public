// task_id maps to insertion order of tasks
// 2 = Submit tax return, 3 = Team standup, 4 = Pay rent
const List<Map<String, dynamic>> testAlerts = [
  // Submit tax return — notification the morning of
  {
    'task_id': 2,
    'alert_time': '2024-01-31 09:00:00',
    'alert_type': 'notification',
    'is_active': 1,
  },

  // Team standup — phone alarm 30 mins before
  {
    'task_id': 3,
    'alert_time': '2024-01-15 09:00:00',
    'alert_type': 'phone_alarm',
    'is_active': 1,
  },

  // Pay rent — two alerts, different types
  {
    'task_id': 4,
    'alert_time': '2024-01-29 09:00:00',
    'alert_type': 'notification',
    'is_active': 1,
  },
  {
    'task_id': 4,
    'alert_time': '2024-01-29 09:00:00',
    'alert_type': 'imessage',
    'is_active': 1,
  },
];