// task_id maps to insertion order of tasks
// 1 = Buy groceries, 2 = Submit tax return, 3 = Team standup
const List<Map<String, dynamic>> testSubtasks = [
  {
    'task_id': 1,
    'title': 'Check what is in the fridge',
    'completed': 1,
    'position': 1,
  },
  {
    'task_id': 1,
    'title': 'Write shopping list',
    'completed': 1,
    'position': 2,
  },
  {
    'task_id': 1,
    'title': 'Go to supermarket',
    'completed': 0,
    'position': 3,
  },
  {
    'task_id': 2,
    'title': 'Gather P60 documents',
    'completed': 0,
    'position': 1,
  },
  {
    'task_id': 2,
    'title': 'Log into HMRC portal',
    'completed': 0,
    'position': 2,
  },
  {
    'task_id': 2,
    'title': 'Submit return',
    'completed': 0,
    'position': 3,
  },
  {
    'task_id': 3,
    'title': 'Review yesterdays progress',
    'completed': 0,
    'position': 1,
  },
  {
    'task_id': 3,
    'title': 'Prepare blockers to raise',
    'completed': 0,
    'position': 2,
  },
];