import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crm_app/models/clue.dart';
import 'package:crm_app/models/initial_real_clues.dart';
import 'package:crm_app/providers/app_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('【轻量化验证】Clue.toJson(includeImageData: false) 能剥离超大 Base64 并保留 OCR 文本', () {
    final chat = ChatRecord(
      id: 'cr_test_1',
      clueId: 'clue_test_1',
      imagePath: '/mock/path.jpg',
      imageData: 'data:image/jpeg;base64,' + 'A' * 50000,
      ocrText: '学员：我想了解专升本',
      createTime: DateTime.now(),
    );

    final clue = Clue(
      id: 'clue_test_1',
      wxNick: '测试学员',
      createTime: DateTime.now(),
      chatRecords: [chat],
    );

    // 全量序列化
    final fullJson = clue.toJson(includeImageData: true);
    expect((fullJson['chatRecords'] as List)[0]['imageData'], isNotNull);
    final fullStr = jsonEncode(fullJson);
    expect(fullStr.length, greaterThan(50000));

    // 轻量序列化
    final lightJson = clue.toJson(includeImageData: false);
    expect((lightJson['chatRecords'] as List)[0]['imageData'], isNull);
    expect((lightJson['chatRecords'] as List)[0]['ocrText'], '学员：我想了解专升本');
    final lightStr = jsonEncode(lightJson);
    expect(lightStr.length, lessThan(1000));
  });

  test('【冷启动防闪烁验证】当本地旧缓存仅有部分线索时，_init 自动增量补齐种子库达到 10 条在跟进线索', () async {
    // 模拟本地原本只有 8 条线索（模拟用户旧缓存中仅有 8 条超级管理员在跟进线索的状态）
    final allSeeds = InitialRealClues.getClues();
    final subSeeds = allSeeds.take(8).toList();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'crm_clues', jsonEncode(subSeeds.map((c) => c.toJson()).toList()));

    final provider = AppProvider();
    await Future.delayed(const Duration(milliseconds: 50));

    // 验证超级管理员在跟进的线索数是否瞬间达到 10 条（补齐了略略与 Y4u）
    final adminActiveCount = provider.clues
        .where((c) =>
            c.ownerName == '超级管理员' &&
            c.status != ClueStatus.enrolled &&
            c.status != ClueStatus.paused)
        .length;
    expect(adminActiveCount, 10);
    expect(provider.clues.any((c) => c.wxNick == '略略'), isTrue);
    expect(provider.clues.any((c) => c.wxNick == 'Y4u'), isTrue);
  });
}
