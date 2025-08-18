import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/user.dart';
import 'config_service.dart';
import 'api/auth_api_client.dart';

/// 认证服务 - 处理用户注册、登录、登出等功能
class AuthService extends ChangeNotifier {
  static const String _userKey = 'current_user';
  static const String _isLoggedInKey = 'is_logged_in';
  static const String _guestModeKey = 'guest_mode';
  static const String _tokenKey = 'auth_token';

  final _api = AuthApiClient();

  User? _currentUser;
  bool _isLoggedIn = false;
  bool _isGuestMode = false;
  bool _isLoading = false;
  String? _error;
  String? _token;

  // Getters
  User? get currentUser => _currentUser;
  bool get isLoggedIn => _isLoggedIn;
  bool get isGuestMode => _isGuestMode;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _isLoggedIn || _isGuestMode;
  String? get token => _token;

  /// 初始化认证服务
  Future<void> initialize() async {
    try {
      _setLoading(true);
      _clearError();

      final prefs = await SharedPreferences.getInstance();
      
      // 检查登录状态
      _isLoggedIn = prefs.getBool(_isLoggedInKey) ?? false;
      _isGuestMode = prefs.getBool(_guestModeKey) ?? false;

      // 如果已登录，加载用户信息
      if (_isLoggedIn) {
        final userJson = prefs.getString(_userKey);
        if (userJson != null) {
          _currentUser = User.fromJson(jsonDecode(userJson));
          // 更新最后登录时间
          await _updateLastLoginTime();
        } else {
          // 用户数据丢失，重置登录状态
          await logout();
        }
      } else if (_isGuestMode) {
        // 游客模式：优先恢复持久化的游客用户；若不存在则创建并持久化一个稳定的游客ID
        final userJson = prefs.getString(_userKey);
        if (userJson != null) {
          _currentUser = User.fromJson(jsonDecode(userJson));
        } else {
          _currentUser = _createGuestUser();
          await _saveUser(_currentUser!);
        }
      }

      debugPrint('认证服务初始化完成 - 登录状态: $_isLoggedIn, 游客模式: $_isGuestMode');
    } catch (e) {
      _setError('初始化认证服务失败: $e');
      debugPrint('认证服务初始化失败: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// 用户注册（根据开关决定走本地还是远端）
  Future<bool> register({
    required String username,
    required String email,
    required String password,
    String? phone,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      if (username.isEmpty || email.isEmpty || password.isEmpty) {
        throw Exception('用户名、邮箱和密码不能为空');
      }
      if (!_isValidEmail(email)) {
        throw Exception('邮箱格式不正确');
      }
      if (password.length < 6) {
        throw Exception('密码长度不能少于6位');
      }

      final useRemote = ConfigService.instance.isRemoteConfigured;
      if (useRemote) {
        final resp = await _api.register(email: email, username: username, password: password);
        final now = DateTime.now();
        final newUser = User(
          id: resp['id'] as String,
          username: resp['username'] as String? ?? username,
          email: resp['email'] as String? ?? email,
          phone: phone,
          settings: UserSettings(
            reminderSettings: ReminderSettings(),
            privacySettings: PrivacySettings(),
          ),
          createdAt: now,
          lastLoginAt: now,
          stats: UserStats(),
        );
        await _saveUser(newUser);
        _currentUser = newUser;
        _isLoggedIn = true;
        _isGuestMode = false;
        await _saveAuthState();
        debugPrint('用户注册成功(远端): ${newUser.username}');
        notifyListeners();
        return true;
      }

      // 本地模式（原逻辑）
      final now = DateTime.now();
      final newUser = User(
        id: _generateUserId(),
        username: username,
        email: email,
        phone: phone,
        settings: UserSettings(
          reminderSettings: ReminderSettings(),
          privacySettings: PrivacySettings(),
        ),
        createdAt: now,
        lastLoginAt: now,
        stats: UserStats(),
      );
      await _saveUser(newUser);
      _currentUser = newUser;
      _isLoggedIn = true;
      _isGuestMode = false;
      await _saveAuthState();
      debugPrint('用户注册成功(本地): ${newUser.username}');
      notifyListeners();
      return true;
    } catch (e) {
      _setError('注册失败: $e');
      debugPrint('用户注册失败: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// 用户登录（根据开关决定走本地还是远端）
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      if (email.isEmpty || password.isEmpty) {
        throw Exception('邮箱和密码不能为空');
      }
      if (!_isValidEmail(email)) {
        throw Exception('邮箱格式不正确');
      }

      final useRemote = ConfigService.instance.isRemoteConfigured;
      if (useRemote) {
        final resp = await _api.login(email: email, password: password);
        final userData = resp['user'] as Map<String, dynamic>;
        final now = DateTime.now();
        final user = User(
          id: userData['id'] as String,
          username: userData['username'] as String? ?? email,
          email: userData['email'] as String? ?? email,
          settings: UserSettings(
            reminderSettings: ReminderSettings(),
            privacySettings: PrivacySettings(),
          ),
          createdAt: now,
          lastLoginAt: now,
          stats: UserStats(),
        );
        _token = resp['token'] as String?;
        await _saveUser(user);
        await _saveAuthState();
        _currentUser = user;
        _isLoggedIn = true;
        _isGuestMode = false;
        debugPrint('用户登录成功(远端): ${user.username}');
        notifyListeners();
        return true;
      }

      // 本地模式（原逻辑）
      final user = await _getUserByEmail(email);
      if (user == null) {
        throw Exception('用户不存在');
      }
      final updatedUser = user.copyWith(lastLoginAt: DateTime.now());
      await _saveUser(updatedUser);
      _currentUser = updatedUser;
      _isLoggedIn = true;
      _isGuestMode = false;
      await _saveAuthState();
      debugPrint('用户登录成功(本地): ${updatedUser.username}');
      notifyListeners();
      return true;
    } catch (e) {
      _setError('登录失败: $e');
      debugPrint('用户登录失败: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// 游客模式登录
  Future<void> loginAsGuest() async {
    try {
      _setLoading(true);
      _clearError();

      // 如果已经有持久化的游客用户，则沿用；否则创建并保存
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString(_userKey);
      if (userJson != null) {
        _currentUser = User.fromJson(jsonDecode(userJson));
      } else {
        _currentUser = _createGuestUser();
        await _saveUser(_currentUser!);
      }
      _isLoggedIn = false;
      _isGuestMode = true;

      await _saveAuthState();

      debugPrint('进入游客模式');
      notifyListeners();
    } catch (e) {
      _setError('进入游客模式失败: $e');
      debugPrint('进入游客模式失败: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// 用户登出
  Future<void> logout() async {
    try {
      _setLoading(true);
      _clearError();

      _currentUser = null;
      _isLoggedIn = false;
      _isGuestMode = false;

      await _clearAuthState();

      debugPrint('用户登出成功');
      notifyListeners();
    } catch (e) {
      _setError('登出失败: $e');
      debugPrint('用户登出失败: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// 更新用户信息
  Future<bool> updateUser(User updatedUser) async {
    try {
      _setLoading(true);
      _clearError();

      await _saveUser(updatedUser);
      _currentUser = updatedUser;

      debugPrint('用户信息更新成功');
      notifyListeners();
      return true;
    } catch (e) {
      _setError('更新用户信息失败: $e');
      debugPrint('更新用户信息失败: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// 删除账户
  Future<bool> deleteAccount() async {
    try {
      _setLoading(true);
      _clearError();

      if (_currentUser == null) {
        throw Exception('用户未登录');
      }

      // 删除用户数据（实际应该调用后端API）
      await _deleteUserData(_currentUser!.id);
      
      // 登出
      await logout();

      debugPrint('账户删除成功');
      return true;
    } catch (e) {
      _setError('删除账户失败: $e');
      debugPrint('删除账户失败: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// 重置密码
  Future<bool> resetPassword(String email) async {
    try {
      _setLoading(true);
      _clearError();

      if (!_isValidEmail(email)) {
        throw Exception('邮箱格式不正确');
      }

      // 简化实现：实际应该发送重置密码邮件
      debugPrint('密码重置邮件已发送到: $email');
      return true;
    } catch (e) {
      _setError('重置密码失败: $e');
      debugPrint('重置密码失败: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // 私有方法

  /// 保存用户信息
  Future<void> _saveUser(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(user.toJson()));
  }

  /// 保存认证状态
  Future<void> _saveAuthState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isLoggedInKey, _isLoggedIn);
    await prefs.setBool(_guestModeKey, _isGuestMode);
  }

  /// 清除认证状态
  Future<void> _clearAuthState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
    await prefs.remove(_isLoggedInKey);
    await prefs.remove(_guestModeKey);
  }

  /// 更新最后登录时间
  Future<void> _updateLastLoginTime() async {
    if (_currentUser != null) {
      final updatedUser = _currentUser!.copyWith(lastLoginAt: DateTime.now());
      await _saveUser(updatedUser);
      _currentUser = updatedUser;
    }
  }

  /// 创建游客用户
  User _createGuestUser() {
    final now = DateTime.now();
    return User(
      id: 'guest_${now.millisecondsSinceEpoch}',
      username: '游客用户',
      email: 'guest@example.com',
      settings: UserSettings(
        reminderSettings: ReminderSettings(),
        privacySettings: PrivacySettings(),
      ),
      createdAt: now,
      lastLoginAt: now,
      stats: UserStats(),
    );
  }

  /// 生成用户ID
  String _generateUserId() {
    return 'user_${DateTime.now().millisecondsSinceEpoch}';
  }

  /// 验证邮箱格式
  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }


  /// 根据邮箱获取用户（简化实现）
  Future<User?> _getUserByEmail(String email) async {
    // 简化实现：实际应该调用后端API
    // 这里返回null表示用户不存在，实际项目中应该从数据库查询
    return null;
  }

  /// 删除用户数据（简化实现）
  Future<void> _deleteUserData(String userId) async {
    // 简化实现：实际应该调用后端API删除用户数据
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  /// 设置加载状态
  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }

  /// 设置错误信息
  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  /// 清除错误信息
  void _clearError() {
    if (_error != null) {
      _error = null;
      notifyListeners();
    }
  }
}
