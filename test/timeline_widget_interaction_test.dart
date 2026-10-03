import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crm_app/models/clue.dart';
import 'package:crm_app/providers/app_provider.dart';
import 'package:crm_app/pages/clue_detail_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('时间轴卡片三点菜单弹出、编辑回显与删除二次确认交互测试', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final provider = AppProvider();

    // 构造测试线索与回访记录
    const clueId = 'widget_test_clue_01';
    final testLog = VisitLog(
      id: 'widget_log_001',
      clueId: clueId,
      contactMethod: ContactMethod.wechat,
      visitResult: VisitResult.normal,
      visitContent: '学生询问自考与专升本区别，沟通细致',
      nextVisitTime: DateTime(2026, 10, 20, 10, 0),
      createTime: DateTime(2026, 10, 1, 9, 30),
    );

    final clue = Clue(
      id: clueId,
      wxNick: '王同学',
      school: '河南经贸',
      grade: '24级',
      status: ClueStatus.contacted,
      intentLevel: IntentLevel.medium,
      createTime: DateTime.now(),
      visitLogs: [testLog],
    );
    provider.addClue(clue);

    // 构建并渲染详情页
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AppProvider>.value(value: provider),
        ],
        child: const MaterialApp(
          home: ClueDetailPage(clueId: clueId),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    // 1. 验证时间轴上渲染了该回访记录的内容
    expect(find.text('学生询问自考与专升本区别，沟通细致'), findsOneWidget);

    // 2. 验证时间轴卡片右上角存在操作按钮（置顶创建卡片与回访卡片各一个，取回访记录的最后一个）
    final moreBtnFinder = find.byTooltip('操作记录').last;
    expect(find.byTooltip('操作记录'), findsNWidgets(2));

    // 3. 点击操作按钮，验证弹出“编辑此记录”与“删除此记录”菜单项
    await tester.tap(moreBtnFinder);
    await tester.pumpAndSettle();

    expect(find.text('编辑此记录'), findsOneWidget);
    expect(find.text('删除此记录'), findsOneWidget);

    // 4. 点击“编辑此记录”，进入编辑页面并验证表单已回显
    await tester.tap(find.text('编辑此记录'));
    await tester.pumpAndSettle();

    expect(find.text('编辑跟进记录'), findsOneWidget);
    expect(find.text('保存修改'), findsOneWidget);
    expect(find.text('学生询问自考与专升本区别，沟通细致'), findsOneWidget);

    // 5. 返回详情页
    Navigator.of(tester.element(find.text('编辑跟进记录'))).pop();
    await tester.pumpAndSettle();

    // 6. 验证删除功能：点击三点菜单 -> 选择删除此记录
    await tester.tap(find.byTooltip('操作记录').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('删除此记录'));
    await tester.pumpAndSettle();

    // 验证出现二次确认对话框
    expect(find.text('删除跟进记录'), findsOneWidget);
    expect(find.text('取消'), findsOneWidget);
    expect(find.text('确认删除'), findsOneWidget);

    // 点击“确认删除”
    await tester.tap(find.text('确认删除'));
    await tester.pumpAndSettle();

    // 7. 验证记录已从页面上消失，且 provider 中记录已被删除
    expect(find.text('学生询问自考与专升本区别，沟通细致'), findsNothing);
    final clueAfter = provider.getClueById(clueId)!;
    expect(clueAfter.visitLogs.isEmpty, isTrue);
    expect(clueAfter.deletedVisitLogIds.contains('widget_log_001'), isTrue);
  });
}
