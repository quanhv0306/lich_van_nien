import '../../core/feng_shui_engine.dart';
import '../../core/lunar_calculator.dart';

class DayInfo {
  final DateTime solarDate;
  final LunarDate lunarDate;
  final String yearCanChi;
  final String monthCanChi;
  final String dayCanChi;
  final String firstHourCanChi;
  final String solarTerm;
  final bool isHoangDao;
  final TrucInfo truc;
  final TuInfo nhiThapBatTu;
  final List<AuspiciousHour> auspiciousHours;
  final List<LyThuanPhongHour> lyThuanPhongHours;
  final DepartureDirection departureDirection;
  final String quote;
  final String quoteAuthor;

  const DayInfo({
    required this.solarDate,
    required this.lunarDate,
    required this.yearCanChi,
    required this.monthCanChi,
    required this.dayCanChi,
    required this.firstHourCanChi,
    required this.solarTerm,
    required this.isHoangDao,
    required this.truc,
    required this.nhiThapBatTu,
    required this.auspiciousHours,
    required this.lyThuanPhongHours,
    required this.departureDirection,
    required this.quote,
    required this.quoteAuthor,
  });

  static const List<Map<String, String>> _dailyQuotes = [
    {
      'quote': 'Có công mài sắt, có ngày nên kim.',
      'author': 'Tục ngữ Việt Nam',
    },
    {
      'quote': 'Cây có cội mới nở cành xanh ngọn, nước có nguồn mới bể rộng sông sâu.',
      'author': 'Ca dao Việt Nam',
    },
    {
      'quote': 'Chữ Tâm kia mới bằng ba chữ Tài.',
      'author': 'Nguyễn Du',
    },
    {
      'quote': 'Thuận vợ thuận chồng, tát biển Đông cũng cạn.',
      'author': 'Tục ngữ Việt Nam',
    },
    {
      'quote': 'Uống nước nhớ nguồn, ăn quả nhớ kẻ trồng cây.',
      'author': 'Tục ngữ Việt Nam',
    },
    {
      'quote': 'Một cây làm chẳng nên non, ba cây chụm lại nên hòn núi cao.',
      'author': 'Ca dao Việt Nam',
    },
    {
      'quote': 'Tâm an vạn sự an, tâm tĩnh vạn sự thành.',
      'author': 'Danh ngôn phương Đông',
    },
  ];

  String get weekdayLabel {
    switch (solarDate.weekday) {
      case DateTime.monday:
        return 'Thứ Hai';
      case DateTime.tuesday:
        return 'Thứ Ba';
      case DateTime.wednesday:
        return 'Thứ Tư';
      case DateTime.thursday:
        return 'Thứ Năm';
      case DateTime.friday:
        return 'Thứ Sáu';
      case DateTime.saturday:
        return 'Thứ Bảy';
      case DateTime.sunday:
      default:
        return 'Chủ Nhật';
    }
  }

  /// Khởi tạo đầy đủ thông tin Âm Dương & Phong thủy của một ngày bất kỳ
  factory DayInfo.fromSolarDate(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    final lunar = LunarCalculator.solarToLunar(
      normalized.day,
      normalized.month,
      normalized.year,
    );
    final jd = lunar.julianDay;
    final quoteItem = _dailyQuotes[jd % _dailyQuotes.length];

    return DayInfo(
      solarDate: normalized,
      lunarDate: lunar,
      yearCanChi: FengShuiEngine.getYearCanChi(lunar.year),
      monthCanChi: FengShuiEngine.getMonthCanChi(lunar.month, lunar.year),
      dayCanChi: FengShuiEngine.getDayCanChi(jd),
      firstHourCanChi: FengShuiEngine.getFirstHourCanChi(jd),
      solarTerm: FengShuiEngine.getSolarTerm(jd),
      isHoangDao: FengShuiEngine.isHoangDaoDay(jd, lunar.month),
      truc: FengShuiEngine.getTruc(jd, lunar.month),
      nhiThapBatTu: FengShuiEngine.getNhiThapBatTu(jd),
      auspiciousHours: FengShuiEngine.getAuspiciousHours(jd),
      lyThuanPhongHours: FengShuiEngine.getLyThuanPhongHours(
        lunar.day,
        lunar.month,
      ),
      departureDirection: FengShuiEngine.getDepartureDirection(jd),
      quote: quoteItem['quote']!,
      quoteAuthor: quoteItem['author']!,
    );
  }
}
