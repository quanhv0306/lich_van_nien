import 'package:flutter/material.dart';
import '../../core/horoscope_engine.dart';
import '../../core/lunar_calculator.dart';
import '../../core/sync_engine.dart';
import '../../data/models/user_profile.dart';

/// Màn hình Hồ Sơ Cá Nhân & Tài Khoản Gia Chủ (`lib/presentation/screens/profile_screen.dart`)
/// Chuẩn Local-First 100% (0ms latency):
/// 1. Thẻ Tóm tắt nhanh Bản Mệnh cá nhân ngay đầu trang ("Gia chủ: [Họ và tên]", Can Chi năm sinh,
///    Ngũ hành Nạp Âm, Cung Phi Bát Trạch & Hướng nhà tốt nhất).
/// 2. Form quản lý thông tin:
///    - Họ và tên (tự động viết hoa chữ cái đầu mỗi từ).
///    - Giới tính (SegmentedButton Nam / Nữ).
///    - Ngày tháng năm sinh (Toggle Nhập Dương Lịch / Nhập Âm Lịch + quy đổi song song Dương & Âm).
///    - Giờ sinh (Dropdown 12 khung giờ Can Chi: "Giờ Thìn (07:00 - 09:00)"...).
///    - Địa chỉ cư trú (tự động điền vào bài văn khấn).
/// 3. Nút "Lưu thông tin" -> Lưu tức thì vào Local Storage & kích hoạt CloudSyncService ngầm.
class ProfileScreen extends StatefulWidget {
  final VoidCallback? onOpenSyncScreen;

  const ProfileScreen({
    super.key,
    this.onOpenSyncScreen,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _addressController;

  String _gender = 'Nam';
  bool _isLunarBirth = false;
  bool _isLeapMonth = false;
  int _inputDay = 15;
  int _inputMonth = 6;
  int _inputYear = 1990;
  int _birthHourIndex = 4; // Mặc định Giờ Thìn (07:00 - 09:00)

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _addressController = TextEditingController();
    _hydrateFromLocalSyncEngine();
    SyncEngine.instance.addListener(_onRemoteProfileSynced);
  }

  @override
  void dispose() {
    SyncEngine.instance.removeListener(_onRemoteProfileSynced);
    _nameController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _hydrateFromLocalSyncEngine() {
    final raw = SyncEngine.instance.profile;
    final userProf = raw.toUserProfile();
    _nameController.text = userProf.fullName;
    _addressController.text = userProf.address;
    _gender = userProf.gender;
    _isLunarBirth = raw.isLunar;
    _isLeapMonth = raw.isLeap;
    _inputDay = raw.birthDay.clamp(1, 31);
    _inputMonth = raw.birthMonth.clamp(1, 12);
    _inputYear = raw.birthYear.clamp(1920, 2040);
    _birthHourIndex = raw.birthHourIndex.clamp(0, 11);
  }

  void _onRemoteProfileSynced() {
    if (!mounted) return;
    final raw = SyncEngine.instance.profile;
    final newGender = UserProfile.normalizeGender(raw.gender);
    if (raw.fullName != _nameController.text ||
        raw.address != _addressController.text ||
        newGender != _gender ||
        raw.isLunar != _isLunarBirth ||
        raw.isLeap != _isLeapMonth ||
        raw.birthDay != _inputDay ||
        raw.birthMonth != _inputMonth ||
        raw.birthYear != _inputYear ||
        raw.birthHourIndex != _birthHourIndex) {
      setState(() {
        _nameController.text = raw.fullName;
        _addressController.text = raw.address;
        _gender = newGender;
        _isLunarBirth = raw.isLunar;
        _isLeapMonth = raw.isLeap;
        _inputDay = raw.birthDay.clamp(1, 31);
        _inputMonth = raw.birthMonth.clamp(1, 12);
        _inputYear = raw.birthYear.clamp(1920, 2040);
        _birthHourIndex = raw.birthHourIndex.clamp(0, 11);
      });
    }
  }

  int get _maxValidDays {
    if (_isLunarBirth) return 30;
    return DateTime(_inputYear, _inputMonth + 1, 0).day;
  }

  /// Tính toán kết quả Bản mệnh theo thông tin đang chọn trên form
  HoroscopeProfileResult _computeCurrentHoroscope() {
    final maxDays = _maxValidDays;
    final validDay = _inputDay > maxDays ? maxDays : _inputDay;
    final nowLunarYear = LunarCalculator.nowInVietnam().year;

    return HoroscopeEngine.analyzeProfile(
      day: validDay,
      month: _inputMonth,
      year: _inputYear,
      isLunarInput: _isLunarBirth,
      isLeapMonth: _isLeapMonth,
      gender: _gender == 'Nữ' ? Gender.female : Gender.male,
      targetLunarYear: nowLunarYear,
    );
  }

  void _handleSaveProfile() {
    final formattedName = UserProfile.capitalizeFullName(_nameController.text);
    final trimmedAddress = _addressController.text.trim();
    final maxDays = _maxValidDays;
    final validDay = _inputDay > maxDays ? maxDays : _inputDay;

    setState(() {
      _inputDay = validDay;
      _nameController.text = formattedName;
      _addressController.text = trimmedAddress;
    });

    // Lưu tức thì vào Local Storage (0ms) và kích hoạt CloudSyncService ngầm
    CloudSyncService.instance.updateProfileLocalFirst(
      fullName: formattedName,
      address: trimmedAddress,
      gender: _gender == 'Nữ' ? 'female' : 'male',
      birthDay: validDay,
      birthMonth: _inputMonth,
      birthYear: _inputYear,
      isLunar: _isLunarBirth,
      isLeap: _isLunarBirth ? _isLeapMonth : false,
      birthHourIndex: _birthHourIndex,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF2E7D32),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          content: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Đã lưu thông tin gia chủ thành công',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final maxDays = _maxValidDays;
    final clampedDay = _inputDay > maxDays ? maxDays : _inputDay;
    final horoscope = _computeCurrentHoroscope();
    final displayName = UserProfile.capitalizeFullName(_nameController.text);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 880),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. THẺ TÓM TẮT NHANH BẢN MỆNH CÁ NHÂN (NỔI BẬT ĐẦU TRANG)
              _buildHeroDestinyCard(
                displayName: displayName,
                horoscope: horoscope,
              ),
              const SizedBox(height: 18),

              // 2. FORM QUẢN LÝ THÔNG TIN HỒ SƠ GIA CHỦ
              _buildProfileFormCard(
                clampedDay: clampedDay,
                maxDays: maxDays,
                horoscope: horoscope,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Card nổi bật đầu trang:
  /// - Chào người dùng: "Gia chủ: [Họ và tên]"
  /// - Huy hiệu: Năm sinh Âm lịch (vd: Canh Ngọ), Ngũ hành bản mệnh (vd: Lộ Bàng Thổ)
  /// - Cung Phi (vd: Cung Khảm • Đông Tứ Mệnh) & Hướng nhà tốt nhất
  Widget _buildHeroDestinyCard({
    required String displayName,
    required HoroscopeProfileResult horoscope,
  }) {
    final bestDir = horoscope.batTrach.goodDirections.isNotEmpty
        ? horoscope.batTrach.goodDirections.first
        : null;
    final hourLabel =
        UserProfile.birthHourLabels[_birthHourIndex.clamp(0, 11)];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF7F0000), Color(0xFFA61C1C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFD4AF37), width: 1.6),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFA61C1C).withValues(alpha: 0.16),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 54,
                height: 54,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD54F).withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFFFFD54F),
                    width: 1.5,
                  ),
                ),
                child: Text(
                  horoscope.napAm.zodiacSymbol,
                  style: const TextStyle(fontSize: 28),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'HỒ SƠ BẢN MỆNH LOCAL-FIRST',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.1,
                        color: Color(0xFFFFECB3),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Gia chủ: ${displayName.isEmpty ? "Chưa cập nhật tên" : displayName}',
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFFFFD54F),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$_gender mệnh • $hourLabel',
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: Color(0xFFFFF8E1),
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.onOpenSyncScreen != null)
                IconButton(
                  tooltip: 'Đồng bộ đa thiết bị',
                  onPressed: widget.onOpenSyncScreen,
                  icon: const Icon(
                    Icons.cloud_sync_rounded,
                    color: Color(0xFFFFD54F),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Huy hiệu (Badges): Năm sinh Âm lịch & Ngũ hành bản mệnh
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              _buildGoldBadge(
                icon: Icons.auto_awesome_rounded,
                label:
                    'Tuổi ${horoscope.yearCanChi} (${horoscope.napAm.zodiacAnimal})',
              ),
              _buildGoldBadge(
                icon: Icons.flare_rounded,
                label:
                    'Mệnh ${horoscope.napAm.element}: ${horoscope.napAm.napAmName}',
              ),
              _buildGoldBadge(
                icon: Icons.explore_rounded,
                label:
                    'Cung ${horoscope.batTrach.cungName} (${horoscope.batTrach.groupName})',
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Hướng nhà tốt nhất & Địa chỉ khấn
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: const Color(0xFFFFD54F).withValues(alpha: 0.35),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (bestDir != null)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.home_rounded,
                        color: Color(0xFFFFD54F),
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Hướng nhà đại cát (${bestDir.starName}): Hướng ${bestDir.direction} — ${bestDir.meaning}',
                          style: const TextStyle(
                            color: Color(0xFFFFF8E1),
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                if (_addressController.text.trim().isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.place_rounded,
                        color: Color(0xFFFFD54F),
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Địa chỉ hành lễ: ${_addressController.text.trim()}',
                          style: const TextStyle(
                            color: Color(0xFFFFECB3),
                            fontSize: 12.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoldBadge({
    required IconData icon,
    IconData? fallbackIcon,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8EC),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFD4AF37)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            fallbackIcon ?? icon,
            size: 15,
            color: const Color(0xFFA61C1C),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4A2511),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Form nhập liệu thông tin Gia chủ
  Widget _buildProfileFormCard({
    required int clampedDay,
    required int maxDays,
    required HoroscopeProfileResult horoscope,
  }) {
    final solarStr =
        '${horoscope.birthSolar.day.toString().padLeft(2, '0')}/${horoscope.birthSolar.month.toString().padLeft(2, '0')}/${horoscope.birthSolar.year}';
    final lunarStr =
        '${horoscope.birthLunar.day.toString().padLeft(2, '0')}/${horoscope.birthLunar.month.toString().padLeft(2, '0')}/${horoscope.birthLunar.year}${horoscope.birthLunar.isLeap ? " (Nhuận)" : ""} (${horoscope.yearCanChi})';

    return Card(
      elevation: 0,
      color: const Color(0xFFFFFDF7),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: const BorderSide(color: Color(0xFFD4AF37), width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.manage_accounts_rounded,
                  color: Color(0xFFA61C1C),
                  size: 22,
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Thông Tin Hồ Sơ Gia Chủ',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF8E0000),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Thông tin được lưu trực tiếp trên thiết bị (Local-First) để tự động tính Bản mệnh Phong Thủy và điền sẵn [Họ tên], [Địa chỉ] trong toàn bộ kho Văn Khấn.',
              style: TextStyle(fontSize: 12.5, color: Color(0xFF5D4037)),
            ),
            const SizedBox(height: 18),

            // 1. Họ và tên (TextField có icon người, tự động viết hoa chữ cái đầu)
            TextField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              onChanged: (_) => setState(() {}),
              onEditingComplete: () {
                final formatted = UserProfile.capitalizeFullName(
                  _nameController.text,
                );
                _nameController.value = TextEditingValue(
                  text: formatted,
                  selection: TextSelection.collapsed(offset: formatted.length),
                );
                setState(() {});
              },
              decoration: InputDecoration(
                labelText: 'Họ và tên Gia chủ / Tín chủ',
                hintText: 'Ví dụ: Nguyễn Văn An',
                prefixIcon: const Icon(
                  Icons.person_rounded,
                  color: Color(0xFFA61C1C),
                ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 2. Giới tính (SegmentedButton Nam / Nữ) & Chế độ nhập ngày sinh (Dương / Âm)
            Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Text(
                  'Giới tính:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13.5,
                    color: Color(0xFF4A2511),
                  ),
                ),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment<String>(
                      value: 'Nam',
                      icon: Icon(Icons.male_rounded, size: 18),
                      label: Text('Nam'),
                    ),
                    ButtonSegment<String>(
                      value: 'Nữ',
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
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment<bool>(
                      value: false,
                      icon: Icon(Icons.wb_sunny_outlined, size: 17),
                      label: Text('Nhập Dương Lịch'),
                    ),
                    ButtonSegment<bool>(
                      value: true,
                      icon: Icon(Icons.nightlight_round, size: 17),
                      label: Text('Nhập Âm Lịch'),
                    ),
                  ],
                  selected: {_isLunarBirth},
                  style: SegmentedButton.styleFrom(
                    selectedBackgroundColor: const Color(0xFFA61C1C),
                    selectedForegroundColor: const Color(0xFFFFD54F),
                    visualDensity: VisualDensity.compact,
                  ),
                  onSelectionChanged: (selection) {
                    setState(() {
                      _isLunarBirth = selection.first;
                      if (!_isLunarBirth) _isLeapMonth = false;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 3. Chọn Ngày / Tháng / Năm sinh
            Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _buildNumberDropdown(
                  label: 'Ngày sinh',
                  value: clampedDay,
                  items: List.generate(maxDays, (i) => i + 1),
                  onChanged: (v) => setState(() => _inputDay = v),
                ),
                _buildNumberDropdown(
                  label: 'Tháng sinh',
                  value: _inputMonth,
                  items: List.generate(12, (i) => i + 1),
                  onChanged: (v) => setState(() => _inputMonth = v),
                ),
                _buildNumberDropdown(
                  label: 'Năm sinh',
                  value: _inputYear,
                  items: List.generate(121, (i) => 1920 + i),
                  onChanged: (v) => setState(() => _inputYear = v),
                ),
                if (_isLunarBirth)
                  FilterChip(
                    label: const Text('Tháng nhuận Âm lịch'),
                    selected: _isLeapMonth,
                    selectedColor: const Color(0xFFFFECB3),
                    onSelected: (v) => setState(() => _isLeapMonth = v),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Quy đổi hiển thị song song cả ngày Dương và ngày Âm bên dưới
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8EC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: const Color(0xFFD4AF37).withValues(alpha: 0.55),
                ),
              ),
              child: Wrap(
                spacing: 20,
                runSpacing: 6,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.wb_sunny_rounded,
                        size: 17,
                        color: Color(0xFFE65100),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'Dương lịch: $solarStr',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF4A2511),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.nightlight_round,
                        size: 16,
                        color: Color(0xFFA61C1C),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'Âm lịch: $lunarStr',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF8E0000),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 4. Giờ sinh (Dropdown chọn 12 Khung giờ Can Chi)
            DropdownButtonFormField<int>(
              initialValue: _birthHourIndex.clamp(0, 11),
              isExpanded: true,
              decoration: InputDecoration(
                labelText: 'Giờ sinh (12 Khung giờ Can Chi)',
                prefixIcon: const Icon(
                  Icons.access_time_filled_rounded,
                  color: Color(0xFFA61C1C),
                ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              items: List.generate(
                UserProfile.birthHourLabels.length,
                (index) => DropdownMenuItem<int>(
                  value: index,
                  child: Text(
                    UserProfile.birthHourLabels[index],
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2D1E17),
                    ),
                  ),
                ),
              ),
              onChanged: (val) {
                if (val != null) {
                  setState(() => _birthHourIndex = val);
                }
              },
            ),
            const SizedBox(height: 16),

            // 5. Địa chỉ cư trú (Tùy chọn: giúp điền sẵn văn khấn)
            TextField(
              controller: _addressController,
              maxLines: 2,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: 'Địa chỉ cư trú (tự động điền vào vị trí [Địa chỉ] trong Văn Khấn)',
                hintText: 'Ví dụ: Số 18 phố Hàng Đào, phường Hàng Đào, quận Hoàn Kiếm, Hà Nội',
                prefixIcon: const Icon(
                  Icons.home_work_rounded,
                  color: Color(0xFFA61C1C),
                ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 6. Nút "Lưu thông tin"
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _handleSaveProfile,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFA61C1C),
                  foregroundColor: const Color(0xFFFFD54F),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(Icons.save_rounded, size: 20),
                label: const Text(
                  'Lưu thông tin',
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNumberDropdown({
    required String label,
    required int value,
    required List<int> items,
    required ValueChanged<int> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFD4AF37).withValues(alpha: 0.65),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF5D4037),
            ),
          ),
          DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: value,
              isDense: true,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF8E0000),
              ),
              items: items
                  .map(
                    (e) => DropdownMenuItem<int>(
                      value: e,
                      child: Text(e.toString().padLeft(2, '0')),
                    ),
                  )
                  .toList(),
              onChanged: (v) {
                if (v != null) onChanged(v);
              },
            ),
          ),
        ],
      ),
    );
  }
}
