import 'dart:convert';
import 'dart:io';

/// 专升本 CRM 多端全能同步服务器（支持线索、员工账号、物料库全量双向同步）
void main() async {
  final portEnv = Platform.environment['PORT'];
  final port = portEnv != null ? (int.tryParse(portEnv) ?? 8888) : 8888;
  final dataDir = Directory('data');
  if (!dataDir.existsSync()) {
    dataDir.createSync(recursive: true);
  }

  // 1. 线索数据表
  final cluesFile = File('data/crm_shared_database.json');
  if (!cluesFile.existsSync()) {
    cluesFile.writeAsStringSync('[]');
  }

  // 2. 员工账号数据表
  final usersFile = File('data/crm_shared_users.json');
  if (!usersFile.existsSync()) {
    usersFile.writeAsStringSync('[]');
  }

  // 3. 物料数据表
  final textMatFile = File('data/crm_shared_text_materials.json');
  if (!textMatFile.existsSync()) {
    textMatFile.writeAsStringSync('[]');
  }
  final imgMatFile = File('data/crm_shared_img_materials.json');
  if (!imgMatFile.existsSync()) {
    imgMatFile.writeAsStringSync('[]');
  }

  // 4. 已删除线索记录表（防复活墓碑）
  final deletedCluesFile = File('data/crm_deleted_clues.json');
  if (!deletedCluesFile.existsSync()) {
    deletedCluesFile.writeAsStringSync('[]');
  }

  // 5. 🛡️ 企业级历史快照备份目录 (保留最近 100 份不可逆快照)
  final backupsDir = Directory('data/backups');
  if (!backupsDir.existsSync()) {
    backupsDir.createSync(recursive: true);
  }

  void makeBackup(List<Map<String, dynamic>> clues, String reason) {
    try {
      if (clues.isEmpty) return;
      final now = DateTime.now();
      final stamp =
          '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}';
      final file = File('data/backups/crm_backup_$stamp.json');
      file.writeAsStringSync(const JsonEncoder.withIndent('  ').convert(clues));
      print('🛡️ [AutoBackup] 已自动生成时间戳快照: ${file.path} (原因: $reason, 条数: ${clues.length})');

      final allBackups = backupsDir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.json'))
          .toList()
        ..sort((a, b) => b.path.compareTo(a.path));
      if (allBackups.length > 100) {
        for (var old in allBackups.sublist(100)) {
          old.deleteSync();
        }
      }
    } catch (e) {
      print('⚠️ [AutoBackup] 备份异常: $e');
    }
  }

  final server = await HttpServer.bind(InternetAddress.anyIPv4, port);
  print('🚀 [CRM Sync Server] 全量多端数据同步服务已在端口 $port 启动成功！');
  print('🌐 访问地址: http://0.0.0.0:$port');

  List<Map<String, dynamic>> readTable(File file) {
    try {
      final content = file.readAsStringSync();
      final list = jsonDecode(content) as List<dynamic>;
      return list.map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (_) {
      return [];
    }
  }

  void writeTable(File file, List<Map<String, dynamic>> list) {
    file.writeAsStringSync(const JsonEncoder.withIndent('  ').convert(list));
  }

  /// 服务端线索深度智能增量合并（非空绝对保全，严防客户端残缺数据抹杀AI报告与次回访时间）
  Map<String, dynamic> mergeServerClue(
      Map<String, dynamic> existing, Map<String, dynamic> incoming) {
    final merged = Map<String, dynamic>.from(existing);

    // 1. 回访记录 (visitLogs) 增量去重合并
    final existingLogs = (existing['visitLogs'] as List<dynamic>?) ?? [];
    final incomingLogs = (incoming['visitLogs'] as List<dynamic>?) ?? [];
    final logMap = <String, Map<String, dynamic>>{};
    for (var l in existingLogs) {
      if (l is Map) {
        final m = Map<String, dynamic>.from(l);
        if (m['id'] != null) logMap[m['id'].toString()] = m;
      }
    }
    for (var l in incomingLogs) {
      if (l is Map) {
        final m = Map<String, dynamic>.from(l);
        if (m['id'] != null) {
          final idStr = m['id'].toString();
          final oldLog = logMap[idStr];
          if (oldLog != null) {
            // 保留历史回访中可能已有的 AI 诊断报告
            final incomingAi = m['aiReport']?.toString().trim();
            final oldAi = oldLog['aiReport']?.toString().trim();
            if ((incomingAi == null || incomingAi.isEmpty) &&
                (oldAi != null && oldAi.isNotEmpty)) {
              m['aiReport'] = oldLog['aiReport'];
            }
          }
          logMap[idStr] = m;
        }
      }
    }
    final mergedLogs = logMap.values.toList()
      ..sort((a, b) {
        final ta = a['createTime']?.toString() ?? '';
        final tb = b['createTime']?.toString() ?? '';
        return tb.compareTo(ta);
      });
    merged['visitLogs'] = mergedLogs;

    // 2. 聊天记录 (chatRecords) 增量去重合并，确保图片数据不丢失
    final existingChats = (existing['chatRecords'] as List<dynamic>?) ?? [];
    final incomingChats = (incoming['chatRecords'] as List<dynamic>?) ?? [];
    final chatMap = <String, Map<String, dynamic>>{};
    for (var c in existingChats) {
      if (c is Map) {
        final m = Map<String, dynamic>.from(c);
        if (m['id'] != null) chatMap[m['id'].toString()] = m;
      }
    }
    for (var c in incomingChats) {
      if (c is Map) {
        final m = Map<String, dynamic>.from(c);
        if (m['id'] != null) {
          final idStr = m['id'].toString();
          final oldChat = chatMap[idStr];
          if (oldChat != null) {
            final incomingImg = m['imageData']?.toString();
            final oldImg = oldChat['imageData']?.toString();
            if ((incomingImg == null || incomingImg.isEmpty) &&
                (oldImg != null && oldImg.isNotEmpty)) {
              m['imageData'] = oldChat['imageData'];
            }
          }
          chatMap[idStr] = m;
        }
      }
    }
    final mergedChats = chatMap.values.toList()
      ..sort((a, b) {
        final ta = a['createTime']?.toString() ?? '';
        final tb = b['createTime']?.toString() ?? '';
        return tb.compareTo(ta);
      });
    merged['chatRecords'] = mergedChats;

    // 3. 标签 (tags) 集合合并
    final existingTags = (existing['tags'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toSet() ??
        {};
    final incomingTags = (incoming['tags'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toSet() ??
        {};
    merged['tags'] = {...existingTags, ...incomingTags}.toList();

    // 4. 下次回访时间 (nextVisitTime) 非空绝对保全
    final incomingNext = incoming['nextVisitTime']?.toString();
    final existingNext = existing['nextVisitTime']?.toString();
    if (incomingNext != null &&
        incomingNext.trim().isNotEmpty &&
        incomingNext != 'null') {
      merged['nextVisitTime'] = incomingNext;
    } else if (existingNext != null &&
        existingNext.trim().isNotEmpty &&
        existingNext != 'null') {
      merged['nextVisitTime'] = existingNext;
    } else {
      merged['nextVisitTime'] = null;
    }

    // 5. AI 分析报告 (aiAnalysisReport) 与时间 (aiAnalysisTime) 保全
    final incomingReport = incoming['aiAnalysisReport']?.toString().trim();
    final existingReport = existing['aiAnalysisReport']?.toString().trim();
    final bool incomingHasReport =
        incomingReport != null && incomingReport.isNotEmpty && incomingReport != 'null';
    final bool existingHasReport =
        existingReport != null && existingReport.isNotEmpty && existingReport != 'null';

    if (incomingHasReport && !existingHasReport) {
      merged['aiAnalysisReport'] = incoming['aiAnalysisReport'];
      merged['aiAnalysisTime'] =
          incoming['aiAnalysisTime'] ?? DateTime.now().toIso8601String();
    } else if (!incomingHasReport && existingHasReport) {
      merged['aiAnalysisReport'] = existing['aiAnalysisReport'];
      merged['aiAnalysisTime'] = existing['aiAnalysisTime'];
    } else if (incomingHasReport && existingHasReport) {
      final inTimeStr = incoming['aiAnalysisTime']?.toString();
      final exTimeStr = existing['aiAnalysisTime']?.toString();
      if (inTimeStr != null && exTimeStr != null) {
        final inTime = DateTime.tryParse(inTimeStr);
        final exTime = DateTime.tryParse(exTimeStr);
        if (inTime != null && exTime != null && inTime.isAfter(exTime)) {
          merged['aiAnalysisReport'] = incoming['aiAnalysisReport'];
          merged['aiAnalysisTime'] = incoming['aiAnalysisTime'];
        } else {
          merged['aiAnalysisReport'] = existing['aiAnalysisReport'];
          merged['aiAnalysisTime'] = existing['aiAnalysisTime'];
        }
      } else {
        merged['aiAnalysisReport'] = incoming['aiAnalysisReport'];
        merged['aiAnalysisTime'] =
            incoming['aiAnalysisTime'] ?? existing['aiAnalysisTime'];
      }
    }

    // 6. 其他基础字段：非空优先覆写
    for (var key in [
      'wxNick',
      'wxId',
      'phone',
      'grade',
      'school',
      'subject',
      'source',
      'classType',
      'ownerName',
      'status',
      'intentLevel',
      'remark',
      'enrollAmount'
    ]) {
      if (incoming.containsKey(key) && incoming[key] != null) {
        if (incoming[key] is String &&
            (incoming[key] as String).trim().isEmpty) {
          if (existing.containsKey(key) &&
              existing[key] is String &&
              (existing[key] as String).trim().isNotEmpty) {
            continue; // 保留服务端的已有非空字符串
          }
        }
        merged[key] = incoming[key];
      }
    }

    return merged;
  }

  await for (HttpRequest req in server) {
    req.response.headers.set('Access-Control-Allow-Origin', '*');
    req.response.headers.set('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
    req.response.headers.set('Access-Control-Allow-Headers', '*');
    req.response.headers.set('Access-Control-Expose-Headers', '*');
    req.response.headers.set('Access-Control-Max-Age', '86400');

    if (req.method == 'OPTIONS') {
      req.response.statusCode = HttpStatus.noContent;
      await req.response.close();
      continue;
    }

    final path = req.uri.path;

    // 健康检查与欢迎页
    if (path == '/' || path == '/health') {
      req.response.statusCode = HttpStatus.ok;
      req.response.headers.contentType = ContentType.json;
      req.response.write(jsonEncode({
        'status': 'online',
        'service': '专升本招生CRM云端同步中枢',
        'timestamp': DateTime.now().toIso8601String(),
        'endpoints': ['/api/clues', '/api/users', '/api/materials/text', '/api/materials/image']
      }));
      await req.response.close();
      continue;
    }

    // 健康检查
    if (path == '/api/health') {
      req.response
        ..headers.contentType = ContentType.json
        ..statusCode = HttpStatus.ok
        ..write(jsonEncode({'status': 'ok', 'time': DateTime.now().toIso8601String()}));
      await req.response.close();
      continue;
    }

    // ─────────────────────────────────────
    // 1. 员工账号接口 (/api/users)
    // ─────────────────────────────────────
    if (path == '/api/users') {
      if (req.method == 'GET') {
        final list = readTable(usersFile);
        req.response
          ..headers.contentType = ContentType.json
          ..statusCode = HttpStatus.ok
          ..write(jsonEncode(list));
        await req.response.close();
        continue;
      }

      if (req.method == 'POST') {
        final bodyStr = await utf8.decodeStream(req);
        final body = jsonDecode(bodyStr);
        final list = readTable(usersFile);
        final map = {for (var item in list) item['id']: item};

        if (body is List) {
          for (var item in body) {
            final m = Map<String, dynamic>.from(item);
            if (m['id'] != null) map[m['id']] = m;
          }
        } else if (body is Map) {
          final m = Map<String, dynamic>.from(body);
          if (m['id'] != null) map[m['id']] = m;
        }

        final resultList = map.values.toList();
        writeTable(usersFile, resultList);

        req.response
          ..headers.contentType = ContentType.json
          ..statusCode = HttpStatus.ok
          ..write(jsonEncode({'success': true, 'count': resultList.length}));
        await req.response.close();
        continue;
      }
    }

    if (path.startsWith('/api/users/')) {
      final id = path.substring('/api/users/'.length);
      if (req.method == 'DELETE') {
        final list = readTable(usersFile);
        list.removeWhere((item) => item['id'] == id);
        writeTable(usersFile, list);

        req.response
          ..headers.contentType = ContentType.json
          ..statusCode = HttpStatus.ok
          ..write(jsonEncode({'success': true, 'deleted': id}));
        await req.response.close();
        continue;
      }
    }

    // ─────────────────────────────────────
    // 2. 线索数据接口 (/api/clues)
    // ─────────────────────────────────────
    // 已删除线索ID列表接口 (/api/clues/deleted)
    if (path == '/api/clues/deleted') {
      if (req.method == 'GET') {
        final list = readTable(deletedCluesFile);
        req.response
          ..headers.contentType = ContentType.json
          ..statusCode = HttpStatus.ok
          ..write(jsonEncode(list.map((e) => e['id']).toList()));
        await req.response.close();
        continue;
      }
    }

    if (path == '/api/clues') {
      if (req.method == 'GET') {
        final list = readTable(cluesFile);
        final isSummary = req.uri.queryParameters['summary'] == 'true';
        final responseData = isSummary
            ? list.map((c) {
                final copy = Map<String, dynamic>.from(c);
                if (copy['chatRecords'] is List) {
                  copy['chatRecords'] = (copy['chatRecords'] as List).map((cr) {
                    if (cr is Map) {
                      final chatCopy = Map<String, dynamic>.from(cr);
                      chatCopy['imageData'] = null; // 剥离超大 Base64 原图，体积由 19.7MB 骤降至 52KB
                      return chatCopy;
                    }
                    return cr;
                  }).toList();
                }
                return copy;
              }).toList()
            : list;

        req.response
          ..headers.contentType = ContentType.json
          ..statusCode = HttpStatus.ok
          ..write(jsonEncode(responseData));
        await req.response.close();
        continue;
      }

      if (req.method == 'POST') {
        final bodyStr = await utf8.decodeStream(req);
        final body = jsonDecode(bodyStr);
        final list = readTable(cluesFile);
        final map = {for (var item in list) item['id']: item};

        // 获取已删除名单，严防老版本客户端擅自复活已删线索
        final deletedList = readTable(deletedCluesFile);
        final deletedIds = {for (var d in deletedList) d['id']};

        void saveOneClue(Map<String, dynamic> item) {
          final id = item['id']?.toString();
          if (id == null || id.isEmpty || deletedIds.contains(id)) return;
          if (map.containsKey(id)) {
            map[id] = mergeServerClue(map[id]!, item);
          } else {
            map[id] = item;
          }
        }

        if (body is List) {
          for (var item in body) {
            if (item is Map) {
              saveOneClue(Map<String, dynamic>.from(item));
            }
          }
        } else if (body is Map) {
          saveOneClue(Map<String, dynamic>.from(body));
        }

        final resultList = map.values.toList();
        resultList.sort((a, b) {
          final ta = a['createTime'] ?? '';
          final tb = b['createTime'] ?? '';
          return tb.compareTo(ta);
        });
        writeTable(cluesFile, resultList);
        makeBackup(resultList, '线索增量更新');

        req.response
          ..headers.contentType = ContentType.json
          ..statusCode = HttpStatus.ok
          ..write(jsonEncode({'success': true, 'count': resultList.length}));
        await req.response.close();
        continue;
      }
    }

    if (path.startsWith('/api/clues/')) {
      final id = path.substring('/api/clues/'.length);
      if (id != 'deleted') {
        if (req.method == 'GET') {
          final list = readTable(cluesFile);
          Map<String, dynamic>? foundClue;
          for (var c in list) {
            if (c['id'] == id) {
              foundClue = c;
              break;
            }
          }
          if (foundClue != null) {
            req.response
              ..headers.contentType = ContentType.json
              ..statusCode = HttpStatus.ok
              ..write(jsonEncode(foundClue));
          } else {
            req.response
              ..headers.contentType = ContentType.json
              ..statusCode = HttpStatus.notFound
              ..write(jsonEncode({'error': '线索不存在', 'id': id}));
          }
          await req.response.close();
          continue;
        }
      }

      if (req.method == 'DELETE') {
        final list = readTable(cluesFile);
        list.removeWhere((item) => item['id'] == id);
        writeTable(cluesFile, list);
        makeBackup(list, '线索删除(ID: $id)');

        // 记入云端墓碑表，严密防止任何客户端再次复活
        final deletedList = readTable(deletedCluesFile);
        final deletedSet = {for (var d in deletedList) d['id']};
        if (!deletedSet.contains(id)) {
          deletedList.add({'id': id, 'time': DateTime.now().toIso8601String()});
          if (deletedList.length > 500) {
            deletedList.removeRange(0, deletedList.length - 500);
          }
          writeTable(deletedCluesFile, deletedList);
        }

        req.response
          ..headers.contentType = ContentType.json
          ..statusCode = HttpStatus.ok
          ..write(jsonEncode({'success': true, 'deleted': id}));
        await req.response.close();
        continue;
      }
    }

    // ─────────────────────────────────────
    // 备份快照管理接口 (/api/backups)
    // ─────────────────────────────────────
    if (path == '/api/backups') {
      if (req.method == 'GET') {
        final allBackups = backupsDir
            .listSync()
            .whereType<File>()
            .where((f) => f.path.endsWith('.json'))
            .toList()
          ..sort((a, b) => b.path.compareTo(a.path));
        final list = allBackups.map((f) {
          final stat = f.statSync();
          return {
            'filename': f.uri.pathSegments.last,
            'modified': stat.modified.toIso8601String(),
            'size': stat.size,
          };
        }).toList();
        req.response
          ..headers.contentType = ContentType.json
          ..statusCode = HttpStatus.ok
          ..write(jsonEncode({'success': true, 'total': list.length, 'backups': list}));
        await req.response.close();
        continue;
      }
    }

    // ─────────────────────────────────────
    // 3. 文字物料接口 (/api/materials/text)
    // ─────────────────────────────────────
    if (path == '/api/materials/text') {
      if (req.method == 'GET') {
        final list = readTable(textMatFile);
        req.response
          ..headers.contentType = ContentType.json
          ..statusCode = HttpStatus.ok
          ..write(jsonEncode(list));
        await req.response.close();
        continue;
      }

      if (req.method == 'POST') {
        final bodyStr = await utf8.decodeStream(req);
        final body = jsonDecode(bodyStr);
        final list = readTable(textMatFile);
        final map = {for (var item in list) item['id']: item};

        if (body is List) {
          for (var item in body) {
            final m = Map<String, dynamic>.from(item);
            if (m['id'] != null) map[m['id']] = m;
          }
        } else if (body is Map) {
          final m = Map<String, dynamic>.from(body);
          if (m['id'] != null) map[m['id']] = m;
        }

        final resultList = map.values.toList();
        writeTable(textMatFile, resultList);

        req.response
          ..headers.contentType = ContentType.json
          ..statusCode = HttpStatus.ok
          ..write(jsonEncode({'success': true, 'count': resultList.length}));
        await req.response.close();
        continue;
      }
    }

    if (path.startsWith('/api/materials/text/')) {
      final id = path.substring('/api/materials/text/'.length);
      if (req.method == 'DELETE') {
        final list = readTable(textMatFile);
        list.removeWhere((item) => item['id'] == id);
        writeTable(textMatFile, list);

        req.response
          ..headers.contentType = ContentType.json
          ..statusCode = HttpStatus.ok
          ..write(jsonEncode({'success': true, 'deleted': id}));
        await req.response.close();
        continue;
      }
    }

    // ─────────────────────────────────────
    // 4. 图片物料接口 (/api/materials/image)
    // ─────────────────────────────────────
    if (path == '/api/materials/image') {
      if (req.method == 'GET') {
        final list = readTable(imgMatFile);
        req.response
          ..headers.contentType = ContentType.json
          ..statusCode = HttpStatus.ok
          ..write(jsonEncode(list));
        await req.response.close();
        continue;
      }

      if (req.method == 'POST') {
        final bodyStr = await utf8.decodeStream(req);
        final body = jsonDecode(bodyStr);
        final list = readTable(imgMatFile);
        final map = {for (var item in list) item['id']: item};

        if (body is List) {
          for (var item in body) {
            final m = Map<String, dynamic>.from(item);
            if (m['id'] != null) map[m['id']] = m;
          }
        } else if (body is Map) {
          final m = Map<String, dynamic>.from(body);
          if (m['id'] != null) map[m['id']] = m;
        }

        final resultList = map.values.toList();
        writeTable(imgMatFile, resultList);

        req.response
          ..headers.contentType = ContentType.json
          ..statusCode = HttpStatus.ok
          ..write(jsonEncode({'success': true, 'count': resultList.length}));
        await req.response.close();
        continue;
      }
    }

    if (path.startsWith('/api/materials/image/')) {
      final id = path.substring('/api/materials/image/'.length);
      if (req.method == 'DELETE') {
        final list = readTable(imgMatFile);
        list.removeWhere((item) => item['id'] == id);
        writeTable(imgMatFile, list);

        req.response
          ..headers.contentType = ContentType.json
          ..statusCode = HttpStatus.ok
          ..write(jsonEncode({'success': true, 'deleted': id}));
        await req.response.close();
        continue;
      }
    }

    // ─────────────────────────────────────
    // 5. 云端统一 AI 大模型服务 (/api/ai)
    // ─────────────────────────────────────
    final aiConfigFile = File('data/crm_ai_config.json');

    Map<String, String> getAiConfig() {
      final envKey = Platform.environment['DEEPSEEK_API_KEY'];
      String apiKey = envKey ?? '';
      String baseUrl = Platform.environment['DEEPSEEK_BASE_URL'] ?? 'https://api.deepseek.com/v1';
      String model = Platform.environment['DEEPSEEK_MODEL'] ?? 'deepseek-chat';

      if (aiConfigFile.existsSync()) {
        try {
          final data = jsonDecode(aiConfigFile.readAsStringSync());
          if (data is Map) {
            if (apiKey.isEmpty && data['apiKey'] != null) apiKey = data['apiKey'].toString().trim();
            if (data['baseUrl'] != null && data['baseUrl'].toString().isNotEmpty) baseUrl = data['baseUrl'].toString().trim();
            if (data['model'] != null && data['model'].toString().isNotEmpty) model = data['model'].toString().trim();
          }
        } catch (_) {}
      }
      return {'apiKey': apiKey, 'baseUrl': baseUrl, 'model': model};
    }

    if (path == '/api/ai/config') {
      final config = getAiConfig();
      if (req.method == 'GET') {
        req.response
          ..headers.contentType = ContentType.json
          ..statusCode = HttpStatus.ok
          ..write(jsonEncode({
            'configured': config['apiKey']!.isNotEmpty,
            'model': config['model'],
            'baseUrl': config['baseUrl'],
          }));
        await req.response.close();
        continue;
      }

      if (req.method == 'POST') {
        final bodyStr = await utf8.decodeStream(req);
        final body = jsonDecode(bodyStr);
        if (body is Map) {
          final current = getAiConfig();
          final newKey = body['apiKey']?.toString().trim() ?? current['apiKey'];
          final newUrl = body['baseUrl']?.toString().trim() ?? current['baseUrl'];
          final newModel = body['model']?.toString().trim() ?? current['model'];

          aiConfigFile.writeAsStringSync(jsonEncode({
            'apiKey': newKey,
            'baseUrl': newUrl,
            'model': newModel,
          }));

          req.response
            ..headers.contentType = ContentType.json
            ..statusCode = HttpStatus.ok
            ..write(jsonEncode({'success': true, 'configured': newKey!.isNotEmpty}));
          await req.response.close();
          continue;
        }
      }
    }

    if (path == '/api/ai/analyze' && req.method == 'POST') {
      final config = getAiConfig();
      if (config['apiKey']!.isEmpty) {
        req.response
          ..headers.contentType = ContentType.json
          ..statusCode = HttpStatus.badRequest
          ..write(jsonEncode({
            'success': false,
            'error': '云端中枢尚未配置 DeepSeek API Key，请超级管理员在设置中统一录入！'
          }));
        await req.response.close();
        continue;
      }

      try {
        final bodyStr = await utf8.decodeStream(req);
        final body = jsonDecode(bodyStr) as Map<String, dynamic>;
        final systemPrompt = body['systemPrompt']?.toString() ??
            '你是一位拥有10年经验的统招专升本招生金牌销售总监。擅长精准挖掘学生内心顾虑，并给出极具杀伤力的实战逼单话术。';
        final userPrompt = body['userPrompt']?.toString() ?? '';

        final cleanBase = config['baseUrl']!.endsWith('/')
            ? config['baseUrl']!.substring(0, config['baseUrl']!.length - 1)
            : config['baseUrl']!;
        final url = Uri.parse('$cleanBase/chat/completions');

        final client = HttpClient();
        client.connectionTimeout = const Duration(seconds: 45);
        final extReq = await client.postUrl(url);
        extReq.headers.set('Content-Type', 'application/json; charset=utf-8');
        extReq.headers.set('Authorization', 'Bearer ${config['apiKey']}');

        final payload = jsonEncode({
          'model': config['model'],
          'messages': [
            {'role': 'system', 'content': systemPrompt},
            {'role': 'user', 'content': userPrompt},
          ],
          'temperature': 0.7,
        });
        extReq.write(payload);
        final extResp = await extReq.close();
        final respText = await utf8.decodeStream(extResp);
        final respJson = jsonDecode(respText);

        if (extResp.statusCode == 200) {
          final content = respJson['choices'][0]['message']['content'];
          req.response
            ..headers.contentType = ContentType.json
            ..statusCode = HttpStatus.ok
            ..write(jsonEncode({'success': true, 'output': content}));
        } else {
          final err = respJson['error']?['message'] ?? 'API Error ${extResp.statusCode}';
          req.response
            ..headers.contentType = ContentType.json
            ..statusCode = HttpStatus.badGateway
            ..write(jsonEncode({'success': false, 'error': err}));
        }
      } catch (e) {
        req.response
          ..headers.contentType = ContentType.json
          ..statusCode = HttpStatus.internalServerError
          ..write(jsonEncode({'success': false, 'error': e.toString()}));
      }
      await req.response.close();
      continue;
    }

    // ==================== 智能 OCR 图片文字提取端点 ====================
    if (path == '/api/ocr/recognize' && req.method == 'POST') {
      try {
        final bodyStr = await utf8.decodeStream(req);
        final body = jsonDecode(bodyStr) as Map<String, dynamic>;
        final base64Image = body['base64Image']?.toString() ?? '';

        if (base64Image.isEmpty) {
          req.response
            ..headers.contentType = ContentType.json
            ..statusCode = HttpStatus.badRequest
            ..write(jsonEncode({'success': false, 'error': 'base64Image 不能为空'}));
          await req.response.close();
          continue;
        }

        // 调用通用高精度 OCR 接口进行文字提取
        final client = HttpClient();
        client.connectionTimeout = const Duration(seconds: 25);
        final ocrUrl = Uri.parse('https://api.ocr.space/parse/image');
        final extReq = await client.postUrl(ocrUrl);
        extReq.headers.set('apikey', 'K87899142388957');
        extReq.headers.set('Content-Type', 'application/x-www-form-urlencoded');

        final postData = 'language=chs&isOverlayRequired=false&base64Image=${Uri.encodeQueryComponent("data:image/jpeg;base64,$base64Image")}';
        extReq.write(postData);
        final extResp = await extReq.close();
        final respText = await utf8.decodeStream(extResp);
        final respJson = jsonDecode(respText);

        if (respJson['ParsedResults'] != null &&
            (respJson['ParsedResults'] as List).isNotEmpty) {
          final parsedText = respJson['ParsedResults'][0]['ParsedText']?.toString() ?? '';
          req.response
            ..headers.contentType = ContentType.json
            ..statusCode = HttpStatus.ok
            ..write(jsonEncode({'success': true, 'rawText': parsedText}));
        } else {
          final err = respJson['ErrorMessage']?.toString() ?? '未能从截图中识别出文字';
          req.response
            ..headers.contentType = ContentType.json
            ..statusCode = HttpStatus.ok
            ..write(jsonEncode({'success': false, 'error': err, 'rawText': ''}));
        }
      } catch (e) {
        req.response
          ..headers.contentType = ContentType.json
          ..statusCode = HttpStatus.internalServerError
          ..write(jsonEncode({'success': false, 'error': e.toString()}));
      }
      await req.response.close();
      continue;
    }

    req.response
      ..statusCode = HttpStatus.notFound
      ..write('Not Found');
    await req.response.close();
  }
}
