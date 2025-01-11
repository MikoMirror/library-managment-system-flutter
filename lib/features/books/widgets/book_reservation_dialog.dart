import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../reservation/bloc/reservation_bloc.dart';
import '../../users/models/user_model.dart';
import '../models/book.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/cubit/test_mode_cubit.dart';
import '../../../core/services/firestore/users_firestore_service.dart';
import '../../../features/settings/services/library_settings_service.dart';


class BookBookingDialog extends StatefulWidget {
  final Book book;
  final bool isAdmin;
  final String userId;

  const BookBookingDialog({
    super.key,
    required this.book,
    required this.isAdmin,
    required this.userId,
  });

  @override
  State<BookBookingDialog> createState() => _BookBookingDialogState();
}

class _BookBookingDialogState extends State<BookBookingDialog> {
  final _formKey = GlobalKey<FormState>();
  final _usersService = UsersFirestoreService();
  final _quantityController = TextEditingController(text: '1');
  String? _selectedUserId;
  final _borrowedDateController = TextEditingController();
  final _dueDateController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeDates();
    });
  }

  Future<void> _initializeDates() async {
    if (!mounted) return;
    
    final now = DateTime.now();
    _borrowedDateController.text = DateFormat('yyyy-MM-dd').format(now);

    final settingsService = context.read<LibrarySettingsService>();
    final maxAdvanceDays = await settingsService.getMaxAdvanceReservationDays().first;
    
    if (!mounted) return;
    
    // Set due date based on the settings
    final dueDate = now.add(Duration(days: maxAdvanceDays));
    _dueDateController.text = DateFormat('yyyy-MM-dd').format(dueDate);
  }

  Future<void> _selectDate(BuildContext context, TextEditingController controller) async {
    final now = DateTime.now();
    
    // Read test mode state
    final isTestMode = context.read<TestModeCubit>().state;
    
    // Get the max advance days from settings
    final maxAdvanceDays = await context
        .read<LibrarySettingsService>()
        .getMaxAdvanceReservationDays()
        .first;
    
    final lastAllowedDate = DateTime(
      now.year,
      now.month,
      now.day + maxAdvanceDays,
    );

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: now,
      // In test mode, allow dates from 2 years ago to 2 years in future
      firstDate: isTestMode 
          ? DateTime(now.year - 2)
          : now,
      lastDate: isTestMode 
          ? DateTime(now.year + 2)
          : lastAllowedDate,
      selectableDayPredicate: isTestMode 
          ? null  // No restrictions in test mode
          : (DateTime date) {
              return date.isBefore(lastAllowedDate.add(const Duration(days: 1)));
            },
    );

    if (picked != null) {
      setState(() {
        controller.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 600;

    return BlocBuilder<TestModeCubit, bool>(
      builder: (context, isTestMode) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: SizedBox(
            width: isDesktop ? 600 : double.infinity,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isTestMode)
                  Container(
                    color: Colors.red.shade100,
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    child: Row(
                      children: [
                        const Icon(Icons.warning, color: Colors.red),
                        const SizedBox(width: 8),
                        Text(
                          'Test Mode Active',
                          style: TextStyle(color: Colors.red.shade900),
                        ),
                      ],
                    ),
                  ),
                if (widget.isAdmin) ...[
                  Flexible(
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Header
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Reserve ${widget.book.title}',
                                      style: Theme.of(context).textTheme.titleLarge,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.close),
                                    onPressed: () => Navigator.pop(context),
                                    padding: EdgeInsets.zero,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // User Selection
                              TextFormField(
                                decoration: const InputDecoration(
                                  labelText: 'Search User',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.search),
                                ),
                                onChanged: (value) {
                                  setState(() => _searchQuery = value);
                                },
                              ),
                              const SizedBox(height: 8),
                              Container(
                                constraints: const BoxConstraints(maxHeight: 200),
                                child: Card(
                                  child: StreamBuilder<List<UserModel>>(
                                    stream: _usersService.getUsersStream(),
                                    builder: (context, snapshot) {
                                      if (!snapshot.hasData) {
                                        return const Center(child: CircularProgressIndicator());
                                      }

                                      final users = snapshot.data!
                                          .where((user) => user.role != 'admin')
                                          .where((user) => 
                                            user.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                                            user.libraryNumber.toLowerCase().contains(_searchQuery.toLowerCase())
                                          )
                                          .toList();

                                      return ListView.builder(
                                        shrinkWrap: true,
                                        itemCount: users.length,
                                        itemBuilder: (context, index) {
                                          final user = users[index];
                                          return ListTile(
                                            dense: true,
                                            title: Text(user.name),
                                            subtitle: Text('Library #: ${user.libraryNumber}'),
                                            selected: _selectedUserId == user.userId,
                                            onTap: () {
                                              setState(() => _selectedUserId = user.userId);
                                            },
                                          );
                                        },
                                      );
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Regular form fields
                              _buildFormFields(),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ] else ...[
                  // Non-admin view
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Reserve ${widget.book.title}',
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: () => Navigator.pop(context),
                                padding: EdgeInsets.zero,
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildFormFields(),
                        ],
                      ),
                    ),
                  ),
                ],

                // Submit button - same for both views
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: _buildSubmitButton(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFormFields() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Quantity Field
        TextFormField(
          controller: _quantityController,
          decoration: const InputDecoration(
            labelText: 'Quantity',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.library_books),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value == null || value.isEmpty) return 'Required';
            final quantity = int.tryParse(value);
            if (quantity == null || quantity < 1) return 'Invalid quantity';
            if (quantity > widget.book.booksQuantity) return 'Not enough books';
            return null;
          },
        ),
        const SizedBox(height: 16),

        // Date Fields
        TextFormField(
          controller: _borrowedDateController,
          decoration: InputDecoration(
            labelText: 'Borrow Date',
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.calendar_today),
            suffixIcon: IconButton(
              icon: const Icon(Icons.edit_calendar),
              onPressed: () => _selectDate(context, _borrowedDateController),
              padding: EdgeInsets.zero,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
          readOnly: true,
          validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _dueDateController,
          decoration: InputDecoration(
            labelText: 'Due Date',
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.event_outlined),
            suffixIcon: IconButton(
              icon: const Icon(Icons.edit_calendar),
              onPressed: () => _selectDate(context, _dueDateController),
              padding: EdgeInsets.zero,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
          readOnly: true,
          validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return BlocConsumer<ReservationBloc, ReservationState>(
      listener: (context, state) {
        if (state is ReservationSuccess) {
          // Close dialog on success
          Navigator.of(context).pop();
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Book reserved successfully')),
          );
        } else if (state is ReservationError) {
          // Show error message but keep dialog open
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
      },
      builder: (context, state) {
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            onPressed: state is ReservationLoading 
              ? null  // Disable button while loading
              : () {
                  if (_formKey.currentState?.validate() ?? false) {
                    // For admin, validate user selection
                    if (widget.isAdmin && _selectedUserId == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please select a user')),
                      );
                      return;
                    }

                    final borrowedDate = DateFormat('yyyy-MM-dd')
                        .parse(_borrowedDateController.text);
                    final dueDate = DateFormat('yyyy-MM-dd')
                        .parse(_dueDateController.text);
                    
                    context.read<ReservationBloc>().add(
                          CreateReservation(
                            userId: widget.userId,
                            bookId: widget.book.id!,
                            quantity: int.parse(_quantityController.text),
                            selectedUserId: widget.isAdmin ? _selectedUserId : null,
                            borrowedDate: Timestamp.fromDate(borrowedDate),
                            dueDate: Timestamp.fromDate(dueDate),
                          ),
                        );
                  }
                },
            child: state is ReservationLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Reserve Book'),
          ),
        );
      },
    );
  }
} 