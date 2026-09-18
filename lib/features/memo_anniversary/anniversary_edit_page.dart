import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/di/providers.dart';
import '../../core/theme/md3e_tokens.dart';
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
    if (_lunar) {
      final picked = await _showLunarDatePicker();
      if (picked != null) {
        setState(() {
          _date = picked.solar;
          _isLeapMonth = picked.isLeap;
        });
      }
      return;
    }
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<LunarPickResult?> _showLunarDatePicker() async {
    // 简单年份/月份/日滑块选择，最终 { solar DateTime, isLeapMonth }。
    int year = _date.year;
    // 先确定 _date 对应农历月日
    final defaultLunar = LunarUtils.solarToLunar(_date);
    int month = defaultLunar.month;
    int day = defaultLunar.day;
    bool isLeap = defaultLunar.isLeapMonth;

    return showModalBottomSheet<LunarPickResult>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return SafeArea(
          child: StatefulBuilder(
            builder: (ctx, setSt) {
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                            onPressed:
                                year > 1900 ? () => setSt(() => year--) : null,
                            icon: const Icon(Icons.chevron_left)),
                        Text('农历 $year 年',
                            style: Theme.of(ctx).textTheme.titleMedium),
                        IconButton(
                            onPressed:
                                year < 2100 ? () => setSt(() => year++) : null,
                            icon: const Icon(Icons.chevron_right)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (int m = 1; m <= 12; m++)
                          ChoiceChip(
                            label: Text(LunarUtils.lunarMonthName(m)),
                            selected: month == m && !isLeap,
                            onSelected: (_) =>
                                setSt(() { month = m; isLeap = false; }),
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
                          return ChoiceChip(
                            label: Text(LunarUtils.lunarDayName(d),
                                style: const TextStyle(fontSize: 12)),
                            selected: day == d,
                            onSelected: (_) => setSt(() => day = d),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: () {
                        final sol = _safeLunarToSolar(year, month, day, isLeap);
                        Navigator.pop(ctx,
                            LunarPickResult(solar: sol, isLeap: isLeap));
                      },
                      child: const Text('确认'),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
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
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(_isNew ? '新建纪念日' : '编辑纪念日'),
        actions: [
          IconButton(
            icon: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.check),
            onPressed: _save,
          ),
        ],
      ),
      body: _list(context, scheme),
    );
  }

  final bool _saving = false;

  Widget _list(BuildContext context, ColorScheme scheme) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 标题
        TextField(
          controller: _title,
          decoration: const InputDecoration(
            labelText: '名称',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.title),
          ),
        ),
        const SizedBox(height: 12),
        // 日历类型
        SegmentedButton<bool>(
          segments: const [
            ButtonSegment(value: false, label: Text('公历')),
            ButtonSegment(value: true, label: Text('农历')),
          ],
          selected: {_lunar},
          onSelectionChanged: (s) => setState(() => _lunar = s.first),
        ),
        const SizedBox(height: 12),
        // 日期选择
        ListTile(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(Md3eTokens.radiusCard)),
          tileColor: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
          leading:
              Icon(Icons.event, color: scheme.primary),
          title: Text(_dateLabel),
          subtitle: Text(_lunar ? '农历日期' : '公历日期'),
          trailing: const Icon(Icons.edit_calendar_outlined),
          onTap: _pickDate,
        ),
        const SizedBox(height: 16),
        // 重复类型
        Text('重复', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 4),
        Wrap(
          spacing: 8,
          children: [
            for (int i = 0; i < _repeatLabels.length; i++)
              ChoiceChip(
                label: Text(_repeatLabels[i]),
                selected: _repeatIndex == i,
                onSelected: (_) => setState(() {
                  _repeatIndex = i;
                  if (i == 0) _interval = 1;
                }),
              ),
          ],
        ),
        if (_repeatIndex != 0) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              const Text('间隔'),
              const SizedBox(width: 12),
              Expanded(
                child: Slider(
                  value: _interval.toDouble(),
                  min: 1,
                  max: _repeatIndex == 3 ? 52 : (_repeatIndex == 2 ? 12 : 50),
                  divisions: _repeatIndex == 3
                      ? 51
                      : (_repeatIndex == 2 ? 11 : 49),
                  label: '$_interval',
                  onChanged: (v) => setState(() => _interval = v.round()),
                ),
              ),
              Text('每 $_interval ${_repeatLabels[_repeatIndex].replaceAll("每", "").replaceAll("不重复", "年")}'),
            ],
          ),
        ],
        const SizedBox(height: 16),
        // 包含起始日开关
        SwitchListTile(
          value: _includeStart,
          onChanged: (v) => setState(() => _includeStart = v),
          title: const Text('正数天数包含起始日'),
          subtitle: const Text('开启后，未来目标天数会 +1（如 1 天后显示为 2 天）'),
        ),
        const SizedBox(height: 16),
        // 卡片文本（备注标签）
        Row(
          children: [
            const Icon(Icons.label_outline, size: 20),
            const SizedBox(width: 8),
            Text('卡片文本（备注标签）',
                style: Theme.of(context).textTheme.titleSmall),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _note,
          maxLines: 2,
          decoration: const InputDecoration(
            hintText: '显示在卡片上的文本（如"生日""纪念日"）',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.edit_outlined),
          ),
        ),
        const SizedBox(height: 16),
        // 预览
        Card(
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
                  Text('预览',
                      style: Theme.of(ctx).textTheme.labelMedium),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      calc.isToday
                          ? '就是今天'
                          : (calc.isUpcoming
                              ? '还有 ${calc.count} 天'
                              : '已过 ${calc.absCount} 天'),
                      style:
                          Theme.of(ctx).textTheme.headlineLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: scheme.primary,
                              ),
                    ),
                  ),
                  if (calc.targetLabel.isNotEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          calc.targetLabel,
                          style: Theme.of(ctx)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: scheme.onSurfaceVariant),
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
