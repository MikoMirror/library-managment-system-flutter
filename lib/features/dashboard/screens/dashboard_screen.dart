import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fl_chart/fl_chart.dart';
import '../cubit/dashboard_cubit.dart';
import '../cubit/dashboard_state.dart';
import '../models/borrowing_trend_point.dart';
import '../widgets/stat_card.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_bar.dart';
import '../widgets/borrowing_trends_chart.dart';
import '../../../features/reports/widgets/report_generation_dialog.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  DashboardLoaded? _dashboardData;

  @override
  void initState() {
    super.initState();
    final currentState = context.read<DashboardCubit>().state;
    
    if (currentState is DashboardInitial) {
      final now = DateTime.now();
      // Set end date to end of current day
      final endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
      
      // Set start date to 13 days before (for 14 days total)
      final startDate = DateTime(
        now.year,
        now.month,
        now.day - 13,
        0, 0, 0,
      );
      
      print('Initial date range: ${startDate.toString()} - ${endDate.toString()}'); // Debug print
      
      context.read<DashboardCubit>().loadDashboard(
        startDate: startDate,
        endDate: endDate,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: UnifiedAppBar(
        title: Text(
          'System Overview',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      backgroundColor: Theme.of(context).brightness == Brightness.dark 
        ? AppTheme.dark.background 
        : AppTheme.light.background,
      body: BlocBuilder<DashboardCubit, DashboardState>(
        builder: (context, state) {
          if (state is DashboardError) {
            return Center(child: Text(state.message));
          }

          if (state is DashboardLoading && _dashboardData == null) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is DashboardLoaded) {
            _dashboardData = state;
            return _DashboardContent(data: state);
          }

          if (_dashboardData != null) {
            return _DashboardContent(data: _dashboardData!);
          }

          return const Center(child: Text('Something went wrong'));
        },
      ),
    );
  }
}

class _DashboardContent extends StatelessWidget {
  final DashboardLoaded data;

  const _DashboardContent({required this.data});

  List<FlSpot> _convertToSpots(List<BorrowingTrendPoint> trends) {
    if (trends.isEmpty) return [];
    
    // Create a map for all possible dates with default value 0
    final Map<DateTime, double> spotMap = {};
    final totalDays = data.selectedEndDate.difference(data.selectedStartDate).inDays + 1;
    
    // Initialize all days with 0
    for (int i = 0; i < totalDays; i++) {
      final date = data.selectedStartDate.add(Duration(days: i));
      spotMap[DateTime(date.year, date.month, date.day)] = 0;
    }
    
    // Fill in actual values
    for (var trend in trends) {
      final date = trend.timestamp;
      spotMap[DateTime(date.year, date.month, date.day)] = trend.count.toDouble();
    }
    
    // Convert map to sorted list of FlSpots
    return spotMap.entries
        .map((entry) {
          final days = entry.key.difference(data.selectedStartDate).inDays;
          return FlSpot(days.toDouble(), entry.value);
        })
        .toList()
      ..sort((a, b) => a.x.compareTo(b.x));
  }

  double _calculateCardWidth(BoxConstraints constraints) {
    final screenWidth = constraints.maxWidth;
    if (screenWidth > 1600) return 320;
    if (screenWidth > 1200) return 280;
    if (screenWidth > 800) return 260;
    if (screenWidth > 600) return screenWidth / 2 - 24;
    return screenWidth - 32;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = _calculateCardWidth(constraints);
        final isMobile = constraints.maxWidth < 600;
        
        return SingleChildScrollView(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Library Statistics',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                    _buildActions(context),
                  ],
                ),
              ),
              AnimatedPadding(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    _buildStatCards(data, cardWidth),
                    const SizedBox(height: 16),
                    RepaintBoundary(
                      child: BorrowingTrendsChart(
                        key: ValueKey('borrowing_trends_chart_${data.selectedStartDate}_${data.selectedEndDate}'),
                        width: constraints.maxWidth - 32,
                        startDate: data.selectedStartDate,
                        endDate: data.selectedEndDate,
                        borrowedTrends: _convertToSpots(data.borrowedTrends),
                        returnedTrends: _convertToSpots(data.returnedTrends),
                        isMobile: isMobile,
                        onDateRangeChanged: (start, end) {
                          context.read<DashboardCubit>().loadDashboard(
                            startDate: start,
                            endDate: end,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCards(DashboardLoaded state, double cardWidth) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      constraints: const BoxConstraints(maxWidth: 1600),
      child: Wrap(
        spacing: 16.0,
        runSpacing: 16.0,
        alignment: WrapAlignment.center,
        children: [
          StatCard(
            width: cardWidth,
            title: 'Unique Books',
            value: '${state.uniqueBooks}',
            icon: Icons.auto_stories,
            color: AppTheme.light.info,
          ),
          StatCard(
            width: cardWidth,
            title: 'Available Books',
            value: '${state.totalBooks - (state.reservedBooks + state.borrowedBooks)}/${state.totalBooks}',
            icon: Icons.library_books,
            color: AppTheme.light.primary,
          ),
          StatCard(
            width: cardWidth,
            title: 'Reserved Books',
            value: '${state.reservedBooks}',
            icon: Icons.bookmark,
            color: AppTheme.light.warning,
          ),
          StatCard(
            width: cardWidth,
            title: 'Borrowed Books',
            value: '${state.borrowedBooks}',
            icon: Icons.book,
            color: AppTheme.light.success,
          ),
          StatCard(
            width: cardWidth,
            title: 'Overdue Books',
            value: '${state.overdueBooks}',
            icon: Icons.warning,
            color: AppTheme.light.error,
          ),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        ElevatedButton.icon(
          onPressed: () => _showReportDialog(context),
          icon: const Icon(Icons.assessment),
          label: const Text('Generate Report'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }

  void _showReportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const ReportGenerationDialog(),
    );
  }
} 
