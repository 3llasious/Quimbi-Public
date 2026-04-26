import 'package:flutter/foundation.dart';
import '../repositories/task_repository.dart';

class PotionManager extends ChangeNotifier {
  int _count = 0;
  int get count => _count;

  final _repo = TaskRepository();

  Future<void> load() async {
    _count = await _repo.fetchPotionCount();
    notifyListeners();
  }

  // Called when all of today's tasks are resolved.
  // Awards 1 potion per newly-completed task (guards against double-awarding).
  // Returns the number of potions actually awarded (0 if already awarded).
  Future<int> checkAndAward(List<int> completedTaskIds, String date) async {
    if (completedTaskIds.isEmpty) return 0;
    final alreadyAwarded = await _repo.fetchAwardedTaskIds(date);
    final newIds = completedTaskIds.where((id) => !alreadyAwarded.contains(id)).toList();
    if (newIds.isEmpty) return 0;
    await _repo.adjustPotions(newIds.length, awardTaskIds: newIds, awardDate: date);
    await _syncCount();
    return newIds.length;
  }

  Future<void> penaliseUndo() async {
    await _repo.adjustPotions(-2);
    await _syncCount();
  }

  Future<void> spendPotion() async {
    if (_count <= 0) return;
    await _repo.adjustPotions(-1);
    await _syncCount();
  }

  Future<void> _syncCount() async {
    _count = await _repo.fetchPotionCount();
    notifyListeners();
  }
}
