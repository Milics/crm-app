import 'package:flutter_test/flutter_test.dart';
import 'package:crm_app/models/initial_real_clues.dart';
import 'package:crm_app/models/clue.dart';
import 'package:crm_app/services/smart_script_engine.dart';

void main() {
  group('SmartScriptEngine 测试', () {
    test('从林建的 AI 报告中正确提取高情商口头化话术', () {
      final clue = InitialRealClues.getClues().firstWhere((c) => c.wxNick.contains('林建'));
      final scenarios = SmartScriptEngine.generate(clue);

      expect(scenarios.length, 3);
      // 第一步定心丸
      expect(scenarios[0].content, contains('林同学，你放心！咱们这个班型就是专门为你这种25届考生定制'));
      expect(scenarios[0].content, contains('绝不会有任何二次收费'));
      // 不应包含原本官方生硬的“你看今天下午或晚上方便语音聊 3 分钟详细说说吗”
      expect(scenarios[0].content, isNot(contains('方便语音聊 3 分钟')));

      // 第二步榜样案例
      expect(scenarios[1].content, contains('林州建筑上一届美术专业综合的张学长'));

      // 第三步逼单
      expect(scenarios[2].content, contains('把名字和收件地址发我'));
    });

    test('从金闪闪的 AI 报告中正确提取降压破冰、资料诱饵与轻量探讨', () {
      final clue = InitialRealClues.getClues().firstWhere((c) => c.wxNick.contains('金闪闪'));
      final scenarios = SmartScriptEngine.generate(clue);

      expect(scenarios.length, 3);
      // 第一步破冰降压
      expect(scenarios[0].content, contains('闪闪同学，这两天看你没回微信，估计在忙学校专业课作业～不用有压力哈！'));
      expect(scenarios[0].content, contains('《美术专业综合历年高分范画与色彩避坑指南》PDF'));

      // 第二步专业探讨引导开口
      expect(scenarios[1].content, contains('经贸今年大二的素描和色彩写生课程'));
      expect(scenarios[1].content, contains('是色彩调色偏灰，还是素描形体结构吃力一些呢？'));

      // 第三步视频探校
      expect(scenarios[2].content, contains('国庆假期咱们校区有经贸专场的微写生集训营'));
    });

    test('从卡厄斯兰那的 AI 报告中正确提取赋能家长与免息分期话术', () {
      final clue = InitialRealClues.getClues().firstWhere((c) => c.wxNick.contains('卡厄斯兰那'));
      final scenarios = SmartScriptEngine.generate(clue);

      expect(scenarios.length, 3);
      // 第一步理解共情赋能家长
      expect(scenarios[0].content, contains('卡同学，特别理解！'));
      expect(scenarios[0].content, contains('《25届公办本科升学规划与投资回报表》'));

      // 第二步免息分期
      expect(scenarios[1].content, contains('高校助学免息分期通道'));
      expect(scenarios[1].content, contains('每个月仅需几百元'));

      // 第三步定金逼单
      expect(scenarios[2].content, contains('200元预留定金'));
    });

    test('针对无 AI 报告且跟进记录有“未回复微信”的普通线索，生成降压型干货破冰话题', () {
      final clue = Clue(
        id: 'test_clue_01',
        wxNick: '王同学',
        school: '郑州轻工业大学',
        subject: '英语专升本',
        status: ClueStatus.following,
        intentLevel: IntentLevel.medium,
        tags: ['价格敏感', '基础薄弱'],
        createTime: DateTime.now(),
        visitLogs: [
          VisitLog(
            id: 'log_01',
            clueId: 'test_clue_01',
            contactMethod: ContactMethod.wechat,
            visitResult: VisitResult.normal,
            visitContent: '发了微信课程介绍，学生未回复微信',
            createTime: DateTime.now(),
          ),
        ],
      );

      final scenarios = SmartScriptEngine.generate(clue);
      expect(scenarios.length, 3);
      // 破冰开口必须体现降压与未回复关怀
      expect(scenarios[0].content, contains('这两天看你没回微信，估计在忙学校专业课或实训作业，不用有压力哈！'));
      expect(scenarios[0].content, contains('《近几年历年高分范画与备考避坑指南》PDF'));
      expect(scenarios[0].content, isNot(contains('方便语音聊 3 分钟')));

      // 打消顾虑直击价格敏感
      expect(scenarios[1].content, contains('学费这块你完全放宽心！'));
      expect(scenarios[1].content, contains('早鸟助学免息分期'));
    });
  });
}
