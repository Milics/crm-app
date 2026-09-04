import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/app_provider.dart';
import '../models/clue.dart';

/// 数据统计页（原型图：饼图+柱状图+核心指标+咨询师排行）
class StatisticPage extends StatefulWidget {
  const StatisticPage({super.key});

  @override
  State<StatisticPage> createState() => _StatisticPageState();
}

class _StatisticPageState extends State<StatisticPage> {
  int? _touchedPieIndex;

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Consumer<AppProvider>(
        builder: (context, provider, _) {
          final totalClues = provider.totalClues;
          final attendedCount = provider.attendedCount;
          final enrolled = provider.enrolledCount;
          final overdueCount = provider.overdueCount;

          final sourceStats = provider.sourceStats;
          final subjectStats = provider.subjectStats;

          return MediaQuery.removePadding(
            context: context,
            removeTop: true,
            child: SingleChildScrollView(
              padding: EdgeInsets.zero,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                // 顶部沉浸式蓝色Banner（自然融入状态栏，去除冗余大标题）
                Container(
                  color: const Color(0xFF1976D2),
                  padding: EdgeInsets.fromLTRB(16, topPadding + 14, 16, 20),
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
                              '${_formatDate(DateTime.now())} 数据概览',
                              style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.8),
                                  fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text('本月',
                            style:
                                TextStyle(color: Colors.white, fontSize: 12)),
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(16),
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
                        childAspectRatio: 1.5,
                        children: [
                          _MetricCard(
                            label: '新增线索',
                            value: '$totalClues',
                            icon: Icons.person_add_alt,
                            color: const Color(0xFF1976D2),
                            subLabel: '总计',
                          ),
                          _MetricCard(
                            label: '逾期',
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
                            subLabel: '推进中',
                          ),
                          _MetricCard(
                            label: '已报名',
                            value: '$enrolled',
                            icon: Icons.school,
                            color: Colors.green,
                            subLabel: '转化',
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // 渠道来源饼图
                      _SectionTitle(title: '线索渠道分布'),
                      const SizedBox(height: 12),
                      _buildPieChart(sourceStats),
                      const SizedBox(height: 20),

                      // 报考科目柱状图
                      _SectionTitle(title: '报考科目分布'),
                      const SizedBox(height: 12),
                      _buildBarChart(subjectStats),
                      const SizedBox(height: 20),

                      // 咨询师业绩排行
                      _SectionTitle(title: '咨询师业绩排行'),
                      const SizedBox(height: 12),
                      _buildRankList(provider),
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

  Widget _buildPieChart(Map<String, int> sourceStats) {
    if (sourceStats.isEmpty || sourceStats.values.every((v) => v == 0)) {
      return _EmptyChart(label: '暂无渠道数据');
    }

    final colors = [
      const Color(0xFF1976D2),
      const Color(0xFF42A5F5),
      const Color(0xFF4CAF50),
      const Color(0xFFFF9800),
      const Color(0xFF9C27B0),
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
                    final pct = (e.value / total * 100).toStringAsFixed(0);
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
      return _EmptyChart(label: '暂无报考科目数据');
    }

    final entries = subjectStats.entries.where((e) => e.value > 0).toList();
    if (entries.isEmpty) {
      return _EmptyChart(label: '暂无报考科目数据');
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

  Widget _buildRankList(AppProvider provider) {
    // 收集所有有效顾问/员工姓名（去重）
    final advisorNames = <String>{};
    for (final u in provider.users) {
      if (u.name.isNotEmpty) advisorNames.add(u.name);
    }
    for (final c in provider.clues) {
      if (c.ownerName.isNotEmpty) advisorNames.add(c.ownerName);
    }

    // 统计每位顾问的真实：线索数(0.5分) / 试听数(3分) / 报名数(10分)
    final ranks = advisorNames.map((name) {
      final advisorClues = provider.clues.where((c) =>
          c.ownerName == name ||
          provider.users.any((u) => u.name == name && c.ownerName == u.username)).toList();

      final cluesCount = advisorClues.length;
      final attendedCount = advisorClues
          .where((c) => c.status == ClueStatus.attended)
          .length;
      final enrolledCount = advisorClues
          .where((c) => c.status == ClueStatus.enrolled)
          .length;

      return _RankItem(
        name: name,
        clues: cluesCount,
        attended: attendedCount,
        enrolled: enrolledCount,
      );
    }).toList();

    // 根据总积分从高到低严格倒序排序，积分相同时按报名数倒序
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
          Row(
            children: const [
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

  String _formatDate(DateTime d) =>
      '${d.year}年${d.month}月${d.day}日';
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
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: color),
              ),
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
