import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'screens/task_list_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) {
    databaseFactory = databaseFactoryFfiWeb;
  } else if (defaultTargetPlatform == TargetPlatform.macOS ||
      defaultTargetPlatform == TargetPlatform.linux ||
      defaultTargetPlatform == TargetPlatform.windows) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  await LiquidGlassWidgets.initialize();
  runApp(LiquidGlassWidgets.wrap(const QuimbiApp()));
}

class QuimbiApp extends StatelessWidget {
  const QuimbiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quimbi',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Anonymous Pro',
        scaffoldBackgroundColor: const Color(0xFFF5F0EA),
      ),
      home: const TaskListScreen(),
    );
  }
}