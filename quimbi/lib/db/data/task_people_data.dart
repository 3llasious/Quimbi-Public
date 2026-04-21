// task_id → task insertion order: 1=Buy groceries, 2=Submit tax return, 3=Team standup, 4=Pay rent, 5=Call dentist
// person_id → person insertion order: 1=Alice Johnson, 2=Bob Patel, 3=Dr. Smith
const List<Map<String, dynamic>> testTaskPeople = [
  // Team standup includes Alice and Bob
  {'task_id': 3, 'person_id': 1},
  {'task_id': 3, 'person_id': 2},

  // Call dentist is with Dr. Smith
  {'task_id': 5, 'person_id': 3},
];
