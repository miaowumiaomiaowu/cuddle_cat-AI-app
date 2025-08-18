import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class NotificationPermissionService {
  static Future<bool> ensureNotificationPermission(BuildContext context) async {
    // Android 13+/iOS 允许检查；其它平台直接返回 true
    final status = await Permission.notification.status;
    if (status.isGranted) return true;
    if (status.isPermanentlyDenied) {
      final go = await _showOpenSettingsDialog(context);
      if (go == true) {
        await openAppSettings();
      }
      return false;
    }
    final req = await Permission.notification.request();
    if (req.isGranted) return true;
    if (req.isPermanentlyDenied) {
      final go = await _showOpenSettingsDialog(context);
      if (go == true) {
        await openAppSettings();
      }
    }
    return false;
  }

  static Future<bool?> _showOpenSettingsDialog(BuildContext context) async {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('需要通知权限'),
        content: const Text('为了按时提醒你的小目标，请在系统设置中开启通知权限。'),
        actions: [
          TextButton(onPressed: ()=> Navigator.of(ctx).pop(false), child: const Text('稍后')),
          FilledButton(onPressed: ()=> Navigator.of(ctx).pop(true), child: const Text('前往设置')),
        ],
      ),
    );
  }
}

