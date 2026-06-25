import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants/colors.dart';
import '../providers/auth_provider.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          '设置',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: Consumer<AuthProvider>(
        builder: (context, auth, child) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildPremiumCard(context, auth.isPremium),
              const SizedBox(height: 20),
              _buildSectionTitle('通知'),
              const SizedBox(height: 8),
              _buildSettingCard([
                _buildSwitchTile(
                  icon: Icons.notifications_outlined,
                  title: '过期提醒',
                  subtitle: '物品过期前会推送通知',
                  value: auth.notificationEnabled,
                  onChanged: (value) => auth.toggleNotification(value),
                ),
              ]),
              const SizedBox(height: 20),
              _buildSectionTitle('关于'),
              const SizedBox(height: 8),
              _buildSettingCard([
                _buildTile(
                  icon: Icons.info_outline,
                  title: '版本',
                  trailing: 'v1.0.0',
                ),
                _buildDivider(),
                _buildTile(
                  icon: Icons.description_outlined,
                  title: '用户协议',
                  trailing: '',
                  onTap: () {},
                ),
                _buildDivider(),
                _buildTile(
                  icon: Icons.lock_outline,
                  title: '隐私政策',
                  trailing: '',
                  onTap: () {},
                ),
              ]),
              const SizedBox(height: 40),
              const Center(
                child: Text(
                  '物序 · 让每一件物品都井井有条',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPremiumCard(BuildContext context, bool isPremium) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Text('👑', style: TextStyle(fontSize: 40)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isPremium ? '已解锁高级版' : '解锁高级版',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isPremium ? '无限物品数量，享受完整功能' : '支付 1 元，解锁无限物品数量',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.85),
                  ),
                ),
              ],
            ),
          ),
          if (!isPremium)
            TextButton(
              onPressed: () => _showPurchaseDialog(context),
              style: TextButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.primary,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text('立即解锁'),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildSettingCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(title,
          style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary)),
      subtitle: Text(subtitle,
          style:
              const TextStyle(fontSize: 12, color: AppColors.textMuted)),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: AppColors.primary,
      ),
    );
  }

  Widget _buildTile({
    required IconData icon,
    required String title,
    required String trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: AppColors.textSecondary),
      title: Text(title,
          style: const TextStyle(
              fontSize: 15, color: AppColors.textPrimary)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailing.isNotEmpty)
            Text(trailing,
                style: const TextStyle(
                    fontSize: 14, color: AppColors.textMuted)),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right,
              size: 20, color: AppColors.textMuted),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Divider(height: 1, color: AppColors.divider),
    );
  }

  void _showPurchaseDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('解锁高级版'),
        content: const Text('支付 1 元即可解锁无限物品数量'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('模拟支付成功')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('支付 1 元'),
          ),
        ],
      ),
    );
  }
}
