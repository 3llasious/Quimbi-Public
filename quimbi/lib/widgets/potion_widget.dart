import 'package:flutter/material.dart';

class PotionWidget extends StatelessWidget {
  const PotionWidget({super.key, required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$count',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.normal,
            color: Color(0xFF888888),
          ),
        ),
        const SizedBox(height: 4),
        Image.asset(
          'assets/Images/streak-potion.png',
          width: 48,
          height: 48,
          fit: BoxFit.contain,
        ),
      ],
    );
  }
}
