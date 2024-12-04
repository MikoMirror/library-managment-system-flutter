import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';
import '../models/book.dart';

class BookReservationDialog extends StatefulWidget {
  final String bookId;
  final bool isAdmin;
  final String userId;
  final int booksQuantity;

  const BookReservationDialog({
    super.key,
    required this.bookId,
    required this.isAdmin,
    required this.userId,
    required this.booksQuantity,
  });

  @override
  State<BookReservationDialog> createState() => _BookReservationDialogState();
}

class _BookReservationDialogState extends State<BookReservationDialog> {
  final _firestoreService = FirestoreService();
  DateTime? _borrowedDate;
  DateTime? _dueDate;
  String? _selectedUserId;
  String _selectedStatus = 'pending';
  bool _isLoading = false;
  final TextEditingController _searchController = TextEditingController();
  List<UserModel> _filteredUsers = [];
  bool _isSearching = false;
  final TextEditingController _quantityController = TextEditingController(text: '1');
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _borrowedDate = DateTime.now();
    _dueDate = DateTime.now().add(const Duration(days: 14));
    _selectedUserId = widget.userId;
  }

  @override
  void dispose() {
    _searchController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  void _filterUsers(String query, List<UserModel> allUsers) {
    setState(() {
      if (query.isEmpty) {
        _filteredUsers = allUsers;
      } else {
        _filteredUsers = allUsers
            .where((user) =>
                user.name.toLowerCase().contains(query.toLowerCase()) ||
                user.libraryNumber.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  Future<void> _selectDate(BuildContext context, bool isBorrowedDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isBorrowedDate ? _borrowedDate! : _dueDate!,
      firstDate: isBorrowedDate ? DateTime.now() : _borrowedDate!,
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        if (isBorrowedDate) {
          _borrowedDate = picked;
          if (_dueDate!.isBefore(_borrowedDate!)) {
            _dueDate = _borrowedDate!.add(const Duration(days: 14));
          }
        } else {
          _dueDate = picked;
        }
      });
    }
  }

  Future<void> _createBooking() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isLoading = true);
      
      try {
        final quantity = int.parse(_quantityController.text);
        
        if (quantity <= 0) {
          throw Exception('Please enter a valid quantity');
        }
        
        if (quantity > widget.booksQuantity) {
          throw Exception('Not enough books available (${widget.booksQuantity} remaining)');
        }

        await _firestoreService.updateBookQuantity(widget.bookId, quantity);
        
        await _firestoreService.createBooking(
          userId: _selectedUserId ?? widget.userId,
          bookId: widget.bookId,
          status: _selectedStatus,
          borrowedDate: Timestamp.fromDate(_borrowedDate!),
          dueDate: Timestamp.fromDate(_dueDate!),
          quantity: quantity,
        );

        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Booking created successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString())),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;

    return Dialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 16.0 : 48.0,
        vertical: isSmallScreen ? 24.0 : 48.0,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context),
                const SizedBox(height: 24),
                if (widget.isAdmin) ...[
                  _buildUserSearch(isSmallScreen),
                  const SizedBox(height: 24),
                ],
                _buildDateFields(isSmallScreen),
                const SizedBox(height: 24),
                if (widget.isAdmin) ...[
                  _buildStatusDropdown(),
                  const SizedBox(height: 24),
                ],
                TextFormField(
                  controller: _quantityController,
                  decoration: InputDecoration(
                    labelText: 'Quantity',
                    helperText: '${widget.booksQuantity} books available',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.library_books),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter quantity';
                    }
                    final quantity = int.tryParse(value);
                    if (quantity == null || quantity <= 0) {
                      return 'Please enter a valid quantity';
                    }
                    if (quantity > widget.booksQuantity) {
                      return 'Not enough books available';
                    }
                    return null;
                  },
                ),
                _buildSubmitButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Reserve Book',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }

  Widget _buildUserSearch(bool isSmallScreen) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestoreService.getUsers(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final users = snapshot.data!.docs
            .map((doc) => UserModel.fromMap(doc.data() as Map<String, dynamic>))
            .toList();

        if (!_isSearching) {
          _filteredUsers = users;
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search Users',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _filterUsers('', users);
                          setState(() => _isSearching = false);
                        },
                      )
                    : null,
              ),
              onChanged: (value) {
                setState(() => _isSearching = true);
                _filterUsers(value, users);
              },
              onTap: () {
                setState(() => _isSearching = true);
              },
            ),
            if (_isSearching)
              Container(
                margin: const EdgeInsets.only(top: 8),
                constraints: BoxConstraints(
                  maxHeight: isSmallScreen ? 150 : 200,
                ),
                child: Card(
                  elevation: 4,
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _filteredUsers.length,
                    itemBuilder: (context, index) {
                      final user = _filteredUsers[index];
                      return ListTile(
                        dense: isSmallScreen,
                        title: Text(
                          user.name,
                          style: TextStyle(
                            fontSize: isSmallScreen ? 14 : 16,
                          ),
                        ),
                        subtitle: Text(
                          user.libraryNumber,
                          style: TextStyle(
                            fontSize: isSmallScreen ? 12 : 14,
                          ),
                        ),
                        onTap: () {
                          setState(() {
                            _selectedUserId = user.userId;
                            _searchController.text = user.name;
                            _isSearching = false;
                          });
                        },
                      );
                    },
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildDateFields(bool isSmallScreen) {
    return Column(
      children: [
        _buildDateField(
          label: 'Borrow Date',
          date: _borrowedDate!,
          onTap: () => _selectDate(context, true),
        ),
        const SizedBox(height: 16),
        _buildDateField(
          label: 'Due Date',
          date: _dueDate!,
          onTap: () => _selectDate(context, false),
        ),
      ],
    );
  }

  Widget _buildDateField({
    required String label,
    required DateTime date,
    required VoidCallback onTap,
  }) {
    return TextFormField(
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        suffixIcon: const Icon(Icons.calendar_today),
      ),
      readOnly: true,
      controller: TextEditingController(
        text: DateFormat('yyyy-MM-dd').format(date),
      ),
      onTap: onTap,
    );
  }

  Widget _buildStatusDropdown() {
    return DropdownButtonFormField<String>(
      decoration: const InputDecoration(
        labelText: 'Status',
        border: OutlineInputBorder(),
      ),
      value: _selectedStatus,
      items: ['pending', 'borrowed', 'returned'].map((status) {
        return DropdownMenuItem(
          value: status,
          child: Text(status.toUpperCase()),
        );
      }).toList(),
      onChanged: (value) {
        setState(() => _selectedStatus = value!);
      },
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        onPressed: _isLoading ? null : _createBooking,
        child: _isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Text(
                'Reserve Book',
                style: TextStyle(fontSize: 16),
              ),
      ),
    );
  }
} 