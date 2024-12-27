import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/theme/app_theme.dart';
import 'package:intl/intl.dart';
import 'dart:math' show max, min;
import 'package:library_management_system/features/dashboard/widgets/date_range_selector.dart';

class BorrowingTrendsChart extends StatefulWidget {
  final double width;
  final DateTime startDate;
  final DateTime endDate;
  final List<FlSpot> borrowedTrends;
  final List<FlSpot> returnedTrends;
  final bool isMobile;
  final Function(DateTime, DateTime) onDateRangeChanged;

  const BorrowingTrendsChart({
    super.key,
    required this.width,
    required this.startDate,
    required this.endDate,
    required this.borrowedTrends,
    required this.returnedTrends,
    required this.onDateRangeChanged,
    this.isMobile = false,
  });

  @override
  State<BorrowingTrendsChart> createState() => _BorrowingTrendsChartState();
}

class _BorrowingTrendsChartState extends State<BorrowingTrendsChart> with AutomaticKeepAliveClientMixin {
  bool _showBorrowed = true;
  late List<FlSpot> _processedBorrowedSpots;
  late List<FlSpot> _processedReturnedSpots;
  final ScrollController _scrollController = ScrollController();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _processDataPoints();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  void _processDataPoints() {
    _processedBorrowedSpots = _convertToSpots(widget.borrowedTrends);
    _processedReturnedSpots = _convertToSpots(widget.returnedTrends);
  }

  List<FlSpot> _convertToSpots(List<FlSpot> trends) {
    if (trends.isEmpty) return [];
    
    // Create a map using actual dates as keys
    final Map<DateTime, double> valueMap = {};
    final totalDays = widget.endDate.difference(widget.startDate).inDays + 1;
    
    // Initialize all days with 0
    for (int i = 0; i < totalDays; i++) {
      final date = widget.startDate.add(Duration(days: i));
      valueMap[DateTime(date.year, date.month, date.day)] = 0;
    }
    
    // Fill in actual values
    for (var spot in trends) {
      final date = widget.startDate.add(Duration(days: spot.x.toInt()));
      valueMap[DateTime(date.year, date.month, date.day)] = spot.y;
    }
    
    // Convert back to FlSpots
    return valueMap.entries
        .map((entry) {
          final days = entry.key.difference(widget.startDate).inDays;
          return FlSpot(days.toDouble(), entry.value);
        })
        .toList()
      ..sort((a, b) => a.x.compareTo(b.x));
  }

  @override
  void didUpdateWidget(BorrowingTrendsChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.borrowedTrends != widget.borrowedTrends ||
        oldWidget.returnedTrends != widget.returnedTrends ||
        oldWidget.startDate != widget.startDate ||
        oldWidget.endDate != widget.endDate) {
      _processDataPoints();
      
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        }
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  String _getTooltipDate(double x) {
    final date = widget.startDate.add(Duration(days: x.toInt()));
    return DateFormat('MMM d, yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final colors = isDarkMode ? AppTheme.dark : AppTheme.light;
    final displayedSpots = _showBorrowed ? _processedBorrowedSpots : _processedReturnedSpots;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Borrowing Trends',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                DateRangeSelector(
                  key: const ValueKey('date_range_selector'),
                  startDate: widget.startDate,
                  endDate: widget.endDate,
                  onDateRangeChanged: widget.onDateRangeChanged,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Center(
              child: SegmentedButton<bool>(
                selected: {_showBorrowed},
                onSelectionChanged: (Set<bool> selected) {
                  setState(() {
                    _showBorrowed = selected.first;
                  });
                },
                segments: [
                  ButtonSegment<bool>(
                    value: true,
                    label: Text('Borrowed', 
                      style: TextStyle(color: colors.onSurface)),
                  ),
                  ButtonSegment<bool>(
                    value: false,
                    label: Text('Returned', 
                      style: TextStyle(color: colors.onSurface)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: SizedBox(
                height: 400,
                width: widget.width,
                child: Builder(
                  builder: (context) {
                    final daysCount = widget.endDate.difference(widget.startDate).inDays + 1;
                    final minWidth = widget.width - 32;
                    final desiredWidth = daysCount * 40.0;
                    
                    if (desiredWidth <= minWidth) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 16.0, bottom: 24.0),
                        child: _buildChart(displayedSpots, colors),
                      );
                    }

                    return Scrollbar(
                      thumbVisibility: true,
                      trackVisibility: true,
                      controller: _scrollController,
                      child: SingleChildScrollView(
                        controller: _scrollController,
                        scrollDirection: Axis.horizontal,
                        child: SizedBox(
                          width: max(desiredWidth, minWidth),
                          child: _buildChart(displayedSpots, colors),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChart(List<FlSpot> spots, CoreColors colors) {
    final allYValues = spots.map((e) => e.y).toList();
    final maxY = allYValues.isEmpty ? 10.0 : max(allYValues.reduce(max) * 1.2, 5.0);
    final horizontalInterval = maxY / 5 > 1 ? (maxY / 5).ceilToDouble() : 1.0;
    final maxX = widget.endDate.difference(widget.startDate).inDays.toDouble();

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: maxX,
        minY: 0,
        maxY: maxY,
        clipData: const FlClipData.all(),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          horizontalInterval: horizontalInterval,
          verticalInterval: 1,
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 1,
              getTitlesWidget: (value, meta) => _bottomTitleWidgets(value, meta, colors),
            ),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: horizontalInterval,
              reservedSize: 40,
              getTitlesWidget: (value, meta) => _leftTitleWidgets(value, meta, colors),
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Colors.grey.withOpacity(0.2)),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: false,
            color: _showBorrowed ? colors.primary : colors.success,
            barWidth: 2,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: (_showBorrowed ? colors.primary : colors.success).withOpacity(0.1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bottomTitleWidgets(double value, TitleMeta meta, CoreColors colors) {
    final style = TextStyle(
      color: colors.textSubtle,
      fontWeight: FontWeight.bold,
      fontSize: 10,
    );

    final date = widget.startDate.add(Duration(days: value.toInt()));
    
    return SideTitleWidget(
      axisSide: meta.axisSide,
      angle: 45,
      child: Text(
        '${date.day} ${DateFormat('MMM').format(date)}',
        style: style,
      ),
    );
  }

  Widget _leftTitleWidgets(double value, TitleMeta meta, CoreColors colors) {
    return Text(
      value.toInt().toString(),
      style: TextStyle(
        color: colors.textSubtle,
        fontWeight: FontWeight.bold,
        fontSize: 12,
      ),
      textAlign: TextAlign.left,
    );
  }
} 