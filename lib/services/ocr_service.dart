import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../utils/clue_text_parser.dart';
import 'crm_sync_service.dart';

/// 截图智能 OCR 文字识别与专升本信息提取服务
class OcrService {
  static final OcrService _instance = OcrService._internal();
  factory OcrService() => _instance;
  OcrService._internal();

  /// 解析学员截图图片（微信名片、首屏聊天截图等）
  Future<ClueParsedResult> recognizeImage(Uint8List imageBytes) async {
    final base64Str = base64Encode(imageBytes);
    String rawText = '';

    // 1. 优先请求云端同步中枢统一 OCR 代理
    try {
      final sync = CrmSyncService();
      final url = '${sync.serverUrl}/api/ocr/recognize';
      final resp = await http
          .post(
            Uri.parse(url),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'base64Image': base64Str}),
          )
          .timeout(const Duration(seconds: 15));

      if (resp.statusCode == 200) {
        final data = jsonDecode(utf8.decode(resp.bodyBytes));
        if (data['success'] == true && data['rawText'] != null) {
          rawText = data['rawText'].toString();
        }
      }
    } catch (e) {
      debugPrint('⚠️ 云端 OCR 代理超时或异常，尝试直接通道: $e');
    }

    // 2. 客户端直接通道兜底（无需依赖云端部署进度）
    if (rawText.trim().isEmpty) {
      try {
        final directResp = await http
            .post(
              Uri.parse('https://api.ocr.space/parse/image'),
              headers: {
                'apikey': 'K87899142388957',
                'Content-Type': 'application/x-www-form-urlencoded',
              },
              body: {
                'language': 'chs',
                'isOverlayRequired': 'false',
                'base64Image': 'data:image/jpeg;base64,$base64Str',
              },
            )
            .timeout(const Duration(seconds: 20));

        if (directResp.statusCode == 200) {
          final data = jsonDecode(utf8.decode(directResp.bodyBytes));
          if (data['ParsedResults'] != null &&
              (data['ParsedResults'] as List).isNotEmpty) {
            rawText = data['ParsedResults'][0]['ParsedText']?.toString() ?? '';
          }
        }
      } catch (e) {
        debugPrint('⚠️ OCR 识别直接通道失败: $e');
      }
    }

    // 3. 将提取到的 OCR 原文交由专升本规范语义解析器进行结构化提取
    return ClueTextParser.parse(rawText);
  }
}
