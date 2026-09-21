import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:crm_app/providers/app_provider.dart';
import 'package:crm_app/models/clue.dart';
import 'package:crm_app/models/initial_real_clues.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  group('【企业级数据安全测试】系统级导出备份与灾难恢复深度验证', () {
    test('1. 导出备份验证：包含完整13位学员、Base64截图与AI深度分析', () {
      final provider = AppProvider();
      final realSeeds = InitialRealClues.getClues();
      for (final c in realSeeds) {
        provider.addClue(c);
      }

      final jsonStr = provider.exportBackupJson();
      expect(jsonStr.isNotEmpty, true);

      final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;
      expect(decoded['backupVersion'], '2.0');
      expect(decoded['system'], '专升本招生CRM');
      expect(decoded['totalClues'] >= 13, true);

      final clues = (decoded['clues'] as List).cast<Map<String, dynamic>>();
      
      // 验证林建包含 Base64 微信原图与 AI 分析
      final linjian = clues.firstWhere((c) => c['wxNick'] == '林建');
      expect(linjian['aiAnalysisReport'] != null, true);
      final chats = linjian['chatRecords'] as List;
      expect(chats.length, 3);
      expect((chats[0]['imageData'] as String).isNotEmpty, true);

      // 验证金闪闪包含 AI 分析报告
      final jinshanshan = clues.firstWhere((c) => c['wxNick'] == '金闪闪想出去玩儿');
      expect(jinshanshan['aiAnalysisReport'] != null, true);
      expect(jinshanshan['aiAnalysisReport'].toString().contains('金牌销售总监'), true);

      // 验证卡厄斯兰那包含 AI 分析报告
      final kaesilanna = clues.firstWhere((c) => c['wxNick'] == '卡厄斯兰那');
      expect(kaesilanna['aiAnalysisReport'] != null, true);
      expect(kaesilanna['aiAnalysisReport'].toString().contains('平原新区'), true);
    });

    test('2. 灾难恢复验证：模拟本地数据残缺时，通过历史备份自愈合并，实图与AI优先保全', () async {
      final provider = AppProvider();
      
      // 导出完整备份
      final fullSeeds = InitialRealClues.getClues();
      final backupJson = const JsonEncoder.withIndent('  ').convert({
        'backupVersion': '2.0',
        'clues': fullSeeds.map((c) => c.toJson()).toList(),
      });

      // 模拟灾难现场：当前本地只剩一条残缺的林建（没有图片，没有AI报告）
      final brokenLinjian = Clue(
        id: '1789782678573',
        wxNick: '林建',
        wxId: '',
        phone: '',
        grade: '25级',
        school: '林州建筑',
        subject: '美术专业综合',
        source: '微信',
        classType: '全程非协议班',
        status: ClueStatus.contacted,
        intentLevel: IntentLevel.medium,
        tags: const [],
        ownerName: '超级管理员',
        createTime: DateTime.parse('2026-09-19T09:51:18.573'),
        aiAnalysisReport: null,
        aiAnalysisTime: null,
        chatRecords: [],
        visitLogs: [],
      );
      provider.addClue(brokenLinjian);

      // 执行灾难恢复导入
      final restoredCount = await provider.restoreFromBackupJson(backupJson);
      expect(restoredCount >= 13, true);

      // 验证林建已被自愈：3张原图回来了，AI报告回来了！
      final healedLinjian = provider.clues.firstWhere((c) => c.id == '1789782678573');
      expect(healedLinjian.chatRecords.length, 3);
      expect(healedLinjian.chatRecords.first.imageData != null, true);
      expect(healedLinjian.aiAnalysisReport != null, true);

      // 验证金闪闪与卡厄斯兰那也成功恢复
      final healedJin = provider.clues.firstWhere((c) => c.wxNick == '金闪闪想出去玩儿');
      expect(healedJin.aiAnalysisReport != null, true);

      final healedKae = provider.clues.firstWhere((c) => c.wxNick == '卡厄斯兰那');
      expect(healedKae.aiAnalysisReport != null, true);
      expect(healedKae.tags.contains('价格敏感'), true);
    });
  });
}
