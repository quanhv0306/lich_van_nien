import 'package:flutter/material.dart';
import '../../core/lunar_calculator.dart';
import '../../core/sync_engine.dart';

/// Danh mục thể loại sự kiện / ghi chú trên lịch
class EventCategory {
  static const String gioChap = 'Giỗ chạp';
  static const String sinhNhat = 'Sinh nhật';
  static const String congViec = 'Công việc';
  static const String khac = 'Khác';

  static const List<String> all = [
    gioChap,
    sinhNhat,
    congViec,
    khac,
  ];

  /// Màu sắc đặc trưng của từng thể loại theo yêu cầu:
  /// - Giỗ chạp: Màu cam / vàng đất
  /// - Sinh nhật: Màu đỏ / hồng
  /// - Công việc: Màu xanh dương
  /// - Khác: Màu xanh lá / xám
  static Color getColor(String category) {
    switch (category) {
      case gioChap:
        return const Color(0xFFE65100); // Cam đất / Lửa hương
      case sinhNhat:
        return const Color(0xFFE91E63); // Hồng đỏ / Sinh nhật
      case congViec:
        return const Color(0xFF1976D2); // Xanh dương / Công việc
      case khac:
      default:
        return const Color(0xFF388E3C); // Xanh lá / Khác
    }
  }

  /// Icon trực quan tương ứng với thể loại
  static IconData getIcon(String category) {
    switch (category) {
      case gioChap:
        return Icons.flare_rounded;
      case sinhNhat:
        return Icons.cake_rounded;
      case congViec:
        return Icons.work_rounded;
      case khac:
      default:
        return Icons.bookmark_rounded;
    }
  }
}

/// Kho dữ liệu Sự kiện & Ghi chú (EventRepository) theo chuẩn Local-First:
/// - Tính toán và gom nhóm các sự kiện theo tháng: `getEventsMapForMonth(int month, int year)`
/// - Hỗ trợ lọc chính xác cả ngày Dương lịch cụ thể và sự kiện lặp hàng năm theo Âm lịch / Dương lịch.
/// - Cache kết quả theo tháng để tối ưu hiệu năng 60fps khi lướt đổi tháng.
class EventRepository {
  static final EventRepository instance = EventRepository._internal();
  EventRepository._internal() {
    // Tự động xóa cache khi dữ liệu trong SyncEngine thay đổi (thêm/sửa/xóa hoặc đồng bộ)
    SyncEngine.instance.addListener(invalidateCache);
  }

  factory EventRepository() => instance;

  // Bộ nhớ đệm gom nhóm sự kiện theo từng tháng (key: "YYYY-MM")
  final Map<String, Map<int, List<CalendarEvent>>> _monthCache = {};

  /// Xóa toàn bộ cache để tính toán lại dữ liệu mới nhất
  void invalidateCache() {
    _monthCache.clear();
  }

  /// Kiểm tra xem sự kiện `event` có diễn ra vào ngày `solarDate` hay không:
  /// 1. Sự kiện một lần: Khớp chính xác YYYY-MM-DD
  /// 2. Sự kiện lặp hàng năm Dương lịch: Khớp ngày & tháng Dương
  /// 3. Sự kiện lặp hàng năm Âm lịch (Giỗ chạp, Lễ Tiết):
  ///    Quy đổi ngày gốc sang Âm lịch, sau đó kiểm tra xem ngày `solarDate`
  ///    có cùng ngày và tháng Âm lịch hay không.
  bool isEventOnDate(
    CalendarEvent event,
    DateTime solarDate, [
    LunarDate? precomputedLunar,
  ]) {
    if (event.isDeleted) return false;

    // 1. Kiểm tra sự kiện không lặp lại (chính xác ngày Dương lịch)
    final dateKey = SyncEngine.formatDateKey(solarDate);
    if (!event.isLunarRecurring && !event.isSolarRecurring) {
      return event.solarDateKey == dateKey;
    }

    final originSolar = DateTime.tryParse(event.solarDateKey);
    if (originSolar == null) return false;

    // 2. Kiểm tra sự kiện lặp hàng năm theo Dương lịch (ví dụ: Sinh nhật Dương lịch)
    if (event.isSolarRecurring) {
      if (originSolar.day == solarDate.day &&
          originSolar.month == solarDate.month) {
        return true;
      }
    }

    // 3. Kiểm tra sự kiện lặp hàng năm theo Âm lịch (ví dụ: Giỗ chạp, Sinh nhật Âm)
    if (event.isLunarRecurring) {
      final originLunar = LunarCalculator.solarToLunar(
        originSolar.day,
        originSolar.month,
        originSolar.year,
      );
      final currentLunar = precomputedLunar ??
          LunarCalculator.solarToLunar(
            solarDate.day,
            solarDate.month,
            solarDate.year,
          );

      if (currentLunar.day == originLunar.day &&
          currentLunar.month == originLunar.month) {
        return true;
      }
    }

    return false;
  }

  /// Gom nhóm dữ liệu sự kiện theo tháng: `getEventsMapForMonth(int month, int year)`
  /// Trả về `Map<int, List<CalendarEvent>>` với key là số ngày trong tháng (1..31).
  /// Tính toán trước một lần và lưu vào cache để từng ô ngày không phải query riêng biệt.
  Map<int, List<CalendarEvent>> getEventsMapForMonth(int month, int year) {
    final cacheKey = '$year-$month';
    if (_monthCache.containsKey(cacheKey)) {
      return _monthCache[cacheKey]!;
    }

    final activeEvents = SyncEngine.instance.activeEvents;
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final Map<int, List<CalendarEvent>> resultMap = {};

    for (int day = 1; day <= daysInMonth; day++) {
      final solarDate = DateTime(year, month, day);
      final lunarDate = LunarCalculator.solarToLunar(day, month, year);
      final dayEvents = <CalendarEvent>[];

      for (final event in activeEvents) {
        if (isEventOnDate(event, solarDate, lunarDate)) {
          dayEvents.add(event);
        }
      }

      if (dayEvents.isNotEmpty) {
        resultMap[day] = dayEvents;
      }
    }

    _monthCache[cacheKey] = resultMap;
    return resultMap;
  }

  /// Lấy danh sách sự kiện cho một ngày cụ thể (Dương lịch)
  List<CalendarEvent> getEventsForDate(DateTime date) {
    final monthMap = getEventsMapForMonth(date.month, date.year);
    return monthMap[date.day] ?? const <CalendarEvent>[];
  }

  /// Thêm sự kiện mới (Local-First 0ms latency)
  void addEvent({
    required String title,
    required String note,
    required DateTime solarDate,
    String category = EventCategory.khac,
    bool isLunarRecurring = false,
    bool isSolarRecurring = false,
  }) {
    SyncEngine.instance.upsertEventLocalFirst(
      title: title,
      note: note,
      solarDate: solarDate,
      category: category,
      isLunarRecurring: isLunarRecurring,
      isSolarRecurring: isSolarRecurring,
    );
  }

  /// Cập nhật sự kiện hiện có
  void updateEvent({
    required String id,
    required String title,
    required String note,
    required DateTime solarDate,
    String category = EventCategory.khac,
    bool isLunarRecurring = false,
    bool isSolarRecurring = false,
  }) {
    SyncEngine.instance.upsertEventLocalFirst(
      id: id,
      title: title,
      note: note,
      solarDate: solarDate,
      category: category,
      isLunarRecurring: isLunarRecurring,
      isSolarRecurring: isSolarRecurring,
    );
  }

  /// Xóa sự kiện theo cơ chế Tombstone
  void deleteEvent(String id) {
    SyncEngine.instance.deleteEventLocalFirst(id);
  }
}
