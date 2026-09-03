import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/clue.dart';

/// AI 大模型咨询服务（支持 DeepSeek / 智谱 / OpenAI 兼容协议）
class AiService {
  static final AiService _instance = AiService._internal();
  factory AiService() => _instance;
  AiService._internal();

  static const String _defaultBaseUrl = 'https://api.deepseek.com/v1';
  static const String _defaultModel = 'deepseek-chat';

  String _apiKey = '';
  String _baseUrl = _defaultBaseUrl;
  String _model = _defaultModel;
  bool _isLoaded = false;

  String get apiKey => _apiKey;
  String get baseUrl => _baseUrl;
  String get model => _model;
  bool get isConfigured => _apiKey.trim().isNotEmpty;

  /// 初始化配置
  Future<void> init() async {
    if (_isLoaded) return;
    final prefs = await SharedPreferences.getInstance();
    _apiKey = prefs.getString('crm_ai_api_key') ?? '';
    _baseUrl = prefs.getString('crm_ai_base_url') ?? _defaultBaseUrl;
    _model = prefs.getString('crm_ai_model') ?? _defaultModel;
    _isLoaded = true;
  }

  /// 保存 AI 配置
  Future<void> saveSettings({
    required String apiKey,
    String? baseUrl,
    String? model,
  }) async {
    _apiKey = apiKey.trim();
    _baseUrl = (baseUrl != null && baseUrl.trim().isNotEmpty)
        ? baseUrl.trim().replaceAll(RegExp(r'/+$'), '')
        : _defaultBaseUrl;
    _model = (model != null && model.trim().isNotEmpty)
        ? model.trim()
        : _defaultModel;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('crm_ai_api_key', _apiKey);
    await prefs.setString('crm_ai_base_url', _baseUrl);
    await prefs.setString('crm_ai_model', _model);
  }

  /// 调用真实大模型进行专升本学员深度诊断与专属话术生成
  Future<String> analyzeClue(Clue clue) async {
    await init();
    if (!isConfigured) {
      throw Exception('未配置 AI API Key，请先点击右上角设置配置 DeepSeek API Key');
    }

    final prompt = _buildPrompt(clue);

    final cleanUrl = _baseUrl.endsWith('/v1')
        ? '$_baseUrl/chat/completions'
        : '$_baseUrl/v1/chat/completions';

    final body = {
      'model': _model,
      'messages': [
        {
          'role': 'system',
          'content':
              '你是一名拥有10年丰富经验的顶级统招专升本招生咨询专家及销售督导。'
              '你精通专科生的备考心理（如基础差信心不足、迷茫拖延、备考时间紧张、家长干预、价格敏感、担心考不上等）。'
              '请根据提供的学员基本信息、历史回访轨迹和聊天顾虑，输出结构清晰、一针见血、具有实战杀伤力的学员诊断和沟通话术。'
              '使用清晰的 Markdown 格式输出，突出重点。',
        },
        {
          'role': 'user',
          'content': prompt,
        }
      ],
      'temperature': 0.7,
      'max_tokens': 1500,
    };

    try {
      final res = await http
          .post(
            Uri.parse(cleanUrl),
            headers: {
              'Content-Type': 'application/json; charset=utf-8',
              'Authorization': 'Bearer $_apiKey',
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 40));

      if (res.statusCode == 200) {
        final data = jsonDecode(utf8.decode(res.bodyBytes));
        final choices = data['choices'] as List<dynamic>?;
        if (choices != null && choices.isNotEmpty) {
          final content = choices[0]['message']['content'] as String?;
          if (content != null && content.trim().isNotEmpty) {
            return content.trim();
          }
        }
        throw Exception('大模型未返回有效文本内容');
      } else {
        final errBody = utf8.decode(res.bodyBytes);
        debugPrint('⚠️ [AiService] 接口请求失败 (${res.statusCode}): $errBody');
        throw Exception('接口请求错误 (${res.statusCode})：$errBody');
      }
    } catch (e) {
      debugPrint('⚠️ [AiService] 调用异常: $e');
      rethrow;
    }
  }

  /// 构造富文本上下文 Prompt
  String _buildPrompt(Clue clue) {
    final buffer = StringBuffer();
    buffer.writeln('【学员基本档案】');
    buffer.writeln('- 微信昵称/姓名: ${clue.wxNick.isEmpty ? "未留名" : clue.wxNick}');
    buffer.writeln('- 就读学校: ${clue.school.isEmpty ? "专科在读" : clue.school}');
    buffer.writeln('- 年级届别: ${clue.grade.isEmpty ? "在读" : clue.grade}');
    buffer.writeln('- 报考科目/专业: ${clue.subject.isEmpty ? "专升本考试" : clue.subject}');
    buffer.writeln('- 意向班型: ${clue.classType.isEmpty ? "集训班" : clue.classType}');
    buffer.writeln('- 来源渠道: ${clue.source.isEmpty ? "自然咨询" : clue.source}');
    buffer.writeln('- 当前跟进状态: ${clue.status.label}');
    buffer.writeln('- 意向等级: ${clue.intentLevel.label}');
    if (clue.tags.isNotEmpty) {
      buffer.writeln('- 关键标签: ${clue.tags.join("、")}');
    }
    if (clue.remark.isNotEmpty) {
      buffer.writeln('- 咨询师初始备注: ${clue.remark}');
    }

    buffer.writeln('\n【历史跟进与回访轨迹 (共 ${clue.visitLogs.length} 次)】');
    if (clue.visitLogs.isEmpty) {
      buffer.writeln('（目前暂无深度回访记录，仅为初次接触）');
    } else {
      for (int i = 0; i < clue.visitLogs.length; i++) {
        final log = clue.visitLogs[i];
        final timeStr = log.createTime.toIso8601String().substring(0, 10);
        buffer.writeln(
            '第 ${i + 1} 次 ($timeStr - ${log.contactMethod.label} - 结果:${log.visitResult.label}):');
        buffer.writeln('  沟通实录: ${log.visitContent}');
        if (log.concerns.isNotEmpty) {
          buffer.writeln('  核心顾虑: ${log.concerns.join("、")}');
        }
      }
    }

    buffer.writeln('\n【请按照以下4大模块提供专业且极具实战价值的指导方案】：');
    buffer.writeln('### 1. 🎯 学员心理与成交痛点诊断');
    buffer.writeln('（分析其内心的真实担忧、决策迟疑点与目前成交阻力）');
    buffer.writeln('### 2. 🔑 本次跟进破局切入点');
    buffer.writeln('（给出精准建议，如：应从哪个话题破冰，如何建立权威与信任）');
    buffer.writeln('### 3. 💬 定制化跟进/逼单话术（提供 3 组真实可用话术，标注【话术一】、【话术二】、【话术三】）');
    buffer.writeln('- **【话术一：共情关怀与痛点激发】**（适用于发微信开启话题，降低防备）');
    buffer.writeln('- **【话术二：专业方案与成功案例赋能】**（消除对学习难度或机构师资的疑虑）');
    buffer.writeln('- **【话术三：临门一脚促定/逼单】**（制造紧迫感，促成试听或锁定名额报名）');
    buffer.writeln('### 4. ⚠️ 禁忌提醒');
    buffer.writeln('（告知咨询师哪些话绝对不能对该学员说，避免踩雷断联）');

    return buffer.toString();
  }
}
