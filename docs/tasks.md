# 物序 V1.0 开发任务拆分 (TASKS)

**文档版本**: V1.0
**创建日期**: 2026-06-25
**产品名称**: 物序
**文档状态**: 初稿

---

## Phase 1: 项目脚手架搭建

### 1.1 Flutter 项目初始化

**做什么**:
- 创建 Flutter 项目 `wuxu-app`
- 配置 `pubspec.yaml` 依赖（flutter_riverpod、sqflite、shared_preferences、flutter_local_notifications、audioplayers、flutter_slidable、uuid、intl）
- 配置 iOS/Android 最低版本（iOS 13.0、Android API 23）
- 创建基础目录结构（lib/pages/、lib/widgets/、lib/models/、lib/services/、lib/providers/）
- 添加项目资源目录（assets/sounds/、assets/images/）

**验收标准**:
- `flutter pub get` 无报错
- iOS/Android 双平台可编译运行
- 目录结构符合 SPEC 定义

**预计耗时**: 2 小时

### 1.2 Go 项目初始化

**做什么**:
- 创建 backend/ 目录结构
- 初始化 Go Module
- 配置 `go.mod` 依赖（gin、gorm、redis、pq、uuid）
- 创建基础目录（cmd/、internal/、pkg/、api/、configs/、migrations/）
- 配置 `config.yaml` 配置文件
- 创建 Makefile 构建脚本

**验收标准**:
- `go mod tidy` 无报错
- `make run` 可启动服务
- 目录结构符合 SPEC 定义

**预计耗时**: 2 小时

---

## Phase 2: 后端基础

### 2.1 数据库连接与配置

**做什么**:
- 实现 PostgreSQL 连接池配置
- 实现 Redis 连接配置
- 创建 GORM 数据库模型（User、Item、Category、Purchase）
- 编写数据库迁移脚本（migrations/001_init.sql）
- 实现配置加载模块（config.yaml → Go struct）

**验收标准**:
- 数据库连接成功
- 可执行迁移脚本创建表
- 配置可从 config.yaml 加载

**预计耗时**: 3 小时

### 2.2 基础中间件

**做什么**:
- 实现 CORS 中间件（允许 Flutter Dev Tools 访问）
- 实现日志中间件（请求日志、响应时间）
- 实现异常恢复中间件（panic 捕获）
- 实现统一响应格式（pkg/response/response.go）

**验收标准**:
- HTTP 请求经过中间件链
- 响应格式统一为 `{"code": 0, "message": "success", "data": ...}`
- 异常不导致服务崩溃

**预计耗时**: 2 小时

### 2.3 Repository 层

**做什么**:
- 实现 UserRepository（创建、查询、更新用户）
- 实现 ItemRepository（CRUD、按条件查询）
- 实现 CategoryRepository（查询所有分类）
- 实现 PurchaseRepository（创建购买记录）
- 实现 Redis 缓存（物品列表缓存、会话缓存）

**验收标准**:
- 各 Repository 方法单元测试通过
- 数据库操作使用事务（涉及多表操作时）
- Redis 缓存命中正常

**预计耗时**: 4 小时

---

## Phase 3: 后端 API 实现

### 3.1 物品 CRUD API

**做什么**:
- POST /api/v1/items — 创建物品
- GET /api/v1/items — 获取列表（支持 sort、order、status 筛选，支持分页）
- GET /api/v1/items/:id — 获取详情
- PUT /api/v1/items/:id — 更新物品
- DELETE /api/v1/items/:id — 删除物品
- 参数校验（名称长度、分类枚举、日期格式、数量范围）
- 业务逻辑（免费用户物品数量上限 20）

**验收标准**:
- 所有接口返回正确状态码（201/200/400/404）
- 筛选、排序、分页功能正常
- 免费上限拦截生效

**预计耗时**: 6 小时

### 3.2 分类与支付 API

**做什么**:
- GET /api/v1/categories — 返回固定分类列表
- POST /api/v1/purchase — 购买解锁（模拟支付）
  - 生成订单
  - 模拟支付成功
  - 更新用户解锁状态
  - 记录购买历史

**验收标准**:
- 分类接口返回正确数据
- 支付接口生成订单并更新状态
- 重复 transactionId 拒绝处理

**预计耗时**: 4 小时

### 3.3 API 联调测试

**做什么**:
- 编写 API 集成测试
- 使用 curl 或 Postman 测试所有接口
- 验证错误处理

**验收标准**:
- 所有接口测试通过
- 错误场景正确响应

**预计耗时**: 2 小时

---

## Phase 4: Flutter 基础

### 4.1 主题配置

**做什么**:
- 配置 Material Design 主题
- 定义颜色规范（红/黄/绿 + 主色调）
- 配置字体、间距规范
- 实现暗色模式（预留）

**验收标准**:
- 主题覆盖所有基础组件
- 颜色定义符合 SPEC 颜色规范

**预计耗时**: 2 小时

### 4.2 路由配置

**做什么**:
- 配置 GoRouter 或 Navigator 2.0
- 定义路由表（Home、AddItem、EditItem、ItemDetail、Settings、Terms、Privacy）
- 实现页面转场动画（底部滑入、右入）

**验收标准**:
- 路由跳转正确
- 动画符合 SPEC 定义
- 深层链接支持（预留）

**预计耗时**: 3 小时

### 4.3 网络层封装

**做什么**:
- 实现 ApiService（Dio 或 http）
- 实现统一错误处理
- 实现 Token 自动注入（V2.0 预留）
- 实现重试机制

**验收标准**:
- V1.0 暂不使用（纯离线），但代码结构预留

**预计耗时**: 1 小时（预留）

### 4.4 本地存储服务

**做什么**:
- 实现 DatabaseService（SQLite 封装）
  - 建表语句
  - CRUD 操作
- 实现 StorageService（SharedPreferences 封装）
  - 付费状态
  - 通知开关
- 实现加密存储（sqflite_sqlcipher）

**验收标准**:
- SQLite CRUD 操作正常
- SharedPrefs 读写正常
- 数据库加密生效

**预计耗时**: 4 小时

---

## Phase 5: Flutter 页面实现

### 5.1 首页/清单页

**做什么**:
- 实现 ItemCard 组件（颜色标识、状态徽章）
- 实现 EmptyState 组件（插图、文案、引导按钮）
- 实现 HomePage 主页面
  - 列表展示（ListView.builder）
  - 按到期日排序
  - 左滑删除 + 右滑编辑（Slidable）
  - 红色卡片呼吸动画
  - 空状态展示
- 实现下拉刷新

**验收标准**:
- 物品按到期日升序排列
- 颜色标识正确（红/黄/绿）
- 滑动操作正常
- 空状态正确展示

**预计耗时**: 6 小时

### 5.2 添加物品页

**做什么**:
- 实现 CategorySelector 组件
- 实现 ExpiryDatePicker（iOS: CupertinoDatePicker, Android: MaterialDatePicker）
- 实现 LocationTags（快捷位置标签）
- 实现 AddItemPage
  - 表单校验（名称、保质期必填）
  - 数量输入（1-999）
  - 播放咔哒声效
  - 上限拦截（20 件）
  - 返回确认对话框

**验收标准**:
- 表单校验生效
- 日期选择器符合平台规范
- 声效正常播放
- 上限拦截正确

**预计耗时**: 5 小时

### 5.3 物品详情页

**做什么**:
- 实现 ItemDetailPage
  - 展示所有字段
  - 状态计算与显示
  - 编辑入口
  - 删除确认对话框
- 复用 AddItemPage 实现 EditItemPage（标题变更、保存按钮文案变更）

**验收标准**:
- 信息展示完整正确
- 编辑跳转正确
- 删除确认正确

**预计耗时**: 4 小时

### 5.4 设置页

**做什么**:
- 实现 SettingsPage
  - 通知开关（Switch）
  - 存储空间显示（X/20 或 无限量）
  - 付费入口（PayDialog）
- 实现 TermsPage（用户协议文本）
- 实现 PrivacyPage（隐私政策文本）

**验收标准**:
- 开关即时生效
- 存储计数正确
- 付费弹窗正常

**预计耗时**: 4 小时

### 5.5 底部导航

**做什么**:
- 实现 BottomNavigationBar
- 三个 Tab（首页、添加、设置）
- 添加 Tab 点击触发底部滑入动画

**验收标准**:
- Tab 切换正确
- 动画符合 SPEC

**预计耗时**: 1 小时

---

## Phase 6: 本地通知集成

### 6.1 通知服务实现

**做什么**:
- 实现 NotificationService
  - 初始化（权限请求、iOS 配置、Android 渠道）
  - 调度提醒（T-3、T-1、T-0）
  - 取消提醒
  - 刷新所有提醒
- 实现通知点击处理（打开详情页）

**验收标准**:
- 权限申请正常
- 可调度通知
- 点击通知跳转正确

**预计耗时**: 4 小时

### 6.2 通知调度集成

**做什么**:
- 应用启动时刷新所有提醒
- 物品添加/编辑/删除时更新提醒
- 通知开关关闭时取消所有提醒

**验收标准**:
- 重启后提醒仍在
- 物品变更后提醒正确更新

**预计耗时**: 2 小时

---

## Phase 7: 联调测试与 Bug 修复

### 7.1 功能联调

**做什么**:
- Flutter + 后端 API 联调（V2.0 预留，当前离线不调用）
- 本地存储 + UI 状态联调
- 通知调度验证

**验收标准**:
- 数据流正确
- 状态同步正确

**预计耗时**: 4 小时

### 7.2 验收标准测试

**做什么**:
- 对照 PRD 验收标准逐项测试
- 首页/清单页（H-1 至 H-7）
- 添加物品页（A-1 至 A-7）
- 物品详情页（D-1 至 D-4）
- 设置页（S-1 至 S-4）
- 本地推送通知（N-1 至 N-4）
- 付费解锁（P-1 至 P-4）

**验收标准**:
- 所有 P0 项通过
- P1 项尽可能通过

**预计耗时**: 6 小时

### 7.3 Bug 修复

**做什么**:
- 修复测试中发现的问题
- 性能优化（列表滚动帧率、内存占用）
- 边界情况处理

**验收标准**:
- 无 P0 Bug
- 性能指标达标

**预计耗时**: 4 小时

### 7.4 发布准备

**做什么**:
- iOS 构建配置（Bundle ID、版本号、图标）
- Android 构建配置（包名、版本号、图标）
- 生成 release 包

**验收标准**:
- iOS .ipa 可安装
- Android .apk 可安装

**预计耗时**: 3 小时

---

## 任务耗时汇总

| Phase | 任务 | 预计耗时 |
|-------|------|---------|
| Phase 1 | Flutter 项目初始化 | 2h |
| Phase 1 | Go 项目初始化 | 2h |
| Phase 2 | 数据库连接与配置 | 3h |
| Phase 2 | 基础中间件 | 2h |
| Phase 2 | Repository 层 | 4h |
| Phase 3 | 物品 CRUD API | 6h |
| Phase 3 | 分类与支付 API | 4h |
| Phase 3 | API 联调测试 | 2h |
| Phase 4 | 主题配置 | 2h |
| Phase 4 | 路由配置 | 3h |
| Phase 4 | 网络层封装 | 1h |
| Phase 4 | 本地存储服务 | 4h |
| Phase 5 | 首页/清单页 | 6h |
| Phase 5 | 添加物品页 | 5h |
| Phase 5 | 物品详情页 | 4h |
| Phase 5 | 设置页 | 4h |
| Phase 5 | 底部导航 | 1h |
| Phase 6 | 通知服务实现 | 4h |
| Phase 6 | 通知调度集成 | 2h |
| Phase 7 | 功能联调 | 4h |
| Phase 7 | 验收标准测试 | 6h |
| Phase 7 | Bug 修复 | 4h |
| Phase 7 | 发布准备 | 3h |
| **总计** | | **80h** |

---

## 优先级排序

### P0 必须完成

| 任务 | Phase |
|------|-------|
| Flutter 项目初始化 | Phase 1 |
| Go 项目初始化 | Phase 1 |
| 数据库连接与配置 | Phase 2 |
| 物品 CRUD API | Phase 3 |
| 本地存储服务 | Phase 4 |
| 首页/清单页（基础功能） | Phase 5 |
| 添加物品页（基础功能） | Phase 5 |
| 物品详情页 | Phase 5 |
| 设置页 | Phase 5 |
| 通知服务实现 | Phase 6 |
| 验收标准测试 | Phase 7 |
| Bug 修复 | Phase 7 |
| 发布准备 | Phase 7 |

### P1 尽量完成

| 任务 | Phase |
|------|-------|
| 过期呼吸动画 | Phase 5 |
| 保存声效 | Phase 5 |
| 返回确认对话框 | Phase 5 |
| 快捷位置标签 | Phase 5 |
| 通知调度集成 | Phase 6 |
| 多条通知处理 | Phase 6 |
| 付费状态防篡改 | Phase 7 |

### P2 预留

| 任务 | Phase |
|------|-------|
| 搜索功能（预留入口） | Phase 5 |
| 暗色模式 | Phase 4 |
| 网络层封装 | Phase 4 |
