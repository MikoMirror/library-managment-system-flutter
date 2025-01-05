import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class CustomSearchBar extends StatefulWidget {
  final String hintText;
  final ValueChanged<String> onChanged;
  final VoidCallback? onClear;
  final TextEditingController? controller;
  final bool isVisible;
  final Animation<double> animation;

  const CustomSearchBar({
    super.key,
    required this.hintText,
    required this.onChanged,
    required this.isVisible,
    required this.animation,
    this.onClear,
    this.controller,
  });

  @override
  State<CustomSearchBar> createState() => _CustomSearchBarState();
}

class _CustomSearchBarState extends State<CustomSearchBar> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final colors = isDarkMode ? AppTheme.dark : AppTheme.light;
    
    return SizeTransition(
      sizeFactor: widget.animation,
      axis: Axis.horizontal,
      child: Container(
        height: 40,
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: colors.background,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: colors.primary.withAlpha(179),
          ),
        ),
        child: Center(
          child: TextField(
            controller: widget.controller ?? _controller,
            onChanged: widget.onChanged,
            style: TextStyle(
              color: colors.secondary,
            ),
            decoration: InputDecoration(
              hintText: widget.hintText,
              hintStyle: TextStyle(
                color: colors.secondary.withAlpha(179),
              ),
              prefixIcon: Icon(
                Icons.search,
                color: colors.secondary.withAlpha(179),
              ),
              border: InputBorder.none,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 10,
              ),
              suffixIcon: widget.controller?.text.isNotEmpty ?? _controller.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(
                        Icons.close,
                        color: colors.secondary.withAlpha(179),
                      ),
                      onPressed: () {
                        final controller = widget.controller ?? _controller;
                        controller.clear();
                        if (widget.onClear != null) {
                          widget.onClear!();
                        }
                      },
                    )
                  : null,
            ),
          ),
        ),
      ),
    );
  }
} 