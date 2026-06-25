import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../constants/colors.dart';
import '../models/item.dart';
import 'status_badge.dart';

class ItemCard extends StatelessWidget {
  final Item item;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const ItemCard({
    super.key,
    required this.item,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final daysLeft = item.daysUntilExpiry;

    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      borderRadius: BorderRadius.circular(12),
      child: Ink(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _statusColor(item.status).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    item.category?.icon ?? '📦',
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        StatusBadge(status: item.status),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 14,
                          color: AppColors.textMuted,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          DateFormat('yyyy.MM.dd').format(item.expiryDate),
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          _daysText(daysLeft),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: _statusColor(item.status),
                          ),
                        ),
                      ],
                    ),
                    if (item.quantity > 1 || item.unit.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        '数量：${item.quantity}${item.unit}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _statusColor(ItemStatus status) {
    switch (status) {
      case ItemStatus.expired:
        return AppColors.expired;
      case ItemStatus.warning:
        return AppColors.warning;
      case ItemStatus.safe:
        return AppColors.safe;
    }
  }

  String _daysText(int days) {
    if (days < 0) return '已过期 ${-days} 天';
    if (days == 0) return '今天过期';
    if (days == 1) return '明天过期';
    return '还剩 $days 天';
  }
}
