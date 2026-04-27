import 'package:flutter/material.dart';
import '../utils/escalation_settings.dart';
import '../widgets/personality_dial.dart';

class SettingsScreen extends StatefulWidget {
  final EscalationSettings settings;

  const SettingsScreen({super.key, required this.settings});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late int _mild;
  late int _moderate;
  late int _severe;
  late int _critical;
  late int _death;
  late QuimbiPersonality _personality;

  static const _bg = Color(0xFFF5EFE6);
  static const _card = Color(0xFFEDE5D8);
  static const _orange = Color(0xFFF55420);
  static const _text = Color(0xFF2D2D2D);
  static const _muted = Color(0xFF888888);
  static const _dividerColor = Color(0xFFD9D0C3);

  @override
  void initState() {
    super.initState();
    _mild = widget.settings.mildMinutes;
    _moderate = widget.settings.moderateMinutes;
    _severe = widget.settings.severeMinutes;
    _critical = widget.settings.criticalMinutes;
    _death = widget.settings.deathMinutes;
    _personality = widget.settings.personality;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 8, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: _text),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Text(
                    'Settings',
                    style: TextStyle(
                      fontFamily: 'CanelaTrialMedium',
                      fontSize: 24,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'ESCALATION',
                style: TextStyle(
                  fontFamily: 'Anonymous Pro',
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: _muted,
                  letterSpacing: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: _card,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  _buildRow(
                    label: 'Mild',
                    sub: '3/4 health',
                    value: _mild,
                    min: 1,
                    max: _moderate - 1,
                    onChanged: (v) => setState(() => _mild = v),
                    onChangeEnd: widget.settings.setMild,
                  ),
                  _divider(),
                  _buildRow(
                    label: 'Moderate',
                    sub: '1/2 health',
                    value: _moderate,
                    min: _mild + 1,
                    max: _severe - 1,
                    onChanged: (v) => setState(() => _moderate = v),
                    onChangeEnd: widget.settings.setModerate,
                  ),
                  _divider(),
                  _buildRow(
                    label: 'Severe',
                    sub: '1/4 health',
                    value: _severe,
                    min: _moderate + 1,
                    max: _critical - 1,
                    onChanged: (v) => setState(() => _severe = v),
                    onChangeEnd: widget.settings.setSevere,
                  ),
                  _divider(),
                  _buildRow(
                    label: 'Critical',
                    sub: 'empty',
                    value: _critical,
                    min: _severe + 1,
                    max: _death - 1,
                    onChanged: (v) => setState(() => _critical = v),
                    onChangeEnd: widget.settings.setCritical,
                  ),
                  _divider(),
                  _buildRow(
                    label: 'Death',
                    sub: 'resurrection',
                    value: _death,
                    min: _critical + 1,
                    max: 120,
                    onChanged: (v) => setState(() => _death = v),
                    onChangeEnd: widget.settings.setDeath,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'PERSONALITY',
                style: TextStyle(
                  fontFamily: 'Anonymous Pro',
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: _muted,
                  letterSpacing: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: SizedBox(
                width: 220,
                child: PersonalityDial(
                  value: _personality,
                  onChanged: (p) {
                    setState(() => _personality = p);
                    widget.settings.setPersonality(p);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _divider() => const Divider(
        height: 1,
        thickness: 1,
        indent: 16,
        endIndent: 16,
        color: _dividerColor,
      );

  Widget _buildRow({
    required String label,
    required String sub,
    required int value,
    required int min,
    required int max,
    required ValueChanged<int> onChanged,
    required ValueChanged<int> onChangeEnd,
  }) {
    final safeMax = max < min ? min : max;
    final clamped = value.clamp(min, safeMax);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
      child: Row(
        children: [
          SizedBox(
            width: 76,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontFamily: 'Anonymous Pro',
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: _text,
                  ),
                ),
                Text(
                  sub,
                  style: const TextStyle(
                    fontFamily: 'Anonymous Pro',
                    fontSize: 11,
                    color: _muted,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SliderTheme(
              data: SliderThemeData(
                activeTrackColor: _orange,
                inactiveTrackColor: const Color(0xFFCFC7B8),
                thumbColor: _orange,
                overlayColor: _orange.withValues(alpha: 0.12),
                trackHeight: 3,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
              ),
              child: Slider(
                value: clamped.toDouble(),
                min: min.toDouble(),
                max: safeMax.toDouble(),
                divisions: safeMax - min > 0 ? safeMax - min : 1,
                onChanged: (v) => onChanged(v.round()),
                onChangeEnd: (v) => onChangeEnd(v.round()),
              ),
            ),
          ),
          SizedBox(
            width: 44,
            child: Text(
              '${clamped}m',
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontFamily: 'Anonymous Pro',
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: _orange,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
