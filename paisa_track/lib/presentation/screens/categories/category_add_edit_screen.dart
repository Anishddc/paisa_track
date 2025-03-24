import 'package:flutter/material.dart';
import 'package:paisa_track/core/constants/color_constants.dart';
import 'package:paisa_track/data/models/category_model.dart';
import 'package:paisa_track/data/models/enums/transaction_type.dart';
import 'package:paisa_track/data/repositories/category_repository.dart';

class CategoryAddEditScreen extends StatefulWidget {
  final CategoryModel? category;
  final bool isIncome;
  
  // If category is null, it's add mode; otherwise, it's edit mode
  const CategoryAddEditScreen({
    Key? key,
    this.category,
    required this.isIncome,
  }) : super(key: key);

  @override
  State<CategoryAddEditScreen> createState() => _CategoryAddEditScreenState();
}

class _CategoryAddEditScreenState extends State<CategoryAddEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  final CategoryRepository _repository = CategoryRepository();
  bool _isLoading = false;
  
  // Default values
  late int _selectedColorIndex;
  late String _selectedIconName;
  
  // Available icons for categories
  final List<Map<String, dynamic>> _availableIcons = [
    {'name': 'food', 'icon': Icons.restaurant},
    {'name': 'transport', 'icon': Icons.directions_car},
    {'name': 'shopping', 'icon': Icons.shopping_cart},
    {'name': 'bills', 'icon': Icons.receipt},
    {'name': 'entertainment', 'icon': Icons.movie},
    {'name': 'health', 'icon': Icons.local_hospital},
    {'name': 'education', 'icon': Icons.school},
    {'name': 'housing', 'icon': Icons.home},
    {'name': 'utilities', 'icon': Icons.electrical_services},
    {'name': 'insurance', 'icon': Icons.security},
    {'name': 'gifts', 'icon': Icons.card_giftcard},
    {'name': 'work', 'icon': Icons.work},
    {'name': 'trending_up', 'icon': Icons.trending_up},
    {'name': 'other', 'icon': Icons.more_horiz},
  ];

  @override
  void initState() {
    super.initState();
    
    if (widget.category != null) {
      // Edit mode - fill the form with existing data
      _nameController.text = widget.category!.name;
      _descriptionController.text = widget.category!.description ?? '';
      
      // Find the selected icon index
      int iconIndex = _availableIcons.indexWhere((element) => element['name'] == widget.category!.iconName);
      _selectedIconName = widget.category!.iconName;
      
      // Find the selected color index
      int colorIndex = ColorConstants.categoryColors.indexWhere((color) => color.value == widget.category!.colorValue);
      _selectedColorIndex = colorIndex >= 0 ? colorIndex : 0;
    } else {
      // Add mode - set defaults
      _selectedIconName = widget.isIncome ? 'work' : 'shopping';
      _selectedColorIndex = widget.isIncome ? 11 : 0; // Different default colors for income/expense
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveCategory() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final color = ColorConstants.categoryColors[_selectedColorIndex];
      
      if (widget.category == null) {
        // Creating a new category
        await _repository.createCustomCategory(
          name: _nameController.text.trim(),
          type: widget.isIncome ? TransactionType.income : TransactionType.expense,
          colorValue: color.value,
          iconName: _selectedIconName,
          description: _descriptionController.text.trim().isNotEmpty 
              ? _descriptionController.text.trim() 
              : null,
        );
      } else {
        // Updating an existing category
        final updatedCategory = widget.category!.copyWith(
          name: _nameController.text.trim(),
          iconName: _selectedIconName,
          colorValue: color.value,
          description: _descriptionController.text.trim().isNotEmpty 
              ? _descriptionController.text.trim() 
              : null,
        );
        
        await _repository.updateCategory(updatedCategory);
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.category == null
                  ? 'Category created successfully'
                  : 'Category updated successfully',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Return true to indicate success
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.category == null ? 'Add Category' : 'Edit Category'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Category Name',
                        hintText: 'Enter category name',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a category name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description (Optional)',
                        hintText: 'Enter category description',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Select Icon',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildIconSelector(),
                    const SizedBox(height: 24),
                    const Text(
                      'Select Color',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildColorSelector(),
                    const SizedBox(height: 32),
                    _buildPreview(),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _saveCategory,
                        child: Text(
                          widget.category == null ? 'Create Category' : 'Update Category',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildIconSelector() {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: GridView.builder(
        padding: const EdgeInsets.all(8),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 8,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: _availableIcons.length,
        itemBuilder: (context, index) {
          final iconData = _availableIcons[index];
          final isSelected = _selectedIconName == iconData['name'];
          
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedIconName = iconData['name'];
              });
            },
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected 
                    ? ColorConstants.categoryColors[_selectedColorIndex].withOpacity(0.2)
                    : Colors.transparent,
                border: isSelected
                    ? Border.all(color: ColorConstants.categoryColors[_selectedColorIndex])
                    : null,
              ),
              child: Icon(
                iconData['icon'],
                color: isSelected 
                    ? ColorConstants.categoryColors[_selectedColorIndex]
                    : Colors.grey,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildColorSelector() {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListView.builder(
        padding: const EdgeInsets.all(8),
        scrollDirection: Axis.horizontal,
        itemCount: ColorConstants.categoryColors.length,
        itemBuilder: (context, index) {
          final color = ColorConstants.categoryColors[index];
          final isSelected = _selectedColorIndex == index;
          
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedColorIndex = index;
              });
            },
            child: Container(
              width: 40,
              height: 40,
              margin: const EdgeInsets.symmetric(horizontal: 5),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color,
                border: isSelected
                    ? Border.all(color: Colors.black, width: 2)
                    : null,
              ),
              child: isSelected
                  ? const Icon(Icons.check, color: Colors.white)
                  : null,
            ),
          );
        },
      ),
    );
  }

  Widget _buildPreview() {
    final selectedColor = ColorConstants.categoryColors[_selectedColorIndex];
    final selectedIcon = _availableIcons.firstWhere(
      (icon) => icon['name'] == _selectedIconName,
      orElse: () => _availableIcons.first,
    )['icon'];
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Preview',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: selectedColor.withOpacity(0.2),
                  child: Icon(
                    selectedIcon,
                    color: selectedColor,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _nameController.text.isEmpty ? 'Category Name' : _nameController.text,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      if (_descriptionController.text.isNotEmpty)
                        Text(
                          _descriptionController.text,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: widget.isIncome ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    widget.isIncome ? 'Income' : 'Expense',
                    style: TextStyle(
                      color: widget.isIncome ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
} 