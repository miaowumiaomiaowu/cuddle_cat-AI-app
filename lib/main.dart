import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// 导入实现的页面
import 'screens/cat_home_screen.dart';
import 'screens/travel_map_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/dialogue_screen.dart';
import 'screens/api_debug_screen.dart';
import 'screens/data_debug_screen.dart';
import 'screens/travel_test_screen.dart';
import 'providers/cat_provider.dart';
import 'providers/dialogue_provider.dart';
import 'providers/travel_provider.dart';
import 'services/provider_manager.dart';
import 'theme/app_theme.dart';
import 'utils/page_transitions.dart';

void main() async {
  //初始化flutter绑定
  WidgetsFlutterBinding.ensureInitialized();

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

  // 创建Provider实例
  final catProvider = CatProvider();
  final dialogueProvider = DialogueProvider();
  final travelProvider = TravelProvider();

  // 创建Provider管理器
  final providerManager = ProviderManager();

  //使用provider状态管理启动应用
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: catProvider),
        ChangeNotifierProvider.value(value: dialogueProvider),
        ChangeNotifierProvider.value(value: travelProvider),
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
      theme: AppTheme.lightTheme,
      home: const MainScreen(),
      routes: {
        DialogueScreen.routeName: (ctx) => const DialogueScreen(),
        ApiDebugScreen.routeName: (ctx) => const ApiDebugScreen(),
        DataDebugScreen.routeName: (ctx) => const DataDebugScreen(),
        '/travel_test': (ctx) => const TravelTestScreen(),
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
    TravelMapScreen(),
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
      final catProvider = Provider.of<CatProvider>(context, listen: false);
      final dialogueProvider = Provider.of<DialogueProvider>(context, listen: false);
      final travelProvider = Provider.of<TravelProvider>(context, listen: false);

      await providerManager.initializeProviders([
        catProvider,
        dialogueProvider,
      ]);

      // 单独初始化TravelProvider（不继承BaseProvider）
      await travelProvider.initialize();

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
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          boxShadow: AppTheme.elevatedShadow,
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
            selectedItemColor: AppTheme.primaryColor,
            unselectedItemColor: AppTheme.textSecondary,
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
