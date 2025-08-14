import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/happiness_provider.dart';
import '../models/happiness_task.dart';
import '../theme/artistic_theme.dart';

class HappinessBlindBox extends StatefulWidget {
  const HappinessBlindBox({super.key});

  @override
  State<HappinessBlindBox> createState() => _HappinessBlindBoxState();
}

class _HappinessBlindBoxState extends State<HappinessBlindBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  late Animation<double> _rotateAnim;
  late Animation<double> _glowAnim;

  final Random _rng = Random();
  HappinessTask? _current;
  final List<String> _recentTitles = [];
  static const int _recentWindow = 3;
  bool _isOpening = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _scaleAnim = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.08).chain(CurveTween(curve: Curves.easeOut)), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.08, end: 1.0).chain(CurveTween(curve: Curves.easeIn)), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.05).chain(CurveTween(curve: Curves.easeOutBack)), weight: 40),
    ]).animate(_controller);
    _rotateAnim = Tween<double>(begin: 0, end: 0.07).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.2, 0.6, curve: Curves.easeInOut)),
    );
    _glowAnim = CurvedAnimation(parent: _controller, curve: const Interval(0.6, 1.0, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<HappinessTask> _buildPool(HappinessProvider hp) {
    final recs = hp.recommendations;
    final userTasks = hp.tasks.where((t) => !t.isArchived).toList();
    // 合并并去重（按标题+类别）
    final Map<String, HappinessTask> map = {};
    for (final t in [...recs, ...userTasks]) {
      final key = '${t.title}::${t.category}';
      map[key] = t;
    }
    return map.values.toList();
  }

  HappinessTask? _pickNext(HappinessProvider hp) {
    final pool = _buildPool(hp);
    if (pool.isEmpty) return null;
    // 打乱
    pool.shuffle(_rng);
    // 避免近期重复
    final filtered = pool.where((t) => !_recentTitles.contains(t.title)).toList();
    final pickFrom = filtered.isNotEmpty ? filtered : pool;
    final next = pickFrom[_rng.nextInt(pickFrom.length)];
    _recentTitles.add(next.title);
    if (_recentTitles.length > _recentWindow) _recentTitles.removeAt(0);
    return next;
  }

  Future<void> _openBox(HappinessProvider hp) async {
    if (_isOpening) return;
    setState(() => _isOpening = true);
    // 选择任务
    final next = _pickNext(hp);
    await _controller.forward(from: 0);
    setState(() {
      _current = next;
      _isOpening = false;
    });
  }

  Future<void> _shuffle(HappinessProvider hp) async {
    setState(() => _current = null);
    await _openBox(hp);
  }

  Future<void> _completeCurrent(HappinessProvider hp) async {
    if (_current == null) return;
    await hp.completeTask(_current!);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('已完成一件小幸福事 ✨')),
    );
    setState(() => _current = null);
    _controller.reset();
  }

  Future<void> _startCurrent(HappinessProvider hp) async {
    if (_current == null) return;
    await hp.addOrUpdateTask(_current!); // 确保入库
    await hp.addRecommendationToToday(_current!);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('已加入今日清单，出发吧！')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hp = Provider.of<HappinessProvider>(context);

    final pool = _buildPool(hp);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('幸福盲盒', style: ArtisticTheme.titleMedium),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: ArtisticTheme.surfaceColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: ArtisticTheme.cardShadow,
            border: Border.all(color: ArtisticTheme.primaryColor.withValues(alpha: 0.15)),
          ),
          child: Center(
            child: () {
              if (_current != null) return _buildRevealed(hp, _current!);
              if (hp.isLoading) return const CircularProgressIndicator();
              if (pool.isEmpty) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('暂无推荐，试试刷新AI推荐吧~'),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: () => hp.refreshAIRecommendations(force: true),
                      icon: const Icon(Icons.refresh),
                      label: const Text('刷新AI推荐'),
                    )
                  ],
                );
              }
              return _buildBox(hp);
            }(),
          ),
        ),
      ],
    );
  }

  Widget _buildBox(HappinessProvider hp) {
    return GestureDetector(
      onTap: () => _openBox(hp),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 光晕
          AnimatedBuilder(
            animation: _glowAnim,
            builder: (context, _) {
              final v = _glowAnim.value;
              return Container(
                width: 160 + 40 * v,
                height: 160 + 40 * v,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      ArtisticTheme.accentColor.withValues(alpha: 0.0 + 0.0 * v),
                      ArtisticTheme.accentColor.withValues(alpha: 0.15 * v),
                      ArtisticTheme.primaryColor.withValues(alpha: 0.10 * v),
                    ],
                  ),
                ),
              );
            },
          ),
          // 礼盒主体（卡片样式 + 丝带）
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return Transform.rotate(
                angle: _rotateAnim.value,
                child: Transform.scale(
                  scale: _scaleAnim.value,
                  child: _giftBoxVisual(),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          const Positioned(
            bottom: 0,
            child: Text('点击开启', style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }

  Widget _giftBoxVisual() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // 盒子底
        Container(
          width: 140,
          height: 100,
          decoration: BoxDecoration(
            color: ArtisticTheme.primaryColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: ArtisticTheme.elevatedShadow,
          ),
        ),
        // 盒子盖（稍大，制造开盖的感觉）
        Positioned(
          top: -4 - 6 * _glowAnim.value,
          child: Transform.translate(
            offset: Offset(0, -6 * _glowAnim.value),
            child: Transform.rotate(
              angle: _rotateAnim.value,
              child: Container(
                width: 160,
                height: 40,
                decoration: BoxDecoration(
                  color: ArtisticTheme.primaryColorDark,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: ArtisticTheme.softShadow,
                ),
              ),
            ),
          ),
        ),
        // 丝带竖条
        Container(
          width: 14,
          height: 95,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        // 丝带横条
        Positioned(
          bottom: 20,
          child: Container(
            width: 120,
            height: 12,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        // 礼花小星星（简单的粒子效果）
        ...List.generate(8, (i) {
          final angle = (pi * 2 / 8) * i;
          final r = 70 + 10 * sin((_glowAnim.value + i) * pi);
          return Positioned(
            left: r * cos(angle) + 70,
            top: r * sin(angle) + 50,
            child: Opacity(
              opacity: 0.6 * _glowAnim.value,
              child: Transform.rotate(
                angle: angle,
                child: const Icon(Icons.star, size: 14, color: Colors.white),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildRevealed(HappinessProvider hp, HappinessTask task) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('🎉 打开啦！', style: ArtisticTheme.titleMedium),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: ArtisticTheme.cardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: ArtisticTheme.cardShadow,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(task.emoji, style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(task.title, style: ArtisticTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(
                    (task.description.isNotEmpty ? task.description : '${task.estimatedMinutes ?? 5}分钟 · ${task.category}'),
                    style: ArtisticTheme.caption,
                  ),
                ],
              )
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            OutlinedButton.icon(
              onPressed: () => _shuffle(hp),
              icon: const Icon(Icons.autorenew),
              label: const Text('换一换'),
            ),
            const SizedBox(width: 12),
            TextButton.icon(
              onPressed: () => _startCurrent(hp),
              icon: const Icon(Icons.play_arrow),
              label: const Text('开始执行'),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: () => _completeCurrent(hp),
              icon: const Icon(Icons.check_circle),
              label: const Text('完成打卡'),
            ),
          ],
        )
      ],
    );
  }
}

