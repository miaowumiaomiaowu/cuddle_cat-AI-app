import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/artistic_theme.dart';
import '../../providers/user_provider.dart';
import '../../widgets/hand_drawn_card.dart';

/// 注册页面
class RegisterScreen extends StatefulWidget {
  static const String routeName = '/register';

  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneController = TextEditingController();
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreeToTerms = false;

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
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: ArtisticTheme.backgroundGradient,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(ArtisticTheme.spacingLarge),
            child: Column(
              children: [
                _buildHeader(),
                const SizedBox(height: 30),
                _buildRegisterForm(),
                const SizedBox(height: 30),
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
            Text(
              '加入暖猫',
              style: ArtisticTheme.headlineLarge.copyWith(
                fontWeight: FontWeight.w300,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '开始你的心情记录之旅',
              style: ArtisticTheme.bodyLarge.copyWith(
                color: ArtisticTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRegisterForm() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: HandDrawnCard(
        child: Padding(
          padding: const EdgeInsets.all(ArtisticTheme.spacingLarge),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 用户名输入框
                TextFormField(
                  controller: _usernameController,
                  decoration: InputDecoration(
                    labelText: '用户名',
                    hintText: '请输入用户名',
                    prefixIcon: const Icon(Icons.person_outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(ArtisticTheme.radiusMedium),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '请输入用户名';
                    }
                    if (value.length < 2) {
                      return '用户名长度不能少于2位';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                
                // 邮箱输入框
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: '邮箱',
                    hintText: '请输入邮箱地址',
                    prefixIcon: const Icon(Icons.email_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(ArtisticTheme.radiusMedium),
                    ),
                  ),
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
                
                // 手机号输入框（可选）
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: '手机号（可选）',
                    hintText: '请输入手机号',
                    prefixIcon: const Icon(Icons.phone_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(ArtisticTheme.radiusMedium),
                    ),
                  ),
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      if (!RegExp(r'^1[3-9]\d{9}$').hasMatch(value)) {
                        return '手机号格式不正确';
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                
                // 密码输入框
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: '密码',
                    hintText: '请输入密码（至少6位）',
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
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(ArtisticTheme.radiusMedium),
                    ),
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
                
                // 确认密码输入框
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  decoration: InputDecoration(
                    labelText: '确认密码',
                    hintText: '请再次输入密码',
                    prefixIcon: const Icon(Icons.lock_outlined),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureConfirmPassword = !_obscureConfirmPassword;
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(ArtisticTheme.radiusMedium),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '请确认密码';
                    }
                    if (value != _passwordController.text) {
                      return '两次输入的密码不一致';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                
                // 同意条款
                Row(
                  children: [
                    Checkbox(
                      value: _agreeToTerms,
                      onChanged: (value) {
                        setState(() {
                          _agreeToTerms = value ?? false;
                        });
                      },
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _agreeToTerms = !_agreeToTerms;
                          });
                        },
                        child: RichText(
                          text: TextSpan(
                            style: ArtisticTheme.bodySmall,
                            children: [
                              const TextSpan(text: '我已阅读并同意'),
                              TextSpan(
                                text: '《用户协议》',
                                style: TextStyle(
                                  color: ArtisticTheme.primaryColor,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                              const TextSpan(text: '和'),
                              TextSpan(
                                text: '《隐私政策》',
                                style: TextStyle(
                                  color: ArtisticTheme.primaryColor,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                
                // 注册按钮
                Consumer<UserProvider>(
                  builder: (context, userProvider, child) {
                    return ElevatedButton(
                      onPressed: userProvider.isLoading || !_agreeToTerms ? null : _handleRegister,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ArtisticTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(ArtisticTheme.radiusMedium),
                        ),
                      ),
                      child: userProvider.isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              '注册',
                              style: ArtisticTheme.titleMedium.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
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

  Widget _buildFooter() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '已有账号？',
            style: ArtisticTheme.bodyMedium.copyWith(
              color: ArtisticTheme.textSecondary,
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('立即登录'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_agreeToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('请先同意用户协议和隐私政策'),
          backgroundColor: ArtisticTheme.warningColor,
        ),
      );
      return;
    }

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    
    final success = await userProvider.register(
      username: _usernameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
      phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
    );

    if (success && mounted) {
      // 注册成功，显示欢迎消息
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🎉 注册成功！欢迎加入暖猫大家庭'),
          backgroundColor: ArtisticTheme.successColor,
        ),
      );
      
      // 跳转到主页
      Navigator.of(context).pushReplacementNamed('/');
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(userProvider.error ?? '注册失败'),
          backgroundColor: ArtisticTheme.errorColor,
        ),
      );
    }
  }
}
