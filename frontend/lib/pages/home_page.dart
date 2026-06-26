import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import '../constants/colors.dart';
import '../models/item.dart';
import '../providers/item_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/expired_animation.dart';
import '../widgets/custom_toast.dart';
import 'add_item_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final List<String> _statusTabs = const ['全部', '即将过期', '已过期', '正常'];
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ItemProvider>(context, listen: false).loadCategories();
      Provider.of<ItemProvider>(context, listen: false).loadItems();
    });
  }

  String _getStatusValue(int index) {
    switch (index) {
      case 1:
        return 'warning';
      case 2:
        return 'expired';
      case 3:
        return 'safe';
      default:
        return 'all';
    }
  }

  void _onTabChanged(int index) {
    setState(() => _selectedTab = index);
    final status = _getStatusValue(index);
    Provider.of<ItemProvider>(context, listen: false)
        .loadItems(status: status, reload: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: () async {
          await Provider.of<ItemProvider>(context, listen: false)
              .loadItems(reload: true);
        },
        color: AppColors.primary,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            _buildSliverAppBar(),
            SliverToBoxAdapter(child: _buildTabs()),
            _buildList(),
          ],
        ),
      ),
      floatingActionButton: _buildFAB(),
    );
  }

  SliverAppBar _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 160,
      floating: false,
      pinned: true,
      backgroundColor: AppColors.primary,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.primaryLight],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 50, 16, 16),
              child: Consumer2<ItemProvider, AuthProvider>(
                builder: (context, itemProvider, authProvider, child) {
                  return Row(
                    children: [
                      Expanded(child: _buildStatCard(
                        '总物品',
                        '${itemProvider.totalCount}',
                        Icons.inventory_2_outlined,
                        Colors.white,
                      )),
                      const SizedBox(width: 12),
                      Expanded(child: _buildStatCard(
                        '即将过期',
                        '${itemProvider.warningCount}',
                        Icons.warning_amber_outlined,
                        AppColors.warning,
                      )),
                      const SizedBox(width: 12),
                      Expanded(child: _buildStatCard(
                        '已过期',
                        '${itemProvider.expiredCount}',
                        Icons.error_outline,
                        AppColors.expired,
                      )),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
        collapseMode: CollapseMode.pin,
      ),
      title: const Text(
        '物序',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.search, color: Colors.white),
          onPressed: () => _showSearchDialog(),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color iconColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 22,
                    height: 1,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    height: 1.1,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      height: 40,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _statusTabs.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final isActive = _selectedTab == index;
          return GestureDetector(
            onTap: () => _onTabChanged(index),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isActive ? AppColors.primary : AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isActive ? AppColors.primary : AppColors.divider,
                ),
                boxShadow: isActive ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ] : null,
              ),
              child: Text(
                _statusTabs[index],
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isActive ? Colors.white : AppColors.textSecondary,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildList() {
    return Consumer<ItemProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.items.isEmpty) {
          return SliverFillRemaining(child: _buildLoadingList());
        }
        if (provider.items.isEmpty) {
          return SliverFillRemaining(child: _buildEmptyState());
        }
        return SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                if (index >= provider.items.length) {
                  return provider.isLoading
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      : const SizedBox.shrink();
                }
                final item = provider.items[index];
                return _buildItemWithActions(item);
              },
              childCount: provider.items.length + (provider.isLoading ? 1 : 0),
            ),
          ),
        );
      },
    );
  }

  Widget _buildItemWithActions(Item item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Dismissible(
        key: Key(item.id),
        direction: DismissDirection.horizontal,
        confirmDismiss: (direction) async {
          if (direction == DismissDirection.endToStart) {
            // 删除
            return await _showDeleteConfirmDialog(item);
          } else {
            // 编辑
            _navigateToEdit(item);
            return false;
          }
        },
        onDismissed: (direction) {
          if (direction == DismissDirection.endToStart) {
            _deleteItem(item);
          }
        },
        background: Container(
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.only(left: 20),
          child: const Row(
            children: [
              Icon(Icons.edit, color: Colors.white),
              SizedBox(width: 8),
              Text('编辑', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        secondaryBackground: Container(
          decoration: BoxDecoration(
            color: AppColors.expired,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text('删除', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              SizedBox(width: 8),
              Icon(Icons.delete, color: Colors.white),
            ],
          ),
        ),
        child: _buildItemCard(item),
      ),
    );
  }

  Widget _buildItemCard(Item item) {
    final Widget card = Container(
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
      child: IntrinsicHeight(
        child: Row(
          children: [
            // 左侧颜色竖条
            Container(
              width: 5,
              decoration: BoxDecoration(
                color: _getStatusColor(item.status),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
              ),
            ),
            // 内容
            Expanded(
              child: InkWell(
                onTap: () => _navigateToDetail(item),
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      // 图标
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: _getStatusColor(item.status).withOpacity(0.15),
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
                      // 信息
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
                                _buildStatusBadge(item),
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
                                  _formatDate(item.expiryDate),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  _getDaysText(item.daysUntilExpiry),
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: _getStatusColor(item.status),
                                  ),
                                ),
                              ],
                            ),
                            if (item.quantity > 1 || item.unit.isNotEmpty) ...[
                              const SizedBox(height: 4),
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
                      const Icon(Icons.chevron_right, color: AppColors.textMuted),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    // 过期卡片添加呼吸动画
    if (item.status == ItemStatus.expired) {
      return ExpiredAnimation(child: card);
    }
    return card;
  }

  Widget _buildStatusBadge(Item item) {
    final color = _getStatusColor(item.status);
    final text = _getStatusText(item);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: color,
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

  String _formatDate(DateTime date) {
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
  }

  String _getDaysText(int days) {
    if (days < 0) return '已过期 ${-days} 天';
    if (days == 0) return '今天过期';
    if (days == 1) return '明天过期';
    return '还剩 $days 天';
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🏠', style: TextStyle(fontSize: 80)),
          const SizedBox(height: 24),
          const Text(
            '家里空空如也',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '开始添加你的第一个物品吧',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => _navigateToAdd(context),
            icon: const Icon(Icons.add),
            label: const Text('添加物品'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingList() {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: 6,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, __) {
        return Shimmer.fromColors(
          baseColor: AppColors.divider,
          highlightColor: AppColors.background,
          child: Container(
            height: 100,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFAB() {
    return FloatingActionButton(
      onPressed: () => _navigateToAdd(context),
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 4,
      child: const Icon(Icons.add),
    );
  }

  void _navigateToAdd(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddItemPage()),
    );
  }

  void _navigateToDetail(Item item) {
    Navigator.pushNamed(context, '/item-detail', arguments: item.id);
  }

  void _navigateToEdit(Item item) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AddItemPage(item: item)),
    );
  }

  Future<bool> _showDeleteConfirmDialog(Item item) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除物品'),
        content: Text('确定要删除「${item.name}」吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.expired),
            child: const Text('删除'),
          ),
        ],
      ),
    ) ?? false;
  }

  void _deleteItem(Item item) async {
    try {
      await Provider.of<ItemProvider>(context, listen: false).deleteItem(item.id);
      if (mounted) {
        HapticFeedback.mediumImpact();
        CustomToast.show(
                                  context,
                                  message: '已删除「${item.name}」',
                                );
      }
    } catch (e) {
      if (mounted) {
        CustomToast.show(context, message: '删除失败', isError: true);
      }
    }
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('搜索'),
        content: const TextField(
          decoration: InputDecoration(
            hintText: '输入物品名称...',
            prefixIcon: Icon(Icons.search),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
        ],
      ),
    );
  }
}
