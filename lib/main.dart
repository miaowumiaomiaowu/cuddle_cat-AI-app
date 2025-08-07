import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// 导入实现的页面
import 'screens/cat_home_screen.dart';
import 'screens/travel_map_screen_enhanced.dart';
import 'screens/profile_screen.dart';
import 'screens/dialogue_screen.dart';
import 'screens/api_debug_screen.dart';
import 'screens/data_debug_screen.dart';
import 'screens/records_summary_screen.dart';
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
import 'providers/travel_provider.dart';
import 'providers/mood_provider.dart';
import 'providers/user_provider.dart';
import 'services/provider_manager.dart';
import 'services/auth_service.dart';
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
  final travelProvider = TravelProvider();
  final userProvider = UserProvider(authService);
  final moodProvider = MoodProvider(userProvider);

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
        ChangeNotifierProvider.value(value: travelProvider),
        ChangeNotifierProvider.value(value: moodProvider),
        Provider.value(value: providerManager),
      ],
      child: const MyApp(),
    ),
  );
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

        '/records_summary': (ctx) => const RecordsSummaryScreen(),
        AIChatScreen.routeName: (ctx) => const AIChatScreen(),
        EnhancedMoodEntryScreen.routeName: (ctx) => const EnhancedMoodEntryScreen(),
        MoodMapScreen.routeName: (ctx) => const MoodMapScreen(),
        DeveloperToolsScreen.routeName: (ctx) => const DeveloperToolsScreen(),
        OnboardingScreen.routeName: (ctx) => const OnboardingScreen(),
        HelpCenterScreen.routeName: (ctx) => const HelpCenterScreen(),
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
  final List<Widget> _screens = const [
    CatHomeScreen(),
    TravelMapScreenEnhanced(),
    ProfileScreen(),
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
      final travelProvider = Provider.of<TravelProvider>(context, listen: false);
      final moodProvider = Provider.of<MoodProvider>(context, listen: false);

      // 首先初始化认证服务
      await authService.initialize();
      await userProvider.initialize();

      await providerManager.initializeProviders([
        catProvider,
        dialogueProvider,
      ]);

      // 单独初始化其他Provider
      await travelProvider.initialize();
      await moodProvider.initialize();

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
                icon: Text('🗺️', style: TextStyle(fontSize: 24)),
                activeIcon: Text('🗺️', style: TextStyle(fontSize: 28)),
                label: '旅行',
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
