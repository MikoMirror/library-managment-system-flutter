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
    final now = DateTime.now();
    _borrowedDateController.text = DateFormat('yyyy-MM-dd').format(now);

    // Get the max advance days from settings
    final settingsService = context.read<LibrarySettingsService>();
    final maxAdvanceDays = await settingsService.getMaxAdvanceReservationDays().first;
    
    // Set due date based on the settings
    final dueDate = now.add(Duration(days: maxAdvanceDays));
    _dueDateController.text = DateFormat('yyyy-MM-dd').format(dueDate);
  }

  Future<void> _selectDate(BuildContext context, TextEditingController controller) async {
    final now = DateTime.now();
    
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
      firstDate: now,
      lastDate: lastAllowedDate,
      selectableDayPredicate: (DateTime date) {
        // Allow selection only up to maxAdvanceDays from now
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
    final screenHeight = MediaQuery.of(context).size.height;
    final isDesktop = screenWidth > 600;

    return BlocBuilder<TestModeCubit, bool>(
      builder: (context, isTestMode) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Container(
            width: isDesktop ? 500 : double.infinity,
            constraints: BoxConstraints(
              maxHeight: screenHeight * 0.8,
              maxWidth: isDesktop ? 500 : screenWidth * 0.9,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Reserve ${widget.book.title}',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 24),
                            
                            // Add Test Mode Switch for admin
                            if (widget.isAdmin && isTestMode) ...[
                              SwitchListTile(
                                title: const Text('Test Mode'),
                                subtitle: const Text('Allow selecting past dates'),
                                value: isTestMode,
                                onChanged: null, // Disabled because it's controlled from settings
                              ),
                              const SizedBox(height: 16),
                            ],

                            // Quantity Field
                            TextFormField(
                              controller: _quantityController,
                              decoration: const InputDecoration(
                                labelText: 'Quantity',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter quantity';
                                }
                                final quantity = int.tryParse(value);
                                if (quantity == null || quantity < 1) {
                                  return 'Please enter a valid quantity';
                                }
                                if (quantity > widget.book.booksQuantity) {
                                  return 'Not enough books available';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // Date Fields
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _borrowedDateController,
                                    decoration: InputDecoration(
                                      labelText: 'Borrow Date',
                                      border: const OutlineInputBorder(),
                                      suffixIcon: IconButton(
                                        icon: const Icon(Icons.calendar_today),
                                        onPressed: () => _selectDate(context, _borrowedDateController),
                                      ),
                                    ),
                                    readOnly: true,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) return 'Please select borrow date';
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: TextFormField(
                                    controller: _dueDateController,
                                    decoration: InputDecoration(
                                      labelText: 'Due Date',
                                      border: const OutlineInputBorder(),
                                      suffixIcon: IconButton(
                                        icon: const Icon(Icons.calendar_today),
                                        onPressed: () => _selectDate(context, _dueDateController),
                                      ),
                                    ),
                                    readOnly: true,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) return 'Please select due date';
                                      return null;
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Keep existing user selection code
                            if (widget.isAdmin) ...[
                              StreamBuilder<List<UserModel>>(
                                stream: _usersService.getUsersStream(),
                                builder: (context, snapshot) {
                                  if (!snapshot.hasData) {
                                    return const CircularProgressIndicator();
                                  }

                                  final users = snapshot.data!
                                      .where((user) => user.role != 'admin')
                                      .where((user) => 
                                        user.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                                        user.libraryNumber.toLowerCase().contains(_searchQuery.toLowerCase())
                                      )
                                      .toList();

                                  return Column(
                                    children: [
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
                                          child: ListView.builder(
                                            shrinkWrap: true,
                                            itemCount: users.length,
                                            itemBuilder: (context, index) {
                                              final user = users[index];
                                              return ListTile(
                                                title: Text(user.name),
                                                subtitle: Text('Library #: ${user.libraryNumber}'),
                                                selected: _selectedUserId == user.userId,
                                                onTap: () {
                                                  setState(() => _selectedUserId = user.userId);
                                                },
                                              );
                                            },
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                              const SizedBox(height: 16),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                // Submit button in a fixed bottom container
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    border: Border(
                      top: BorderSide(
                        color: Theme.of(context).dividerColor,
                      ),
                    ),
                  ),
                  child: BlocConsumer<ReservationBloc, ReservationState>(
                    listener: (context, state) {
                      if (state is ReservationSuccess) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Book reserved successfully')),
                        );
                      } else if (state is ReservationError) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(state.message)),
                        );
                      }
                    },
                    builder: (context, state) {
                      return SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: state is ReservationLoading
                              ? null
                              : () {
                                  if (_formKey.currentState?.validate() ?? false) {
                                    final borrowedDate = DateFormat('dd/MM/yyyy')
                                        .parse(_borrowedDateController.text);
                                    final dueDate = DateFormat('dd/MM/yyyy')
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
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
} 