import 'package:flutter/material.dart';

class DayOfMonthDialog extends StatefulWidget {
  final Color accent;
  final bool returnFullDate;
  final bool showRecurrenceLabel;
  const DayOfMonthDialog({
    super.key,
    required this.accent,
    this.returnFullDate = false,
    this.showRecurrenceLabel = true,
  });

  @override
  State<DayOfMonthDialog> createState() => _DayOfMonthDialogState();
}

class _DayOfMonthDialogState extends State<DayOfMonthDialog> {
  int? _selected;
  late DateTime _viewMonth;

  static const _dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
  static const _monthNames = [
    'january','february','march','april','may','june',
    'july','august','september','october','november','december',
  ];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _viewMonth = DateTime(now.year, now.month);
  }

  int get _daysInMonth => DateTime(_viewMonth.year, _viewMonth.month + 1, 0).day;
  int get _firstWeekday => DateTime(_viewMonth.year, _viewMonth.month, 1).weekday;

  String get _monthLabel {
    final now = DateTime.now();
    if (_viewMonth.year == now.year && _viewMonth.month == now.month) return 'this month';
    return _monthNames[_viewMonth.month - 1];
  }

  void _prevMonth() => setState(() =>
      _viewMonth = DateTime(_viewMonth.year, _viewMonth.month - 1));

  void _nextMonth() => setState(() =>
      _viewMonth = DateTime(_viewMonth.year, _viewMonth.month + 1));

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [
            BoxShadow(color: Color(0x18000000), blurRadius: 24, offset: Offset(0, 8)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildMonthHeader(),
            _buildDayHeaders(),
            const Divider(height: 1, color: Color(0xFFF0F0F0)),
            _buildCalendarGrid(),
            const Divider(height: 1, color: Color(0xFFF0F0F0)),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: _prevMonth,
            child: const Icon(Icons.chevron_left, color: Color(0xFF333333), size: 22),
          ),
          Text(
            _monthLabel,
            style: const TextStyle(
              fontFamily: 'Anonymous Pro',
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFF333333),
            ),
          ),
          GestureDetector(
            onTap: _nextMonth,
            child: const Icon(Icons.chevron_right, color: Color(0xFF333333), size: 22),
          ),
        ],
      ),
    );
  }

  Widget _buildDayHeaders() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: _dayLabels.map((l) => SizedBox(
          width: 32,
          child: Center(
            child: Text(
              l,
              style: TextStyle(
                fontFamily: 'Anonymous Pro',
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: widget.accent,
              ),
            ),
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildCalendarGrid() {
    final today = DateTime.now();
    final isThisMonth = _viewMonth.year == today.year && _viewMonth.month == today.month;
    final todayDay = isThisMonth ? today.day : null;
    final leadingBlanks = _firstWeekday - 1;
    final totalCells = leadingBlanks + _daysInMonth;
    final rows = (totalCells / 7).ceil();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        children: List.generate(rows, (row) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(7, (col) {
              final cellIndex = row * 7 + col;
              final day = cellIndex - leadingBlanks + 1;

              if (day < 1 || day > _daysInMonth) {
                return const SizedBox(width: 32, height: 36);
              }

              final isSelected = _selected == day;
              final isToday = todayDay == day;

              return GestureDetector(
                onTap: () => setState(() => _selected = day),
                child: Container(
                  width: 32,
                  height: 36,
                  margin: const EdgeInsets.symmetric(vertical: 2),
                  decoration: isSelected
                      ? BoxDecoration(
                          color: widget.accent,
                          borderRadius: BorderRadius.circular(10),
                        )
                      : isToday
                          ? BoxDecoration(
                              border: Border.all(color: widget.accent, width: 1.5),
                              borderRadius: BorderRadius.circular(10),
                            )
                          : null,
                  child: Center(
                    child: Text(
                      '$day',
                      style: TextStyle(
                        fontFamily: 'Anonymous Pro',
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isSelected
                            ? Colors.white
                            : isToday
                                ? widget.accent
                                : const Color(0xFF333333),
                      ),
                    ),
                  ),
                ),
              );
            }),
          );
        }),
      ),
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Row(
        children: [
          if (_selected != null && widget.showRecurrenceLabel)
            Text(
              'recurs every ${_ordinal(_selected!)}',
              style: TextStyle(
                fontFamily: 'Anonymous Pro',
                fontSize: 12,
                color: Colors.grey.shade500,
              ),
            ),
          const Spacer(),
          GestureDetector(
            onTap: _selected != null ? () {
              final result = widget.returnFullDate
                  ? DateTime(_viewMonth.year, _viewMonth.month, _selected!)
                  : _selected;
              Navigator.of(context).pop(result);
            } : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: _selected != null ? widget.accent : const Color(0xFFEEEEEE),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'set',
                style: TextStyle(
                  fontFamily: 'Anonymous Pro',
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: _selected != null ? Colors.white : Colors.grey.shade400,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _ordinal(int n) {
    if (n >= 11 && n <= 13) return '${n}th';
    switch (n % 10) {
      case 1: return '${n}st';
      case 2: return '${n}nd';
      case 3: return '${n}rd';
      default: return '${n}th';
    }
  }
}
