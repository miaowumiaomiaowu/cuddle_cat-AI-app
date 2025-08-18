import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/happiness_provider.dart';
import '../models/wellness_plan.dart';
import '../theme/artistic_theme.dart';

class WellnessPlanCard extends StatelessWidget {
  const WellnessPlanCard({super.key});

  @override
  Widget build(BuildContext context) {
    final hp = context.watch<HappinessProvider>();
    final WellnessPlan? plan = hp.wellnessPlan;
    if (plan == null) return const SizedBox.shrink();

    final goals = plan.goals.take(2).toList();
    final habits = plan.habits.take(3).toList();
    final checkpoint = plan.checkpoints.isNotEmpty ? plan.checkpoints.first : null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ArtisticTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: ArtisticTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🗓️', style: TextStyle(fontSize: 22)),
              const SizedBox(width: 8),
              Text('本周健康计划', style: ArtisticTheme.titleMedium),
            ],
          ),
          const SizedBox(height: 8),
          if (goals.isNotEmpty) ...[
            Text('目标', style: ArtisticTheme.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            ...goals.map((g) => Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• '),
                    Expanded(child: Text(g.title, style: ArtisticTheme.bodyMedium)),
                  ],
                )),
            const SizedBox(height: 10),
          ],
          if (habits.isNotEmpty) ...[
            Text('习惯', style: ArtisticTheme.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            ...habits.map((h) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      const Text('• '),
                      Expanded(
                        child: Text(
                          '${h.title} · ${h.frequency}${h.estimatedMinutes != null ? ' · ${h.estimatedMinutes}分钟' : ''}',
                          style: ArtisticTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                )),
            const SizedBox(height: 10),
          ],
          if (checkpoint != null) ...[
            Text('本周关注点', style: ArtisticTheme.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text('${checkpoint.focus}${checkpoint.metricHint != null ? '（${checkpoint.metricHint}）' : ''}',
                style: ArtisticTheme.bodyMedium),
          ],
        ],
      ),
    );
  }
}

