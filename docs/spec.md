# 物序 V1.0 技术规格文档 (SPEC)

**文档版本**: V1.0
**创建日期**: 2026-06-25
**产品名称**: 物序
**技术栈**: Flutter 3.44.2 + Go 1.26.4 + PostgreSQL 15 + Redis 7
**文档状态**: 初稿

---

## 1. 系统架构

### 1.1 架构决策说明

**关键决策**: PRD 明确要求 V1.0 为纯离线应用（本地 SQLite 存储），但用户指定了 Go + PostgreSQL + Redis 技术栈。

**决策**: 采用"离线优先 + 后端预留"架构
- **当前阶段 (V1.0 MVP)**: Flutter App 直接操作本地 SQLite，后端暂不使用
- **未来阶段 (V2.0)**: 复用本设计的后端 API，实现云同步

这样做的好处：
1. 满足用户指定的技术栈要求
2. 为未来云同步预留扩展能力
3. API 设计与前端解耦，可独立开发

### 1.2 系统架构图

```
┌─────────────────────────────────────────────────────────────────────────┐
│                           物序 App (Flutter)                            │
├─────────────────────────────────────────────────────────────────────────┤
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐   │
│  │  首页/清单   │  │  添加物品   │  │  物品详情   │  │   设置页    │   │
│  │  HomePage  │  │ AddItemPage │  │ItemDetailPage│  │SettingsPage │   │
│  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘   │
│         │                │                │                │          │
│  ┌──────▼────────────────▼────────────────▼────────────────▼──────┐   │
│  │                    State Management (Riverpod)                 │   │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐            │   │
│  │  │ ItemNotifier│  │SettingsNotifier│ │ PurchaseNotifier│       │   │
│  │  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘            │   │
│  └─────────┼────────────────┼────────────────┼────────────────────┘   │
│            │                │                │                       │
│  ┌─────────▼────────────────▼────────────────▼─────────────────────┐  │
│  │                      Local Storage Layer                          │  │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────────┐   │  │
│  │  │   SQLite    │  │ SharedPrefs │  │  flutter_local_notifs  │   │  │
│  │  │ (sqflite)   │  │ (持久化)    │  │      (通知调度)        │   │  │
│  │  └─────────────┘  └─────────────┘  └─────────────────────────┘   │  │
│  └───────────────────────────────────────────────────────────────────┘  │
│                                    │                                    │
│                                    │ 可选: 在线模式启用                  │
└────────────────────────────────────┼────────────────────────────────────┘
                                     │
                    ┌────────────────▼────────────────┐
                    │      Go API Server (Gin + GORM)  │
                    │  ┌─────────────────────────────────┐ │
                    │  │         RESTful API            │ │
                    │  │  POST /api/v1/items            │ │
                    │  │  GET  /api/v1/items            │ │
                    │  │  GET  /api/v1/items/:id        │ │
                    │  │  PUT  /api/v1/items/:id        │ │
                    │  │  DELETE /api/v1/items/:id      │ │
                    │  │  GET  /api/v1/categories       │ │
                    │  │  POST /api/v1/purchase         │ │
                    │  └─────────────────────────────────┘ │
                    └────────────────┬─────────────────────┘
                                     │
              ┌──────────────────────┼──────────────────────┐
              │                      │                      │
    ┌─────────▼─────────┐  ┌─────────▼─────────┐
    │    PostgreSQL 15   │  │      Redis 7      │
    │   (主数据存储)     │  │   (缓存/会话)     │
    └───────────────────┘  └───────────────────┘
```

### 1.3 数据流向

```
[用户操作] → [Flutter UI] → [Riverpod Provider] → [Local SQLite]
                                                      ↑
                                              (V2.0 云同步时)
                                                      ↓
                                         [Go API] → [PostgreSQL]
```

---

## 2. 目录结构

### 2.1 Backend Go 项目结构

```
backend/
├── cmd/
│   └── server/
│       └── main.go              # 程序入口
├── internal/
│   ├── config/
│   │   └── config.go            # 配置加载
│   ├── handler/
│   │   ├── item.go              # 物品 CRUD handler
│   │   ├── category.go          # 分类 handler
│   │   └── purchase.go           # 支付 handler
│   ├── middleware/
│   │   ├── cors.go              # CORS 中间件
│   │   ├── logger.go            # 日志中间件
│   │   └── recovery.go          # 异常恢复中间件
│   ├── model/
│   │   ├── item.go              # 物品模型
│   │   ├── category.go          # 分类模型
│   │   ├── user.go              # 用户模型
│   │   └── purchase.go          # 购买记录模型
│   ├── repository/
│   │   ├── item_repo.go         # 物品数据访问层
│   │   └── user_repo.go         # 用户数据访问层
│   ├── service/
│   │   ├── item_service.go      # 物品业务逻辑
│   │   └── purchase_service.go  # 支付业务逻辑
│   └── router/
│       └── router.go           # 路由配置
├── pkg/
│   ├── database/
│   │   ├── postgres.go          # PostgreSQL 连接
│   │   └── redis.go             # Redis 连接
│   ├── response/
│   │   └── response.go          # 统一响应格式
│   └── validator/
│       └── validator.go        # 参数校验
├── api/
│   └── openapi.yaml             # OpenAPI 3.0 规范（可选）
├── configs/
│   └── config.yaml             # 配置文件
├── migrations/
│   └── 001_init.sql             # 数据库迁移脚本
├── go.mod
├── go.sum
└── Makefile
```

### 2.2 Frontend Flutter 项目结构

```
frontend/
├── lib/
│   ├── main.dart                # 应用入口
│   ├── app.dart                 # MaterialApp 配置
│   ├── config/
│   │   ├── theme.dart           # 主题配置
│   │   ├── routes.dart          # 路由配置
│   │   └── constants.dart       # 常量定义
│   ├── models/
│   │   ├── item.dart            # 物品模型
│   │   ├── category.dart        # 分类模型
│   │   └── user_state.dart      # 用户状态模型
│   ├── services/
│   │   ├── database_service.dart    # SQLite 服务
│   │   ├── notification_service.dart # 本地通知服务
│   │   ├── audio_service.dart      # 音效服务
│   │   └── api_service.dart        # API 服务（V2.0 预留）
│   ├── providers/
│   │   ├── item_provider.dart      # 物品状态管理
│   │   ├── category_provider.dart  # 分类状态管理
│   │   ├── settings_provider.dart  # 设置状态管理
│   │   └── purchase_provider.dart  # 付费状态管理
│   ├── pages/
│   │   ├── home/
│   │   │   └── home_page.dart     # 首页/清单页
│   │   ├── item/
│   │   │   ├── add_item_page.dart # 添加物品页
│   │   │   ├── edit_item_page.dart # 编辑物品页（复用 AddItemPage）
│   │   │   └── item_detail_page.dart # 物品详情页
│   │   ├── settings/
│   │   │   ├── settings_page.dart  # 设置页
│   │   │   ├── terms_page.dart    # 用户协议页
│   │   │   └── privacy_page.dart  # 隐私政策页
│   │   └── widgets/
│   │       ├── item_card.dart     # 物品卡片组件
│   │       ├── empty_state.dart   # 空状态组件
│   │       ├── category_selector.dart # 分类选择器
│   │       ├── expiry_badge.dart   # 到期状态徽章
│   │       └── pay_dialog.dart     # 支付弹窗
│   └── utils/
│       ├── date_utils.dart       # 日期工具
│       ├── color_utils.dart      # 颜色工具
│       └── storage_utils.dart     # 存储工具
├── assets/
│   ├── sounds/
│   │   └── click.mp3             # 咔哒声效
│   └── images/
│       └── empty_state.png      # 空状态插图
├── pubspec.yaml
└── Makefile
```

---

## 3. API 接口设计

### 3.1 接口概述

| 方法 | 路径 | 描述 | 认证 |
|------|------|------|------|
| POST | /api/v1/items | 创建物品 | 可选 |
| GET | /api/v1/items | 获取物品列表 | 可选 |
| GET | /api/v1/items/:id | 获取物品详情 | 可选 |
| PUT | /api/v1/items/:id | 更新物品 | 可选 |
| DELETE | /api/v1/items/:id | 删除物品 | 可选 |
| GET | /api/v1/categories | 获取分类列表 | 否 |
| POST | /api/v1/purchase | 购买解锁 | 必需 |

**说明**: V1.0 为离线优先设计，API 主要用于未来云同步。当前 Flutter App 暂不调用这些接口。

### 3.2 通用规范

**请求头**:
```
Content-Type: application/json
Authorization: Bearer <token>  (可选，V1.0 暂不使用)
```

**成功响应格式**:
```json
{
  "code": 0,
  "message": "success",
  "data": { ... }
}
```

**错误响应格式**:
```json
{
  "code": <错误码>,
  "message": "<错误信息>",
  "data": null
}
```

**错误码定义**:
| 错误码 | 说明 |
|--------|------|
| 0 | 成功 |
| 1001 | 参数错误 |
| 1002 | 物品不存在 |
| 2001 | 用户不存在 |
| 3001 | 余额不足 |
| 3002 | 购买失败 |
| 5001 | 服务器内部错误 |

### 3.3 物品接口

#### POST /api/v1/items — 创建物品

**请求体**:
```json
{
  "name": "纯牛奶",
  "category": "food",
  "expiryDate": "2026-07-15",
  "quantity": 1,
  "location": "冰箱冷藏室"
}
```

| 字段 | 类型 | 必填 | 约束 | 说明 |
|------|------|------|------|------|
| name | string | 是 | 1-50 字符 | 物品名称 |
| category | string | 是 | food/daily/medicine/other | 分类 |
| expiryDate | string | 是 | yyyy-MM-dd 格式 | 保质期 |
| quantity | int | 是 | 1-999，默认 1 | 数量 |
| location | string | 否 | 0-100 字符 | 存放位置 |

**成功响应** (201 Created):
```json
{
  "code": 0,
  "message": "success",
  "data": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "name": "纯牛奶",
    "category": "food",
    "expiryDate": "2026-07-15",
    "quantity": 1,
    "location": "冰箱冷藏室",
    "createdAt": "2026-06-25T10:30:00Z",
    "updatedAt": "2026-06-25T10:30:00Z"
  }
}
```

#### GET /api/v1/items — 获取物品列表

**Query 参数**:
| 参数 | 类型 | 必填 | 默认值 | 说明 |
|------|------|------|--------|------|
| sort | string | 否 | expiryDate | 排序字段：expiryDate/createdAt/name |
| order | string | 否 | asc | 排序方向：asc/desc |
| status | string | 否 | all | 筛选状态：all/expired/expiring/safe |
| page | int | 否 | 1 | 页码 |
| pageSize | int | 否 | 20 | 每页数量，最大 100 |

**status 筛选逻辑**:
- `expired`: 当前日期 > expiryDate
- `expiring`: 0 <= (expiryDate - 当前日期) <= 7 天
- `safe`: (expiryDate - 当前日期) > 7 天

**成功响应** (200 OK):
```json
{
  "code": 0,
  "message": "success",
  "data": {
    "items": [
      {
        "id": "550e8400-e29b-41d4-a716-446655440000",
        "name": "纯牛奶",
        "category": "food",
        "expiryDate": "2026-07-15",
        "quantity": 1,
        "location": "冰箱冷藏室",
        "createdAt": "2026-06-25T10:30:00Z",
        "updatedAt": "2026-06-25T10:30:00Z"
      }
    ],
    "total": 50,
    "page": 1,
    "pageSize": 20
  }
}
```

#### GET /api/v1/items/:id — 获取物品详情

**成功响应** (200 OK):
```json
{
  "code": 0,
  "message": "success",
  "data": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "name": "纯牛奶",
    "category": "food",
    "expiryDate": "2026-07-15",
    "quantity": 1,
    "location": "冰箱冷藏室",
    "createdAt": "2026-06-25T10:30:00Z",
    "updatedAt": "2026-06-25T10:30:00Z"
  }
}
```

**错误响应** (404 Not Found):
```json
{
  "code": 1002,
  "message": "物品不存在",
  "data": null
}
```

#### PUT /api/v1/items/:id — 更新物品

**请求体**:
```json
{
  "name": "纯牛奶（新版）",
  "category": "food",
  "expiryDate": "2026-08-01",
  "quantity": 2,
  "location": "冰箱冷冻室"
}
```

**成功响应** (200 OK):
```json
{
  "code": 0,
  "message": "success",
  "data": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "name": "纯牛奶（新版）",
    "category": "food",
    "expiryDate": "2026-08-01",
    "quantity": 2,
    "location": "冰箱冷冻室",
    "createdAt": "2026-06-25T10:30:00Z",
    "updatedAt": "2026-06-25T11:00:00Z"
  }
}
```

#### DELETE /api/v1/items/:id — 删除物品

**成功响应** (200 OK):
```json
{
  "code": 0,
  "message": "success",
  "data": null
}
```

### 3.4 分类接口

#### GET /api/v1/categories — 获取分类列表

**成功响应** (200 OK):
```json
{
  "code": 0,
  "message": "success",
  "data": [
    { "value": "food", "label": "食品", "icon": "🍎" },
    { "value": "daily", "label": "日用品", "icon": "🧴" },
    { "value": "medicine", "label": "药品", "icon": "💊" },
    { "value": "other", "label": "其他", "icon": "📦" }
  ]
}
```

### 3.5 支付接口

#### POST /api/v1/purchase — 购买解锁

**请求体**:
```json
{
  "userId": "user_123",
  "productId": "unlock_unlimited",
  "paymentMethod": "wechat",
  "transactionId": "微信支付交易号"
}
```

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| userId | string | 是 | 用户 ID |
| productId | string | 是 | 产品 ID，固定为 "unlock_unlimited" |
| paymentMethod | string | 是 | 支付方式：wechat/alipay/iap |
| transactionId | string | 是 | 支付平台交易号 |

**成功响应** (200 OK):
```json
{
  "code": 0,
  "message": "success",
  "data": {
    "orderId": "order_550e8400-e29b-41d4-a716-446655440000",
    "userId": "user_123",
    "productId": "unlock_unlimited",
    "amount": 1.00,
    "currency": "CNY",
    "paidAt": "2026-06-25T12:00:00Z"
  }
}
```

**错误响应** (400 Bad Request):
```json
{
  "code": 3002,
  "message": "支付失败，请重试",
  "data": null
}
```

---

## 4. 数据库 Schema

### 4.1 ER 图

```
┌─────────────┐       ┌─────────────┐       ┌─────────────┐
│   users     │       │   items     │       │ categories  │
├─────────────┤       ├─────────────┤       ├─────────────┤
│ id (PK)     │       │ id (PK)     │       │ id (PK)     │
│ device_id   │       │ user_id(FK) │       │ value       │
│ has_unlocked│       │ name        │       │ label       │
│ created_at  │       │ category_id │       │ icon        │
│ updated_at  │       │ expiry_date │       │ sort_order  │
└──────┬──────┘       │ quantity    │       └─────────────┘
       │              │ location    │
       │              │ created_at  │
       │              │ updated_at  │
       │              └─────────────┘
       │                      │
       │              ┌───────▼───────┐
       │              │  purchases    │
       │              ├───────────────┤
       └──────────────│ id (PK)       │
                      │ user_id (FK)  │
                      │ product_id    │
                      │ amount        │
                      │ currency      │
                      │ transaction_id│
                      │ paid_at       │
                      │ created_at    │
                      └───────────────┘
```

### 4.2 表结构

#### users 表
```sql
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    device_id VARCHAR(255) UNIQUE NOT NULL,  -- 设备唯一标识
    has_unlocked BOOLEAN NOT NULL DEFAULT FALSE,  -- 是否已付费解锁
    notification_enabled BOOLEAN NOT NULL DEFAULT TRUE,  -- 通知开关
    item_count INTEGER NOT NULL DEFAULT 0,  -- 物品数量缓存
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_users_device_id ON users(device_id);
```

#### categories 表
```sql
CREATE TABLE categories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    value VARCHAR(50) UNIQUE NOT NULL,  -- food/daily/medicine/other
    label VARCHAR(50) NOT NULL,  -- 中文标签
    icon VARCHAR(10) NOT NULL,  -- emoji 图标
    sort_order INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- 初始化数据
INSERT INTO categories (value, label, icon, sort_order) VALUES
    ('food', '食品', '🍎', 1),
    ('daily', '日用品', '🧴', 2),
    ('medicine', '药品', '💊', 3),
    ('other', '其他', '📦', 4);
```

#### items 表
```sql
CREATE TABLE items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    category_id UUID NOT NULL REFERENCES categories(id),
    name VARCHAR(50) NOT NULL,
    expiry_date DATE NOT NULL,
    quantity INTEGER NOT NULL DEFAULT 1 CHECK (quantity >= 1 AND quantity <= 999),
    location VARCHAR(100),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_items_user_id ON items(user_id);
CREATE INDEX idx_items_expiry_date ON items(expiry_date);
CREATE INDEX idx_items_category_id ON items(category_id);
CREATE INDEX idx_items_user_expiry ON items(user_id, expiry_date);  -- 复合索引加速排序查询
```

#### purchases 表
```sql
CREATE TABLE purchases (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    product_id VARCHAR(50) NOT NULL,
    amount DECIMAL(10, 2) NOT NULL,
    currency VARCHAR(3) NOT NULL DEFAULT 'CNY',
    transaction_id VARCHAR(255) UNIQUE NOT NULL,  -- 支付平台交易号，防重复
    payment_method VARCHAR(20) NOT NULL,  -- wechat/alipay/iap
    paid_at TIMESTAMP WITH TIME ZONE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_purchases_user_id ON purchases(user_id);
CREATE INDEX idx_purchases_transaction_id ON purchases(transaction_id);
```

---

## 5. Flutter 状态管理方案

### 5.1 方案选型：Riverpod

**推荐方案**: Riverpod (flutter_riverpod)

**理由**:

| 维度 | Provider | Riverpod |
|------|----------|----------|
| 编译时安全 | 需配合代码生成 | 纯代码，编译时安全 |
| 性能 | 好 | 略优（无 Provider 额外开销） |
| 测试友好度 | 一般 | 高（依赖注入简单） |
| 文档质量 | 好 | 非常好 |
| 学习曲线 | 低 | 中等 |
| 空安全 | 需配置 | 原生支持 |
| 异步处理 | FutureProvider/StreamProvider | 同，更简洁 |

**结论**: Riverpod 更适合复杂状态管理场景，且未来 V2.0 云同步时需要处理网络状态、离线缓存等复杂逻辑，Riverpod 的优势会更明显。

### 5.2 状态架构

```
┌─────────────────────────────────────────────────────────┐
│                    Riverpod Providers                    │
├─────────────────────────────────────────────────────────┤
│  ┌─────────────────┐  ┌─────────────────┐                │
│  │ itemProvider   │  │ settingsProvider│                │
│  │ (AsyncNotifier)│  │ (Notifier)      │                │
│  └────────┬────────┘  └────────┬────────┘                │
│           │                      │                        │
│  ┌────────▼────────┐  ┌─────────▼─────────┐              │
│  │ ItemRepository  │  │ SettingsRepository │              │
│  │ (Local SQLite)  │  │ (SharedPrefs)     │              │
│  └─────────────────┘  └───────────────────┘              │
└─────────────────────────────────────────────────────────┘
```

### 5.3 Provider 定义

```dart
// 物品列表 Provider
final itemProvider = AsyncNotifierProvider<ItemNotifier, List<Item>>(
  ItemNotifier.new,
);

// 物品详情 Provider
final itemDetailProvider = FutureProvider.family<Item?, String>((ref, id) async {
  final items = await ref.watch(itemProvider.future);
  return items.firstWhere((item) => item.id == id);
});

// 设置 Provider
final settingsProvider = NotifierProvider<SettingsNotifier, UserState>(
  SettingsNotifier.new,
);

// 分类 Provider
final categoryProvider = Provider<List<Category>>((ref) {
  return [
    Category(value: 'food', label: '食品', icon: '🍎'),
    Category(value: 'daily', label: '日用品', icon: '🧴'),
    Category(value: 'medicine', label: '药品', icon: '💊'),
    Category(value: 'other', label: '其他', icon: '📦'),
  ];
});
```

---

## 6. 本地通知方案

### 6.1 插件选型

**插件**: flutter_local_notifications

**理由**:
- 社区认可度高，维护活跃
- 支持 iOS/Android 双平台
- 支持定时通知、周期性通知
- 支持通知渠道（Android 8.0+）
- 支持 iOS 权限申请

### 6.2 通知策略

#### 触发时机

| 提醒类型 | 触发时间点 | 示例 |
|---------|-----------|------|
| T-3 提醒 | 到期前 3 天 09:00 | "纯牛奶" 将在 3 天后过期 |
| T-1 提醒 | 到期前 1 天 09:00 | "纯牛奶" 将在明天过期 |
| T-0 提醒 | 到期当天 09:00 | "纯牛奶" 今天到期 |

#### 通知文案格式

```
标题: 【物序提醒】
内容: 「{物品名称}」将在 {N} 天后过期
```

过期当天:
```
标题: 【物序提醒】
内容: 「{物品名称}」今天到期，请尽快处理！
```

已过期:
```
标题: 【物序提醒】
内容: 「{物品名称}」已过期 {X} 天
```

### 6.3 实现策略

```dart
class NotificationService {
  // 初始化通知服务
  Future<void> initialize() async {
    // 请求权限
    // 配置 iOS/Android 平台设置
    // 创建通知渠道（Android）
  }

  // 调度物品提醒
  Future<void> scheduleItemReminders(Item item) async {
    // 计算 T-3, T-1, T-0 三个时间点
    // 为每个时间点创建周期性通知
    // 存储通知 ID 映射（用于后续取消）
  }

  // 取消物品提醒
  Future<void> cancelItemReminders(String itemId) async {
    // 根据物品 ID 取消所有相关通知
  }

  // 刷新所有提醒（应用启动或物品变更时）
  Future<void> refreshAllReminders() async {
    // 取消所有现有通知
    // 重新调度所有未过期物品的提醒
  }
}
```

### 6.4 通知管理

- **存储映射**: 使用 `item_{id}_t3`, `item_{id}_t1`, `item_{id}_t0` 作为通知标签，便于精确取消
- **启动刷新**: 应用启动时重新调度所有提醒（防止系统清除通知）
- **设置联动**: 通知开关关闭时，取消所有已调度的通知

---

## 7. 数据同步策略

### 7.1 方案选型：离线优先 (Offline-First)

**采用方案**: 离线优先，数据本地优先存储，网络可用时同步到服务端

**理由**:

| 维度 | 在线优先 | 离线优先 |
|------|---------|---------|
| 用户体验（无网） | 功能受限 | 功能完整 |
| 复杂度 | 高（需处理冲突） | 中（本地为主） |
| 开发成本 | 高 | 中低 |
| PRD 符合度 | 不符合 | 符合 |

### 7.2 同步架构

```
┌─────────────────────────────────────────────────────────┐
│                      Flutter App                         │
├─────────────────────────────────────────────────────────┤
│  Local SQLite ──────────────────────────────────────►   │
│       │                     ▲                            │
│       │                     │                            │
│       │              ┌──────┴───────┐                   │
│       │              │   Sync Engine │                   │
│       │              └──────┬───────┘                   │
│       │                     │                            │
│       ▼                     │                            │
│  API Service ───────────────┘                            │
│                         │                                │
└─────────────────────────┼────────────────────────────────┘
                          │
                          ▼
                    ┌───────────┐
                    │ PostgreSQL│
                    └───────────┘
```

### 7.3 V1.0 MVP 实现

**当前阶段**:
- 所有数据仅存储在本地 SQLite
- 不调用任何网络 API
- 不实现同步逻辑

**V2.0 预留设计**:
```dart
// 同步引擎接口（V2.0 实现）
abstract class SyncEngine {
  // 拉取远程数据
  Future<void> pull();

  // 推送本地变更
  Future<void> push();

  // 冲突解决
  Future<SyncResult> resolveConflicts();
}
```

### 7.4 数据一致性保障

| 场景 | 处理方式 |
|------|---------|
| 应用启动 | 从 SQLite 加载数据到内存 |
| 数据变更 | 先更新 SQLite，再更新内存状态 |
| 通知调度 | 读取 SQLite 中的物品列表计算时间 |
| 付费状态 | 本地 SharedPrefs + 服务端双重校验（V2.0） |

---

## 8. 关键实现细节

### 8.1 颜色编码规则

```dart
enum ExpiryStatus {
  expired,   // 已过期：当前日期 > expiryDate
  expiring,  // 即将过期：0 < (expiryDate - 当前日期) <= 7 天
  safe,      // 安全：(expiryDate - 当前日期) > 7 天
}

Color getStatusColor(ExpiryStatus status) {
  switch (status) {
    case ExpiryStatus.expired:
      return const Color(0xFFFF4D4F);  // 红色
    case ExpiryStatus.expiring:
      return const Color(0xFFFAAD14);  // 黄色
    case ExpiryStatus.safe:
      return const Color(0xFF52C41A);  // 绿色
  }
}
```

### 8.2 呼吸动画实现

```dart
class BreathingCard extends StatefulWidget {
  // 使用 AnimationController + Tween
  // 周期 2 秒，透明度 0.7-1.0
  // ease-in-out 缓动
}
```

### 8.3 滑动操作阈值

- 滑动距离超过卡片宽度 30% 时触发操作
- 使用 `Slidable` 组件或 `Dismissible` 定制实现

---

## 9. 安全设计

### 9.1 SQLite 数据加密

使用 `sqflite_sqlcipher` 替代标准 `sqflite`:
- 数据库文件加密存储
- 密钥由设备标识符派生

### 9.2 付费状态防篡改

```
付费状态存储:
1. SharedPrefs: hasUnlocked = true
2. 本地签名: HMAC(hasUnlocked, deviceSecret)

校验时:
- 检查 SharedPrefs 布尔值
- 校验签名是否匹配
- 不匹配视为异常状态
```

---

## 10. 技术依赖清单

### 10.1 Flutter 依赖

```yaml
dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.8

  # 状态管理
  flutter_riverpod: ^2.5.1
  riverpod_annotation: ^2.3.5

  # 本地存储
  sqflite: ^2.3.3
  sqflite_sqlcipher: ^3.1.0+1
  shared_preferences: ^2.2.3
  path: ^1.9.0

  # 通知
  flutter_local_notifications: ^17.2.2
  timezone: ^0.9.4

  # 音效
  audioplayers: ^6.0.0

  # UI 组件
  flutter_slidable: ^3.1.1

  # 工具
  uuid: ^4.4.2
  intl: ^0.19.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^4.0.0
  riverpod_generator: ^2.4.3
  build_runner: ^2.4.11
```

### 10.2 Go 依赖

```go
require (
    github.com/gin-gonic/gin v1.9.1
    github.com/go-redis/redis/v8 v8.11.5
    github.com/google/uuid v1.6.0
    github.com/lib/pq v1.10.9
    golang.org/x/crypto v0.21.0
    gorm.io/driver/postgres v1.5.7
    gorm.io/gorm v1.25.9
)
```
