import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crm_app/models/clue.dart';
import 'package:crm_app/providers/app_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('时间轴跟进记录修改与删除测试', () {
    test('【修改记录】updateVisitLog 成功修改内容、下次时间与意向，并打上修改时间戳', () async {
      final provider = AppProvider();
      await Future.delayed(const Duration(milliseconds: 50));

      final clueId = 'clue_unit_edit_001';
      final clue = Clue(
        id: clueId,
        wxNick: '学员小明',
        createTime: DateTime.now(),
        status: ClueStatus.contacted,
        intentLevel: IntentLevel.medium,
      );
      provider.addClue(clue);

      // 添加一条初始记录
      final logId = 'log_unit_001';
      final log = VisitLog(
        id: logId,
        clueId: clueId,
        contactMethod: ContactMethod.wechat,
        visitResult: VisitResult.normal,
        visitContent: '原沟通记录：询问报名时间',
        nextVisitTime: DateTime(2026, 10, 10, 10, 0),
        createTime: DateTime(2026, 10, 1, 9, 0),
      );
      await provider.addVisitLog(clueId, log);

      final addedClue = provider.getClueById(clueId)!;
      expect(addedClue.visitLogs.any((l) => l.id == logId), isTrue);

      // 执行修改
      final updatedNextTime = DateTime(2026, 10, 15, 14, 30);
      final updatedLog = log.copyWith(
        visitContent: '已修改：顾问打错字已更正，约15号试听',
        visitResult: VisitResult.trialBooked,
        nextVisitTime: updatedNextTime,
      );
      final success = await provider.updateVisitLog(
        clueId,
        updatedLog,
        newStatus: ClueStatus.invited,
        newIntentLevel: IntentLevel.high,
      );

      expect(success, isTrue);

      final modifiedClue = provider.getClueById(clueId)!;
      final target = modifiedClue.visitLogs.firstWhere((l) => l.id == logId);
      expect(target.visitContent, '已修改：顾问打错字已更正，约15号试听');
      expect(target.visitResult, VisitResult.trialBooked);
      expect(target.nextVisitTime, updatedNextTime);
      expect(target.updatedTime, isNotNull);
      expect(modifiedClue.status, ClueStatus.invited);
      expect(modifiedClue.intentLevel, IntentLevel.high);
      expect(modifiedClue.nextVisitTime, updatedNextTime);
    });

    test('【删除记录】deleteVisitLog 移除记录，生成墓碑并智能联动次回访时间', () async {
      final provider = AppProvider();
      await Future.delayed(const Duration(milliseconds: 50));

      final clueId = 'clue_unit_delete_002';
      final clue = Clue(
        id: clueId,
        wxNick: '学员小华',
        createTime: DateTime.now(),
        status: ClueStatus.contacted,
        intentLevel: IntentLevel.medium,
      );
      provider.addClue(clue);

      final olderLogTime = DateTime(2026, 10, 20, 10, 0);
      final olderLog = VisitLog(
        id: 'unit_older_log',
        clueId: clueId,
        contactMethod: ContactMethod.phone,
        visitResult: VisitResult.normal,
        visitContent: '较早记录：依然有效',
        nextVisitTime: olderLogTime,
        createTime: DateTime(2026, 9, 20, 9, 0),
      );
      await provider.addVisitLog(clueId, olderLog);

      final wrongLog = VisitLog(
        id: 'unit_wrong_log',
        clueId: clueId,
        contactMethod: ContactMethod.wechat,
        visitResult: VisitResult.normal,
        visitContent: '写错手滑的记录，需要删除',
        nextVisitTime: DateTime(2026, 10, 5, 10, 0),
        createTime: DateTime(2026, 9, 25, 9, 0),
      );
      await provider.addVisitLog(clueId, wrongLog);

      final beforeDelete = provider.getClueById(clueId)!;
      expect(beforeDelete.visitLogs.any((l) => l.id == 'unit_wrong_log'), isTrue);

      // 删除写错的记录
      final deleteSuccess = await provider.deleteVisitLog(clueId, 'unit_wrong_log');
      expect(deleteSuccess, isTrue);

      final afterDelete = provider.getClueById(clueId)!;
      // 1. 验证记录已从时间轴移除
      expect(afterDelete.visitLogs.any((l) => l.id == 'unit_wrong_log'), isFalse);
      // 2. 验证墓碑名单已记录该 ID
      expect(afterDelete.deletedVisitLogIds.contains('unit_wrong_log'), isTrue);
      // 3. 验证下次回访时间自动联动回退至剩余有效记录的次回访时间
      expect(afterDelete.nextVisitTime, olderLogTime);
    });

    test('【分布式防复活验证】多端同步合并时，被删除的回访记录绝对不被远端旧数据复活', () {
      final provider = AppProvider();

      // 本地线索：已删除 wrong_001，带有墓碑名单
      final localClue = Clue(
        id: 'clue_sync_test_01',
        wxNick: '学员大强',
        createTime: DateTime(2026, 9, 1),
        visitLogs: [
          VisitLog(
            id: 'valid_002',
            clueId: 'clue_sync_test_01',
            visitContent: '有效记录',
            createTime: DateTime(2026, 9, 10),
          ),
        ],
        deletedVisitLogIds: ['wrong_001'],
      );

      // 远端线索：旧数据里还包含 wrong_001
      final remoteClue = Clue(
        id: 'clue_sync_test_01',
        wxNick: '学员大强',
        createTime: DateTime(2026, 9, 1),
        visitLogs: [
          VisitLog(
            id: 'wrong_001',
            clueId: 'clue_sync_test_01',
            visitContent: '写错的历史记录（云端残留）',
            createTime: DateTime(2026, 9, 5),
          ),
          VisitLog(
            id: 'valid_002',
            clueId: 'clue_sync_test_01',
            visitContent: '有效记录',
            createTime: DateTime(2026, 9, 10),
          ),
        ],
        deletedVisitLogIds: [],
      );

      final needsUpload = <Clue>[];
      final merged = provider.mergeClueForTesting(localClue, remoteClue, needsUpload: needsUpload);

      // 验证已删除记录在合并时被拦截丢弃
      expect(merged.visitLogs.any((l) => l.id == 'wrong_001'), isFalse);
      expect(merged.visitLogs.length, 1);
      expect(merged.visitLogs.first.id, 'valid_002');
      expect(merged.deletedVisitLogIds.contains('wrong_001'), isTrue);
      // 验证自愈补推将墓碑推向云端
      expect(needsUpload.any((c) => c.id == 'clue_sync_test_01'), isTrue);
    });
  });
}
