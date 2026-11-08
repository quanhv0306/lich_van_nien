import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lich_van_nien/core/horoscope_engine.dart';
import 'package:lich_van_nien/core/lunar_calculator.dart';
import 'package:lich_van_nien/core/sync_engine.dart';
import 'package:lich_van_nien/data/models/user_profile.dart';
import 'package:lich_van_nien/data/repositories/event_repository.dart';
import 'package:lich_van_nien/main.dart';
import 'package:lich_van_nien/presentation/widgets/add_event_dialog.dart';
import 'package:lich_van_nien/presentation/screens/prayer_detail_screen.dart';
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

    // Chuyển qua tab Lịch Tháng (nơi có ô ngày 9/11 -> 1/10 ÂL)
    await tester.tap(find.text('Lịch Tháng'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    // Chuyển qua tab Phong Thủy kiểm tra thẻ Bản Mệnh, Cung Phi & Vận Hạn
    await tester.tap(find.text('Phong Thủy'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Xem Bát Tự & Quẻ Mệnh'), findsOneWidget);
    expect(find.text('Tra cứu người khác'), findsOneWidget);

    // Chuyển qua tab Hồ Sơ kiểm tra giao diện Hồ sơ Gia chủ & Bản mệnh
    await tester.tap(find.text('Hồ Sơ'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Lưu thông tin'), findsOneWidget);

    // Chuyển qua tab Đồng Bộ kiểm tra giao diện Local-First
    await tester.tap(find.text('Đồng Bộ'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Tạo mã đồng bộ'), findsOneWidget);
  });

  test('Kiểm thử HoroscopeEngine (Nạp Âm, Cung Phi Bát Trạch, Cửu Diệu, Tam Tai - Kim Lâu - Hoang Ốc)', () {
    // Sinh ngày 15/06/1990 Dương lịch -> Năm Canh Ngọ (Lộ Bàng Thổ)
    final profile = HoroscopeEngine.analyzeProfile(
      day: 15,
      month: 6,
      year: 1990,
      isLunarInput: false,
      gender: Gender.male,
      targetLunarYear: 2026,
    );
    expect(profile.yearCanChi, 'Canh Ngọ');
    expect(profile.napAm.napAmName, 'Lộ Bàng Thổ');
    expect(profile.napAm.element, 'Thổ');
    expect(profile.batTrach.cungName, 'Khảm');
    expect(profile.batTrach.groupName, 'Đông Tứ Mệnh');
    expect(profile.batTrach.goodDirections.length, 4);
    expect(profile.batTrach.badDirections.length, 4);
    expect(profile.cuuDieu.lunarAge, 37);
  });

  test('Kiểm thử SyncEngine.mergePayloads (Merge 2 chiều Profile, gộp Events offline & Tombstone is_deleted)', () {
    final t1 = DateTime.utc(2026, 11, 7, 10, 0, 0);
    final t2 = DateTime.utc(2026, 11, 7, 12, 0, 0);
    final t3 = DateTime.utc(2026, 11, 7, 14, 0, 0);

    final localProfile = SyncUserProfile.defaultProfile().copyWith(
      fullName: 'Nguyễn Văn A (Local cũ)',
      updatedAt: t1,
    );
    final remoteProfile = SyncUserProfile.defaultProfile().copyWith(
      fullName: 'Nguyễn Văn A (Remote mới hơn)',
      updatedAt: t2,
    );

    final localEvents = <String, CalendarEvent>{
      // Sự kiện chỉ có ở Local (tạo lúc offline)
      'evt_local_only': CalendarEvent(
        id: 'evt_local_only',
        title: 'Giỗ tổ tạo lúc offline',
        note: 'Ghi chú local',
        solarDateKey: '2026-11-10',
        updatedAt: t2,
      ),
      // Sự kiện trùng ID nhưng bản Remote đã bị xóa với timestamp mới hơn (Tombstone)
      'evt_deleted_on_remote': CalendarEvent(
        id: 'evt_deleted_on_remote',
        title: 'Sự kiện sắp xóa',
        note: '',
        solarDateKey: '2026-11-12',
        isDeleted: false,
        updatedAt: t1,
      ),
    };

    final remotePayload = {
      'profile': remoteProfile.toJson(),
      'events': [
        // Sự kiện chỉ có ở Remote
        CalendarEvent(
          id: 'evt_remote_only',
          title: 'Họp mặt từ thiết bị B',
          note: '',
          solarDateKey: '2026-11-15',
          updatedAt: t1,
        ).toJson(),
        // Tombstone xóa mới hơn bản Local
        CalendarEvent(
          id: 'evt_deleted_on_remote',
          title: 'Sự kiện sắp xóa',
          note: '',
          solarDateKey: '2026-11-12',
          isDeleted: true,
          updatedAt: t3,
        ).toJson(),
      ],
    };

    final outcome = SyncEngine.mergePayloads(
      localProfile: localProfile,
      localEvents: localEvents,
      remotePayload: remotePayload,
    );

    // 1. Profile lấy bản mới hơn (Remote t2 > Local t1)
    expect(outcome.mergedProfile.fullName, 'Nguyễn Văn A (Remote mới hơn)');
    // 2. Giữ cả sự kiện chỉ có ở Local và chỉ có ở Remote
    expect(outcome.mergedEvents.containsKey('evt_local_only'), isTrue);
    expect(outcome.mergedEvents.containsKey('evt_remote_only'), isTrue);
    // 3. Sự kiện xóa ở Remote (t3 > t1) giữ nguyên cờ Tombstone isDeleted = true
    expect(outcome.mergedEvents['evt_deleted_on_remote']?.isDeleted, isTrue);
    // 4. Vì Local có 'evt_local_only' chưa có trên Remote nên cần push lại lên Supabase
    expect(outcome.shouldPushToRemote, isTrue);
  });

  test('Kiểm thử UserProfile & PrayerDetailScreen.formatPrayerContent (Điền tự động [Họ tên], [Tín chủ], [Địa chỉ])', () {
    final nowUtc = DateTime.utc(2026, 11, 8, 1, 0, 0);
    final userProf = UserProfile(
      fullName: UserProfile.capitalizeFullName('nguyễn văn an'),
      gender: 'Nam',
      birthDate: DateTime(1990, 6, 15),
      isLunarBirth: false,
      birthHourIndex: 4,
      address: 'Số 10 Hàng Đào, Hà Nội',
      updatedAt: nowUtc,
    );

    expect(userProf.fullName, 'Nguyễn Văn An');
    expect(userProf.birthHourLabel, 'Giờ Thìn (07:00 - 09:00)');

    final jsonMap = userProf.toJson();
    final restored = UserProfile.fromJson(jsonMap);
    expect(restored.fullName, 'Nguyễn Văn An');
    expect(restored.gender, 'Nam');
    expect(restored.birthHourIndex, 4);
    expect(restored.address, 'Số 10 Hàng Đào, Hà Nội');

    // Khi đã có fullName và address -> tự động thay thế [Họ tên], [Tín chủ], [Địa chỉ]
    const samplePrayer =
        'Tín chủ con là [Họ tên] (tức [Tín chủ]), ngụ tại [Địa chỉ] thành tâm kính lạy.';
    final filled = PrayerDetailScreen.formatPrayerContent(
      rawContent: samplePrayer,
      fullName: restored.fullName,
      address: restored.address,
    );
    expect(
      filled,
      'Tín chủ con là Nguyễn Văn An (tức Nguyễn Văn An), ngụ tại Số 10 Hàng Đào, Hà Nội thành tâm kính lạy.',
    );

    // Khi chưa lưu tên/địa chỉ -> giữ nguyên ngoặc vuông
    final unfilled = PrayerDetailScreen.formatPrayerContent(
      rawContent: samplePrayer,
      fullName: '',
      address: '',
    );
    expect(unfilled, samplePrayer);
  });

  group('Kiểm thử EventCategory & EventRepository (Sự kiện & Ghi chú Lịch Tháng Local-First)', () {
    test('Kiểm thử phân loại màu sắc và biểu tượng của EventCategory', () {
      expect(EventCategory.getColor(EventCategory.gioChap), const Color(0xFFE65100));
      expect(EventCategory.getColor(EventCategory.sinhNhat), const Color(0xFFE91E63));
      expect(EventCategory.getColor(EventCategory.congViec), const Color(0xFF1976D2));
      expect(EventCategory.getColor(EventCategory.khac), const Color(0xFF388E3C));

      expect(EventCategory.getIcon(EventCategory.gioChap), Icons.flare_rounded);
      expect(EventCategory.getIcon(EventCategory.sinhNhat), Icons.cake_rounded);
      expect(EventCategory.getIcon(EventCategory.congViec), Icons.work_rounded);
      expect(EventCategory.getIcon(EventCategory.khac), Icons.bookmark_rounded);
    });

    test('Kiểm thử nhận diện sự kiện đơn, lặp Dương lịch và Giỗ chạp lặp Âm lịch', () {
      final repo = EventRepository.instance;

      // 1. Sự kiện đơn: 15/11/2026
      final singleEvent = CalendarEvent(
        id: 'evt_1',
        title: 'Họp công ty',
        note: 'Chuẩn bị tài liệu',
        solarDateKey: '2026-11-15',
        category: EventCategory.congViec,
        isLunarRecurring: false,
        isSolarRecurring: false,
        updatedAt: DateTime.now(),
      );
      expect(repo.isEventOnDate(singleEvent, DateTime(2026, 11, 15)), isTrue);
      expect(repo.isEventOnDate(singleEvent, DateTime(2026, 11, 16)), isFalse);
      expect(repo.isEventOnDate(singleEvent, DateTime(2027, 11, 15)), isFalse);

      // 2. Sự kiện lặp Dương lịch hàng năm (Sinh nhật): 20/05/1995 -> hiển thị 20/05 hàng năm
      final bdayEvent = CalendarEvent(
        id: 'evt_2',
        title: 'Sinh nhật Lan',
        note: '',
        solarDateKey: '1995-05-20',
        category: EventCategory.sinhNhat,
        isLunarRecurring: false,
        isSolarRecurring: true,
        updatedAt: DateTime.now(),
      );
      expect(repo.isEventOnDate(bdayEvent, DateTime(2026, 5, 20)), isTrue);
      expect(repo.isEventOnDate(bdayEvent, DateTime(2027, 5, 20)), isTrue);
      expect(repo.isEventOnDate(bdayEvent, DateTime(2026, 5, 21)), isFalse);

      // 3. Sự kiện Giỗ chạp lặp Âm lịch hàng năm (isLunarRecurring = true):
      // Giỗ cụ ngày 15/07 Âm lịch (Vu Lan).
      // Giả sử ngày tạo sự kiện có ngày Âm lịch là 15/07/2020:
      final solarDateForGio = LunarCalculator.lunarToSolar(15, 7, 2020, false);
      final lunarEvent = CalendarEvent(
        id: 'evt_3',
        title: 'Giỗ Cụ Cố',
        note: 'Thắp hương gia tiên',
        solarDateKey: SyncEngine.formatDateKey(DateTime(solarDateForGio.year, solarDateForGio.month, solarDateForGio.day)),
        category: EventCategory.gioChap,
        isLunarRecurring: true,
        isSolarRecurring: false,
        updatedAt: DateTime.now(),
      );

      // Tính ngày Dương lịch của 15/07 Âm lịch năm 2026:
      final solar2026 = LunarCalculator.lunarToSolar(15, 7, 2026, false);
      final testDateMatch = DateTime(solar2026.year, solar2026.month, solar2026.day);
      final testDateMismatch = DateTime(solar2026.year, solar2026.month, solar2026.day + 1);

      expect(repo.isEventOnDate(lunarEvent, testDateMatch), isTrue);
      expect(repo.isEventOnDate(lunarEvent, testDateMismatch), isFalse);
    });

    test('Kiểm thử khởi tạo, gom nhóm và cache getEventsMapForMonth trong EventRepository', () async {
      SharedPreferences.setMockInitialValues({});
      await SyncEngine.instance.initLocalAndBackgroundListener();

      final repo = EventRepository.instance;

      // Thêm 3 sự kiện vào tháng 11/2026
      repo.addEvent(
        title: 'Sự kiện 1',
        note: '',
        solarDate: DateTime(2026, 11, 5),
        category: EventCategory.congViec,
      );
      repo.addEvent(
        title: 'Sự kiện 2',
        note: '',
        solarDate: DateTime(2026, 11, 5),
        category: EventCategory.sinhNhat,
      );
      repo.addEvent(
        title: 'Sự kiện 3',
        note: '',
        solarDate: DateTime(2026, 11, 10),
        category: EventCategory.khac,
      );

      final monthMap = repo.getEventsMapForMonth(11, 2026);
      expect(monthMap[5]?.length, 2);
      expect(monthMap[10]?.length, 1);
      expect(monthMap[11], isNull);

      final eventsDay5 = repo.getEventsForDate(DateTime(2026, 11, 5));
      expect(eventsDay5.length, 2);
      expect(eventsDay5.map((e) => e.title), containsAll(['Sự kiện 1', 'Sự kiện 2']));

      // Thêm sự kiện thứ 3 vào ngày 5/11 và kiểm tra cache tự động cập nhật
      final activeBefore = SyncEngine.instance.activeEvents.length;
      repo.addEvent(
        title: 'Sự kiện 4',
        note: '',
        solarDate: DateTime(2026, 11, 5),
        category: EventCategory.gioChap,
      );
      expect(SyncEngine.instance.activeEvents.length, activeBefore + 1);
      final updatedMap = repo.getEventsMapForMonth(11, 2026);
      expect(updatedMap[5]?.length, 3);

      // Xóa sự kiện
      final evtAdded = SyncEngine.instance.activeEvents.firstWhere((e) => e.title == 'Sự kiện 4');
      repo.deleteEvent(evtAdded.id);
      final mapAfterDelete = repo.getEventsMapForMonth(11, 2026);
      expect(mapAfterDelete[5]?.length, 2);
    });

    testWidgets('Kiểm thử hộp thoại AddEventDialog: Bấm "Đổi ngày" hiển thị DatePicker không bị crash/màn hình trắng', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('vi', 'VN'),
            Locale('vi'),
            Locale('en'),
          ],
          locale: const Locale('vi', 'VN'),
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => AddEventDialog.show(context, initialDate: DateTime(2026, 11, 8)),
                  child: const Text('Open Dialog'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Mở hộp thoại AddEventDialog
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Thêm Ghi Chú & Sự Kiện'), findsOneWidget);
      expect(find.text('Đổi ngày'), findsOneWidget);

      // Chạm vào nút "Đổi ngày"
      await tester.tap(find.text('Đổi ngày'));
      await tester.pumpAndSettle();

      // Kiểm tra DatePickerDialog hiển thị hoàn hảo bằng tiếng Việt, không có exception nào
      expect(tester.takeException(), isNull);
      expect(find.byType(DatePickerDialog), findsOneWidget);

      // Bấm nút HỦY
      await tester.tap(find.text('HỦY'));
      await tester.pumpAndSettle();

      // Vẫn ở trong hộp thoại AddEventDialog an toàn
      expect(find.text('Thêm Ghi Chú & Sự Kiện'), findsOneWidget);
    });
  });
}
