import 'package:flutter/material.dart';

import '../constants/colors.dart';

class AddItemPage extends StatefulWidget {
  const AddItemPage({super.key});

  @override
  State<AddItemPage> createState() => _AddItemPageState();
}

class _AddItemPageState extends State<AddItemPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');
  final _locationController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime _selectedDate = DateTime.now().add(const Duration(days: 30));
  String _selectedCategory = '食品';
  String _selectedUnit = '个';

  final List<String> _categories = const ['食品', '日用品', '药品', '其他'];
  final List<String> _categoryIcons = const ['🍎', '🧴', '💊', '📦'];
  final List<String> _units = const ['个', '盒', '瓶', '袋', '包', '支'];

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _locationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          '添加物品',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.textSecondary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildSectionTitle('物品信息'),
            const SizedBox(height: 12),
            _buildNameField(),
            const SizedBox(height: 16),
            _buildCategoryPicker(),
            const SizedBox(height: 16),
            _buildSectionTitle('数量与单位'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildQuantityField()),
                const SizedBox(width: 12),
                Expanded(child: _buildUnitPicker()),
              ],
            ),
            const SizedBox(height: 16),
            _buildSectionTitle('保质期'),
            const SizedBox(height: 12),
            _buildDatePicker(),
            const SizedBox(height: 16),
            _buildSectionTitle('存放位置'),
            const SizedBox(height: 12),
            _buildLocationField(),
            const SizedBox(height: 16),
            _buildSectionTitle('备注'),
            const SizedBox(height: 12),
            _buildNotesField(),
            const SizedBox(height: 32),
            _buildSaveButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildNameField() {
    return TextFormField(
      controller: _nameController,
      decoration: InputDecoration(
        hintText: '请输入物品名称',
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return '请输入物品名称';
        }
        if (value.length > 50) {
          return '名称不能超过50个字符';
        }
        return null;
      },
    );
  }

  Widget _buildCategoryPicker() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: List.generate(_categories.length, (index) {
          final isSelected = _selectedCategory == _categories[index];
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedCategory = _categories[index]),
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary.withOpacity(0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : Colors.transparent,
                  ),
                ),
                child: Column(
                  children: [
                    Text(_categoryIcons[index], style: const TextStyle(fontSize: 24)),
                    const SizedBox(height: 4),
                    Text(
                      _categories[index],
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildQuantityField() {
    return TextFormField(
      controller: _quantityController,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        hintText: '数量',
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }

  Widget _buildUnitPicker() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedUnit,
          isExpanded: true,
          items: _units.map((unit) {
            return DropdownMenuItem(
              value: unit,
              child: Text(unit, style: const TextStyle(fontSize: 14)),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) setState(() => _selectedUnit = value);
          },
        ),
      ),
    );
  }

  Widget _buildDatePicker() {
    return GestureDetector(
      onTap: _selectDate,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today,
                size: 20, color: AppColors.textSecondary),
            const SizedBox(width: 12),
            Text(
              '${_selectedDate.year}.${_selectedDate.month.toString().padLeft(2, '0')}.${_selectedDate.day.toString().padLeft(2, '0')}',
              style: const TextStyle(
                fontSize: 15,
                color: AppColors.textPrimary,
              ),
            ),
            const Spacer(),
            const Icon(Icons.chevron_right,
                color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationField() {
    return TextFormField(
      controller: _locationController,
      decoration: InputDecoration(
        hintText: '例如：冷藏层、零食柜',
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }

  Widget _buildNotesField() {
    return TextFormField(
      controller: _notesController,
      maxLines: 3,
      decoration: InputDecoration(
        hintText: '选填，记录注意事项等',
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _saveItem,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          '保存',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Future<void> _selectDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 365 * 10)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: AppColors.primary,
                ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  void _saveItem() {
    if (_formKey.currentState?.validate() ?? false) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('物品已保存（演示）')),
      );
    }
  }
}
