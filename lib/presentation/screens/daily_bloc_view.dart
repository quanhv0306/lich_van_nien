import 'package:flutter/material.dart';
import '../../core/sync_engine.dart';
import '../../data/models/day_info.dart';
import '../widgets/bloc_card.dart';

/// Màn hình Tờ lịch Bloc ngày hỗ trợ vuốt ngang mượt mà bằng PageView
/// (không bị khựng khi chuyển ngày liên tiếp hoặc chọn ngày từ lịch tháng/bộ chọn ngày).
class DailyBlocView extends StatefulWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateChanged;

  const DailyBlocView({
    super.key,
    required this.selectedDate,
    required this.onDateChanged,
  });

  @override
  State<DailyBlocView> createState() => _DailyBlocViewState();
}

class _DailyBlocViewState extends State<DailyBlocView> {
  static const int _initialPage = 50000;
  late final DateTime _anchorDate;
  late final PageController _pageController;
  int _currentPage = _initialPage;
  bool _isAnimatingProgrammatically = false;

  @override
  void initState() {
    super.initState();
    _anchorDate = _normalize(widget.selectedDate);
    _currentPage = _initialPage;
    _pageController = PageController(initialPage: _currentPage);
  }

  @override
  void didUpdateWidget(covariant DailyBlocView oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newTarget = _normalize(widget.selectedDate);
    final targetPage = _pageForDate(newTarget);
    if (targetPage != _currentPage) {
      final distance = (targetPage - _currentPage).abs();
      _currentPage = targetPage;
      if (_pageController.hasClients) {
        if (distance == 1) {
          _isAnimatingProgrammatically = true;
          _pageController
              .animateToPage(
                targetPage,
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutCubic,
              )
              .whenComplete(() {
                _isAnimatingProgrammatically = false;
              });
        } else {
          _isAnimatingProgrammatically = true;
          _pageController.jumpToPage(targetPage);
          _isAnimatingProgrammatically = false;
        }
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  DateTime _normalize(DateTime d) => DateTime.utc(d.year, d.month, d.day);

  DateTime _dateForPage(int page) {
    final shifted = _anchorDate.add(Duration(days: page - _initialPage));
    return DateTime(shifted.year, shifted.month, shifted.day);
  }

  int _pageForDate(DateTime date) {
    final normalized = _normalize(date);
    return _initialPage + normalized.difference(_anchorDate).inDays;
  }

  Future<void> _pickDate(BuildContext context, DateTime currentDate) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: currentDate,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      widget.onDateChanged(picked);
    }
  }

  void _stepDay(int deltaDays) {
    final targetDate = _dateForPage(_currentPage + deltaDays);
    widget.onDateChanged(targetDate);
  }

  Future<void> _showEventDialog(
    BuildContext context,
    DateTime pageDate, {
    CalendarEvent? existing,
  }) async {
    final titleCtrl = TextEditingController(text: existing?.title ?? '');
    final noteCtrl = TextEditingController(text: existing?.note ?? '');

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFFFFFDF7),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFFD4AF37)),
        ),
        title: Text(
          existing == null
              ? 'Ghi chú ngày ${pageDate.day.toString().padLeft(2, '0')}/${pageDate.month.toString().padLeft(2, '0')}/${pageDate.year}'
              : 'Sửa ghi chú',
          style: const TextStyle(
            fontSize: 16.5,
            fontWeight: FontWeight.bold,
            color: Color(0xFF8E0000),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Tiêu đề sự kiện / ghi chú *',
                hintText: 'VD: Giỗ tổ, Cúng Rằm, Lịch hẹn...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: noteCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Chi tiết ghi chú',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Hủy'),
          ),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFA61C1C),
              foregroundColor: const Color(0xFFFFD54F),
            ),
            onPressed: () {
              final title = titleCtrl.text.trim();
              if (title.isEmpty) return;
              // Ghi trực tiếp vào Local Storage (0ms) và kích hoạt Sync ngầm
              SyncEngine.instance.upsertEventLocalFirst(
                id: existing?.id,
                title: title,
                note: noteCtrl.text.trim(),
                solarDate: pageDate,
              );
              Navigator.of(dialogContext).pop();
            },
            icon: const Icon(Icons.save_rounded, size: 18),
            label: const Text('Lưu ngay'),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyEventsCard(BuildContext context, DateTime pageDate) {
    return ListenableBuilder(
      listenable: SyncEngine.instance,
      builder: (context, _) {
        final dayEvents = SyncEngine.instance.eventsForDate(pageDate);

        return Card(
          elevation: 0,
          color: const Color(0xFFFFFDF7),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: const Color(0xFFD4AF37).withValues(alpha: 0.45),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.event_note_rounded,
                      color: Color(0xFFA61C1C),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Ghi Chú & Sự Kiện Ngày (${dayEvents.length})',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF4A2511),
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => _showEventDialog(context, pageDate),
                      icon: const Icon(Icons.add_circle_outline, size: 17),
                      label: const Text('Thêm'),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFFA61C1C),
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ],
                ),
                if (dayEvents.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Text(
                      'Chưa có sự kiện nào trong ngày này. Bấm "Thêm" để lưu ghi chú cá nhân (tự động đồng bộ đa thiết bị).',
                      style: TextStyle(fontSize: 12.5, color: Color(0xFF795548)),
                    ),
                  )
                else
                  ...dayEvents.map(
                    (evt) => Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF8EC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFFD4AF37).withValues(alpha: 0.4),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  evt.title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13.5,
                                    color: Color(0xFF2D1E17),
                                  ),
                                ),
                                if (evt.note.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    evt.note,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF5D4037),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            icon: const Icon(
                              Icons.edit_outlined,
                              size: 18,
                              color: Color(0xFF5D4037),
                            ),
                            onPressed: () => _showEventDialog(
                              context,
                              pageDate,
                              existing: evt,
                            ),
                          ),
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            icon: const Icon(
                              Icons.delete_outline_rounded,
                              size: 18,
                              color: Colors.redAccent,
                            ),
                            onPressed: () =>
                                SyncEngine.instance.deleteEventLocalFirst(evt.id),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      controller: _pageController,
      physics: const BouncingScrollPhysics(),
      onPageChanged: (page) {
        _currentPage = page;
        if (!_isAnimatingProgrammatically) {
          widget.onDateChanged(_dateForPage(page));
        }
      },
      itemBuilder: (context, index) {
        final pageDate = _dateForPage(index);
        final dayInfo = DayInfo.fromSolarDate(pageDate);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  BlocCard(
                    dayInfo: dayInfo,
                    onPreviousDay: () => _stepDay(-1),
                    onNextDay: () => _stepDay(1),
                    onPickDate: () => _pickDate(context, pageDate),
                  ),
                  const SizedBox(height: 14),

                  // Khung gợi ý Việc nên làm / Kiêng kỵ trong ngày
                  Card(
                    elevation: 0,
                    color: const Color(0xFFFFFDF7),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: const Color(0xFFD4AF37).withValues(alpha: 0.45),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.compass_calibration_rounded,
                                color: Color(0xFFA61C1C),
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Trực ${dayInfo.truc.name} • Sao ${dayInfo.nhiThapBatTu.name} (${dayInfo.nhiThapBatTu.type})',
                                  style: const TextStyle(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF4A2511),
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
                                Icons.check_circle_outline,
                                color: Colors.green,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Nên làm: ${dayInfo.truc.good}',
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.remove_circle_outline,
                                color: Colors.redAccent,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Kiêng kỵ: ${dayInfo.truc.bad}',
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _buildDailyEventsCard(context, pageDate),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
