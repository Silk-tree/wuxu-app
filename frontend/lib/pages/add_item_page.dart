import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../constants/colors.dart';
import '../models/item.dart';
import '../providers/item_provider.dart';
import '../services/storage_service.dart';
import '../widgets/custom_toast.dart';

class AddItemPage extends StatefulWidget {
  final Item? item;

  const AddItemPage({super.key, this.item});

  @override
  State<AddItemPage> createState() => _AddItemPageState();
}

class _AddItemPageState extends State<AddItemPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  final _notesController = TextEditingController();

  int _quantity = 1;
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 7));
  String _selectedCategory = '食品';
  String _selectedUnit = '个';
  bool _isLoading = false;

  // 常用位置列表
  final List<String> _suggestedLocations = [
    '冰箱冷藏层',
    '冰箱冷冻层',
    '零食柜',
    '厨房',
    '客厅',
    '卧室',
    '药箱',
    '抽屉',
  ];

  // 历史输入记录
  List<String> _historyNames = [];

  bool get _isEditing => widget.item != null;

  @override
  void initState() {
    super.initState();
    _loadHistory();
    if (_isEditing) {
      _initWithItem(widget.item!);
    }
  }

  void _initWithItem(Item item) {
    _nameController.text = item.name;
    _quantity = item.quantity;
    _selectedUnit = item.unit.isNotEmpty ? item.unit : '个';
    _selectedDate = item.expiryDate;
    _selectedCategory = _getCategoryFromId(item.categoryId);
    _locationController.text = item.storageLocation;
    _notesController.text = item.notes;
  }

  String _getCategoryFromId(String categoryId) {
    final categories = ['食品', '日用品', '药品', '其他'];
    final index = int.tryParse(categoryId);
    if (index != null && index >= 0 && index < categories.length) {
      return categories[index];
    }
    return '食品';
  }

  Future<void> _loadHistory() async {
    try {
      final storage = await StorageService.getInstance();
      final history = storage.getHistoryNames();
      if (mounted) {
        setState(() => _historyNames = history);
      }
    } catch (_) {}
  }

  Future<void> _saveNameToHistory(String name) async {
    if (name.isEmpty) return;
    try {
      final storage = await StorageService.getInstance();
      await storage.addHistoryName(name);
    } catch (_) {}
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildSectionTitle('物品名称'),
                  const SizedBox(height: 8),
                  _buildNameField(),
                  const SizedBox(height: 20),
                  _buildSectionTitle('分类'),
                  const SizedBox(height: 8),
                  _buildCategoryPicker(),
                  const SizedBox(height: 20),
                  _buildSectionTitle('数量'),
                  const SizedBox(height: 8),
                  _buildQuantityStepper(),
                  const SizedBox(height: 20),
                  _buildSectionTitle('保质期'),
                  const SizedBox(height: 8),
                  _buildDatePicker(),
                  const SizedBox(height: 20),
                  _buildSectionTitle('存放位置'),
                  const SizedBox(height: 8),
                  _buildLocationField(),
                  const SizedBox(height: 20),
                  _buildSectionTitle('备注'),
                  const SizedBox(height: 8),
                  _buildNotesField(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
            _buildSaveButton(),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.background,
      elevation: 0,
      title: Text(
        _isEditing ? '编辑物品' : '添加物品',
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.close, color: AppColors.textSecondary),
        onPressed: () => Navigator.pop(context),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
      ),
    );
  }

  Widget _buildNameField() {
    return Autocomplete<String>(
      optionsBuilder: (textEditingValue) {
        if (textEditingValue.text.isEmpty || _historyNames.isEmpty) {
          return const Iterable<String>.empty();
        }
        return _historyNames.where((name) =>
            name.toLowerCase().contains(textEditingValue.text.toLowerCase()));
      },
      onSelected: (String selection) {
        _nameController.text = selection;
      },
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        // 同步控制器
        if (controller.text.isEmpty && _nameController.text.isNotEmpty) {
          controller.text = _nameController.text;
        }
        return TextFormField(
          controller: controller,
          focusNode: focusNode,
          decoration: InputDecoration(
            hintText: '请输入物品名称',
            hintStyle: const TextStyle(color: AppColors.textMuted),
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            prefixIcon: const Icon(Icons.inventory_2_outlined, color: AppColors.textMuted),
          ),
          textCapitalization: TextCapitalization.sentences,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return '请输入物品名称';
            }
            if (value.length > 50) {
              return '名称不能超过50个字符';
            }
            return null;
          },
          onChanged: (value) {
            _nameController.text = value;
          },
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              constraints: const BoxConstraints(maxHeight: 200),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListView.builder(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final option = options.elementAt(index);
                  return ListTile(
                    dense: true,
                    leading: const Icon(Icons.history, size: 20, color: AppColors.textMuted),
                    title: Text(option),
                    onTap: () => onSelected(option),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCategoryPicker() {
    final categories = ['食品', '日用品', '药品', '其他'];
    final icons = ['🍎', '🧴', '💊', '📦'];

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: List.generate(categories.length, (index) {
          final isSelected = _selectedCategory == categories[index];
          return Expanded(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _selectedCategory = categories[index]);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary.withOpacity(0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                child: Column(
                  children: [
                    Text(icons[index], style: const TextStyle(fontSize: 24)),
                    const SizedBox(height: 4),
                    Text(
                      categories[index],
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

  Widget _buildQuantityStepper() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _buildStepperButton(
            icon: Icons.remove,
            onTap: () {
              if (_quantity > 1) {
                HapticFeedback.selectionClick();
                setState(() => _quantity--);
              }
            },
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  '$_quantity',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  _selectedUnit,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          _buildStepperButton(
            icon: Icons.add,
            onTap: () {
              if (_quantity < 999) {
                HapticFeedback.selectionClick();
                setState(() => _quantity++);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStepperButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: AppColors.primary),
      ),
    );
  }

  Widget _buildDatePicker() {
    final now = DateTime.now();
    final daysUntilExpiry = _selectedDate.difference(DateTime(now.year, now.month, now.day)).inDays;

    return GestureDetector(
      onTap: _selectDate,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, size: 20, color: AppColors.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_selectedDate.year}年${_selectedDate.month}月${_selectedDate.day}日',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    daysUntilExpiry < 0
                        ? '已过期 ${-daysUntilExpiry} 天'
                        : daysUntilExpiry == 0
                            ? '今天过期'
                            : '$daysUntilExpiry 天后过期',
                    style: TextStyle(
                      fontSize: 12,
                      color: daysUntilExpiry < 0
                          ? AppColors.expired
                          : daysUntilExpiry <= 7
                              ? AppColors.warning
                              : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _locationController,
          decoration: InputDecoration(
            hintText: '输入存放位置',
            hintStyle: const TextStyle(color: AppColors.textMuted),
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            prefixIcon: const Icon(Icons.place_outlined, color: AppColors.textMuted),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _suggestedLocations.map((location) {
            final isSelected = _locationController.text == location;
            return GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() {
                  _locationController.text = location;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.divider,
                  ),
                ),
                child: Text(
                  location,
                  style: TextStyle(
                    fontSize: 12,
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildNotesField() {
    return TextFormField(
      controller: _notesController,
      maxLines: 3,
      decoration: InputDecoration(
        hintText: '选填，记录注意事项等',
        hintStyle: const TextStyle(color: AppColors.textMuted),
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, bottomPadding + 12),
      decoration: BoxDecoration(
        color: AppColors.background,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          onPressed: _isLoading ? null : _saveItem,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            disabledBackgroundColor: AppColors.primary.withOpacity(0.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(
                  _isEditing ? '保存修改' : '添加物品',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
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

  Future<void> _saveItem() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final provider = Provider.of<ItemProvider>(context, listen: false);
      final name = _nameController.text.trim();

      if (_isEditing) {
        await provider.updateItem(widget.item!.id, {
          'name': name,
          'category_id': _getCategoryId(_selectedCategory),
          'quantity': _quantity,
          'unit': _selectedUnit,
          'expiry_date': _formatDate(_selectedDate),
          'storage_location': _locationController.text.trim(),
          'notes': _notesController.text.trim(),
        });
        HapticFeedback.lightImpact();
        CustomToast.show(context, message: '已保存「$name」');
      } else {
        await provider.createItem(Item(
          id: '',
          name: name,
          categoryId: _getCategoryId(_selectedCategory),
          quantity: _quantity,
          unit: _selectedUnit,
          expiryDate: _selectedDate,
          storageLocation: _locationController.text.trim(),
          status: ItemStatus.safe,
          notes: _notesController.text.trim(),
          deviceId: '',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ));
        HapticFeedback.lightImpact();
        CustomToast.show(context, message: '已添加「$name」');
        await _saveNameToHistory(name);
      }

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        CustomToast.show(context, message: e.toString(), isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _getCategoryId(String category) {
    final categories = ['食品', '日用品', '药品', '其他'];
    final index = categories.indexOf(category);
    return index >= 0 ? index.toString() : '0';
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
