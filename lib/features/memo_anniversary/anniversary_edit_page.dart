import 'package:mindspace/ui/design_system/app_design_system.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/di/providers.dart';
import '../../core/utils/lunar_utils.dart';
import '../home/home_provider.dart';
import 'anniversary_provider.dart';

/// 纪念日类型铭记的编辑器。
///
/// 功能：
/// - 标题、日历类型（公历 / 农历）、目标日期选择
/// - 重复类型（不重复 / 每周 / 每月 / 每年）+ 间隔
/// - 正数天数是否「包含起始日」的开关
/// - 备注标签
class AnniversaryEditPage extends ConsumerStatefulWidget {
  const AnniversaryEditPage({super.key, required this.memoId});
  final String memoId;

  @override
  ConsumerState<AnniversaryEditPage> createState() =>
      _AnniversaryEditPageState();
}

class _AnniversaryEditPageState extends ConsumerState<AnniversaryEditPage> {
  final _title = TextEditingController();
  final _note = TextEditingController();

  bool _lunar = false;
  bool _isLeapMonth = false;
  DateTime _date = DateTime.now();
  int _repeatIndex = 0; // 0=none, 1=year, 2=month, 3=week
  int _interval = 1;
  bool _includeStart = false;
  bool _loading = true;

  static const _repeatLabels = ['不重复', '每年', '每月', '每周'];

  /// AppScaffold 子树内的宿主 context（弹层 API 需要脚手架下方的 context）。
  BuildContext? _hostCtx;

  BuildContext? get _pageCtx {
    final ctx = _hostCtx;
    return (ctx != null && ctx.mounted) ? ctx : null;
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final repo = ref.read(memoRepositoryProvider);
    final memo = await repo.findById(widget.memoId);
    if (!mounted) return;
    if (memo != null) {
      _title.text = memo.title;
      _note.text = memo.remark ?? '';
      final cfg = AnniversaryConfig.fromMemo(memo);
      _lunar = cfg.calendar == 'lunar';
      _isLeapMonth = cfg.isLeapMonth;
      _repeatIndex = switch (cfg.repeat) {
        'year' => 1,
        'month' => 2,
        'week' => 3,
        _ => 0,
      };
      _interval = cfg.repeatInterval.clamp(1, 200);
      _includeStart = cfg.includeStart;
      _date = _parseDate(cfg, _lunar);
    }
    setState(() => _loading = false);
  }

  DateTime _parseDate(AnniversaryConfig cfg, bool lunar) {
    if (cfg.date.isEmpty) return DateTime.now();
    if (lunar) {
      final p = cfg.date.split('-').map(int.tryParse).toList();
      if (p.length >= 3 && p[1] != null && p[2] != null && p[0] != null) {
        // 农历年只影响转换锚点，我们取今年公历化后存入
        final now = DateTime.now();
        return _safeLunarToSolar(now.year, p[1]!, p[2]!, cfg.isLeapMonth);
      }
      return DateTime.now();
    }
    final p = cfg.date.split('-').map(int.tryParse).toList();
    if (p.length >= 3 &&
        p[0] != null &&
        p[1] != null &&
        p[2] != null) {
      return _safeDate(p[0]!, p[1]!, p[2]!);
    }
    return DateTime.now();
  }

  DateTime _safeDate(int y, int m, int d) {
    final last = DateTime(y, m + 1, 0).day;
    return DateTime(y, m, d > last ? last : d);
  }

  DateTime _safeLunarToSolar(
      int lunarYear, int month, int day, bool isLeap) {
    try {
      return LunarUtils.lunarToSolar(lunarYear, month, day,
          isLeapMonth: isLeap, clamp: true);
    } catch (_) {
      return DateTime.now();
    }
  }

  bool get _isNew => !_loading && (_title.text.isEmpty);

  Future<void> _pickDate() async {
    final ctx = _pageCtx;
    if (ctx == null) return;
    if (_lunar) {
      final picked = await _showLunarDatePicker(ctx);
      if (picked != null) {
        setState(() {
          _date = picked.solar;
          _isLeapMonth = picked.isLeap;
        });
      }
      return;
    }
    // 公历：MiuixDatePicker 内嵌底部抽屉，选择后经「确定」关闭并保存。
    DateTime selected = _date;
    final picked = await AppSheet.show<DateTime>(
      context: ctx,
      title: '选择日期',
      builder: (sheetCtx) => StatefulBuilder(
        builder: (sheetCtx, setSt) => Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              MiuixDatePicker(
                initialDate: _date,
                firstDate: DateTime(1900),
                lastDate: DateTime(2100),
                onDateChanged: (d) => setSt(() => selected = d),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: MiuixButton(
                  onPressed: () =>
                      AppSheet.close<DateTime>(sheetCtx, selected),
                  child: const MiuixText('确定'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<LunarPickResult?> _showLunarDatePicker(BuildContext ctx) async {
    // 简单年份/月份/日滑块选择，最终 { solar DateTime, isLeapMonth }。
    int year = _date.year;
    // 先确定 _date 对应农历月日
    final defaultLunar = LunarUtils.solarToLunar(_date);
    int month = defaultLunar.month;
    int day = defaultLunar.day;
    bool isLeap = defaultLunar.isLeapMonth;

    return AppSheet.show<LunarPickResult>(
      context: ctx,
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (sheetCtx, setSt) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      AppTapIcon(
                          onPressed:
                              year > 1900 ? () => setSt(() => year--) : null,
                          icon: const HiuiIcon(HiuiIcons.chevronLeft)),
                      MiuixText('农历 $year 年',
                          style: MiuixTheme.of(sheetCtx).textStyles.title3),
                      AppTapIcon(
                          onPressed:
                              year < 2100 ? () => setSt(() => year++) : null,
                          icon: const HiuiIcon(HiuiIcons.chevronRight)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (int mi = 1; mi <= 12; mi++)
                        AppChip(
                          label: MiuixText(LunarUtils.lunarMonthName(mi)),
                          selected: month == mi && !isLeap,
                          onSelected: (_) =>
                              setSt(() { month = mi; isLeap = false; }),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 110,
                    child: GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 6,
                        mainAxisSpacing: 4,
                        crossAxisSpacing: 4,
                      ),
                      itemCount: 30,
                      itemBuilder: (ctx, i) {
                        final d = i + 1;
                        return AppChip(
                          label: MiuixText(LunarUtils.lunarDayName(d),
                              style: MiuixTheme.of(context)
                                  .textStyles
                                  .footnote2
                                  .copyWith(fontSize: 12)),
                          selected: day == d,
                          onSelected: (_) => setSt(() => day = d),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  AppButton(
                    onPressed: () {
                      final sol = _safeLunarToSolar(year, month, day, isLeap);
                      AppSheet.close<LunarPickResult>(
                          sheetCtx, LunarPickResult(solar: sol, isLeap: isLeap));
                    },
                    child: MiuixText('确认'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// 重复规则选择：底部抽屉单选（保留现有规则枚举与计算逻辑）。
  Future<void> _pickRepeat() async {
    final ctx = _pageCtx;
    if (ctx == null) return;
    final current = _repeatIndex;
    final selected = await AppSheet.show<int>(
      context: ctx,
      title: '重复',
      builder: (sheetCtx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int i = 0; i < _repeatLabels.length; i++)
            MiuixRadioButtonPreference(
              title: _repeatLabels[i],
              selected: i == current,
              onClick: () => AppSheet.close<int>(sheetCtx, i),
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
    if (selected == null) return;
    setState(() {
      _repeatIndex = selected;
      if (selected == 0) _interval = 1;
    });
  }

  String get _dateLabel {
    if (_lunar) {
      final l = LunarUtils.solarToLunar(_date);
      return LunarUtils.lunarFullLabel(
        DateTime.now().year,
        l.month,
        l.day,
        isLeapMonth: l.isLeapMonth,
      );
    }
    String two(int v) => v.toString().padLeft(2, '0');
    return '${_date.year}-${two(_date.month)}-${two(_date.day)}';
  }

  String _buildDateStorage() {
    if (_lunar) {
      final l = LunarUtils.solarToLunar(_date);
      // 农历年用当前农历年份，便于 yearly repeat 按农历月日匹配
      return '${l.year}-${l.month}-${l.day}';
    }
    String two(int v) => v.toString().padLeft(2, '0');
    return '${_date.year}-${two(_date.month)}-${two(_date.day)}';
  }

  Future<void> _save() async {
    if (_loading) return;
    final repo = ref.read(memoRepositoryProvider);
    final type = switch (_repeatIndex) {
      1 => 'year',
      2 => 'month',
      3 => 'week',
      _ => 'none',
    };
    final cfg = AnniversaryConfig(
      calendar: _lunar ? 'lunar' : 'gregorian',
      date: _buildDateStorage(),
      isLeapMonth: _isLeapMonth,
      repeat: type,
      repeatInterval: _interval.clamp(1, 200),
      includeStart: _includeStart,
      note: _note.text.isEmpty ? null : _note.text,
    );
    final titleText = _title.text.isEmpty ? '纪念日' : _title.text;
    final existing = await repo.findById(widget.memoId);
    final newMeta = <String, dynamic>{
      if (existing != null) ...existing.metadata,
      ...cfg.toMetadata(),
    };
    if (existing == null) return;
    if (existing.title != titleText) {
      await repo.rename(widget.memoId, titleText);
    }
    await repo.setAppearance(
      widget.memoId,
      remark: _note.text.isEmpty ? null : _note.text,
    );
    await repo.updateMetadata(widget.memoId, newMeta);
    if (mounted) {
      ref.invalidate(memoDetailProvider(widget.memoId));
      ref.invalidate(memoListProvider(existing.folderId));
      context.pop();
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const AppScaffold(body: Center(child: AppCircleProgress()));
    }
    return AppScaffold(
      topBar: AppHeader(
        title: _isNew ? '新建纪念日' : '编辑纪念日',
        actions: [
          AppTapIcon(
            icon: const HiuiIcon(HiuiIcons.check),
            onPressed: _save,
          ),
        ],
      ),
      content: (context, padding) => Builder(builder: (hostCtx) {
        _hostCtx = hostCtx;
        return _list(hostCtx, padding);
      }),
    );
  }

  Widget _list(BuildContext context, EdgeInsets padding) {
    final colors = MiuixTheme.of(context).colors;
    return ListView(
      // 含输入框：MiuixScaffold 不做键盘避让，把 viewInsets 并入底部 padding。
      padding: padding
          .add(const EdgeInsets.all(16))
          .add(EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom)),
      children: [
        // 标题
        AppInput(
          controller: _title,
          label: '名称',
          leadingIcon: const HiuiIcon(HiuiIcons.heading),
        ),
        const SizedBox(height: 12),
        // 日历类型（公历 / 农历）
        MiuixTabRowWithContour(
          tabs: const ['公历', '农历'],
          selectedTabIndex: _lunar ? 1 : 0,
          onTabSelected: (i) => setState(() => _lunar = i == 1),
        ),
        const SizedBox(height: 12),
        // 日期选择
        AppListRow(
          leading: HiuiIcon(HiuiIcons.calendar, color: colors.primary),
          title: MiuixText(_dateLabel),
          subtitle: MiuixText(_lunar ? '农历日期' : '公历日期'),
          trailing: const HiuiIcon(HiuiIcons.calendar),
          onTap: _pickDate,
        ),
        const SizedBox(height: 16),
        // 重复类型（底部抽屉单选）
        MiuixText('重复', style: MiuixTheme.of(context).textStyles.body2),
        const SizedBox(height: 4),
        AppListRow(
          leading: HiuiIcon(HiuiIcons.repeat, color: colors.primary),
          title: MiuixText(_repeatLabels[_repeatIndex]),
          subtitle: const MiuixText('选择重复规则'),
          onTap: _pickRepeat,
        ),
        if (_repeatIndex != 0) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              MiuixText('间隔'),
              const SizedBox(width: 12),
              Expanded(
                child: MiuixSlider(
                  value: _interval.toDouble(),
                  min: 1,
                  max: _repeatIndex == 3 ? 52 : (_repeatIndex == 2 ? 12 : 50),
                  steps: _repeatIndex == 3
                      ? 51
                      : (_repeatIndex == 2 ? 11 : 49),
                  onValueChanged: (v) => setState(() => _interval = v.round()),
                ),
              ),
              MiuixText('每 $_interval ${_repeatLabels[_repeatIndex].replaceAll("每", "").replaceAll("不重复", "年")}'),
            ],
          ),
        ],
        const SizedBox(height: 16),
        // 包含起始日开关
        MiuixSwitchPreference(
          value: _includeStart,
          onChanged: (v) => setState(() => _includeStart = v),
          title: '正数天数包含起始日',
          summary: '开启后，未来目标天数会 +1（如 1 天后显示为 2 天）',
        ),
        const SizedBox(height: 16),
        // 卡片文本（备注标签）
        Row(
          children: [
            const HiuiIcon(HiuiIcons.tag, size: 20),
            const SizedBox(width: 8),
            MiuixText('卡片文本（备注标签）',
                style: MiuixTheme.of(context).textStyles.body2),
          ],
        ),
        const SizedBox(height: 8),
        AppInput(
          controller: _note,
          maxLines: 2,
          hintText: '显示在卡片上的文本（如"生日""纪念日"）',
          leadingIcon: const HiuiIcon(HiuiIcons.edit),
        ),
        const SizedBox(height: 16),
        // 预览
        MiuixSurface(
          cornerRadius: AppTokens.radiusCard,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Builder(builder: (ctx) {
              final cfg = AnniversaryConfig(
                calendar: _lunar ? 'lunar' : 'gregorian',
                date: _buildDateStorage(),
                isLeapMonth: _isLeapMonth,
                repeat: switch (_repeatIndex) {
                  1 => 'year',
                  2 => 'month',
                  3 => 'week',
                  _ => 'none',
                },
                repeatInterval: _interval,
                includeStart: _includeStart,
                note: _note.text.isEmpty ? null : _note.text,
              );
              final calc = computeAnniversary(cfg);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MiuixText('预览',
                      style: MiuixTheme.of(ctx).textStyles.footnote1),
                  const SizedBox(height: 8),
                  Center(
                    child: MiuixText(
                      calc.isToday
                          ? '就是今天'
                          : (calc.isUpcoming
                              ? '还有 ${calc.count} 天'
                              : '已过 ${calc.absCount} 天'),
                      style:
                          MiuixTheme.of(ctx).textStyles.title1.copyWith(
                                fontWeight: FontWeight.w700,
                                color: colors.primary,
                              ),
                    ),
                  ),
                  if (calc.targetLabel.isNotEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: MiuixText(
                          calc.targetLabel,
                          style: MiuixTheme.of(ctx)
                              .textStyles
                              .body1
                              .copyWith(color: colors.onSurfaceVariantSummary),
                        ),
                      ),
                    ),
                ],
              );
            }),
          ),
        ),
      ],
    );
  }
}

class LunarPickResult {
  const LunarPickResult({required this.solar, required this.isLeap});
  final DateTime solar;
  final bool isLeap;
}
