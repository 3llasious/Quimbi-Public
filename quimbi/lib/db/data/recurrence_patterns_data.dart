// task_id maps to insertion order of tasks
// 1 = Buy groceries, 3 = Team standup, 4 = Pay rent
const List<Map<String, dynamic>> testRecurrencePatterns = [
  // Buy groceries — every Saturday
  {
    'task_id': 1,
    'recurrence_type': 'weekly',
    'weekdays': '6',
    'day_of_month': null,
    'interval_count': 1,
    'starts_on': '2024-01-15',
    'ends_on': null,
  },
 
  // Team standup — every weekday Mon-Fri
  {
    'task_id': 3,
    'recurrence_type': 'weekly',
    'weekdays': '1,2,3,4,5',
    'day_of_month': null,
    'interval_count': 1,
    'starts_on': '2024-01-15',
    'ends_on': null,
  },
 
  // Pay rent — every 1st of the month
  {
    'task_id': 4,
    'recurrence_type': 'monthly',
    'weekdays': null,
    'day_of_month': 1,
    'interval_count': 1,
    'starts_on': '2024-01-01',
    'ends_on': null,
  },
];