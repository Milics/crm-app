import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crm_app/models/clue.dart';
import 'package:crm_app/providers/app_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('【三无空记录判定与过滤】isValid 与 hasImage 属性逻辑校验', () {
    // 1. 三无记录：无图片、无路径、无 OCR
    final emptyRecord = ChatRecord(
      id: 'cr_empty',
      clueId: 'c1',
      imagePath: '',
      imageData: null,
      ocrText: '   ',
      createTime: DateTime.now(),
    );
    expect(emptyRecord.isValid, isFalse);
    expect(emptyRecord.hasImage, isFalse);

    // 2. 纯文字沟通记录（有 OCR 文本，无图片）
    final noteRecord = ChatRecord(
      id: 'cr_note',
      clueId: 'c1',
      imagePath: '',
      imageData: null,
      ocrText: '学员咨询了专升本美术课程价格',
      createTime: DateTime.now(),
    );
    expect(noteRecord.isValid, isTrue);
    expect(noteRecord.hasImage, isFalse);

    // 3. 正常图片记录（有 Base64）
    final imgRecord = ChatRecord(
      id: 'cr_img',
      clueId: 'c1',
      imagePath: '',
      imageData: 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
      ocrText: '微信截图',
      createTime: DateTime.now(),
    );
    expect(imgRecord.isValid, isTrue);
    expect(imgRecord.hasImage, isTrue);
  });

  test('【冷启动与保存清洗】AppProvider 启动时自动清洗本地现存的三无空记录', () async {
    // 模拟本地存储中存在三无空记录（如略略之前旧缓存生成的 24 条三无占位符）
    final mockClue = Clue(
      id: 'clue_luelue',
      wxNick: '略略',
      createTime: DateTime.now(),
      chatRecords: [
        ChatRecord(
          id: 'cr_invalid_1',
          clueId: 'clue_luelue',
          imagePath: '',
          imageData: null,
          ocrText: '',
          createTime: DateTime.now(),
        ),
        ChatRecord(
          id: 'cr_invalid_2',
          clueId: 'clue_luelue',
          imagePath: '',
          imageData: null,
          ocrText: '',
          createTime: DateTime.now(),
        ),
        ChatRecord(
          id: 'cr_valid_1',
          clueId: 'clue_luelue',
          imagePath: '',
          imageData: 'valid_b64',
          ocrText: '真实的沟通图',
          createTime: DateTime.now(),
        ),
      ],
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'crm_clues', jsonEncode([mockClue.toJson(includeImageData: true)]));

    final provider = AppProvider();
    await Future.delayed(const Duration(milliseconds: 50));

    final loadedClue = provider.clues.firstWhere((c) => c.id == 'clue_luelue');
    // 验证三无空记录已被完全清洗剔除，仅保留有效记录
    expect(loadedClue.chatRecords.length, 1);
    expect(loadedClue.chatRecords.first.id, 'cr_valid_1');
  });

  test('【单条沟通记录删除与墓碑机制】deleteChatRecord 从线索中移除并登记到 deletedChatRecordIds 防复活', () async {
    final validRecord1 = ChatRecord(
      id: 'cr_101',
      clueId: 'clue_demo',
      imagePath: '',
      imageData: 'b64_1',
      ocrText: '截图1',
      createTime: DateTime.now(),
    );
    final validRecord2 = ChatRecord(
      id: 'cr_102',
      clueId: 'clue_demo',
      imagePath: '',
      imageData: 'b64_2',
      ocrText: '截图2',
      createTime: DateTime.now(),
    );

    final clue = Clue(
      id: 'clue_demo',
      wxNick: '陈明',
      createTime: DateTime.now(),
      chatRecords: [validRecord1, validRecord2],
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'crm_clues', jsonEncode([clue.toJson(includeImageData: true)]));

    final provider = AppProvider();
    await Future.delayed(const Duration(milliseconds: 50));

    // 删除第 1 条记录
    provider.deleteChatRecord('clue_demo', 'cr_101');

    final updatedClue = provider.clues.firstWhere((c) => c.id == 'clue_demo');
    // 聊天列表中只剩一条
    expect(updatedClue.chatRecords.length, 1);
    expect(updatedClue.chatRecords.first.id, 'cr_102');
    // 墓碑集合中包含已删除的 ID
    expect(updatedClue.deletedChatRecordIds, contains('cr_101'));
  });
}
