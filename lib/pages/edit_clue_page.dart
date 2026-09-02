import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/clue.dart';

/// 线索信息编辑页
class EditCluePage extends StatefulWidget {
  final Clue clue;
  const EditCluePage({super.key, required this.clue});

  @override
  State<EditCluePage> createState() => _EditCluePageState();
}

class _EditCluePageState extends State<EditCluePage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _wxNickCtrl;
  late TextEditingController _wxIdCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _gradeCtrl;
  late TextEditingController _schoolCtrl;
  late TextEditingController _subjectCtrl;
  late TextEditingController _classTypeCtrl;
  late TextEditingController _remarkCtrl;

  late ClueStatus _status;
  late IntentLevel _intentLevel;
  String _source = '';
  late List<String> _tags;
  final _newTagCtrl = TextEditingController();

  final List<String> _sources = ['抖音', '小红书', '地推', '转介绍', '老带新'];
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
  final List<String> _classTypes = ['全程集训班', '精英班', '基础班', '网课班', '冲刺班'];
  final List<String> _presetTags = [
    '跨专业',
    '价格敏感',
    '基础薄弱',
    '目标名校',
    '二战升本',
    '在职备考',
    '家长决策',
    '考虑竞品',
    '住宿需求',
    '已试听好评'
  ];

  @override
  void initState() {
    super.initState();
    final c = widget.clue;
    _wxNickCtrl = TextEditingController(text: c.wxNick);
    _wxIdCtrl = TextEditingController(text: c.wxId);
    _phoneCtrl = TextEditingController(text: c.phone);
    _gradeCtrl = TextEditingController(text: c.grade);
    _schoolCtrl = TextEditingController(text: c.school);
    _subjectCtrl = TextEditingController(text: c.subject);
    _classTypeCtrl = TextEditingController(text: c.classType);
    _remarkCtrl = TextEditingController(text: c.remark);
    _status = c.status;
    _intentLevel = c.intentLevel;
    _source = c.source;
    _tags = List.from(c.tags);
  }

  @override
  void dispose() {
    _wxNickCtrl.dispose();
    _wxIdCtrl.dispose();
    _phoneCtrl.dispose();
    _gradeCtrl.dispose();
    _schoolCtrl.dispose();
    _subjectCtrl.dispose();
    _classTypeCtrl.dispose();
    _remarkCtrl.dispose();
    _newTagCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    context.read<AppProvider>().updateClue(
      clueId: widget.clue.id,
      wxNick: _wxNickCtrl.text.trim(),
      wxId: _wxIdCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      grade: _gradeCtrl.text.trim(),
      school: _schoolCtrl.text.trim(),
      subject: _subjectCtrl.text.trim(),
      source: _source,
      classType: _classTypeCtrl.text.trim(),
      status: _status,
      intentLevel: _intentLevel,
      tags: _tags,
      remark: _remarkCtrl.text.trim(),
    );
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('信息已保存'), duration: Duration(seconds: 2)),
    );
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除线索'),
        content: Text('确定要删除「${widget.clue.wxNick}」的线索吗？\n删除后无法恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      context.read<AppProvider>().deleteClue(widget.clue.id);
      // 同时关闭编辑页和详情页，回到列表
      Navigator.pop(context);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('线索已删除'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('编辑线索'),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text('保存', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _Section(title: '基本信息', children: [
              _Field(
                label: '微信昵称 *',
                controller: _wxNickCtrl,
                hint: '请输入微信昵称',
                validator: (v) => (v == null || v.trim().isEmpty) ? '昵称不能为空' : null,
              ),
              _Field(
                label: '微信号',
                controller: _wxIdCtrl,
                hint: '请输入微信号',
              ),
              _Field(
                label: '手机号',
                controller: _phoneCtrl,
                hint: '请输入手机号',
                keyboardType: TextInputType.phone,
                validator: (v) {
                  if (v != null && v.trim().isNotEmpty) {
                    if (!RegExp(r'^1[3-9]\d{9}$').hasMatch(v.trim())) {
                      return '请输入正确的手机号';
                    }
                  }
                  return null;
                },
              ),
              _Field(
                label: '就读学校',
                controller: _schoolCtrl,
                hint: '例如：河南经贸职业学院',
              ),
              _Field(
                label: '年级/届别',
                controller: _gradeCtrl,
                hint: '例如：24级 / 23级 / 25级',
              ),
            ]),

            const SizedBox(height: 12),
            _Section(title: '来源', children: [
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _sources.map((s) {
                  final selected = _source == s;
                  return GestureDetector(
                    onTap: () => setState(() => _source = s),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: selected ? const Color(0xFF1976D2) : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: selected ? const Color(0xFF1976D2) : const Color(0xFFDEE2E8),
                        ),
                      ),
                      child: Text(
                        s,
                        style: TextStyle(
                          color: selected ? Colors.white : const Color(0xFF444444),
                          fontSize: 13,
                          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),
            ]),

            const SizedBox(height: 12),
            _Section(title: '意向信息', children: [
              // 报考科目快捷选择
              const _Label(text: '报考科目'),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _subjects.map((s) {
                  final selected = _subjectCtrl.text == s;
                  return GestureDetector(
                    onTap: () => setState(() => _subjectCtrl.text = s),
                    child: _ChipTag(label: s, selected: selected),
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),
              _Field(label: '', controller: _subjectCtrl, hint: '或手动输入报考科目'),
              const SizedBox(height: 8),

              // 意向班型快捷选择
              const _Label(text: '意向班型'),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _classTypes.map((s) {
                  final selected = _classTypeCtrl.text == s;
                  return GestureDetector(
                    onTap: () => setState(() => _classTypeCtrl.text = s),
                    child: _ChipTag(label: s, selected: selected),
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),
              _Field(label: '', controller: _classTypeCtrl, hint: '或手动输入班型'),
            ]),

            const SizedBox(height: 12),
            _Section(title: '状态 & 意向', children: [
              const _Label(text: '线索状态'),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ClueStatus.values.map((s) {
                  final selected = _status == s;
                  return GestureDetector(
                    onTap: () => setState(() => _status = s),
                    child: _ChipTag(label: s.label, selected: selected),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              const _Label(text: '意向等级'),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: IntentLevel.values.where((l) => l != IntentLevel.none).map((l) {
                  final selected = _intentLevel == l;
                  return GestureDetector(
                    onTap: () => setState(() => _intentLevel = l),
                    child: _ChipTag(label: l.label, selected: selected),
                  );
                }).toList()
                  ..add(GestureDetector(
                    onTap: () => setState(() => _intentLevel = IntentLevel.none),
                    child: _ChipTag(label: '未标记', selected: _intentLevel == IntentLevel.none),
                  )),
              ),
            ]),

            const SizedBox(height: 12),
            _Section(title: '学生特征标签', children: [
              const _Label(text: '已选标签（点击 ✕ 移除）：'),
              const SizedBox(height: 6),
              if (_tags.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 4),
                  child: Text('暂无标签，可从下方快捷选择或手动添加',
                      style: TextStyle(fontSize: 12, color: Colors.grey)),
                )
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _tags.map((t) {
                    return Chip(
                      label: Text(t,
                          style: const TextStyle(
                              fontSize: 12, color: Color(0xFF1976D2))),
                      backgroundColor:
                          const Color(0xFF1976D2).withValues(alpha: 0.1),
                      deleteIcon: const Icon(Icons.close, size: 14),
                      deleteIconColor: const Color(0xFF1976D2),
                      onDeleted: () {
                        setState(() {
                          _tags.remove(t);
                        });
                      },
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      side: const BorderSide(color: Color(0xFF1976D2)),
                    );
                  }).toList(),
                ),
              const SizedBox(height: 10),
              const _Label(text: '快捷常用标签：'),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _presetTags.map((t) {
                  final hasTag = _tags.contains(t);
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        if (hasTag) {
                          _tags.remove(t);
                        } else {
                          _tags.add(t);
                        }
                      });
                    },
                    child: _ChipTag(
                      label: hasTag ? '✓ $t' : '+ $t',
                      selected: hasTag,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _newTagCtrl,
                      decoration: const InputDecoration(
                        hintText: '输入自定义标签（如：考虑专转本）',
                        hintStyle: TextStyle(fontSize: 13, color: Colors.grey),
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: 10, vertical: 8),
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      final text = _newTagCtrl.text.trim();
                      if (text.isNotEmpty && !_tags.contains(text)) {
                        setState(() {
                          _tags.add(text);
                          _newTagCtrl.clear();
                        });
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1976D2),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                    ),
                    child: const Text('添加'),
                  ),
                ],
              ),
              const SizedBox(height: 6),
            ]),

            const SizedBox(height: 12),
            _Section(title: '备注', children: [
              TextFormField(
                controller: _remarkCtrl,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: '添加备注信息...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ),
            ]),

            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1976D2),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('保存修改', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _delete,
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                label: const Text('删除线索', style: TextStyle(color: Colors.red, fontSize: 15)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _Section({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 13, color: Color(0xFF1976D2), fontWeight: FontWeight.bold)),
          const Divider(height: 16, thickness: 0.5),
          ...children,
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String hint;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  const _Field({
    required this.label,
    required this.controller,
    required this.hint,
    this.keyboardType = TextInputType.text,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.isNotEmpty) _Label(text: label),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            border: InputBorder.none,
            hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
            contentPadding: const EdgeInsets.symmetric(vertical: 8),
          ),
        ),
        const Divider(height: 1, thickness: 0.5, color: Color(0xFFF0F0F0)),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(text, style: const TextStyle(fontSize: 12, color: Colors.grey)),
    );
  }
}

class _ChipTag extends StatelessWidget {
  final String label;
  final bool selected;
  const _ChipTag({required this.label, required this.selected});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFF1976D2) : const Color(0xFFF7F8FA),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: selected ? const Color(0xFF1976D2) : const Color(0xFFDEE2E8),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: selected ? Colors.white : const Color(0xFF555555),
          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
}
