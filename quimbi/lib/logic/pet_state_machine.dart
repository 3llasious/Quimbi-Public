import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/task_model.dart';
import '../utils/date_time_utils.dart';
import '../utils/escalation_config.dart';

enum PetDisplayState {
  idle,
  joy,
  attack,
  escalating1, // +10 min overdue — 3/4 health
  escalating2, // +20 min overdue — 1/2 health
  escalating3, // +40 min overdue — 1/4 health
  critical,    // +55 min overdue — empty
  dead,        // +60 min overdue → resurrection
}

class PetStateMachine extends ChangeNotifier {
  double happiness = 50;
  double energy = 50;

  // Hysteresis prevents rapid flickering between mood states at a boundary.
  int _happinessLevel = 2;
  int _energyLevel = 2;
  static const _hysteresis = 3.0;

  PetDisplayState _displayState = PetDisplayState.idle;
  PetDisplayState get displayState => _displayState;

  String get mood => _moodMatrix[_energyLevel][_happinessLevel];

  void Function(int taskId, String missedDate)? onTaskMissed;
  VoidCallback? onResurrection;

  bool _reminderActive = false;
  bool get reminderActive => _reminderActive;

  // Tasks that already triggered death this session — prevents repeat triggers.
  final Set<int> _missedTaskIds = {};
  // Tasks seen actively escalating — stale tasks that skip straight to dead bypass the animation.
  final Set<int> _activelyEscalatingIds = {};
  // Alert keys ('taskId_HH:MM') triggered this session — prevents re-firing.
  final Set<String> _triggeredAlerts = {};

  // Used to detect midnight rollover and reset session state.
  String _lastKnownDay = '';

  List<TaskModel> _tasks = [];

  Timer? _idleTimer;
  Timer? _joyTimer;
  Timer? _escalationTimer;
  Timer? _attackTimer;

  final _rng = Random();

  static const _moodMatrix = [
    ['Empty', 'Bored', 'Sleepy', 'Dreamy'],
    ['Sulky', 'Hangry', 'Fussy', 'Cozy'],
    ['Grumpy', 'Pouty', 'Perky', 'Sunny'],
    ['Devilish', 'Jittery', 'Bouncy', 'Dancy'],
  ];

  void start() {
    _lastKnownDay = todayDateString();
    _idleTimer = Timer.periodic(EscalationConfig.idleTickInterval, (_) => _tickIdle());
    _escalationTimer = Timer.periodic(EscalationConfig.escalationCheckInterval, (_) {
      _checkAndResetForNewDay();
      _checkEscalation();
      _checkReminders();
    });
  }

  void updateTasks(List<TaskModel> tasks) {
    _tasks = tasks;
    _checkAndResetForNewDay();
    _checkEscalation();
    _checkReminders();
  }

  void triggerAttack() {
    if (_displayState == PetDisplayState.dead) return;
    _attackTimer?.cancel();
    _setDisplayState(PetDisplayState.attack);
    _attackTimer = Timer(EscalationConfig.attackAnimationDuration, () {
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

    _joyTimer = Timer(EscalationConfig.joyStateDuration, () {
      _updateLevels();
      _setDisplayState(PetDisplayState.idle);
      _checkEscalation();
    });
  }

  void _checkAndResetForNewDay() {
    final today = todayDateString();
    if (today == _lastKnownDay) return;
    _lastKnownDay = today;
    _missedTaskIds.clear();
    _activelyEscalatingIds.clear();
    _triggeredAlerts.clear();
    if (_reminderActive) {
      _reminderActive = false;
      notifyListeners();
    }
  }

  void _tickIdle() {
    if (_displayState != PetDisplayState.idle) return;
    final previousMood = mood;
    happiness = (happiness + _nextMoodDelta()).clamp(0, 100);
    energy = (energy + _nextMoodDelta()).clamp(0, 100);
    _updateLevels();
    if (mood != previousMood) notifyListeners();
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

  double _nextMoodDelta() {
    final randomValue = _rng.nextDouble();
    final magnitude = 2 + (randomValue * randomValue) * 8; // squared bias towards small changes
    return _rng.nextDouble() < 0.5 ? magnitude : -magnitude;
  }

  // Returns true if any task (other than excludeTaskId) has a triggered alert
  // that is still pending today — i.e. the task occurs today and is not yet resolved.
  bool _hasActiveTriggeredAlerts({int? excludeTaskId}) {
    final today = todayDateString();
    final now = DateTime.now();
    return _triggeredAlerts.any((key) {
      final taskId = int.tryParse(key.split('_').first);
      if (taskId == null || taskId == excludeTaskId) return false;
      try {
        final task = _tasks.firstWhere((t) => t.id == taskId);
        return task.occursOn(now) &&
            !task.isCompletedOn(today) &&
            !task.isMissedOn(today);
      } catch (_) {
        return false;
      }
    });
  }

  void _checkReminders() {
    final now = DateTime.now();
    final today = todayDateString();

    for (final task in _tasks) {
      if (!task.isTimeSensitive) continue;
      if (!task.occursOn(now)) continue;
      if (task.isCompletedOn(today) || task.isMissedOn(today)) continue;

      for (final alert in task.alerts) {
        if (!alert.isActive) continue;
        final key = '${task.id}_${alert.alertTime}';
        if (_triggeredAlerts.contains(key)) continue;

        final parsed = parseTimeParts(alert.alertTime);
        if (parsed == null) continue;

        final alertTime = DateTime(now.year, now.month, now.day, parsed.hour, parsed.minute);
        if (now.isAfter(alertTime)) {
          _triggeredAlerts.add(key);
          triggerReminder();
        }
      }
    }

    _syncReminderState();
  }

  void _syncReminderState() {
    if (_reminderActive && !_hasActiveTriggeredAlerts()) {
      _reminderActive = false;
      notifyListeners();
    }
  }

  void _checkEscalation() {
    final now = DateTime.now();
    final today = todayDateString();
    final worstTask = _findWorstOverdueTask(now, today);

    final maxMinutes = worstTask?.$2 ?? 0;
    final worstTaskId = worstTask?.$1;

    final target = _escalationStateFor(maxMinutes);

    if (target == PetDisplayState.dead && worstTaskId != null) {
      _handleDeathTransition(worstTaskId);
      return;
    }

    if (worstTaskId != null && target != PetDisplayState.idle) {
      _activelyEscalatingIds.add(worstTaskId);
    }

    if (_displayState != PetDisplayState.joy && _displayState != PetDisplayState.attack) {
      _setDisplayState(target);
    }
  }

  (int taskId, int minutes)? _findWorstOverdueTask(DateTime now, String today) {
    int maxMinutes = 0;
    int? worstTaskId;

    for (final task in _tasks) {
      if (!task.isTimeSensitive || task.dueTime == null) continue;
      if (!task.occursOn(now)) continue;
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

    return worstTaskId != null ? (worstTaskId, maxMinutes) : null;
  }

  void _handleDeathTransition(int taskId) {
    if (_displayState == PetDisplayState.dead) return;
    _missedTaskIds.add(taskId);

    if (!_activelyEscalatingIds.contains(taskId)) {
      // Task was already past the death threshold when first seen — skip animation.
      onTaskMissed?.call(taskId, todayDateString());
      _checkEscalation();
    } else {
      _triggerDeath(taskId);
    }
  }

  int? _minutesOverdue(TaskModel task, DateTime now) {
    final raw = task.dueTime!;
    final DateTime due;

    if (task.recurrence != null || !raw.contains(' ')) {
      final timePart = raw.contains(' ') ? raw.split(' ').last : raw;
      final parsed = parseTimeParts(timePart);
      if (parsed == null) return null;
      due = DateTime(now.year, now.month, now.day, parsed.hour, parsed.minute);
    } else {
      final parsed = DateTime.tryParse(raw);
      if (parsed == null) return null;
      final dueDate = parsed.dateOnly;
      final today = now.dateOnly;
      if (dueDate != today) return null;
      due = parsed;
    }

    final createdAt = DateTime.tryParse(task.createdAt);
    if (createdAt != null) {
      final createdToday = createdAt.dateOnly == now.dateOnly;
      if (createdToday && createdAt.isAfter(due)) return null;
    }

    final diff = now.difference(due).inMinutes;
    return diff > 0 ? diff : null;
  }

  PetDisplayState _escalationStateFor(int minutes) {
    if (minutes >= EscalationConfig.deathMinutes) return PetDisplayState.dead;
    if (minutes >= EscalationConfig.criticalMinutes) return PetDisplayState.critical;
    if (minutes >= EscalationConfig.severeMinutes) return PetDisplayState.escalating3;
    if (minutes >= EscalationConfig.moderateMinutes) return PetDisplayState.escalating2;
    if (minutes >= EscalationConfig.mildMinutes) return PetDisplayState.escalating1;
    return PetDisplayState.idle;
  }

  void _triggerDeath(int taskId) {
    _setDisplayState(PetDisplayState.dead);
    Future.delayed(EscalationConfig.deathAnimationDuration, () {
      onTaskMissed?.call(taskId, todayDateString());
      onResurrection?.call();
      happiness = 50;
      energy = 50;
      _updateLevels();
      _checkEscalation();
    });
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
    super.dispose();
  }
}
