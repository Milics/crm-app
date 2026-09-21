import '../models/clue.dart';

/// 话术场景对象
class ScriptScenario {
  /// 场景唯一标识 (opening: 破冰开口, reassure: 打消顾虑, close: 促成逼单)
  final String key;

  /// 场景标签名称 (如：🌱 破冰开口 (首选))
  final String label;

  /// 简短标签（胶囊按钮显示用）
  final String shortLabel;

  /// 使用场景指导说明 (指导顾问何时使用)
  final String tip;

  /// 适合复制直接发送给学员的微信口头化话术
  final String content;

  const ScriptScenario({
    required this.key,
    required this.label,
    required this.shortLabel,
    required this.tip,
    required this.content,
  });
}

/// 智能口头化沟通话术生成引擎
/// 核心准则：口头化、微信化、降压、易开口、深度绑定 AI 深度报告与学员画像
class SmartScriptEngine {
  /// 为指定线索生成多场景口头化推荐话术
  static List<ScriptScenario> generate(Clue clue, {String? reportOverride}) {
    // 1. 优先尝试从 AI 大模型深度分析报告中提取原汁原味的金牌销售策略
    final aiScenarios = _extractFromAiReport(clue, reportOverride: reportOverride);
    if (aiScenarios != null && aiScenarios.isNotEmpty) {
      return aiScenarios;
    }

    // 2. 若未解析到 AI 报告，则根据线索画像、跟进记录（是否未回微信）动态生成口头化话术
    return _generateFromProfile(clue);
  }

  /// 从 AI 分析报告 Markdown 中解析提取三套口头化话术
  static List<ScriptScenario>? _extractFromAiReport(Clue clue, {String? reportOverride}) {
    final report = reportOverride ?? clue.aiAnalysisReport;
    if (report == null || report.trim().isEmpty) return null;

    String? step1;
    String? step2;
    String? step3;

    // 模式 A：匹配 "### 第一步..." / "### 第二步..." / "### 第三步..." 及其下方的引用块 (如林建、金闪闪、卡厄斯兰那)
    final step1Match = RegExp(
      r'###\s*第一步[^\n]*\n+>\s*([^\n]+(?:\n>[^\n]+)*)',
      multiLine: true,
    ).firstMatch(report);
    if (step1Match != null) {
      step1 = _cleanQuote(step1Match.group(1));
    }

    final step2Match = RegExp(
      r'###\s*第二步[^\n]*\n+>\s*([^\n]+(?:\n>[^\n]+)*)',
      multiLine: true,
    ).firstMatch(report);
    if (step2Match != null) {
      step2 = _cleanQuote(step2Match.group(1));
    }

    final step3Match = RegExp(
      r'###\s*第三步[^\n]*\n+>\s*([^\n]+(?:\n>[^\n]+)*)',
      multiLine: true,
    ).firstMatch(report);
    if (step3Match != null) {
      step3 = _cleanQuote(step3Match.group(1));
    }

    // 模式 B：若未匹配到模式 A，尝试匹配 "• 【话术一 ...】" / "• 【话术二 ...】" / "• 【话术三 ...】"
    if (step1 == null) {
      final h1Match = RegExp(r'【话术一[^\n]*】[：:]\s*([^\n]+)').firstMatch(report);
      if (h1Match != null) step1 = _cleanQuote(h1Match.group(1));
    }
    if (step2 == null) {
      final h2Match = RegExp(r'【话术二[^\n]*】[：:]\s*([^\n]+)').firstMatch(report);
      if (h2Match != null) step2 = _cleanQuote(h2Match.group(1));
    }
    if (step3 == null) {
      final h3Match = RegExp(r'【话术三[^\n]*】[：:]\s*([^\n]+)').firstMatch(report);
      if (h3Match != null) step3 = _cleanQuote(h3Match.group(1));
    }

    if (step1 != null || step2 != null || step3 != null) {
      final name = clue.wxNick.isNotEmpty ? clue.wxNick : '同学';
      return [
        ScriptScenario(
          key: 'opening',
          label: '🌱 破冰开口 (首选推荐)',
          shortLabel: '破冰开口',
          tip: '适合学员防备心重或微信冷场未回，通过降压、送资料或轻量提问让其先开口回复',
          content: step1 ??
              '$name同学，这两天看你没回微信，估计在忙学校上课或作业，不用有压力哈！老师先整理了一份干货资料发你一份，你平时在宿舍顺手就能参考看～',
        ),
        ScriptScenario(
          key: 'reassure',
          label: '🛡️ 打消顾虑 · 定心丸',
          shortLabel: '打消顾虑',
          tip: '直击 AI 诊断出的核心卡点与担忧（如学费分期、全程陪伴保障、基础薄弱等），给予定心丸',
          content: step2 ??
              '$name同学你放心！咱们课程中途绝不会有任何二次收费，全程名师持续陪伴辅导直到考前。',
        ),
        ScriptScenario(
          key: 'close',
          label: '🔥 促成逼单 · 锁定名额',
          shortLabel: '促成逼单',
          tip: '限时名额或福利建档逼单，适合在学员打消疑虑后快速锁定定金或进班名额',
          content: step3 ??
              '今天正好是本月学员建档的最后节点，老师先帮你申请特批锁定名额与大礼包，你看把收件地址发我一下好吗？',
        ),
      ];
    }

    return null;
  }

  /// 清理 Markdown 引用块中的 `>`、多余首尾引号和括号说明
  static String _cleanQuote(String? raw) {
    if (raw == null) return '';
    var text = raw.replaceAll(RegExp(r'\n>\s*'), '\n').trim();
    // 移除开头的 "发送资料后追问一句：" 等提示词
    text = text.replaceFirst(RegExp(r'^发送资料后追问一句[：:]\s*'), '');
    // 移除最外层的直角引号或双引号
    if ((text.startsWith('“') && text.endsWith('”')) ||
        (text.startsWith('"') && text.endsWith('"'))) {
      text = text.substring(1, text.length - 1).trim();
    }
    // 移除文末的提示括号，例如：(通过专业技术探讨替代销售邀约)
    text = text.replaceFirst(RegExp(r'（[^）]*$'), '').trim();
    return text;
  }

  /// 基于学员画像、跟进历史动态组装口头化微信话术
  static List<ScriptScenario> _generateFromProfile(Clue clue) {
    final name = clue.wxNick.isNotEmpty ? clue.wxNick : '同学';
    final subject = clue.subject.isNotEmpty ? clue.subject : '专升本';
    final school = clue.school.isNotEmpty ? clue.school : '咱们学校';

    // 检查跟进历史中是否多次未回微信
    bool hasNoReply = false;
    for (final log in clue.visitLogs) {
      final content = log.visitContent.toLowerCase();
      if (content.contains('未回复') ||
          content.contains('未回') ||
          content.contains('没回') ||
          content.contains('不回') ||
          content.contains('已读不回')) {
        hasNoReply = true;
        break;
      }
    }

    final tags = clue.tags.map((e) => e.trim()).toList();
    final bool isPriceSensitive =
        tags.any((t) => t.contains('学费') || t.contains('价格') || t.contains('分期'));
    final bool isWeakBase =
        tags.any((t) => t.contains('基础') || t.contains('零基础') || t.contains('薄弱'));
    final bool isOnlineOrFull =
        tags.any((t) => t.contains('网课') || t.contains('全程') || t.contains('周末'));

    // 1. 破冰开口话题（核心：绝不逼单，先让学生开口敲键盘）
    String openingContent;
    if (hasNoReply) {
      openingContent =
          '$name同学，这两天看你没回微信，估计在忙学校专业课或实训作业，不用有压力哈！不用特地抽时间跑来校区，老师先把咱们针对 $school $subject 的《近几年历年高分范画与备考避坑指南》PDF先发你一份，你平时在宿舍就能参考对照着看～对了，你现在备考觉得最吃力的是哪一块呀？';
    } else if (clue.visitLogs.isEmpty) {
      openingContent =
          '$name同学你好呀！看到你也在关注 $subject 专升本，目前准备得怎么样啦？我们刚把针对 $school 的最新历年考情分析和核心考点题型整理成电子版了，直接发你一份在微信里存着参考，顺祝你升本顺顺利利！';
    } else {
      openingContent =
          '$name同学，上次聊完后一直记着你的复习进度～今天教研组刚更新了《$subject 最新高频必考点与避坑手册》，里面有不少针对咱们省统考的解题技巧，直接免费发你一份在手机上顺手看看哈！';
    }

    // 2. 打消顾虑话术（定心丸）
    String reassureContent;
    if (isPriceSensitive) {
      reassureContent =
          '$name同学，关于学费这块你完全放宽心！很多同学都会跟爸妈商量，大额支出慎重是对的。老师今天专门找教务主管帮你申请了针对咱们 $school 的【早鸟助学免息分期】，月供折下来只要几百元，完全没有一次性负担。我把分期明细单发你参考看看哈！';
    } else if (isWeakBase) {
      reassureContent =
          '$name同学，关于基础这块你不用太焦虑哈！咱们班不少同学一开始也是零基础起步的，老师刚把往届零基础逆袭考上公办本科的学长复习进度表整理出来了，你对照着按部就班学，老师全程带你，完全没问题！';
    } else if (isOnlineOrFull) {
      reassureContent =
          '$name同学，网课和后续排课你放心～咱们的班型就是针对大家平时在校时间定制的，周末面授搭配高清精讲随时补课，从开班一直管到明年进考场前，中途绝无任何隐形二次收费，非常省心！';
    } else {
      reassureContent =
          '$name同学，升本备考最怕的是前期一个人摸黑学、抓不住重点走弯路。咱们这边的老师都是带过多届全省高分学员的名师，会全程针对你的专业课底子一对一定制复习计划，你完全不用担心跟不上！';
    }

    // 3. 促成逼单话术（临门一脚锁名额）
    String closeContent;
    if (isPriceSensitive) {
      closeContent =
          '$name同学，这周末咱们面授集训大课就要正式锁定名额建档了，目前班里仅剩最后2个免息分期助学名额。老师先用工号特批帮你占住一个名额和政策，你今天先交个200元预留定金（万一后续有变动开课前可随时退），咱们先把名额和开课资料抢到手！';
    } else {
      closeContent =
          '$name同学，今天正好是咱们本月微集训营学员建档的最后一天，主教老师下午就要定下周的面授名额。我现在直接帮你锁定一个早鸟助学名额，把全套内部核心考点集和大礼包寄到学校给你，咱们这周末就可以正式进班跟学，你把名字和收件地址发我，我现在就给你办！';
    }

    return [
      ScriptScenario(
        key: 'opening',
        label: '🌱 破冰开口 (首选推荐)',
        shortLabel: '破冰开口',
        tip: '适合学员防备心重或微信冷场未回，通过降压、送资料或轻量提问让其先开口回复',
        content: openingContent,
      ),
      ScriptScenario(
        key: 'reassure',
        label: '🛡️ 打消顾虑 · 定心丸',
        shortLabel: '打消顾虑',
        tip: '直击核心顾虑与痛点，给出口头化定心承诺，消除学生或家长的后顾之忧',
        content: reassureContent,
      ),
      ScriptScenario(
        key: 'close',
        label: '🔥 促成逼单 · 锁定名额',
        shortLabel: '促成逼单',
        tip: '限时名额、助学优惠或开课建档锁定，适合在答疑充分后临门一脚快速锁定',
        content: closeContent,
      ),
    ];
  }
}
