import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../bloc/booking_bloc.dart';
import '../../users/models/user_model.dart';
import '../../books/models/book.dart';
import '../../../core/services/database/firestore_service.dart';

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
  final _quantityController = TextEditingController(text: '1');
  String? _selectedUserId;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 600;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: isDesktop ? 500 : double.infinity,
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

              // User Selection for Admin
              if (widget.isAdmin) ...[
                StreamBuilder<QuerySnapshot>(
                  stream: FirestoreService().getUsers(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const CircularProgressIndicator();
                    }

                    final users = snapshot.data!.docs
                        .map((doc) => UserModel.fromMap(doc.data() as Map<String, dynamic>))
                        .where((user) => user.role != 'admin')
                        .toList();

                    return DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Select User',
                        border: OutlineInputBorder(),
                      ),
                      value: _selectedUserId,
                      items: users.map((user) {
                        return DropdownMenuItem(
                          value: user.userId,
                          child: Text(user.name),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() => _selectedUserId = value);
                      },
                      validator: (value) {
                        if (value == null) return 'Please select a user';
                        return null;
                      },
                    );
                  },
                ),
                const SizedBox(height: 16),
              ],

              BlocConsumer<BookingBloc, BookingState>(
                listener: (context, state) {
                  if (state is BookingSuccess) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Book reserved successfully')),
                    );
                  } else if (state is BookingError) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(state.message)),
                    );
                  }
                },
                builder: (context, state) {
                  return SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: state is BookingLoading
                          ? null
                          : () {
                              if (_formKey.currentState?.validate() ?? false) {
                                context.read<BookingBloc>().add(
                                      CreateBooking(
                                        userId: widget.userId,
                                        bookId: widget.book.id!,
                                        quantity: int.parse(_quantityController.text),
                                        selectedUserId: widget.isAdmin ? _selectedUserId : null,
                                      ),
                                    );
                              }
                            },
                      child: state is BookingLoading
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
            ],
          ),
        ),
      ),
    );
  }
} 