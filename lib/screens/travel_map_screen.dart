import 'package:flutter/material.dart';

class TravelMapScreen extends StatefulWidget {
  const TravelMapScreen({super.key});

  @override
  State<TravelMapScreen> createState() => _TravelMapScreenState();
}

class _TravelMapScreenState extends State<TravelMapScreen> {
  final List<TravelRecord> _travelRecords = [
    TravelRecord(
      id: '1',
      location: '北京',
      date: DateTime.now().subtract(const Duration(days: 30)),
      image: 'https://picsum.photos/id/1018/300/200',
      description: '在北京度过了一个美好的周末，参观了故宫和长城。',
    ),
    TravelRecord(
      id: '2',
      location: '上海',
      date: DateTime.now().subtract(const Duration(days: 15)),
      image: 'https://picsum.photos/id/1015/300/200',
      description: '上海的夜景真的很美，外滩的灯光璀璨夺目。',
    ),
    TravelRecord(
      id: '3',
      location: '杭州',
      date: DateTime.now().subtract(const Duration(days: 5)),
      image: 'https://picsum.photos/id/1019/300/200',
      description: '西湖的美景让人流连忘返，享受了一天的宁静时光。',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text(
            '旅行地图',
            style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
          ),
          bottom: const TabBar(
            labelColor: Colors.pink,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.pink,
            tabs: [
              Tab(text: '地图', icon: Icon(Icons.map)),
              Tab(text: '记录', icon: Icon(Icons.photo_album)),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.add_location_alt, color: Colors.black87),
              onPressed: () {
                _showAddTravelRecordDialog();
              },
            ),
          ],
        ),
        body: TabBarView(
          children: [
            // 地图标签页
            _buildMapTab(),
            
            // 记录标签页
            _buildRecordsTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildMapTab() {
    return Stack(
      children: [
        // 这里将来会实现真实的地图
        Container(
          color: Colors.grey.shade200,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.map,
                  size: 100,
                  color: Colors.grey,
                ),
                const SizedBox(height: 20),
                Text(
                  '地图功能即将上线',
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () {
                    _showAddTravelRecordDialog();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  ),
                  child: const Text('添加旅行记录'),
                ),
              ],
            ),
          ),
        ),
        
        // 底部的位置指示器（模拟）
        Positioned(
          bottom: 20,
          right: 20,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 5,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.my_location, color: Theme.of(context).primaryColor, size: 18),
                const SizedBox(width: 5),
                const Text('定位到当前位置', style: TextStyle(fontSize: 12)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecordsTab() {
    if (_travelRecords.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.photo_album, size: 100, color: Colors.grey.shade300),
            const SizedBox(height: 20),
            Text(
              '还没有旅行记录',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                _showAddTravelRecordDialog();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('添加第一条记录'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _travelRecords.length,
      itemBuilder: (context, index) {
        final record = _travelRecords[index];
        return _buildTravelRecordCard(record);
      },
    );
  }

  Widget _buildTravelRecordCard(TravelRecord record) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 图片
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: SizedBox(
              width: double.infinity,
              height: 150,
              child: Image.network(
                record.image,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey.shade300,
                    alignment: Alignment.center,
                    child: const Icon(Icons.image_not_supported, size: 50, color: Colors.white),
                  );
                },
              ),
            ),
          ),
          
          // 内容
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      record.location,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _formatDate(record.date),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  record.description,
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      icon: const Icon(Icons.share, size: 18),
                      label: const Text('分享'),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('分享功能即将开放！'))
                        );
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: Theme.of(context).primaryColor,
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      icon: const Icon(Icons.edit, size: 18),
                      label: const Text('编辑'),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('编辑功能即将开放！'))
                        );
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAddTravelRecordDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('添加旅行记录'),
        content: const Text('这个功能将在后续版本中开放，敬请期待！'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

class TravelRecord {
  final String id;
  final String location;
  final DateTime date;
  final String image;
  final String description;

  TravelRecord({
    required this.id,
    required this.location,
    required this.date,
    required this.image,
    required this.description,
  });
} 