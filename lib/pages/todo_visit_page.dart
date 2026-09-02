import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/app_provider.dart';
import '../models/clue.dart';
import 'clue_detail_page.dart';

/// 待回访列表页
class TodoVisitPage extends StatelessWidget {
  const TodoVisitPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('待回访')),
      body: Consumer<AppProvider>(
        builder: (context, provider, _) {
          final todos = provider.todoClues;

          if (todos.isEmpty) {
            return RefreshIndicator(
              onRefresh: () async {
                final success = await provider.refreshClues();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(success ? '☁️ 已从云端同步最新数据' : '⚠️ 同步失败，请检查网络'),
                      duration: const Duration(seconds: 2),
                      backgroundColor: success ? Colors.green : Colors.orange,
                    ),
                  );
                }
              },
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.25),
                  const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.event_available, size: 64, color: Colors.grey),
                        SizedBox(height: 12),
                        Text('暂无待回访线索', style: TextStyle(color: Colors.grey)),
                        SizedBox(height: 6),
                        Text('在线索详情中设置回访时间后将在此显示（下拉可同步云端）',
                            style: TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }

          // 分组：今天、明天、以后
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);
          final tomorrow = today.add(const Duration(days: 1));

          final overdue = todos
              .where((c) => c.nextVisitTime!.isBefore(today))
              .toList();
          final todayList = todos
              .where((c) =>
                  !c.nextVisitTime!.isBefore(today) &&
                  c.nextVisitTime!.isBefore(tomorrow))
              .toList();
          final futureList = todos
              .where((c) => !c.nextVisitTime!.isBefore(tomorrow))
              .toList();

          return RefreshIndicator(
            onRefresh: () async {
              final success = await provider.refreshClues();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? '☁️ 已从云端同步最新数据' : '⚠️ 同步失败，请检查网络'),
                    duration: const Duration(seconds: 2),
                    backgroundColor: success ? Colors.green : Colors.orange,
                  ),
                );
              }
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(12),
              children: [
                if (overdue.isNotEmpty) ...[
                  _SectionHeader(
                      title: '已逾期', count: overdue.length, color: Colors.red),
                  ...overdue.map((c) => _TodoCard(clue: c, isOverdue: true)),
                ],
                if (todayList.isNotEmpty) ...[
                  _SectionHeader(
                      title: '今日回访',
                      count: todayList.length,
                      color: Colors.orange),
                  ...todayList.map((c) => _TodoCard(clue: c, isToday: true)),
                ],
                if (futureList.isNotEmpty) ...[
                  _SectionHeader(
                      title: '即将回访',
                      count: futureList.length,
                      color: Colors.blue),
                  ...futureList.map((c) => _TodoCard(clue: c)),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final int count;
  final Color color;

  const _SectionHeader(
      {required this.title, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 6),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 16,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: color,
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: TextStyle(fontSize: 12, color: color),
            ),
          ),
        ],
      ),
    );
  }
}

class _TodoCard extends StatelessWidget {
  final Clue clue;
  final bool isOverdue;
  final bool isToday;

  const _TodoCard(
      {required this.clue, this.isOverdue = false, this.isToday = false});

  @override
  Widget build(BuildContext context) {
    Color accentColor = isOverdue
        ? Colors.red
        : isToday
            ? Colors.orange
            : Colors.blue;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: accentColor.withOpacity(0.2)),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ClueDetailPage(clueId: clue.id),
            ),
          );
        },
        leading: CircleAvatar(
          backgroundColor: accentColor.withOpacity(0.15),
          child: Text(
            clue.wxNick.isNotEmpty ? clue.wxNick[0] : '?',
            style: TextStyle(
                color: accentColor, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          clue.wxNick,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (clue.subject.isNotEmpty)
              Text(clue.subject,
                  style:
                      const TextStyle(color: Colors.grey, fontSize: 12)),
            Row(
              children: [
                Icon(Icons.schedule, size: 13, color: accentColor),
                const SizedBox(width: 4),
                Text(
                  DateFormat('MM月dd日 HH:mm')
                      .format(clue.nextVisitTime!),
                  style: TextStyle(
                      fontSize: 12,
                      color: accentColor,
                      fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      ),
    );
  }
}
