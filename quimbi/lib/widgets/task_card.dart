import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/task_model.dart';
import '../models/subtask_model.dart';
import 'edit_task_modal.dart';
import 'copy_task_modal.dart';

class AppColours {
  static const orange = Color(0xFFF55420);
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
  final DateTime selectedDate;
  final VoidCallback onComplete;
  final VoidCallback onDelete;
  final VoidCallback? onUndo;
  final VoidCallback? onRefresh;
  final bool isCompleted;
  final bool isMissed;

  const TaskCard({
    super.key,
    required this.task,
    required this.selectedDate,
    required this.onComplete,
    required this.onDelete,
    this.onUndo,
    this.onRefresh,
    this.isCompleted = false,
    this.isMissed = false,
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

  bool get _isToday {
    final now = DateTime.now();
    final d = widget.selectedDate;
    return d.year == now.year && d.month == now.month && d.day == now.day;
  }

  bool get _isFuture {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final sel = DateTime(widget.selectedDate.year, widget.selectedDate.month, widget.selectedDate.day);
    return sel.isAfter(today);
  }

  @override
  void initState() {
    super.initState();
    _setupAnimation();
    if (widget.task.isTimeSensitive && _isToday && !widget.isCompleted && !widget.isMissed) _startCountdown();
  }

  @override
  void didUpdateWidget(TaskCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final o = oldWidget.selectedDate;
    final n = widget.selectedDate;
    final dateChanged = o.year != n.year || o.month != n.month || o.day != n.day;
    final dueTimeChanged = oldWidget.task.dueTime != widget.task.dueTime;

    if (dateChanged || dueTimeChanged) {
      _countdownTimer?.cancel();
      _countdownTimer = null;
      _secondsLeft = 0;
      _isCountdownVisible = false;
      if (widget.task.isTimeSensitive && _isToday && !widget.isCompleted && !widget.isMissed) _startCountdown();
    }
  }

  @override
  void dispose() {
    _expandController.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  String _dateStr(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

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
    final d = widget.selectedDate;

    final alertTimes = widget.task.alerts.map((alert) {
      final parts = _parseTimeParts(alert.alertTime);
      return DateTime(d.year, d.month, d.day,
          int.parse(parts[0]), int.parse(parts[1]));
    }).toList();

    alertTimes.sort();
    final earliestAlert = alertTimes.first;

    final dueParts = _parseTimeParts(widget.task.dueTime!);
    final dueDateTime = DateTime(d.year, d.month, d.day,
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

 void _openEditModal() {
  showDialog(
    context: context,
    builder: (_) => EditTaskModal(
      task: widget.task,
      selectedDate: widget.selectedDate,
      onSaved: () { widget.onRefresh?.call(); },
    ),
  );
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
    if (rawTime.isEmpty) return ['00', '00'];
    final timePart = rawTime.contains(' ') ? rawTime.split(' ').last : rawTime;
    if (!timePart.contains(':')) return ['00', '00'];
    final parts = timePart.split(':');
    if (parts.isEmpty || parts[0].isEmpty) return ['00', '00'];
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

    return timeString;
  }

  Color _countdownColour() {
    return _secondsLeft < 0 ? AppColours.overdueRed : _accentColour();
  }

  @override
  Widget build(BuildContext context) {
    final canComplete = widget.isMissed || (!widget.isCompleted && !_isFuture);
    final canUndo = widget.isCompleted && !widget.isMissed;

    return Container(
      decoration: const BoxDecoration(
         color: Colors.white,
        borderRadius: BorderRadius.all(Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Color(0xFFD4C9BC),
            blurRadius: 4,
            offset: Offset(4, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Dismissible(
          key: Key('${widget.isCompleted ? "done" : "active"}_${widget.task.id}'),
          direction: (canComplete || canUndo)
              ? DismissDirection.horizontal
              : DismissDirection.endToStart,
          onDismissed: (direction) {
            if (direction == DismissDirection.startToEnd) {
              canUndo ? widget.onUndo?.call() : widget.onComplete();
            } else {
              widget.onDelete();
            }
          },
          background: (canComplete || canUndo)
              ? _buildSwipeBackground(
                  color: widget.isCompleted ? const Color(0xFFB8AD96) : AppColours.green,
                  icon: widget.isCompleted ? Icons.undo : Icons.check,
                  alignment: Alignment.centerLeft,
                )
              : const SizedBox.shrink(),
          secondaryBackground: _buildSwipeBackground(
            color: AppColours.red,
            icon: Icons.delete_outline,
            alignment: Alignment.centerRight,
          ),
          child: (widget.isCompleted || widget.isMissed)
              ? Opacity(opacity: 0.5, child: _buildCard())
              : _buildCard(),
        ),
      ),
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
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.all(Radius.circular(28)),
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
        const SizedBox(height: 1),
        if (widget.task.location != null)
          _buildMetaRow(Icons.location_on_outlined, widget.task.location!.label),
        if (widget.task.location != null) const SizedBox(height: 2),
        if (widget.task.people.isNotEmpty)
          _buildMetaRow(Icons.person_outline, widget.task.people.map((p) => p.name).join(', ')),
        if (widget.task.people.isNotEmpty) const SizedBox(height: 4),
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
          _secondsLeft < 0
              ? _buildOverdueIcon(size: 14)
              : Icon(Icons.timer_outlined, color: _countdownColour(), size: 14),
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

  Widget _buildOverdueIcon({double size = 14}) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SvgPicture.asset(
            'assets/icons/danger.svg',
            width: size,
            height: size,
            colorFilter: const ColorFilter.mode(AppColours.overdueRed, BlendMode.srcIn),
          ),
          Text(
            '!',
            style: TextStyle(
              color: Colors.white,
              fontSize: size * 0.6,
              fontWeight: FontWeight.bold,
              height: 1,
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
          widget.task.recurrence!.recurrenceType == 'daily'
              ? _buildDailyPill()
              : _buildSvgActionButton('assets/icons/repeate-one.svg'),
          const SizedBox(width: 5),
        ],
        ..._buildAlertButtons(),
      ],
    );
  }

  List<Widget> _buildAlertButtons() {
    final alertButtons = <Widget>[];

    final sortedAlerts = [...widget.task.alerts]..sort((a, b) {
        final ap = _parseTimeParts(a.alertTime);
        final bp = _parseTimeParts(b.alertTime);
        final aMinutes = int.parse(ap[0]) * 60 + int.parse(ap[1]);
        final bMinutes = int.parse(bp[0]) * 60 + int.parse(bp[1]);
        return aMinutes.compareTo(bMinutes);
      });

    for (final alert in sortedAlerts) {
      final hasAlertPassed = _hasAlertTimePassed(alert.alertTime);

      if (alert.alertType == 'imessage') {
        alertButtons.add(
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: _backgroundForAlertType(alert.alertType, hasAlertPassed),
              borderRadius: BorderRadius.circular(9.5),
              boxShadow: const [
                 BoxShadow(color: Color(0x26000000), blurRadius: 4, offset: Offset(0, 2)),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(5),
              child: SvgPicture.asset(
                'assets/icons/test_message_alert.svg',
                fit: BoxFit.contain,
                colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
              ),
            ),
          ),
        );
      } else {
        alertButtons.add(
          _buildActionButton(
            _iconForAlertType(alert.alertType),
            _backgroundForAlertType(alert.alertType, hasAlertPassed),
            _iconColourForAlertType(alert.alertType, hasAlertPassed),
          ),
        );
      }
      alertButtons.add(const SizedBox(width: 5));
    }

    return alertButtons;
  }

  bool _hasAlertTimePassed(String alertTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final sel = DateTime(
        widget.selectedDate.year, widget.selectedDate.month, widget.selectedDate.day);
    if (sel.isBefore(today)) return true;
    if (!_isToday) return false;
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

  Widget _buildDailyPill() {
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
      child: Center(
        child: Text('∞', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _accentColour())),
      ),
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
              _secondsLeft < 0
                  ? _buildOverdueIcon(size: 12)
                  : Icon(Icons.timer_outlined, color: _countdownColour(), size: 12),
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
      GestureDetector(
        onTap: () => _openCopyModal(),
        child: SvgPicture.asset('assets/icons/copy.svg', width: 22, height: 22),
      ),
      GestureDetector(
        onTap: () => _openEditModal(),
        child: SvgPicture.asset('assets/icons/Button OnClick- edit.svg', width: 17, height: 17),
      ),
    ],
  );
}

void _openCopyModal() {
  showDialog(
    context: context,
    builder: (_) => CopyTaskModal(
      task: widget.task,
      onSaved: () { widget.onRefresh?.call(); },
    ),
  );
}
}