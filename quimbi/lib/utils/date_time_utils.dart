import 'package:flutter/material.dart';

extension DateOnly on DateTime {
  DateTime get dateOnly => DateTime(year, month, day);
}

String formatDate(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';

String formatDateTime(DateTime date, TimeOfDay time) =>
    '${formatDate(date)} ${formatTimeOfDay(time)}:00';

String formatTimeOfDay(TimeOfDay time) =>
    '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

String todayDateString() => formatDate(DateTime.now());

/// Extracts hour and minute from 'HH:MM', 'HH:MM:SS', or 'YYYY-MM-DD HH:MM:SS'.
/// Returns null if the string is malformed or values are outside valid clock range.
({int hour, int minute})? parseTimeParts(String rawTime) {
  if (rawTime.isEmpty) return null;
  final timePart = rawTime.contains(' ') ? rawTime.split(' ').last : rawTime;
  final segments = timePart.split(':');
  if (segments.length < 2) return null;
  final hour = int.tryParse(segments[0]);
  final minute = int.tryParse(segments[1]);
  if (hour == null || minute == null) return null;
  if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;
  return (hour: hour, minute: minute);
}

String ordinal(int n) {
  if (n >= 11 && n <= 13) return '${n}th';
  switch (n % 10) {
    case 1: return '${n}st';
    case 2: return '${n}nd';
    case 3: return '${n}rd';
    default: return '${n}th';
  }
}
