import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'custom_search_bar.dart';

class UnifiedAppBar extends StatefulWidget implements PreferredSizeWidget {
  final List<Widget>? actions;
  final Widget? title;
  final bool automaticallyImplyLeading;
  final Widget? leading;
  final PreferredSizeWidget? bottom;
  final String? searchHint;
  final ValueChanged<String>? onSearch;
  final bool isSimple;

  const UnifiedAppBar({
    super.key,
    this.actions,
    this.title,
    this.automaticallyImplyLeading = true,
    this.leading,
    this.bottom,
    this.searchHint,
    this.onSearch,
    this.isSimple = false,
  });

  @override
  Size get preferredSize {
    final baseHeight = isSimple ? 48.0 : kToolbarHeight + 8.0;
    final bottomHeight = bottom?.preferredSize.height ?? 0;
    return Size.fromHeight(baseHeight + bottomHeight);
  }

  @override
  State<UnifiedAppBar> createState() => _UnifiedAppBarState();
}

class _UnifiedAppBarState extends State<UnifiedAppBar> with SingleTickerProviderStateMixin {
  bool _isSearchVisible = false;
  late final TextEditingController _searchController;
  late final AnimationController _animationController;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    setState(() {
      _isSearchVisible = !_isSearchVisible;
      if (!_isSearchVisible) {
        _searchController.clear();
        widget.onSearch!('');
        _animationController.reverse();
      } else {
        _animationController.forward();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final colors = isDarkMode ? AppTheme.dark : AppTheme.light;

    return AppBar(
      leading: widget.leading,
      title: Row(
        children: [
          if (!_isSearchVisible && widget.title != null) 
            Expanded(child: widget.title!),
          if (widget.onSearch != null && _isSearchVisible)
            Expanded(
              child: CustomSearchBar(
                hintText: widget.searchHint ?? 'Search...',
                controller: _searchController,
                isVisible: _isSearchVisible,
                animation: _animation,
                onChanged: widget.onSearch!,
                onClear: _toggleSearch,
              ),
            ),
        ],
      ),
      actions: [
        const SizedBox(width: 8),
        if (widget.onSearch != null)
          if (_isSearchVisible)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: _toggleSearch,
            )
          else
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: _toggleSearch,
            ),
        if (!_isSearchVisible && widget.actions != null) ...[
          const SizedBox(width: 8),
          ...widget.actions!,
        ],
        const SizedBox(width: 8),
      ],
      automaticallyImplyLeading: widget.automaticallyImplyLeading,
      centerTitle: false,
      elevation: 0,
      backgroundColor: colors.primary.withAlpha(25),
      iconTheme: IconThemeData(
        color: colors.primary,
      ),
      bottom: widget.bottom != null
          ? PreferredSize(
              preferredSize: widget.bottom!.preferredSize,
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  widget.bottom!,
                ],
              ),
            )
          : null,
      toolbarHeight: kToolbarHeight + 8.0,
    );
  }
}