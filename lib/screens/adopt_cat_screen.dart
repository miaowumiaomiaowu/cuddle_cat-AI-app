import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/cat.dart';
import '../providers/cat_provider.dart';
import '../theme/app_theme.dart';
import '../utils/cat_image_manager.dart';

class AdoptCatScreen extends StatefulWidget {
  const AdoptCatScreen({super.key});

  @override
  State<AdoptCatScreen> createState() => _AdoptCatScreenState();
}

class _AdoptCatScreenState extends State<AdoptCatScreen> with TickerProviderStateMixin {
  final TextEditingController _nameController = TextEditingController();
  CatBreed _selectedBreed = CatBreed.random;
  bool _isRandom = true;
  bool _isAdopting = false;
  CatPersonality _selectedPersonality = CatPersonality.playful;

  late AnimationController _burstController;
  late Animation<double> _burstOpacity;
  late Animation<double> _burstScale;
  final Random _rng = Random();

  @override
  void initState() {
    super.initState();
    _burstController = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _burstOpacity = CurvedAnimation(parent: _burstController, curve: Curves.easeOutCubic);
    _burstScale = Tween<double>(begin: 0.6, end: 1.35).animate(CurvedAnimation(parent: _burstController, curve: Curves.easeOutBack));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _burstController.dispose();
    super.dispose();
  }

  void _adoptCat() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请给你的猫咪取个名字吧~')),
      );
      return;
    }

    setState(() {
      _isAdopting = true;
    });

    try {
      final catProvider = Provider.of<CatProvider>(context, listen: false);

      if (_isRandom) {
        await catProvider.adoptCat(
          name: _nameController.text.trim(),
          breed: CatBreed.random,
          personality: _selectedPersonality,
        );
      } else {
        await catProvider.adoptCat(
          breed: _selectedBreed,
          name: _nameController.text.trim(),
          personality: _selectedPersonality,
        );
      }

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('领养失败: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAdopting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          '领养猫咪',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Text(
                  '欢迎来到暖猫',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(color: AppTheme.primaryColorDark),
                ),
              ),
              const SizedBox(height: 10),
              const Center(
                child: Text(
                  '准备好领养一只专属于你的猫咪了吗？',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // 猫咪图像预览
              Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // 爆发层
                    AnimatedBuilder(
                      animation: _burstController,
                      builder: (context, _) {
                        final v = _burstOpacity.value;
                        if (v <= 0.001) return const SizedBox.shrink();
                        return Transform.scale(
                          scale: _burstScale.value,
                          child: Opacity(opacity: v, child: _rewardBurst()),
                        );
                      },
                    ),
                    // 圆形预览（使用真实猫图）
                    Container(
                      width: 220,
                      height: 220,
                      decoration: const BoxDecoration(shape: BoxShape.circle),
                      child: ClipOval(
                        child: Image.asset(
                          _isRandom
                              ? CatImageManager.getPersonaImagePath(_selectedPersonality)
                              : CatImageManager.getCatImagePath(_breedKey(_selectedBreed)),
                          fit: BoxFit.cover,
                          errorBuilder: (c, e, s) => Icon(Icons.pets, size: 80, color: AppTheme.primaryColor),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // 猫咪名字输入
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: '猫咪名字',
                  hintText: '给你的猫咪取个可爱的名字吧',
                  prefixIcon: const Icon(Icons.edit),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // 领养方式选择
              SwitchListTile(
                title: const Text('随机领养'),
                subtitle: const Text('让系统为你选择一只随机品种的猫咪'),
                value: _isRandom,
                activeColor: AppTheme.primaryColor,
                onChanged: (value) {
                  setState(() {
                    _isRandom = value;
                  });
                },
              ),

              // 猫咪品种选择（在非随机模式下显示）
              if (!_isRandom) ...[
                const Padding(
                  padding: EdgeInsets.only(top: 10, bottom: 10),
                  child: Text(
                    '选择猫咪品种',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 3,
                  childAspectRatio: 0.9,
                  children: [
                    CatImageManager.buildBreedCard(breed: 'persian', onTap: () => setState(() => _selectedBreed = CatBreed.persian), isSelected: _selectedBreed == CatBreed.persian),
                    CatImageManager.buildBreedCard(breed: 'ragdoll', onTap: () => setState(() => _selectedBreed = CatBreed.ragdoll), isSelected: _selectedBreed == CatBreed.ragdoll),
                    CatImageManager.buildBreedCard(breed: 'siamese', onTap: () => setState(() => _selectedBreed = CatBreed.siamese), isSelected: _selectedBreed == CatBreed.siamese),
                    CatImageManager.buildBreedCard(breed: 'bengal', onTap: () => setState(() => _selectedBreed = CatBreed.bengal), isSelected: _selectedBreed == CatBreed.bengal),
                    CatImageManager.buildBreedCard(breed: 'maine_coon', onTap: () => setState(() => _selectedBreed = CatBreed.maineCoon), isSelected: _selectedBreed == CatBreed.maineCoon),
                  ],
                ),
              ],

              const SizedBox(height: 30),

              // 个性选择
              const SizedBox(height: 16),
              Text('选择猫咪个性', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(children: [
                  CatImageManager.buildPersonalityCard(
                    personality: CatPersonality.playful,
                    title: '阳光',
                    description: _personalityDesc(CatPersonality.playful),
                    selected: _selectedPersonality == CatPersonality.playful,
                    onTap: () {
                      setState(() => _selectedPersonality = CatPersonality.playful);
                      _showPersonalityPreviewBubble(CatPersonality.playful);
                    },
                  ),
                  CatImageManager.buildPersonalityCard(
                    personality: CatPersonality.social,
                    title: '搞笑',
                    description: _personalityDesc(CatPersonality.social),
                    selected: _selectedPersonality == CatPersonality.social,
                    onTap: () {
                      setState(() => _selectedPersonality = CatPersonality.social);
                      _showPersonalityPreviewBubble(CatPersonality.social);
                    },
                  ),
                  CatImageManager.buildPersonalityCard(
                    personality: CatPersonality.independent,
                    title: '严厉',
                    description: _personalityDesc(CatPersonality.independent),
                    selected: _selectedPersonality == CatPersonality.independent,
                    onTap: () {
                      setState(() => _selectedPersonality = CatPersonality.independent);
                      _showPersonalityPreviewBubble(CatPersonality.independent);
                    },
                  ),
                  CatImageManager.buildPersonalityCard(
                    personality: CatPersonality.calm,
                    title: '温暖',
                    description: _personalityDesc(CatPersonality.calm),
                    selected: _selectedPersonality == CatPersonality.calm,
                    onTap: () {
                      setState(() => _selectedPersonality = CatPersonality.calm);
                      _showPersonalityPreviewBubble(CatPersonality.calm);
                    },
                  ),
                  CatImageManager.buildPersonalityCard(
                    personality: CatPersonality.lazy,
                    title: '文艺',
                    description: _personalityDesc(CatPersonality.lazy),
                    selected: _selectedPersonality == CatPersonality.lazy,
                    onTap: () {
                      setState(() => _selectedPersonality = CatPersonality.lazy);
                      _showPersonalityPreviewBubble(CatPersonality.lazy);
                    },
                  ),
                ]),
              ),
              const SizedBox(height: 8),
              Text(_personalityDesc(_selectedPersonality), style: Theme.of(context).textTheme.bodyMedium),

              // 领养按钮
              const SizedBox(height: 24),
              Center(
                child: ElevatedButton(
                  onPressed: _isAdopting ? null : () async {
                    // 盲盒揭晓：随机模式触发一次爆发
                    if (_isRandom) {
                      await _burstController.forward(from: 0);
                      // 随机个性（如果当前没手动选）
                      final all = CatPersonality.values;
                      _selectedPersonality = all[_rng.nextInt(all.length)];
                      setState(() {});
                    }
                    _adoptCat();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 15,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: _isAdopting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          '领养猫咪',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
      );
  }


  // 个性预览气泡：展示该性格的典型回应风格
  void _showPersonalityPreviewBubble(CatPersonality p) {
    final Map<CatPersonality, List<String>> samples = {
      CatPersonality.playful: ['嘿嘿，今天也想黏着你~', '给你偷偷递一颗小太阳 ☀️'],
      CatPersonality.social: ['笑一个嘛～我先来：😹', '来点开心的！🎉'],
      CatPersonality.independent: ['我在，你放心做你该做的。', '给你一条清晰路线 🧭'],
      CatPersonality.calm: ['先深呼吸，慢慢来。', '我在，轻轻抱一会儿。'],
      CatPersonality.curious: ['这个可以这样试试：', '我有个小主意💡'],
      CatPersonality.lazy: ['泡杯茶听首歌吧 🎵', '给心情一点留白。'],
    };
    final list = samples[p] ?? ['喵~'];
    final text = (list..shuffle()).first;

    final overlay = Overlay.of(context);

    final entry = OverlayEntry(
      builder: (_) => Positioned(
        left: 24,
        right: 24,
        bottom: 140,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 350),
          builder: (c, v, child) => Opacity(
            opacity: v,
            child: Transform.translate(offset: Offset(0, 10 * (1 - v)), child: child),
          ),
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8)],
              ),
              child: Row(children: [
                const Text('💬 ', style: TextStyle(color: Colors.white)),
                Expanded(child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 14))),
              ]),
            ),
          ),
        ),
      ),
    );

    overlay.insert(entry);
    Future.delayed(const Duration(milliseconds: 1200), entry.remove);
  }


  // 将枚举品种转换为图片键
  String _breedKey(CatBreed b) {
    switch (b) {
      case CatBreed.persian:
        return 'persian';
      case CatBreed.ragdoll:
        return 'ragdoll';
      case CatBreed.siamese:
        return 'siamese';
      case CatBreed.bengal:
        return 'bengal';
      case CatBreed.maineCoon:
        return 'maine_coon';
      case CatBreed.random:
        return 'ragdoll';
    }
  }

  String _personalityDesc(CatPersonality p) {
    switch (p) {
      case CatPersonality.playful:
        return '软软的心，喜欢撒娇黏着你';
      case CatPersonality.independent:
        return '话不多，但一直在你身边';
      case CatPersonality.social:
        return '今天也想逗你笑呀';
      case CatPersonality.calm:
        return '像春风一样轻轻安慰你';
      case CatPersonality.curious:
        return '给出温和清晰的小建议';
      case CatPersonality.lazy:
        return '用一点小诗意点亮平凡';
    }
  }

  Widget _rewardBurst() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // 光束
        ...List.generate(12, (i) {
          final angle = (pi * 2 / 12) * i;
          return Transform.rotate(
            angle: angle,
            child: Container(
              width: 3,
              height: 120,
              decoration: BoxDecoration(
                color: AppTheme.accentColor.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
        // 绿色小星星
        ...List.generate(8, (i) {
          final angle = (pi * 2 / 8) * i;
          final dx = 40 * cos(angle);
          final dy = 40 * sin(angle);
          return Transform.translate(
            offset: Offset(dx, dy),
            child: const Icon(Icons.star, color: Colors.lightGreen, size: 18),
          );
        }),
      ],
    );
  }

  // 原 _buildBreedCard/_getCatColor/_getCatBreedName 已由 CatImageManager 的卡片替代，移除冗余。
}
