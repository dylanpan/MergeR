----
文件: clearRoguelike/map/Prng.js — 迁移完整性: 部分

JS 关键逻辑/行号:
- 12–22 createPRNG(seed) 返回 Mulberry32 闭包（可独立种子实例）
- 31–33 randomInt(prng,min,max)
- 41–43 randomChoice(prng,array)
- 52–64 weightedRandomChoice(prng,items,weights)
- 72–79 shuffle(prng,array)

GD 对应实现/行号 (gdRoguelike/map/prng.gd):
- 11–16 _init/set_seed(seed)
- 17–23 next_float()（Mulberry32 核心）
- 25–26 next_int(min,max)

缺失/差异点及影响:
- 未迁移: randomChoice、weightedRandomChoice、shuffle（JS: 41–79）。影响：上层权重抽样、洗牌、从数组随机选取被迫重复实现或简化，可能产生不等价行为。
- API 差异: JS 返回可复现的闭包函数；GD 是实例方法（用法不同但能复现）。需注意调用端的种子管理与多实例用法差异可能导致不可复现或序列不同。

----
文件: clearRoguelike/map/MapGenerator.js — 迁移完整性: 部分

JS 关键逻辑 / 行号 (clearRoguelike/map/MapGenerator.js)
- 19–95 generateGameRounds: 15 回合池生成，按 tier 加权选敌（权重 10/3），步数软着陆保护，返回 orderEnermyPool。
- 104–383 generateGameLevels: 分层节点、节点类型按 profile.eventRate/restRate/shopRate 决定，构建层间无交叉网格（208–379 为网格连接/消交叉算法）。
- 406–531 generateMap: 用 PRNG（409）串联生成 gameRounds/gameLevels，并把 level -> map.layers（433–519）填充节点、modifiers、敌人池；结尾做 MapModel.validateMapModel(map)（523–525）。
- 541–568 sampleRoundByDifficulty: 加权候选并调用 Prng.weightedRandomChoice（566）。
- 591–606 sampleShopByDifficulty: 加权选择 shop（604）。

GD 对应实现 / 行号 (gdRoguelike/map/map_generator.gd)
- 10–68 generate_game_rounds(profile, prng)：生成回合表，但选敌使用候选列表与 prng.next_int(0, size-1)（无 JS 权重）。
- 70–113 generate_map(difficulty, seed)：整体流程简化；基于 tier 决定 node_type（boss/elite/shop/rest/event/battle），随机阈值硬编码（lines ~87–97）。
- GD 未实现 JS 的网格连接/无交叉修正算法（JS 208–379），也未调用 MapModel.validateMapModel 对等严格校验。

缺失 / 差异点 与 可能影响
1) 加权选择缺失：JS 在 generateGameRounds/sampleShop 等处用权重（10/3、tier*diffBonus），GD 用等概率或 next_int 随机选。影响：敌人分布、难度曲线、商店/Boss 出现概率会偏离原设计（可复现性/平衡不同）。  
2) 随机工具差异：JS 使用 Prng.createPRNG + Prng.weightedRandomChoice/shuffle；GD 用 Prng.next_float/next_int，缺少 weighted/shuffle（见 Prng 对照）。影响：复现性与抽样策略不一致。  
3) 网格连接算法缺失：JS 实现复杂的区间划分与交叉修正（208–379），GD 没有等价实现。影响：关卡路径网状性、连通性与无交叉保证丢失，可能改变玩家路径感与难度分布。  
4) 配置驱动 vs 硬编码：JS 广泛使用 MetaConsts（事件/休息/商店候选、debug 日志），GD 更倾向硬编码阈值与简化逻辑。影响：可配置性下降，调参与内容扩展更困难。  
5) 验证/日志：JS 最终校验 MapModel.validateMapModel(map) 并 printMapDebugLog，GD 缺少等效严格校验与同等可视化日志，降低错误发现速度。

----
文件: clearRoguelike/map/MapModel.js — 迁移完整性: 部分

JS 关键逻辑 / 行号 (clearRoguelike/map/MapModel.js)
- 39–48 createEmptyMap(difficulty, seed)：初始化 version/seed/difficulty/createdAt/layers/profile（MetaConsts.getDifficultyProfile）。
- 55–86 validateMapModel(map)：验证 version=1、seed≥0、difficulty 1–10、layers 是数组；逐节点校验（64–65）；验证 roundId/shopId/enemies 在 MetaConsts 中存在（68–74）；约束：首节点必为 BATTLE、末节点必为 BOSS（78–82）。
- 93–112 validateMapNode(node)：验证 id/type/index 存在、type 在 GameConsts.MapNodeType 中、根据 type 验证对应字段（roundId/shopId）（100–109）。
- 119–124 serializeMap(map)：验证后 JSON.stringify。
- 131–137 deserializeMap(json)：JSON.parse + validateMapModel 再次验证反序列化结果。

GD 对应实现 / 行号 (gdRoguelike/map/map_model.gd)
- 18–26 create_empty_map(p_difficulty, p_seed)：初始化属性，设置 created_at 为 Time.get_unix_time_from_system()，profile = MetaConsts.get_difficulty_profile(p_difficulty)。
- 28–35 validate_map_node(node)：轻量校验（仅检查 is_empty()、has("id"/"type"/"index")），无深度字段检查。
- 37–46 serialize()：返回 Dictionary（含 gameRounds 和 profile 的 duplicate）。
- **缺失**: deserialize（不存在）；validateMapModel（不存在；GD 侧无整体地图合法性检查）。

缺失 / 差异点 与 可能影响
1) **validateMapModel 缺失**（JS 55–86）：GD 没有整体地图校验函数。影响：序列化后不会验证版本号、difficulty 范围、layers 完整性、首末节点约束、元数据引用存在性。可能导致不合法地图被接受或在运行时才暴露错误（例如 node.roundId 指向不存在的回合）。  
2) **deserialize 缺失**（JS 131–137）：GD 没有反序列化入口，无法从保存数据恢复地图并验证。影响：存档加载时无法保证完整性，污染地图可能无法被检测。  
3) **validateMapNode 深度不足**（JS 93–112 vs GD 28–35）：GD 仅检查键存在性；JS 验证 id≥0、type 合法、根据 type 检查对应字段（roundId/shopId 类型）。影响：节点数据脏污（例如 type=BATTLE 但没有 roundId，或 roundId 不是数字）会被接受。  
4) **约束校验缺失**（JS 78–82）：GD 无"首节点必为 BATTLE、末节点必为 BOSS"的约束检查。影响：生成或加载的地图可能首末节点类型错误，破坏关卡流程。  
5) **元数据引用检查缺失**（JS 68–74）：JS 验证 roundId/shopId/enemies 在 MetaConsts 中存在；GD 无此检查。影响：地图包含悬挂引用（指向不存在的 round/shop/enemy），可能在运行时崩溃或显示错误。  
6) **版本和时间戳**：JS 存 createdAt，GD 存 created_at；两侧字段名不一致（camelCase vs snake_case）需要序列化/反序列化时同步（GD 的 serialize 返回 camelCase 键名，so OK，但 deserialize 缺失导致加载时无法映射回属性）。

下一步建议：GD 需补充 validate_map_model(map) 与 deserialize_from_json(json_data) 函数，并在 MapGenerator.generate_map 的末尾调用完整验证。

----

文件: clearRoguelike/events/EventFactory.js — 迁移完整性: 部分

JS 关键逻辑 / 行号 (clearRoguelike/events/EventFactory.js)
- 15–19 EventClassMap：映射表，每个 eventId 指向一个动态 import 加载器（lazy loading）。
- 27–51 createEventEntity(eventId, node)：
  - 28–32：从 MetaConsts.gameEvents[eventId] 读取事件元数据；若无则 warn 并返回 null。
  - 34–38：从 EventClassMap 取加载器；若无则 warn 并返回 null。
  - 40–50：异步加载模块（41）、实例化 EventClass（43）、**调用 eventEntity.init(eventMeta) 注入元数据**（44）、返回实例。异常捕获并记录错误日志（40–50）。
- 58–60 registerEventEntity(eventId, loader)：允许外部动态注册新事件。

GD 对应实现 / 行号 (gdRoguelike/events/event_factory.gd)
- 8–16 _event_registry：静态注册表，直接存储 ID → 构造函数（lambda）映射。
- 17–26 create_event_entity(event_id)：
  - 18–19：检查注册表是否为空，调用 _static_init()；若为空则初始化。
  - 21–26：从注册表取工厂函数；若存在则 factory.call(event_id) 创建实例并返回；否则 push_warning 并返回 null。
  - **注意：无元数据注入步骤，无 meta 传参**。
- 28–37 register_event_entity(event_id, class_ref)：接收类引用，注册为 lambda func(id): return class_ref.new(id)。

缺失 / 差异点 与 可能影响
1) **元数据注入缺失**（JS 44 eventEntity.init(eventMeta) vs GD 无对应）：JS 在创建后立即注入 MetaConsts.gameEvents[eventId] 的完整配置；GD 仅 new(id)，无 meta 注入。影响：事件实例无法访问配置数据（如 rewardPool、buffPool、healPercent 等），被迫使用硬编码或依赖外部调用端传参（见后续事件实现）。  
2) **动态 import vs 静态注册**：JS 使用 dynamic import 并在 createEventEntity 时异步加载（lazy，延迟加载节省内存）；GD 使用静态注册表与 class 引用（同步，加载时全部编译）。影响：模块化、加载时序、内存管理策略不同；GD 若后续新增事件需更新 _static_init()，可扩展性较弱。  
3) **错误处理差异**：JS 使用 try-catch 及 ClearRoguelikeLogger.error 详细捕获加载/实例化失败（40–50）；GD 使用 push_warning（可能被忽略）。影响：运行时错误诊断信息少，调试难度增加。  
4) **node 参数传递**：JS 的 createEventEntity(eventId, node) 允许传递 UI 节点参数（node 作为第二参数）；GD 的 create_event_entity(event_id) 无 node 参数，如需节点则需由调用端另行处理。影响：事件与 UI 的耦合方式不同，可能影响事件响应生命周期。  
5) **API 设计差异**：JS 的 EventClassMap 存加载器（函数）；GD 的 _event_registry 存 lambda；两者都支持注册，但 JS 更灵活（可传递任意 async 加载逻辑），GD 则绑定到 class_ref.new(id) 固定形式。

**总结**：GD 的工厂模式虽然功能完整（创建实例），但缺少关键的"元数据注入"步骤，导致下游事件实现被迫硬编码。建议 GD 补充 meta 注入逻辑或改变事件的配置获取方式。

----

文件: clearRoguelike/events/TreasureChestEvent.js — 迁移完整性: 部分

JS 关键逻辑 / 行号 (clearRoguelike/events/TreasureChestEvent.js)
- 9–12 constructor(eventId, node)：初始化 eventId、node、_reward=null。
- 14–17 onInit()：调用 this._rollReward() 从配置池中随机抽取奖励对象。
- 19–33 onSelectOption(optionId)：
  - case 1 (打开宝箱)：调用 _giveReward(wdm) 发放奖励；return true。
  - case 2 (离开)：return true。
  - default：return false。
- 35–40 getUIData()：返回 { ...this._meta, rewardPreview: this._reward }（展示可获得奖励预览）。
- 46–62 _rollReward()：读取 this._meta.rewardPool（由 EventFactory.init(eventMeta) 注入），按 reward.chance 加权随机抽取，返回 reward 对象。
- 64–68 _giveReward(wdm)：调用 wdm.addItem(this._reward.itemId, 1) 添加到玩家背包。

GD 对应实现 / 行号 (gdRoguelike/events/treasure_chest_event.gd)
- 5–6 _init(p_event_id)：初始化 event_id 与 event_type。
- 8–9 on_enter()：返回硬编码 UI 数据 Dictionary（name="宝箱"、options=[打开/离开]），**无 rewardPreview**。
- 11–16 on_option_select(option_id)：
  - if option_id == 1：获取 world、调用 world.inventory_service.add_item(60000001, randi()%3+1)（硬编码 itemId 与 1–3 随机数量）。
  - 无 case 2 或其他选项处理。

缺失 / 差异点 与 可能影响
1) **元数据配置缺失**（JS 46–62 读 this._meta.rewardPool vs GD 硬编码 60000001）：
   - JS：_rollReward() 读取 this._meta.rewardPool，这是由 EventFactory.init(eventMeta) 注入的配置数据，包含多个道具与 chance 权重。
   - GD：完全无 meta，on_option_select 硬编码 itemId=60000001 与数量 randi()%3+1（即 1–3）。
   - 影响：奖励多样性、权重、可配置性全部丧失；运行时无法修改宝箱掉落，内容设计被锁死。

2) **权重随机缺失**（JS 46–62 加权抽取 vs GD 纯随机数量）：
   - JS：遍历 rewardPool，按 chance 权重决定哪个 reward 被选中（更像真实掉落表）。
   - GD：直接 randi()%3+1 决定数量，无掉落表概念。
   - 影响：GD 无法实现"某些道具更稀有"的设计，所有道具掉落机制简化为单一数量随机。

3) **UI 数据差异**（JS getUIData 返回 rewardPreview vs GD on_enter 无预览）：
   - JS：getUIData() 返回 { ...this._meta, rewardPreview: this._reward }，提前向 UI 显示玩家会获得什么（增强预期管理）。
   - GD：on_enter() 仅返回基础 UI 结构（name、options），无奖励预览信息。
   - 影响：玩家体验差异；GD 版本玩家选择前不知道会获得什么，增加随机感但降低可预见性。

4) **WorldDataManager vs InventoryService 接口**：
   - JS：WorldDataManager.getInstance().addItem(itemId, count)。
   - GD：world.inventory_service.add_item(itemId, count)。
   - 影响：虽然都是添加道具，但接口名称与获取方式不同（影响整体系统集成一致性）。

5) **缺少完整的 onInit 流程**（JS 14–17 vs GD 无对应）：
   - JS：onInit() 在事件初始化时调用，预先抽取 _reward，后续 getUIData 可直接使用。
   - GD：无 on_init，选择奖励的逻辑（硬编码）不在任何初始化方法中；on_option_select 时动态 randi()。
   - 影响：GD 每次点击时都会重新随机，而 JS 是初始化时锁定，两者随机时机不同（可复现性、玩家期望不同）。

6) **返回值与流程**：
   - JS：onSelectOption 根据 optionId 返回 true/false，用于系统判断事件是否结束。
   - GD：on_option_select 无明确返回值，EventSystem 需自行判断事件结束（见 EventSystem 对照）。
   - 影响：生命周期控制方式不同，可能导致事件状态管理混乱。

**总结**：GD 版本是 JS 的极度简化版，几乎所有配置与权重逻辑被移除，只留下硬编码的基本掉落。建议补充 meta 注入与加权随机逻辑，恢复配置驱动的可玩性。

----

文件: clearRoguelike/events/HealFountainEvent.js — 迁移完整性: 部分

JS 关键逻辑 / 行号 (clearRoguelike/events/HealFountainEvent.js)
- 9–12 constructor(eventId, node)：初始化 eventId、node、_healAmount=0。
- 14–20 onInit()：
  - 获取 WorldDataManager.getInstance()（wdm）。
  - 获取 wdm.getOrderSelfData()（当前玩家数据）。
  - 计算 maxHp = orderSelfData?.hp || 0。
  - 设置 this._healAmount = Math.floor(maxHp * this._meta.healPercent)（**从配置读 healPercent**）。
- 22–36 onSelectOption(optionId)：
  - case 1 (饮用泉水)：调用 _healPlayer(wdm)；return true。
  - case 2 (离开)：return true。
  - default：return false。
- 38–43 getUIData()：返回 { ...this._meta, healAmount: this._healAmount }（显示治疗量）。
- 49–57 _healPlayer(wdm)：
  - 获取 orderSelfData。
  - **关键行 54**：orderSelfData.hp = Math.min(orderSelfData.hp + this._healAmount, orderSelfData.hp)。
  - **注意：这行存在疑似 bug**——min 的第二参数应为 orderSelfData.maxHp，但代码写的是 orderSelfData.hp（会导致不治疗，因为 hp+healAmount 总是 > hp）。

GD 对应实现 / 行号 (gdRoguelike/events/heal_fountain_event.gd)
- 5–6 _init(p_event_id)：初始化 event_id 与 event_type。
- 8–9 on_enter()：返回硬编码 UI 数据（name="治愈喷泉"、options=[恢复HP/离开]），**无 healAmount 预显示**。
- 11–19 on_option_select(option_id)：
  - if option_id == 1：获取 world、遍历 self_entities、获取 data_comp、计算 max_hp = data_comp.data.get("maxHp", data_comp.data.get("hp", 100))、修改 data_comp.data["hp"] = min(current + 30, max_hp)（**硬编码 +30**）。
  - 无 case 2 或其他选项处理。

缺失 / 差异点 与 可能影响
1) **配置驱动 vs 硬编码**（JS 读 this._meta.healPercent vs GD 硬编码 +30）：
   - JS：在 onInit 时读取 this._meta.healPercent（由 EventFactory 注入），根据配置百分比计算治疗量。
   - GD：直接 +30 治疗点数（固定值），无配置读取。
   - 影响：GD 无法根据游戏配置调整治疗强度；若要改变治疗效果，需修改代码而非调整配置。可平衡性与可维护性下降。

2) **maxHp 获取差异**：
   - JS：onInit 时读 maxHp = orderSelfData?.hp || 0（**这里似乎也有逻辑问题**——应读 maxHp 字段，而非 hp）。
   - GD：on_option_select 时读 maxHp = data_comp.data.get("maxHp", data_comp.data.get("hp", 100))（fallback 链：优先 maxHp，次要 hp，最终默认 100）。
   - 影响：两侧获取最大生命的方式不同；GD 的 fallback 更保险（容错性强），JS 可能在 maxHp 字段不存在时失效。

3) **上限修正的关键 bug**（JS 54 vs GD 19）：
   - JS 第 54 行：`orderSelfData.hp = Math.min(orderSelfData.hp + this._healAmount, orderSelfData.hp)`
     - **bug**：min 的第二参数写成 orderSelfData.hp，导致永远不会增加（因为 hp+healAmount > hp）。
     - 应为：`Math.min(orderSelfData.hp + this._healAmount, orderSelfData.maxHp)`。
   - GD 第 19 行：`data_comp.data["hp"] = min(data_comp.data.get("hp", 0) + heal_amount, max_hp)`
     - **正确**：上限正确地设为 max_hp。
   - 影响：**GD 其实修正了 JS 的 bug**（但这是巧合，因为 GD 用硬编码 30 而非配置 healPercent）。

4) **UI 预显示**（JS getUIData 返回 healAmount vs GD on_enter 无预显示）：
   - JS：getUIData() 返回 { ...this._meta, healAmount: this._healAmount }，提前告诉玩家会治疗多少。
   - GD：on_enter() 无 healAmount 字段，玩家选择前不知道治疗效果。
   - 影响：信息透明度差异；JS 版本玩家可以计算是否值得使用，GD 版本则完全未知。

5) **作用对象范围**（JS 单个 getOrderSelfData() vs GD 遍历 self_entities）：
   - JS：onInit 读单个 orderSelfData；_healPlayer 也操作单个（假设只有一个玩家）。
   - GD：on_option_select 遍历 self_entities 数组，对每个应用治疗（支持多玩家）。
   - 影响：架构假设不同；JS 假设单玩家，GD 预留多玩家支持（可能是 GD 系统设计的改进）。

6) **缺少完整的 onInit 流程**（JS 14–20 vs GD 无对应）：
   - JS：onInit 预先计算 healAmount。
   - GD：无 on_init，计算在 on_option_select 时（heal_amount = max_hp * 0.5，固定 50%）。
   - 影响：GD 虽然无配置，但用的是百分比（50%）而非 JS 的配置驱动（应为 healPercent，但代码 bug）；两者随机时机与数据获取时机不同。

7) **返回值与流程**：
   - JS：onSelectOption 返回 true/false。
   - GD：on_option_select 无返回值。
   - 影响：同 TreasureChestEvent 的生命周期差异。

**总结**：GD 版本虽然用硬编码替代了配置，但在 maxHp 上限修正上反而更正确（修正了 JS 原代码的 bug）。不过失去了配置驱动与 UI 预显示，且多玩家支持的改变可能改变游戏平衡（治疗所有玩家 vs 仅玩家一人）。建议 GD 补充配置参数化与 UI 预显示逻辑。

----

文件: clearRoguelike/events/RandomBuffEvent.js — 迁移完整性: 部分

JS 关键逻辑 / 行号 (clearRoguelike/events/RandomBuffEvent.js)
- 11–14 constructor(eventId, node)：初始化 eventId、node、_selectedBuff=null。
- 16–19 onInit()：调用 this._rollBuff() 随机抽取一个 buff 配置。
- 21–39 onSelectOption(optionId)：
  - case 1 (接受 buff)：获取 wdm.getOrderSelfEntities() 遍历玩家实体，对每个调用 _applyBuff(orderSelfEntity)；return true。
  - case 2 (离开)：return true。
  - default：return false。
- 41–46 getUIData()：返回 { ...this._meta, selectedBuff: this._selectedBuff }（展示已选 buff）。
- 52–68 _rollBuff()：
  - 读取 this._meta.buffPool（由 EventFactory 注入的配置）。
  - 遍历 buffPool，按 b.chance 加权随机抽取一个 buff 对象。
  - 返回 buff 对象（包含 buffId 等）。
- 70–84 _applyBuff(orderSelfEntity)：
  - 检查 this._selectedBuff 与 orderSelfEntity。
  - 调用 MetaConsts.resolveBuff(this._selectedBuff.buffId) 获取 buffData（包含 type、bonus.value、bonus.duration）。
  - 调用 BuffSystem.getInstance().addBuff(orderSelfEntity, buffData.type, buffData.bonus.value, buffData.bonus.duration, "event_random_buff")（**来源标记为 "event_random_buff"**）。

GD 对应实现 / 行号 (gdRoguelike/events/random_buff_event.gd)
- 5–6 _init(p_event_id)：初始化 event_id 与 event_type。
- 8–9 on_enter()：返回硬编码 UI 数据（name="随机 Buff"、options=[接受祝福/离开]），**无 selectedBuff 预显示**。
- 11–18 on_option_select(option_id)：
  - if option_id == 1：
    - 硬编码 buff_types 列表：["atk_up", "def_up", "shield", "heal"]。
    - 用 randi()%buff_types.size() 随机选一个 selected（buff 类型字符串）。
    - 获取 world、获取 self_entity（单个）、调用 BuffSystem.get_instance().add_buff(self_entity, selected, 5.0, 5)（**硬编码 value=5.0、duration=5、无来源标记**）。

缺失 / 差异点 与 可能影响
1) **buffPool 配置缺失**（JS 52–68 读 this._meta.buffPool vs GD 硬编码 ["atk_up", "def_up", "shield", "heal"]）：
   - JS：_rollBuff() 读取 this._meta.buffPool，这是由 EventFactory.init(eventMeta) 注入的配置，包含多个 buff 与 chance 权重。
   - GD：完全无 meta，hardcoded buff_types = ["atk_up", "def_up", "shield", "heal"]，无权重概念。
   - 影响：GD 无法扩展 buff 类型、无法调整出现概率；新增 buff 需改代码而非配置。可配置性与可维护性下降。

2) **权重随机缺失**（JS 52–68 加权抽取 vs GD 纯均匀随机）：
   - JS：遍历 buffPool，按 b.chance 权重决定哪个 buff 被选中。
   - GD：直接 randi()%size 等概率选择（每个 buff 25% 概率）。
   - 影响：GD 无法实现"某些 buff 更稀有"或"平衡不同buff出现率"的设计；所有 buff 机会均等。

3) **buff 数值配置缺失**（JS 70–84 读 buffData.bonus.value/duration vs GD 硬编码 5.0/5）：
   - JS：MetaConsts.resolveBuff(buffId) 获取完整 buffData，包含 type、bonus.value、bonus.duration。
   - GD：直接传递硬编码的 value=5.0 与 duration=5（固定强度）。
   - 影响：GD 无法根据配置调整 buff 强度，所有 buff 效果锁死；若想改变效果数值需改源码。

4) **来源标记缺失**（JS "event_random_buff" vs GD 无来源标记）：
   - JS：BuffSystem.addBuff(..., "event_random_buff") 明确标记 buff 来源为随机事件。
   - GD：BuffSystem.add_buff(...) 无来源参数或填 null。
   - 影响：系统无法区分 buff 来源（事件 vs 商店 vs 其他），影响日志、统计、buff 交互逻辑（例如"来自事件的 buff 叠加不超过 3 层"这样的逻辑无法实现）。

5) **UI 预显示**（JS getUIData 返回 selectedBuff vs GD on_enter 无预显示）：
   - JS：getUIData() 返回 { ...this._meta, selectedBuff: this._selectedBuff }，提前告诉玩家会获得什么 buff。
   - GD：on_enter() 无 selectedBuff，玩家选择前不知道获得哪个 buff。
   - 影响：信息透明度差异；JS 版本玩家可以根据预显示选择，GD 版本完全随机未知。

6) **作用对象范围**（JS 遍历 getOrderSelfEntities() vs GD 仅 get_order_self_entity() 单个）：
   - JS：onSelectOption 中循环 orderSelfEntities，对**每个**玩家应用 buff（line 27–30）。
   - GD：on_option_select 仅获取单个 self_entity 并应用一次（line 16）。
   - 影响：多玩家情况下行为不同；JS 给所有玩家都加 buff，GD 仅给一个玩家（可能改变游戏平衡）。

7) **buff 对象 vs 字符串**：
   - JS：_selectedBuff 是对象，包含 buffId、可能的额外配置。
   - GD：selected 是字符串 buff 类型名。
   - 影响：数据结构差异；GD 无法存储 buff 对象的附加属性（例如来源描述、特殊条件等）。

8) **缺少完整的 onInit 流程**（JS 16–19 vs GD 无对应）：
   - JS：onInit() 预先抽取 _selectedBuff。
   - GD：无 on_init，buff 选择在 on_option_select 时执行。
   - 影响：GD 每次进入选项时都重新随机（可能不是设计意图），JS 是初始化时锁定。

9) **返回值与流程**：
   - JS：onSelectOption 返回 true/false。
   - GD：on_option_select 无返回值。
   - 影响：同前事件的生命周期差异。

10) **MetaConsts.resolveBuff 缺失**：
    - JS：调用 MetaConsts.resolveBuff(buffId) 获取完整 buffData。
    - GD：无对应方法，直接使用字符串 buff_type_name。
    - 影响：GD 无法存储和读取 buff 的元数据（价值观不对齐）；系统依赖于字符串而非对象，扩展性差。

**总结**：GD 版本是 JS 的极度简化版，移除了所有配置驱动逻辑（buffPool、权重、数值、来源标记），替代为硬编码的 4 种 buff 与固定数值。同时多玩家处理也被简化为单玩家。建议 GD 补充 meta 注入、加权随机、多玩家遍历与来源标记等逻辑。

----

文件: clearRoguelike/rests/RestFactory.js — 迁移完整性: 部分

JS 关键逻辑 / 行号 (clearRoguelike/rests/RestFactory.js)
- 16–20 RestClassMap：映射表，每个 restId 指向一个动态 import 加载器（lazy loading）。ID 从 80001 开始。
- 28–52 createRestEntity(restId, node)：
  - 29–32：从 MetaConsts.gameRests[restId] 读取休息点元数据；若无则 warn 并返回 null。
  - 35–38：从 RestClassMap 取加载器；若无则 warn 并返回 null。
  - 41–50：异步加载模块、实例化 RestClass、**调用 restEntity.init(restMeta) 注入元数据**（45）、返回实例。异常捕获并记录错误日志。
  - **注意：支持 node 参数传递**（node 作为第二参数），用于 UI 交互。
- 59–61 registerRestEntity(restId, loader)：允许外部动态注册新休息点。

GD 对应实现 / 行号 (gdRoguelike/rests/rest_factory.gd)
- 7–15 create_rest_entity(rest_id)：
  - match 语句直接返回 RestX.new(rest_id)（简单工厂）。
  - 支持 80001/80002/80003；其他返回 null。
  - **无 meta 注入，无 node 参数，无异常处理/日志**。

缺失 / 差异点 与 可能影响
1) **元数据注入缺失**（JS 45 restEntity.init(restMeta) vs GD 无对应）：
   - JS：在创建后立即注入 MetaConsts.gameRests[restId] 的完整配置。
   - GD：仅 new(rest_id)，无 meta 注入。
   - 影响：GD 的 rest 实例无法访问配置数据（如 healPercent、itemPool 等），被迫使用硬编码（见后续 rest 实现差异）。

2) **动态 import vs 硬编码 match**：
   - JS：使用 dynamic import，支持任意个 rest 类型（列表式扩展）。
   - GD：使用 match 语句，新增 rest 需修改工厂函数并硬编码新的 case。
   - 影响：GD 的可扩展性较弱；若要加入新休息点，需改工厂代码而非仅添加注册。

3) **node 参数缺失**（JS createRestEntity(restId, node) vs GD create_rest_entity(rest_id)）：
   - JS：允许传递 UI 节点参数（node），rest 实例可获得上下文信息。
   - GD：无 node 参数，rest 实例无 UI 节点引用。
   - 影响：GD 的 rest 与 UI 的耦合方式不同，可能影响交互流程（例如需要从 world 或 UIManager 获取节点，而非直接传递）。

4) **错误处理差异**：
   - JS：try-catch 及 ClearRoguelikeLogger.error 详细捕获加载/实例化失败。
   - GD：无异常处理，若加载失败仅返回 null（无日志）。
   - 影响：GD 的错误诊断信息少，调试难度增加。

5) **API 对称性**：
   - JS：EventFactory 与 RestFactory 设计完全一致（都支持 meta 注入、动态加载、节点传参）。
   - GD：EventFactory 与 RestFactory 设计不一致（EventFactory 还有一些注册逻辑，RestFactory 完全简化）。
   - 影响：代码风格不统一，增加维护复杂度。

6) **注册机制差异**：
   - JS：registerRestEntity(restId, loader) 支持外部注册新类型（插件式）。
   - GD：无对应注册方法，所有 rest 类型硬编码在 match 语句中。
   - 影响：GD 无法支持插件化扩展；要新增 rest 必须修改核心文件。

**总结**：GD 的 RestFactory 是 JS 的极度简化版，几乎所有高级功能（meta 注入、动态加载、错误处理、插件注册）都被移除，仅保留基本的 match 工厂。这种简化导致下游 rest 实现必须硬编码配置（见后续 RestHealCamp/RestUpgradeStation/RestRewardChest 对照）。建议 GD 补充 meta 注入逻辑与更灵活的工厂设计。

----

文件: clearRoguelike/rests/RestHealCamp.js — 迁移完整性: 部分

JS 关键逻辑 / 行号 (clearRoguelike/rests/RestHealCamp.js)
- 11–13 onInit()：记录初始化日志 `RestHealCamp: 初始化营火休息点 #${this.restId}`。
- 15–17 onOpen()：记录打开日志，显示治疗百分比 `恢复 ${this.meta.healPercent * 100}% 生命值`（**从配置读 healPercent**）。
- 19–39 onConfirm()：
  - 获取 wdm = WorldDataManager.getInstance()。
  - 获取 playerEntities = wdm.getOrderSelfEntities()（玩家实体数组）。
  - 遍历每个 player：
    - 获取 dataComponent = player.getComponent("Data")。
    - 计算 maxHp = dataComponent.data["maxHp"] || dataComponent.data["hp"] || 100。
    - 计算 healAmount = Math.floor(maxHp * **this.meta.healPercent**)（**从配置读百分比**）。
    - 修改 hp：dataComponent.data["hp"] = Math.min(dataComponent.data["hp"] + healAmount, maxHp)。
    - 记录详细日志：`玩家恢复 ${healAmount} 点生命值, 当前血量: ${dataComponent.data["hp"]}/${maxHp}`。
- 41–43 onSkip()：记录跳过日志。
- 45–47 onComplete()：记录完成日志。

GD 对应实现 / 行号 (gdRoguelike/rests/rest_heal_camp.gd)
- 5–6 _init(p_rest_id)：初始化 rest_id 与 rest_type。
- 8–9 on_enter()：返回 dict，desc="恢复所有己方单位50%HP"（**硬编码 50%**）。
- 11–19 on_confirm()：
  - 获取 world = ClearRoguelikeManager.get_world()。
  - 获取 self_entities = world.entity_service.get_order_self()。
  - 遍历 entity in self_entities：
    - 获取 data_comp = entity.get_component(ComponentNames.DATA) as DataComponent。
    - 计算 max_hp = data_comp.data.get("maxHp", data_comp.data.get("hp", 100))。
    - 计算 heal_amount = max_hp * **0.5**（**硬编码 50%**）。
    - 修改 hp：data_comp.data["hp"] = min(data_comp.data.get("hp", 0) + heal_amount, max_hp)。
    - **无日志输出**。
- 21–22 on_skip()：空实现（pass）。

缺失 / 差异点 与 可能影响
1) **配置驱动 vs 硬编码**（JS 读 this.meta.healPercent vs GD 硬编码 0.5）：
   - JS：onInit/onOpen 时读取 this.meta.healPercent（由 RestFactory.init(restMeta) 注入），可在运行时调整。
   - GD：直接 heal_amount = max_hp * 0.5，百分比锁死为 50%，且写在 on_enter() 的 desc 中。
   - 影响：GD 无法通过配置修改治疗强度；若想改成 60% 或 40%，需改源码。可配置性与可维护性下降。

2) **生命周期完整性**（JS 5 个方法 vs GD 3 个）：
   - JS：onInit→onOpen→onConfirm/onSkip→onComplete（完整的四个阶段）。
   - GD：_init→on_enter/on_confirm/on_skip（缺少 on_complete）。
   - 影响：GD 无法在休息完成后执行清理或后续逻辑；生命周期不对称。

3) **日志详细度**（JS 详细记录 vs GD 无日志）：
   - JS：每个阶段（init/open/confirm/skip/complete）都有对应日志，包括治疗数值与血量变化信息（line 33）。
   - GD：无任何日志输出。
   - 影响：GD 的运行时诊断能力弱；调试与问题排查困难。

4) **onOpen 的语义差异**：
   - JS：onOpen() 在打开 UI 时调用，显示治疗百分比信息。
   - GD：on_enter() 返回 UI data（dict），包含 name/type/desc，desc 中硬编码"50%HP"。
   - 影响：信息展示时机与结构不同；JS 侧更灵活（可动态改 healPercent），GD 侧硬编码。

5) **getComponent vs get_component 接口**：
   - JS：player.getComponent("Data")（字符串名称）。
   - GD：entity.get_component(ComponentNames.DATA)（枚举常量）。
   - 影响：接口设计哲学不同（字符串 vs 枚举），但功能本质相同。GD 的枚举方式更类型安全。

6) **getOrderSelfEntities vs get_order_self**：
   - JS：wdm.getOrderSelfEntities()（复数，强调返回数组）。
   - GD：world.entity_service.get_order_self()（可能是单数或复数，需核实实现）。
   - 影响：API 命名与获取方式不同；假设两者都返回数组，但系统集成点可能不一致。

7) **WorldDataManager vs world.entity_service 接口**：
   - JS：WorldDataManager.getInstance().getOrderSelfEntities()。
   - GD：ClearRoguelikeManager.get_world().entity_service.get_order_self()。
   - 影响：服务定位方式不同；JS 用单例模式，GD 通过 world 对象获取。两侧架构思路不同。

8) **数值计算差异**：
   - JS：Math.floor(maxHp * this.meta.healPercent)（取整为向下取整，ensure 整数）。
   - GD：max_hp * 0.5（浮点数计算，可能在后续赋值时隐式转换）。
   - 影响：GD 可能导致浮点数被赋给整数字段，引发潜在的舍入误差或类型错误。

9) **maxHp 获取的 fallback 链**：
   - JS：dataComponent.data["maxHp"] || dataComponent.data["hp"] || 100。
   - GD：data_comp.data.get("maxHp", data_comp.data.get("hp", 100))（两层 get with default）。
   - 影响：两种 fallback 方式逻辑等价，但 GD 的链式 get 更明确；JS 用 || 可能在 0 值时失败。

10) **hp 当前值获取差异**：
    - JS：dataComponent.data["hp"]（直接访问，假设存在）。
    - GD：data_comp.data.get("hp", 0)（安全访问，默认 0）。
    - 影响：GD 更防御性；JS 若 hp 未初始化会报错。

11) **修改上限的正确性**：
    - 两侧都用 min(..., maxHp) 正确地 cap 治疗后的 hp 不超过最大值。

**总结**：GD 版本虽然基本逻辑保留（遍历玩家、治疗、上限保护），但失去了几乎所有的配置驱动与生命周期完整性。硬编码的 50% 治疗量、缺失的日志、缺失的 onComplete 方法，都降低了可维护性与可调试性。建议 GD 补充 meta 注入、百分比配置化、完整生命周期方法与日志输出。

----

文件: clearRoguelike/rests/RestUpgradeStation.js — 迁移完整性: 部分

JS 关键逻辑 / 行号 (clearRoguelike/rests/RestUpgradeStation.js)
- 11–13 onInit()：记录初始化日志。
- 15–17 onOpen()：记录打开日志，提示"发射器等级+1"。
- 19–48 onConfirm()：
  - 获取 wdm = WorldDataManager.getInstance()。
  - 获取 launcherEntities = wdm.getLauncherEntities()（**所有发射器实体**）。
  - 遍历每个 launcher（line 27）：
    - 获取 dataComponent = launcher.getComponent("Data")。
    - **级别升级**（line 31–35）：level += 1，若不存在则初始化为 2。
    - **攻击加成提升**（line 38–40）：atkBonus += 0.05（每次 +5%）。
    - 记录详细日志，显示升级后的等级与攻击加成百分比（line 42）。
  - 返回 true。
- 50–52 onSkip()：记录跳过日志。
- 54–56 onComplete()：记录完成日志。

GD 对应实现 / 行号 (gdRoguelike/rests/rest_upgrade_station.gd)
- 5–6 _init(p_rest_id)：初始化 rest_id 与 rest_type。
- 8–9 on_enter()：返回 dict，desc="永久提升攻击力+3"（**硬编码 +3**）。
- 11–18 on_confirm()：
  - 获取 world = ClearRoguelikeManager.get_world()。
  - 获取 self_entity = world.entity_service.get_order_self_entity()（**仅单个玩家**）。
  - if self_entity：
    - 获取 data_comp = self_entity.get_component(ComponentNames.DATA)。
    - if data_comp：修改 data_comp.data["atk"] = data_comp.data.get("atk", 0) + 3。
  - **无日志输出，无返回值**。
- 19–20 on_skip()：空实现（pass）。

缺失 / 差异点 与 可能影响
1) **目标对象范围不同**（JS getLauncherEntities() vs GD get_order_self_entity()）：
   - JS：wdm.getLauncherEntities() 获取**所有发射器实体**（可能多个，例如左右两个发射器），对每个升级。
   - GD：world.entity_service.get_order_self_entity() 获取**单个玩家实体**，仅升级该玩家的 atk 属性。
   - 影响：**游戏逻辑完全不同**。JS 升级的是"发射器装备"（launcher 实体），GD 升级的是"玩家属性"（self_entity.atk）。这改变了游戏系统设计（装备强化 vs 角色强化）。

2) **升级内容差异**（JS level+atkBonus vs GD atk）：
   - JS：升级**两个属性**：
     - level += 1（发射器等级）。
     - atkBonus += 0.05（发射器攻击加成，+5%）。
   - GD：升级**单个属性**：
     - atk += 3（玩家基础攻击力，+3 点）。
   - 影响：GD 的升级方式是线性加值（+3），JS 的方式是指数增长（等级升高 + 加成百分比）。两者的强度曲线完全不同。

3) **配置驱动 vs 硬编码**：
   - JS：虽然写了 0.05 和 level，但没有从 meta 读配置。**属于半硬编码**（值在代码中，但逻辑完整）。
   - GD：on_enter() 的 desc 硬编码"+3"，on_confirm() 也硬编码"+3"。**完全硬编码**。
   - 影响：两者都无配置化，但 JS 的可配性稍好（至少属性结构清晰）。

4) **初始化逻辑差异**（JS level 初始化为 2 vs GD 无初始化逻辑）：
   - JS：line 31–35：若 data["level"] 不存在，初始化为 2；然后 += 1，第一次升级后为 3。
   - GD：无初始化逻辑，假设 atk 已存在；若不存在则 get("atk", 0) 返回 0，再 + 3 = 3。
   - 影响：初始化策略不同；JS 假设发射器最低初始等级为 1（升级到 2），GD 假设玩家基础 atk 为 0 或已有值。

5) **百分比 vs 绝对值**（atkBonus += 0.05 vs atk += 3）：
   - JS：atkBonus 是倍数（每次 +5%，即 +0.05），影响攻击伤害的百分比增幅。
   - GD：atk 是绝对值（每次 +3 点），影响基础攻击力。
   - 影响：伤害计算差异；百分比增长会随玩家强度增加而增加（非线性），绝对值增长线性。

6) **生命周期完整性**（JS 5 个方法 vs GD 3 个）：
   - JS：onInit → onOpen → onConfirm/onSkip → onComplete（完整四个阶段）。
   - GD：_init → on_enter/on_confirm/on_skip（缺少 on_complete）。
   - 影响：GD 无法在升级完成后执行清理或后续逻辑。

7) **日志详细度**（JS 详尽 vs GD 无日志）：
   - JS：每个阶段都有日志，包括升级后的等级、加成百分比（line 42：`${(dataComponent.data["atkBonus"] * 100).toFixed(1)}%`）。
   - GD：无任何日志。
   - 影响：GD 的调试困难；无法追踪升级历史。

8) **返回值**（JS return true vs GD 无返回值）：
   - JS：onConfirm() return true（暗示事件完成）。
   - GD：on_confirm() 无返回值。
   - 影响：生命周期信号不同；JS 侧可用返回值判断是否结束，GD 侧需外部判断。

9) **属性访问差异**（JS 直接访问 vs GD 使用 get with default）：
   - JS：dataComponent.data["level"] 与 dataComponent.data["atkBonus"]（假设存在）。
   - GD：data_comp.data.get("atk", 0)（防御性获取）。
   - 影响：JS 若字段不存在会报错，GD 更安全；但 GD 的初始化逻辑不如 JS 明确。

10) **发射器数量假设**：
    - JS：遍历所有 launcherEntities，假设可能有多个发射器（例如左右各一个）。
    - GD：获取单个玩家，升级其属性。
    - 影响：游戏架构差异；JS 假设多发射器系统，GD 假设单一角色系统。

**总结**：GD 版本几乎是对 JS 的**完全重构**而非迁移，核心逻辑改变了（装备升级→角色属性升级）、升级内容改变了（level+atkBonus→atk+3）、目标对象改变了（all launchers→single player）。这已经不是"迁移遗漏"，而是"设计调整"。建议审查是否有意为之，或需要重新回到原 JS 设计。

----

文件: clearRoguelike/rests/RestRewardChest.js — 迁移完整性: 部分

JS 关键逻辑 / 行号
- 13–15 onInit(): log 初始化
- 17–19 onOpen(): log 打开
- 21–57 onConfirm():
  - 28–35 定义 rewardPool（6 项候选）
  - 38 prng = Prng.createPRNG(Date.now())
  - 39 count = 1 + floor(prng() * 2)（1–2 件）
  - 42–52 循环用 prng 随机选 itemId、查 MetaConsts.shopItems，wdm.addItem(itemId,1)，记录每项名称和总数（50–54）

GD 对应实现 / 行号 (gdRoguelike/rests/rest_reward_chest.gd)
- 8–9 on_enter(): 返回 UI 描述
- 11–16 on_confirm():
  - 12 item_ids = [60000001,60000002,60000003,60000004]（只有 4 项）
  - 13 selected = item_ids[randi() % item_ids.size()]
  - 14–16 world.inventory_service.add_item(selected, 1)
  - 无 count 随机化、无日志、无 MetaConsts 名称解析、无 PRNG 实例化

缺失 / 差异点 与 可能影响
- 配置驱动丢失：JS 的 rewardPool 与 MetaConsts 驱动被替换为小规模硬编码池 → 掉落多样性、稀有度、可配置性下降。
- 数量/权重差异：JS 随机 1–2 件且用 prng，可自控种子；GD 固定 1 件且用全局 randi() → 抽样分布与可复现性不同。
- 日志/反馈丢失：JS 有详细日志与用户可见奖励信息；GD 无日志/预览，玩家体验与调试受影响。
- 接口差异：wdm.addItem vs world.inventory_service.add_item（集成点不同，需确认语义一致）。

----
