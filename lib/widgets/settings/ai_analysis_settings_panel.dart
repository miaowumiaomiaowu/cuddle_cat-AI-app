import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AIAnalysisSettingsPanel extends StatefulWidget {
  const AIAnalysisSettingsPanel({super.key});

  @override
  State<AIAnalysisSettingsPanel> createState() => _AIAnalysisSettingsPanelState();
}

class _AIAnalysisSettingsPanelState extends State<AIAnalysisSettingsPanel> {
  final _ctrl = TextEditingController();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _ctrl.text = prefs.getString('ai_analysis_base_url') ?? '';
      _loading = false;
    });
  }

  // 保存方法已不再使用，AI 分析由 .env 控制

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          leading: const Icon(Icons.check_circle, color: Colors.green),
          title: const Text('AI 分析模式由 .env 控制'),
          subtitle: const Text('当 ENABLE_REMOTE_BACKEND=true 时，始终使用 HTTP 后端'),
        ),
        TextField(
          controller: _ctrl,
          readOnly: true,
          decoration: const InputDecoration(
            labelText: '分析服务地址（baseUrl）',
            hintText: '由 .env 的 SERVER_BASE_URL/AI_ANALYSIS_BASE_URL 或默认 10.0.2.2:8002 提供',
          ),
        ),
      ],
    );
  }
}

