import 'package:flutter/material.dart';
import '../../core/sync_engine.dart';
import '../../data/models/day_info.dart';
import '../../data/repositories/event_repository.dart';
import '../widgets/add_event_dialog.dart';

/// Lưới lịch tháng thông minh & Quản lý Sự kiện / Ghi chú:
/// 1. Tương tác chọn ngày: Chạm vào ô ngày bất kỳ để chọn, hiển thị viền nổi bật.
/// 2. Danh sách sự kiện ngày được chọn: Lọc cả sự kiện ngày Dương và ngày Giỗ/Sinh nhật lặp theo Âm lịch qua EventRepository.
/// 3. Nút Thêm ghi chú / FAB (+): Tự động điền ngày đang chọn làm mặc định, hỗ trợ chọn thể loại và chu kỳ lặp Âm/Dương.
/// 4. Chỉ báo chấm tròn (Indicators):
///    - 1..3 sự kiện: Hàng chấm màu theo thể loại (Giỗ chạp: cam, Sinh nhật: hồng/đỏ, Công việc: xanh dương, Khác: xanh lá).
///    - >3 sự kiện: 2 chấm màu đầu tiên kèm badge số lượng (+N).
/// 5. Tối ưu hiệu năng: Cache gom nhóm sự kiện theo tháng `getEventsMapForMonth` giúp lướt tháng mượt mà 60fps.
/// 6. Thiết kế Responsive:
///    - Desktop (>= 720px): Layout 2 cột (Lưới tháng 65% bên trái, Danh sách ghi chú 35% bên phải).
///    - Mobile (< 720px): Lưới tháng ở trên, danh sách ghi chú ở dưới kèm nút (+) nổi.
class MonthlyGridView extends StatelessWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateSelected;

  const MonthlyGridView({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
  });

  /// Tạo danh sách 35 ô (7x5) hoặc 42 ô (7x6) tùy theo số ngày trong tháng và thứ bắt đầu
  List<DateTime?> _generateMonthCells(int year, int month) {
    final firstDayOfMonth = DateTime(year, month, 1);
    final daysInMonth = DateTime(year, month + 1, 0).day;
    // Đưa Thứ Hai về cột đầu tiên (0..6)
    final leadingEmpty = (firstDayOfMonth.weekday - 1) % 7;

    final List<DateTime?> cells = List<DateTime?>.filled(
      leadingEmpty,
      null,
      growable: true,
    );
    for (int d = 1; d <= daysInMonth; d++) {
      cells.add(DateTime(year, month, d));
    }
    // Bổ sung các ô trống cuối tháng để tròn 7x5 (35) hoặc 7x6 (42)
    final int targetCells = cells.length <= 35 ? 35 : 42;
    while (cells.length < targetCells) {
      cells.add(null);
    }
    return cells;
  }

  void _changeMonth(int offset) {
    final target = DateTime(
      selectedDate.year,
      selectedDate.month + offset,
      1,
    );
    final maxDays = DateTime(target.year, target.month + 1, 0).day;
    final clampedDay = selectedDate.day > maxDays ? maxDays : selectedDate.day;
    onDateSelected(DateTime(target.year, target.month, clampedDay));
  }

  void _changeYear(int newYear) {
    final maxDays = DateTime(newYear, selectedDate.month + 1, 0).day;
    final clampedDay = selectedDate.day > maxDays ? maxDays : selectedDate.day;
    onDateSelected(DateTime(newYear, selectedDate.month, clampedDay));
  }

  void _changeMonthDirect(int newMonth) {
    final maxDays = DateTime(selectedDate.year, newMonth + 1, 0).day;
    final clampedDay = selectedDate.day > maxDays ? maxDays : selectedDate.day;
    onDateSelected(DateTime(selectedDate.year, newMonth, clampedDay));
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: SyncEngine.instance,
      builder: (context, _) {
        // Tối ưu hiệu năng: Tính trước và cache toàn bộ sự kiện trong tháng (O(1) cho mỗi ô ngày)
        final eventsMap = EventRepository.instance.getEventsMapForMonth(
          selectedDate.month,
          selectedDate.year,
        );
        final selectedDayEvents = EventRepository.instance.getEventsForDate(selectedDate);

        return LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth >= 720;

            if (isDesktop) {
              return _buildDesktopLayout(context, eventsMap, selectedDayEvents);
            } else {
              return _buildMobileLayout(context, eventsMap, selectedDayEvents);
            }
          },
        );
      },
    );
  }

  /// Bố cục Desktop / Màn hình rộng (>= 720px):
  /// - Cột trái (65%): Lưới lịch tháng + Thanh chuyển tháng/năm
  /// - Cột phải (35%): Chi tiết ngày được chọn + Quản lý Sự kiện / Ghi chú (Thêm / Sửa / Xóa)
  Widget _buildDesktopLayout(
    BuildContext context,
    Map<int, List<CalendarEvent>> eventsMap,
    List<CalendarEvent> selectedDayEvents,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Lưới tháng (65%)
          Expanded(
            flex: 65,
            child: _buildCalendarCard(context, eventsMap),
          ),
          const SizedBox(width: 14),

          // Danh sách chi tiết sự kiện của ngày đang chọn (35%)
          Expanded(
            flex: 35,
            child: _buildDayDetailAndEventsCard(context, selectedDayEvents),
          ),
        ],
      ),
    );
  }

  /// Bố cục Mobile (< 720px):
  /// - Nửa trên: Lưới lịch tháng
  /// - Nửa dưới: Thẻ danh sách ghi chú của ngày được chọn và nút (+) nổi
  Widget _buildMobileLayout(
    BuildContext context,
    Map<int, List<CalendarEvent>> eventsMap,
    List<CalendarEvent> selectedDayEvents,
  ) {
    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildCalendarCard(context, eventsMap),
              const SizedBox(height: 14),
              _buildDayDetailAndEventsCard(context, selectedDayEvents),
            ],
          ),
        ),
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton(
            heroTag: 'fab_monthly_add_event',
            onPressed: () => AddEventDialog.show(context, initialDate: selectedDate),
            backgroundColor: const Color(0xFFA61C1C),
            foregroundColor: const Color(0xFFFFD54F),
            tooltip: 'Thêm ghi chú ngày ${selectedDate.day}/${selectedDate.month}',
            child: const Icon(Icons.add_rounded, size: 28),
          ),
        ),
      ],
    );
  }

  /// Card Lưới lịch tháng + Header chuyển tháng & năm
  Widget _buildCalendarCard(
    BuildContext context,
    Map<int, List<CalendarEvent>> eventsMap,
  ) {
    final cells = _generateMonthCells(selectedDate.year, selectedDate.month);
    final int rowCount = cells.length ~/ 7; // 5 hoặc 6 hàng (7x5 hoặc 7x6)
    final today = DateTime.now();
    const weekdays = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
    final years = List<int>.generate(201, (i) => 1900 + i);

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: const Color(0xFFFFFDF9),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(
          color: const Color(0xFFD4AF37).withValues(alpha: 0.55),
          width: 1.4,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ================= HEADER: NÚT CHUYỂN THÁNG & CHỌN NHANH NĂM =================
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton.filledTonal(
                  onPressed: () => _changeMonth(-1),
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFFFFF3CD),
                    foregroundColor: const Color(0xFFA61C1C),
                  ),
                  icon: const Icon(Icons.chevron_left_rounded),
                  tooltip: 'Tháng trước',
                ),
                Expanded(
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      // Chọn nhanh Tháng
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF8E7),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFFD4AF37),
                          ),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<int>(
                            value: selectedDate.month,
                            isDense: true,
                            icon: const Icon(
                              Icons.arrow_drop_down_rounded,
                              color: Color(0xFFA61C1C),
                            ),
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFA61C1C),
                            ),
                            items: List.generate(
                              12,
                              (i) => DropdownMenuItem<int>(
                                value: i + 1,
                                child: Text(
                                  'Tháng ${(i + 1).toString().padLeft(2, '0')}',
                                ),
                              ),
                            ),
                            onChanged: (val) {
                              if (val != null) _changeMonthDirect(val);
                            },
                          ),
                        ),
                      ),

                      // Chọn nhanh Năm
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFA61C1C),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFFFFD54F),
                          ),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<int>(
                            value: years.contains(selectedDate.year)
                                ? selectedDate.year
                                : 2026,
                            dropdownColor: const Color(0xFF8E0000),
                            isDense: true,
                            icon: const Icon(
                              Icons.arrow_drop_down_rounded,
                              color: Color(0xFFFFD54F),
                            ),
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFFFD54F),
                            ),
                            items: years
                                .map(
                                  (y) => DropdownMenuItem<int>(
                                    value: y,
                                    child: Text('Năm $y'),
                                  ),
                                )
                                .toList(),
                            onChanged: (val) {
                              if (val != null) _changeYear(val);
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton.filledTonal(
                  onPressed: () => _changeMonth(1),
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFFFFF3CD),
                    foregroundColor: const Color(0xFFA61C1C),
                  ),
                  icon: const Icon(Icons.chevron_right_rounded),
                  tooltip: 'Tháng sau',
                ),
              ],
            ),

            const SizedBox(height: 12),

            // ================= TIÊU ĐỀ 7 CỘT THỨ TRONG TUẦN =================
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3CD).withValues(alpha: 0.65),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: List.generate(7, (index) {
                  final isSunday = index == 6;
                  final isSaturday = index == 5;
                  return Expanded(
                    child: Center(
                      child: Text(
                        weekdays[index],
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: isSunday
                              ? const Color(0xFFB71C1C)
                              : (isSaturday
                                    ? const Color(0xFF0D47A1)
                                    : const Color(0xFF4E342E)),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),

            const SizedBox(height: 10),

            // ================= LƯỚI THÁNG 7x5 HOẶC 7x6 =================
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: rowCount * 7,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: 5,
                crossAxisSpacing: 5,
                // Chiều cao cân đối giúp hiển thị ngày Dương, chấm sự kiện và ngày Âm không bị tràn
                childAspectRatio: 0.78,
              ),
              itemBuilder: (context, index) {
                final date = cells[index];
                if (date == null) {
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.brown.withValues(alpha: 0.03),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  );
                }

                final info = DayInfo.fromSolarDate(date);
                final isSelected = date.year == selectedDate.year &&
                    date.month == selectedDate.month &&
                    date.day == selectedDate.day;
                final isToday = date.year == today.year &&
                    date.month == today.month &&
                    date.day == today.day;
                final isSunday = date.weekday == DateTime.sunday;
                final isSaturday = date.weekday == DateTime.saturday;

                // Danh sách sự kiện của ngày này từ cache O(1)
                final dayEvents = eventsMap[date.day] ?? const <CalendarEvent>[];

                // Kiểm tra ngày Mùng 1 hoặc Rằm (15 Âm lịch)
                final bool isMung1OrRam =
                    info.lunarDate.day == 1 || info.lunarDate.day == 15;

                // Hiển thị ngày/tháng Âm cho Mùng 1 hoặc ngày đầu tháng Dương
                final String lunarText =
                    (info.lunarDate.day == 1 || date.day == 1)
                        ? '${info.lunarDate.day}/${info.lunarDate.month}'
                        : '${info.lunarDate.day}';

                final Color solarTextColor = isSelected
                    ? Colors.white
                    : (isSunday
                          ? const Color(0xFFB71C1C)
                          : (isSaturday
                                ? const Color(0xFF0D47A1)
                                : const Color(0xFF2D1E17)));

                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => onDateSelected(date),
                    borderRadius: BorderRadius.circular(10),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFFA61C1C)
                            : (isMung1OrRam
                                  ? const Color(0xFFFFEBEE)
                                  : (isToday
                                        ? const Color(0xFFFFF3CD)
                                        : Colors.white)),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFFFFD54F)
                              : (isMung1OrRam
                                    ? const Color(0xFFD32F2F)
                                        .withValues(alpha: 0.65)
                                    : (isToday
                                          ? const Color(0xFFD4AF37)
                                          : Colors.grey.shade200)),
                          width: isSelected ? 2.0 : (isToday || isMung1OrRam ? 1.4 : 1.0),
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: const Color(0xFFA61C1C).withValues(alpha: 0.35),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 3,
                        vertical: 3,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Hàng trên: Số ngày Dương lịch (trái) & Chấm Hoàng Đạo (phải)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Flexible(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.topLeft,
                                  child: Text(
                                    '${date.day}',
                                    maxLines: 1,
                                    style: TextStyle(
                                      fontSize: 13,
                                      height: 1.0,
                                      fontWeight: FontWeight.w800,
                                      color: solarTextColor,
                                    ),
                                  ),
                                ),
                              ),
                              if (info.isHoangDao)
                                Container(
                                  width: 5,
                                  height: 5,
                                  margin: const EdgeInsets.only(top: 1),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isSelected
                                        ? const Color(0xFFFFD54F)
                                        : const Color(0xFFFFB300),
                                  ),
                                ),
                            ],
                          ),

                          // Hàng giữa: CHỈ BÁO GHI CHÚ TRÊN TỪNG Ô NGÀY (MONTHLY CELL INDICATORS)
                          _buildEventIndicators(dayEvents, isSelected),

                          // Hàng dưới: Số ngày Âm lịch (góc dưới bên phải)
                          Align(
                            alignment: Alignment.bottomRight,
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.bottomRight,
                              child: Container(
                                padding: isMung1OrRam
                                    ? const EdgeInsets.symmetric(
                                        horizontal: 3,
                                        vertical: 0.5,
                                      )
                                    : EdgeInsets.zero,
                                decoration: isMung1OrRam
                                    ? BoxDecoration(
                                        color: isSelected
                                            ? const Color(0xFFFFD54F)
                                            : const Color(0xFFC62828),
                                        borderRadius: BorderRadius.circular(3),
                                      )
                                    : null,
                                child: Text(
                                  lunarText,
                                  maxLines: 1,
                                  softWrap: false,
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    height: 1.05,
                                    fontWeight: isMung1OrRam
                                        ? FontWeight.w800
                                        : FontWeight.w600,
                                    color: isMung1OrRam
                                        ? (isSelected
                                              ? const Color(0xFF8E0000)
                                              : Colors.white)
                                        : (isSelected
                                              ? const Color(0xFFFFE082)
                                              : const Color(0xFF6D4C41)),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 12),

            // ================= CHÚ THÍCH CÁC CHỈ BÁO =================
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 12,
              runSpacing: 6,
              children: [
                const _LegendDot(
                  color: Color(0xFFC62828),
                  label: 'Mùng 1 & Rằm',
                ),
                const _LegendDot(
                  color: Color(0xFFFFB300),
                  label: 'Hoàng Đạo',
                ),
                _LegendDot(
                  color: EventCategory.getColor(EventCategory.gioChap),
                  label: 'Giỗ chạp',
                ),
                _LegendDot(
                  color: EventCategory.getColor(EventCategory.sinhNhat),
                  label: 'Sinh nhật',
                ),
                _LegendDot(
                  color: EventCategory.getColor(EventCategory.congViec),
                  label: 'Công việc',
                ),
                Text(
                  'Lưới ${rowCount == 5 ? "7x5" : "7x6"}',
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF8D6E63),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Hiển thị hàng chấm chỉ báo (Dot indicators) hoặc Badge số lượng trên mỗi ô ngày
  Widget _buildEventIndicators(List<CalendarEvent> events, bool isSelected) {
    if (events.isEmpty) {
      return const SizedBox(height: 5);
    }

    if (events.length <= 3) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: events.map((e) {
          final dotColor = EventCategory.getColor(e.category);
          return Container(
            width: 5,
            height: 5,
            margin: const EdgeInsets.symmetric(horizontal: 1),
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
              border: isSelected
                  ? Border.all(color: Colors.white, width: 0.6)
                  : null,
            ),
          );
        }).toList(),
      );
    } else {
      // Khi > 3 sự kiện: Hiển thị 2 chấm màu đầu tiên kèm badge số lượng còn lại (+N)
      final firstTwo = events.take(2).toList();
      final extraCount = events.length - 2;

      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          ...firstTwo.map((e) {
            final dotColor = EventCategory.getColor(e.category);
            return Container(
              width: 4.5,
              height: 4.5,
              margin: const EdgeInsets.symmetric(horizontal: 0.8),
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
                border: isSelected
                    ? Border.all(color: Colors.white, width: 0.6)
                    : null,
              ),
            );
          }),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 2.5, vertical: 0.5),
            margin: const EdgeInsets.only(left: 1),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFFFFD54F)
                  : const Color(0xFFA61C1C),
              borderRadius: BorderRadius.circular(3),
            ),
            child: Text(
              '+$extraCount',
              style: TextStyle(
                fontSize: 7.5,
                fontWeight: FontWeight.w900,
                height: 1.0,
                color: isSelected
                    ? const Color(0xFF8E0000)
                    : Colors.white,
              ),
            ),
          ),
        ],
      );
    }
  }

  /// Card tóm tắt chi tiết ngày được chọn + Danh sách các sự kiện/ghi chú diễn ra trong ngày
  Widget _buildDayDetailAndEventsCard(
    BuildContext context,
    List<CalendarEvent> dayEvents,
  ) {
    final dayInfo = DayInfo.fromSolarDate(selectedDate);

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: const Color(0xFFFFFDF8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(
          color: const Color(0xFFD4AF37).withValues(alpha: 0.6),
          width: 1.4,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ================= BANNER THÔNG TIN NGÀY =================
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8EC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: const Color(0xFFD4AF37).withValues(alpha: 0.6),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFA61C1C),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          selectedDate.day.toString().padLeft(2, '0'),
                          style: const TextStyle(
                            color: Color(0xFFFFD54F),
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${dayInfo.weekdayLabel}, ${selectedDate.day.toString().padLeft(2, '0')}/${selectedDate.month.toString().padLeft(2, '0')}/${selectedDate.year}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14.5,
                                color: Color(0xFF8E0000),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Âm lịch: ${dayInfo.lunarDate.day}/${dayInfo.lunarDate.month}${dayInfo.lunarDate.isLeap ? " (Nhuận)" : ""}/${dayInfo.lunarDate.year} (${dayInfo.yearCanChi})',
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF4A2511),
                              ),
                            ),
                            Text(
                              'Ngày ${dayInfo.dayCanChi} • Trực ${dayInfo.truc.name} (${dayInfo.isHoangDao ? "Hoàng Đạo" : "Hắc Đạo"})',
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: Color(0xFF6D4C41),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // ================= TIÊU ĐỀ PHẦN GHI CHÚ & NÚT THÊM =================
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.event_note_rounded,
                        color: Color(0xFFA61C1C),
                        size: 20,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Sự Kiện & Ghi Chú (${dayEvents.length})',
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF4A2511),
                        ),
                      ),
                    ],
                  ),
                ),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: FilledButton.tonalIcon(
                    onPressed: () => AddEventDialog.show(
                      context,
                      initialDate: selectedDate,
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFFFF3CD),
                      foregroundColor: const Color(0xFF8E0000),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      visualDensity: VisualDensity.compact,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: const Icon(Icons.add_rounded, size: 17),
                    label: const Text(
                      'Thêm ghi chú',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // ================= DANH SÁCH CÁC SỰ KIỆN TRONG NGÀY =================
            if (dayEvents.isEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8EC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: const Color(0xFFD4AF37).withValues(alpha: 0.35),
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.event_available_rounded,
                      size: 36,
                      color: const Color(0xFFD4AF37).withValues(alpha: 0.8),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Chưa có sự kiện nào trong ngày này.',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF5D4037),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Chạm "Thêm ghi chú" để lưu ngày Giỗ chạp, Sinh nhật hoặc Công việc.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 11.5, color: Color(0xFF795548)),
                    ),
                  ],
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: dayEvents.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final event = dayEvents[index];
                  final catColor = EventCategory.getColor(event.category);
                  final catIcon = EventCategory.getIcon(event.category);

                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: catColor.withValues(alpha: 0.35),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: catColor.withValues(alpha: 0.06),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: catColor.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(catIcon, color: catColor, size: 18),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 1.5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: catColor.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      event.category,
                                      style: TextStyle(
                                        color: catColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                  if (event.isLunarRecurring) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 1.5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFFF3CD),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Text(
                                        'Lặp Âm lịch',
                                        style: TextStyle(
                                          color: Color(0xFFE65100),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 10.5,
                                        ),
                                      ),
                                    ),
                                  ] else if (event.isSolarRecurring) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 1.5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE3F2FD),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Text(
                                        'Lặp Dương lịch',
                                        style: TextStyle(
                                          color: Color(0xFF1976D2),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 10.5,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                event.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Color(0xFF2D1E17),
                                ),
                              ),
                              if (event.note.isNotEmpty) ...[
                                const SizedBox(height: 3),
                                Text(
                                  event.note,
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    color: Color(0xFF5D4037),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        // Nút Sửa & Xóa
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, size: 18),
                              color: const Color(0xFF6D4C41),
                              visualDensity: VisualDensity.compact,
                              tooltip: 'Sửa',
                              onPressed: () => AddEventDialog.show(
                                context,
                                initialDate: selectedDate,
                                existing: event,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, size: 18),
                              color: Colors.redAccent,
                              visualDensity: VisualDensity.compact,
                              tooltip: 'Xóa',
                              onPressed: () => EventRepository.instance.deleteEvent(event.id),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(fontSize: 11.5, color: Color(0xFF5D4037)),
        ),
      ],
    );
  }
}
