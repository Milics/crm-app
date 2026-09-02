import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/clue.dart';
import '../models/material_item.dart';

/// LeanCloud 国内免翻墙云端数据存储服务
class LeanCloudService {
  static final LeanCloudService _instance = LeanCloudService._internal();
  factory LeanCloudService() => _instance;
  LeanCloudService._internal();

  // LeanCloud 国内版应用凭证配置
  String _appId = '';
  String _appKey = '';
  String _serverUrl = '';

  bool _isConfigured = false;
  bool get isConfigured => _isConfigured;

  /// 初始化凭证
  void config({
    required String appId,
    required String appKey,
    required String serverUrl,
  }) {
    _appId = appId.trim();
    _appKey = appKey.trim();
    _serverUrl = serverUrl.trim();
    if (_serverUrl.endsWith('/')) {
      _serverUrl = _serverUrl.substring(0, _serverUrl.length - 1);
    }
    _isConfigured =
        _appId.isNotEmpty && _appKey.isNotEmpty && _serverUrl.isNotEmpty;
    if (_isConfigured) {
      debugPrint('🇨🇳 [LeanCloud] 国内免翻墙云端服务已配置成功: $_serverUrl');
    }
  }

  Map<String, String> get _headers => {
        'X-LC-Id': _appId,
        'X-LC-Key': _appKey,
        'Content-Type': 'application/json',
      };

  // ==================== 线索管理 ====================

  /// 从 LeanCloud 云端获取所有线索
  Future<List<Clue>?> fetchAllClues() async {
    if (!_isConfigured) return null;
    try {
      final url = Uri.parse(
          '$_serverUrl/1.1/classes/CrmClue?order=-createTime&limit=1000');
      final response = await http
          .get(url, headers: _headers)
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final results = data['results'] as List<dynamic>? ?? [];
        final list = results.map((item) {
          final map = Map<String, dynamic>.from(item);
          // 还原 id
          if (map['customId'] != null) {
            map['id'] = map['customId'];
          } else {
            map['id'] = map['objectId'];
          }
          return Clue.fromJson(map);
        }).toList();
        debugPrint('🇨🇳 [LeanCloud] 成功同步云端 ${list.length} 条线索');
        return list;
      } else {
        debugPrint('⚠️ [LeanCloud] 获取线索失败 (${response.statusCode}): ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('⚠️ [LeanCloud] 获取线索网络异常: $e');
      return null;
    }
  }

  /// 保存或更新单个线索到 LeanCloud
  Future<bool> saveClue(Clue clue) async {
    if (!_isConfigured) return false;
    try {
      // 1. 先查询云端是否存在该 customId 的记录
      final queryUrl = Uri.parse(
          '$_serverUrl/1.1/classes/CrmClue?where=${Uri.encodeComponent(jsonEncode({"customId": clue.id}))}');
      final queryRes = await http
          .get(queryUrl, headers: _headers)
          .timeout(const Duration(seconds: 6));

      final clueData = clue.toJson();
      clueData['customId'] = clue.id;

      if (queryRes.statusCode == 200) {
        final queryBody = jsonDecode(queryRes.body);
        final results = queryBody['results'] as List<dynamic>? ?? [];

        if (results.isNotEmpty) {
          // 已存在，执行 PUT 更新
          final objectId = results.first['objectId'];
          final updateUrl =
              Uri.parse('$_serverUrl/1.1/classes/CrmClue/$objectId');
          final updateRes = await http
              .put(updateUrl, headers: _headers, body: jsonEncode(clueData))
              .timeout(const Duration(seconds: 6));
          return updateRes.statusCode == 200;
        } else {
          // 不存在，执行 POST 创建
          final createUrl = Uri.parse('$_serverUrl/1.1/classes/CrmClue');
          final createRes = await http
              .post(createUrl, headers: _headers, body: jsonEncode(clueData))
              .timeout(const Duration(seconds: 6));
          return createRes.statusCode == 201;
        }
      }
      return false;
    } catch (e) {
      debugPrint('⚠️ [LeanCloud] 保存线索异常 (${clue.id}): $e');
      return false;
    }
  }

  /// 删除单个线索
  Future<bool> deleteClue(String clueId) async {
    if (!_isConfigured) return false;
    try {
      final queryUrl = Uri.parse(
          '$_serverUrl/1.1/classes/CrmClue?where=${Uri.encodeComponent(jsonEncode({"customId": clueId}))}');
      final queryRes = await http
          .get(queryUrl, headers: _headers)
          .timeout(const Duration(seconds: 6));

      if (queryRes.statusCode == 200) {
        final queryBody = jsonDecode(queryRes.body);
        final results = queryBody['results'] as List<dynamic>? ?? [];
        for (final item in results) {
          final objectId = item['objectId'];
          final delUrl = Uri.parse('$_serverUrl/1.1/classes/CrmClue/$objectId');
          await http
              .delete(delUrl, headers: _headers)
              .timeout(const Duration(seconds: 5));
        }
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('⚠️ [LeanCloud] 删除线索异常 ($clueId): $e');
      return false;
    }
  }

  /// 批量上传本地线索
  Future<void> batchUploadClues(List<Clue> clues) async {
    if (!_isConfigured || clues.isEmpty) return;
    for (final clue in clues) {
      await saveClue(clue);
    }
  }

  // ==================== 物料管理 ====================

  /// 获取文字物料
  Future<List<TextMaterial>?> fetchTextMaterials() async {
    if (!_isConfigured) return null;
    try {
      final url = Uri.parse(
          '$_serverUrl/1.1/classes/CrmTextMaterial?order=-createdAt&limit=500');
      final res = await http
          .get(url, headers: _headers)
          .timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final results = data['results'] as List<dynamic>? ?? [];
        return results.map((e) => TextMaterial.fromJson(e)).toList();
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// 保存文字物料
  Future<void> saveTextMaterial(TextMaterial mat) async {
    if (!_isConfigured) return;
    try {
      final url = Uri.parse('$_serverUrl/1.1/classes/CrmTextMaterial');
      final data = mat.toJson();
      data['customId'] = mat.id;
      await http.post(url, headers: _headers, body: jsonEncode(data));
    } catch (_) {}
  }
}
