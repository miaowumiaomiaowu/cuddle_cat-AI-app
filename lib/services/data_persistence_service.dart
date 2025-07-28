import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';

/// 数据持久化服务 - 统一管理所有数据的存储和恢复
class DataPersistenceService {
  // 单例模式
  static DataPersistenceService? _instance;

  // 私有构造函数
  DataPersistenceService._internal();

  // 获取单例实例
  static DataPersistenceService getInstance() {
    _instance ??= DataPersistenceService._internal();
    return _instance!;
  }

  // 工厂构造函数（保持向后兼容）
  factory DataPersistenceService() => getInstance();

  // SharedPreferences实例缓存
  SharedPreferences? _prefs;

  // 初始化状态标记
  bool _isInitialized = false;
  bool _isInitializing = false;

  // 数据键常量
  static const String _catDataKey = 'cat_data';
  static const String _travelRecordsKey = 'travel_records';
  static const String _dialogueSessionsKey = 'dialogue_sessions';
  static const String _appStateKey = 'app_state';
  static const String _userPreferencesKey = 'user_preferences';
  static const String _backupMetadataKey = 'backup_metadata';

  // 备份相关常量
  static const String _backupFileName = 'cuddle_cat_backup.json';
  static const int _maxBackupFiles = 5;
  static const Duration _autoBackupInterval = Duration(hours: 24);

  /// 初始化服务
  Future<void> initialize() async {
    // 如果已经初始化，直接返回
    if (_isInitialized) {
      return;
    }

    // 如果正在初始化，等待完成
    if (_isInitializing) {
      while (_isInitializing && !_isInitialized) {
        await Future.delayed(const Duration(milliseconds: 10));
      }
      return;
    }

    _isInitializing = true;

    try {
      _prefs = await SharedPreferences.getInstance();
      await _performAutoBackupIfNeeded();
      _isInitialized = true;
      debugPrint('DataPersistenceService: 初始化成功');
    } catch (e) {
      debugPrint('DataPersistenceService: 初始化失败 - $e');
      rethrow;
    } finally {
      _isInitializing = false;
    }
  }

  /// 获取SharedPreferences实例
  Future<SharedPreferences> get prefs async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  /// 保存数据到SharedPreferences
  Future<bool> saveData(String key, dynamic value) async {
    try {
      final preferences = await prefs;

      if (value == null) {
        return await preferences.remove(key);
      }

      if (value is String) {
        return await preferences.setString(key, value);
      } else if (value is int) {
        return await preferences.setInt(key, value);
      } else if (value is double) {
        return await preferences.setDouble(key, value);
      } else if (value is bool) {
        return await preferences.setBool(key, value);
      } else if (value is List<String>) {
        return await preferences.setStringList(key, value);
      } else {
        // 对于复杂对象，转换为JSON字符串
        final jsonString = jsonEncode(value);
        return await preferences.setString(key, jsonString);
      }
    } catch (e) {
      debugPrint('DataPersistenceService: 保存数据失败 [$key] - $e');
      return false;
    }
  }

  /// 从SharedPreferences读取数据
  Future<T?> loadData<T>(String key, {T? defaultValue}) async {
    try {
      final preferences = await prefs;

      if (!preferences.containsKey(key)) {
        return defaultValue;
      }

      final value = preferences.get(key);

      if (value is T) {
        return value;
      } else if (T == String && value is String) {
        return value as T;
      } else if (value is String) {
        // 尝试解析JSON
        try {
          final decoded = jsonDecode(value);
          return decoded as T?;
        } catch (e) {
          debugPrint('DataPersistenceService: JSON解析失败 [$key] - $e');
          return defaultValue;
        }
      }

      return defaultValue;
    } catch (e) {
      debugPrint('DataPersistenceService: 读取数据失败 [$key] - $e');
      return defaultValue;
    }
  }

  /// 批量保存数据
  Future<bool> saveBatchData(Map<String, dynamic> data) async {
    try {
      final preferences = await prefs;

      for (final entry in data.entries) {
        final key = entry.key;
        final value = entry.value;

        if (value == null) {
          await preferences.remove(key);
        } else if (value is String) {
          await preferences.setString(key, value);
        } else if (value is int) {
          await preferences.setInt(key, value);
        } else if (value is double) {
          await preferences.setDouble(key, value);
        } else if (value is bool) {
          await preferences.setBool(key, value);
        } else if (value is List<String>) {
          await preferences.setStringList(key, value);
        } else {
          final jsonString = jsonEncode(value);
          await preferences.setString(key, jsonString);
        }
      }

      return true;
    } catch (e) {
      debugPrint('DataPersistenceService: 批量保存数据失败 - $e');
      return false;
    }
  }

  /// 删除数据
  Future<bool> removeData(String key) async {
    try {
      final preferences = await prefs;
      return await preferences.remove(key);
    } catch (e) {
      debugPrint('DataPersistenceService: 删除数据失败 [$key] - $e');
      return false;
    }
  }

  /// 清除所有数据
  Future<bool> clearAllData() async {
    try {
      final preferences = await prefs;
      return await preferences.clear();
    } catch (e) {
      debugPrint('DataPersistenceService: 清除所有数据失败 - $e');
      return false;
    }
  }

  /// 获取所有存储的键
  Future<Set<String>> getAllKeys() async {
    try {
      final preferences = await prefs;
      return preferences.getKeys();
    } catch (e) {
      debugPrint('DataPersistenceService: 获取所有键失败 - $e');
      return <String>{};
    }
  }

  /// 检查键是否存在
  Future<bool> containsKey(String key) async {
    try {
      final preferences = await prefs;
      return preferences.containsKey(key);
    } catch (e) {
      debugPrint('DataPersistenceService: 检查键存在失败 [$key] - $e');
      return false;
    }
  }

  /// 创建数据备份
  Future<bool> createBackup() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final backupDir = Directory('${directory.path}/backups');

      if (!await backupDir.exists()) {
        await backupDir.create(recursive: true);
      }

      // 获取所有数据
      final preferences = await prefs;
      final allKeys = preferences.getKeys();
      final backupData = <String, dynamic>{};

      for (final key in allKeys) {
        backupData[key] = preferences.get(key);
      }

      // 添加备份元数据
      final metadata = {
        'timestamp': DateTime.now().toIso8601String(),
        'version': '1.0.0',
        'dataKeys': allKeys.toList(),
      };

      final fullBackup = {
        'metadata': metadata,
        'data': backupData,
      };

      // 生成备份文件名（包含时间戳）
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final backupFile = File('${backupDir.path}/backup_$timestamp.json');

      await backupFile.writeAsString(jsonEncode(fullBackup));

      // 清理旧备份文件
      await _cleanupOldBackups(backupDir);

      // 更新备份元数据
      await _updateBackupMetadata(backupFile.path);

      debugPrint('DataPersistenceService: 备份创建成功 - ${backupFile.path}');
      return true;
    } catch (e) {
      debugPrint('DataPersistenceService: 创建备份失败 - $e');
      return false;
    }
  }

  /// 从备份恢复数据
  Future<bool> restoreFromBackup([String? backupPath]) async {
    try {
      File? backupFile;

      if (backupPath != null) {
        backupFile = File(backupPath);
      } else {
        // 使用最新的备份文件
        backupFile = await _getLatestBackupFile();
      }

      if (backupFile == null || !await backupFile.exists()) {
        debugPrint('DataPersistenceService: 备份文件不存在');
        return false;
      }

      final backupContent = await backupFile.readAsString();
      final backupData = jsonDecode(backupContent);

      if (!backupData.containsKey('data')) {
        debugPrint('DataPersistenceService: 备份文件格式无效');
        return false;
      }

      // 清除现有数据
      await clearAllData();

      // 恢复数据
      final data = backupData['data'] as Map<String, dynamic>;
      await saveBatchData(data);

      debugPrint('DataPersistenceService: 数据恢复成功');
      return true;
    } catch (e) {
      debugPrint('DataPersistenceService: 数据恢复失败 - $e');
      return false;
    }
  }

  /// 获取备份文件列表
  Future<List<File>> getBackupFiles() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final backupDir = Directory('${directory.path}/backups');

      if (!await backupDir.exists()) {
        return [];
      }

      final files = await backupDir.list().toList();
      final backupFiles = files
          .whereType<File>()
          .where((file) => file.path.endsWith('.json'))
          .toList();

      // 按修改时间排序（最新的在前）
      backupFiles
          .sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));

      return backupFiles;
    } catch (e) {
      debugPrint('DataPersistenceService: 获取备份文件列表失败 - $e');
      return [];
    }
  }

  /// 删除备份文件
  Future<bool> deleteBackup(String backupPath) async {
    try {
      final file = File(backupPath);
      if (await file.exists()) {
        await file.delete();
        debugPrint('DataPersistenceService: 备份文件删除成功 - $backupPath');
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('DataPersistenceService: 删除备份文件失败 - $e');
      return false;
    }
  }

  /// 自动备份检查
  Future<void> _performAutoBackupIfNeeded() async {
    try {
      final lastBackupTime = await loadData<String>(_backupMetadataKey);

      if (lastBackupTime == null) {
        // 首次运行，创建备份
        await createBackup();
        return;
      }

      final lastBackup = DateTime.parse(lastBackupTime);
      final now = DateTime.now();

      if (now.difference(lastBackup) >= _autoBackupInterval) {
        await createBackup();
      }
    } catch (e) {
      debugPrint('DataPersistenceService: 自动备份检查失败 - $e');
    }
  }

  /// 清理旧备份文件
  Future<void> _cleanupOldBackups(Directory backupDir) async {
    try {
      final files = await backupDir.list().toList();
      final backupFiles = files
          .whereType<File>()
          .where((file) => file.path.endsWith('.json'))
          .toList();

      if (backupFiles.length <= _maxBackupFiles) {
        return;
      }

      // 按修改时间排序
      backupFiles
          .sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));

      // 删除多余的备份文件
      for (int i = _maxBackupFiles; i < backupFiles.length; i++) {
        await backupFiles[i].delete();
        debugPrint('DataPersistenceService: 删除旧备份文件 - ${backupFiles[i].path}');
      }
    } catch (e) {
      debugPrint('DataPersistenceService: 清理旧备份失败 - $e');
    }
  }

  /// 更新备份元数据
  Future<void> _updateBackupMetadata(String backupPath) async {
    await saveData(_backupMetadataKey, DateTime.now().toIso8601String());
  }

  /// 获取最新的备份文件
  Future<File?> _getLatestBackupFile() async {
    final backupFiles = await getBackupFiles();
    return backupFiles.isNotEmpty ? backupFiles.first : null;
  }

  /// 数据验证和修复
  Future<bool> validateAndRepairData() async {
    try {
      bool needsRepair = false;

      // 验证猫咪数据
      final catData = await loadData<Map<String, dynamic>>(_catDataKey);
      if (catData != null) {
        if (!_validateCatData(catData)) {
          debugPrint('DataPersistenceService: 猫咪数据损坏，尝试修复');
          final repairedCatData = _repairCatData(catData);
          await saveData(_catDataKey, repairedCatData);
          needsRepair = true;
        }
      }

      // 验证旅行记录数据
      final travelData = await loadData<List<dynamic>>(_travelRecordsKey);
      if (travelData != null) {
        final repairedTravelData = _repairTravelData(travelData);
        if (repairedTravelData.length != travelData.length) {
          await saveData(_travelRecordsKey, repairedTravelData);
          needsRepair = true;
        }
      }

      // 验证对话数据
      final dialogueData = await loadData<List<dynamic>>(_dialogueSessionsKey);
      if (dialogueData != null) {
        final repairedDialogueData = _repairDialogueData(dialogueData);
        if (repairedDialogueData.length != dialogueData.length) {
          await saveData(_dialogueSessionsKey, repairedDialogueData);
          needsRepair = true;
        }
      }

      if (needsRepair) {
        debugPrint('DataPersistenceService: 数据修复完成');
      }

      return true;
    } catch (e) {
      debugPrint('DataPersistenceService: 数据验证和修复失败 - $e');
      return false;
    }
  }

  /// 验证猫咪数据
  bool _validateCatData(Map<String, dynamic> data) {
    final requiredFields = [
      'name',
      'breed',
      'mood',
      'energyLevel',
      'happiness'
    ];
    return requiredFields.every((field) => data.containsKey(field));
  }

  /// 修复猫咪数据
  Map<String, dynamic> _repairCatData(Map<String, dynamic> data) {
    final repaired = Map<String, dynamic>.from(data);

    // 设置默认值
    repaired['name'] ??= '小猫';
    repaired['breed'] ??= 'random';
    repaired['mood'] ??= 'normal';
    repaired['energyLevel'] ??= 100;
    repaired['happiness'] ??= 50;
    repaired['adoptionDate'] ??= DateTime.now().toIso8601String();

    // 确保数值在有效范围内
    repaired['energyLevel'] = (repaired['energyLevel'] as int).clamp(0, 100);
    repaired['happiness'] = (repaired['happiness'] as int).clamp(0, 100);

    return repaired;
  }

  /// 修复旅行记录数据
  List<dynamic> _repairTravelData(List<dynamic> data) {
    return data.where((item) {
      if (item is! Map<String, dynamic>) return false;

      final requiredFields = [
        'id',
        'title',
        'locationName',
        'latitude',
        'longitude'
      ];
      return requiredFields.every((field) => item.containsKey(field));
    }).toList();
  }

  /// 修复对话数据
  List<dynamic> _repairDialogueData(List<dynamic> data) {
    return data.where((item) {
      if (item is! Map<String, dynamic>) return false;

      final requiredFields = ['id', 'startTime', 'messages'];
      return requiredFields.every((field) => item.containsKey(field));
    }).toList();
  }

  /// 获取数据存储统计信息
  Future<Map<String, dynamic>> getStorageStats() async {
    try {
      final preferences = await prefs;
      final keys = preferences.getKeys();

      int totalSize = 0;
      final keyStats = <String, int>{};

      for (final key in keys) {
        final value = preferences.get(key);
        int size = 0;

        if (value is String) {
          size = value.length;
        } else if (value != null) {
          size = value.toString().length;
        }

        keyStats[key] = size;
        totalSize += size;
      }

      return {
        'totalKeys': keys.length,
        'totalSize': totalSize,
        'keyStats': keyStats,
        'backupFiles': (await getBackupFiles()).length,
      };
    } catch (e) {
      debugPrint('DataPersistenceService: 获取存储统计失败 - $e');
      return {};
    }
  }
}
