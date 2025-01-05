import 'package:flutter/material.dart';
import '../models/book.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/book_cover_selector_widget.dart';
import '../constants/language_constants.dart';
import '../widgets/language_management_dialog.dart';
import 'dart:async';
import '../utils/book_cover_utils.dart';
import '../../../core/services/firestore/books_firestore_service.dart';
import '../constants/book_genres.dart';
import '../widgets/genre_management_dialog.dart';

enum FormMode { add, edit }

class BookFormScreen extends StatefulWidget {
  final String collectionId;
  final Book? book;
  final FormMode mode;

  const BookFormScreen({
    required this.collectionId,
    this.book,
    required this.mode,
    super.key,
  });

  @override
  State<BookFormScreen> createState() => BookFormScreenState();
}

class BookFormScreenState extends State<BookFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _booksService = BooksFirestoreService();
  bool _isLoading = false;

  late TextEditingController _titleController;
  late TextEditingController _authorController;
  late TextEditingController _isbnController;
  late TextEditingController _descriptionController;
  final List<String> _selectedCategories = [];
  late TextEditingController _pageCountController;
  late TextEditingController _publishedDateController;
  late TextEditingController _quantityController;

  Timestamp? _selectedDate;
  String? _imageUrl;
  String _selectedLanguage = LanguageConstants.defaultLanguage;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _initializeLanguage();
    
    // Add listener to ISBN controller
    _isbnController.addListener(_onIsbnChanged);

    final book = widget.book;
    if (book != null) {
      _selectedCategories.addAll(book.categories);
    }
  }

  @override
  void dispose() {
    _isbnController.removeListener(_onIsbnChanged);
    _titleController.dispose();
    _authorController.dispose();
    _isbnController.dispose();
    _descriptionController.dispose();
    _pageCountController.dispose();
    _publishedDateController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  void _initializeLanguage() {
    if (widget.book != null) {
      _selectedLanguage = LanguageConstants.isValidLanguage(widget.book!.language)
          ? widget.book!.language
          : LanguageConstants.defaultLanguage;
    }
  }

  void _initializeControllers() {
    final book = widget.book;

    _titleController = TextEditingController(text: book?.title ?? '');
    _authorController = TextEditingController(text: book?.author ?? '');
    _isbnController = TextEditingController(text: book?.isbn ?? '');
    _descriptionController = TextEditingController(text: book?.description ?? '');
    _pageCountController = TextEditingController(text: book?.pageCount.toString() ?? '');
    _quantityController = TextEditingController(text: book?.booksQuantity.toString() ?? '0');

    _selectedDate = book?.publishedDate;
    
    // Initialize image URL from book or generate new one if ISBN exists
    if (book?.externalImageUrl != null) {
      _imageUrl = book?.externalImageUrl;
    } else if (book?.isbn != null && book!.isbn.isNotEmpty) {
      _imageUrl = BookCoverUtils.getOpenLibraryCover(
        book.isbn,
        size: CoverSize.large,
      );
    }

    _publishedDateController = TextEditingController(
      text: book?.publishedDate != null
          ? DateFormat('yyyy-MM-dd').format(book!.publishedDate!.toDate())
          : '',
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate?.toDate() ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (picked != null && picked != _selectedDate?.toDate()) {
      setState(() {
        _selectedDate = Timestamp.fromDate(picked);
        _publishedDateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final bookData = Book(
          id: widget.book?.id,
          title: _titleController.text,
          author: _authorController.text,
          isbn: _isbnController.text,
          description: _descriptionController.text,
          categories: _selectedCategories,
          pageCount: int.tryParse(_pageCountController.text) ?? 0,
          booksQuantity: int.tryParse(_quantityController.text) ?? 0,
          publishedDate: _selectedDate,
          language: _selectedLanguage,
          ratings: widget.book?.ratings ?? {},
          externalImageUrl: _imageUrl,
        );

        if (widget.mode == FormMode.edit) {
          await _booksService.updateBook(bookData);
        } else {
          await _booksService.addBook(bookData);
        }

        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                widget.mode == FormMode.edit
                    ? 'Book updated successfully'
                    : 'Book added successfully',
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  // Add debounce timer
  Timer? _debounceTimer;

  void _onIsbnChanged() {
    // Cancel previous timer if it exists
    _debounceTimer?.cancel();
    
    // Set new timer
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (_isbnController.text.isNotEmpty) {
        setState(() {
          _imageUrl = BookCoverUtils.getOpenLibraryCover(
            _isbnController.text,
            size: CoverSize.large,
          );
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Add responsive breakpoint
    final isDesktop = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.mode == FormMode.edit ? 'Edit Book' : 'Add Book'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Container(
            // Constrain width on desktop
            constraints: BoxConstraints(maxWidth: isDesktop ? 800 : double.infinity),
            child: Form(
              key: _formKey,
              child: Column(
                children: <Widget>[
                  // Book image section
                  Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        children: [
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              BookCoverSelector(
                                initialUrl: _imageUrl,
                                isbn: _isbnController.text,
                                onCoverSelected: (String url) {
                                  WidgetsBinding.instance.addPostFrameCallback((_) {
                                    if (mounted) {
                                      setState(() {
                                        _imageUrl = url;
                                      });
                                    }
                                  });
                                },
                              ),
                              if (_isLoading)
                                Container(
                                  width: 200,
                                  height: 300,
                                  decoration: BoxDecoration(
                                    color: Colors.black.withAlpha(179),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Book Cover',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Form fields section
                  Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          // Basic info section
                          Text(
                            'Basic Information',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 16),
                          if (isDesktop) _buildDesktopFields() else _buildMobileFields(),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Submit button
                  SizedBox(
                    width: isDesktop ? 200 : double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submitForm,
                      child: _isLoading
                          ? const CircularProgressIndicator()
                          : Text(
                              widget.mode == FormMode.edit ? 'Save Changes' : 'Add Book',
                              style: const TextStyle(fontSize: 16),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopFields() {
    return Column(
      children: [
        // First row: Title and Author
        Row(
          children: [
            Expanded(
              child: _buildTextField(_titleController, 'Title', required: true),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildTextField(_authorController, 'Author', required: true),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        // Second row: ISBN centered
        SizedBox(
          width: MediaQuery.of(context).size.width * 0.4, // Adjust width as needed
          child: _buildTextField(_isbnController, 'ISBN'),
        ),
        const SizedBox(height: 16),
        
        // Third row: Categories full width
        _buildCategoriesField(),
        const SizedBox(height: 16),
        
        // Fourth row: Page Count and Quantity
        Row(
          children: [
            Expanded(
              child: _buildTextField(_pageCountController, 'Page Count', 
                  keyboardType: TextInputType.number),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildTextField(_quantityController, 'Quantity', 
                  keyboardType: TextInputType.number),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        // Fifth row: Published Date and Language
        Row(
          children: [
            Expanded(
              child: _buildDatePicker(),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildLanguageDropdown(),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        // Description takes full width
        _buildTextField(_descriptionController, 'Description', maxLines: 3),
      ],
    );
  }

  Widget _buildMobileFields() {
    return Column(
      children: [
        _buildTextField(_titleController, 'Title', required: true),
        const SizedBox(height: 16),
        _buildTextField(_authorController, 'Author', required: true),
        const SizedBox(height: 16),
        _buildTextField(_isbnController, 'ISBN'),
        const SizedBox(height: 16),
        _buildCategoriesField(),
        const SizedBox(height: 16),
        _buildTextField(_pageCountController, 'Page Count', 
            keyboardType: TextInputType.number),
        const SizedBox(height: 16),
        _buildTextField(_quantityController, 'Quantity', 
            keyboardType: TextInputType.number),
        const SizedBox(height: 16),
        _buildDatePicker(),
        const SizedBox(height: 16),
        _buildTextField(_descriptionController, 'Description', maxLines: 3),
        const SizedBox(height: 16),
        _buildLanguageDropdown(),
      ],
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    bool required = false,
    int? maxLines,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        filled: true,
      ),
      maxLines: maxLines ?? 1,
      keyboardType: keyboardType,
      validator: required
          ? (value) => value == null || value.isEmpty
              ? 'Please enter ${label.toLowerCase()}'
              : null
          : null,
    );
  }

  Widget _buildDatePicker() {
    return GestureDetector(
      onTap: () => _selectDate(context),
      child: AbsorbPointer(
        child: TextFormField(
          controller: _publishedDateController,
          decoration: const InputDecoration(
            labelText: 'Published Date',
            border: OutlineInputBorder(),
            filled: true,
            suffixIcon: Icon(Icons.calendar_today),
          ),
          enabled: false,
        ),
      ),
    );
  }

  Widget _buildLanguageDropdown() {
    if (!LanguageConstants.isValidLanguage(_selectedLanguage)) {
      setState(() {
        _selectedLanguage = LanguageConstants.defaultLanguage;
      });
    }

    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<String>(
            value: _selectedLanguage,
            decoration: const InputDecoration(
              labelText: 'Language',
              border: OutlineInputBorder(),
              filled: true,
            ),
            items: LanguageConstants.getActiveLanguages()
                .map((lang) => DropdownMenuItem(
                      value: lang.code,
                      child: Text('${lang.name} (${lang.code.toUpperCase()})'),
                    ))
                .toList(),
            onChanged: (value) {
              if (value != null && LanguageConstants.isValidLanguage(value)) {
                setState(() {
                  _selectedLanguage = value;
                });
              }
            },
            validator: (value) => value == null || !LanguageConstants.isValidLanguage(value)
                ? 'Please select a valid language'
                : null,
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: const Icon(Icons.settings),
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => const LanguageManagementDialog(),
            ).then((_) => setState(() {})); // Refresh the dropdown after dialog closes
          },
          tooltip: 'Manage Languages',
        ),
      ],
    );
  }

  Widget _buildCategoriesField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Categories', style: Theme.of(context).textTheme.titleMedium),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.settings),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => const GenreManagementDialog(),
                    ).then((_) => setState(() {}));
                  },
                  tooltip: 'Manage Genres',
                ),
                TextButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Add'),
                  onPressed: _showAddCategoryDialog,
                ),
              ],
            ),
          ],
        ),
        Wrap(
          spacing: 8,
          children: _selectedCategories.map((categoryId) {
            final genre = BookGenres.getAllGenres()
                .firstWhere((g) => g.id == categoryId,
                    orElse: () => Genre(id: categoryId, name: categoryId));
            return Chip(
              label: Text(genre.name),
              onDeleted: () {
                setState(() {
                  _selectedCategories.remove(categoryId);
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Future<void> _showAddCategoryDialog() async {
    final searchController = TextEditingController();
    final availableGenres = BookGenres.getAllGenres()
        .where((genre) => !_selectedCategories.contains(genre.id))
        .toList();
    List<Genre> filteredGenres = List.from(availableGenres);

    return showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Category'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: searchController,
                decoration: const InputDecoration(
                  hintText: 'Search categories...',
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (value) {
                  setDialogState(() {
                    filteredGenres = availableGenres
                        .where((genre) =>
                            genre.name.toLowerCase().contains(value.toLowerCase()))
                        .toList();
                  });
                },
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 200,
                width: double.maxFinite,
                child: ListView.builder(
                  itemCount: filteredGenres.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      title: Text(filteredGenres[index].name),
                      onTap: () {
                        setState(() {
                          _selectedCategories.add(filteredGenres[index].id);
                        });
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }
} 