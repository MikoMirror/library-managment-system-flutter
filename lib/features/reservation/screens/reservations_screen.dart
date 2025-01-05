import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/reservation_table.dart';
import '../widgets/reservation_filter_section.dart';
import '../models/reservation.dart';
import '../bloc/reservation_bloc.dart';
import '../cubit/reservation_filter_cubit.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_bar.dart';
import '../../auth/bloc/auth/auth_bloc.dart';
import '../../users/models/user_model.dart';
import '../repositories/reservation_repository.dart';
import '../../../core/theme/cubit/test_mode_cubit.dart';
import '../../../core/services/firestore/reservations_firestore_service.dart';
import '../../../core/services/firestore/users_firestore_service.dart';
import '../../../core/services/firestore/books_firestore_service.dart';
import '../cubit/reservation_selection_cubit.dart';

class ReservationsScreen extends StatelessWidget {
  final ReservationsFirestoreService reservationsService;
  final BooksFirestoreService booksService;
  final UsersFirestoreService usersService;

  const ReservationsScreen({
    super.key,
    required this.reservationsService,
    required this.booksService,
    required this.usersService,
  });

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => ReservationSelectionCubit()),
        BlocProvider(create: (context) => ReservationFilterCubit()),
        BlocProvider(
          create: (context) => ReservationBloc(
            repository: ReservationsRepository(
              reservationsService: reservationsService,
              booksService: booksService,
              usersService: usersService,
            ),
          )..add(LoadReservations()),
        ),
      ],
      child: Builder(
        builder: (context) {
          return BlocBuilder<ReservationSelectionCubit, ReservationSelectionState>(
            builder: (context, selectionState) {
              return Scaffold(
                appBar: UnifiedAppBar(
                  title: Text(
                    selectionState.isSelectionMode
                      ? '${selectionState.selectedIds.length} selected'
                      : 'Reservations',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  actions: [
                    if (selectionState.isSelectionMode) ...[
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (dialogContext) => AlertDialog(
                              title: const Text('Delete Reservations'),
                              content: Text(
                                'Delete ${selectionState.selectedIds.length} selected reservations?'
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(dialogContext),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(dialogContext);
                                    // Delete all selected reservations
                                    for (final id in selectionState.selectedIds) {
                                      context.read<ReservationBloc>()
                                        .add(DeleteReservation(reservationId: id));
                                    }
                                    context.read<ReservationSelectionCubit>().clearSelection();
                                  },
                                  child: const Text('Delete'),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          context.read<ReservationSelectionCubit>().clearSelection();
                        },
                      ),
                    ],
                  ],
                  bottom: PreferredSize(
                    preferredSize: Size.fromHeight(
                      MediaQuery.of(context).size.width < 600 ? 56 : 72
                    ),
                    child: const ReservationFilterSection(),
                  ),
                  searchHint: 'Search reservations...',
                  onSearch: (query) {
                    context.read<ReservationBloc>().add(SearchReservations(query));
                  },
                  isSimple: false,
                ),
                backgroundColor: Theme.of(context).brightness == Brightness.dark 
                  ? AppTheme.dark.background 
                  : AppTheme.light.background,
                body: _ReservationsScreenContent(
                  reservationsService: reservationsService,
                  booksService: booksService,
                  usersService: usersService,
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _ReservationsScreenContent extends StatelessWidget {
  final ReservationsFirestoreService reservationsService;
  final BooksFirestoreService booksService;
  final UsersFirestoreService usersService;

  const _ReservationsScreenContent({
    required this.reservationsService,
    required this.booksService,
    required this.usersService,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        if (authState is! AuthSuccess) {
          return const Center(child: CircularProgressIndicator());
        }

        return StreamBuilder<DocumentSnapshot>(
          stream: usersService.getUserStream(authState.user.uid),
          builder: (context, userSnapshot) {
            if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
              return const Center(child: CircularProgressIndicator());
            }

            final userData = userSnapshot.data!.data();
            if (userData == null) {
              return const Center(
                child: Text('User data not found'),
              );
            }

            final userModel = UserModel.fromMap(userData as Map<String, dynamic>);
            final isAdmin = userModel.role == 'admin';

            return Column(
              children: [
                if (isAdmin) ...[
                  BlocBuilder<TestModeCubit, bool>(
                    builder: (context, isTestMode) {
                      if (!isTestMode) return const SizedBox.shrink();
                      
                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 8.0
                        ),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final isSmallScreen = constraints.maxWidth < 600;
                            
                            return Center(
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxWidth: isSmallScreen ? double.infinity : 300,
                                ),
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    final repository = context.read<ReservationsRepository>();
                                    repository.checkExpiredReservations();
                                    repository.checkAndUpdateOverdueReservations();
                                    
                                    context.read<ReservationBloc>().add(LoadReservations());
                                    
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Reservation statuses have been updated'),
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.refresh),
                                  label: Text(
                                    isSmallScreen ? 'Update Status' : 'Force Status Update',
                                    textAlign: TextAlign.center,
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Theme.of(context).colorScheme.error,
                                    foregroundColor: Colors.white,
                                    padding: EdgeInsets.symmetric(
                                      vertical: isSmallScreen ? 12 : 16,
                                      horizontal: isSmallScreen ? 16 : 24,
                                    ),
                                    minimumSize: Size(
                                      isSmallScreen ? double.infinity : 200,
                                      0,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ],
                Expanded(
                  child: BlocBuilder<ReservationBloc, ReservationState>(
                    builder: (context, state) {
                      if (state is ReservationsLoaded) {
                        return BlocBuilder<ReservationFilterCubit, ReservationFilter>(
                          builder: (context, filter) {
                            final filteredReservations = _filterReservations(
                              state.reservations,
                              filter,
                              isAdmin,
                              authState.user.uid,
                            );
                            
                            return ReservationTable(
                              reservations: filteredReservations,
                              isAdmin: isAdmin,
                              onStatusChange: (reservationId, newStatus) {
                                context.read<ReservationBloc>().add(
                                  UpdateReservationStatus(
                                    reservationId: reservationId,
                                    newStatus: newStatus,
                                  ),
                                );
                              },
                              onDelete: (reservationId) {
                                context.read<ReservationBloc>().add(
                                  DeleteReservation(reservationId: reservationId),
                                );
                              },
                            );
                          },
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  List<Reservation> _filterReservations(
    List<Reservation> reservations,
    ReservationFilter filter,
    bool isAdmin,
    String userId,
  ) {
    // First filter by user if not admin
    final filteredByUser = isAdmin 
        ? reservations 
        : reservations.where((b) => b.userId == userId).toList();

    // Then apply status filter
    switch (filter) {
      case ReservationFilter.reserved:
        return filteredByUser.where((b) => b.status == 'reserved').toList();
      case ReservationFilter.borrowed:
        return filteredByUser.where((b) => b.status == 'borrowed' && !b.isOverdue).toList();
      case ReservationFilter.returned:
        return filteredByUser.where((b) => b.status == 'returned').toList();
      case ReservationFilter.overdue:
        return filteredByUser.where((b) => b.isOverdue).toList();
      case ReservationFilter.expired:
        return filteredByUser.where((b) => b.status == 'expired').toList();
      case ReservationFilter.canceled:
        return filteredByUser.where((b) => b.status == 'canceled').toList();
      case ReservationFilter.all:
      default:
        return filteredByUser;
    }
  }
}
  