import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/cat.dart';
import '../providers/cat_provider.dart';
import '../theme/app_theme.dart';

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
                    // 圆形预览
                    Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        color: _isRandom
                            ? AppTheme.primaryColorLight.withValues(alpha: 0.25)
                            : _getCatColor(_selectedBreed).withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.pets,
                              size: 80,
                              color: _isRandom
                                  ? AppTheme.primaryColor
                                  : _getCatColor(_selectedBreed),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              _isRandom ? '随机猫咪' : _getCatBreedName(_selectedBreed),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: _isRandom
                                    ? AppTheme.primaryColor
                                    : _getCatColor(_selectedBreed),
                              ),
                            ),
                          ],
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
                  childAspectRatio: 1,
                  children: [
                    _buildBreedCard(CatBreed.persian),
                    _buildBreedCard(CatBreed.ragdoll),
                    _buildBreedCard(CatBreed.siamese),
                    _buildBreedCard(CatBreed.bengal),
                    _buildBreedCard(CatBreed.maineCoon),
                  ],
                ),
              ],

              const SizedBox(height: 30),

              // 个性选择
              const SizedBox(height: 16),
              Text('选择猫咪个性', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _personalityChip(CatPersonality.playful, '可爱'),
                  _personalityChip(CatPersonality.independent, '高冷'),
                  _personalityChip(CatPersonality.social, '搞笑'),
                  _personalityChip(CatPersonality.calm, '温柔'),
                  _personalityChip(CatPersonality.curious, '理性'),
                  _personalityChip(CatPersonality.lazy, '文艺'),
                ],
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

  Widget _personalityChip(CatPersonality p, String label) {
    final selected = _selectedPersonality == p;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      selectedColor: AppTheme.primaryColor.withValues(alpha: 0.2),
      onSelected: (_) => setState(() => _selectedPersonality = p),
    );
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

  Widget _buildBreedCard(CatBreed breed) {
    final isSelected = _selectedBreed == breed;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedBreed = breed;
        });
      },
      child: Card(
        elevation: isSelected ? 4 : 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isSelected ? AppTheme.primaryColor : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.pets,
              size: 40,
              color: _getCatColor(breed),
            ),
            const SizedBox(height: 8),
            Text(
              _getCatBreedName(breed),
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Color _getCatColor(CatBreed breed) {
    switch (breed) {
      case CatBreed.persian:
        return Colors.grey.shade600;
      case CatBreed.ragdoll:
        return Colors.blue.shade300;
      case CatBreed.siamese:
        return Colors.brown.shade300;
      case CatBreed.bengal:
        return Colors.orange.shade600;
      case CatBreed.maineCoon:
        return Colors.brown.shade700;
      case CatBreed.random:
        return AppTheme.primaryColor;
    }
  }

  String _getCatBreedName(CatBreed breed) {
    switch (breed) {
      case CatBreed.persian:
        return '波斯猫';
      case CatBreed.ragdoll:
        return '布偶猫';
      case CatBreed.siamese:
        return '暹罗猫';
      case CatBreed.bengal:
        return '孟加拉猫';
      case CatBreed.maineCoon:
        return '缅因猫';
      case CatBreed.random:
        return '随机猫咪';
    }
  }
}
