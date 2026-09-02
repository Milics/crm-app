import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../models/clue.dart';
import '../models/app_user.dart';
import '../models/material_item.dart';

/// 智能多端同步服务（涵盖线索、员工账号、物料库全量双向同步）
class CrmSyncService {
  static final CrmSyncService _instance = CrmSyncService._internal();
  factory CrmSyncService() => _instance;
  CrmSyncService._internal();

  // 候选服务端点列表（涵盖云端域名、Mac 当前 IP、USB 端口映射、本机 Localhost 等）
  final List<String> _candidateUrls = [
    'https://crm-app-ojs3.onrender.com', // 🌟 用户专属云端 7x24 小时公网同步中枢
    'http://127.0.0.1:8888', // ADB reverse 端口映射 / 本机 Chrome
    'http://localhost:8888',
    'http://192.168.31.104:8888', // Mac 当前 Wi-Fi 局域网 IP
    'http://10.0.2.2:8888', // Android 模拟器访问宿主机
    'http://172.20.10.3:8888', // 备用手机热点 IP
  ];

  String? _customCloudUrl;
  String? get customCloudUrl => _customCloudUrl;

  String? _activeBaseUrl;
  String? get activeBaseUrl => _activeBaseUrl;
  bool get isConnected => _activeBaseUrl != null;

  /// 设置并保存自定义云端同步域名
  Future<bool> setCustomCloudUrl(String url) async {
    final cleanUrl = url.trim().replaceAll(RegExp(r'/+$'), '');
    _customCloudUrl = cleanUrl;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('crm_custom_server_url', cleanUrl);
    return await detectServer();
  }

  /// 自动探测可用端点（优先探测公网云端域名）
  Future<bool> detectServer() async {
    final prefs = await SharedPreferences.getInstance();
    _customCloudUrl = prefs.getString('crm_custom_server_url') ?? _customCloudUrl;

    final urlsToTest = <String>[];
    if (_customCloudUrl != null && _customCloudUrl!.isNotEmpty) {
      urlsToTest.add(_customCloudUrl!);
    }
    urlsToTest.addAll(_candidateUrls);

    for (final url in urlsToTest) {
      try {
        final res = await http
            .get(Uri.parse('$url/api/health'))
            .timeout(const Duration(milliseconds: 2500));
        if (res.statusCode == 200) {
          _activeBaseUrl = url;
          debugPrint('🟢 [CrmSync] 成功连通数据同步服务器: $_activeBaseUrl');
          return true;
        }
      } catch (_) {}
    }
    return false;
  }

  // ─────────────────────────────────────
  // 1. 员工账号同步 (Users)
  // ─────────────────────────────────────

  /// 获取云端所有员工账号
  Future<List<AppUser>?> fetchUsers() async {
    if (_activeBaseUrl == null) {
      final found = await detectServer();
      if (!found) return null;
    }

    try {
      final res = await http
          .get(Uri.parse('$_activeBaseUrl/api/users'))
          .timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final list = jsonDecode(res.body) as List<dynamic>;
        return list.map((e) => AppUser.fromJson(e)).toList();
      }
    } catch (e) {
      debugPrint('⚠️ [CrmSync] 拉取员工账号异常: $e');
      _activeBaseUrl = null;
    }
    return null;
  }

  /// 保存单个或批量员工账号到云端
  Future<bool> saveUsers(List<AppUser> users) async {
    if (users.isEmpty) return true;
    if (_activeBaseUrl == null) {
      final found = await detectServer();
      if (!found) return false;
    }

    try {
      final payload = users.map((u) => u.toJson()).toList();
      final res = await http
          .post(
            Uri.parse('$_activeBaseUrl/api/users'),
            headers: {'Content-Type': 'application/json; charset=utf-8'},
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 4));
      return res.statusCode == 200;
    } catch (e) {
      debugPrint('⚠️ [CrmSync] 保存员工账号异常: $e');
      _activeBaseUrl = null;
      return false;
    }
  }

  /// 删除单个员工账号
  Future<bool> deleteUser(String id) async {
    if (_activeBaseUrl == null) {
      final found = await detectServer();
      if (!found) return false;
    }

    try {
      final res = await http
          .delete(Uri.parse('$_activeBaseUrl/api/users/$id'))
          .timeout(const Duration(seconds: 4));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // ─────────────────────────────────────
  // 2. 线索同步 (Clues)
  // ─────────────────────────────────────

  /// 获取云端全部线索
  Future<List<Clue>?> fetchAllClues() async {
    if (_activeBaseUrl == null) {
      final found = await detectServer();
      if (!found) return null;
    }

    try {
      final res = await http
          .get(Uri.parse('$_activeBaseUrl/api/clues'))
          .timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final list = jsonDecode(res.body) as List<dynamic>;
        final clues = list.map((e) => Clue.fromJson(e)).toList();
        debugPrint('🟢 [CrmSync] 成功从同步服务器拉取 ${clues.length} 条线索');
        return clues;
      }
    } catch (e) {
      debugPrint('⚠️ [CrmSync] 拉取数据异常: $e');
      _activeBaseUrl = null;
    }
    return null;
  }

  /// 保存单个或批量线索
  Future<bool> saveClues(List<Clue> clues) async {
    if (clues.isEmpty) return true;
    if (_activeBaseUrl == null) {
      final found = await detectServer();
      if (!found) return false;
    }

    try {
      final payload = clues.map((c) => c.toJson()).toList();
      final res = await http
          .post(
            Uri.parse('$_activeBaseUrl/api/clues'),
            headers: {'Content-Type': 'application/json; charset=utf-8'},
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 4));
      return res.statusCode == 200;
    } catch (e) {
      debugPrint('⚠️ [CrmSync] 保存数据异常: $e');
      _activeBaseUrl = null;
      return false;
    }
  }

  /// 删除单个线索
  Future<bool> deleteClue(String clueId) async {
    if (_activeBaseUrl == null) {
      final found = await detectServer();
      if (!found) return false;
    }

    try {
      final res = await http
          .delete(Uri.parse('$_activeBaseUrl/api/clues/$clueId'))
          .timeout(const Duration(seconds: 4));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // ─────────────────────────────────────
  // 3. 物料同步 (Materials)
  // ─────────────────────────────────────

  Future<List<TextMaterial>?> fetchTextMaterials() async {
    if (_activeBaseUrl == null) {
      final found = await detectServer();
      if (!found) return null;
    }
    try {
      final res = await http
          .get(Uri.parse('$_activeBaseUrl/api/materials/text'))
          .timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final list = jsonDecode(res.body) as List<dynamic>;
        return list.map((e) => TextMaterial.fromJson(e)).toList();
      }
    } catch (_) {}
    return null;
  }

  Future<bool> saveTextMaterials(List<TextMaterial> list) async {
    if (_activeBaseUrl == null) {
      final found = await detectServer();
      if (!found) return false;
    }
    try {
      final payload = list.map((m) => m.toJson()).toList();
      final res = await http
          .post(
            Uri.parse('$_activeBaseUrl/api/materials/text'),
            headers: {'Content-Type': 'application/json; charset=utf-8'},
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 4));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<List<ImageMaterial>?> fetchImageMaterials() async {
    if (_activeBaseUrl == null) {
      final found = await detectServer();
      if (!found) return null;
    }
    try {
      final res = await http
          .get(Uri.parse('$_activeBaseUrl/api/materials/image'))
          .timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final list = jsonDecode(res.body) as List<dynamic>;
        return list.map((e) => ImageMaterial.fromJson(e)).toList();
      }
    } catch (_) {}
    return null;
  }

  Future<bool> saveImageMaterials(List<ImageMaterial> list) async {
    if (_activeBaseUrl == null) {
      final found = await detectServer();
      if (!found) return false;
    }
    try {
      final payload = list.map((m) => m.toJson()).toList();
      final res = await http
          .post(
            Uri.parse('$_activeBaseUrl/api/materials/image'),
            headers: {'Content-Type': 'application/json; charset=utf-8'},
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 4));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
