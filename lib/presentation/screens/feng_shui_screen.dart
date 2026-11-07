import 'package:flutter/material.dart';
import '../../core/lunar_calculator.dart';
import '../../data/models/day_info.dart';

/// 2. Trang Phong Thủy:
/// - Bảng việc nên làm và kiêng cữ theo Trực của ngày (kèm bảng tham khảo 12 Trực).
/// - Bảng tra giờ xuất hành Lý Thuần Phong theo 12 khung giờ trong ngày hiện tại.
/// - Công cụ quy đổi ngày Âm - Dương 2 chiều & Hướng xuất hành.
class FengShuiScreen extends StatefulWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateChanged;

  const FengShuiScreen({
    super.key,
    required this.selectedDate,
    required this.onDateChanged,
  });

  @override
  State<FengShuiScreen> createState() => _FengShuiScreenState();
}

class _FengShuiScreenState extends State<FengShuiScreen> {
  late int _lunarDay;
  late int _lunarMonth;
  late int _lunarYear;
  bool _isLeapMonth = false;

  @override
  void initState() {
    super.initState();
    _syncFromSolar(widget.selectedDate);
  }

  @override
  void didUpdateWidget(covariant FengShuiScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedDate != widget.selectedDate) {
      _syncFromSolar(widget.selectedDate);
    }
  }

  void _syncFromSolar(DateTime date) {
    final lunar = LunarCalculator.solarToLunar(date.day, date.month, date.year);
    _lunarDay = lunar.day;
    _lunarMonth = lunar.month;
    _lunarYear = lunar.year;
    _isLeapMonth = lunar.isLeap;
  }

  void _convertLunarToSolar() {
    final solar = LunarCalculator.lunarToSolar(
      _lunarDay,
      _lunarMonth,
      _lunarYear,
      _isLeapMonth,
    );
    if (solar.year == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Tháng $_lunarMonth năm $_lunarYear không phải là tháng nhuận!',
          ),
        ),
      );
      return;
    }
    widget.onDateChanged(DateTime(solar.year, solar.month, solar.day));
  }

  @override
  Widget build(BuildContext context) {
    final info = DayInfo.fromSolarDate(widget.selectedDate);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 920),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ================= 1. BẢNG VIỆC NÊN LÀM VÀ KIÊNG CỮ THEO TRỰC CỦA NGÀY =================
              Card(
                elevation: 0,
                color: const Color(0xFFFFFDF7),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: const Color(0xFFD4AF37).withValues(alpha: 0.55),
                    width: 1.4,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFA61C1C),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.gavel_rounded,
                              color: Color(0xFFFFD54F),
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  ' Bảng Việc Nên Làm & Kiêng Cữ • Trực ${info.truc.name}',
                                  style: const TextStyle(
                                    fontSize: 16.5,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF8E0000),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Ngày ${info.dayCanChi} (${info.solarDate.day.toString().padLeft(2, '0')}/${info.solarDate.month.toString().padLeft(2, '0')}/${info.solarDate.year}) • Sao ${info.nhiThapBatTu.name} (${info.nhiThapBatTu.type})',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF5D4037),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Hai cột/khung: Việc Nên Làm (Cát) & Việc Kiêng Cữ (Hung)
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isWide = constraints.maxWidth >= 560;
                          final goodBox = _TrucActionBox(
                            title: 'VIỆC NÊN LÀM (NGHI)',
                            content: info.truc.good,
                            extraNote:
                                'Sao ${info.nhiThapBatTu.name}: ${info.nhiThapBatTu.meaning}',
                            icon: Icons.check_circle_rounded,
                            accentColor: const Color(0xFF2E7D32),
                            bgColor: const Color(0xFFE8F5E9),
                          );
                          final badBox = _TrucActionBox(
                            title: 'VIỆC KIÊNG CỮ (KỴ)',
                            content: info.truc.bad,
                            extraNote:
                                'Hướng Hắc Thần nên tránh: ${info.departureDirection.hacThan}',
                            icon: Icons.cancel_rounded,
                            accentColor: const Color(0xFFC62828),
                            bgColor: const Color(0xFFFFEBEE),
                          );

                          if (isWide) {
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(child: goodBox),
                                const SizedBox(width: 12),
                                Expanded(child: badBox),
                              ],
                            );
                          }
                          return Column(
                            children: [
                              goodBox,
                              const SizedBox(height: 10),
                              badBox,
                            ],
                          );
                        },
                      ),

                      const SizedBox(height: 12),

                      // Hướng xuất hành trong ngày
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF8E1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFFD4AF37).withValues(alpha: 0.6),
                          ),
                        ),
                        child: Wrap(
                          spacing: 20,
                          runSpacing: 6,
                          children: [
                            _DirectionTag(
                              label: 'Hướng Hỷ Thần (May mắn)',
                              value: info.departureDirection.hyThan,
                              color: const Color(0xFFB71C1C),
                            ),
                            _DirectionTag(
                              label: 'Hướng Tài Thần (Tài lộc)',
                              value: info.departureDirection.taiThan,
                              color: const Color(0xFF1B5E20),
                            ),
                            _DirectionTag(
                              label: 'Tiết khí',
                              value: info.solarTerm,
                              color: const Color(0xFF4E342E),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // ================= 2. BẢNG TRA GIỜ XUẤT HÀNH LÝ THUẦN PHONG (12 KHUNG GIỜ) =================
              Card(
                elevation: 0,
                color: const Color(0xFFFFFDF7),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: const Color(0xFFD4AF37).withValues(alpha: 0.55),
                    width: 1.4,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.schedule_send_rounded,
                            color: Color(0xFFA61C1C),
                            size: 24,
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Bảng Tra Giờ Xuất Hành Lý Thuần Phong (12 Canh Giờ)',
                              style: TextStyle(
                                fontSize: 16.5,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF8E0000),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Áp dụng cho ngày Âm lịch ${info.lunarDate.day}/${info.lunarDate.month}/${info.lunarDate.year} (${info.dayCanChi})',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF5D4037),
                        ),
                      ),
                      const SizedBox(height: 14),

                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: info.lyThuanPhongHours.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final item = info.lyThuanPhongHours[index];
                          return Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: item.isGood
                                  ? const Color(0xFFFFFBF0)
                                  : Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: item.isGood
                                    ? const Color(0xFFD4AF37)
                                    : Colors.grey.shade300,
                                width: item.isGood ? 1.3 : 1.0,
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Khung Giờ Chi & Khoảng thời gian
                                Container(
                                  width: 112,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: item.isGood
                                        ? const Color(0xFFA61C1C)
                                        : const Color(0xFF5D4037),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Column(
                                    children: [
                                      Text(
                                        'Giờ ${item.chi}',
                                        style: const TextStyle(
                                          color: Color(0xFFFFD54F),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13.5,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        item.timeRange,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),

                                // Tên cung Lý Thuần Phong + Luận giải
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            item.name,
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w800,
                                              color: item.isGood
                                                  ? const Color(0xFF1B5E20)
                                                  : const Color(0xFFB71C1C),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: item.isGood
                                                  ? const Color(0xFFE8F5E9)
                                                  : const Color(0xFFFFEBEE),
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            child: Text(
                                              item.isGood
                                                  ? 'Giờ Tốt (Cát)'
                                                  : 'Giờ Xấu (Hung)',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: item.isGood
                                                    ? const Color(0xFF2E7D32)
                                                    : const Color(0xFFC62828),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        item.description,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          height: 1.35,
                                          color: Color(0xFF3E2723),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // ================= 3. CÔNG CỤ QUY ĐỔI NGÀY ÂM - DƯƠNG HAI CHIỀU =================
              Card(
                elevation: 0,
                color: const Color(0xFFFFFDF7),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: const Color(0xFFD4AF37).withValues(alpha: 0.5),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.swap_horiz_rounded,
                            color: Color(0xFFA61C1C),
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Tra cứu & Quy đổi Ngày Âm - Dương (GMT+7)',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF4A2511),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          _DropdownNumber(
                            label: 'Ngày Âm',
                            value: _lunarDay,
                            items: List.generate(30, (i) => i + 1),
                            onChanged: (v) => setState(() => _lunarDay = v),
                          ),
                          _DropdownNumber(
                            label: 'Tháng Âm',
                            value: _lunarMonth,
                            items: List.generate(12, (i) => i + 1),
                            onChanged: (v) => setState(() => _lunarMonth = v),
                          ),
                          _DropdownNumber(
                            label: 'Năm Âm',
                            value: _lunarYear,
                            items: List.generate(151, (i) => 1950 + i),
                            onChanged: (v) => setState(() => _lunarYear = v),
                          ),
                          FilterChip(
                            label: const Text('Tháng nhuận'),
                            selected: _isLeapMonth,
                            onSelected: (v) => setState(() => _isLeapMonth = v),
                          ),
                          FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFFA61C1C),
                            ),
                            onPressed: _convertLunarToSolar,
                            icon: const Icon(Icons.check, size: 18),
                            label: const Text('Chuyển sang ngày này'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TrucActionBox extends StatelessWidget {
  final String title;
  final String content;
  final String extraNote;
  final IconData icon;
  final Color accentColor;
  final Color bgColor;

  const _TrucActionBox({
    required this.title,
    required this.content,
    required this.extraNote,
    required this.icon,
    required this.accentColor,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accentColor.withValues(alpha: 0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: accentColor),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: accentColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF2D1E17),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            extraNote,
            style: const TextStyle(
              fontSize: 12.5,
              color: Color(0xFF4E342E),
            ),
          ),
        ],
      ),
    );
  }
}

class _DirectionTag extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _DirectionTag({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(fontSize: 13, color: Color(0xFF5D4037)),
        children: [
          TextSpan(text: '$label: '),
          TextSpan(
            text: value,
            style: TextStyle(fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }
}

class _DropdownNumber extends StatelessWidget {
  final String label;
  final int value;
  final List<int> items;
  final ValueChanged<int> onChanged;

  const _DropdownNumber({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(fontSize: 12.5, color: Colors.black54),
          ),
          DropdownButton<int>(
            value: items.contains(value) ? value : items.first,
            underline: const SizedBox.shrink(),
            items: items
                .map(
                  (e) => DropdownMenuItem<int>(
                    value: e,
                    child: Text(
                      '$e',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                )
                .toList(),
            onChanged: (v) {
              if (v != null) onChanged(v);
            },
          ),
        ],
      ),
    );
  }
}
