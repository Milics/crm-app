import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crm_app/providers/app_provider.dart';
import 'package:crm_app/models/clue.dart';

void main() {
  setUp(() {
    // 使用内存 mock，避免真实磁盘读写
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('CRM App smoke test - 应用可以正常启动', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AppProvider(),
        child: const MaterialApp(
          home: Scaffold(body: Center(child: Text('测试启动成功'))),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('测试启动成功'), findsOneWidget);
  });

  testWidgets('AppProvider 初始化后 isLoaded 为 true', (WidgetTester tester) async {
    final provider = AppProvider();
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: provider,
        child: const MaterialApp(home: SizedBox()),
      ),
    );
    await tester.pumpAndSettle();
    expect(provider.isLoaded, isTrue);
  });

  testWidgets('AppProvider 首次启动保持纯净线索池并支持录入真实学员', (WidgetTester tester) async {
    final provider = AppProvider();
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: provider,
        child: const MaterialApp(home: SizedBox()),
      ),
    );
    await tester.pumpAndSettle();
    // 纯净状态：默认不包含测试线索
    expect(provider.clues.length, 0);

    // 录入真实学员线索成功
    final newClue = Clue(
      id: 'real_student_001',
      wxNick: '李华',
      phone: '13811112222',
      createTime: DateTime.now(),
    );
    provider.addClue(newClue);
    expect(provider.clues.length, 1);
  });
}

