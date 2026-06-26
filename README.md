# 物序 (wuxu-app)

> 家中万物，井然有序

物序是一款面向城市家庭的全屋食品与日用品智能管理工具。通过数字化记录、保质期追踪与智能提醒，帮助用户降低浪费、提升家庭库存管理效率。

## 📱 产品特性

- **手动录入** — 低门槛，快速记录物品名称、分类、保质期
- **颜色编码** — 红/黄/绿三色卡片，一眼识别紧急程度
- **到期提醒** — 到期前 3 天、当天本地推送提醒，每日汇总通知
- **付费解锁** — 免费 20 件，1 元解锁无限量存储
- **滑动操作** — 左滑删除、右滑编辑，便捷操作
- **状态管理** — 自动计算物品状态（正常/即将过期/已过期）

## 🛠 技术栈

| 层 | 技术 |
|----|------|
| 前端 | Flutter 3.x (Dart 3.x) |
| 状态管理 | Provider |
| 本地存储 | SharedPreferences |
| 本地通知 | flutter_local_notifications 17.x |
| 网络请求 | http |
| 后端 | Go 1.26.4 + Gin + GORM |
| 数据库 | PostgreSQL 15 |
| 目标平台 | iOS 13.0+ / Android 6.0+ / Web |

## 📂 项目结构

```
wuxu-app/
├── docs/                    # 文档
│   ├── PRD-v1.0.md             # 产品需求文档
│   ├── UI-Design-v1.0.md       # UI 设计规范
│   ├── spec.md                 # 技术规格文档
│   ├── tasks.md                # 开发任务拆分
│   └── checklist.md            # 验收检查清单
├── backend/                 # Go 后端
│   ├── cmd/
│   │   ├── server/             # 服务入口
│   │   └── migrate/            # 数据库迁移
│   ├── configs/                # 配置文件
│   ├── internal/
│   │   ├── config/             # 配置管理
│   │   ├── handlers/           # API 处理器
│   │   ├── middleware/         # 中间件
│   │   ├── models/             # 数据模型
│   │   ├── repository/         # 数据访问层
│   │   ├── router/             # 路由
│   │   ├── services/           # 业务逻辑
│   │   └── mocks/              # 测试模拟
│   ├── pkg/utils/              # 工具函数
│   ├── Makefile
│   └── go.mod
└── frontend/                # Flutter 前端
    ├── lib/
    │   ├── constants/          # 常量定义
    │   ├── models/             # 数据模型
    │   ├── pages/              # 页面
    │   ├── providers/          # 状态管理
    │   ├── services/           # 服务层
    │   ├── widgets/            # 公共组件
    │   ├── app.dart            # 应用主体
    │   └── main.dart           # 入口
    ├── android/                # Android 平台配置
    ├── ios/                    # iOS 平台配置
    ├── web/                    # Web 平台配置
    ├── test/                   # 测试
    └── pubspec.yaml
```

## 🚀 快速开始

### 后端

```bash
cd backend

# 安装依赖
go mod download

# 配置数据库
# 修改 configs/config.yaml 中的数据库连接信息

# 运行数据库迁移
make migrate

# 启动服务
make run
```

后端服务默认运行在 `http://localhost:8080`

### 前端

```bash
cd frontend

# 安装依赖
flutter pub get

# 运行（调试模式）
flutter run

# 构建 Release APK
flutter build apk --release

# 构建 Web 版本
flutter build web --release
```

## 🔌 API 接口

所有接口统一响应格式：`{ code, message, data }`

### 物品管理
- `GET /api/v1/items` — 获取物品列表（支持筛选、排序、分页）
- `GET /api/v1/items/:id` — 获取物品详情
- `POST /api/v1/items` — 创建物品
- `PUT /api/v1/items/:id` — 更新物品
- `DELETE /api/v1/items/:id` — 删除物品

### 分类管理
- `GET /api/v1/categories` — 获取分类列表

### 统计
- `GET /api/v1/stats` — 获取统计信息

### 购买
- `POST /api/v1/purchase` — 付费解锁

## 📋 开发阶段

- [x] **文档阶段** — PRD、UI 设计、技术规格
- [x] **Phase 1** — 项目脚手架搭建（Go + Flutter）
- [x] **Phase 2** — 后端基础
- [x] **Phase 3** — 后端 API 实现
- [x] **Phase 4** — Flutter 基础
- [x] **Phase 5** — Flutter 页面实现
- [x] **Phase 6** — 本地通知集成
- [x] **Phase 7** — 联调测试与 Bug 修复

## 📄 License

MIT
