import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/reservation_table.dart';
import '../widgets/reservation_filter_section.dart';
import '../models/reservation.dart';
import '../bloc/reservation_bloc.dart';
import '../cubit/reservation_filter_cubit.dart';
import '../../../core/services/database/firestore_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../auth/bloc/auth/auth_bloc.dart';
import '../../users/models/user_model.dart';
import '../repositories/reservation_repository.dart';
import '../../../core/widgets/custom_app_bar.dart';


class ReservationsScreen extends StatelessWidget {
  final FirestoreService firestoreService = FirestoreService();

  ReservationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => ReservationFilterCubit()),
        BlocProvider(
          create: (context) => ReservationBloc(
            repository: ReservationsRepository(firestore: FirebaseFirestore.instance),
          )..add(LoadReservations()),
        ),
      ],
      child: Scaffold(
        appBar: CustomAppBar(
          title: Text(
            'Reservations',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(80),
            child: ReservationFilterSection(),
          ),
        ),
        backgroundColor: isDarkMode 
          ? AppTheme.dark.background 
          : AppTheme.light.background,
        body: _ReservationsScreenContent(firestoreService: firestoreService),
      ),
    );
  }
}

class _ReservationsScreenContent extends StatelessWidget {
  final FirestoreService firestoreService;

  const _ReservationsScreenContent({required this.firestoreService});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        if (authState is! AuthSuccess) {
          return const Center(child: CircularProgressIndicator());
        }

        return StreamBuilder<DocumentSnapshot>(
          stream: firestoreService.getUserStream(authState.user.uid),
          builder: (context, userSnapshot) {
            if (!userSnapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final userData = userSnapshot.data!.data() as Map<String, dynamic>;
            final userModel = UserModel.fromMap(userData);
            final isAdmin = userModel.role == 'admin';

            return Column(
              children: [
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
      case ReservationFilter.all:
      default:
        return filteredByUser;
    }
  }
}
  