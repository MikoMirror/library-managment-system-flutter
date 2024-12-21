import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/theme/app_theme.dart';
import '../../../features/dashboard/cubit/dashboard_cubit.dart';
import '../../../features/dashboard/cubit/dashboard_state.dart';
import '../models/borrowing_trend_point.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

enum TimeRange {
  day,
  week,
  month,
  halfYear
}

class BorrowingTrendsChart extends StatefulWidget {
  final double width;
  final Color color;

  const BorrowingTrendsChart({
    super.key,
    required this.width,
    required this.color,
  });

  @override
  State<BorrowingTrendsChart> createState() => _BorrowingTrendsChartState();
}

class _BorrowingTrendsChartState extends State<BorrowingTrendsChart> {
  TimeRange _selectedRange = TimeRange.week;

  List<FlSpot> _getSpots(List<BorrowingTrendPoint> trends) {
    if (trends.isEmpty) return [];

    // Filter trends based on selected range
    final now = DateTime.now();
    final startDate = switch (_selectedRange) {
      TimeRange.day => DateTime(now.year, now.month, now.day - 1),
      TimeRange.week => now.subtract(const Duration(days: 7)),
      TimeRange.month => DateTime(now.year, now.month - 1, now.day),
      TimeRange.halfYear => DateTime(now.year, now.month - 6, now.day),
    };

    final filteredTrends = trends
        .where((trend) => trend.timestamp.isAfter(startDate))
        .toList();

    return filteredTrends.asMap().entries.map((entry) {
      return FlSpot(
        entry.key.toDouble(),
        entry.value.count.toDouble(),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final colors = isDarkMode ? AppTheme.dark : AppTheme.light;

    return Column(
      children: [
        _buildTimeRangeSelector(colors),
        const SizedBox(height: 16),
        SizedBox(
          width: widget.width,
          height: 300,
          child: BlocBuilder<DashboardCubit, DashboardState>(
            builder: (context, state) {
              if (state is DashboardLoaded) {
                final spots = _getSpots(state.borrowingTrends);
                return _buildChart(spots, colors);
              }
              return const Center(child: CircularProgressIndicator());
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTimeRangeSelector(CoreColors colors) {
    return SegmentedButton<TimeRange>(
      selected: {_selectedRange},
      onSelectionChanged: (Set<TimeRange> selection) {
        setState(() {
          _selectedRange = selection.first;
        });
      },
      segments: [
        ButtonSegment<TimeRange>(
          value: TimeRange.day,
          label: Text('Day'),
        ),
        ButtonSegment<TimeRange>(
          value: TimeRange.week,
          label: Text('Week'),
        ),
        ButtonSegment<TimeRange>(
          value: TimeRange.month,
          label: Text('Month'),
        ),
        ButtonSegment<TimeRange>(
          value: TimeRange.halfYear,
          label: Text('6M'),
        ),
      ],
    );
  }

  Widget _buildChart(List<FlSpot> spots, CoreColors colors) {
    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          horizontalInterval: 1,
          verticalInterval: 1,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: colors.onBackground.withOpacity(0.1),
              strokeWidth: 1,
            );
          },
          getDrawingVerticalLine: (value) {
            return FlLine(
              color: colors.onBackground.withOpacity(0.1),
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 1,
              getTitlesWidget: _bottomTitleWidgets,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              getTitlesWidget: _leftTitleWidgets,
              reservedSize: 42,
            ),
          ),
        ),
        borderData: FlBorderData(
          show: false,
        ),
        minX: 0,
        maxX: _getMaxX(),
        minY: 0,
        maxY: 6,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            gradient: LinearGradient(
              colors: [
                widget.color.withOpacity(0.5),
                widget.color,
              ],
            ),
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: false,
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  widget.color.withOpacity(0.1),
                  widget.color.withOpacity(0.05),
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

  Widget _bottomTitleWidgets(double value, TitleMeta meta) {
    final style = TextStyle(
      color: Colors.grey,
      fontWeight: FontWeight.bold,
      fontSize: 12,
    );

    String text;
    switch (_selectedRange) {
      case TimeRange.day:
        text = '${value.toInt()}h';
        break;
      case TimeRange.week:
        text = 'D${value.toInt()}';
        break;
      case TimeRange.month:
        text = 'W${value.toInt()}';
        break;
      case TimeRange.halfYear:
        text = 'M${value.toInt()}';
        break;
    }

    return SideTitleWidget(
      axisSide: meta.axisSide,
      child: Text(text, style: style),
    );
  }

  Widget _leftTitleWidgets(double value, TitleMeta meta) {
    final style = TextStyle(
      color: Colors.grey,
      fontWeight: FontWeight.bold,
      fontSize: 12,
    );

    return Text(value.toInt().toString(), style: style, textAlign: TextAlign.left);
  }

  double _getMaxX() {
    switch (_selectedRange) {
      case TimeRange.day:
        return 23;
      case TimeRange.week:
        return 7;
      case TimeRange.month:
        return 4;
      case TimeRange.halfYear:
        return 6;
    }
  }
} 