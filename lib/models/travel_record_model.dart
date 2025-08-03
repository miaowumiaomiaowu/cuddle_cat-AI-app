import 'package:uuid/uuid.dart';

/// 旅行记录模型 - 增强版
class TravelRecord {
  final String id;
  final String title;
  final String description;
  final LocationInfo location;
  final List<MediaItem> mediaItems;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String mood; // 心情标记
  final List<String> tags; // 标签
  final WeatherInfo? weather; // 天气信息
  final List<String> companions; // 同行者
  final double? rating; // 评分 (1-5)
  final bool isPrivate; // 是否私密
  final String? shareUrl; // 分享链接

  TravelRecord({
    String? id,
    required this.title,
    required this.description,
    required this.location,
    required this.mediaItems,
    DateTime? createdAt,
    this.updatedAt,
    required this.mood,
    required this.tags,
    this.weather,
    required this.companions,
    this.rating,
    this.isPrivate = false,
    this.shareUrl,
  }) : id = id ?? const Uuid().v4(),
       createdAt = createdAt ?? DateTime.now();

  /// 从JSON创建对象
  factory TravelRecord.fromJson(Map<String, dynamic> json) {
    return TravelRecord(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      location: LocationInfo.fromJson(json['location']),
      mediaItems: (json['mediaItems'] as List)
          .map((item) => MediaItem.fromJson(item))
          .toList(),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt']) 
          : null,
      mood: json['mood'],
      tags: List<String>.from(json['tags']),
      weather: json['weather'] != null 
          ? WeatherInfo.fromJson(json['weather']) 
          : null,
      companions: List<String>.from(json['companions']),
      rating: json['rating']?.toDouble(),
      isPrivate: json['isPrivate'] ?? false,
      shareUrl: json['shareUrl'],
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'location': location.toJson(),
      'mediaItems': mediaItems.map((item) => item.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'mood': mood,
      'tags': tags,
      'weather': weather?.toJson(),
      'companions': companions,
      'rating': rating,
      'isPrivate': isPrivate,
      'shareUrl': shareUrl,
    };
  }

  /// 创建副本
  TravelRecord copyWith({
    String? title,
    String? description,
    LocationInfo? location,
    List<MediaItem>? mediaItems,
    DateTime? updatedAt,
    String? mood,
    List<String>? tags,
    WeatherInfo? weather,
    List<String>? companions,
    double? rating,
    bool? isPrivate,
    String? shareUrl,
  }) {
    return TravelRecord(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      location: location ?? this.location,
      mediaItems: mediaItems ?? this.mediaItems,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      mood: mood ?? this.mood,
      tags: tags ?? this.tags,
      weather: weather ?? this.weather,
      companions: companions ?? this.companions,
      rating: rating ?? this.rating,
      isPrivate: isPrivate ?? this.isPrivate,
      shareUrl: shareUrl ?? this.shareUrl,
    );
  }
}

/// 地理位置信息
class LocationInfo {
  final double latitude;
  final double longitude;
  final String address;
  final String? city;
  final String? province;
  final String? country;
  final String? poiName; // 兴趣点名称

  LocationInfo({
    required this.latitude,
    required this.longitude,
    required this.address,
    this.city,
    this.province,
    this.country,
    this.poiName,
  });

  factory LocationInfo.fromJson(Map<String, dynamic> json) {
    return LocationInfo(
      latitude: json['latitude'].toDouble(),
      longitude: json['longitude'].toDouble(),
      address: json['address'],
      city: json['city'],
      province: json['province'],
      country: json['country'],
      poiName: json['poiName'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'city': city,
      'province': province,
      'country': country,
      'poiName': poiName,
    };
  }
}

/// 多媒体项目
class MediaItem {
  final String id;
  final MediaType type;
  final String path; // 本地路径或网络URL
  final String? thumbnail; // 缩略图路径
  final String? caption; // 说明文字
  final DateTime createdAt;
  final int? duration; // 视频/音频时长(秒)
  final double? fileSize; // 文件大小(MB)

  MediaItem({
    String? id,
    required this.type,
    required this.path,
    this.thumbnail,
    this.caption,
    DateTime? createdAt,
    this.duration,
    this.fileSize,
  }) : id = id ?? const Uuid().v4(),
       createdAt = createdAt ?? DateTime.now();

  factory MediaItem.fromJson(Map<String, dynamic> json) {
    return MediaItem(
      id: json['id'],
      type: MediaType.values[json['type']],
      path: json['path'],
      thumbnail: json['thumbnail'],
      caption: json['caption'],
      createdAt: DateTime.parse(json['createdAt']),
      duration: json['duration'],
      fileSize: json['fileSize']?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.index,
      'path': path,
      'thumbnail': thumbnail,
      'caption': caption,
      'createdAt': createdAt.toIso8601String(),
      'duration': duration,
      'fileSize': fileSize,
    };
  }
}

/// 媒体类型枚举
enum MediaType {
  image,
  video,
  audio,
  text,
}

/// 天气信息
class WeatherInfo {
  final String condition; // 天气状况
  final double temperature; // 温度
  final String icon; // 天气图标
  final int humidity; // 湿度
  final String windSpeed; // 风速

  WeatherInfo({
    required this.condition,
    required this.temperature,
    required this.icon,
    required this.humidity,
    required this.windSpeed,
  });

  factory WeatherInfo.fromJson(Map<String, dynamic> json) {
    return WeatherInfo(
      condition: json['condition'],
      temperature: json['temperature'].toDouble(),
      icon: json['icon'],
      humidity: json['humidity'],
      windSpeed: json['windSpeed'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'condition': condition,
      'temperature': temperature,
      'icon': icon,
      'humidity': humidity,
      'windSpeed': windSpeed,
    };
  }
}

/// 旅行统计模型
class TravelStats {
  final int totalRecords; // 总记录数
  final int totalCities; // 去过的城市数
  final int totalProvinces; // 去过的省份数
  final double totalDistance; // 总里程(公里)
  final int totalDays; // 总旅行天数
  final Map<String, int> moodDistribution; // 心情分布
  final Map<String, int> monthlyDistribution; // 月度分布
  final List<String> topCities; // 最常去的城市
  final List<String> topTags; // 最常用的标签

  TravelStats({
    required this.totalRecords,
    required this.totalCities,
    required this.totalProvinces,
    required this.totalDistance,
    required this.totalDays,
    required this.moodDistribution,
    required this.monthlyDistribution,
    required this.topCities,
    required this.topTags,
  });

  factory TravelStats.fromJson(Map<String, dynamic> json) {
    return TravelStats(
      totalRecords: json['totalRecords'],
      totalCities: json['totalCities'],
      totalProvinces: json['totalProvinces'],
      totalDistance: json['totalDistance'].toDouble(),
      totalDays: json['totalDays'],
      moodDistribution: Map<String, int>.from(json['moodDistribution']),
      monthlyDistribution: Map<String, int>.from(json['monthlyDistribution']),
      topCities: List<String>.from(json['topCities']),
      topTags: List<String>.from(json['topTags']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalRecords': totalRecords,
      'totalCities': totalCities,
      'totalProvinces': totalProvinces,
      'totalDistance': totalDistance,
      'totalDays': totalDays,
      'moodDistribution': moodDistribution,
      'monthlyDistribution': monthlyDistribution,
      'topCities': topCities,
      'topTags': topTags,
    };
  }
}
