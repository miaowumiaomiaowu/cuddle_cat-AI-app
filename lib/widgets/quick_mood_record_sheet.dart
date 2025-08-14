import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/mood_provider.dart';
import '../models/mood_record.dart';
import '../theme/artistic_theme.dart';
import '../providers/user_provider.dart';

/// 快速心情记录底部弹窗
class QuickMoodRecordSheet extends StatefulWidget {
  const QuickMoodRecordSheet({super.key});

  @override
  State<QuickMoodRecordSheet> createState() => _QuickMoodRecordSheetState();
}

class _QuickMoodRecordSheetState extends State<QuickMoodRecordSheet>
    with TickerProviderStateMixin {

  MoodType? _selectedMood;
  int _intensity = 5;
  final TextEditingController _descriptionController = TextEditingController();
  bool _isSubmitting = false;

  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  final List<MoodType> _quickMoods = [
    MoodType.happy,
    MoodType.sad,
    MoodType.excited,
    MoodType.anxious,
    MoodType.peaceful,
    MoodType.grateful,
  ];

  @override
  void initState() {
    super.initState();

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOut,
    ));

    _slideController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 20),
                _buildMoodSelector(),
                if (_selectedMood != null) ...[
                  const SizedBox(height: 20),
                  _buildIntensitySlider(),
                  const SizedBox(height: 20),
                  _buildDescriptionInput(),
                  const SizedBox(height: 20),
                  _buildActionButtons(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: ArtisticTheme.primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(
            Icons.mood,
            color: ArtisticTheme.primaryColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '记录心情',
                style: ArtisticTheme.headingStyle.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '分享你此刻的感受',
                style: ArtisticTheme.bodyStyle.copyWith(
                  color: ArtisticTheme.textSecondary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close),
          style: IconButton.styleFrom(
            backgroundColor: Colors.grey.withValues(alpha: 0.1),
          ),
        ),
      ],
    );
  }

  Widget _buildMoodSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '你现在的心情如何？',
          style: ArtisticTheme.bodyStyle.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: _quickMoods.map((mood) => _buildMoodChip(mood)).toList(),
        ),
      ],
    );
  }

  Widget _buildMoodChip(MoodType mood) {
    final isSelected = _selectedMood == mood;
    final emoji = MoodTypeConfig.getMoodEmoji(mood);
    final name = MoodTypeConfig.getMoodName(mood);
    final color = MoodTypeConfig.getMoodColor(mood);

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedMood = mood;
        });
        HapticFeedback.lightImpact();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.2) : Colors.grey.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: isSelected ? color : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Text(
              name,
              style: ArtisticTheme.bodyStyle.copyWith(
                color: isSelected ? color : ArtisticTheme.textPrimary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIntensitySlider() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '强度: $_intensity/10',
          style: ArtisticTheme.bodyStyle.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: MoodTypeConfig.getMoodColor(_selectedMood!),
            thumbColor: MoodTypeConfig.getMoodColor(_selectedMood!),
            overlayColor: MoodTypeConfig.getMoodColor(_selectedMood!).withValues(alpha: 0.2),
          ),
          child: Slider(
            value: _intensity.toDouble(),
            min: 1,
            max: 10,
            divisions: 9,
            onChanged: (value) {
              setState(() {
                _intensity = value.round();
              });
              HapticFeedback.selectionClick();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDescriptionInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '想说点什么吗？（可选）',
          style: ArtisticTheme.bodyStyle.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _descriptionController,
          decoration: InputDecoration(
            hintText: '描述一下你的感受...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: MoodTypeConfig.getMoodColor(_selectedMood!)),
            ),
            contentPadding: const EdgeInsets.all(16),
          ),
          maxLines: 3,
          maxLength: 200,
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('取消'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: _isSubmitting ? null : _submitMoodRecord,
            style: ElevatedButton.styleFrom(
              backgroundColor: MoodTypeConfig.getMoodColor(_selectedMood!),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    '记录心情 ${MoodTypeConfig.getMoodEmoji(_selectedMood!)}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
          ),
        ),
      ],
    );
  }

  Future<void> _submitMoodRecord() async {
    if (_selectedMood == null || _isSubmitting) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final moodProvider = Provider.of<MoodProvider>(context, listen: false);

      if (userProvider.currentUser == null) {
        throw Exception('用户未登录');
      }

      final entry = MoodTypeConfig.createMoodEntry(
        userId: userProvider.currentUser!.id,
        moodType: _selectedMood!,
        intensity: _intensity,
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
      );

      await moodProvider.addMoodEntry(entry);

      if (mounted) {
        HapticFeedback.mediumImpact();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '心情记录已保存 ${MoodTypeConfig.getMoodEmoji(_selectedMood!)}',
            ),
            backgroundColor: ArtisticTheme.successColor,
            behavior: SnackBarBehavior.floating,
          ),
        );

        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('记录失败: $e'),
            backgroundColor: ArtisticTheme.errorColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }
}
