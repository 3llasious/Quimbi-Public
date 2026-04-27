import 'dart:math';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import '../logic/pet_state_machine.dart';
import '../logic/potion_manager.dart';
import '../repositories/task_repository.dart';
import '../utils/escalation_settings.dart';
import '../widgets/add_task_modal.dart';
import '../widgets/date_selector_header.dart';
import '../widgets/day_of_month_dialog.dart';
import '../widgets/nav_bar.dart';
import '../widgets/pet_widget.dart';
import '../widgets/potion_widget.dart';
import '../widgets/task_list.dart';
import 'settings_screen.dart';

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

const _monthNames = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];

class _TaskListScreenState extends State<TaskListScreen> {
  DateTime _selectedDate = DateTime.now();
  DateTime? _jumpToDate;
  String? _firstName;
  int _refreshKey = 0;
  bool _fabOpen = false;
  final _escalationSettings = EscalationSettings();
  late final PetStateMachine _petMachine;
  final _potionManager = PotionManager();
  late final ConfettiController _confettiLeft;
  late final ConfettiController _confettiRight;
  bool _showToast = false;
  int _toastPotions = 0;

  bool get _isPastDate {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final sel = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
    return sel.isBefore(today);
  }

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  void initState() {
    super.initState();
    _petMachine = PetStateMachine(_escalationSettings);
    _escalationSettings.load();
    _confettiLeft = ConfettiController(duration: const Duration(seconds: 2));
    _confettiRight = ConfettiController(duration: const Duration(seconds: 2));
    _petMachine.onTaskMissed = (taskId, missedDate) async {
      await TaskRepository().missTask(taskId, missedDate);
      if (mounted) setState(() => _refreshKey++);
    };
    _petMachine.onResurrection = () => _potionManager.spendPotion();
    _petMachine.start();
    _potionManager.load();
    _loadUserName();
  }

  void _fireConfetti() {
    _confettiLeft.play();
    _confettiRight.play();
  }

  void _showCompletionToast(int potionsEarned) {
    setState(() {
      _toastPotions = potionsEarned;
      _showToast = true;
    });
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) setState(() => _showToast = false);
    });
  }

  void _openSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SettingsScreen(settings: _escalationSettings),
      ),
    );
  }

  @override
  void dispose() {
    _confettiLeft.dispose();
    _confettiRight.dispose();
    _petMachine.dispose();
    _potionManager.dispose();
    _escalationSettings.dispose();
    super.dispose();
  }

  Future<void> _openCalendar() async {
    final picked = await showDialog<DateTime>(
      context: context,
      builder: (_) => const DayOfMonthDialog(
        accent: Color(0xFF7DBF87),
        returnFullDate: true,
        showRecurrenceLabel: false,
      ),
    );
    if (picked != null && mounted) {
      setState(() {
        _selectedDate = DateTime(picked.year, picked.month, picked.day);
        _jumpToDate = _selectedDate;
      });
    }
  }

  void _openAddModal() {
    setState(() => _fabOpen = true);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddTaskModal(
        selectedDate: _selectedDate,
        onSaved: () => setState(() => _refreshKey++),
      ),
    ).whenComplete(() => setState(() => _fabOpen = false));
  }

  Future<void> _loadUserName() async {
    final name = await TaskRepository().fetchUserName();
    if (name != null && mounted) {
      setState(() => _firstName = name.split(' ').first);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.white, Color(0xFFF5EFE6)],
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _firstName != null ? '$_greeting $_firstName,' : _greeting,
                            style: const TextStyle(
                              fontFamily: 'CanelaTrialMedium',
                              fontSize: 24,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: _openSettings,
                          child: Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5EFE6),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: const Color(0xFFE0D6C8),
                                width: 1.5,
                              ),
                            ),
                            child: const Icon(
                              Icons.tune,
                              size: 20,
                              color: Color(0xFF2D2D2D),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
  padding: const EdgeInsets.fromLTRB(0, 0, 16, 0),
  child: Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      GestureDetector(
        onTap: _openCalendar,
        child: Image.asset(
          'assets/Images/calendar.png',
          height: 60,
          width: 60,
          fit: BoxFit.contain,
        ),
      ),
      const SizedBox(width: 4),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFEDE5D8),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          _monthNames[_selectedDate.month - 1],
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.normal,
            color: Color(0xFF888888),
          ),
        ),
      ),
    ],
  ),
),
                  DateSelectorHeader(
                    jumpToDate: _jumpToDate,
                    onDateSelected: (date) =>
                        setState(() => _selectedDate = date),
                  ),
                  Expanded(
                    child: TaskList(
                      selectedDate: _selectedDate,
                      refreshKey: _refreshKey,
                      onTasksLoaded: _petMachine.updateTasks,
                      onTaskCompleted: _petMachine.onTaskCompleted,
                      onAllResolvedToday: (ids, date) async {
                        final earned = await _potionManager.checkAndAward(ids, date);
                        if (!mounted || earned == 0) return;
                        _fireConfetti();
                        _showCompletionToast(earned);
                      },
                      onTaskUncompleted: _potionManager.penaliseUndo,
                      header: Padding(
                        padding: const EdgeInsets.fromLTRB(0, 8, 0, 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            GestureDetector(
                          onTap: _petMachine.triggerAttack,
                          child: PetWidget(machine: _petMachine),
                        ),
                            const Spacer(),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: ListenableBuilder(
                                listenable: _potionManager,
                                builder: (_, _) => PotionWidget(count: _potionManager.count),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: QuimbiNavBar(
                fabOpen: _fabOpen,
                isPastDate: _isPastDate,
                onAddTap: _openAddModal,
              ),
            ),
          ),
          if (_showToast)
            Center(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 40),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(color: Color(0x22000000), blurRadius: 16, offset: Offset(0, 4)),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_toastPotions > 0) ...[
                      Image.asset('assets/Images/streak-potion.png', width: 26, height: 26),
                      const SizedBox(width: 10),
                    ],
                    Flexible(
                      child: Text(
                        _toastPotions > 0
                            ? 'All done! +$_toastPotions ${_toastPotions == 1 ? 'potion' : 'potions'}'
                            : 'All done! Tasks cleared.',
                        style: const TextStyle(fontSize: 15, color: Color(0xFF4D5B71)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Align(
            alignment: Alignment.topLeft,
            child: ConfettiWidget(
              confettiController: _confettiLeft,
              blastDirection: -pi / 6,
              emissionFrequency: 0.12,
              numberOfParticles: 20,
              gravity: 0.4,
              minimumSize: const Size(4, 4),
              maximumSize: const Size(10, 10),
              shouldLoop: false,
              colors: const [
                Color(0xFFF55420),
                Color(0xFFFFC4AC),
                Color(0xFF5CC96E),
                Color(0xFFFFD966),
                Color(0xFFB8AD96),
                Color(0xFFE3D9C1),
              ],
            ),
          ),
          Align(
            alignment: Alignment.topRight,
            child: ConfettiWidget(
              confettiController: _confettiRight,
              blastDirection: pi + pi / 6,
              emissionFrequency: 0.12,
              numberOfParticles: 20,
              gravity: 0.4,
              minimumSize: const Size(4, 4),
              maximumSize: const Size(10, 10),
              shouldLoop: false,
              colors: const [
                Color(0xFFF55420),
                Color(0xFFFFC4AC),
                Color(0xFF5CC96E),
                Color(0xFFFFD966),
                Color(0xFFB8AD96),
                Color(0xFFE3D9C1),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
