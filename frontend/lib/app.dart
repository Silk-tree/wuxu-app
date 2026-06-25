import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'constants/colors.dart';
import 'pages/home_page.dart';
import 'pages/settings_page.dart';
import 'pages/item_detail_page.dart';
import 'pages/add_item_page.dart';
import 'providers/item_provider.dart';
import 'providers/auth_provider.dart';
import 'services/api_service.dart';
import 'services/storage_service.dart';
import 'services/notification_service.dart';
import 'widgets/custom_bottom_nav.dart';

class WuxuApp extends StatefulWidget {
  const WuxuApp({super.key});

  @override
  State<WuxuApp> createState() => _WuxuAppState();
}

class _WuxuAppState extends State<WuxuApp> with WidgetsBindingObserver {
  StorageService? _storage;
  ApiService? _apiService;
  bool _isInitialized = false;
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initServices();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// 处理应用生命周期变化
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // 应用从后台恢复时，重新加载数据
      _reloadDataIfNeeded();
    }
  }

  Future<void> _reloadDataIfNeeded() async {
    if (_navigatorKey.currentContext != null) {
      final itemProvider = Provider.of<ItemProvider>(
        _navigatorKey.currentContext!,
        listen: false,
      );
      await itemProvider.loadItems(reload: true);
    }
  }

  Future<void> _initServices() async {
    _storage = await StorageService.getInstance();
    String deviceId = _storage!.getDeviceId();
    if (deviceId.isEmpty) {
      deviceId = DateTime.now().millisecondsSinceEpoch.toString();
      await _storage!.setDeviceId(deviceId);
    }
    _apiService = ApiService(deviceId: deviceId);

    // 初始化通知服务
    final notificationService = NotificationService();
    await notificationService.init(
      onNotificationTap: _handleNotificationTap,
    );

    // 通知服务初始化后，重新安排所有通知
    if (mounted) {
      setState(() => _isInitialized = true);
    }
  }

  /// 处理通知点击
  void _handleNotificationTap(String? payload) {
    debugPrint('收到通知点击: $payload');

    if (payload == null) return;

    // 解析 payload，格式: "item:xxx"
    if (payload.startsWith('item:')) {
      final itemId = payload.substring(5);
      _navigateToItemDetail(itemId);
    } else if (payload == 'daily_summary') {
      // 每日汇总通知，点击跳转首页
      _navigatorKey.currentState?.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainPage()),
        (route) => false,
      );
    }
  }

  /// 跳转到物品详情页
  void _navigateToItemDetail(String itemId) {
    // 使用 pushNamed 导航到详情页
    // 先确保在首页
    _navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const MainPage()),
      (route) => false,
    );

    // 延迟导航到详情页，确保首页已加载
    Future.delayed(const Duration(milliseconds: 300), () {
      _navigatorKey.currentState?.pushNamed(
        '/item-detail',
        arguments: itemId,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized || _storage == null || _apiService == null) {
      return MaterialApp(
        theme: _buildTheme(),
        home: const Scaffold(
          backgroundColor: AppColors.background,
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>(
          create: (_) => AuthProvider(
            storage: _storage!,
            apiService: _apiService!,
          )..init(),
        ),
        ChangeNotifierProvider<ItemProvider>(
          create: (_) => ItemProvider(apiService: _apiService!),
        ),
      ],
      child: MaterialApp(
        navigatorKey: _navigatorKey,
        title: '物序',
        debugShowCheckedModeBanner: false,
        theme: _buildTheme(),
        home: const MainPage(),
        routes: {
          '/item-detail': (context) {
            final id = ModalRoute.of(context)?.settings.arguments as String? ?? '';
            return ItemDetailPage(itemId: id);
          },
          '/add-item': (context) => const AddItemPage(),
        },
      ),
    );
  }

  ThemeData _buildTheme() {
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'PingFang SC',
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.surface,
        error: AppColors.expired,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        iconTheme: IconThemeData(color: AppColors.textSecondary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: AppColors.textPrimary),
        bodyMedium: TextStyle(color: AppColors.textPrimary),
        bodySmall: TextStyle(color: AppColors.textSecondary),
        titleLarge: TextStyle(color: AppColors.textPrimary),
        titleMedium: TextStyle(color: AppColors.textPrimary),
        titleSmall: TextStyle(color: AppColors.textPrimary),
      ),
      dividerColor: AppColors.divider,
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    HomePage(),
    _PlaceholderPage(title: '分类', icon: Icons.category),
    _PlaceholderPage(title: '统计', icon: Icons.bar_chart),
    SettingsPage(),
  ];

  void _onNavTap(int index) {
    if (index == 4) {
      Navigator.pushNamed(context, '/add-item');
      return;
    }
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: CustomBottomNav(
        currentIndex: _currentIndex,
        onTap: _onNavTap,
      ),
    );
  }
}

class _PlaceholderPage extends StatelessWidget {
  final String title;
  final IconData icon;

  const _PlaceholderPage({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: AppColors.textMuted),
            const SizedBox(height: 16),
            Text(
              '$title功能开发中',
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
