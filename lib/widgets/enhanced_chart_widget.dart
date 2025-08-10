import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme/artistic_theme.dart';

// import '../models/expense_record.dart'; // 已删除

/// 增强的图表组件 - 支持多种图表类型
class EnhancedChartWidget extends StatefulWidget {
  final ChartType chartType;
  final Map<String, double> data;
  final String title;
  final String? subtitle;
  final Color? primaryColor;
  final double height;
  final bool showLegend;
  final bool showAnimation;

  const EnhancedChartWidget({
    super.key,
    required this.chartType,
    required this.data,
    required this.title,
    this.subtitle,
    this.primaryColor,
    this.height = 200,
    this.showLegend = true,
    this.showAnimation = true,
  });

  @override
  State<EnhancedChartWidget> createState() => _EnhancedChartWidgetState();
}

class _EnhancedChartWidgetState extends State<EnhancedChartWidget>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOutCubic,
    );

    if (widget.showAnimation) {
      _animationController.forward();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height + (widget.showLegend ? 80 : 40),
      decoration: ArtisticTheme.artisticCard,
      child: Padding(
        padding: const EdgeInsets.all(ArtisticTheme.spacingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: ArtisticTheme.spacingMedium),
            Expanded(
              child: widget.showAnimation
                  ? AnimatedBuilder(
                      animation: _animation,
                      builder: (context, child) => _buildChart(),
                    )
                  : _buildChart(),
            ),
            if (widget.showLegend) ...[
              const SizedBox(height: ArtisticTheme.spacingSmall),
              _buildLegend(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.title,
          style: ArtisticTheme.titleLarge.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        if (widget.subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            widget.subtitle!,
            style: ArtisticTheme.bodySmall.copyWith(
              color: ArtisticTheme.textSecondary,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildChart() {
    if (widget.data.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bar_chart,
              size: 48,
              color: ArtisticTheme.textSecondary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 8),
            Text(
              '暂无数据',
              style: ArtisticTheme.bodyMedium.copyWith(
                color: ArtisticTheme.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    switch (widget.chartType) {
      case ChartType.line:
        return _buildLineChart();
      case ChartType.bar:
        return _buildBarChart();
      case ChartType.pie:
        return _buildPieChart();
      case ChartType.area:
        return _buildAreaChart();
    }
  }

  Widget _buildLineChart() {
    final spots = widget.data.entries.map((entry) {
      final index = widget.data.keys.toList().indexOf(entry.key);
      return FlSpot(index.toDouble(), entry.value);
    }).toList();

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 1,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: ArtisticTheme.textSecondary.withValues(alpha: 0.1),
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 1,
              getTitlesWidget: (double value, TitleMeta meta) {
                final index = value.toInt();
                if (index >= 0 && index < widget.data.keys.length) {
                  final key = widget.data.keys.elementAt(index);
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    child: Text(
                      key,
                      style: ArtisticTheme.caption,
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              getTitlesWidget: (double value, TitleMeta meta) {
                return Text(
                  value.toInt().toString(),
                  style: ArtisticTheme.caption,
                );
              },
              reservedSize: 42,
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(
            color: ArtisticTheme.textSecondary.withValues(alpha: 0.2),
          ),
        ),
        minX: 0,
        maxX: (widget.data.length - 1).toDouble(),
        minY: 0,
        maxY: widget.data.values.reduce((a, b) => a > b ? a : b) * 1.2,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            gradient: LinearGradient(
              colors: [
                widget.primaryColor ?? ArtisticTheme.primaryColor,
                (widget.primaryColor ?? ArtisticTheme.primaryColor).withValues(alpha: 0.3),
              ],
            ),
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 4,
                  color: widget.primaryColor ?? ArtisticTheme.primaryColor,
                  strokeWidth: 2,
                  strokeColor: Colors.white,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  (widget.primaryColor ?? ArtisticTheme.primaryColor).withValues(alpha: 0.3),
                  (widget.primaryColor ?? ArtisticTheme.primaryColor).withValues(alpha: 0.0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBarChart() {
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: widget.data.values.reduce((a, b) => a > b ? a : b) * 1.2,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => ArtisticTheme.surfaceColor,
            tooltipHorizontalAlignment: FLHorizontalAlignment.center,
            tooltipMargin: -10,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              String weekDay = widget.data.keys.elementAt(group.x);
              return BarTooltipItem(
                '$weekDay\n',
                ArtisticTheme.bodySmall,
                children: <TextSpan>[
                  TextSpan(
                    text: rod.toY.toStringAsFixed(1),
                    style: ArtisticTheme.titleSmall.copyWith(
                      color: widget.primaryColor ?? ArtisticTheme.primaryColor,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (double value, TitleMeta meta) {
                final index = value.toInt();
                if (index >= 0 && index < widget.data.keys.length) {
                  final key = widget.data.keys.elementAt(index);
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    child: Text(
                      key,
                      style: ArtisticTheme.caption,
                    ),
                  );
                }
                return const Text('');
              },
              reservedSize: 38,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              interval: 1,
              getTitlesWidget: (double value, TitleMeta meta) {
                return Text(
                  value.toInt().toString(),
                  style: ArtisticTheme.caption,
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(
          show: false,
        ),
        barGroups: widget.data.entries.map((entry) {
          final index = widget.data.keys.toList().indexOf(entry.key);
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: entry.value * (widget.showAnimation ? _animation.value : 1.0),
                gradient: LinearGradient(
                  colors: [
                    widget.primaryColor ?? ArtisticTheme.primaryColor,
                    (widget.primaryColor ?? ArtisticTheme.primaryColor).withValues(alpha: 0.7),
                  ],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
                width: 16,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPieChart() {
    final colors = _generateColors(widget.data.length);
    
    return PieChart(
      PieChartData(
        pieTouchData: PieTouchData(
          touchCallback: (FlTouchEvent event, pieTouchResponse) {
            // 处理触摸事件
          },
        ),
        borderData: FlBorderData(show: false),
        sectionsSpace: 2,
        centerSpaceRadius: 40,
        sections: widget.data.entries.map((entry) {
          final index = widget.data.keys.toList().indexOf(entry.key);
          final color = colors[index % colors.length];
          
          return PieChartSectionData(
            color: color,
            value: entry.value * (widget.showAnimation ? _animation.value : 1.0),
            title: '${entry.value.toStringAsFixed(1)}%',
            radius: 50,
            titleStyle: ArtisticTheme.caption.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAreaChart() {
    return _buildLineChart(); // 区域图基于线图实现
  }

  Widget _buildLegend() {
    final colors = _generateColors(widget.data.length);
    
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: widget.data.entries.map((entry) {
        final index = widget.data.keys.toList().indexOf(entry.key);
        final color = colors[index % colors.length];
        
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              entry.key,
              style: ArtisticTheme.caption,
            ),
          ],
        );
      }).toList(),
    );
  }

  List<Color> _generateColors(int count) {
    final baseColors = [
      ArtisticTheme.primaryColor,
      ArtisticTheme.accentColor,
      ArtisticTheme.successColor,
      ArtisticTheme.warningColor,
      ArtisticTheme.errorColor,
      ArtisticTheme.infoColor,
    ];

    final colors = <Color>[];
    for (int i = 0; i < count; i++) {
      colors.add(baseColors[i % baseColors.length]);
    }
    return colors;
  }
}

/// 图表类型枚举
enum ChartType {
  line,   // 线图
  bar,    // 柱状图
  pie,    // 饼图
  area,   // 区域图
}
