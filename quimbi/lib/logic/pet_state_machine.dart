import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/task_model.dart';

enum PetDisplayState {
  idle,
  joy,
  attack,
  escalating1, // +10min overdue — 3/4 health
  escalating2, // +20min overdue — 1/2 health
  escalating3, // +40min overdue — 1/4 health
  critical, // +55min overdue — empty
  dead, // +60min overdue → resurrection
}

class PetStateMachine extends ChangeNotifier {
  double happiness = 50;
  double energy = 50;

  // Hysteresis levels — only update when value is clearly past the boundary
  int _happinessLevel = 2;
  int _energyLevel = 2;
  static const _hysteresis = 3.0;

  PetDisplayState _displayState = PetDisplayState.idle;
  PetDisplayState get displayState => _displayState;

  String get mood => _getMood();

  void Function(int taskId, String missedDate)? onTaskMissed;
  VoidCallback? onResurrection;

  bool _reminderActive = false;
  bool get reminderActive => _reminderActive;
  Timer? _reminderTimer;

  // Tasks that already triggered death this session — prevents repeat triggers
  final Set<int> _missedTaskIds = {};
  // Tasks seen actively escalating — stale tasks that skip straight to dead bypass this
  final Set<int> _seenEscalatingIds = {};
  // Tracks alerts already triggered this session to prevent repeat fires
  final Set<String> _triggeredAlerts = {};

  List<TaskModel> _tasks = [];

  Timer? _idleTimer;
  Timer? _joyTimer;
  Timer? _escalationTimer;
  Timer? _attackTimer;

  final _rng = Random();

  void start() {
    _idleTimer = Timer.periodic(
      const Duration(seconds: 3),
      (_) => _tickIdle(),
    );
    _escalationTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) {
        _checkEscalation();
        _checkReminders();
      },
    );
  }

  void updateTasks(List<TaskModel> tasks) {
    _tasks = tasks;
    _checkEscalation();
    _checkReminders();
  }

  void triggerAttack() {
    if (_displayState == PetDisplayState.dead) return;
    _attackTimer?.cancel();
    _setDisplayState(PetDisplayState.attack);
    // Duration is a placeholder — adjust to match the gif length
    _attackTimer = Timer(const Duration(milliseconds: 1500), () {
      _setDisplayState(PetDisplayState.idle);
      _checkEscalation();
    });
  }

  void triggerReminder() {
    _reminderActive = true;
    notifyListeners();
  }

  void clearReminder() {
    if (!_reminderActive) return;
    _reminderActive = false;
    notifyListeners();
  }

  void onTaskCompleted(int taskId) {
    _missedTaskIds.remove(taskId);
    if (!_hasActiveTriggeredAlerts(excludeTaskId: taskId)) clearReminder();

    if (_displayState == PetDisplayState.dead) return;

    _joyTimer?.cancel();
    happiness = (happiness + 15).clamp(0, 100);
    energy = (energy - 10).clamp(0, 100);
    _setDisplayState(PetDisplayState.joy);

    _joyTimer = Timer(const Duration(seconds: 5), () {
      _updateLevels();
      _setDisplayState(PetDisplayState.idle);
      _checkEscalation();
    });
  }

  void _tickIdle() {
    if (_displayState != PetDisplayState.idle) return;
    final prevMood = _getMood();
    happiness = (happiness + _fluctuation()).clamp(0, 100);
    energy = (energy + _fluctuation()).clamp(0, 100);
    _updateLevels();
    if (_getMood() != prevMood) notifyListeners();
  }

  void _updateLevels() {
    _happinessLevel = _applyHysteresis(happiness, _happinessLevel);
    _energyLevel = _applyHysteresis(energy, _energyLevel);
  }

  int _applyHysteresis(double value, int currentLevel) {
    const boundaries = [25.0, 50.0, 75.0];
    if (currentLevel < 3 && value >= boundaries[currentLevel] + _hysteresis) {
      return currentLevel + 1;
    }
    if (currentLevel > 0 && value <= boundaries[currentLevel - 1] - _hysteresis) {
      return currentLevel - 1;
    }
    return currentLevel;
  }

  double _fluctuation() {
    final t = _rng.nextDouble();
    final magnitude = 2 + (t * t) * 8; // squared biases towards 2, max 10
    return _rng.nextDouble() < 0.5 ? magnitude : -magnitude;
  }

  // Returns true if any task OTHER than excludeTaskId has a triggered alert and is still active today
  bool _hasActiveTriggeredAlerts({int? excludeTaskId}) {
    final today = _todayDateString();
    return _triggeredAlerts.any((key) {
      final id = int.tryParse(key.split('_').first);
      if (id == null || id == excludeTaskId) return false;
      try {
        final task = _tasks.firstWhere((t) => t.id == id);
        return _occursToday(task) &&
            !task.isCompletedOn(today) &&
            !task.isMissedOn(today);
      } catch (_) {
        return false;
      }
    });
  }

  bool _occursToday(TaskModel task) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final r = task.recurrence;

    if (r == null) {
      final anchor = task.dueTime ?? task.createdAt;
      final due = DateTime.tryParse(anchor);
      if (due == null) return false;
      return due.year == now.year && due.month == now.month && due.day == now.day;
    }

    if (r.startsOn != null) {
      final start = DateTime.parse(r.startsOn!);
      if (today.isBefore(DateTime(start.year, start.month, start.day))) return false;
    }
    if (r.endsOn != null) {
      final end = DateTime.parse(r.endsOn!);
      if (today.isAfter(DateTime(end.year, end.month, end.day))) return false;
    }

    switch (r.recurrenceType) {
      case 'daily':
        return true;
      case 'weekly':
        if (r.weekdays == null) return false;
        final days = r.weekdays!.split(',').map(int.parse).toList();
        return days.contains(now.weekday);
      case 'monthly':
        return r.dayOfMonth != null && now.day == r.dayOfMonth;
      default:
        return false;
    }
  }

  void _checkReminders() {
    final now = DateTime.now();
    final today = _todayDateString();

    for (final task in _tasks) {
      if (!task.isTimeSensitive) continue;
      if (!_occursToday(task)) continue;
      if (task.isCompletedOn(today) || task.isMissedOn(today)) continue;

      for (final alert in task.alerts) {
        if (!alert.isActive) continue;
        final key = '${task.id}_${alert.alertTime}';
        if (_triggeredAlerts.contains(key)) continue;

        final segments = alert.alertTime.split(':');
        if (segments.length < 2) continue;
        final hour = int.tryParse(segments[0]);
        final minute = int.tryParse(segments[1]);
        if (hour == null || minute == null) continue;

        final alertTime = DateTime(now.year, now.month, now.day, hour, minute);
        if (now.isAfter(alertTime)) {
          _triggeredAlerts.add(key);
          triggerReminder();
        }
      }
    }

    // Sync: clear the reminder if no triggered alerts are still pending
    if (_reminderActive && !_hasActiveTriggeredAlerts()) {
      _reminderActive = false;
      notifyListeners();
    }
  }

  void _checkEscalation() {
    final now = DateTime.now();
    final today = _todayDateString();
    int maxMinutes = 0;
    int? worstTaskId;

    for (final task in _tasks) {
      if (!task.isTimeSensitive || task.dueTime == null) continue;
      if (task.isCompletedOn(today)) continue;
      if (_missedTaskIds.contains(task.id)) continue;
      if (task.isMissedOn(today)) {
        _missedTaskIds.add(task.id);
        continue;
      }

      final minutes = _minutesOverdue(task, now);
      if (minutes != null && minutes > maxMinutes) {
        maxMinutes = minutes;
        worstTaskId = task.id;
      }
    }

    final target = _escalationStateFor(maxMinutes);

    if (target == PetDisplayState.dead && worstTaskId != null) {
      if (_displayState != PetDisplayState.dead) {
        _missedTaskIds.add(worstTaskId);
        if (!_seenEscalatingIds.contains(worstTaskId)) {
          // Stale — task was already past death threshold when first seen, skip animation
          onTaskMissed?.call(worstTaskId, _todayDateString());
          _checkEscalation();
        } else {
          _triggerDeath(worstTaskId);
        }
      }
      return;
    }

    // Track tasks we've seen actively escalating (not stale)
    if (worstTaskId != null && target != PetDisplayState.idle) {
      _seenEscalatingIds.add(worstTaskId);
    }

    if (_displayState != PetDisplayState.joy &&
        _displayState != PetDisplayState.attack) {
      _setDisplayState(target);
    }
  }

  int? _minutesOverdue(TaskModel task, DateTime now) {
    final raw = task.dueTime!;
    final DateTime due;

    if (task.recurrence != null || !raw.contains(' ')) {
      // Recurring task: ignore the stored date, apply the time to today
      final timePart = raw.contains(' ') ? raw.split(' ').last : raw;
      final segments = timePart.split(':');
      if (segments.length < 2) return null;
      final hour = int.tryParse(segments[0]);
      final minute = int.tryParse(segments[1]);
      if (hour == null || minute == null) return null;
      due = DateTime(now.year, now.month, now.day, hour, minute);
    } else {
      // One-time task: only escalate on the specific due date
      final parsed = DateTime.tryParse(raw);
      if (parsed == null) return null;
      final dueDate = DateTime(parsed.year, parsed.month, parsed.day);
      final today = DateTime(now.year, now.month, now.day);
      if (dueDate != today) return null;
      due = parsed;
    }

    // Don't penalise tasks created today after their due time — user just added them
    final createdAt = DateTime.tryParse(task.createdAt);
    if (createdAt != null) {
      final createdToday = DateTime(createdAt.year, createdAt.month, createdAt.day) ==
          DateTime(now.year, now.month, now.day);
      if (createdToday && createdAt.isAfter(due)) return null;
    }

    final diff = now.difference(due).inMinutes;
    return diff > 0 ? diff : null;
  }

  PetDisplayState _escalationStateFor(int minutes) {
    if (minutes >= 60) return PetDisplayState.dead;
    if (minutes >= 55) return PetDisplayState.critical;
    if (minutes >= 40) return PetDisplayState.escalating3;
    if (minutes >= 20) return PetDisplayState.escalating2;
    if (minutes >= 10) return PetDisplayState.escalating1;
    return PetDisplayState.idle;
  }

  void _triggerDeath(int taskId) {
    _setDisplayState(PetDisplayState.dead);
    Future.delayed(const Duration(seconds: 8), () {
      onTaskMissed?.call(taskId, _todayDateString());
      onResurrection?.call();
      happiness = 50;
      energy = 50;
      _updateLevels();
      _checkEscalation();
    });
  }

  String _todayDateString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  String _getMood() {
    const matrix = [
      ['Empty', 'Bored', 'Sleepy', 'Dreamy'],
      ['Sulky', 'Hangry', 'Fussy', 'Cozy'],
      ['Grumpy', 'Pouty', 'Perky', 'Sunny'],
      ['Devilish', 'Jittery', 'Bouncy', 'Dancy'],
    ];
    return matrix[_energyLevel][_happinessLevel];
  }

  void _setDisplayState(PetDisplayState state) {
    if (_displayState == state) return;
    _displayState = state;
    notifyListeners();
  }

  @override
  void dispose() {
    _idleTimer?.cancel();
    _joyTimer?.cancel();
    _escalationTimer?.cancel();
    _attackTimer?.cancel();
    _reminderTimer?.cancel();
    super.dispose();
  }
}
