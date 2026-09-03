import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../utils/clue_text_parser.dart';
import 'crm_sync_service.dart';

/// 截图智能 OCR 文字识别与专升本信息提取服务（支持多通道智能故障转移）
class OcrService {
  static final OcrService _instance = OcrService._internal();
  factory OcrService() => _instance;
  OcrService._internal();

  // 高可用备用 Key 池，自动故障转移防 429 限频
  static const List<String> _keyPool = [
    'K88825838588957',
    'K82885994288957',
    'K81546959888957',
    'helloworld',
  ];

  /// 解析学员截图图片（微信名片、首屏聊天截图等）
  Future<ClueParsedResult> recognizeImage(Uint8List imageBytes) async {
    final base64Str = base64Encode(imageBytes);
    String rawText = '';

    // 1. 优先尝试云端同步中枢统一 OCR
    try {
      final sync = CrmSyncService();
      final url = '${sync.serverUrl}/api/ocr/recognize';
      final resp = await http
          .post(
            Uri.parse(url),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'base64Image': base64Str}),
          )
          .timeout(const Duration(seconds: 12));

      if (resp.statusCode == 200) {
        final data = jsonDecode(utf8.decode(resp.bodyBytes));
        if (data['success'] == true &&
            data['rawText'] != null &&
            data['rawText'].toString().trim().isNotEmpty) {
          rawText = data['rawText'].toString();
        }
      }
    } catch (e) {
      debugPrint('ℹ️ 云端代理未就绪或超时，自动切换本地多通道池: $e');
    }

    // 2. 客户端高可用 Key 池自动故障转移（避免单个 Key 429 报错）
    if (rawText.trim().isEmpty) {
      for (final key in _keyPool) {
        try {
          final directResp = await http
              .post(
                Uri.parse('https://api.ocr.space/parse/image'),
                headers: {
                  'apikey': key,
                  'Content-Type': 'application/x-www-form-urlencoded',
                },
                body: {
                  'language': 'chs',
                  'isOverlayRequired': 'false',
                  'OCREngine': '2',
                  'base64Image': 'data:image/jpeg;base64,$base64Str',
                },
              )
              .timeout(const Duration(seconds: 18));

          if (directResp.statusCode == 200) {
            final data = jsonDecode(utf8.decode(directResp.bodyBytes));
            if (data['ParsedResults'] != null &&
                (data['ParsedResults'] as List).isNotEmpty) {
              final text = data['ParsedResults'][0]['ParsedText']?.toString() ?? '';
              if (text.trim().isNotEmpty) {
                rawText = text;
                debugPrint('✅ OCR 成功解析 (使用 Key 通道 $key)');
                break;
              }
            }
          } else if (directResp.statusCode == 429) {
            debugPrint('⚠️ 通道 $key 限频(429)，自动尝试下一个通道...');
            continue;
          }
        } catch (e) {
          debugPrint('⚠️ 通道 $key 请求异常: $e');
        }
      }
    }

    // 3. 将提取到的 OCR 原文交由专升本规范语义解析器进行结构化提取
    return ClueTextParser.parse(rawText);
  }
}
