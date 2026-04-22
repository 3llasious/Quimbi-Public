String _todayAt(int hour, int minute) {
  final now = DateTime.now();
  return '${now.year.toString().padLeft(4, '0')}-'
      '${now.month.toString().padLeft(2, '0')}-'
      '${now.day.toString().padLeft(2, '0')} '
      '${hour.toString().padLeft(2, '0')}:'
      '${minute.toString().padLeft(2, '0')}:00';
}

List<Map<String, dynamic>> get testTasks => [
  {
    'title': 'Buy groceries',
    'time_sensitive': 0,
    'due_time': null,
    'completed': 0,
    'created_at': _todayAt(8, 0),
    'location_id': 1,
  },
  {
    'title': 'Submit tax return',
    'time_sensitive': 1,
    'due_time': _todayAt(17, 0),
    'completed': 0,
    'created_at': _todayAt(8, 0),
    'location_id': null,
  },
  {
    'title': 'Team standup',
    'time_sensitive': 1,
    'due_time': _todayAt(9, 0),
    'completed': 0,
    'created_at': _todayAt(8, 0),
    'location_id': 2,
  },
  {
    'title': 'Pay rent',
    'time_sensitive': 1,
    'due_time': _todayAt(18, 0),
    'completed': 0,
    'created_at': _todayAt(8, 0),
    'location_id': null,
  },
  {
    'title': 'Call dentist',
    'time_sensitive': 0,
    'due_time': null,
    'completed': 1,
    'created_at': _todayAt(8, 0),
    'location_id': 3,
  },
];
