import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/artistic_theme.dart';
import '../../providers/user_provider.dart';
import '../../ui/app_card.dart';
import 'register_screen.dart';

import '../../ui/app_button.dart';
import '../../ui/app_input.dart';


import 'package:animations/animations.dart';
import '../../theme/app_theme.dart';

/// 登录页面
class LoginScreen extends StatefulWidget {
  static const String routeName = '/login';

  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  bool _obscurePassword = true;
  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: ArtisticTheme.backgroundGradient,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(ArtisticTheme.spacingLarge),
            child: Column(
              children: [
                const SizedBox(height: 60),
                _buildHeader(),
                const SizedBox(height: 40),
                _buildLoginForm(),
                const SizedBox(height: 30),
                _buildLoginOptions(),
                const SizedBox(height: 40),
                _buildFooter(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Column(
          children: [
            // 应用图标
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: ArtisticTheme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: ArtisticTheme.primaryColor.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.pets,
                size: 50,
                color: ArtisticTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              '暖猫',
              style: ArtisticTheme.headlineLarge.copyWith(
                fontWeight: FontWeight.w300,
                letterSpacing: 2.0,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '记录心情，治愈心灵',
              style: ArtisticTheme.bodyLarge.copyWith(
                color: ArtisticTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginForm() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: AppCard(
        child: Padding(
          padding: const EdgeInsets.all(ArtisticTheme.spacingLarge),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '欢迎回来',
                  style: ArtisticTheme.headlineSmall.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),

                // 邮箱输入框
                AppInput(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  label: '邮箱',
                  hint: '请输入邮箱地址',
                  prefixIcon: const Icon(Icons.email_outlined),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '请输入邮箱地址';
                    }
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                      return '邮箱格式不正确';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // 密码输入框
                AppInput(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  label: '密码',
                  hint: '请输入密码',
                  prefixIcon: const Icon(Icons.lock_outlined),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '请输入密码';
                    }
                    if (value.length < 6) {
                      return '密码长度不能少于6位';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // 记住我和忘记密码
                Row(
                  children: [
                    Checkbox(
                      value: _rememberMe,
                      onChanged: (value) {
                        setState(() {
                          _rememberMe = value ?? false;
                        });
                      },
                    ),
                    const Text('记住我'),
                    const Spacer(),
                    TextButton(
                      onPressed: _showForgotPasswordDialog,
                      child: const Text('忘记密码？'),
                    ),
                  ],
                ),
                const SizedBox(height: 30),

                // 登录按钮
                Consumer<UserProvider>(
                  builder: (context, userProvider, child) {
                    return AppButton.primary(
                      '登录',
                      onPressed: userProvider.isLoading ? null : _handleLogin,
                      loading: userProvider.isLoading,
                      useGradient: false,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    );
                  },
                ),
                const SizedBox(height: 16),

                // 快速游客模式按钮
                Consumer<UserProvider>(
                  builder: (context, userProvider, child) {
                    return TextButton(
                      onPressed: userProvider.isLoading ? null : _handleGuestLogin,
                      child: Text(
                        '跳过登录，直接体验',
                        style: ArtisticTheme.bodyMedium.copyWith(
                          color: ArtisticTheme.primaryColor,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginOptions() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        children: [
          // 分割线
          Row(
            children: [
              const Expanded(child: Divider()),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  '或者',
                  style: ArtisticTheme.bodySmall.copyWith(
                    color: ArtisticTheme.textSecondary,
                  ),
                ),
              ),
              const Expanded(child: Divider()),
            ],
          ),
          const SizedBox(height: 20),

          // 游客模式按钮
          Consumer<UserProvider>(
            builder: (context, userProvider, child) {
              return SizedBox(
                width: double.infinity,
                child: AppButton.outlined(
                  '游客模式体验',
                  onPressed: userProvider.isLoading ? null : _handleGuestLogin,
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '还没有账号？',
            style: ArtisticTheme.bodyMedium.copyWith(
              color: ArtisticTheme.textSecondary,
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).push(
                PageRouteBuilder(
                  transitionDuration: AppTheme.motionMedium,
                  reverseTransitionDuration: AppTheme.motionMedium,
                  pageBuilder: (context, animation, secondaryAnimation) => const RegisterScreen(),
                  transitionsBuilder: (context, animation, secondaryAnimation, child) {
                    final curve = CurvedAnimation(parent: animation, curve: AppTheme.easeStandard);
                    return SharedAxisTransition(
                      animation: curve,
                      secondaryAnimation: secondaryAnimation,
                      transitionType: SharedAxisTransitionType.horizontal,
                      child: child,
                    );
                  },
                ),
              );
            },
            child: const Text('立即注册'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final userProvider = Provider.of<UserProvider>(context, listen: false);

    final success = await userProvider.login(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (success && mounted) {
      Navigator.of(context).pushReplacementNamed('/');
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(userProvider.error ?? '登录失败'),
          backgroundColor: ArtisticTheme.errorColor,
        ),
      );
    }
  }

  Future<void> _handleGuestLogin() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    await userProvider.loginAsGuest();

    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/');
    }
  }

  void _showForgotPasswordDialog() {
    showGeneralDialog(
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
              title: const Text('重置密码'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('请输入您的邮箱地址，我们将发送重置密码的链接。'),
                  const SizedBox(height: 16),
                  TextFormField(
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: '邮箱地址',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('取消'),
                ),
                FilledButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('重置密码邮件已发送')),
                    );
                  },
                  child: const Text('发送'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
