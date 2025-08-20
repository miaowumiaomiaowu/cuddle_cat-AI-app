import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

import 'package:provider/provider.dart';
import '../services/provider_manager.dart';
import '../utils/persistence_monitor.dart';
import '../ui/app_card.dart';

/// 数据调试屏幕 - 用于监控和调试数据持久化系统
class DataDebugScreen extends StatefulWidget {
  static const String routeName = '/data_debug';

  const DataDebugScreen({super.key});

  @override
  State<DataDebugScreen> createState() => _DataDebugScreenState();
}

class _DataDebugScreenState extends State<DataDebugScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final PersistenceMonitor _monitor = PersistenceMonitor();

  Map<String, dynamic>? _monitoringReport;
  Map<String, dynamic>? _performanceStats;
  Map<String, dynamic>? _providersStats;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _monitor.startMonitoring();
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final providerManager =
          Provider.of<ProviderManager>(context, listen: false);

      final results = await Future.wait([
        _monitor.getMonitoringReport(),
        Future.value(_monitor.getPerformanceStats()),
        Future.value(providerManager.getProvidersStats()),
      ]);

      if (!mounted) return;
      setState(() {
        _monitoringReport = results[0];
        _performanceStats = results[1];
        _providersStats = results[2];
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('加载数据失败: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('数据调试'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
          PopupMenuButton<String>(
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'backup', child: Text('创建备份')),
              const PopupMenuItem(value: 'restore', child: Text('恢复备份')),
              const PopupMenuItem(value: 'clear_events', child: Text('清除事件')),
              const PopupMenuItem(value: 'export', child: Text('导出数据')),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: '监控'),
            Tab(text: '性能'),
            Tab(text: 'Provider'),
            Tab(text: '事件'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildMonitoringTab(),
                _buildPerformanceTab(),
                _buildProvidersTab(),
                _buildEventsTab(),
              ],
            ),
    );
  }

  Widget _buildMonitoringTab() {
    if (_monitoringReport == null) {
      return const Center(child: Text('暂无监控数据'));
    }

    final monitoring =
        _monitoringReport!['monitoring'] as Map<String, dynamic>? ?? {};
    final storage =
        _monitoringReport!['storage'] as Map<String, dynamic>? ?? {};
    final backups =
        _monitoringReport!['backups'] as Map<String, dynamic>? ?? {};

    return Container(
      decoration: const BoxDecoration(
        gradient: AppTheme.mistSkyGradient,
      ),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('监控状态', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                _buildInfoRow('监控状态', monitoring['isActive'] == true ? '运行中' : '已停止'),
                _buildInfoRow('总事件数', '${monitoring['totalEvents'] ?? 0}'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('存储信息', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                _buildInfoRow('总键数', '${storage['totalKeys'] ?? 0}'),
                _buildInfoRow('存储大小', _formatBytes(storage['totalSize'] as int? ?? 0)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('备份信息', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                _buildInfoRow('备份文件数', '${backups['count'] ?? 0}'),
              ],
            ),
          ),
          if (backups['files'] != null) ...[
            const SizedBox(height: 16),
            _buildBackupsList(backups['files'] as List),
          ],
        ],
      ),
    );
  }

  Widget _buildPerformanceTab() {
    if (_performanceStats == null || _performanceStats!.isEmpty) {
      return const Center(child: Text('暂无性能数据'));
    }

    return Container(
      decoration: const BoxDecoration(
        gradient: AppTheme.mistSkyGradient,
      ),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: _performanceStats!.entries.map((entry) {
          final stats = entry.value as Map<String, dynamic>;
          return AppCard(
            margin: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.key, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                _buildInfoRow('调用次数', '${stats['count']}'),
                _buildInfoRow('平均耗时', '${stats['avgMs']}ms'),
                _buildInfoRow('最大耗时', '${stats['maxMs']}ms'),
                _buildInfoRow('最小耗时', '${stats['minMs']}ms'),
                _buildInfoRow('总耗时', '${stats['totalMs']}ms'),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildProvidersTab() {
    if (_providersStats == null) {
      return const Center(child: Text('暂无Provider数据'));
    }

    final providers =
        _providersStats!['providers'] as Map<String, dynamic>? ?? {};

    return Container(
      decoration: const BoxDecoration(
        gradient: AppTheme.mistSkyGradient,
      ),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('总览', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                _buildInfoRow('Provider总数', '${_providersStats!['totalProviders'] ?? 0}'),
                _buildInfoRow('初始化状态', _providersStats!['isInitialized'] == true ? '已初始化' : '未初始化'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ...providers.entries.map((entry) {
            final stats = entry.value as Map<String, dynamic>;
            return AppCard(
              margin: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(entry.key, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  _buildInfoRow('初始化状态', stats['isInitialized'] == true ? '已初始化' : '未初始化'),
                  _buildInfoRow('加载状态', stats['isLoading'] == true ? '加载中' : '空闲'),
                  _buildInfoRow('错误状态', stats['hasError'] == true ? '有错误' : '正常'),
                  _buildInfoRow('通知次数', '${stats['notificationCount'] ?? 0}'),
                  if (stats['hasError'] == true && stats['errorMessage'] != null)
                    _buildInfoRow('错误信息', stats['errorMessage']),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildEventsTab() {
    final events = _monitor.events;

    if (events.isEmpty) {
      return const Center(child: Text('暂无事件记录'));
    }

    return Container(
      decoration: const BoxDecoration(
        gradient: AppTheme.mistSkyGradient,
      ),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: events.length,
        itemBuilder: (context, index) {
          final event = events[events.length - 1 - index]; // 倒序显示
          return AppCard(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: _getEventIcon(event.type),
              title: Text(event.message),
              subtitle: Text(_formatDateTime(event.timestamp)),
              dense: true,
            ),
          );
        },
      ),
    );
  }



  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildBackupsList(List backupFiles) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '备份文件',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...backupFiles.map((file) {
              final fileName = (file['path'] as String).split('/').last;
              final size = _formatBytes(file['size'] as int);
              final modified = DateTime.parse(file['modified'] as String);

              return ListTile(
                dense: true,
                title: Text(fileName),
                subtitle: Text('$size - ${_formatDateTime(modified)}'),
                trailing: IconButton(
                  icon: const Icon(Icons.restore),
                  onPressed: () => _restoreFromBackup(file['path'] as String),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _getEventIcon(PersistenceEventType type) {
    switch (type) {
      case PersistenceEventType.error:
        return const Text('❌', style: TextStyle(fontSize: 16));
      case PersistenceEventType.warning:
        return const Text('⚠️', style: TextStyle(fontSize: 16));
      case PersistenceEventType.performance:
        return const Text('⚡', style: TextStyle(fontSize: 16));
      case PersistenceEventType.backup:
        return const Text('💾', style: TextStyle(fontSize: 16));
      case PersistenceEventType.dataOperation:
        return const Text('📊', style: TextStyle(fontSize: 16));
      default:
        return const Text('ℹ️', style: TextStyle(fontSize: 16));
    }
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.month}/${dateTime.day} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _handleMenuAction(String action) async {
    final providerManager =
        Provider.of<ProviderManager>(context, listen: false);

    switch (action) {
      case 'backup':
        final success = await providerManager.createBackup();
        if (!mounted) return;
        _showMessage(success ? '备份创建成功' : '备份创建失败');
        if (success) _loadData();
        break;

      case 'restore':
        final success = await providerManager.restoreFromBackup();
        if (!mounted) return;
        _showMessage(success ? '数据恢复成功' : '数据恢复失败');
        if (success) _loadData();
        break;

      case 'clear_events':
        _monitor.clearEvents();
        _showMessage('事件记录已清除');
        setState(() {});
        break;

      case 'export':
        final data = await _monitor.exportMonitoringData();
        _showExportDialog(data);
        break;
    }
  }

  Future<void> _restoreFromBackup(String backupPath) async {
    final confirmed = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'dialog',
      transitionDuration: AppTheme.motionMedium,
      pageBuilder: (ctx, _, __) => const SizedBox.shrink(),
      transitionBuilder: (ctx, anim, sec, child) {
        final curved = CurvedAnimation(parent: anim, curve: AppTheme.easeStandard);
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.98, end: 1.0).animate(curved),
            child: AlertDialog(
              title: const Text('确认恢复'),
              content: const Text('确定要从此备份恢复数据吗？这将覆盖当前所有数据。'),
              actions: [
                TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('取消')),
                TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('确认')),
              ],
            ),
          ),
        );
      },
    );

    if (confirmed == true) {
      if (!mounted) return;
      final providerManager = Provider.of<ProviderManager>(context, listen: false);
      final success = await providerManager.restoreFromBackup(backupPath);
      if (!mounted) return;
      _showMessage(success ? '数据恢复成功' : '数据恢复失败');
      if (success) _loadData();
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _showExportDialog(String data) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'dialog',
      transitionDuration: AppTheme.motionMedium,
      pageBuilder: (ctx, _, __) => const SizedBox.shrink(),
      transitionBuilder: (ctx, anim, sec, child) {
        final curved = CurvedAnimation(parent: anim, curve: AppTheme.easeStandard);
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.98, end: 1.0).animate(curved),
            child: AlertDialog(
              title: const Text('导出数据'),
              content: SingleChildScrollView(
                child: SelectableText(data),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('关闭'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

}

