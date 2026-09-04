/// 安全解析日期字符串，容忍 null、'None'、空字符串和非法格式，返回 null 而非抛异常
DateTime? _safeParseDatetime(dynamic value) {
  if (value == null) return null;
  final str = value.toString().trim();
  if (str.isEmpty || str == 'null' || str == 'None') return null;
  try {
    return DateTime.parse(str);
  } catch (_) {
    return null;
  }
}

/// 线索状态枚举
enum ClueStatus {
  following,  // 待跟进
  contacted,  // 联系中
  invited,   // 已邀约
  attended,  // 已试听
  enrolled,   // 已报名
  paused,    // 暂搁置
}

/// 意向等级枚举
enum IntentLevel {
  high,   // 高意向
  medium, // 中意向
  low,    // 低意向
  none,   // 未标记
}

/// 沟通方式枚举
enum ContactMethod {
  wechat, // 微信聊天
  phone,  // 电话
  face,   // 当面沟通
}

/// 回访结果枚举
enum VisitResult {
  normal,       // 沟通正常
  followUp,     // 继续跟进
  unreachable,  // 暂时联系不上
  noIntent,     // 明确无意向
  intentUp,     // 意向提升
  trialBooked,  // 约约试听
}

/// 线索数据模型
class Clue {
  final String id;
  String wxNick;
  String wxId;
  String phone;
  String grade;
  String school;
  String subject;
  String source;
  String classType;
  ClueStatus status;
  IntentLevel intentLevel;
  DateTime? nextVisitTime;
  final DateTime createTime;
  List<VisitLog> visitLogs;
  List<ChatRecord> chatRecords;
  List<String> tags;
  String remark;
  String ownerName; // 归属老师姓名
  String? aiAnalysisReport; // 最新保存的 AI 大模型深度分析报告
  DateTime? aiAnalysisTime; // 最新分析生成时间

  Clue({
    required this.id,
    required this.wxNick,
    this.wxId = '',
    this.phone = '',
    this.grade = '',
    this.school = '',
    this.subject = '',
    this.source = '',
    this.classType = '',
    this.status = ClueStatus.following,
    this.intentLevel = IntentLevel.none,
    this.nextVisitTime,
    required this.createTime,
    List<VisitLog>? visitLogs,
    List<ChatRecord>? chatRecords,
    List<String>? tags,
    this.remark = '',
    this.ownerName = '',
    this.aiAnalysisReport,
    this.aiAnalysisTime,
  })  : visitLogs = visitLogs ?? [],
        chatRecords = chatRecords ?? [],
        tags = tags ?? [];

  Map<String, dynamic> toJson() => {
        'id': id,
        'wxNick': wxNick,
        'wxId': wxId,
        'phone': phone,
        'grade': grade,
        'school': school,
        'subject': subject,
        'source': source,
        'classType': classType,
        'status': status.name,
        'intentLevel': intentLevel.name,
        'nextVisitTime': nextVisitTime?.toIso8601String(),
        'createTime': createTime.toIso8601String(),
        'visitLogs': visitLogs.map((v) => v.toJson()).toList(),
        'chatRecords': chatRecords.map((c) => c.toJson()).toList(),
        'tags': tags,
        'remark': remark,
        'ownerName': ownerName,
        'aiAnalysisReport': aiAnalysisReport,
        'aiAnalysisTime': aiAnalysisTime?.toIso8601String(),
      };

  factory Clue.fromJson(Map<String, dynamic> json) => Clue(
        id: json['id'],
        wxNick: json['wxNick'] ?? '',
        wxId: json['wxId'] ?? '',
        phone: json['phone'] ?? '',
        grade: json['grade'] ?? '',
        school: json['school'] ?? '',
        subject: json['subject'] ?? '',
        source: json['source'] ?? '',
        classType: json['classType'] ?? '',
        status: ClueStatus.values.firstWhere(
          (e) => e.name == json['status'],
          orElse: () => ClueStatus.following,
        ),
        intentLevel: IntentLevel.values.firstWhere(
          (e) => e.name == json['intentLevel'],
          orElse: () => IntentLevel.none,
        ),
        nextVisitTime: _safeParseDatetime(json['nextVisitTime']),
        createTime: _safeParseDatetime(json['createTime']) ?? DateTime.now(),
        visitLogs: (json['visitLogs'] as List<dynamic>?)
                ?.map((v) => VisitLog.fromJson(v))
                .toList() ??
            [],
        chatRecords: (json['chatRecords'] as List<dynamic>?)
                ?.map((c) => ChatRecord.fromJson(c))
                .toList() ??
            [],
        tags: (json['tags'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
        remark: json['remark'] ?? '',
        ownerName: json['ownerName'] ?? '',
        aiAnalysisReport: json['aiAnalysisReport'],
        aiAnalysisTime: _safeParseDatetime(json['aiAnalysisTime']),
      );

  String get statusText {
    switch (status) {
      case ClueStatus.following:
        return '待跟进';
      case ClueStatus.contacted:
        return '联系中';
      case ClueStatus.invited:
        return '已邀约';
      case ClueStatus.attended:
        return '已试听';
      case ClueStatus.enrolled:
        return '已报名';
      case ClueStatus.paused:
        return '无效线索';
    }
  }

  String get intentText {
    switch (intentLevel) {
      case IntentLevel.high:
        return '高意向';
      case IntentLevel.medium:
        return '中意向';
      case IntentLevel.low:
        return '低意向';
      case IntentLevel.none:
        return '未标记';
    }
  }
}

/// 回访记录数据模型
class VisitLog {
  final String id;
  final String clueId;
  ContactMethod contactMethod;
  VisitResult visitResult;
  String visitContent;
  List<String> concerns;
  DateTime? nextVisitTime;
  final DateTime createTime;

  VisitLog({
    required this.id,
    required this.clueId,
    this.contactMethod = ContactMethod.wechat,
    this.visitResult = VisitResult.normal,
    required this.visitContent,
    List<String>? concerns,
    this.nextVisitTime,
    required this.createTime,
  }) : concerns = concerns ?? [];

  Map<String, dynamic> toJson() => {
        'id': id,
        'clueId': clueId,
        'contactMethod': contactMethod.name,
        'visitResult': visitResult.name,
        'visitContent': visitContent,
        'concerns': concerns,
        'nextVisitTime': nextVisitTime?.toIso8601String(),
        'createTime': createTime.toIso8601String(),
      };

  factory VisitLog.fromJson(Map<String, dynamic> json) => VisitLog(
        id: json['id'],
        clueId: json['clueId'],
        contactMethod: ContactMethod.values.firstWhere(
          (e) => e.name == json['contactMethod'],
          orElse: () => ContactMethod.wechat,
        ),
        visitResult: VisitResult.values.firstWhere(
          (e) => e.name == json['visitResult'],
          orElse: () => VisitResult.normal,
        ),
        visitContent: json['visitContent'] ?? '',
        concerns: List<String>.from(json['concerns'] ?? []),
        nextVisitTime: _safeParseDatetime(json['nextVisitTime']),
        createTime: _safeParseDatetime(json['createTime']) ?? DateTime.now(),
      );
}

/// 聊天截图记录
class ChatRecord {
  final String id;
  final String clueId;
  final String imagePath;
  final String? imageData; // Base64 格式的图片数据（跨设备全端同步显示）
  String ocrText;
  final DateTime createTime;

  ChatRecord({
    required this.id,
    required this.clueId,
    required this.imagePath,
    this.imageData,
    this.ocrText = '',
    required this.createTime,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'clueId': clueId,
        'imagePath': imagePath,
        'imageData': imageData,
        'ocrText': ocrText,
        'createTime': createTime.toIso8601String(),
      };

  factory ChatRecord.fromJson(Map<String, dynamic> json) => ChatRecord(
        id: json['id'],
        clueId: json['clueId'],
        imagePath: json['imagePath'] ?? '',
        imageData: json['imageData'],
        ocrText: json['ocrText'] ?? '',
        createTime: _safeParseDatetime(json['createTime']) ?? DateTime.now(),
      );
}


/// 扩展方法：枚举转中文
extension ClueStatusExt on ClueStatus {
  String get label {
    switch (this) {
      case ClueStatus.following: return '待跟进';
      case ClueStatus.contacted: return '联系中';
      case ClueStatus.invited: return '已邀约';
      case ClueStatus.attended: return '已试听';
      case ClueStatus.enrolled: return '已报名';
      case ClueStatus.paused: return '暂搁置';
    }
  }
}

extension IntentLevelExt on IntentLevel {
  String get label {
    switch (this) {
      case IntentLevel.high: return '高意向';
      case IntentLevel.medium: return '中意向';
      case IntentLevel.low: return '低意向';
      case IntentLevel.none: return '';
    }
  }
}

extension ContactMethodExt on ContactMethod {
  String get label {
    switch (this) {
      case ContactMethod.wechat: return '微信聊天';
      case ContactMethod.phone: return '电话';
      case ContactMethod.face: return '当面沟通';
    }
  }
}

extension VisitResultExt on VisitResult {
  String get label {
    switch (this) {
      case VisitResult.normal: return '沟通正常';
      case VisitResult.followUp: return '继续跟进';
      case VisitResult.unreachable: return '暂时联系不上';
      case VisitResult.noIntent: return '明确无意向';
      case VisitResult.intentUp: return '意向提升';
      case VisitResult.trialBooked: return '约约试听';
    }
  }
}
