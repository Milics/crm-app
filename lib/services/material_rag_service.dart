import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/material_item.dart';
import 'ai_service.dart';

/// 物料 AI 问答助教生成结果模型
class MaterialAiResult {
  final String userQuestion;
  final String analysis; // 🎯 学员心理透视与核心破局点
  final String recommendedReply; // 💬 顾问推荐直接回复话术（可一键发送）
  final String followUpAction; // 💡 下一步跟进动作建议
  final List<TextMaterial> matchedMaterials; // 引用物料来源
  final bool isAiGenerated; // true: 云端/本地大模型实时生成, false: 本地知识库高可用合成
  final DateTime createdAt;

  MaterialAiResult({
    required this.userQuestion,
    required this.analysis,
    required this.recommendedReply,
    required this.followUpAction,
    required this.matchedMaterials,
    required this.isAiGenerated,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();
}

/// 专升本机构物料知识库智能检索 (RAG) 与问答服务
class MaterialRagService {
  static final MaterialRagService _instance = MaterialRagService._internal();
  factory MaterialRagService() => _instance;
  MaterialRagService._internal();

  /// 专升本业务高频关键词与意图映射字典
  static final Map<String, List<String>> _intentSynonyms = {
    '英语': ['英语', '高数', '数学', '公共课', '单词', '语法', '分值', '及格'],
    '基础差': ['基础差', '30分', '三十分', '底子薄', '自卑', '学不会', '零基础', '初中水平', '高中没学好', '高考分低', '挂科'],
    '学费': ['学费', '贵', '多少钱', '价格', '收费', '便宜', '省钱', '分期', '性价比', '自己学', '自学'],
    '公办': ['公办', '民办', '二本', '一本', '大学', '录取率', '报录比', '省控线', '校线', '名额', '专业对照表'],
    '集训营': ['集训', '封闭', '走读', '班型', '宿舍', '住宿', '作息', '管得严', '手机', '自律', '双师', '督学'],
    '大二': ['大二', '大一', '大三', '早', '太早', '等等', '明年', '实习', '时间不够', '冲突'],
    '试听': ['试听', '公开课', '体验', '看看', '听一下', '现场', '参观', '测评'],
    '逼单': ['定金', '预定', '早鸟', '优惠', '床位', '名额', '截止', '报名', '最后'],
    '案例': ['逆袭', '学长', '学姐', '考上', '上岸', '考研', '事业编', '公务员'],
  };

  /// 智能检索物料库中最契合的 Top K 篇物料
  List<TextMaterial> retrieveRelevantMaterials(
    String question,
    List<TextMaterial> pool, {
    int topK = 4,
  }) {
    if (pool.isEmpty) return [];

    final cleanQ = question.trim().toLowerCase();
    if (cleanQ.isEmpty) {
      return pool.take(topK).toList();
    }

    // 1. 识别意图与分词
    final matchedKeywords = <String>{};
    for (final entry in _intentSynonyms.entries) {
      for (final kw in entry.value) {
        if (cleanQ.contains(kw.toLowerCase())) {
          matchedKeywords.add(kw.toLowerCase());
          matchedKeywords.add(entry.key.toLowerCase());
        }
      }
    }

    // 补充常规切分词（长度 >= 2）
    final regex = RegExp(r'[\u4e00-\u9fa5a-zA-Z0-9]{2,}');
    for (final m in regex.allMatches(cleanQ)) {
      matchedKeywords.add(m.group(0)!);
    }

    // 2. 对物料库每篇物料计算相关度得分
    final scoredList = <MapEntry<TextMaterial, double>>[];

    for (final mat in pool) {
      double score = 0.0;
      final title = mat.title.toLowerCase();
      final category = mat.category.toLowerCase();
      final content = mat.content.toLowerCase();

      // 关键词命中权重
      for (final kw in matchedKeywords) {
        if (title.contains(kw)) score += 8.0;
        if (category.contains(kw)) score += 6.0;
        if (content.contains(kw)) score += 3.0;
      }

      // 意图分类强化
      if (cleanQ.contains('差') || cleanQ.contains('不会') || cleanQ.contains('贵') || cleanQ.contains('自学')) {
        if (category.contains('痛点') || category.contains('异议')) score += 10.0;
      }
      if (cleanQ.contains('公办') || cleanQ.contains('民办') || cleanQ.contains('专业') || cleanQ.contains('政策')) {
        if (category.contains('政策') || category.contains('规划')) score += 10.0;
      }
      if (cleanQ.contains('集训') || cleanQ.contains('班') || cleanQ.contains('宿舍') || cleanQ.contains('作息')) {
        if (category.contains('课程') || category.contains('班型')) score += 10.0;
      }
      if (cleanQ.contains('试听') || cleanQ.contains('体验') || cleanQ.contains('看')) {
        if (category.contains('试听') || category.contains('到校')) score += 10.0;
      }
      if (cleanQ.contains('优惠') || cleanQ.contains('定金') || cleanQ.contains('床位') || cleanQ.contains('报名')) {
        if (category.contains('促单') || category.contains('特惠')) score += 10.0;
      }
      if (cleanQ.contains('案例') || cleanQ.contains('学长') || cleanQ.contains('学姐') || cleanQ.contains('逆袭')) {
        if (category.contains('案例') || category.contains('口碑')) score += 10.0;
      }

      if (score > 0) {
        scoredList.add(MapEntry(mat, score));
      }
    }

    // 3. 排序并截取 Top K
    if (scoredList.isNotEmpty) {
      scoredList.sort((a, b) => b.value.compareTo(a.value));
      return scoredList.take(topK).map((e) => e.key).toList();
    }

    // 无明显命中时，保底匹配第一类“初次接触”或前几篇物料
    return pool.take(min(topK, pool.length)).toList();
  }

  /// 顾问提问答疑主入口：双模式保障（在线大模型 + 本地规则高可用降级）
  Future<MaterialAiResult> generateAnswer({
    required String question,
    required List<TextMaterial> materialsPool,
  }) async {
    final cleanQ = question.trim();
    if (cleanQ.isEmpty) {
      throw Exception('请输入学员的问题或沟通卡点');
    }

    // 1. 先从物料库检索最相关的物料
    final relevantMaterials = retrieveRelevantMaterials(cleanQ, materialsPool, topK: 4);

    // 2. 判断是否具备大模型在线环境
    final aiService = AiService();
    await aiService.init();

    if (aiService.isConfigured) {
      try {
        final result = await _callLlmWithRag(cleanQ, relevantMaterials);
        if (result != null) {
          return result;
        }
      } catch (e) {
        debugPrint('⚠️ 大模型问答调用异常，自动降级为本地智能物料生成引擎: $e');
      }
    }

    // 3. 优雅降级：本地高可用物料智能提炼引擎（零配置/离线 100% 可用）
    return _generateLocalFallback(cleanQ, relevantMaterials);
  }

  /// 在线大模型 RAG 生成
  Future<MaterialAiResult?> _callLlmWithRag(
    String question,
    List<TextMaterial> contextMaterials,
  ) async {
    final aiService = AiService();

    final buffer = StringBuffer();
    buffer.writeln('【学员提问 / 顾问沟通阻碍】：$question\n');
    buffer.writeln('【我们机构现有的权威官方物料与标准话术库（共 ${contextMaterials.length} 篇参考）】：');

    for (int i = 0; i < contextMaterials.length; i++) {
      final m = contextMaterials[i];
      buffer.writeln('----- 参考物料 ${i + 1} -----');
      buffer.writeln('【标题】：${m.title} (分类: ${m.category})');
      buffer.writeln('【权威话术与事实论据】：\n${m.content}\n');
    }

    buffer.writeln('【任务要求】：');
    buffer.writeln('请作为专升本资深销售总监，充分吸收上述参考物料中的真实政策数据、课程优势与实操论点，针对学员问题生成高质量的指导与话术。');
    buffer.writeln('必须严格输出以下三个版块（请务必保留 ### 标题格式，以便系统解析）：');
    buffer.writeln('### 🎯 学员心理透视与核心破局点');
    buffer.writeln('(深度剖析学员提出此问题背后的真实心理：如自卑借口、认知偏差、怕花冤枉钱等，指出顾问本轮沟通的核心心法)');
    buffer.writeln('### 💬 推荐直接回复话术（可一键发给学员）');
    buffer.writeln('(结合参考物料提炼成一段口语化、真诚、有说服力的微信回复，直击痛点，可直接复制发送)');
    buffer.writeln('### 💡 下一步跟进动作建议');
    buffer.writeln('(指导顾问发完此话术后，怎样通过发资料、约试听或锁床位推进成单)');

    const systemPrompt =
        '你是一位深耕统招专升本招生10年的金牌咨询总监。擅长基于机构真实物料库，给出极具同理心与成交说服力的话术。';

    final output = await aiService.chatWithCustomPrompt(
      systemPrompt: systemPrompt,
      userPrompt: buffer.toString(),
      temperature: 0.65,
    );

    // 解析结构化输出
    String analysis = '';
    String reply = '';
    String action = '';

    if (output.contains('### 🎯 学员心理透视与核心破局点') || output.contains('### 💬 推荐直接回复话术')) {
      final parts = output.split(RegExp(r'###\s*'));
      for (final part in parts) {
        if (part.contains('学员心理透视') || part.contains('核心破局点')) {
          analysis = part.replaceFirst(RegExp(r'.*?\n'), '').trim();
        } else if (part.contains('推荐直接回复话术')) {
          reply = part.replaceFirst(RegExp(r'.*?\n'), '').trim();
        } else if (part.contains('下一步跟进动作建议')) {
          action = part.replaceFirst(RegExp(r'.*?\n'), '').trim();
        }
      }
    }

    if (reply.isEmpty) {
      reply = output.trim();
    }
    if (analysis.isEmpty) {
      analysis = '学员对专升本关键考情与机构优势存在认知差，需要用权威论据与同理心重塑信心。';
    }
    if (action.isEmpty) {
      action = '发送后紧跟一份对应的专属专业备考资料或试听预约链接，引导进一步锁定。';
    }

    return MaterialAiResult(
      userQuestion: question,
      analysis: analysis,
      recommendedReply: reply,
      followUpAction: action,
      matchedMaterials: contextMaterials,
      isAiGenerated: true,
    );
  }

  /// 本地智能高可用合成引擎（零配置/离线兜底，基于物料库结构化组合）
  MaterialAiResult _generateLocalFallback(
    String question,
    List<TextMaterial> materials,
  ) {
    if (materials.isEmpty) {
      return MaterialAiResult(
        userQuestion: question,
        analysis: '学员正处于专升本政策了解初期，对备考方向尚不明晰。',
        recommendedReply: '同学你好呀！统招专升本是人生唯一一次获得全日制第一学历本科的机会。目前你的专业能报考哪些本科院校对照表我已经整理好了，发你一份参考评估～',
        followUpAction: '索要专业与大几信息，发送院校对照表建立连接。',
        matchedMaterials: [],
        isAiGenerated: false,
      );
    }

    final topMat = materials.first;
    final otherMats = materials.skip(1).take(2).toList();

    // 智能分析心理
    String analysis = '【基于机构物料知识库精准匹配】学员提出“$question”，核心根源在于对政策或自身学习能力存在顾虑。在跟进时切忌空洞打鸡血，应以【${topMat.category}】为支点，拿出具体数据和解决方案消除顾虑。';
    if (question.contains('英语') || question.contains('30') || question.contains('差') || question.contains('不会')) {
      analysis = '【学员心理透视】学员并非不想升本，而是对基础薄弱（尤其英语/数学）产生逃避与畏难自卑心理，担心报班白花钱。必须用“专升本应试技巧不同于高考”降低心理门槛。';
    } else if (question.contains('贵') || question.contains('学费') || question.contains('自学')) {
      analysis = '【学员心理透视】学员对投入产出比存疑，对自学抱有侥幸心理。破局点在于帮他算“公办 vs 民办本科的学费差额账”，自学考不上民办一年学费2.5万起，考上公办立省4-5万！';
    } else if (question.contains('大二') || question.contains('早') || question.contains('等等')) {
      analysis = '【学员心理透视】学员存在拖延和观望心理。核心破局点在于点破“大二打底、大三冲刺”的黄金备考节奏，大三再学不仅时间不够，还要面对实习压力。';
    }

    // 智能拼装回复话术
    final replyBuffer = StringBuffer();
    replyBuffer.writeln(topMat.content.trim());

    // 智能建议动作
    String action = '发送该话术后，立即为学员推荐《${topMat.title}》相关配套资料，并锁定本周末的学情诊断或名师试听名额。';
    if (otherMats.isNotEmpty) {
      action += ' 若学员进一步追问，可联动参考物料《${otherMats.first.title}》继续跟进。';
    }

    return MaterialAiResult(
      userQuestion: question,
      analysis: analysis,
      recommendedReply: replyBuffer.toString(),
      followUpAction: action,
      matchedMaterials: materials,
      isAiGenerated: false,
    );
  }
}
