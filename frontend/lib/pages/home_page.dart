import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import '../constants/colors.dart';
import '../providers/item_provider.dart';
import '../widgets/item_card.dart';
import '../widgets/empty_state.dart';
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
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildTabs(),
          Expanded(
            child: Consumer<ItemProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading && provider.items.isEmpty) {
                  return _buildLoadingList();
                }
                if (provider.items.isEmpty) {
                  return EmptyState(
                    icon: '📦',
                    title: '还没有物品',
                    subtitle: '点击右下角按钮添加第一个物品吧',
                    actionText: '添加物品',
                    onAction: () => _navigateToAdd(context),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () =>
                      provider.loadItems(reload: true),
                  color: AppColors.primary,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: provider.items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = provider.items[index];
                      return ItemCard(
                        item: item,
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            '/item-detail',
                            arguments: item.id,
                          );
                        },
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToAdd(context),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.background,
      elevation: 0,
      title: const Text(
        '物序',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.search, color: AppColors.textSecondary),
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _buildTabs() {
    return Container(
      height: 40,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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

  void _navigateToAdd(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddItemPage()),
    );
  }
}
