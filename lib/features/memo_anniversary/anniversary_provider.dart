import '../../core/utils/lunar_utils.dart';
import '../../data/models/memo.dart';

/// 纪念日类型铭记：语义化计算"今天距/过目标日期几天"。
///
/// 所有配置通过 [Memo.metadata] 持久化，key 集中在 [AnniversaryKeys]；
/// 计算逻辑为纯函数，无副作用，可在卡片缩略图、查看页、分享等任意位置复用。

// ———————————— 元数据 key 常量 ————————————

class AnniversaryKeys {
  /// 日历类型：'gregorian'（公历） | 'lunar'（农历）。
  static const calendar = 'anniversaryCalendar';
  /// 目标日期：公历时存 'YYYY-MM-DD'，农历时存 'YYYY-M-D'（农历年份+月日）。
  static const date = 'anniversaryDate';
  /// 农历闰月标记（仅农历时有效）。
  static const isLeapMonth = 'anniversaryIsLeapMonth';
  /// 重复类型：'none' | 'year' | 'month' | 'week'。
  static const repeat = 'anniversaryRepeat';
  /// 重复间隔（正整数，默认 1）。
  static const repeatInterval = 'anniversaryRepeatInterval';
  /// 正数天数是否包含起始日（true → 未来目标天数 +1）。
  static const includeStart = 'anniversaryIncludeStart';
  /// 纪念日标签 / 备注（如"生日""结婚纪念日"）。
  static const note = 'anniversaryNote';
}

// ———————————— 配置对象 ————————————

class AnniversaryConfig {
  const AnniversaryConfig({
    required this.calendar,
    required this.date,
    required this.isLeapMonth,
    required this.repeat,
    required this.repeatInterval,
    required this.includeStart,
    required this.note,
  });

  /// 'gregorian' | 'lunar'
  final String calendar;
  /// 公历 'YYYY-MM-DD' 或农历 'YYYY-M-D'
  final String date;
  final bool isLeapMonth;
  final String repeat;
  final int repeatInterval;
  final bool includeStart;
  final String? note;

  factory AnniversaryConfig.fromMemo(Memo memo) {
    final md = memo.metadata;
    return AnniversaryConfig(
      calendar: (md[AnniversaryKeys.calendar] as String?) ?? 'gregorian',
      date: (md[AnniversaryKeys.date] as String?) ?? '',
      isLeapMonth: (md[AnniversaryKeys.isLeapMonth] as bool?) ?? false,
      repeat: (md[AnniversaryKeys.repeat] as String?) ?? 'none',
      repeatInterval: (md[AnniversaryKeys.repeatInterval] as int?) ?? 1,
      includeStart: (md[AnniversaryKeys.includeStart] as bool?) ?? false,
      note: md[AnniversaryKeys.note] as String?,
    );
  }

  /// 序列化：写入 metadata 时只覆盖 anniversary 分支，不影响其他 key。
  Map<String, dynamic> toMetadata() {
    return {
      AnniversaryKeys.calendar: calendar,
      AnniversaryKeys.date: date,
      if (calendar == 'lunar') AnniversaryKeys.isLeapMonth: isLeapMonth,
      AnniversaryKeys.repeat: repeat,
      AnniversaryKeys.repeatInterval: repeatInterval,
      AnniversaryKeys.includeStart: includeStart,
      if (note != null && note!.isNotEmpty) AnniversaryKeys.note: note,
    };
  }
}

// ———————————— 计算结果 ————————————

class AnniversaryCalc {
  const AnniversaryCalc({
    required this.count,
    required this.targetDate,
    required this.targetLabel,
    required this.repeatLabel,
  });

  /// 距今天数：>0 还有 N 天，=0 今天，<0 已过 |N| 天。
  /// 不重复时可能是负数；重复（年/月/周）时永远 ≥0（总是找下一次未来日期）。
  /// includeStart 时的 +1 已计入（过去时 |count| 同步放大）。
  final int count;
  /// 当前周期对应的目标公历午夜。
  final DateTime targetDate;
  /// 目标日期展示文本（公历：'YYYY-MM-DD'，农历：'腊月初三'）。
  final String targetLabel;
  final String repeatLabel;

  /// 历史/未来用绝对值展示。
  int get absCount => count.abs();
  bool get isToday => count == 0;
  bool get isUpcoming => count >= 0;
}

// ———————————— 纯函数计算核心 ————————————

/// 计算 [today]（默认此刻）对应的纪念日状态。
///
/// 语义约定：
/// - 不重复：目标日期固定；未来 → 正数（还有 N 天）；过去 → 负数（已过 |N| 天）。
/// - 重复（年/月/周）：一律找"下一个未来或今天"的目标日期 → 非负数。
///
/// 关于 `包含起始日`（includeStart）：
/// - 未来 → 计数 +1（未来第 2 天显示为"还有 3 天"）
/// - 过去 → |计数| +1（刚过去 3 天显示为"已过 4 天"，包含纪念日当天）
AnniversaryCalc computeAnniversary(AnniversaryConfig cfg, {DateTime? today}) {
  final ref = _dateOnly(today ?? DateTime.now());
  final target = _resolveTarget(cfg, ref);
  var rawDiff = target.target.difference(ref).inDays;

  // 包含起始日：绝对 +1
  if (cfg.includeStart) {
    rawDiff = rawDiff >= 0 ? rawDiff + 1 : rawDiff - 1;
  }

  return AnniversaryCalc(
    count: rawDiff,
    targetDate: target.target,
    targetLabel: target.display,
    repeatLabel: _repeatDisplay(cfg.repeat, cfg.repeatInterval),
  );
}

// ———————————— 目标日期解析（按 repeat 类型分派）————————————

_TargetInfo _resolveTarget(AnniversaryConfig cfg, DateTime today) {
  return switch (cfg.repeat) {
    'week' => _targetWeekly(cfg, today),
    'month' => _targetMonthly(cfg, today),
    'year' => _targetYearly(cfg, today),
    _ => _targetNone(cfg, today),
  };
}

/// 不重复：唯一目标日期。
_TargetInfo _targetNone(AnniversaryConfig cfg, DateTime today) {
  final t = _cfgToSolar(cfg, anchorYear: today.year);
  return _TargetInfo(
    target: t,
    display: cfg.calendar == 'lunar'
        ? _lunarShortFrom(cfg)
        : _fmtDate(t),
  );
}

// ————————————————————————————————————————————————
// 重复模式：一律找"≥ today 的最近未来版本"作为目标日期。
// 未来目标 → count ≥ 0（只有不重复时才可能是负数）。
// ————————————————————————————————————————————————

/// 每周重复：锚定到与 baseDate 同一星期几，以 interval*7 步长向前搜索。
_TargetInfo _targetWeekly(AnniversaryConfig cfg, DateTime today) {
  final anchor = _cfgToSolar(cfg, anchorYear: today.year);
  final step = cfg.repeatInterval.clamp(1, 99) * 7;
  today = _dateOnly(today);
  // 先把锚点移到 ≤ today 的最大位置。
  var target = anchor;
  if (target.isAfter(today)) {
    final backSteps = (target.difference(today).inDays / step).ceil();
    target = target.subtract(Duration(days: backSteps * step));
    if (target.isAfter(today)) {
      target = target.subtract(Duration(days: step));
    }
  }
  // 现在 target ≤ today，step 向前找到第一个 > today 的（若 == today 则取今天）。
  while (target.isBefore(today)) {
    target = target.add(Duration(days: step));
  }
  return _TargetInfo(target: target, display: _fmtDate(target));
}

/// 每月重复：同一日序号向前搜索；溢出时卡到月底。
_TargetInfo _targetMonthly(AnniversaryConfig cfg, DateTime today) {
  final day = _baseDay(cfg);
  final interval = cfg.repeatInterval.clamp(1, 12);

  // 先尝试今天当月
  var year = today.year;
  var month = today.month;

  // 生成 today 当月的一个候选，若它 ≥ today 直接返回（今天或未来），否则向前 +interval 月
  for (var i = 0; i < 1200; i++) {
    final t = _safeDate(year, month, day);
    if (!t.isBefore(today)) {
      return _TargetInfo(
        target: t,
        display: cfg.calendar == 'lunar'
            ? _lunarShortFrom(cfg)
            : _fmtDate(t),
      );
    }
    // 过去 → 前推 interval 个月
    month += interval;
    while (month > 12) {
      month -= 12;
      year += 1;
    }
  }
  // 防呆
  final fb = _cfgToSolar(cfg, anchorYear: today.year);
  return _TargetInfo(target: fb, display: _fmtDate(fb));
}

_TargetInfo _targetYearly(AnniversaryConfig cfg, DateTime today) {
  final interval = cfg.repeatInterval.clamp(1, 200);
  final todayY = today.year;

  if (cfg.calendar == 'lunar') {
    final parts = cfg.date.split('-').map(int.tryParse).toList();
    if (parts.length < 3 ||
        parts[0] == null ||
        parts[1] == null ||
        parts[2] == null) {
      final fb = _safeDate(todayY, 1, 1);
      return _TargetInfo(target: fb, display: _fmtDate(fb));
    }
    final lunarYear = parts[0]!;
    final month = parts[1]!;
    final day = parts[2]!;
    final isLeap = cfg.isLeapMonth;

    // 从当前农历年向前找：若今年对应公历已过去则推至下一年
    for (var y = lunarYear; y <= lunarYear + 200; y++) {
      final sol = _lunarToSolarSafe(y, month, day, isLeap);
      if (sol == null) continue;
      if (!sol.isBefore(today)) {
        return _TargetInfo(
          target: sol,
          display: LunarUtils.lunarShortLabel(lunarYear, month, day),
        );
      }
    }
    // 防呆
    final fb = _safeDate(todayY + 1, 1, 1);
    return _TargetInfo(
      target: fb,
      display: LunarUtils.lunarShortLabel(lunarYear, month, day),
    );
  }

  // 公历 yearly：同样月日
  final anchor = _cfgToSolar(cfg, anchorYear: today.year);
  final baseMonth = anchor.month;
  final baseDay = anchor.day;

  // 今年候选 → 若已过则推至 +interval 年
  var year = todayY;
  var candidate = _safeDate(year, baseMonth, baseDay);
  while (candidate.isBefore(today)) {
    year += interval;
    if (year > todayY + 200) break; // 防呆
    candidate = _safeDate(year, baseMonth, baseDay);
  }
  return _TargetInfo(target: candidate, display: _fmtDate(candidate));
}

// ———————————— 工具函数 ————————————

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

String _fmtDate(DateTime d) {
  String two(int v) => v.toString().padLeft(2, '0');
  return '${d.year}-${two(d.month)}-${two(d.day)}';
}

String _repeatDisplay(String repeat, int interval) {
  return switch (repeat) {
    'year' => '每 $interval 年',
    'month' => '每 $interval 月',
    'week' => '每 $interval 周',
    _ => '不重复',
  };
}

int _baseDay(AnniversaryConfig cfg) {
  final parts = cfg.date.split('-').map(int.tryParse).toList();
  return parts.length >= 3 && parts[2] != null ? parts[2]! : 1;
}

/// 把 cfg 中的日期解析为公历 DateTime（anchorYear 用作农历转换的年份锚点）；
/// 对于农历，anchorYear 影响「该年对应某个农历月日」的公历输出。
DateTime _cfgToSolar(AnniversaryConfig cfg, {required int anchorYear}) {
  if (cfg.date.isEmpty) return _safeDate(anchorYear, 1, 1);
  if (cfg.calendar == 'lunar') {
    final parts = cfg.date.split('-').map(int.tryParse).toList();
    if (parts.length >= 3 &&
        parts[0] != null &&
        parts[1] != null &&
        parts[2] != null) {
      final r = _lunarToSolarSafe(anchorYear, parts[1]!, parts[2]!, cfg.isLeapMonth);
      if (r != null) return r;
    }
    return _safeDate(anchorYear, 1, 1);
  }
  final parts = cfg.date.split('-').map(int.tryParse).toList();
  if (parts.length >= 3 &&
      parts[0] != null &&
      parts[1] != null &&
      parts[2] != null) {
    return _safeDate(parts[0]!, parts[1]!, parts[2]!);
  }
  return _safeDate(anchorYear, 1, 1);
}

String _lunarShortFrom(AnniversaryConfig cfg) {
  final parts = cfg.date.split('-').map(int.tryParse).toList();
  if (parts.length >= 3 &&
      parts[0] != null &&
      parts[1] != null &&
      parts[2] != null) {
    return LunarUtils.lunarShortLabel(parts[0]!, parts[1]!, parts[2]!,
        isLeapMonth: cfg.isLeapMonth);
  }
  return '';
}

DateTime? _lunarToSolarSafe(
    int lunarYear, int month, int day, bool isLeapMonth) {
  try {
    return LunarUtils.lunarToSolar(lunarYear, month, day,
        isLeapMonth: isLeapMonth, clamp: true);
  } catch (_) {
    return null;
  }
}

DateTime _safeDate(int y, int m, int d) {
  final last = DateTime(y, m + 1, 0).day;
  return DateTime(y, m, d > last ? last : d);
}

class _TargetInfo {
  const _TargetInfo({
    required this.target,
    required this.display,
  });
  final DateTime target;
  final String display;
}

// 在底层库完全构造前的占位入口（为上层 import 友好保留）。
@pragma('vm:prefer-inline')
AnniversaryConfig anniversaryConfigOf(Memo memo) =>
    AnniversaryConfig.fromMemo(memo);

@pragma('vm:prefer-inline')
AnniversaryCalc anniversaryCalcOf(Memo memo, {DateTime? today}) =>
    computeAnniversary(AnniversaryConfig.fromMemo(memo), today: today);
