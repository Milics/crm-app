import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/clue.dart';

/// 转为报名独立页（原型图：班型选择 + 预交金额 + 备注 + 确认按钮）
class EnrollPage extends StatefulWidget {
  final Clue clue;
  const EnrollPage({super.key, required this.clue});

  @override
  State<EnrollPage> createState() => _EnrollPageState();
}

class _EnrollPageState extends State<EnrollPage> {
  int _selectedClassType = 0;
  final _amountCtrl = TextEditingController();
  final _remarkCtrl = TextEditingController();
  bool _loading = false;

  final List<_ClassType> _classTypes = const [
    _ClassType(name: '全程集训班', icon: Icons.school, desc: '线下集中授课，全科系统培训'),
    _ClassType(name: '寒暑假集训班', icon: Icons.wb_sunny_outlined, desc: '假期密集备考，效率提升'),
    _ClassType(name: '周末走读班', icon: Icons.calendar_today, desc: '周末上课，不耽误工作学习'),
    _ClassType(name: '单科提分班', icon: Icons.star_outline, desc: '针对薄弱科目专项突破'),
  ];

  @override
  void dispose() {
    _amountCtrl.dispose();
    _remarkCtrl.dispose();
    super.dispose();
  }

  Future<void> _confirmEnroll() async {
    if (_amountCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请填写预交金额'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _loading = true);
    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;
    final provider = context.read<AppProvider>();
    provider.enrollClue(
      widget.clue.id,
      _classTypes[_selectedClassType].name,
      _remarkCtrl.text.trim(),
    );
    setState(() => _loading = false);

    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('🎉 ${widget.clue.wxNick} 已成功转为报名！'),
        backgroundColor: const Color(0xFFE65100),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final clue = widget.clue;
    return Scaffold(
      appBar: AppBar(
        title: const Text('转为报名'),
        backgroundColor: const Color(0xFFE65100),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 客户信息摘要卡
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFE65100), Color(0xFFFF8F00)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor:
                                  Colors.white.withValues(alpha: 0.3),
                              radius: 22,
                              child: Text(
                                clue.wxNick.isNotEmpty
                                    ? clue.wxNick[0]
                                    : '?',
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 18),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  clue.wxNick,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  clue.wxId.isEmpty ? '微信号未填写' : clue.wxId,
                                  style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.9),
                                      fontSize: 13),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            _InfoChip(label: '来源：${clue.source}'),
                            _InfoChip(
                                label: '意向：${clue.intentLevel.label}'),
                            if (clue.subject.isNotEmpty)
                              _InfoChip(label: '科目：${clue.subject}'),
                            _InfoChip(
                                label: '回访：${clue.visitLogs.length}次'),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 班型选择
                  const _SectionTitle(title: '报班类型'),
                  const SizedBox(height: 10),
                  ...List.generate(_classTypes.length, (i) {
                    final ct = _classTypes[i];
                    final isSelected = _selectedClassType == i;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedClassType = i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFFFFF3E0)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFFE65100)
                                : Colors.grey[200]!,
                            width: isSelected ? 2 : 1,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: const Color(0xFFE65100)
                                        .withValues(alpha: 0.15),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  )
                                ]
                              : [],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFFE65100)
                                        .withValues(alpha: 0.15)
                                    : Colors.grey[100],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(ct.icon,
                                  color: isSelected
                                      ? const Color(0xFFE65100)
                                      : Colors.grey[400],
                                  size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    ct.name,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: isSelected
                                          ? const Color(0xFFE65100)
                                          : Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(ct.desc,
                                      style: TextStyle(
                                          color: Colors.grey[500],
                                          fontSize: 12)),
                                ],
                              ),
                            ),
                            if (isSelected)
                              const Icon(Icons.check_circle,
                                  color: Color(0xFFE65100)),
                          ],
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 16),

                  // 预交金额
                  const _SectionTitle(title: '预交金额（元）'),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Row(
                      children: [
                        const Text('¥',
                            style: TextStyle(
                                fontSize: 20,
                                color: Color(0xFFE65100),
                                fontWeight: FontWeight.bold)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _amountCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              hintText: '请输入预交金额',
                              border: InputBorder.none,
                              contentPadding:
                                  EdgeInsets.symmetric(vertical: 12),
                            ),
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 备注信息
                  const _SectionTitle(title: '备注信息'),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: TextField(
                      controller: _remarkCtrl,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        hintText: '录入特殊备注（分期协议、特殊优惠、约定内容等）',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // 提示
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.warning_amber_rounded,
                            color: Colors.orange, size: 16),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '确认后，该线索状态将更新为"已报名"，请核实信息无误后再提交。',
                            style:
                                TextStyle(color: Colors.orange, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 底部确认按钮
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                )
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _confirmEnroll,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE65100),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: _loading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('确认转为报名',
                        style: TextStyle(
                            fontSize: 17, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ClassType {
  final String name;
  final IconData icon;
  final String desc;
  const _ClassType({required this.name, required this.icon, required this.desc});
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});
  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
          fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF333333)),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  const _InfoChip({required this.label});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: const TextStyle(color: Colors.white, fontSize: 12)),
    );
  }
}
