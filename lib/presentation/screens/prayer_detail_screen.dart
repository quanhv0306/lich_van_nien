import 'package:flutter/material.dart';
import '../../core/sync_engine.dart';
import '../../data/models/prayer_model.dart';

/// Màn hình / Khung chi tiết bài Văn Khấn (`lib/presentation/screens/prayer_detail_screen.dart`):
/// - Tự động đọc `fullName` và `address` từ Hồ sơ Gia chủ Local-First (`SyncEngine.instance.profile`).
/// - Khi mở bất kỳ bài văn khấn nào, tự động tìm và thay thế:
///   + `[Họ tên]` hoặc `[Tín chủ]` -> `fullName` của người dùng (nếu đã lưu).
///   + `[Địa chỉ]` -> `address` của người dùng (nếu đã lưu).
///   + Nếu người dùng chưa lưu tên/địa chỉ, giữ nguyên dạng ngoặc vuông `[Họ tên]`, `[Tín chủ]`, `[Địa chỉ]`.
class PrayerDetailScreen extends StatelessWidget {
  final PrayerModel prayer;
  final double fontSize;
  final String userName;
  final String userAddress;
  final ValueChanged<double> onFontSizeChanged;
  final VoidCallback onEditUserInfo;
  final ScrollController? scrollController;

  const PrayerDetailScreen({
    super.key,
    required this.prayer,
    required this.fontSize,
    required this.userName,
    required this.userAddress,
    required this.onFontSizeChanged,
    required this.onEditUserInfo,
    this.scrollController,
  });

  /// Hàm chuẩn hóa nội dung văn khấn:
  /// Thay thế `[Họ tên]`, `[Tín chủ]` bằng `fullName` và `[Địa chỉ]` bằng `address`.
  /// Nếu chưa lưu (`isEmpty`), giữ nguyên dấu ngoặc vuông để gia chủ tự đọc.
  static String formatPrayerContent({
    required String rawContent,
    required String fullName,
    required String address,
  }) {
    String text = rawContent;
    final cleanName = fullName.trim();
    final cleanAddress = address.trim();

    if (cleanName.isNotEmpty) {
      text = text
          .replaceAll('[Họ tên]', cleanName)
          .replaceAll('[Tín chủ]', cleanName);
    }
    if (cleanAddress.isNotEmpty) {
      text = text.replaceAll('[Địa chỉ]', cleanAddress);
    }
    return text;
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: SyncEngine.instance,
      builder: (context, _) {
        final syncedProfile = SyncEngine.instance.profile;
        final effectiveName = syncedProfile.fullName.trim().isNotEmpty
            ? syncedProfile.fullName.trim()
            : userName.trim();
        final effectiveAddress = syncedProfile.address.trim().isNotEmpty
            ? syncedProfile.address.trim()
            : userAddress.trim();

        final formattedText = formatPrayerContent(
          rawContent: prayer.content,
          fullName: effectiveName,
          address: effectiveAddress,
        );

        return ListView(
          controller: scrollController,
          padding: const EdgeInsets.all(20),
          children: [
            // Thanh công cụ điều chỉnh cỡ chữ & Điền tên/địa chỉ
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3CD),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFD4AF37)),
              ),
              child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 6,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.format_size_rounded,
                        size: 18,
                        color: Color(0xFF8E0000),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Cỡ chữ: ${fontSize.toInt()}pt',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13.5,
                          color: Color(0xFF4A2511),
                        ),
                      ),
                    ],
                  ),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      OutlinedButton.icon(
                        onPressed: onEditUserInfo,
                        style: OutlinedButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          foregroundColor: const Color(0xFF4A2511),
                        ),
                        icon: const Icon(Icons.edit_rounded, size: 15),
                        label: const Text('Điền Tên/Địa chỉ'),
                      ),
                      OutlinedButton.icon(
                        onPressed: fontSize > 14
                            ? () => onFontSizeChanged(fontSize - 2.0)
                            : null,
                        style: OutlinedButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          foregroundColor: const Color(0xFF8E0000),
                        ),
                        icon: const Icon(Icons.text_decrease_rounded, size: 16),
                        label: const Text('Chữ nhỏ'),
                      ),
                      FilledButton.icon(
                        onPressed: fontSize < 32
                            ? () => onFontSizeChanged(fontSize + 2.0)
                            : null,
                        style: FilledButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          backgroundColor: const Color(0xFFA61C1C),
                        ),
                        icon: const Icon(Icons.text_increase_rounded, size: 16),
                        label: const Text('Chữ to'),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Danh mục & Tiêu đề bài khấn
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFA61C1C),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  prayer.category,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFFD54F),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              prayer.title,
              style: const TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w900,
                color: Color(0xFF4A2511),
              ),
            ),

            const SizedBox(height: 12),

            // Ý nghĩa ngày lễ (`meaning`), Thời gian cúng tốt nhất (`best_time`) & Lễ vật (`offerings`)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFDF6E4),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: const Color(0xFFD4AF37).withValues(alpha: 0.45),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        size: 18,
                        color: Color(0xFFA61C1C),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            style: const TextStyle(
                              fontSize: 13.5,
                              height: 1.4,
                              color: Color(0xFF2D1E17),
                            ),
                            children: [
                              const TextSpan(
                                text: 'Ý nghĩa nghi lễ: ',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF8E0000),
                                ),
                              ),
                              TextSpan(text: prayer.meaning),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.access_time_filled_rounded,
                        size: 18,
                        color: Color(0xFF2E7D32),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            style: const TextStyle(
                              fontSize: 13.5,
                              height: 1.4,
                              color: Color(0xFF2D1E17),
                            ),
                            children: [
                              const TextSpan(
                                text: 'Thời gian cúng thích hợp: ',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1B5E20),
                                ),
                              ),
                              TextSpan(text: prayer.bestTime),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.auto_awesome,
                        size: 18,
                        color: Color(0xFFB7791F),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            style: const TextStyle(
                              fontSize: 13.5,
                              height: 1.4,
                              color: Color(0xFF2D1E17),
                            ),
                            children: [
                              const TextSpan(
                                text: 'Sắm lễ vật tham khảo: ',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF4A2511),
                                ),
                              ),
                              TextSpan(text: prayer.offerings),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'LỜI VĂN KHẤN CỔ TRUYỀN',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.1,
                      color: Color(0xFFA61C1C),
                    ),
                  ),
                ),
                if (effectiveName.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      'Tín chủ: $effectiveName',
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2E7D32),
                      ),
                    ),
                  ),
              ],
            ),
            const Divider(height: 16),
            SelectableText(
              formattedText,
              style: TextStyle(
                fontSize: fontSize,
                height: 1.75,
                color: const Color(0xFF2D1E17),
              ),
            ),
          ],
        );
      },
    );
  }
}
