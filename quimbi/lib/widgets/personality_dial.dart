import 'dart:math';
import 'package:flutter/material.dart';
import '../utils/escalation_settings.dart';

class PersonalityDial extends StatefulWidget {
  final QuimbiPersonality value;
  final ValueChanged<QuimbiPersonality> onChanged;

  const PersonalityDial({super.key, required this.value, required this.onChanged});

  @override
  State<PersonalityDial> createState() => _PersonalityDialState();
}

class _PersonalityDialState extends State<PersonalityDial>
    with SingleTickerProviderStateMixin {
  static const _count = 5;
  static const _personalities = [
    QuimbiPersonality.base,
    QuimbiPersonality.sunny,
    QuimbiPersonality.anxious,
    QuimbiPersonality.sleepy,
    QuimbiPersonality.grumpy,
  ];
  static const _labels = ['Base', 'Sunny', 'Anxious', 'Sleepy', 'Grumpy'];
  static const _emojis = ['😊', '☀️', '😰', '😴', '😤'];

  late double _rotation;
  double _lastAngle = 0;

  late AnimationController _snapController;
  late double _snapFrom;
  late double _snapTo;

  @override
  void initState() {
    super.initState();
    _rotation = _rotationFor(_personalities.indexOf(widget.value));
    _snapFrom = _rotation;
    _snapTo = _rotation;
    _snapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _snapController.addListener(() {
      setState(() {
        _rotation = _snapFrom +
            (_snapTo - _snapFrom) *
                Curves.easeOut.transform(_snapController.value);
      });
    });
  }

  @override
  void didUpdateWidget(PersonalityDial old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value) {
      _snapToIndex(_personalities.indexOf(widget.value));
    }
  }

  @override
  void dispose() {
    _snapController.dispose();
    super.dispose();
  }

  double _rotationFor(int idx) => -idx * 2 * pi / _count;

  int _selectedIndex() {
    // Which label is nearest to the top (angle = -π/2 = top of dial)?
    // Label i is at dial angle: (-π/2 + i*2π/5) + _rotation
    // It's at the top when its dial angle = -π/2, i.e. i*2π/5 + _rotation ≈ 0
    final steps = -_rotation * _count / (2 * pi);
    final idx = steps.round() % _count;
    return idx < 0 ? idx + _count : idx;
  }

  void _snapToIndex(int idx) {
    final ideal = _rotationFor(idx);
    final diff = _rotation - ideal;
    final n = (diff / (2 * pi)).round();
    _snapFrom = _rotation;
    _snapTo = ideal + n * 2 * pi;
    _snapController.forward(from: 0);
  }

  void _handlePanStart(Offset local, double size) {
    _snapController.stop();
    final c = size / 2;
    _lastAngle = atan2(local.dy - c, local.dx - c);
  }

  void _handlePanUpdate(Offset local, double size) {
    final c = size / 2;
    final angle = atan2(local.dy - c, local.dx - c);
    var delta = angle - _lastAngle;
    if (delta > pi) delta -= 2 * pi;
    if (delta < -pi) delta += 2 * pi;
    setState(() {
      _rotation += delta;
      _lastAngle = angle;
    });
    final idx = _selectedIndex();
    if (_personalities[idx] != widget.value) {
      widget.onChanged(_personalities[idx]);
    }
  }

  void _handlePanEnd() => _snapToIndex(_selectedIndex());

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _selectedIndex();

    return LayoutBuilder(builder: (context, constraints) {
      final size = constraints.maxWidth;

      return GestureDetector(
        onPanStart: (d) => _handlePanStart(d.localPosition, size),
        onPanUpdate: (d) => _handlePanUpdate(d.localPosition, size),
        onPanEnd: (_) => _handlePanEnd(),
        child: SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: Size(size, size),
                painter: _DialPainter(
                  rotation: _rotation,
                  emojis: _emojis,
                  labels: _labels,
                  selectedIndex: selectedIndex,
                ),
              ),
              // Fixed centre display
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_emojis[selectedIndex],
                      style: const TextStyle(fontSize: 28)),
                  const SizedBox(height: 2),
                  Text(
                    _labels[selectedIndex],
                    style: const TextStyle(
                      fontFamily: 'Anonymous Pro',
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF888888),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    });
  }
}

class _DialPainter extends CustomPainter {
  final double rotation;
  final List<String> emojis;
  final List<String> labels;
  final int selectedIndex;

  static const _count = 5;
  static const _orange = Color(0xFFF55420);
  static const _ring1 = Color(0xFFD4CBC0);
  static const _ring2 = Color(0xFFEDE5D8);
  static const _ring3 = Color(0xFFE5DDD0);

  const _DialPainter({
    required this.rotation,
    required this.emojis,
    required this.labels,
    required this.selectedIndex,
  });

  double _angleFor(int i) => -pi / 2 + i * 2 * pi / _count;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final R = size.width / 2;

    // Drop shadow
    canvas.drawCircle(
      c + const Offset(2, 5),
      R * 0.95,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.08)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );

    // Fixed outer rings
    _circle(canvas, c, R * 0.95, _ring1);
    _circle(canvas, c, R * 0.87, _ring2);

    // Fixed pointer at top — small orange dot on the outer ring
    final pointerPos = c + Offset(0, -R * 0.91);
    canvas.drawCircle(pointerPos, 5, Paint()..color = _orange);

    // Rotating disc background
    _circle(canvas, c, R * 0.77, _ring3);

    // Rotating tick marks + emoji labels
    for (int i = 0; i < _count; i++) {
      final angle = _angleFor(i) + rotation;
      final isSelected = i == selectedIndex;

      // Tick
      final tickOuter = c + Offset(cos(angle) * R * 0.82, sin(angle) * R * 0.82);
      final tickInner = c + Offset(cos(angle) * R * 0.74, sin(angle) * R * 0.74);
      canvas.drawLine(
        tickOuter,
        tickInner,
        Paint()
          ..color = isSelected ? _orange : _ring1
          ..strokeWidth = isSelected ? 2.5 : 1.5
          ..strokeCap = StrokeCap.round,
      );

      // Emoji at rotated position (text drawn horizontally)
      final emojiPos = c + Offset(cos(angle) * R * 0.56, sin(angle) * R * 0.56);
      _paintText(canvas, emojis[i], emojiPos, fontSize: isSelected ? 15 : 12);
    }

    // Fixed centre knob on top
    _circle(canvas, c, R * 0.44, _ring2);
  }

  void _circle(Canvas canvas, Offset c, double r, Color color) =>
      canvas.drawCircle(c, r, Paint()..color = color);

  void _paintText(Canvas canvas, String text, Offset pos, {double fontSize = 14}) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: TextStyle(fontSize: fontSize)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, pos - Offset(tp.width / 2, tp.height / 2));
  }

@override
  bool shouldRepaint(_DialPainter old) =>
      old.rotation != rotation || old.selectedIndex != selectedIndex;
}
