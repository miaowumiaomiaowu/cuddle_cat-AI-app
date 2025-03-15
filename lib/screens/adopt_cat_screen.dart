import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/cat.dart';
import '../providers/cat_provider.dart';

class AdoptCatScreen extends StatefulWidget {
  const AdoptCatScreen({super.key});

  @override
  State<AdoptCatScreen> createState() => _AdoptCatScreenState();
}

class _AdoptCatScreenState extends State<AdoptCatScreen> {
  final TextEditingController _nameController = TextEditingController();
  CatBreed _selectedBreed = CatBreed.random;
  bool _isRandom = true;
  bool _isAdopting = false;

  @override
  void dispose() {
    _nameController.dispose();
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
        );
      } else {
        await catProvider.adoptCat(
          breed: _selectedBreed,
          name: _nameController.text.trim(),
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
        title: const Text(
          '领养猫咪',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(
                child: Text(
                  '欢迎来到暖猫',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.pink,
                  ),
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
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    color: _isRandom
                        ? Colors.pink.shade50
                        : _getCatColor(_selectedBreed).withOpacity(0.3),
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
                              ? Colors.pink
                              : _getCatColor(_selectedBreed),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _isRandom ? '随机猫咪' : _getCatBreedName(_selectedBreed),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: _isRandom
                                ? Colors.pink
                                : _getCatColor(_selectedBreed),
                          ),
                        ),
                      ],
                    ),
                  ),
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
                activeColor: Colors.pink,
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
              
              // 领养按钮
              Center(
                child: ElevatedButton(
                  onPressed: _isAdopting ? null : _adoptCat,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pink,
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
            color: isSelected ? Colors.pink : Colors.transparent,
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
        return Colors.pink;
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