import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

/// 远程版本信息模型
class AppVersionInfo {
  final int versionCode;
  final String versionName;
  final String title;
  final String changelog;
  final String downloadUrl;
  final bool forceUpdate;
  final String publishTime;

  AppVersionInfo({
    required this.versionCode,
    required this.versionName,
    required this.title,
    required this.changelog,
    required this.downloadUrl,
    this.forceUpdate = false,
    this.publishTime = '',
  });

  factory AppVersionInfo.fromJson(Map<String, dynamic> json) {
    return AppVersionInfo(
      versionCode: json['versionCode'] is num ? (json['versionCode'] as num).toInt() : 1,
      versionName: json['versionName']?.toString() ?? '1.0.0',
      title: json['title']?.toString() ?? '发现新版本',
      changelog: json['changelog']?.toString() ?? '',
      downloadUrl: json['downloadUrl']?.toString() ?? '',
      forceUpdate: json['forceUpdate'] == true,
      publishTime: json['publishTime']?.toString() ?? '',
    );
  }
}

/// Android / 多端应用内版本检测与热升级服务
class AppUpgradeService {
  AppUpgradeService._();
  static final AppUpgradeService instance = AppUpgradeService._();

  /// 当前安装包内置版本号（与 pubspec.yaml 保持严格同步）
  static const int currentVersionCode = 6;
  static const String currentVersionName = '1.0.5';

  /// 云端版本配置文件直链（托管于 GitHub Pages）
  static const String defaultVersionCheckUrl =
      'https://milics.github.io/crm-app/app_version.json';

  /// 备用云端版本检查直链（托管于 GitHub Raw，直连无 Pages 构建延迟）
  static const String fallbackVersionCheckUrl =
      'https://raw.githubusercontent.com/Milics/crm-app/gh-pages/app_version.json';

  /// 默认 APK 下载落地直达页（集成多线路国内高速镜像，防运营商拦截）
  static const String defaultApkDownloadUrl =
      'https://milics.github.io/crm-app/download.html';

  /// 避免单次冷启动内静默弹窗频繁打扰
  bool _hasPromptedThisSession = false;

  /// 用于单元测试或自定义注入
  String versionCheckUrl = defaultVersionCheckUrl;

  /// 重置单次会话检查标记（主要用于测试）
  void resetSession() {
    _hasPromptedThisSession = false;
  }

  /// 获取云端最新版本信息（支持自定义 http.Client 便于自动化测试）
  Future<AppVersionInfo?> fetchLatestVersion({http.Client? client}) async {
    final httpClient = client ?? http.Client();
    try {
      // 🛡️ 防 CDN/浏览器强缓存：追加毫秒时间戳参数
      final uri = Uri.parse('$versionCheckUrl?t=${DateTime.now().millisecondsSinceEpoch}');
      final response = await httpClient.get(uri).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        return AppVersionInfo.fromJson(decoded);
      } else {
        debugPrint('⚠️ [AppUpgrade] 主通道获取版本信息失败，HTTP状态码: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('⚠️ [AppUpgrade] 主通道检查版本异常: $e');
    }

    // 备用通道检测（若当前使用的是默认主地址，且主通道未成功）
    if (versionCheckUrl == defaultVersionCheckUrl) {
      try {
        final fallbackUri = Uri.parse('$fallbackVersionCheckUrl?t=${DateTime.now().millisecondsSinceEpoch}');
        final fbResponse = await httpClient.get(fallbackUri).timeout(const Duration(seconds: 8));
        if (fbResponse.statusCode == 200) {
          final decoded = jsonDecode(utf8.decode(fbResponse.bodyBytes)) as Map<String, dynamic>;
          return AppVersionInfo.fromJson(decoded);
        }
      } catch (e) {
        debugPrint('⚠️ [AppUpgrade] 备用通道检查版本异常: $e');
      } finally {
        if (client == null) {
          httpClient.close();
        }
      }
    } else {
      if (client == null) {
        httpClient.close();
      }
    }
    return null;
  }

  /// 检查更新并按需弹出升级对话框
  /// - [manual] : 是否为用户在“我的”页面主动点击触发
  Future<void> checkAndPromptUpdate(
    BuildContext context, {
    bool manual = false,
    http.Client? client,
  }) async {
    // 🌐 Web 端提示适配
    if (kIsWeb) {
      if (manual && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🌐 当前为 Web 云端版本，刷新浏览器页面即可自动加载最新功能！'),
            backgroundColor: Color(0xFF1976D2),
            duration: Duration(seconds: 3),
          ),
        );
      }
      return;
    }

    if (!manual && _hasPromptedThisSession) {
      return;
    }

    // 手动检查时弹出轻量 Loading 交互
    BuildContext? loadingCtx;
    if (manual && context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) {
          loadingCtx = ctx;
          return const Center(
            child: Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12))),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    ),
                    SizedBox(width: 16),
                    Text('正在检查新版本...', style: TextStyle(fontSize: 14)),
                  ],
                ),
              ),
            ),
          );
        },
      );
    }

    final latest = await fetchLatestVersion(client: client);

    // 关闭 Loading 弹窗
    if (loadingCtx != null && loadingCtx!.mounted) {
      Navigator.of(loadingCtx!).pop();
    }

    if (!context.mounted) return;

    if (latest == null) {
      if (manual) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⚠️ 检查更新失败，请检查网络连接后重试'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
      return;
    }

    // 判断是否有更高版本
    if (latest.versionCode > currentVersionCode) {
      _hasPromptedThisSession = true;
      if (context.mounted) {
        showUpgradeDialog(context, latest);
      }
    } else {
      if (manual && context.mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: Color(0xFF2E7D32), size: 22),
                SizedBox(width: 8),
                Text('已是最新版本', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            content: Text(
              '当前安装版本为 V$currentVersionName (构建号 $currentVersionCode)，暂无可用更新。',
              style: const TextStyle(fontSize: 13.5, color: Colors.black87, height: 1.5),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('好的'),
              ),
            ],
          ),
        );
      }
    }
  }

  /// 弹出设计精致的版本升级对话框
  void showUpgradeDialog(BuildContext context, AppVersionInfo info) {
    showDialog(
      context: context,
      barrierDismissible: !info.forceUpdate,
      builder: (ctx) => PopScope(
        canPop: !info.forceUpdate,
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 28),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 顶部活力渐变头图
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF1976D2), Color(0xFF42A5F5)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.rocket_launch_rounded,
                            size: 36, color: Colors.white),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        info.title.isNotEmpty ? info.title : '发现新版本 V${info.versionName}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (info.publishTime.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          '发布时间：${info.publishTime}',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.85),
                            fontSize: 11.5,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // 更新日志内容区
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.new_releases_outlined,
                              size: 16, color: Color(0xFF1976D2)),
                          SizedBox(width: 6),
                          Text('本次更新内容：',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              )),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        constraints: const BoxConstraints(maxHeight: 180),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F9FF),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFD6E4FF)),
                        ),
                        child: SingleChildScrollView(
                          child: Text(
                            info.changelog.isNotEmpty
                                ? info.changelog
                                : '优化多项功能体验与系统稳定性。',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF333333),
                              height: 1.6,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // 操作按钮区
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 6, 20, 20),
                  child: Row(
                    children: [
                      if (!info.forceUpdate) ...[
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(ctx),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              side: BorderSide(color: Colors.grey.shade300),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                            child: const Text('稍后提醒',
                                style: TextStyle(color: Colors.grey, fontSize: 14)),
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            final targetUrl = info.downloadUrl.isNotEmpty
                                ? info.downloadUrl
                                : defaultApkDownloadUrl;
                            final uri = Uri.parse(targetUrl);
                            try {
                              if (await canLaunchUrl(uri)) {
                                await launchUrl(uri,
                                    mode: LaunchMode.externalApplication);
                              }
                            } catch (e) {
                              debugPrint('⚠️ [AppUpgrade] 打开下载链接异常: $e');
                            }
                            if (!info.forceUpdate && ctx.mounted) {
                              Navigator.pop(ctx);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1976D2),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                            elevation: 2,
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.download_rounded, size: 18),
                              SizedBox(width: 4),
                              Text('立即更新',
                                  style: TextStyle(
                                      fontSize: 14, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
