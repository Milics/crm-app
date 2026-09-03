import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/clue.dart';
import '../pages/add_clue_page.dart';
import 'batch_import_dialog.dart';

/// 新建线索弹窗
class AddClueDialog extends StatefulWidget {
  const AddClueDialog({super.key});

  @override
  State<AddClueDialog> createState() => _AddClueDialogState();
}

class _AddClueDialogState extends State<AddClueDialog> {
  final _wxNickCtrl = TextEditingController();
  final _wxIdCtrl = TextEditingController();
  String _subject = '';
  String _source = '';

  // 下次回访时间（默认明天 10:00）
  bool _enableNextVisit = true;
  DateTime _nextVisitDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _nextVisitTime = const TimeOfDay(hour: 10, minute: 0);

  // 报考科目选项
  final List<String> _subjects = [
    '高等数学',
    '管理学',
    '大学语文',
    '经济学',
    '法学基础',
    '教育学心理学',
    '生理学病理解剖学',
    '中医基础',
    '动物植物遗传学',
    '美术专业综合',
    '音乐专业综合',
    '舞蹈专业综合',
    '体育专业综合',
  ];
  // 线索来源选项
  final List<String> _sources = ['抖音', '小红书', '地推', '其他'];

  @override
  void dispose() {
    _wxNickCtrl.dispose();
    _wxIdCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (_wxNickCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('微信昵称不能为空')),
      );
      return;
    }

    DateTime? nextVisitDateTime;
    if (_enableNextVisit) {
      nextVisitDateTime = DateTime(
        _nextVisitDate.year,
        _nextVisitDate.month,
        _nextVisitDate.day,
        _nextVisitTime.hour,
        _nextVisitTime.minute,
      );
    }

    final provider = context.read<AppProvider>();
    final clue = Clue(
      id: provider.generateId(),
      wxNick: _wxNickCtrl.text.trim(),
      wxId: _wxIdCtrl.text.trim(),
      subject: _subject,
      source: _source,
      nextVisitTime: nextVisitDateTime,
      createTime: DateTime.now(),
    );

    provider.addClue(clue);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('线索创建成功'),
        backgroundColor: Colors.green,
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Widget _buildChip(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color:
              isSelected ? const Color(0xFF1976D2) : const Color(0xFFF7F8FA),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF1976D2)
                : const Color(0xFFDEE2E8),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: isSelected ? Colors.white : const Color(0xFF555555),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 标题栏
            Row(
              children: [
                const Icon(Icons.person_add_outlined, color: Color(0xFF1976D2)),
                const SizedBox(width: 8),
                const Text(
                  '新建线索',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AddCluePage(initialTabIndex: 1),
                      ),
                    );
                  },
                  icon: const Icon(Icons.crop_original, size: 15),
                  label: const Text('截图导入', style: TextStyle(fontSize: 12.5)),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF1976D2),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    showDialog(
                      context: context,
                      builder: (_) => const BatchImportDialog(),
                    );
                  },
                  icon: const Icon(Icons.playlist_add_check, size: 15),
                  label: const Text('批量导入', style: TextStyle(fontSize: 12.5)),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF1976D2),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 微信昵称（必填）
            TextField(
              controller: _wxNickCtrl,
              decoration: const InputDecoration(
                labelText: '微信昵称 *',
                hintText: '请输入微信昵称',
                prefixIcon: Icon(Icons.chat_bubble_outline),
              ),
            ),
            const SizedBox(height: 14),

            // 微信号（选填）
            TextField(
              controller: _wxIdCtrl,
              decoration: const InputDecoration(
                labelText: '微信号（选填）',
                hintText: '请输入微信号',
                prefixIcon: Icon(Icons.tag),
              ),
            ),
            const SizedBox(height: 14),

            // 报考科目
            DropdownButtonFormField<String>(
              value: _subject.isEmpty ? null : _subject,
              decoration: const InputDecoration(
                labelText: '报考科目（选填）',
                prefixIcon: Icon(Icons.menu_book_outlined),
              ),
              hint: const Text('请选择报考科目'),
              items: _subjects
                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                  .toList(),
              onChanged: (v) => setState(() => _subject = v ?? ''),
            ),
            const SizedBox(height: 14),

            // 线索来源
            DropdownButtonFormField<String>(
              value: _source.isEmpty ? null : _source,
              decoration: const InputDecoration(
                labelText: '线索来源（选填）',
                prefixIcon: Icon(Icons.campaign_outlined),
              ),
              hint: const Text('请选择线索来源'),
              items: _sources
                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                  .toList(),
              onChanged: (v) => setState(() => _source = v ?? ''),
            ),
            const SizedBox(height: 16),

            // ⏰ 下次回访提醒
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F7FF),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFB3D7FF)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '⏰ 下次回访时间',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1565C0)),
                  ),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildChip('不设提醒', !_enableNextVisit, () {
                          setState(() => _enableNextVisit = false);
                        }),
                        const SizedBox(width: 6),
                        _buildChip(
                          '今天',
                          _enableNextVisit &&
                              _isSameDay(_nextVisitDate, DateTime.now()),
                          () => setState(() {
                            _enableNextVisit = true;
                            _nextVisitDate = DateTime.now();
                          }),
                        ),
                        const SizedBox(width: 6),
                        _buildChip(
                          '明天',
                          _enableNextVisit &&
                              _isSameDay(_nextVisitDate,
                                  DateTime.now().add(const Duration(days: 1))),
                          () => setState(() {
                            _enableNextVisit = true;
                            _nextVisitDate =
                                DateTime.now().add(const Duration(days: 1));
                          }),
                        ),
                        const SizedBox(width: 6),
                        _buildChip(
                          '3天后',
                          _enableNextVisit &&
                              _isSameDay(_nextVisitDate,
                                  DateTime.now().add(const Duration(days: 3))),
                          () => setState(() {
                            _enableNextVisit = true;
                            _nextVisitDate =
                                DateTime.now().add(const Duration(days: 3));
                          }),
                        ),
                        const SizedBox(width: 6),
                        _buildChip(
                          '自定义',
                          _enableNextVisit &&
                              !_isSameDay(_nextVisitDate, DateTime.now()) &&
                              !_isSameDay(
                                  _nextVisitDate,
                                  DateTime.now()
                                      .add(const Duration(days: 1))) &&
                              !_isSameDay(
                                  _nextVisitDate,
                                  DateTime.now()
                                      .add(const Duration(days: 3))),
                          () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _nextVisitDate,
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now()
                                  .add(const Duration(days: 365)),
                            );
                            if (picked != null) {
                              setState(() {
                                _enableNextVisit = true;
                                _nextVisitDate = picked;
                              });
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  if (_enableNextVisit) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.access_time_rounded,
                            size: 14, color: Colors.blue[700]),
                        const SizedBox(width: 4),
                        Text(
                          '${_nextVisitDate.month}月${_nextVisitDate.day}日 ${_nextVisitTime.format(context)}',
                          style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue[700],
                              fontWeight: FontWeight.bold),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: () async {
                            final picked = await showTimePicker(
                              context: context,
                              initialTime: _nextVisitTime,
                            );
                            if (picked != null) {
                              setState(() => _nextVisitTime = picked);
                            }
                          },
                          child: Text(
                            '修改时间',
                            style:
                                TextStyle(fontSize: 11, color: Colors.blue[600]),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 操作按钮
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('取消'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _save,
                    child: const Text('保存线索'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
