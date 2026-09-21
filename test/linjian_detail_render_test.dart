import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:crm_app/providers/app_provider.dart';
import 'package:crm_app/pages/clue_detail_page.dart';
import 'package:crm_app/models/clue.dart';
import 'package:crm_app/models/initial_real_clues.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  testWidgets('验证林建详情页沟通截图真实渲染与时间轴去重单条展示', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final provider = AppProvider();
    final linjian = InitialRealClues.getClues().firstWhere((c) => c.wxNick == '林建');
    provider.addClue(linjian);

    await tester.pumpWidget(
      ChangeNotifierProvider<AppProvider>.value(
        value: provider,
        child: MaterialApp(
          home: ClueDetailPage(clueId: linjian.id),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));

    // 1. 验证学员信息
    expect(find.text('林建'), findsWidgets);
    expect(find.textContaining('林州建筑'), findsWidgets);

    // 2. 验证沟通截图档案 (3张)
    expect(find.text('沟通截图档案'), findsOneWidget);
    expect(find.text('(3张)'), findsOneWidget);
    final imageFinders = find.byType(Image);
    debugPrint('📸 页面内找到 Image 数量: ${imageFinders.evaluate().length}');
    expect(imageFinders.evaluate().length >= 3, true);

    // 3. 验证时间轴去重与唯一性
    // "再次跟进网课的事情，微信没有回复！" 应当且仅当出现 1 次
    final followUp1 = find.textContaining('再次跟进网课的事情');
    debugPrint('🕒 "再次跟进网课" 匹配数: ${followUp1.evaluate().length}');
    expect(followUp1, findsOneWidget);

    // "发微信告知周末班和网课已开课" 应当且仅当出现 1 次
    final followUp2 = find.textContaining('发微信告知周末班');
    debugPrint('🕒 "发微信告知周末班" 匹配数: ${followUp2.evaluate().length}');
    expect(followUp2, findsOneWidget);

    // "线索创建" 应当且仅当出现 1 次
    final createLog = find.text('线索创建');
    debugPrint('🕒 "线索创建" 匹配数: ${createLog.evaluate().length}');
    expect(createLog, findsOneWidget);

    debugPrint('🎉 自动化测试断言全部通过：林建 3 张微信原图渲染成功，时间轴无任何重复项！');
  });
}
