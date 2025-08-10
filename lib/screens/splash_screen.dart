import 'package:flutter/material.dart';

import '../theme/artistic_theme.dart';
// import '../services/performance_service.dart'; // 已删除
// import '../services/health_check_service.dart'; // 已删除

/// 启动画面 - 温暖治愈的欢迎界面
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _textController;
  late AnimationController _progressController;
  
  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _textOpacity;
  late Animation<Offset> _textSlide;
  late Animation<double> _progressValue;

  String _loadingText = '正在准备温暖的治愈空间...';
  final List<String> _loadingMessages = [
    '正在准备温暖的治愈空间...',
    '正在唤醒AI小暖...',
    '正在整理心情地图...',
    '正在检查应用健康状态...',
    '一切准备就绪！',
  ];
  int _messageIndex = 0;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startLoadingSequence();
  }

  void _initializeAnimations() {
    // Logo动画
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _logoScale = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: Curves.elasticOut,
    ));
    
    _logoOpacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
    ));

    // 文字动画
    _textController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _textOpacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _textController,
      curve: Curves.easeIn,
    ));
    
    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _textController,
      curve: Curves.easeOutCubic,
    ));

    // 进度动画
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );
    
    _progressValue = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeInOut,
    ));
  }

  Future<void> _startLoadingSequence() async {
    // 启动Logo动画
    _logoController.forward();
    
    // 延迟启动文字动画
    await Future.delayed(const Duration(milliseconds: 500));
    _textController.forward();
    
    // 延迟启动进度动画
    await Future.delayed(const Duration(milliseconds: 800));
    _progressController.forward();
    
    // 开始加载过程
    await _performInitialization();
  }

  Future<void> _performInitialization() async {
    // 健康检查和性能服务已删除
    // 健康检查和性能服务已删除

    try {
      // 性能监控已删除
      _updateLoadingMessage(0);
      await Future.delayed(const Duration(milliseconds: 600));
      
      // 启动健康监控 (已禁用)
      // healthCheckService.startHealthMonitoring();
      _updateLoadingMessage(1);
      await Future.delayed(const Duration(milliseconds: 600));
      
      // 预加载关键资源
      _updateLoadingMessage(2);
      await Future.delayed(const Duration(milliseconds: 600));
      
      // 执行快速健康检查
      _updateLoadingMessage(3);
      await Future.delayed(const Duration(milliseconds: 600));
      
      // 完成
      _updateLoadingMessage(4);
      await Future.delayed(const Duration(milliseconds: 800));
      
      // 导航到主界面
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/main');
      }
    } catch (e) {
      debugPrint('初始化失败: $e');
      // 即使初始化失败也要继续
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/main');
      }
    }
  }

  void _updateLoadingMessage(int index) {
    if (index < _loadingMessages.length && mounted) {
      setState(() {
        _messageIndex = index;
        _loadingText = _loadingMessages[index];
      });
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ArtisticTheme.backgroundColor,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              ArtisticTheme.backgroundColor,
              ArtisticTheme.surfaceColor,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(flex: 2),
              
              // Logo区域
              AnimatedBuilder(
                animation: _logoController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _logoScale.value,
                    child: Opacity(
                      opacity: _logoOpacity.value,
                      child: _buildLogo(),
                    ),
                  );
                },
              ),
              
              const SizedBox(height: 40),
              
              // 标题文字
              AnimatedBuilder(
                animation: _textController,
                builder: (context, child) {
                  return SlideTransition(
                    position: _textSlide,
                    child: FadeTransition(
                      opacity: _textOpacity,
                      child: Column(
                        children: [
                          Text(
                            '暖猫',
                            style: ArtisticTheme.headlineLarge.copyWith(
                              fontWeight: FontWeight.w300,
                              letterSpacing: 2.0,
                              color: ArtisticTheme.primaryColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Cuddle Cat',
                            style: ArtisticTheme.titleMedium.copyWith(
                              color: ArtisticTheme.textSecondary,
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '你的AI心理治愈伙伴',
                            style: ArtisticTheme.bodyLarge.copyWith(
                              color: ArtisticTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              
              const Spacer(flex: 2),
              
              // 加载进度区域
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Column(
                  children: [
                    // 加载文字
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: Text(
                        _loadingText,
                        key: ValueKey(_messageIndex),
                        style: ArtisticTheme.bodyMedium.copyWith(
                          color: ArtisticTheme.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // 进度条
                    AnimatedBuilder(
                      animation: _progressValue,
                      builder: (context, child) {
                        return Container(
                          height: 4,
                          decoration: BoxDecoration(
                            color: ArtisticTheme.textSecondary.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: _progressValue.value,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: ArtisticTheme.primaryGradient,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              
              const Spacer(),
              
              // 底部版权信息
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Text(
                  '© 2024 暖猫团队',
                  style: ArtisticTheme.caption.copyWith(
                    color: ArtisticTheme.textSecondary.withValues(alpha: 0.6),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        gradient: ArtisticTheme.primaryGradient,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: ArtisticTheme.primaryColor.withValues(alpha: 0.3),
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: const Center(
        child: Text(
          '🐱',
          style: TextStyle(fontSize: 60),
        ),
      ),
    );
  }
}
