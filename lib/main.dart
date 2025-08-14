import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// 导入实现的页面
// import 'screens/cat_home_screen.dart';
import 'screens/happiness_home_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/dialogue_screen.dart';
import 'screens/api_debug_screen.dart';
import 'screens/data_debug_screen.dart';
import 'screens/happiness_task_edit_screen.dart';

import 'screens/immersive_chat_home_screen.dart';
import 'screens/ai_chat_screen.dart';
import 'screens/enhanced_mood_entry_screen.dart';
import 'screens/mood_map_screen.dart';
import 'screens/developer_tools_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/help_center_screen.dart';
import 'widgets/quick_record_fab.dart';
import 'services/error_handling_service.dart';
import 'providers/cat_provider.dart';
import 'providers/dialogue_provider.dart';

import 'providers/mood_provider.dart';
import 'providers/user_provider.dart';
import 'services/provider_manager.dart';
import 'services/auth_service.dart';
import 'services/ai_psychology_service.dart';
import 'providers/happiness_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'theme/artistic_theme.dart';
import 'utils/page_transitions.dart';

void main() async {
  //初始化flutter绑定
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化错误处理服务
  ErrorHandlingService().initialize();

  // 加载环境变量 - 添加错误处理
  try {
    await dotenv.load(fileName: ".env");
    debugPrint("环境变量加载成功");
  } catch (e) {
    debugPrint("环境变量加载失败: $e");
    // 继续运行，不阻止应用启动
  }

  // 全局 HTTP 代理（方案B）：通过 .env 开关让所有网络走 10.0.2.2:7890 等代理
  _maybeEnableGlobalProxyFromEnv();

  // 设置系统UI样式
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  // 设置屏幕方向
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // 创建服务实例
  final authService = AuthService();

  // 创建Provider实例
  final catProvider = CatProvider();
  final dialogueProvider = DialogueProvider();

  final userProvider = UserProvider(authService);
  final moodProvider = MoodProvider(userProvider);
  // 幸福任务 Provider（AI联动）
  final happinessProvider = HappinessProvider(
    aiService: AIPsychologyService(),
    dialogueProvider: dialogueProvider,
    moodProvider: moodProvider,
    userProvider: userProvider,
  );

  // 创建Provider管理器
  final providerManager = ProviderManager();

  //使用provider状态管理启动应用
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authService),
        ChangeNotifierProvider.value(value: userProvider),
        ChangeNotifierProvider.value(value: catProvider),
        ChangeNotifierProvider.value(value: dialogueProvider),

        ChangeNotifierProvider.value(value: moodProvider),
        ChangeNotifierProvider.value(value: happinessProvider),
        Provider.value(value: providerManager),
      ],
      child: const MyApp(),
    ),
  );
}

void _maybeEnableGlobalProxyFromEnv() {
  // 支持 USE_HTTP_PROXY=true / 1 / yes / on（大小写不敏感）
  final raw = dotenv.env['USE_HTTP_PROXY']?.trim().toLowerCase();
  final enable = raw == 'true' || raw == '1' || raw == 'yes' || raw == 'on';

  if (!enable) {
    debugPrint('未开启全局代理');
    return;
  }

  // 支持 HTTP_PROXY=host:port 或 HTTP_PROXY_HOST + HTTP_PROXY_PORT
  String? proxy = dotenv.env['HTTP_PROXY']?.trim();
  final host = dotenv.env['HTTP_PROXY_HOST']?.trim();
  final port = dotenv.env['HTTP_PROXY_PORT']?.trim();
  if ((proxy == null || proxy.isEmpty) && host != null && host.isNotEmpty && port != null && port.isNotEmpty) {
    proxy = '$host:$port';
  }
  if (proxy == null || proxy.isEmpty) {
    debugPrint('已开启全局代理但未提供 HTTP_PROXY/HTTP_PROXY_HOST/HTTP_PROXY_PORT');
    return;
  }

  // 是否忽略证书，仅开发调试使用
  final insecureRaw = dotenv.env['HTTP_PROXY_INSECURE']?.trim().toLowerCase();
  final insecure = insecureRaw == 'true' || insecureRaw == '1' || insecureRaw == 'yes' || insecureRaw == 'on';

  HttpOverrides.global = _ProxyHttpOverrides(proxy, allowBadCertificate: insecure);
  debugPrint('已启用全局代理 -> $proxy, 允许自签: $insecure');
}

class _ProxyHttpOverrides extends HttpOverrides {
  final String proxyHostPort; // e.g. 10.0.2.2:7890
  final bool allowBadCertificate;
  _ProxyHttpOverrides(this.proxyHostPort, {this.allowBadCertificate = false});

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final client = super.createHttpClient(context);
    client.findProxy = (uri) {
      // 让所有请求（http/https）走 HTTP 代理
      return 'PROXY $proxyHostPort;';
    };
    if (allowBadCertificate) {
      client.badCertificateCallback = (X509Certificate cert, String host, int port) => true;
    }
    return client;
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '暖猫',
      theme: ArtisticTheme.lightTheme,
      home: const SplashScreen(),
      routes: {
        LoginScreen.routeName: (ctx) => const LoginScreen(),
        RegisterScreen.routeName: (ctx) => const RegisterScreen(),
        DialogueScreen.routeName: (ctx) => const DialogueScreen(),
        ApiDebugScreen.routeName: (ctx) => const ApiDebugScreen(),
        DataDebugScreen.routeName: (ctx) => const DataDebugScreen(),

        // '/records_summary': (ctx) => const RecordsSummaryScreen(), // 已删除
        AIChatScreen.routeName: (ctx) => const AIChatScreen(),
        EnhancedMoodEntryScreen.routeName: (ctx) => const EnhancedMoodEntryScreen(),
        MoodMapScreen.routeName: (ctx) => const MoodMapScreen(),
        DeveloperToolsScreen.routeName: (ctx) => const DeveloperToolsScreen(),
        OnboardingScreen.routeName: (ctx) => const OnboardingScreen(),
        HelpCenterScreen.routeName: (ctx) => const HelpCenterScreen(),
        HappinessTaskEditScreen.routeName: (ctx) => const HappinessTaskEditScreen(),

        '/splash': (ctx) => const SplashScreen(),
        '/main': (ctx) => const MainScreen(),
      },
      // 自定义页面过渡动画
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case DialogueScreen.routeName:
            return PageTransitions.slideUpTransition(
              const DialogueScreen(),
              settings: settings,
            );
          case ApiDebugScreen.routeName:
            return PageTransitions.fadeTransition(
              const ApiDebugScreen(),
              settings: settings,
            );
          case DataDebugScreen.routeName:
            return PageTransitions.fadeTransition(
              const DataDebugScreen(),
              settings: settings,
            );
          default:
            return null;
        }
      },
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with WidgetsBindingObserver {
  int _currentIndex = 0;
  bool _isInitialized = false;

  // 主页面列表
  final List<Widget> _screens = [
    const ImmersiveChatHomeScreen(),
    const HappinessHomeScreen(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // 延迟初始化Provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeProviders();
    });
  }

  Future<void> _initializeProviders() async {
    if (_isInitialized) return;

    try {
      final providerManager = Provider.of<ProviderManager>(context, listen: false);
      final authService = Provider.of<AuthService>(context, listen: false);
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final catProvider = Provider.of<CatProvider>(context, listen: false);
      final dialogueProvider = Provider.of<DialogueProvider>(context, listen: false);

      final moodProvider = Provider.of<MoodProvider>(context, listen: false);
      final happinessProvider = Provider.of<HappinessProvider>(context, listen: false);

      // 首先初始化认证服务
      await authService.initialize();
      await userProvider.initialize();

      await providerManager.initializeProviders([
        catProvider,
        dialogueProvider,
      ]);

      // 单独初始化其他Provider（先心情，再幸福，以便AI可用心情数据）
      await moodProvider.initialize();

      await happinessProvider.initialize();

      _isInitialized = true;
      debugPrint("Provider管理器延迟初始化成功");
    } catch (e) {
      debugPrint("Provider管理器延迟初始化失败: $e");
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (_isInitialized) {
      // 通知Provider管理器处理生命周期变化
      final providerManager = Provider.of<ProviderManager>(context, listen: false);
      providerManager.handleAppLifecycleChange(state);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        // 如果用户未认证，显示登录页面
        if (!userProvider.isAuthenticated) {
          return const LoginScreen();
        }

        // 已认证用户显示主界面
        return _buildMainInterface();
      },
    );
  }

  Widget _buildMainInterface() {
    return Scaffold(
      body: _screens[_currentIndex],
      floatingActionButton: const QuickRecordFAB(),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: ArtisticTheme.surfaceColor,
          boxShadow: ArtisticTheme.elevatedShadow,
        ),
        child: SafeArea(
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            elevation: 0,
            backgroundColor: Colors.transparent,
            selectedItemColor: ArtisticTheme.primaryColor,
            unselectedItemColor: ArtisticTheme.textSecondary,
            type: BottomNavigationBarType.fixed,
            selectedLabelStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.normal,
            ),
            items: const [
              BottomNavigationBarItem(
                icon: Text('🐱', style: TextStyle(fontSize: 24)),
                activeIcon: Text('🐱', style: TextStyle(fontSize: 28)),
                label: '猫咪',
              ),
              BottomNavigationBarItem(
                icon: Text('🌿', style: TextStyle(fontSize: 24)),
                activeIcon: Text('🌿', style: TextStyle(fontSize: 28)),
                label: '幸福',
              ),
              BottomNavigationBarItem(
                icon: Text('👤', style: TextStyle(fontSize: 24)),
                activeIcon: Text('👤', style: TextStyle(fontSize: 28)),
                label: '我的',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
