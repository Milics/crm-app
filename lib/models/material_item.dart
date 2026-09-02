/// 审核状态定义
class MaterialReviewStatus {
  static const String none = 'none'; // 仅个人自用，未申请
  static const String pending = 'pending'; // 已提交，待超级管理员审核
  static const String approved = 'approved'; // 审核通过，已加入公共物料池
  static const String rejected = 'rejected'; // 已驳回
}

/// 文字物料
class TextMaterial {
  final String id;
  final String category;
  final String title;
  final String content;
  final String ownerName; // 创建人/归属老师
  final bool isPublic; // 是否为全局公共物料
  final String reviewStatus; // 审核状态：none, pending, approved, rejected
  final String rejectReason; // 驳回原因
  final DateTime createdAt; // 创建时间

  TextMaterial({
    required this.id,
    required this.category,
    required this.title,
    required this.content,
    this.ownerName = '超级管理员',
    this.isPublic = true,
    this.reviewStatus = MaterialReviewStatus.approved,
    this.rejectReason = '',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  TextMaterial copyWith({
    String? category,
    String? title,
    String? content,
    String? ownerName,
    bool? isPublic,
    String? reviewStatus,
    String? rejectReason,
  }) =>
      TextMaterial(
        id: id,
        category: category ?? this.category,
        title: title ?? this.title,
        content: content ?? this.content,
        ownerName: ownerName ?? this.ownerName,
        isPublic: isPublic ?? this.isPublic,
        reviewStatus: reviewStatus ?? this.reviewStatus,
        rejectReason: rejectReason ?? this.rejectReason,
        createdAt: createdAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'category': category,
        'title': title,
        'content': content,
        'ownerName': ownerName,
        'isPublic': isPublic,
        'reviewStatus': reviewStatus,
        'rejectReason': rejectReason,
        'createdAt': createdAt.toIso8601String(),
      };

  factory TextMaterial.fromJson(Map<String, dynamic> json) => TextMaterial(
        id: json['id'],
        category: json['category'] ?? '',
        title: json['title'] ?? '',
        content: json['content'] ?? '',
        ownerName: json['ownerName'] ?? '超级管理员',
        isPublic: json['isPublic'] ?? true,
        reviewStatus: json['reviewStatus'] ?? MaterialReviewStatus.approved,
        rejectReason: json['rejectReason'] ?? '',
        createdAt: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt']) ?? DateTime.now()
            : DateTime.now(),
      );
}

/// 图片物料
class ImageMaterial {
  final String id;
  final String category;
  final String title;
  final String desc;
  final String ownerName;
  final bool isPublic;
  final String reviewStatus;
  final String rejectReason;
  final DateTime createdAt;

  ImageMaterial({
    required this.id,
    required this.category,
    required this.title,
    required this.desc,
    this.ownerName = '超级管理员',
    this.isPublic = true,
    this.reviewStatus = MaterialReviewStatus.approved,
    this.rejectReason = '',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  ImageMaterial copyWith({
    String? category,
    String? title,
    String? desc,
    String? ownerName,
    bool? isPublic,
    String? reviewStatus,
    String? rejectReason,
  }) =>
      ImageMaterial(
        id: id,
        category: category ?? this.category,
        title: title ?? this.title,
        desc: desc ?? this.desc,
        ownerName: ownerName ?? this.ownerName,
        isPublic: isPublic ?? this.isPublic,
        reviewStatus: reviewStatus ?? this.reviewStatus,
        rejectReason: rejectReason ?? this.rejectReason,
        createdAt: createdAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'category': category,
        'title': title,
        'desc': desc,
        'ownerName': ownerName,
        'isPublic': isPublic,
        'reviewStatus': reviewStatus,
        'rejectReason': rejectReason,
        'createdAt': createdAt.toIso8601String(),
      };

  factory ImageMaterial.fromJson(Map<String, dynamic> json) => ImageMaterial(
        id: json['id'],
        category: json['category'] ?? '',
        title: json['title'] ?? '',
        desc: json['desc'] ?? '',
        ownerName: json['ownerName'] ?? '超级管理员',
        isPublic: json['isPublic'] ?? true,
        reviewStatus: json['reviewStatus'] ?? MaterialReviewStatus.approved,
        rejectReason: json['rejectReason'] ?? '',
        createdAt: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt']) ?? DateTime.now()
            : DateTime.now(),
      );
}
