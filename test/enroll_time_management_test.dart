import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:crm_app/models/clue.dart';
import 'package:crm_app/providers/app_provider.dart';
import 'package:crm_app/pages/enroll_page.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('报名时间管理与修改全链路测试', () {
    test('1. 历史数据兼容：未设置 enrollTime 时，effectiveEnrollTime 平滑回退到 createTime', () {
      final pastTime = DateTime(2025, 3, 15, 10, 30);
      final clue = Clue(
        id: 'clue_test_enroll_01',
        wxNick: '张三',
        status: ClueStatus.enrolled,
        createTime: pastTime,
        enrollTime: null,
      );

      expect(clue.enrollTime, isNull);
      expect(clue.effectiveEnrollTime, equals(pastTime));
    });

    test('2. 显式设置 enrollTime 时，effectiveEnrollTime 优先返回 enrollTime', () {
      final createTime = DateTime(2025, 3, 15, 10, 30);
      final enrollTime = DateTime(2025, 6, 20, 14, 00);
      final clue = Clue(
        id: 'clue_test_enroll_02',
        wxNick: '李四',
        status: ClueStatus.enrolled,
        createTime: createTime,
        enrollTime: enrollTime,
      );

      expect(clue.enrollTime, equals(enrollTime));
      expect(clue.effectiveEnrollTime, equals(enrollTime));
    });

    test('3. JSON 序列化与反序列化全链路保证 enrollTime 不丢失', () {
      final enrollTime = DateTime(2025, 9, 1, 9, 0);
      final createTime = DateTime(2025, 8, 1, 9, 0);
      final clue = Clue(
        id: 'clue_test_enroll_03',
        wxNick: '王五',
        status: ClueStatus.enrolled,
        createTime: createTime,
        enrollTime: enrollTime,
      );

      final json = clue.toJson();
      expect(json['enrollTime'], isNotNull);
      expect(json['enrollTime'], equals(enrollTime.toIso8601String()));

      final restored = Clue.fromJson(json);
      expect(restored.enrollTime, equals(enrollTime));
      expect(restored.effectiveEnrollTime, equals(enrollTime));
    });

    test('4. AppProvider.enrollClue 与 updateEnrollInfo 支持设置和修改报名时间', () async {
      final provider = AppProvider();
      provider.initMockData();

      final customCreate = DateTime(2025, 1, 10, 8, 0);
      final testClue = Clue(
        id: 'c_enroll_provider_test',
        wxNick: '赵六',
        status: ClueStatus.following,
        createTime: customCreate,
      );

      provider.addClue(testClue);

      // 转为报名，并指定报名时间为 2025-05-01 12:00
      final firstEnrollTime = DateTime(2025, 5, 1, 12, 0);
      provider.enrollClue(
        'c_enroll_provider_test',
        '全程协议班',
        '报名定金500',
        enrollAmount: 500,
        enrollTime: firstEnrollTime,
      );

      final enrolled = provider.getClueById('c_enroll_provider_test')!;
      expect(enrolled.status, equals(ClueStatus.enrolled));
      expect(enrolled.classType, equals('全程协议班'));
      expect(enrolled.enrollAmount, equals(500.0));
      expect(enrolled.enrollTime, equals(firstEnrollTime));
      expect(enrolled.effectiveEnrollTime, equals(firstEnrollTime));

      // 在报名详情中修改报名时间为 2025-05-03 15:30，班型改为冲刺班
      final updatedEnrollTime = DateTime(2025, 5, 3, 15, 30);
      provider.updateEnrollInfo(
        'c_enroll_provider_test',
        '冲刺班',
        1200,
        '补齐尾款并改冲刺班',
        enrollTime: updatedEnrollTime,
      );

      final updated = provider.getClueById('c_enroll_provider_test')!;
      expect(updated.classType, equals('冲刺班'));
      expect(updated.enrollAmount, equals(1200.0));
      expect(updated.remark, equals('补齐尾款并改冲刺班'));
      expect(updated.enrollTime, equals(updatedEnrollTime));
      expect(updated.effectiveEnrollTime, equals(updatedEnrollTime));
    });

    testWidgets('5. EnrollPage 页面渲染与交互修改报名时间', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final provider = AppProvider();
      provider.initMockData();

      final originalTime = DateTime(2025, 5, 1, 10, 0);
      final clue = Clue(
        id: 'c_widget_enroll_test',
        wxNick: '钱七',
        status: ClueStatus.enrolled,
        classType: '全程协议班',
        enrollAmount: 2000,
        createTime: DateTime(2025, 3, 1),
        enrollTime: originalTime,
      );
      provider.addClue(clue);

      await tester.pumpWidget(
        ChangeNotifierProvider<AppProvider>.value(
          value: provider,
          child: MaterialApp(
            home: EnrollPage(clue: clue),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 验证标题和各板块渲染
      expect(find.text('报名详情'), findsOneWidget);
      expect(find.text('报班类型'), findsOneWidget);
      expect(find.text('预交金额（元）'), findsOneWidget);
      expect(find.text('报名时间'), findsOneWidget);
      expect(find.text('设为当前时间'), findsOneWidget);
      expect(find.text('修改时间'), findsOneWidget);
      expect(find.textContaining('2025-05-01 10:00'), findsOneWidget);

      // 点击“设为当前时间”快捷按钮
      await tester.tap(find.text('设为当前时间'));
      await tester.pumpAndSettle();

      final now = DateTime.now();
      final currentYearMonth = '${now.year}-${now.month.toString().padLeft(2, '0')}';
      expect(find.textContaining(currentYearMonth), findsOneWidget);

      // 点击保存修改
      await tester.tap(find.text('保存修改'));
      await tester.pumpAndSettle(const Duration(milliseconds: 600));

      final savedClue = provider.getClueById('c_widget_enroll_test')!;
      expect(savedClue.enrollTime!.year, equals(now.year));
      expect(savedClue.enrollTime!.month, equals(now.month));
      expect(savedClue.enrollTime!.day, equals(now.day));
    });
  });
}
