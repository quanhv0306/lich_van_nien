import 'feng_shui_engine.dart';
import 'lunar_calculator.dart';

/// Giới tính phục vụ tra cứu Cung Phi Bát Trạch & Cửu Diệu Niên Hạn
enum Gender {
  male,
  female;

  String get label => this == Gender.male ? 'Nam' : 'Nữ';
  String get fullLabel => this == Gender.male ? 'Nam mệnh' : 'Nữ mệnh';
}

/// Thông tin Ngũ Hành Bản Mệnh (60 Hoa Giáp / Lục Thập Hoa Giáp Nạp Âm)
class NapAmInfo {
  final String canChi;
  final String napAmName;
  final String vietnameseMeaning;
  final String element; // Kim, Mộc, Thủy, Hỏa, Thổ
  final String zodiacAnimal;
  final String zodiacSymbol;
  final String compatibleElements;
  final String incompatibleElements;

  const NapAmInfo({
    required this.canChi,
    required this.napAmName,
    required this.vietnameseMeaning,
    required this.element,
    required this.zodiacAnimal,
    required this.zodiacSymbol,
    required this.compatibleElements,
    required this.incompatibleElements,
  });
}

/// Một hướng trong Bát Trạch (4 hướng tốt / 4 hướng xấu)
class BatTrachDirection {
  final String starName; // Sinh Khí, Thiên Y, Diên Niên, Phục Vị / Tuyệt Mệnh, Ngũ Quỷ, Lục Sát, Họa Hại
  final String direction; // Bắc, Nam, Đông, Tây, Đông Bắc, Tây Bắc, Đông Nam, Tây Nam
  final bool isGood;
  final String meaning;

  const BatTrachDirection({
    required this.starName,
    required this.direction,
    required this.isGood,
    required this.meaning,
  });
}

/// Kết quả Cung Phi Bát Trạch
class CungPhiBatTrach {
  final String cungName; // Khảm, Cấn, Chấn, Tốn, Ly, Khôn, Đoài, Càn
  final String cungElement; // Thủy, Thổ, Mộc, Hỏa, Kim
  final String groupName; // Đông Tứ Mệnh hoặc Tây Tứ Mệnh
  final List<BatTrachDirection> goodDirections;
  final List<BatTrachDirection> badDirections;

  const CungPhiBatTrach({
    required this.cungName,
    required this.cungElement,
    required this.groupName,
    required this.goodDirections,
    required this.badDirections,
  });
}

/// Thông tin Sao chiếu mệnh & Hạn năm hiện tại (Cửu Diệu Niên Hạn)
class CuuDieuNienHan {
  final int lunarAge; // Tuổi mụ (tuổi Âm lịch)
  final String starName; // Thái Dương, Thái Âm, Mộc Đức, Vân Hớn, Thổ Tú, Thủy Diệu, Thái Bạch, La Hầu, Kế Đô
  final String starNature; // Cát tinh (Tốt), Trung tính, Hung tinh (Xấu)
  final bool isGoodStar;
  final String starDescription;
  final String hanName; // Huỳnh Tuyền, Tam Kheo, Ngũ Mộ, Thiên Tinh, Tán Tận (Toán Tận), Thiên La, Địa Võng, Diêm Vương
  final String hanDescription;
  final String adviceAndRemedy;

  const CuuDieuNienHan({
    required this.lunarAge,
    required this.starName,
    required this.starNature,
    required this.isGoodStar,
    required this.starDescription,
    required this.hanName,
    required this.hanDescription,
    required this.adviceAndRemedy,
  });
}

/// Thông tin Tam Tai, Kim Lâu, Hoang Ốc trong năm tra cứu
class YearlyTaboos {
  final int targetLunarYear;
  final String targetYearCanChi;
  final bool hasTamTai;
  final String tamTaiDetail;
  final bool hasKimLau;
  final String kimLauDetail;
  final bool hasHoangOc;
  final String hoangOcCung;
  final String hoangOcDetail;

  const YearlyTaboos({
    required this.targetLunarYear,
    required this.targetYearCanChi,
    required this.hasTamTai,
    required this.tamTaiDetail,
    required this.hasKimLau,
    required this.kimLauDetail,
    required this.hasHoangOc,
    required this.hoangOcCung,
    required this.hoangOcDetail,
  });

  bool get isGoodForBuilding => !hasTamTai && !hasKimLau && !hasHoangOc;
}

/// Hồ sơ tổng hợp Bản Mệnh, Cung Phi Bát Trạch & Vận Hạn Năm
class HoroscopeProfileResult {
  final SolarDate birthSolar;
  final LunarDate birthLunar;
  final Gender gender;
  final String yearCanChi;
  final String monthCanChi;
  final String dayCanChi;
  final NapAmInfo napAm;
  final CungPhiBatTrach batTrach;
  final CuuDieuNienHan cuuDieu;
  final YearlyTaboos taboos;

  const HoroscopeProfileResult({
    required this.birthSolar,
    required this.birthLunar,
    required this.gender,
    required this.yearCanChi,
    required this.monthCanChi,
    required this.dayCanChi,
    required this.napAm,
    required this.batTrach,
    required this.cuuDieu,
    required this.taboos,
  });
}

/// Bộ máy tính Tử Vi - Phong Thủy Bản Mệnh Offline 100%
class HoroscopeEngine {
  // Bảng 30 cặp Nạp Âm (Lục Thập Hoa Giáp: 2 năm liên tiếp cùng 1 Nạp Âm)
  static const List<Map<String, String>> _napAm30Table = [
    {
      'name': 'Hải Trung Kim',
      'meaning': 'Vàng trong biển',
      'element': 'Kim',
    },
    {
      'name': 'Lư Trung Hỏa',
      'meaning': 'Lửa trong lò',
      'element': 'Hỏa',
    },
    {
      'name': 'Đại Lâm Mộc',
      'meaning': 'Gỗ rừng già',
      'element': 'Mộc',
    },
    {
      'name': 'Lộ Bàng Thổ',
      'meaning': 'Đất ven đường',
      'element': 'Thổ',
    },
    {
      'name': 'Kiếm Phong Kim',
      'meaning': 'Vàng mũi kiếm',
      'element': 'Kim',
    },
    {
      'name': 'Sơn Đầu Hỏa',
      'meaning': 'Lửa trên đỉnh núi',
      'element': 'Hỏa',
    },
    {
      'name': 'Giản Hạ Thủy',
      'meaning': 'Nước dưới khe suối',
      'element': 'Thủy',
    },
    {
      'name': 'Thành Đầu Thổ',
      'meaning': 'Đất trên mặt thành',
      'element': 'Thổ',
    },
    {
      'name': 'Bạch Lạp Kim',
      'meaning': 'Vàng trong nến rắn',
      'element': 'Kim',
    },
    {
      'name': 'Dương Liễu Mộc',
      'meaning': 'Gỗ cây dương liễu',
      'element': 'Mộc',
    },
    {
      'name': 'Tuyền Trung Thủy',
      'meaning': 'Nước trong suối nguồn',
      'element': 'Thủy',
    },
    {
      'name': 'Ốc Thượng Thổ',
      'meaning': 'Đất trên mái nhà',
      'element': 'Thổ',
    },
    {
      'name': 'Tích Lịch Hỏa',
      'meaning': 'Lửa sấm sét',
      'element': 'Hỏa',
    },
    {
      'name': 'Tùng Bách Mộc',
      'meaning': 'Gỗ cây tùng bách',
      'element': 'Mộc',
    },
    {
      'name': 'Trường Lưu Thủy',
      'meaning': 'Dòng nước chảy dài',
      'element': 'Thủy',
    },
    {
      'name': 'Sa Trung Kim',
      'meaning': 'Vàng trong cát',
      'element': 'Kim',
    },
    {
      'name': 'Sơn Hạ Hỏa',
      'meaning': 'Lửa dưới chân núi',
      'element': 'Hỏa',
    },
    {
      'name': 'Bình Địa Mộc',
      'meaning': 'Gỗ đồng bằng',
      'element': 'Mộc',
    },
    {
      'name': 'Bích Thượng Thổ',
      'meaning': 'Đất trên vách tường',
      'element': 'Thổ',
    },
    {
      'name': 'Kim Bạc Kim',
      'meaning': 'Vàng pha bạch kim',
      'element': 'Kim',
    },
    {
      'name': 'Phúc Đăng Hỏa',
      'meaning': 'Lửa đèn chụp',
      'element': 'Hỏa',
    },
    {
      'name': 'Thiên Hà Thủy',
      'meaning': 'Nước trên ngân hà',
      'element': 'Thủy',
    },
    {
      'name': 'Đại Dịch Thổ',
      'meaning': 'Đất vùng đầm lầy rộng',
      'element': 'Thổ',
    },
    {
      'name': 'Thoa Xuyến Kim',
      'meaning': 'Vàng trang sức (trâm, vòng)',
      'element': 'Kim',
    },
    {
      'name': 'Tang Đố Mộc',
      'meaning': 'Gỗ cây dâu tằm',
      'element': 'Mộc',
    },
    {
      'name': 'Đại Khê Thủy',
      'meaning': 'Nước khe suối lớn',
      'element': 'Thủy',
    },
    {
      'name': 'Sa Trung Thổ',
      'meaning': 'Đất pha trong cát',
      'element': 'Thổ',
    },
    {
      'name': 'Thiên Thượng Hỏa',
      'meaning': 'Lửa trên bầu trời',
      'element': 'Hỏa',
    },
    {
      'name': 'Thạch Lựu Mộc',
      'meaning': 'Gỗ cây thạch lựu',
      'element': 'Mộc',
    },
    {
      'name': 'Đại Hải Thủy',
      'meaning': 'Nước biển lớn (Đại dương)',
      'element': 'Thủy',
    },
  ];

  static const Map<String, Map<String, String>> _zodiacByChi = {
    'Tý': {'animal': 'Chuột (Tý)', 'symbol': '🐭'},
    'Sửu': {'animal': 'Trâu (Sửu)', 'symbol': '🐮'},
    'Dần': {'animal': 'Hổ (Dần)', 'symbol': '🐯'},
    'Mão': {'animal': 'Mèo (Mão)', 'symbol': '🐱'},
    'Thìn': {'animal': 'Rồng (Thìn)', 'symbol': '🐲'},
    'Tỵ': {'animal': 'Rắn (Tỵ)', 'symbol': '🐍'},
    'Ngọ': {'animal': 'Ngựa (Ngọ)', 'symbol': '🐴'},
    'Mùi': {'animal': 'Dê (Mùi)', 'symbol': '🐐'},
    'Thân': {'animal': 'Khỉ (Thân)', 'symbol': '🐵'},
    'Dậu': {'animal': 'Gà (Dậu)', 'symbol': '🐔'},
    'Tuất': {'animal': 'Chó (Tuất)', 'symbol': '🐶'},
    'Hợi': {'animal': 'Heo (Hợi)', 'symbol': '🐷'},
  };

  /// 1. Tính Ngũ Hành Bản Mệnh (60 Hoa Giáp Nạp Âm) từ năm Âm lịch
  static NapAmInfo calculateNapAm(int lunarYear) {
    final String canChi = FengShuiEngine.getYearCanChi(lunarYear);
    final String chi = FengShuiEngine.diaChi[(lunarYear + 8) % 12];
    final int cycle60Index = ((lunarYear - 4) % 60 + 60) % 60;
    final int napAmIndex = cycle60Index ~/ 2;
    final item = _napAm30Table[napAmIndex];
    final String element = item['element']!;

    String compatible;
    String incompatible;
    switch (element) {
      case 'Kim':
        compatible = 'Thổ sinh Kim, Kim sinh Thủy, Kim hợp Kim';
        incompatible = 'Hỏa khắc Kim, Kim khắc Mộc';
        break;
      case 'Mộc':
        compatible = 'Thủy sinh Mộc, Mộc sinh Hỏa, Mộc hợp Mộc';
        incompatible = 'Kim khắc Mộc, Mộc khắc Thổ';
        break;
      case 'Thủy':
        compatible = 'Kim sinh Thủy, Thủy sinh Mộc, Thủy hợp Thủy';
        incompatible = 'Thổ khắc Thủy, Thủy khắc Hỏa';
        break;
      case 'Hỏa':
        compatible = 'Mộc sinh Hỏa, Hỏa sinh Thổ, Hỏa hợp Hỏa';
        incompatible = 'Thủy khắc Hỏa, Hỏa khắc Kim';
        break;
      case 'Thổ':
      default:
        compatible = 'Hỏa sinh Thổ, Thổ sinh Kim, Thổ hợp Thổ';
        incompatible = 'Mộc khắc Thổ, Thổ khắc Thủy';
        break;
    }

    final zodiac = _zodiacByChi[chi] ?? {'animal': chi, 'symbol': '☯'};

    return NapAmInfo(
      canChi: canChi,
      napAmName: item['name']!,
      vietnameseMeaning: item['meaning']!,
      element: element,
      zodiacAnimal: zodiac['animal']!,
      zodiacSymbol: zodiac['symbol']!,
      compatibleElements: compatible,
      incompatibleElements: incompatible,
    );
  }

  /// 2. Tính Cung Phi Bát Trạch (Khảm, Cấn, Chấn, Tốn, Ly, Khôn, Đoài, Càn)
  /// và phân nhóm Đông Tứ Mệnh / Tây Tứ Mệnh kèm 4 hướng tốt, 4 hướng xấu
  static CungPhiBatTrach calculateCungPhi(int lunarYear, Gender gender) {
    // Tính số Kua chuẩn theo năm Âm lịch
    int sumDigits(int n) {
      int s = n.abs();
      while (s > 9) {
        int next = 0;
        while (s > 0) {
          next += s % 10;
          s ~/= 10;
        }
        s = next;
      }
      return s;
    }

    final int lastTwoDigits = lunarYear % 100;
    final int reduced = sumDigits(lastTwoDigits);
    int kua;
    if (lunarYear < 2000) {
      if (gender == Gender.male) {
        kua = 10 - reduced;
      } else {
        kua = sumDigits(reduced + 5);
      }
    } else {
      if (gender == Gender.male) {
        kua = 9 - reduced;
        if (kua <= 0) kua += 9;
      } else {
        kua = sumDigits(reduced + 6);
      }
    }

    // Trường hợp Kua = 5 (Trung cung): Nam quy về Khôn (2), Nữ quy về Cấn (8)
    if (kua == 5) {
      kua = gender == Gender.male ? 2 : 8;
    }

    String cungName;
    String cungElement;
    bool isDongTuMenh;

    switch (kua) {
      case 1:
        cungName = 'Khảm';
        cungElement = 'Thủy';
        isDongTuMenh = true;
        break;
      case 2:
        cungName = 'Khôn';
        cungElement = 'Thổ';
        isDongTuMenh = false;
        break;
      case 3:
        cungName = 'Chấn';
        cungElement = 'Mộc';
        isDongTuMenh = true;
        break;
      case 4:
        cungName = 'Tốn';
        cungElement = 'Mộc';
        isDongTuMenh = true;
        break;
      case 6:
        cungName = 'Càn';
        cungElement = 'Kim';
        isDongTuMenh = false;
        break;
      case 7:
        cungName = 'Đoài';
        cungElement = 'Kim';
        isDongTuMenh = false;
        break;
      case 8:
        cungName = 'Cấn';
        cungElement = 'Thổ';
        isDongTuMenh = false;
        break;
      case 9:
      default:
        cungName = 'Ly';
        cungElement = 'Hỏa';
        isDongTuMenh = true;
        break;
    }

    // Bảng ánh xạ 8 hướng theo từng Cung Phi:
    // Thứ tự 4 hướng tốt: [Sinh Khí, Thiên Y, Diên Niên, Phục Vị]
    // Thứ tự 4 hướng xấu: [Tuyệt Mệnh, Ngũ Quỷ, Lục Sát, Họa Hại]
    const Map<String, Map<String, List<String>>> directionTable = {
      'Khảm': {
        'good': ['Đông Nam', 'Chính Đông', 'Chính Nam', 'Chính Bắc'],
        'bad': ['Tây Nam', 'Đông Bắc', 'Tây Bắc', 'Chính Tây'],
      },
      'Ly': {
        'good': ['Chính Đông', 'Đông Nam', 'Chính Bắc', 'Chính Nam'],
        'bad': ['Tây Bắc', 'Chính Tây', 'Tây Nam', 'Đông Bắc'],
      },
      'Chấn': {
        'good': ['Chính Nam', 'Chính Bắc', 'Đông Nam', 'Chính Đông'],
        'bad': ['Chính Tây', 'Tây Bắc', 'Đông Bắc', 'Tây Nam'],
      },
      'Tốn': {
        'good': ['Chính Bắc', 'Chính Nam', 'Chính Đông', 'Đông Nam'],
        'bad': ['Đông Bắc', 'Tây Nam', 'Chính Tây', 'Tây Bắc'],
      },
      'Càn': {
        'good': ['Chính Tây', 'Đông Bắc', 'Tây Nam', 'Tây Bắc'],
        'bad': ['Chính Nam', 'Chính Đông', 'Chính Bắc', 'Đông Nam'],
      },
      'Khôn': {
        'good': ['Đông Bắc', 'Chính Tây', 'Tây Bắc', 'Tây Nam'],
        'bad': ['Chính Bắc', 'Đông Nam', 'Chính Nam', 'Chính Đông'],
      },
      'Cấn': {
        'good': ['Tây Nam', 'Tây Bắc', 'Chính Tây', 'Đông Bắc'],
        'bad': ['Đông Nam', 'Chính Bắc', 'Chính Đông', 'Chính Nam'],
      },
      'Đoài': {
        'good': ['Tây Bắc', 'Tây Nam', 'Đông Bắc', 'Chính Tây'],
        'bad': ['Chính Đông', 'Chính Nam', 'Đông Nam', 'Chính Bắc'],
      },
    };

    final goodDirs = directionTable[cungName]!['good']!;
    final badDirs = directionTable[cungName]!['bad']!;

    const goodStars = [
      {
        'name': 'Sinh Khí',
        'meaning': 'Thu hút tài lộc, thăng quan tiến chức, vượng khí dồi dào.',
      },
      {
        'name': 'Thiên Y',
        'meaning': 'Che chở sức khỏe, tiêu trừ bệnh tật, gặp quý nhân phù trợ.',
      },
      {
        'name': 'Diên Niên',
        'meaning': 'Củng cố gia đạo êm ấm, tình duyên và quan hệ xã giao bền chặt.',
      },
      {
        'name': 'Phục Vị',
        'meaning': 'Tinh thần vững vàng, thi cử đỗ đạt, bình an may mắn.',
      },
    ];

    const badStars = [
      {
        'name': 'Tuyệt Mệnh',
        'meaning': 'Hướng đại hung, dễ tổn hao sức khỏe và tài sản, cần tránh mở cửa chính.',
      },
      {
        'name': 'Ngũ Quỷ',
        'meaning': 'Dễ gặp thị phi, tranh chấp miệng tiếng, hao tán tiền bạc.',
      },
      {
        'name': 'Lục Sát',
        'meaning': 'Bất ổn tình cảm gia đình, công việc dễ gặp trì trệ.',
      },
      {
        'name': 'Họa Hại',
        'meaning': 'Dễ vướng chuyện phiền toái vụn vặt, kém may mắn.',
      },
    ];

    return CungPhiBatTrach(
      cungName: cungName,
      cungElement: cungElement,
      groupName: isDongTuMenh ? 'Đông Tứ Mệnh' : 'Tây Tứ Mệnh',
      goodDirections: List.generate(
        4,
        (i) => BatTrachDirection(
          starName: goodStars[i]['name']!,
          direction: goodDirs[i],
          isGood: true,
          meaning: goodStars[i]['meaning']!,
        ),
      ),
      badDirections: List.generate(
        4,
        (i) => BatTrachDirection(
          starName: badStars[i]['name']!,
          direction: badDirs[i],
          isGood: false,
          meaning: badStars[i]['meaning']!,
        ),
      ),
    );
  }

  /// 3. Tính Cửu Diệu Niên Hạn (Sao chiếu mệnh & Hạn năm hiện tại)
  static CuuDieuNienHan calculateCuuDieu(
    int birthLunarYear,
    int currentLunarYear,
    Gender gender,
  ) {
    final int lunarAge = (currentLunarYear - birthLunarYear + 1).clamp(1, 150);

    // Chu kỳ 9 sao Cửu Diệu theo tuổi mụ (lunarAge % 9):
    // 余 1, 2, 3, 4, 5, 6, 7, 8, 0
    const List<String> maleStarsByMod9 = [
      'Mộc Đức', // mod 0 (9, 18, 27, 36, 45...)
      'La Hầu', // mod 1 (10, 19, 28, 37, 46...)
      'Thổ Tú', // mod 2 (11, 20, 29, 38...)
      'Thủy Diệu', // mod 3 (12, 21, 30, 39...)
      'Thái Bạch', // mod 4 (13, 22, 31, 40...)
      'Thái Dương', // mod 5 (14, 23, 32, 41...)
      'Vân Hớn', // mod 6 (15, 24, 33, 42...)
      'Kế Đô', // mod 7 (16, 25, 34, 43...)
      'Thái Âm', // mod 8 (17, 26, 35, 44...)
    ];

    const List<String> femaleStarsByMod9 = [
      'Thủy Diệu', // mod 0 (9, 18, 27, 36, 45...)
      'Kế Đô', // mod 1 (10, 19, 28, 37, 46...)
      'Vân Hớn', // mod 2 (11, 20, 29, 38...)
      'Mộc Đức', // mod 3 (12, 21, 30, 39...)
      'Thái Âm', // mod 4 (13, 22, 31, 40...)
      'Thổ Tú', // mod 5 (14, 23, 32, 41...)
      'La Hầu', // mod 6 (15, 24, 33, 42...)
      'Thái Dương', // mod 7 (16, 25, 34, 43...)
      'Thái Bạch', // mod 8 (17, 26, 35, 44...)
    ];

    final int mod9 = lunarAge % 9;
    final String starName = gender == Gender.male
        ? maleStarsByMod9[mod9]
        : femaleStarsByMod9[mod9];

    final Map<String, Map<String, dynamic>> starDetails = {
      'Thái Dương': {
        'nature': 'Đệ Nhất Cát Tinh (Rất Tốt)',
        'isGood': true,
        'desc':
            'Sao Thái Dương chủ về vượng lộc, công danh rạng rỡ, kinh doanh phát đạt, đi xa có lợi (nhất là tháng 6 và tháng 10 Âm lịch).',
        'remedy':
            'Giữ tâm chính trực, làm việc minh bạch để đón vượng khí. Ngày 27 Âm lịch hàng tháng có thể thắp hương hướng Đông cầu bình an.',
      },
      'Thái Âm': {
        'nature': 'Cát Tinh Tài Lộc & Điền Sản (Tốt)',
        'isGood': true,
        'desc':
            'Sao Thái Âm chủ về danh lợi lưỡng toàn, tốt cho mua bán nhà đất, hỷ sự (rất vượng vào tháng 9 Âm lịch, riêng tháng 11 cần giữ gìn sức khỏe).',
        'remedy':
            'Thuận lợi đầu tư tích lũy, chăm sóc sức khỏe mùa đông. Ngày 26 Âm lịch có thể hướng về phía Tây cầu an.',
      },
      'Mộc Đức': {
        'nature': 'Phúc Lộc Cát Tinh (Tốt)',
        'isGood': true,
        'desc':
            'Sao Mộc Đức mang tới quý nhân giúp đỡ, gia đạo an vui, có tin mừng cưới hỏi hoặc thăng tiến (vượng nhất vào tháng 10 và tháng Chạp).',
        'remedy':
            'Đề phòng bệnh nhẹ về mắt hoặc máu huyết đầu năm. Ngày 25 Âm lịch có thể làm việc thiện, hướng Đông Nam cầu phúc.',
      },
      'Thủy Diệu': {
        'nature': 'Tài Lộc Tinh (Khá Tốt)',
        'isGood': true,
        'desc':
            'Sao Thủy Diệu chủ về tài lộc bất ngờ, hỷ sự. Tuy nhiên cần cẩn trọng khi đi sông nước và giữ hòa khí vào tháng 4, tháng 8 Âm lịch.',
        'remedy':
            'Tránh tranh cãi thị phi, cẩn thận khi đi lại đường thủy. Ngày 21 Âm lịch có thể cầu bình an hướng Bắc.',
      },
      'Thổ Tú': {
        'nature': 'Trung Tinh (Bán Cát Bán Hung)',
        'isGood': false,
        'desc':
            'Sao Thổ Tú thử thách sự kiên trì, đầu năm dễ có chuyện buồn phiền hoặc tiểu nhân dèm pha (nhất là tháng 4 và tháng 8 Âm lịch).',
        'remedy':
            'Lấy nhu thắng cương, giữ tâm bình tĩnh, hạn chế xuất hành quá xa. Ngày 19 Âm lịch có thể làm lễ cầu an hướng Tây.',
      },
      'Vân Hớn': {
        'nature': 'Trung Tinh (Cẩn Trọng Lời Ăn Tiếng Nói)',
        'isGood': false,
        'desc':
            'Sao Vân Hớn (Vân Hán) chủ về sự bảo thủ, dễ nóng nảy dẫn tới kiện cáo hoặc thương tật nhỏ vào tháng 2 và tháng 8 Âm lịch.',
        'remedy':
            'Dĩ hòa vi quý, cẩn trọng giấy tờ pháp lý và phòng hỏa hoạn. Ngày 29 Âm lịch hướng Nam tịnh tâm cầu an.',
      },
      'La Hầu': {
        'nature': 'Hung Tinh (Khẩu Thiệt Tinh)',
        'isGood': false,
        'desc':
            'Sao La Hầu chủ về khẩu thiệt, thị phi công sở, dễ hao tài và mắc bệnh tai mắt (cần lưu ý nhất vào tháng Giêng và tháng 7 Âm lịch).',
        'remedy':
            'Nói năng khiêm nhường, tránh đầu tư mạo hiểm, năng làm việc phúc thiện. Dân gian thường cúng cầu an vào ngày mùng 8 tháng Giêng.',
      },
      'Kế Đô': {
        'nature': 'Hung Tinh (Ám Tinh)',
        'isGood': false,
        'desc':
            'Sao Kế Đô dễ gây tâm lý bất an, tự ti, chuyện buồn trong gia đạo (kỵ tháng 3 và tháng 9 Âm lịch), nhưng đi xa làm ăn lại dễ có tài lộc.',
        'remedy':
            'Giữ tinh thần lạc quan, chăm làm phước bố thí, đeo trang sức đá màu sáng để cân bằng năng lượng. Ngày 18 Âm lịch cầu an hướng Tây.',
      },
      'Thái Bạch': {
        'nature': 'Hung Tinh (Hao Tài Tinh)',
        'isGood': false,
        'desc':
            'Sao Thái Bạch ("Thái Bạch quét sạch cửa nhà") dễ gây hao tán tiền của, sức khỏe suy giảm vào tháng 2, tháng 5 và tháng 8 Âm lịch.',
        'remedy':
            'Quản lý tài chính chặt chẽ, tránh cho vay mượn lớn, chủ động chi tiêu vào việc thiện hoặc mua sắm tài sản tích lũy đầu năm. Ngày 15 Âm lịch cầu an hướng Tây.',
      },
    };

    // Tính Bát Hạn theo phương pháp Cửu Cung truyền thống:
    // Khởi 10 tuổi tại Huỳnh Tuyền -> 20 Tam Kheo -> 30 Ngũ Mộ -> 40 Thiên Tinh -> 50 Tán Tận -> 60 Thiên La -> 70 Địa Võng -> 80 Diêm Vương
    // Nam thuận chiều, Nữ nghịch chiều (bỏ số 0 hàng đơn vị sau khi đếm từ hàng chục)
    const List<String> eightHans = [
      'Huỳnh Tuyền',
      'Tam Kheo',
      'Ngũ Mộ',
      'Thiên Tinh',
      'Toán Tận',
      'Thiên La',
      'Địa Võng',
      'Diêm Vương',
    ];

    int hanIndex;
    final int tens = (lunarAge ~/ 10).clamp(1, 9);
    final int units = lunarAge % 10;
    final int baseIdx = (tens - 1) % 8;
    if (gender == Gender.male) {
      hanIndex = (baseIdx + units) % 8;
    } else {
      hanIndex = ((baseIdx - units) % 8 + 8) % 8;
    }
    final String hanName = eightHans[hanIndex];

    const Map<String, String> hanMeanings = {
      'Huỳnh Tuyền':
          'Hạn về sức khỏe (đau đầu, huyết áp, chóng mặt), không nên làm việc quá sức hoặc mạo hiểm đường sông nước.',
      'Tam Kheo':
          'Hạn về xương khớp, tay chân và thị lực; nên tập luyện thể thao điều độ và cẩn thận khi tham gia giao thông.',
      'Ngũ Mộ':
          'Hạn hao tài bất ngờ; mua sắm hàng hóa cần kiểm tra rõ nguồn gốc, hạn chế cho vay mượn không giấy tờ.',
      'Thiên Tinh':
          'Đề phòng ngộ độc thực phẩm (ăn uống hợp vệ sinh) và tránh va chạm dẫn đến tranh chấp pháp lý.',
      'Toán Tận':
          'Hạn thất thoát tiền bạc đột ngột; không nên mang nhiều tài sản quý giá khi đi xa hoặc hùn hạp mạo hiểm.',
      'Thiên La':
          'Tâm lý dễ lo âu, mất ngủ, vợ chồng nên nhường nhịn thấu hiểu nhau để tránh hiểu lầm không đáng có.',
      'Địa Võng':
          'Cẩn trọng lời ăn tiếng nói, tránh nghe lời thị phi đồn đoán và không nên đi về quá khuya.',
      'Diêm Vương':
          'Người có bệnh nền cần thăm khám định kỳ; ngược lại nếu biết chăm sóc sức khỏe tốt thì mưu cầu tài lộc vẫn hanh thông.',
    };

    final info = starDetails[starName]!;
    return CuuDieuNienHan(
      lunarAge: lunarAge,
      starName: starName,
      starNature: info['nature'] as String,
      isGoodStar: info['isGood'] as bool,
      starDescription: info['desc'] as String,
      hanName: hanName,
      hanDescription: hanMeanings[hanName]!,
      adviceAndRemedy: info['remedy'] as String,
    );
  }

  /// 4. Tính hạn Tam Tai, Kim Lâu, Hoang Ốc cho năm hiện tại (`targetLunarYear`)
  static YearlyTaboos calculateYearlyTaboos(
    int birthLunarYear,
    int targetLunarYear,
  ) {
    final int lunarAge = (targetLunarYear - birthLunarYear + 1).clamp(1, 150);
    final String birthChi = FengShuiEngine.diaChi[(birthLunarYear + 8) % 12];
    final String targetChi = FengShuiEngine.diaChi[(targetLunarYear + 8) % 12];
    final String targetYearCanChi =
        FengShuiEngine.getYearCanChi(targetLunarYear);

    // 4.1. Tính Tam Tai theo nhóm Tam Hợp Địa Chi:
    // - Thân, Tý, Thìn gặp Tam Tai năm: Dần, Mão, Thìn
    // - Dần, Ngọ, Tuất gặp Tam Tai năm: Thân, Dậu, Tuất
    // - Hợi, Mão, Mùi gặp Tam Tai năm: Tỵ, Ngọ, Mùi
    // - Tỵ, Dậu, Sửu gặp Tam Tai năm: Hợi, Tý, Sửu
    List<String> tamTaiYears;
    if (['Thân', 'Tý', 'Thìn'].contains(birthChi)) {
      tamTaiYears = ['Dần', 'Mão', 'Thìn'];
    } else if (['Dần', 'Ngọ', 'Tuất'].contains(birthChi)) {
      tamTaiYears = ['Thân', 'Dậu', 'Tuất'];
    } else if (['Hợi', 'Mão', 'Mùi'].contains(birthChi)) {
      tamTaiYears = ['Tỵ', 'Ngọ', 'Mùi'];
    } else {
      tamTaiYears = ['Hợi', 'Tý', 'Sửu'];
    }

    final int tamTaiYearIndex = tamTaiYears.indexOf(targetChi);
    final bool hasTamTai = tamTaiYearIndex != -1;
    final String tamTaiDetail = hasTamTai
        ? 'Phạm Tam Tai năm thứ ${tamTaiYearIndex + 1}/3 (Tuổi $birthChi gặp năm $targetChi - hạn các năm ${tamTaiYears.join(", ")}).'
        : 'Không phạm Tam Tai (Tuổi $birthChi chỉ kỵ các năm ${tamTaiYears.join(", ")}).';

    // 4.2. Tính Kim Lâu (lấy tuổi mụ chia 9, dư 1, 3, 6, 8 là phạm Kim Lâu):
    // Dư 1: Kim Lâu Thân | Dư 3: Kim Lâu Thê | Dư 6: Kim Lâu Tử | Dư 8: Kim Lâu Súc
    final int kimLauMod = lunarAge % 9;
    bool hasKimLau = false;
    String kimLauDetail = 'Không phạm Kim Lâu ($lunarAge tuổi Âm lịch).';
    if (kimLauMod == 1) {
      hasKimLau = true;
      kimLauDetail = 'Phạm Kim Lâu Thân (Kỵ bản thân gia chủ khi động thổ, cưới hỏi).';
    } else if (kimLauMod == 3) {
      hasKimLau = true;
      kimLauDetail = 'Phạm Kim Lâu Thê (Không tốt cho người phối ngẫu khi xây nhà).';
    } else if (kimLauMod == 6) {
      hasKimLau = true;
      kimLauDetail = 'Phạm Kim Lâu Tử (Bất lợi cho con cái khi khởi tạo lớn).';
    } else if (kimLauMod == 8) {
      hasKimLau = true;
      kimLauDetail = 'Phạm Kim Lâu Súc (Ảnh hưởng tới kinh tế, vật nuôi, tài sản).';
    }

    // 4.3. Tính Hoang Ốc (Vòng 6 cung: 1 Nhất Cát, 2 Nhì Nghi, 3 Tam Địa Sát, 4 Tứ Tấn Tài, 5 Ngũ Thọ Tử, 6 Lục Hoang Ốc)
    final int tens = (lunarAge ~/ 10);
    final int units = lunarAge % 10;
    final int hoangOcIndex = ((tens + units - 1) % 6 + 6) % 6; // 0..5

    const List<Map<String, dynamic>> hoangOcTable = [
      {
        'cung': 'Nhất Cát (Tốt)',
        'isBad': false,
        'detail': 'Làm nhà thuận lợi, chốn an cư tốt đẹp, mọi việc hanh thông.',
      },
      {
        'cung': 'Nhì Nghi (Tốt)',
        'isBad': false,
        'detail': 'Làm nhà hưng vượng, giàu có, gia đạo phát đạt.',
      },
      {
        'cung': 'Tam Địa Sát (Xấu)',
        'isBad': true,
        'detail': 'Phạm Tam Địa Sát - Gia chủ dễ gặp bệnh tật, nên mượn tuổi nếu động thổ.',
      },
      {
        'cung': 'Tứ Tấn Tài (Tốt)',
        'isBad': false,
        'detail': 'Làm nhà phúc lộc tới, kinh doanh phát tài.',
      },
      {
        'cung': 'Ngũ Thọ Tử (Xấu)',
        'isBad': true,
        'detail': 'Phạm Ngũ Thọ Tử - Gia đình dễ bất hòa, chia rẽ, kỵ khởi công xây dựng.',
      },
      {
        'cung': 'Lục Hoang Ốc (Xấu)',
        'isBad': true,
        'detail': 'Phạm Lục Hoang Ốc - Công việc làm ăn dễ trắc trở, khó thành đạt.',
      },
    ];

    final hoangOcItem = hoangOcTable[hoangOcIndex];

    return YearlyTaboos(
      targetLunarYear: targetLunarYear,
      targetYearCanChi: targetYearCanChi,
      hasTamTai: hasTamTai,
      tamTaiDetail: tamTaiDetail,
      hasKimLau: hasKimLau,
      kimLauDetail: kimLauDetail,
      hasHoangOc: hoangOcItem['isBad'] as bool,
      hoangOcCung: hoangOcItem['cung'] as String,
      hoangOcDetail: hoangOcItem['detail'] as String,
    );
  }

  /// Hàm tổng hợp phân tích đầy đủ Bản Mệnh & Vận Hạn từ ngày sinh (Dương hoặc Âm)
  static HoroscopeProfileResult analyzeProfile({
    required int day,
    required int month,
    required int year,
    required bool isLunarInput,
    bool isLeapMonth = false,
    required Gender gender,
    int? targetLunarYear,
  }) {
    late final SolarDate birthSolar;
    late final LunarDate birthLunar;

    if (isLunarInput) {
      final convertedSolar = LunarCalculator.lunarToSolar(
        day,
        month,
        year,
        isLeapMonth,
      );
      if (convertedSolar.year == 0) {
        // Nếu người dùng tích tháng nhuận cho tháng không nhuận -> tự động quy về tháng thường của năm đó
        birthSolar = LunarCalculator.lunarToSolar(day, month, year, false);
      } else {
        birthSolar = convertedSolar;
      }
      birthLunar = LunarCalculator.solarToLunar(
        birthSolar.day,
        birthSolar.month,
        birthSolar.year,
      );
    } else {
      // Kẹp ngày hợp lệ cho năm nhuận / tháng 28-31 ngày Dương lịch
      final int maxDaysInMonth = DateTime(year, month + 1, 0).day;
      final int validDay = day > maxDaysInMonth ? maxDaysInMonth : day;
      birthSolar = SolarDate(day: validDay, month: month, year: year);
      birthLunar = LunarCalculator.solarToLunar(validDay, month, year);
    }

    final int evalLunarYear = targetLunarYear ??
        LunarCalculator.solarDateTimeToLunar(DateTime.now()).year;

    final int jd = birthLunar.julianDay;
    final String yearCanChi = FengShuiEngine.getYearCanChi(birthLunar.year);
    final String monthCanChi =
        FengShuiEngine.getMonthCanChi(birthLunar.month, birthLunar.year);
    final String dayCanChi = FengShuiEngine.getDayCanChi(jd);

    final NapAmInfo napAm = calculateNapAm(birthLunar.year);
    final CungPhiBatTrach batTrach =
        calculateCungPhi(birthLunar.year, gender);
    final CuuDieuNienHan cuuDieu =
        calculateCuuDieu(birthLunar.year, evalLunarYear, gender);
    final YearlyTaboos taboos =
        calculateYearlyTaboos(birthLunar.year, evalLunarYear);

    return HoroscopeProfileResult(
      birthSolar: birthSolar,
      birthLunar: birthLunar,
      gender: gender,
      yearCanChi: yearCanChi,
      monthCanChi: monthCanChi,
      dayCanChi: dayCanChi,
      napAm: napAm,
      batTrach: batTrach,
      cuuDieu: cuuDieu,
      taboos: taboos,
    );
  }
}
