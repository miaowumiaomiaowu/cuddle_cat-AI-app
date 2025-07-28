import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// 错误状态组件
class ErrorStateWidget extends StatelessWidget {
  final String? title;
  final String message;
  final IconData? icon;
  final String? actionText;
  final VoidCallback? onAction;
  final bool showRetry;

  const ErrorStateWidget({
    super.key,
    this.title,
    required this.message,
    this.icon,
    this.actionText,
    this.onAction,
    this.showRetry = true,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spacingLarge),
        margin: const EdgeInsets.all(AppTheme.spacingMedium),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 错误图标
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.errorColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon ?? Icons.error_outline,
                size: 40,
                color: AppTheme.errorColor,
              ),
            ),

            const SizedBox(height: AppTheme.spacingLarge),

            // 标题
            if (title != null) ...[
              Text(
                title!,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTheme.spacingSmall),
            ],

            // 错误消息
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: AppTheme.spacingLarge),

            // 操作按钮
            if (showRetry || onAction != null)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (showRetry)
                    ElevatedButton.icon(
                      onPressed: onAction,
                      icon: const Icon(Icons.refresh, size: 18),
                      label: Text(actionText ?? '重试'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  if (!showRetry && onAction != null)
                    ElevatedButton(
                      onPressed: onAction,
                      child: Text(actionText ?? '确定'),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

/// 网络错误组件
class NetworkErrorWidget extends StatelessWidget {
  final VoidCallback? onRetry;

  const NetworkErrorWidget({
    super.key,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return ErrorStateWidget(
      title: '网络连接失败',
      message: '请检查您的网络连接，然后重试',
      icon: Icons.wifi_off,
      actionText: '重新连接',
      onAction: onRetry,
    );
  }
}

/// 空状态组件
class EmptyStateWidget extends StatelessWidget {
  final String title;
  final String message;
  final IconData? icon;
  final String? actionText;
  final VoidCallback? onAction;

  const EmptyStateWidget({
    super.key,
    required this.title,
    required this.message,
    this.icon,
    this.actionText,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spacingLarge),
        margin: const EdgeInsets.all(AppTheme.spacingMedium),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 空状态图标
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon ?? Icons.inbox_outlined,
                size: 50,
                color: AppTheme.primaryColor.withOpacity(0.7),
              ),
            ),

            const SizedBox(height: AppTheme.spacingLarge),

            // 标题
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: AppTheme.spacingSmall),

            // 描述
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),

            // 操作按钮
            if (onAction != null) ...[
              const SizedBox(height: AppTheme.spacingLarge),
              ElevatedButton(
                onPressed: onAction,
                child: Text(actionText ?? '开始'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// 内联错误提示组件
class InlineErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback? onDismiss;
  final bool showIcon;

  const InlineErrorWidget({
    super.key,
    required this.message,
    this.onDismiss,
    this.showIcon = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingMedium,
        vertical: AppTheme.spacingSmall,
      ),
      padding: const EdgeInsets.all(AppTheme.spacingMedium),
      decoration: BoxDecoration(
        color: AppTheme.errorColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        border: Border.all(
          color: AppTheme.errorColor.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          if (showIcon) ...[
            Icon(
              Icons.error_outline,
              color: AppTheme.errorColor,
              size: 20,
            ),
            const SizedBox(width: AppTheme.spacingSmall),
          ],
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.errorColor,
                  ),
            ),
          ),
          if (onDismiss != null) ...[
            const SizedBox(width: AppTheme.spacingSmall),
            GestureDetector(
              onTap: onDismiss,
              child: Icon(
                Icons.close,
                color: AppTheme.errorColor,
                size: 18,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// 成功提示组件
class SuccessWidget extends StatelessWidget {
  final String message;
  final VoidCallback? onDismiss;
  final bool showIcon;

  const SuccessWidget({
    super.key,
    required this.message,
    this.onDismiss,
    this.showIcon = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingMedium,
        vertical: AppTheme.spacingSmall,
      ),
      padding: const EdgeInsets.all(AppTheme.spacingMedium),
      decoration: BoxDecoration(
        color: AppTheme.successColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        border: Border.all(
          color: AppTheme.successColor.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          if (showIcon) ...[
            Icon(
              Icons.check_circle_outline,
              color: AppTheme.successColor,
              size: 20,
            ),
            const SizedBox(width: AppTheme.spacingSmall),
          ],
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.successColor,
                  ),
            ),
          ),
          if (onDismiss != null) ...[
            const SizedBox(width: AppTheme.spacingSmall),
            GestureDetector(
              onTap: onDismiss,
              child: Icon(
                Icons.close,
                color: AppTheme.successColor,
                size: 18,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// 警告提示组件
class WarningWidget extends StatelessWidget {
  final String message;
  final VoidCallback? onDismiss;
  final bool showIcon;

  const WarningWidget({
    super.key,
    required this.message,
    this.onDismiss,
    this.showIcon = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingMedium,
        vertical: AppTheme.spacingSmall,
      ),
      padding: const EdgeInsets.all(AppTheme.spacingMedium),
      decoration: BoxDecoration(
        color: AppTheme.warningColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        border: Border.all(
          color: AppTheme.warningColor.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          if (showIcon) ...[
            Icon(
              Icons.warning_outlined,
              color: AppTheme.warningColor,
              size: 20,
            ),
            const SizedBox(width: AppTheme.spacingSmall),
          ],
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.warningColor,
                  ),
            ),
          ),
          if (onDismiss != null) ...[
            const SizedBox(width: AppTheme.spacingSmall),
            GestureDetector(
              onTap: onDismiss,
              child: Icon(
                Icons.close,
                color: AppTheme.warningColor,
                size: 18,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
