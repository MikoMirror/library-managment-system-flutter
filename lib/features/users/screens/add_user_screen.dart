import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../bloc/users_bloc.dart';
import '../bloc/users_event.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';

class AddUserScreen extends StatefulWidget {
  final bool isAdmin;
  final UserModel? userToEdit;

  const AddUserScreen({
    super.key,
    required this.isAdmin,
    this.userToEdit,
  });

  @override
  State<AddUserScreen> createState() => _AddUserScreenState();
}

class _AddUserScreenState extends State<AddUserScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _peselController = TextEditingController();
  String _selectedRole = 'member';
  bool _isLoading = false;
  bool _showPassword = false;
  String? _adminEmail;

  bool get isEditing => widget.userToEdit != null;

  @override
  void initState() {
    super.initState();
    _loadAdminCredentials();
    _selectedRole = widget.isAdmin ? 'admin' : 'member';
    
    if (isEditing) {
      _nameController.text = widget.userToEdit!.name;
      _emailController.text = widget.userToEdit!.email;
      _phoneController.text = widget.userToEdit!.phoneNumber;
      _peselController.text = widget.userToEdit!.pesel;
      _selectedRole = widget.userToEdit!.role;
    }
  }

  Future<void> _loadAdminCredentials() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      setState(() {
        _adminEmail = currentUser.email;
      });
    }
  }

  Future<String?> _getAdminPassword() async {
    String? password;
    if (_adminEmail != null) {
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Admin Authentication'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Please enter your admin password to continue'),
              const SizedBox(height: 16),
              TextField(
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Admin Password',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) => password = value,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                password = null;
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Confirm'),
            ),
          ],
        ),
      );
    }
    return password;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _peselController.dispose();
    super.dispose();
  }

  Future<void> _saveUser() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isLoading = true);
      try {
        final adminPassword = await _getAdminPassword();
        if (adminPassword == null && _adminEmail != null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Admin password required'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }

        if (isEditing) {
          context.read<UsersBloc>().add(UpdateUser(
            userId: widget.userToEdit!.userId,
            name: _nameController.text.trim(),
            phoneNumber: _phoneController.text.trim(),
            pesel: _peselController.text.trim(),
            email: _emailController.text.trim(),
            role: _selectedRole,
            adminEmail: _adminEmail,
            adminPassword: adminPassword,
          ));
        } else {
          context.read<UsersBloc>().add(CreateUser(
            name: _nameController.text.trim(),
            phoneNumber: _phoneController.text.trim(),
            pesel: _peselController.text.trim(),
            email: _emailController.text.trim(),
            password: _passwordController.text,
            role: _selectedRole,
            adminEmail: _adminEmail,
            adminPassword: adminPassword,
          ));
        }

        if (mounted) {
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
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
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing 
          ? 'Edit User' 
          : (widget.isAdmin ? 'Add Admin' : 'Add User')),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CustomTextField(
                label: 'Full Name',
                controller: _nameController,
                prefixIcon: const Icon(Icons.person),
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Please enter full name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Email',
                controller: _emailController,
                prefixIcon: const Icon(Icons.email),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Please enter email';
                  }
                  if (!value!.contains('@')) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              if (!isEditing) ...[
                CustomTextField(
                  label: 'Password',
                  controller: _passwordController,
                  prefixIcon: const Icon(Icons.lock),
                  obscureText: !_showPassword,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _showPassword ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        _showPassword = !_showPassword;
                      });
                    },
                  ),
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return 'Please enter password';
                    }
                    if (value!.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
              ],
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Phone Number',
                controller: _phoneController,
                prefixIcon: const Icon(Icons.phone),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Please enter phone number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'PESEL',
                controller: _peselController,
                prefixIcon: const Icon(Icons.numbers),
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Please enter PESEL';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              if (!widget.isAdmin) // Only show role dropdown if not adding an admin
                DropdownButtonFormField<String>(
                  value: _selectedRole,
                  decoration: const InputDecoration(
                    labelText: 'Role',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.admin_panel_settings),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'member',
                      child: Text('Member'),
                    ),
                    DropdownMenuItem(
                      value: 'admin',
                      child: Text('Admin'),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedRole = value!;
                    });
                  },
                ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _saveUser,
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : Text(isEditing ? 'Save Changes' : 'Add ${widget.isAdmin ? 'Admin' : 'User'}'),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 