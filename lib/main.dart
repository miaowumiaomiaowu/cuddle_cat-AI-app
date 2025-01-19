import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cuddle_cat/models/cat.dart';
import 'package:cuddle_cat/screens/home_screen.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => CatModel(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '治愈猫咪',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.pink.shade100),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}