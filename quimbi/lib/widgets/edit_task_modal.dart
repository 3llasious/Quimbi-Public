import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../models/task_model.dart';
import '../models/modal_alert.dart';
import '../repositories/task_repository.dart';
import '../utils/date_time_utils.dart';
import 'day_of_month_dialog.dart';
import 'time_roller_sheet.dart';

class EditTaskModal extends StatefulWidget {
  final TaskModel task;
  final VoidCallback onSaved;
  final DateTime selectedDate;

  const EditTaskModal({
    super.key,
    required this.task,
    required this.onSaved,
    required this.selectedDate,
  });

  @override
  State<EditTaskModal> createState() => _EditTaskModalState();
}

class _EditTaskModalState extends State<EditTaskModal> {
  static const _orange = Color(0xFFFF4A00);
  static const _purple = Color(0xFF7B61FF);
  static const _lightSlate = Color(0xFF8D9EB7);

  late TextEditingController _titleController;
  late TextEditingController _locationController;
  late TextEditingController _personController;
  late bool _isTimeSensitive;

  // alerts
  final List<ModalAlert> _alerts = [];

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
    _locationController = TextEditingController(text: widget.task.location?.label ?? '');
    _personController = TextEditingController(text: widget.task.people.map((p) => p.name).join(', '));
    _isTimeSensitive = widget.task.isTimeSensitive;

    if (widget.task.dueTime != null) {
      final parsed = parseTimeParts(widget.task.dueTime!);
      if (parsed != null) _dueTime = TimeOfDay(hour: parsed.hour, minute: parsed.minute);
    }

    bool dueAlertFound = false;
    for (final alert in widget.task.alerts) {
      final parsed = parseTimeParts(alert.alertTime);
      if (parsed == null) continue;
      final time = TimeOfDay(hour: parsed.hour, minute: parsed.minute);
      if (_isTimeSensitive && _dueTime != null && !dueAlertFound &&
          time.hour == _dueTime!.hour && time.minute == _dueTime!.minute) {
        _dueAlertType = alert.alertType;
        dueAlertFound = true;
      } else {
        _alerts.add(ModalAlert(time: time, type: alert.alertType));
      }
    }

    if (widget.task.recurrence != null) {
      final recurrence = widget.task.recurrence!;
      if (recurrence.recurrenceType == 'daily') {
        _isDaily = true;
      } else if (recurrence.recurrenceType == 'weekly' && recurrence.weekdays != null) {
        _weekdays.addAll(
          recurrence.weekdays!
              .split(',')
              .map((entry) => int.tryParse(entry.trim()))
              .whereType<int>(),
        );
      } else if (recurrence.recurrenceType == 'monthly' && recurrence.dayOfMonth != null) {
        _useCalendar = true;
        _dayOfMonth = recurrence.dayOfMonth;
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _personController.dispose();
    super.dispose();
  }


  void _cycleAlertType(String current, ValueChanged<String> onChanged) {
    final idx = _alertTypes.indexOf(current);
    final next = _alertTypes[(idx + 1) % _alertTypes.length];
    setState(() => onChanged(next));
  }

  Widget _iconForAlertType(String type) {
    if (type == 'imessage') {
      return SizedBox(
        width: 22,
        height: 16,
        child: SvgPicture.asset(
          'assets/icons/test_message_alert.svg',
          fit: BoxFit.contain,
          colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
        ),
      );
    }
    return Icon(
      type == 'phone_alarm' ? Icons.alarm : Icons.notifications_outlined,
      color: Colors.white,
      size: 18,
    );
  }

  Future<void> _pickTime({
    required TimeOfDay initial,
    required ValueChanged<TimeOfDay> onPicked,
  }) => pickTime(context: context, initial: initial, accent: _accent, onPicked: onPicked);

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
                    const SizedBox(height: 12),
                    _buildTitleField(),
                    const SizedBox(height: 12),
                    _buildLocationRow(),
                    const SizedBox(height: 12),
                    _buildPeopleRow(),
                    const SizedBox(height: 12),
                    _buildReminderSection(),
                    const SizedBox(height: 12),
                    _buildDueTimeSection(),
                    const SizedBox(height: 12),
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
      children: [
        GestureDetector(
          onTap: () => setState(() => _isTimeSensitive = !_isTimeSensitive),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: _accent,
              borderRadius: BorderRadius.circular(5),
            ),
          ),
        ),
        const Spacer(),
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
          onTap: () async {
            final navigator = Navigator.of(context);
            await _save();
            navigator.pop();
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
            decoration: InputDecoration(
              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: _accent, width: 1)),
              focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: _accent, width: 1.5)),
              isDense: true,
              contentPadding: const EdgeInsets.only(bottom: 4),
              hintText: 'location',
              hintStyle: const TextStyle(fontFamily: 'Anonymous Pro', fontSize: 15, color: _lightSlate),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReminderSection() {
    final nextHour = TimeOfDay(hour: (TimeOfDay.now().hour + 1) % 24, minute: 0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Icon(Icons.watch_later_outlined, color: _lightSlate, size: 20),
          const SizedBox(width: 10),
          const Text('reminders', style: TextStyle(fontFamily: 'Anonymous Pro', fontSize: 15, color: _lightSlate)),
        ]),
        const SizedBox(height: 6),
        ..._alerts.asMap().entries.map((e) {
          final i = e.key; final a = e.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(children: [
              GestureDetector(
                onTap: () => _pickTime(initial: a.time, onPicked: (t) => setState(() => a.time = t)),
                child: Text(formatTimeOfDay(a.time), style: const TextStyle(fontFamily: 'Anonymous Pro', fontSize: 15, color: _lightSlate)),
              ),
              const Spacer(),
              _buildAlertTypePicker(current: a.type, onCycle: (t) => a.type = t),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () => setState(() => _alerts.removeAt(i)),
                child: Icon(Icons.close, size: 16, color: Colors.grey.shade400),
              ),
            ]),
          );
        }),
        if (_alerts.length < 3)
          GestureDetector(
            onTap: () => setState(() => _alerts.add(ModalAlert(time: nextHour))),
            child: Container(
              width: 20, height: 20,
              decoration: const BoxDecoration(color: Color(0xFFB0B8C8), shape: BoxShape.circle),
              child: const Icon(Icons.add, color: Colors.white, size: 12),
            ),
          ),
      ],
    );
  }

  Widget _buildDueTimeSection() {
    return Row(
      children: [
        Icon(Icons.timer_outlined, color: _lightSlate, size: 20),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: () => _pickTime(
            initial: _dueTime ?? const TimeOfDay(hour: 12, minute: 0),
            onPicked: (t) => setState(() => _dueTime = t),
          ),
          child: Text(
            '${_isTimeSensitive ? 'due by time' : 'due time'} : ${_dueTime != null ? formatTimeOfDay(_dueTime!) : 'n/a'}',
            style: const TextStyle(fontFamily: 'Anonymous Pro', fontSize: 15, color: _lightSlate),
          ),
        ),
        const Spacer(),
        AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: _isTimeSensitive ? 1.0 : 0.35,
          child: IgnorePointer(
            ignoring: !_isTimeSensitive,
            child: _buildAlertTypePicker(current: _dueAlertType, onCycle: (t) => _dueAlertType = t),
          ),
        ),
        const SizedBox(width: 26),
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
            child: Center(child: _iconForAlertType(current)),
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
            // repeat — lights up for weekly or monthly
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: (_weekdays.isNotEmpty || _useCalendar) ? _accent : const Color(0xFFF0F0F0),
                shape: BoxShape.circle,
              ),
              child: Center(child: Icon(Icons.repeat, size: 18,
                color: (_weekdays.isNotEmpty || _useCalendar) ? Colors.white : Colors.grey.shade500)),
            ),
            const SizedBox(width: 8),
            // 1 — once
            GestureDetector(
              onTap: () => setState(() { _isDaily = false; _weekdays.clear(); _useCalendar = false; _dayOfMonth = null; }),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: (!_isDaily && _weekdays.isEmpty && !_useCalendar) ? _accent : const Color(0xFFF0F0F0),
                  shape: BoxShape.circle,
                ),
                child: Center(child: Text('1', style: TextStyle(
                  fontFamily: 'Anonymous Pro', fontSize: 15, fontWeight: FontWeight.bold,
                  color: (!_isDaily && _weekdays.isEmpty && !_useCalendar) ? Colors.white : Colors.grey.shade500,
                ))),
              ),
            ),
            const SizedBox(width: 8),
            // ∞ — daily
            GestureDetector(
              onTap: () => setState(() { _isDaily = true; _weekdays.clear(); _useCalendar = false; _dayOfMonth = null; }),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: _isDaily ? _accent : const Color(0xFFF0F0F0),
                  shape: BoxShape.circle,
                ),
                child: Center(child: Text('∞', style: TextStyle(
                  fontFamily: 'Anonymous Pro', fontSize: 18, fontWeight: FontWeight.bold,
                  color: _isDaily ? Colors.white : Colors.grey.shade500,
                ))),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildWeekdayPicker(),
        const SizedBox(height: 16),
        _buildCalendarRow(),
      ],
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

  Future<void> _save() async {
    String? recurrenceType;
    List<int>? weekdays;
    int? dayOfMonth;
    if (_isDaily) {
      recurrenceType = 'daily';
    } else if (_useCalendar && _dayOfMonth != null) {
      recurrenceType = 'monthly';
      dayOfMonth = _dayOfMonth;
    } else if (_weekdays.isNotEmpty) {
      recurrenceType = 'weekly';
      weekdays = _weekdays.toList()..sort();
    }

    final alerts = _alerts.map((alert) => {'time': formatTimeOfDay(alert.time), 'type': alert.type}).toList();
    if (_isTimeSensitive && _dueTime != null) {
      alerts.insert(0, {'time': formatTimeOfDay(_dueTime!), 'type': _dueAlertType});
    }

    String? dueTimeStr;
    if (_dueTime != null) {
      final existing = widget.task.dueTime;
      final wasRecurring = widget.task.recurrence != null;
      // Recurring → once: anchor to selectedDate (the stored date is the creation
      // date of the recurring task, which would put the task on the wrong day).
      // All other cases: preserve the existing date so we don't silently move
      // a non-recurring task just because the user is viewing a different date.
      final datePart = (wasRecurring && recurrenceType == null)
          ? formatDate(widget.selectedDate)
          : (existing != null && existing.contains(' '))
              ? existing.split(' ').first
              : formatDate(widget.selectedDate);
      dueTimeStr = '$datePart ${formatTimeOfDay(_dueTime!)}:00';
    } else if (recurrenceType == null) {
      dueTimeStr = formatDate(widget.selectedDate);
    }

    await TaskRepository().updateTask(
      taskId: widget.task.id,
      title: _titleController.text.trim(),
      isTimeSensitive: _isTimeSensitive,
      dueTime: dueTimeStr,
      recurrenceType: recurrenceType,
      weekdays: weekdays,
      dayOfMonth: dayOfMonth,
      alerts: alerts,
      existingLocationId: widget.task.locationId,
      locationLabel: _locationController.text,
      people: _personController.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList(),
    );
  }

  Future<void> _toggleCalendar() async {
    if (_useCalendar) {
      setState(() { _useCalendar = false; _dayOfMonth = null; });
    } else {
      final day = await showDialog<int>(
        context: context,
        builder: (_) => DayOfMonthDialog(accent: _accent),
      );
      if (day != null) {
        setState(() { _useCalendar = true; _dayOfMonth = day; _weekdays.clear(); _isDaily = false; });
      }
    }
  }

  Widget _buildCalendarRow() {
    return Row(
      children: [
        GestureDetector(
          onTap: _toggleCalendar,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: _useCalendar ? _accent.withValues(alpha: 0.15) : _accent.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _useCalendar ? _accent : Colors.transparent, width: 1.5),
            ),
            child: Center(child: Icon(Icons.calendar_today_outlined, color: _accent, size: 18)),
          ),
        ),
        if (_useCalendar && _dayOfMonth != null) ...[
          const SizedBox(width: 12),
          Text(
            'recurs every ${ordinal(_dayOfMonth!)}',
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

  Widget _buildPeopleRow() {
    return Row(
      children: [
        Icon(Icons.person_outline, color: _lightSlate, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: TextField(
            controller: _personController,
            style: const TextStyle(fontFamily: 'Anonymous Pro', fontSize: 15, color: _lightSlate),
            decoration: InputDecoration(
              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: _accent, width: 1)),
              focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: _accent, width: 1.5)),
              isDense: true,
              contentPadding: const EdgeInsets.only(bottom: 4),
              hintText: 'people',
              hintStyle: const TextStyle(fontFamily: 'Anonymous Pro', fontSize: 15, color: _lightSlate),
            ),
          ),
        ),
      ],
    );
  }

}