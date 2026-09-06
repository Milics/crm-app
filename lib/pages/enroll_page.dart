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

  late final List<_ClassType> _classTypes;

  @override
  void initState() {
    super.initState();
    _classTypes = [
      const _ClassType(
          name: '全程协议班',
          icon: Icons.verified_user_rounded,
          desc: '线下全科系统培训，协议保障通关'),
      const _ClassType(
          name: '全程非协议班',
          icon: Icons.school_rounded,
          desc: '线下全科系统面授，高师带学'),
      const _ClassType(
          name: '单科班',
          icon: Icons.star_outline_rounded,
          desc: '针对薄弱单科突破，专项拔高提分'),
      const _ClassType(
          name: '网课班',
          icon: Icons.laptop_mac_rounded,
          desc: '线上网课随心学，时间灵活自由'),
      const _ClassType(
          name: '冲刺班',
          icon: Icons.bolt_rounded,
          desc: '考前高频考点点睛与全真模考冲刺'),
    ];

    // 如果历史线索已有其他班型（例如全程集训班），自动追加并回显，保证历史数据不丢失
    if (widget.clue.classType.isNotEmpty &&
        !_classTypes.any((ct) => ct.name == widget.clue.classType)) {
      _classTypes.add(_ClassType(
        name: widget.clue.classType,
        icon: Icons.bookmark_added_outlined,
        desc: '历史登记班型',
      ));
    }

    // 自动回显已有报班类型
    final foundIndex =
        _classTypes.indexWhere((ct) => ct.name == widget.clue.classType);
    if (foundIndex != -1) {
      _selectedClassType = foundIndex;
    }
    // 自动回显预交金额
    if (widget.clue.enrollAmount != null) {
      final amt = widget.clue.enrollAmount!;
      _amountCtrl.text =
          (amt % 1 == 0) ? amt.toInt().toString() : amt.toString();
    }
    // 自动回显备注信息
    if (widget.clue.remark.isNotEmpty) {
      _remarkCtrl.text = widget.clue.remark;
    }
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _remarkCtrl.dispose();
    super.dispose();
  }

  Future<void> _confirmEnroll() async {
    final isEnrolled = widget.clue.status == ClueStatus.enrolled;
    final amountText = _amountCtrl.text.trim();
    double? amount;
    if (amountText.isNotEmpty) {
      amount = double.tryParse(amountText);
      if (amount == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('请输入合法的预交金额数值'), backgroundColor: Colors.red),
        );
        return;
      }
    } else if (!isEnrolled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请填写预交金额'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _loading = true);
    await Future.delayed(const Duration(milliseconds: 400));

    if (!mounted) return;
    final provider = context.read<AppProvider>();
    if (isEnrolled) {
      provider.updateEnrollInfo(
        widget.clue.id,
        _classTypes[_selectedClassType].name,
        amount,
        _remarkCtrl.text.trim(),
      );
    } else {
      provider.enrollClue(
        widget.clue.id,
        _classTypes[_selectedClassType].name,
        _remarkCtrl.text.trim(),
        enrollAmount: amount,
      );
    }
    setState(() => _loading = false);

    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isEnrolled
            ? '✅ ${widget.clue.wxNick} 的报名信息已成功更新！'
            : '🎉 ${widget.clue.wxNick} 已成功转为报名！'),
        backgroundColor:
            isEnrolled ? const Color(0xFF2E7D32) : const Color(0xFFE65100),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final clue = widget.clue;
    final isEnrolled = clue.status == ClueStatus.enrolled;
    final themeColor =
        isEnrolled ? const Color(0xFF2E7D32) : const Color(0xFFE65100);

    return Scaffold(
      appBar: AppBar(
        title: Text(isEnrolled ? '报名详情' : '转为报名'),
        backgroundColor: themeColor,
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
                      gradient: LinearGradient(
                        colors: isEnrolled
                            ? const [Color(0xFF2E7D32), Color(0xFF43A047)]
                            : const [Color(0xFFE65100), Color(0xFFFF8F00)],
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
                              ? themeColor.withValues(alpha: 0.1)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? themeColor
                                : Colors.grey[200]!,
                            width: isSelected ? 2 : 1,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: themeColor.withValues(alpha: 0.15),
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
                                    ? themeColor.withValues(alpha: 0.15)
                                    : Colors.grey[100],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(ct.icon,
                                  color: isSelected
                                      ? themeColor
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
                                          ? themeColor
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
                              Icon(Icons.check_circle,
                                  color: themeColor),
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
                        Text('¥',
                            style: TextStyle(
                                fontSize: 20,
                                color: themeColor,
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
                      color: isEnrolled ? Colors.green[50] : Colors.orange[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                            isEnrolled
                                ? Icons.verified_user_outlined
                                : Icons.warning_amber_rounded,
                            color: isEnrolled
                                ? const Color(0xFF2E7D32)
                                : Colors.orange,
                            size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            isEnrolled
                                ? '该学员已成功报名，如班型、预交金额或特殊协议备注有变动，可直接修改并保存更新。'
                                : '确认后，该线索状态将更新为"已报名"，请核实信息无误后再提交。',
                            style: TextStyle(
                                color: isEnrolled
                                    ? const Color(0xFF2E7D32)
                                    : Colors.orange[800],
                                fontSize: 12),
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
                  backgroundColor: themeColor,
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
                    : Text(isEnrolled ? '保存修改' : '确认转为报名',
                        style: const TextStyle(
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
