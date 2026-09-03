import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/clue.dart';
import '../providers/app_provider.dart';
import '../services/ai_service.dart';

/// AI 智能分析页面（支持 DeepSeek / 智谱大模型实时诊断 + 专业启发式规则双引擎）
class AiAnalysisPage extends StatefulWidget {
  final Clue clue;
  const AiAnalysisPage({super.key, required this.clue});

  @override
  State<AiAnalysisPage> createState() => _AiAnalysisPageState();
}

class _AiAnalysisPageState extends State<AiAnalysisPage> {
  bool _loading = true;
  bool _saved = false;
  bool _usingLlm = false;
  String? _llmOutput;
  String? _errorMessage;
  _AnalysisResult? _result;

  @override
  void initState() {
    super.initState();
    // 优先秒开展示已保存的历史 AI 报告，省时省 Token；若没有才自动首次分析
    if (widget.clue.aiAnalysisReport != null &&
        widget.clue.aiAnalysisReport!.isNotEmpty) {
      _loading = false;
      _usingLlm = true;
      _llmOutput = widget.clue.aiAnalysisReport;
      _result = _generateResult(widget.clue);
    } else {
      _analyze();
    }
  }

  Future<void> _analyze() async {
    setState(() {
      _loading = true;
      _saved = false;
      _errorMessage = null;
    });

    final ai = AiService();
    await ai.init();

    if (ai.isConfigured) {
      try {
        final output = await ai.analyzeClue(widget.clue);
        if (mounted) {
          setState(() {
            _loading = false;
            _usingLlm = true;
            _llmOutput = output;
            _result = _generateResult(widget.clue);
          });
          // 自动持久化沉淀到线索档案并同步到云端
          context.read<AppProvider>().saveAiAnalysisReport(widget.clue.id, output);
          return;
        }
      } catch (e) {
        debugPrint('⚠️ 大模型调用失败，降级为规则引擎: $e');
        _errorMessage = '云端大模型连接遇到问题 ($e)，已自动平滑切换至内置金牌专家规则模式。';
      }
    }

    // 启发式规则兜底模式
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    setState(() {
      _loading = false;
      _usingLlm = false;
      _result = _generateResult(widget.clue);
    });
  }

  _AnalysisResult _generateResult(Clue clue) {
    final visitCount = clue.visitLogs.length;
    final subject = clue.subject.isEmpty ? '专升本' : clue.subject;
    final classType = clue.classType.isEmpty ? '集训班' : clue.classType;

    final allConcerns = <String>{};
    for (final log in clue.visitLogs) {
      allConcerns.addAll(log.concerns);
    }
    allConcerns.addAll(clue.tags);

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
    if (_saved) return;
    final provider = context.read<AppProvider>();
    final summary = _usingLlm && _llmOutput != null
        ? '【AI大模型深度诊断】已完成深度剖析，包含破冰、案例与逼单方案，详见AI分析页。'
        : '【AI智能跟进策略】意向预测得分：${_result!.score}分（${_result!.scoreLevel}）。建议跟进重点：${_result!.topics.first}';

    final log = VisitLog(
      id: provider.generateId(),
      clueId: widget.clue.id,
      contactMethod: ContactMethod.wechat,
      visitResult: VisitResult.normal,
      visitContent: summary,
      concerns: widget.clue.tags,
      nextVisitTime: widget.clue.nextVisitTime,
      createTime: DateTime.now(),
    );
    provider.addVisitLog(widget.clue.id, log);
    setState(() => _saved = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ 已成功将 AI 诊断纪要沉淀到学员时间轴！'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showSettingsDialog() {
    final ai = AiService();
    final keyCtrl = TextEditingController(text: ai.apiKey);
    final urlCtrl = TextEditingController(text: ai.baseUrl);
    final modelCtrl = TextEditingController(text: ai.model);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.auto_awesome, color: Color(0xFF7B1FA2)),
            SizedBox(width: 8),
            Text('AI 大模型设置', style: TextStyle(fontSize: 16)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '🌟 云端统一托管机制：作为负责人您只需在此配置一次 API Key，系统将自动加密托管至 Render 云中枢，全团队所有顾问手机直接免配畅享大模型实时诊断！',
                style: TextStyle(
                    fontSize: 12.5,
                    color: Color(0xFF7B1FA2),
                    height: 1.45,
                    fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: keyCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'DeepSeek API Key (如 sk-...)',
                  hintText: '输入您的 DeepSeek API Key',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: urlCtrl,
                decoration: const InputDecoration(
                  labelText: 'API 接口地址 Base URL',
                  hintText: 'https://api.deepseek.com/v1',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: modelCtrl,
                decoration: const InputDecoration(
                  labelText: '模型名称 Model',
                  hintText: 'deepseek-chat',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              await ai.saveSettings(
                apiKey: keyCtrl.text,
                baseUrl: urlCtrl.text,
                model: modelCtrl.text,
              );
              if (ctx.mounted) Navigator.pop(ctx);
              _analyze();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7B1FA2),
              foregroundColor: Colors.white,
            ),
            child: const Text('保存并重新分析'),
          ),
        ],
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
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: '重新分析',
            onPressed: _loading ? null : _analyze,
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: '配置大模型 API Key',
            onPressed: _showSettingsDialog,
          ),
        ],
      ),
      body: _loading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: Color(0xFF7B1FA2)),
                  const SizedBox(height: 20),
                  Text(
                    _usingLlm || AiService().isConfigured
                        ? '✨ 正在向 DeepSeek 云端大模型发起深度推理分析...'
                        : 'AI 正在深度分析客户画像与沟通历史...',
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text('综合考量回访记录 + 沟通截图 + 标签画像 + 意向等级',
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
                        // 提示胶囊
                        if (_errorMessage != null)
                          Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.amber[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.amber[300]!),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.warning_amber_rounded,
                                    color: Colors.amber, size: 18),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _errorMessage!,
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.brown[700]),
                                  ),
                                ),
                              ],
                            ),
                          )
                        else if (!_usingLlm)
                          GestureDetector(
                            onTap: _showSettingsDialog,
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: const Color(0xFF7B1FA2)
                                    .withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                    color: const Color(0xFF7B1FA2)
                                        .withValues(alpha: 0.2)),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.auto_awesome,
                                      size: 16, color: Color(0xFF7B1FA2)),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      '当前为内置专家规则模式。超管点击右上角 ⚙️ 输入一次 DeepSeek Key，全团队 5 位顾问直接免配畅享大模型实时诊断！',
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF7B1FA2),
                                          fontWeight: FontWeight.w500),
                                    ),
                                  ),
                                  Icon(Icons.chevron_right,
                                      size: 16, color: Color(0xFF7B1FA2)),
                                ],
                              ),
                            ),
                          ),

                        // 大模型实时输出区域
                        if (_usingLlm && _llmOutput != null) ...[
                          if (widget.clue.aiAnalysisTime != null &&
                              _llmOutput == widget.clue.aiAnalysisReport)
                            Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8F5E9),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                    color: const Color(0xFFC8E6C9)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.history,
                                      size: 16, color: Color(0xFF2E7D32)),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      '已秒开加载历史诊断 (${DateFormat("yyyy.MM.dd HH:mm").format(widget.clue.aiAnalysisTime!)}) · 若学员有新回访进展可点右上角 🔄 重新分析',
                                      style: const TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF1B5E20)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          _LlmReportCard(output: _llmOutput!),
                          const SizedBox(height: 14),
                        ],

                        // 意向评分卡
                        _ScoreCard(
                            score: _result!.score,
                            level: _result!.scoreLevel),
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
                                .map((p) => Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 6),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text('• ',
                                              style: TextStyle(
                                                  color: Color(0xFF1976D2),
                                                  fontWeight:
                                                      FontWeight.bold)),
                                          Expanded(
                                            child: Text(
                                              p,
                                              style: const TextStyle(
                                                  fontSize: 13.5,
                                                  color: Color(0xFF333333)),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ))
                                .toList(),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // 2. 核心顾虑分析
                        _AnalysisCard(
                          number: '2',
                          title: '核心抗拒点与心理顾虑',
                          icon: Icons.psychology_outlined,
                          color: const Color(0xFFE65100),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: _result!.concerns
                                .map((c) => Container(
                                      margin: const EdgeInsets.only(bottom: 8),
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFFF3E0),
                                        borderRadius:
                                            BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        c,
                                        style: const TextStyle(
                                            fontSize: 13,
                                            color: Color(0xFF5D4037),
                                            height: 1.4),
                                      ),
                                    ))
                                .toList(),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // 3. 专属定制话术
                        _AnalysisCard(
                          number: '3',
                          title: '专属推荐沟通话术',
                          icon: Icons.chat_outlined,
                          color: const Color(0xFF2E7D32),
                          action: ElevatedButton.icon(
                            onPressed: () {
                              Clipboard.setData(
                                  ClipboardData(text: _result!.script));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('已复制推荐话术到剪贴板！'),
                                  backgroundColor: Color(0xFF2E7D32),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            },
                            icon: const Icon(Icons.copy, size: 14),
                            label: const Text('一键复制'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2E7D32),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              textStyle: const TextStyle(fontSize: 12),
                            ),
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F5E9),
                              borderRadius: BorderRadius.circular(8),
                              border:
                                  Border.all(color: const Color(0xFFC8E6C9)),
                            ),
                            child: Text(
                              _result!.script,
                              style: const TextStyle(
                                fontSize: 13.5,
                                color: Color(0xFF1B5E20),
                                height: 1.5,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),

                // 底部操作栏
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 10,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _saveToTimeline,
                          icon: Icon(
                            _saved
                                ? Icons.check_circle
                                : Icons.bookmark_add_outlined,
                            color: _saved
                                ? Colors.green
                                : const Color(0xFF7B1FA2),
                          ),
                          label: Text(
                            _saved ? '已存入时间轴' : '沉淀到档案时间轴',
                            style: TextStyle(
                              color: _saved
                                  ? Colors.green
                                  : const Color(0xFF7B1FA2),
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding:
                                const EdgeInsets.symmetric(vertical: 12),
                            side: BorderSide(
                              color: _saved
                                  ? Colors.green
                                  : const Color(0xFF7B1FA2),
                            ),
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

/// 大模型生成的 Markdown 富文本报告卡片
class _LlmReportCard extends StatelessWidget {
  final String output;
  const _LlmReportCard({required this.output});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: const Color(0xFF7B1FA2).withValues(alpha: 0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7B1FA2).withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF7B1FA2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.psychology, size: 15, color: Colors.white),
                    SizedBox(width: 4),
                    Text(
                      'DeepSeek 实时深度诊断',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: output));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('已复制完整大模型诊断与逼单方案！'),
                      backgroundColor: Color(0xFF7B1FA2),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                icon: const Icon(Icons.copy_all, size: 14),
                label: const Text('复制方案', style: TextStyle(fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7B1FA2),
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SelectableText(
            output,
            style: const TextStyle(
              fontSize: 13.5,
              color: Color(0xFF263238),
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

class _ScoreCard extends StatelessWidget {
  final int score;
  final String level;
  const _ScoreCard({required this.score, required this.level});

  @override
  Widget build(BuildContext context) {
    final color = score >= 80
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
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 68,
                height: 68,
                child: CircularProgressIndicator(
                  value: score / 100,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  strokeWidth: 7,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$score',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  const Text('意向分',
                      style: TextStyle(fontSize: 10, color: Colors.grey)),
                ],
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '综合成交意向指数',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C3E50),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    level,
                    style: TextStyle(
                      fontSize: 12,
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  '基于跟进频次、沟通意愿、抗拒阻力等全景因子计算',
                  style: TextStyle(fontSize: 11, color: Colors.grey),
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
  final Widget child;
  final Widget? action;

  const _AnalysisCard({
    required this.number,
    required this.title,
    required this.icon,
    required this.color,
    required this.child,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
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
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    number,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C3E50),
                  ),
                ),
              ),
              if (action != null) action!,
            ],
          ),
          const Divider(height: 20),
          child,
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
