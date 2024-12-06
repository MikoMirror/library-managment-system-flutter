import 'package:flutter/material.dart';

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
  Widget build(BuildContext context) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(48.0),
      child: AppBar(
        leading: leading,
        title: title,
        actions: actions,
        automaticallyImplyLeading: automaticallyImplyLeading,
        centerTitle: false,
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(48.0);
} 