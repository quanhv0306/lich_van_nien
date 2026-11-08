import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/horoscope_engine.dart';
import '../../core/lunar_calculator.dart';
import '../../core/sync_engine.dart';
import '../../data/models/day_info.dart';

/// Màn hình Phong Thủy & Tra Cứu Bản Mệnh Offline 100%:
/// 1. Form nhập ngày/tháng/năm sinh (Tab Dương Lịch / Âm Lịch), Giới tính (Nam/Nữ),
///    lưu hồ sơ vào `shared_preferences` và nút "Xem Bát Tự & Quẻ Mệnh".
/// 2. 3 Thẻ kết quả Bản Mệnh trực quan:
///    - Thẻ Bản Mệnh (Can Chi, Mệnh Ngũ Hành Nạp Âm, Con giáp tượng trưng).
///    - Thẻ Cung Phi & Hướng Nhà (La bàn Bát Trạch trực quan + 4 hướng tốt / 4 hướng xấu).
///    - Thẻ Vận Hạn Năm Hiện Tại (Sao Cửu Diệu, Hạn năm, Tam Tai - Kim Lâu - Hoang Ốc & cách hóa giải).
/// 3. Bảng Việc Nên Làm / Kiêng Cữ theo Trực và 12 Giờ Xuất Hành Lý Thuần Phong của ngày đang chọn.
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
  static const String _prefBirthDayKey = 'horoscope_birth_day';
  static const String _prefBirthMonthKey = 'horoscope_birth_month';
  static const String _prefBirthYearKey = 'horoscope_birth_year';
  static const String _prefIsLunarKey = 'horoscope_is_lunar';
  static const String _prefIsLeapKey = 'horoscope_is_leap';
  static const String _prefGenderKey = 'horoscope_gender';
  static const String _prefSaveProfileKey = 'horoscope_save_profile';

  int _birthDay = 15;
  int _birthMonth = 6;
  int _birthYear = 1990;
  bool _isLunarInput = false;
  bool _isLeapMonth = false;
  Gender _gender = Gender.male;
  bool _rememberProfile = true;

  /// Chế độ tra cứu:
  /// - `false`: Xem cho bản thân (`[Họ và tên]` từ Hồ sơ Gia chủ Local-First)
  /// - `true`: Tra cứu người khác (nhập tên & năm sinh tạm thời mà không đè hồ sơ chính)
  bool _isGuestLookup = false;
  String _ownerFullName = '';
  final TextEditingController _guestNameController = TextEditingController();

  HoroscopeProfileResult? _profileResult;

  @override
  void initState() {
    super.initState();
    _applyOwnerProfileFromLocalCache();
    SyncEngine.instance.addListener(_onSyncedProfileChanged);
    _loadSavedProfileAndAnalyze();
  }

  @override
  void dispose() {
    SyncEngine.instance.removeListener(_onSyncedProfileChanged);
    _guestNameController.dispose();
    super.dispose();
  }

  void _applyOwnerProfileFromLocalCache() {
    final p = SyncEngine.instance.profile;
    _ownerFullName = p.fullName.trim();
    _birthDay = p.birthDay.clamp(1, 31);
    _birthMonth = p.birthMonth.clamp(1, 12);
    _birthYear = p.birthYear.clamp(1920, 2040);
    _isLunarInput = p.isLunar;
    _isLeapMonth = p.isLeap;
    _gender = p.gender == 'female' ? Gender.female : Gender.male;
  }

  void _onSyncedProfileChanged() {
    if (!mounted) return;
    final p = SyncEngine.instance.profile;
    _ownerFullName = p.fullName.trim();
    if (_isGuestLookup || !_rememberProfile) {
      setState(() {});
      return;
    }
    final incomingGender = p.gender == 'female' ? Gender.female : Gender.male;
    if (p.birthDay != _birthDay ||
        p.birthMonth != _birthMonth ||
        p.birthYear != _birthYear ||
        p.isLunar != _isLunarInput ||
        p.isLeap != _isLeapMonth ||
        incomingGender != _gender) {
      _birthDay = p.birthDay.clamp(1, 31);
      _birthMonth = p.birthMonth.clamp(1, 12);
      _birthYear = p.birthYear.clamp(1920, 2040);
      _isLunarInput = p.isLunar;
      _isLeapMonth = p.isLeap;
      _gender = incomingGender;
      _runHoroscopeAnalysis(saveToPrefs: false);
    } else {
      setState(() {});
    }
  }

  @override
  void didUpdateWidget(covariant FengShuiScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedDate.year != widget.selectedDate.year) {
      _runHoroscopeAnalysis(saveToPrefs: false);
    }
  }

  Future<void> _loadSavedProfileAndAnalyze() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedRemember = prefs.getBool(_prefSaveProfileKey) ?? true;
      if (savedRemember) {
        final d = prefs.getInt(_prefBirthDayKey);
        final m = prefs.getInt(_prefBirthMonthKey);
        final y = prefs.getInt(_prefBirthYearKey);
        final isLunar = prefs.getBool(_prefIsLunarKey);
        final isLeap = prefs.getBool(_prefIsLeapKey);
        final genderStr = prefs.getString(_prefGenderKey);

        if (d != null && m != null && y != null) {
          _birthDay = d.clamp(1, 31);
          _birthMonth = m.clamp(1, 12);
          _birthYear = y.clamp(1920, 2040);
          _isLunarInput = isLunar ?? false;
          _isLeapMonth = isLeap ?? false;
          _gender = genderStr == 'female' ? Gender.female : Gender.male;
        }
      }
      _rememberProfile = savedRemember;
    } catch (_) {}

    if (!mounted) return;
    _runHoroscopeAnalysis(saveToPrefs: false);
  }

  int get _maxValidDaysForInput {
    if (_isLunarInput) {
      return 30;
    }
    return DateTime(_birthYear, _birthMonth + 1, 0).day;
  }

  Future<void> _runHoroscopeAnalysis({bool saveToPrefs = true}) async {
    final maxDays = _maxValidDaysForInput;
    if (_birthDay > maxDays) {
      _birthDay = maxDays;
    }

    final currentLunarYear = LunarCalculator.solarToLunar(
      widget.selectedDate.day,
      widget.selectedDate.month,
      widget.selectedDate.year,
    ).year;

    final result = HoroscopeEngine.analyzeProfile(
      day: _birthDay,
      month: _birthMonth,
      year: _birthYear,
      isLunarInput: _isLunarInput,
      isLeapMonth: _isLeapMonth,
      gender: _gender,
      targetLunarYear: currentLunarYear,
    );

    setState(() {
      _profileResult = result;
    });

    if (saveToPrefs && !_isGuestLookup) {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_prefSaveProfileKey, _rememberProfile);
        if (_rememberProfile) {
          await prefs.setInt(_prefBirthDayKey, _birthDay);
          await prefs.setInt(_prefBirthMonthKey, _birthMonth);
          await prefs.setInt(_prefBirthYearKey, _birthYear);
          await prefs.setBool(_prefIsLunarKey, _isLunarInput);
          await prefs.setBool(_prefIsLeapKey, _isLeapMonth);
          await prefs.setString(
            _prefGenderKey,
            _gender == Gender.female ? 'female' : 'male',
          );
          SyncEngine.instance.updateProfileLocalFirst(
            birthDay: _birthDay,
            birthMonth: _birthMonth,
            birthYear: _birthYear,
            isLunar: _isLunarInput,
            isLeap: _isLeapMonth,
            gender: _gender == Gender.female ? 'female' : 'male',
          );
        }
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    final dayInfo = DayInfo.fromSolarDate(widget.selectedDate);
    final maxDays = _maxValidDaysForInput;
    final clampedDay = _birthDay > maxDays ? maxDays : _birthDay;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 940),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ================= 1. FORM TRA CỨU BẢN MỆNH & BÁT TỰ OFFLINE =================
              Card(
                elevation: 0,
                color: const Color(0xFFFFFDF7),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22),
                  side: const BorderSide(
                    color: Color(0xFFD4AF37),
                    width: 1.5,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Tiêu đề
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFA61C1C),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.auto_graph_rounded,
                              color: Color(0xFFFFD54F),
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Tra Cứu Bản Mệnh, Cung Phi & Vận Hạn',
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF8E0000),
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Nhập ngày sinh Dương lịch hoặc Âm lịch để luận giải Ngũ Hành, Hướng hợp & Sao hạn',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    color: Color(0xFF5D4037),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Chuyển đổi: "Xem cho bản thân ([Họ và tên])" vs "Tra cứu người khác"
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF8EC),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: const Color(0xFFD4AF37).withValues(
                              alpha: 0.5,
                            ),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Wrap(
                              spacing: 10,
                              runSpacing: 8,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                ChoiceChip(
                                  avatar: Icon(
                                    Icons.person_pin_rounded,
                                    size: 18,
                                    color: !_isGuestLookup
                                        ? const Color(0xFFFFD54F)
                                        : const Color(0xFFA61C1C),
                                  ),
                                  label: Text(
                                    'Xem cho bản thân (${_ownerFullName.isEmpty ? "Gia chủ" : _ownerFullName})',
                                  ),
                                  selected: !_isGuestLookup,
                                  selectedColor: const Color(0xFFA61C1C),
                                  backgroundColor: Colors.white,
                                  labelStyle: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: !_isGuestLookup
                                        ? const Color(0xFFFFD54F)
                                        : const Color(0xFF4A2511),
                                  ),
                                  onSelected: (selected) {
                                    if (selected && _isGuestLookup) {
                                      setState(() {
                                        _isGuestLookup = false;
                                        _applyOwnerProfileFromLocalCache();
                                      });
                                      _runHoroscopeAnalysis(saveToPrefs: false);
                                    }
                                  },
                                ),
                                ChoiceChip(
                                  avatar: Icon(
                                    Icons.person_search_rounded,
                                    size: 18,
                                    color: _isGuestLookup
                                        ? const Color(0xFFFFD54F)
                                        : const Color(0xFF4A2511),
                                  ),
                                  label: const Text('Tra cứu người khác'),
                                  selected: _isGuestLookup,
                                  selectedColor: const Color(0xFF4A2511),
                                  backgroundColor: Colors.white,
                                  labelStyle: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: _isGuestLookup
                                        ? const Color(0xFFFFD54F)
                                        : const Color(0xFF4A2511),
                                  ),
                                  onSelected: (selected) {
                                    if (selected && !_isGuestLookup) {
                                      setState(() {
                                        _isGuestLookup = true;
                                      });
                                    }
                                  },
                                ),
                              ],
                            ),
                            if (_isGuestLookup) ...[
                              const SizedBox(height: 10),
                              TextField(
                                controller: _guestNameController,
                                textCapitalization: TextCapitalization.words,
                                onChanged: (_) => setState(() {}),
                                decoration: InputDecoration(
                                  isDense: true,
                                  labelText:
                                      'Họ tên người cần tra cứu (Tạm thời - không ghi đè hồ sơ chính)',
                                  hintText: 'Ví dụ: Trần Thị B',
                                  prefixIcon: const Icon(
                                    Icons.badge_outlined,
                                    color: Color(0xFFA61C1C),
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),

                      const SizedBox(height: 14),

                      // Chuyển đổi Tab Sinh Dương Lịch / Sinh Âm Lịch & Chọn Giới tính
                      Wrap(
                        spacing: 12,
                        runSpacing: 10,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          // Segmented chọn lịch Dương / Âm
                          SegmentedButton<bool>(
                            segments: const [
                              ButtonSegment<bool>(
                                value: false,
                                icon: Icon(Icons.wb_sunny_outlined, size: 17),
                                label: Text('Sinh Dương Lịch'),
                              ),
                              ButtonSegment<bool>(
                                value: true,
                                icon: Icon(Icons.nightlight_round, size: 17),
                                label: Text('Sinh Âm Lịch'),
                              ),
                            ],
                            selected: {_isLunarInput},
                            style: SegmentedButton.styleFrom(
                              selectedBackgroundColor: const Color(0xFFA61C1C),
                              selectedForegroundColor: const Color(0xFFFFD54F),
                              visualDensity: VisualDensity.compact,
                            ),
                            onSelectionChanged: (selection) {
                              setState(() {
                                _isLunarInput = selection.first;
                                if (!_isLunarInput) _isLeapMonth = false;
                              });
                            },
                          ),

                          // Chọn Giới tính Nam / Nữ
                          SegmentedButton<Gender>(
                            segments: const [
                              ButtonSegment<Gender>(
                                value: Gender.male,
                                icon: Icon(Icons.male_rounded, size: 18),
                                label: Text('Nam'),
                              ),
                              ButtonSegment<Gender>(
                                value: Gender.female,
                                icon: Icon(Icons.female_rounded, size: 18),
                                label: Text('Nữ'),
                              ),
                            ],
                            selected: {_gender},
                            style: SegmentedButton.styleFrom(
                              selectedBackgroundColor: const Color(0xFF4A2511),
                              selectedForegroundColor: const Color(0xFFFFD54F),
                              visualDensity: VisualDensity.compact,
                            ),
                            onSelectionChanged: (selection) {
                              setState(() => _gender = selection.first);
                            },
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      // Chọn Ngày / Tháng / Năm sinh
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          _DropdownNumber(
                            label: 'Ngày',
                            value: clampedDay,
                            items: List.generate(maxDays, (i) => i + 1),
                            onChanged: (v) => setState(() => _birthDay = v),
                          ),
                          _DropdownNumber(
                            label: 'Tháng',
                            value: _birthMonth,
                            items: List.generate(12, (i) => i + 1),
                            onChanged: (v) => setState(() => _birthMonth = v),
                          ),
                          _DropdownNumber(
                            label: 'Năm sinh',
                            value: _birthYear,
                            items: List.generate(121, (i) => 1920 + i),
                            onChanged: (v) => setState(() => _birthYear = v),
                          ),
                          if (_isLunarInput)
                            FilterChip(
                              label: const Text('Tháng nhuận'),
                              selected: _isLeapMonth,
                              selectedColor: const Color(0xFFFFF3CD),
                              onSelected: (v) =>
                                  setState(() => _isLeapMonth = v),
                            ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Lưu hồ sơ + Nút "Xem Bát Tự & Quẻ Mệnh"
                      Wrap(
                        spacing: 16,
                        runSpacing: 10,
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          InkWell(
                            borderRadius: BorderRadius.circular(8),
                            onTap: () => setState(
                              () => _rememberProfile = !_rememberProfile,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: Checkbox(
                                    value: _rememberProfile,
                                    activeColor: const Color(0xFFA61C1C),
                                    onChanged: (v) => setState(
                                      () => _rememberProfile = v ?? true,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Flexible(
                                  child: Text(
                                    'Lưu hồ sơ ngày sinh cho lần mở sau',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF4A2511),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          FilledButton.icon(
                            onPressed: () =>
                                _runHoroscopeAnalysis(saveToPrefs: true),
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFFA61C1C),
                              foregroundColor: const Color(0xFFFFD54F),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            icon: const Icon(Icons.compass_calibration_rounded),
                            label: const Text(
                              'Xem Bát Tự & Quẻ Mệnh',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // ================= 2. HIỂN THỊ 3 THẺ KẾT QUẢ BẢN MỆNH =================
              if (_profileResult != null) ...[
                _BuildBanMenhCard(
                  result: _profileResult!,
                  subjectName: _isGuestLookup
                      ? (_guestNameController.text.trim().isEmpty
                            ? 'Khách tra cứu tạm thời'
                            : _guestNameController.text.trim())
                      : (_ownerFullName.isEmpty ? 'Gia chủ' : _ownerFullName),
                  isGuestLookup: _isGuestLookup,
                ),
                const SizedBox(height: 16),
                _BuildCungPhiCompassCard(result: _profileResult!),
                const SizedBox(height: 16),
                _BuildYearlyFortuneCard(result: _profileResult!),
                const SizedBox(height: 20),
              ],

              // ================= 3. THÔNG TIN PHONG THỦY CỦA NGÀY ĐANG CHỌN =================
              _BuildDailyTrucAndHoursSection(dayInfo: dayInfo),
            ],
          ),
        ),
      ),
    );
  }
}

/// THẺ 1: BẢN MỆNH (Can Chi, Mệnh Ngũ Hành Nạp Âm, Con giáp tượng trưng)
class _BuildBanMenhCard extends StatelessWidget {
  final HoroscopeProfileResult result;
  final String subjectName;
  final bool isGuestLookup;

  const _BuildBanMenhCard({
    required this.result,
    required this.subjectName,
    this.isGuestLookup = false,
  });

  Color _elementColor(String element) {
    switch (element) {
      case 'Kim':
        return const Color(0xFFB7791F);
      case 'Mộc':
        return const Color(0xFF2E7D32);
      case 'Thủy':
        return const Color(0xFF1565C0);
      case 'Hỏa':
        return const Color(0xFFC62828);
      case 'Thổ':
      default:
        return const Color(0xFF6D4C41);
    }
  }

  @override
  Widget build(BuildContext context) {
    final elemColor = _elementColor(result.napAm.element);

    return Card(
      elevation: 0,
      color: const Color(0xFFFFFDF7),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: const Color(0xFFD4AF37).withValues(alpha: 0.65),
          width: 1.4,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Thẻ Bản Mệnh
            Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFC62828), Color(0xFF8E0000)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFFFFD54F),
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    result.napAm.zodiacSymbol,
                    style: const TextStyle(fontSize: 28),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isGuestLookup
                            ? 'Người tra cứu: $subjectName'
                            : 'Gia chủ: $subjectName',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFA61C1C),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            'Tuổi ${result.yearCanChi} • ${result.gender.fullLabel}',
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF8E0000),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: elemColor.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: elemColor),
                            ),
                            child: Text(
                              'Mệnh ${result.napAm.element}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: elemColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Con giáp: ${result.napAm.zodiacAnimal} • ${result.cuuDieu.lunarAge} tuổi Âm lịch',
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

            const Divider(height: 24),

            // Lưới thông tin Bát Tự & Ngũ Hành Nạp Âm
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _InfoBadge(
                  label: 'Dương lịch sinh',
                  value:
                      '${result.birthSolar.day.toString().padLeft(2, '0')}/${result.birthSolar.month.toString().padLeft(2, '0')}/${result.birthSolar.year}',
                ),
                _InfoBadge(
                  label: 'Âm lịch sinh',
                  value:
                      '${result.birthLunar.day.toString().padLeft(2, '0')}/${result.birthLunar.month.toString().padLeft(2, '0')}${result.birthLunar.isLeap ? " (Nhuận)" : ""}/${result.birthLunar.year}',
                ),
                _InfoBadge(
                  label: 'Tứ Trụ (Năm - Tháng - Ngày)',
                  value:
                      'Năm ${result.yearCanChi} • Tháng ${result.monthCanChi} • Ngày ${result.dayCanChi}',
                ),
                _InfoBadge(
                  label: 'Ngũ Hành Nạp Âm',
                  value:
                      '${result.napAm.napAmName} (${result.napAm.vietnameseMeaning})',
                  highlight: true,
                ),
              ],
            ),

            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8E7),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFD4AF37).withValues(alpha: 0.5),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '• Tương sinh / Tương hợp: ${result.napAm.compatibleElements}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1B5E20),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '• Tương khắc: ${result.napAm.incompatibleElements}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFB71C1C),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// THẺ 2: CUNG PHI BÁT TRẠCH & LA BÀN 8 HƯỚNG TRỰC QUAN
class _BuildCungPhiCompassCard extends StatelessWidget {
  final HoroscopeProfileResult result;

  const _BuildCungPhiCompassCard({required this.result});

  BatTrachDirection _findDir(String dirName) {
    for (final d in result.batTrach.goodDirections) {
      if (d.direction == dirName) return d;
    }
    for (final d in result.batTrach.badDirections) {
      if (d.direction == dirName) return d;
    }
    return result.batTrach.goodDirections.first;
  }

  @override
  Widget build(BuildContext context) {
    final bt = result.batTrach;

    return Card(
      elevation: 0,
      color: const Color(0xFFFFFDF7),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: const Color(0xFFD4AF37).withValues(alpha: 0.65),
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
                const Icon(
                  Icons.explore_rounded,
                  color: Color(0xFFA61C1C),
                  size: 24,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Cung Phi Bát Trạch: Cung ${bt.cungName} (${bt.cungElement}) • ${bt.groupName}',
                    style: const TextStyle(
                      fontSize: 16.5,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF8E0000),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'La bàn Cửu Cung Bát Trạch (Xanh: 4 Hướng Tốt hợp mệnh • Đỏ: 4 Hướng Xấu nên tránh):',
              style: TextStyle(fontSize: 12.5, color: Color(0xFF5D4037)),
            ),
            const SizedBox(height: 14),

            // Sơ đồ La Bàn Bát Trạch 3x3 trực quan
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFDF6E4),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFD4AF37)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: _CompassCell(dir: _findDir('Tây Bắc'))),
                      const SizedBox(width: 6),
                      Expanded(child: _CompassCell(dir: _findDir('Chính Bắc'))),
                      const SizedBox(width: 6),
                      Expanded(child: _CompassCell(dir: _findDir('Đông Bắc'))),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(child: _CompassCell(dir: _findDir('Chính Tây'))),
                      const SizedBox(width: 6),
                      // Trung cung hiển thị Cung Phi & Nhóm Mệnh
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 4,
                          ),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFC62828), Color(0xFF8E0000)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFFFFD54F),
                              width: 1.5,
                            ),
                          ),
                          child: Column(
                            children: [
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  'CUNG ${bt.cungName.toUpperCase()}',
                                  style: const TextStyle(
                                    color: Color(0xFFFFD54F),
                                    fontWeight: FontWeight.w900,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 2),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  bt.groupName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(child: _CompassCell(dir: _findDir('Chính Đông'))),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(child: _CompassCell(dir: _findDir('Tây Nam'))),
                      const SizedBox(width: 6),
                      Expanded(child: _CompassCell(dir: _findDir('Chính Nam'))),
                      const SizedBox(width: 6),
                      Expanded(child: _CompassCell(dir: _findDir('Đông Nam'))),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Chi tiết 4 Hướng Tốt & 4 Hướng Xấu
            LayoutBuilder(
              builder: (context, constraints) {
                final isTwoCol = constraints.maxWidth >= 580;
                final goodColumn = _DirectionListPanel(
                  title: '4 HƯỚNG TỐT HỢP MỆNH (NÊN CHỌN)',
                  items: bt.goodDirections,
                  accentColor: const Color(0xFF2E7D32),
                  bgColor: const Color(0xFFE8F5E9),
                );
                final badColumn = _DirectionListPanel(
                  title: '4 HƯỚNG XẤU KHẮC MỆNH (NÊN TRÁNH)',
                  items: bt.badDirections,
                  accentColor: const Color(0xFFC62828),
                  bgColor: const Color(0xFFFFEBEE),
                );

                if (isTwoCol) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: goodColumn),
                      const SizedBox(width: 12),
                      Expanded(child: badColumn),
                    ],
                  );
                }
                return Column(
                  children: [
                    goodColumn,
                    const SizedBox(height: 12),
                    badColumn,
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// THẺ 3: VẬN HẠN NĂM HIỆN TẠI (Cửu Diệu Sao Chiếu Mệnh, Hạn Năm, Tam Tai - Kim Lâu - Hoang Ốc)
class _BuildYearlyFortuneCard extends StatelessWidget {
  final HoroscopeProfileResult result;

  const _BuildYearlyFortuneCard({required this.result});

  @override
  Widget build(BuildContext context) {
    final cd = result.cuuDieu;
    final tb = result.taboos;

    return Card(
      elevation: 0,
      color: const Color(0xFFFFFDF7),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: const Color(0xFFD4AF37).withValues(alpha: 0.65),
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
                const Icon(
                  Icons.stars_rounded,
                  color: Color(0xFFA61C1C),
                  size: 24,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Vận Hạn Năm ${tb.targetLunarYear} (${tb.targetYearCanChi}) • ${cd.lunarAge} Tuổi Mụ',
                    style: const TextStyle(
                      fontSize: 16.5,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF8E0000),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Sao chiếu mệnh & Hạn năm
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: cd.isGoodStar
                    ? const Color(0xFFE8F5E9)
                    : const Color(0xFFFFF8E1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: cd.isGoodStar
                      ? const Color(0xFF2E7D32)
                      : const Color(0xFFD4AF37),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        'Sao chiếu mệnh: Sao ${cd.starName}',
                        style: TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w900,
                          color: cd.isGoodStar
                              ? const Color(0xFF1B5E20)
                              : const Color(0xFFB71C1C),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: cd.isGoodStar
                              ? const Color(0xFF2E7D32)
                              : const Color(0xFFC62828),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          cd.starNature,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    cd.starDescription,
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: Color(0xFF2D1E17),
                    ),
                  ),
                  const Divider(height: 18),
                  Text(
                    'Hạn niên vận: Hạn ${cd.hanName}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF8E0000),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    cd.hanDescription,
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: Color(0xFF2D1E17),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.lightbulb_outline_rounded,
                          color: Color(0xFFA61C1C),
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Lời khuyên & Hóa giải: ${cd.adviceAndRemedy}',
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF4A2511),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // Bảng kiểm tra Tam Tai - Kim Lâu - Hoang Ốc
            const Text(
              'Hạn Xây Nhà / Động Thổ / Cưới Hỏi Trong Năm (Tam Tai • Kim Lâu • Hoang Ốc):',
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w800,
                color: Color(0xFF4A2511),
              ),
            ),
            const SizedBox(height: 8),
            _TabooRow(
              label: 'Hạn Tam Tai',
              isBad: tb.hasTamTai,
              statusText: tb.hasTamTai ? 'Phạm Tam Tai' : 'Không phạm',
              detail: tb.tamTaiDetail,
            ),
            const SizedBox(height: 8),
            _TabooRow(
              label: 'Hạn Kim Lâu',
              isBad: tb.hasKimLau,
              statusText: tb.hasKimLau ? 'Phạm Kim Lâu' : 'Không phạm',
              detail: tb.kimLauDetail,
            ),
            const SizedBox(height: 8),
            _TabooRow(
              label: 'Hạn Hoang Ốc',
              isBad: tb.hasHoangOc,
              statusText: tb.hoangOcCung,
              detail: tb.hoangOcDetail,
            ),
          ],
        ),
      ),
    );
  }
}

/// Khối hiển thị Trực & 12 Giờ Xuất Hành Lý Thuần Phong của ngày đang chọn
class _BuildDailyTrucAndHoursSection extends StatelessWidget {
  final DayInfo dayInfo;

  const _BuildDailyTrucAndHoursSection({required this.dayInfo});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Bảng Việc Nên Làm & Kiêng Cữ theo Trực của ngày
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
                            'Bảng Việc Nên Làm & Kiêng Cữ • Trực ${dayInfo.truc.name}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF8E0000),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Ngày ${dayInfo.dayCanChi} (${dayInfo.solarDate.day.toString().padLeft(2, '0')}/${dayInfo.solarDate.month.toString().padLeft(2, '0')}/${dayInfo.solarDate.year}) • Sao ${dayInfo.nhiThapBatTu.name} (${dayInfo.nhiThapBatTu.type})',
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF5D4037),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth >= 560;
                    final goodBox = _TrucActionBox(
                      title: 'VIỆC NÊN LÀM (NGHI)',
                      content: dayInfo.truc.good,
                      extraNote:
                          'Sao ${dayInfo.nhiThapBatTu.name}: ${dayInfo.nhiThapBatTu.meaning}',
                      icon: Icons.check_circle_rounded,
                      accentColor: const Color(0xFF2E7D32),
                      bgColor: const Color(0xFFE8F5E9),
                    );
                    final badBox = _TrucActionBox(
                      title: 'VIỆC KIÊNG CỮ (KỴ)',
                      content: dayInfo.truc.bad,
                      extraNote:
                          'Hướng Hắc Thần nên tránh: ${dayInfo.departureDirection.hacThan}',
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
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Bảng 12 Giờ Xuất Hành Lý Thuần Phong
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
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF8E0000),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Áp dụng cho ngày Âm lịch ${dayInfo.lunarDate.day}/${dayInfo.lunarDate.month}/${dayInfo.lunarDate.year} (${dayInfo.dayCanChi})',
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: Color(0xFF5D4037),
                  ),
                ),
                const SizedBox(height: 14),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: dayInfo.lyThuanPhongHours.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final item = dayInfo.lyThuanPhongHours[index];
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
                          Container(
                            width: 102,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: item.isGood
                                  ? const Color(0xFFA61C1C)
                                  : const Color(0xFF5D4037),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              children: [
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    'Giờ ${item.chi}',
                                    maxLines: 1,
                                    style: const TextStyle(
                                      color: Color(0xFFFFD54F),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13.5,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 3),
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    item.timeRange,
                                    maxLines: 1,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 4,
                                  crossAxisAlignment: WrapCrossAlignment.center,
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
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: item.isGood
                                            ? const Color(0xFFE8F5E9)
                                            : const Color(0xFFFFEBEE),
                                        borderRadius: BorderRadius.circular(10),
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
                                const SizedBox(height: 5),
                                Text(
                                  item.description,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    height: 1.38,
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
      ],
    );
  }
}

class _InfoBadge extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;

  const _InfoBadge({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: highlight ? const Color(0xFFFFF3CD) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: highlight ? const Color(0xFFD4AF37) : Colors.grey.shade300,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 11.5, color: Color(0xFF6D4C41)),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
              color: highlight
                  ? const Color(0xFF8E0000)
                  : const Color(0xFF2D1E17),
            ),
          ),
        ],
      ),
    );
  }
}

class _CompassCell extends StatelessWidget {
  final BatTrachDirection dir;

  const _CompassCell({required this.dir});

  @override
  Widget build(BuildContext context) {
    final bgColor = dir.isGood
        ? const Color(0xFFE8F5E9)
        : const Color(0xFFFFEBEE);
    final borderColor = dir.isGood
        ? const Color(0xFF2E7D32)
        : const Color(0xFFC62828);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor.withValues(alpha: 0.6)),
      ),
      child: Column(
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              dir.direction,
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFF2D1E17),
              ),
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              dir.starName,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w900,
                color: borderColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DirectionListPanel extends StatelessWidget {
  final String title;
  final List<BatTrachDirection> items;
  final Color accentColor;
  final Color bgColor;

  const _DirectionListPanel({
    required this.title,
    required this.items,
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
          Text(
            title,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w900,
              color: accentColor,
            ),
          ),
          const SizedBox(height: 8),
          ...items.map(
            (d) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '• ${d.direction} (${d.starName})',
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF2D1E17),
                    ),
                  ),
                  Text(
                    d.meaning,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF4E342E),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TabooRow extends StatelessWidget {
  final String label;
  final bool isBad;
  final String statusText;
  final String detail;

  const _TabooRow({
    required this.label,
    required this.isBad,
    required this.statusText,
    required this.detail,
  });

  @override
  Widget build(BuildContext context) {
    final color = isBad ? const Color(0xFFC62828) : const Color(0xFF2E7D32);
    final bg = isBad ? const Color(0xFFFFEBEE) : const Color(0xFFE8F5E9);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Icon(
                isBad ? Icons.warning_amber_rounded : Icons.verified_rounded,
                size: 17,
                color: color,
              ),
              Text(
                '$label:',
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF2D1E17),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  statusText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            detail,
            style: const TextStyle(fontSize: 12.5, color: Color(0xFF3E2723)),
          ),
        ],
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
