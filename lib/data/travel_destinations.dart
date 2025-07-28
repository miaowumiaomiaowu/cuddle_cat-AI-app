import '../models/travel.dart';

/// 预设的旅行目的地数据
class TravelDestinations {
  static const List<Map<String, dynamic>> destinations = [
    // 国内热门城市
    {
      'name': '北京',
      'emoji': '🏛️',
      'latitude': 39.9042,
      'longitude': 116.4074,
      'description': '中国的首都，拥有丰富的历史文化遗产',
      'tags': ['历史', '文化', '古建筑', '美食'],
      'attractions': ['故宫', '长城', '天安门', '颐和园'],
      'mood': 'excited',
    },
    {
      'name': '上海',
      'emoji': '🌃',
      'latitude': 31.2304,
      'longitude': 121.4737,
      'description': '国际化大都市，现代与传统的完美融合',
      'tags': ['现代', '购物', '夜景', '美食'],
      'attractions': ['外滩', '东方明珠', '南京路', '豫园'],
      'mood': 'happy',
    },
    {
      'name': '杭州',
      'emoji': '🌸',
      'latitude': 30.2741,
      'longitude': 120.1551,
      'description': '人间天堂，以西湖美景闻名于世',
      'tags': ['自然', '湖泊', '古典', '宁静'],
      'attractions': ['西湖', '灵隐寺', '雷峰塔', '宋城'],
      'mood': 'peaceful',
    },
    {
      'name': '成都',
      'emoji': '🐼',
      'latitude': 30.5728,
      'longitude': 104.0668,
      'description': '天府之国，熊猫故乡，美食天堂',
      'tags': ['美食', '熊猫', '休闲', '文化'],
      'attractions': ['大熊猫基地', '宽窄巷子', '锦里', '武侯祠'],
      'mood': 'relaxed',
    },
    {
      'name': '西安',
      'emoji': '🏺',
      'latitude': 34.3416,
      'longitude': 108.9398,
      'description': '十三朝古都，丝绸之路起点',
      'tags': ['历史', '古迹', '文化', '美食'],
      'attractions': ['兵马俑', '大雁塔', '古城墙', '回民街'],
      'mood': 'amazed',
    },
    {
      'name': '厦门',
      'emoji': '🏖️',
      'latitude': 24.4798,
      'longitude': 118.0819,
      'description': '海上花园城市，鼓浪屿的浪漫情怀',
      'tags': ['海滨', '浪漫', '文艺', '小清新'],
      'attractions': ['鼓浪屿', '南普陀寺', '厦门大学', '环岛路'],
      'mood': 'romantic',
    },
    {
      'name': '青岛',
      'emoji': '🍺',
      'latitude': 36.0986,
      'longitude': 120.3719,
      'description': '红瓦绿树，碧海蓝天，啤酒之城',
      'tags': ['海滨', '啤酒', '德式建筑', '海鲜'],
      'attractions': ['栈桥', '八大关', '崂山', '青岛啤酒博物馆'],
      'mood': 'cheerful',
    },
    {
      'name': '大理',
      'emoji': '🏔️',
      'latitude': 25.6066,
      'longitude': 100.2676,
      'description': '风花雪月，苍山洱海的诗意生活',
      'tags': ['自然', '古城', '民族文化', '宁静'],
      'attractions': ['洱海', '苍山', '大理古城', '双廊'],
      'mood': 'peaceful',
    },
    {
      'name': '丽江',
      'emoji': '🌺',
      'latitude': 26.8721,
      'longitude': 100.2240,
      'description': '纳西古城，雪山下的浪漫时光',
      'tags': ['古城', '民族文化', '雪山', '浪漫'],
      'attractions': ['丽江古城', '玉龙雪山', '泸沽湖', '束河古镇'],
      'mood': 'romantic',
    },
    {
      'name': '三亚',
      'emoji': '🏝️',
      'latitude': 18.2479,
      'longitude': 109.5146,
      'description': '热带天堂，椰风海韵的度假胜地',
      'tags': ['海滨', '热带', '度假', '阳光'],
      'attractions': ['亚龙湾', '天涯海角', '南山寺', '蜈支洲岛'],
      'mood': 'relaxed',
    },
    
    // 国际热门城市
    {
      'name': '东京',
      'emoji': '🗼',
      'latitude': 35.6762,
      'longitude': 139.6503,
      'description': '现代与传统并存的国际大都市',
      'tags': ['现代', '文化', '美食', '购物'],
      'attractions': ['东京塔', '浅草寺', '银座', '新宿'],
      'mood': 'excited',
    },
    {
      'name': '巴黎',
      'emoji': '🗼',
      'latitude': 48.8566,
      'longitude': 2.3522,
      'description': '浪漫之都，艺术与时尚的殿堂',
      'tags': ['浪漫', '艺术', '时尚', '历史'],
      'attractions': ['埃菲尔铁塔', '卢浮宫', '凯旋门', '塞纳河'],
      'mood': 'romantic',
    },
    {
      'name': '纽约',
      'emoji': '🗽',
      'latitude': 40.7128,
      'longitude': -74.0060,
      'description': '不夜城，世界金融和文化中心',
      'tags': ['现代', '繁华', '多元文化', '艺术'],
      'attractions': ['自由女神像', '时代广场', '中央公园', '帝国大厦'],
      'mood': 'energetic',
    },
    {
      'name': '伦敦',
      'emoji': '🎡',
      'latitude': 51.5074,
      'longitude': -0.1278,
      'description': '雾都，历史悠久的国际大都市',
      'tags': ['历史', '文化', '艺术', '传统'],
      'attractions': ['大本钟', '伦敦眼', '白金汉宫', '泰晤士河'],
      'mood': 'cultured',
    },
    {
      'name': '悉尼',
      'emoji': '🏄‍♀️',
      'latitude': -33.8688,
      'longitude': 151.2093,
      'description': '南半球的璀璨明珠，海港城市',
      'tags': ['海港', '现代', '自然', '活力'],
      'attractions': ['悉尼歌剧院', '海港大桥', '邦迪海滩', '达令港'],
      'mood': 'energetic',
    },
  ];

  /// 根据名称获取目的地信息
  static Map<String, dynamic>? getDestinationByName(String name) {
    try {
      return destinations.firstWhere((dest) => dest['name'] == name);
    } catch (e) {
      return null;
    }
  }

  /// 获取所有目的地名称
  static List<String> getAllDestinationNames() {
    return destinations.map((dest) => dest['name'] as String).toList();
  }

  /// 根据标签筛选目的地
  static List<Map<String, dynamic>> getDestinationsByTag(String tag) {
    return destinations.where((dest) {
      final tags = dest['tags'] as List<String>;
      return tags.contains(tag);
    }).toList();
  }

  /// 获取所有标签
  static List<String> getAllTags() {
    final allTags = <String>{};
    for (final dest in destinations) {
      final tags = dest['tags'] as List<String>;
      allTags.addAll(tags);
    }
    return allTags.toList()..sort();
  }

  /// 创建快速旅行记录
  static Travel createQuickTravelRecord(String destinationName, {
    String? customTitle,
    String? customDescription,
  }) {
    final dest = getDestinationByName(destinationName);
    if (dest == null) {
      throw ArgumentError('未找到目的地: $destinationName');
    }

    return Travel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: customTitle ?? '${dest['emoji']} ${dest['name']}之旅',
      locationName: dest['name'],
      latitude: dest['latitude'],
      longitude: dest['longitude'],
      mood: dest['mood'],
      description: customDescription ?? dest['description'],
      tags: List<String>.from(dest['tags']),
      photos: [],
      date: DateTime.now(),
      isFavorite: false,
    );
  }

  /// 获取推荐的目的地（基于心情）
  static List<Map<String, dynamic>> getRecommendationsByMood(String mood) {
    switch (mood.toLowerCase()) {
      case 'happy':
      case 'excited':
        return destinations.where((dest) => 
          ['excited', 'happy', 'energetic'].contains(dest['mood'])).toList();
      case 'peaceful':
      case 'relaxed':
        return destinations.where((dest) => 
          ['peaceful', 'relaxed'].contains(dest['mood'])).toList();
      case 'romantic':
        return destinations.where((dest) => 
          dest['mood'] == 'romantic').toList();
      case 'adventurous':
        return destinations.where((dest) => 
          ['energetic', 'excited'].contains(dest['mood'])).toList();
      default:
        return destinations.take(5).toList();
    }
  }

  /// 获取随机推荐
  static List<Map<String, dynamic>> getRandomRecommendations(int count) {
    final shuffled = List<Map<String, dynamic>>.from(destinations);
    shuffled.shuffle();
    return shuffled.take(count).toList();
  }
}
