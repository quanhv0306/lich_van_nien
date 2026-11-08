import '../../core/lunar_calculator.dart';

/// Mô hình Hồ sơ Gia chủ / Người dùng chuẩn Local-First (`lib/data/models/user_profile.dart`)
class UserProfile {
  /// Danh sách 12 khung giờ sinh theo Can Chi chuẩn cổ truyền
  static const List<String> birthHourLabels = [
    'Giờ Tý (23:00 - 01:00)',
    'Giờ Sửu (01:00 - 03:00)',
    'Giờ Dần (03:00 - 05:00)',
    'Giờ Mão (05:00 - 07:00)',
    'Giờ Thìn (07:00 - 09:00)',
    'Giờ Tỵ (09:00 - 11:00)',
    'Giờ Ngọ (11:00 - 13:00)',
    'Giờ Mùi (13:00 - 15:00)',
    'Giờ Thân (15:00 - 17:00)',
    'Giờ Dậu (17:00 - 19:00)',
    'Giờ Tuất (19:00 - 21:00)',
    'Giờ Hợi (21:00 - 23:00)',
  ];

  /// Họ và tên đầy đủ của gia chủ/người dùng
  final String fullName;

  /// Giới tính ('Nam' hoặc 'Nữ')
  final String gender;

  /// Ngày tháng năm sinh Dương lịch chuẩn
  final DateTime birthDate;

  /// Đánh dấu người dùng nhập ngày sinh gốc là Âm lịch hay Dương lịch
  final bool isLunarBirth;

  /// Đánh dấu tháng nhuận nếu người dùng nhập theo Âm lịch
  final bool isLeapBirthMonth;

  /// Chỉ số giờ sinh theo 12 Can Chi (0: Tý 23h-01h, 1: Sửu 01h-03h, ..., 11: Hợi 21h-23h)
  final int birthHourIndex;

  /// Địa chỉ nơi ở - dùng để tự động điền vào văn khấn
  final String address;

  /// Cỡ chữ đọc văn khấn ưa thích
  final double prayerFontSize;

  /// Thời điểm cập nhật (UTC) phục vụ đồng bộ 2 chiều
  final DateTime updatedAt;

  const UserProfile({
    required this.fullName,
    required this.gender,
    required this.birthDate,
    required this.isLunarBirth,
    this.isLeapBirthMonth = false,
    required this.birthHourIndex,
    required this.address,
    this.prayerFontSize = 18.0,
    required this.updatedAt,
  });

  factory UserProfile.defaultProfile() => UserProfile(
        fullName: '',
        gender: 'Nam',
        birthDate: DateTime(1990, 6, 15),
        isLunarBirth: false,
        isLeapBirthMonth: false,
        birthHourIndex: 4, // Mặc định Giờ Thìn (07:00 - 09:00)
        address: '',
        prayerFontSize: 18.0,
        updatedAt: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      );

  /// Chuẩn hóa giới tính sang 'Nam' hoặc 'Nữ'
  static String normalizeGender(String raw) {
    final lower = raw.trim().toLowerCase();
    if (lower == 'female' || lower == 'nữ' || lower == 'nu') {
      return 'Nữ';
    }
    return 'Nam';
  }

  bool get isFemale => normalizeGender(gender) == 'Nữ';

  String get genderLegacyCode => isFemale ? 'female' : 'male';

  /// Tên hiển thị khung giờ sinh (VD: "Giờ Thìn (07:00 - 09:00)")
  String get birthHourLabel {
    final idx = birthHourIndex.clamp(0, birthHourLabels.length - 1);
    return birthHourLabels[idx];
  }

  /// Quy đổi ngày sinh Dương lịch (`birthDate`) sang ngày Âm lịch tương ứng
  LunarDate get lunarBirthDate => LunarCalculator.solarToLunar(
        birthDate.day,
        birthDate.month,
        birthDate.year,
      );

  /// Ngày sinh gốc (theo hệ lịch người dùng chọn khi nhập)
  int get inputDay => isLunarBirth ? lunarBirthDate.day : birthDate.day;
  int get inputMonth => isLunarBirth ? lunarBirthDate.month : birthDate.month;
  int get inputYear => isLunarBirth ? lunarBirthDate.year : birthDate.year;

  /// Viết hoa chữ cái đầu mỗi từ trong Họ và tên
  static String capitalizeFullName(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return '';
    return trimmed
        .split(RegExp(r'\s+'))
        .map((word) {
          if (word.isEmpty) return '';
          return word[0].toUpperCase() + word.substring(1);
        })
        .join(' ');
  }

  UserProfile copyWith({
    String? fullName,
    String? gender,
    DateTime? birthDate,
    bool? isLunarBirth,
    bool? isLeapBirthMonth,
    int? birthHourIndex,
    String? address,
    double? prayerFontSize,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      fullName: fullName ?? this.fullName,
      gender: gender != null ? normalizeGender(gender) : this.gender,
      birthDate: birthDate ?? this.birthDate,
      isLunarBirth: isLunarBirth ?? this.isLunarBirth,
      isLeapBirthMonth: isLeapBirthMonth ?? this.isLeapBirthMonth,
      birthHourIndex:
          (birthHourIndex ?? this.birthHourIndex).clamp(0, 11),
      address: address ?? this.address,
      prayerFontSize: prayerFontSize ?? this.prayerFontSize,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    final lunar = lunarBirthDate;
    final inputD = isLunarBirth ? lunar.day : birthDate.day;
    final inputM = isLunarBirth ? lunar.month : birthDate.month;
    final inputY = isLunarBirth ? lunar.year : birthDate.year;

    return {
      'full_name': fullName,
      'gender': normalizeGender(gender),
      'gender_code': genderLegacyCode,
      'birth_date':
          '${birthDate.year.toString().padLeft(4, '0')}-${birthDate.month.toString().padLeft(2, '0')}-${birthDate.day.toString().padLeft(2, '0')}',
      'is_lunar_birth': isLunarBirth,
      'birth_hour_index': birthHourIndex.clamp(0, 11),
      'address': address,
      'prayer_font_size': prayerFontSize,
      'updated_at': updatedAt.toUtc().toIso8601String(),
      // Các trường tương thích ngược cho thiết bị cũ
      'birth_day': inputD,
      'birth_month': inputM,
      'birth_year': inputY,
      'is_lunar': isLunarBirth,
      'is_leap': isLunarBirth ? lunar.isLeap : isLeapBirthMonth,
    };
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final parsedUpdated = DateTime.tryParse(
          json['updated_at']?.toString() ?? '',
        )?.toUtc() ??
        DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);

    final isLunar = (json['is_lunar_birth'] as bool?) ??
        (json['is_lunar'] as bool?) ??
        false;
    final isLeap = (json['is_leap'] as bool?) ?? false;

    DateTime resolvedSolarDate = DateTime(1990, 6, 15);
    final rawBirthDate = json['birth_date']?.toString();
    if (rawBirthDate != null && rawBirthDate.isNotEmpty) {
      final parsed = DateTime.tryParse(rawBirthDate);
      if (parsed != null) {
        resolvedSolarDate = DateTime(parsed.year, parsed.month, parsed.day);
      }
    } else {
      final d = ((json['birth_day'] as num?)?.toInt() ?? 15).clamp(1, 31);
      final m = ((json['birth_month'] as num?)?.toInt() ?? 6).clamp(1, 12);
      final y = ((json['birth_year'] as num?)?.toInt() ?? 1990).clamp(1900, 2100);
      if (isLunar) {
        final s = LunarCalculator.lunarToSolar(d.clamp(1, 30), m, y, isLeap);
        resolvedSolarDate = DateTime(s.year, s.month, s.day);
      } else {
        final maxD = DateTime(y, m + 1, 0).day;
        resolvedSolarDate = DateTime(y, m, d > maxD ? maxD : d);
      }
    }

    final rawGender =
        json['gender']?.toString() ?? json['gender_code']?.toString() ?? 'Nam';

    return UserProfile(
      fullName: json['full_name']?.toString() ?? '',
      gender: normalizeGender(rawGender),
      birthDate: resolvedSolarDate,
      isLunarBirth: isLunar,
      isLeapBirthMonth: isLeap,
      birthHourIndex:
          ((json['birth_hour_index'] as num?)?.toInt() ?? 4).clamp(0, 11),
      address: json['address']?.toString() ?? '',
      prayerFontSize: (json['prayer_font_size'] as num?)?.toDouble() ?? 18.0,
      updatedAt: parsedUpdated,
    );
  }
}
