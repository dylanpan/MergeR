# 域词汇表 — gdRoguelike

## 核心概念

| 术语 | 说明 |
|------|------|
| **World** | 游戏世界核心，ECS 架构中的世界容器，负责系统注册与主循环 |
| **Entity** | 实体，ECS 中的基本对象，由多个 Component 组成 |
| **Component** | 组件，纯数据结构，承载实体的属性（位置、血量、技能等） |
| **System** | 系统，处理游戏逻辑，通过 `_world` 引用访问服务层 |
| **Service** | 服务，封装领域逻辑，由 World 实例化并注入给系统 |
| **Buff** | 增益/减益效果，可叠加、可计时，影响实体属性或行为 |
| **Skill** | 技能，实体的主动能力，可在战斗中释放 |
| **Round** | 回合，游戏的最小进度单位，每回合推进事件链 |
| **Autoload** | Godot 全局单例，在项目启动时自动加载并常驻内存 |
| **Roguelike** | 随机生成地牢、永久死亡、回合制策略的游玩模式 |

## 游戏机制

| 术语 | 说明 |
|------|------|
| **难度（Difficulty）** | 游戏开始前选择，影响敌人强度、奖励数量等参数 |
| **事件（Event）** | 随机遭遇，如宝箱、祝福泉、神秘 Buff 等 |
| **休息点（Rest）** | 回合间停留点，可用于恢复或策略选择 |
| **商店（Shop）** | 回合间购买物品/ Buff 的地点 |
| **层（Floor）** | 地牢的层级，每层地图随机生成 |

## 技术架构

| 术语 | 说明 |
|------|------|
| **ECS** | Entity-Component-System 架构模式，数据与行为分离 |
| **World** | 核心枢纽，管理所有 System、Service、EntityManager。已加入场景树 |
| **Service 层** | 6 个领域服务：game_state, inventory, persistence, ui_root, entity, element |
| **SystemRegistry** | 系统注册表，按 Phase（PRE_BATTLE→BATTLE→POST_BATTLE→CLEANUP）编排执行 |
| **World.tick()** | 主循环入口，替代直接遍历系统列表的方式 |
| **GlobalEventBus** | 全局事件总线，模块间解耦通信 |
| **GameSessionService** | 独立于 World 的会话服务，用于 UI 面板间数据传输（难度选择→角色选择→主游戏） |
| **EnemyFactory** | 敌人生成工厂，根据回合配置生成敌方单位 |
| **UIManager** | 分层 UI 管理系统，支持 5 层 CanvasLayer 渲染 |
| **ClearRoguelikeManager** | 游戏主流程编排管理器，持有 game_session 引用 |

## 架构演进（从上帝类到服务化）

```
v1 (原始): WorldDataManager (817 行上帝类)
  ├── 所有系统直接调用 WorldDataManager.xxx()
  └── 所有 UI 面板通过 WorldDataManager 传递数据

v2 (当前): 服务化 ECS 架构
  ├── core/services/     → 8 个专注服务
  ├── core/system/       → 通过 _world.service.xxx 访问
  ├── World.tick()       → Phase 编排主循环
  └── GameSessionService → UI 面板数据总线
```

## ADR（架构决策记录）

架构决策记录位于 `docs/adr/` 目录。