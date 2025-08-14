import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AIAnalysisSettingsPanel extends StatefulWidget {
  const AIAnalysisSettingsPanel({super.key});

  @override
  State<AIAnalysisSettingsPanel> createState() => _AIAnalysisSettingsPanelState();
}

class _AIAnalysisSettingsPanelState extends State<AIAnalysisSettingsPanel> {
  bool _enabled = false;
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
      _enabled = prefs.getBool('ai_analysis_enabled') ?? false;
      _ctrl.text = prefs.getString('ai_analysis_base_url') ?? '';
      _loading = false;
    });
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('ai_analysis_enabled', _enabled);
    await prefs.setString('ai_analysis_base_url', _ctrl.text.trim());
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('AI 分析配置已保存')));
  }

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
        SwitchListTile(
          title: const Text('启用 AI 分析（HTTP）'),
          subtitle: const Text('关闭时使用本地 Stub，不调用服务端'),
          value: _enabled,
          onChanged: (v) => setState(() => _enabled = v),
        ),
        TextField(
          controller: _ctrl,
          decoration: const InputDecoration(
            labelText: '分析服务地址（baseUrl）',
            hintText: '例如 http://127.0.0.1:8000',
          ),
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: _save,
          icon: const Icon(Icons.save),
          label: const Text('保存'),
        )
      ],
    );
  }
}

