import 'package:flutter/material.dart';
import '../theme/app_theme.dart';



class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final List<Widget>? actions;
  final Widget? title;
  final bool automaticallyImplyLeading;
  final Widget? leading;
  final PreferredSizeWidget? bottom;

  const CustomAppBar({
    super.key,
    this.actions,
    this.title,
    this.automaticallyImplyLeading = true,
    this.leading,
    this.bottom,
  });

  @override
  Size get preferredSize => Size.fromHeight(
    kToolbarHeight + (bottom?.preferredSize.height ?? 0)
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final colors = isDarkMode ? AppTheme.dark : AppTheme.light;
    
    return AppBar(
      leading: leading,
      title: title,
      actions: [
        if (actions != null) ...actions!,
      ],
      automaticallyImplyLeading: automaticallyImplyLeading,
      centerTitle: false,
      elevation: 0,
      backgroundColor: colors.primary.withAlpha(25),
      iconTheme: IconThemeData(
        color: colors.primary,
      ),
      bottom: bottom,
    );
  }
} 