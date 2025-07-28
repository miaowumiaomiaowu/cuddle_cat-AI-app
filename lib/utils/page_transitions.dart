import 'package:flutter/material.dart';

/// 页面过渡动画类型
enum PageTransitionType {
  fade,
  slide,
  scale,
  rotation,
  slideUp,
  slideDown,
  slideLeft,
  slideRight,
}

/// 自定义页面路由
class CustomPageRoute<T> extends PageRouteBuilder<T> {
  final Widget child;
  final PageTransitionType transitionType;
  final Duration duration;
  final Curve curve;

  CustomPageRoute({
    required this.child,
    this.transitionType = PageTransitionType.slide,
    this.duration = const Duration(milliseconds: 300),
    this.curve = Curves.easeInOut,
    RouteSettings? settings,
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => child,
          transitionDuration: duration,
          reverseTransitionDuration: duration,
          settings: settings,
        );

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curvedAnimation = CurvedAnimation(
      parent: animation,
      curve: curve,
    );

    switch (transitionType) {
      case PageTransitionType.fade:
        return FadeTransition(
          opacity: curvedAnimation,
          child: child,
        );

      case PageTransitionType.scale:
        return ScaleTransition(
          scale: curvedAnimation,
          child: child,
        );

      case PageTransitionType.rotation:
        return RotationTransition(
          turns: curvedAnimation,
          child: child,
        );

      case PageTransitionType.slideUp:
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.0, 1.0),
            end: Offset.zero,
          ).animate(curvedAnimation),
          child: child,
        );

      case PageTransitionType.slideDown:
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.0, -1.0),
            end: Offset.zero,
          ).animate(curvedAnimation),
          child: child,
        );

      case PageTransitionType.slideLeft:
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1.0, 0.0),
            end: Offset.zero,
          ).animate(curvedAnimation),
          child: child,
        );

      case PageTransitionType.slideRight:
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(-1.0, 0.0),
            end: Offset.zero,
          ).animate(curvedAnimation),
          child: child,
        );

      case PageTransitionType.slide:
      default:
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1.0, 0.0),
            end: Offset.zero,
          ).animate(curvedAnimation),
          child: child,
        );
    }
  }
}

/// 页面过渡工具类
class PageTransitions {
  /// 淡入淡出过渡
  static Route<T> fadeTransition<T>(Widget page, {RouteSettings? settings}) {
    return CustomPageRoute<T>(
      child: page,
      transitionType: PageTransitionType.fade,
      settings: settings,
    );
  }

  /// 滑动过渡
  static Route<T> slideTransition<T>(Widget page, {RouteSettings? settings}) {
    return CustomPageRoute<T>(
      child: page,
      transitionType: PageTransitionType.slide,
      settings: settings,
    );
  }

  /// 缩放过渡
  static Route<T> scaleTransition<T>(Widget page, {RouteSettings? settings}) {
    return CustomPageRoute<T>(
      child: page,
      transitionType: PageTransitionType.scale,
      curve: Curves.elasticOut,
      settings: settings,
    );
  }

  /// 向上滑动过渡
  static Route<T> slideUpTransition<T>(Widget page, {RouteSettings? settings}) {
    return CustomPageRoute<T>(
      child: page,
      transitionType: PageTransitionType.slideUp,
      settings: settings,
    );
  }

  /// 向下滑动过渡
  static Route<T> slideDownTransition<T>(Widget page,
      {RouteSettings? settings}) {
    return CustomPageRoute<T>(
      child: page,
      transitionType: PageTransitionType.slideDown,
      settings: settings,
    );
  }

  /// 从左滑入过渡
  static Route<T> slideLeftTransition<T>(Widget page,
      {RouteSettings? settings}) {
    return CustomPageRoute<T>(
      child: page,
      transitionType: PageTransitionType.slideLeft,
      settings: settings,
    );
  }

  /// 从右滑入过渡
  static Route<T> slideRightTransition<T>(Widget page,
      {RouteSettings? settings}) {
    return CustomPageRoute<T>(
      child: page,
      transitionType: PageTransitionType.slideRight,
      settings: settings,
    );
  }

  /// 旋转过渡
  static Route<T> rotationTransition<T>(Widget page,
      {RouteSettings? settings}) {
    return CustomPageRoute<T>(
      child: page,
      transitionType: PageTransitionType.rotation,
      duration: const Duration(milliseconds: 500),
      settings: settings,
    );
  }
}

/// 导航扩展
extension NavigatorExtensions on NavigatorState {
  /// 使用淡入淡出过渡推送页面
  Future<T?> pushWithFade<T extends Object?>(Widget page) {
    return push<T>(PageTransitions.fadeTransition<T>(page));
  }

  /// 使用滑动过渡推送页面
  Future<T?> pushWithSlide<T extends Object?>(Widget page) {
    return push<T>(PageTransitions.slideTransition<T>(page));
  }

  /// 使用缩放过渡推送页面
  Future<T?> pushWithScale<T extends Object?>(Widget page) {
    return push<T>(PageTransitions.scaleTransition<T>(page));
  }

  /// 使用向上滑动过渡推送页面
  Future<T?> pushWithSlideUp<T extends Object?>(Widget page) {
    return push<T>(PageTransitions.slideUpTransition<T>(page));
  }

  /// 使用向下滑动过渡推送页面
  Future<T?> pushWithSlideDown<T extends Object?>(Widget page) {
    return push<T>(PageTransitions.slideDownTransition<T>(page));
  }

  /// 使用从左滑入过渡推送页面
  Future<T?> pushWithSlideLeft<T extends Object?>(Widget page) {
    return push<T>(PageTransitions.slideLeftTransition<T>(page));
  }

  /// 使用从右滑入过渡推送页面
  Future<T?> pushWithSlideRight<T extends Object?>(Widget page) {
    return push<T>(PageTransitions.slideRightTransition<T>(page));
  }

  /// 使用旋转过渡推送页面
  Future<T?> pushWithRotation<T extends Object?>(Widget page) {
    return push<T>(PageTransitions.rotationTransition<T>(page));
  }
}

/// 页面过渡动画组件
class PageTransitionAnimation extends StatefulWidget {
  final Widget child;
  final PageTransitionType transitionType;
  final Duration duration;
  final Curve curve;
  final bool reverse;

  const PageTransitionAnimation({
    super.key,
    required this.child,
    this.transitionType = PageTransitionType.fade,
    this.duration = const Duration(milliseconds: 300),
    this.curve = Curves.easeInOut,
    this.reverse = false,
  });

  @override
  State<PageTransitionAnimation> createState() =>
      _PageTransitionAnimationState();
}

class _PageTransitionAnimationState extends State<PageTransitionAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    );

    if (!widget.reverse) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    switch (widget.transitionType) {
      case PageTransitionType.fade:
        return FadeTransition(
          opacity: _animation,
          child: widget.child,
        );

      case PageTransitionType.scale:
        return ScaleTransition(
          scale: _animation,
          child: widget.child,
        );

      case PageTransitionType.rotation:
        return RotationTransition(
          turns: _animation,
          child: widget.child,
        );

      case PageTransitionType.slideUp:
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.0, 1.0),
            end: Offset.zero,
          ).animate(_animation),
          child: widget.child,
        );

      case PageTransitionType.slideDown:
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.0, -1.0),
            end: Offset.zero,
          ).animate(_animation),
          child: widget.child,
        );

      case PageTransitionType.slideLeft:
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1.0, 0.0),
            end: Offset.zero,
          ).animate(_animation),
          child: widget.child,
        );

      case PageTransitionType.slideRight:
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(-1.0, 0.0),
            end: Offset.zero,
          ).animate(_animation),
          child: widget.child,
        );

      case PageTransitionType.slide:
      default:
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1.0, 0.0),
            end: Offset.zero,
          ).animate(_animation),
          child: widget.child,
        );
    }
  }
}
