import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cat_provider.dart';
import 'cat_interaction_animation.dart';

class CatInteractionPanel extends StatefulWidget {
  final VoidCallback? onPetCat;

  const CatInteractionPanel({
    Key? key,
    this.onPetCat,
  }) : super(key: key);

  @override
  State<CatInteractionPanel> createState() => _CatInteractionPanelState();
}

class _CatInteractionPanelState extends State<CatInteractionPanel> {
  InteractionAnimationType? _currentAnimation;
  Offset? _animationPosition;

  void _showInteractionAnimation(InteractionAnimationType type, Offset position) {
    setState(() {
      _currentAnimation = type;
      _animationPosition = position;
    });
  }

  void _onAnimationComplete() {
    setState(() {
      _currentAnimation = null;
      _animationPosition = null;
    });
  }

  Widget _buildInteractionButton({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onPressed,
    required bool isEnabled,
    required String cooldownText,
  }) {
    return Opacity(
      opacity: isEnabled ? 1.0 : 0.5,
      child: Column(
        children: [
          SizedBox(
            width: 50,
            height: 50,
            child: MaterialButton(
              onPressed: isEnabled ? onPressed : null,
              color: color.withOpacity(0.2),
              shape: const CircleBorder(),
              child: Icon(icon, color: color),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isEnabled ? Colors.black87 : Colors.black45,
            ),
          ),
          if (!isEnabled && cooldownText.isNotEmpty)
            Text(
              cooldownText,
              style: const TextStyle(
                fontSize: 10,
                color: Colors.black45,
              ),
            ),
        ],
      ),
    );
  }

  String _formatCooldown(int seconds) {
    if (seconds < 60) {
      return '$seconds秒';
    }
    final minutes = seconds ~/ 60;
    if (minutes < 60) {
      return '$minutes分钟';
    }
    final hours = minutes ~/ 60;
    return '$hours小时';
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CatProvider>(
      builder: (context, catProvider, child) {
        if (!catProvider.hasCat) {
          return const SizedBox.shrink();
        }

        return Stack(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildInteractionButton(
                    icon: Icons.pets,
                    color: Colors.pink,
                    label: '抚摸',
                    onPressed: () {
                      catProvider.petCat();
                      widget.onPetCat?.call();
                      _showInteractionAnimation(
                        InteractionAnimationType.pet,
                        const Offset(0, -50),
                      );
                    },
                    isEnabled: true,
                    cooldownText: '',
                  ),
                  _buildInteractionButton(
                    icon: Icons.restaurant,
                    color: Colors.orange,
                    label: '喂食',
                    onPressed: () {
                      catProvider.feedCat();
                      _showInteractionAnimation(
                        InteractionAnimationType.feed,
                        const Offset(0, -50),
                      );
                    },
                    isEnabled: catProvider.canFeedCat(),
                    cooldownText: catProvider.canFeedCat()
                        ? ''
                        : '冷却中 ${_formatCooldown(catProvider.getFeedCooldown())}',
                  ),
                  _buildInteractionButton(
                    icon: Icons.toys,
                    color: Colors.purple,
                    label: '玩耍',
                    onPressed: () {
                      catProvider.playWithCat();
                      _showInteractionAnimation(
                        InteractionAnimationType.play,
                        const Offset(0, -50),
                      );
                    },
                    isEnabled: catProvider.canPlayWithCat(),
                    cooldownText: catProvider.canPlayWithCat()
                        ? ''
                        : '冷却中 ${_formatCooldown(catProvider.getPlayCooldown())}',
                  ),
                  _buildInteractionButton(
                    icon: Icons.shower,
                    color: Colors.blue,
                    label: '梳理',
                    onPressed: () {
                      catProvider.groomCat();
                      _showInteractionAnimation(
                        InteractionAnimationType.groom,
                        const Offset(0, -50),
                      );
                    },
                    isEnabled: catProvider.canGroomCat(),
                    cooldownText: catProvider.canGroomCat()
                        ? ''
                        : '冷却中 ${_formatCooldown(catProvider.getGroomCooldown())}',
                  ),
                  _buildInteractionButton(
                    icon: Icons.school,
                    color: Colors.amber,
                    label: '训练',
                    onPressed: () {
                      catProvider.trainCat();
                      _showInteractionAnimation(
                        InteractionAnimationType.train,
                        const Offset(0, -50),
                      );
                    },
                    isEnabled: catProvider.canTrainCat(),
                    cooldownText: catProvider.canTrainCat()
                        ? ''
                        : '冷却中 ${_formatCooldown(catProvider.getTrainCooldown())}',
                  ),
                  _buildInteractionButton(
                    icon: Icons.chat_bubble_outline,
                    color: Colors.teal,
                    label: '对话',
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('对话功能即将开放！'))
                      );
                    },
                    isEnabled: true,
                    cooldownText: '',
                  ),
                ],
              ),
            ),
            if (_currentAnimation != null && _animationPosition != null)
              Positioned(
                left: MediaQuery.of(context).size.width / 2 - 25,
                top: MediaQuery.of(context).size.height / 2 + _animationPosition!.dy,
                child: CatInteractionAnimation(
                  type: _currentAnimation!,
                  size: 50,
                  onComplete: _onAnimationComplete,
                ),
              ),
          ],
        );
      },
    );
  }
} 