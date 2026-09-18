/// 农历（Chinese lunar calendar）工具：
/// - 1900–2100 年农历数据表，含闰月与每月天数（大月 30 天 / 小月 29 天）。
/// - 公历 → 农历、农历 → 公历 双向转换。
/// - 不依赖三方包，纯查表实现。
class LunarUtils {
  LunarUtils._();

  // ———————————— 基础数据 ————————————

  /// 天干。
  static const List<String> _heavenlyStems = [
    '甲', '乙', '丙', '丁', '戊', '己', '庚', '辛', '壬', '癸',
  ];

  /// 地支。
  static const List<String> _earthlyBranches = [
    '子', '丑', '寅', '卯', '辰', '巳', '午', '未', '申', '酉', '戌', '亥',
  ];

  /// 生肖（对应地支序）。
  static const List<String> _zodiacAnimals = [
    '鼠', '牛', '虎', '兔', '龙', '蛇', '马', '羊', '猴', '鸡', '狗', '猪',
  ];

  /// 农历月份名称。
  static const List<String> _lunarMonthNames = [
    '正', '二', '三', '四', '五', '六',
    '七', '八', '九', '十', '冬', '腊',
  ];

  /// 农历日期名称（初一 ~ 三十）。
  static const List<String> _lunarDayNames = [
    '初一', '初二', '初三', '初四', '初五', '初六', '初七', '初八', '初九', '初十',
    '十一', '十二', '十三', '十四', '十五', '十六', '十七', '十八', '十九', '二十',
    '廿一', '廿二', '廿三', '廿四', '廿五', '廿六', '廿七', '廿八', '廿九', '三十',
  ];

  /// 每年一个整数，编码含义（16 bit）：
  ///   bit 16   — 闰月天数（1=30 天 / 0=29 天）
  ///   bit 12-15 — 闰月月份（0 表示无闰月，1-12 为几月）
  ///   bit 1-12  — 12 个普通农历月的大小月（1=30 天 / 0=29 天）
  /// 数据来源：标准农历数据表（1900-01-31 = 农历 1900 年正月初一）。
  static const List<int> _lunarInfo = [
    0x04bd8, 0x04ae0, 0x0a570, 0x054d5, 0x0d260, 0x0d950, 0x16554, 0x056a0,
    0x09ad0, 0x055d2, 0x04ae0, 0x0a5b6, 0x0a4d0, 0x0d250, 0x1d255, 0x0b540,
    0x0d6a0, 0x0ada2, 0x095b0, 0x14977, 0x04970, 0x0a4b0, 0x0b4b5, 0x06a50,
    0x06d40, 0x1ab54, 0x02b60, 0x09570, 0x052f2, 0x04970, 0x06566, 0x0d4a0,
    0x0ea50, 0x06e95, 0x05ad0, 0x02b60, 0x186e3, 0x092e0, 0x1c8d7, 0x0c950,
    0x0d4a0, 0x1d8a6, 0x0b550, 0x056a0, 0x1a5b4, 0x025d0, 0x092d0, 0x0d2b2,
    0x0a950, 0x0b557, 0x06ca0, 0x0b550, 0x15355, 0x04da0, 0x0a5b0, 0x14573,
    0x052b0, 0x0a9a8, 0x0e950, 0x06aa0, 0x0aea6, 0x0ab50, 0x04b60, 0x0aae4,
    0x0a570, 0x05260, 0x0f263, 0x0d950, 0x05b57, 0x056a0, 0x096d0, 0x04dd5,
    0x04ad0, 0x0a4d0, 0x0d4d4, 0x0d250, 0x0d558, 0x0b540, 0x0b6a0, 0x195a6,
    0x095b0, 0x049b0, 0x0a974, 0x0a4b0, 0x0b27a, 0x06a50, 0x06d40, 0x0af46,
    0x0ab60, 0x09570, 0x04af5, 0x04970, 0x064b0, 0x074a3, 0x0ea50, 0x06b58,
    0x05ac0, 0x0ab60, 0x096d5, 0x092e0, 0x0c960, 0x0d954, 0x0d4a0, 0x0da50,
    0x07552, 0x056a0, 0x0abb7, 0x025d0, 0x092d0, 0x0cab5, 0x0a950, 0x0b4a0,
    0x0baa4, 0x0ad50, 0x055d9, 0x04ba0, 0x0a5b0, 0x15176, 0x052b0, 0x0a930,
    0x07954, 0x06aa0, 0x0ad50, 0x05b52, 0x04b60, 0x0a6e6, 0x0a4e0, 0x0d260,
    0x0ea65, 0x0d530, 0x05aa0, 0x076a3, 0x096d0, 0x04afb, 0x04ad0, 0x0a4d0,
    0x1d0b6, 0x0d250, 0x0d520, 0x0dd45, 0x0b5a0, 0x056d0, 0x055b2, 0x049b0,
    0x0a577, 0x0a4b0, 0x0aa50, 0x1b255, 0x06d20, 0x0ada0, 0x14b63, 0x09370,
    0x049f8, 0x04970, 0x064b0, 0x168a6, 0x0ea50, 0x06b20, 0x1a6c4, 0x0aae0,
    0x092e0, 0x0d2e3, 0x0c960, 0x0d557, 0x0d4a0, 0x0da50, 0x05d55, 0x056a0,
    0x0a6d0, 0x055d4, 0x052d0, 0x0a9b8, 0x0a950, 0x0b4a0, 0x0b6a6, 0x0ad50,
    0x055a0, 0x0aba4, 0x0a5b0, 0x052b0, 0x0b273, 0x06930, 0x07337, 0x06aa0,
    0x0ad50, 0x14b55, 0x04b60, 0x0a570, 0x054e4, 0x0d160, 0x0e968, 0x0d520,
    0x0daa0, 0x16aa6, 0x056d0, 0x04ae0, 0x0a9d4, 0x0a4d0, 0x0d150, 0x0f252,
    0x0d520,
  ];

  static final DateTime _gregorianEpoch =
      DateTime.utc(1900, 1, 31); // 农历 1900 年正月初一的公历日期

  // ———————————— 基础查询 ————————————

  /// 农历 year 年的总天数（所有农历月天数之和 + 闰月天数）。
  static int _lunarYearDays(int year) {
    final idx = year - 1900;
    if (idx < 0 || idx >= _lunarInfo.length) return 348;
    int sum = 348; // 12 小月 = 29*12 = 348 基准
    int info = _lunarInfo[idx];
    for (int i = 0x8000; i > 0x8; i >>= 1) {
      if ((info & i) != 0) sum++;
    }
    return sum + _leapDays(year);
  }

  /// 农历 year 年的闰月月份（0 表示无闰月）。
  static int _leapMonth(int year) {
    return _lunarInfo[year - 1900] & 0xf;
  }

  /// 农历 year 年的闰月天数（29 或 30，0 表示无闰月）。
  static int _leapDays(int year) {
    if (_leapMonth(year) == 0) return 0;
    return (_lunarInfo[year - 1900] & 0x10000) != 0 ? 30 : 29;
  }

  /// 农历 year 年第 month 个农历月的天数（month 1-12）。
  static int _monthDays(int year, int month) {
    return (_lunarInfo[year - 1900] & (0x10000 >> month)) != 0 ? 30 : 29;
  }

  // ———————————— 公历 → 农历 ————————————

  // ignore: unused_element
  static LunarDate solarToLunar(DateTime solar) {
    final base = _gregorianEpoch;
    int offset =
        (solar.millisecondsSinceEpoch - base.millisecondsSinceEpoch) ~/
            86400000;

    // 年
    int year = 1900;
    int daysInYear;
    while (year < 2101 && offset > 0) {
      daysInYear = _lunarYearDays(year);
      if (offset < daysInYear) break;
      offset -= daysInYear;
      year++;
    }

    final leap = _leapMonth(year);
    bool isLeap = false;

    int month = 1;
    int daysInMonth;
    while (month < 13 && offset > 0) {
      if (leap > 0 && month == leap + 1 && !isLeap) {
        month--;
        isLeap = true;
        daysInMonth = _leapDays(year);
      } else {
        daysInMonth = _monthDays(year, month);
      }
      if (offset < daysInMonth) break;
      offset -= daysInMonth;
      if (isLeap && month == leap) {
        isLeap = false;
      }
      month++;
    }

    if (month == leap + 1 && isLeap) {
      isLeap = false;
    }

    return LunarDate._(
      year: year,
      month: month,
      day: offset + 1,
      isLeapMonth: isLeap,
    );
  }

  // ———————————— 农历 → 公历 ————————————

  static DateTime lunarToSolar(int year, int month, int day,
      {bool isLeapMonth = false, bool clamp = true}) {
    // 先校验边界，如果 clamp=true 则裁到当月最后一天。
    final maxDay = _dayLimitForLunarMonth(year, month, isLeapMonth);
    if (day > maxDay) {
      if (!clamp) return DateTime(0);
      day = maxDay;
    }
    if (day < 1) day = 1;

    int offset = 0;
    for (int y = 1900; y < year; y++) {
      offset += _lunarYearDays(y);
    }
    final leap = _leapMonth(year);
    for (int m = 1; m < month; m++) {
      offset += _monthDays(year, m);
      if (leap == m) {
        if (!isLeapMonth) {
          offset += _leapDays(year);
        }
      }
    }
    if (leap > 0 && month > leap) {
      offset += _leapDays(year);
    }
    if (isLeapMonth && leap == month) {
      offset += _monthDays(year, month);
    }
    offset += day - 1;
    return _gregorianEpoch.add(Duration(days: offset));
  }

  /// 农历 year 年第 month 月（含闰月）的最大天数。
  static int _dayLimitForLunarMonth(int year, int month, bool isLeap) {
    if (isLeap) return _leapDays(year);
    if (month < 1 || month > 12) return 30;
    return _monthDays(year, month);
  }

  // ———————————— 显示辅助 ————————————

  /// 干支纪年（如「甲辰」）。
  static String ganZhi(int year) {
    final idx = (year - 4) % 60;
    return _heavenlyStems[idx % 10] + _earthlyBranches[idx % 12];
  }

  /// 生肖（如「龙」）。
  static String zodiac(int year) {
    return _zodiacAnimals[(year - 4) % 12];
  }

  /// 农历月名（如「闰六」「正」）。
  static String lunarMonthName(int month, {bool isLeap = false}) {
    return '${isLeap ? "闰" : ""}${_lunarMonthNames[(month - 1) % 12]}月';
  }

  /// 农历日名（如「初一」「廿三」「三十」）。
  static String lunarDayName(int day) {
    if (day < 1 || day > 30) return '';
    return _lunarDayNames[day - 1];
  }

  /// 完整农历日期字符串，如「甲辰年 腊月 廿三」。
  static String lunarFullLabel(int year, int month, int day,
      {bool isLeapMonth = false}) {
    return '${ganZhi(year)}年 ${lunarMonthName(month, isLeap: isLeapMonth)} ${lunarDayName(day)}';
  }

  /// 农历日期短格式，用于 UI 显示，如「腊月初三」。
  static String lunarShortLabel(int year, int month, int day,
      {bool isLeapMonth = false}) {
    return '${lunarMonthName(month, isLeap: isLeapMonth)}${lunarDayName(day)}';
  }
}

/// 农历日期对象。
class LunarDate {
  const LunarDate._({
    required this.year,
    required this.month,
    required this.day,
    required this.isLeapMonth,
  });

  final int year;
  final int month;
  final int day;
  final bool isLeapMonth;

  @override
  String toString() =>
      '$year年${isLeapMonth ? "闰" : ""}$month月$day日';
}
