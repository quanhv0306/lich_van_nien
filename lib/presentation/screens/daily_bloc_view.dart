import 'package:flutter/material.dart';
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
    _pageController = PageController(initialPage: _initialPage);
  }

  @override
  void didUpdateWidget(covariant DailyBlocView oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newTarget = _normalize(widget.selectedDate);
    final targetPage = _pageForDate(newTarget);
    if (targetPage != _currentPage && _pageController.hasClients) {
      final distance = (targetPage - _currentPage).abs();
      _currentPage = targetPage;
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
        _pageController.jumpToPage(targetPage);
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
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
