import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../models/task_model.dart';

class EditTaskModal extends StatefulWidget {
  final TaskModel task;
  final VoidCallback onSaved;

  const EditTaskModal({
    super.key,
    required this.task,
    required this.onSaved,
  });

  @override
  State<EditTaskModal> createState() => _EditTaskModalState();
}

class _EditTaskModalState extends State<EditTaskModal> {
  static const _orange = Color(0xFFFF4A00);
  static const _purple = Color(0xFF7B61FF);
  static const _slate = Color(0xFF4D5B71);
  static const _lightSlate = Color(0xFF8D9EB7);

  late TextEditingController _titleController;
  late TextEditingController _locationController;
  late bool _isTimeSensitive;

  // reminder
  TimeOfDay? _reminderTime;
  String _reminderAlertType = 'notification';

  // due time
  TimeOfDay? _dueTime;
  String _dueAlertType = 'notification';

  // recurrence
  final Set<int> _weekdays = {};
  bool _isDaily = false;
  int? _dayOfMonth;
  bool _useCalendar = false;

  final List<String> _alertTypes = ['notification', 'phone_alarm', 'imessage'];

  Color get _accent => _isTimeSensitive ? _orange : _purple;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task.title);
    _locationController = TextEditingController(
      text: widget.task.location?.label ?? '',
    );
    _isTimeSensitive = widget.task.isTimeSensitive;

    // pre-fill reminder
    if (widget.task.alerts.isNotEmpty) {
      final parts = widget.task.alerts.first.alertTime.split(':');
      _reminderTime = TimeOfDay(
        hour: int.tryParse(parts[0]) ?? 0,
        minute: int.tryParse(parts[1]) ?? 0,
      );
      _reminderAlertType = widget.task.alerts.first.alertType;
    }

    // pre-fill due time
    if (widget.task.dueTime != null) {
      final raw = widget.task.dueTime!;
      final timePart = raw.contains(' ') ? raw.split(' ').last : raw;
      final parts = timePart.split(':');
      _dueTime = TimeOfDay(
        hour: int.tryParse(parts[0]) ?? 0,
        minute: int.tryParse(parts[1]) ?? 0,
      );
    }

    // pre-fill recurrence
  if (widget.task.recurrence != null) {
  final r = widget.task.recurrence!;
  if (r.recurrenceType == 'daily') {
    _isDaily = true;
  } else if (r.recurrenceType == 'weekly' && r.weekdays != null) {
    _weekdays.addAll(
      r.weekdays!.split(',').map((d) => int.parse(d.trim())),
    );
  } else if (r.recurrenceType == 'monthly' && r.dayOfMonth != null) {
    _useCalendar = true;
    _dayOfMonth = r.dayOfMonth;
  }
}
  }

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  String _fmtTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  void _cycleAlertType(String current, ValueChanged<String> onChanged) {
    final idx = _alertTypes.indexOf(current);
    final next = _alertTypes[(idx + 1) % _alertTypes.length];
    setState(() => onChanged(next));
  }

  IconData _iconForAlertType(String type) {
    switch (type) {
      case 'notification': return Icons.notifications_outlined;
      case 'phone_alarm':  return Icons.alarm;
      case 'imessage':     return Icons.message_outlined;
      default:             return Icons.notifications_outlined;
    }
  }

  String _labelForAlertType(String type) {
    switch (type) {
      case 'notification': return 'notification';
      case 'phone_alarm':  return 'alarm';
      case 'imessage':     return 'imessage';
      default:             return 'notification';
    }
  }

  Future<void> _pickTime({
    required TimeOfDay initial,
    required ValueChanged<TimeOfDay> onPicked,
  }) async {
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked != null) onPicked(picked);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 40),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: const [
            BoxShadow(
              color: Color(0xFFD4C9BC),
              blurRadius: 16,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 20),
                    _buildTitleField(),
                    const SizedBox(height: 20),
                    _buildLocationRow(),
                    const SizedBox(height: 20),
                    _buildTimeSensitiveRow(),
                    const SizedBox(height: 20),
                    _buildReminderSection(),
                    const SizedBox(height: 20),
                    _buildDueTimeSection(),
                    const SizedBox(height: 24),
                    _buildRecurrenceSection(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          'save edits?',
          style: TextStyle(
            fontFamily: 'Anonymous Pro',
            fontSize: 13,
            color: Colors.grey.shade400,
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () {
            Navigator.of(context).pop();
            widget.onSaved();
          },
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.rectangle,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF333333), width: 1.5),
            ),
            child: const Center(
              child: Icon(Icons.check, size: 18, color: Color(0xFF333333)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTitleField() {
    return TextField(
      controller: _titleController,
      style: const TextStyle(
        fontFamily: 'Anonymous Pro',
        fontSize: 26,
        fontWeight: FontWeight.bold,
        color: Color(0xFF111111),
      ),
      maxLines: null,
      decoration: const InputDecoration(
        border: InputBorder.none,
        isDense: true,
        contentPadding: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildLocationRow() {
    return Row(
      children: [
        Icon(Icons.location_on_outlined, color: _lightSlate, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: TextField(
            controller: _locationController,
            style: const TextStyle(
              fontFamily: 'Anonymous Pro',
              fontSize: 15,
              color: _lightSlate,
            ),
            decoration: const InputDecoration(
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
              hintText: 'location',
              hintStyle: TextStyle(
                fontFamily: 'Anonymous Pro',
                fontSize: 15,
                color: _lightSlate,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeSensitiveRow() {
    return GestureDetector(
      onTap: () => setState(() => _isTimeSensitive = !_isTimeSensitive),
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: _accent,
              borderRadius: BorderRadius.circular(5),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'time-sensitive : ${_isTimeSensitive ? 'yes' : 'no'}',
            style: const TextStyle(
              fontFamily: 'Anonymous Pro',
              fontSize: 15,
              color: _lightSlate,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReminderSection() {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: _isTimeSensitive ? 1.0 : 0.35,
      child: IgnorePointer(
        ignoring: !_isTimeSensitive,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.watch_later_outlined, color: _lightSlate, size: 20),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: () => _pickTime(
                    initial: _reminderTime ?? const TimeOfDay(hour: 9, minute: 0),
                    onPicked: (t) => setState(() => _reminderTime = t),
                  ),
                  child: Text(
                    'reminder time : ${_reminderTime != null ? _fmtTime(_reminderTime!) : 'n/a'}',
                    style: const TextStyle(
                      fontFamily: 'Anonymous Pro',
                      fontSize: 15,
                      color: _lightSlate,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.only(left: 30),
              child: Row(
                children: [
                  Text(
                    'alert type : ',
                    style: const TextStyle(
                      fontFamily: 'Anonymous Pro',
                      fontSize: 15,
                      color: _lightSlate,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildAlertTypePicker(
                    current: _reminderAlertType,
                    onCycle: (t) => _reminderAlertType = t,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDueTimeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.timer_outlined, color: _lightSlate, size: 20),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: () => _pickTime(
                initial: _dueTime ?? const TimeOfDay(hour: 12, minute: 0),
                onPicked: (t) => setState(() => _dueTime = t),
              ),
              child: Text(
                '${_isTimeSensitive ? 'due by time' : 'due time'} : ${_dueTime != null ? _fmtTime(_dueTime!) : 'n/a'}',
                style: const TextStyle(
                  fontFamily: 'Anonymous Pro',
                  fontSize: 15,
                  color: _lightSlate,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: _isTimeSensitive ? 1.0 : 0.35,
          child: IgnorePointer(
            ignoring: !_isTimeSensitive,
            child: Padding(
              padding: const EdgeInsets.only(left: 30),
              child: Row(
                children: [
                  const Text(
                    'alert type : ',
                    style: TextStyle(
                      fontFamily: 'Anonymous Pro',
                      fontSize: 15,
                      color: _lightSlate,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildAlertTypePicker(
                    current: _dueAlertType,
                    onCycle: (t) => _dueAlertType = t,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAlertTypePicker({
    required String current,
    required ValueChanged<String> onCycle,
  }) {
    return GestureDetector(
      onTap: () => _cycleAlertType(current, onCycle),
      child: Column(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _accent,
              shape: BoxShape.circle,
            ),
            child: Icon(_iconForAlertType(current), color: Colors.white, size: 18),
          ),
        
          Icon(Icons.keyboard_arrow_down, size: 14, color: Colors.grey.shade400),
        ],
      ),
    );
  }

  Widget _buildRecurrenceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _buildRecurrenceToggle(),
            const SizedBox(width: 8),
            _buildRecurrenceCount(),
          ],
        ),
        const SizedBox(height: 16),
        _buildWeekdayPicker(),
        const SizedBox(height: 16),
        _buildCalendarRow(),
      ],
    );
  }

  Widget _buildRecurrenceToggle() {
    return GestureDetector(
      onTap: () => setState(() {
        _isDaily = !_isDaily;
        if (_isDaily) {
          _weekdays.clear();
          _useCalendar = false;
          _dayOfMonth = null;
        }
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: (_isDaily || _weekdays.isNotEmpty || _useCalendar) ? _accent : const Color(0xFFE8E8E8),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(
          Icons.repeat,
          color: (_isDaily || _weekdays.isNotEmpty || _useCalendar) ? Colors.white : Colors.grey.shade400,
          size: 22,
        ),
      ),
    );
  }

  Widget _buildRecurrenceCount() {
    final count = _isDaily ? '∞' : _weekdays.isNotEmpty ? '${_weekdays.length}' : _dayOfMonth?.toString() ?? '1';
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: const Color(0xFFE8E8E8),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Center(
        child: Text(
          count,
          style: TextStyle(
            fontFamily: 'Anonymous Pro',
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade500,
          ),
        ),
      ),
    );
  }

  Widget _buildWeekdayPicker() {
  const labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
  return Row(
    children: List.generate(7, (i) {
      final day = i + 1;
      final selected = _weekdays.contains(day);
      return Padding(
        padding: const EdgeInsets.only(right: 6),
        child: GestureDetector(
          onTap: () => setState(() {
            _isDaily = false;
            selected ? _weekdays.remove(day) : _weekdays.add(day);
          }),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: selected ? _accent : const Color(0xFFF0F0F0),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                labels[i],
                style: TextStyle(
                  fontFamily: 'Anonymous Pro',
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: selected ? Colors.white : Colors.grey.shade500,
                ),
              ),
            ),
          ),
        ),
      );
    }),
  );
}

  Widget _buildCalendarRow() {
    return Row(
      children: [
        GestureDetector(
          onTap: () => setState(() {
            _useCalendar = !_useCalendar;
            if (_useCalendar) {
              _isDaily = false;
              _weekdays.clear();
            }
          }),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _useCalendar ? _accent : const Color(0xFFE8E8E8),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.calendar_month_outlined,
              color: _useCalendar ? Colors.white : Colors.grey.shade400,
              size: 22,
            ),
          ),
        ),
        if (_useCalendar && _dayOfMonth != null) ...[
          const SizedBox(width: 12),
          Text(
            'next repeat : ${_dayOfMonth}/12/2026',
            style: const TextStyle(
              fontFamily: 'Anonymous Pro',
              fontSize: 13,
              color: _lightSlate,
            ),
          ),
        ],
      ],
    );
  }
}