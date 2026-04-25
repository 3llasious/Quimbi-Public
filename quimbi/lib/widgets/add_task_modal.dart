import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../repositories/task_repository.dart';
import '../utils/date_time_utils.dart';
import 'day_of_month_dialog.dart';
import 'time_roller_sheet.dart';

class _Reminder {
  TimeOfDay time;
  String type = 'notification';
  _Reminder({required this.time});
}

class _LinkEntry {
  String label;
  String url;
  _LinkEntry({this.label = '', this.url = ''});
}

class AddTaskModal extends StatefulWidget {
  final DateTime selectedDate;
  final VoidCallback onSaved;

  const AddTaskModal({
    super.key,
    required this.selectedDate,
    required this.onSaved,
  });

  @override
  State<AddTaskModal> createState() => _AddTaskModalState();
}

class _AddTaskModalState extends State<AddTaskModal> {
  static const _orange = Color(0xFFFF4A00);
  static const _purple = Color(0xFF7B61FF);

  int _step = 1;
  bool? _isSensitive;

  final _titleController = TextEditingController();

  // Page 2
  final Set<int> _weekdays = {};
  bool _useCalendar = false;
  int? _dayOfMonth;
  bool _isDaily = false;

  // Page 3a
  TimeOfDay? _dueTime;
  String _dueAlertType = 'notification';
  final List<_Reminder> _reminders = [];

  // Page 3b
  bool _isAllDay = true;
  final List<_Reminder> _suggestions = [];

  // Page 4
  final List<_LinkEntry> _links = [];
  final List<String> _subtasks = [];
  final _linkLabelController = TextEditingController();
  final _linkUrlController = TextEditingController();
  final _subtaskController = TextEditingController();

  // Page 5
  final List<String> _people = [];
  final _locationController = TextEditingController();
  final _personController = TextEditingController();

  Color get _accent => _isSensitive == true ? _orange : _purple;

  TimeOfDay get _nextHour {
    final nextHour = DateTime.now().hour + 1;
    return TimeOfDay(hour: nextHour.clamp(0, 23), minute: 0);
  }

  String get _headerTitle {
    final selectedDay = widget.selectedDate;
    final now = DateTime.now();
    if (selectedDay.year == now.year && selectedDay.month == now.month && selectedDay.day == now.day) {
      return 'add a task for today';
    }
    const months = ['jan','feb','mar','apr','may','jun','jul','aug','sep','oct','nov','dec'];
    return 'add a task for ${selectedDay.day} ${months[selectedDay.month - 1]}';
  }

  bool get _canAdvance =>
      _step != 1 || (_titleController.text.trim().isNotEmpty && _isSensitive != null);

  @override
  void initState() {
    super.initState();
    _titleController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _titleController.dispose();
    _linkLabelController.dispose();
    _linkUrlController.dispose();
    _subtaskController.dispose();
    _locationController.dispose();
    _personController.dispose();
    super.dispose();
  }

  void _goNext() {
    if (!_canAdvance) return;
    if (_step < 5) {
      setState(() => _step++);
    } else {
      _save();
    }
  }

  void _goBack() {
    if (_step == 1) {
      Navigator.of(context).pop();
    } else {
      setState(() => _step--);
    }
  }


  Future<void> _save() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;

    final isSensitive = _isSensitive ?? false;
    final selectedDay = widget.selectedDate;

    String? dueTimeStr;
    if (isSensitive && _dueTime != null) {
      dueTimeStr = formatDateTime(selectedDay, _dueTime!);
    } else if (!isSensitive && !_isAllDay && _suggestions.isNotEmpty) {
      dueTimeStr = formatDateTime(selectedDay, _suggestions.first.time);
    } else {
      dueTimeStr = '${formatDate(selectedDay)} 00:00:00';
    }

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

    final alertSource = isSensitive ? _reminders : (_isAllDay ? <_Reminder>[] : _suggestions);
    final alerts = alertSource
        .map((reminder) => {'time': '${formatTimeOfDay(reminder.time)}:00', 'type': reminder.type})
        .toList();
    if (isSensitive && _dueTime != null) {
      alerts.insert(0, {'time': '${formatTimeOfDay(_dueTime!)}:00', 'type': _dueAlertType});
    }

    final links = _links
        .where((l) => l.label.isNotEmpty && l.url.isNotEmpty)
        .map((l) => {'label': l.label, 'url': l.url})
        .toList();

    final locationLabel = _locationController.text.trim();

    await TaskRepository().addFullTask(
      title: title,
      isTimeSensitive: isSensitive,
      dueTime: dueTimeStr,
      recurrenceType: recurrenceType,
      weekdays: weekdays,
      dayOfMonth: dayOfMonth,
      startsOn: recurrenceType != null ? formatDate(selectedDay) : null,
      alerts: alerts,
      links: links,
      subtasks: _subtasks,
      locationLabel: locationLabel.isEmpty ? null : locationLabel,
      people: _people,
    );

    if (mounted) {
      Navigator.of(context).pop();
      widget.onSaved();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 4),
              child: Container(
                width: 36, height: 4,
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 36),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 24),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      transitionBuilder: (child, anim) => FadeTransition(
                        opacity: anim,
                        child: SlideTransition(
                          position: Tween<Offset>(begin: const Offset(0.04, 0), end: Offset.zero).animate(anim),
                          child: child,
                        ),
                      ),
                      child: _buildCurrentPage(),
                    ),
                    const SizedBox(height: 24),
                    _buildFooter(),
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            _headerTitle,
            style: const TextStyle(
              fontFamily: 'Anonymous Pro',
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111111),
              height: 1.2,
            ),
          ),
        ),
        const SizedBox(width: 12),
        GestureDetector(
          onTap: _goBack,
          child: Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF333333), width: 1.5),
            ),
            child: const Center(child: Text('✕', style: TextStyle(fontSize: 13, color: Color(0xFF333333)))),
          ),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return Row(
      children: [
        if (_step >= 4)
          GestureDetector(
            onTap: _save,
            child: Text(
              'skip & save?',
              style: TextStyle(fontFamily: 'Anonymous Pro', fontSize: 12, color: Colors.grey.shade500),
            ),
          ),
        const Spacer(),
        GestureDetector(
          onTap: _canAdvance ? _goNext : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 36, height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: _canAdvance ? const Color(0xFF333333) : Colors.grey.shade300,
                width: 1.5,
              ),
            ),
            child: Center(
              child: Icon(Icons.arrow_forward, size: 16,
                  color: _canAdvance ? const Color(0xFF333333) : Colors.grey.shade300),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCurrentPage() {
    switch (_step) {
      case 1: return _buildPage1();
      case 2: return _buildPage2();
      case 3: return _isSensitive == true ? _buildPage3a() : _buildPage3b();
      case 4: return _buildPage4();
      case 5: return _buildPage5();
      default: return const SizedBox.shrink();
    }
  }

  // ── Page 1 ──────────────────────────────────────────────────────────────────

  Widget _buildPage1() {
    return Column(
      key: const ValueKey(1),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _titleController,
          autofocus: true,
          style: const TextStyle(fontFamily: 'Anonymous Pro', fontSize: 18, color: Color(0xFF111111)),
          decoration: InputDecoration(
            hintText: 'Type a short description here',
            hintStyle: TextStyle(fontFamily: 'Anonymous Pro', fontSize: 18, color: Colors.grey.shade300),
            enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFCCCCCC), width: 1.5)),
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: _accent, width: 1.5)),
            contentPadding: const EdgeInsets.only(bottom: 8),
          ),
        ),
        const SizedBox(height: 24),
        Row(children: [
          _typePill('Time sensitive', true),
          const SizedBox(width: 10),
          _typePill('Time independent', false),
        ]),
      ],
    );
  }

  Widget _typePill(String label, bool sensitive) {
    final active = _isSensitive == sensitive;
    final color = sensitive ? _orange : _purple;
    return GestureDetector(
      onTap: () => setState(() => _isSensitive = sensitive),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: active ? color : const Color(0xFFE8E8E8),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label, style: TextStyle(
          fontFamily: 'Anonymous Pro', fontSize: 13, fontWeight: FontWeight.bold,
          color: active ? Colors.white : Colors.grey.shade500,
        )),
      ),
    );
  }

  // ── Page 2 ──────────────────────────────────────────────────────────────────

  Widget _buildPage2() {
    return Column(
      key: const ValueKey(2),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _taskName(),
        const SizedBox(height: 16),
        Row(children: [
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
          // 1 — once (default)
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
        ]),
        const SizedBox(height: 12),
        Opacity(
          opacity: (_useCalendar || _isDaily) ? 0.3 : 1.0,
          child: IgnorePointer(ignoring: _useCalendar || _isDaily, child: _weekdayPicker()),
        ),
        const SizedBox(height: 12),
        Opacity(
          opacity: _isDaily ? 0.3 : 1.0,
          child: IgnorePointer(
            ignoring: _isDaily,
            child: Row(
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
                  Text('recurs every ${ordinal(_dayOfMonth!)}',
                    style: TextStyle(fontFamily: 'Anonymous Pro', fontSize: 13, color: Colors.grey.shade500)),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _weekdayPicker() {
    const labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return Row(
      children: List.generate(7, (i) {
        final day = i + 1;
        final sel = _weekdays.contains(day);
        return Padding(
          padding: const EdgeInsets.only(right: 6),
          child: GestureDetector(
            onTap: () => setState(() => sel ? _weekdays.remove(day) : _weekdays.add(day)),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: sel ? _accent : const Color(0xFFF0F0F0),
                shape: BoxShape.circle,
              ),
              child: Center(child: Text(labels[i], style: TextStyle(
                fontFamily: 'Anonymous Pro', fontSize: 12, fontWeight: FontWeight.bold,
                color: sel ? Colors.white : Colors.grey.shade500,
              ))),
            ),
          ),
        );
      }),
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
        setState(() { _useCalendar = true; _dayOfMonth = day; _weekdays.clear(); });
      }
    }
  }


  // ── Page 3a ─────────────────────────────────────────────────────────────────

  Widget _buildPage3a() {
    return Column(
      key: const ValueKey('3a'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _taskName(),
        const SizedBox(height: 16),
        _sectionLabel('due by', 'deadline time'),
        const SizedBox(height: 8),
        Row(children: [
          _timeChip(
            time: _dueTime,
            onTap: () => _pickTime(
              initial: _dueTime ?? _nextHour,
              onPicked: (t) => setState(() => _dueTime = t),
            ),
          ),
          const Spacer(),
          AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: _dueTime != null ? 1.0 : 0.3,
            child: IgnorePointer(
              ignoring: _dueTime == null,
              child: _dueAlertTypeSelector(),
            ),
          ),
        ]),
        const SizedBox(height: 20),
        _sectionLabel('remind me', 'prior to deadline (max 3)'),
        const SizedBox(height: 8),
        _reminderList(_reminders),
      ],
    );
  }

  // ── Page 3b ─────────────────────────────────────────────────────────────────

  Widget _buildPage3b() {
    return Column(
      key: const ValueKey('3b'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _taskName(),
        const SizedBox(height: 16),
        Row(children: [
          const Text('all-day?', style: TextStyle(fontFamily: 'Anonymous Pro', fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF333333))),
          const SizedBox(width: 16),
          Switch(value: _isAllDay, activeThumbColor: _accent, onChanged: (v) => setState(() => _isAllDay = v)),
        ]),
        const SizedBox(height: 16),
        AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: _isAllDay ? 0.35 : 1.0,
          child: IgnorePointer(
            ignoring: _isAllDay,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('suggest a nudge time', style: TextStyle(fontFamily: 'Anonymous Pro', fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF333333))),
              Text('(max 3 nudges)', style: TextStyle(fontFamily: 'Anonymous Pro', fontSize: 12, color: Colors.grey.shade400)),
              const SizedBox(height: 8),
              _reminderList(_suggestions),
            ]),
          ),
        ),
      ],
    );
  }

  // ── Page 4 ──────────────────────────────────────────────────────────────────

  Widget _buildPage4() {
    return Column(
      key: const ValueKey(4),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _taskName(),
        const SizedBox(height: 16),
        Row(children: [
          Icon(Icons.link, color: _accent, size: 16),
          const SizedBox(width: 6),
          const Text('links', style: TextStyle(fontFamily: 'Anonymous Pro', fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF333333))),
          const SizedBox(width: 6),
          Text('(optional)', style: TextStyle(fontFamily: 'Anonymous Pro', fontSize: 11, color: Colors.grey.shade400)),
        ]),
        const SizedBox(height: 8),
        ..._links.asMap().entries.map((e) => _linkRow(e.key, e.value)),
        Row(children: [
          Expanded(child: _compactInput(_linkLabelController, 'label')),
          const SizedBox(width: 6),
          Expanded(flex: 2, child: _compactInput(_linkUrlController, 'paste url here')),
          const SizedBox(width: 6),
          _addBtn(_addLink),
        ]),
        const SizedBox(height: 20),
        Row(children: [
          Icon(Icons.checklist_outlined, color: _accent, size: 16),
          const SizedBox(width: 6),
          const Text('subtasks', style: TextStyle(fontFamily: 'Anonymous Pro', fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF333333))),
          const SizedBox(width: 6),
          Text('(optional)', style: TextStyle(fontFamily: 'Anonymous Pro', fontSize: 11, color: Colors.grey.shade400)),
        ]),
        const SizedBox(height: 8),
        ..._subtasks.asMap().entries.map((e) => _subtaskRow(e.key, e.value)),
        Row(children: [
          Expanded(child: _compactInput(_subtaskController, 'add a subtask')),
          const SizedBox(width: 6),
          _addBtn(_addSubtask),
        ]),
      ],
    );
  }

  // ── Shared helpers ───────────────────────────────────────────────────────────

  Widget _taskName() => Text(
    _titleController.text,
    style: const TextStyle(fontFamily: 'Anonymous Pro', fontSize: 17, color: Color(0xFF111111)),
  );

  Widget _sectionLabel(String title, String sub) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title, style: const TextStyle(fontFamily: 'Anonymous Pro', fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF333333))),
      Text(sub, style: TextStyle(fontFamily: 'Anonymous Pro', fontSize: 10, color: Colors.grey.shade400)),
    ],
  );

  Widget _timeChip({TimeOfDay? time, required VoidCallback onTap}) {
    final label = time != null
        ? '${time.hour.toString().padLeft(2,'0')}:${time.minute.toString().padLeft(2,'0')}'
        : '--:--';
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFFAFAFA),
          border: Border.all(color: const Color(0xFFDDDDDD)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(label, style: const TextStyle(fontFamily: 'Anonymous Pro', fontSize: 13, color: Color(0xFF555555))),
          const SizedBox(width: 6),
          const Text('▾', style: TextStyle(fontSize: 10, color: Color(0xFFAAAAAA))),
        ]),
      ),
    );
  }

  Widget _reminderList(List<_Reminder> list) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...list.asMap().entries.map((e) {
          final i = e.key;
          final r = e.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(children: [
              _timeChip(
                time: r.time,
                onTap: () => _pickTime(initial: r.time, onPicked: (t) => setState(() => list[i].time = t)),
              ),
              const SizedBox(width: 6),
              if (list.length < 3)
                GestureDetector(
                  onTap: () => setState(() => list.add(_Reminder(time: _nextHour))),
                  child: _pill(_accent, const Icon(Icons.add, color: Colors.white, size: 13)),
                ),
              const SizedBox(width: 4),
              GestureDetector(
                onTap: () => setState(() => list.removeAt(i)),
                child: _pill(const Color(0xFFE8E8E8), const Icon(Icons.remove, color: Color(0xFF888888), size: 13)),
              ),
              const Spacer(),
              _alertTypeSelector(r),
            ]),
          );
        }),
        if (list.isEmpty)
          GestureDetector(
            onTap: () => setState(() => list.add(_Reminder(time: _nextHour))),
            child: _pill(_accent, const Icon(Icons.add, color: Colors.white, size: 13)),
          ),
      ],
    );
  }

  Widget _pill(Color bg, Widget child) => Container(
    width: 26, height: 26,
    decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
    child: Center(child: child),
  );

  Widget _dueAlertTypeSelector() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('alert type', style: TextStyle(fontFamily: 'Anonymous Pro', fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF333333))),
      const SizedBox(height: 3),
      Row(children: [
        _alertBtnForType('notification', _dueAlertType, icon: const Icon(Icons.notifications_outlined, color: Colors.white, size: 13),
            onTap: () => setState(() => _dueAlertType = 'notification')),
        const SizedBox(width: 4),
        _alertBtnForType('phone_alarm', _dueAlertType, icon: const Icon(Icons.alarm, color: Colors.white, size: 13),
            onTap: () => setState(() => _dueAlertType = 'phone_alarm')),
        const SizedBox(width: 4),
        _alertBtnForType('imessage', _dueAlertType, svg: 'assets/icons/test_message_alert.svg',
            onTap: () => setState(() => _dueAlertType = 'imessage')),
      ]),
    ]);
  }

  Widget _alertBtnForType(String type, String current, {Widget? icon, String? svg, required VoidCallback onTap}) {
    final active = current == type;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 26, height: 26,
        decoration: BoxDecoration(color: active ? _accent : const Color(0xFFCCCCCC), shape: BoxShape.circle),
        child: Center(
          child: svg != null
              ? Padding(padding: const EdgeInsets.all(5), child: SvgPicture.asset(svg, fit: BoxFit.contain, colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn)))
              : icon,
        ),
      ),
    );
  }

  Widget _alertTypeSelector(_Reminder r) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('alert type', style: TextStyle(fontFamily: 'Anonymous Pro', fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF333333))),
      const SizedBox(height: 3),
      Row(children: [
        _alertBtn(r, 'notification', icon: const Icon(Icons.notifications_outlined, color: Colors.white, size: 13)),
        const SizedBox(width: 4),
        _alertBtn(r, 'phone_alarm', icon: const Icon(Icons.alarm, color: Colors.white, size: 13)),
        const SizedBox(width: 4),
        _alertBtn(r, 'imessage', svg: 'assets/icons/test_message_alert.svg'),
      ]),
    ]);
  }

  Widget _alertBtn(_Reminder r, String type, {Widget? icon, String? svg}) {
    final active = r.type == type;
    return GestureDetector(
      onTap: () => setState(() => r.type = type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 26, height: 26,
        decoration: BoxDecoration(color: active ? _accent : const Color(0xFFCCCCCC), shape: BoxShape.circle),
        child: Center(
          child: svg != null
              ? Padding(padding: const EdgeInsets.all(5), child: SvgPicture.asset(svg, fit: BoxFit.contain, colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn)))
              : icon,
        ),
      ),
    );
  }

  Widget _compactInput(TextEditingController ctrl, String hint) => TextField(
    controller: ctrl,
    style: const TextStyle(fontFamily: 'Anonymous Pro', fontSize: 12, color: Color(0xFF555555)),
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(fontFamily: 'Anonymous Pro', fontSize: 12, color: Colors.grey.shade300),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFDDDDDD))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFDDDDDD))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: _accent)),
    ),
  );

  Widget _addBtn(VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 32, height: 32,
      decoration: const BoxDecoration(color: Color(0xFFB0B8C8), shape: BoxShape.circle),
      child: const Icon(Icons.add, color: Colors.white, size: 16),
    ),
  );

  Widget _linkRow(int i, _LinkEntry link) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Row(children: [
      Expanded(child: Text(link.label, style: const TextStyle(fontFamily: 'Anonymous Pro', fontSize: 12, color: Color(0xFF555555)), overflow: TextOverflow.ellipsis)),
      const SizedBox(width: 4),
      GestureDetector(onTap: () => setState(() => _links.removeAt(i)), child: const Icon(Icons.close, size: 13, color: Color(0xFFAAAAAA))),
    ]),
  );

  Widget _subtaskRow(int i, String title) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Row(children: [
      const Icon(Icons.circle, size: 6, color: Color(0xFFAAAAAA)),
      const SizedBox(width: 6),
      Expanded(child: Text(title, style: const TextStyle(fontFamily: 'Anonymous Pro', fontSize: 12, color: Color(0xFF555555)))),
      GestureDetector(onTap: () => setState(() => _subtasks.removeAt(i)), child: const Icon(Icons.close, size: 13, color: Color(0xFFAAAAAA))),
    ]),
  );

  void _addLink() {
    final label = _linkLabelController.text.trim();
    final url = _linkUrlController.text.trim();
    if (label.isEmpty || url.isEmpty) return;
    setState(() {
      _links.add(_LinkEntry(label: label, url: url));
      _linkLabelController.clear();
      _linkUrlController.clear();
    });
  }

  void _addSubtask() {
    final title = _subtaskController.text.trim();
    if (title.isEmpty) return;
    setState(() { _subtasks.add(title); _subtaskController.clear(); });
  }

  // ── Page 5 ──────────────────────────────────────────────────────────────────

  Widget _buildPage5() {
    return Column(
      key: const ValueKey(5),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _taskName(),
        const SizedBox(height: 16),
        Row(children: [
          Icon(Icons.location_on_outlined, color: _accent, size: 16),
          const SizedBox(width: 6),
          const Text('location', style: TextStyle(fontFamily: 'Anonymous Pro', fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF333333))),
          const SizedBox(width: 6),
          Text('(optional)', style: TextStyle(fontFamily: 'Anonymous Pro', fontSize: 11, color: Colors.grey.shade400)),
        ]),
        const SizedBox(height: 8),
        _compactInput(_locationController, 'e.g. home, office, gym'),
        const SizedBox(height: 20),
        Row(children: [
          Icon(Icons.person_outline, color: _accent, size: 16),
          const SizedBox(width: 6),
          const Text('people', style: TextStyle(fontFamily: 'Anonymous Pro', fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF333333))),
          const SizedBox(width: 6),
          Text('(optional)', style: TextStyle(fontFamily: 'Anonymous Pro', fontSize: 11, color: Colors.grey.shade400)),
        ]),
        const SizedBox(height: 8),
        ..._people.asMap().entries.map((e) => _personRow(e.key, e.value)),
        Row(children: [
          Expanded(child: _compactInput(_personController, 'add a person')),
          const SizedBox(width: 6),
          _addBtn(_addPerson),
        ]),
      ],
    );
  }

  Widget _personRow(int i, String name) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Row(children: [
      const Icon(Icons.person_outline, size: 12, color: Color(0xFFAAAAAA)),
      const SizedBox(width: 6),
      Expanded(child: Text(name, style: const TextStyle(fontFamily: 'Anonymous Pro', fontSize: 12, color: Color(0xFF555555)))),
      GestureDetector(onTap: () => setState(() => _people.removeAt(i)), child: const Icon(Icons.close, size: 13, color: Color(0xFFAAAAAA))),
    ]),
  );

  void _addPerson() {
    final name = _personController.text.trim();
    if (name.isEmpty) return;
    setState(() { _people.add(name); _personController.clear(); });
  }

  Future<void> _pickTime({required TimeOfDay initial, required ValueChanged<TimeOfDay> onPicked}) =>
      pickTime(context: context, initial: initial, accent: _accent, onPicked: onPicked);
}

