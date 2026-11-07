import 'package:flutter/material.dart';
import '../../data/models/day_info.dart';

/// Tờ lịch Bloc Đỏ / Vàng phong cách hiện đại:
/// - Phía trên: Thứ, Tháng/Năm Dương lịch.
/// - Trung tâm: Số ngày Dương lịch kích thước lớn; ngay dưới là Ngày/Tháng Âm lịch rõ nét kèm Can Chi ngày.
/// - Phía dưới: Danh sách giờ Hoàng đạo (dạng Chip), Tiết khí hiện tại, Đánh giá ngày (Hoàng đạo/Hắc đạo).
class BlocCard extends StatelessWidget {
  final DayInfo dayInfo;
  final VoidCallback? onPreviousDay;
  final VoidCallback? onNextDay;
  final VoidCallback? onPickDate;

  const BlocCard({
    super.key,
    required this.dayInfo,
    this.onPreviousDay,
    this.onNextDay,
    this.onPickDate,
  });

  @override
  Widget build(BuildContext context) {
    final isSunday = dayInfo.solarDate.weekday == DateTime.sunday;
    final isSaturday = dayInfo.solarDate.weekday == DateTime.saturday;

    final Color solarDayColor = isSunday
        ? const Color(0xFFB71C1C)
        : (isSaturday ? const Color(0xFF0D47A1) : const Color(0xFF8B1A1A));

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFFFFDF7),
            Color(0xFFFFF6E0),
          ],
        ),
        border: Border.all(
          color: const Color(0xFFD4AF37),
          width: 1.8,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8B0000).withValues(alpha: 0.12),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ================= 1. PHÍA TRÊN: THỨ, THÁNG/NĂM DƯƠNG LỊCH =================
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFC62828),
                  Color(0xFF8E0000),
                ],
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
            ),
            child: Column(
              children: [
                // Hai đinh tán vàng mô phỏng khuy lịch Bloc hiện đại
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _GoldPin(),
                    _GoldPin(),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    IconButton(
                      onPressed: onPreviousDay,
                      icon: const Icon(
                        Icons.chevron_left_rounded,
                        color: Color(0xFFFFD54F),
                        size: 28,
                      ),
                      tooltip: 'Ngày trước',
                    ),
                    Expanded(
                      child: InkWell(
                        onTap: onPickDate,
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Column(
                            children: [
                              Text(
                                'THÁNG ${dayInfo.solarDate.month.toString().padLeft(2, '0')} NĂM ${dayInfo.solarDate.year}',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Color(0xFFFFE082),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13.5,
                                  letterSpacing: 1.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                dayInfo.weekdayLabel.toUpperCase(),
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 22,
                                  letterSpacing: 1.8,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: onNextDay,
                      icon: const Icon(
                        Icons.chevron_right_rounded,
                        color: Color(0xFFFFD54F),
                        size: 28,
                      ),
                      tooltip: 'Ngày sau',
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ================= 2. TRUNG TÂM: SỐ NGÀY DƯƠNG LỚN & NGÀY/THÁNG ÂM + CAN CHI =================
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Column(
              children: [
                // Số ngày Dương lịch kích thước lớn
                Text(
                  dayInfo.solarDate.day.toString().padLeft(2, '0'),
                  style: TextStyle(
                    fontSize: 100,
                    height: 1.0,
                    fontWeight: FontWeight.w900,
                    color: solarDayColor,
                    shadows: [
                      Shadow(
                        color: const Color(0xFFD4AF37).withValues(alpha: 0.35),
                        offset: const Offset(0, 5),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                // Câu danh ngôn / Ca dao ngắn gọn
                Text(
                  '“${dayInfo.quote}”',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontStyle: FontStyle.italic,
                    fontSize: 13.5,
                    color: Color(0xFF5D4037),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '— ${dayInfo.quoteAuthor} —',
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF8D6E63),
                  ),
                ),

                const SizedBox(height: 16),

                // Khối Ngày/Tháng Âm lịch rõ nét kèm Can Chi ngày (Nền Đỏ/Vàng nổi bật)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFFFFF3CD),
                        Color(0xFFFFE69C),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFFD4AF37),
                      width: 1.4,
                    ),
                  ),
                  child: Row(
                    children: [
                      // Huy hiệu Ngày/Tháng Âm lịch rõ nét
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFFC62828),
                              Color(0xFF8E0000),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFFFFD54F),
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              'ÂM LỊCH',
                              style: TextStyle(
                                color: Color(0xFFFFD54F),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.1,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${dayInfo.lunarDate.day.toString().padLeft(2, '0')}/${dayInfo.lunarDate.month.toString().padLeft(2, '0')}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            if (dayInfo.lunarDate.isLeap)
                              const Text(
                                'Tháng Nhuận',
                                style: TextStyle(
                                  color: Color(0xFFFFE082),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 14),
                      // Thông tin Can Chi Ngày, Tháng, Năm
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Ngày ${dayInfo.dayCanChi}',
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF8E0000),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Tháng ${dayInfo.monthCanChi} • Năm ${dayInfo.yearCanChi}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF4A2511),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Giờ đầu ngày: ${dayInfo.firstHourCanChi} • Trực ${dayInfo.truc.name}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF5D4037),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // ================= 3. PHÍA DƯỚI: ĐÁNH GIÁ NGÀY, TIẾT KHÍ & GIỜ HOÀNG ĐẠO (CHIP) =================
                // Hàng huy hiệu Đánh giá ngày (Hoàng đạo / Hắc đạo) & Tiết khí hiện tại
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    // Đánh giá ngày: Hoàng đạo / Hắc đạo
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: dayInfo.isHoangDao
                            ? const Color(0xFFB71C1C)
                            : const Color(0xFF4E342E),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFFFFD54F),
                          width: 1.2,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            dayInfo.isHoangDao
                                ? Icons.wb_sunny_rounded
                                : Icons.nights_stay_rounded,
                            size: 15,
                            color: const Color(0xFFFFD54F),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            dayInfo.isHoangDao
                                ? 'Ngày Hoàng Đạo (Tốt)'
                                : 'Ngày Hắc Đạo',
                            style: const TextStyle(
                              color: Color(0xFFFFD54F),
                              fontSize: 12.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Tiết khí hiện tại
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF8E1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFFD4AF37),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.eco_rounded,
                            size: 15,
                            color: Color(0xFF2E7D32),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Tiết khí: ${dayInfo.solarTerm}',
                            style: const TextStyle(
                              color: Color(0xFF3E2723),
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: Divider(height: 1, color: Color(0xFFE6C27A)),
                ),

                // Danh sách Giờ Hoàng Đạo dạng Chip
                Align(
                  alignment: Alignment.centerLeft,
                  child: Row(
                    children: [
                      const Icon(
                        Icons.access_time_filled_rounded,
                        size: 18,
                        color: Color(0xFFA61C1C),
                      ),
                      const SizedBox(width: 6),
                      const Expanded(
                        child: Text(
                          'GIỜ HOÀNG ĐẠO TRONG NGÀY',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                            color: Color(0xFF8E0000),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: dayInfo.auspiciousHours
                      .map(
                        (h) => Chip(
                          visualDensity: VisualDensity.compact,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          avatar: const Icon(
                            Icons.star_rounded,
                            size: 15,
                            color: Color(0xFFB71C1C),
                          ),
                          backgroundColor: const Color(0xFFFFF3CD),
                          side: const BorderSide(color: Color(0xFFD4AF37)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          label: Text(
                            '${h.chi} (${h.timeRange})',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF4A2511),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GoldPin extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 7,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        gradient: const LinearGradient(
          colors: [
            Color(0xFFFFE082),
            Color(0xFFD4AF37),
            Color(0xFFFFF8E1),
          ],
        ),
      ),
    );
  }
}
