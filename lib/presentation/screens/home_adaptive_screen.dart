import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/responsive_layout.dart';
import 'daily_bloc_view.dart';
import 'feng_shui_screen.dart';
import 'monthly_grid_view.dart';
import 'prayers_screen.dart';

class HomeAdaptiveScreen extends StatefulWidget {
  const HomeAdaptiveScreen({super.key});

  @override
  State<HomeAdaptiveScreen> createState() => _HomeAdaptiveScreenState();
}

class _HomeAdaptiveScreenState extends State<HomeAdaptiveScreen> {
  static const String _prefMobileTabKey = 'last_mobile_tab_index';
  static const String _prefRightPaneTabKey = 'last_right_pane_tab_index';

  /// Tab trên Mobile (< 768px):
  /// 0: Lịch Ngày | 1: Lịch Tháng | 2: Văn Khấn | 3: Phong Thủy
  int _mobileTabIndex = 0;

  /// Chế độ công cụ ở cột phải (60%) trên PC/Tablet (>= 768px):
  /// 0: Lịch Tháng & Tra cứu nhanh | 1: Văn Khấn | 2: Phong Thủy & Đổi ngày
  int _rightPaneTabIndex = 0;

  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_handleKeyEvent);
    _loadSavedTabPreferences();
  }

  Future<void> _loadSavedTabPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedMobileTab = prefs.getInt(_prefMobileTabKey);
      final savedRightTab = prefs.getInt(_prefRightPaneTabKey);
      if (!mounted) return;
      setState(() {
        if (savedMobileTab != null &&
            savedMobileTab >= 0 &&
            savedMobileTab <= 3) {
          _mobileTabIndex = savedMobileTab;
        }
        if (savedRightTab != null && savedRightTab >= 0 && savedRightTab <= 2) {
          _rightPaneTabIndex = savedRightTab;
        }
      });
    } catch (_) {
      // Bỏ qua nếu môi trường chưa khởi tạo được SharedPreferences
    }
  }

  Future<void> _saveMobileTab(int index) async {
    setState(() => _mobileTabIndex = index);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_prefMobileTabKey, index);
    } catch (_) {}
  }

  Future<void> _saveRightPaneTab(int index) async {
    setState(() => _rightPaneTabIndex = index);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_prefRightPaneTabKey, index);
    } catch (_) {}
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleKeyEvent);
    super.dispose();
  }

  /// Xử lý phím tắt bàn phím:
  /// - Mũi tên Trái / Phải: Chuyển ngày trước / sau
  /// - Mũi tên Lên / Xuống: Chuyển tháng trước / sau
  /// - Phím Home: Quay về ngày hôm nay
  bool _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return false;
    }

    // Bỏ qua phím tắt khi người dùng đang gõ chữ trong ô tìm kiếm (EditableText)
    final focusedContext = FocusManager.instance.primaryFocus?.context;
    if (focusedContext != null &&
        focusedContext.findAncestorWidgetOfExactType<EditableText>() != null) {
      return false;
    }

    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.arrowLeft) {
      _stepDay(-1);
      return true;
    } else if (key == LogicalKeyboardKey.arrowRight) {
      _stepDay(1);
      return true;
    } else if (key == LogicalKeyboardKey.arrowUp) {
      _stepMonth(-1);
      return true;
    } else if (key == LogicalKeyboardKey.arrowDown) {
      _stepMonth(1);
      return true;
    } else if (key == LogicalKeyboardKey.home) {
      _updateSelectedDate(DateTime.now());
      return true;
    }
    return false;
  }

  void _updateSelectedDate(DateTime date) {
    setState(() {
      _selectedDate = DateTime(date.year, date.month, date.day);
    });
  }

  void _stepDay(int deltaDays) {
    final baseUtc = DateTime.utc(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
    ).add(Duration(days: deltaDays));
    _updateSelectedDate(DateTime(baseUtc.year, baseUtc.month, baseUtc.day));
  }

  void _stepMonth(int deltaMonths) {
    final targetFirstDay = DateTime(
      _selectedDate.year,
      _selectedDate.month + deltaMonths,
      1,
    );
    final maxDays = DateTime(
      targetFirstDay.year,
      targetFirstDay.month + 1,
      0,
    ).day;
    final clampedDay =
        _selectedDate.day > maxDays ? maxDays : _selectedDate.day;
    _updateSelectedDate(
      DateTime(targetFirstDay.year, targetFirstDay.month, clampedDay),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobile: _buildMobileScaffold(),
      desktop: _buildWideScaffold(),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFFA61C1C),
      foregroundColor: const Color(0xFFFFD54F),
      elevation: 0,
      titleSpacing: 12,
      title: const Row(
        children: [
          Icon(
            Icons.calendar_today_rounded,
            size: 19,
            color: Color(0xFFFFD54F),
          ),
          SizedBox(width: 8),
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                'LỊCH VẠN NIÊN VIỆT NAM',
                maxLines: 1,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16.5,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ),
        ],
      ),
      actions: [
        Tooltip(
          message: 'Phím tắt: ←/→ Đổi ngày • ↑/↓ Đổi tháng • Home Về hôm nay',
          child: TextButton.icon(
            onPressed: () => _updateSelectedDate(DateTime.now()),
            icon: const Icon(Icons.today, color: Color(0xFFFFD54F), size: 18),
            label: const Text(
              'Hôm nay',
              style: TextStyle(
                color: Color(0xFFFFD54F),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  /// Giao diện Mobile (< 768px): BottomNavigationBar với 4 tab
  /// (Lịch Ngày, Lịch Tháng, Văn Khấn, Phong Thủy)
  Widget _buildMobileScaffold() {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _buildMobileBody(_mobileTabIndex),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _mobileTabIndex,
        onTap: _saveMobileTab,
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFFFFFDF7),
        selectedItemColor: const Color(0xFFA61C1C),
        unselectedItemColor: const Color(0xFF795548),
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.event_note_outlined),
            activeIcon: Icon(Icons.event_note),
            label: 'Lịch Ngày',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month_outlined),
            activeIcon: Icon(Icons.calendar_month),
            label: 'Lịch Tháng',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_book_outlined),
            activeIcon: Icon(Icons.menu_book),
            label: 'Văn Khấn',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.explore_outlined),
            activeIcon: Icon(Icons.explore),
            label: 'Phong Thủy',
          ),
        ],
      ),
    );
  }

  Widget _buildMobileBody(int index) {
    switch (index) {
      case 0:
        return DailyBlocView(
          selectedDate: _selectedDate,
          onDateChanged: _updateSelectedDate,
        );
      case 1:
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              MonthlyGridView(
                selectedDate: _selectedDate,
                onDateSelected: _updateSelectedDate,
              ),
              FengShuiScreen(
                selectedDate: _selectedDate,
                onDateChanged: _updateSelectedDate,
              ),
            ],
          ),
        );
      case 2:
        return const PrayersScreen();
      case 3:
      default:
        return FengShuiScreen(
          selectedDate: _selectedDate,
          onDateChanged: _updateSelectedDate,
        );
    }
  }

  /// Giao diện PC/Tablet (>= 768px):
  /// Kết hợp NavigationRail bên trái + Bố cục 2 cột cố định:
  /// - Cột trái (40%): Tờ lịch Bloc ngày (`DailyBlocView`)
  /// - Cột phải (60%): Lịch Tháng và công cụ tra cứu (Phong Thủy / Văn Khấn)
  Widget _buildWideScaffold() {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          NavigationRail(
            selectedIndex: _rightPaneTabIndex,
            onDestinationSelected: _saveRightPaneTab,
            labelType: NavigationRailLabelType.all,
            backgroundColor: const Color(0xFFFFF8EC),
            selectedIconTheme: const IconThemeData(color: Color(0xFFA61C1C)),
            selectedLabelTextStyle: const TextStyle(
              color: Color(0xFFA61C1C),
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
            unselectedLabelTextStyle: const TextStyle(
              color: Color(0xFF5D4037),
              fontSize: 11.5,
            ),
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.calendar_month_outlined),
                selectedIcon: Icon(Icons.calendar_month),
                label: Text('Lịch Tháng'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.menu_book_outlined),
                selectedIcon: Icon(Icons.menu_book),
                label: Text('Văn Khấn'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.explore_outlined),
                selectedIcon: Icon(Icons.explore),
                label: Text('Phong Thủy'),
              ),
            ],
          ),
          const VerticalDivider(width: 1, thickness: 1),
          // Vùng hiển thị 2 cột cố định: Trái 40% (flex: 4) - Phải 60% (flex: 6)
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cột trái (40%): Tờ lịch Bloc ngày cố định
                Expanded(
                  flex: 4,
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border(
                        right: BorderSide(
                          color: const Color(0xFFD4AF37).withValues(alpha: 0.35),
                        ),
                      ),
                    ),
                    child: DailyBlocView(
                      selectedDate: _selectedDate,
                      onDateChanged: _updateSelectedDate,
                    ),
                  ),
                ),

                // Cột phải (60%): Lịch Tháng và công cụ tra cứu
                Expanded(
                  flex: 6,
                  child: _buildRightPaneContent(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRightPaneContent() {
    switch (_rightPaneTabIndex) {
      case 0:
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              MonthlyGridView(
                selectedDate: _selectedDate,
                onDateSelected: _updateSelectedDate,
              ),
              FengShuiScreen(
                selectedDate: _selectedDate,
                onDateChanged: _updateSelectedDate,
              ),
            ],
          ),
        );
      case 1:
        return const PrayersScreen();
      case 2:
      default:
        return FengShuiScreen(
          selectedDate: _selectedDate,
          onDateChanged: _updateSelectedDate,
        );
    }
  }
}
