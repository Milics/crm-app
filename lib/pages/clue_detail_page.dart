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
import '../services/launcher_service.dart';
import '../services/smart_script_engine.dart';

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

        return PopScope(
          canPop: true,
          child: Scaffold(
            backgroundColor: const Color(0xFFF5F7FA),
          appBar: AppBar(
            title: Text(clue.status == ClueStatus.enrolled ? '报名详情' : '线索详情'),
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
        ),
      );
    },
    );
  }
}

/// 顶部信息卡片（支持折叠收起，默认仅保留就读学校与年级届别，极致压缩卡片高度）
class _HeaderCard extends StatefulWidget {
  final Clue clue;
  const _HeaderCard({required this.clue});

  @override
  State<_HeaderCard> createState() => _HeaderCardState();
}

class _HeaderCardState extends State<_HeaderCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final clue = widget.clue;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(16, 14, 16, _expanded ? 16 : 10),
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
                radius: 24,
                backgroundColor: Colors.white.withValues(alpha: 0.25),
                child: Text(
                  clue.wxNick.isNotEmpty ? clue.wxNick[0] : '?',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            clue.wxNick,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 19,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (clue.wxNick.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          InkWell(
                            onTap: () {
                              Clipboard.setData(
                                  ClipboardData(text: clue.wxNick));
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('已复制昵称: ${clue.wxNick}'),
                                  duration: const Duration(seconds: 2),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(6),
                            child: Padding(
                              padding: const EdgeInsets.all(4.0),
                              child: Icon(
                                Icons.copy_rounded,
                                size: 16,
                                color: Colors.white.withValues(alpha: 0.85),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      clue.status.label,
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 12.5),
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
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // 核心常驻行：就读学校 + 年级届别
          Row(
            children: [
              Expanded(
                child: _InfoChip(
                  label: '就读学校',
                  value: clue.school.isEmpty ? '未填写' : clue.school,
                  enableCopy: false,
                ),
              ),
              Container(width: 1, height: 30, color: Colors.white24),
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

          // 折叠内容区域（微信号/手机号/科目/班型/来源/顾问/标签）——纯垂直向下延展动画，彻底避免左右水平拉伸/左侧划入
          ClipRect(
            child: AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeInOutCubic,
              alignment: Alignment.topCenter,
              child: SizedBox(
                width: double.infinity,
                child: _expanded
                    ? Column(
                        children: [
                          const SizedBox(height: 12),
                          // 微信号 + 手机号
                          Row(
                            children: [
                              Expanded(
                                child: _InfoChip(
                                  label: '微信号',
                                  value: clue.wxId.isEmpty ? '未填写' : clue.wxId,
                                  actionIcon: Icons.open_in_new,
                                  customTap: clue.wxId.isNotEmpty
                                      ? () => LauncherService.copyAndOpenWechat(
                                          context, clue.wxId)
                                      : null,
                                ),
                              ),
                              Container(
                                  width: 1, height: 30, color: Colors.white24),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(left: 12),
                                  child: _InfoChip(
                                    label: '手机号',
                                    value:
                                        clue.phone.isEmpty ? '未填写' : clue.phone,
                                    actionIcon: Icons.phone_in_talk,
                                    customTap: clue.phone.isNotEmpty
                                        ? () => _showPhoneActionSheet(
                                            context, clue.phone)
                                        : null,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // 报考科目 + 意向班型
                          Row(
                            children: [
                              Expanded(
                                child: _InfoChip(
                                  label: '报考科目',
                                  value: clue.subject.isEmpty
                                      ? '未填写'
                                      : clue.subject,
                                  enableCopy: false,
                                ),
                              ),
                              Container(
                                  width: 1, height: 30, color: Colors.white24),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(left: 12),
                                  child: _InfoChip(
                                    label: clue.status == ClueStatus.enrolled
                                        ? '已报班型'
                                        : '意向班型',
                                    value: clue.classType.isEmpty
                                        ? '未填写'
                                        : (clue.enrollAmount != null
                                            ? '${clue.classType} (¥${clue.enrollAmount! % 1 == 0 ? clue.enrollAmount!.toInt() : clue.enrollAmount})'
                                            : clue.classType),
                                    enableCopy: false,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // 线索来源 + 归属顾问
                          Row(
                            children: [
                              Expanded(
                                child: _InfoChip(
                                  label: '线索来源',
                                  value: clue.source.isEmpty
                                      ? '未填写'
                                      : clue.source,
                                  enableCopy: false,
                                ),
                              ),
                              Container(
                                  width: 1, height: 30, color: Colors.white24),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(left: 12),
                                  child: _InfoChip(
                                    label: '归属顾问',
                                    value: clue.ownerName.isEmpty
                                        ? '待分配'
                                        : clue.ownerName,
                                    actionIcon: context
                                            .read<AppProvider>()
                                            .canViewAllClues
                                        ? Icons.swap_horiz
                                        : null,
                                    customTap: context
                                            .read<AppProvider>()
                                            .canViewAllClues
                                        ? () =>
                                            _showReassignDialog(context, clue)
                                        : null,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (clue.tags.isNotEmpty) ...[
                            const SizedBox(height: 12),
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
                                      color:
                                          Colors.white.withValues(alpha: 0.18),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      t,
                                      style: const TextStyle(
                                          color: Colors.white, fontSize: 11.5),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ],
                        ],
                      )
                    : const SizedBox.shrink(),
              ),
            ),
          ),

          const SizedBox(height: 6),

          // 展开/收起切换按钮
          Center(
            child: InkWell(
              onTap: () => setState(() => _expanded = !_expanded),
              borderRadius: BorderRadius.circular(14),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _expanded ? '收起资料' : '展开完整档案 (微信/电话/班型等)',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 2),
                    Icon(
                      _expanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: Colors.white.withValues(alpha: 0.8),
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showReassignDialog(BuildContext context, Clue clue) {
    final provider = context.read<AppProvider>();
    final advisors = provider.users.where((u) => u.isActive).toList();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('指派/转派归属顾问'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: advisors.length,
            itemBuilder: (c, idx) {
              final user = advisors[idx];
              final isCurrent = clue.ownerName == user.name;
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: isCurrent ? Colors.blue : Colors.grey[200],
                  child: Text(user.name.isNotEmpty ? user.name[0] : '?',
                      style: TextStyle(
                          color: isCurrent ? Colors.white : Colors.black87)),
                ),
                title: Text(user.name,
                    style: TextStyle(
                        fontWeight:
                            isCurrent ? FontWeight.bold : FontWeight.normal)),
                subtitle: Text('${user.role.label} · ${user.phone}'),
                trailing: isCurrent
                    ? const Icon(Icons.check, color: Colors.blue)
                    : null,
                onTap: () {
                  provider.reassignClueOwner(clue.id, user.name);
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('已将该线索指派给「${user.name}」老师')),
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
        ],
      ),
    );
  }

  void _showPhoneActionSheet(BuildContext context, String phone) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                '联系学员: $phone',
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFE8F5E9),
                child: Icon(Icons.phone, color: Color(0xFF2E7D32)),
              ),
              title: const Text('立即拨打电话',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text('调用系统拨号盘直拨'),
              onTap: () {
                Navigator.pop(ctx);
                LauncherService.makePhoneCall(context, phone);
              },
            ),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFE3F2FD),
                child: Icon(Icons.copy, color: Color(0xFF1976D2)),
              ),
              title: const Text('仅复制手机号'),
              onTap: () {
                Navigator.pop(ctx);
                Clipboard.setData(ClipboardData(text: phone));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('已复制手机号: $phone')),
                );
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final String value;
  final bool enableCopy;
  final VoidCallback? customTap;
  final IconData? actionIcon;

  const _InfoChip({
    required this.label,
    required this.value,
    this.enableCopy = true,
    this.customTap,
    this.actionIcon,
  });

  @override
  Widget build(BuildContext context) {
    final canClick = customTap != null ||
        (enableCopy && value.isNotEmpty && value != '未填写');

    return InkWell(
      onTap: canClick
          ? () {
              if (customTap != null) {
                customTap!();
              } else {
                Clipboard.setData(ClipboardData(text: value));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('已复制$label: $value'),
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            }
          : null,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
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
                if (canClick) ...[
                  const SizedBox(width: 4),
                  Icon(
                    actionIcon ?? Icons.copy_rounded,
                    size: 14,
                    color: Colors.white70,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 智能口头化实战沟通话术卡片组件 (支持破冰开口/打消顾虑/促成逼单场景胶囊切换)
class _RecommendScriptCard extends StatefulWidget {
  final Clue clue;
  const _RecommendScriptCard({required this.clue});

  @override
  State<_RecommendScriptCard> createState() => _RecommendScriptCardState();
}

class _RecommendScriptCardState extends State<_RecommendScriptCard> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final scenarios = SmartScriptEngine.generate(widget.clue);
    final currentScenario = (scenarios.isNotEmpty && _selectedIndex < scenarios.length)
        ? scenarios[_selectedIndex]
        : scenarios.first;
    final bool hasAi = widget.clue.aiAnalysisReport != null &&
        widget.clue.aiAnalysisReport!.trim().isNotEmpty;

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
          // 头部：场景标签 + AI 定制标志 + 物料库入口
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF1976D2).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      hasAi ? Icons.psychology_outlined : Icons.auto_awesome,
                      size: 15,
                      color: const Color(0xFF1976D2),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      hasAi ? 'AI 深度定制话术' : '专属推荐沟通话术',
                      style: const TextStyle(
                        fontSize: 13,
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

          // 场景胶囊切换
          if (scenarios.length > 1) ...[
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(
                  scenarios.length,
                  (idx) {
                    final sc = scenarios[idx];
                    final isSel = _selectedIndex == idx;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(sc.label),
                        selected: isSel,
                        onSelected: (_) {
                          setState(() {
                            _selectedIndex = idx;
                          });
                        },
                        selectedColor: const Color(0xFFE3F2FD),
                        backgroundColor: const Color(0xFFF5F5F5),
                        labelStyle: TextStyle(
                          fontSize: 12,
                          fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                          color: isSel ? const Color(0xFF1976D2) : Colors.grey.shade700,
                        ),
                        side: BorderSide(
                          color: isSel ? const Color(0xFF1976D2) : const Color(0xFFE0E0E0),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            if (currentScenario.tip.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F7FF),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFD0E3F7)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.lightbulb_outline_rounded,
                        size: 14, color: Color(0xFF1976D2)),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        currentScenario.tip,
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: Color(0xFF0D47A1),
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 10),
          ],

          // 话术内容框
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFEEEEEE)),
            ),
            child: Text(
              currentScenario.content,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF2C3E50),
                height: 1.55,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // 底部操作区
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (!hasAi)
                InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AiAnalysisPage(clue: widget.clue),
                      ),
                    );
                  },
                  child: const Row(
                    children: [
                      Icon(Icons.auto_awesome, size: 13, color: Color(0xFF7B1FA2)),
                      SizedBox(width: 4),
                      Text(
                        '获取 AI 深度策略 >',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF7B1FA2),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                )
              else
                const SizedBox.shrink(),
              ElevatedButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: currentScenario.content));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          '已复制【${currentScenario.shortLabel}】话术到剪贴板，可直接粘贴发给学生！'),
                      backgroundColor: const Color(0xFF1976D2),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
                icon: const Icon(Icons.copy_rounded, size: 14, color: Colors.white),
                label: Text(
                  '复制【${currentScenario.shortLabel}】话术',
                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1976D2),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ],
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
            icon: clue.status == ClueStatus.enrolled
                ? Icons.assignment_turned_in_outlined
                : Icons.how_to_reg_outlined,
            label: clue.status == ClueStatus.enrolled ? '报名详情' : '转为报名',
            color: clue.status == ClueStatus.enrolled
                ? const Color(0xFF2E7D32)
                : const Color(0xFFE65100),
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
    // 除了顶部的“线索创建”固定置顶外，其余回访记录始终按时间倒序排列（最新的记录在最上方）
    // 🛡️ 防御性语义去重：同一内容且时间相差在60秒以内的重复记录仅保留一条
    final rawLogs = List<VisitLog>.from(clue.visitLogs)
      ..sort((a, b) => b.createTime.compareTo(a.createTime));
    final logs = <VisitLog>[];
    for (final l in rawLogs) {
      final isDup = logs.any((ex) {
        final sameContent = ex.visitContent.trim() == l.visitContent.trim();
        final timeDiff = ex.createTime.difference(l.createTime).inSeconds.abs();
        return sameContent && timeDiff <= 60;
      });
      if (!isDup) {
        logs.add(l);
      }
    }
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
            subtitle:
                '来源：${clue.source.isEmpty ? "未知" : clue.source} · 归属顾问：${clue.ownerName.isEmpty ? "待分配" : clue.ownerName}',
            color: const Color(0xFF1976D2),
            dotFilled: true,
            isLast: logs.isEmpty,
          ),

          // 回访记录
          ...logs.asMap().entries.map((e) {
            final log = e.value;
            final isLast = e.key == logs.length - 1;
            final isAiLog = (log.aiReport != null && log.aiReport!.isNotEmpty) ||
                log.visitContent.contains('【AI') ||
                log.visitContent.contains('AI大模型') ||
                log.visitContent.contains('AI智能跟进策略');
            return _TimelineItem(
              date: DateFormat('yyyy.MM.dd HH:mm').format(log.createTime),
              title: log.visitResult.label,
              subtitle: log.visitContent,
              color: isAiLog ? const Color(0xFF7B1FA2) : _getResultColor(log.visitResult),
              dotFilled: false,
              isLast: isLast,
              isAiLog: isAiLog,
              onTap: isAiLog
                  ? () {
                      final report = (log.aiReport != null && log.aiReport!.isNotEmpty)
                          ? log.aiReport
                          : clue.aiAnalysisReport;
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AiAnalysisPage(
                            clue: clue,
                            initialReport: report,
                            reportSubtitle:
                                '${DateFormat('yyyy.MM.dd HH:mm').format(log.createTime)} 诊断存档',
                          ),
                        ),
                      );
                    }
                  : null,
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
  final bool isAiLog;
  final VoidCallback? onTap;

  const _TimelineItem({
    required this.date,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.dotFilled,
    required this.isLast,
    this.isAiLog = false,
    this.onTap,
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
                  Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    child: InkWell(
                      onTap: onTap,
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: isAiLog
                              ? const Color(0xFF7B1FA2).withValues(alpha: 0.08)
                              : color.withValues(alpha: 0.07),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isAiLog
                                ? const Color(0xFF7B1FA2).withValues(alpha: 0.35)
                                : color.withValues(alpha: 0.22),
                            width: isAiLog ? 1.2 : 1.0,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  title,
                                  style: TextStyle(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.bold,
                                    color: color,
                                  ),
                                ),
                                if (isAiLog) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF7B1FA2).withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.auto_awesome, size: 11, color: Color(0xFF7B1FA2)),
                                        SizedBox(width: 3),
                                        Text(
                                          'AI诊断',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF7B1FA2),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
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
                            if (isAiLog) ...[
                              const SizedBox(height: 8),
                              const Row(
                                children: [
                                  Text(
                                    '点击查看完整AI分析报告',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF7B1FA2),
                                    ),
                                  ),
                                  SizedBox(width: 4),
                                  Icon(Icons.arrow_forward_ios_rounded,
                                      size: 11, color: Color(0xFF7B1FA2)),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
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
                            _safeBase64Decode(record.imageData!),
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
                                      _safeBase64Decode(rec.imageData!),
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

/// 安全解码 Base64 字符串（自动兼容纯 Base64 或带有 dataURI 前缀的格式）
Uint8List _safeBase64Decode(String raw) {
  var b64 = raw.trim();
  if (b64.contains(',')) {
    b64 = b64.split(',').last.trim();
  }
  return base64Decode(b64);
}
