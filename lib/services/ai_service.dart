import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/clue.dart';
import 'crm_sync_service.dart';

/// AI 大模型咨询服务（支持云端中枢统一托管托管 + 客户端直连双模式）
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
  bool _cloudConfigured = false;

  String get apiKey => _apiKey;
  String get baseUrl => _baseUrl;
  String get model => _model;

  /// 是否具备可用的大模型配置（云端已托管，或本地已配置）
  bool get isConfigured => _cloudConfigured || _apiKey.trim().isNotEmpty;
  bool get isCloudManaged => _cloudConfigured;

  /// 初始化并自动探活云端中枢的 AI 配置
  Future<void> init() async {
    if (!_isLoaded) {
      final prefs = await SharedPreferences.getInstance();
      _apiKey = prefs.getString('crm_ai_api_key') ?? '';
      _baseUrl = prefs.getString('crm_ai_base_url') ?? _defaultBaseUrl;
      _model = prefs.getString('crm_ai_model') ?? _defaultModel;
      _isLoaded = true;
    }

    // 探活云端同步中枢是否已由超管托管了 Key
    await checkCloudAiStatus();
  }

  /// 探活云端中枢的 AI 状态
  Future<bool> checkCloudAiStatus() async {
    try {
      final sync = CrmSyncService();
      final url = '${sync.serverUrl}/api/ai/config';
      final resp = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 4));
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        _cloudConfigured = data['configured'] == true;
        if (data['model'] != null && data['model'].toString().isNotEmpty) {
          _model = data['model'];
        }
        return _cloudConfigured;
      }
    } catch (_) {}
    return false;
  }

  /// 保存 AI 配置（超管在任一客户端设置后，自动同步至云端中枢，全员免配置即用）
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

    // 同步给云端中枢服务端托管，让其他顾问直接开箱即用
    try {
      final sync = CrmSyncService();
      final url = '${sync.serverUrl}/api/ai/config';
      final resp = await http
          .post(
            Uri.parse(url),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'apiKey': _apiKey,
              'baseUrl': _baseUrl,
              'model': _model,
            }),
          )
          .timeout(const Duration(seconds: 5));
      if (resp.statusCode == 200) {
        _cloudConfigured = _apiKey.isNotEmpty;
      }
    } catch (e) {
      debugPrint('⚠️ 上传 AI 配置到云端失败: $e');
    }
  }

  /// 调用大模型（优先使用云端中枢统一代理，兼具安全性与全员免配）
  Future<String> analyzeClue(Clue clue) async {
    await init();
    if (!isConfigured) {
      throw Exception('云端中枢与本地均尚未配置 DeepSeek Key，请联系超级管理员在设置中统一录入');
    }

    final userPrompt = _buildPrompt(clue);
    const systemPrompt =
        '你是一位拥有10年经验的统招专升本招生金牌销售总监。擅长精准挖掘学生心理顾虑与阻碍，并给出极具杀伤力的实战促单逼单话术。';

    // 1. 优先走云端中枢托管模式（普通顾问手机零配置，直接可用）
    if (_cloudConfigured) {
      try {
        final sync = CrmSyncService();
        final url = '${sync.serverUrl}/api/ai/analyze';
        final resp = await http
            .post(
              Uri.parse(url),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({
                'systemPrompt': systemPrompt,
                'userPrompt': userPrompt,
              }),
            )
            .timeout(const Duration(seconds: 50));

        if (resp.statusCode == 200) {
          final data = jsonDecode(utf8.decode(resp.bodyBytes));
          if (data['success'] == true && data['output'] != null) {
            return data['output'].toString();
          } else {
            throw Exception(data['error'] ?? '云端 AI 服务返回异常');
          }
        } else {
          final data = jsonDecode(utf8.decode(resp.bodyBytes));
          throw Exception(data['error'] ?? '云端返回状态码 ${resp.statusCode}');
        }
      } catch (e) {
        debugPrint('⚠️ 云端代理调用失败，尝试本地直连: $e');
        if (_apiKey.isEmpty) rethrow;
      }
    }

    // 2. 本地直连模式（当本地填有 Key 时的备选方案）
    if (_apiKey.isNotEmpty) {
      final cleanUrl = _baseUrl.endsWith('/v1')
          ? '$_baseUrl/chat/completions'
          : '$_baseUrl/v1/chat/completions';

      final body = {
        'model': _model,
        'messages': [
          {'role': 'system', 'content': systemPrompt},
          {'role': 'user', 'content': userPrompt},
        ],
        'temperature': 0.7,
      };

      final response = await http
          .post(
            Uri.parse(cleanUrl),
            headers: {
              'Content-Type': 'application/json; charset=utf-8',
              'Authorization': 'Bearer $_apiKey',
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 40));

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return data['choices'][0]['message']['content'] as String;
      } else {
        throw Exception('DeepSeek API 请求失败 (${response.statusCode}): ${response.body}');
      }
    }

    throw Exception('无法发起大模型分析');
  }

  /// 构造专升本领域实战 Prompt
  String _buildPrompt(Clue clue) {
    final buffer = StringBuffer();
    buffer.writeln('【学员档案基本信息】');
    buffer.writeln('• 称呼: ${clue.wxNick}');
    buffer.writeln('• 就读专科院校: ${clue.school.isEmpty ? "未知" : clue.school}');
    buffer.writeln('• 年级届别: ${clue.grade.isEmpty ? "在读大专生" : clue.grade}');
    buffer.writeln('• 目标报考专业: ${clue.subject.isEmpty ? "专升本待定" : clue.subject}');
    buffer.writeln('• 意向班型: ${clue.classType.isEmpty ? "集训班" : clue.classType}');
    buffer.writeln('• 当前跟进状态: ${clue.status.label}');
    buffer.writeln('• 意向热度等级: ${clue.intentLevel.label}');
    buffer.writeln('• 渠道来源: ${clue.source.isEmpty ? "其他" : clue.source}');
    buffer.writeln(
        '• 已打标签/学员画像: ${clue.tags.isEmpty ? "无" : clue.tags.join("、")}');
    buffer.writeln('• 咨询师跟进备注: ${clue.remark.isEmpty ? "无" : clue.remark}');

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

    if (clue.chatRecords.isNotEmpty) {
      buffer.writeln('\n【微信聊天截图提炼核心卡点 (共 ${clue.chatRecords.length} 条)】');
      for (final rec in clue.chatRecords) {
        if (rec.ocrText.isNotEmpty) {
          buffer.writeln('• 对话要点: ${rec.ocrText}');
        }
      }
    }

    buffer.writeln('\n【请按照以下4大模块提供专业且极具实战价值的指导方案】：');
    buffer.writeln('### 1. 🎯 学员心理与成交痛点诊断');
    buffer.writeln('（深度剖析其内心的真实担忧、决策迟疑点与目前的核心成交阻力）');
    buffer.writeln('### 2. 🔑 本次跟进破局切入点');
    buffer.writeln('（明确顾问今天应该用什么借口/话题去找他，怎样切入不会显得死缠烂打）');
    buffer.writeln('### 3. 💬 3组实战促单逼单话术（可直接一键复制发送给学生）');
    buffer.writeln('• 【话术一 · 价值破冰】：（发送真题资料包/名校录取考情/避坑指南）');
    buffer.writeln('• 【话术二 · 痛点化解】：（专门化解其最担心的问题，如高数基础差/学费分期/时间不够）');
    buffer.writeln('• 【话术三 · 限时逼单】：（制造名额紧迫感/早鸟优惠截止/锁定名师席位促成定金）');
    buffer.writeln('### 4. ⚠️ 顾问沟通致命禁忌提醒');
    buffer.writeln('（提醒顾问在此类学员面前绝对不能说的1~2句雷区话）');

    return buffer.toString();
  }
}
