# ADR 002: 代码架构重构 —— EntityManager / 多管理器 / SystemRegistry / ComponentNames

## 状态
2026-05-13 — 已实施

## 背景
原始项目存在以下架构问题：
1. **WorldDataManager 神类**（788行），集实体管理、游戏状态、背包、UI 根引用于一身
2. **ECS 查询手动遍历**，系统需通过 `WorldDataManager.get_order_enermy_entities()` 获取实体
3. **系统注册硬编码**在 `World._create_systems()` 中
4. **组件名称字符串魔法**，全项目使用 `get_component("Data")` 等字符串

## 决策
分 4 个阶段逐步重构，每个阶段都是向后兼容的增量改进：

### Phase 1 — EntityManager + Query 系统
- 新增 `core/entity_manager/entity_manager.gd` — 集中管理实体注册/注销，按类型和组件索引
- 新增 `core/entity_manager/entity_query.gd` — 链式 API：`.with("Data").without("Buff").all()`
- 新增 `core/entity_manager/entity_type.gd` — 实体类型枚举
- 所有实体 CRUD 需同时更新 EntityManager 和新管理器

### Phase 2 — 管理器拆分
- 将 WorldDataManager 的职责拆分为 4 个独立管理器：
  - `GameStateManager` — 回合/关卡/步数/选择数据
  - `InventoryManager` — 物品/货币 CRUD
  - `UIRootManager` — 5 个 UI 根节点引用
  - `EntityService` — EntityManager 上方便层
- WorldDataManager 保留为向后兼容 Facade

### Phase 3 — SystemRegistry
- 新增 `core/system/system_registry.gd`，支持按阶段（Phase）+ 优先级注册系统
- 删除 World._create_systems() 硬编码列表
- 系统生命周期由 SystemRegistry 管理

### Phase 4 — ComponentNames 常量
- 新增 `core/component/component_names.gd`，所有组件名称提取为常量
- 全项目 48+ 处 `get_component("Data")` 替换为 `ComponentNames.DATA`

## 后果
- 正向：新增实体类型无需修改多处代码
- 正向：系统可按需启用/禁用
- 正向：重构时 IDE 自动补全
- 待改进：WorldDataManager 仍保留为 Facade，后续可完全废弃