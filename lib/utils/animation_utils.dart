import 'package:flutter/material.dart';

class AnimationUtils {
  // 手绘风格的弹跳动画
  static AnimationController createBounceController(TickerProvider vsync) {
    return AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: vsync,
    );
  }

  // 手绘风格的摇摆动画
  static AnimationController createWiggleController(TickerProvider vsync) {
    return AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: vsync,
    );
  }

  // 手绘风格的脉冲动画
  static AnimationController createPulseController(TickerProvider vsync) {
    return AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: vsync,
    );
  }

  // 手绘风格的浮动动画
  static AnimationController createFloatController(TickerProvider vsync) {
    return AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: vsync,
    );
  }

  // 弹跳动画曲线
  static Animation<double> createBounceAnimation(AnimationController controller) {
    return Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: Curves.elasticOut,
    ));
  }

  // 摇摆动画曲线
  static Animation<double> createWiggleAnimation(AnimationController controller) {
    return Tween<double>(
      begin: -0.05,
      end: 0.05,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: Curves.easeInOut,
    ));
  }

  // 脉冲动画曲线
  static Animation<double> createPulseAnimation(AnimationController controller) {
    return Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: Curves.easeInOut,
    ));
  }

  // 浮动动画曲线
  static Animation<double> createFloatAnimation(AnimationController controller) {
    return Tween<double>(
      begin: 0.0,
      end: 10.0,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: Curves.easeInOut,
    ));
  }

  // 渐入动画
  static Animation<double> createFadeInAnimation(AnimationController controller) {
    return Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: Curves.easeIn,
    ));
  }

  // 滑入动画
  static Animation<Offset> createSlideInAnimation(AnimationController controller) {
    return Tween<Offset>(
      begin: const Offset(0.0, 1.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: Curves.easeOutCubic,
    ));
  }

  // 旋转动画
  static Animation<double> createRotationAnimation(AnimationController controller) {
    return Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: Curves.linear,
    ));
  }

  // 缩放动画
  static Animation<double> createScaleAnimation(AnimationController controller) {
    return Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: Curves.elasticOut,
    ));
  }
}

// 手绘风格动画组件
class HandDrawnAnimatedWidget extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final AnimationType animationType;

  const HandDrawnAnimatedWidget({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.animationType = AnimationType.fadeIn,
  });

  @override
  State<HandDrawnAnimatedWidget> createState() => _HandDrawnAnimatedWidgetState();
}

class _HandDrawnAnimatedWidgetState extends State<HandDrawnAnimatedWidget>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    switch (widget.animationType) {
      case AnimationType.fadeIn:
        _animation = AnimationUtils.createFadeInAnimation(_controller);
        break;
      case AnimationType.bounce:
        _animation = AnimationUtils.createBounceAnimation(_controller);
        break;
      case AnimationType.scale:
        _animation = AnimationUtils.createScaleAnimation(_controller);
        break;
      case AnimationType.slideIn:
        _slideAnimation = AnimationUtils.createSlideInAnimation(_controller);
        break;
    }

    // 延迟启动动画
    Future.delayed(widget.delay, () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    switch (widget.animationType) {
      case AnimationType.fadeIn:
        return FadeTransition(
          opacity: _animation,
          child: widget.child,
        );
      case AnimationType.bounce:
      case AnimationType.scale:
        return ScaleTransition(
          scale: _animation,
          child: widget.child,
        );
      case AnimationType.slideIn:
        return SlideTransition(
          position: _slideAnimation,
          child: widget.child,
        );
    }
  }
}

// 动画类型枚举
enum AnimationType {
  fadeIn,
  bounce,
  scale,
  slideIn,
}

// 手绘风格悬浮动画组件
class HandDrawnFloatingWidget extends StatefulWidget {
  final Widget child;
  final double amplitude;
  final Duration duration;

  const HandDrawnFloatingWidget({
    super.key,
    required this.child,
    this.amplitude = 5.0,
    this.duration = const Duration(seconds: 3),
  });

  @override
  State<HandDrawnFloatingWidget> createState() => _HandDrawnFloatingWidgetState();
}

class _HandDrawnFloatingWidgetState extends State<HandDrawnFloatingWidget>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _animation = Tween<double>(
      begin: -widget.amplitude,
      end: widget.amplitude,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _animation.value),
          child: widget.child,
        );
      },
    );
  }
}

// 手绘风格脉冲动画组件
class HandDrawnPulseWidget extends StatefulWidget {
  final Widget child;
  final double minScale;
  final double maxScale;
  final Duration duration;

  const HandDrawnPulseWidget({
    super.key,
    required this.child,
    this.minScale = 0.95,
    this.maxScale = 1.05,
    this.duration = const Duration(milliseconds: 1500),
  });

  @override
  State<HandDrawnPulseWidget> createState() => _HandDrawnPulseWidgetState();
}

class _HandDrawnPulseWidgetState extends State<HandDrawnPulseWidget>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _animation = Tween<double>(
      begin: widget.minScale,
      end: widget.maxScale,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.scale(
          scale: _animation.value,
          child: widget.child,
        );
      },
    );
  }
}
