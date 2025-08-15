import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../services/auth_service.dart';

/// 用户状态管理Provider
class UserProvider extends ChangeNotifier {
  final AuthService _authService;
  
  UserProvider(this._authService) {
    // 监听认证服务的变化
    _authService.addListener(_onAuthStateChanged);
  }

  @override
  void dispose() {
    _authService.removeListener(_onAuthStateChanged);
    super.dispose();
  }

  // Getters - 代理到AuthService
  User? get currentUser => _authService.currentUser;
  bool get isLoggedIn => _authService.isLoggedIn;
  bool get isGuestMode => _authService.isGuestMode;
  bool get isLoading => _authService.isLoading;
  String? get error => _authService.error;
  bool get isAuthenticated => _authService.isAuthenticated;

  /// 初始化
  Future<void> initialize() async {
    await _authService.initialize();
  }

  /// 用户注册
  Future<bool> register({
    required String username,
    required String email,
    required String password,
    String? phone,
  }) async {
    return await _authService.register(
      username: username,
      email: email,
      password: password,
      phone: phone,
    );
  }

  /// 用户登录
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    return await _authService.login(
      email: email,
      password: password,
    );
  }

  /// 游客模式登录
  Future<void> loginAsGuest() async {
    await _authService.loginAsGuest();
  }

  /// 用户登出
  Future<void> logout() async {
    await _authService.logout();
  }

  /// 更新用户信息
  Future<bool> updateUserInfo({
    String? username,
    String? phone,
    String? avatar,
    DateTime? birthday,
    String? bio,
  }) async {
    if (currentUser == null) return false;

    final updatedUser = currentUser!.copyWith(
      username: username,
      phone: phone,
      avatar: avatar,
      birthday: birthday,
      bio: bio,
    );

    return await _authService.updateUser(updatedUser);
  }

  /// 更新用户设置
  Future<bool> updateUserSettings(UserSettings settings) async {
    if (currentUser == null) return false;

    final updatedUser = currentUser!.copyWith(settings: settings);
    return await _authService.updateUser(updatedUser);
  }

  /// 更新用户统计
  Future<bool> updateUserStats(UserStats stats) async {
    if (currentUser == null) return false;

    final updatedUser = currentUser!.copyWith(stats: stats);
    return await _authService.updateUser(updatedUser);
  }

  /// 增加心情记录统计
  Future<void> incrementMoodEntryCount() async {
    if (currentUser == null) return;

    final now = DateTime.now();
    final currentStats = currentUser!.stats;
    
    // 计算连续记录天数
    int consecutiveDays = currentStats.consecutiveDays;
    if (currentStats.lastMoodEntry != null) {
      final lastEntryDate = currentStats.lastMoodEntry!;
      final daysDiff = now.difference(lastEntryDate).inDays;
      
      if (daysDiff == 1) {
        // 连续记录
        consecutiveDays++;
      } else if (daysDiff > 1) {
        // 中断了，重新开始
        consecutiveDays = 1;
      }
      // daysDiff == 0 表示今天已经记录过了，不增加连续天数
    } else {
      // 第一次记录
      consecutiveDays = 1;
    }

    final updatedStats = currentStats.copyWith(
      totalMoodEntries: currentStats.totalMoodEntries + 1,
      consecutiveDays: consecutiveDays,
      longestStreak: consecutiveDays > currentStats.longestStreak 
          ? consecutiveDays 
          : currentStats.longestStreak,
      lastMoodEntry: now,
    );

    await updateUserStats(updatedStats);
  }


  /// 添加成就
  Future<void> addAchievement(String achievementId) async {
    if (currentUser == null) return;

    final currentStats = currentUser!.stats;
    if (currentStats.achievements.contains(achievementId)) {
      return; // 已经有这个成就了
    }

    final updatedAchievements = [...currentStats.achievements, achievementId];
    final updatedStats = currentStats.copyWith(achievements: updatedAchievements);

    await updateUserStats(updatedStats);
  }

  /// 删除账户
  Future<bool> deleteAccount() async {
    return await _authService.deleteAccount();
  }

  /// 重置密码
  Future<bool> resetPassword(String email) async {
    return await _authService.resetPassword(email);
  }

  /// 获取用户显示名称
  String get displayName {
    if (currentUser == null) return '未知用户';
    return currentUser!.username;
  }

  /// 获取用户头像
  String? get userAvatar {
    return currentUser?.avatar;
  }

  /// 是否为新用户
  bool get isNewUser {
    return currentUser?.isNewUser ?? true;
  }

  /// 获取注册天数
  int get daysSinceRegistration {
    return currentUser?.daysSinceRegistration ?? 0;
  }

  /// 获取总记录数
  int get totalRecords {
    if (currentUser == null) return 0;
    return currentUser!.stats.totalMoodEntries;
  }

  /// 获取连续记录天数
  int get consecutiveDays {
    return currentUser?.stats.consecutiveDays ?? 0;
  }

  /// 获取最长连续记录
  int get longestStreak {
    return currentUser?.stats.longestStreak ?? 0;
  }

  /// 获取成就数量
  int get achievementCount {
    return currentUser?.stats.achievements.length ?? 0;
  }

  /// 检查是否有特定成就
  bool hasAchievement(String achievementId) {
    return currentUser?.stats.achievements.contains(achievementId) ?? false;
  }

  /// 获取用户等级（基于记录数量）
  int get userLevel {
    final total = totalRecords;
    if (total < 10) return 1;
    if (total < 50) return 2;
    if (total < 100) return 3;
    if (total < 200) return 4;
    if (total < 500) return 5;
    return 6; // 最高等级
  }

  /// 获取用户等级名称
  String get userLevelName {
    switch (userLevel) {
      case 1:
        return '新手记录者';
      case 2:
        return '记录爱好者';
      case 3:
        return '记录达人';
      case 4:
        return '记录专家';
      case 5:
        return '记录大师';
      case 6:
        return '记录传奇';
      default:
        return '记录者';
    }
  }

  /// 获取下一等级所需记录数
  int get recordsToNextLevel {
    final total = totalRecords;
    switch (userLevel) {
      case 1:
        return 10 - total;
      case 2:
        return 50 - total;
      case 3:
        return 100 - total;
      case 4:
        return 200 - total;
      case 5:
        return 500 - total;
      default:
        return 0; // 已达到最高等级
    }
  }

  /// 获取等级进度（0.0 - 1.0）
  double get levelProgress {
    final total = totalRecords;
    switch (userLevel) {
      case 1:
        return total / 10.0;
      case 2:
        return (total - 10) / 40.0;
      case 3:
        return (total - 50) / 50.0;
      case 4:
        return (total - 100) / 100.0;
      case 5:
        return (total - 200) / 300.0;
      default:
        return 1.0; // 已达到最高等级
    }
  }

  /// 认证状态变化监听
  void _onAuthStateChanged() {
    notifyListeners();
  }

  /// 清除错误信息
  void clearError() {
    // 通过公共方法清除错误
    if (_authService.error != null) {
      // 触发一次状态更新来清除错误
      notifyListeners();
    }
  }
}
