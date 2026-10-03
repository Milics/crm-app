import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:crm_app/models/clue.dart';
import 'package:crm_app/providers/app_provider.dart';
import 'package:crm_app/pages/add_visit_page.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('新增/编辑回访页回访提醒日期选项交互测试', () {
    testWidgets('1. 日期选项顺序验证：自选日期在最前，不设提醒在最后', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final provider = AppProvider();
      provider.initMockData();

      final clue = Clue(
        id: 'c_test_visit_dates',
        wxNick: '测试学员',
        createTime: DateTime.now(),
      );
      provider.addClue(clue);

      await tester.pumpWidget(
        ChangeNotifierProvider<AppProvider>.value(
          value: provider,
          child: MaterialApp(
            home: AddVisitPage(clueId: clue.id),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 验证回访日期区域各选项都在
      expect(find.text('自选日期'), findsOneWidget);
      expect(find.text('今天'), findsOneWidget);
      expect(find.text('明天'), findsOneWidget);
      expect(find.text('3天后'), findsOneWidget);
      expect(find.text('7天后'), findsOneWidget);
      expect(find.text('不设提醒'), findsOneWidget);

      // 验证顺序（X 坐标递增）：自选日期 X < 今天 X < 明天 X < 3天后 X < 7天后 X < 不设提醒 X
      final customX = tester.getTopLeft(find.text('自选日期')).dx;
      final todayX = tester.getTopLeft(find.text('今天')).dx;
      final tomorrowX = tester.getTopLeft(find.text('明天')).dx;
      final d3X = tester.getTopLeft(find.text('3天后')).dx;
      final d7X = tester.getTopLeft(find.text('7天后')).dx;
      final noRemindX = tester.getTopLeft(find.text('不设提醒')).dx;

      expect(customX < todayX, isTrue, reason: '自选日期必须在最前面');
      expect(todayX < tomorrowX, isTrue);
      expect(tomorrowX < d3X, isTrue);
      expect(d3X < d7X, isTrue);
      expect(d7X < noRemindX, isTrue, reason: '不设提醒必须在最后面');
    });

    testWidgets('2. 编辑回访且存在非快捷自定义日期时，按钮中自动显示已经选择的月和日', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final provider = AppProvider();
      provider.initMockData();

      final customDate = DateTime(2026, 11, 25, 14, 30);
      final existingLog = VisitLog(
        id: 'log_custom_date_test',
        clueId: 'c_test_visit_dates_2',
        contactMethod: ContactMethod.wechat,
        visitResult: VisitResult.followUp,
        visitContent: '学生沟通良好，约了11月25日再聊',
        nextVisitTime: customDate,
        createTime: DateTime.now(),
      );

      final clue = Clue(
        id: 'c_test_visit_dates_2',
        wxNick: '测试学员2',
        createTime: DateTime.now(),
        visitLogs: [existingLog],
      );
      provider.addClue(clue);

      await tester.pumpWidget(
        ChangeNotifierProvider<AppProvider>.value(
          value: provider,
          child: MaterialApp(
            home: AddVisitPage(
              clueId: clue.id,
              existingLog: existingLog,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 验证自选日期按钮里显示了已经选择的月和日（11月25日）
      expect(find.text('11月25日'), findsOneWidget);
      // 验证默认不再是“自选日期”空文案
      expect(find.text('自选日期'), findsNothing);
    });
  });
}
