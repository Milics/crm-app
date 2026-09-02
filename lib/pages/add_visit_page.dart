import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/clue.dart';

/// 新增回访独立页（按原型图：沟通方式/回访结果单选/顾虑标签/天数选择）
class AddVisitPage extends StatefulWidget {
  final String clueId;
  const AddVisitPage({super.key, required this.clueId});

  @override
  State<AddVisitPage> createState() => _AddVisitPageState();
}

class _AddVisitPageState extends State<AddVisitPage> {
  ContactMethod _contactMethod = ContactMethod.wechat;
  VisitResult _visitResult = VisitResult.normal;
  final _contentCtrl = TextEditingController();
  final Set<String> _selectedConcerns = {};
  // 下次回访时间配置
  bool _enableNextVisit = true;
  DateTime _nextVisitDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _nextVisitTime = const TimeOfDay(hour: 14, minute: 30);

  final List<String> _concernOptions = ['学费', '基础', '住宿', '时间', '距离', '效果'];

  @override
  void dispose() {
    _contentCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (_contentCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请填写沟通内容摘要'), backgroundColor: Colors.red),
      );
      return;
    }

    final provider = context.read<AppProvider>();
    DateTime? finalNextVisitTime;
    if (_enableNextVisit) {
      finalNextVisitTime = DateTime(
        _nextVisitDate.year,
        _nextVisitDate.month,
        _nextVisitDate.day,
        _nextVisitTime.hour,
        _nextVisitTime.minute,
      );
    }

    final log = VisitLog(
      id: provider.generateId(),
      clueId: widget.clueId,
      contactMethod: _contactMethod,
      visitResult: _visitResult,
      visitContent: _contentCtrl.text.trim(),
      concerns: _selectedConcerns.toList(),
      nextVisitTime: finalNextVisitTime,
      createTime: DateTime.now(),
    );

    provider.addVisitLog(widget.clueId, log);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('回访记录已保存'), backgroundColor: Colors.green),
    );
  }

  Future<void> _pickCustomDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _nextVisitDate,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _enableNextVisit = true;
        _nextVisitDate = picked;
      });
    }
  }

  Future<void> _pickCustomTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _nextVisitTime,
    );
    if (picked != null) {
      setState(() {
        _enableNextVisit = true;
        _nextVisitTime = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isToday = _nextVisitDate.year == now.year &&
        _nextVisitDate.month == now.month &&
        _nextVisitDate.day == now.day;
    final isTomorrow = _nextVisitDate.year == now.year &&
        _nextVisitDate.month == now.month &&
        _nextVisitDate.day == now.day + 1;

    final dateLabel = isToday
        ? '今天'
        : isTomorrow
            ? '明天'
            : '${_nextVisitDate.month}月${_nextVisitDate.day}日';
    final timeLabel =
        '${_nextVisitTime.hour.toString().padLeft(2, '0')}:${_nextVisitTime.minute.toString().padLeft(2, '0')}';

    return Scaffold(
      appBar: AppBar(title: const Text('新增回访')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 回访时间
            _SectionCard(
              title: '本次回访信息',
              child: Column(
                children: [
                  _InfoRow(
                    label: '沟通时间',
                    child: Text(
                      _formatNow(),
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _InfoRow(
                    label: '沟通方式',
                    child: DropdownButton<ContactMethod>(
                      value: _contactMethod,
                      underline: const SizedBox(),
                      isDense: true,
                      items: ContactMethod.values
                          .map((m) => DropdownMenuItem(
                              value: m, child: Text(m.label)))
                          .toList(),
                      onChanged: (v) =>
                          setState(() => _contactMethod = v!),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // 回访结果单选
            _SectionCard(
              title: '回访结果',
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                children: VisitResult.values.map((r) {
                  final isSelected = _visitResult == r;
                  return GestureDetector(
                    onTap: () => setState(() => _visitResult = r),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF1976D2)
                            : Colors.grey[100],
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF1976D2)
                              : Colors.grey[300]!,
                        ),
                      ),
                      child: Text(
                        r.label,
                        style: TextStyle(
                          fontSize: 13,
                          color:
                              isSelected ? Colors.white : Colors.grey[700],
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 14),

            // 沟通内容摘要
            _SectionCard(
              title: '沟通内容摘要',
              child: TextField(
                controller: _contentCtrl,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: '请描述沟通情况、学生反馈等...',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
            const SizedBox(height: 14),

            // 学生核心顾虑标签
            _SectionCard(
              title: '学生核心顾虑',
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _concernOptions.map((c) {
                  final isSelected = _selectedConcerns.contains(c);
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          _selectedConcerns.remove(c);
                        } else {
                          _selectedConcerns.add(c);
                        }
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF1976D2).withValues(alpha: 0.1)
                            : Colors.grey[100],
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF1976D2)
                              : Colors.grey[300]!,
                        ),
                      ),
                      child: Text(
                        c,
                        style: TextStyle(
                          fontSize: 13,
                          color: isSelected
                              ? const Color(0xFF1976D2)
                              : Colors.grey[600],
                        fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 14),

            // 下次回访时间设置（日期 + 具体几点）
            _SectionCard(
              title: '下次回访提醒设置',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. 快捷日期选择
                  const Text('回访日期', style: TextStyle(fontSize: 13, color: Colors.grey)),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _QuickDateChip(
                          label: '不设提醒',
                          selected: !_enableNextVisit,
                          onTap: () => setState(() => _enableNextVisit = false),
                        ),
                        const SizedBox(width: 8),
                        _QuickDateChip(
                          label: '今天',
                          selected: _enableNextVisit && isToday,
                          onTap: () => setState(() {
                            _enableNextVisit = true;
                            _nextVisitDate = now;
                          }),
                        ),
                        const SizedBox(width: 8),
                        _QuickDateChip(
                          label: '明天',
                          selected: _enableNextVisit && isTomorrow,
                          onTap: () => setState(() {
                            _enableNextVisit = true;
                            _nextVisitDate = now.add(const Duration(days: 1));
                          }),
                        ),
                        const SizedBox(width: 8),
                        _QuickDateChip(
                          label: '3天后',
                          selected: _enableNextVisit &&
                              _nextVisitDate.day == now.add(const Duration(days: 3)).day,
                          onTap: () => setState(() {
                            _enableNextVisit = true;
                            _nextVisitDate = now.add(const Duration(days: 3));
                          }),
                        ),
                        const SizedBox(width: 8),
                        _QuickDateChip(
                          label: '7天后',
                          selected: _enableNextVisit &&
                              _nextVisitDate.day == now.add(const Duration(days: 7)).day,
                          onTap: () => setState(() {
                            _enableNextVisit = true;
                            _nextVisitDate = now.add(const Duration(days: 7));
                          }),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton.icon(
                          onPressed: _pickCustomDate,
                          icon: const Icon(Icons.calendar_month, size: 16),
                          label: const Text('自选日期', style: TextStyle(fontSize: 12)),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                      ],
                    ),
                  ),

                  if (_enableNextVisit) ...[
                    const SizedBox(height: 16),
                    // 2. 快捷时段与具体时间选择
                    const Text('回访具体时间点', style: TextStyle(fontSize: 13, color: Colors.grey)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _QuickTimeChip(
                          label: '上午 10:00',
                          selected: _nextVisitTime.hour == 10 && _nextVisitTime.minute == 0,
                          onTap: () => setState(() =>
                              _nextVisitTime = const TimeOfDay(hour: 10, minute: 0)),
                        ),
                        _QuickTimeChip(
                          label: '下午 14:30',
                          selected: _nextVisitTime.hour == 14 && _nextVisitTime.minute == 30,
                          onTap: () => setState(() =>
                              _nextVisitTime = const TimeOfDay(hour: 14, minute: 30)),
                        ),
                        _QuickTimeChip(
                          label: '傍晚 17:30',
                          selected: _nextVisitTime.hour == 17 && _nextVisitTime.minute == 30,
                          onTap: () => setState(() =>
                              _nextVisitTime = const TimeOfDay(hour: 17, minute: 30)),
                        ),
                        _QuickTimeChip(
                          label: '晚上 19:30',
                          selected: _nextVisitTime.hour == 19 && _nextVisitTime.minute == 30,
                          onTap: () => setState(() =>
                              _nextVisitTime = const TimeOfDay(hour: 19, minute: 30)),
                        ),
                        OutlinedButton.icon(
                          onPressed: _pickCustomTime,
                          icon: const Icon(Icons.access_time, size: 16),
                          label: Text(
                            '自定义 ($timeLabel)',
                            style: const TextStyle(fontSize: 12),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),
                    // 回显区域
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF8E1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFFFE082)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.notifications_active, size: 18, color: Colors.orange),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '⏰ 下次回访：${_nextVisitDate.year}-${_nextVisitDate.month.toString().padLeft(2, '0')}-${_nextVisitDate.day.toString().padLeft(2, '0')} ($dateLabel) $timeLabel',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFFE65100),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    const SizedBox(height: 10),
                    const Text(
                      '已选择不设置下次回访时间',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 保存按钮
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16)),
                child: const Text('保存回访记录', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatNow() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} '
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
  }
}

class _QuickDateChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _QuickDateChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF1976D2) : Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? const Color(0xFF1976D2) : Colors.grey[300]!,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: selected ? Colors.white : Colors.grey[700],
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _QuickTimeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _QuickTimeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF1976D2).withValues(alpha: 0.12)
              : Colors.grey[100],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? const Color(0xFF1976D2) : Colors.grey[300]!,
            width: selected ? 1.5 : 1.0,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: selected ? const Color(0xFF1976D2) : Colors.grey[700],
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title,
            style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Color(0xFF333333)),
          ),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2))
            ],
          ),
          child: child,
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final Widget child;
  const _InfoRow({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 70,
          child: Text(label,
              style: const TextStyle(color: Colors.grey, fontSize: 13)),
        ),
        Expanded(child: child),
        const Icon(Icons.keyboard_arrow_down, color: Colors.grey, size: 18),
      ],
    );
  }
}

