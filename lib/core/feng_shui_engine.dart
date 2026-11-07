import 'dart:convert';
import 'package:flutter/services.dart';
import 'lunar_calculator.dart';

class TrucInfo {
  final String name;
  final String good;
  final String bad;

  const TrucInfo({
    required this.name,
    required this.good,
    required this.bad,
  });

  factory TrucInfo.fromJson(Map<String, dynamic> json) => TrucInfo(
        name: json['name'] as String,
        good: json['good'] as String,
        bad: json['bad'] as String,
      );
}

class TuInfo {
  final String name;
  final String animal;
  final String type;
  final String meaning;

  const TuInfo({
    required this.name,
    required this.animal,
    required this.type,
    required this.meaning,
  });

  factory TuInfo.fromJson(Map<String, dynamic> json) => TuInfo(
        name: json['name'] as String,
        animal: json['animal'] as String,
        type: json['type'] as String,
        meaning: json['meaning'] as String,
      );
}

class AuspiciousHour {
  final String chi;
  final String timeRange;

  const AuspiciousHour({
    required this.chi,
    required this.timeRange,
  });
}

class DepartureDirection {
  final String hyThan;
  final String taiThan;
  final String hacThan;

  const DepartureDirection({
    required this.hyThan,
    required this.taiThan,
    required this.hacThan,
  });
}

/// Thông tin 1 khung giờ xuất hành theo Lý Thuần Phong (trong 12 canh giờ)
class LyThuanPhongHour {
  final String chi;
  final String timeRange;
  final String name;
  final bool isGood;
  final String description;

  const LyThuanPhongHour({
    required this.chi,
    required this.timeRange,
    required this.name,
    required this.isGood,
    required this.description,
  });
}

/// Bộ máy tính Can Chi, Trực, Nhị Thập Bát Tú, Giờ Hoàng Đạo & Hướng Xuất Hành
class FengShuiEngine {
  static const List<String> thienCan = [
    'Giáp',
    'Ất',
    'Bính',
    'Đinh',
    'Mậu',
    'Kỷ',
    'Canh',
    'Tân',
    'Nhâm',
    'Quý',
  ];

  static const List<String> diaChi = [
    'Tý',
    'Sửu',
    'Dần',
    'Mão',
    'Thìn',
    'Tỵ',
    'Ngọ',
    'Mùi',
    'Thân',
    'Dậu',
    'Tuất',
    'Hợi',
  ];

  static const List<String> tietKhiNames = [
    'Xuân Phân',
    'Thanh Minh',
    'Cốc Vũ',
    'Lập Hạ',
    'Tiểu Mãn',
    'Mang Chủng',
    'Hạ Chí',
    'Tiểu Thử',
    'Đại Thử',
    'Lập Thu',
    'Xử Thử',
    'Bạch Lộ',
    'Thu Phân',
    'Hàn Lộ',
    'Sương Giáng',
    'Lập Đông',
    'Tiểu Tuyết',
    'Đại Tuyết',
    'Đông Chí',
    'Tiểu Hàn',
    'Đại Hàn',
    'Lập Xuân',
    'Vũ Thủy',
    'Kinh Trập',
  ];

  static const Map<String, String> chiTimeRanges = {
    'Tý': '23:00 - 01:00',
    'Sửu': '01:00 - 03:00',
    'Dần': '03:00 - 05:00',
    'Mão': '05:00 - 07:00',
    'Thìn': '07:00 - 09:00',
    'Tỵ': '09:00 - 11:00',
    'Ngọ': '11:00 - 13:00',
    'Mùi': '13:00 - 15:00',
    'Thân': '15:00 - 17:00',
    'Dậu': '17:00 - 19:00',
    'Tuất': '19:00 - 21:00',
    'Hợi': '21:00 - 23:00',
  };

  static List<TrucInfo> _trucList = const [
    TrucInfo(
      name: 'Kiến',
      good: 'Xuất hành, giá thú, cầu tài lộc, khai trương',
      bad: 'Động thổ, chôn cất, đào giếng',
    ),
    TrucInfo(
      name: 'Trừ',
      good: 'Cúng tế, cầu phúc, giải hạn, chữa bệnh',
      bad: 'Khai trương, xuất hành xa, ký hợp đồng lớn',
    ),
    TrucInfo(
      name: 'Mãn',
      good: 'Cầu tài, khai trương, xuất hành, sửa kho',
      bad: 'Chôn cất, kiện tụng, nhậm chức',
    ),
    TrucInfo(
      name: 'Bình',
      good: 'Tu tạo, sửa chữa nhà cửa, cưới hỏi, giao dịch',
      bad: 'Đào mương, chôn cất',
    ),
    TrucInfo(
      name: 'Định',
      good: 'Ký kết hợp đồng, buôn bán, nhập học',
      bad: 'Thưa kiện, xuất hành đường xa',
    ),
    TrucInfo(
      name: 'Chấp',
      good: 'Xây dựng, tu sửa, gieo trồng, cưới hỏi',
      bad: 'Xuất tiền của, dời nhà, đi xa',
    ),
    TrucInfo(
      name: 'Phá',
      good: 'Phá dỡ công trình cũ, chữa bệnh',
      bad: 'Khai trương, cưới hỏi, ký hợp đồng',
    ),
    TrucInfo(
      name: 'Nguy',
      good: 'Cúng bái, cầu an, kê giường',
      bad: 'Đi thuyền, leo cao, xuất hành xa, động thổ',
    ),
    TrucInfo(
      name: 'Thành',
      good: 'Khai trương, nhập học, cưới hỏi, dời nhà',
      bad: 'Kiện tụng, tranh chấp',
    ),
    TrucInfo(
      name: 'Thu',
      good: 'Thu hoạch, cất trữ, mua bán, lập khế ước',
      bad: 'An táng, khởi công, xuất hành',
    ),
    TrucInfo(
      name: 'Khai',
      good: 'Khai trương, động thổ, cưới hỏi, xuất hành',
      bad: 'An táng, tranh chấp',
    ),
    TrucInfo(
      name: 'Bế',
      good: 'Đắp đê, xây tường, cất giữ tài vật',
      bad: 'Khai trương, xuất hành, nhậm chức',
    ),
  ];

  static List<TuInfo> _tuList = const [
    TuInfo(
      name: 'Giác',
      animal: 'Giao long',
      type: 'Cát',
      meaning: 'Thuận lợi cho thi cử, cưới hỏi, xây dựng.',
    ),
    TuInfo(
      name: 'Cang',
      animal: 'Rồng',
      type: 'Hung',
      meaning: 'Kỵ cưới hỏi, khởi công xây dựng.',
    ),
    TuInfo(
      name: 'Đê',
      animal: 'Lạc hoàn',
      type: 'Hung',
      meaning: 'Kỵ khai trương, cưới hỏi, đi thuyền.',
    ),
    TuInfo(
      name: 'Phòng',
      animal: 'Thỏ',
      type: 'Cát',
      meaning: 'Đại cát, vượng tài lộc, cưới hỏi, xây cất đều tốt.',
    ),
  ];

  static Map<String, List<String>> _gioHoangDaoMap = const {
    'Tý': ['Tý', 'Sửu', 'Mão', 'Ngọ', 'Thân', 'Dậu'],
    'Ngọ': ['Tý', 'Sửu', 'Mão', 'Ngọ', 'Thân', 'Dậu'],
    'Sửu': ['Dần', 'Mão', 'Tỵ', 'Thân', 'Tuất', 'Hợi'],
    'Mùi': ['Dần', 'Mão', 'Tỵ', 'Thân', 'Tuất', 'Hợi'],
    'Dần': ['Tý', 'Sửu', 'Thìn', 'Tỵ', 'Mùi', 'Tuất'],
    'Thân': ['Tý', 'Sửu', 'Thìn', 'Tỵ', 'Mùi', 'Tuất'],
    'Mão': ['Tý', 'Dần', 'Mão', 'Ngọ', 'Mùi', 'Dậu'],
    'Dậu': ['Tý', 'Dần', 'Mão', 'Ngọ', 'Mùi', 'Dậu'],
    'Thìn': ['Dần', 'Thìn', 'Tỵ', 'Thân', 'Dậu', 'Hợi'],
    'Tuất': ['Dần', 'Thìn', 'Tỵ', 'Thân', 'Dậu', 'Hợi'],
    'Tỵ': ['Sửu', 'Thìn', 'Ngọ', 'Mùi', 'Tuất', 'Hợi'],
    'Hợi': ['Sửu', 'Thìn', 'Ngọ', 'Mùi', 'Tuất', 'Hợi'],
  };

  /// Nạp dữ liệu bảng tra từ `assets/data/feng_shui_rules.json`
  static Future<void> loadRules() async {
    try {
      final raw = await rootBundle.loadString('assets/data/feng_shui_rules.json');
      final data = json.decode(raw) as Map<String, dynamic>;
      if (data['truc'] is List) {
        _trucList = (data['truc'] as List)
            .map((e) => TrucInfo.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      if (data['tu'] is List) {
        _tuList = (data['tu'] as List)
            .map((e) => TuInfo.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      if (data['gio_hoang_dao'] is Map) {
        final map = data['gio_hoang_dao'] as Map<String, dynamic>;
        _gioHoangDaoMap = map.map(
          (k, v) => MapEntry(k, (v as List).map((e) => e.toString()).toList()),
        );
      }
    } catch (_) {
      // Sử dụng dữ liệu mặc định nếu chưa load được asset
    }
  }

  /// Can Chi của năm Âm lịch
  static String getYearCanChi(int lunarYear) {
    final String can = thienCan[(lunarYear + 6) % 10];
    final String chi = diaChi[(lunarYear + 8) % 12];
    return '$can $chi';
  }

  /// Can Chi của tháng Âm lịch
  static String getMonthCanChi(int lunarMonth, int lunarYear) {
    final String can = thienCan[(lunarYear * 12 + lunarMonth + 3) % 10];
    final String chi = diaChi[(lunarMonth + 1) % 12];
    return '$can $chi';
  }

  /// Can Chi của ngày theo Julian Day
  static String getDayCanChi(int jd) {
    final String can = thienCan[(jd + 9) % 10];
    final String chi = diaChi[(jd + 1) % 12];
    return '$can $chi';
  }

  /// Can Chi của giờ Tý khởi đầu trong ngày
  static String getFirstHourCanChi(int jd) {
    final int dayCanIndex = (jd + 9) % 10;
    final int hourCanIndex = (dayCanIndex * 2) % 10;
    return '${thienCan[hourCanIndex]} Tý';
  }

  /// Lấy Địa Chi của ngày (0..11)
  static int getDayChiIndex(int jd) => (jd + 1) % 12;

  /// Lấy Thiên Can của ngày (0..9)
  static int getDayCanIndex(int jd) => (jd + 9) % 10;

  /// Tính Tiết Khí của ngày
  static String getSolarTerm(int jd) {
    final int index = LunarCalculator.getSolarTermIndex(jd);
    return tietKhiNames[index % tietKhiNames.length];
  }

  /// Tính Trực của ngày dựa trên tháng Âm lịch và Địa Chi của ngày
  static TrucInfo getTruc(int jd, int lunarMonth) {
    final int dayChi = getDayChiIndex(jd);
    final int monthBranch = (lunarMonth + 1) % 12;
    final int trucIndex = (dayChi - monthBranch + 12) % 12;
    return _trucList[trucIndex % _trucList.length];
  }

  /// Tính sao trong Nhị Thập Bát Tú theo Julian Day
  static TuInfo getNhiThapBatTu(int jd) {
    final int index = (jd + 11) % _tuList.length;
    return _tuList[index];
  }

  /// Kiểm tra ngày Hoàng Đạo / Hắc Đạo
  static bool isHoangDaoDay(int jd, int lunarMonth) {
    const Map<int, List<int>> hoangDaoChiByMonth = {
      1: [0, 1, 4, 5, 7, 10],
      7: [0, 1, 4, 5, 7, 10],
      2: [2, 3, 6, 7, 9, 0],
      8: [2, 3, 6, 7, 9, 0],
      3: [4, 5, 8, 9, 11, 2],
      9: [4, 5, 8, 9, 11, 2],
      4: [6, 7, 10, 11, 1, 4],
      10: [6, 7, 10, 11, 1, 4],
      5: [8, 9, 0, 1, 3, 6],
      11: [8, 9, 0, 1, 3, 6],
      6: [10, 11, 2, 3, 5, 8],
      12: [10, 11, 2, 3, 5, 8],
    };
    final int dayChi = getDayChiIndex(jd);
    return hoangDaoChiByMonth[lunarMonth]?.contains(dayChi) ?? false;
  }

  /// Danh sách 6 Giờ Hoàng Đạo trong ngày
  static List<AuspiciousHour> getAuspiciousHours(int jd) {
    final String dayChi = diaChi[getDayChiIndex(jd)];
    final List<String> branches = _gioHoangDaoMap[dayChi] ?? [];
    return branches
        .map(
          (chi) => AuspiciousHour(
            chi: chi,
            timeRange: chiTimeRanges[chi] ?? '',
          ),
        )
        .toList();
  }

  /// Tính hướng xuất hành (Hỷ Thần, Tài Thần, Hắc Thần) theo Thiên Can ngày
  static DepartureDirection getDepartureDirection(int jd) {
    final String can = thienCan[getDayCanIndex(jd)];
    String hyThan;
    if (can == 'Giáp' || can == 'Kỷ') {
      hyThan = 'Đông Bắc';
    } else if (can == 'Ất' || can == 'Canh') {
      hyThan = 'Tây Bắc';
    } else if (can == 'Bính' || can == 'Tân') {
      hyThan = 'Tây Nam';
    } else if (can == 'Đinh' || can == 'Nhâm') {
      hyThan = 'Chính Nam';
    } else {
      hyThan = 'Đông Nam';
    }

    String taiThan;
    switch (can) {
      case 'Giáp':
      case 'Ất':
        taiThan = 'Đông Nam';
        break;
      case 'Bính':
      case 'Đinh':
        taiThan = 'Chính Đông';
        break;
      case 'Mậu':
        taiThan = 'Chính Bắc';
        break;
      case 'Kỷ':
        taiThan = 'Chính Nam';
        break;
      case 'Canh':
      case 'Tân':
        taiThan = 'Tây Nam';
        break;
      case 'Nhâm':
        taiThan = 'Chính Tây';
        break;
      default:
        taiThan = 'Tây Bắc';
    }

    final List<String> hacDirections = [
      'Đông Bắc',
      'Chính Đông',
      'Đông Nam',
      'Chính Nam',
      'Tây Nam',
      'Chính Tây',
      'Tây Bắc',
      'Chính Bắc',
    ];
    final String hacThan = hacDirections[jd % hacDirections.length];

    return DepartureDirection(
      hyThan: hyThan,
      taiThan: taiThan,
      hacThan: hacThan,
    );
  }

  static const List<Map<String, dynamic>> _lyThuanPhong6Hours = [
    {
      'name': 'Đại An',
      'isGood': true,
      'description':
          'Mọi việc đều tốt lành, cầu tài đi hướng Tây Nam, nhà cửa yên lành, người xuất hành đều bình yên.',
    },
    {
      'name': 'Lưu Niên',
      'isGood': false,
      'description':
          'Mưu sự khó thành, cầu lộc chưa thông, đề phòng miệng tiếng, việc quan hay giấy tờ nên hoãn lại.',
    },
    {
      'name': 'Tốc Hỷ',
      'isGood': true,
      'description':
          'Tin vui sắp tới, cầu lộc cầu tài đi hướng Nam đại lợi, gặp gỡ giao dịch hay xuất hành đều may mắn.',
    },
    {
      'name': 'Xích Khẩu',
      'isGood': false,
      'description':
          'Hay xảy ra tranh cãi, bất hòa, người đi xa nên hoãn lại, phòng lời ăn tiếng nói trong giao dịch.',
    },
    {
      'name': 'Tiểu Các',
      'isGood': true,
      'description':
          'Rất tốt lành, xuất hành gặp may, buôn bán có lời, phụ nữ có tin mừng, mọi việc trôi chảy êm đẹp.',
    },
    {
      'name': 'Không Vong',
      'isGood': false,
      'description':
          'Việc làm dễ gặp trở ngại, cầu tài không có lợi, người đi xa dễ trễ hẹn hoặc hao tốn tiền của.',
    },
  ];

  /// Bảng tra 12 khung giờ xuất hành Lý Thuần Phong trong ngày (Tý -> Hợi)
  /// Công thức Lục Nhâm Lý Thuần Phong: `(lunarMonth + lunarDay + chiIndex - 2) % 6`
  static List<LyThuanPhongHour> getLyThuanPhongHours(
    int lunarDay,
    int lunarMonth,
  ) {
    return List<LyThuanPhongHour>.generate(12, (chiIndex) {
      final String chi = diaChi[chiIndex];
      final int stateIndex = (lunarMonth + lunarDay + chiIndex - 2) % 6;
      final Map<String, dynamic> state = _lyThuanPhong6Hours[stateIndex];
      return LyThuanPhongHour(
        chi: chi,
        timeRange: chiTimeRanges[chi] ?? '',
        name: state['name'] as String,
        isGood: state['isGood'] as bool,
        description: state['description'] as String,
      );
    });
  }

  /// Trả về toàn bộ danh sách 12 Trực để đối chiếu
  static List<TrucInfo> get allTrucList => _trucList;
}
