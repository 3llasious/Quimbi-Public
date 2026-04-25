import 'package:flutter/material.dart';

class ModalAlert {
  TimeOfDay time;
  String type;
  ModalAlert({required this.time, this.type = 'notification'});
}
