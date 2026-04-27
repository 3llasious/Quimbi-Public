import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum QuimbiPersonality { base, sunny, anxious, sleepy, grumpy }

class EscalationSettings extends ChangeNotifier {
  static const _keyMild = 'esc_mild';
  static const _keyModerate = 'esc_moderate';
  static const _keySevere = 'esc_severe';
  static const _keyCritical = 'esc_critical';
  static const _keyDeath = 'esc_death';
  static const _keyPersonality = 'esc_personality';

  int mildMinutes = 10;
  int moderateMinutes = 20;
  int severeMinutes = 40;
  int criticalMinutes = 55;
  int deathMinutes = 60;
  QuimbiPersonality personality = QuimbiPersonality.base;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    mildMinutes = prefs.getInt(_keyMild) ?? 10;
    moderateMinutes = prefs.getInt(_keyModerate) ?? 20;
    severeMinutes = prefs.getInt(_keySevere) ?? 40;
    criticalMinutes = prefs.getInt(_keyCritical) ?? 55;
    deathMinutes = prefs.getInt(_keyDeath) ?? 60;
    final pName = prefs.getString(_keyPersonality) ?? 'base';
    personality = QuimbiPersonality.values.firstWhere(
      (p) => p.name == pName,
      orElse: () => QuimbiPersonality.base,
    );
    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyMild, mildMinutes);
    await prefs.setInt(_keyModerate, moderateMinutes);
    await prefs.setInt(_keySevere, severeMinutes);
    await prefs.setInt(_keyCritical, criticalMinutes);
    await prefs.setInt(_keyDeath, deathMinutes);
    await prefs.setString(_keyPersonality, personality.name);
  }

  void setMild(int v) { mildMinutes = v; notifyListeners(); _persist(); }
  void setModerate(int v) { moderateMinutes = v; notifyListeners(); _persist(); }
  void setSevere(int v) { severeMinutes = v; notifyListeners(); _persist(); }
  void setCritical(int v) { criticalMinutes = v; notifyListeners(); _persist(); }
  void setDeath(int v) { deathMinutes = v; notifyListeners(); _persist(); }

  void setPersonality(QuimbiPersonality v) {
    personality = v;
    notifyListeners();
    _persist();
  }
}
