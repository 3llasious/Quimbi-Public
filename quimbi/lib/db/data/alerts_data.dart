String _fmtTime(int hour, int minute) {
  final now = DateTime.now();
  return '${now.year.toString().padLeft(4, '0')}-'
      '${now.month.toString().padLeft(2, '0')}-'
      '${now.day.toString().padLeft(2, '0')} '
      '${hour.toString().padLeft(2, '0')}:'
      '${minute.toString().padLeft(2, '0')}:00';
}

List<Map<String, dynamic>> get testAlerts {
  return [
    // Submit tax return — due 17:00, alert 30 mins before at 16:30
    {
      'task_id': 2,
      'alert_time': _fmtTime(16, 30),
      'alert_type': 'notification',
      'is_active': 1,
    },

    // Team standup — due 09:00, alert 1hr before at 08:00
    {
      'task_id': 3,
      'alert_time': _fmtTime(8, 0),
      'alert_type': 'phone_alarm',
      'is_active': 1,
    },
    // Team standup — 30 mins before at 08:30
    {
      'task_id': 3,
      'alert_time': _fmtTime(8, 30),
      'alert_type': 'notification',
      'is_active': 1,
    },

    // Pay rent — due 18:00, alert 1hr before at 17:00
    {
      'task_id': 4,
      'alert_time': _fmtTime(17, 0),
      'alert_type': 'notification',
      'is_active': 1,
    },
    // Pay rent — 30 mins before at 17:30
    {
      'task_id': 4,
      'alert_time': _fmtTime(17, 30),
      'alert_type': 'imessage',
      'is_active': 1,
    },
  ];
}
