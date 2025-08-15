import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/artistic_theme.dart';

/// 功能气泡菜单组件
class FunctionBubbleMenu extends StatefulWidget {
  final VoidCallback onMoodRecord;
  final VoidCallback onSettings;
  final VoidCallback onClose;

  const FunctionBubbleMenu({
    super.key,
    required this.onMoodRecord,
    required this.onSettings,
    required this.onClose,
  });

  @override
  State<FunctionBubbleMenu> createState() => _FunctionBubbleMenuState();
}

class _FunctionBubbleMenuState extends State<FunctionBubbleMenu>
    with TickerProviderStateMixin {
  
  late AnimationController _staggerController;
  late List<Animation<double>> _itemAnimations;
  late List<Animation<Offset>> _slideAnimations;

  final List<FunctionItem> _functions = [
    FunctionItem(
      icon: Icons.mood,
      label: '心情记录',
      color: Colors.pink,
      emoji: '💭',
    ),
    FunctionItem(
      icon: Icons.settings,
      label: '设置',
      color: Colors.grey,
      emoji: '⚙️',
    ),
  ];

  @override
  void initState() {
    super.initState();
    
    _staggerController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    // 创建交错动画
    _itemAnimations = List.generate(_functions.length, (index) {
      final start = index * 0.1;
      final end = start + 0.6;
      
      return Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: _staggerController,
        curve: Interval(start, end, curve: Curves.elasticOut),
      ));
    });

    // 创建滑动动画
    _slideAnimations = List.generate(_functions.length, (index) {
      final start = index * 0.1;
      final end = start + 0.6;
      
      return Tween<Offset>(
        begin: const Offset(1.0, 0.0),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _staggerController,
        curve: Interval(start, end, curve: Curves.easeOut),
      ));
    });

    // 启动动画
    _staggerController.forward();
  }

  @override
  void dispose() {
    _staggerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onClose,
      child: Container(
        width: 200,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // 功能按钮列表
            ...List.generate(_functions.length, (index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: SlideTransition(
                  position: _slideAnimations[index],
                  child: ScaleTransition(
                    scale: _itemAnimations[index],
                    child: _buildFunctionButton(
                      _functions[index],
                      index,
                    ),
                  ),
                ),
              );
            }),
            
            // 关闭提示
            const SizedBox(height: 8),
            ScaleTransition(
              scale: _itemAnimations.last,
              child: _buildCloseHint(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFunctionButton(FunctionItem item, int index) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        _handleFunctionTap(index);
      },
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: item.color.withValues(alpha: 0.2),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 图标容器
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: item.color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    item.icon,
                    color: item.color,
                    size: 24,
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Text(
                      item.emoji,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),
            
            // 标签
            Padding(
              padding: const EdgeInsets.only(left: 12, right: 16),
              child: Text(
                item.label,
                style: ArtisticTheme.bodyStyle.copyWith(
                  fontWeight: FontWeight.w600,
                  color: ArtisticTheme.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCloseHint() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Text(
        '点击空白处关闭',
        style: ArtisticTheme.bodyStyle.copyWith(
          color: Colors.white,
          fontSize: 10,
        ),
      ),
    );
  }

  void _handleFunctionTap(int index) {
    switch (index) {
      case 0:
        widget.onMoodRecord();
        break;
      case 1:
        widget.onSettings();
        break;
    }
  }
}

/// 功能项模型
class FunctionItem {
  final IconData icon;
  final String label;
  final Color color;
  final String emoji;

  FunctionItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.emoji,
  });
}

/// 快速功能按钮组件
class QuickFunctionButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool isActive;

  const QuickFunctionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.isActive = false,
  });

  @override
  State<QuickFunctionButton> createState() => _QuickFunctionButtonState();
}

class _QuickFunctionButtonState extends State<QuickFunctionButton>
    with SingleTickerProviderStateMixin {
  
  late AnimationController _pressController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    _pressController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _pressController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _pressController.forward(),
      onTapUp: (_) => _pressController.reverse(),
      onTapCancel: () => _pressController.reverse(),
      onTap: () {
        HapticFeedback.lightImpact();
        widget.onTap();
      },
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: widget.isActive 
                ? widget.color 
                : widget.color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
            boxShadow: widget.isActive 
                ? [
                    BoxShadow(
                      color: widget.color.withValues(alpha: 0.3),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ]
                : null,
          ),
          child: Icon(
            widget.icon,
            color: widget.isActive 
                ? Colors.white 
                : widget.color,
            size: 28,
          ),
        ),
      ),
    );
  }
}
