import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/dashboard_cubit.dart';
import '../cubit/dashboard_state.dart';
import '../widgets/stat_card.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../../core/theme/app_theme.dart';
import '../widgets/borrowing_trends_chart.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final colors = isDarkMode ? AppTheme.dark : AppTheme.light;

    return Scaffold(
      appBar: CustomAppBar(
        title: Text(
          'System Overview',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      backgroundColor: isDarkMode 
        ? AppTheme.dark.background 
        : AppTheme.light.background,
      body: _DashboardContent(colors: colors),
    );
  }
}

class _DashboardContent extends StatelessWidget {
  final CoreColors colors;

  const _DashboardContent({required this.colors});

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final cardWidth = _calculateCardWidth(screenSize.width);
    final gridSpacing = screenSize.width > 1200 ? 24.0 : 16.0;

    return BlocBuilder<DashboardCubit, DashboardState>(
      builder: (context, state) {
        if (state is DashboardLoading) {
          return Center(
            child: CircularProgressIndicator(
              color: colors.primary,
            ),
          );
        }

        if (state is DashboardLoaded) {
          return SingleChildScrollView(
            padding: EdgeInsets.all(gridSpacing),
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.only(bottom: gridSpacing),
                  child: Center(
                    child: Text(
                      'Library Statistics',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colors.onBackground,
                      ),
                    ),
                  ),
                ),
                Center(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return Container(
                        constraints: BoxConstraints(
                          maxWidth: 1600,
                        ),
                        child: Wrap(
                          spacing: gridSpacing,
                          runSpacing: gridSpacing,
                          alignment: WrapAlignment.center,
                          children: [
                            StatCard(
                              width: cardWidth,
                              title: 'Unique Books',
                              value: state.uniqueBooks.toString(),
                              icon: Icons.auto_stories,
                              color: colors.info,
                            ),
                            StatCard(
                              width: cardWidth,
                              title: 'Available Books',
                              value: '${state.totalBooks - (state.reservedBooks + state.borrowedBooks)}/${state.totalBooks}',
                              icon: Icons.library_books,
                              color: colors.primary,
                            ),
                            StatCard(
                              width: cardWidth,
                              title: 'Reserved Books',
                              value: state.reservedBooks.toString(),
                              icon: Icons.bookmark,
                              color: colors.warning,
                            ),
                            StatCard(
                              width: cardWidth,
                              title: 'Borrowed Books',
                              value: state.borrowedBooks.toString(),
                              icon: Icons.book,
                              color: colors.success,
                            ),
                            StatCard(
                              width: cardWidth,
                              title: 'Overdue Books',
                              value: state.overdueBooks.toString(),
                              icon: Icons.warning,
                              color: colors.error,
                            ),
                            BorrowingTrendsChart(
                              width: screenSize.width > 800 ? screenSize.width - 48 : screenSize.width - 32,
                              color: colors.primary,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        }

        if (state is DashboardError) {
          return Center(
            child: Text(
              state.message,
              style: TextStyle(color: colors.error),
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  double _calculateCardWidth(double screenWidth) {
    if (screenWidth > 1600) return 320; // Extra large screens
    if (screenWidth > 1200) return 280; // Large screens
    if (screenWidth > 800) return 260;  // Medium screens
    if (screenWidth > 600) return screenWidth / 2 - 24; // Small screens
    return screenWidth - 32; // Mobile screens
  }
} 