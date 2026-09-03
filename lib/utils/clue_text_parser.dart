/// 专升本学员信息与招生规范智能语义解析器
/// 专门适配专升本行业标准命名规范：如「李文文-河南经贸-24级-视传」
class ClueParsedResult {
  final String name;
  final String phone;
  final String wxId;
  final String school;
  final String grade;
  final String subject;
  final String rawText;

  ClueParsedResult({
    this.name = '',
    this.phone = '',
    this.wxId = '',
    this.school = '',
    this.grade = '',
    this.subject = '',
    this.rawText = '',
  });

  @override
  String toString() {
    return 'ClueParsedResult(姓名: $name, 电话: $phone, 微信: $wxId, 学校: $school, 年级: $grade, 专业: $subject)';
  }
}

class ClueTextParser {
  // 专业缩写与标准科目映射表
  static final Map<String, String> _subjectMap = {
    '视传': '美术专业综合',
    '视觉传达': '美术专业综合',
    '设计': '美术专业综合',
    '美术': '美术专业综合',
    '环艺': '美术专业综合',
    '环境艺术': '美术专业综合',
    '高数': '高等数学',
    '数学': '高等数学',
    '计算机': '高等数学',
    '计科': '高等数学',
    '软件': '高等数学',
    '信管': '管理学',
    '管理': '管理学',
    '工商管理': '管理学',
    '经管': '经济学',
    '会计': '经济学',
    '财管': '经济学',
    '金融': '经济学',
    '国贸': '经济学',
    '电商': '管理学',
    '电子商务': '管理学',
    '市场营销': '管理学',
    '语文': '大学语文',
    '汉语言': '大学语文',
    '文秘': '大学语文',
    '英语': '大学语文',
    '商务英语': '大学语文',
    '学前': '教育学心理学',
    '学前教育': '教育学心理学',
    '小教': '教育学心理学',
    '小学教育': '教育学心理学',
    '心理': '教育学心理学',
    '法学': '法学基础',
    '法律': '法学基础',
    '护理': '生理学病理解剖学',
    '药学': '生理学病理解剖学',
    '临床': '生理学病理解剖学',
    '医学': '生理学病理解剖学',
    '中医': '中医基础',
    '针推': '中医基础',
    '音乐': '音乐专业综合',
    '舞蹈': '舞蹈专业综合',
    '体育': '体育专业综合',
  };

  /// 智能解析文本（无论是单行规范备注，还是截图中识别出的整篇多行文本）
  static ClueParsedResult parse(String text) {
    if (text.trim().isEmpty) return ClueParsedResult();

    String name = '';
    String phone = '';
    String wxId = '';
    String school = '';
    String grade = '';
    String subject = '';

    // 1. 优先提取 11 位手机号
    final phoneMatch = RegExp(r'1[3-9]\d{9}').firstMatch(text);
    if (phoneMatch != null) {
      phone = phoneMatch.group(0)!;
    }

    // 2. 提取微信号（支持 微信号: xxx、wxid_xxx、或微信ID）
    final wxMatch = RegExp(
            r'(?:微信号|微\s*信|ID|WeChat\s*ID)[:：\s]+([a-zA-Z0-9_-]{6,25})',
            caseSensitive: false)
        .firstMatch(text);
    if (wxMatch != null) {
      wxId = wxMatch.group(1)!;
    } else {
      final wxidDirect = RegExp(r'\bwxid_[a-zA-Z0-9_-]+\b').firstMatch(text);
      if (wxidDirect != null) {
        wxId = wxidDirect.group(0)!;
      }
    }

    // 3. 核心：识别招生命名规范「李文文-河南经贸-24级-视传」
    final lines = text.split(RegExp(r'\r?\n'));
    for (final rawLine in lines) {
      final line = rawLine.trim();
      if (line.isEmpty) continue;

      // 如果这一行包含常见分隔符
      final parts = line
          .split(RegExp(r'[\-_/|——\s]+'))
          .map((p) => p.trim())
          .where((p) => p.isNotEmpty)
          .toList();

      if (parts.length >= 2) {
        for (final part in parts) {
          // 判断年级（如 24级、25届、2024级、大二、大三）
          if (grade.isEmpty &&
              (RegExp(r'^(?:20)?\d{2}[级届]$').hasMatch(part) ||
                  RegExp(r'^大[一二三四]$').hasMatch(part))) {
            grade = part.length == 3 && part.endsWith('级')
                ? part
                : part.contains('级') || part.contains('届')
                    ? part
                    : '$part级';
            continue;
          }

          // 判断学校
          if (school.isEmpty &&
              (part.contains('经贸') ||
                  part.contains('职院') ||
                  part.contains('职业') ||
                  part.contains('大学') ||
                  part.contains('学院') ||
                  part.contains('专科') ||
                  part.contains('理工') ||
                  part.contains('师范') ||
                  part.contains('科技') ||
                  part.contains('商贸') ||
                  part.contains('外语') ||
                  part.contains('财经') ||
                  part.contains('工学院') ||
                  part.contains('医专') ||
                  part.contains('中医药'))) {
            school = part;
            continue;
          }

          // 判断专业
          if (subject.isEmpty) {
            String? matched;
            for (final entry in _subjectMap.entries) {
              if (part == entry.key || part.contains(entry.key)) {
                matched = entry.value;
                break;
              }
            }
            if (matched != null) {
              subject = matched;
              continue;
            }
          }

          // 判断姓名
          if (name.isEmpty &&
              RegExp(r'^[\u4e00-\u9fa5]{2,4}$').hasMatch(part) &&
              !part.contains('微') &&
              !part.contains('信') &&
              !part.contains('电') &&
              !part.contains('话') &&
              !part.contains('备') &&
              !part.contains('考')) {
            name = part;
            continue;
          }
        }

        if (name.isEmpty && parts.isNotEmpty) {
          name = parts.first;
        }

        if (name.isNotEmpty && (school.isNotEmpty || grade.isNotEmpty || subject.isNotEmpty)) {
          break;
        }
      }
    }

    // 4. 全局后备兜底
    if (school.isEmpty) {
      final schoolMatch = RegExp(
              r'[\u4e00-\u9fa5]{2,10}(?:大学|学院|职业技术学院|高等专科学校|经贸|职院)')
          .firstMatch(text);
      if (schoolMatch != null) {
        school = schoolMatch.group(0)!;
      }
    }

    if (grade.isEmpty) {
      final gradeMatch = RegExp(r'(?:20)?\d{2}[级届]').firstMatch(text);
      if (gradeMatch != null) {
        grade = gradeMatch.group(0)!;
      }
    }

    if (subject.isEmpty) {
      for (final entry in _subjectMap.entries) {
        if (text.contains(entry.key)) {
          subject = entry.value;
          break;
        }
      }
    }

    if (name.isEmpty) {
      final nameMatch = RegExp(r'(?:姓名|昵称|备注)[:：\s]*([\u4e00-\u9fa5]{2,4})').firstMatch(text);
      if (nameMatch != null) {
        name = nameMatch.group(1)!;
      }
    }

    // 5. 针对微信个人名片页特定布局兜底抓取（首个非系统关键字的大字行）
    if (name.isEmpty) {
      for (final rawLine in lines) {
        final line = rawLine.trim();
        if (line.isEmpty) continue;
        // 排除微信名片系统关键词
        if (line.contains('微信号') ||
            line.contains('地区') ||
            line.contains('发消息') ||
            line.contains('音视频') ||
            line.contains('朋友权限') ||
            line.contains('朋友圈') ||
            line.contains('标签') ||
            line.contains('来源') ||
            line.contains('描述') ||
            line.contains('设置备注') ||
            line.contains('更多信息') ||
            line.contains('通讯录') ||
            line.contains('微信') ||
            line.startsWith('http') ||
            RegExp(r'^\d+[\s:]*\d+').hasMatch(line)) {
          continue;
        }
        if (line.length >= 2 && line.length <= 15) {
          name = line;
          break;
        }
      }
    }

    return ClueParsedResult(
      name: name,
      phone: phone,
      wxId: wxId,
      school: school,
      grade: grade,
      subject: subject,
      rawText: text,
    );
  }
}
