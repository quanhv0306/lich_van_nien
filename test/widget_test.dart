import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lich_van_nien/core/lunar_calculator.dart';
import 'package:lich_van_nien/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('Kiểm thử thuật toán Âm lịch TS. Hồ Ngọc Đức (Kinh tuyến 105° Đông - UTC+7)', () {
    test('Test Case 1: Mùng 1 Tết Giáp Thìn 2024 (10/02/2024 Dương lịch)', () {
      final lunar = LunarCalculator.solarToLunar(10, 2, 2024);
      expect(
        lunar.toMap(),
        equals({'day': 1, 'month': 1, 'year': 2024, 'isLeap': false}),
      );

      final solar = LunarCalculator.lunarToSolar(1, 1, 2024, false);
      expect(
        solar.toMap(),
        equals({'day': 10, 'month': 2, 'year': 2024}),
      );
    });

    test('Test Case 2: Tháng Nhuận năm Quý Mão 2023 (Mùng 1 tháng 2 Nhuận <-> 22/03/2023)', () {
      // Năm 2023 nhuận tháng 2 Âm lịch:
      // Mùng 1 tháng 2 thường: 20/02/2023
      // Mùng 1 tháng 2 nhuận: 22/03/2023
      final regularMonth2 = LunarCalculator.solarToLunar(20, 2, 2023);
      expect(
        regularMonth2.toMap(),
        equals({'day': 1, 'month': 2, 'year': 2023, 'isLeap': false}),
      );

      final leapMonth2 = LunarCalculator.solarToLunar(22, 3, 2023);
      expect(
        leapMonth2.toMap(),
        equals({'day': 1, 'month': 2, 'year': 2023, 'isLeap': true}),
      );

      final backToSolar = LunarCalculator.lunarToSolar(1, 2, 2023, true);
      expect(
        backToSolar.toMap(),
        equals({'day': 22, 'month': 3, 'year': 2023}),
      );
    });

    test('Test Case 3: Tháng Nhuận năm Ất Tỵ 2025 (Rằm tháng 6 Nhuận <-> 08/08/2025)', () {
      // Năm 2025 nhuận tháng 6 Âm lịch:
      // Ngày 25/07/2025 là Mùng 1 tháng 6 nhuận -> 08/08/2025 là 15/6 nhuận
      final lunar = LunarCalculator.solarToLunar(8, 8, 2025);
      expect(
        lunar.toMap(),
        equals({'day': 15, 'month': 6, 'year': 2025, 'isLeap': true}),
      );

      final solar = LunarCalculator.lunarToSolar(15, 6, 2025, true);
      expect(
        solar.toMap(),
        equals({'day': 8, 'month': 8, 'year': 2025}),
      );
    });

    test('Test Case 4: Ngày Dương lịch nhuận 29/02/2024 (20/01/2024 Âm lịch)', () {
      final lunar = LunarCalculator.solarToLunar(29, 2, 2024);
      expect(
        lunar.toMap(),
        equals({'day': 20, 'month': 1, 'year': 2024, 'isLeap': false}),
      );

      final solar = LunarCalculator.lunarToSolar(20, 1, 2024, false);
      expect(
        solar.toMap(),
        equals({'day': 29, 'month': 2, 'year': 2024}),
      );
    });

    test('Test Case 5: Ngày hôm nay (07/11/2026 Dương lịch <-> 29/09/2026 Âm lịch & tính toàn vẹn 2 chiều)', () {
      // Kiểm tra mốc ngày hôm nay 07/11/2026
      final specificToday = LunarCalculator.solarToLunar(7, 11, 2026);
      expect(
        specificToday.toMap(),
        equals({'day': 29, 'month': 9, 'year': 2026, 'isLeap': false}),
      );

      // Kiểm tra hàm nowInVietnam() theo chuẩn UTC+7 (độc lập OS timezone)
      final vnToday = LunarCalculator.nowInVietnam();
      final lunarToday = LunarCalculator.solarToLunar(
        vnToday.day,
        vnToday.month,
        vnToday.year,
      );
      final roundTripSolar = LunarCalculator.lunarToSolar(
        lunarToday.day,
        lunarToday.month,
        lunarToday.year,
        lunarToday.isLeap,
      );
      expect(roundTripSolar, equals(vnToday));
    });
  });

  testWidgets('Khởi chạy giao diện Lịch Vạn Niên (Mobile < 768px & PC/Tablet >= 768px)', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'last_mobile_tab_index': 2,
      'prayer_font_size': 22.0,
    });

    // 1. Kiểm tra chế độ Mobile (< 768px) -> hiển thị BottomNavigationBar 4 tab & khôi phục tab từ SharedPreferences
    tester.view.physicalSize = const Size(500, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const LichVanNienApp());
    await tester.pumpAndSettle();

    expect(find.text('LỊCH VẠN NIÊN VIỆT NAM'), findsOneWidget);
    expect(find.byType(BottomNavigationBar), findsOneWidget);
    final bottomNav = tester.widget<BottomNavigationBar>(
      find.byType(BottomNavigationBar),
    );
    expect(bottomNav.currentIndex, 2);
    expect(find.text('Lịch Ngày'), findsOneWidget);
    expect(find.text('Lịch Tháng'), findsOneWidget);
    expect(find.text('Văn Khấn'), findsOneWidget);
    expect(find.text('Phong Thủy'), findsOneWidget);

    // 2. Kiểm tra chế độ PC/Tablet (>= 768px) -> hiển thị NavigationRail + 2 cột (40% / 60%)
    tester.view.physicalSize = const Size(1280, 800);
    await tester.pumpWidget(const LichVanNienApp());
    await tester.pumpAndSettle();

    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(BottomNavigationBar), findsNothing);

    // 3. Kiểm tra phím tắt bàn phím: ←/→ (đổi ngày), ↑/↓ (đổi tháng), Home (về hôm nay)
    final today = DateTime.now();
    final tomorrow = DateTime.utc(today.year, today.month, today.day)
        .add(const Duration(days: 1));

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(find.text(tomorrow.day.toString().padLeft(2, '0')), findsWidgets);

    await tester.sendKeyEvent(LogicalKeyboardKey.home);
    await tester.pumpAndSettle();
    expect(find.text(today.day.toString().padLeft(2, '0')), findsWidgets);

    // 4. Kiểm tra màn hình nhỏ (360px) với textScaler lớn không bị tràn chữ (overflow)
    tester.view.physicalSize = const Size(360, 780);
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(
          size: Size(360, 780),
          textScaler: TextScaler.linear(1.35),
        ),
        child: const LichVanNienApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Chuyển qua tab Lịch Tháng (nơi có ô ngày 9/11 -> 1/10 ÂL và bảng Lý Thuần Phong)
    await tester.tap(find.text('Lịch Tháng'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
