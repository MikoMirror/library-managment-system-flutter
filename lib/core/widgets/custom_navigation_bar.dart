import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/theme/cubit/theme_cubit.dart';

class NavigationItem {
  final int index;
  final IconData selectedIcon;
  final IconData unselectedIcon;
  final String label;

  const NavigationItem({
    required this.index,
    required this.selectedIcon,
    required this.unselectedIcon,
    required this.label,
  });
}

class CustomNavigationBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;
  final bool isHorizontal;
  final List<NavigationItem> items;

  const CustomNavigationBar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    required this.isHorizontal,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, ThemeState>(
      builder: (context, themeState) {
        final theme = Theme.of(context);
        final isDarkMode = themeState.isDarkMode;
        final colors = isDarkMode ? AppTheme.dark : AppTheme.light;

        return Container(
          decoration: BoxDecoration(
            color: isDarkMode ? colors.surface : colors.primary.withOpacity(0.1),
            border: isHorizontal ? Border(
              right: BorderSide(
                color: Colors.transparent,
                width: 0,
              ),
            ) : null,
          ),
          child: isHorizontal
            ? Column(
                children: items.map((item) => _buildVerticalItem(
                  context, 
                  item,
                  isDarkMode,
                  colors,
                )).toList(),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: items.map((item) => _buildHorizontalItem(
                  context,
                  item,
                  isDarkMode,
                  colors,
                )).toList(),
              ),
        );
      },
    );
  }

  Widget _buildVerticalItem(
    BuildContext context,
    NavigationItem item,
    bool isDarkMode,
    CoreColors colors,
  ) {
    final isSelected = selectedIndex == item.index;
    
    return InkWell(
      onTap: () => onItemSelected(item.index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        width: double.infinity,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? item.selectedIcon : item.unselectedIcon,
              color: isSelected 
                ? colors.primary
                : colors.primary.withOpacity(0.7),
            ),
            const SizedBox(height: 4),
            Text(
              item.label,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isSelected 
                  ? colors.primary
                  : colors.primary.withOpacity(0.7),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHorizontalItem(
    BuildContext context,
    NavigationItem item,
    bool isDarkMode,
    CoreColors colors,
  ) {
    final isSelected = selectedIndex == item.index;
    
    return Expanded(
      child: InkWell(
        onTap: () => onItemSelected(item.index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isSelected ? item.selectedIcon : item.unselectedIcon,
                color: isSelected 
                  ? colors.primary
                  : colors.primary.withOpacity(0.7),
              ),
              const SizedBox(height: 4),
              Text(
                item.label,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: isSelected 
                    ? colors.primary
                    : colors.primary.withOpacity(0.7),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}