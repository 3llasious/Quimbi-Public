import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:glassmorphism/glassmorphism.dart';

class QuimbiNavBar extends StatefulWidget {
  const QuimbiNavBar({super.key});

  @override
  State<QuimbiNavBar> createState() => _QuimbiNavBarState();
}

class _QuimbiNavBarState extends State<QuimbiNavBar> {
  String _active = 'todo';
  bool _fabOpen = false;

  static const _orange = Color(0xFFFF4A00);
  static const _purple = Color(0xFF7B61FF);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom + 4,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildPill(),
          const SizedBox(width: 12),
          _buildFab(),
        ],
      ),
    );
  }

  Widget _buildPill() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        boxShadow: const [
          BoxShadow(
            color: Color(0x40000000),
            blurRadius: 4,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: GlassmorphicContainer(
      width: 260,
      height: 72,
      borderRadius: 999,
      blur: 20,
      alignment: Alignment.center,
      border: 1.5,
      linearGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withOpacity(0.65),
          Colors.white.withOpacity(0.45),
        ],
      ),
      borderGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withOpacity(0.9),
          Colors.white.withOpacity(0.1),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildNavItem('home', _homeIconSvg),
            _buildNavItem('todo', _todoIconSvg),
            _buildNavItem('community', null),
          ],
        ),
      ),
    ),
    );
  }

  Widget _buildNavItem(String key, String? svgString) {
    final isActive = _active == key;
    final label = key == 'todo' ? 'to-do' : key;

    return GestureDetector(
      onTap: () => setState(() => _active = key),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.elasticOut,
        width: isActive ? 96 : 64,
        height: double.infinity,
        decoration: isActive
            ? BoxDecoration(
                color: _orange,
                borderRadius: BorderRadius.circular(999),
                boxShadow: [
                  BoxShadow(
                    color: _orange.withOpacity(0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              )
            : null,
        child: Stack(
          alignment: Alignment.center,
          children: [
            AnimatedSlide(
              offset: isActive ? const Offset(0, -0.22) : Offset.zero,
              duration: const Duration(milliseconds: 300),
              curve: Curves.elasticOut,
              child: key == 'community'
                  ? _communityDot(isActive)
                  : SvgPicture.string(
                      svgString!.replaceAll(
                          'currentColor', isActive ? '#FFFFFF' : '#7B61FF'),
                      width: 22,
                      height: 22,
                    ),
            ),
            if (isActive)
              Positioned(
                bottom: 6,
                child: Text(
                  label,
                  style: const TextStyle(
                    fontFamily: 'Anonymous Pro',
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _communityDot(bool isActive) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isActive ? Colors.white : _purple,
        boxShadow: [
          BoxShadow(
            color: (isActive ? Colors.white : _purple).withOpacity(0.6),
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ],
      ),
    );
  }

  Widget _buildFab() {
    return GestureDetector(
      onTap: () => setState(() => _fabOpen = !_fabOpen),
      child: Container(
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Color(0x26000000),
              blurRadius: 16,
              spreadRadius: 4,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: GlassmorphicContainer(
        width: 72,
        height: 72,
        borderRadius: 999,
        blur: 15,
        alignment: Alignment.center,
        border: 1.5,
        linearGradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.55),
            Colors.white.withOpacity(0.35),
          ],
        ),
        borderGradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.8),
            Colors.white.withOpacity(0.3),
          ],
        ),
        child: AnimatedRotation(
          turns: _fabOpen ? 0.125 : 0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.elasticOut,
          child: Icon(
            Icons.add,
            color: _fabOpen ? _orange : _purple,
            size: 26,
          ),
        ),
        ),
      ),
    );
  }

  static const String _homeIconSvg = '''
<svg width="27" height="27" viewBox="0 0 27 27" fill="none" xmlns="http://www.w3.org/2000/svg">
  <path d="M3.48438 13.5813V22.3599L7 23.3141V17.7798L11.1016 18.734V24.4592L15.3984 25.9859M15.3984 25.9859V18.1615M15.3984 25.9859L23.9922 21.1379V16.4439M0.75 13.1996L9.14844 5.56605M9.14844 5.56605L17.5469 0.985901L25.75 13.1996L17.5469 17.7798L9.14844 5.56605Z" stroke="currentColor" stroke-width="1.5" stroke-linecap="round"/>
</svg>''';

  static const String _todoIconSvg = '''
<svg width="25" height="25" viewBox="0 0 25 25" fill="none" xmlns="http://www.w3.org/2000/svg">
  <path d="M3.646 18.75V7.29165C3.646 3.12498 4.68766 2.08331 8.85433 2.08331H16.146C20.3127 2.08331 21.3543 3.12498 21.3543 7.29165V17.7083C21.3543 17.8541 21.3543 18 21.3439 18.1458" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/>
  <path d="M6.61475 15.625H21.3543V19.2708C21.3543 21.2812 19.7189 22.9167 17.7085 22.9167H7.29183C5.28141 22.9167 3.646 21.2812 3.646 19.2708V18.5938C3.646 16.9583 4.97933 15.625 6.61475 15.625Z" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/>
  <path d="M8.3335 7.29169H16.6668" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/>
  <path d="M8.3335 10.9375H13.5418" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/>
</svg>''';
}
