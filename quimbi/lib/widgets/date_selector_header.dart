import 'package:flutter/material.dart';

const _selectedGreen = Color(0xFF7DBF87);

const double _separatorWidth = 8;
const double _horizontalPadding = 16;
const int _visibleDays = 7;
const int _daysBeforeToday = 365;

class DateSelectorHeader extends StatefulWidget {
  final ValueChanged<DateTime> onDateSelected;
  final DateTime? jumpToDate;

  const DateSelectorHeader({
    super.key,
    required this.onDateSelected,
    this.jumpToDate,
  });

  @override
  State<DateSelectorHeader> createState() => _DateSelectorHeaderState();
}

class _DateSelectorHeaderState extends State<DateSelectorHeader> {
  late final DateTime _origin;
  late final DateTime _today;
  late final ScrollController _scrollController;
  double _itemWidth = 40;
  int _centeredIndex = _daysBeforeToday;

  @override
  void initState() {
    super.initState();
    _today = _dateOnly(DateTime.now());
    _origin = _today.subtract(const Duration(days: _daysBeforeToday));
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _snapToIndex(_daysBeforeToday, animate: false));
  }

  @override
  void didUpdateWidget(DateSelectorHeader oldWidget) {
    super.didUpdateWidget(oldWidget);
    final jt = widget.jumpToDate;
    if (jt != null && jt != oldWidget.jumpToDate) {
      final index = _dateOnly(jt).difference(_origin).inDays;
      if (index >= 0 && index < 36500) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _snapToIndex(index);
          setState(() => _centeredIndex = index);
        });
      }
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
  DateTime _dateAt(int index) => _origin.add(Duration(days: index));

  double get _stride => _itemWidth + _separatorWidth;

  int _indexAtCenter() {
    if (!_scrollController.hasClients) return _centeredIndex;
    final viewport = _scrollController.position.viewportDimension;
    final contentCenter = _scrollController.offset + viewport / 2;
    return ((contentCenter - _horizontalPadding - _itemWidth / 2) / _stride)
        .round()
        .clamp(0, 36499);
  }

  void _onScroll() {
    final index = _indexAtCenter();
    if (index != _centeredIndex) {
      setState(() => _centeredIndex = index);
    }
  }

  void _snapToIndex(int index, {bool animate = true}) {
    if (!_scrollController.hasClients) return;
    final viewport = _scrollController.position.viewportDimension;
    final offset = (_horizontalPadding + index * _stride + _itemWidth / 2 - viewport / 2)
        .clamp(0.0, _scrollController.position.maxScrollExtent);
    if (animate) {
      _scrollController.animateTo(offset,
          duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
    } else {
      _scrollController.jumpTo(offset);
    }
  }

  void _onScrollEnd() {
    final index = _indexAtCenter();
    _snapToIndex(index);
    final date = _dateOnly(_dateAt(index));
    widget.onDateSelected(date);
    if (index != _centeredIndex) setState(() => _centeredIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _itemWidth = (constraints.maxWidth - _horizontalPadding * 2 - (_visibleDays - 1) * _separatorWidth) / _visibleDays;

        return SizedBox(
          height: 72,
          child: Stack(
            children: [
              // Fixed green pill — bottom layer, dates scroll above it
              IgnorePointer(
                child: Center(
                  child: Container(
                    width: _itemWidth,
                    height: 72,
                    decoration: BoxDecoration(
                      color: _selectedGreen,
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                ),
              ),
              NotificationListener<ScrollEndNotification>(
                onNotification: (_) {
                  WidgetsBinding.instance.addPostFrameCallback((_) => _onScrollEnd());
                  return false;
                },
                child: ListView.separated(
                  controller: _scrollController,
                  scrollDirection: Axis.horizontal,
                  physics: const ClampingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: _horizontalPadding),
                  itemCount: 36500,
                  separatorBuilder: (_, __) => const SizedBox(width: _separatorWidth),
                  itemBuilder: (context, index) => _DateItem(
                    date: _dateAt(index),
                    itemWidth: _itemWidth,
                    isCenter: index == _centeredIndex,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DateItem extends StatelessWidget {
  final DateTime date;
  final double itemWidth;
  final bool isCenter;

  static const _weekdayInitials = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  const _DateItem({
    required this.date,
    required this.itemWidth,
    required this.isCenter,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isCenter ? Colors.white : const Color(0xFF4D5B71);

    return SizedBox(
      width: itemWidth,
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
    );
  }
}
