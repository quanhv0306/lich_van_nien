import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/feng_shui_engine.dart';
import 'core/sync_engine.dart';
import 'presentation/screens/home_adaptive_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FengShuiEngine.loadRules();

  // Khởi tạo Supabase bọc trong try-catch để khởi động app 100% không phụ thuộc Internet
  bool supabaseInitialized = false;
  try {
    await Supabase.initialize(
      url: SyncEngine.supabaseUrl,
      // ignore: deprecated_member_use
      anonKey: SyncEngine.supabaseAnonKey,
    );
    supabaseInitialized = true;
  } catch (e) {
    debugPrint('[main] Offline startup (Supabase init skipped): $e');
  }

  // Nạp dữ liệu từ Local Storage (Single Source of Truth) và bật listener mạng chạy ngầm
  await SyncEngine.instance.initLocalAndBackgroundListener(
    supabaseInitialized: supabaseInitialized,
  );

  runApp(const LichVanNienApp());
}

class LichVanNienApp extends StatelessWidget {
  const LichVanNienApp({super.key});

  @override
  Widget build(BuildContext context) {
    final baseTheme = ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xFFFDF8EE),
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFFA61C1C),
        primary: const Color(0xFFA61C1C),
        secondary: const Color(0xFFD4AF37),
        surface: const Color(0xFFFFFDF7),
      ),
    );

    return MaterialApp(
      title: 'Lịch Vạn Niên',
      debugShowCheckedModeBanner: false,
      theme: baseTheme.copyWith(
        textTheme: baseTheme.textTheme.apply(
          bodyColor: const Color(0xFF2D1E17),
          displayColor: const Color(0xFF2D1E17),
        ),
      ),
      builder: (context, child) {
        // Giới hạn tỷ lệ phóng to font hệ thống tối đa 1.15x để không bị vỡ/tràn khung trên màn hình nhỏ
        final mediaQuery = MediaQuery.of(context);
        final clampedScaler = mediaQuery.textScaler.clamp(
          minScaleFactor: 0.85,
          maxScaleFactor: 1.15,
        );
        return MediaQuery(
          data: mediaQuery.copyWith(textScaler: clampedScaler),
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: const HomeAdaptiveScreen(),
    );
  }
}
