import 'package:flutter/material.dart';
import '../logic/pet_state_machine.dart';
import '../logic/potion_manager.dart';
import '../repositories/task_repository.dart';
import '../widgets/add_task_modal.dart';
import '../widgets/date_selector_header.dart';
import '../widgets/day_of_month_dialog.dart';
import '../widgets/nav_bar.dart';
import '../widgets/pet_widget.dart';
import '../widgets/potion_widget.dart';
import '../widgets/task_list.dart';

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
  final _petMachine = PetStateMachine();
  final _potionManager = PotionManager();

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
    _petMachine.onTaskMissed = (taskId, missedDate) async {
      await TaskRepository().missTask(taskId, missedDate);
      if (mounted) setState(() => _refreshKey++);
    };
    _petMachine.onResurrection = () => _potionManager.spendPotion();
    _petMachine.start();
    _potionManager.load();
    _loadUserName();
  }

  @override
  void dispose() {
    _petMachine.dispose();
    _potionManager.dispose();
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
                    child: Text(
                      _firstName != null ? '$_greeting $_firstName,' : _greeting,
                      style: const TextStyle(
                        fontFamily: 'CanelaTrialMedium',
                        fontSize: 24,
                      ),
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
                      onAllResolvedToday: _potionManager.checkAndAward,
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
                                builder: (_, __) => PotionWidget(count: _potionManager.count),
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
        ],
      ),
    );
  }
}
