import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/accessory.dart';
import '../providers/accessory_provider.dart';
import '../providers/cat_provider.dart';
import '../widgets/accessory_preview.dart';

class AccessoryShopScreen extends StatefulWidget {
  const AccessoryShopScreen({Key? key}) : super(key: key);

  @override
  State<AccessoryShopScreen> createState() => _AccessoryShopScreenState();
}

class _AccessoryShopScreenState extends State<AccessoryShopScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Accessory? _selectedAccessory;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: AccessoryType.values.length,
      vsync: this,
    );
    
    _tabController.addListener(() {
      final accessoryProvider = Provider.of<AccessoryProvider>(context, listen: false);
      accessoryProvider.changeType(AccessoryType.values[_tabController.index]);
      setState(() {
        _selectedAccessory = null;
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _getAccessoryTypeLabel(AccessoryType type) {
    switch (type) {
      case AccessoryType.hat:
        return '帽子';
      case AccessoryType.collar:
        return '项圈';
      case AccessoryType.glasses:
        return '眼镜';
      case AccessoryType.costume:
        return '服装';
      case AccessoryType.background:
        return '背景';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '装饰品商店',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: Theme.of(context).primaryColor,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Theme.of(context).primaryColor,
          tabs: AccessoryType.values.map((type) {
            return Tab(text: _getAccessoryTypeLabel(type));
          }).toList(),
        ),
      ),
      body: Column(
        children: [
          // 用户金币信息
          _buildCoinInfo(),
          
          // 商品列表和预览区域
          Expanded(
            child: Row(
              children: [
                // 左侧商品列表
                Expanded(
                  flex: 3,
                  child: _buildAccessoryList(),
                ),
                
                // 右侧预览和操作区域
                Expanded(
                  flex: 2,
                  child: _buildPreviewArea(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoinInfo() {
    return Consumer<AccessoryProvider>(
      builder: (context, provider, child) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          color: Colors.amber.withOpacity(0.1),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              const Icon(Icons.monetization_on, color: Colors.amber),
              const SizedBox(width: 8),
              Text(
                '${provider.coins}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              // DEV模式下的添加金币按钮
              IconButton(
                icon: const Icon(Icons.add_circle_outline, size: 16),
                onPressed: () {
                  provider.addCoins(500);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('已添加500金币（开发模式）')),
                  );
                },
              ),
            ],
          ),
        );
      }
    );
  }

  Widget _buildAccessoryList() {
    return Consumer<AccessoryProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final accessories = provider.currentTypeAccessories;
        
        if (accessories.isEmpty) {
          return const Center(child: Text('暂无可用装饰品'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: accessories.length,
          itemBuilder: (context, index) {
            final accessory = accessories[index];
            final isSelected = _selectedAccessory?.id == accessory.id;
            
            return Card(
              elevation: isSelected ? 4 : 1,
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: isSelected 
                    ? BorderSide(color: Theme.of(context).primaryColor, width: 2)
                    : BorderSide.none,
              ),
              child: InkWell(
                onTap: () {
                  setState(() {
                    _selectedAccessory = accessory;
                  });
                },
                borderRadius: BorderRadius.circular(10),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      // 装饰品图标（暂时用默认图标代替）
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: accessory.rarityColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          _getIconForType(accessory.type),
                          color: accessory.rarityColor,
                        ),
                      ),
                      const SizedBox(width: 16),
                      
                      // 装饰品信息
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  accessory.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: accessory.rarityColor.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    accessory.rarityText,
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: accessory.rarityColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              accessory.description,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      
                      // 价格/状态信息
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (accessory.isLocked)
                            Row(
                              children: [
                                const Icon(
                                  Icons.monetization_on,
                                  color: Colors.amber,
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${accessory.price}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            )
                          else
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                '已拥有',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPreviewArea() {
    return Consumer2<AccessoryProvider, CatProvider>(
      builder: (context, accessoryProvider, catProvider, child) {
        if (!catProvider.hasCat) {
          return const Center(child: Text('请先领养一只猫咪'));
        }

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // 预览标题
              const Text(
                '装饰品预览',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              
              // 装饰品预览
              Expanded(
                child: _selectedAccessory == null
                    ? Center(
                        child: Text(
                          '选择一个装饰品来预览',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      )
                    : AccessoryPreview(
                        cat: catProvider.cat!,
                        accessory: _selectedAccessory!,
                      ),
              ),
              
              // 操作按钮
              if (_selectedAccessory != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: _buildActionButton(
                    accessoryProvider, 
                    catProvider, 
                    _selectedAccessory!
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActionButton(
    AccessoryProvider accessoryProvider, 
    CatProvider catProvider, 
    Accessory accessory
  ) {
    // 检查猫咪是否已装备该类型的配饰
    final cat = catProvider.cat!;
    final isEquipped = cat.equippedAccessories.containsKey(accessory.type.toString()) && 
                       cat.equippedAccessories[accessory.type.toString()] == accessory.id;
                       
    if (accessory.isLocked) {
      // 未拥有，显示购买按钮
      return ElevatedButton.icon(
        onPressed: accessoryProvider.coins >= accessory.price
            ? () async {
                final success = await accessoryProvider.purchaseAccessory(accessory.id);
                if (success) {
                  setState(() {
                    // 更新选中的装饰品状态
                    _selectedAccessory = accessoryProvider
                        .getAccessoriesByType(accessory.type)
                        .firstWhere((a) => a.id == accessory.id);
                  });
                  
                  // 显示购买成功提示
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('成功购买 ${accessory.name}')),
                    );
                  }
                } else if (accessoryProvider.errorMessage != null) {
                  // 显示错误提示
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(accessoryProvider.errorMessage!)),
                    );
                  }
                  accessoryProvider.clearError();
                }
              }
            : null, // 金币不足时禁用按钮
        icon: const Icon(Icons.shopping_cart),
        label: Text('购买 (${accessory.price} 金币)'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).primaryColor,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } else if (isEquipped) {
      // 已装备，显示移除按钮
      return OutlinedButton.icon(
        onPressed: () {
          catProvider.removeAccessory(accessory.type.toString());
          setState(() {}); // 刷新UI
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('已移除 ${accessory.name}')),
          );
        },
        icon: const Icon(Icons.remove_circle_outline),
        label: const Text('移除装饰'),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.red,
          side: const BorderSide(color: Colors.red),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } else {
      // 已拥有但未装备，显示装备按钮
      return ElevatedButton.icon(
        onPressed: () {
          catProvider.equipAccessory(accessory.type.toString(), accessory.id);
          setState(() {}); // 刷新UI
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('已装备 ${accessory.name}')),
          );
        },
        icon: const Icon(Icons.checkroom),
        label: const Text('装备'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  IconData _getIconForType(AccessoryType type) {
    switch (type) {
      case AccessoryType.hat:
        return Icons.face;
      case AccessoryType.collar:
        return Icons.favorite;
      case AccessoryType.glasses:
        return Icons.remove_red_eye;
      case AccessoryType.costume:
        return Icons.checkroom;
      case AccessoryType.background:
        return Icons.image;
    }
  }
} 