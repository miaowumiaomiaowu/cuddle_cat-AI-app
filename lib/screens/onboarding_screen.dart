import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/artistic_theme.dart';
import '../widgets/hand_drawn_card.dart';

/// 用户引导页面 - 首次使用时的温暖介绍
class OnboardingScreen extends StatefulWidget {
  static const String routeName = '/onboarding';

  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  int _currentPage = 0;
  final int _totalPages = 4;

  final List<OnboardingPage> _pages = [
    OnboardingPage(
      emoji: '🐱',
      title: '欢迎来到暖猫',
      subtitle: '你的AI心理治愈伙伴',
      description: '在这里，你可以记录心情、获得AI支持，让每一天都充满温暖和治愈。',
      color: ArtisticTheme.primaryColor,
    ),
    OnboardingPage(
      emoji: '💭',
      title: '记录你的心情',
      subtitle: '每一种感受都值得被记录',
      description: '通过详细的心情记录，包括强度、标签、触发事件和感恩日记，更好地了解自己。',
      color: ArtisticTheme.joyColor,
    ),
    OnboardingPage(
      emoji: '🤖',
      title: 'AI小暖陪伴你',
      subtitle: '24小时温暖支持',
      description: 'AI小暖会分析你的心情模式，提供个性化的心理支持和改善建议。',
      color: ArtisticTheme.infoColor,
    ),

  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ArtisticTheme.backgroundColor,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              _pages[_currentPage].color.withValues(alpha: 0.1),
              ArtisticTheme.backgroundColor,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // 跳过按钮
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextButton(
                    onPressed: _completeOnboarding,
                    child: Text(
                      '跳过',
                      style: ArtisticTheme.bodyMedium.copyWith(
                        color: ArtisticTheme.textSecondary,
                      ),
                    ),
                  ),
                ),
              ),
              
              // 页面内容
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                    });
                    _animationController.reset();
                    _animationController.forward();
                  },
                  itemCount: _totalPages,
                  itemBuilder: (context, index) {
                    return FadeTransition(
                      opacity: _fadeAnimation,
                      child: _buildPage(_pages[index]),
                    );
                  },
                ),
              ),
              
              // 页面指示器和导航按钮
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    // 页面指示器
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        _totalPages,
                        (index) => _buildPageIndicator(index),
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // 导航按钮
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // 上一页按钮
                        if (_currentPage > 0)
                          TextButton.icon(
                            onPressed: _previousPage,
                            icon: const Icon(Icons.arrow_back),
                            label: const Text('上一页'),
                          )
                        else
                          const SizedBox(width: 100),
                        
                        // 下一页/完成按钮
                        ElevatedButton.icon(
                          onPressed: _currentPage == _totalPages - 1
                              ? _completeOnboarding
                              : _nextPage,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _pages[_currentPage].color,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                          icon: Icon(
                            _currentPage == _totalPages - 1
                                ? Icons.check
                                : Icons.arrow_forward,
                          ),
                          label: Text(
                            _currentPage == _totalPages - 1 ? '开始使用' : '下一页',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPage(OnboardingPage page) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 表情符号
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: page.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(60),
              border: Border.all(
                color: page.color.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: Center(
              child: Text(
                page.emoji,
                style: const TextStyle(fontSize: 60),
              ),
            ),
          ),
          
          const SizedBox(height: 40),
          
          // 标题
          Text(
            page.title,
            style: ArtisticTheme.headlineMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: page.color,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 16),
          
          // 副标题
          Text(
            page.subtitle,
            style: ArtisticTheme.titleMedium.copyWith(
              color: ArtisticTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 24),
          
          // 描述
          HandDrawnCard(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                page.description,
                style: ArtisticTheme.bodyLarge.copyWith(
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageIndicator(int index) {
    final isActive = index == _currentPage;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: isActive ? 24 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: isActive 
            ? _pages[_currentPage].color 
            : ArtisticTheme.textSecondary.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _completeOnboarding() async {
    // 标记引导完成
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);
    
    // 导航到主界面
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/main');
    }
  }
}

/// 引导页面数据模型
class OnboardingPage {
  final String emoji;
  final String title;
  final String subtitle;
  final String description;
  final Color color;

  OnboardingPage({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.color,
  });
}
