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
    if (path == '/api/clues') {
      if (req.method == 'GET') {
        final list = readTable(cluesFile);
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
        final list = readTable(cluesFile);
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
        resultList.sort((a, b) {
          final ta = a['createTime'] ?? '';
          final tb = b['createTime'] ?? '';
          return tb.compareTo(ta);
        });
        writeTable(cluesFile, resultList);

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
      if (req.method == 'DELETE') {
        final list = readTable(cluesFile);
        list.removeWhere((item) => item['id'] == id);
        writeTable(cluesFile, list);

        req.response
          ..headers.contentType = ContentType.json
          ..statusCode = HttpStatus.ok
          ..write(jsonEncode({'success': true, 'deleted': id}));
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

    req.response
      ..statusCode = HttpStatus.notFound
      ..write('Not Found');
    await req.response.close();
  }
}
