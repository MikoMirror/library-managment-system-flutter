import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../books/models/book.dart';
import '../../books/bloc/books_bloc.dart';
import '../../books/bloc/books_state.dart';
import '../../books/bloc/books_event.dart';
import '../../../core/navigation/cubit/navigation_cubit.dart';
import '../../books/widgets/book card/book_card.dart';
import '../../books/enums/sort_type.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/cubit/theme_cubit.dart';
import '../../books/screens/books_screen.dart';
import '../../auth/bloc/auth/auth_bloc.dart';
import 'dart:async';
import '../../books/bloc/book_card_bloc.dart';
import '../../books/repositories/books_repository.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/navigation/cubit/navigation_cubit.dart';
import '../../../core/navigation/cubit/navigation_state.dart';
import 'package:flutter/gestures.dart' show DragStartBehavior, PointerDeviceKind;

class MainHomeScreen extends StatefulWidget {
  const MainHomeScreen({super.key});

  @override
  State<MainHomeScreen> createState() => _MainHomeScreenState();
}

class _MainHomeScreenState extends State<MainHomeScreen> {
  StreamSubscription? _adminStreamSubscription;
  bool _isAdmin = false;
  String? _userId;
  late final Map<SortType, Widget> _cachedSections;
  bool _initialized = false;
  bool _showBooksList = false;
  SortType? _currentSortType;

  @override
  void initState() {
    super.initState();
    context.read<BooksBloc>().add(const LoadBooksEvent());
    _setupAdminStream();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initializeSections();
      _initialized = true;
    }
  }

  void _initializeSections() {
    final colors = Theme.of(context).brightness == Brightness.dark 
        ? AppTheme.dark 
        : AppTheme.light;
    
    _cachedSections = {
      SortType.rating: _buildSection(
        title: 'Most popular books',
        subtitle: 'Highest rated books in our collection',
        sortType: SortType.rating,
        icon: Icons.star,
        colors: colors,
      ),
      SortType.date: _buildSection(
        title: 'New books',
        subtitle: 'Recently added to our collection',
        sortType: SortType.date,
        icon: Icons.new_releases,
        colors: colors,
      ),
    };
  }

  void _setupAdminStream() {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthSuccess) {
      _userId = authState.user.uid;
      _adminStreamSubscription?.cancel();
      
      _adminStreamSubscription = FirebaseFirestore.instance
          .collection('users')
          .doc(_userId)
          .snapshots()
          .listen(
        (snapshot) {
          if (mounted) {
            final userData = snapshot.data() as Map<String, dynamic>?;
            setState(() {
              _isAdmin = userData?['role'] == 'admin';
            });
          }
        },
        onError: (error) {
          debugPrint('Error in admin stream: $error');
        },
      );
    }
  }

  @override
  void dispose() {
    _adminStreamSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).brightness == Brightness.dark 
        ? AppTheme.dark 
        : AppTheme.light;

    return BlocBuilder<NavigationCubit, NavigationState>(
      builder: (context, state) {
        final showBooks = state.params?['showBooks'] ?? false;
        final sortTypeStr = state.params?['sortType'] as String?;
        
        final sortType = sortTypeStr != null
            ? SortType.values.firstWhere(
                (type) => type.toString() == sortTypeStr,
                orElse: () => SortType.none,
              )
            : null;
        
        return Container(
          color: colors.background,
          child: showBooks
            ? BooksScreen(
                sortType: sortType,
              )
            : SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 32.0),
                        child: Text(
                          'Welcome to Library',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: colors.onBackground,
                          ),
                        ),
                      ),
                      if (_cachedSections != null) ...[
                        _cachedSections[SortType.rating]!,
                        const SizedBox(height: 32),
                        _cachedSections[SortType.date]!,
                      ],
                    ],
                  ),
                ),
              ),
        );
      },
    );
  }

  Widget _buildSection({
    required String title,
    required String subtitle,
    required SortType sortType,
    required IconData icon,
    required CoreColors colors,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          title: title,
          subtitle: subtitle,
          icon: icon,
          onTap: () => _navigateToBooks(context, sortType),
          colors: colors,
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 300,
          child: _buildBooksList(context, sortType: sortType),
        ),
      ],
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    required CoreColors colors,
  }) {
    return InkWell(
      onTap: onTap,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colors.primaryContainer.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: colors.primaryContainer,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: colors.onBackground,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 14,
                          color: colors.textSubtle,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: colors.textSubtle,
          ),
        ],
      ),
    );
  }

  Widget _buildBookRail(BuildContext context, {required SortType sortType, required String title, required String subtitle}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          sortType == SortType.rating ? Icons.star : Icons.new_releases,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onBackground,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () => _navigateToBooks(context, sortType),
                child: Row(
                  children: [
                    Text(
                      'View all',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 280,
          child: ShaderMask(
            shaderCallback: (Rect bounds) {
              return LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Colors.black,
                  Colors.transparent,
                  Colors.transparent,
                  Colors.black,
                ],
                stops: const [0.0, 0.05, 0.95, 1.0],
              ).createShader(bounds);
            },
            blendMode: BlendMode.dstOut,
            child: _buildBooksList(context, sortType: sortType),
          ),
        ),
      ],
    );
  }

  Widget _buildBooksList(BuildContext context, {required SortType sortType}) {
    // Get screen width to determine if we're on mobile
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600; // Common breakpoint for mobile devices
    
    return BlocBuilder<BooksBloc, BooksState>(
      builder: (context, state) {
        if (state is BooksLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is BooksError) {
          return Center(child: Text(state.message));
        }

        if (state is BooksLoaded) {
          final books = List<Book>.from(state.books);

          // Sort books based on type
          if (sortType == SortType.rating) {
            books.sort((a, b) => b.averageRating.compareTo(a.averageRating));
          } else if (sortType == SortType.date) {
            books.sort((a, b) => (b.publishedDate ?? Timestamp.now())
                .compareTo(a.publishedDate ?? Timestamp.now()));
          }

          final displayBooks = books.take(10).toList();

          return ScrollConfiguration(
            behavior: ScrollConfiguration.of(context).copyWith(
              dragDevices: {
                PointerDeviceKind.touch,
                PointerDeviceKind.mouse,
              },
            ),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              physics: const AlwaysScrollableScrollPhysics(),
              dragStartBehavior: DragStartBehavior.down,
              clipBehavior: Clip.none,
              itemCount: displayBooks.length,
              separatorBuilder: (context, index) => SizedBox(width: isMobile ? 8 : 16),
              itemBuilder: (context, index) {
                return SizedBox(
                  width: 180,
                  child: BookCard(
                    book: displayBooks[index],
                    isMobile: false,
                    isAdmin: _isAdmin,
                    userId: _userId ?? '',
                    onDelete: () => _handleBookDelete(context, displayBooks[index]),
                  ),
                );
              },
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  void _handleBookDelete(BuildContext context, Book book) {
    context.read<BooksBloc>().add(DeleteBook(book.id!));
  }

  void _navigateToBooks(BuildContext context, SortType sortType) {
    context.read<NavigationCubit>().navigateToBooks(sortType);
  }
} 
