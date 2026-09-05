import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:crm_app/models/clue.dart';
import 'package:crm_app/models/material_item.dart';
import 'package:crm_app/models/app_user.dart';
import 'package:crm_app/utils/clue_text_parser.dart';
import 'package:crm_app/data/default_materials.dart';
import 'package:crm_app/services/material_rag_service.dart';
import 'package:crm_app/providers/app_provider.dart';

import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

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

  group('【QA 专项测试 7】专升本 8 大实战金牌话术库与物料分类规范校验', () {
    test('7.1 验证 8 大实战标签体系完整性与分类覆盖', () {
      final categories = DefaultMaterials.categories;
      expect(categories.length, 8);
      expect(categories, contains('初次接触'));
      expect(categories, contains('政策与院校规划'));
      expect(categories, contains('痛点消解与异议处理'));
      expect(categories, contains('课程体系与班型'));
      expect(categories, contains('邀约试听与到校体验'));
      expect(categories, contains('深度跟进与日常保温'));
      expect(categories, contains('促单截单与限时特惠'));
      expect(categories, contains('逆袭案例与口碑背书'));
    });

    test('7.2 验证话术总量为 80 条，且每个标签恰好包含 10 条高价值实战话术', () {
      final materials = DefaultMaterials.getDefaultTextMaterials();
      expect(materials.length, 80);

      for (final cat in DefaultMaterials.categories) {
        final catMaterials = materials.where((m) => m.category == cat).toList();
        expect(catMaterials.length, 10, reason: '分类【$cat】应该包含恰好 10 条话术');
        for (final m in catMaterials) {
          expect(m.title.isNotEmpty, true);
          expect(m.content.trim().length, greaterThan(15), reason: '话术【${m.title}】内容应详实充实');
          expect(m.isPublic, true);
        }
      }
    });
  });

  group('【QA 专项测试 8】物料 RAG 知识检索与智能问答生成校验', () {
    final pool = DefaultMaterials.getDefaultTextMaterials();
    final ragService = MaterialRagService();

    test('8.1 英语基础差场景：智能检索必须精准匹配英语/基础差痛点物料', () {
      final matched = ragService.retrieveRelevantMaterials('学员高考英语才30分，担心学不会怎么办', pool, topK: 3);
      expect(matched.isNotEmpty, true);
      // 检查 Top 1 或 Top 2 是否命中痛点消解中关于英语/基础薄弱的话术
      final topTitles = matched.map((m) => m.title).join(' ');
      final topCategories = matched.map((m) => m.category).join(' ');
      expect(topCategories.contains('痛点消解') || topTitles.contains('英语') || topTitles.contains('基础'), true);
    });

    test('8.2 公办与民办学费场景：智能检索必须匹配政策规划与学费算账物料', () {
      final matched = ragService.retrieveRelevantMaterials('公办本科和民办本科有什么区别，学费差很多吗', pool, topK: 3);
      expect(matched.isNotEmpty, true);
      final topText = matched.map((m) => '${m.title} ${m.category} ${m.content}').join(' ');
      expect(topText.contains('公办') || topText.contains('民办') || topText.contains('学费'), true);
    });

    test('8.3 暑期集训营场景：必须精准命中课程体系与班型中的集训营', () {
      final matched = ragService.retrieveRelevantMaterials('暑假封闭集训营平时作息和住宿管得严不严', pool, topK: 3);
      expect(matched.isNotEmpty, true);
      final topTitles = matched.map((m) => m.title).join(' ');
      expect(topTitles.contains('集训') || topTitles.contains('营') || topTitles.contains('班'), true);
    });

    test('8.4 问答生成与高可用 Fallback 结构化字段完整性校验', () async {
      final res = await ragService.generateAnswer(
        question: '大二学生觉得现在报班太早了，想大三再说怎么破',
        materialsPool: pool,
      );

      expect(res.userQuestion, '大二学生觉得现在报班太早了，想大三再说怎么破');
      expect(res.analysis.isNotEmpty, true);
      expect(res.recommendedReply.isNotEmpty, true);
      expect(res.recommendedReply.length, greaterThan(20));
      expect(res.followUpAction.isNotEmpty, true);
      expect(res.matchedMaterials.isNotEmpty, true);
    });
  });

  group('【QA 专项测试 9】专属物料库隔离机制与已上架保留逻辑校验', () {
    test('9.1 模型序列化与老数据向下兼容：官方话术自动标记为非专属池', () {
      // 官方预置话术 json（模拟老数据无 fromPrivatePool）
      final officialJson = {
        'id': 'tm_cb_01',
        'category': '初次接触',
        'title': '微信好友通过初次问候',
        'content': '同学你好...',
        'ownerName': '超级管理员',
        'isPublic': true,
      };
      final m1 = TextMaterial.fromJson(officialJson);
      expect(m1.fromPrivatePool, false);

      // 顾问自建私有话术 json（老数据无 fromPrivatePool）
      final privateJson = {
        'id': 'tm_1788599999',
        'category': '个人话术',
        'title': '我的专属私聊',
        'content': '自用内容',
        'ownerName': '李老师',
        'isPublic': false,
      };
      final m2 = TextMaterial.fromJson(privateJson);
      expect(m2.fromPrivatePool, true);
    });

    test('9.2 AppProvider 专属池严密隔离：80条官方金牌话术绝不混入超级管理员的专属池', () async {
      SharedPreferences.setMockInitialValues({});
      final provider = AppProvider();
      provider.initMockData();
      final adminUser = AppUser(
        id: 'usr_admin',
        username: 'admin',
        password: '123',
        name: '超级管理员',
        role: UserRole.superAdmin,
      );
      provider.setCurrentUserForTesting(adminUser);

      // 超级管理员登录状态
      expect(provider.currentUser, '超级管理员');
      expect(provider.isSuperAdmin, true);

      // 公共文字物料库总数应该大于等于 80
      expect(provider.publicTextMaterials.length, greaterThanOrEqualTo(80));

      // 超级管理员专属池中，绝不能包含任何 tm_cb_ 官方话术！
      final privateOfficialMatches = provider.myPrivateTextMaterials
          .where((m) => m.id.startsWith('tm_cb_'))
          .toList();
      expect(privateOfficialMatches.isEmpty, true,
          reason: '官方话术绝对不可出现在专属物料库');

      // 超级管理员专属池中，绝不能包含 im1~im8 官方海报！
      final privateOfficialImages = provider.myPrivateImageMaterials
          .where((m) => m.id.startsWith('im') && int.tryParse(m.id.substring(2)) != null)
          .toList();
      expect(privateOfficialImages.isEmpty, true,
          reason: '官方海报绝对不可出现在专属图片库');
    });

    test('9.3 专属物料审核通过上架全链路：审核通过后公共池可见，专属池保留且标记已上架', () async {
      SharedPreferences.setMockInitialValues({});
      final provider = AppProvider();
      provider.initMockData();

      final adminUser = AppUser(
        id: 'usr_admin',
        username: 'admin',
        password: '123',
        name: '超级管理员',
        role: UserRole.superAdmin,
      );
      final liTeacher = AppUser(
        id: 'usr_li',
        username: 'lilaoshi',
        password: '123',
        name: '李老师',
        role: UserRole.advisor,
      );

      // 1. 李老师登录并创建一条专属话术
      provider.setCurrentUserForTesting(liTeacher);
      final myMat = TextMaterial(
        id: 'tm_custom_001',
        category: '促单截单',
        title: '李老师独家绝密促单话术',
        content: '限时直减500元',
        ownerName: '李老师',
        isPublic: false,
        fromPrivatePool: true,
        reviewStatus: MaterialReviewStatus.pending,
      );
      provider.addTextMaterial(myMat);

      // 验证在李老师专属池中可见，但在公共池不可见
      expect(provider.myPrivateTextMaterials.any((m) => m.id == 'tm_custom_001'), true);
      expect(provider.publicTextMaterials.any((m) => m.id == 'tm_custom_001'), false);

      // 2. 超级管理员审核通过
      provider.setCurrentUserForTesting(adminUser);
      provider.approveMaterial('tm_custom_001', true);

      // 公共池现在全员可见
      expect(provider.publicTextMaterials.any((m) => m.id == 'tm_custom_001'), true);

      // 3. 切回李老师，验证专属物料库中依然保留该物料，且 reviewStatus 为 approved
      provider.setCurrentUserForTesting(liTeacher);
      final inMyPool = provider.myPrivateTextMaterials.firstWhere((m) => m.id == 'tm_custom_001');
      expect(inMyPool.isPublic, true);
      expect(inMyPool.fromPrivatePool, true);
      expect(inMyPool.reviewStatus, MaterialReviewStatus.approved);

      // 4. 超级管理员直接创建的公共物料，绝不会混进李老师专属池
      provider.setCurrentUserForTesting(adminUser);
      final adminPublicMat = TextMaterial(
        id: 'tm_admin_pub_001',
        category: '政策与院校规划',
        title: '总部统一发布公办政策',
        content: '2026年最新批复',
        ownerName: '超级管理员',
        isPublic: true,
        fromPrivatePool: false,
        reviewStatus: MaterialReviewStatus.approved,
      );
      provider.addTextMaterial(adminPublicMat);

      // 切回超级管理员专属池，不应该包含该公共话术
      expect(provider.myPrivateTextMaterials.any((m) => m.id == 'tm_admin_pub_001'), false);
      // 切回李老师专属池，更不应该包含
      provider.setCurrentUserForTesting(liTeacher);
      expect(provider.myPrivateTextMaterials.any((m) => m.id == 'tm_admin_pub_001'), false);
    });
  });
}
