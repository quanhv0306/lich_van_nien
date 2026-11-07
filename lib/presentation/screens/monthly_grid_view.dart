import 'package:flutter/material.dart';
import '../../data/models/day_info.dart';

/// Lưới lịch tháng 7x5 hoặc 7x6:
/// - Header: Nút chuyển tháng trước/sau, chọn nhanh Tháng và chọn nhanh Năm.
/// - Từng ô ngày: Số ngày Dương lịch ở góc trên bên trái, số ngày Âm lịch ở góc dưới bên phải.
/// - Đánh dấu màu đỏ nổi bật cho ngày Mùng 1 và Rằm (15 Âm lịch).
/// - Chạm vào ngày bất kỳ sẽ cập nhật dữ liệu hiển thị chi tiết của ngày đó.
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
    final cells = _generateMonthCells(selectedDate.year, selectedDate.month);
    final int rowCount = cells.length ~/ 7; // 5 hoặc 6 hàng (7x5 hoặc 7x6)
    final today = DateTime.now();
    const weekdays = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
    final years = List<int>.generate(201, (i) => 1900 + i);

    return Card(
      elevation: 0,
      margin: const EdgeInsets.all(16),
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
                mainAxisSpacing: 6,
                crossAxisSpacing: 6,
                childAspectRatio: 1.0,
              ),
              itemBuilder: (context, index) {
                final date = cells[index];
                if (date == null) {
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.brown.withValues(alpha: 0.03),
                      borderRadius: BorderRadius.circular(12),
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
                    borderRadius: BorderRadius.circular(12),
                    child: Ink(
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFFA61C1C)
                            : (isMung1OrRam
                                  ? const Color(0xFFFFEBEE)
                                  : (isToday
                                        ? const Color(0xFFFFF3CD)
                                        : Colors.white)),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFFFFD54F)
                              : (isMung1OrRam
                                    ? const Color(0xFFD32F2F)
                                        .withValues(alpha: 0.65)
                                    : (isToday
                                          ? const Color(0xFFD4AF37)
                                          : Colors.grey.shade200)),
                          width: (isSelected || isToday || isMung1OrRam)
                              ? 1.5
                              : 1.0,
                        ),
                      ),
                      padding: const EdgeInsets.all(6),
                      child: Stack(
                        children: [
                          // Góc trên bên trái: Số ngày Dương lịch
                          Align(
                            alignment: Alignment.topLeft,
                            child: Text(
                              '${date.day}',
                              style: TextStyle(
                                fontSize: 15,
                                height: 1.05,
                                fontWeight: FontWeight.w800,
                                color: solarTextColor,
                              ),
                            ),
                          ),

                          // Góc trên bên phải: Chấm nhỏ báo ngày Hoàng Đạo
                          if (info.isHoangDao)
                            Align(
                              alignment: Alignment.topRight,
                              child: Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isSelected
                                      ? const Color(0xFFFFD54F)
                                      : const Color(0xFFFFB300),
                                ),
                              ),
                            ),

                          // Góc dưới bên phải: Số ngày Âm lịch (đánh dấu đỏ cho Mùng 1 & Rằm)
                          Align(
                            alignment: Alignment.bottomRight,
                            child: Container(
                              padding: isMung1OrRam
                                  ? const EdgeInsets.symmetric(
                                      horizontal: 4,
                                      vertical: 1,
                                    )
                                  : EdgeInsets.zero,
                              decoration: isMung1OrRam
                                  ? BoxDecoration(
                                      color: isSelected
                                          ? const Color(0xFFFFD54F)
                                          : const Color(0xFFC62828),
                                      borderRadius: BorderRadius.circular(6),
                                    )
                                  : null,
                              child: Text(
                                lunarText,
                                style: TextStyle(
                                  fontSize: 10.5,
                                  height: 1.1,
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
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 12),

            // ================= CHÚ THÍCH =================
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 16,
              runSpacing: 6,
              children: [
                const _LegendDot(
                  color: Color(0xFFC62828),
                  label: 'Mùng 1 & Rằm (15 ÂL)',
                ),
                const _LegendDot(
                  color: Color(0xFFFFB300),
                  label: 'Ngày Hoàng Đạo',
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
          width: 9,
          height: 9,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Color(0xFF5D4037)),
        ),
      ],
    );
  }
}
