import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/happiness_provider.dart';
import '../models/happiness_task.dart';
import '../theme/artistic_theme.dart';
import '../services/feedback_service.dart';


class HappinessGiftView extends StatefulWidget {
  const HappinessGiftView({super.key});

  @override
  State<HappinessGiftView> createState() => _HappinessGiftViewState();
}

class _HappinessGiftViewState extends State<HappinessGiftView>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  late Animation<double> _rotateAnim;
  late Animation<double> _glowAnim;
  HappinessTask? _current;
  final _rng = Random();
  final List<String> _recent = [];
  final FeedbackService _feedbackService = FeedbackService();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _scaleAnim = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.05), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.05, end: 1.0), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.03), weight: 40),
    ]).animate(_controller);
    _rotateAnim = Tween<double>(begin: 0, end: 0.06).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.2, 0.6, curve: Curves.easeInOut)),
    );
    _glowAnim = CurvedAnimation(parent: _controller, curve: const Interval(0.5, 1.0, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<HappinessTask> _pool(HappinessProvider hp) {
    final recs = hp.recommendations;
    final user = hp.tasks.where((t) => !t.isArchived).toList();
    final map = <String, HappinessTask>{};
    for (final t in [...recs, ...user]) {
      map['${t.title}::${t.category}'] = t;
    }
    return map.values.toList();
  }

  HappinessTask? _pick(HappinessProvider hp) {
    final pool = _pool(hp);
    if (pool.isEmpty) return null;
    pool.shuffle(_rng);
    final filtered = pool.where((t) => !_recent.contains(t.title)).toList();
    final base = filtered.isNotEmpty ? filtered : pool;
    final next = base[_rng.nextInt(base.length)];
    _recent.add(next.title);
    if (_recent.length > 3) _recent.removeAt(0);
    return next;
  }

  Future<void> _open(HappinessProvider hp) async {
    final next = _pick(hp);
    await _controller.forward(from: 0);
    setState(() => _current = next);
  }

  Future<void> _shuffle(HappinessProvider hp) async {
    setState(() => _current = null);
    // 播放同样的开盖动画与音效
    await _open(hp);
  }

  Future<void> _start(HappinessProvider hp) async {
    if (_current == null) return;

    // 记录用户反馈
    await _feedbackService.likegift(_current!.id, _current!.title);

    await hp.addOrUpdateTask(_current!);
    await hp.addRecommendationToToday(_current!);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('已收下礼物，开始行动吧！')),
    );
  }

  Future<void> _complete(HappinessProvider hp) async {
    if (_current == null) return;

    // 记录完成反馈
    await _feedbackService.completeGift(_current!.id, _current!.title, rating: 5);

    await hp.completeTask(_current!);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('哇你真的很厉害！继续保持这份力量吧 ✨')),
    );
    setState(() => _current = null);
    _controller.reset();
  }

  @override
  Widget build(BuildContext context) {
    final hp = Provider.of<HappinessProvider>(context);
    final size = MediaQuery.of(context).size;

    return Container(
      width: size.width,
      height: size.height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [ArtisticTheme.primaryColor.withAlpha(18), Colors.white],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: AspectRatio(
            aspectRatio: 0.75,
            child: _current == null ? _buildGift(hp) : _buildCard(hp, _current!),
          ),
        ),
      ),
    );
  }

  Widget _buildGift(HappinessProvider hp) {
    final pool = _pool(hp);
    if (hp.isLoading) return const Center(child: CircularProgressIndicator());
    if (pool.isEmpty) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('暂时没有可打开的礼物'),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => hp.refreshAIRecommendations(force: true),
            icon: const Icon(Icons.refresh),
            label: const Text('刷新AI推荐'),
          )
        ],
      );
    }

    final canOpen = hp.canOpenGiftToday;
    return GestureDetector(
      onTap: canOpen ? () async { await _open(hp); hp.markGiftOpenedToday(); } : null,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (!canOpen)
            Positioned(
              bottom: 28,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: const Color(0x66000000), borderRadius: BorderRadius.circular(12)),
                  child: const Text('今天已开启，明天再来新的小礼物吧～', style: TextStyle(color: Colors.white)),
                ),
              ),
            ),
          AnimatedBuilder(
            animation: _glowAnim,
            builder: (context, _) {
              final v = _glowAnim.value;
              return Container(
                width: 260 + 60 * v,
                height: 260 + 60 * v,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [
                    ArtisticTheme.accentColor.withAlpha((40 * v).toInt()),
                    ArtisticTheme.primaryColor.withAlpha((30 * v).toInt()),
                    Colors.transparent,
                  ]),
                ),
              );
            },
          ),
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return Transform.rotate(
                angle: _rotateAnim.value,
                child: Transform.scale(
                  scale: _scaleAnim.value,
                  child: _giftVisual(),
                ),
              );
            },
          ),
          const Positioned(bottom: 0, child: Text('嗨！做一点小事让今天更好吧！', style: TextStyle(color: Colors.grey))),
        ],
      ),
    );
  }

  Widget _giftVisual() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 220,
          height: 160,
          decoration: BoxDecoration(
            color: ArtisticTheme.primaryColor,
            borderRadius: BorderRadius.circular(24),
            boxShadow: ArtisticTheme.elevatedShadow,
          ),
        ),
        Positioned(
          top: -6,
          child: Transform.translate(
            offset: Offset(0, -8 * _glowAnim.value),
            child: Transform.rotate(
              angle: _rotateAnim.value,
              child: Container(
                width: 260,
                height: 60,
                decoration: BoxDecoration(
                  color: ArtisticTheme.primaryColorDark,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: ArtisticTheme.softShadow,
                ),
              ),
            ),
          ),
        ),
        Container(width: 18, height: 150, decoration: BoxDecoration(color: Colors.white.withAlpha(220), borderRadius: BorderRadius.circular(10))),
        Positioned(bottom: 40, child: Container(width: 180, height: 14, decoration: BoxDecoration(color: Colors.white.withAlpha(220), borderRadius: BorderRadius.circular(10)))),
        ...List.generate(12, (i) {
          final ang = (pi * 2 / 12) * i;
          final r = 100 + 12 * sin((_glowAnim.value + i) * pi);
          return Positioned(
            left: r * cos(ang) + 110,
            top: r * sin(ang) + 80,
            child: Opacity(
              opacity: 0.5 * _glowAnim.value,
              child: Transform.rotate(angle: ang, child: const Icon(Icons.star, size: 16, color: Colors.white)),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildCard(HappinessProvider hp, HappinessTask task) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ArtisticTheme.cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: ArtisticTheme.cardShadow,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('🎁 今日礼物', style: ArtisticTheme.titleMedium),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(task.emoji, style: const TextStyle(fontSize: 36)),
              const SizedBox(width: 12),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(task.title, style: ArtisticTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(
                      task.description.isNotEmpty ? task.description : '${task.estimatedMinutes ?? 5}分钟 · ${task.category}',
                      style: ArtisticTheme.caption,
                    ),
                  ],
                ),
              )
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 12,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(onPressed: () => _shuffle(hp), icon: const Icon(Icons.autorenew), label: const Text('换一换')),
              TextButton.icon(onPressed: () => _start(hp), icon: const Icon(Icons.play_arrow), label: const Text('收下礼物')),
              ElevatedButton.icon(onPressed: () => _complete(hp), icon: const Icon(Icons.check_circle), label: const Text('完成打卡')),
            ],
          )
        ],
      ),
    );
  }
}

