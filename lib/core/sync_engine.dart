import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/models/user_profile.dart';
import 'lunar_calculator.dart';

/// Hồ sơ người dùng lưu trữ Local-First (Single Source of Truth)
class SyncUserProfile {
  final int birthDay;
  final int birthMonth;
  final int birthYear;
  final bool isLunar;
  final bool isLeap;
  final int birthHourIndex; // 0..11 (Tý..Hợi)
  final String gender; // 'male' | 'female'
  final String fullName;
  final String address;
  final double prayerFontSize;
  final DateTime updatedAt;

  const SyncUserProfile({
    required this.birthDay,
    required this.birthMonth,
    required this.birthYear,
    required this.isLunar,
    required this.isLeap,
    this.birthHourIndex = 4,
    required this.gender,
    required this.fullName,
    required this.address,
    required this.prayerFontSize,
    required this.updatedAt,
  });

  factory SyncUserProfile.defaultProfile() => SyncUserProfile(
        birthDay: 15,
        birthMonth: 6,
        birthYear: 1990,
        isLunar: false,
        isLeap: false,
        birthHourIndex: 4,
        gender: 'male',
        fullName: '',
        address: '',
        prayerFontSize: 18.0,
        updatedAt: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      );

  /// Chuyển đổi sang mô hình chuẩn `UserProfile` (`lib/data/models/user_profile.dart`)
  UserProfile toUserProfile() {
    DateTime solarBirthDate;
    if (isLunar) {
      final s = LunarCalculator.lunarToSolar(
        birthDay.clamp(1, 30),
        birthMonth.clamp(1, 12),
        birthYear.clamp(1900, 2100),
        isLeap,
      );
      solarBirthDate = DateTime(s.year, s.month, s.day);
    } else {
      final y = birthYear.clamp(1900, 2100);
      final m = birthMonth.clamp(1, 12);
      final maxD = DateTime(y, m + 1, 0).day;
      solarBirthDate = DateTime(y, m, birthDay.clamp(1, maxD));
    }

    return UserProfile(
      fullName: fullName,
      gender: UserProfile.normalizeGender(gender),
      birthDate: solarBirthDate,
      isLunarBirth: isLunar,
      isLeapBirthMonth: isLeap,
      birthHourIndex: birthHourIndex.clamp(0, 11),
      address: address,
      prayerFontSize: prayerFontSize,
      updatedAt: updatedAt,
    );
  }

  /// Tạo `SyncUserProfile` từ `UserProfile`
  factory SyncUserProfile.fromUserProfile(UserProfile userProfile) {
    final lunar = userProfile.lunarBirthDate;
    final bDay = userProfile.isLunarBirth
        ? lunar.day
        : userProfile.birthDate.day;
    final bMonth = userProfile.isLunarBirth
        ? lunar.month
        : userProfile.birthDate.month;
    final bYear = userProfile.isLunarBirth
        ? lunar.year
        : userProfile.birthDate.year;
    final bLeap = userProfile.isLunarBirth
        ? lunar.isLeap
        : userProfile.isLeapBirthMonth;

    return SyncUserProfile(
      birthDay: bDay,
      birthMonth: bMonth,
      birthYear: bYear,
      isLunar: userProfile.isLunarBirth,
      isLeap: bLeap,
      birthHourIndex: userProfile.birthHourIndex.clamp(0, 11),
      gender: userProfile.genderLegacyCode,
      fullName: userProfile.fullName,
      address: userProfile.address,
      prayerFontSize: userProfile.prayerFontSize,
      updatedAt: userProfile.updatedAt.toUtc(),
    );
  }

  SyncUserProfile copyWith({
    int? birthDay,
    int? birthMonth,
    int? birthYear,
    bool? isLunar,
    bool? isLeap,
    int? birthHourIndex,
    String? gender,
    String? fullName,
    String? address,
    double? prayerFontSize,
    DateTime? updatedAt,
  }) {
    return SyncUserProfile(
      birthDay: birthDay ?? this.birthDay,
      birthMonth: birthMonth ?? this.birthMonth,
      birthYear: birthYear ?? this.birthYear,
      isLunar: isLunar ?? this.isLunar,
      isLeap: isLeap ?? this.isLeap,
      birthHourIndex: (birthHourIndex ?? this.birthHourIndex).clamp(0, 11),
      gender: gender ?? this.gender,
      fullName: fullName ?? this.fullName,
      address: address ?? this.address,
      prayerFontSize: prayerFontSize ?? this.prayerFontSize,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    final userProf = toUserProfile();
    return {
      'birth_day': birthDay,
      'birth_month': birthMonth,
      'birth_year': birthYear,
      'is_lunar': isLunar,
      'is_leap': isLeap,
      'is_lunar_birth': isLunar,
      'birth_hour_index': birthHourIndex.clamp(0, 11),
      'birth_date':
          '${userProf.birthDate.year.toString().padLeft(4, '0')}-${userProf.birthDate.month.toString().padLeft(2, '0')}-${userProf.birthDate.day.toString().padLeft(2, '0')}',
      'gender': gender,
      'gender_label': userProf.gender,
      'full_name': fullName,
      'address': address,
      'prayer_font_size': prayerFontSize,
      'updated_at': updatedAt.toUtc().toIso8601String(),
    };
  }

  factory SyncUserProfile.fromJson(Map<String, dynamic> json) {
    final parsedUpdated = DateTime.tryParse(
          json['updated_at']?.toString() ?? '',
        )?.toUtc() ??
        DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);

    final isLunarVal = (json['is_lunar'] as bool?) ??
        (json['is_lunar_birth'] as bool?) ??
        false;
    final isLeapVal = json['is_leap'] as bool? ?? false;

    int bDay = (json['birth_day'] as num?)?.toInt() ?? 15;
    int bMonth = (json['birth_month'] as num?)?.toInt() ?? 6;
    int bYear = (json['birth_year'] as num?)?.toInt() ?? 1990;

    if (!json.containsKey('birth_day') && json['birth_date'] != null) {
      final parsedDate = DateTime.tryParse(json['birth_date'].toString());
      if (parsedDate != null) {
        if (isLunarVal) {
          final l = LunarCalculator.solarToLunar(
            parsedDate.day,
            parsedDate.month,
            parsedDate.year,
          );
          bDay = l.day;
          bMonth = l.month;
          bYear = l.year;
        } else {
          bDay = parsedDate.day;
          bMonth = parsedDate.month;
          bYear = parsedDate.year;
        }
      }
    }

    final rawGender = json['gender']?.toString() ?? 'male';
    final normalizedCode = UserProfile.normalizeGender(rawGender) == 'Nữ'
        ? 'female'
        : 'male';

    return SyncUserProfile(
      birthDay: bDay,
      birthMonth: bMonth,
      birthYear: bYear,
      isLunar: isLunarVal,
      isLeap: isLeapVal,
      birthHourIndex:
          ((json['birth_hour_index'] as num?)?.toInt() ?? 4).clamp(0, 11),
      gender: normalizedCode,
      fullName: json['full_name']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      prayerFontSize: (json['prayer_font_size'] as num?)?.toDouble() ?? 18.0,
      updatedAt: parsedUpdated,
    );
  }
}

/// Sự kiện / Ghi chú trên lịch (hỗ trợ Tombstone `isDeleted` + `updatedAt` + Thể loại & Lặp lại)
class CalendarEvent {
  final String id;
  final String title;
  final String note;
  final String solarDateKey; // YYYY-MM-DD
  final String category; // 'Giỗ chạp' | 'Sinh nhật' | 'Công việc' | 'Khác'
  final bool isLunarRecurring;
  final bool isSolarRecurring;
  final bool isDeleted;
  final DateTime updatedAt;

  const CalendarEvent({
    required this.id,
    required this.title,
    required this.note,
    required this.solarDateKey,
    this.category = 'Khác',
    this.isLunarRecurring = false,
    this.isSolarRecurring = false,
    this.isDeleted = false,
    required this.updatedAt,
  });

  CalendarEvent copyWith({
    String? title,
    String? note,
    String? solarDateKey,
    String? category,
    bool? isLunarRecurring,
    bool? isSolarRecurring,
    bool? isDeleted,
    DateTime? updatedAt,
  }) {
    return CalendarEvent(
      id: id,
      title: title ?? this.title,
      note: note ?? this.note,
      solarDateKey: solarDateKey ?? this.solarDateKey,
      category: category ?? this.category,
      isLunarRecurring: isLunarRecurring ?? this.isLunarRecurring,
      isSolarRecurring: isSolarRecurring ?? this.isSolarRecurring,
      isDeleted: isDeleted ?? this.isDeleted,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'note': note,
        'solar_date_key': solarDateKey,
        'category': category,
        'is_lunar_recurring': isLunarRecurring,
        'is_solar_recurring': isSolarRecurring,
        'is_deleted': isDeleted,
        'updated_at': updatedAt.toUtc().toIso8601String(),
      };

  factory CalendarEvent.fromJson(Map<String, dynamic> json) {
    final parsedUpdated = DateTime.tryParse(
          json['updated_at']?.toString() ?? '',
        )?.toUtc() ??
        DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);

    return CalendarEvent(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      note: json['note']?.toString() ?? '',
      solarDateKey: json['solar_date_key']?.toString() ?? '',
      category: json['category']?.toString() ?? 'Khác',
      isLunarRecurring: json['is_lunar_recurring'] as bool? ?? false,
      isSolarRecurring: json['is_solar_recurring'] as bool? ?? false,
      isDeleted: json['is_deleted'] as bool? ?? false,
      updatedAt: parsedUpdated,
    );
  }
}

/// Bộ máy Đồng bộ Đa Thiết Bị theo kiến trúc LOCAL-FIRST TUYỆT ĐỐI (Offline-First Architecture).
/// - UI chỉ đọc và ghi vào Local Storage (`SharedPreferences` + bộ nhớ đệm).
/// - Không bao giờ bắt UI `await` kết quả mạng từ Supabase.
/// - Mọi lỗi mạng được xử lý im lặng (Silent Failure), tự động đồng bộ lại khi có mạng.
class SyncEngine extends ChangeNotifier {
  static const String supabaseUrl = 'https://bnviaszjhkpotlfrobwm.supabase.co';
  static const String supabaseAnonKey =
      'sb_publishable_L8bqzT92o1Ijf-Z9xSoOAg_NInYjzqo';
  static const String vaultTable = 'sync_vault';

  // Các khóa lưu trữ Local Storage
  static const String _keySyncCode = 'local_sync_code';
  static const String _keyIsDirty = 'local_sync_is_dirty';
  static const String _keyLastSyncedAt = 'local_last_synced_at';
  static const String _keyProfileJson = 'local_sync_profile_json';
  static const String _keyEventsJson = 'local_sync_events_json';

  // Tương thích với các khóa cũ của Horoscope & Prayers
  static const String _legacyBirthDayKey = 'horoscope_birth_day';
  static const String _legacyBirthMonthKey = 'horoscope_birth_month';
  static const String _legacyBirthYearKey = 'horoscope_birth_year';
  static const String _legacyIsLunarKey = 'horoscope_is_lunar';
  static const String _legacyIsLeapKey = 'horoscope_is_leap';
  static const String _legacyBirthHourKey = 'horoscope_birth_hour_index';
  static const String _legacyGenderKey = 'horoscope_gender';
  static const String _legacyUserNameKey = 'prayer_user_fullname';
  static const String _legacyUserAddressKey = 'prayer_user_address';
  static const String _legacyFontSizeKey = 'prayer_font_size';

  static final SyncEngine instance = SyncEngine._internal();

  SyncEngine._internal();

  bool _supabaseReady = false;
  bool _isSyncing = false;
  bool _isDirty = false;
  bool _wasOffline = false;
  String? _syncCode;
  DateTime? _lastSyncedAt;

  SyncUserProfile _localProfile = SyncUserProfile.defaultProfile();
  final Map<String, CalendarEvent> _localEvents = {};
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  // Getters cho UI (Đọc trực tiếp từ Local Cache 0ms)
  String? get syncCode => _syncCode;
  bool get isPaired => _syncCode != null && _syncCode!.length == 6;
  bool get isDirty => _isDirty;
  bool get isSyncing => _isSyncing;
  DateTime? get lastSyncedAt => _lastSyncedAt;
  SyncUserProfile get profile => _localProfile;

  /// Hồ sơ chuẩn `UserProfile` đọc trực tiếp từ Local Cache (0ms latency)
  UserProfile get userProfile => _localProfile.toUserProfile();

  /// Định dạng mã đồng bộ `xxx-xxx`
  String get formattedSyncCode {
    if (_syncCode == null || _syncCode!.length != 6) return '---';
    return '${_syncCode!.substring(0, 3)}-${_syncCode!.substring(3)}';
  }

  /// Lấy danh sách sự kiện chưa xóa từ Local Cache
  List<CalendarEvent> get activeEvents {
    final list = _localEvents.values.where((e) => !e.isDeleted).toList();
    list.sort((a, b) => a.solarDateKey.compareTo(b.solarDateKey));
    return list;
  }

  /// Lấy danh sách sự kiện của một ngày cụ thể (YYYY-MM-DD)
  List<CalendarEvent> eventsForDate(DateTime date) {
    final key = formatDateKey(date);
    return _localEvents.values
        .where((e) => !e.isDeleted && e.solarDateKey == key)
        .toList();
  }

  static String formatDateKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  /// Khởi tạo Local Cache & Lắng nghe thay đổi kết nối mạng
  Future<void> initLocalAndBackgroundListener({
    bool supabaseInitialized = false,
  }) async {
    _supabaseReady = supabaseInitialized;
    await _loadFromLocalStorage();
    _setupConnectivityListener();

    // Nếu đã ghép đôi, chạy đồng bộ ngầm lần đầu (fire-and-forget, không chặn UI)
    if (isPaired) {
      unawaited(syncNow());
    }
  }

  void markSupabaseInitialized(bool ready) {
    _supabaseReady = ready;
  }

  /// Nạp toàn bộ dữ liệu từ Local Storage (SharedPreferences)
  Future<void> _loadFromLocalStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _syncCode = prefs.getString(_keySyncCode);
      _isDirty = prefs.getBool(_keyIsDirty) ?? false;

      final lastSyncRaw = prefs.getString(_keyLastSyncedAt);
      if (lastSyncRaw != null) {
        _lastSyncedAt = DateTime.tryParse(lastSyncRaw);
      }

      // Đọc Profile từ JSON hoặc khôi phục từ các khóa đơn lẻ hiện có
      final rawProfile = prefs.getString(_keyProfileJson);
      if (rawProfile != null && rawProfile.isNotEmpty) {
        _localProfile = SyncUserProfile.fromJson(
          json.decode(rawProfile) as Map<String, dynamic>,
        );
      } else {
        _localProfile = SyncUserProfile(
          birthDay: prefs.getInt(_legacyBirthDayKey) ?? 15,
          birthMonth: prefs.getInt(_legacyBirthMonthKey) ?? 6,
          birthYear: prefs.getInt(_legacyBirthYearKey) ?? 1990,
          isLunar: prefs.getBool(_legacyIsLunarKey) ?? false,
          isLeap: prefs.getBool(_legacyIsLeapKey) ?? false,
          birthHourIndex: prefs.getInt(_legacyBirthHourKey) ?? 4,
          gender: prefs.getString(_legacyGenderKey) ?? 'male',
          fullName: prefs.getString(_legacyUserNameKey) ?? '',
          address: prefs.getString(_legacyUserAddressKey) ?? '',
          prayerFontSize: prefs.getDouble(_legacyFontSizeKey) ?? 18.0,
          updatedAt: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
        );
      }

      // Đọc danh sách Sự kiện / Ghi chú từ Local JSON
      final rawEvents = prefs.getString(_keyEventsJson);
      if (rawEvents != null && rawEvents.isNotEmpty) {
        final decoded = json.decode(rawEvents) as List<dynamic>;
        _localEvents.clear();
        for (final item in decoded) {
          final event = CalendarEvent.fromJson(item as Map<String, dynamic>);
          if (event.id.isNotEmpty) {
            _localEvents[event.id] = event;
          }
        }
      }
      notifyListeners();
    } catch (e) {
      debugPrint('[SyncEngine] Load local cache silent warning: $e');
    }
  }

  /// Lưu ngay vào Local Storage (Single Source of Truth)
  Future<void> _persistToLocalStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_syncCode != null) {
        await prefs.setString(_keySyncCode, _syncCode!);
      } else {
        await prefs.remove(_keySyncCode);
      }
      await prefs.setBool(_keyIsDirty, _isDirty);
      if (_lastSyncedAt != null) {
        await prefs.setString(
          _keyLastSyncedAt,
          _lastSyncedAt!.toUtc().toIso8601String(),
        );
      }

      await prefs.setString(
        _keyProfileJson,
        json.encode(_localProfile.toJson()),
      );

      // Đồng bộ ngược lại các khóa đơn lẻ để mọi màn hình đọc tức thì
      await prefs.setInt(_legacyBirthDayKey, _localProfile.birthDay);
      await prefs.setInt(_legacyBirthMonthKey, _localProfile.birthMonth);
      await prefs.setInt(_legacyBirthYearKey, _localProfile.birthYear);
      await prefs.setBool(_legacyIsLunarKey, _localProfile.isLunar);
      await prefs.setBool(_legacyIsLeapKey, _localProfile.isLeap);
      await prefs.setInt(_legacyBirthHourKey, _localProfile.birthHourIndex);
      await prefs.setString(_legacyGenderKey, _localProfile.gender);
      await prefs.setString(_legacyUserNameKey, _localProfile.fullName);
      await prefs.setString(_legacyUserAddressKey, _localProfile.address);
      await prefs.setDouble(_legacyFontSizeKey, _localProfile.prayerFontSize);

      final eventsList = _localEvents.values.map((e) => e.toJson()).toList();
      await prefs.setString(_keyEventsJson, json.encode(eventsList));
    } catch (e) {
      debugPrint('[SyncEngine] Persist local storage silent warning: $e');
    }
  }

  /// Lắng nghe sự kiện mạng: Khi chuyển từ Offline -> Online thì tự động gọi `syncNow()` ngầm
  void _setupConnectivityListener() {
    try {
      _connectivitySubscription?.cancel();
      _connectivitySubscription = Connectivity()
          .onConnectivityChanged
          .listen((List<ConnectivityResult> results) {
        final isOfflineNow = results.isEmpty ||
            results.every((r) => r == ConnectivityResult.none);
        if (isOfflineNow) {
          _wasOffline = true;
        } else {
          if (_wasOffline || _isDirty) {
            _wasOffline = false;
            unawaited(syncNow());
          }
        }
      }, onError: (Object err) {
        debugPrint('[SyncEngine] Connectivity listener silent error: $err');
      });
    } catch (e) {
      debugPrint('[SyncEngine] Connectivity setup silent warning: $e');
    }
  }

  // ==================== CÁC THAO TÁC CẬP NHẬT LOCAL-FIRST (0ms UI) ====================

  /// Cập nhật Hồ sơ người dùng -> Lưu Local ngay -> Gán `is_dirty = true` -> Trigger Sync ngầm
  void updateProfileLocalFirst({
    int? birthDay,
    int? birthMonth,
    int? birthYear,
    bool? isLunar,
    bool? isLeap,
    int? birthHourIndex,
    String? gender,
    String? fullName,
    String? address,
    double? prayerFontSize,
  }) {
    final nowUtc = DateTime.now().toUtc();
    _localProfile = _localProfile.copyWith(
      birthDay: birthDay,
      birthMonth: birthMonth,
      birthYear: birthYear,
      isLunar: isLunar,
      isLeap: isLeap,
      birthHourIndex: birthHourIndex,
      gender: gender,
      fullName: fullName,
      address: address,
      prayerFontSize: prayerFontSize,
      updatedAt: nowUtc,
    );
    _isDirty = true;
    notifyListeners();

    unawaited(_persistToLocalStorage());
    if (isPaired) {
      unawaited(syncNow());
    }
  }

  /// Lưu trực tiếp đối tượng `UserProfile` chuẩn Local-First (0ms) & kích hoạt đồng bộ ngầm
  void saveUserProfileLocalFirst(UserProfile updatedUserProfile) {
    final nowUtc = DateTime.now().toUtc();
    _localProfile = SyncUserProfile.fromUserProfile(
      updatedUserProfile.copyWith(updatedAt: nowUtc),
    );
    _isDirty = true;
    notifyListeners();

    unawaited(_persistToLocalStorage());
    if (isPaired) {
      unawaited(syncNow());
    }
  }

  /// Thêm hoặc Sửa sự kiện/ghi chú -> Lưu Local ngay -> Gán `is_dirty = true` -> Trigger Sync ngầm
  void upsertEventLocalFirst({
    String? id,
    required String title,
    required String note,
    required DateTime solarDate,
    String category = 'Khác',
    bool isLunarRecurring = false,
    bool isSolarRecurring = false,
  }) {
    final nowUtc = DateTime.now().toUtc();
    final eventId = id ??
        'evt_${nowUtc.millisecondsSinceEpoch}_${Random().nextInt(9000) + 1000}';
    final event = CalendarEvent(
      id: eventId,
      title: title.trim(),
      note: note.trim(),
      solarDateKey: formatDateKey(solarDate),
      category: category,
      isLunarRecurring: isLunarRecurring,
      isSolarRecurring: isSolarRecurring,
      isDeleted: false,
      updatedAt: nowUtc,
    );
    _localEvents[eventId] = event;
    _isDirty = true;
    notifyListeners();

    unawaited(_persistToLocalStorage());
    if (isPaired) {
      unawaited(syncNow());
    }
  }

  /// Xóa sự kiện theo cơ chế Tombstone (`is_deleted = true` kèm `updated_at = nowUtc`)
  void deleteEventLocalFirst(String eventId) {
    final existing = _localEvents[eventId];
    if (existing == null) return;

    final nowUtc = DateTime.now().toUtc();
    _localEvents[eventId] = existing.copyWith(
      isDeleted: true,
      updatedAt: nowUtc,
    );
    _isDirty = true;
    notifyListeners();

    unawaited(_persistToLocalStorage());
    if (isPaired) {
      unawaited(syncNow());
    }
  }

  // ==================== GHÉP ĐÔI THIẾT BỊ & MÃ ĐỒNG BỘ 6 SỐ ====================

  /// Sinh mã đồng bộ 6 chữ số ngẫu nhiên, lưu Local và đẩy snapshot đầu tiên ngầm
  Future<String> createNewSyncCode() async {
    final rng = Random.secure();
    final code = (100000 + rng.nextInt(900000)).toString();
    _syncCode = code;
    _isDirty = true;
    // Đảm bảo hồ sơ local có timestamp hợp lệ để đẩy bản đầu tiên
    if (_localProfile.updatedAt.millisecondsSinceEpoch == 0) {
      _localProfile = _localProfile.copyWith(
        updatedAt: DateTime.now().toUtc(),
      );
    }
    notifyListeners();
    await _persistToLocalStorage();
    unawaited(syncNow());
    return code;
  }

  /// Kết nối với mã 6 số từ thiết bị khác
  Future<void> connectWithSyncCode(String rawCode) async {
    final digitsOnly = rawCode.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitsOnly.length != 6) return;

    _syncCode = digitsOnly;
    _isDirty = true;
    notifyListeners();
    await _persistToLocalStorage();
    unawaited(syncNow());
  }

  /// Ngắt kết nối mã đồng bộ (dữ liệu Local vẫn giữ nguyên an toàn)
  Future<void> disconnectSyncCode() async {
    _syncCode = null;
    _isDirty = false;
    notifyListeners();
    await _persistToLocalStorage();
  }

  // ==================== THUẬT TOÁN MERGE 2 CHIỀU THÔNG MINH ====================

  /// Hợp nhất 2 chiều giữa Local và bảng `sync_vault` trên Supabase.
  /// Mọi lỗi mạng đều được bắt im lặng (Silent Failure), tuyệt đối không ném ngoại lệ ra UI.
  Future<void> syncNow() async {
    if (!isPaired || _isSyncing || !_supabaseReady) {
      return;
    }

    _isSyncing = true;
    notifyListeners();

    try {
      final code = _syncCode!;
      final client = Supabase.instance.client;

      // 1. Kéo payload mới nhất từ bảng `sync_vault` theo `sync_code`
      final Map<String, dynamic>? row = await client
          .from(vaultTable)
          .select()
          .eq('sync_code', code)
          .maybeSingle()
          .timeout(const Duration(seconds: 10));

      Map<String, dynamic>? remotePayload;
      if (row != null) {
        final dynamic rawPayload = row['payload'] ?? row['data'];
        if (rawPayload is Map<String, dynamic>) {
          remotePayload = rawPayload;
        } else if (rawPayload is String && rawPayload.isNotEmpty) {
          remotePayload = json.decode(rawPayload) as Map<String, dynamic>;
        }
      }

      // 2 & 3. Hợp nhất dữ liệu 2 chiều (Profile + CalendarEvents với Tombstone)
      final mergeOutcome = mergePayloads(
        localProfile: _localProfile,
        localEvents: Map<String, CalendarEvent>.from(_localEvents),
        remotePayload: remotePayload,
      );

      _localProfile = mergeOutcome.mergedProfile;
      _localEvents
        ..clear()
        ..addAll(mergeOutcome.mergedEvents);

      // 4. Lưu kết quả hợp nhất chuẩn vào Local Database
      await _persistToLocalStorage();

      // 5. Nếu Local có dữ liệu mới hơn hoặc trên Cloud chưa có bản ghi -> Push lên Supabase
      if (mergeOutcome.shouldPushToRemote || row == null || _isDirty) {
        final nowIso = DateTime.now().toUtc().toIso8601String();
        final mergedPayload = {
          'profile': _localProfile.toJson(),
          'events': _localEvents.values.map((e) => e.toJson()).toList(),
          'updated_at': nowIso,
        };

        await client.from(vaultTable).upsert({
          'sync_code': code,
          'payload': mergedPayload,
          'updated_at': nowIso,
        }).timeout(const Duration(seconds: 10));
      }

      _isDirty = false;
      _lastSyncedAt = DateTime.now();
      await _persistToLocalStorage();
    } catch (e) {
      // Silent failure: Chỉ ghi log nội bộ, giữ _isDirty để đồng bộ lại khi mạng ổn định
      debugPrint('[SyncEngine] Silent sync warning (offline/timeout): $e');
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  /// Thuật toán Merge 2 chiều độc lập (có thể kiểm thử Unit Test trực tiếp):
  /// - So sánh `updated_at` của Profile.
  /// - Duyệt từng `event.id`, giữ cả sự kiện chỉ có ở Local hoặc Remote,
  ///   so sánh `updated_at` khi trùng ID và tôn trọng cờ xóa Tombstone (`is_deleted = true`).
  static MergeResult mergePayloads({
    required SyncUserProfile localProfile,
    required Map<String, CalendarEvent> localEvents,
    required Map<String, dynamic>? remotePayload,
  }) {
    if (remotePayload == null) {
      return MergeResult(
        mergedProfile: localProfile,
        mergedEvents: localEvents,
        shouldPushToRemote: true,
      );
    }

    bool localHasNewer = false;

    // Hợp nhất Profile theo `updated_at`
    SyncUserProfile mergedProfile = localProfile;
    if (remotePayload['profile'] is Map<String, dynamic>) {
      final remoteProfile = SyncUserProfile.fromJson(
        remotePayload['profile'] as Map<String, dynamic>,
      );
      if (remoteProfile.updatedAt.isAfter(localProfile.updatedAt)) {
        mergedProfile = remoteProfile;
      } else if (localProfile.updatedAt.isAfter(remoteProfile.updatedAt)) {
        localHasNewer = true;
      }
    } else {
      localHasNewer = true;
    }

    // Hợp nhất danh sách Sự kiện / Ghi chú (CalendarEvents)
    final Map<String, CalendarEvent> remoteEvents = {};
    if (remotePayload['events'] is List) {
      for (final raw in (remotePayload['events'] as List)) {
        if (raw is Map<String, dynamic>) {
          final evt = CalendarEvent.fromJson(raw);
          if (evt.id.isNotEmpty) {
            remoteEvents[evt.id] = evt;
          }
        }
      }
    }

    final Map<String, CalendarEvent> mergedEvents = {};
    final allIds = <String>{...localEvents.keys, ...remoteEvents.keys};

    for (final id in allIds) {
      final localEvt = localEvents[id];
      final remoteEvt = remoteEvents[id];

      if (localEvt != null && remoteEvt == null) {
        // Chỉ có ở Local -> giữ lại và đánh dấu cần đẩy lên Remote
        mergedEvents[id] = localEvt;
        localHasNewer = true;
      } else if (remoteEvt != null && localEvt == null) {
        // Chỉ có ở Remote -> kéo về Local
        mergedEvents[id] = remoteEvt;
      } else if (localEvt != null && remoteEvt != null) {
        // Có ở cả 2 bên -> so sánh `updated_at` (bao gồm cả trạng thái Tombstone `isDeleted`)
        if (remoteEvt.updatedAt.isAfter(localEvt.updatedAt)) {
          mergedEvents[id] = remoteEvt;
        } else {
          mergedEvents[id] = localEvt;
          if (localEvt.updatedAt.isAfter(remoteEvt.updatedAt)) {
            localHasNewer = true;
          }
        }
      }
    }

    return MergeResult(
      mergedProfile: mergedProfile,
      mergedEvents: mergedEvents,
      shouldPushToRemote: localHasNewer,
    );
  }
}

class MergeResult {
  final SyncUserProfile mergedProfile;
  final Map<String, CalendarEvent> mergedEvents;
  final bool shouldPushToRemote;

  const MergeResult({
    required this.mergedProfile,
    required this.mergedEvents,
    required this.shouldPushToRemote,
  });
}

/// Bí danh `CloudSyncService` liên kết trực tiếp với `SyncEngine` chuẩn Local-First
typedef CloudSyncService = SyncEngine;
