import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/app_provider.dart';
import '../models/clue.dart';

/// 数据统计页（支持届别多选、时间周期、销售人员多维联动筛选，支持点击按钮向下展开筛选器）
class StatisticPage extends StatefulWidget {
  const StatisticPage({super.key});

  @override
  State<StatisticPage> createState() => _StatisticPageState();
}

class _StatisticPageState extends State<StatisticPage> {
  int? _touchedPieIndex;

  // 筛选器面板是否向下展开（默认收起，点击右上角按钮切换展开/收起）
  bool _isFilterExpanded = false;

  // 多维筛选状态
  final Set<String> _selectedGrades = {}; // 为空表示全部届别，非空表示多选的具体届别（如 '26级', '25级'）
  String _selectedTimeRange = 'all'; // 'all', 'this_month', 'this_week', 'today'
  String _selectedAdvisor = 'all'; // 'all', 'mine', 或具体顾问姓名（仅超管可用）

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Consumer<AppProvider>(
        builder: (context, provider, _) {
          // 1. 基础线索池（基于用户角色权限与所选顾问）
          List<Clue> baseClues;
          if (!provider.canViewAllClues) {
            // 普通销售：严格只统计归属于本人的线索
            baseClues = provider.clues.where((c) =>
                c.ownerName.isNotEmpty &&
                (c.ownerName == provider.currentUser ||
                    c.ownerName == provider.currentUserObj?.username)).toList();
          } else {
            // 超级管理员：可自由切换看全员、我的或指定销售顾问
            if (_selectedAdvisor == 'mine') {
              baseClues = provider.clues.where((c) =>
                  c.ownerName.isNotEmpty &&
                  (c.ownerName == provider.currentUser ||
                      c.ownerName == provider.currentUserObj?.username)).toList();
            } else if (_selectedAdvisor != 'all') {
              baseClues = provider.clues.where((c) =>
                  c.ownerName == _selectedAdvisor ||
                  (provider.users.any((u) =>
                      u.name == _selectedAdvisor && c.ownerName == u.username))).toList();
            } else {
              baseClues = List.from(provider.clues);
            }
          }

          // 2. 届别/年级过滤（支持除“全部”外的多选）
          List<Clue> gradeFilteredClues = baseClues;
          if (_selectedGrades.isNotEmpty) {
            gradeFilteredClues = baseClues.where((c) {
              final norm = AppProvider.normalizeGrade(c.grade);
              return _selectedGrades.contains(norm);
            }).toList();
          }

          // 3. 时间范围计算起点
          final now = DateTime.now();
          final todayStart = DateTime(now.year, now.month, now.day);
          final weekStart = todayStart.subtract(Duration(days: now.weekday - 1));
          final monthStart = DateTime(now.year, now.month, 1);

          DateTime? timeFilterStart;
          if (_selectedTimeRange == 'today') {
            timeFilterStart = todayStart;
          } else if (_selectedTimeRange == 'this_week') {
            timeFilterStart = weekStart;
          } else if (_selectedTimeRange == 'this_month') {
            timeFilterStart = monthStart;
          }

          // 4. 统计切片计算
          final DateTime? start = timeFilterStart;

          // 新增线索总数
          final totalCluesCount = start == null
              ? gradeFilteredClues.length
              : gradeFilteredClues.where((c) => c.createTime.isAfter(start)).length;

          // 当前待办逾期量（属于当前所选届别和顾问的逾期线索）
          final overdueCount = gradeFilteredClues
              .where((c) => c.nextVisitTime != null && c.nextVisitTime!.isBefore(now))
              .length;

          // 已试听量
          final attendedCount = start == null
              ? gradeFilteredClues.where((c) => c.status == ClueStatus.attended).length
              : gradeFilteredClues.where((c) =>
                  c.status == ClueStatus.attended &&
                  (c.createTime.isAfter(start) ||
                      c.visitLogs.any((v) => v.createTime.isAfter(start)))).length;

          // 已报名量
          final enrolledCount = start == null
              ? gradeFilteredClues.where((c) => c.status == ClueStatus.enrolled).length
              : gradeFilteredClues.where((c) =>
                  c.status == ClueStatus.enrolled &&
                  (c.effectiveEnrollTime.isAfter(start) ||
                      c.createTime.isAfter(start))).length;

          // 转化率计算
          final attendRate = totalCluesCount > 0
              ? (attendedCount / totalCluesCount * 100).toStringAsFixed(1)
              : '0.0';
          final enrollRate = totalCluesCount > 0
              ? (enrolledCount / totalCluesCount * 100).toStringAsFixed(1)
              : '0.0';

          // 5. 当前切片图表线索集（供渠道分布饼图和报考科目柱状图使用）
          final chartClues = start == null
              ? gradeFilteredClues
              : gradeFilteredClues.where((c) => c.createTime.isAfter(start)).toList();

          final sourceStats = _computeSourceStats(chartClues);
          final subjectStats = _computeSubjectStats(chartClues);

          // 格式化时间标签与届别标签
          final timeRangeLabel = _getTimeRangeLabel(_selectedTimeRange);
          final gradeLabel = _getGradesSummaryLabel();

          return MediaQuery.removePadding(
            context: context,
            removeTop: true,
            child: SingleChildScrollView(
              padding: EdgeInsets.zero,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 顶部沉浸式蓝色Banner
                  Container(
                    color: const Color(0xFF1976D2),
                    padding: EdgeInsets.fromLTRB(16, topPadding + 14, 16, 18),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '你好，${provider.currentUser} 👋',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${_formatDate(DateTime.now())} · $gradeLabel · $timeRangeLabel',
                                style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.85),
                                    fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        // 顶部展开/收起筛选器按钮（点击向下展示现在的筛选器）
                        InkWell(
                          onTap: () => setState(() => _isFilterExpanded = !_isFilterExpanded),
                          borderRadius: BorderRadius.circular(20),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: _isFilterExpanded
                                  ? Colors.white
                                  : Colors.white.withValues(alpha: 0.22),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: _isFilterExpanded
                                    ? Colors.white
                                    : Colors.white.withValues(alpha: 0.35),
                                width: 1,
                              ),
                              boxShadow: _isFilterExpanded
                                  ? [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.12),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.tune_rounded,
                                  size: 13,
                                  color: _isFilterExpanded
                                      ? const Color(0xFF1976D2)
                                      : Colors.white,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  timeRangeLabel,
                                  style: TextStyle(
                                      color: _isFilterExpanded
                                          ? const Color(0xFF1976D2)
                                          : Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(width: 3),
                                Icon(
                                  _isFilterExpanded
                                      ? Icons.keyboard_arrow_up
                                      : Icons.keyboard_arrow_down,
                                  size: 16,
                                  color: _isFilterExpanded
                                      ? const Color(0xFF1976D2)
                                      : Colors.white,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 点击按钮后，向下展开的筛选器面板（带丝滑尺寸动画）
                  AnimatedSize(
                    duration: const Duration(milliseconds: 240),
                    curve: Curves.easeInOut,
                    child: _isFilterExpanded
                        ? _buildFilterControlPanel(provider)
                        : const SizedBox.shrink(),
                  ),

                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 核心指标 2x2（顺序：1.新增线索 2.逾期 3.已试听 4.已报名）
                        GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          padding: EdgeInsets.zero,
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 1.48,
                          children: [
                            _MetricCard(
                              label: '新增线索',
                              value: '$totalCluesCount',
                              icon: Icons.person_add_alt,
                              color: const Color(0xFF1976D2),
                              subLabel: _selectedTimeRange == 'all' ? '总计' : timeRangeLabel,
                            ),
                            _MetricCard(
                              label: '逾期待跟进',
                              value: '$overdueCount',
                              icon: Icons.warning_amber_rounded,
                              color: overdueCount > 0 ? Colors.red : Colors.grey,
                              subLabel: '需处理',
                            ),
                            _MetricCard(
                              label: '已试听',
                              value: '$attendedCount',
                              icon: Icons.headphones_outlined,
                              color: Colors.deepOrange,
                              subLabel: '转化率 $attendRate%',
                            ),
                            _MetricCard(
                              label: '已报名',
                              value: '$enrolledCount',
                              icon: Icons.school,
                              color: Colors.green,
                              subLabel: '转化率 $enrollRate%',
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // 综合转化率成效条
                        _buildConversionBanner(totalCluesCount, attendedCount,
                            enrolledCount, attendRate, enrollRate),
                        const SizedBox(height: 20),

                        // 渠道来源饼图
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _SectionTitle(title: '线索渠道分布'),
                            Text(
                              '共 $totalCluesCount 条',
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildPieChart(sourceStats),
                        const SizedBox(height: 20),

                        // 报考科目柱状图
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _SectionTitle(title: '报考科目分布'),
                            Text(
                              '专升本专业意向',
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildBarChart(subjectStats),
                        const SizedBox(height: 20),

                        // 咨询师业绩排行（支持届别与时间周期联动战报）
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _SectionTitle(title: '咨询师业绩排行'),
                            Text(
                              '$gradeLabel · $timeRangeLabel',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: const Color(0xFF1976D2),
                                  fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildRankList(provider, timeFilterStart),
                        const SizedBox(height: 100), // 留出底部导航栏安全距离
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// 顶部多维筛选控制面板（向下滑出展示）
  Widget _buildFilterControlPanel(AppProvider provider) {
    final allGrades = provider.allGrades;

    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(
          bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. 届别筛选胶囊行（除了“全部届别”，其他支持多选）
          Row(
            children: [
              const Icon(Icons.school_outlined,
                  size: 16, color: Color(0xFF1976D2)),
              const SizedBox(width: 6),
              const Text(
                '届别：',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF334155),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      // 全部届别（单选重置）
                      _buildChip(
                        label: '全部届别',
                        isSelected: _selectedGrades.isEmpty,
                        onTap: () {
                          setState(() {
                            _selectedGrades.clear();
                          });
                        },
                      ),
                      // 具体届别（支持多选）
                      ...allGrades.map((g) {
                        final isSelected = _selectedGrades.contains(g);
                        return _buildChip(
                          label: _getGradeDisplayWithRemark(g),
                          isSelected: isSelected,
                          isMultiSelect: true,
                          onTap: () {
                            setState(() {
                              if (_selectedGrades.contains(g)) {
                                _selectedGrades.remove(g);
                              } else {
                                _selectedGrades.add(g);
                              }
                            });
                          },
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // 2. 时间周期筛选胶囊行（直接在此点击切换，无需底部弹窗）
          Row(
            children: [
              const Icon(Icons.access_time_rounded,
                  size: 16, color: Color(0xFF0284C7)),
              const SizedBox(width: 6),
              const Text(
                '周期：',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF334155),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildChip(
                        label: '全部时间',
                        isSelected: _selectedTimeRange == 'all',
                        onTap: () => setState(() => _selectedTimeRange = 'all'),
                      ),
                      _buildChip(
                        label: '本月',
                        isSelected: _selectedTimeRange == 'this_month',
                        onTap: () =>
                            setState(() => _selectedTimeRange = 'this_month'),
                      ),
                      _buildChip(
                        label: '本周',
                        isSelected: _selectedTimeRange == 'this_week',
                        onTap: () =>
                            setState(() => _selectedTimeRange = 'this_week'),
                      ),
                      _buildChip(
                        label: '今日',
                        isSelected: _selectedTimeRange == 'today',
                        onTap: () =>
                            setState(() => _selectedTimeRange = 'today'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // 3. 销售顾问切换行（仅超级管理员有权查看全员与其他顾问）
          if (provider.canViewAllClues) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.badge_outlined,
                    size: 16, color: Color(0xFF0D9488)),
                const SizedBox(width: 6),
                const Text(
                  '人员：',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF334155),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildChip(
                          label: '全员汇总',
                          isSelected: _selectedAdvisor == 'all',
                          onTap: () =>
                              setState(() => _selectedAdvisor = 'all'),
                        ),
                        _buildChip(
                          label: '我的',
                          isSelected: _selectedAdvisor == 'mine',
                          onTap: () =>
                              setState(() => _selectedAdvisor = 'mine'),
                        ),
                        ...provider.allAdvisorNames
                            .where((name) =>
                                name != provider.currentUser &&
                                name.isNotEmpty)
                            .map((name) {
                          return _buildChip(
                            label: name,
                            isSelected: _selectedAdvisor == name,
                            onTap: () =>
                                setState(() => _selectedAdvisor = name),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            // 普通销售：展示专属提示，明确告知当前是个人私有线索统计
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  const Icon(Icons.shield_outlined,
                      size: 13, color: Color(0xFF16A34A)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '专属看板：仅统计您本人负责的私有线索（${provider.currentUser}）',
                      style: const TextStyle(
                          fontSize: 11, color: Color(0xFF475569)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 筛选胶囊小部件（支持多选指示勾选标记）
  Widget _buildChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    bool isMultiSelect = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF1976D2) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? const Color(0xFF1976D2) : Colors.transparent,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isMultiSelect && isSelected) ...[
                const Icon(Icons.check, size: 12, color: Colors.white),
                const SizedBox(width: 3),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? Colors.white : const Color(0xFF475569),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 转化成效展示条
  Widget _buildConversionBanner(
    int total,
    int attended,
    int enrolled,
    String attendRate,
    String enrollRate,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.deepOrange,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                const Text('试听率：',
                    style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                Text(
                  '$attendRate%',
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepOrange),
                ),
              ],
            ),
          ),
          Container(width: 1, height: 20, color: const Color(0xFFE2E8F0)),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                const Text('最终报名转化率：',
                    style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                Text(
                  '$enrollRate%',
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.green),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 渠道分布计算
  Map<String, int> _computeSourceStats(List<Clue> clues) {
    final map = <String, int>{};
    for (final c in clues) {
      final key = c.source.isEmpty ? '其他' : c.source;
      map[key] = (map[key] ?? 0) + 1;
    }
    return map;
  }

  /// 科目分布计算
  Map<String, int> _computeSubjectStats(List<Clue> clues) {
    const standardOrder = [
      '高数',
      '管理',
      '语文',
      '经济',
      '法学',
      '教心',
      '生理病理',
      '中医',
      '动植遗传',
      '美术',
      '音乐',
      '舞蹈',
      '体育',
    ];

    final map = <String, int>{for (var s in standardOrder) s: 0};

    String normalize(String raw) {
      final s = raw.trim();
      if (s.isEmpty) return '未填写';
      if (s.contains('高数') ||
          s.contains('高等数学') ||
          s.contains('理工') ||
          s.contains('计算机')) {
        return '高数';
      }
      if (s.contains('管理') || s.contains('经管') || s.contains('工商')) {
        return '管理';
      }
      if (s.contains('语文') || s.contains('大学语文') || s.contains('文史')) {
        return '语文';
      }
      if (s.contains('经济')) return '经济';
      if (s.contains('法学')) return '法学';
      if (s.contains('教心') ||
          s.contains('教育学') ||
          s.contains('教育') ||
          s.contains('心理')) {
        return '教心';
      }
      if (s.contains('生理') ||
          s.contains('病理') ||
          s.contains('解剖') ||
          s.contains('医学')) {
        return '生理病理';
      }
      if (s.contains('中医')) return '中医';
      if (s.contains('动植') ||
          s.contains('动物') ||
          s.contains('植物') ||
          s.contains('遗传') ||
          s.contains('农学')) {
        return '动植遗传';
      }
      if (s.contains('美术') || s.contains('艺术') || s.contains('设计')) {
        return '美术';
      }
      if (s.contains('音乐') || s.contains('声乐')) return '音乐';
      if (s.contains('舞蹈')) return '舞蹈';
      if (s.contains('体育')) return '体育';
      return s;
    }

    for (final c in clues) {
      final normKey = normalize(c.subject);
      map[normKey] = (map[normKey] ?? 0) + 1;
    }

    return map;
  }

  Widget _buildPieChart(Map<String, int> sourceStats) {
    if (sourceStats.isEmpty || sourceStats.values.every((v) => v == 0)) {
      return _EmptyChart(label: '当前筛选条件下暂无渠道数据');
    }

    final colors = [
      const Color(0xFF1976D2),
      const Color(0xFF42A5F5),
      const Color(0xFF4CAF50),
      const Color(0xFFFF9800),
      const Color(0xFF9C27B0),
      const Color(0xFF00ACC1),
      const Color(0xFFEC407A),
      const Color(0xFF8D6E63),
    ];

    final entries = sourceStats.entries.where((e) => e.value > 0).toList();
    final total = entries.fold(0, (s, e) => s + e.value);

    final sections = entries.asMap().entries.map((entry) {
      final i = entry.key;
      final e = entry.value;
      final isTouched = _touchedPieIndex == i;
      return PieChartSectionData(
        value: e.value.toDouble(),
        color: colors[i % colors.length],
        radius: isTouched ? 65 : 55,
        title: isTouched ? '${e.key}\n${e.value}' : '',
        titleStyle: const TextStyle(
            fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold),
      );
    }).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          SizedBox(
            height: entries.length > 5 ? 200 : 180,
            child: Row(
              children: [
                Expanded(
                  child: PieChart(
                    PieChartData(
                      sections: sections,
                      pieTouchData: PieTouchData(
                        touchCallback: (event, response) {
                          setState(() {
                            if (response == null ||
                                response.touchedSection == null) {
                              _touchedPieIndex = null;
                            } else {
                              _touchedPieIndex = response
                                  .touchedSection!.touchedSectionIndex;
                            }
                          });
                        },
                      ),
                      centerSpaceRadius: 36,
                      sectionsSpace: 2,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: entries.asMap().entries.map((entry) {
                    final i = entry.key;
                    final e = entry.value;
                    final pct = total > 0
                        ? (e.value / total * 100).toStringAsFixed(0)
                        : '0';
                    return Padding(
                      padding: EdgeInsets.only(
                          bottom: entries.length > 5 ? 4.5 : 7.0),
                      child: Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: colors[i % colors.length],
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text('${e.key}  $pct%',
                              style: const TextStyle(fontSize: 12)),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBarChart(Map<String, int> subjectStats) {
    if (subjectStats.isEmpty || subjectStats.values.every((v) => v == 0)) {
      return _EmptyChart(label: '当前筛选条件下暂无报考科目数据');
    }

    final entries = subjectStats.entries.where((e) => e.value > 0).toList();
    if (entries.isEmpty) {
      return _EmptyChart(label: '当前筛选条件下暂无报考科目数据');
    }

    final maxVal = entries.map((e) => e.value).reduce((a, b) => a > b ? a : b);
    final needScroll = entries.length > 6;
    final chartWidth = needScroll ? entries.length * 56.0 : null;

    final chartWidget = SizedBox(
      height: 200,
      width: chartWidth,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: (maxVal + 1).toDouble(),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                return BarTooltipItem(
                  '${entries[groupIndex].key}\n${rod.toY.toInt()}人',
                  const TextStyle(color: Colors.white, fontSize: 12),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final i = value.toInt();
                  if (i >= entries.length) {
                    return const SizedBox();
                  }
                  final label = entries[i].key;
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFF666666),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                },
                reservedSize: 32,
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 26,
                getTitlesWidget: (value, meta) {
                  if (value % 1 != 0) return const SizedBox();
                  return Text(
                    '${value.toInt()}',
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  );
                },
              ),
            ),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 1,
            getDrawingHorizontalLine: (_) =>
                const FlLine(color: Color(0xFFEEEEEE), strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
          barGroups: entries.asMap().entries.map((entry) {
            final i = entry.key;
            final e = entry.value;
            return BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: e.value.toDouble(),
                  color: const Color(0xFF1976D2),
                  width: 20,
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(6)),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: needScroll
          ? SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: chartWidget,
            )
          : chartWidget,
    );
  }

  /// 咨询师排行榜（完全随选中的届别多选与时间段动态计算积分战报）
  Widget _buildRankList(AppProvider provider, DateTime? timeFilterStart) {
    // 收集所有顾问姓名（去重）
    final advisorNames = <String>{};
    for (final u in provider.users) {
      if (u.name.isNotEmpty) advisorNames.add(u.name);
    }
    for (final c in provider.clues) {
      if (c.ownerName.isNotEmpty) advisorNames.add(c.ownerName);
    }

    // 计算每位顾问在选定届别与时间周期下的业绩
    final ranks = advisorNames.map((name) {
      var advisorClues = provider.clues.where((c) =>
          c.ownerName == name ||
          provider.users.any((u) => u.name == name && c.ownerName == u.username)).toList();

      // 届别多选过滤
      if (_selectedGrades.isNotEmpty) {
        advisorClues = advisorClues.where((c) {
          final norm = AppProvider.normalizeGrade(c.grade);
          return _selectedGrades.contains(norm);
        }).toList();
      }

      // 时间切片过滤
      final DateTime? start = timeFilterStart;
      final clueCount = start == null
          ? advisorClues.length
          : advisorClues.where((c) => c.createTime.isAfter(start)).length;

      final attendedCount = start == null
          ? advisorClues.where((c) => c.status == ClueStatus.attended).length
          : advisorClues.where((c) =>
              c.status == ClueStatus.attended &&
              (c.createTime.isAfter(start) ||
                  c.visitLogs.any((v) => v.createTime.isAfter(start)))).length;

      final enrolledCount = start == null
          ? advisorClues.where((c) => c.status == ClueStatus.enrolled).length
          : advisorClues.where((c) =>
              c.status == ClueStatus.enrolled &&
              (c.effectiveEnrollTime.isAfter(start) ||
                  c.createTime.isAfter(start))).length;

      return _RankItem(
        name: name,
        clues: clueCount,
        attended: attendedCount,
        enrolled: enrolledCount,
      );
    }).toList();

    // 倒序排列：总积分高 -> 低，同分看报名数
    ranks.sort((a, b) {
      final sc = b.score.compareTo(a.score);
      if (sc != 0) return sc;
      final ec = b.enrolled.compareTo(a.enrolled);
      if (ec != 0) return ec;
      return b.attended.compareTo(a.attended);
    });

    if (ranks.isEmpty) {
      return _EmptyChart(label: '暂无顾问业绩数据');
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 计分规则说明胶囊
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Row(
              children: [
                Icon(Icons.stars_rounded, size: 15, color: Color(0xFFE65100)),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '积分规则：线索 +0.5分 · 试听 +3分 · 报名 +10分',
                    style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                  ),
                ),
              ],
            ),
          ),

          // 表头
          const Row(
            children: [
              SizedBox(width: 28),
              Expanded(
                child: Text('姓名',
                    style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        fontWeight: FontWeight.bold)),
              ),
              SizedBox(
                  width: 38,
                  child: Text('线索',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                      textAlign: TextAlign.center)),
              SizedBox(
                  width: 38,
                  child: Text('试听',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                      textAlign: TextAlign.center)),
              SizedBox(
                  width: 38,
                  child: Text('报名',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                      textAlign: TextAlign.center)),
              SizedBox(
                  width: 52,
                  child: Text('总分',
                      style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF1976D2),
                          fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center)),
            ],
          ),
          const Divider(height: 16),

          // 榜单行
          ...ranks.asMap().entries.map((entry) {
            final i = entry.key;
            final r = entry.value;
            final rankColors = [
              const Color(0xFFFFB300), // 金
              const Color(0xFF90A4AE), // 银
              const Color(0xFFBCAAA4), // 铜
            ];

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: i < 3 ? rankColors[i] : Colors.grey[200],
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${i + 1}',
                        style: TextStyle(
                          color: i < 3 ? Colors.white : Colors.grey[600],
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      r.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(
                    width: 38,
                    child: Text('${r.clues}',
                        style: const TextStyle(fontSize: 13),
                        textAlign: TextAlign.center),
                  ),
                  SizedBox(
                    width: 38,
                    child: Text(
                      '${r.attended}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: r.attended > 0
                            ? FontWeight.w600
                            : FontWeight.normal,
                        color: r.attended > 0
                            ? const Color(0xFF00897B)
                            : Colors.grey[700],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  SizedBox(
                    width: 38,
                    child: Text(
                      '${r.enrolled}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: r.enrolled > 0
                            ? const Color(0xFF2E7D32)
                            : Colors.grey,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  SizedBox(
                    width: 52,
                    child: Text(
                      r.scoreFormatted,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: i < 3
                            ? const Color(0xFF1976D2)
                            : Colors.grey[800],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration() => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      );

  String _formatDate(DateTime d) => '${d.year}年${d.month}月${d.day}日';

  String _getTimeRangeLabel(String range) {
    switch (range) {
      case 'today':
        return '今日';
      case 'this_week':
        return '本周';
      case 'this_month':
        return '本月';
      default:
        return '全部时间';
    }
  }

  /// 届别多选摘要标签
  String _getGradesSummaryLabel() {
    if (_selectedGrades.isEmpty) return '全部届别';
    if (_selectedGrades.length == 1) {
      return _getGradeDisplayWithRemark(_selectedGrades.first);
    }
    final labels = _selectedGrades.map((g) {
      final clean = g.replaceAll('级', '').replaceAll('届', '').trim();
      return '${clean}届';
    }).toList();
    if (labels.length <= 2) {
      return labels.join('+');
    }
    return '${labels.take(2).join('+')}等${labels.length}届';
  }

  /// 届别显示名称，自动补齐大一/大二/大三标注，业务沟通零成本
  String _getGradeDisplayWithRemark(String gradeKey) {
    final clean = gradeKey.replaceAll('级', '').replaceAll('届', '').trim();
    if (clean == '26') return '26届 (大一)';
    if (clean == '25') return '25届 (大二)';
    if (clean == '24') return '24届 (大三)';
    if (clean.isNotEmpty) return '$clean届';
    return gradeKey;
  }
}

class _RankItem {
  final String name;
  final int clues;
  final int attended;
  final int enrolled;
  final double score;

  _RankItem({
    required this.name,
    required this.clues,
    required this.attended,
    required this.enrolled,
  }) : score = (clues * 0.5) + (attended * 3.0) + (enrolled * 10.0);

  String get scoreFormatted {
    if (score == score.roundToDouble()) {
      return '${score.toInt()}分';
    }
    return '${score.toStringAsFixed(1)}分';
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final String subLabel;

  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.subLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const Spacer(),
              Text(subLabel,
                  style:
                      TextStyle(color: Colors.grey[400], fontSize: 11)),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: color),
              ),
              const SizedBox(height: 2),
              Text(label,
                  style: TextStyle(
                      color: Colors.grey[600], fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 16,
          decoration: BoxDecoration(
            color: const Color(0xFF1976D2),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: Color(0xFF333333)),
        ),
      ],
    );
  }
}

class _EmptyChart extends StatelessWidget {
  final String label;
  const _EmptyChart({required this.label});
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Center(
        child: Text(label,
            style: TextStyle(color: Colors.grey[400], fontSize: 13)),
      ),
    );
  }
}
