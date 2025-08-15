import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/achievement.dart';
import '../models/happiness_task.dart';

class AchievementService {
  static const String _achievementsKey = 'user_achievements';
  static const String _progressKey = 'achievement_progress';
  
  List<Achievement> _achievements = [];
  Map<String, int> _progress = {};
  
  Future<void> initialize() async {
    await _loadAchievements();
    await _loadProgress();
  }
  
  Future<void> _loadAchievements() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_achievementsKey);
    
    if (jsonStr != null) {
      final List<dynamic> jsonList = jsonDecode(jsonStr);
      _achievements = jsonList.map((json) => Achievement.fromJson(json)).toList();
    } else {
      // 首次使用，初始化默认成就
      _achievements = AchievementTemplates.defaultAchievements;
      await _saveAchievements();
    }
  }
  
  Future<void> _loadProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_progressKey);
    
    if (jsonStr != null) {
      final Map<String, dynamic> jsonMap = jsonDecode(jsonStr);
      _progress = jsonMap.map((key, value) => MapEntry(key, value as int));
    }
  }
  
  Future<void> _saveAchievements() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = jsonEncode(_achievements.map((a) => a.toJson()).toList());
    await prefs.setString(_achievementsKey, jsonStr);
  }
  
  Future<void> _saveProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = jsonEncode(_progress);
    await prefs.setString(_progressKey, jsonStr);
  }
  
  List<Achievement> get allAchievements => List.unmodifiable(_achievements);
  List<Achievement> get unlockedAchievements => 
      _achievements.where((a) => a.isUnlocked).toList();
  List<Achievement> get lockedAchievements => 
      _achievements.where((a) => !a.isUnlocked).toList();
  
  int get totalUnlocked => unlockedAchievements.length;
  int get totalAchievements => _achievements.length;
  double get completionPercentage => 
      totalAchievements > 0 ? totalUnlocked / totalAchievements : 0.0;
  
  Future<List<Achievement>> checkTaskCompletion(HappinessTask task) async {
    final newlyUnlocked = <Achievement>[];
    
    // 检查分类专精成就
    final categoryKey = 'category_${task.category}';
    _progress[categoryKey] = (_progress[categoryKey] ?? 0) + 1;
    
    for (final achievement in _achievements) {
      if (achievement.isUnlocked) continue;
      
      bool shouldUnlock = false;
      int currentProgress = 0;
      
      switch (achievement.type) {
        case AchievementType.category:
          final targetCategory = achievement.metadata?['category'];
          if (targetCategory == task.category) {
            currentProgress = _progress[categoryKey] ?? 0;
            shouldUnlock = currentProgress >= achievement.requiredValue;
          }
          break;
        case AchievementType.special:
          if (achievement.id == 'special_first_gift') {
            shouldUnlock = true;
          }
          break;
        default:
          break;
      }
      
      if (shouldUnlock) {
        final unlockedAchievement = achievement.copyWith(
          isUnlocked: true,
          unlockedAt: DateTime.now(),
          currentProgress: achievement.requiredValue,
        );
        
        final index = _achievements.indexOf(achievement);
        _achievements[index] = unlockedAchievement;
        newlyUnlocked.add(unlockedAchievement);
      } else if (currentProgress > achievement.currentProgress) {
        // 更新进度
        final updatedAchievement = achievement.copyWith(
          currentProgress: currentProgress,
        );
        final index = _achievements.indexOf(achievement);
        _achievements[index] = updatedAchievement;
      }
    }
    
    if (newlyUnlocked.isNotEmpty) {
      await _saveAchievements();
    }
    await _saveProgress();
    
    return newlyUnlocked;
  }
  
  Future<List<Achievement>> checkStreakAchievements(int currentStreak) async {
    final newlyUnlocked = <Achievement>[];
    
    for (final achievement in _achievements) {
      if (achievement.isUnlocked || achievement.type != AchievementType.streak) {
        continue;
      }
      
      if (currentStreak >= achievement.requiredValue) {
        final unlockedAchievement = achievement.copyWith(
          isUnlocked: true,
          unlockedAt: DateTime.now(),
          currentProgress: achievement.requiredValue,
        );
        
        final index = _achievements.indexOf(achievement);
        _achievements[index] = unlockedAchievement;
        newlyUnlocked.add(unlockedAchievement);
      } else {
        // 更新进度
        final updatedAchievement = achievement.copyWith(
          currentProgress: currentStreak,
        );
        final index = _achievements.indexOf(achievement);
        _achievements[index] = updatedAchievement;
      }
    }
    
    if (newlyUnlocked.isNotEmpty) {
      await _saveAchievements();
    }
    
    return newlyUnlocked;
  }
  
  Future<List<Achievement>> checkMilestoneAchievements(int totalCompleted) async {
    final newlyUnlocked = <Achievement>[];
    
    for (final achievement in _achievements) {
      if (achievement.isUnlocked || achievement.type != AchievementType.milestone) {
        continue;
      }
      
      if (totalCompleted >= achievement.requiredValue) {
        final unlockedAchievement = achievement.copyWith(
          isUnlocked: true,
          unlockedAt: DateTime.now(),
          currentProgress: achievement.requiredValue,
        );
        
        final index = _achievements.indexOf(achievement);
        _achievements[index] = unlockedAchievement;
        newlyUnlocked.add(unlockedAchievement);
      } else {
        // 更新进度
        final updatedAchievement = achievement.copyWith(
          currentProgress: totalCompleted,
        );
        final index = _achievements.indexOf(achievement);
        _achievements[index] = updatedAchievement;
      }
    }
    
    if (newlyUnlocked.isNotEmpty) {
      await _saveAchievements();
    }
    
    return newlyUnlocked;
  }
  
  Future<Achievement?> checkFirstGiftAchievement() async {
    final achievement = _achievements.firstWhere(
      (a) => a.id == 'special_first_gift',
      orElse: () => Achievement(
        id: '',
        title: '',
        description: '',
        emoji: '',
        type: AchievementType.special,
        tier: AchievementTier.bronze,
        requiredValue: 0,
      ),
    );
    
    if (achievement.id.isNotEmpty && !achievement.isUnlocked) {
      final unlockedAchievement = achievement.copyWith(
        isUnlocked: true,
        unlockedAt: DateTime.now(),
        currentProgress: 1,
      );
      
      final index = _achievements.indexOf(achievement);
      _achievements[index] = unlockedAchievement;
      await _saveAchievements();
      
      return unlockedAchievement;
    }
    
    return null;
  }
  
  List<Achievement> getAchievementsByType(AchievementType type) {
    return _achievements.where((a) => a.type == type).toList();
  }
  
  List<Achievement> getRecentlyUnlocked({int days = 7}) {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    return unlockedAchievements
        .where((a) => a.unlockedAt != null && a.unlockedAt!.isAfter(cutoff))
        .toList()
      ..sort((a, b) => b.unlockedAt!.compareTo(a.unlockedAt!));
  }
  
  Map<AchievementTier, int> getTierDistribution() {
    final distribution = <AchievementTier, int>{};
    
    for (final achievement in unlockedAchievements) {
      distribution[achievement.tier] = (distribution[achievement.tier] ?? 0) + 1;
    }
    
    return distribution;
  }
}
