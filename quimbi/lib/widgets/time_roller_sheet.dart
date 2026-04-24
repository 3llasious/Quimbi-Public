import 'package:flutter/material.dart';

Future<void> pickTime({
  required BuildContext context,
  required TimeOfDay initial,
  required Color accent,
  required ValueChanged<TimeOfDay> onPicked,
}) async {
  final picked = await showDialog<TimeOfDay>(
    context: context,
    barrierColor: Colors.black38,
    builder: (_) => Align(
      alignment: const Alignment(0, 0.5),
      child: TimeRollerSheet(initial: initial, accent: accent),
    ),
  );
  if (picked != null) onPicked(picked);
}

class TimeRollerSheet extends StatefulWidget {
  final TimeOfDay initial;
  final Color accent;
  const TimeRollerSheet({super.key, required this.initial, required this.accent});

  @override
  State<TimeRollerSheet> createState() => _TimeRollerSheetState();
}

class _TimeRollerSheetState extends State<TimeRollerSheet> {
  static const _itemH = 42.0;
  late int _hour;
  late int _minute;
  late FixedExtentScrollController _hourCtrl;
  late FixedExtentScrollController _minCtrl;

  @override
  void initState() {
    super.initState();
    _hour = widget.initial.hour;
    _minute = widget.initial.minute;
    _hourCtrl = FixedExtentScrollController(initialItem: _hour);
    _minCtrl = FixedExtentScrollController(initialItem: _minute);
  }

  @override
  void dispose() {
    _hourCtrl.dispose();
    _minCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFDDE0F0), width: 1),
        boxShadow: const [
          BoxShadow(color: Color(0x14000000), blurRadius: 16, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 240,
            child: Stack(children: [
              Center(
                child: Container(
                  height: _itemH,
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: widget.accent,
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
              Row(children: [
                Expanded(child: _wheel(_hourCtrl, 24, _hour, (v) => setState(() => _hour = v))),
                Expanded(child: _wheel(_minCtrl, 60, _minute, (v) => setState(() => _minute = v))),
              ]),
              Positioned(
                top: 0, left: 0, right: 0,
                child: IgnorePointer(child: Container(height: 80,
                  decoration: const BoxDecoration(gradient: LinearGradient(
                    begin: Alignment.topCenter, end: Alignment.bottomCenter,
                    colors: [Colors.white, Colors.transparent],
                  )),
                )),
              ),
              Positioned(
                bottom: 0, left: 0, right: 0,
                child: IgnorePointer(child: Container(height: 80,
                  decoration: const BoxDecoration(gradient: LinearGradient(
                    begin: Alignment.bottomCenter, end: Alignment.topCenter,
                    colors: [Colors.white, Colors.transparent],
                  )),
                )),
              ),
            ]),
          ),
          Divider(height: 1, color: const Color(0xFFDDE0F0)),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
            child: Row(children: [
              Text(
                '${_hour.toString().padLeft(2, '0')}:${_minute.toString().padLeft(2, '0')}',
                style: TextStyle(
                  fontFamily: 'Anonymous Pro',
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: widget.accent,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => Navigator.of(context).pop(TimeOfDay(hour: _hour, minute: _minute)),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  decoration: BoxDecoration(
                    color: widget.accent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'set',
                    style: TextStyle(
                      fontFamily: 'Anonymous Pro',
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _wheel(FixedExtentScrollController ctrl, int count, int selected, ValueChanged<int> onChange) {
    return ListWheelScrollView(
      controller: ctrl,
      itemExtent: _itemH,
      physics: const FixedExtentScrollPhysics(),
      onSelectedItemChanged: onChange,
      children: List.generate(count, (i) => Center(
        child: Text(
          i.toString().padLeft(2, '0'),
          style: TextStyle(
            fontFamily: 'Anonymous Pro',
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: i == selected ? Colors.white : const Color(0xFFB8B8C4),
          ),
        ),
      )),
    );
  }
}
