import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:gif/gif.dart';
import '../logic/pet_state_machine.dart';

class PetWidget extends StatefulWidget {
  const PetWidget({super.key, required this.machine});

  final PetStateMachine machine;

  @override
  State<PetWidget> createState() => _PetWidgetState();
}

class _PetWidgetState extends State<PetWidget> with SingleTickerProviderStateMixin {
  late GifController _controller;
  String? _currentPath;

  @override
  void initState() {
    super.initState();
    _controller = GifController(vsync: this);
    widget.machine.addListener(_onStateChanged);
  }

  @override
  void dispose() {
    widget.machine.removeListener(_onStateChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onStateChanged() {
    final newPath = _gifPath(widget.machine.displayState);
    if (newPath != _currentPath) _controller.reset();
    setState(() {});
  }

  String _gifPath(PetDisplayState state) {
    switch (state) {
      case PetDisplayState.joy:
        return 'assets/gifs/joy.gif';
      case PetDisplayState.attack:
        return 'assets/gifs/attack.gif';
      case PetDisplayState.escalating1:
        return 'assets/gifs/3-4-life.gif';
      case PetDisplayState.escalating2:
      case PetDisplayState.escalating3:
      case PetDisplayState.critical:
        return 'assets/gifs/1-2-life.gif';
      case PetDisplayState.dead:
        return 'assets/gifs/resurrection.gif';
      case PetDisplayState.idle:
        return _idleGifPath();
    }
  }

  int _fpsFor(String path) {
    if (path == 'assets/gifs/attack.gif') return 12;
    if (path == 'assets/gifs/hula-2.gif') return 2;          // ~500ms/frame
    if (path == 'assets/gifs/side_to_side.gif') return 15;   // snappy high energy
    if (path == 'assets/gifs/front-sleep.gif') return 7;     // ~143ms/frame (nearest to 0.15s)
    if (path == 'assets/gifs/side sleep.gif') return 7;      // ~143ms/frame
    return 10;
  }

  // Mood → idle gif. Replace with 'assets/gifs/idle/$mood.gif' once per-mood assets exist.
  String _idleGifPath() {
    const map = {
      // Very low energy
      'empty':    'assets/gifs/front-sleep.gif',
      'bored':    'assets/gifs/front-sleep.gif',
      'sleepy':   'assets/gifs/side sleep.gif',
      'dreamy':   'assets/gifs/side sleep.gif',
      // Low energy
      'sulky':    'assets/gifs/front-sleep.gif',
      'hangry':   'assets/gifs/ramen.gif',
      'fussy':    'assets/gifs/hungry.gif',
      'cozy':     'assets/gifs/side sleep.gif',
      // Medium energy
      'grumpy':   'assets/gifs/front-sleep.gif',
      'pouty':    'assets/gifs/hula-2.gif',
      'perky':    'assets/gifs/hula-2.gif',
      'sunny':    'assets/gifs/side_to_side.gif',
      // High energy
      'devilish': 'assets/gifs/devilish-quimbi.gif',
      'jittery':  'assets/gifs/hula-2.gif',
      'bouncy':   'assets/gifs/side_to_side.gif',
      'dancy':    'assets/gifs/side_to_side.gif',
    };
    return map[widget.machine.mood.toLowerCase()] ?? 'assets/gifs/hula-2.gif';
  }

  @override
  Widget build(BuildContext context) {
    final path = _gifPath(widget.machine.displayState);
    _currentPath = path;

    final gif = Gif(
      key: ValueKey(path),
      image: AssetImage(path),
      controller: _controller,
      fps: _fpsFor(path),
      autostart: Autostart.loop,
      width: 130,
      height: 130,
      fit: BoxFit.contain,
    );

    final showReminder = widget.machine.reminderActive &&
        widget.machine.displayState == PetDisplayState.idle;
    return Stack(
      children: [
        gif,
        if (showReminder)
          Positioned(
            right: 8,
            top: 30,
            child: SvgPicture.asset(
              'assets/icons/reminder_triggered.svg',
              height: 15,
            ),
          ),
      ],
    );
  }
}
