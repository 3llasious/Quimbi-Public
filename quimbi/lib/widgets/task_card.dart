import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/task_model.dart';
import '../models/alert_model.dart';
import '../models/subtask_model.dart';

class AppColours {
  static const orange = Color(0xFFFF4A00);
  static const peach = Color(0xFFFFC4AC);
  static const slate = Color(0xFF4D5B71);
  static const lightSlate = Color(0xFF8D9EB7);
  static const green = Color(0xFF5CC96E);
  static const red = Color(0xFFFF6B5B);
  static const overdueRed = Color(0xFFFF383C);
  static const purple = Color(0xFF7B61FF);
  static const purpleFaded = Color(0xFFD7CFFF);
}

class TaskCard extends StatefulWidget {
  final TaskModel task;
  final VoidCallback onComplete;
  final VoidCallback onDelete;

  const TaskCard({
    super.key,
    required this.task,
    required this.onComplete,
    required this.onDelete,
  });

  @override
  State<TaskCard> createState() => _TaskCardState();
}

class _TaskCardState extends State<TaskCard>
    with SingleTickerProviderStateMixin {

  bool _isExpanded = false;
  late AnimationController _expandController;
  late Animation<double> _expandAnimation;
  Timer? _countdownTimer;
  int _secondsLeft = 0;
  bool _isCountdownVisible = false;

  @override
  void initState() {
    super.initState();
    _setupAnimation();
    if (widget.task.isTimeSensitive) _startCountdown();
  }

  @override
  void dispose() {
    _expandController.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _setupAnimation() {
    _expandController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _expandController,
      curve: Curves.elasticOut,
    );
  }

  void _setupCountdown() {
    if (widget.task.alerts.isEmpty || widget.task.dueTime == null) return;

    final now = DateTime.now();

    final alertTimes = widget.task.alerts.map((alert) {
      final parts = _parseTimeParts(alert.alertTime);
      return DateTime(now.year, now.month, now.day,
          int.parse(parts[0]), int.parse(parts[1]));
    }).toList();

    alertTimes.sort();
    final earliestAlert = alertTimes.first;

    final dueParts = _parseTimeParts(widget.task.dueTime!);
    final dueDateTime = DateTime(now.year, now.month, now.day,
        int.parse(dueParts[0]), int.parse(dueParts[1]));

    if (now.isAfter(earliestAlert)) {
      _isCountdownVisible = true;
      _secondsLeft = dueDateTime.difference(now).inSeconds;
    }
  }

  Color _accentColour() {
    return widget.task.isTimeSensitive ? AppColours.orange : AppColours.purple;
  }

  Color _fadedAccentColour() {
    return widget.task.isTimeSensitive ? AppColours.peach : AppColours.purpleFaded;
  }

  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_isCountdownVisible) {
        _setupCountdown();
      }
      setState(() {
        if (_isCountdownVisible) {
          _secondsLeft--;
        }
      });
    });
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      _isExpanded ? _expandController.forward() : _expandController.reverse();
    });
  }

  void _toggleSubtask(SubtaskModel subtask) {
    setState(() => subtask.isCompleted = !subtask.isCompleted);
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    await launchUrl(uri);
  }

  // Extracts HH:MM from either 'HH:MM', 'HH:MM:SS', or 'YYYY-MM-DD HH:MM:SS'
  List<String> _parseTimeParts(String rawTime) {
    final timePart = rawTime.contains(' ') ? rawTime.split(' ').last : rawTime;
    final parts = timePart.split(':');
    return [parts[0], parts.length > 1 ? parts[1] : '00'];
  }

  String _formatCountdown() {
    final absoluteSeconds = _secondsLeft.abs();

    final hours = (absoluteSeconds ~/ 3600).toString().padLeft(2, '0');
    final minutes = ((absoluteSeconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final seconds = (absoluteSeconds % 60).toString().padLeft(2, '0');

    final timeString = _isExpanded
        ? '$hours:$minutes:$seconds'
        : '$hours:$minutes';

    return _secondsLeft < 0 ? 'overdue $timeString' : timeString;
  }

  Color _countdownColour() {
    return _secondsLeft < 0 ? AppColours.overdueRed : _accentColour();
  }

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(widget.task.id.toString()),
      onDismissed: (direction) {
        if (direction == DismissDirection.startToEnd) {
          widget.onComplete();
        } else {
          widget.onDelete();
        }
      },
      background: _buildSwipeBackground(
        color: AppColours.green,
        icon: Icons.check,
        alignment: Alignment.centerLeft,
      ),
      secondaryBackground: _buildSwipeBackground(
        color: AppColours.red,
        icon: Icons.delete_outline,
        alignment: Alignment.centerRight,
      ),
      child: _buildCard(),
    );
  }

  Widget _buildSwipeBackground({
    required Color color,
    required IconData icon,
    required Alignment alignment,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(28),
      ),
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Icon(icon, color: Colors.white, size: 32),
    );
  }

  Widget _buildCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x40000000),
            blurRadius: 4,
            offset: Offset(4, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 16, 12),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTimeColumn(),
            const SizedBox(width: 5),
            Expanded(child: _buildContentColumn()),
            const SizedBox(width: 5),
            _buildIconColumn(),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeColumn() {
    final timeParts = _parseTimeParts(widget.task.dueTime ?? '00:00');
    final hours = timeParts[0];
    final minutes = timeParts[1];

    return SizedBox(
      width: 70,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$hours:',
            style: TextStyle(
              color: _accentColour(),
              fontSize: 38,
              height: 1,
              letterSpacing: -1,
            ),
          ),
          Text(
            minutes,
            style: TextStyle(
              color: _fadedAccentColour(),
              fontSize: 38,
              height: 1,
              letterSpacing: -1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_isExpanded && widget.task.isTimeSensitive && _isCountdownVisible) _buildCountdownRow(),
        Text(
          widget.task.title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(height: 4),
        _buildMetaRow(Icons.location_on_outlined, 'home.westminster'),
        const SizedBox(height: 4),
        _buildMetaRow(Icons.person_outline, 'Delilah Madden'),
        const SizedBox(height: 8),
        _buildActionButtons(),
        SizeTransition(
          sizeFactor: _expandAnimation,
          axisAlignment: -1,
          child: _buildExpandedSection(),
        ),
        const SizedBox(height: 8),
        _buildBottomRow(),
      ],
    );
  }

  Widget _buildCountdownRow() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(Icons.timer_outlined, color: _countdownColour(), size: 14),
          const SizedBox(width: 5),
          Text(
            _formatCountdown(),
            style: TextStyle(
              color: _countdownColour(),
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetaRow(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 12, color: AppColours.slate),
        const SizedBox(width: 5),
        Text(label, style: const TextStyle(color: AppColours.slate, fontSize: 11)),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        if (widget.task.recurrence != null) ...[
          _buildSvgActionButton('assets/icons/repeate-one.svg'),
          const SizedBox(width: 5),
        ],
        ..._buildAlertButtons(),
      ],
    );
  }

  List<Widget> _buildAlertButtons() {
    final alertButtons = <Widget>[];

    for (final alert in widget.task.alerts) {
      final hasAlertPassed = _hasAlertTimePassed(alert.alertTime);

      alertButtons.add(
        _buildActionButton(
          _iconForAlertType(alert.alertType),
          _backgroundForAlertType(alert.alertType, hasAlertPassed),
          _iconColourForAlertType(alert.alertType, hasAlertPassed),
        ),
      );
      alertButtons.add(const SizedBox(width: 5));
    }

    return alertButtons;
  }

  bool _hasAlertTimePassed(String alertTime) {
    final now = DateTime.now();
    final timeParts = _parseTimeParts(alertTime);
    final alertDateTime = DateTime(
      now.year,
      now.month,
      now.day,
      int.parse(timeParts[0]),
      int.parse(timeParts[1]),
    );
    return now.isAfter(alertDateTime);
  }

  IconData _iconForAlertType(String alertType) {
    switch (alertType) {
      case 'notification': return Icons.notifications_outlined;
      case 'phone_alarm':  return Icons.alarm;
      case 'imessage':     return Icons.message_outlined;
      default:             return Icons.notifications_outlined;
    }
  }

  Color _backgroundForAlertType(String alertType, bool hasPassed) {
    if (hasPassed) return _fadedAccentColour();
    return _accentColour();
  }

  Color _iconColourForAlertType(String alertType, bool hasPassed) {
    return Colors.white;
  }

  Widget _buildActionButton(IconData icon, Color background, Color iconColour) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(9.5),
        boxShadow: const [
          BoxShadow(color: Color(0x26000000), blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Icon(icon, size: 16, color: iconColour),
    );
  }

  Widget _buildSvgActionButton(String assetPath) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(9.5),
        boxShadow: const [
          BoxShadow(color: Color(0x26000000), blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: SvgPicture.asset(
          assetPath,
          colorFilter: ColorFilter.mode(_accentColour(), BlendMode.srcIn),
        ),
      ),
    );
  }

  Widget _buildLinksRow() {
    if (widget.task.links.isEmpty) return const SizedBox.shrink();

    return Row(
      children: [
        SvgPicture.asset('assets/icons/link.svg', width: 14, height: 14),
        const SizedBox(width: 8),
        Expanded(
          child: Wrap(
            spacing: 6,
            children: widget.task.links
                .map((link) => GestureDetector(
                      onTap: () => _launchUrl(link.url),
                      child: Text(
                        link.label,
                        style: const TextStyle(
                          color: AppColours.slate,
                          fontSize: 11,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ))
                .toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildExpandedSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        _buildLinksRow(),
        const SizedBox(height: 8),
        ...widget.task.subtasks.map((subtask) => _buildSubtaskRow(subtask)),
      ],
    );
  }

  Widget _buildSubtaskRow(SubtaskModel subtask) {
    return GestureDetector(
      onTap: () => _toggleSubtask(subtask),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            _buildDot(subtask.isCompleted),
            const SizedBox(width: 8),
            Text(subtask.title, style: const TextStyle(color: AppColours.slate, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget _buildDot(bool isFilled) {
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const RadialGradient(
          colors: [Color(0xFFDDE3EC), Color(0xFFEEF0F4)],
        ),
        border: Border.all(color: const Color(0x99B4BECD)),
        boxShadow: const [
          BoxShadow(color: Color(0x2E000000), blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: isFilled
          ? Center(
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _accentColour(),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildBottomRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          onTap: _toggleExpanded,
          child: AnimatedRotation(
            turns: _isExpanded ? 0.5 : 0,
            duration: const Duration(milliseconds: 250),
            child: Icon(
              Icons.keyboard_arrow_down,
              color: _accentColour(),
              size: 20,
            ),
          ),
        ),
        if (!_isExpanded && widget.task.isTimeSensitive && _isCountdownVisible)
          Row(
            children: [
              Icon(Icons.timer_outlined, color: _countdownColour(), size: 12),
              const SizedBox(width: 5),
              Text(
                _formatCountdown(),
                style: TextStyle(
                  color: _countdownColour(),
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildIconColumn() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        SvgPicture.asset('assets/icons/copy.svg', width: 22, height: 22),
        SvgPicture.asset('assets/icons/Button OnClick- edit.svg', width: 17, height: 17),
      ],
    );
  }
}
