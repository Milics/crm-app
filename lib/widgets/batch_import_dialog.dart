import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/clue.dart';
import '../providers/app_provider.dart';

/// 批量导入线索弹窗（支持 Excel/表格复制粘贴多行数据智能解析与查重）
class BatchImportDialog extends StatefulWidget {
  const BatchImportDialog({super.key});

  @override
  State<BatchImportDialog> createState() => _BatchImportDialogState();
}

class _BatchImportDialogState extends State<BatchImportDialog> {
  final TextEditingController _textCtrl = TextEditingController();
  List<_ParsedItem> _parsedList = [];
  bool _skipDuplicates = true;
  bool _isImporting = false;

  final String _sampleText =
      '张小萌\t13811223344\t计算机科学与技术\t南昌职业大学\t地推扫码\n'
      '李建国\t13988776655\t学前教育\t九江职业大学\t小红书投放\n'
      '王雅婷\t15012345678\t电子商务\t江西财经职业学院\t转介绍';

  @override
  void dispose() {
    _textCtrl.dispose();
    super.dispose();
  }

  void _parseText() {
    final raw = _textCtrl.text.trim();
    if (raw.isEmpty) {
      setState(() => _parsedList = []);
      return;
    }

    final provider = context.read<AppProvider>();
    final existingPhones = provider.clues
        .map((c) => c.phone.trim())
        .where((p) => p.isNotEmpty)
        .toSet();

    final lines = raw.split(RegExp(r'\r?\n'));
    final results = <_ParsedItem>[];

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;

      // 拆分字段（支持 Tab、逗号、分号、或连续两个以上空格）
      final tokens = trimmed
          .split(RegExp(r'[\t,;]+|\s{2,}'))
          .map((t) => t.trim())
          .where((t) => t.isNotEmpty)
          .toList();

      if (tokens.isEmpty) continue;

      String name = '';
      String phone = '';
      String subject = '专升本';
      String school = '';
      String source = '批量导入';

      // 正则识别 11 位手机号
      final phoneRegex = RegExp(r'1[3-9]\d{9}');
      for (final t in tokens) {
        if (phone.isEmpty && phoneRegex.hasMatch(t)) {
          phone = phoneRegex.firstMatch(t)!.group(0)!;
        } else if (school.isEmpty &&
            (t.contains('大学') ||
                t.contains('学院') ||
                t.contains('校区') ||
                t.contains('职业') ||
                t.contains('专科'))) {
          school = t;
        } else if (name.isEmpty) {
          name = t;
        } else if (subject == '专升本' &&
            (t.contains('学') ||
                t.contains('语') ||
                t.contains('法') ||
                t.contains('计') ||
                t.contains('医') ||
                t.contains('教育') ||
                t.contains('经') ||
                t.contains('管') ||
                t.contains('艺') ||
                t.contains('工'))) {
          subject = t;
        } else {
          source = t;
        }
      }

      if (name.isEmpty && tokens.isNotEmpty) {
        name = tokens.first;
      }

      final isDup = phone.isNotEmpty && existingPhones.contains(phone);

      results.add(
        _ParsedItem(
          name: name,
          phone: phone,
          subject: subject,
          school: school,
          source: source,
          isDuplicate: isDup,
        ),
      );
    }

    setState(() => _parsedList = results);
  }

  Future<void> _doImport() async {
    final validItems = _parsedList.where((item) {
      if (_skipDuplicates && item.isDuplicate) return false;
      return item.name.isNotEmpty || item.phone.isNotEmpty;
    }).toList();

    if (validItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('无可导入的有效线索（请检查是否全部重复或内容为空）'),
            backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isImporting = true);

    final provider = context.read<AppProvider>();
    final newClues = validItems.map((item) {
      final id = provider.generateId();
      return Clue(
        id: id,
        wxNick: item.name.isEmpty ? '学员_${item.phone.substring(item.phone.length - 4)}' : item.name,
        wxId: '',
        phone: item.phone,
        school: item.school,
        subject: item.subject,
        source: item.source.isEmpty ? '批量导入' : item.source,
        classType: '集训班',
        status: ClueStatus.following,
        intentLevel: IntentLevel.medium,
        remark: '【批量导入】就读学校：${item.school.isEmpty ? "待沟通" : item.school}',
        tags: ['批量导入'],
        createTime: DateTime.now(),
        nextVisitTime: DateTime.now().add(const Duration(days: 1)),
        ownerName: provider.currentUser,
      );
    }).toList();

    await provider.batchAddClues(newClues);

    if (!mounted) return;
    setState(() => _isImporting = false);

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('🎉 成功批量导入 ${newClues.length} 条专升本线索，已同步上云！'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dupCount = _parsedList.where((i) => i.isDuplicate).length;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 580, maxHeight: 680),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 顶栏
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1976D2).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.playlist_add_check,
                      color: Color(0xFF1976D2)),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '批量导入专升本线索',
                        style: TextStyle(
                            fontSize: 17, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '支持从 Excel / 微信名单复制多行数据一键解析',
                        style: TextStyle(fontSize: 11.5, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // 文本输入区
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FA),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                children: [
                  TextField(
                    controller: _textCtrl,
                    maxLines: 4,
                    style: const TextStyle(fontSize: 12.5),
                    decoration: const InputDecoration(
                      hintText:
                          '每行一条数据，支持格式示例：\n张小萌  13811223344  计算机  南昌职业大学  地推扫码',
                      hintStyle:
                          TextStyle(fontSize: 12, color: Colors.grey, height: 1.4),
                      contentPadding: EdgeInsets.all(12),
                      border: InputBorder.none,
                    ),
                    onChanged: (_) => _parseText(),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(10)),
                    ),
                    child: Row(
                      children: [
                        TextButton.icon(
                          onPressed: () {
                            _textCtrl.text = _sampleText;
                            _parseText();
                          },
                          icon: const Icon(Icons.flash_on, size: 14),
                          label: const Text('填入示例测试',
                              style: TextStyle(fontSize: 11.5)),
                        ),
                        const Spacer(),
                        if (_textCtrl.text.isNotEmpty)
                          TextButton(
                            onPressed: () {
                              _textCtrl.clear();
                              _parseText();
                            },
                            child: const Text('清空',
                                style:
                                    TextStyle(fontSize: 11.5, color: Colors.red)),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // 选项与统计栏
            if (_parsedList.isNotEmpty)
              Row(
                children: [
                  Text(
                    '已解析 ${_parsedList.length} 条数据',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  if (dupCount > 0) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.red[200]!),
                      ),
                      child: Text(
                        '重复 $dupCount 条',
                        style: TextStyle(fontSize: 11, color: Colors.red[800]),
                      ),
                    ),
                  ],
                  const Spacer(),
                  Checkbox(
                    value: _skipDuplicates,
                    onChanged: (v) =>
                        setState(() => _skipDuplicates = v ?? true),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  const Text('自动跳过重复号码', style: TextStyle(fontSize: 12)),
                ],
              ),

            const SizedBox(height: 6),

            // 解析预览列表
            Expanded(
              child: _parsedList.isEmpty
                  ? Center(
                      child: Text(
                        '在上方粘贴名单后，将在此实时预览智能识别结果',
                        style: TextStyle(color: Colors.grey[400], fontSize: 12.5),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _parsedList.length,
                      itemBuilder: (ctx, i) {
                        final item = _parsedList[i];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: item.isDuplicate
                                ? Colors.red[50]
                                : Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: item.isDuplicate
                                  ? Colors.red[200]!
                                  : Colors.grey[200]!,
                            ),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 14,
                                backgroundColor: item.isDuplicate
                                    ? Colors.red[100]
                                    : const Color(0xFF1976D2)
                                        .withValues(alpha: 0.1),
                                child: Text(
                                  item.name.isNotEmpty
                                      ? item.name.substring(0, 1)
                                      : '学',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: item.isDuplicate
                                        ? Colors.red
                                        : const Color(0xFF1976D2),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          item.name,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          item.phone,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: item.isDuplicate
                                                ? Colors.red
                                                : Colors.grey[700],
                                            fontWeight: item.isDuplicate
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                          ),
                                        ),
                                        if (item.isDuplicate) ...[
                                          const SizedBox(width: 6),
                                          const Text(
                                            '(库中已存在)',
                                            style: TextStyle(
                                                fontSize: 10,
                                                color: Colors.red),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${item.subject} · ${item.school.isEmpty ? "学校未知" : item.school} · 来源:${item.source}',
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey[600]),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close,
                                    size: 16, color: Colors.grey),
                                onPressed: () {
                                  setState(() => _parsedList.removeAt(i));
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),

            const SizedBox(height: 12),

            // 底部操作
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
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _parsedList.isEmpty || _isImporting
                        ? null
                        : _doImport,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1976D2),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: _isImporting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : Text(
                            '确认导入 (${_skipDuplicates ? _parsedList.where((i) => !i.isDuplicate).length : _parsedList.length}条)'),
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

class _ParsedItem {
  final String name;
  final String phone;
  final String subject;
  final String school;
  final String source;
  final bool isDuplicate;

  _ParsedItem({
    required this.name,
    required this.phone,
    required this.subject,
    required this.school,
    required this.source,
    required this.isDuplicate,
  });
}
