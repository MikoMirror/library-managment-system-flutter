import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final List<Widget>? actions;
  final Widget? title;
  final bool automaticallyImplyLeading;
  final Widget? leading;

  const CustomAppBar({
    super.key,
    this.actions,
    this.title,
    this.automaticallyImplyLeading = true,
    this.leading,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final isDesktop = MediaQuery.of(context).size.width >= 1024;
    
    return AppBar(
      leading: leading,
      title: title,
      actions: [
        if (actions != null) ...actions!,
        if (isDesktop && actions != null) const SizedBox(width: 8),
      ],
      automaticallyImplyLeading: automaticallyImplyLeading,
      centerTitle: false,
      elevation: 0,
      backgroundColor: isDarkMode 
          ? AppTheme.primaryDark.withOpacity(0.3)
          : AppTheme.primaryLight.withOpacity(0.3),
      iconTheme: IconThemeData(
        color: isDarkMode ? AppTheme.accentDark : AppTheme.accentLight,
      ),
    );
  }
} 