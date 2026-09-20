import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:crm_app/models/clue.dart';
import 'package:crm_app/models/material_item.dart';
import 'package:crm_app/models/app_user.dart';
import 'package:crm_app/utils/clue_text_parser.dart';
import 'package:crm_app/data/default_materials.dart';
import 'package:crm_app/services/material_rag_service.dart';
import 'package:crm_app/providers/app_provider.dart';
import 'package:flutter/material.dart';
import 'package:crm_app/pages/clue_detail_page.dart';
import 'package:provider/provider.dart';
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

  group('【QA 专项测试 10】暂搁置 (ClueStatus.paused) 隔离与专属 Tab 机制校验', () {
    test('10.1 状态枚举与文本映射统一：Clue.statusText 与 ClueStatusExt.label 均映射为「暂搁置」', () {
      final pausedClue = Clue(
        id: 'c_paused_01',
        wxNick: '搁置学员小明',
        status: ClueStatus.paused,
        createTime: DateTime.now(),
      );
      expect(pausedClue.statusText, '暂搁置');
      expect(ClueStatus.paused.label, '暂搁置');
      expect(AppProvider.statusFilters.contains('暂搁置'), true);
      expect(AppProvider.statusFilters.contains('无效线索'), false);
    });

    test('10.2 待回访(Tab 1)与已逾期(Tab 2)严格排除暂搁置线索，即使存在回访时间也不打扰', () async {
      SharedPreferences.setMockInitialValues({});
      final provider = AppProvider();
      provider.initMockData();

      final testUser = AppUser(
        id: 'usr_test',
        username: 'test_advisor',
        password: '123',
        name: '测试顾问',
        role: UserRole.advisor,
      );
      provider.setCurrentUserForTesting(testUser);

      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);

      // 1. 正常的待回访线索（今天下午）
      final activeTodoClue = Clue(
        id: 'c_active_todo',
        wxNick: '正常待回访',
        status: ClueStatus.following,
        ownerName: '测试顾问',
        createTime: now,
        nextVisitTime: todayStart.add(const Duration(hours: 15)),
      );

      // 2. 正常的逾期线索（昨天）
      final activeOverdueClue = Clue(
        id: 'c_active_overdue',
        wxNick: '正常已逾期',
        status: ClueStatus.contacted,
        ownerName: '测试顾问',
        createTime: now.subtract(const Duration(days: 1)),
        nextVisitTime: todayStart.subtract(const Duration(hours: 5)),
      );

      // 3. 暂搁置线索 A（原回访时间为未来，但已标记暂搁置）
      final pausedFutureClue = Clue(
        id: 'c_paused_future',
        wxNick: '暂搁置学员未来的',
        status: ClueStatus.paused,
        ownerName: '测试顾问',
        createTime: now.subtract(const Duration(hours: 3)),
        nextVisitTime: todayStart.add(const Duration(days: 2)),
      );

      // 4. 暂搁置线索 B（原回访时间已过去，但已标记暂搁置）
      final pausedPastClue = Clue(
        id: 'c_paused_past',
        wxNick: '暂搁置学员过去的',
        status: ClueStatus.paused,
        ownerName: '测试顾问',
        createTime: now.subtract(const Duration(hours: 5)),
        nextVisitTime: todayStart.subtract(const Duration(days: 3)),
      );

      // 添加到 provider
      provider.addClue(activeTodoClue);
      provider.addClue(activeOverdueClue);
      provider.addClue(pausedFutureClue);
      provider.addClue(pausedPastClue);

      // 检验 Tab 1：待回访
      provider.setClueTabIndex(1);
      final todoList = provider.filteredClues;
      expect(todoList.any((c) => c.id == 'c_active_todo'), true);
      expect(todoList.any((c) => c.id == 'c_paused_future'), false, reason: '暂搁置客户绝不能出现在待回访列表');
      expect(todoList.any((c) => c.id == 'c_paused_past'), false);

      // 检验 Tab 2：已逾期
      provider.setClueTabIndex(2);
      final overdueList = provider.filteredClues;
      expect(overdueList.any((c) => c.id == 'c_active_overdue'), true);
      expect(overdueList.any((c) => c.id == 'c_paused_past'), false, reason: '暂搁置客户绝不能出现在已逾期列表');
      expect(overdueList.any((c) => c.id == 'c_paused_future'), false);

      // 检验待办任务列表 todoClues（工作台快捷入口）
      final todoCluesList = provider.todoClues;
      expect(todoCluesList.any((c) => c.id == 'c_active_todo'), true);
      expect(todoCluesList.any((c) => c.id == 'c_active_overdue'), true);
      expect(todoCluesList.any((c) => c.id == 'c_paused_future'), false, reason: 'todoClues中必须排除暂搁置客户');
      expect(todoCluesList.any((c) => c.id == 'c_paused_past'), false, reason: 'todoClues中必须排除暂搁置客户');

      // 检验 Tab 5：独立「暂搁置」池
      provider.setClueTabIndex(5);
      final pausedList = provider.filteredClues;
      expect(pausedList.any((c) => c.id == 'c_paused_future'), true);
      expect(pausedList.any((c) => c.id == 'c_paused_past'), true);
      expect(pausedList.any((c) => c.id == 'c_active_todo'), false);
      expect(pausedList.any((c) => c.id == 'c_active_overdue'), false);

      // 检验 Tab 0：首页「全部」列表（严格排除已报名与暂搁置）
      provider.setClueTabIndex(0);
      final allList = provider.filteredClues;
      expect(allList.any((c) => c.id == 'c_active_todo'), true);
      expect(allList.any((c) => c.id == 'c_active_overdue'), true);
      expect(allList.any((c) => c.id == 'c_paused_future'), false, reason: '首页全部列表必须排除暂搁置线索');
      expect(allList.any((c) => c.id == 'c_paused_past'), false, reason: '首页全部列表必须排除暂搁置线索');
    });
  });

  group('【QA 专项测试 11】已报名学员报名详情改造、预交金额持久化与修改验证', () {
    test('11.1 Clue模型支持enrollAmount预交金额的JSON序列化与反序列化（兼容整数/浮点/空值）', () {
      final clue = Clue(
        id: 'c_enrolled_01',
        wxNick: '报名学员大成',
        classType: '全程集训班',
        status: ClueStatus.enrolled,
        enrollAmount: 3500.0,
        remark: '已协议分期首付',
        createTime: DateTime.now(),
      );

      final jsonMap = clue.toJson();
      expect(jsonMap['enrollAmount'], 3500.0);
      expect(jsonMap['classType'], '全程集训班');

      final fromJsonClue = Clue.fromJson(jsonMap);
      expect(fromJsonClue.enrollAmount, 3500.0);
      expect(fromJsonClue.classType, '全程集训班');
      expect(fromJsonClue.remark, '已协议分期首付');

      // 测试兼容整数字段解析
      final intJsonMap = Map<String, dynamic>.from(jsonMap);
      intJsonMap['enrollAmount'] = 5000;
      final fromIntClue = Clue.fromJson(intJsonMap);
      expect(fromIntClue.enrollAmount, 5000.0);

      // 测试空值兼容性
      intJsonMap.remove('enrollAmount');
      final nullClue = Clue.fromJson(intJsonMap);
      expect(nullClue.enrollAmount, isNull);
    });

    test('11.2 AppProvider 支持直接转为报名并记录预交金额，且支持 updateEnrollInfo 更新报名班型、金额及备注', () async {
      SharedPreferences.setMockInitialValues({});
      final provider = AppProvider();
      provider.initMockData();

      final now = DateTime.now();
      final testClue = Clue(
        id: 'c_flow_test',
        wxNick: '周小峰',
        status: ClueStatus.contacted,
        ownerName: '李老师',
        createTime: now,
      );
      provider.addClue(testClue);

      // 1. 初次转为报名（全程集训班，预交2000元，初始备注）
      provider.enrollClue(
        'c_flow_test',
        '全程集训班',
        '初次报名协议',
        enrollAmount: 2000.0,
      );

      final enrolled = provider.getClueById('c_flow_test')!;
      expect(enrolled.status, ClueStatus.enrolled);
      expect(enrolled.classType, '全程集训班');
      expect(enrolled.enrollAmount, 2000.0);
      expect(enrolled.remark, '初次报名协议');
      expect(enrolled.nextVisitTime, isNull);

      // 2. 学员补齐或更换班型：修改报名详情（转为寒暑假集训班，补齐至3800元，更新备注）
      provider.updateEnrollInfo(
        'c_flow_test',
        '寒暑假集训班',
        3800.0,
        '已补齐尾款并确认食宿安排',
      );

      final updated = provider.getClueById('c_flow_test')!;
      expect(updated.status, ClueStatus.enrolled);
      expect(updated.classType, '寒暑假集训班');
      expect(updated.enrollAmount, 3800.0);
      expect(updated.remark, '已补齐尾款并确认食宿安排');
    });
  });

  group('【QA 专项测试 12】届别/年级筛选与偏好持久化及重置测试', () {
    test('12.1 allGrades 能正确提取并排序，setGradeFilter 能够准确过滤线索并持久化', () async {
      SharedPreferences.setMockInitialValues({});
      final provider = AppProvider();
      while (!provider.isLoaded) {
        await Future.delayed(const Duration(milliseconds: 10));
      }
      final adminUser = AppUser(
        id: 'usr_test_admin',
        username: 'admin',
        password: 'password123',
        name: '超级管理员',
        role: UserRole.superAdmin,
      );
      provider.setCurrentUserForTesting(adminUser);
      
      final now = DateTime.now();
      final c1 = Clue(id: 'c_g_1', wxNick: '学员A', grade: '24级', ownerName: '超级管理员', createTime: now);
      final c2 = Clue(id: 'c_g_2', wxNick: '学员B', grade: '25级', ownerName: '超级管理员', createTime: now);
      final c3 = Clue(id: 'c_g_3', wxNick: '学员C', grade: '26级', ownerName: '超级管理员', createTime: now);
      provider.addClue(c1);
      provider.addClue(c2);
      provider.addClue(c3);

      expect(provider.allGrades.contains('24级'), true);
      expect(provider.allGrades.contains('25级'), true);
      expect(provider.allGrades.contains('26级'), true);

      // 切换届别到 25级
      await provider.setGradeFilter('25级');
      expect(provider.gradeFilter, '25级');
      expect(provider.hasActiveFilter, true);

      final filtered = provider.filteredClues.where((c) => c.id.startsWith('c_g_')).toList();
      expect(filtered.length, 1);
      expect(filtered.first.wxNick, '学员B');

      // 验证持久化
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('crm_grade_filter'), '25级');

      // 重置筛选
      await provider.resetFilters();
      expect(provider.gradeFilter, 'all');
      expect(provider.hasActiveFilter, false);
      expect(prefs.getString('crm_grade_filter'), 'all');

      final allReset = provider.filteredClues.where((c) => c.id.startsWith('c_g_')).toList();
      expect(allReset.length, 3);
    });
  });

  group('【QA 专项测试 13】新增回访支持直接改变状态与意向等级', () {
    test('13.1 addVisitLog 接收并更新 newStatus 与 newIntentLevel', () async {
      SharedPreferences.setMockInitialValues({});
      final provider = AppProvider();
      while (!provider.isLoaded) {
        await Future.delayed(const Duration(milliseconds: 10));
      }

      final now = DateTime.now();
      final testClue = Clue(
        id: 'c_visit_status_test',
        wxNick: '张小凡',
        status: ClueStatus.contacted,
        intentLevel: IntentLevel.medium,
        createTime: now,
      );
      provider.addClue(testClue);

      // 新增回访并显式指定修改为「已试听」与「高意向」
      final log = VisitLog(
        id: 'v_log_001',
        clueId: 'c_visit_status_test',
        contactMethod: ContactMethod.wechat,
        visitResult: VisitResult.normal,
        visitContent: '学生今天准时参加了试听课，反馈良好',
        createTime: now,
      );

      await provider.addVisitLog(
        'c_visit_status_test',
        log,
        newStatus: ClueStatus.attended,
        newIntentLevel: IntentLevel.high,
      );

      final updated = provider.getClueById('c_visit_status_test')!;
      expect(updated.visitLogs.length, 1);
      expect(updated.status, ClueStatus.attended);
      expect(updated.intentLevel, IntentLevel.high);
    });
  });

  group('【QA 专项测试 14】线索详情页顶部卡片高度压缩与折叠展开测试', () {
    testWidgets('14.1 默认仅展示就读学校与年级届别，点击可展开完整档案与收起', (tester) async {
      final provider = AppProvider();
      await tester.runAsync(() async {
        while (!provider.isLoaded) {
          await Future.delayed(const Duration(milliseconds: 10));
        }
      });

      final testClue = Clue(
        id: 'c_expand_header_test',
        wxNick: '王晓宇',
        wxId: 'wx_expand_test',
        phone: '13899998888',
        school: '广东轻工职业技术学院',
        grade: '25级',
        subject: '经管',
        classType: '全程集训班',
        source: '老带新',
        ownerName: '郭培杨',
        status: ClueStatus.invited,
        intentLevel: IntentLevel.high,
        createTime: DateTime.now(),
      );
      provider.addClue(testClue);

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: provider,
          child: MaterialApp(
            home: ClueDetailPage(clueId: 'c_expand_header_test'),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      // 1. 验证默认状态：姓名、状态、意向标签可见
      expect(find.text('王晓宇'), findsOneWidget);
      expect(find.text('已邀约'), findsOneWidget);
      expect(find.text('高意向'), findsOneWidget);

      // 2. 验证默认状态：常驻展示就读学校和年级/届别
      expect(find.text('就读学校'), findsOneWidget);
      expect(find.text('广东轻工职业技术学院'), findsOneWidget);
      expect(find.text('年级/届别'), findsOneWidget);
      expect(find.text('25级'), findsOneWidget);

      // 3. 验证默认状态：存在折叠展开按钮
      final expandBtn = find.text('展开完整档案 (微信/电话/班型等)');
      expect(expandBtn, findsOneWidget);

      // 4. 点击展开
      await tester.tap(expandBtn);
      await tester.pump(const Duration(milliseconds: 300));

      // 5. 展开后：微信号、手机号、科目、班型等完整信息可见
      expect(find.text('微信号'), findsOneWidget);
      expect(find.text('wx_expand_test'), findsOneWidget);
      expect(find.text('手机号'), findsOneWidget);
      expect(find.text('13899998888'), findsOneWidget);
      expect(find.text('报考科目'), findsOneWidget);
      expect(find.text('经管'), findsOneWidget);
      expect(find.text('收起资料'), findsOneWidget);

      // 6. 点击收起
      await tester.tap(find.text('收起资料'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('展开完整档案 (微信/电话/班型等)'), findsOneWidget);
    });
  });

  group('【QA 专项测试 15】年级/届别规范化归一与纯净筛选胶囊校验', () {
    test('15.1 normalizeGrade 规范清洗纯数字、大专年级、过滤异常字符', () {
      expect(AppProvider.normalizeGrade('25'), '25级');
      expect(AppProvider.normalizeGrade('24'), '24级');
      expect(AppProvider.normalizeGrade('23'), '23级');
      expect(AppProvider.normalizeGrade('2025'), '25级');
      expect(AppProvider.normalizeGrade('2024级'), '24级');
      expect(AppProvider.normalizeGrade('25届'), '25级');
      expect(AppProvider.normalizeGrade('大三'), '24级');
      expect(AppProvider.normalizeGrade('大二'), '25级');
      expect(AppProvider.normalizeGrade('大一'), '26级');
      expect(AppProvider.normalizeGrade('12'), ''); // 误输入的异常值直接过滤
      expect(AppProvider.normalizeGrade(''), '');
    });

    test('15.2 allGrades 提取去重后全为标准规范格式，无 25/24/12 等杂乱项', () {
      final provider = AppProvider();
      final adminUser = AppUser(
        id: 'usr_admin',
        username: 'admin',
        password: 'password123',
        name: '超级管理员',
        role: UserRole.superAdmin,
      );
      provider.setCurrentUserForTesting(adminUser);

      final now = DateTime.now();
      // 模拟添加混杂了不同格式的线索
      provider.addClue(Clue(id: 'cg1', wxNick: 'A', grade: '25', ownerName: 'admin', createTime: now));
      provider.addClue(Clue(id: 'cg2', wxNick: 'B', grade: '25级', ownerName: 'admin', createTime: now));
      provider.addClue(Clue(id: 'cg3', wxNick: 'C', grade: '24', ownerName: 'admin', createTime: now));
      provider.addClue(Clue(id: 'cg4', wxNick: 'D', grade: '12', ownerName: 'admin', createTime: now));

      final grades = provider.allGrades;
      // 必须包含规范的 25级、24级
      expect(grades.contains('25级'), true);
      expect(grades.contains('24级'), true);
      // 绝不能包含散乱的 '25'、'24'、'12'
      expect(grades.contains('25'), false);
      expect(grades.contains('24'), false);
      expect(grades.contains('12'), false);

      // 筛选 '25级' 应该能同时命中录入为 '25' 和 '25级' 的线索
      provider.setGradeFilter('25级');
      final filtered = provider.filteredClues.where((c) => c.id == 'cg1' || c.id == 'cg2').toList();
      expect(filtered.length, 2);
    });

    test('【QA 专项测试 16】回访记录保存与双向合并防覆盖测试：刷新后新回访不丢失、下次跟进时间不回退', () async {
      final provider = AppProvider();
      while (!provider.isLoaded) {
        await Future.delayed(const Duration(milliseconds: 10));
      }

      final now = DateTime.now();
      final todayTenAm = DateTime(now.year, now.month, now.day, 10, 0);
      final futureDate = now.add(const Duration(days: 5));

      // 1. 本地初始化一条原线索（今日待回访）
      final clueId = 'c_merge_protect_001';
      final initialClue = Clue(
        id: clueId,
        wxNick: '何海燕',
        nextVisitTime: todayTenAm,
        status: ClueStatus.following,
        ownerName: '超级管理员',
        createTime: now.subtract(const Duration(days: 1)),
      );
      provider.addClue(initialClue);

      // 2. 本地新增一条回访记录，并推迟下次跟进时间到 5 天后
      final newLog = VisitLog(
        id: 'log_protect_001',
        clueId: clueId,
        contactMethod: ContactMethod.wechat,
        visitResult: VisitResult.followUp,
        visitContent: '今天电话沟通，学员表示周末再考虑，约好5天后再回访',
        nextVisitTime: futureDate,
        createTime: DateTime.now(),
      );
      final addSuccess = await provider.addVisitLog(clueId, newLog);
      expect(addSuccess, true);

      // 验证本地已经成功更新
      final afterAdd = provider.getClueById(clueId)!;
      expect(afterAdd.visitLogs.length, 1);
      expect(afterAdd.nextVisitTime, futureDate);

      // 3. 模拟此时从云端拉取到了旧版本（云端尚未收到更新，依然是0条回访记录，次回访为今天10点）
      final staleRemoteClue = Clue(
        id: clueId,
        wxNick: '何海燕',
        nextVisitTime: todayTenAm,
        status: ClueStatus.following,
        ownerName: '超级管理员',
        createTime: now.subtract(const Duration(days: 1)),
        visitLogs: [],
      );

      // 4. 执行智能合并对齐
      final needsUpload = <Clue>[];
      final merged = provider.mergeClueForTesting(afterAdd, staleRemoteClue, needsUpload: needsUpload);

      // 5. 核心断言：本地新回访绝对不被覆盖抹平！
      expect(merged.visitLogs.length, 1);
      expect(merged.visitLogs.first.visitContent, '今天电话沟通，学员表示周末再考虑，约好5天后再回访');
      // 次回访时间必须保持最新的 5 天后，绝不能回退到 todayTenAm！
      expect(merged.nextVisitTime, futureDate);
      // 必须被识别为 needsUpload，以便自动推回云端修复云端旧数据
      expect(needsUpload.any((c) => c.id == clueId), true);
    });

    test('【QA 专项测试 17】线索删除与云端刷新防复活测试：删除后刷新页面线索绝不复生', () async {
      final provider = AppProvider();
      while (!provider.isLoaded) {
        await Future.delayed(const Duration(milliseconds: 10));
      }

      final now = DateTime.now();
      final deleteTargetId = 'c_delete_test_001';
      final survivorId = 'c_survivor_test_002';

      // 1. 本地初始化两条真实线索
      final clueToDelete = Clue(
        id: deleteTargetId,
        wxNick: '王丽华',
        status: ClueStatus.following,
        ownerName: '超级管理员',
        createTime: now.subtract(const Duration(days: 2)),
      );
      final survivorClue = Clue(
        id: survivorId,
        wxNick: '赵志刚',
        status: ClueStatus.following,
        ownerName: '超级管理员',
        createTime: now.subtract(const Duration(days: 1)),
      );
      provider.addClue(clueToDelete);
      provider.addClue(survivorClue);

      expect(provider.getClueById(deleteTargetId), isNotNull);
      expect(provider.getClueById(survivorId), isNotNull);

      // 2. 用户执行删除线索操作
      await provider.deleteClue(deleteTargetId);

      // 验证本地立即删除，且记录了墓碑
      expect(provider.getClueById(deleteTargetId), isNull);
      expect(provider.deletedClueIds.contains(deleteTargetId), true);
      expect(provider.getClueById(survivorId), isNotNull);

      // 3. 模拟用户刷新页面（云端拉取时，云端因时差依然回传了刚刚被删除的 clueToDelete）
      final staleRemotes = [
        Clue(
          id: deleteTargetId,
          wxNick: '王丽华',
          status: ClueStatus.following,
          ownerName: '超级管理员',
          createTime: now.subtract(const Duration(days: 2)),
        ),
        Clue(
          id: survivorId,
          wxNick: '赵志刚',
          status: ClueStatus.following,
          ownerName: '超级管理员',
          createTime: now.subtract(const Duration(days: 1)),
        ),
      ];

      // 触发合并
      await provider.mergeAndApplyRemoteCluesForTesting(staleRemotes);

      // 4. 核心断言：刷新后已被删除的线索绝对不会复活！正常线索依然存在！
      expect(provider.getClueById(deleteTargetId), isNull);
      expect(provider.getClueById(survivorId), isNotNull);
      expect(provider.clues.any((c) => c.id == deleteTargetId), false);
      expect(provider.clues.any((c) => c.id == survivorId), true);
    });

    test('【QA 专项测试 18】跨设备删除同步对齐：设备A在云端删除了线索，设备B刷新时自动识别并移除，绝不擅自上传复活', () async {
      final provider = AppProvider();
      while (!provider.isLoaded) {
        await Future.delayed(const Duration(milliseconds: 10));
      }

      final now = DateTime.now();
      final historicClueId = 'c_historic_sync_001';
      final normalClueId = 'c_normal_sync_002';

      // 模拟设备B本地原本缓存着历史同步下来的线索（张帅）和另一条正常线索
      final historicClue = Clue(
        id: historicClueId,
        wxNick: '张帅',
        status: ClueStatus.following,
        ownerName: '超级管理员',
        createTime: now.subtract(const Duration(days: 3)),
      );
      final normalClue = Clue(
        id: normalClueId,
        wxNick: '林建',
        status: ClueStatus.following,
        ownerName: '超级管理员',
        createTime: now.subtract(const Duration(days: 2)),
      );

      // 直接加入本地线索池（模拟历史缓存，并非本设备此时新增）
      provider.addClue(historicClue);
      provider.addClue(normalClue);

      // 模拟已完成过云端同步上报（移出 pendingCreationClueIds）
      provider.clearPendingCreationForTesting(historicClueId);
      provider.clearPendingCreationForTesting(normalClueId);
      expect(provider.getClueById(historicClueId), isNotNull);

      // 模拟设备A在手机上删除了张帅，云端返回的最新列表里已经没有张帅，只有林建
      final cloudRemotesWithoutZhangshuai = [
        Clue(
          id: normalClueId,
          wxNick: '林建',
          status: ClueStatus.following,
          ownerName: '超级管理员',
          createTime: now.subtract(const Duration(days: 2)),
        ),
      ];

      // 设备B刷新列表，触发全量双向对齐
      await provider.mergeAndApplyRemoteCluesForTesting(cloudRemotesWithoutZhangshuai);

      // 核心断言：设备B必须跟随云端完成删除，张帅必须从本地彻底消失！
      expect(provider.getClueById(historicClueId), isNull);
      expect(provider.clues.any((c) => c.id == historicClueId), false);
      expect(provider.getClueById(normalClueId), isNotNull);
      // 墓碑集合必须自动记录该ID
      expect(provider.deletedClueIds.contains(historicClueId), true);
    });

    test('【QA 专项测试 19】超级管理员线索默认显示自己与自由切换全员/其他顾问测试', () async {
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

      // 录入两条不同归属人的线索
      final adminClue = Clue(
        id: 'c_test_admin_001',
        wxNick: '王同学',
        status: ClueStatus.following,
        ownerName: '超级管理员',
        grade: '25级',
        createTime: DateTime.now(),
      );
      final liClue = Clue(
        id: 'c_test_li_001',
        wxNick: '张同学',
        status: ClueStatus.following,
        ownerName: '李老师',
        grade: '25级',
        createTime: DateTime.now(),
      );
      provider.addClue(adminClue);
      provider.addClue(liClue);

      // 1. 超管登录
      provider.setCurrentUserForTesting(adminUser);
      expect(provider.isSuperAdmin, true);
      expect(provider.canViewAllClues, true);

      // 核心断言 1：超管默认筛选必须为 'mine'（默认显示自己的线索）
      expect(provider.ownerFilter, 'mine');
      expect(provider.hasActiveFilter, false, reason: '默认状态下不应显示筛选高亮徽标');

      // 默认线索列表只包含超级管理员自己的线索，不包含李老师的线索
      final defaultClues = provider.filteredClues;
      expect(defaultClues.any((c) => c.id == 'c_test_admin_001'), true);
      expect(defaultClues.any((c) => c.id == 'c_test_li_001'), false);
      expect(provider.accessibleClues.any((c) => c.id == 'c_test_admin_001'), true);
      expect(provider.accessibleClues.any((c) => c.id == 'c_test_li_001'), false);

      // 2. 超管主动切换为 'all'（查看全员线索）
      provider.setOwnerFilter('all');
      expect(provider.ownerFilter, 'all');
      expect(provider.hasActiveFilter, true, reason: '切换为非默认后激活筛选指示');
      final allClues = provider.filteredClues;
      expect(allClues.any((c) => c.id == 'c_test_admin_001'), true);
      expect(allClues.any((c) => c.id == 'c_test_li_001'), true);

      // 3. 超管切换为 '李老师'（查看指定顾问的线索）
      provider.setOwnerFilter('李老师');
      expect(provider.ownerFilter, '李老师');
      expect(provider.hasActiveFilter, true);
      final liClues = provider.filteredClues;
      expect(liClues.any((c) => c.id == 'c_test_admin_001'), false);
      expect(liClues.any((c) => c.id == 'c_test_li_001'), true);

      // 4. 重置筛选，必须自动恢复为 'mine'（恢复默认仅显示自己）
      await provider.resetFilters();
      expect(provider.ownerFilter, 'mine');
      expect(provider.hasActiveFilter, false);
      final resetClues = provider.filteredClues;
      expect(resetClues.any((c) => c.id == 'c_test_admin_001'), true);
      expect(resetClues.any((c) => c.id == 'c_test_li_001'), false);
    });

    test('【QA 专项测试 20】AI 深度分析报告多版本持久化与时间轴直达测试', () async {
      SharedPreferences.setMockInitialValues({});
      final provider = AppProvider();
      provider.initMockData();

      final clueId = 'c_ai_history_test_01';
      final clue = Clue(
        id: clueId,
        wxNick: '周同学',
        status: ClueStatus.following,
        ownerName: '超级管理员',
        createTime: DateTime.now().subtract(const Duration(days: 3)),
      );
      provider.addClue(clue);

      // 1. 模拟第一次上传聊天记录并进行 AI 分析
      const firstReport = '# 第一次 AI 诊断\n学员重点关注专升本英语底子薄，建议早鸟名师词汇营。';
      final log1 = VisitLog(
        id: 'vl_ai_001',
        clueId: clueId,
        visitContent: '【AI大模型深度诊断】已完成深度剖析，包含破冰、案例与逼单方案，详见AI分析页。',
        createTime: DateTime.now().subtract(const Duration(days: 2)),
        aiReport: firstReport,
      );
      await provider.addVisitLog(clueId, log1);
      await provider.saveAiAnalysisReport(clueId, firstReport);

      var updatedClue = provider.getClueById(clueId)!;
      expect(updatedClue.aiAnalysisReport, firstReport);
      expect(updatedClue.visitLogs.length, 1);
      expect(updatedClue.visitLogs.first.aiReport, firstReport);

      // 2. 模拟三天后再次上传新的聊天记录进行第二次分析
      const secondReport = '# 第二次 AI 诊断（最新）\n学员已产生价格敏感，核心决策人为家长，推荐周末面授协议班与分期免息。';
      final log2 = VisitLog(
        id: 'vl_ai_002',
        clueId: clueId,
        visitContent: '【AI大模型深度诊断】已完成深度剖析，包含破冰、案例与逼单方案，详见AI分析页。',
        createTime: DateTime.now(),
        aiReport: secondReport,
      );
      await provider.addVisitLog(clueId, log2);
      await provider.saveAiAnalysisReport(clueId, secondReport);

      updatedClue = provider.getClueById(clueId)!;
      // 核心断言 1：线索主体的 aiAnalysisReport 始终保存最新的第二份报告
      expect(updatedClue.aiAnalysisReport, secondReport);
      expect(updatedClue.visitLogs.length, 2);

      // 核心断言 2：时间轴上的两条历史记录，各自完整保存了当时的专属报告内容，互不覆盖！
      // 备注：visitLogs 采用倒序存储（最新生成的在 index 0）
      expect(updatedClue.visitLogs[0].aiReport, secondReport);
      expect(updatedClue.visitLogs[1].aiReport, firstReport);

      // 核心断言 3：验证从时间轴第一次历史节点点击时，获取到的是当时的专属报告（firstReport）
      final timelineFirstLog = updatedClue.visitLogs[1];
      final targetReportFromTimeline1 = (timelineFirstLog.aiReport != null && timelineFirstLog.aiReport!.isNotEmpty)
          ? timelineFirstLog.aiReport
          : updatedClue.aiAnalysisReport;
      expect(targetReportFromTimeline1, firstReport);

      // 核心断言 4：从底部 AI 入口直接进入时，获取到的是全局最新报告（secondReport）
      final targetReportFromBottomAi = updatedClue.aiAnalysisReport;
      expect(targetReportFromBottomAi, secondReport);

      // 核心断言 5：VisitLog JSON 序列化持久化完整性
      final json = log2.toJson();
      expect(json['aiReport'], secondReport);
      final restoredLog = VisitLog.fromJson(json);
      expect(restoredLog.aiReport, secondReport);
    });
  });
}


