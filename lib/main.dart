import 'package:flutter/material.dart';
import 'core/feng_shui_engine.dart';
import 'presentation/screens/home_adaptive_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FengShuiEngine.loadRules();
  runApp(const LichVanNienApp());
}

class LichVanNienApp extends StatelessWidget {
  const LichVanNienApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lịch Vạn Niên',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFFDF8EE),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFA61C1C),
          primary: const Color(0xFFA61C1C),
          secondary: const Color(0xFFD4AF37),
          surface: const Color(0xFFFFFDF7),
        ),
      ),
      home: const HomeAdaptiveScreen(),
    );
  }
}
