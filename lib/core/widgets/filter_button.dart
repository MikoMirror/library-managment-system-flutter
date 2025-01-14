import 'package:flutter/material.dart';

class FilterButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool isActive;

  const FilterButton({
    super.key,
    required this.onPressed,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return IconButton(
      icon: Stack(
        children: [
          Icon(
            Icons.filter_list,
            color: isActive ? theme.colorScheme.primary : theme.iconTheme.color,
          ),
          if (isActive)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
      onPressed: onPressed,
      tooltip: 'Filter',
    );
  }
} 