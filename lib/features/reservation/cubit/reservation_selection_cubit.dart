import 'package:flutter_bloc/flutter_bloc.dart';

class ReservationSelectionState {
  final bool isSelectionMode;
  final Set<String> selectedIds;

  ReservationSelectionState({
    this.isSelectionMode = false,
    Set<String>? selectedIds,
  }) : selectedIds = selectedIds ?? {};

  ReservationSelectionState copyWith({
    bool? isSelectionMode,
    Set<String>? selectedIds,
  }) {
    return ReservationSelectionState(
      isSelectionMode: isSelectionMode ?? this.isSelectionMode,
      selectedIds: selectedIds ?? this.selectedIds,
    );
  }
}

class ReservationSelectionCubit extends Cubit<ReservationSelectionState> {
  ReservationSelectionCubit() : super(ReservationSelectionState());

  void toggleSelectionMode() {
    if (state.isSelectionMode) {
      // Exit selection mode and clear selections
      emit(ReservationSelectionState());
    } else {
      // Enter selection mode
      emit(state.copyWith(isSelectionMode: true));
    }
  }

  void toggleReservationSelection(String reservationId) {
    final selectedIds = Set<String>.from(state.selectedIds);
    if (selectedIds.contains(reservationId)) {
      selectedIds.remove(reservationId);
    } else {
      selectedIds.add(reservationId);
    }

    // If no items are selected, exit selection mode
    if (selectedIds.isEmpty) {
      emit(ReservationSelectionState());
    } else {
      emit(state.copyWith(selectedIds: selectedIds));
    }
  }

  void clearSelection() {
    emit(ReservationSelectionState());
  }
} 