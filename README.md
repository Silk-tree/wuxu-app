# 物序 (wuxu-app)

> 家中万物，井然有序

物序是一款面向城市家庭的全屋食品与日用品智能管理工具。通过数字化记录、保质期追踪与智能提醒，帮助用户降低浪费、提升家庭库存管理效率。

## 📱 产品特性

- **手动录入** — 低门槛，快速记录物品名称、分类、保质期
- **颜色编码** — 红/黄/绿三色卡片，一眼识别紧急程度
- **到期提醒** — T-3、T-1、当天三重本地推送提醒
- **离线优先** — 所有数据本地存储，无需网络即可使用
- **付费解锁** — 免费 20 件，1 元解锁无限量存储

## 🛠 技术栈

| 层 | 技术 |
|----|------|
| 前端 | Flutter 3.44.2 (Dart 3.12) |
| 状态管理 | Riverpod |
| 本地存储 | SQLite (sqflite_sqlcipher) |
| 本地通知 | flutter_local_notifications |
| 后端 | Go 1.26.4 + Gin + GORM |
| 数据库 | PostgreSQL 15 + Redis 7 |
| 目标平台 | iOS 13.0+ / Android 6.0+ |

## 📂 项目结构

```
wuxu-app/
├── docs/              # 文档
│   ├── PRD-v1.0.md       # 产品需求文档
│   ├── UI-Design-v1.0.md # UI 设计规范
│   ├── spec.md           # 技术规格文档
│   ├── tasks.md          # 开发任务拆分
│   └── checklist.md      # 验收检查清单
├── backend/           # Go 后端（待开发）
└── frontend/          # Flutter 前端（待开发）
```

## 📋 开发阶段

- [x] **文档阶段** — PRD、UI 设计、技术规格
- [ ] **Phase 1** — 项目脚手架搭建（Go + Flutter）
- [ ] **Phase 2** — 后端基础
- [ ] **Phase 3** — 后端 API 实现
- [ ] **Phase 4** — Flutter 基础
- [ ] **Phase 5** — Flutter 页面实现
- [ ] **Phase 6** — 本地通知集成
- [ ] **Phase 7** — 联调测试与 Bug 修复

## 📄 License

MIT
