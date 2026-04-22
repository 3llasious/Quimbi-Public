import 'package:flutter/material.dart';

const _selectedGreen = Color(0xFF0BD172);

const double _itemWidth = 40;
const double _separatorWidth = 8;
const double _itemStride = _itemWidth + _separatorWidth;
const double _horizontalPadding = 16;

// Days shown before today — origin of the list.
const int _daysBeforeToday = 3;

class DateSelectorHeader extends StatefulWidget {
  final ValueChanged<DateTime> onDateSelected;

  const DateSelectorHeader({
    super.key,
    required this.onDateSelected,
  });

  @override
  State<DateSelectorHeader> createState() => _DateSelectorHeaderState();
}

class _DateSelectorHeaderState extends State<DateSelectorHeader> {
  late final DateTime _origin; // index 0 = today - 3 days
  late final DateTime _today;
  late DateTime _selectedDate;
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _today = _dateOnly(DateTime.now());
    _origin = _today.subtract(const Duration(days: _daysBeforeToday));
    _selectedDate = _today;
    _scrollController = ScrollController();

    WidgetsBinding.instance.addPostFrameCallback((_) => _centerOnToday());
  }

  void _centerOnToday() {
    if (!_scrollController.hasClients) return;
    final viewport = _scrollController.position.viewportDimension;
    // Offset that places today's centre at the viewport centre.
    final todayIndex = _daysBeforeToday;
    final todayCenter = _horizontalPadding + todayIndex * _itemStride + _itemWidth / 2;
    final offset = (todayCenter - viewport / 2).clamp(0.0, _scrollController.position.maxScrollExtent);
    _scrollController.jumpTo(offset);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  DateTime _dateAt(int index) => _origin.add(Duration(days: index));

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 72,
      child: ListView.separated(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        // Prevent scrolling left past the origin (3 days before today).
        physics: const ClampingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: _horizontalPadding),
        itemCount: 36500, // ~100 years forward
        separatorBuilder: (_, _) => const SizedBox(width: _separatorWidth),
        itemBuilder: (context, index) {
          final date = _dateAt(index);
          return _DateItem(
            date: date,
            isSelected: _dateOnly(date) == _selectedDate,
            onTap: () {
              setState(() => _selectedDate = _dateOnly(date));
              widget.onDateSelected(date);
            },
          );
        },
      ),
    );
  }
}

class _DateItem extends StatelessWidget {
  final DateTime date;
  final bool isSelected;
  final VoidCallback onTap;

  static const _weekdayInitials = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  const _DateItem({
    required this.date,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isSelected ? Colors.white : const Color(0xFF4D5B71);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: _itemWidth,
        decoration: BoxDecoration(
          color: isSelected ? _selectedGreen : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _weekdayInitials[date.weekday - 1],
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${date.day}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
