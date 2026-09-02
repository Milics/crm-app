/// 角色类型定义
enum UserRole {
  superAdmin('super_admin', '超级管理员', '👑'),
  advisor('advisor', '招生顾问', '💼');

  final String code;
  final String label;
  final String icon;
  const UserRole(this.code, this.label, this.icon);

  static UserRole fromCode(String code) {
    return UserRole.values.firstWhere(
      (r) => r.code == code,
      orElse: () => UserRole.advisor,
    );
  }
}

/// 用户实体类（第一期精简架构：各人管各自的数据，单独配置物料编辑特权）
class AppUser {
  final String id;
  final String username; // 登录账号（唯一）
  final String password; // 登录密码
  final String name; // 真实姓名（例如：张老师）
  final UserRole role; // 角色（超管 / 顾问）
  final bool isActive; // 账号状态：true 正常，false 已禁用
  final String phone; // 手机号
  final bool canManageMaterials; // 是否允许编辑公共话术与物料库
  final DateTime createdAt; // 创建时间
  final String createdBy; // 创建人姓名/账号

  AppUser({
    required this.id,
    required this.username,
    required this.password,
    required this.name,
    this.role = UserRole.advisor,
    this.isActive = true,
    this.phone = '',
    bool? canManageMaterials,
    DateTime? createdAt,
    this.createdBy = '系统',
  })  : canManageMaterials = canManageMaterials ?? (role == UserRole.superAdmin),
        createdAt = createdAt ?? DateTime.now();

  /// 权限校验助手
  bool get isSuperAdmin => role == UserRole.superAdmin;
  bool get canManageUsers => isSuperAdmin;
  bool get canViewAllClues => isSuperAdmin;

  AppUser copyWith({
    String? username,
    String? password,
    String? name,
    UserRole? role,
    bool? isActive,
    String? phone,
    bool? canManageMaterials,
  }) {
    return AppUser(
      id: id,
      username: username ?? this.username,
      password: password ?? this.password,
      name: name ?? this.name,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      phone: phone ?? this.phone,
      canManageMaterials: canManageMaterials ?? this.canManageMaterials,
      createdAt: createdAt,
      createdBy: createdBy,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'password': password,
      'name': name,
      'role': role.code,
      'isActive': isActive,
      'phone': phone,
      'canManageMaterials': canManageMaterials,
      'createdAt': createdAt.toIso8601String(),
      'createdBy': createdBy,
    };
  }

  factory AppUser.fromJson(Map<String, dynamic> json) {
    final role = UserRole.fromCode(json['role'] ?? 'advisor');
    final canManageMat = json['canManageMaterials'] as bool? ??
        (role == UserRole.superAdmin);

    return AppUser(
      id: json['id'] ?? '',
      username: json['username'] ?? '',
      password: json['password'] ?? '123456',
      name: json['name'] ?? '',
      role: role,
      isActive: json['isActive'] ?? true,
      phone: json['phone'] ?? '',
      canManageMaterials: canManageMat,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt']) ?? DateTime.now()
          : DateTime.now(),
      createdBy: json['createdBy'] ?? '系统',
    );
  }
}
