import 'package:flutter/material.dart';

import '../constants/colors.dart';
import '../models/item.dart';

class StatusBadge extends StatelessWidget {
  final ItemStatus status;
  final bool showText;

  const StatusBadge({
    super.key,
    required this.status,
    this.showText = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: _dotColor,
              shape: BoxShape.circle,
            ),
          ),
          if (showText) ...[
            const SizedBox(width: 4),
            Text(
              _label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: _textColor,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color get _bgColor {
    switch (status) {
      case ItemStatus.expired:
        return AppColors.expired.withOpacity(0.15);
      case ItemStatus.warning:
        return AppColors.warning.withOpacity(0.3);
      case ItemStatus.safe:
        return AppColors.safe.withOpacity(0.2);
    }
  }

  Color get _dotColor {
    switch (status) {
      case ItemStatus.expired:
        return AppColors.expired;
      case ItemStatus.warning:
        return const Color(0xFFE9B872);
      case ItemStatus.safe:
        return AppColors.safe;
    }
  }

  Color get _textColor {
    switch (status) {
      case ItemStatus.expired:
        return AppColors.expired;
      case ItemStatus.warning:
        return const Color(0xFFB8860B);
      case ItemStatus.safe:
        return AppColors.primary;
    }
  }

  String get _label {
    switch (status) {
      case ItemStatus.expired:
        return '已过期';
      case ItemStatus.warning:
        return '即将过期';
      case ItemStatus.safe:
        return '正常';
    }
  }
}
