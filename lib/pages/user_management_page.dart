import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/app_user.dart';

/// 后台账号管理页面（仅超级管理员可见）
class UserManagementPage extends StatefulWidget {
  const UserManagementPage({super.key});

  @override
  State<UserManagementPage> createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage> {
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppProvider>().syncUsersFromCloud();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          '账号管理',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt_1_rounded),
            tooltip: '添加员工账号',
            onPressed: () => _showUserDialog(context),
          ),
        ],
      ),
      body: Consumer<AppProvider>(
        builder: (context, provider, _) {
          final users = provider.users.where((u) {
            if (_searchQuery.isEmpty) return true;
            final q = _searchQuery.toLowerCase();
            return u.name.toLowerCase().contains(q) ||
                u.username.toLowerCase().contains(q) ||
                u.phone.contains(q);
          }).toList();

          final totalCount = provider.users.length;
          final activeCount = provider.users.where((u) => u.isActive).length;
          final superCount = provider.users.where((u) => u.isSuperAdmin).length;

          return Column(
            children: [
              // 顶部统计指标与搜索栏
              Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        _StatChip(
                          label: '总员工',
                          value: '$totalCount',
                          color: const Color(0xFF1976D2),
                        ),
                        const SizedBox(width: 8),
                        _StatChip(
                          label: '启用中',
                          value: '$activeCount',
                          color: const Color(0xFF2E7D32),
                        ),
                        const SizedBox(width: 8),
                        _StatChip(
                          label: '管理员',
                          value: '$superCount',
                          color: const Color(0xFFE65100),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      decoration: InputDecoration(
                        hintText: '搜索姓名、账号、手机号...',
                        prefixIcon: const Icon(Icons.search, size: 20),
                        filled: true,
                        fillColor: const Color(0xFFF5F7FA),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onChanged: (val) => setState(() => _searchQuery = val),
                    ),
                  ],
                ),
              ),

              // 员工列表视图
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    final success = await provider.syncUsersFromCloud();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(success ? '☁️ 员工数据已同步' : '⚠️ 暂无云端数据更新'),
                          duration: const Duration(seconds: 1),
                          backgroundColor: success ? Colors.green : Colors.orange,
                        ),
                      );
                    }
                  },
                  child: users.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: const [
                            SizedBox(height: 120),
                            Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.person_off_outlined,
                                      size: 56, color: Colors.grey),
                                  SizedBox(height: 12),
                                  Text('未找到符合条件的员工账号',
                                      style: TextStyle(color: Colors.grey)),
                                ],
                              ),
                            ),
                          ],
                        )
                      : ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(12),
                          itemCount: users.length,
                          itemBuilder: (context, index) {
                            final user = users[index];
                            final isCurrent =
                                provider.currentUserObj?.id == user.id;

                          return _UserCard(
                            user: user,
                            isCurrentLoginUser: isCurrent,
                            onEdit: () =>
                                _showUserDialog(context, editUser: user),
                            onResetPassword: () =>
                                _showResetPasswordDialog(context, user: user),
                            onToggleStatus: () async {
                              final res =
                                  await provider.toggleUserStatus(user.id);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(res['message']),
                                    backgroundColor: res['success']
                                        ? Colors.green
                                        : Colors.red,
                                  ),
                                );
                              }
                            },
                            onDelete: () => _confirmDeleteUser(context, user),
                          );
                        },
                      ),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showUserDialog(context),
        backgroundColor: const Color(0xFF1976D2),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('添加员工',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  /// 显示添加/编辑用户弹窗
  void _showUserDialog(BuildContext context, {AppUser? editUser}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _UserEditModal(editUser: editUser),
    );
  }

  /// 显示重置密码弹窗
  void _showResetPasswordDialog(BuildContext context, {required AppUser user}) {
    final pwdCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('重置密码 - ${user.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('为账号 @${user.username} 设置新密码：',
                style: const TextStyle(fontSize: 13, color: Colors.grey)),
            const SizedBox(height: 12),
            TextField(
              controller: pwdCtrl,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: '新密码',
                hintText: '请输入至少 6 位密码',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newPwd = pwdCtrl.text.trim();
              if (newPwd.length < 6) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('密码长度不能少于 6 位'),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }
              final success = await context
                  .read<AppProvider>()
                  .resetUserPassword(user.id, newPwd);
              if (ctx.mounted) Navigator.pop(ctx);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? '✅ 密码重置成功' : '重置失败'),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            child: const Text('确认重置'),
          ),
        ],
      ),
    );
  }

  /// 确认删除账号
  void _confirmDeleteUser(BuildContext context, AppUser user) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认删除账号?'),
        content: Text(
          '确定要彻底删除员工【${user.name}】(@${user.username}) 吗？\n删除后该账号将无法再登录系统。',
          style: const TextStyle(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              final res =
                  await context.read<AppProvider>().deleteUser(user.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(res['message']),
                    backgroundColor:
                        res['success'] ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            child: const Text('彻底删除'),
          ),
        ],
      ),
    );
  }
}

/// 顶部小指标 Chip
class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatChip(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 11, color: color)),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 单个员工卡片
class _UserCard extends StatelessWidget {
  final AppUser user;
  final bool isCurrentLoginUser;
  final VoidCallback onEdit;
  final VoidCallback onResetPassword;
  final VoidCallback onToggleStatus;
  final VoidCallback onDelete;

  const _UserCard({
    required this.user,
    required this.isCurrentLoginUser,
    required this.onEdit,
    required this.onResetPassword,
    required this.onToggleStatus,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final roleColor = user.isSuperAdmin
        ? const Color(0xFFE65100)
        : const Color(0xFF1976D2);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isCurrentLoginUser
              ? const Color(0xFF1976D2).withValues(alpha: 0.4)
              : Colors.black.withValues(alpha: 0.05),
          width: isCurrentLoginUser ? 1.5 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 头部：姓名、账号、角色 Badge、状态开关
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: roleColor.withValues(alpha: 0.12),
                  child: Text(
                    user.name.isNotEmpty ? user.name.substring(0, 1) : '用',
                    style: TextStyle(
                      color: roleColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            user.name,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: user.isActive
                                  ? Colors.black87
                                  : Colors.grey,
                            ),
                          ),
                          if (isCurrentLoginUser) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1976D2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                '当前登录',
                                style: TextStyle(
                                    fontSize: 10, color: Colors.white),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '@${user.username}${user.phone.isNotEmpty ? ' · ${user.phone}' : ''}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                // 角色 Badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: roleColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${user.role.icon} ${user.role.label}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: roleColor,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 8),

            // 特权标签展示
            Row(
              children: [
                if (user.isSuperAdmin)
                  _PermBadge(label: '👑 超级管理员（全权）', color: Colors.orange)
                else if (user.canManageMaterials)
                  _PermBadge(label: '💬 公共物料编辑特权', color: Colors.teal)
                else
                  _PermBadge(label: '💼 专属个人线索池', color: Colors.blueGrey),
              ],
            ),

            const SizedBox(height: 10),

            // 底部操作栏：启用/禁用状态 Switch、操作按钮
            Row(
              children: [
                GestureDetector(
                  onTap: isCurrentLoginUser ? null : onToggleStatus,
                  child: Row(
                    children: [
                      Switch(
                        value: user.isActive,
                        onChanged:
                            isCurrentLoginUser ? null : (_) => onToggleStatus(),
                        activeThumbColor: const Color(0xFF2E7D32),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      Text(
                        user.isActive ? '正常' : '已禁用',
                        style: TextStyle(
                          fontSize: 12,
                          color: user.isActive
                              ? const Color(0xFF2E7D32)
                              : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                OutlinedButton.icon(
                  icon: const Icon(Icons.key, size: 14),
                  label: const Text('重置密码', style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: onResetPassword,
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  tooltip: '编辑员工',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: onEdit,
                ),
                const SizedBox(width: 8),
                if (!isCurrentLoginUser && !user.isSuperAdmin)
                  IconButton(
                    icon: const Icon(Icons.delete_outline,
                        size: 18, color: Colors.red),
                    tooltip: '删除员工',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: onDelete,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PermBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _PermBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w500),
      ),
    );
  }
}

/// 添加/编辑员工 BottomSheet（精简版：仅物料编辑开关）
class _UserEditModal extends StatefulWidget {
  final AppUser? editUser;
  const _UserEditModal({this.editUser});

  @override
  State<_UserEditModal> createState() => _UserEditModalState();
}

class _UserEditModalState extends State<_UserEditModal> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _usernameCtrl;
  late TextEditingController _nameCtrl;
  late TextEditingController _passwordCtrl;
  late TextEditingController _phoneCtrl;

  late UserRole _selectedRole;
  late bool _canManageMaterials;

  @override
  void initState() {
    super.initState();
    final u = widget.editUser;
    _usernameCtrl = TextEditingController(text: u?.username ?? '');
    _nameCtrl = TextEditingController(text: u?.name ?? '');
    _passwordCtrl = TextEditingController(text: u == null ? '123456' : '');
    _phoneCtrl = TextEditingController(text: u?.phone ?? '');

    _selectedRole = u?.role ?? UserRole.advisor;
    _canManageMaterials = u?.canManageMaterials ?? false;
  }

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _nameCtrl.dispose();
    _passwordCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.editUser != null;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 标题
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isEdit ? '编辑员工信息 - ${widget.editUser!.name}' : '➕ 添加新员工账号',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 10),

              // 基本信息
              TextFormField(
                controller: _usernameCtrl,
                enabled: !isEdit,
                decoration: InputDecoration(
                  labelText: '登录账号名 *',
                  hintText: '用于登录系统（如：zhangsan）',
                  prefixIcon: const Icon(Icons.account_circle_outlined),
                  border: const OutlineInputBorder(),
                  filled: isEdit,
                  fillColor: isEdit ? Colors.grey[100] : null,
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? '请输入登录账号名' : null,
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _nameCtrl,
                      decoration: const InputDecoration(
                        labelText: '真实姓名 *',
                        hintText: '如：张老师',
                        prefixIcon: Icon(Icons.badge_outlined),
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? '请输入真实姓名' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _phoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: '手机号',
                        hintText: '可选',
                        prefixIcon: Icon(Icons.phone_outlined),
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              if (!isEdit) ...[
                TextFormField(
                  controller: _passwordCtrl,
                  decoration: const InputDecoration(
                    labelText: '初始密码 *',
                    hintText: '默认 123456',
                    prefixIcon: Icon(Icons.lock_outline),
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => v == null || v.trim().length < 6
                      ? '密码长度不能少于6位'
                      : null,
                ),
                const SizedBox(height: 16),
              ],

              // 角色选择
              const Text('选择系统角色',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Text('👑 超级管理员',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      selected: _selectedRole == UserRole.superAdmin,
                      selectedColor: const Color(0xFFE65100),
                      labelStyle: TextStyle(
                        color: _selectedRole == UserRole.superAdmin
                            ? Colors.white
                            : Colors.black87,
                      ),
                      onSelected: (val) {
                        if (val) {
                          setState(() {
                            _selectedRole = UserRole.superAdmin;
                            _canManageMaterials = true;
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ChoiceChip(
                      label: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Text('💼 招生顾问',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      selected: _selectedRole == UserRole.advisor,
                      selectedColor: const Color(0xFF1976D2),
                      labelStyle: TextStyle(
                        color: _selectedRole == UserRole.advisor
                            ? Colors.white
                            : Colors.black87,
                      ),
                      onSelected: (val) {
                        if (val) {
                          setState(() {
                            _selectedRole = UserRole.advisor;
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // 物料管理特权单选开关（替代旧的多项复杂配置）
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F7FA),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Row(
                  children: [
                    const Icon(Icons.collections_bookmark_outlined,
                        color: Color(0xFF1976D2), size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '公共话术物料管理权限',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _selectedRole == UserRole.superAdmin
                                ? '超级管理员默认拥有物料编辑权限'
                                : '开启后允许该老师添加、修改和删除全局话术与图片',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _selectedRole == UserRole.superAdmin
                          ? true
                          : _canManageMaterials,
                      activeThumbColor: const Color(0xFF1976D2),
                      onChanged: _selectedRole == UserRole.superAdmin
                          ? null
                          : (val) {
                              setState(() => _canManageMaterials = val);
                            },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // 底部保存按钮
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1976D2),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () async {
                    if (!_formKey.currentState!.validate()) return;

                    final provider = context.read<AppProvider>();

                    if (isEdit) {
                      // 编辑已有用户
                      final updated = widget.editUser!.copyWith(
                        name: _nameCtrl.text.trim(),
                        phone: _phoneCtrl.text.trim(),
                        role: _selectedRole,
                        canManageMaterials: _canManageMaterials,
                      );
                      final messenger = ScaffoldMessenger.of(context);
                      final navigator = Navigator.of(context);

                      final ok = await provider.updateUser(updated);
                      if (mounted) navigator.pop();
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text(ok ? '✅ 员工信息已更新' : '更新失败'),
                          backgroundColor: ok ? Colors.green : Colors.red,
                        ),
                      );
                    } else {
                      // 新增用户
                      final newUser = AppUser(
                        id: 'usr_${DateTime.now().millisecondsSinceEpoch}',
                        username: _usernameCtrl.text.trim(),
                        name: _nameCtrl.text.trim(),
                        password: _passwordCtrl.text.trim(),
                        phone: _phoneCtrl.text.trim(),
                        role: _selectedRole,
                        canManageMaterials: _canManageMaterials,
                        createdBy: provider.currentUser,
                      );
                      final messenger = ScaffoldMessenger.of(context);
                      final navigator = Navigator.of(context);

                      final res = await provider.addUser(newUser);
                      if (mounted) navigator.pop();
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text(res['message']),
                          backgroundColor:
                              res['success'] ? Colors.green : Colors.red,
                        ),
                      );
                    }
                  },
                  child: Text(
                    isEdit ? '保存修改' : '确认添加员工',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
