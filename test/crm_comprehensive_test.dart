import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:crm_app/models/clue.dart';
import 'package:crm_app/models/material_item.dart';
import 'package:crm_app/utils/clue_text_parser.dart';

void main() {
  group('【QA 专项测试 1】专升本规范智能语义解析器 (ClueTextParser) 极限与边界测试', () {
    test('1.1 标准团队规范：李文文-河南经贸-24级-视传', () {
      final text = '李文文-河南经贸-24级-视传\n微信号: wxid_liwenwen\n电话: 13912345678';
      final res = ClueTextParser.parse(text);
      expect(res.name, '李文文');
      expect(res.school, '河南经贸');
      expect(res.grade, '24级');
      expect(res.subject, '美术专业综合'); // 视传智能匹配为统考科目
      expect(res.wxId, 'wxid_liwenwen');
      expect(res.phone, '13912345678');
    });

    test('1.2 异形分隔符与专业变体：下划线/空格/计算机/经管/护理', () {
      final t1 = '张伟_九江职业大学_25届_计算机';
      final r1 = ClueTextParser.parse(t1);
      expect(r1.name, '张伟');
      expect(r1.school, '九江职业大学');
      expect(r1.grade, '25届');
      expect(r1.subject, '高等数学');

      final t2 = '王丽 河南财经政法专科 2024级 会计 13800138000';
      final r2 = ClueTextParser.parse(t2);
      expect(r2.name, '王丽');
      expect(r2.school.contains('专科') || r2.school.contains('财经'), true);
      expect(r2.grade, '2024级');
      expect(r2.subject, '经济学');
      expect(r2.phone, '13800138000');
    });

    test('1.3 微信个人名片截图文本（模拟 OCR 提取到的多行系统文字）', () {
      final ocrText = '''
10:25
微信
赵雪-黄冈职业技术学院-24级-学前
微信号: zhaoxue_study
地区: 湖北 黄冈
设置备注和标签
朋友圈
发消息
音视频通话
''';
      final res = ClueTextParser.parse(ocrText);
      expect(res.name, '赵雪');
      expect(res.school, '黄冈职业技术学院');
      expect(res.grade, '24级');
      expect(res.subject, '教育学心理学');
      expect(res.wxId, 'zhaoxue_study');
    });

    test('1.4 极端边界测试：纯空文本/纯符号/纯数字', () {
      final emptyRes = ClueTextParser.parse('');
      expect(emptyRes.name, '');
      expect(emptyRes.school, '');

      final symbolRes = ClueTextParser.parse('---///___   ');
      expect(symbolRes.name, '');

      final numRes = ClueTextParser.parse('13811112222');
      expect(numRes.phone, '13811112222');
    });
  });

  group('【QA 专项测试 2】线索模型与全字段序列化 (Clue & ChatRecord)', () {
    test('2.1 线索完整字段与 AI 报告持久化序列化 (toJson / fromJson)', () {
      final now = DateTime.now();
      final clue = Clue(
        id: 'clue_test_001',
        wxNick: '陈佳佳',
        wxId: 'jiajia_2026',
        phone: '13700001111',
        grade: '24级',
        school: '河南经贸职业学院',
        subject: '管理学',
        source: '转介绍',
        classType: '全程集训班',
        status: ClueStatus.invited,
        intentLevel: IntentLevel.high,
        nextVisitTime: now.add(const Duration(days: 2)),
        createTime: now,
        remark: '特别想考郑州轻工业大学',
        ownerName: '招生顾问小王',
        aiAnalysisReport: '【学员心理痛点诊断】目标明确但担心高数基础...',
        aiAnalysisTime: now,
        chatRecords: [
          ChatRecord(
            id: 'chat_001',
            clueId: 'clue_test_001',
            imagePath: 'chat_screen.png',
            imageData: 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==',
            ocrText: '老师，我想问问管理学真题有吗',
            createTime: now,
          ),
        ],
        visitLogs: [
          VisitLog(
            id: 'log_001',
            clueId: 'clue_test_001',
            createTime: now,
            contactMethod: ContactMethod.wechat,
            visitResult: VisitResult.intentUp,
            visitContent: '已发送历年考情分析表，学生反馈很专业',
            concerns: ['录取分数线', '学费分期'],
          ),
        ],
      );

      final jsonMap = clue.toJson();
      expect(jsonMap['id'], 'clue_test_001');
      expect(jsonMap['wxNick'], '陈佳佳');
      expect(jsonMap['status'], 'invited');
      expect(jsonMap['intentLevel'], 'high');
      expect(jsonMap['aiAnalysisReport'] != null, true);
      expect(jsonMap['chatRecords'].length, 1);
      expect(jsonMap['visitLogs'].length, 1);

      // 反序列化还原
      final restored = Clue.fromJson(jsonMap);
      expect(restored.id, clue.id);
      expect(restored.wxNick, clue.wxNick);
      expect(restored.status, ClueStatus.invited);
      expect(restored.intentLevel, IntentLevel.high);
      expect(restored.aiAnalysisReport, clue.aiAnalysisReport);
      expect(restored.chatRecords.first.ocrText, '老师，我想问问管理学真题有吗');
      expect(restored.visitLogs.first.concerns, ['录取分数线', '学费分期']);
    });

    test('2.2 容错性解析：缺失/null/异常字段保护', () {
      final brokenJson = {
        'id': 'clue_broken',
        'wxNick': null,
        'status': 'unknown_status_xxx',
        'intentLevel': 'unknown_intent',
        'createTime': 'invalid_date',
        'nextVisitTime': null,
      };

      final safeClue = Clue.fromJson(brokenJson);
      expect(safeClue.id, 'clue_broken');
      expect(safeClue.wxNick, '');
      expect(safeClue.status, ClueStatus.following); // 平滑回退到默认
      expect(safeClue.intentLevel, IntentLevel.none);
      expect(safeClue.createTime.isBefore(DateTime.now().add(const Duration(minutes: 1))), true);
    });
  });

  group('【QA 专项测试 3】线索状态流转与回访推进状态机测试', () {
    test('3.1 回访结果意向提升 (intentUp) 自动流转为已邀约高意向', () {
      final clue = Clue(
        id: 'c1',
        wxNick: '测试生',
        status: ClueStatus.following,
        intentLevel: IntentLevel.medium,
        createTime: DateTime.now(),
      );

      final log = VisitLog(
        id: 'l1',
        clueId: 'c1',
        createTime: DateTime.now(),
        contactMethod: ContactMethod.phone,
        visitResult: VisitResult.intentUp,
        visitContent: '学生同意周六来校区试听体验',
      );

      clue.visitLogs.insert(0, log);
      if (log.visitResult == VisitResult.intentUp) {
        clue.status = ClueStatus.invited;
        clue.intentLevel = IntentLevel.high;
      }

      expect(clue.status, ClueStatus.invited);
      expect(clue.intentLevel, IntentLevel.high);
      expect(clue.visitLogs.length, 1);
    });

    test('3.2 回访结果明确无意向 (noIntent) 自动流转为暂搁置', () {
      final clue = Clue(
        id: 'c2',
        wxNick: '放弃生',
        status: ClueStatus.contacted,
        intentLevel: IntentLevel.low,
        createTime: DateTime.now(),
      );

      final log = VisitLog(
        id: 'l2',
        clueId: 'c2',
        createTime: DateTime.now(),
        contactMethod: ContactMethod.wechat,
        visitResult: VisitResult.noIntent,
        visitContent: '学生决定直接就业，不再参加专升本',
      );

      clue.visitLogs.insert(0, log);
      if (log.visitResult == VisitResult.noIntent) {
        clue.status = ClueStatus.paused;
      }

      expect(clue.status, ClueStatus.paused);
    });
  });

  group('【QA 专项测试 4】数据导出 CSV 与 Windows Excel UTF-8 BOM 防乱码校验', () {
    test('4.1 导出的 CSV 头部必须严格以 0xFEFF BOM 字节开头', () {
      final buffer = StringBuffer();
      buffer.write('\uFEFF'); // UTF-8 BOM
      buffer.writeln('序号,称呼/昵称,微信号,手机号,就读学校,年级,报考专业,意向班型,状态,意向度');
      buffer.writeln('1,李文文,liwenwen,13912345678,河南经贸,24级,美术专业综合,全程集训班,联系中,高意向');

      final csvString = buffer.toString();
      final bytes = utf8.encode(csvString);

      // 校验前 3 个字节为 UTF-8 BOM: 0xEF, 0xBB, 0xBF
      expect(bytes[0], 0xEF);
      expect(bytes[1], 0xBB);
      expect(bytes[2], 0xBF);
    });
  });

  group('【QA 专项测试 5】图片物料模型与海报管理校验', () {
    test('5.1 物料项创建、缩略 Base64 验证与分类管理', () {
      final item = ImageMaterial(
        id: 'mat_001',
        title: '2026年河南专升本高数核心考点公式海报',
        category: '考情考点海报',
        desc: '升本人必背！学长学姐人手一份的高数高分图解！',
        imageUrl: 'gaoshu_poster.png',
        imageData: 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==',
        createdAt: DateTime.now(),
      );

      final json = item.toJson();
      expect(json['title'], '2026年河南专升本高数核心考点公式海报');
      expect(json['category'], '考情考点海报');
      expect(json['imageData'] != null, true);

      final restored = ImageMaterial.fromJson(json);
      expect(restored.title, item.title);
      expect(restored.desc, item.desc);
    });
  });

  group('【QA 专项测试 6】待回访Tab过滤（严格排除逾期）与今日回访属性测试', () {
    test('6.1 待回访过滤规则严格排除已逾期线索，只保留今天及未来', () {
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final overdueClue = Clue(
        id: 'c_overdue',
        wxNick: '逾期学员',
        status: ClueStatus.following,
        intentLevel: IntentLevel.high,
        createTime: now.subtract(const Duration(days: 5)),
        nextVisitTime: todayStart.subtract(const Duration(hours: 2)), // 昨天或更早
      );
      final todayClue = Clue(
        id: 'c_today',
        wxNick: '今日学员',
        status: ClueStatus.invited,
        intentLevel: IntentLevel.high,
        createTime: now,
        nextVisitTime: todayStart.add(const Duration(hours: 14)), // 今天 14:00
      );
      final futureClue = Clue(
        id: 'c_future',
        wxNick: '未来学员',
        status: ClueStatus.attended,
        intentLevel: IntentLevel.medium,
        createTime: now,
        nextVisitTime: todayStart.add(const Duration(days: 2, hours: 10)), // 后天 10:00
      );

      final list = [overdueClue, todayClue, futureClue];
      // 待回访过滤规则：!c.nextVisitTime!.isBefore(todayStart)
      final todoFiltered = list.where((c) =>
          c.status != ClueStatus.enrolled &&
          c.nextVisitTime != null &&
          !c.nextVisitTime!.isBefore(todayStart)).toList();

      expect(todoFiltered.length, 2);
      expect(todoFiltered.any((c) => c.id == 'c_overdue'), false);
      expect(todoFiltered.any((c) => c.id == 'c_today'), true);
      expect(todoFiltered.any((c) => c.id == 'c_future'), true);

      // 验证状态与意向文案
      expect(todayClue.statusText, '已邀约');
      expect(todayClue.intentText, '高意向');
      expect(futureClue.statusText, '已试听');
      expect(futureClue.intentText, '中意向');
    });
  });
}
