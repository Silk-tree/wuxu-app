import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../constants/colors.dart';
import '../providers/auth_provider.dart';
import '../services/notification_service.dart';
import '../services/storage_service.dart';
import '../widgets/custom_toast.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _isRequestingPermission = false;
  bool _isClearingCache = false;

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
              _buildPremiumCard(context, auth),
              const SizedBox(height: 20),
              _buildSectionTitle('通知'),
              const SizedBox(height: 8),
              _buildSettingCard([
                _buildNotificationTile(context, auth),
              ]),
              const SizedBox(height: 20),
              _buildSectionTitle('数据'),
              const SizedBox(height: 8),
              _buildSettingCard([
                _buildClearCacheTile(),
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
                  onTap: () => _showUserAgreement(context),
                ),
                _buildDivider(),
                _buildTile(
                  icon: Icons.lock_outline,
                  title: '隐私政策',
                  trailing: '',
                  onTap: () => _showPrivacyPolicy(context),
                ),
              ]),
              const SizedBox(height: 40),
              _buildFooter(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPremiumCard(BuildContext context, AuthProvider auth) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: auth.isPremium
              ? [AppColors.primary, AppColors.primaryLight]
              : [AppColors.secondary, AppColors.secondaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (auth.isPremium ? AppColors.primary : AppColors.secondary)
                .withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Text(auth.isPremium ? '👑' : '🌟', style: const TextStyle(fontSize: 40)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  auth.isPremium ? '已解锁高级版' : '解锁高级版',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  auth.isPremium
                      ? '无限物品数量，享受完整功能'
                      : '支付 ¥1.00，解锁无限物品数量',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
          if (!auth.isPremium)
            GestureDetector(
              onTap: () => _showPurchaseDialog(context, auth),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  '¥1.00',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.secondary,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNotificationTile(BuildContext context, AuthProvider auth) {
    return ListTile(
      leading: Icon(
        auth.notificationEnabled
            ? Icons.notifications_active
            : Icons.notifications_off_outlined,
        color: auth.notificationEnabled ? AppColors.primary : AppColors.textMuted,
      ),
      title: const Text(
        '过期提醒',
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),
      ),
      subtitle: Text(
        auth.notificationEnabled ? '已开启' : '点击开启通知',
        style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_isRequestingPermission)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            Switch(
              value: auth.notificationEnabled,
              onChanged: (value) => _handleNotificationToggle(context, auth, value),
              activeColor: AppColors.primary,
            ),
        ],
      ),
    );
  }

  Widget _buildClearCacheTile() {
    return ListTile(
      leading: const Icon(Icons.cleaning_services_outlined, color: AppColors.textSecondary),
      title: const Text(
        '清理缓存',
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),
      ),
      subtitle: const Text(
        '清除历史记录等临时数据',
        style: TextStyle(fontSize: 12, color: AppColors.textMuted),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_isClearingCache)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            const Icon(Icons.chevron_right, color: AppColors.textMuted),
        ],
      ),
      onTap: _isClearingCache ? null : () => _showClearCacheDialog(context),
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
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
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
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          color: AppColors.textPrimary,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailing.isNotEmpty)
            Text(
              trailing,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textMuted,
              ),
            ),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right, size: 20, color: AppColors.textMuted),
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

  Widget _buildFooter() {
    return Center(
      child: Column(
        children: [
          const Text(
            '🏠',
            style: TextStyle(fontSize: 32),
          ),
          const SizedBox(height: 8),
          const Text(
            '物序',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            '让每一件物品都井井有条',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleNotificationToggle(
    BuildContext context,
    AuthProvider auth,
    bool value,
  ) async {
    if (value && !auth.notificationEnabled) {
      // 开启通知
      setState(() => _isRequestingPermission = true);
      try {
        final notificationService = NotificationService();
        await notificationService.init();
        final granted = await notificationService.requestPermissions();
        if (granted) {
          await auth.toggleNotification(true);
          HapticFeedback.lightImpact();
          if (mounted) {
            CustomToast.show(context, message: '已开启通知提醒');
          }
        } else {
          if (mounted) {
            CustomToast.show(
              context,
              message: '请在系统设置中开启通知权限',
              isError: true,
            );
          }
        }
      } catch (e) {
        if (mounted) {
          CustomToast.show(context, message: '开启通知失败', isError: true);
        }
      } finally {
        if (mounted) {
          setState(() => _isRequestingPermission = false);
        }
      }
    } else {
      await auth.toggleNotification(value);
    }
  }

  void _showClearCacheDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清理缓存'),
        content: const Text('确定要清理缓存数据吗？\n这将清除历史记录等临时数据。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _clearCache(context);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.expired),
            child: const Text('清理'),
          ),
        ],
      ),
    );
  }

  Future<void> _clearCache(BuildContext context) async {
    setState(() => _isClearingCache = true);
    try {
      final storage = await StorageService.getInstance();
      await storage.clearHistoryNames();
      HapticFeedback.mediumImpact();
      if (mounted) {
        CustomToast.show(context, message: '缓存已清理');
      }
    } catch (e) {
      if (mounted) {
        CustomToast.show(context, message: '清理失败', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isClearingCache = false);
      }
    }
  }

  void _showPurchaseDialog(BuildContext context, AuthProvider auth) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            const Text('👑', style: TextStyle(fontSize: 60)),
            const SizedBox(height: 16),
            const Text(
              '解锁高级版',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '¥1.00',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w700,
                color: AppColors.secondary,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '解锁后您将获得：',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            _buildFeatureItem('无限物品数量'),
            _buildFeatureItem('无限分类数量'),
            _buildFeatureItem('数据统计功能'),
            _buildFeatureItem('优先客服支持'),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _processPurchase(context, auth);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  '确认支付 ¥1.00',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: AppColors.safe, size: 20),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _processPurchase(BuildContext context, AuthProvider auth) async {
    try {
      // 模拟支付
      await Future.delayed(const Duration(seconds: 1));
      final success = await auth.purchase();
      if (success) {
        HapticFeedback.heavyImpact();
        if (mounted) {
          CustomToast.show(context, message: '购买成功！感谢您的支持 🎉');
        }
      } else {
        if (mounted) {
          CustomToast.show(context, message: '支付失败，请重试', isError: true);
        }
      }
    } catch (e) {
      if (mounted) {
        CustomToast.show(context, message: '支付失败', isError: true);
      }
    }
  }

  void _showUserAgreement(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('用户协议'),
        content: const SingleChildScrollView(
          child: Text(
            '物序用户协议\n\n'
            '1. 服务条款\n'
            '使用物序应用即表示您同意遵守本协议。\n\n'
            '2. 数据使用\n'
            '我们承诺保护您的个人隐私，所有数据仅用于提供和改进服务。\n\n'
            '3. 付费服务\n'
            '高级版为一次性付费，解锁后永久有效。\n\n'
            '4. 免责声明\n'
            '物品过期提醒仅供参考，请以实际保质期为准。\n\n'
            '如有任何问题，请联系客服。',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  void _showPrivacyPolicy(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('隐私政策'),
        content: const SingleChildScrollView(
          child: Text(
            '物序隐私政策\n\n'
            '我们非常重视您的隐私。\n\n'
            '1. 信息收集\n'
            '我们仅收集设备标识符，用于提供个性化服务。\n\n'
            '2. 数据存储\n'
            '您的数据安全存储在本地设备中。\n\n'
            '3. 通知权限\n'
            '我们需要通知权限来提醒您物品过期。\n\n'
            '4. 数据共享\n'
            '我们不会与任何第三方共享您的个人信息。\n\n'
            '5. 联系我们\n'
            '如有任何隐私问题，请联系客服。',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }
}
