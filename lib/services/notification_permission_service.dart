import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

import 'package:permission_handler/permission_handler.dart';

class NotificationPermissionService {
  static Future<bool> ensureNotificationPermission(BuildContext context) async {
    // Android 13+/iOS 允许检查；其它平台直接返回 true
    final status = await Permission.notification.status;
    if (status.isGranted) return true;
    if (status.isPermanentlyDenied) {
      if (!context.mounted) return false;
      final go = await _showOpenSettingsDialog(context);
      if (go == true) {
        await openAppSettings();
      }
      return false;
    }
    final req = await Permission.notification.request();
    if (req.isGranted) return true;
    if (req.isPermanentlyDenied) {
      if (!context.mounted) return false;
      final go = await _showOpenSettingsDialog(context);
      if (go == true) {
        await openAppSettings();
      }
    }
    return false;
  }

  static Future<bool?> _showOpenSettingsDialog(BuildContext context) async {
    if (!context.mounted) return false;
    return showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'dialog',
      transitionDuration: AppTheme.motionMedium,
      pageBuilder: (ctx, _, __) => const SizedBox.shrink(),
      transitionBuilder: (ctx, anim, sec, child) {
        final curved = CurvedAnimation(parent: anim, curve: AppTheme.easeStandard);
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.98, end: 1.0).animate(curved),
            child: AlertDialog(
              title: const Text('需要通知权限'),
              content: const Text('为了按时提醒你的小目标，请在系统设置中开启通知权限。'),
              actions: [
                TextButton(onPressed: ()=> Navigator.of(ctx).pop(false), child: const Text('稍后')),
                FilledButton(onPressed: ()=> Navigator.of(ctx).pop(true), child: const Text('前往设置')),
              ],
            ),
          ),
        );
      },
    );
  }
}

