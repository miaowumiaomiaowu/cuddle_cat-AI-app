/// 旅行记录模型
class Travel {
  final String id;
  final String title;
  final String locationName;
  final double latitude;
  final double longitude;
  final String mood;
  final String description;
  final List<String> tags;
  final List<String> photos;
  final DateTime date;
  bool isFavorite;

  Travel({
    required this.id,
    required this.title,
    required this.locationName,
    required this.latitude,
    required this.longitude,
    required this.mood,
    required this.description,
    required this.tags,
    required this.photos,
    required this.date,
    this.isFavorite = false,
  });

  /// 从JSON创建Travel实例
  factory Travel.fromJson(Map<String, dynamic> json) {
    return Travel(
      id: json['id'] as String,
      title: json['title'] as String,
      locationName: json['locationName'] as String,
      latitude: json['latitude'] as double,
      longitude: json['longitude'] as double,
      mood: json['mood'] as String,
      description: json['description'] as String,
      tags: List<String>.from(json['tags']),
      photos: List<String>.from(json['photos']),
      date: DateTime.parse(json['date'] as String),
      isFavorite: json['isFavorite'] as bool,
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'locationName': locationName,
      'latitude': latitude,
      'longitude': longitude,
      'mood': mood,
      'description': description,
      'tags': tags,
      'photos': photos,
      'date': date.toIso8601String(),
      'isFavorite': isFavorite,
    };
  }

  /// 创建Travel的副本
  Travel copyWith({
    String? id,
    String? title,
    String? locationName,
    double? latitude,
    double? longitude,
    String? mood,
    String? description,
    List<String>? tags,
    List<String>? photos,
    DateTime? date,
    bool? isFavorite,
  }) {
    return Travel(
      id: id ?? this.id,
      title: title ?? this.title,
      locationName: locationName ?? this.locationName,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      mood: mood ?? this.mood,
      description: description ?? this.description,
      tags: tags ?? this.tags,
      photos: photos ?? this.photos,
      date: date ?? this.date,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}



/// 表示经纬度坐标的类，代替高德地图的LatLng类
class LatLng {
  final double latitude;
  final double longitude;

  const LatLng(this.latitude, this.longitude);
}
