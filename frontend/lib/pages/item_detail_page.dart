import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../constants/colors.dart';
import '../models/item.dart';
import '../widgets/status_badge.dart';

class ItemDetailPage extends StatefulWidget {
  final String itemId;

  const ItemDetailPage({super.key, required this.itemId});

  @override
  State<ItemDetailPage> createState() => _ItemDetailPageState();
}

class _ItemDetailPageState extends State<ItemDetailPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textSecondary),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: AppColors.textSecondary),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.expired),
            onPressed: () => _showDeleteDialog(context),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          _buildInfoCard(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Center(
            child: Text('🍎', style: TextStyle(fontSize: 40)),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          '示例物品',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        StatusBadge(status: ItemStatus.safe, showText: true),
      ],
    );
  }

  Widget _buildInfoCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildInfoRow('分类', '食品'),
          _buildDivider(),
          _buildInfoRow('数量', '1 个'),
          _buildDivider(),
          _buildInfoRow(
            '保质期',
            DateFormat('yyyy年MM月dd日').format(DateTime.now().add(const Duration(days: 30))),
          ),
          _buildDivider(),
          _buildInfoRow('存放位置', '冰箱冷藏层'),
          _buildDivider(),
          _buildInfoRow('备注', '无'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
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
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(height: 1, color: AppColors.divider);
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除物品'),
        content: const Text('确定要删除这个物品吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.expired),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }
}
