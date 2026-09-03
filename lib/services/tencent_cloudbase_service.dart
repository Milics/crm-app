import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/clue.dart';
import '../models/material_item.dart';

/// 腾讯云开发 CloudBase 国内极速直连数据同步服务
class TencentCloudBaseService {
  static final TencentCloudBaseService _instance =
      TencentCloudBaseService._internal();
  factory TencentCloudBaseService() => _instance;
  TencentCloudBaseService._internal();

  static const String envId = 'crm-app-d6g1yyfhj5f8cff07';
  static const String region = 'ap-shanghai';
  static const String accessKey =
      'eyJhbGciOiJSUzI1NiIsImtpZCI6IjliODY1MDFjLTYwZGQtNGI1Yi1hZTYwLWNkMDNjY2M4ZmFjNiJ9.eyJpc3MiOiJodHRwczovL2NybS1hcHAtZDZnMXl5ZmhqNWY4Y2ZmMDcuYXAtc2hhbmdoYWkudGNiLWFwaS50ZW5jZW50Y2xvdWRhcGkuY29tIiwic3ViIjoiYW5vbiIsImF1ZCI6ImNybS1hcHAtZDZnMXl5ZmhqNWY4Y2ZmMDciLCJleHAiOjQwOTE4NzQ1MTksImlhdCI6MTc4ODE5MTMxOSwibm9uY2UiOiJwcHlQRU83Y1RtdWlDb18zUWhVM2VBIiwiYXRfaGFzaCI6InBweVBFTzdjVG11aUNvXzNRaFUzZUEiLCJuYW1lIjoiQW5vbnltb3VzIiwic2NvcGUiOiJhbm9ueW1vdXMiLCJwcm9qZWN0X2lkIjoiY3JtLWFwcC1kNmcxeXlmaGo1ZjhjZmYwNyIsIm1ldGEiOnsicGxhdGZvcm0iOiJQdWJsaXNoYWJsZUtleSJ9LCJyb2xlIjoiYW5vbiIsImlzX2Fub255bW91cyI6dHJ1ZSwiYXBwX21ldGFkYXRhIjp7InByb3ZpZGVyIjoiYW5vbnltb3VzIiwicHJvdmlkZXJzIjpbImFub255bW91cyJdfSwidXNlcl9tZXRhZGF0YSI6eyJuYW1lIjoiQW5vbnltb3VzIn0sInVzZXJfdHlwZSI6IiIsImNsaWVudF90eXBlIjoiY2xpZW50X3VzZXIiLCJpc19zeXN0ZW1fYWRtaW4iOmZhbHNlfQ.Y8xXjpyVU79cfuqmhmal08AqAcHzfSfvbQQM4JXHGvPnknq6EeCN8TxaYJy96y7jfTBZxZoWFeRtph-lTA5zUWVDtLqsLikLMbKi68Z4jZxFGDC9wjZvpUEVYeWYLQZ1CPFeOdbK5st46ghOlqkW_MEYQJCUbPaZWaK2nR1VmG_rl-6Lm4J4ReOESQJYrS95Heau__DkyWg9QJfaihyHyH3jaWuRkreQ4xQNpHWNVKtr1UsbNIEDQCZQVwyDO6yGWbmKV88JCfDxsFLLh2u2TTXzjm70Gj8Cu7Cx6J2ihTiKYvfU7QHsWDuncAndi2iK4TW3po5hqv-QvxC6xixmOw';

  // 腾讯云 PostgREST / REST 接口基地址
  static const String baseUrl =
      'https://$envId.$region.tcb-api.tencentcloudapi.com';

  // 在 Web 环境下浏览器会触发 CORS 拦截，主同步走 Render 云中枢；移动端仍可正常备用
  bool get isAvailable => !kIsWeb;

  Map<String, String> get _headers => {
        'Authorization': 'Bearer $accessKey',
        'apikey': accessKey,
        'Content-Type': 'application/json',
        'Prefer': 'resolution=merge-duplicates,return=representation',
      };

  // ==================== 线索管理 ====================

  /// 从腾讯云获取所有线索
  Future<List<Clue>?> fetchAllClues() async {
    try {
      final url = Uri.parse('$baseUrl/rest/v1/crm_clues?select=*');
      final res = await http
          .get(url, headers: _headers)
          .timeout(const Duration(seconds: 6));

      if (res.statusCode == 200) {
        final list = jsonDecode(res.body) as List<dynamic>;
        final clues = list.map((item) {
          final map = Map<String, dynamic>.from(item);
          if (map.containsKey('data') && map['data'] is Map) {
            final data = Map<String, dynamic>.from(map['data']);
            data['id'] = map['id'] ?? data['id'];
            return Clue.fromJson(data);
          } else {
            return Clue.fromJson(map);
          }
        }).toList();
        debugPrint('🐧 [腾讯云开发] 成功获取 ${clues.length} 条线索');
        return clues;
      } else {
        debugPrint('⚠️ [腾讯云开发] 获取线索返回 ${res.statusCode}: ${res.body}');
        return null;
      }
    } catch (e) {
      debugPrint('⚠️ [腾讯云开发] 网络异常: $e');
      return null;
    }
  }

  /// 保存或更新单个线索到腾讯云
  Future<bool> saveClue(Clue clue) async {
    try {
      final url = Uri.parse('$baseUrl/rest/v1/crm_clues');
      final payload = {
        'id': clue.id,
        'data': clue.toJson(),
      };

      final res = await http
          .post(url, headers: _headers, body: jsonEncode(payload))
          .timeout(const Duration(seconds: 6));

      if (res.statusCode == 200 || res.statusCode == 201) {
        debugPrint('🐧 [腾讯云开发] 线索已成功保存到云端: ${clue.id} (${clue.wxNick})');
        return true;
      } else {
        debugPrint('⚠️ [腾讯云开发] 保存线索失败 (${res.statusCode}): ${res.body}');
        return false;
      }
    } catch (e) {
      debugPrint('⚠️ [腾讯云开发] 保存线索网络异常: $e');
      return false;
    }
  }

  /// 从腾讯云删除线索
  Future<bool> deleteClue(String clueId) async {
    try {
      final url = Uri.parse('$baseUrl/rest/v1/crm_clues?id=eq.$clueId');
      final res = await http
          .delete(url, headers: _headers)
          .timeout(const Duration(seconds: 6));
      return res.statusCode == 200 || res.statusCode == 204;
    } catch (e) {
      debugPrint('⚠️ [腾讯云开发] 删除线索异常: $e');
      return false;
    }
  }

  /// 批量上传线索
  Future<void> batchUploadClues(List<Clue> clues) async {
    if (clues.isEmpty) return;
    for (final c in clues) {
      await saveClue(c);
    }
  }

  // ==================== 物料管理 ====================

  Future<List<TextMaterial>?> fetchTextMaterials() async {
    try {
      final url = Uri.parse('$baseUrl/rest/v1/crm_text_materials?select=*');
      final res = await http
          .get(url, headers: _headers)
          .timeout(const Duration(seconds: 6));
      if (res.statusCode == 200) {
        final list = jsonDecode(res.body) as List<dynamic>;
        return list.map((e) => TextMaterial.fromJson(e['data'] ?? e)).toList();
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<void> saveTextMaterial(TextMaterial mat) async {
    try {
      final url = Uri.parse('$baseUrl/rest/v1/crm_text_materials');
      final payload = {'id': mat.id, 'data': mat.toJson()};
      await http.post(url, headers: _headers, body: jsonEncode(payload));
    } catch (_) {}
  }
}
