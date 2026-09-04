import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/app_provider.dart';
import '../models/clue.dart';
import '../services/crm_sync_service.dart';
import '../widgets/batch_import_dialog.dart';
import 'materials_page.dart';
import 'user_management_page.dart';

/// 我的页面（顾问个人中心 & 数据概况）
class MinePage extends StatelessWidget {
  const MinePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Consumer<AppProvider>(
        builder: (context, provider, _) {
          final isSuper = provider.isSuperAdmin;
          final canManage = provider.canManageUsers;

          return SingleChildScrollView(
            child: Column(
              children: [
                // 顶部个人信息与业绩概况区
                _ProfileHeaderCard(provider: provider),

                const SizedBox(height: 16),

                // 超级管理员专属管理菜单
                if (canManage) ...[
                  _SectionTitle(title: '系统与团队管理'),
                  _MenuItem(
                    icon: Icons.manage_accounts_rounded,
                    title: '员工账号管理',
                    subtitle: '管理 ${provider.users.length} 位员工账号 · 添加/重置密码/停用',
                    iconColor: const Color(0xFFE65100),
                    trailingBadge: isSuper ? '超管' : null,
                    badgeColor: const Color(0xFFE65100),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const UserManagementPage()),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // 云端备份状态区
                _SectionTitle(title: '数据安全与云端'),
                _MenuItem(
                  icon: Icons.cloud_done_rounded,
                  title: '云端同步状态',
                  subtitle: provider.isCloudConnected
                      ? '🟢 云端实时双向同步中（防丢防卸载）'
                      : '🟡 本地离线持久化模式（联网后自动同步）',
                  iconColor: provider.isCloudConnected
                      ? const Color(0xFF2E7D32)
                      : const Color(0xFFF57C00),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(provider.isCloudConnected
                            ? '✅ 数据已在云端实时备份，多设备秒级互通！'
                            : '⚡ 当前处于离线/本地缓存状态，网络连接正常后将自动完成云端合并。'),
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 16),

                // 业务功能菜单组
                _SectionTitle(title: '业务工具'),
                _MenuItem(
                  icon: Icons.collections_outlined,
                  title: '我的物料与话术',
                  subtitle: '${provider.textMaterials.length} 条文字话术 · ${provider.imageMaterials.length} 组图片',
                  iconColor: const Color(0xFF1976D2),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const MaterialsPage()),
                  ),
                ),
                _MenuItem(
                  icon: Icons.playlist_add_check,
                  title: '批量导入专升本线索',
                  subtitle: '从 Excel / 微信名单复制多行文本一键解析与查重导入',
                  iconColor: const Color(0xFF1976D2),
                  onTap: () => showDialog(
                    context: context,
                    builder: (_) => const BatchImportDialog(),
                  ),
                ),
                _MenuItem(
                  icon: Icons.file_download_outlined,
                  title: '导出线索报表 (CSV)',
                  subtitle: provider.canExportData
                      ? '一键生成并导出全部 ${provider.totalClues} 条线索（支持 Excel 格式）'
                      : '🔒 暂无导出权限（需管理员授权）',
                  iconColor: provider.canExportData
                      ? const Color(0xFF2E7D32)
                      : Colors.grey,
                  onTap: () {
                    if (!provider.canExportData) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('⚠️ 暂无数据导出权限，请联系超级管理员在后台开通'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                      return;
                    }
                    _showExportCsvDialog(context, provider);
                  },
                ),

                const SizedBox(height: 16),

                // 系统与工具菜单组
                _SectionTitle(title: '系统设置'),
                _MenuItem(
                  icon: Icons.cloud_sync_outlined,
                  title: '云端同步与公网配置',
                  subtitle: '绑定云端免费域名，实现异地免开电脑实时互通',
                  iconColor: const Color(0xFF0288D1),
                  trailingBadge: provider.isCloudConnected ? '已连通' : '离线模式',
                  badgeColor: provider.isCloudConnected ? Colors.green : Colors.grey,
                  onTap: () => _showCloudSyncDialog(context, provider),
                ),
                if (isSuper)
                  _MenuItem(
                    icon: Icons.restart_alt_rounded,
                    title: '恢复初始演示数据',
                    subtitle: '清空当前修改并重置15条测试线索',
                    iconColor: Colors.orange,
                    onTap: () => _showResetDialog(context, provider),
                  ),
                _MenuItem(
                  icon: Icons.lock_outline,
                  title: '修改我的密码',
                  subtitle: '修改当前账号的登录密码',
                  iconColor: const Color(0xFF5C6BC0),
                  onTap: () => _showChangePasswordDialog(context, provider),
                ),
                _MenuItem(
                  icon: Icons.info_outline,
                  title: '关于 CRM 系统',
                  iconColor: const Color(0xFF26A69A),
                  onTap: () => _showAboutDialog(context),
                ),

                const SizedBox(height: 16),

                // 退出登录
                _MenuItem(
                  icon: Icons.logout,
                  title: '退出登录',
                  titleColor: Colors.red,
                  iconColor: Colors.red,
                  onTap: () => _showLogoutDialog(context, provider),
                ),

                const SizedBox(height: 32),
                const Text(
                  '专升本招生 CRM  v1.0.0 (Release)',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showExportCsvDialog(BuildContext context, AppProvider provider) {
    final buffer = StringBuffer();
    // 注入 UTF-8 BOM，防止 Windows Excel 打开中文显示乱码
    buffer.write('\uFEFF');
    // 表头
    buffer.writeln('序号,微信昵称,微信号,手机号,就读学校,年级/届别,报考专业,线索来源,意向班型,跟进状态,意向等级,特征标签,回访次数,下次回访时间,创建时间,备注');

    int index = 1;
    for (final c in provider.clues) {
      final nextVisit = c.nextVisitTime != null
          ? DateFormat('yyyy-MM-dd HH:mm').format(c.nextVisitTime!)
          : '未设置';
      final createTime = DateFormat('yyyy-MM-dd').format(c.createTime);
      final tags = c.tags.isNotEmpty ? c.tags.join(';') : '';
      final remark = c.remark.replaceAll(',', '，').replaceAll('\n', ' ');

      buffer.writeln(
        '$index,${c.wxNick},${c.wxId},${c.phone},${c.school},${c.grade},'
        '${c.subject},${c.source},${c.classType},${c.status.label},${c.intentLevel.label},"$tags",'
        '${c.visitLogs.length},$nextVisit,$createTime,"$remark"',
      );
      index++;
    }

    final csvContent = buffer.toString();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.table_chart_outlined, color: Color(0xFF2E7D32)),
            SizedBox(width: 8),
            Text('导出线索报表'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('已成功导出 ${provider.clues.length} 条线索完整数据！',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 8),
            const Text(
              '✅ 已注入 UTF-8 BOM 防乱码标头，Windows Excel、Mac Numbers 打开中文 100% 正常显示。',
              style: TextStyle(fontSize: 12, color: Color(0xFF2E7D32), height: 1.4),
            ),
            const SizedBox(height: 12),
            Container(
              height: 90,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFCBD5E1)),
              ),
              child: SingleChildScrollView(
                child: Text(
                  csvContent,
                  style: const TextStyle(fontSize: 10, fontFamily: 'monospace', color: Colors.black87),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('关闭'),
          ),
          OutlinedButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: csvContent));
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('CSV 数据已复制到剪贴板，可直接粘贴进 Excel 表格！'),
                  backgroundColor: Color(0xFF1976D2),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            icon: const Icon(Icons.copy_rounded, size: 15),
            label: const Text('复制文本'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              try {
                final uri = Uri.dataFromString(
                  csvContent,
                  mimeType: 'text/csv',
                  encoding: utf8,
                );
                await launchUrl(uri);
              } catch (_) {
                Clipboard.setData(ClipboardData(text: csvContent));
              }
              if (ctx.mounted) Navigator.pop(ctx);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('已触发 CSV 文件下载 / 打开！'),
                    backgroundColor: Color(0xFF2E7D32),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
            icon: const Icon(Icons.file_download, size: 16),
            label: const Text('下载 CSV 文件'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _showResetDialog(BuildContext context, AppProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('重置演示数据'),
        content: const Text('确定要将所有线索与物料恢复至初始模拟数据吗？\n当前添加的线索与修改将被覆盖。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              provider.resetToMockData();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('数据已恢复至初始演示状态'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('确认重置'),
          ),
        ],
      ),
    );
  }



  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.asset(
                'assets/images/logo.png',
                width: 24,
                height: 24,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const Icon(Icons.school, size: 24, color: Color(0xFF1976D2)),
              ),
            ),
            const SizedBox(width: 8),
            const Text('关于应用'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  'assets/images/logo.png',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.school, size: 40, color: Color(0xFF1976D2)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              '全科专升本 · 招生CRM',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            const Text('版本：V1.0.0 (Release)',
                style: TextStyle(color: Colors.black87, fontSize: 13)),
            const SizedBox(height: 4),
            const Text('适用对象：专升本招生团队 / 咨询顾问',
                style: TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 8),
            const Text(
              '功能亮点：全流程线索跟进、跟进时间轴、话术与物料库、支持多维度检索与数据持久化。',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 12, height: 1.4),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('知道了'),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog(
      BuildContext context, AppProvider provider) {
    final oldPwdCtrl = TextEditingController();
    final newPwdCtrl = TextEditingController();
    final confirmPwdCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('修改我的密码'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: oldPwdCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: '原密码',
                  hintText: '请输入当前密码',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: newPwdCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: '新密码',
                  hintText: '至少 6 位',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: confirmPwdCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: '确认新密码',
                  hintText: '请再次输入新密码',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              final oldP = oldPwdCtrl.text.trim();
              final newP = newPwdCtrl.text.trim();
              final confP = confirmPwdCtrl.text.trim();

              final currentU = provider.currentUserObj;
              if (currentU != null && currentU.password != oldP) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('原密码不正确'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              if (newP.length < 6) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('新密码长度不能少于 6 位'),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }

              if (newP != confP) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('两次输入的新密码不一致'),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }

              if (currentU != null) {
                await provider.resetUserPassword(currentU.id, newP);
              }

              if (ctx.mounted) Navigator.pop(ctx);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✅ 密码修改成功！请妥善保管新密码'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: const Text('确认修改'),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, AppProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('退出登录'),
        content: Text('确定要退出【${provider.currentUser}】账号吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              provider.logout();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('退出', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showCloudSyncDialog(BuildContext context, AppProvider provider) {
    final syncService = CrmSyncService();
    final urlCtrl = TextEditingController(
      text: (syncService.customCloudUrl != null && syncService.customCloudUrl!.isNotEmpty)
          ? syncService.customCloudUrl!
          : 'https://crm-app-ojs3.onrender.com',
    );
    bool isTesting = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final isConnected = syncService.isConnected;
          final activeNode = syncService.activeBaseUrl ?? '未连接（当前为本地离线模式）';

          return AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.cloud_sync, color: Color(0xFF0288D1)),
                SizedBox(width: 8),
                Text('云端同步与公网配置', style: TextStyle(fontSize: 17)),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isConnected
                          ? const Color(0xFFE8F5E9)
                          : const Color(0xFFFFF3E0),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isConnected ? Colors.green.shade300 : Colors.orange.shade300,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isConnected ? Icons.check_circle : Icons.offline_bolt_rounded,
                          color: isConnected ? Colors.green : Colors.orange,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isConnected ? '当前状态：已连通同步中枢' : '当前状态：本地离线模式',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: isConnected ? Colors.green.shade800 : Colors.orange.shade800,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '活跃节点: $activeNode',
                                style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '公网云端域名 / 独立服务器地址：',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: urlCtrl,
                    decoration: InputDecoration(
                      hintText: '例：https://crm-sync.onrender.com',
                      hintStyle: const TextStyle(fontSize: 12, color: Colors.grey),
                      isDense: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      prefixIcon: const Icon(Icons.link, size: 18),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '💡 说明：支持绑定免费 Render / Zeabur / 腾讯云公网域名。绑定后电脑关机也能实现异地全员实时同步。',
                    style: TextStyle(fontSize: 11, color: Colors.grey, height: 1.4),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('关闭'),
              ),
              TextButton.icon(
                icon: const Icon(Icons.sync, size: 16),
                label: const Text('全量对齐'),
                onPressed: () async {
                  final ok = await provider.forceSyncAll();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(ok ? '✅ 已将手机本地与云端所有线索完全对齐同步！' : '⚠️ 对齐已执行完毕'),
                        backgroundColor: ok ? Colors.green : Colors.blue,
                      ),
                    );
                  }
                },
              ),
              ElevatedButton(
                onPressed: isTesting
                    ? null
                    : () async {
                        setDialogState(() => isTesting = true);
                        final success = await syncService.setCustomCloudUrl(urlCtrl.text.trim());
                        if (success) {
                          await provider.refreshClues();
                        }
                        setDialogState(() => isTesting = false);

                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(success
                                  ? '🎉 恭喜！已成功连通云端中枢，数据已实时同步！'
                                  : '⚠️ 无法连接该地址，请检查域名是否拼写正确且服务已启动'),
                              backgroundColor: success ? Colors.green : Colors.orange,
                            ),
                          );
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1976D2),
                  foregroundColor: Colors.white,
                ),
                child: isTesting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('测试并连接'),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// 顶部个人卡片与数据统计
class _ProfileHeaderCard extends StatelessWidget {
  final AppProvider provider;
  const _ProfileHeaderCard({required this.provider});

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final user = provider.currentUserObj;
    final userName = user?.name.isNotEmpty == true
        ? user!.name
        : (provider.currentUser.isNotEmpty ? provider.currentUser : '顾问');
    final initialLetter =
        userName.isNotEmpty ? userName[0].toUpperCase() : 'C';

    final roleLabel = user != null
        ? '${user.role.icon} ${user.role.label}'
        : '💼 招生顾问';
    final usernameText = user != null ? '@${user.username}' : '';

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFF1976D2),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          SizedBox(height: topPadding + 16),
          // 头像 & 姓名
          CircleAvatar(
            radius: 36,
            backgroundColor: Colors.white.withValues(alpha: 0.25),
            child: Text(
              initialLetter,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            userName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  roleLabel,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (usernameText.isNotEmpty) ...[
                const SizedBox(width: 8),
                Text(
                  usernameText,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 20),

          // 个人业绩数据概况
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                _StatCell(label: '总线索', value: '${provider.totalClues}'),
                _StatDivider(),
                _StatCell(
                  label: '逾期',
                  value: '${provider.overdueCount}',
                  valueColor: provider.overdueCount > 0 ? Colors.red : null,
                ),
                _StatDivider(),
                _StatCell(
                  label: '已试听',
                  value: '${provider.attendedCount}',
                  valueColor: Colors.deepOrange,
                ),
                _StatDivider(),
                _StatCell(
                  label: '已报名',
                  value: '${provider.enrolledCount}',
                  valueColor: const Color(0xFF2E7D32),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _StatCell({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: valueColor ?? const Color(0xFF1976D2),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class _StatDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 24,
      color: Colors.grey.withValues(alpha: 0.3),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 6),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final Color? titleColor;
  final Color? iconColor;
  final String? trailingBadge;
  final Color? badgeColor;

  const _MenuItem({
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.titleColor,
    this.iconColor,
    this.trailingBadge,
    this.badgeColor,
  });

  @override
  Widget build(BuildContext context) {
    final iColor = iconColor ?? titleColor ?? const Color(0xFF555555);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: iColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iColor, size: 20),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: titleColor ?? const Color(0xFF333333),
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle!,
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              )
            : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (trailingBadge != null) ...[
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: (badgeColor ?? const Color(0xFF1976D2))
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  trailingBadge!,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: badgeColor ?? const Color(0xFF1976D2),
                  ),
                ),
              ),
              const SizedBox(width: 4),
            ],
            const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}

