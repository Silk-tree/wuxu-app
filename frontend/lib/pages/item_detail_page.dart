import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../constants/colors.dart';
import '../models/item.dart';
import '../providers/item_provider.dart';
import '../widgets/expired_animation.dart';
import '../widgets/custom_toast.dart';
import 'add_item_page.dart';

class ItemDetailPage extends StatefulWidget {
  final String itemId;

  const ItemDetailPage({super.key, required this.itemId});

  @override
  State<ItemDetailPage> createState() => _ItemDetailPageState();
}

class _ItemDetailPageState extends State<ItemDetailPage> {
  @override
  Widget build(BuildContext context) {
    return Consumer<ItemProvider>(
      builder: (context, provider, child) {
        final item = provider.getItemById(widget.itemId);

        if (item == null) {
          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
              backgroundColor: AppColors.background,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: AppColors.textSecondary),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            body: const Center(
              child: Text('物品不存在'),
            ),
          );
        }

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: _buildAppBar(item),
          body: _buildBody(item),
          bottomNavigationBar: _buildBottomBar(item),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(Item item) {
    return AppBar(
      backgroundColor: AppColors.background,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: AppColors.textSecondary),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.edit, color: AppColors.primary),
          onPressed: () => _navigateToEdit(item),
        ),
        IconButton(
          icon: const Icon(Icons.delete_outline, color: AppColors.expired),
          onPressed: () => _showDeleteDialog(item),
        ),
      ],
    );
  }

  Widget _buildBody(Item item) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    return ListView(
      padding: EdgeInsets.fromLTRB(16, 16, 16, bottomPadding + 80),
      children: [
        _buildHeader(item),
        const SizedBox(height: 24),
        _buildStatusCard(item),
        const SizedBox(height: 16),
        _buildInfoCard(item),
        const SizedBox(height: 16),
        if (item.notes.isNotEmpty) _buildNotesCard(item),
      ],
    );
  }

  Widget _buildHeader(Item item) {
    Widget headerContent = Column(
      children: [
        Hero(
          tag: 'item-icon-${item.id}',
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: _getStatusColor(item.status).withOpacity(0.15),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Center(
              child: Text(
                item.category?.icon ?? '📦',
                style: const TextStyle(fontSize: 50),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Hero(
          tag: 'item-name-${item.id}',
          child: Material(
            color: Colors.transparent,
            child: Text(
              item.name,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        _buildStatusBadge(item),
      ],
    );

    if (item.status == ItemStatus.expired) {
      return ExpiredAnimation(child: headerContent);
    }
    return headerContent;
  }

  Widget _buildStatusBadge(Item item) {
    final color = _getStatusColor(item.status);
    final text = _getStatusText(item);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(Item item) {
    final daysLeft = item.daysUntilExpiry;
    final color = _getStatusColor(item.status);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.1),
            color.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatusItem(
            icon: _getDaysIcon(item.status),
            label: _getDaysText(item.status, daysLeft),
            value: daysLeft < 0 ? '${-daysLeft}' : '$daysLeft',
            unit: '天',
            color: color,
          ),
          Container(
            width: 1,
            height: 50,
            color: color.withOpacity(0.2),
          ),
          _buildStatusItem(
            icon: Icons.calendar_today,
            label: '过期日期',
            value: DateFormat('MM/dd').format(item.expiryDate),
            unit: '',
            color: color,
          ),
          Container(
            width: 1,
            height: 50,
            color: color.withOpacity(0.2),
          ),
          _buildStatusItem(
            icon: Icons.numbers,
            label: '数量',
            value: '${item.quantity}',
            unit: item.unit,
            color: color,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusItem({
    required IconData icon,
    required String label,
    required String value,
    required String unit,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        if (unit.isNotEmpty)
          Text(
            unit,
            style: TextStyle(
              fontSize: 12,
              color: color.withOpacity(0.8),
            ),
          ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(Item item) {
    final categoryName = item.category?.name ?? '其他';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '物品信息',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoRow(Icons.category_outlined, '分类', categoryName),
          const Divider(height: 24, color: AppColors.divider),
          _buildInfoRow(Icons.numbers, '数量', '${item.quantity} ${item.unit}'),
          const Divider(height: 24, color: AppColors.divider),
          _buildInfoRow(
            Icons.event,
            '过期日期',
            DateFormat('yyyy年MM月dd日').format(item.expiryDate),
          ),
          const Divider(height: 24, color: AppColors.divider),
          _buildInfoRow(
            Icons.place_outlined,
            '存放位置',
            item.storageLocation.isEmpty ? '未设置' : item.storageLocation,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildNotesCard(Item item) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.note_outlined, size: 20, color: AppColors.primary),
              const SizedBox(width: 8),
              const Text(
                '备注',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            item.notes,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(Item item) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
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
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _navigateToEdit(item),
                icon: const Icon(Icons.edit_outlined),
                label: const Text('编辑'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _showDeleteDialog(item),
                icon: const Icon(Icons.delete_outline),
                label: const Text('删除'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.expired,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(ItemStatus status) {
    switch (status) {
      case ItemStatus.expired:
        return AppColors.expired;
      case ItemStatus.warning:
        return AppColors.warning;
      case ItemStatus.safe:
        return AppColors.safe;
    }
  }

  String _getStatusText(Item item) {
    switch (item.status) {
      case ItemStatus.expired:
        return '已过期';
      case ItemStatus.warning:
        return '即将过期';
      case ItemStatus.safe:
        return '正常';
    }
  }

  IconData _getDaysIcon(ItemStatus status) {
    switch (status) {
      case ItemStatus.expired:
        return Icons.error_outline;
      case ItemStatus.warning:
        return Icons.warning_amber_outlined;
      case ItemStatus.safe:
        return Icons.check_circle_outline;
    }
  }

  String _getDaysText(ItemStatus status, int days) {
    if (status == ItemStatus.expired) return '已过期';
    if (status == ItemStatus.warning) return '剩余';
    return '剩余';
  }

  void _navigateToEdit(Item item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddItemPage(item: item),
      ),
    );
  }

  void _showDeleteDialog(Item item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除物品'),
        content: Text('确定要删除「${item.name}」吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteItem(item);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.expired),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  void _deleteItem(Item item) async {
    try {
      await Provider.of<ItemProvider>(context, listen: false).deleteItem(item.id);
      HapticFeedback.mediumImpact();
      if (mounted) {
        CustomToast.show(context, message: '已删除「${item.name}」');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        CustomToast.show(context, message: '删除失败', isError: true);
      }
    }
  }
}
