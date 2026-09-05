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
  final bool fromPrivatePool; // 是否诞生自专属物料池（用于上架到公共池后依然在专属池保留并展示“已上架”标识）
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
    this.fromPrivatePool = false,
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
    bool? fromPrivatePool,
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
        fromPrivatePool: fromPrivatePool ?? this.fromPrivatePool,
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
        'fromPrivatePool': fromPrivatePool,
        'reviewStatus': reviewStatus,
        'rejectReason': rejectReason,
        'createdAt': createdAt.toIso8601String(),
      };

  factory TextMaterial.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String? ?? '';
    final isPublic = json['isPublic'] as bool? ?? true;
    final isOfficial = id.startsWith('tm_cb_') || id.startsWith('tm_def_');
    // 向下兼容：如果有明确存储则以存储为准；若无存储，则官方预置公共话术绝不是从专属池诞生
    final fromPrivatePool = json['fromPrivatePool'] as bool? ??
        (!isPublic && !isOfficial);

    return TextMaterial(
      id: id,
      category: json['category'] ?? '',
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      ownerName: json['ownerName'] ?? '超级管理员',
      isPublic: isPublic,
      fromPrivatePool: fromPrivatePool,
      reviewStatus: json['reviewStatus'] ?? MaterialReviewStatus.approved,
      rejectReason: json['rejectReason'] ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt']) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

/// 图片物料
class ImageMaterial {
  final String id;
  final String category;
  final String title;
  final String desc;
  final String? imageData; // Base64 格式的图片数据（可全端同步显示）
  final String? imageUrl; // 图片URL或本地路径
  final String ownerName;
  final bool isPublic;
  final bool fromPrivatePool; // 是否诞生自专属物料池
  final String reviewStatus;
  final String rejectReason;
  final DateTime createdAt;

  ImageMaterial({
    required this.id,
    required this.category,
    required this.title,
    required this.desc,
    this.imageData,
    this.imageUrl,
    this.ownerName = '超级管理员',
    this.isPublic = true,
    this.fromPrivatePool = false,
    this.reviewStatus = MaterialReviewStatus.approved,
    this.rejectReason = '',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  ImageMaterial copyWith({
    String? category,
    String? title,
    String? desc,
    String? imageData,
    String? imageUrl,
    String? ownerName,
    bool? isPublic,
    bool? fromPrivatePool,
    String? reviewStatus,
    String? rejectReason,
  }) =>
      ImageMaterial(
        id: id,
        category: category ?? this.category,
        title: title ?? this.title,
        desc: desc ?? this.desc,
        imageData: imageData ?? this.imageData,
        imageUrl: imageUrl ?? this.imageUrl,
        ownerName: ownerName ?? this.ownerName,
        isPublic: isPublic ?? this.isPublic,
        fromPrivatePool: fromPrivatePool ?? this.fromPrivatePool,
        reviewStatus: reviewStatus ?? this.reviewStatus,
        rejectReason: rejectReason ?? this.rejectReason,
        createdAt: createdAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'category': category,
        'title': title,
        'desc': desc,
        'imageData': imageData,
        'imageUrl': imageUrl,
        'ownerName': ownerName,
        'isPublic': isPublic,
        'fromPrivatePool': fromPrivatePool,
        'reviewStatus': reviewStatus,
        'rejectReason': rejectReason,
        'createdAt': createdAt.toIso8601String(),
      };

  factory ImageMaterial.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String? ?? '';
    final isPublic = json['isPublic'] as bool? ?? true;
    const officialIds = {'im1', 'im2', 'im3', 'im4', 'im5', 'im6', 'im7', 'im8'};
    final fromPrivatePool = json['fromPrivatePool'] as bool? ??
        (!isPublic && !officialIds.contains(id));

    return ImageMaterial(
      id: id,
      category: json['category'] ?? '',
      title: json['title'] ?? '',
      desc: json['desc'] ?? '',
      imageData: json['imageData'],
      imageUrl: json['imageUrl'],
      ownerName: json['ownerName'] ?? '超级管理员',
      isPublic: isPublic,
      fromPrivatePool: fromPrivatePool,
      reviewStatus: json['reviewStatus'] ?? MaterialReviewStatus.approved,
      rejectReason: json['rejectReason'] ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt']) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
