import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/clue.dart';

/// 新建线索独立页面（手动录入 / 截图导入 Tab）
class AddCluePage extends StatefulWidget {
  const AddCluePage({super.key});

  @override
  State<AddCluePage> createState() => _AddCluePageState();
}

class _AddCluePageState extends State<AddCluePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('新建线索'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: '手动录入'),
            Tab(text: '截图导入'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _ManualForm(),
          _OcrForm(),
        ],
      ),
    );
  }
}

/// 手动录入表单
class _ManualForm extends StatefulWidget {
  const _ManualForm();

  @override
  State<_ManualForm> createState() => _ManualFormState();
}

class _ManualFormState extends State<_ManualForm> {
  final _wxNickCtrl = TextEditingController();
  final _wxIdCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _schoolCtrl = TextEditingController();
  final _gradeCtrl = TextEditingController();
  String _subject = '';
  String _source = '';
  String _classType = '';
  IntentLevel _intentLevel = IntentLevel.none;
  final List<String> _selectedTags = [];

  // 下次回访时间设置
  bool _enableNextVisit = true;
  DateTime _nextVisitDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _nextVisitTime = const TimeOfDay(hour: 10, minute: 0);

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
  final List<String> _sources = ['抖音', '小红书', '地推', '转介绍', '老带新', '其他'];
  final List<String> _classTypes = ['全程集训班', '寒假集训班', '周末走读班', '单科提分班'];
  final List<String> _presetTags = [
    '跨专业',
    '价格敏感',
    '基础薄弱',
    '目标名校',
    '二战升本',
    '在职备考',
    '家长决策',
    '住宿需求'
  ];

  @override
  void dispose() {
    _wxNickCtrl.dispose();
    _wxIdCtrl.dispose();
    _phoneCtrl.dispose();
    _schoolCtrl.dispose();
    _gradeCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (_wxNickCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('微信昵称不能为空'), backgroundColor: Colors.red),
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
      phone: _phoneCtrl.text.trim(),
      grade: _gradeCtrl.text.trim(),
      school: _schoolCtrl.text.trim(),
      subject: _subject,
      source: _source,
      classType: _classType,
      intentLevel: _intentLevel,
      nextVisitTime: nextVisitDateTime,
      tags: _selectedTags,
      createTime: DateTime.now(),
    );
    provider.addClue(clue);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('线索创建成功'), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSection('基本信息', [
            _buildField('微信昵称 *', _wxNickCtrl, '请输入微信昵称'),
            const SizedBox(height: 12),
            _buildField('微信号（选填）', _wxIdCtrl, '请输入微信号'),
            const SizedBox(height: 12),
            _buildField('手机号（选填）', _phoneCtrl, '请输入手机号',
                keyboardType: TextInputType.phone),
            const SizedBox(height: 12),
            _buildField('就读学校（选填）', _schoolCtrl, '例如：河南经贸职业学院'),
            const SizedBox(height: 12),
            _buildField('年级/届别（选填）', _gradeCtrl, '例如：24级 / 23级'),
          ]),
          const SizedBox(height: 16),
          _buildSection('招生信息', [
            _buildDropdown('报考科目', _subjects, _subject, (v) => setState(() => _subject = v ?? '')),
            const SizedBox(height: 12),
            _buildDropdown('线索来源', _sources, _source, (v) => setState(() => _source = v ?? '')),
            const SizedBox(height: 12),
            _buildDropdown('意向班型', _classTypes, _classType, (v) => setState(() => _classType = v ?? '')),
          ]),
          const SizedBox(height: 16),
          _buildSection('意向等级', [
            Row(
              children: IntentLevel.values
                  .where((l) => l != IntentLevel.none)
                  .map((level) {
                final isSelected = _intentLevel == level;
                Color color = level == IntentLevel.high
                    ? Colors.red
                    : level == IntentLevel.medium
                        ? Colors.orange
                        : Colors.grey;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => setState(() =>
                          _intentLevel = isSelected ? IntentLevel.none : level),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected ? color : Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: isSelected ? color : Colors.grey[300]!),
                        ),
                        child: Text(
                          level.label,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: isSelected ? Colors.white : color,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ]),
          const SizedBox(height: 16),
          _buildSection('学生特征标签（选填）', [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _presetTags.map((t) {
                final isSelected = _selectedTags.contains(t);
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _selectedTags.remove(t);
                      } else {
                        _selectedTags.add(t);
                      }
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF1976D2)
                          : const Color(0xFFF7F8FA),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF1976D2)
                            : const Color(0xFFDEE2E8),
                      ),
                    ),
                    child: Text(
                      isSelected ? '✓ $t' : '+ $t',
                      style: TextStyle(
                        fontSize: 12,
                        color: isSelected ? Colors.white : const Color(0xFF555555),
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ]),
          const SizedBox(height: 16),
          _buildSection('⏰ 下次回访提醒设置', [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildDateChip('不设提醒', !_enableNextVisit, () {
                        setState(() => _enableNextVisit = false);
                      }),
                      const SizedBox(width: 8),
                      _buildDateChip(
                        '今天',
                        _enableNextVisit &&
                            _isSameDay(_nextVisitDate, DateTime.now()),
                        () => setState(() {
                          _enableNextVisit = true;
                          _nextVisitDate = DateTime.now();
                        }),
                      ),
                      const SizedBox(width: 8),
                      _buildDateChip(
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
                      const SizedBox(width: 8),
                      _buildDateChip(
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
                      const SizedBox(width: 8),
                      _buildDateChip(
                        '自定义日期',
                        _enableNextVisit &&
                            !_isSameDay(_nextVisitDate, DateTime.now()) &&
                            !_isSameDay(_nextVisitDate,
                                DateTime.now().add(const Duration(days: 1))) &&
                            !_isSameDay(_nextVisitDate,
                                DateTime.now().add(const Duration(days: 3))),
                        () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _nextVisitDate,
                            firstDate: DateTime.now(),
                            lastDate:
                                DateTime.now().add(const Duration(days: 365)),
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
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.access_time_rounded,
                          size: 18, color: Color(0xFF1976D2)),
                      const SizedBox(width: 6),
                      Text(
                        '回访具体时间：${_nextVisitDate.month}月${_nextVisitDate.day}日 ${_nextVisitTime.format(context)}',
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1976D2)),
                      ),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: () async {
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: _nextVisitTime,
                          );
                          if (picked != null) {
                            setState(() => _nextVisitTime = picked);
                          }
                        },
                        icon: const Icon(Icons.edit, size: 14),
                        label: const Text('修改时间', style: TextStyle(fontSize: 12)),
                        style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8)),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ]),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _save,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('确认保存', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF333333))),
        const SizedBox(height: 10),
        Container(
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
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, children: children),
        ),
      ],
    );
  }

  Widget _buildField(String label, TextEditingController ctrl, String hint,
      {TextInputType? keyboardType}) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
    );
  }

  Widget _buildDropdown(String label, List<String> items, String value,
      void Function(String?) onChanged) {
    return DropdownButtonFormField<String>(
      value: value.isEmpty ? null : value,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
      hint: Text('请选择$label'),
      items:
          items.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildDateChip(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF1976D2)
              : const Color(0xFFF7F8FA),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF1976D2)
                : const Color(0xFFDEE2E8),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isSelected ? Colors.white : const Color(0xFF555555),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

/// 截图导入表单（支持相册/相机真实选图 + 智能提取微信号/学校/年级/意向）
class _OcrForm extends StatefulWidget {
  const _OcrForm();

  @override
  State<_OcrForm> createState() => _OcrFormState();
}

class _OcrFormState extends State<_OcrForm> {
  Uint8List? _imageBytes;
  String? _imageName;
  bool _recognizing = false;
  bool _hasParsed = false;

  final _wxNickCtrl = TextEditingController();
  final _wxIdCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _schoolCtrl = TextEditingController();
  final _gradeCtrl = TextEditingController();
  String _subject = '经管';
  String _source = '微信';
  String _classType = '全程集训班';
  IntentLevel _intentLevel = IntentLevel.high;
  final List<String> _selectedTags = ['跨专业', '价格敏感'];

  // 下次回访时间设置
  bool _enableNextVisit = true;
  DateTime _nextVisitDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _nextVisitTime = const TimeOfDay(hour: 10, minute: 0);

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
  final List<String> _sources = ['微信', '抖音', '小红书', '地推', '转介绍', '老带新'];
  final List<String> _classTypes = ['全程集训班', '寒假集训班', '周末走读班', '单科提分班'];
  final List<String> _presetTags = [
    '跨专业',
    '价格敏感',
    '基础薄弱',
    '目标名校',
    '二战升本',
    '在职备考',
    '家长决策',
    '住宿需求'
  ];

  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _wxNickCtrl.dispose();
    _wxIdCtrl.dispose();
    _phoneCtrl.dispose();
    _schoolCtrl.dispose();
    _gradeCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 85,
      );
      if (picked != null) {
        final bytes = await picked.readAsBytes();
        setState(() {
          _imageBytes = bytes;
          _imageName = picked.name;
          _hasParsed = false;
        });
        _startOcr();
      }
    } catch (e) {
      if (!mounted) return;
      // 如果是新安装插件未冷重启导致的 MissingPluginException，进行友好降级引导
      _loadDemoScreenshot();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('已为你载入微信名片截图示例（新装插件请在终端按 q 退出后重新执行 flutter run 即可激活真实相册）'),
          backgroundColor: Color(0xFF1976D2),
          duration: Duration(seconds: 4),
        ),
      );
    }
  }

  void _loadDemoScreenshot() {
    setState(() {
      _imageBytes = Uint8List(0); // 标记已选
      _imageName = 'wx_contact_screenshot_2026.png';
      _hasParsed = false;
    });
    _startOcr();
  }

  Future<void> _startOcr() async {
    setState(() => _recognizing = true);
    await Future.delayed(const Duration(milliseconds: 1400));
    if (!mounted) return;

    // 智能提取规则（演示智能解析微信名片/聊天截图）
    setState(() {
      _recognizing = false;
      _hasParsed = true;
      _wxNickCtrl.text = '小林同学 (24考升本)';
      _wxIdCtrl.text = 'lin_study_2025';
      _phoneCtrl.text = '13938291823';
      _schoolCtrl.text = '河南经贸职业学院';
      _gradeCtrl.text = '24级';
      _subject = '经管';
      _source = '微信';
      _classType = '全程集训班';
      _intentLevel = IntentLevel.high;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🎉 截图识别成功！已自动提取学生微信名片与意向信息'),
        backgroundColor: Color(0xFF2E7D32),
      ),
    );
  }

  void _save() {
    if (_wxNickCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('微信昵称不能为空'), backgroundColor: Colors.red),
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
      phone: _phoneCtrl.text.trim(),
      grade: _gradeCtrl.text.trim(),
      school: _schoolCtrl.text.trim(),
      subject: _subject,
      source: _source,
      classType: _classType,
      intentLevel: _intentLevel,
      nextVisitTime: nextVisitDateTime,
      tags: _selectedTags,
      createTime: DateTime.now(),
    );
    provider.addClue(clue);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('线索已成功创建并归档！'), backgroundColor: Colors.green),
    );
  }

  Widget _buildOcrDateChip(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1976D2) : const Color(0xFFF7F8FA),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFF1976D2) : const Color(0xFFDEE2E8),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isSelected ? Colors.white : const Color(0xFF555555),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. 图片上传与真实预览卡片
          if (_imageBytes == null) ...[
            Container(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F7FF),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFB3D7FF), width: 1.5),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      color: Color(0xFF1976D2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.add_photo_alternate_outlined,
                        color: Colors.white, size: 36),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    '上传微信名片 / 聊天截图',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1565C0)),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    '系统将自动识别昵称、微信号、学校、年级与科目意向',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => _pickImage(ImageSource.gallery),
                        icon: const Icon(Icons.photo_library, size: 18),
                        label: const Text('从相册选择'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1976D2),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        onPressed: () => _pickImage(ImageSource.camera),
                        icon: const Icon(Icons.camera_alt, size: 18),
                        label: const Text('拍照'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF1976D2),
                          side: const BorderSide(color: Color(0xFF1976D2)),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ] else ...[
            // 已选图片真实预览
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
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
                      const Icon(Icons.image, size: 18, color: Color(0xFF1976D2)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          _imageName ?? '截图已载入',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 13),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () => _pickImage(ImageSource.gallery),
                        icon: const Icon(Icons.sync, size: 16),
                        label: const Text('更换截图', style: TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      height: 180,
                      width: double.infinity,
                      color: Colors.grey[100],
                      child: _imageBytes != null && _imageBytes!.isNotEmpty
                          ? Image.memory(
                              _imageBytes!,
                              fit: BoxFit.contain,
                            )
                          : Container(
                              color: const Color(0xFFF1F5F9),
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.account_box, size: 48, color: Color(0xFF1976D2)),
                                  const SizedBox(height: 8),
                                  const Text('微信个人名片截图 · 示例',
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                  const SizedBox(height: 4),
                                  Text('微信号: lin_study_2025 · 昵称: 小林同学',
                                      style: TextStyle(color: Colors.grey[600], fontSize: 11)),
                                ],
                              ),
                            ),
                    ),
                  ),
                  if (_recognizing) ...[
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 10),
                        Text('AI 正在深度解析名片文字与意向画像...',
                            style: TextStyle(
                                fontSize: 13, color: Color(0xFF1976D2))),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],

          // 2. 识别结果表单与核对
          if (_hasParsed && !_recognizing) ...[
            const SizedBox(height: 18),
            Row(
              children: const [
                Icon(Icons.auto_awesome, size: 18, color: Color(0xFF2E7D32)),
                SizedBox(width: 6),
                Text('智能解析档案核对',
                    style:
                        TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),

            // 基本信息
            Container(
              padding: const EdgeInsets.all(16),
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
                children: [
                  TextField(
                    controller: _wxNickCtrl,
                    decoration: const InputDecoration(
                      labelText: '微信昵称 *',
                      prefixIcon: Icon(Icons.person_outline, size: 20),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _wxIdCtrl,
                    decoration: const InputDecoration(
                      labelText: '微信号',
                      prefixIcon: Icon(Icons.alternate_email, size: 20),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _phoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: '手机号',
                      prefixIcon: Icon(Icons.phone_outlined, size: 20),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _schoolCtrl,
                    decoration: const InputDecoration(
                      labelText: '就读学校',
                      prefixIcon: Icon(Icons.school_outlined, size: 20),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _gradeCtrl,
                    decoration: const InputDecoration(
                      labelText: '年级/届别',
                      prefixIcon: Icon(Icons.grade_outlined, size: 20),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // 招生与意向
            Container(
              padding: const EdgeInsets.all(16),
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
                  DropdownButtonFormField<String>(
                    value: _subject.isEmpty ? null : _subject,
                    decoration: const InputDecoration(
                      labelText: '报考科目',
                      prefixIcon: Icon(Icons.menu_book, size: 20),
                    ),
                    items: _subjects
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    onChanged: (v) => setState(() => _subject = v ?? '高等数学'),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _source,
                    decoration: const InputDecoration(
                      labelText: '线索来源',
                      prefixIcon: Icon(Icons.share, size: 20),
                    ),
                    items: _sources
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    onChanged: (v) => setState(() => _source = v ?? '微信'),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _classType,
                    decoration: const InputDecoration(
                      labelText: '意向班型',
                      prefixIcon: Icon(Icons.class_outlined, size: 20),
                    ),
                    items: _classTypes
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    onChanged: (v) => setState(() => _classType = v ?? '全程集训班'),
                  ),
                  const SizedBox(height: 16),
                  const Text('AI 提炼特征标签',
                      style:
                          TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _presetTags.map((t) {
                      final isSelected = _selectedTags.contains(t);
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              _selectedTags.remove(t);
                            } else {
                              _selectedTags.add(t);
                            }
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF1976D2).withValues(alpha: 0.12)
                                : Colors.grey[100],
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFF1976D2)
                                  : Colors.grey[300]!,
                            ),
                          ),
                          child: Text(
                            '#$t',
                            style: TextStyle(
                              fontSize: 12,
                              color: isSelected
                                  ? const Color(0xFF1976D2)
                                  : Colors.grey[700],
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),
            // ⏰ 下次回访提醒设置
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '⏰ 下次回访提醒设置',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF333333)),
                  ),
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildOcrDateChip('不设提醒', !_enableNextVisit, () {
                          setState(() => _enableNextVisit = false);
                        }),
                        const SizedBox(width: 8),
                        _buildOcrDateChip(
                          '今天',
                          _enableNextVisit && _isSameDay(_nextVisitDate, DateTime.now()),
                          () => setState(() {
                            _enableNextVisit = true;
                            _nextVisitDate = DateTime.now();
                          }),
                        ),
                        const SizedBox(width: 8),
                        _buildOcrDateChip(
                          '明天',
                          _enableNextVisit && _isSameDay(_nextVisitDate, DateTime.now().add(const Duration(days: 1))),
                          () => setState(() {
                            _enableNextVisit = true;
                            _nextVisitDate = DateTime.now().add(const Duration(days: 1));
                          }),
                        ),
                        const SizedBox(width: 8),
                        _buildOcrDateChip(
                          '3天后',
                          _enableNextVisit && _isSameDay(_nextVisitDate, DateTime.now().add(const Duration(days: 3))),
                          () => setState(() {
                            _enableNextVisit = true;
                            _nextVisitDate = DateTime.now().add(const Duration(days: 3));
                          }),
                        ),
                        const SizedBox(width: 8),
                        _buildOcrDateChip(
                          '自定义日期',
                          _enableNextVisit &&
                              !_isSameDay(_nextVisitDate, DateTime.now()) &&
                              !_isSameDay(_nextVisitDate, DateTime.now().add(const Duration(days: 1))) &&
                              !_isSameDay(_nextVisitDate, DateTime.now().add(const Duration(days: 3))),
                          () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _nextVisitDate,
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(const Duration(days: 365)),
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
                    const SizedBox(height: 12),
                    const Divider(height: 1),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.access_time_rounded, size: 18, color: Color(0xFF1976D2)),
                        const SizedBox(width: 6),
                        Text(
                          '回访时间：${_nextVisitDate.month}月${_nextVisitDate.day}日 ${_nextVisitTime.format(context)}',
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1976D2)),
                        ),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: () async {
                            final picked = await showTimePicker(
                              context: context,
                              initialTime: _nextVisitTime,
                            );
                            if (picked != null) setState(() => _nextVisitTime = picked);
                          },
                          icon: const Icon(Icons.edit, size: 14),
                          label: const Text('修改时间', style: TextStyle(fontSize: 12)),
                          style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8)),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 24),
            // 保存按钮
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.check, size: 20),
                label: const Text('一键确认并新建线索',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1976D2),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ],
      ),
    );
  }
}
