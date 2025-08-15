import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/user_preferences_service.dart';

class AIPrefsScreen extends StatefulWidget {
  static const routeName = '/ai_prefs';
  const AIPrefsScreen({super.key});
  @override
  State<AIPrefsScreen> createState() => _AIPrefsScreenState();
}

class _AIPrefsScreenState extends State<AIPrefsScreen> {
  String _tone = 'auto';
  int _advice = 50;
  String _lang = 'auto';
  String _ctx = 'medium';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final tone = await UserPreferencesService.getTone();
    final advice = await UserPreferencesService.getAdviceRatio();
    final lang = await UserPreferencesService.getLang();
    final ctx = await UserPreferencesService.getContextWindow();
    if (!mounted) return;
    setState(() {
      _tone = tone;
      _advice = advice;
      _lang = lang;
      _ctx = ctx;
      _loading = false;
    });
  }

  Future<void> _save() async {
    await UserPreferencesService.setTone(_tone);
    await UserPreferencesService.setAdviceRatio(_advice);
    await UserPreferencesService.setLang(_lang);
    await UserPreferencesService.setContextWindow(_ctx);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已保存AI偏好')));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI 偏好设置')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(AppTheme.spacingLarge),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _section('语气', DropdownButton<String>(
                    value: _tone,
                    items: const [
                      DropdownMenuItem(value: 'auto', child: Text('自动')),
                      DropdownMenuItem(value: 'cute', child: Text('可爱')),
                      DropdownMenuItem(value: 'cool', child: Text('高冷')),
                      DropdownMenuItem(value: 'funny', child: Text('搞笑')),
                      DropdownMenuItem(value: 'gentle', child: Text('温柔')),
                      DropdownMenuItem(value: 'rational', child: Text('理性')),
                      DropdownMenuItem(value: 'literary', child: Text('文艺')),
                    ],
                    onChanged: (v) => setState(() => _tone = v ?? 'auto'),
                    underline: const SizedBox.shrink(),
                  )),
                  const SizedBox(height: 12),
                  _section('建议比例（%）', Row(children: [
                    Expanded(
                      child: Slider(
                        value: _advice.toDouble(),
                        min: 0,
                        max: 100,
                        divisions: 10,
                        label: '$_advice%',
                        onChanged: (v) => setState(() => _advice = v.toInt()),
                      ),
                    ),
                    SizedBox(width: 48, child: Text('$_advice%'))
                  ])),
                  const SizedBox(height: 12),
                  _section('语言', DropdownButton<String>(
                    value: _lang,
                    items: const [
                      DropdownMenuItem(value: 'auto', child: Text('自动')),
                      DropdownMenuItem(value: 'zh', child: Text('中文')),
                      DropdownMenuItem(value: 'en', child: Text('英文')),
                    ],
                    onChanged: (v) => setState(() => _lang = v ?? 'auto'),
                    underline: const SizedBox.shrink(),
                  )),
                  const SizedBox(height: 12),
                  _section('上下文窗口', DropdownButton<String>(
                    value: _ctx,
                    items: const [
                      DropdownMenuItem(value: 'short', child: Text('短')),
                      DropdownMenuItem(value: 'medium', child: Text('中')),
                      DropdownMenuItem(value: 'long', child: Text('长')),
                    ],
                    onChanged: (v) => setState(() => _ctx = v ?? 'medium'),
                    underline: const SizedBox.shrink(),
                  )),
                  const Spacer(),
                  Row(
                    children: [
                      OutlinedButton(
                        onPressed: () => setState(() {
                          _tone = 'auto';
                          _advice = 50;
                          _lang = 'auto';
                          _ctx = 'medium';
                        }),
                        child: const Text('恢复默认'),
                      ),
                      const Spacer(),
                      ElevatedButton.icon(
                        onPressed: _save,
                        icon: const Icon(Icons.save),
                        label: const Text('保存'),
                      ),
                    ],
                  )
                ],
              ),
            ),
    );
  }

  Widget _section(String title, Widget child) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spacingLarge),
      margin: const EdgeInsets.only(bottom: AppTheme.spacingMedium),
      decoration: AppTheme.handDrawnCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

