import 'dart:math';

/// Kết quả quy đổi ngày Âm lịch theo kinh tuyến 105° Đông (UTC+7)
class LunarDate {
  final int day;
  final int month;
  final int year;
  final bool isLeap;
  final int julianDay;

  const LunarDate({
    required this.day,
    required this.month,
    required this.year,
    required this.isLeap,
    required this.julianDay,
  });

  /// Tương thích bí danh `isLeapMonth`
  bool get isLeapMonth => isLeap;

  Map<String, dynamic> toMap() => {
        'day': day,
        'month': month,
        'year': year,
        'isLeap': isLeap,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LunarDate &&
          day == other.day &&
          month == other.month &&
          year == other.year &&
          isLeap == other.isLeap;

  @override
  int get hashCode => Object.hash(day, month, year, isLeap);

  @override
  String toString() =>
      'LunarDate(day: $day, month: $month, year: $year, isLeap: $isLeap)';
}

/// Kết quả quy đổi ngày Dương lịch (thuần số nguyên, không phụ thuộc OS timezone)
class SolarDate {
  final int day;
  final int month;
  final int year;

  const SolarDate({
    required this.day,
    required this.month,
    required this.year,
  });

  DateTime toUtcDateTime() => DateTime.utc(year, month, day);

  Map<String, int> toMap() => {
        'day': day,
        'month': month,
        'year': year,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SolarDate &&
          day == other.day &&
          month == other.month &&
          year == other.year;

  @override
  int get hashCode => Object.hash(day, month, year);

  @override
  String toString() => 'SolarDate($day/$month/$year)';
}

/// Thuật toán thiên văn Âm lịch Việt Nam của TS. Hồ Ngọc Đức (Dart thuần).
/// Toàn bộ phép tính cố định theo kinh tuyến 105° Đông (UTC+7), hoàn toàn độc lập
/// với múi giờ của hệ điều hành.
class LunarCalculator {
  /// Múi giờ chuẩn Việt Nam: Kinh tuyến 105° Đông = UTC + 7.0 giờ
  static const double vnTimeZone = 7.0;

  /// Đổi ngày Dương lịch (dd/mm/yyyy) ra số ngày Julius (Julian Day Number)
  static int jdFromDate(int dd, int mm, int yy) {
    final int a = (14 - mm) ~/ 12;
    final int y = yy + 4800 - a;
    final int m = mm + 12 * a - 3;
    int jd = dd +
        ((153 * m + 2) ~/ 5) +
        365 * y +
        (y ~/ 4) -
        (y ~/ 100) +
        (y ~/ 400) -
        32045;
    if (jd < 2299161) {
      jd = dd + ((153 * m + 2) ~/ 5) + 365 * y + (y ~/ 4) - 32083;
    }
    return jd;
  }

  /// Đổi số ngày Julius (JDN) sang ngày Dương lịch [dd, mm, yyyy]
  static List<int> jdToDate(int jd) {
    int a, b, c;
    if (jd > 2299160) {
      a = jd + 32044;
      b = (4 * a + 3) ~/ 146097;
      c = a - ((b * 146097) ~/ 4);
    } else {
      b = 0;
      c = jd + 32082;
    }
    final int d = (4 * c + 3) ~/ 1461;
    final int e = c - ((1461 * d) ~/ 4);
    final int m = (5 * e + 2) ~/ 153;
    final int day = e - ((153 * m + 2) ~/ 5) + 1;
    final int month = m + 3 - 12 * (m ~/ 10);
    final int year = b * 100 + d - 4800 + (m ~/ 10);
    return [day, month, year];
  }

  /// Tính điểm Sóc (New Moon) thứ k kể từ điểm Sóc ngày 1/1/1900 (theo UTC+7)
  static int getNewMoonDay(int k, [double timeZone = vnTimeZone]) {
    final double t = k / 1236.85;
    final double t2 = t * t;
    final double t3 = t2 * t;
    final double dr = pi / 180.0;
    double jd1 = 2415020.75933 +
        29.53058868 * k +
        0.0001178 * t2 -
        0.000000155 * t3;
    jd1 += 0.00033 * sin((166.56 + 132.87 * t - 0.009173 * t2) * dr);
    final double m =
        359.2242 + 29.10535608 * k - 0.0000333 * t2 - 0.00000347 * t3;
    final double mpr =
        306.0253 + 385.81691806 * k + 0.0107306 * t2 + 0.00001236 * t3;
    final double f =
        21.2964 + 390.67050646 * k - 0.0016528 * t2 - 0.00000239 * t3;
    double c1 = (0.1734 - 0.000393 * t) * sin(m * dr) +
        0.0021 * sin(2 * dr * m) -
        0.4068 * sin(mpr * dr) +
        0.0161 * sin(dr * 2 * mpr) -
        0.0004 * sin(dr * 3 * mpr) +
        0.0104 * sin(dr * 2 * f) -
        0.0051 * sin(dr * (m + mpr)) -
        0.0074 * sin(dr * (m - mpr)) +
        0.0004 * sin(dr * (2 * f + m)) -
        0.0004 * sin(dr * (2 * f - m)) -
        0.0006 * sin(dr * (2 * f + mpr)) +
        0.0010 * sin(dr * (2 * f - mpr)) +
        0.0005 * sin(dr * (2 * mpr + m));
    double deltat;
    if (t < -11) {
      deltat = 0.001 +
          0.000839 * t +
          0.0002261 * t2 -
          0.00000845 * t3 -
          0.000000081 * t * t3;
    } else {
      deltat = -0.000278 + 0.000265 * t + 0.000262 * t2;
    }
    final double jdNew = jd1 + c1 - deltat;
    return (jdNew + 0.5 + timeZone / 24.0).floor();
  }

  /// Tính cung kinh độ Mặt Trời (0..11) tại 00:00 (UTC+7) của ngày Julius `jdn`
  static int getSunLongitude(int jdn, [double timeZone = vnTimeZone]) {
    final double jdnVal = jdn - 0.5 - timeZone / 24.0;
    final double t = (jdnVal - 2451545.0) / 36525.0;
    final double t2 = t * t;
    final double dr = pi / 180.0;
    final double m =
        357.52910 + 35999.05030 * t - 0.0001559 * t2 - 0.00000048 * t * t2;
    final double l0 = 280.46645 + 36000.76983 * t + 0.0003032 * t2;
    double dl = (1.914600 - 0.004817 * t - 0.000014 * t2) * sin(dr * m);
    dl += (0.019993 - 0.000101 * t) * sin(dr * 2 * m) +
        0.000290 * sin(dr * 3 * m);
    double l = l0 + dl;
    l = l * dr;
    l = l - pi * 2 * (l / (pi * 2)).floor();
    return (l / pi * 6).floor();
  }

  /// Tính chỉ số 24 Tiết Khí (0..23) theo kinh độ Mặt Trời tại UTC+7
  static int getSolarTermIndex(int jdn, [double timeZone = vnTimeZone]) {
    final double jdnVal = jdn - 0.5 - timeZone / 24.0;
    final double t = (jdnVal - 2451545.0) / 36525.0;
    final double t2 = t * t;
    final double dr = pi / 180.0;
    final double m =
        357.52910 + 35999.05030 * t - 0.0001559 * t2 - 0.00000048 * t * t2;
    final double l0 = 280.46645 + 36000.76983 * t + 0.0003032 * t2;
    double dl = (1.914600 - 0.004817 * t - 0.000014 * t2) * sin(dr * m);
    dl += (0.019993 - 0.000101 * t) * sin(dr * 2 * m) +
        0.000290 * sin(dr * 3 * m);
    double l = l0 + dl;
    l = l * dr;
    l = l - pi * 2 * (l / (pi * 2)).floor();
    return (l / pi * 12).floor();
  }

  /// Tìm ngày bắt đầu tháng 11 Âm lịch (chứa Đông Chí) của năm `yy`
  static int getLunarMonth11(int yy, [double timeZone = vnTimeZone]) {
    final int off = jdFromDate(31, 12, yy) - 2415021;
    final int k = (off / 29.530588853).floor();
    int nm = getNewMoonDay(k, timeZone);
    final int sunLong = getSunLongitude(nm, timeZone);
    if (sunLong >= 9) {
      nm = getNewMoonDay(k - 1, timeZone);
    }
    return nm;
  }

  /// Xác định vị trí tháng nhuận sau tháng 11 Âm lịch `a11`
  static int getLeapMonthOffset(int a11, [double timeZone = vnTimeZone]) {
    final int k = ((a11 - 2415021.076998695) / 29.530588853 + 0.5).floor();
    int last = 0;
    int i = 1;
    int arc = getSunLongitude(getNewMoonDay(k + i, timeZone), timeZone);
    do {
      last = arc;
      i++;
      arc = getSunLongitude(getNewMoonDay(k + i, timeZone), timeZone);
    } while (arc != last && i < 14);
    return i - 1;
  }

  /// 1. Hàm `solarToLunar(int day, int month, int year)`
  /// Chuyển đổi ngày Dương lịch sang Âm lịch {day, month, year, isLeap}
  /// cố định theo kinh tuyến 105° Đông (UTC+7).
  static LunarDate solarToLunar(int day, int month, int year) {
    final int dayNumber = jdFromDate(day, month, year);
    final int k = ((dayNumber - 2415021.076998695) / 29.530588853).floor();
    int monthStart = getNewMoonDay(k + 1, vnTimeZone);
    if (monthStart > dayNumber) {
      monthStart = getNewMoonDay(k, vnTimeZone);
    }
    int a11 = getLunarMonth11(year, vnTimeZone);
    int b11 = a11;
    int lunarYear;
    if (a11 >= monthStart) {
      lunarYear = year;
      a11 = getLunarMonth11(year - 1, vnTimeZone);
    } else {
      lunarYear = year + 1;
      b11 = getLunarMonth11(year + 1, vnTimeZone);
    }
    final int lunarDay = dayNumber - monthStart + 1;
    final int diff = ((monthStart - a11) / 29).floor();
    bool lunarLeap = false;
    int lunarMonth = diff + 11;
    if (b11 - a11 > 365) {
      final int leapMonthDiff = getLeapMonthOffset(a11, vnTimeZone);
      if (diff >= leapMonthDiff) {
        lunarMonth = diff + 10;
        if (diff == leapMonthDiff) {
          lunarLeap = true;
        }
      }
    }
    if (lunarMonth > 12) {
      lunarMonth = lunarMonth - 12;
    }
    if (lunarMonth >= 11 && diff < 4) {
      lunarYear -= 1;
    }
    return LunarDate(
      day: lunarDay,
      month: lunarMonth,
      year: lunarYear,
      isLeap: lunarLeap,
      julianDay: dayNumber,
    );
  }

  /// Hàm tiện ích chuyển từ đối tượng `DateTime` sang `LunarDate`
  static LunarDate solarDateTimeToLunar(DateTime date) =>
      solarToLunar(date.day, date.month, date.year);

  /// Lấy thời điểm hiện tại theo đúng múi giờ Việt Nam (UTC+7),
  /// không phụ thuộc vào múi giờ của hệ điều hành.
  static SolarDate nowInVietnam() {
    final DateTime vnNow =
        DateTime.now().toUtc().add(const Duration(hours: 7));
    return SolarDate(day: vnNow.day, month: vnNow.month, year: vnNow.year);
  }

  /// 2. Hàm `lunarToSolar(int day, int month, int year, bool isLeap)`
  /// Chuyển đổi ngày Âm lịch sang Dương lịch (trả về `SolarDate` gồm day, month, year)
  /// cố định theo kinh tuyến 105° Đông (UTC+7).
  static SolarDate lunarToSolar(
    int day,
    int month,
    int year, [
    bool isLeap = false,
  ]) {
    int a11, b11;
    if (month < 11) {
      a11 = getLunarMonth11(year - 1, vnTimeZone);
      b11 = getLunarMonth11(year, vnTimeZone);
    } else {
      a11 = getLunarMonth11(year, vnTimeZone);
      b11 = getLunarMonth11(year + 1, vnTimeZone);
    }
    final int k = ((0.5 + (a11 - 2415021.076998695) / 29.530588853)).floor();
    int off = month - 11;
    if (off < 0) {
      off += 12;
    }
    if (b11 - a11 > 365) {
      final int leapOff = getLeapMonthOffset(a11, vnTimeZone);
      int leapMonth = leapOff - 2;
      if (leapMonth < 0) {
        leapMonth += 12;
      }
      if (isLeap && month != leapMonth) {
        // Tháng truyền vào không phải là tháng nhuận hợp lệ của năm đó
        return const SolarDate(day: 0, month: 0, year: 0);
      } else if (isLeap || off >= leapOff) {
        off += 1;
      }
    }
    final int monthStart = getNewMoonDay(k + off, vnTimeZone);
    final List<int> solar = jdToDate(monthStart + day - 1);
    return SolarDate(day: solar[0], month: solar[1], year: solar[2]);
  }
}
