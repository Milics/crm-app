import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

/// 呼叫与外部应用跳转服务（一键拨打电话、微信直达跳转）
class LauncherService {
  /// 一键呼起手机系统拨号盘
  static Future<bool> makePhoneCall(BuildContext context, String phone) async {
    final cleanPhone = phone.trim().replaceAll(RegExp(r'[^0-9+]'), '');
    if (cleanPhone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('未填写有效手机号'), backgroundColor: Colors.orange),
      );
      return false;
    }

    final uri = Uri.parse('tel:$cleanPhone');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
        return true;
      } else {
        // 降级为复制到剪贴板
        await Clipboard.setData(ClipboardData(text: cleanPhone));
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('当前设备无法呼出电话，已复制手机号: $cleanPhone'),
              backgroundColor: const Color(0xFF1976D2),
            ),
          );
        }
        return false;
      }
    } catch (e) {
      await Clipboard.setData(ClipboardData(text: cleanPhone));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('已复制手机号: $cleanPhone'),
            backgroundColor: const Color(0xFF1976D2),
          ),
        );
      }
      return false;
    }
  }

  /// 复制微信号并尝试一键打开微信 App
  static Future<void> copyAndOpenWechat(
      BuildContext context, String wxId) async {
    final cleanWx = wxId.trim();
    if (cleanWx.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('未填写微信号'), backgroundColor: Colors.orange),
      );
      return;
    }

    await Clipboard.setData(ClipboardData(text: cleanWx));

    final wechatUri = Uri.parse('weixin://');
    bool launched = false;
    try {
      if (await canLaunchUrl(wechatUri)) {
        await launchUrl(wechatUri, mode: LaunchMode.externalApplication);
        launched = true;
      }
    } catch (_) {}

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(launched
              ? '已复制微信号「$cleanWx」并已打开微信，可直接搜索添加好友！'
              : '微信号「$cleanWx」已复制到剪贴板，可前往微信粘贴搜索！'),
          backgroundColor: const Color(0xFF2E7D32),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
}
