# gdRoguelike

基于 **Godot 4.x** 引擎开发的 Roguelike 游戏模块，从 Cocos Creator + JavaScript 项目 [**clearRoguelike**](../clearRoguelike) 迁移而来。

---

## 项目背景

最初的原型项目 `clearRoguelike` 基于 **Cocos Creator** 引擎并使用 **JavaScript** 编写，采用 ECS（Entity-Component-System）架构实现了完整的 Roguelike 玩法循环。为利用 Godot 引擎强大的 2D/3D 渲染能力、场景系统以及更灵活的脚本支持，该项目被迁移至 Godot 4.x 平台，使用 **GDScript** 语言重写，同时保留了原项目的核心架构设计理念。

## 技术栈

| 组件     | 技术选型               |
| -------- | ---------------------- |
| 引擎     | Godot 4.x              |
| 脚本语言 | GDScript               |
| 架构模式 | ECS（实体-组件-系统）  |
| UI 系统  | 自建分层 UIManager 框架 |

## 核心架构

项目采用 ECS 架构模式，将数据与行为分离：

### World（世界核心）

`core/world.gd` 是整个游戏的核心枢纽。它在游戏启动时创建并注册所有系统（System），并作为游戏主循环的入口。

```gdscript
# 系统注册流程（world.gd 中 _create_systems）
- BuffSystem            # Buff/效果系统
- CountDownStepSystem   # 倒计时步进系统
- BattleSystem          # 战斗系统
- RoundSystem           # 回合系统
- ShopSystem            # 商店系统
- EventSystem           # 事件系统
- RestSystem            # 休息点系统
```

### Autoload 管理器（单例）

项目通过 Godot 的 Autoload 功能注册了以下全局单例：

| 管理器                    | 职责说明                                         |
| ------------------------- | ------------------------------------------------ |
| `ClearRoguelikeManager`   | 游戏主流程编排：难度选择 → 角色选择 → 进入游戏   |
| `UIManager`               | 分层 UI 管理系统，支持层级控制、堆栈历史、动画过渡 |
| `WorldDataManager`        | 游戏世界数据管理、存档读写                         |
| `GlobalEventBus`          | 全局事件总线，模块间解耦通信                       |

### 游戏流程

```
启动游戏 → 难度选择界面 → 角色选择界面 → 主游戏界面
                                            ↓
                                   ┌────────┴────────┐
                                   事件 → 战斗 → 商店 → 休息
                                   └────────┬────────┘
                                            ↓
                                         下一层
```

## 主要模块

### ECS 组件体系（core/）

| 模块路径               | 说明                             |
| ---------------------- | -------------------------------- |
| `core/entity/`         | 实体基类及各类游戏实体定义       |
| `core/component/`      | 组件，承载具体数据（坐标、技能、Buff 等） |
| `core/system/`         | 系统，处理游戏逻辑（战斗、回合、事件） |
| `core/buffs/`          | Buff 效果系统，含注册与类型索引    |
| `core/skills/`         | 技能系统，含技能注册与类型索引     |

### 随机事件（events/）

| 文件                     | 说明               |
| ------------------------ | ------------------ |
| `event_factory.gd`       | 事件工厂，控制随机生成逻辑 |
| `treasure_chest_event.gd` | 宝箱事件           |
| `heal_fountain_event.gd`  | 祝福泉（回复）事件 |
| `random_buff_event.gd`   | 随机 Buff 事件      |

### 地图系统（map/）

核心地图系统，负责关卡布局生成与节点管理。

### 休息点（rests/）

回合间可停留的功能休息点，提供恢复和策略选择。

### UI 框架（ui/）

基于 `UIManager` 的分层 UI 框架，支持：

- 五层 UI 层级：`BG` → `HUD` → `Popup` → `Tooltip` → `Loading`
- 独立 CanvasLayer 渲染，互不干扰
- 模态遮罩与输入阻塞
- UI 堆栈历史与返回功能
- 面板进出动画（Tween）
- 按需加载与预加载

## 目录结构

```
gdRoguelike/
├── autoload/          # Autoload 全局单例（管理器、事件总线）
├── core/              # 核心 ECS 框架
│   ├── entity/        # 实体类
│   ├── component/     # 组件类
│   ├── system/        # 系统类
│   ├── buffs/         # Buff 系统
│   ├── skills/        # 技能系统
│   └── log/           # 日志工具
├── data/              # 数据定义与游戏常量
├── doc/               # 技术文档与设计说明
├── events/            # 随机事件系统
├── map/               # 地图系统
├── rests/             # 休息点系统
├── ui/                # UI 界面
├── tests/             # 测试脚本
├── main.gd            # 主场景脚本
├── main.tscn          # 主场景
└── project.godot      # 项目配置文件
```

## 运行方式

1. 使用 **Godot 4.x** 打开 `project.godot`
2. 运行主场景 `main.tscn`
3. 游戏将按以下流程启动：
   - 难度选择界面（默认难度 5）
   - 角色选择界面
   - 进入 Roguelike 主游戏

## 相关项目

- [clearRoguelike](../clearRoguelike) — 本项目的 Cocos Creator + JavaScript 原型版本