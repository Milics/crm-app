import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/app_provider.dart';
import '../models/clue.dart';
import 'add_visit_page.dart';
import 'upload_chat_page.dart';
import 'ai_analysis_page.dart';
import 'enroll_page.dart';
import 'edit_clue_page.dart';
import 'materials_page.dart';

/// 线索详情页（包含信息区、推荐话术、4按钮操作区及时间轴）
class ClueDetailPage extends StatelessWidget {
  final String clueId;
  const ClueDetailPage({super.key, required this.clueId});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final clue = provider.getClueById(clueId);
        if (clue == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('线索详情')),
            body: const Center(child: Text('线索不存在')),
          );
        }

        return Scaffold(
          backgroundColor: const Color(0xFFF5F7FA),
          appBar: AppBar(
            title: const Text('线索详情'),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                tooltip: '编辑信息',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => EditCluePage(clue: clue)),
                ),
              ),
            ],
          ),
          body: SafeArea(
            top: false,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // 顶部信息卡片（蓝色背景）
                  _HeaderCard(clue: clue),

                  const SizedBox(height: 12),

                  // 推荐沟通话术卡片（智能跟进工具）
                  _RecommendScriptCard(clue: clue),

                  const SizedBox(height: 12),

                  // 4个操作按钮横排
                  _ActionButtons(clue: clue),

                  const SizedBox(height: 12),

                  // 沟通截图档案区域 (真实微信聊天记录)
                  if (clue.chatRecords.isNotEmpty) ...[
                    _ChatRecordsSection(clue: clue),
                    const SizedBox(height: 12),
                  ],

                  // 时间轴区域
                  _TimelineSection(clue: clue),

                  const SizedBox(height: 56),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// 顶部信息卡片
class _HeaderCard extends StatelessWidget {
  final Clue clue;
  const _HeaderCard({required this.clue});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      decoration: const BoxDecoration(
        color: Color(0xFF1976D2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 头像 + 昵称行
          Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: Colors.white.withValues(alpha: 0.25),
                child: Text(
                  clue.wxNick.isNotEmpty ? clue.wxNick[0] : '?',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      clue.wxNick,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      clue.status.label,
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
              ),
              // 意向等级标志 — 白色半透明风格，与蓝色背景协调
              if (clue.intentLevel != IntentLevel.none)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.5)),
                  ),
                  child: Text(
                    clue.intentLevel.label,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // 信息行（三行网格）
          Column(
            children: [
              // 第一行：微信号 + 手机号
              Row(
                children: [
                  Expanded(
                    child: _InfoChip(
                      label: '微信号',
                      value: clue.wxId.isEmpty ? '未填写' : clue.wxId,
                    ),
                  ),
                  Container(width: 1, height: 32, color: Colors.white24),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 12),
                      child: _InfoChip(
                        label: '手机号',
                        value: clue.phone.isEmpty ? '未填写' : clue.phone,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // 第二行：就读学校 + 年级届别
              Row(
                children: [
                  Expanded(
                    child: _InfoChip(
                      label: '就读学校',
                      value: clue.school.isEmpty ? '未填写' : clue.school,
                      enableCopy: false,
                    ),
                  ),
                  Container(width: 1, height: 32, color: Colors.white24),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 12),
                      child: _InfoChip(
                        label: '年级/届别',
                        value: clue.grade.isEmpty ? '未填写' : clue.grade,
                        enableCopy: false,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // 第三行：报考科目 + 意向班型
              Row(
                children: [
                  Expanded(
                    child: _InfoChip(
                      label: '报考科目',
                      value: clue.subject.isEmpty ? '未填写' : clue.subject,
                      enableCopy: false,
                    ),
                  ),
                  Container(width: 1, height: 32, color: Colors.white24),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 12),
                      child: _InfoChip(
                        label: '意向班型',
                        value: clue.classType.isEmpty ? '未填写' : clue.classType,
                        enableCopy: false,
                      ),
                    ),
                  ),
                ],
              ),
              if (clue.tags.isNotEmpty) ...[
                const SizedBox(height: 14),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: clue.tags.map((t) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.35),
                          ),
                        ),
                        child: Text(
                          '#$t',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final String value;
  final bool enableCopy;

  const _InfoChip({
    required this.label,
    required this.value,
    this.enableCopy = true,
  });

  @override
  Widget build(BuildContext context) {
    final canCopy = enableCopy && value.isNotEmpty && value != '未填写';

    return InkWell(
      onTap: canCopy
          ? () {
              Clipboard.setData(ClipboardData(text: value));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('已复制$label: $value'),
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          : null,
      borderRadius: BorderRadius.circular(4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 12.5),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  value,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (canCopy) ...[
                const SizedBox(width: 4),
                const Icon(Icons.copy_rounded, size: 14, color: Colors.white70),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// 推荐沟通话术卡片组件
class _RecommendScriptCard extends StatelessWidget {
  final Clue clue;
  const _RecommendScriptCard({required this.clue});

  String _getRecommendTag() {
    switch (clue.status) {
      case ClueStatus.following:
        return '【待跟进】首次破冰话术';
      case ClueStatus.contacted:
        return '【联系中】试听邀约话术';
      case ClueStatus.invited:
        return '【已邀约】出席确认提醒';
      case ClueStatus.attended:
        return '【已试听】促成报名话术';
      case ClueStatus.enrolled:
        return '【已报名】老带新转介绍';
      case ClueStatus.paused:
        return '【暂搁置】复活关怀话术';
    }
  }

  String _getRecommendContent() {
    final name = clue.wxNick.isNotEmpty ? clue.wxNick : '同学';
    final subject = clue.subject.isNotEmpty ? clue.subject : '专升本';
    final classType = clue.classType.isNotEmpty ? clue.classType : '集训班';

    switch (clue.status) {
      case ClueStatus.following:
        return '同学你好呀！看到你关注了 $subject 专升本，目前准备得怎么样了呢？我们针对 $subject 整理了一份最新的备考真题与升本指南，方便发你一份了解下吗？';
      case ClueStatus.contacted:
        return '$name 同学，我们本周六刚好有专门针对 $subject 的 $classType 试听讲座，由名师带学讲解考点，名额有限，需要帮你预留一个试听席位吗？';
      case ClueStatus.invited:
        return '$name 同学，温馨提醒一下：您预约的 $subject 试听课程将于明天正式开始。地址已发您，期待您的到来，有任何路线问题随时联系我哦！';
      case ClueStatus.attended:
        return '$name 同学，上次的 $classType 试听课感受怎么样？老师讲的知识点都能消化吗？本周前报名可以享受早鸟优惠和赠送全套教材，有需要我帮你申请一下名额吗？';
      case ClueStatus.enrolled:
        return '$name 同学，恭喜成功报名 $classType！如果有认识同校想一起备考 $subject 的同学，推荐过来可以各获得 200 元图书卡哦！';
      case ClueStatus.paused:
        return '$name 同学好久不见！最近 $subject 专升本出台了最新的招生政策，顺便关怀一下你目前的复习进度，方便抽空聊聊吗？';
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = _getRecommendContent();
    final tag = _getRecommendTag();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE3F2FD)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF1976D2).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.auto_awesome, size: 15, color: Color(0xFF1976D2)),
                    const SizedBox(width: 5),
                    Text(
                      tag,
                      style: const TextStyle(
                        fontSize: 13.5,
                        color: Color(0xFF1976D2),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const MaterialsPage()),
                  );
                },
                child: const Row(
                  children: [
                    Text(
                      '物料库',
                      style: TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                    Icon(Icons.chevron_right, size: 16, color: Colors.grey),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFEEEEEE)),
            ),
            child: Text(
              content,
              style: const TextStyle(
                fontSize: 14.5,
                color: Color(0xFF2C3E50),
                height: 1.55,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: content));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('话术已复制到剪贴板，可直接粘贴发给学生！'),
                    backgroundColor: Color(0xFF1976D2),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              icon: const Icon(Icons.copy_rounded, size: 15, color: Colors.white),
              label: const Text('复制推荐话术',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1976D2),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}


/// 4个操作按钮横排
class _ActionButtons extends StatelessWidget {
  final Clue clue;
  const _ActionButtons({required this.clue});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _ActionBtn(
            icon: Icons.add_comment_outlined,
            label: '新增回访',
            color: const Color(0xFF1976D2),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => AddVisitPage(clueId: clue.id)),
            ),
          ),
          _ActionBtn(
            icon: Icons.photo_library_outlined,
            label: '上传聊天截图',
            color: const Color(0xFF00897B),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => UploadChatPage(clueId: clue.id)),
            ),
          ),
          _ActionBtn(
            icon: Icons.auto_awesome,
            label: 'AI分析',
            color: const Color(0xFF7B1FA2),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => AiAnalysisPage(clue: clue)),
            ),
          ),
          _ActionBtn(
            icon: Icons.how_to_reg_outlined,
            label: '转为报名',
            color: const Color(0xFFE65100),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => EnrollPage(clue: clue)),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionBtn({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 时间轴区域
class _TimelineSection extends StatelessWidget {
  final Clue clue;
  const _TimelineSection({required this.clue});

  @override
  Widget build(BuildContext context) {
    final logs = clue.visitLogs.reversed.toList();
    final totalCount = logs.length + 1;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.show_chart, color: Color(0xFF1976D2), size: 20),
              const SizedBox(width: 6),
              const Text(
                '时间轴',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                ),
              ),
              const Spacer(),
              Text(
                '共 $totalCount 条记录',
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 线索创建节点（始终在顶部）
          _TimelineItem(
            date: DateFormat('yyyy.MM.dd').format(clue.createTime),
            title: '线索创建',
            subtitle: '来源：${clue.source.isEmpty ? "未知" : clue.source}',
            color: const Color(0xFF1976D2),
            dotFilled: true,
            isLast: logs.isEmpty,
          ),

          // 回访记录
          ...logs.asMap().entries.map((e) {
            final log = e.value;
            final isLast = e.key == logs.length - 1;
            return _TimelineItem(
              date: DateFormat('yyyy.MM.dd HH:mm').format(log.createTime),
              title: log.visitResult.label,
              subtitle: log.visitContent,
              color: _getResultColor(log.visitResult),
              dotFilled: false,
              isLast: isLast,
            );
          }),

          if (clue.visitLogs.isEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 28, bottom: 12),
              child: Text(
                '暂无回访记录，点击上方新增回访',
                style: TextStyle(color: Colors.grey[400], fontSize: 13),
              ),
            ),
        ],
      ),
    );
  }

  Color _getResultColor(VisitResult result) {
    switch (result) {
      case VisitResult.intentUp:
      case VisitResult.trialBooked:
        return const Color(0xFF2E7D32);
      case VisitResult.unreachable:
      case VisitResult.noIntent:
        return const Color(0xFFC62828);
      case VisitResult.followUp:
        return const Color(0xFFEF6C00);
      default:
        return const Color(0xFF1976D2);
    }
  }
}

/// 时间轴单条记录（左侧圆点连线，右侧内容卡片）
class _TimelineItem extends StatelessWidget {
  final String date;
  final String title;
  final String subtitle;
  final Color color;
  final bool dotFilled;
  final bool isLast;

  const _TimelineItem({
    required this.date,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.dotFilled,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 左侧：圆点 + 竖线
          SizedBox(
            width: 28,
            child: Column(
              children: [
                // 圆点
                Container(
                  width: 14,
                  height: 14,
                  margin: const EdgeInsets.only(top: 2),
                  decoration: BoxDecoration(
                    color: dotFilled ? color : Colors.white,
                    border: Border.all(color: color, width: 2.5),
                    shape: BoxShape.circle,
                  ),
                ),
                // 竖线
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: Colors.grey[200],
                    ),
                  ),
              ],
            ),
          ),
          // 右侧：内容卡片
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 8 : 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 日期行
                  Text(
                    date,
                    style: TextStyle(fontSize: 12.5, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 5),
                  // 内容卡片
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: color.withValues(alpha: 0.22)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                        if (subtitle.isNotEmpty) ...[
                          const SizedBox(height: 5),
                          Text(
                            subtitle,
                            style: const TextStyle(
                              fontSize: 13.5,
                              color: Color(0xFF37474F),
                              height: 1.55,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 微信沟通截图档案卡片组件
class _ChatRecordsSection extends StatelessWidget {
  final Clue clue;
  const _ChatRecordsSection({required this.clue});

  void _showFullImage(BuildContext context, ChatRecord record) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 12, 8),
                child: Row(
                  children: [
                    const Icon(Icons.chat_bubble_outline,
                        color: Color(0xFF00897B), size: 18),
                    const SizedBox(width: 6),
                    Text(
                      '聊天记录 (${DateFormat('yyyy.MM.dd HH:mm').format(record.createTime)})',
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 400),
                  color: Colors.black12,
                  child: record.imageData != null && record.imageData!.isNotEmpty
                      ? InteractiveViewer(
                          child: Image.memory(
                            base64Decode(record.imageData!),
                            fit: BoxFit.contain,
                          ),
                        )
                      : const Center(child: Text('无图片数据')),
                ),
              ),
              if (record.ocrText.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F8E9),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFDCEDC8)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('提炼要点 / 沟通备注：',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF33691E))),
                        const SizedBox(height: 4),
                        Text(record.ocrText,
                            style: const TextStyle(
                                fontSize: 13, color: Color(0xFF1B5E20))),
                      ],
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00897B),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('关 闭'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.photo_library_outlined,
                  color: Color(0xFF00897B), size: 18),
              const SizedBox(width: 6),
              const Text(
                '沟通截图档案',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '(${clue.chatRecords.length}张)',
                style: const TextStyle(color: Colors.grey, fontSize: 12.5),
              ),
              const Spacer(),
              InkWell(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => UploadChatPage(clueId: clue.id),
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.add, size: 15, color: Color(0xFF00897B)),
                    Text(
                      '加截图',
                      style: TextStyle(
                          fontSize: 12.5,
                          color: Color(0xFF00897B),
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 130,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: clue.chatRecords.length,
              itemBuilder: (context, idx) {
                final rec = clue.chatRecords[idx];
                final hasImage =
                    rec.imageData != null && rec.imageData!.isNotEmpty;

                return GestureDetector(
                  onTap: () => _showFullImage(context, rec),
                  child: Container(
                    width: 110,
                    margin: const EdgeInsets.only(right: 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey[200]!),
                      color: Colors.grey[50],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(9)),
                            child: SizedBox(
                              width: double.infinity,
                              child: hasImage
                                  ? Image.memory(
                                      base64Decode(rec.imageData!),
                                      fit: BoxFit.cover,
                                    )
                                  : Center(
                                      child: Icon(Icons.image,
                                          color: Colors.grey[400]),
                                    ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(5),
                          child: Text(
                            rec.ocrText.isNotEmpty ? rec.ocrText : '点击放大查看',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 10.5,
                              color: rec.ocrText.isNotEmpty
                                  ? const Color(0xFF2E7D32)
                                  : Colors.grey[600],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
