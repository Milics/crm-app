import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/clue.dart';
import '../providers/app_provider.dart';

/// AI智能分析独立页（含意向评分预测、画像诊断、核心顾虑、策略话题与专属话术）
class AiAnalysisPage extends StatefulWidget {
  final Clue clue;
  const AiAnalysisPage({super.key, required this.clue});

  @override
  State<AiAnalysisPage> createState() => _AiAnalysisPageState();
}

class _AiAnalysisPageState extends State<AiAnalysisPage> {
  bool _loading = true;
  bool _saved = false;
  _AnalysisResult? _result;

  @override
  void initState() {
    super.initState();
    _analyze();
  }

  Future<void> _analyze() async {
    setState(() {
      _loading = true;
      _saved = false;
    });
    await Future.delayed(const Duration(milliseconds: 1000));
    if (!mounted) return;
    setState(() {
      _loading = false;
      _result = _generateResult(widget.clue);
    });
  }

  _AnalysisResult _generateResult(Clue clue) {
    final visitCount = clue.visitLogs.length;
    final subject = clue.subject.isEmpty ? '专升本' : clue.subject;
    final classType = clue.classType.isEmpty ? '集训班' : clue.classType;

    // 收集所有顾虑与特征标签
    final allConcerns = <String>{};
    for (final log in clue.visitLogs) {
      allConcerns.addAll(log.concerns);
    }
    allConcerns.addAll(clue.tags);

    // 计算成交意向预测得分 (0 ~ 100)
    int baseScore = 50;
    if (clue.status == ClueStatus.enrolled) {
      baseScore = 100;
    } else if (clue.status == ClueStatus.attended) {
      baseScore = 85;
    } else if (clue.status == ClueStatus.invited) {
      baseScore = 78;
    } else if (clue.status == ClueStatus.contacted) {
      baseScore = 65;
    } else if (clue.status == ClueStatus.paused) {
      baseScore = 30;
    }

    if (clue.intentLevel == IntentLevel.high) baseScore += 12;
    if (clue.intentLevel == IntentLevel.medium) baseScore += 5;
    if (clue.tags.contains('目标名校') || clue.tags.contains('二战升本')) baseScore += 6;
    if (clue.tags.contains('价格敏感')) baseScore -= 5;
    final score = baseScore.clamp(15, 99);

    final scoreLevel = score >= 80
        ? '高意向 · 极高转化可能'
        : score >= 60
            ? '良好 · 需持续促成'
            : '观望 · 需破冰与价值引导';

    return _AnalysisResult(
      score: score,
      scoreLevel: scoreLevel,
      portrait: [
        '学员称呼：${clue.wxNick}',
        '目标专业：${subject.isEmpty ? "待确认" : subject} 专升本',
        '意向班型：$classType',
        '跟进频次：已完成 $visitCount 次深度沟通',
        '特征画像：${clue.tags.isNotEmpty ? clue.tags.map((t) => "#$t").join(" ") : "尚未打标，可在编辑页添加标签"}',
        '当前阶段：${clue.status.label}（${clue.intentLevel.label}意向）',
      ],
      concerns: allConcerns.isEmpty
          ? ['暂未记录明显顾虑，建议在沟通中主动探寻学生在复习时间或基础上的痛点。']
          : allConcerns.map((c) {
              switch (c) {
                case '学费':
                case '价格敏感':
                  return '💰 价格敏感：对学费比较关注，需主动介绍分期付款、早鸟减免或奖学金政策。';
                case '基础':
                case '基础薄弱':
                  return '📚 基础担忧：担心 $subject 考不过或底子薄，需推荐零基础阶梯课程与专属答疑服务。';
                case '时间':
                case '在职备考':
                  return '⏳ 时间紧张：属于在职/实习备考，需推荐周末走读班或名师高清录播随时补课。';
                case '跨专业':
                  return '🔄 跨专业备考：对跨考政策与加试科目不熟悉，需提供精准跨考院校招生分析表。';
                case '二战升本':
                  return '🎯 二战考生：心理压力大且目标明确，需强调往年高分通过率与针对性刷题集训。';
                case '住宿':
                case '住宿需求':
                  return '🏠 住宿需求：关注吃住学一体化集训环境，需发送基地宿舍与食堂实拍图。';
                case '家长决策':
                  return '👨‍👩‍👧 家长决策：最终需家长同意出资，建议提供正式办学资质、协议范本供家庭参考。';
                default:
                  return '📌 关注要点：$c';
              }
            }).toList(),
      topics: visitCount == 0
          ? [
              '询问大专在读年级与目标升本大学',
              '确认 $subject 的薄弱知识模块与备考痛点',
              '发送最新 $subject 历年考情分析与真题资料包',
              '引导预约本周末名师试听课席位',
            ]
          : [
              '针对核心诉求（${allConcerns.take(2).join("、")}）提供专项解决方案',
              '同步本周最新的早鸟限时优惠名额（仅剩少量优惠席位）',
              '分享同专业已成功上岸学长学姐的备考案例与复习笔记',
              '推进确认报名或到访校区参加全真模考',
            ],
      script: visitCount == 0
          ? '同学你好呀！看到你关注了 $subject 专升本，目前复习准备得怎么样啦？我们教研团队刚整理了一份最新的《$subject 核心考点与升本避坑指南》，包含近5年真题剖析，方便发你一份参考了解下吗？'
          : '${clue.wxNick} 同学，上次咱们沟通后我一直记着你的情况～${allConcerns.contains("价格敏感") || allConcerns.contains("学费") ? "针对学费方面，我今天专门帮你向教务主管申请了免息分期和早鸟助学金，月供仅需几百元；" : "咱们针对 $subject 的 $classType 名师定制班刚好这周有名额开放；"}你看今天下午或晚上方便语音聊 3 分钟详细说说吗？',
    );
  }

  void _saveToTimeline() {
    if (_result == null || _saved) return;
    final provider = context.read<AppProvider>();
    final log = VisitLog(
      id: provider.generateId(),
      clueId: widget.clue.id,
      contactMethod: ContactMethod.wechat,
      visitResult: VisitResult.normal,
      visitContent: '【AI智能跟进策略】意向预测得分：${_result!.score}分（${_result!.scoreLevel}）。建议跟进重点：${_result!.topics.first}',
      concerns: widget.clue.tags,
      nextVisitTime: widget.clue.nextVisitTime,
      createTime: DateTime.now(),
    );
    provider.addVisitLog(widget.clue.id, log);
    setState(() => _saved = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('已成功将 AI 分析纪要沉淀到线索时间轴！'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('AI 智能分析'),
        backgroundColor: const Color(0xFF7B1FA2),
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: Color(0xFF7B1FA2)),
                  const SizedBox(height: 20),
                  const Text('AI 正在深度分析客户画像与沟通历史...',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('综合考量回访记录 + 标签画像 + 意向等级',
                      style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                ],
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        // 0. AI意向评分卡
                        _ScoreCard(score: _result!.score, level: _result!.scoreLevel),
                        const SizedBox(height: 14),

                        // 1. 客户整体画像
                        _AnalysisCard(
                          number: '1',
                          title: '客户综合画像诊断',
                          icon: Icons.person_outline,
                          color: const Color(0xFF1976D2),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: _result!.portrait
                                .map((item) => _CheckItem(text: item))
                                .toList(),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // 2. 核心顾虑汇总
                        _AnalysisCard(
                          number: '2',
                          title: '核心顾虑与痛点洞察',
                          icon: Icons.psychology_outlined,
                          color: const Color(0xFF00897B),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: _result!.concerns
                                .map((item) => Padding(
                                      padding: const EdgeInsets.only(bottom: 8),
                                      child: Text(
                                        item,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: Color(0xFF333333),
                                          height: 1.4,
                                        ),
                                      ),
                                    ))
                                .toList(),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // 3. 建议回访话题
                        _AnalysisCard(
                          number: '3',
                          title: '建议下一步沟通策略',
                          icon: Icons.lightbulb_outline,
                          color: Colors.orange,
                          trailing: '${_result!.topics.length} 个策略点',
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: _result!.topics
                                .asMap()
                                .entries
                                .map((e) => Padding(
                                      padding: const EdgeInsets.only(bottom: 8),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            width: 20,
                                            height: 20,
                                            decoration: BoxDecoration(
                                              color: Colors.orange.withValues(alpha: 0.15),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Center(
                                              child: Text(
                                                '${e.key + 1}',
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.orange,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              e.value,
                                              style: const TextStyle(
                                                fontSize: 13,
                                                color: Color(0xFF333333),
                                                height: 1.4,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ))
                                .toList(),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // 4. 定制化破冰/促成话术
                        _AnalysisCard(
                          number: '4',
                          title: 'AI 定制攻坚话术',
                          icon: Icons.record_voice_over_outlined,
                          color: const Color(0xFF7B1FA2),
                          trailing: '微信直接发送',
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF3E5F5),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: const Color(0xFFE1BEE7)),
                                ),
                                child: Text(
                                  _result!.script,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF4A148C),
                                    height: 1.6,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Align(
                                alignment: Alignment.centerRight,
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    Clipboard.setData(ClipboardData(text: _result!.script));
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('AI话术已复制，可直接粘贴发给学生！'),
                                        backgroundColor: Color(0xFF7B1FA2),
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.copy_rounded, size: 14, color: Colors.white),
                                  label: const Text('一键复制话术', style: TextStyle(fontSize: 12)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF7B1FA2),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),

                // 底部操作区
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
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _saved ? null : _saveToTimeline,
                          icon: Icon(
                            _saved ? Icons.check_circle : Icons.bookmark_add_outlined,
                            size: 18,
                            color: _saved ? Colors.green : const Color(0xFF7B1FA2),
                          ),
                          label: Text(_saved ? '已沉淀到时间轴' : '保存分析到时间轴'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            foregroundColor: const Color(0xFF7B1FA2),
                            side: const BorderSide(color: Color(0xFF7B1FA2)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _analyze,
                          icon: const Icon(Icons.refresh, size: 18),
                          label: const Text('重新分析'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF7B1FA2),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

class _AnalysisResult {
  final int score;
  final String scoreLevel;
  final List<String> portrait;
  final List<String> concerns;
  final List<String> topics;
  final String script;

  _AnalysisResult({
    required this.score,
    required this.scoreLevel,
    required this.portrait,
    required this.concerns,
    required this.topics,
    required this.script,
  });
}

class _ScoreCard extends StatelessWidget {
  final int score;
  final String level;

  const _ScoreCard({required this.score, required this.level});

  @override
  Widget build(BuildContext context) {
    Color scoreColor = score >= 80
        ? const Color(0xFF2E7D32)
        : score >= 60
            ? const Color(0xFFE65100)
            : const Color(0xFFC62828);

    return Container(
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
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: scoreColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$score',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: scoreColor,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'AI 成交意向预测分',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: scoreColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        level,
                        style: TextStyle(fontSize: 11, color: scoreColor, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: score / 100.0,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AnalysisCard extends StatelessWidget {
  final String number;
  final String title;
  final IconData icon;
  final Color color;
  final String? trailing;
  final Widget child;

  const _AnalysisCard({
    required this.number,
    required this.title,
    required this.icon,
    required this.color,
    this.trailing,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
          Row(
            children: [
              Text(
                '$number. ',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color),
              ),
              Text(
                title,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: color),
              ),
              const Spacer(),
              if (trailing != null)
                Text(trailing!, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _CheckItem extends StatelessWidget {
  final String text;
  const _CheckItem({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle_outline, size: 16, color: Color(0xFF1976D2)),
          const SizedBox(width: 6),
          Expanded(
            child: Text(text, style: const TextStyle(fontSize: 13, color: Color(0xFF333333))),
          ),
        ],
      ),
    );
  }
}
