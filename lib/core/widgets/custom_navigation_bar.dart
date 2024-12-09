import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

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
    final theme = Theme.of(context);
    
    return Container(
      color: theme.appBarTheme.backgroundColor,
      child: isHorizontal
          ? Column(
              children: items.map((item) => _buildVerticalItem(context, item)).toList(),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: items.map((item) => _buildHorizontalItem(context, item)).toList(),
            ),
    );
  }

  Widget _buildVerticalItem(BuildContext context, NavigationItem item) {
    final isSelected = selectedIndex == item.index;
    final theme = Theme.of(context);
    const selectedColor = AppTheme.primaryLight;
    
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
              color: isSelected ? selectedColor : theme.iconTheme.color,
            ),
            const SizedBox(height: 4),
            Text(
              item.label,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: isSelected ? selectedColor : theme.iconTheme.color,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHorizontalItem(BuildContext context, NavigationItem item) {
    final isSelected = selectedIndex == item.index;
    final theme = Theme.of(context);
    const selectedColor = AppTheme.primaryLight;
    
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
                color: isSelected ? selectedColor : theme.iconTheme.color,
              ),
              const SizedBox(height: 4),
              Text(
                item.label,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isSelected ? selectedColor : theme.iconTheme.color,
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