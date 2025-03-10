import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

// 导入实现的页面
import 'screens/cat_home_screen.dart';
import 'screens/travel_map_screen.dart';
import 'screens/profile_screen.dart';
import 'providers/cat_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // 设置状态栏颜色为透明
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
  ));
  
  // 强制竖屏
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CatProvider()),
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
      theme: ThemeData(
        primarySwatch: Colors.pink,
        primaryColor: const Color(0xFFFE9BB0), // 浅粉色作为主色调
        hintColor: const Color(0xFFFFC0CB), // 粉色作为辅助色
        scaffoldBackgroundColor: const Color(0xFFFFF5F7), // 淡淡的粉色背景
        fontFamily: 'Quicksand',
        textTheme: const TextTheme(
          displayLarge: TextStyle(fontSize: 28.0, fontWeight: FontWeight.bold),
          displayMedium: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold),
          displaySmall: TextStyle(fontSize: 20.0, fontWeight: FontWeight.w600),
          bodyLarge: TextStyle(fontSize: 16.0),
          bodyMedium: TextStyle(fontSize: 14.0),
        ),
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  
  // 主页面列表
  final List<Widget> _screens = const [
    CatHomeScreen(),
    TravelMapScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 10,
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          backgroundColor: Colors.white,
          selectedItemColor: Theme.of(context).primaryColor,
          unselectedItemColor: Colors.grey,
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.pets),
              label: '猫咪',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.map),
              label: '旅行',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: '我的',
            ),
          ],
        ),
      ),
    );
  }
} 