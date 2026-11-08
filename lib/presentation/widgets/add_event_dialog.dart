import 'package:flutter/material.dart';
import '../../core/lunar_calculator.dart';
import '../../core/sync_engine.dart';
import '../../data/repositories/event_repository.dart';

/// Hộp thoại thêm mới hoặc chỉnh sửa Sự Kiện / Ghi Chú (`AddEventDialog`)
/// - Tự động điền ngày đang được chọn làm ngày mặc định (không bắt người dùng chọn lại bằng tay).
/// - Hiển thị song song ngày Dương lịch và ngày Âm lịch tương ứng.
/// - Cho phép chọn thể loại: Giỗ chạp, Sinh nhật, Công việc, Khác.
/// - Tùy chọn lặp lại: Không lặp, Lặp hàng năm theo Âm lịch, Lặp hàng năm theo Dương lịch.
class AddEventDialog extends StatefulWidget {
  final DateTime initialDate;
  final CalendarEvent? existing;

  const AddEventDialog({
    super.key,
    required this.initialDate,
    this.existing,
  });

  /// Phương thức tĩnh tiện lợi để hiển thị hộp thoại
  static Future<void> show(
    BuildContext context, {
    required DateTime initialDate,
    CalendarEvent? existing,
  }) {
    return showDialog<void>(
      context: context,
      builder: (context) => AddEventDialog(
        initialDate: initialDate,
        existing: existing,
      ),
    );
  }

  @override
  State<AddEventDialog> createState() => _AddEventDialogState();
}

class _AddEventDialogState extends State<AddEventDialog> {
  late final TextEditingController _titleController;
  late final TextEditingController _noteController;
  late DateTime _chosenDate;
  late String _selectedCategory;
  late int _repeatMode; // 0: Không lặp | 1: Lặp Âm lịch hàng năm | 2: Lặp Dương lịch hàng năm

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _titleController = TextEditingController(text: existing?.title ?? '');
    _noteController = TextEditingController(text: existing?.note ?? '');

    if (existing != null) {
      _chosenDate = DateTime.tryParse(existing.solarDateKey) ?? widget.initialDate;
      _selectedCategory = existing.category;
      if (existing.isLunarRecurring) {
        _repeatMode = 1;
      } else if (existing.isSolarRecurring) {
        _repeatMode = 2;
      } else {
        _repeatMode = 0;
      }
    } else {
      _chosenDate = widget.initialDate;
      _selectedCategory = EventCategory.congViec;
      _repeatMode = 0;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    try {
      final picked = await showDatePicker(
        context: context,
        initialDate: _chosenDate,
        firstDate: DateTime(1900),
        lastDate: DateTime(2100),
        helpText: 'CHỌN NGÀY SỰ KIỆN',
        cancelText: 'HỦY',
        confirmText: 'CHỌN',
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.light(
                primary: Color(0xFFA61C1C), // Nền tiêu đề lịch & ngày được chọn
                onPrimary: Color(0xFFFFD54F), // Màu chữ ngày được chọn
                surface: Color(0xFFFFFDF8), // Nền hộp thoại
                onSurface: Color(0xFF2D1E17), // Màu chữ các ngày
              ),
              textButtonTheme: TextButtonThemeData(
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFFA61C1C),
                ),
              ),
            ),
            child: child ?? const SizedBox.shrink(),
          );
        },
      );
      if (picked != null && mounted) {
        setState(() => _chosenDate = picked);
      }
    } catch (e) {
      debugPrint('[AddEventDialog] Lỗi chọn ngày: $e');
    }
  }

  void _onCategorySelected(String category) {
    setState(() {
      _selectedCategory = category;
      // Thông minh: Nếu chọn Giỗ chạp, tự động gợi ý lặp hàng năm theo Âm lịch
      if (category == EventCategory.gioChap && _repeatMode == 0) {
        _repeatMode = 1;
      } else if (category == EventCategory.sinhNhat && _repeatMode == 0) {
        _repeatMode = 2;
      }
    });
  }

  void _handleSave() {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;

    final note = _noteController.text.trim();
    final isLunar = _repeatMode == 1;
    final isSolar = _repeatMode == 2;

    if (widget.existing != null) {
      EventRepository.instance.updateEvent(
        id: widget.existing!.id,
        title: title,
        note: note,
        solarDate: _chosenDate,
        category: _selectedCategory,
        isLunarRecurring: isLunar,
        isSolarRecurring: isSolar,
      );
    } else {
      EventRepository.instance.addEvent(
        title: title,
        note: note,
        solarDate: _chosenDate,
        category: _selectedCategory,
        isLunarRecurring: isLunar,
        isSolarRecurring: isSolar,
      );
    }

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existing != null;
    final lunar = LunarCalculator.solarToLunar(
      _chosenDate.day,
      _chosenDate.month,
      _chosenDate.year,
    );

    return AlertDialog(
      backgroundColor: const Color(0xFFFFFDF8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: const BorderSide(color: Color(0xFFD4AF37), width: 1.5),
      ),
      titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      actionsPadding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFA61C1C),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.event_note_rounded,
              color: Color(0xFFFFD54F),
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              isEditing ? 'Chỉnh Sửa Sự Kiện' : 'Thêm Ghi Chú & Sự Kiện',
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Color(0xFF8E0000),
              ),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. BANNER NGÀY ĐANG CHỌN (Dương & Âm lịch)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8EC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: const Color(0xFFD4AF37).withValues(alpha: 0.6),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.calendar_today_rounded,
                              size: 15,
                              color: Color(0xFFA61C1C),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Dương: ${_chosenDate.day.toString().padLeft(2, '0')}/${_chosenDate.month.toString().padLeft(2, '0')}/${_chosenDate.year}',
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2D1E17),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.nightlight_round,
                              size: 14,
                              color: Color(0xFFC62828),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Âm lịch: ${lunar.day}/${lunar.month}${lunar.isLeap ? " (Nhuận)" : ""}/${lunar.year}',
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF8E0000),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: _pickDate,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFA61C1C),
                      side: const BorderSide(color: Color(0xFFA61C1C)),
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: const Icon(Icons.edit_calendar_rounded, size: 15),
                    label: const Text('Đổi ngày', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // 2. Ô NHẬP TIÊU ĐỀ
            TextField(
              controller: _titleController,
              autofocus: !isEditing,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: 'Tiêu đề sự kiện / ghi chú *',
                hintText: 'VD: Giỗ ông nội, Sinh nhật con, Họp cơ quan...',
                prefixIcon: const Icon(Icons.edit_note_rounded, color: Color(0xFFA61C1C)),
                filled: true,
                fillColor: Colors.white,
                isDense: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 14),

            // 3. CHỌN THỂ LOẠI (Giỗ chạp, Sinh nhật, Công việc, Khác)
            const Text(
              'Thể loại sự kiện:',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.bold,
                color: Color(0xFF5D4037),
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: EventCategory.all.map((cat) {
                final isSelected = _selectedCategory == cat;
                final catColor = EventCategory.getColor(cat);
                final catIcon = EventCategory.getIcon(cat);

                return ChoiceChip(
                  avatar: Icon(
                    catIcon,
                    size: 16,
                    color: isSelected ? Colors.white : catColor,
                  ),
                  label: Text(cat),
                  selected: isSelected,
                  selectedColor: catColor,
                  backgroundColor: Colors.white,
                  side: BorderSide(
                    color: isSelected ? catColor : const Color(0xFFD4AF37).withValues(alpha: 0.6),
                  ),
                  labelStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : const Color(0xFF2D1E17),
                  ),
                  onSelected: (selected) {
                    if (selected) _onCategorySelected(cat);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 14),

            // 4. TÙY CHỌN LẶP LẠI (Không lặp | Lặp Âm lịch | Lặp Dương lịch)
            const Text(
              'Tùy chọn chu kỳ lặp lại:',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.bold,
                color: Color(0xFF5D4037),
              ),
            ),
            const SizedBox(height: 6),
            SegmentedButton<int>(
              segments: const [
                ButtonSegment<int>(
                  value: 0,
                  label: Text('Một lần', style: TextStyle(fontSize: 11.5)),
                  icon: Icon(Icons.event_busy_rounded, size: 15),
                ),
                ButtonSegment<int>(
                  value: 1,
                  label: Text('Lặp Âm lịch', style: TextStyle(fontSize: 11.5)),
                  icon: Icon(Icons.nightlight_round, size: 14),
                ),
                ButtonSegment<int>(
                  value: 2,
                  label: Text('Lặp Dương', style: TextStyle(fontSize: 11.5)),
                  icon: Icon(Icons.wb_sunny_rounded, size: 14),
                ),
              ],
              selected: {_repeatMode},
              style: SegmentedButton.styleFrom(
                selectedBackgroundColor: const Color(0xFFA61C1C),
                selectedForegroundColor: const Color(0xFFFFD54F),
                visualDensity: VisualDensity.compact,
              ),
              onSelectionChanged: (selection) {
                setState(() => _repeatMode = selection.first);
              },
            ),
            if (_repeatMode == 1) ...[
              const SizedBox(height: 6),
              Text(
                '• Sẽ tự động nhắc vào ngày ${lunar.day}/${lunar.month} Âm lịch hàng năm (chuẩn ngày Giỗ chạp).',
                style: const TextStyle(fontSize: 11.5, color: Color(0xFFE65100), fontWeight: FontWeight.w600),
              ),
            ] else if (_repeatMode == 2) ...[
              const SizedBox(height: 6),
              Text(
                '• Sẽ tự động nhắc vào ngày ${_chosenDate.day}/${_chosenDate.month} Dương lịch hàng năm (chuẩn ngày Sinh nhật).',
                style: const TextStyle(fontSize: 11.5, color: Color(0xFF1976D2), fontWeight: FontWeight.w600),
              ),
            ],
            const SizedBox(height: 14),

            // 5. Ô NHẬP NỘI DUNG CHI TIẾT
            TextField(
              controller: _noteController,
              maxLines: 2,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: 'Chi tiết ghi chú (tùy chọn)',
                hintText: 'Lễ vật cần sắm, địa chỉ, khách mời, chuẩn bị...',
                alignLabelWithHint: true,
                filled: true,
                fillColor: Colors.white,
                isDense: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Hủy'),
        ),
        FilledButton.icon(
          onPressed: _handleSave,
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFA61C1C),
            foregroundColor: const Color(0xFFFFD54F),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          icon: const Icon(Icons.check_rounded, size: 18),
          label: Text(
            isEditing ? 'Cập nhật' : 'Lưu ghi chú',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
