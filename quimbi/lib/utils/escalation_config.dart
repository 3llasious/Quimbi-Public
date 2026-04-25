class EscalationConfig {
  static const int mildMinutes = 10;
  static const int moderateMinutes = 20;
  static const int severeMinutes = 40;
  static const int criticalMinutes = 55;
  static const int deathMinutes = 60;

  static const idleTickInterval = Duration(seconds: 3);
  static const escalationCheckInterval = Duration(minutes: 1);
  static const attackAnimationDuration = Duration(milliseconds: 1500);
  static const joyStateDuration = Duration(seconds: 5);
  static const deathAnimationDuration = Duration(seconds: 8);
}
