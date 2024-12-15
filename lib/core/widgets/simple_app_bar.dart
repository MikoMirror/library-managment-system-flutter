import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SimpleAppBar extends StatelessWidget implements PreferredSizeWidget {
  final List<Widget>? actions;
  final Widget? title;
  final bool automaticallyImplyLeading;
  final Widget? leading;

  const SimpleAppBar({
    super.key,
    this.actions,
    this.title,
    this.automaticallyImplyLeading = true,
    this.leading,
  });

  @override
  Size get preferredSize => const Size.fromHeight(48.0);

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return AppBar(
      leading: leading,
      title: title,
      actions: actions,
      automaticallyImplyLeading: automaticallyImplyLeading,
      centerTitle: false,
      elevation: 0,
      backgroundColor: isDarkMode 
          ? AppTheme.dark.primary.withOpacity(0.3)
          : AppTheme.light.primary.withOpacity(0.3),
      iconTheme: IconThemeData(
        color: isDarkMode ? AppTheme.dark.secondary : AppTheme.light.secondary,
      ),
    );
  }
} 