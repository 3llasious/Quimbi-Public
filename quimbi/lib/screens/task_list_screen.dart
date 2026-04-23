import 'package:flutter/material.dart';
import '../repositories/task_repository.dart';
import '../widgets/add_task_modal.dart';
import '../widgets/date_selector_header.dart';
import '../widgets/nav_bar.dart';
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
  String? _firstName;
  int _refreshKey = 0;
  bool _fabOpen = false;

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
    _loadUserName();
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
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                    child: Text(
                      _monthNames[_selectedDate.month - 1],
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4D5B71),
                      ),
                    ),
                  ),
                  DateSelectorHeader(
                    onDateSelected: (date) =>
                        setState(() => _selectedDate = date),
                  ),
                  const SizedBox(height: 8),
                  Expanded(child: TaskList(selectedDate: _selectedDate, refreshKey: _refreshKey)),
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
