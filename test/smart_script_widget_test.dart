import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crm_app/models/initial_real_clues.dart';
import 'package:crm_app/providers/app_provider.dart';
import 'package:crm_app/pages/clue_detail_page.dart';
import 'package:crm_app/pages/ai_analysis_page.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('林建详情页高情商口头化话术与胶囊切换测试', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final provider = AppProvider();
    final linjian = InitialRealClues.getClues().firstWhere((c) => c.wxNick.contains('林建'));
    provider.addClue(linjian);

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: provider,
        child: MaterialApp(
          home: ClueDetailPage(clueId: linjian.id),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 验证标题为 AI 深度定制话术
    expect(find.text('AI 深度定制话术'), findsOneWidget);

    // 默认展示首选【破冰开口】话术
    expect(find.text('🌱 破冰开口 (首选推荐)'), findsOneWidget);
    expect(find.text('🛡️ 打消顾虑 · 定心丸'), findsOneWidget);
    expect(find.text('🔥 促成逼单 · 锁定名额'), findsOneWidget);

    // 验证话术内容绝无“方便语音聊 3 分钟”官方机械套话
    expect(find.textContaining('方便语音聊 3 分钟'), findsNothing);

    // 验证第一步定心丸内容口头化
    expect(find.textContaining('林同学，你放心！咱们这个班型就是专门为你这种25届考生定制'), findsOneWidget);

    // 点击切换到【打消顾虑】胶囊
    await tester.tap(find.text('🛡️ 打消顾虑 · 定心丸'));
    await tester.pumpAndSettle();

    // 验证内容切换为第二步
    expect(find.textContaining('林州建筑上一届美术专业综合的张学长'), findsOneWidget);

    // 点击切换到【促成逼单】胶囊
    await tester.tap(find.text('🔥 促成逼单 · 锁定名额'));
    await tester.pumpAndSettle();

    // 验证内容切换为第三步
    expect(find.textContaining('把名字和收件地址发我'), findsOneWidget);
  });

  testWidgets('AI 诊断页卡片3实战口头化话术展示与胶囊切换测试', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final provider = AppProvider();
    final linjian = InitialRealClues.getClues().firstWhere((c) => c.wxNick.contains('林建'));
    provider.addClue(linjian);

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: provider,
        child: MaterialApp(
          home: AiAnalysisPage(clue: linjian),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 验证模块 3 标题为专属实战沟通话术
    expect(find.text('专属实战沟通话术'), findsOneWidget);

    // 验证场景胶囊存在
    expect(find.text('🌱 破冰开口 (首选推荐)'), findsOneWidget);
    expect(find.text('🛡️ 打消顾虑 · 定心丸'), findsOneWidget);
    expect(find.text('🔥 促成逼单 · 锁定名额'), findsOneWidget);

    // 验证口头化定心丸话术存在于独立 Text 控件中
    expect(
      find.byWidgetPredicate((widget) =>
          widget is Text &&
          widget.data != null &&
          widget.data!.contains('林同学，你放心！咱们这个班型就是专门为你这种25届考生定制')),
      findsOneWidget,
    );
    expect(find.textContaining('方便语音聊 3 分钟'), findsNothing);

    // 点击切换到【促成逼单】胶囊
    await tester.tap(find.text('🔥 促成逼单 · 锁定名额'));
    await tester.pumpAndSettle();

    expect(
      find.byWidgetPredicate((widget) =>
          widget is Text &&
          widget.data != null &&
          widget.data!.contains('把名字和收件地址发我')),
      findsOneWidget,
    );
  });
}
