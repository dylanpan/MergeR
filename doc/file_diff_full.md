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

文件: clearRoguelike/data/GameData.js — 迁移完整性: 是

JS 关键逻辑 / 行号 (clearRoguelike/data/GameData.js)
- 3 FORMAT_VERSION = 1
- 5–6 constructor()：空实现
- 14–66 load(json)：
  - 16–36 defaults 对象：定义所有字段的默认值（col/row/elements、lcol/lrow/launchers、scol/srow/shots、orderSelfId/orderSelf/orderEnermy/orderShop、level/round、items/currencies）
  - 39 Object.assign({}, defaults, json || {})：合并（defaults 为基础，json 覆盖）
  - 41–65 赋值到类属性
- 72–100 toJSON()：返回完整字典（含 _formatVersion、_saveTime、所有数据字段），使用 ...spread/JSON.parse(JSON.stringify(...)) 深拷贝
- 107–111 isValid(json) static：检查 json 与 version ≤ FORMAT_VERSION
- 114–250 getter/setter：对每个字段定义属性访问器（col、row、elements、lcol、lrow、launchers、scol、srow、shots、orderEnermy、orderSelf、orderSelfId、orderShop、level、round、items、currencies）

GD 对应实现 / 行号 (gdRoguelike/data/game_data.gd)
- 9 const FORMAT_VERSION = 1
- 11–42 属性声明（_format_version、_save_time、_col/_row/_elements、_lcol/_lrow/_launchers、_scol/_srow/_shots、_order_self_id/_order_self/_order_enermy/_order_shop、_level/_round、_items/_currencies）
- 43–44 _init()：设置 _save_time = Time.get_unix_time_from_system()
- 46–89 load(json_data)：
  - 47–64 defaults dict（同 JS 的字段列表）
  - 67–69 合并逻辑：var merged = defaults.duplicate(true); for key in json_data: merged[key] = json_data[key]
  - 71–89 逐个赋值到类属性（使用 .get() 与 type check）
- 91–112 to_json()：返回 dict（含所有数据字段），每个 collection 调用 .duplicate(true)
- 114–120 is_valid(json_data) static：检查 typeof 与 version
- 122–189 属性定义：每个字段用 var name: type 与 getter/setter（例：var col: int: get: return _col; set(value): _col = value）

缺失 / 差异点 与 可能影响
1) **load 合并逻辑略有差异**：
   - JS：Object.assign({}, defaults, json || {})（单行，JS 的 assign 右关联覆盖）
   - GD：merged = defaults.duplicate(true); for key in json_data: merged[key] = json_data[key]（显式循环）
   - 影响：逻辑等价，但 GD 更冗长；GD 的类型检查（"if merged.get(...) is Dictionary"）多了类型校验，可能比 JS 更严格

2) **深拷贝方式**：
   - JS：JSON.parse(JSON.stringify(...))（标准深拷贝，但仅适用于可 JSON 序列化的数据）
   - GD：.duplicate(true)（Godot 原生深拷贝，支持更多类型）
   - 影响：两者在纯数据结构上等价；GD 的方式对 Godot 对象更友好

3) **_save_time 赋值时机**：
   - JS：toJSON() 时赋 Date.now()（每次序列化时更新）
   - GD：_init() 时赋 Time.get_unix_time_from_system()（初始化时一次）
   - 影响：两者都会记录保存时间，但 JS 更新频度更高（每次 to_json）；GD 只在初始化时记录（可能导致时间戳陈旧）

4) **属性访问器实现**：
   - JS：getter/setter 显式定义每个字段（114–250），返回 || 默认值（例：return this._col || 7）
   - GD：属性用 var name: type with get/set 简写语法（122–189）
   - 影响：功能等价，但语法风格不同；GD 的简写更现代，JS 的显式更冗长

5) **isValid 严格度**：
   - JS：仅检查 json 存在、_formatVersion 存在且 ≤ FORMAT_VERSION
   - GD：检查 typeof(json_data) != TYPE_DICTIONARY，version check 同 JS
   - 影响：GD 多了类型检查（防止 null/错误类型），JS 相对宽松（可能接受其他类型对象）

6) **默认值处理差异**：
   - JS：getter 中写 || 默认值（例：get col() { return this._col || 7; }），但这在 0/false/null 时都会用默认值（潜在 bug）
   - GD：getter 返回 _col（无默认值逻辑在 getter 中），默认值在初始化或 load 时处理
   - 影响：JS 的 || 逻辑可能在某些边界条件下触发意外默认值（例如若 _col 被设为 0，则 get col 会返回 7）；GD 更严格

7) **level/round 的空值处理**（JS vs GD 差异注意）：
   - JS getter for level：`return this._level ?? 0;`（使用 nullish coalescing，仅 null/undefined 时用 0，0 本身保留）
   - 同理 round
   - GD：对应属性无特殊处理（假设总是有初值或在 load 时赋）
   - 影响：JS 对 level/round 的 nullish 处理更精细（不会把 0 误判为空）；GD 侧若未初始化可能为空

8) **to_json 时间戳更新**：
   - JS：toJSON 中 "_saveTime": Date.now()（每次调用都更新）
   - GD：to_json 中 "_saveTime": Time.get_unix_time_from_system()（同样每次更新）
   - 影响：两者都每次序列化更新时间戳，但与 load/init 的时间戳逻辑配合效果不同

**总结**：GameData 的 JS 与 GD 实现在**功能上几乎等价**，主要差异在语法、默认值处理策略、时间戳更新时机的细节。GD 的实现更加类型安全与严格，JS 的实现更灵活但存在潜在的 || 空值检查 bug（针对 level/round 已用 ?? 修正）。**迁移完整性评为"是"**因为核心逻辑完整保留。

----

文件: clearRoguelike/data/BuffContext.js — 迁移完整性: 部分

JS 关键逻辑 / 行号 (clearRoguelike/data/BuffContext.js)
- 6–32 constructor(options = {})：
  - 8 source = options.source || null（触发源实体）
  - 11 target = options.target || null（目标实体）
  - 14 timing = options.timing || null（当前触发时机）
  - 17 baseValue = options.baseValue || 0（原始数值，用于修正计算）
  - 20 modifiedValue = options.baseValue || 0（修正后数值，初始同 baseValue）
  - 23–25 attackData/damageData/bulletData = options.XXX || null（战斗数据透传）
  - 28 extra = options.extra || {}（自定义扩展数据）
  - 31 _cancelled = false（是否终止后续 Buff 执行）
- 37–39 cancel()：设置 this._cancelled = true
- 45–47 isCancelled()：返回 this._cancelled
- 53–55 setValue(value)：设置 modifiedValue = value
- 61–63 multiplyValue(factor)：累乘 modifiedValue *= factor
- 69–71 addValue(delta)：累加 modifiedValue += delta
- 77–86 toJSON()：返回序列化对象（source.id、target.id、timing、baseValue、modifiedValue、cancelled）

GD 对应实现 / 行号 (gdRoguelike/data/buff_context.gd)
- 11–19 属性声明：entity、source、buff_data: Dictionary = {}、trigger_timing: int = -1、extra: Dictionary = {}
- 21–24 _init(p_entity = null, p_source = null, p_buff_data: Dictionary = {})：设置 entity、source、buff_data
- 27–36 辅助方法：get_value()（返回 buff_data.get("value", 0.0)）、get_stack()（返回 buff_data.get("stack", 1)）、get_remaining_turns()（返回 buff_data.get("remainingTurns", -1)）

缺失 / 差异点 与 可能影响
1) **核心数值修正机制缺失**（JS 的 baseValue/modifiedValue 完全无对应）：
   - JS：baseValue 记录原始值，modifiedValue 记录修正后值，通过 setValue/multiplyValue/addValue 逐步修改。
   - GD：仅用 buff_data dict，无 baseValue/modifiedValue 分离，无值修改方法。
   - 影响：**关键缺失**——Buff 系统中复杂的数值链式修正（例如攻击力 = baseAtk × (1 + buffModifier1) × (1 + buffModifier2)）无法实现；无法追踪原始值与修正值的差异。

2) **cancel/isCancelled 机制缺失**（JS 的 _cancelled 与方法无对应）：
   - JS：_cancelled 标志与 cancel()/isCancelled() 方法，用于在 Buff 链执行中"短路"——某个 Buff 调用 cancel() 后，后续 Buff 不执行。
   - GD：完全无此机制。
   - 影响：**关键缺失**——BuffSystem.triggerTiming() 中的"if (context.isCancelled()) break"逻辑（见 BuffSystem 对照 line 225）无法实现；无法支持"一个 buff 阻止后续 buff 执行"的设计。

3) **值修改方法缺失**（setValue/multiplyValue/addValue）：
   - JS：提供三种修改 modifiedValue 的方式：直接赋值、乘法累加、加法累加。
   - GD：完全无这些方法。
   - 影响：外部 Buff 逻辑（或 BuffSystem）无法动态修改上下文中的数值；所有值修改必须在 Buff 子类内部实现。

4) **战斗数据字段缺失**（JS 的 attackData/damageData/bulletData）：
   - JS：这三个字段用于透传战斗相关的详细数据（攻击者信息、伤害类型、子弹属性等）。
   - GD：完全无对应字段，仅用泛用的 buff_data dict。
   - 影响：战斗细节数据无法通过 context 传递；Buff 逻辑需要从外部获取这些信息，导致耦合增强。

5) **扩展数据字段**（extra）：
   - JS：extra = options.extra || {}（自定义扩展）
   - GD：extra: Dictionary = {}（存在但无初始化传参）
   - 影响：GD 可能无法从外部初始化 extra，扩展数据受限。

6) **属性名称与数据结构**：
   - JS：target（目标）、timing（触发时机）等清晰的语义字段名。
   - GD：entity（实体，而非 target）、trigger_timing（字段名冗长）、buff_data 泛用 dict。
   - 影响：语义差异；GD 的设计相对模糊（entity vs target 含义略有不同）。

7) **toJSON 序列化**（JS 有对应，GD 缺失）：
   - JS：toJSON() 返回可序列化的纯对象（source.id、target.id 等）。
   - GD：无 to_json() 方法。
   - 影响：GD 的 BuffContext 无法被序列化用于日志/调试。

8) **辅助方法**（GD 的 get_value/get_stack/get_remaining_turns）：
   - JS：无对应方法，这些信息从 options 传入后直接存储。
   - GD：提供便捷访问器，从 buff_data 中提取。
   - 影响：GD 的方法更方便，但这不能弥补核心功能（cancel/setValue/multiplyValue）的缺失。

9) **触发时机字段**：
   - JS：timing 是传入的值，仅用于记录当前时机。
   - GD：trigger_timing: int = -1，初始为 -1（待设置）。
   - 影响：两者都用于记录时机，功能相似。

**总结**：GD 的 BuffContext 是 JS 的**严重简化版**，丢失了四个关键功能：
- **值修正链**（baseValue/modifiedValue/setValue/multiplyValue/addValue）——影响复杂 Buff 数值计算。
- **执行控制**（cancel/isCancelled）——影响 Buff 链的短路机制。
- **战斗数据透传**（attackData/damageData/bulletData）——影响数据流。
- **序列化**（toJSON）——影响调试与持久化。

这将**直接导致** BuffSystem.triggerTiming() 等复杂 Buff 交互失效。建议 GD 补充这些方法，或重新设计 Buff 执行模型。

----

文件: clearRoguelike/base/system/BuffSystem.js — 迁移完整性: 部分

JS 关键逻辑 / 行号 (clearRoguelike/base/system/BuffSystem.js)
- 12–21 constructor()：_entityBuffs = new Map()、_initialized = false。
- 23–28 getInstance()：单例模式。
- 30–35 init()：检查 _initialized，设置 true、记录日志。
- 37–41 dispose()：清空 _entityBuffs、设 _initialized=false、调用 super.dispose()。
- 56–103 addBuff(entity, buffType, value, duration, source)：
  - 57–60 参数校验。
  - 62–66 从 BuffRegistry 获取 BuffClass，校验存在。
  - 69–74 创建 Buff 实例（new BuffClass({type, value, duration, source})）。
  - 77–81 获取或创建 entity._entityBuffs[entity.id] 列表。
  - 84–88 检查同类 buff，若存在则 addStacks() 并返回（不新增）。
  - 91 新 buff push 到列表。
  - 94–99 创建 BuffContext、调用 buff.apply(context)（触发 ON_APPLY 回调）。
  - 101 记录详细日志。
  - 103 返回 buff。
- 110–131 removeBuff(entity, buffId)：查找 buff、调用 buff.remove(context)、删除。
- 139–150 getBuffs(entity, buffType=null)：返回过滤后的 buff 列表或全部。
- 158–161 hasBuff(entity, buffType)：检查是否有活跃 buff。
- 170–181 calculateModifier(entity, buffType, baseValue)：遍历 buff，累乘修正 finalValue *= (1 + buff.getBuffValue())。
- 187–205 clearBuffs(entity)：清除所有 buff，触发 remove 回调。
- 212–270 triggerTiming(timing, context)：
  - 213 设置 context.timing = timing。
  - 216–222 遍历所有实体与其 buff 列表。
  - 218–222 过滤需要当前时机的 buff。
  - 224–261 **巨大的 switch 语句**（分别处理 ROUND_START/ROUND_END/ATTACK_CHECK/DAMAGE_CALCULATE/CRIT_SETTLE/HURT/BULLET_CREATE/MOVE_CALCULATE/ATTACK_END/DAMAGE_SETTLE/ELEMENT_CHECK 共 11 种时机）。
    - 每种时机调用对应 buff 方法（buff.onRoundStart(context) 等）。
    - **第 225 行：if (context.isCancelled()) break;** ——关键的短路逻辑。
  - 265–268 移除已过期 buff。
- 275–286 onRoundStart/onRoundEnd：创建 context、调用 triggerTiming。
- 292–298 getDebugInfo()：返回所有 buff 的序列化信息。

GD 对应实现 / 行号 (gdRoguelike/core/system/buff_system.gd)
- 9–11 属性声明：_instance、_entity_buffs: Dictionary、_initialized: bool。
- 13–15 _init()：设置 _instance = self。
- 17–20 get_instance()：单例。
- 22–25 init()、dispose()、update()：基础方法。
- 40–80 add_buff(entity, buff_type_name: String, value, duration, source)：
  - 41–42 参数校验。
  - 45 class_path = BuffRegistry.get_buff_class(buff_type_name)。
  - 49 buff_type_enum = BUFF_TYPE_STRINGS.get(buff_type_name, BuffTypes.NONE)。
  - 52–54 获取或创建 entity_id 与 buff_list。
  - 59–62 检查同类 buff，若存在则 add_stacks(1) 并返回。
  - 65–72 load(class_path)、new BuffClass(...)、创建 buff 实例。
  - 74 push buff。
  - 77–78 创建 BuffContext、调用 buff.apply(context)。
  - 80 返回 buff。
- 85–100 remove_buff/remove_buff_by_id()。
- 121–135 get_buffs()。
- 140–149 has_buff()。
- 154–164 calculate_modifier()。
- 169–180 clear_buffs()。
- 185–237 trigger_timing(timing: int, context: BuffContext = null)：
  - 190–198 遍历实体与 buff，过滤需要时机的 buff。
  - 200–230 **match 语句**（分别处理 ON_APPLY/ON_REMOVE/ROUND_START/ROUND_END/ATTACK_CHECK/DAMAGE_CALCULATE/CRIT_SETTLE/HURT/BULLET_CREATE/MOVE_CALCULATE/ATTACK_END/DAMAGE_SETTLE/ACTION_PHASE/ELEMENT_CHECK 共 14 种时机）。
    - **无短路逻辑**（没有 if (context.isCancelled()) break;）。
  - 232–237 移除过期 buff。
- 242–251 onRoundStart/onRoundEnd。
- 256–265 getDebugInfo()。
- 270–303 BUFF_TYPE_STRINGS 映射表。

缺失 / 差异点 与 可能影响
1) **短路机制缺失**（JS line 225 if (context.isCancelled()) break; vs GD 无对应）：
   - JS：在 triggerTiming 循环中，若 context.isCancelled()，则 break 跳出当前实体的 buff 处理循环。
   - GD：无此检查，所有 buff 都会被触发。
   - **影响**：**关键缺失**。若某个 buff 想阻止后续 buff 执行（例如"盾牌 buff 吸收伤害后，后续伤害计算 buff 不执行"），在 GD 侧无法实现。这会改变 Buff 链的执行语义。

2) **BuffContext.isCancelled() 不可用**：
   - JS：BuffContext 提供 cancel()/isCancelled()（见前一对照）。
   - GD：BuffContext 缺失这些方法。
   - **影响**：JS 的短路机制依赖 BuffContext.isCancelled()；GD 侧即使补充短路代码也会失效（因为 context 无 isCancelled 方法）。

3) **动态加载与类型映射差异**（line 45、49）：
   - JS：BuffRegistry.getBuffClass(buffType) 直接返回 class 引用。
   - GD：BuffRegistry.get_buff_class(buff_type_name) 返回 class_path（字符串路径），后续 load(class_path)。
   - 影响：GD 的实现假设 registry 存储路径字符串；若 registry 实际存储 class 引用（见 buff_registry.gd line 11 register_buff 接收 class_ref），则 load(class_path) 会失败。**需核实 registry 的返回类型**。

4) **触发时机枚举差异**（11 种 vs 14 种）：
   - JS：ROUND_START、ROUND_END、ATTACK_CHECK、DAMAGE_CALCULATE、CRIT_SETTLE、HURT、BULLET_CREATE、MOVE_CALCULATE、ATTACK_END、DAMAGE_SETTLE、ELEMENT_CHECK。
   - GD：ON_APPLY、ON_REMOVE、ROUND_START、...、ACTION_PHASE、ELEMENT_CHECK。
   - 差异：GD 多了 ON_APPLY/ON_REMOVE 作为独立时机，JS 则在 add_buff/removeBuff 中直接调用（不通过 triggerTiming）；GD 多了 ACTION_PHASE。
   - 影响：时机枚举不对齐，可能导致某些时机在 JS 版本被跳过，或在 GD 版本被异常触发。

5) **buff 方法命名差异**（camelCase vs snake_case）：
   - JS：buff.onRoundStart(context)、buff.onAttackCheck(context) 等。
   - GD：buff.on_round_start(context)、buff.on_attack_check(context) 等。
   - 影响：GD 的 match 语句调用 buff.on_round_start 等方法；若 buff 子类命名不匹配会导致方法调用失败（例如 GD buff 定义 on_round_start 但 system 尝试调用 onRoundStart）。**需核实 buff 实现的方法命名是否与 system 调用一致**。

6) **参数形式差异**（line 40 vs line 56）：
   - JS addBuff：(entity, buffType: string, value: number, duration: number, source: any)。
   - GD add_buff：(entity, buff_type_name: String, value: float = 0.0, duration: int = -1, source = null)。
   - 影响：参数默认值设置不同（JS 无默认，GD 有默认），可能影响调用端的传参习惯。

7) **日志与调试**：
   - JS：addBuff 第 101 行有详细日志；removeBuff 第 130 行有日志；clearBuffs 第 204 行有日志。
   - GD：add_buff 等处无日志（或用 silent return）。
   - 影响：GD 的调试能见度低。

8) **过期 buff 清理**（line 265–268 vs line 232–237）：
   - 两者都在 triggerTiming 末尾检查并移除过期 buff，逻辑相似。

9) **calculateModifier 的累乘逻辑**（line 177 vs line 163）：
   - JS：finalValue *= (1 + buff.getBuffValue())。
   - GD：final_value *= (1.0 + buff.get_buff_value())。
   - 逻辑相同，仅风格差异。

10) **单例初始化**：
    - JS：getInstance 检查 !this._instance 后创建（line 24–27）。
    - GD：_init 中设置 _instance = self；getInstance 检查后创建（line 13–20）。
    - 都是单例，方式略有不同但等价。

11) **BUFF_TYPE_STRINGS 映射表**（line 270–303 GD only）：
    - GD 维护一个静态映射表，将字符串 buff 类型名（"atk_up"、"def_up" 等）映射到枚举值。
    - JS 不需要此映射（因为 buffType 本身可能就是字符串或直接用枚举）。
    - 影响：两侧对 buff 类型的标识方式不同；GD 用字符串名称 + 映射表，JS 可能用直接枚举。这可能影响 BuffRegistry 的存储与查询方式。

**总结**：GD 的 BuffSystem 在**整体结构上与 JS 相似**（单例、addBuff/removeBuff/getBuffs/triggerTiming），但在几个关键点上有重要差异：
- **短路机制缺失**（会影响复杂 buff 交互）。
- **动态加载实现可能有 bug**（load(class_path) 若 registry 不存储路径会失败）。
- **触发时机枚举不一致**（ON_APPLY/ON_REMOVE、ACTION_PHASE 差异）。
- **buff 方法命名可能不匹配**（camelCase vs snake_case）。
- **日志详细度不足**。

这些差异可能导致复杂 buff 逻辑失效或产生运行时错误。建议重点检查：
1. BuffRegistry.get_buff_class 的返回类型。
2. BaseBuff 的方法命名是否与 BuffSystem.trigger_timing 的 match 调用一致。
3. 补充 BuffContext 的 cancel/isCancelled 方法与 BuffSystem 的短路逻辑。

----

文件: clearRoguelike/base/system/EventSystem.js — 迁移完整性: 部分

JS 关键逻辑 / 行号 (clearRoguelike/base/system/EventSystem.js)
- 13–18 constructor()：
  - 初始化 _curEventEntity = null。
  - EventManager.register(this, "event.event.optionSelect")：注册全局事件监听。
- 20–26 dispose()：
  - EventManager.unregister(this)。
  - 若 _curEventEntity 存在，调用 dispose() 并置空。
- 28–30 update(dt)：空实现（事件系统不需帧更新）。
- 32–36 onEvent(event, arg)：处理来自 EventManager 的事件回调。
- 42–61 openEvent(eventId)：
  - 42 **async 关键字**（异步方法）。
  - 43–46 检查是否已有打开的事件。
  - 48 const eventEntity = **await** EventFactory.createEventEntity(eventId)：**异步等待**工厂创建。
  - 53 _curEventEntity = eventEntity。
  - 56 eventEntity.open()。
  - 58 WorldDataManager.getInstance().addEventEntity(eventEntity)：注册到全局管理器。
  - 60 return true。
- 66–71 closeCurrentEvent()：检查 _curEventEntity、调用 close()、置空。
- 76–84 _onOptionSelect(data)：
  - 79 const result = _curEventEntity.selectOption(data ? data.optionId : null)。
  - 81–83 若 result 为 true，置空 _curEventEntity（暗示事件结束）。
- 86–89 getter currentEvent：返回 _curEventEntity。

GD 对应实现 / 行号 (gdRoguelike/core/system/event_system.gd)
- 8 var _cur_event_entity = null。
- 10–11 _init()：空。
- 13–16 dispose()：置空 _cur_event_entity。
- 18–19 update(dt)：空。
- 22–36 open_event(event_id)：
  - 23–25 检查已有事件。
  - 27 var event_entity = EventFactory.create_event_entity(event_id)：**同步调用**（无 await）。
  - 31 _cur_event_entity = event_entity。
  - 32 event_entity.open()。
  - 34–35 若 _world 存在，调用 _world.entity_manager.register_entity(event_entity)。
  - 36 return true。
- 39–47 trigger_event(entity)：
  - 40–41 获取 entity.on_enter() 返回的 event_data。
  - 43 _cur_event_entity = entity。
  - 45–46 若 _world 存在，调用 register_entity；emit GlobalEventBus.event_event_open(entity.get_id(), event_data)。
- 49–52 close_current_event()：检查、close()、置空。
- 55–60 resolve_option(entity, option_id)：
  - 56–59 若 entity 有 on_option_select，调用并获 result；若 result 为 true，置空 _cur_event_entity。
  - 60 emit GlobalEventBus.event_event_close()。

缺失 / 差异点 与 可能影响
1) **异步 vs 同步**（JS async/await vs GD 同步）：
   - JS：openEvent 是 async 方法，使用 await EventFactory.createEventEntity(eventId)（允许异步加载模块）。
   - GD：open_event 是同步方法，直接调用 EventFactory.create_event_entity(event_id)（无 await，同步返回）。
   - 影响：JS 支持动态模块加载（lazy loading），可能降低启动时间；GD 同步加载可能阻塞主线程（若工厂加载耗时）。两者在处理加载错误的方式上差异（JS 可用 try-catch，GD 的同步调用需在工厂内处理）。

2) **事件系统架构差异**（EventManager vs GlobalEventBus）：
   - JS：使用 EventManager 单例来注册/注销监听，openEvent 内部无显式事件发送（可能由外部系统通过 EventManager 驱动）。
   - GD：使用 GlobalEventBus（信号系统）来 emit 事件（event_event_open、event_event_close），触发上层 UI 或其他系统响应。
   - 影响：**架构理念不同**。JS 用观察者模式（register listener），GD 用信号系统（emit signal）。两者的事件流向与耦合方式完全不同，可能影响整体系统集成。

3) **元数据与节点传参**（JS openEvent(eventId, node) vs GD open_event(event_id)）：
   - JS：openEvent 支持 node 参数（虽然代码中未使用），可能用于传递 UI 节点。
   - GD：open_event 无 node 参数（openEvent 中无对应传递）。
   - 影响：GD 的事件实例无法直接获得 UI 节点上下文；若需要，必须从 world 或其他地方获取。

4) **entity 注册的集成点不同**：
   - JS：WorldDataManager.getInstance().addEventEntity(eventEntity)。
   - GD：_world.entity_manager.register_entity(event_entity)。
   - 影响：JS 用 WorldDataManager（可能是全局存储），GD 用 world.entity_manager（ECS 架构注册）。两者的实体管理方式不同，可能影响事件实体的生命周期与可访问性。

5) **trigger_event 方法独有于 GD**：
   - JS：无对应方法。
   - GD：trigger_event(entity) 允许直接触发现有实体作为事件（不需通过工厂创建）。
   - 影响：GD 的设计更灵活（支持预创建的事件实体），但增加了 API 表面积（JS 侧可能不需要此功能）。

6) **resolve_option 方法独有于 GD**：
   - JS：_onOptionSelect 是私有方法，通过 EventManager.register listener 的方式调用。
   - GD：resolve_option 是公开方法，外部可直接调用（或由 GlobalEventBus 驱动）。
   - 影响：GD 的方法可被外部直接调用，增加了灵活性但也增加了耦合可能。

7) **事件结果处理**（return value vs GlobalEventBus signal）：
   - JS：_onOptionSelect 检查 result，若 true 则置空 _curEventEntity（通过返回值判断完成）。
   - GD：resolve_option 同样检查 result，但还会额外 emit GlobalEventBus.event_rest_close（有显式信号）。
   - 影响：GD 的信号机制更显式（容易被其他系统监听），但可能导致多处理流（signal emit + 状态更新）。

8) **onEvent callback vs no listener registration in GD**：
   - JS：onEvent(event, arg) 作为 EventManager.register 的回调（line 32–36）。
   - GD：无对应的监听器注册（open_event/trigger_event/resolve_option 都是外部调用）。
   - 影响：GD 的事件驱动方式依赖于外部调用（可能来自 UI 控制器或 GlobalEventBus listener），而非内部的被动监听。这改变了事件流的管理点。

9) **_world 引用**（GD only）：
   - GD 的 open_event 与 trigger_event 中都检查 if _world 才进行 entity_manager.register_entity。
   - JS 无 _world，直接用 WorldDataManager.getInstance()。
   - 影响：GD 需要 world 引用被正确初始化，否则实体不会被注册；JS 使用全局单例，无此依赖。

10) **生命周期完整性**：
    - JS：onInit（无在代码中）、openEvent、onEvent/selectOption、closeCurrentEvent。
    - GD：open_event、trigger_event、resolve_option、close_current_event。
    - 两者流程相似，但 GD 缺少事件初始化阶段的显式处理（可能在 open_event 内或事件实例 _init 中）。

11) **日志与错误处理**：
    - JS：openEvent 若 eventEntity 为 null 则 return false（无日志，错误处理由工厂负责）。
    - GD：open_event 同样 return false if eventEntity is null，无日志。
    - 影响：两者的错误可见度都不高。

**总结**：GD 的 EventSystem 与 JS **在功能流程上相似**（openEvent→open()→register→selectOption/close），但在**架构层面差异巨大**：
- **异步/同步加载**：JS 异步，GD 同步。
- **事件系统**：JS 用 EventManager（观察者），GD 用 GlobalEventBus（信号）。
- **实体管理**：JS 用 WorldDataManager，GD 用 world.entity_manager。
- **额外方法**：GD 有 trigger_event/resolve_option，JS 通过 onEvent/EventManager 隐式处理。

这些差异反映了两个版本底层架构的不同选择。建议梳理整体的事件驱动流程，确保 UI 控制器、EventSystem、事件实体、GlobalEventBus 之间的调用链一致。

----

文件: clearRoguelike/base/system/RestSystem.js — 迁移完整性: 部分

JS 关键逻辑 / 行号 (clearRoguelike/base/system/RestSystem.js)
- 14–22 constructor()：
  - 初始化 _currentRest = null。
  - EventManager.register(this, "event.rest.confirm")。
  - EventManager.register(this, "event.rest.skip")。
  - EventManager.register(this, "event.rest.close")：注册三个全局事件监听。
- 24–31 dispose()：
  - EventManager.unregister(this)。
  - 若 _currentRest 存在，调用 dispose() 并置空。
  - 调用 super.dispose()。
- 33–41 onEvent(event, arg)：
  - 处理 "event.rest.confirm" → onRestConfirm()。
  - 处理 "event.rest.skip" → onRestSkip()。
  - 处理 "event.rest.close" → onRestClose()。
- 43–45 update(dt)：注释"系统运行时更新逻辑"（但无实现）。
- 52–70 openRest(restId, node = null)：
  - 52 **async 关键字**。
  - 56–59 关闭当前休息点（若存在）。
  - 62 const restEntity = **await** RestFactory.createRestEntity(restId, node)：**异步等待**。
  - 68 _currentRest = restEntity。
  - 69 _currentRest.open()。
- 75–80 onRestConfirm()：
  - 77–79 若 _currentRest 存在，调用 confirm()。
- 85–90 onRestSkip()：
  - 87–89 若 _currentRest 存在，调用 skip()。
- 95–101 onRestClose()：
  - 97–99 若 _currentRest 存在，调用 dispose()、置空。
- 107–110 getter currentRest：返回 _currentRest。

GD 对应实现 / 行号 (gdRoguelike/core/system/rest_system.gd)
- 8–15 _init()、dispose()、update(dt)：基础方法（dispose/update 为空或仅注释）。
- 17–21 open_rest(entity)：
  - 19 var rest_data = entity.on_enter() if entity.has_method("on_enter") else {}。
  - 21 GlobalEventBus.event_rest_open.emit(entity.get_id(), rest_data)。
- 23–27 confirm_rest(entity)：
  - 24–25 若 entity 有 on_confirm，调用。
  - 26–27 emit GlobalEventBus.event_rest_confirm() 与 event_rest_close()。
- 29–33 skip_rest(entity)：
  - 30–31 若 entity 有 on_skip，调用。
  - 32–33 emit GlobalEventBus.event_rest_skip() 与 event_rest_close()。

缺失 / 差异点 与 可能影响
1) **异步 vs 同步**（JS async openRest vs GD 同步 open_rest）：
   - JS：openRest 是 async，使用 await RestFactory.createRestEntity(restId, node)。
   - GD：open_rest 是同步，直接调用 entity.on_enter()（假设 entity 已存在）。
   - 影响：JS 支持异步工厂创建（可能涉及 IO），GD 假设实体已预先创建。两者的加载时序与错误处理策略完全不同。

2) **中央状态管理缺失**（JS _currentRest vs GD 无对应）：
   - JS：RestSystem 持有 _currentRest 指针，管理当前打开的休息点生命周期（open/confirm/skip/close）。
   - GD：无中央 _currentRest，open_rest/confirm_rest/skip_rest 都是独立方法，接收 entity 参数，无状态跟踪。
   - **影响**：**关键缺失**。JS 通过 _currentRest 确保同一时间仅一个休息点活跃，并协调其生命周期；GD 则完全依赖外部调用端的正确时序。若调用端出错（例如连续 open_rest 两次），JS 会自动 close 前一个，GD 则无保护。

3) **事件系统架构**（EventManager listener vs GlobalEventBus signal）：
   - JS：EventManager.register(this, "event.rest.confirm") 等，被动监听全局事件。
   - GD：不注册监听，而是主动 emit GlobalEventBus.event_rest_confirm/close 等信号（由外部监听）。
   - 影响：事件驱动方向反转。JS 侧 RestSystem 是被动监听并响应的（类似中断处理），GD 侧是主动发送信号的（类似事件发布）。两者的事件流向完全不同。

4) **实体获取与工厂创建**（JS 工厂创建 vs GD 外部传入）：
   - JS：openRest(restId, node) 接收 restId，由工厂创建实体，由 RestSystem 管理生命周期。
   - GD：open_rest(entity) 接收已创建的 entity，由外部决定何时创建、如何销毁。
   - 影响：GD 的设计更灵活（可预创建复用实体），但职责不清（谁负责创建销毁？）。JS 的设计更明确（RestSystem 负责全生命周期）。

5) **node 参数**（JS 支持，GD 不支持）：
   - JS：openRest(restId, node) 允许传递 UI 节点。
   - GD：open_rest(entity) 无 node 参数（entity 本身可能包含 UI 引用）。
   - 影响：GD 的 rest 实体与 UI 的关系需在 entity 层面维护。

6) **响应方法的语义**（onRestConfirm/onRestSkip vs confirm_rest/skip_rest）：
   - JS：onRestConfirm/onRestSkip 是内部响应方法（被 EventManager 调用），对应用户在 UI 上的操作。
   - GD：confirm_rest/skip_rest 是公开方法（外部可直接调用），同样响应用户操作。
   - 影响：JS 隐式事件链（UI → EventManager → onRestConfirm），GD 显式方法调用。

7) **生命周期管理**（JS _currentRest 持有 vs GD 无状态）：
   - JS 的 onRestClose 显式调用 _currentRest.dispose() 并置空，确保资源释放。
   - GD 无对应 _currentRest，无法追踪当前活跃 rest，无法保证只有一个 rest 同时打开。
   - 影响：GD 可能导致多个 rest 同时活跃（若上层调用逻辑有误），或资源泄漏（无显式 dispose）。

8) **处理流程完整性**（confirm vs confirm+close）：
   - JS：onRestConfirm 仅调用 _currentRest.confirm()，close 由外部或 UI 层显式触发（onRestClose）。
   - GD：confirm_rest 既调用 entity.on_confirm()，也 emit event_rest_close（一步完成确认+关闭）。
   - 影响：GD 的流程更快速（不需分开调用 close），但灵活性降低（无法在 confirm 后保持 rest 活跃）。

9) **skip 流程**（同样的 confirm vs confirm+close 差异）：
   - JS：onRestSkip 仅调用 skip()，close 分开。
   - GD：skip_rest 既调用 on_skip()，也 emit event_rest_skip + event_rest_close。

10) **返回值**：
    - JS 的 openRest 返回 void（或隐式 undefined），无返回值。
    - GD 的各方法均无返回值。
    - 影响：两者都无法通过返回值判断成功/失败。JS 的错误处理在 RestFactory（传播 null），GD 的错误处理需在调用端检查。

11) **update(dt) 方法**：
    - JS：注释"系统运行时更新逻辑"但无实现。
    - GD：同样空实现（pass）。
    - 影响：两者都未使用帧更新机制；rest 的所有逻辑都在事件驱动下进行（非连续时间轴）。

12) **dispose 的彻底性**：
    - JS：dispose 显式 unregister EventManager listener、dispose _currentRest、调用 super.dispose()。
    - GD：dispose 为空。
    - 影响：GD 侧若 rest_system 被销毁，其管理的实体可能未被正确清理（如果有的话）。

**总结**：GD 的 RestSystem 与 JS **在职责与架构上差异最大**：
- **中央状态管理缺失**：JS 有 _currentRest，GD 无（无法保证单一活跃 rest）。
- **异步 vs 同步**：JS 异步创建，GD 外部传入。
- **事件系统**：JS 被动监听，GD 主动发信号。
- **生命周期**：JS 显式管理（open→confirm/skip→close），GD 隐式/快速（confirm/skip 直接 close）。
- **资源管理**：JS 有 dispose 保护，GD 无。

这些差异表明 GD 的 RestSystem 是**大幅简化的设计**，假设外部调用端会正确协调 rest 的创建、响应、销毁。建议梳理完整的 rest 生命周期流程（谁创建→谁触发→谁销毁），确保 GD 的无状态设计不会导致状态污染或资源泄漏。

----

文件: clearRoguelike/base/buffs/BaseBuff.js — 迁移完整性: 是

JS 关键逻辑 / 行号 (clearRoguelike/base/buffs/BaseBuff.js)
- 9–45 constructor(buffData)：
  - 11 id = buffData.id || `buff_${Date.now()}_${Math.floor(Math.random() * 10000)}`
  - 14 type = buffData.type || BuffTypes.NONE
  - 17 value = buffData.value || 0
  - 20 duration = buffData.duration || -1（-1 表示永久）
  - 23 remainingDuration = buffData.remainingDuration ?? this.duration（nullish coalescing）
  - 26 stacks = buffData.stacks || 1
  - 29 maxStacks = buffData.maxStacks || 99
  - 32 source = buffData.source || null
  - 35/38/41 isExpired/isActive/category 初始化
  - 44 triggerTiming = []（触发时机列表）
- 51–53 apply(context)：设置 isActive = true
- 59–61 remove(context)：设置 isActive = false
- 67–82 onRoundEnd(context)：
  - 76–82 若 duration > 0，remainingDuration--，≤0 时设 isExpired = true
- 88–154 多个 onXXX 钩子方法（onRoundStart/onAttackCheck/onDamageCalculate/onCritSettle/onHurt/onBulletCreate/onMoveCalculate/onAttackEnd/onDamageSettle/onElementCheck）：都是空实现，等待子类覆盖
- 160–162 addStacks(stacks = 1)：stacks = Math.min(this.stacks + stacks, maxStacks)
- 168–173 removeStacks(stacks = 1)：stacks = Math.max(this.stacks - stacks, 0)；若 ≤0 设 isExpired = true
- 179–181 getBuffValue()：return value * stacks
- 187–200 toJSON()：返回序列化对象（id/type/value/duration/remainingDuration/stacks/maxStacks/source/isExpired/isActive）

GD 对应实现 / 行号 (gdRoguelike/core/buffs/base_buff.gd)
- 11–33 属性声明：id、type、value、duration、remaining_duration、stacks、max_stacks、source、is_expired、is_active、category、trigger_timing
- 35–47 _init(buff_data: Dictionary = {})：
  - 36 id = buff_data.get("id", "buff_" + str(Time.get_unix_time_from_system()) + "_" + str(randi() % 10000))
  - 37–42 逐个赋值 type、value、duration、remaining_duration、stacks、max_stacks、source
  - 43–47 初始化 is_expired、is_active、category、trigger_timing = []
- 49–53 apply(context)、remove(context)：设置 is_active
- 55–62 on_round_end(context)：
  - 59–62 若 duration > 0，remaining_duration -= 1，≤0 时设 is_expired = true
- 64–92 多个 on_xxx 方法：onRoundStart/onAttackCheck/onDamageCalculate/onCritSettle/onHurt/onBulletCreate/onMoveCalculate/onAttackEnd/onDamageSettle/onElementCheck/onActionPhase（11 个，JS 有 10 个；GD 多一个 on_action_phase）
- 94–100 add_stacks/remove_stacks：逻辑同 JS
- 102–103 get_buff_value()：return value * stacks
- 105–117 to_json()：返回 dict，字段名用 camelCase（"remainingDuration"、"maxStacks"、"isExpired"、"isActive"）

缺失 / 差异点 与 可能影响
1) **命名风格**（camelCase vs snake_case）：
   - JS：isExpired、isActive、remainingDuration、maxStacks、triggerTiming
   - GD：is_expired、is_active、remaining_duration、max_stacks、trigger_timing（内部属性）；但 to_json() 返回 camelCase 键名（保持兼容）
   - 影响：语言习惯差异，但不影响功能；GD 的 to_json 映射正确，可兼容。

2) **id 生成方式**：
   - JS：`buff_${Date.now()}_${Math.floor(Math.random() * 10000)}`（毫秒时间戳 + 随机数）
   - GD：`"buff_" + str(Time.get_unix_time_from_system()) + "_" + str(randi() % 10000)`（秒级时间戳 + 随机数）
   - 影响：GD 的时间戳粒度更粗（秒 vs 毫秒），在高频创建 buff 时可能产生重复 id（概率极低但理论存在）。

3) **remainingDuration 初始化**（nullish coalescing ?? vs get with default）：
   - JS：remainingDuration = buffData.remainingDuration ?? this.duration（若为 null/undefined 则用 duration）
   - GD：remaining_duration = buff_data.get("remainingDuration", duration)（若不存在则用 duration）
   - 影响：逻辑等价，GD 更安全（无需预先访问 this.duration）。

4) **onActionPhase 方法**（GD only）：
   - JS：无此方法
   - GD：额外的 on_action_phase(context) 钩子（line 91–92）
   - 影响：GD 扩展了触发时机，可能对应新的游戏系统（例如"行动阶段"相关的 buff 效果）。若 BuffSystem.trigger_timing 中有对应的 ACTION_PHASE 时机，则此方法会被调用。

5) **toJSON 字段完整性**：
   - 两者都返回相同的字段（id/type/value/duration/remainingDuration/stacks/maxStacks/source/isExpired/isActive）。

6) **初始化的完整性**：
   - JS：constructor 中显式初始化所有属性，逻辑清晰。
   - GD：_init 中赋值，但需确保 buff_data 包含所有必要字段（否则 get with default 会用默认值）。

**总结**：BaseBuff 的 JS 与 GD 实现**在功能上完全等价**，主要差异为：
- **命名风格**：snake_case（内部）vs camelCase（序列化），但一致性良好。
- **时间戳精度**：秒 vs 毫秒（理论影响极小）。
- **额外方法**：GD 多一个 on_action_phase（扩展功能）。

**迁移完整性评为"是"**因为核心逻辑、生命周期、所有钩子方法都完整保留。GD 版本甚至扩展了触发时机支持。

----

文件: clearRoguelike/base/buffs/BuffRegistry.js — 迁移完整性: 是

JS 关键逻辑 / 行号 (clearRoguelike/base/buffs/BuffRegistry.js)
- 2 _registryMap = new Map()（静态私有映射表）
- 8–10 registerBuff(type, clazz) static：this._registryMap.set(type, clazz)
- 17–19 getBuffClass(type) static：return this._registryMap.get(type) || null
- 26–28 hasBuff(type) static：return this._registryMap.has(type)
- 34–36 getAllBuffTypes() static：return Array.from(this._registryMap.keys())

GD 对应实现 / 行号 (gdRoguelike/core/buffs/buff_registry.gd)
- 8 static var _registry: Dictionary = {}（静态私有映射表）
- 10–11 register_buff(type_str: String, class_ref) static：_registry[type_str] = class_ref
- 13–14 get_buff_class(type_str: String) static：return _registry.get(type_str, null)
- 16–17 has_buff(type_str: String) static：return _registry.has(type_str)
- 19–20 get_all_buff_types() static：return _registry.keys()

缺失 / 差异点 与 可能影响
1) **数据结构差异**（Map vs Dictionary）：
   - JS：使用 Map（键值对映射，高效查询）
   - GD：使用 Dictionary（键值对映射，等价功能）
   - 影响：性能上无差异（两者都是 O(1) 查询）；语言特性差异，但逻辑等价。

2) **getAllBuffTypes 返回形式**（Array vs Array）：
   - JS：Array.from(this._registryMap.keys())（显式转换为数组）
   - GD：_registry.keys()（返回 keys view，通常可迭代）
   - 影响：在 GD 侧 get_all_buff_types() 返回的是 keys view 而非数组，若调用端期望数组，需要显式转换（例如 Array(_registry.keys())）。这是潜在的 API 不一致（若上游代码做 .length 或索引访问会失败）。

3) **API 命名**（camelCase vs snake_case）：
   - JS：registerBuff、getBuffClass、hasBuff、getAllBuffTypes
   - GD：register_buff、get_buff_class、has_buff、get_all_buff_types
   - 影响：方法名风格不同，但在内部调用时需对应（BuffSystem 中调用 get_buff_class 时需用 snake_case）。

4) **参数名**（type vs type_str）：
   - JS：type（泛用）
   - GD：type_str（明确字符串类型）
   - 影响：仅文档性差异，无功能影响。

5) **返回值一致性**（|| null vs get with default）：
   - JS：this._registryMap.get(type) || null（若 undefined 则返回 null）
   - GD：_registry.get(type_str, null)（若不存在返回 null default）
   - 影响：逻辑等价，GD 更明确。

**总结**：BuffRegistry 的 JS 与 GD 实现**在功能上完全等价**，仅存在语言特性与命名风格的差异。

**潜在问题**：GD 的 get_all_buff_types() 返回 keys view 而非数组，若上游代码假设返回数组会出现问题。建议 GD 补充 `return _registry.keys()` 改为 `return Array(_registry.keys())` 确保一致性。

**迁移完整性评为"是"**因为四个方法都完整迁移，功能等价。

---

## 📋 1️⃣ OrderEnermyEntity.js 对照报告 (缺失 90%)

### 文件位置
- **JS**: clearRoguelike/base/entity/OrderEnermyEntity.js (191 行)
- **GD**: gdRoguelike/core/entity/order_enermy_entity.gd (46 行)
- **迁移完整度**: 仅 10%

---

### 核心差异 - 缺失的功能块

#### ❌ 1. 敌人初始化方法 (行 49-108)

| 功能 | JS 行号 | GD 代码 | 状态 | 备注 |
|------|--------|--------|------|------|
| **完整的 init(data) 方法** | 49-108 | 无 | ❌ 完全缺失 | 敌人数据无法初始化 |
| 数据组件初始化 | 50-52 | 无 | ❌ 缺失 | 敌人属性无法加载 |
| BuffId 配置初始化 | 54-65 | 无 | ❌ 缺失 | 敌人固有Buff无法应用 |
| Buff 从JSON恢复 | 68-71 | 无 | ❌ 缺失 | 无法恢复战斗状态 |
| **Boss判定与分化初始化** | 74-106 | 无 | ❌ 完全缺失 | 无法区分Boss/普通敌人 |
| └─ Boss UI初始化 (BossUI) | 77-79 | 无 | ❌ 缺失 | Boss无法显示UI |
| └─ 普通敌人UI初始化 (OrderEnermyUI) | 100-103 | 无 | ❌ 缺失 | 敌人无法显示UI |
| └─ Boss能力初始化调用 | 95 | 无 | ❌ 缺失 | Boss组件无法初始化 |

**可能影响**: 敌人系统完全无法工作，战斗流程断裂 🔴 **严重**

---

#### ❌ 2. Boss 能力初始化方法 (行 110-140)

| 功能 | JS 行号 | GD 代码 | 状态 | 备注 |
|------|--------|--------|------|------|
| **_initBossAbilities() 整个方法** | 110-140 | 无 | ❌ 完全缺失 | Boss系统无法启动 |
| 阶段管理器初始化 | 113-117 | 无 | ❌ 缺失 | Boss阶段切换无法进行 |
| 技能管理器初始化 | 120-124 | 无 | ❌ 缺失 | Boss技能无法使用 |
| 元素变化初始化 | 127-130 | 无 | ❌ 缺失 | Boss元素变化无法工作 |
| 护盾初始化 | 134-136 | 无 | ❌ 缺失 | Boss护盾无法激活 |
| 日志记录 | 138 | 无 | ❌ 缺失 | 调试信息无法输出 |

**可能影响**: Boss战斗系统完全失效 🔴 **严重**

---

#### ❌ 3. Boss 四大组件系统 (行 82-92)

| 组件 | JS 行号 | 用途 | GD 状态 | 影响 |
|------|--------|------|--------|------|
| SkillComponent | 82 | Boss技能管理 | ❌ 无 | Boss无法释放技能 |
| ShieldComponent | 85 | Boss护盾保护 | ❌ 无 | Boss护盾系统失效 |
| ElementChangeComponent | 88 | Boss元素变化 | ❌ 无 | Boss无法变换元素 |
| PhaseManagerComponent | 91 | Boss分阶段管理 | ❌ 无 | Boss无法切换阶段 |

**可能影响**: Boss四大核心能力全部无法实现 🔴 **严重**

---

#### ❌ 4. Boss 判定方法 (行 144-148)

| 功能 | JS 行号 | GD 代码 | 状态 | 备注 |
|------|--------|--------|------|------|
| **isBoss() 判定方法** | 144-148 | 无 | ❌ 完全缺失 | 无法区分敌人类型 |
| 返回值 | - | - | ❌ 无 | 无法判断 phases 存在 |

**可能影响**: 无法判断是Boss还是普通敌人，init()中的分化逻辑无法执行 🔴 **严重**

---

#### ❌ 5. 伤害计算系统 (行 151-181)

| 功能 | JS 行号 | GD 代码 | 状态 | 备注 |
|------|--------|--------|------|------|
| **applyDamageToTarget() 整个方法** | 151-181 | 无 | ❌ 完全缺失 | 伤害处理机制缺失 |
| 护盾检查 | 156-167 | 无 | ❌ 缺失 | 护盾无法吸收伤害 |
| 护盾完全吸收检查 | 159-164 | 无 | ❌ 缺失 | 伤害被完全挡住时无提前返回 |
| 剩余伤害计算 | 166 | 无 | ❌ 缺失 | 伤害溅射计算无法进行 |
| 伤害事件触发 | 173-178 | 无 | ❌ 缺失 | UI伤害动画无法显示 |
| 日志记录 | 180 | 无 | ❌ 缺失 | 调试信息无法输出 |

**对应的GD实现** (仅有基础版本):
```
GD: reduce_hp(amount) - 仅简单扣血，无护盾逻辑、无事件触发
```

**可能影响**: 伤害计算不完整，护盾系统无法工作，UI无法更新 🔴 **严重**

---

### 缺失内容清单

| 序号 | 缺失内容 | JS 位置 | 重要性 | 影响范围 |
|------|---------|--------|--------|---------|
| 1 | init(data) 方法 | 49-108 | **严重** | 敌人初始化 |
| 2 | _initBossAbilities() 方法 | 110-140 | **严重** | Boss初始化 |
| 3 | isBoss() 方法 | 144-148 | **严重** | Boss判定 |
| 4 | applyDamageToTarget() 方法 | 151-181 | **严重** | 伤害计算 |
| 5 | dispose() 方法 | 183-190 | 中等 | 资源清理 |
| 6 | SkillComponent 组件 | 82 | **严重** | Boss技能 |
| 7 | ShieldComponent 组件 | 85 | **严重** | Boss护盾 |
| 8 | ElementChangeComponent 组件 | 88 | **严重** | Boss元素 |
| 9 | PhaseManagerComponent 组件 | 91 | **严重** | Boss阶段 |
| 10 | BossUI 初始化 | 77-79 | **严重** | UI显示 |
| 11 | OrderEnermyUI 初始化 | 100-103 | **严重** | UI显示 |

**统计**: 11 项缺失，其中 10 项 **严重** ❌

---

### GD 版本保留内容（仅）

| 保留的方法 | GD 行号 | 功能 | 完整性 |
|-----------|--------|------|--------|
| get_entity_type() | 9-10 | 获取实体类型 | ✅ 完整 |
| _init() | 14-21 | 基础初始化（仅2个组件） | ⚠️ 极度简化 |
| get_hp() | 23-25 | 获取HP | ✅ 完整 |
| set_hp() | 27-30 | 设置HP | ✅ 完整 |
| reduce_hp() | 32-36 | 扣血（无护盾逻辑） | ⚠️ 简化版 |
| is_alive() | 38-39 | 判断是否活着 | ✅ 完整 |
| reduce_step() | 41-43 | 减少攻击步数 | ✅ 完整 |
| is_step_zero() | 45-46 | 步数判定 | ✅ 完整 |

**评价**: 仅保留了最基础的HP和步数管理，核心战斗逻辑全部缺失

---

### 可能影响分析

#### 🔴 游戏流程断裂
- 敌人无法初始化 → 战斗无法开始
- Boss无法加载 → Boss战无法进行
- 伤害无法计算 → 战斗无法进行

#### 🔴 Boss 系统完全失效
- 无技能系统 → Boss无法释放技能
- 无护盾系统 → Boss无法自卫
- 无阶段系统 → Boss无法分阶段战斗
- 无元素系统 → Boss无法变换属性

#### 🔴 UI 无法显示
- 无 BossUI 初始化 → 玩家看不到Boss
- 无 OrderEnermyUI 初始化 → 玩家看不到敌人
- 无伤害事件 → 伤害动画无法播放

#### 🔴 战斗机制失效
- 护盾吸收无法工作 → 伤害计算错误
- 没有护盾完全吸收的判定 → 伤害处理逻辑错误
- 无事件通知 → 游戏状态无法同步

---

### 总体评价

**❌ 最严重的削弱** - OrderEnermyEntity.js

| 指标 | 数值 |
|------|------|
| **代码行数削减** | 191 → 46 (76% 删除) |
| **迁移完整度** | 仅 10% |
| **严重缺失项** | 10 项 |
| **影响程度** | 🔴 游戏无法进行 |

敌人系统是战斗的核心，该文件删除了：
- ✗ 敌人初始化 (无法创建敌人)
- ✗ Boss系统 (无法战斗Boss)
- ✗ 伤害计算 (无法处理伤害)
- ✗ UI系统 (玩家无法看到敌人)

**这是整个迁移中最关键的缺失，直接导致战斗系统无法运作。**

---

## 📋 2️⃣ BaseEventEntity.js 对照报告 (缺失 80%)

### 文件位置
- **JS**: clearRoguelike/base/entity/BaseEventEntity.js (166 行)
- **GD**: gdRoguelike/core/entity/base_event_entity.gd (27 行)
- **迁移完整度**: 仅 20%

---

### 核心差异 - 缺失的生命周期

#### ❌ 1. 事件生命周期框架 (行 24-100)

| 生命周期方法 | JS 行号 | GD 代码 | 状态 | 备注 |
|-----------|--------|--------|------|------|
| **init(meta) 元数据注入** | 24-27 | 无 | ❌ 完全缺失 | 事件配置无法注入 |
| **open() 打开事件** | 32-41 | 无 | ❌ 完全缺失 | 事件UI无法显示 |
| **selectOption() 选项选择** | 48-68 | 无 | ❌ 完全缺失 | 用户选择无法处理 |
| **close() 关闭事件** | 73-77 | 无 | ❌ 完全缺失 | 事件无法关闭 |
| **enterNextLevel() 进入下一关卡** | 83-99 | 无 | ❌ 完全缺失 | 战斗流程无法衔接 |

**关键缺失**: 事件的完整生命周期 (init → open → selectOption → close → enterNextLevel) 全部删除

**可能影响**: 事件系统完全无法工作，玩家无法与事件交互 🔴 **严重**

---

#### ❌ 2. 事件状态管理 (行 16-17)

| 状态管理 | JS 行号 | GD 代码 | 状态 | 备注 |
|---------|--------|--------|------|------|
| **_state 状态机** | 16 | 无 | ❌ 完全缺失 | 无法追踪事件执行阶段 |
| 状态值: init/opened/selected/completed | - | - | ❌ 无 | 状态转移无法进行 |
| **_selectedOption 选项记录** | 17 | 无 | ❌ 完全缺失 | 用户选择无法记录 |

**影响范围**: 无法判断事件当前处于哪个阶段，无法防止重复操作 🔴 **严重**

---

#### ❌ 3. 事件虚方法（回调机制）(行 108-149)

| 虚方法 | JS 行号 | GD 对应 | 参数 | 返回值 | 状态 | 备注 |
|--------|--------|--------|------|--------|------|------|
| **onInit()** | 108-110 | 无 | void | void | ❌ 缺失 | 事件初始化回调 |
| **onOpen()** | 115-117 | 无 | void | void | ❌ 缺失 | 事件打开时回调 |
| **onSelectOption()** | 124-127 | on_option_select | option_id | **bool** → void | ❌ **关键缺失** | 选择处理，**返回值改变** |
| **onComplete()** | 132-134 | 无 | void | void | ❌ 缺失 | 事件完成回调 |
| **onClose()** | 139-141 | 无 | void | void | ❌ 缺失 | 事件关闭回调 |
| **getUIData()** | 147-149 | 无 | void | Object | ❌ 缺失 | UI数据获取 |

**关键差异**: onSelectOption 在GD中变为 on_option_select，且：
- JS 返回 `bool` (成功/失败) → 流程控制
- GD 返回 `void` → 无流程控制

**可能影响**: 事件选择无法验证成功/失败，无法进行条件判断 🔴 **严重**

---

#### ❌ 4. 事件UI交互机制 (行 37-40, 61)

| 交互机制 | JS 行号 | GD 代码 | 状态 | 备注 |
|---------|--------|--------|------|------|
| **event.event.open 事件发送** | 37 | 无 | ❌ 缺失 | UI无法接收打开事件 |
| 事件数据传递 (eventData) | 39 | 无 | ❌ 缺失 | UI无法获取事件配置 |
| **event.event.close 事件发送** | 61 | 无 | ❌ 缺失 | UI无法接收关闭事件 |
| **event.round.newLevelStart 事件** | 94 | 无 | ❌ 缺失 | 新关卡启动通知丢失 |
| **event.update.gameWin 事件** | 97 | 无 | ❌ 缺失 | 游戏胜利通知丢失 |

**影响范围**: EventManager 事件通信完全缺失，UI无法显示 🔴 **严重**

---

#### ❌ 5. 构造参数丢失 (行 11)

| 参数 | JS 代码 | GD 代码 | 状态 | 备注 |
|------|--------|--------|------|------|
| **eventId** | 第1个参数 | 有 (p_event_id) | ✅ 保留 | 事件ID |
| **node (UI节点)** | 第2个参数 | 无 | ❌ **完全删除** | GD无法保存UI节点引用 |

**影响**: 无法保持UI节点的引用，UI操作可能失效 ⚠️ **重要**

---

#### ❌ 6. 访问器缺失 (行 155-165)

| 访问器 | JS 行号 | GD 代码 | 状态 | 备注 |
|--------|--------|--------|------|------|
| **get eventId** | 155-157 | 属性 event_id | ✅ 部分保留 | 保留为属性 |
| **get meta** | 159-161 | 无 | ❌ **缺失** | 无法获取事件配置 |
| **get state** | 163-165 | 无 | ❌ **缺失** | 无法获取当前状态 |

**影响**: 无法访问事件元数据和状态，事件流程控制失效 🔴 **严重**

---

### 缺失内容清单

| 序号 | 缺失内容 | JS 位置 | 重要性 | 影响范围 |
|------|---------|--------|--------|---------|
| 1 | init(meta) 方法 | 24-27 | **严重** | 元数据注入 |
| 2 | open() 方法 | 32-41 | **严重** | UI显示 |
| 3 | selectOption() 方法 | 48-68 | **严重** | 选项处理 |
| 4 | close() 方法 | 73-77 | **严重** | 事件关闭 |
| 5 | enterNextLevel() 方法 | 83-99 | **严重** | 流程衔接 |
| 6 | _state 状态机 | 16 | **严重** | 状态管理 |
| 7 | _selectedOption 记录 | 17 | 中等 | 选项记录 |
| 8 | onInit() 虚方法 | 108-110 | 中等 | 初始化回调 |
| 9 | onOpen() 虚方法 | 115-117 | 中等 | 打开回调 |
| 10 | onSelectOption() 虚方法 | 124-127 | **严重** | 选择回调 (返回值关键) |
| 11 | onComplete() 虚方法 | 132-134 | 中等 | 完成回调 |
| 12 | onClose() 虚方法 | 139-141 | 中等 | 关闭回调 |
| 13 | getUIData() 虚方法 | 147-149 | 中等 | UI数据获取 |
| 14 | node 构造参数 | 11 | 中等 | UI节点引用 |
| 15 | get meta 访问器 | 159-161 | 中等 | 配置访问 |
| 16 | get state 访问器 | 163-165 | 中等 | 状态访问 |
| 17 | EventManager 事件发送 | 37, 61, 94, 97 | **严重** | UI通信 |

**统计**: 17 项缺失，其中 8 项 **严重** ❌

---

### GD 版本保留内容（仅）

| 保留的方法 | GD 行号 | 功能 | 完整性 |
|-----------|--------|------|--------|
| get_entity_type() | 9-10 | 获取实体类型 | ✅ 完整 |
| _init() | 15-20 | 构造初始化 | ⚠️ 简化 |
| on_enter() | 22-24 | 事件进入（新方法） | ✅ 新增 |
| on_option_select() | 26-27 | 选项选择（无返回值） | ⚠️ **关键缺陷** |

**评价**: 仅保留骨架，on_option_select 缺少返回值，导致无法进行流程控制

---

### 关键差异分析

#### 🔴 生命周期框架完全缺失

| 生命周期 | JS 对应 | GD 对应 | 状态 | 后果 |
|---------|--------|--------|------|------|
| **初始化阶段** | init(meta) + onInit() | 无 | ❌ 缺失 | 事件配置无法注入 |
| **打开阶段** | open() + onOpen() | 无 | ❌ 缺失 | UI无法显示 |
| **选择阶段** | selectOption() + onSelectOption() | on_option_select() | ⚠️ **签名改变** | 返回值缺失，无法验证 |
| **完成阶段** | onComplete() | 无 | ❌ 缺失 | 完成回调无法执行 |
| **关闭阶段** | close() + onClose() | 无 | ❌ 缺失 | 资源无法清理 |
| **流程衔接** | enterNextLevel() | 无 | ❌ 缺失 | 战斗无法启动 |

#### 🔴 方法返回值改变带来的影响

```
JS:  onSelectOption(optionId) → boolean
     if (result) { ... 执行后续逻辑 ... }

GD:  on_option_select(option_id) → void
     调用者无法知道是否成功，无法进行条件判断
```

#### 🔴 元数据注入机制缺失

```
JS:  事件 → init(meta) → 获取配置 → getUIData() → 传递给UI
GD:  事件 → _init() → 无法获取配置 → on_enter() → 返回硬编码数据
```

---

### 可能影响分析

#### 🔴 事件系统无法运作
- 事件无法初始化 (缺 init)
- 事件UI无法显示 (缺 open)
- 选项选择无法处理 (缺 selectOption)
- 事件无法关闭 (缺 close)
- 战斗无法启动 (缺 enterNextLevel)

#### 🔴 配置管理失效
- 无法注入事件元数据 (缺 init(meta))
- 无法获取UI数据 (缺 getUIData())
- 所有事件参数必须硬编码

#### 🔴 UI交互完全断裂
- EventManager 事件通信缺失
- UI无法接收打开/关闭事件
- UI无法获取事件数据

#### 🔴 状态管理缺失
- 无法判断事件当前阶段
- 无法防止重复操作
- 用户选择无法记录

---

### 总体评价

**❌ 系统级缺失 - BaseEventEntity.js**

| 指标 | 数值 |
|------|------|
| **代码行数削减** | 166 → 27 (84% 删除) |
| **迁移完整度** | 仅 20% |
| **严重缺失项** | 8 项 |
| **影响程度** | 🔴 事件系统完全无法工作 |

该文件删除了：
- ✗ 事件生命周期 (init → open → selectOption → close)
- ✗ 状态管理 (_state 状态机)
- ✗ 虚方法回调 (5个虚方法)
- ✗ UI交互 (EventManager 通信)
- ✗ 流程衔接 (enterNextLevel)

**这是事件系统的基类，其生命周期缺失直接导致所有继承的事件类无法运作。**

---

## 📋 3️⃣ BaseRestEntity.js 对照报告 (缺失 85%)

### 文件位置
- **JS**: clearRoguelike/base/entity/BaseRestEntity.js (178 行)
- **GD**: gdRoguelike/core/entity/base_rest_entity.gd (31 行)
- **迁移完整度**: 仅 15%

---

### 核心差异 - 缺失的生命周期

#### ❌ 1. 休息点生命周期框架 (行 23-105)

| 生命周期方法 | JS 行号 | GD 代码 | 状态 | 备注 |
|-----------|--------|--------|------|------|
| **init(meta) 元数据注入** | 23-26 | 无 | ❌ 完全缺失 | 休息配置无法注入 |
| **open() 打开休息点** | 31-40 | 无 | ❌ 完全缺失 | 休息UI无法显示 |
| **confirm() 确认使用** | 46-65 | 无 | ❌ 完全缺失 | 休息功能无法执行 |
| **skip() 跳过休息** | 70-74 | 无 | ❌ 完全缺失 | 跳过功能无法执行 |
| **close() 关闭休息** | 79-83 | 无 | ❌ 完全缺失 | 休息无法关闭 |
| **enterNextLevel() 进入下一关卡** | 89-105 | 无 | ❌ 完全缺失 | 战斗流程无法衔接 |

**关键缺失**: 休息点的完整生命周期 (init → open → confirm/skip → close → enterNextLevel) 全部删除

**可能影响**: 休息系统完全无法工作，玩家无法使用休息点 🔴 **严重**

---

#### ❌ 2. 休息状态管理 (行 16)

| 状态管理 | JS 行号 | GD 代码 | 状态 | 备注 |
|---------|--------|--------|------|------|
| **_state 状态机** | 16 | 无 | ❌ 完全缺失 | 无法追踪休息执行阶段 |
| 状态值: init/opened/completed | - | - | ❌ 无 | 状态转移无法进行 |

**影响范围**: 无法判断休息点当前处于哪个阶段，无法防止重复操作 🔴 **严重**

---

#### ❌ 3. 休息虚方法（回调机制）(行 114-153)

| 虚方法 | JS 行号 | GD 对应 | 参数 | 返回值 | 状态 | 备注 |
|--------|--------|--------|------|--------|------|------|
| **onInit()** | 114-116 | 无 | void | void | ❌ 缺失 | 休息初始化回调 |
| **onOpen()** | 121-123 | 无 | void | void | ❌ 缺失 | 休息打开时回调 |
| **onConfirm()** | 129-132 | on_confirm | void | **bool** → void | ❌ **关键缺失** | 确认处理，**返回值改变** |
| **onSkip()** | 137-139 | on_skip | void | void | ✅ 保留 | 跳过回调 |
| **onComplete()** | 144-146 | 无 | void | void | ❌ 缺失 | 休息完成回调 |
| **onClose()** | 151-153 | 无 | void | void | ❌ 缺失 | 休息关闭回调 |
| **getUIData()** | 159-161 | 无 | void | Object | ❌ 缺失 | UI数据获取 |

**关键差异**: onConfirm 在GD中变为 on_confirm，且：
- JS 返回 `bool` (成功/失败) → 流程控制
- GD 返回 `void` → 无流程控制

**可能影响**: 休息确认无法验证成功/失败，无法进行条件判断 🔴 **严重**

---

#### ❌ 4. 休息UI交互机制 (行 36, 58, 71, 80)

| 交互机制 | JS 行号 | GD 代码 | 状态 | 备注 |
|---------|--------|--------|------|------|
| **event.rest.open 事件发送** | 36 | 无 | ❌ 缺失 | UI无法接收打开事件 |
| 事件数据传递 (restData) | 38 | 无 | ❌ 缺失 | UI无法获取休息配置 |
| **event.rest.close 事件发送** | 58, 71, 80 | 无 | ❌ 缺失 | UI无法接收关闭事件 |
| **event.round.newLevelStart 事件** | 100 | 无 | ❌ 缺失 | 新关卡启动通知丢失 |
| **event.update.gameWin 事件** | 103 | 无 | ❌ 缺失 | 游戏胜利通知丢失 |

**影响范围**: EventManager 事件通信完全缺失，UI无法显示 🔴 **严重**

---

#### ❌ 5. 构造参数丢失 (行 11)

| 参数 | JS 代码 | GD 代码 | 状态 | 备注 |
|------|--------|--------|------|------|
| **restId** | 第1个参数 | 有 (p_rest_id) | ✅ 保留 | 休息ID |
| **node (UI节点)** | 第2个参数 | 无 | ❌ **完全删除** | GD无法保存UI节点引用 |

**影响**: 无法保持UI节点的引用，UI操作可能失效 ⚠️ **重要**

---

#### ❌ 6. 访问器缺失 (行 167-177)

| 访问器 | JS 行号 | GD 代码 | 状态 | 备注 |
|--------|--------|--------|------|------|
| **get restId** | 167-169 | 属性 rest_id | ✅ 部分保留 | 保留为属性 |
| **get meta** | 171-173 | 无 | ❌ **缺失** | 无法获取休息配置 |
| **get state** | 175-177 | 无 | ❌ **缺失** | 无法获取当前状态 |

**影响**: 无法访问休息元数据和状态，休息流程控制失效 🔴 **严重**

---

### 缺失内容清单

| 序号 | 缺失内容 | JS 位置 | 重要性 | 影响范围 |
|------|---------|--------|--------|---------|
| 1 | init(meta) 方法 | 23-26 | **严重** | 元数据注入 |
| 2 | open() 方法 | 31-40 | **严重** | UI显示 |
| 3 | confirm() 方法 | 46-65 | **严重** | 确认处理 |
| 4 | skip() 方法 | 70-74 | **严重** | 跳过处理 |
| 5 | close() 方法 | 79-83 | **严重** | 休息关闭 |
| 6 | enterNextLevel() 方法 | 89-105 | **严重** | 流程衔接 |
| 7 | _state 状态机 | 16 | **严重** | 状态管理 |
| 8 | onInit() 虚方法 | 114-116 | 中等 | 初始化回调 |
| 9 | onOpen() 虚方法 | 121-123 | 中等 | 打开回调 |
| 10 | onConfirm() 虚方法 | 129-132 | **严重** | 确认回调 (返回值关键) |
| 11 | onComplete() 虚方法 | 144-146 | 中等 | 完成回调 |
| 12 | onClose() 虚方法 | 151-153 | 中等 | 关闭回调 |
| 13 | getUIData() 虚方法 | 159-161 | 中等 | UI数据获取 |
| 14 | node 构造参数 | 11 | 中等 | UI节点引用 |
| 15 | get meta 访问器 | 171-173 | 中等 | 配置访问 |
| 16 | get state 访问器 | 175-177 | 中等 | 状态访问 |
| 17 | EventManager 事件发送 | 36, 58, 71, 80, 100, 103 | **严重** | UI通信 |

**统计**: 17 项缺失，其中 9 项 **严重** ❌

---

### GD 版本保留内容（仅）

| 保留的方法 | GD 行号 | 功能 | 完整性 |
|-----------|--------|------|--------|
| get_entity_type() | 9-10 | 获取实体类型 | ✅ 完整 |
| _init() | 15-20 | 构造初始化 | ⚠️ 简化 |
| on_enter() | 22-23 | 休息进入（新方法） | ✅ 新增 |
| on_confirm() | 25-27 | 确认休息（无返回值） | ⚠️ **关键缺陷** |
| on_skip() | 29-31 | 跳过休息 | ✅ 保留 |

**评价**: 仅保留骨架，on_confirm 缺少返回值，导致无法进行流程控制

---

### 对比分析：BaseEventEntity vs BaseRestEntity

两个基类的缺失情况几乎**完全一致**：

| 方面 | BaseEventEntity | BaseRestEntity | 共同点 |
|------|-----------------|----------------|--------|
| 生命周期缺失 | init, open, selectOption, close, enterNextLevel | init, open, confirm, skip, close, enterNextLevel | 都缺少完整生命周期 |
| 状态管理缺失 | _state 状态机 | _state 状态机 | 都无法追踪状态 |
| 虚方法缺失数 | 5 个 (onInit, onOpen, onSelectOption, onComplete, onClose) | 5 个 (onInit, onOpen, onConfirm, onComplete, onClose) | 都缺少核心回调 |
| 返回值改变 | onSelectOption: bool → void | onConfirm: bool → void | 都失去返回值控制 |
| UI交互缺失 | event.event.* 事件 | event.rest.* 事件 | 都无法与UI通信 |
| 访问器缺失 | get meta, get state | get meta, get state | 都无法访问配置和状态 |
| 迁移完整度 | 20% | 15% | 都是极度简化 |
| 代码删除率 | 84% | 82% | 都删除了80%以上代码 |

**结论**: BaseRestEntity.js 的缺失模式与 BaseEventEntity.js **几乎完全相同**，都是系统级别的生命周期缺失。

---

### 关键差异分析

#### 🔴 生命周期框架完全缺失

| 阶段 | JS 对应 | GD 对应 | 状态 | 后果 |
|------|--------|--------|------|------|
| **初始化阶段** | init(meta) + onInit() | 无 | ❌ 缺失 | 休息配置无法注入 |
| **打开阶段** | open() + onOpen() | 无 | ❌ 缺失 | 休息UI无法显示 |
| **确认/跳过阶段** | confirm() + onConfirm() / skip() + onSkip() | on_confirm() / on_skip() | ⚠️ **部分缺失** | 返回值缺失，无法验证 |
| **完成阶段** | onComplete() | 无 | ❌ 缺失 | 完成回调无法执行 |
| **关闭阶段** | close() + onClose() | 无 | ❌ 缺失 | 资源无法清理 |
| **流程衔接** | enterNextLevel() | 无 | ❌ 缺失 | 战斗无法启动 |

#### 🔴 方法返回值改变带来的影响

```
JS:  onConfirm() → boolean
     if (result) { ... 执行后续逻辑 ... }

GD:  on_confirm() → void
     调用者无法知道是否成功，无法进行条件判断
```

#### 🔴 元数据注入机制缺失

```
JS:  休息点 → init(meta) → 获取配置 → getUIData() → 传递给UI
GD:  休息点 → _init() → 无法获取配置 → on_enter() → 返回硬编码数据
```

---

### 可能影响分析

#### 🔴 休息系统无法运作
- 休息点无法初始化 (缺 init)
- 休息UI无法显示 (缺 open)
- 确认操作无法处理 (缺 confirm)
- 跳过操作无返回值 (缺 返回bool)
- 休息无法关闭 (缺 close)
- 战斗无法启动 (缺 enterNextLevel)

#### 🔴 配置管理失效
- 无法注入休息元数据 (缺 init(meta))
- 无法获取UI数据 (缺 getUIData())
- 所有休息参数必须硬编码

#### 🔴 UI交互完全断裂
- EventManager 事件通信缺失
- UI无法接收打开/关闭事件
- UI无法获取休息数据

#### 🔴 状态管理缺失
- 无法判断休息点当前阶段
- 无法防止重复操作
- 用户操作选择无法记录

---

### 总体评价

**❌ 系统级缺失 - BaseRestEntity.js**

| 指标 | 数值 |
|------|------|
| **代码行数削减** | 178 → 31 (83% 删除) |
| **迁移完整度** | 仅 15% |
| **严重缺失项** | 9 项 |
| **影响程度** | 🔴 休息系统完全无法工作 |

该文件删除了：
- ✗ 休息生命周期 (init → open → confirm/skip → close)
- ✗ 状态管理 (_state 状态机)
- ✗ 虚方法回调 (4个虚方法)
- ✗ UI交互 (EventManager 通信)
- ✗ 流程衔接 (enterNextLevel)

**与 BaseEventEntity.js 的地位相同，都是基类，其生命周期缺失直接导致所有继承的休息类无法运作。**

---

### 与 BaseEventEntity.js 的对比

两个基类的缺失程度**几乎相同**：

```
缺失项目数：BaseEventEntity (17) ≈ BaseRestEntity (17)
严重缺失数：BaseEventEntity (8) ≈ BaseRestEntity (9)
删除比例：BaseEventEntity (84%) ≈ BaseRestEntity (83%)
迁移完整度：BaseEventEntity (20%) ≈ BaseRestEntity (15%)
```

这表明 GD 版本对**两个基类的处理方式完全相同**，都是极度简化为骨架。

---

## 📋 4️⃣ ElementEntity.js 对照报告 (缺失 70%)

### 文件位置
- **JS**: clearRoguelike/base/entity/ElementEntity.js (223 行)
- **GD**: gdRoguelike/core/entity/element_entity.gd (44 行)
- **迁移完整度**: 仅 30%

---

### 核心差异 - 缺失的交互逻辑

#### ❌ 1. 完整的 init(data) 方法部分删除 (行 43-71)

| 功能 | JS 行号 | GD 代码 | 状态 | 备注 |
|------|--------|--------|------|------|
| **init(data) 方法** | 43-71 | 部分保留 | ⚠️ **部分缺失** | GD版本被截断了 |
| 数据组件初始化 | 44-46 | 有 | ✅ 保留 | 数据初始化 |
| BuffId 初始化 | 49-57 | 有 (简化) | ⚠️ **简化版** | GD无法调用 fromJSON() |
| **Buff 从JSON恢复** | 62-65 | **无** | ❌ **完全缺失** | 无法恢复战斗中的临时Buff |
| UI初始化 | 67-70 | **无** | ❌ **完全缺失** | UI初始化代码被删除 |

**关键发现**: GD版本的init()在第44行就截断了，缺少后续的Buff恢复和UI初始化

**可能影响**: 存档中的临时Buff无法恢复，UI交互无法初始化 ⚠️ **重要**

---

#### ❌ 2. 拖拽交互系统完全删除 (行 73-89)

| 功能 | JS 行号 | GD 代码 | 状态 | 备注 |
|------|--------|--------|------|------|
| **onDropCompleteHandler() 方法** | 73-89 | 无 | ❌ **完全删除** | 拖拽处理无法工作 |
| 相同实体检测 | 74-75 | 无 | ❌ 缺失 | 无法判断拖拽对象 |
| 特殊区域拖拽检查 | 81 | 无 | ❌ 缺失 | 棋盘↔子弹区域交互 |
| 元素合成判定 | 84 | 无 | ❌ 缺失 | 无法触发合成逻辑 |
| 数据交换调用 | 87 | 无 | ❌ 缺失 | 元素位置无法交换 |

**影响范围**: 棋盘拖拽机制完全失效，玩家无法操作棋子 🔴 **严重**

---

#### ❌ 3. 特殊区域拖拽逻辑删除 (行 91-139)

| 功能 | JS 行号 | GD 代码 | 状态 | 备注 |
|------|--------|--------|------|------|
| **_handleDropToShotArea() 方法** | 91-139 | 无 | ❌ **完全删除** | 棋盘↔子弹交互失效 |
| 空位置接收元素 | 105-110 | 无 | ❌ 缺失 | 无法将元素放入空位 |
| 位置交换逻辑 | 112-122 | 无 | ❌ 缺失 | 无法交换元素 |
| 元素移动逻辑 | 123-131 | 无 | ❌ 缺失 | 无法移动元素 |
| 步数更新 | 133 | 无 | ❌ 缺失 | 游戏进度无法记录 |

**影响范围**: 棋盘和子弹区域之间的交互完全失效 🔴 **严重**

---

#### ❌ 4. 点击交互系统完全删除 (行 141-153)

| 功能 | JS 行号 | GD 代码 | 状态 | 备注 |
|------|--------|--------|------|------|
| **onClickHandler() 方法** | 141-153 | 无 | ❌ **完全删除** | 点击事件无法处理 |
| 数据检查 | 143-144 | 无 | ❌ 缺失 | 无法验证元素有效性 |
| 发射器判定 | 145-147 | 无 | ❌ 缺失 | 无法区分区域 |
| 发射器点击处理 | 149 | 无 | ❌ 缺失 | 发射器点击无法工作 |

**影响范围**: 点击事件完全无法处理，玩家无法点击激活发射器 🔴 **严重**

---

#### ❌ 5. 发射器点击生成元素逻辑删除 (行 163-174)

| 功能 | JS 行号 | GD 代码 | 状态 | 备注 |
|------|--------|--------|------|------|
| **_clickLauncher() 方法** | 163-174 | 无 | ❌ **完全删除** | 发射器无法生成元素 |
| 元素类型判定 | 166 | 无 | ❌ 缺失 | 无法判断是否为发射器 |
| 新元素创建 | 167 | 无 | ❌ 缺失 | 无法创建新元素 |
| 空位查找 | 169 | 无 | ❌ 缺失 | 无法找到放置位置 |
| 元素初始化 | 171 | 无 | ❌ 缺失 | 新元素无法初始化 |

**影响范围**: 发射器机制完全无法工作，玩家无法生成棋子 🔴 **严重**

---

#### ❌ 6. 辅助判定方法删除 (行 176-184)

| 功能 | JS 行号 | GD 代码 | 状态 | 备注 |
|------|--------|--------|------|------|
| **_isSameEntity() 方法** | 176-184 | 无 | ❌ 完全缺失 | 无法判断相同实体 |
| 坐标比较 | 177-182 | 无 | ❌ 缺失 | 无法验证实体同一性 |

**影响范围**: 无法防止自我拖拽，可能导致逻辑错误 ⚠️ **重要**

---

#### ❌ 7. 数据交换逻辑删除 (行 187-195)

| 功能 | JS 行号 | GD 代码 | 状态 | 备注 |
|------|--------|--------|------|------|
| **_swapEntityData() 方法** | 187-195 | 无 | ❌ **完全删除** | 元素交换失效 |
| 数据临时存储 | 188-191 | 无 | ❌ 缺失 | 无法实现交换逻辑 |
| 数据互换 | 192-193 | 无 | ❌ 缺失 | 元素无法交换位置 |

**影响范围**: 棋盘位置交换机制完全失效 🔴 **严重**

---

#### ❌ 8. 元素合成逻辑删除 (行 197-210)

| 功能 | JS 行号 | GD 代码 | 状态 | 备注 |
|------|--------|--------|------|------|
| **_mergeEntityData() 方法** | 197-210 | 无 | ❌ **完全删除** | 元素合成失效 |
| 源元素清除 | 198 | 无 | ❌ 缺失 | 无法清除合成源 |
| 合成输出计算 | 200 | 无 | ❌ 缺失 | 无法计算合成结果 |
| 目标更新 | 202 | 无 | ❌ 缺失 | 合成结果无法显示 |
| 步数更新 | 205 | 无 | ❌ 缺失 | 游戏进度无法记录 |

**影响范围**: 元素合成系统完全失效，玩法核心机制无法工作 🔴 **严重**

---

#### ❌ 9. 数据更新方法删除 (行 212-215)

| 功能 | JS 行号 | GD 代码 | 状态 | 备注 |
|------|--------|--------|------|------|
| **_updateData() 方法** | 212-215 | 无 | ❌ 完全缺失 | 数据更新无法工作 |

**影响范围**: 所有数据更新操作无法进行 ⚠️ **重要**

---

#### ❌ 10. 资源清理逻辑删除 (行 217-222)

| 功能 | JS 行号 | GD 代码 | 状态 | 备注 |
|------|--------|--------|------|------|
| **dispose() 析构方法** | 217-222 | 无 | ❌ 完全缺失 | UI销毁逻辑缺失 |
| UI销毁动画 | 220 | 无 | ❌ 缺失 | 元素无法播放销毁动画 |

**影响范围**: 资源泄漏风险，UI销毁不完整 ⚠️ **重要**

---

#### ❌ 11. WorldDataManager 集成完全缺失

| 调用点 | JS 行号 | GD 代码 | 状态 | 用途 |
|--------|--------|--------|------|------|
| 合成检查 | 84 | 无 | ❌ 缺失 | canElementMerge() |
| 步数更新 | 133, 205 | 无 | ❌ 缺失 | updateStep() |
| 合成输出 | 200 | 无 | ❌ 缺失 | getElementMergeOutputData() |
| 新元素创建 | 167 | 无 | ❌ 缺失 | createElementData() |
| 空位查找 | 169 | 无 | ❌ 缺失 | getEmptyElementEntity() |

**影响范围**: 与游戏数据管理器的集成完全缺失，所有游戏逻辑无法驱动 🔴 **严重**

---

### 缺失内容清单

| 序号 | 缺失内容 | JS 位置 | 重要性 | 游戏影响 |
|------|---------|--------|--------|---------|
| 1 | init() 后续部分 | 62-70 | 中等 | Buff恢复失效 |
| 2 | onDropCompleteHandler() | 73-89 | **严重** | 拖拽机制失效 |
| 3 | _handleDropToShotArea() | 91-139 | **严重** | 棋盘↔子弹交互失效 |
| 4 | onClickHandler() | 141-153 | **严重** | 点击机制失效 |
| 5 | _getAreaId() | 155-161 | 中等 | 区域识别失效 |
| 6 | _clickLauncher() | 163-174 | **严重** | 发射器失效 |
| 7 | _isSameEntity() | 176-184 | 中等 | 同一性检查失效 |
| 8 | _swapEntityData() | 187-195 | **严重** | 交换机制失效 |
| 9 | _mergeEntityData() | 197-210 | **严重** | 合成机制失效 |
| 10 | _updateData() | 212-215 | 中等 | 数据更新失效 |
| 11 | dispose() | 217-222 | 中等 | 资源清理失效 |
| 12 | WorldDataManager 集成 | 全文 | **严重** | 游戏逻辑驱动失效 |

**统计**: 12 项缺失，其中 6 项 **严重** ❌

---

### GD 版本保留内容（仅）

| 保留的方法 | GD 行号 | 功能 | 完整性 |
|-----------|--------|------|--------|
| get_entity_type() | 9-10 | 获取实体类型 | ✅ 完整 |
| _init() | 12-26 | 坐标初始化 + 组件创建 | ✅ 保留 |
| init(data) | 28-44 | 数据初始化 | ⚠️ **部分保留** |
| └─ 数据初始化 | 29-31 | DataComponent初始化 | ✅ 保留 |
| └─ BuffId初始化 | 32-43 | Buff初始化 | ⚠️ 简化版 |
| └─ **后续部分截断** | (缺) | Buff恢复、UI初始化 | ❌ 缺失 |

**评价**: 仅保留了基础初始化，删除了所有交互逻辑和UI初始化

---

### 核心游戏机制缺失

#### 🔴 棋盘拖拽系统（游戏核心玩法）

```
JS: 玩家拖拽元素 → onDropCompleteHandler()
    → 判断是否合成 / 交换 / 特殊区域
    → 调用 _mergeEntityData() / _swapEntityData() / _handleDropToShotArea()
    → 更新游戏状态

GD: 拖拽事件无法响应 → 无法进行任何操作
```

**影响**: 棋盘操作完全无法进行

#### 🔴 元素合成系统（游戏核心玩法）

```
JS: 拖拽触发 → canElementMerge() 判定
    → _mergeEntityData() 执行合成
    → getElementMergeOutputData() 获取结果
    → updateStep() 更新进度

GD: 无 _mergeEntityData() → 合成无法执行
```

**影响**: 无法进行元素合成

#### 🔴 发射器生成系统（游戏核心玩法）

```
JS: 点击发射器 → onClickHandler() 判定
    → _clickLauncher() 执行
    → createElementData() 创建元素
    → getEmptyElementEntity() 找空位
    → 新元素初始化

GD: 无 onClickHandler() → 点击无法响应
    无 _clickLauncher() → 发射器无法工作
```

**影响**: 发射器完全无法使用

#### 🔴 棋盘交换系统（游戏玩法）

```
JS: 拖拽触发 → _swapEntityData() 交换位置
    
GD: 无 _swapEntityData() → 无法交换
```

**影响**: 不同区域元素无法互换

---

### 可能影响分析

#### 🔴 主要游戏玩法完全失效
1. **棋盘拖拽** - 无 onDropCompleteHandler()
2. **元素合成** - 无 _mergeEntityData()
3. **发射器** - 无 _clickLauncher()
4. **棋盘交换** - 无 _swapEntityData()

#### 🔴 UI交互完全断裂
- 无拖拽事件处理
- 无点击事件处理
- UI销毁逻辑缺失

#### 🔴 游戏数据管理断裂
- 无 WorldDataManager 集成
- 无法检查合成条件
- 无法更新游戏步数
- 无法创建新元素

#### 🔴 存档恢复失效
- 无 fromJSON() 调用
- 战斗中的临时Buff无法恢复

---

### 总体评价

**❌ 严重削弱 - ElementEntity.js**

| 指标 | 数值 |
|------|------|
| **代码行数削减** | 223 → 44 (80% 删除) |
| **迁移完整度** | 仅 30% |
| **严重缺失项** | 6 项 |
| **游戏影响** | 🔴 核心玩法失效 |

该文件删除了：
- ✗ 拖拽交互系统 (所有拖拽逻辑)
- ✗ 点击交互系统 (所有点击逻辑)
- ✗ 元素合成系统 (完全无法合成)
- ✗ 发射器系统 (完全无法生成元素)
- ✗ 棋盘交换系统 (无法交换元素)
- ✗ WorldDataManager 集成 (游戏状态无法驱动)

**ElementEntity 控制了棋盘的所有玩法逻辑，删除这些方法意味着玩家无法与棋盘进行任何交互。**

---

## 📋 5️⃣ OrderSelfEntity.js 对照报告 (缺失 75%)

### 文件位置
- **JS**: clearRoguelike/base/entity/OrderSelfEntity.js (99 行)
- **GD**: gdRoguelike/core/entity/order_self_entity.gd (35 行)
- **迁移完整度**: 仅 25%

---

### 核心差异 - 缺失的初始化和交互

#### ❌ 1. 完整的 init(data) 方法完全删除 (行 45-76)

| 功能 | JS 行号 | GD 代码 | 状态 | 备注 |
|------|--------|--------|------|------|
| **init(data) 整个方法** | 45-76 | 无 | ❌ **完全删除** | 角色数据无法初始化 |
| 数据组件初始化 | 46-48 | 无 | ❌ 缺失 | 角色属性无法加载 |
| **BuffId 配置初始化** | 50-65 | **无** | ❌ **完全缺失** | 角色固有Buff无法应用 |
| Buff 从JSON恢复 | 68-70 | **无** | ❌ **完全缺失** | 战斗中的临时Buff无法恢复 |
| UI初始化 | 72-75 | **无** | ❌ **完全缺失** | 角色UI无法显示 |

**关键影响**: 角色完全无法初始化，无法加载任何数据

**可能影响**: 角色系统完全无法工作，战斗无法进行 🔴 **严重**

---

#### ❌ 2. 角色属性初始化缺失 (行 50-65)

| 功能 | JS 行号 | GD 代码 | 状态 | 备注 |
|------|--------|--------|------|------|
| **BuffId 初始化逻辑** | 50-65 | 无 | ❌ **完全缺失** | 角色属性系统失效 |
| MetaConsts.resolveBuff() 调用 | 54 | 无 | ❌ 缺失 | 无法获取Buff配置 |
| 角色Buff添加 | 56-63 | 无 | ❌ 缺失 | 角色属性无法应用 |
| 永久Buff标记 | 59 | 无 | ❌ 缺失 | 属性持久化无法标记 |
| Buff详细信息 | 60-62 | 无 | ❌ 缺失 | Buff元数据无法加载 |

**影响范围**: 角色无法获得固有属性加成

**示例**: 如果角色有 buffId="atk_plus_5"，该Buff将无法应用到角色

---

#### ❌ 3. 临时Buff恢复缺失 (行 68-70)

| 功能 | JS 行号 | GD 代码 | 状态 | 备注 |
|------|--------|--------|------|------|
| **fromJSON() 调用** | 69 | 无 | ❌ **完全缺失** | 存档恢复失效 |
| 存档Buff数据恢复 | - | 无 | ❌ 缺失 | 无法恢复战斗中的临时状态 |

**影响范围**: 无法从存档恢复角色的战斗状态

**可能场景**: 存档时有临时Buff，读档后Buff丢失

---

#### ❌ 4. 角色UI初始化完全删除 (行 72-75)

| 功能 | JS 行号 | GD 代码 | 状态 | 备注 |
|------|--------|--------|------|------|
| **UI 初始化** | 72-75 | 无 | ❌ **完全缺失** | UI无法显示 |
| UIComponent 初始化 | 72 | 无 | ❌ 缺失 | UI组件无法创建 |
| OrderSelfUI 创建 | 73 | 无 | ❌ 缺失 | 角色UI无法显示 |
| UI.init() 调用 | 74 | 无 | ❌ 缺失 | UI初始化逻辑无法执行 |

**影响范围**: 玩家无法看到己方角色

---

#### ❌ 5. 点击交互系统完全删除 (行 78-91)

| 功能 | JS 行号 | GD 代码 | 状态 | 备注 |
|------|--------|--------|------|------|
| **onClickHandler() 方法** | 78-80 | 无 | ❌ **完全删除** | 点击事件无法处理 |
| **_clickEntityData() 方法** | 82-91 | 无 | ❌ **完全删除** | 角色选择逻辑无法执行 |
| 角色选择标记 | 86 | 无 | ❌ 缺失 | 无法标记选中的攻击者 |
| 步数更新 | 88 | 无 | ❌ 缺失 | 游戏进度无法记录 |
| 战斗阶段启动 | 89 | 无 | ❌ 缺失 | 战斗流程无法启动 |

**关键影响**: 玩家无法选择角色进行攻击

**游戏流程**: 点击角色 → 标记为攻击者 → 启动战斗阶段 （全部缺失）

**可能影响**: 战斗流程无法启动，玩家无法操作 🔴 **严重**

---

#### ❌ 6. 资源清理逻辑删除 (行 93-98)

| 功能 | JS 行号 | GD 代码 | 状态 | 备注 |
|------|--------|--------|------|------|
| **dispose() 析构方法** | 93-98 | 无 | ❌ 完全缺失 | 资源清理无法工作 |
| UI销毁动画 | 96 | 无 | ❌ 缺失 | UI销毁不完整 |

**影响范围**: 资源泄漏风险，内存占用增加 ⚠️ **重要**

---

#### ❌ 7. WorldDataManager 集成完全缺失

| 调用点 | JS 行号 | GD 代码 | 状态 | 用途 |
|--------|--------|--------|------|------|
| 步数更新 | 88 | 无 | ❌ 缺失 | updateStep() |
| 战斗阶段启动 | 89 | 无 | ❌ 缺失 | addStage(StageSelfBattle) |

**影响范围**: 与游戏管理器的集成完全缺失

---

### GD 版本保留内容

| 保留的方法 | GD 行号 | 功能 | 完整性 |
|-----------|--------|------|--------|
| get_entity_type() | 9-10 | 获取实体类型 | ✅ 完整 |
| _init() | 12-14 | 数据初始化 | ⚠️ **极度简化** |
| get_hp() | 19-21 | 获取HP | ✅ 完整 |
| set_hp() | 23-26 | 设置HP | ✅ 完整 |
| reduce_hp() | 28-32 | 扣血 | ✅ 完整 |
| is_alive() | 34-35 | 判断活着 | ✅ 完整 |

**评价**: 仅保留了HP管理工具方法，删除了所有初始化、属性、和交互逻辑

---

### 缺失内容清单

| 序号 | 缺失内容 | JS 位置 | 重要性 | 影响范围 |
|------|---------|--------|--------|---------|
| 1 | init(data) 整个方法 | 45-76 | **严重** | 角色初始化 |
| 2 | 数据组件初始化 | 46-48 | **严重** | 角色数据 |
| 3 | BuffId 属性初始化 | 50-65 | **严重** | 角色属性 |
| 4 | Buff 从JSON恢复 | 68-70 | **严重** | 存档恢复 |
| 5 | UI 初始化 | 72-75 | **严重** | UI显示 |
| 6 | onClickHandler() | 78-80 | **严重** | 点击事件 |
| 7 | _clickEntityData() | 82-91 | **严重** | 角色选择 |
| 8 | dispose() | 93-98 | 中等 | 资源清理 |
| 9 | WorldDataManager 集成 | 全文 | **严重** | 游戏流程 |

**统计**: 9 项缺失，其中 8 项 **严重** ❌

---

### 核心游戏机制缺失

#### 🔴 角色初始化系统（战斗前置）

```
JS: 创建角色 → init(data)
    → 初始化数据 → 加载Buff → 恢复存档状态 → 显示UI
    → 战斗开始

GD: 创建角色 → _init() (仅创建组件)
    → 无数据初始化 → 无UI显示 → 无法进行战斗
```

**影响**: 角色完全无法初始化

#### 🔴 角色属性系统（战斗核心）

```
JS: 角色配置 → BuffId="warrior_buff"
    → MetaConsts.resolveBuff() 获取配置
    → addBuff() 应用属性
    → 角色获得属性加成

GD: 无法加载 BuffId → 角色无属性 → 战斗数据错误
```

**影响**: 角色无法获得属性加成

#### 🔴 角色选择系统（战斗启动）

```
JS: 玩家点击角色 → onClickHandler()
    → _clickEntityData() 处理
    → 标记为攻击者 → updateStep() → addStage()
    → 启动战斗阶段

GD: 点击事件无法响应 → 无法选择角色 → 战斗无法启动
```

**影响**: 玩家无法操作战斗

#### 🔴 存档恢复系统（进度保存）

```
JS: 读取存档 → init(data)
    → fromJSON() 恢复临时Buff
    → 战斗状态完整恢复

GD: 无 fromJSON() → 临时Buff丢失 → 存档状态不一致
```

**影响**: 无法正确恢复战斗状态

---

### 可能影响分析

#### 🔴 战斗系统无法启动
1. **角色无法初始化** - 缺 init(data)
2. **角色属性无法加载** - 缺 BuffId初始化
3. **玩家无法选择** - 缺 onClickHandler()
4. **战斗阶段无法启动** - 缺 addStage()

#### 🔴 角色属性管理失效
- 无法加载固有属性 (Buff)
- 角色数据不完整
- 战斗计算数据错误

#### 🔴 UI显示失效
- 无角色UI显示
- 玩家看不到角色信息
- 无法进行视觉交互

#### 🔴 存档恢复失效
- 临时Buff丢失
- 战斗中的状态无法保存
- 读档后状态不一致

#### 🔴 游戏流程中断
- 无法从角色选择进入战斗
- 战斗系统完全无法启动

---

### 与 OrderEnermyEntity 的对比

| 方面 | OrderSelfEntity | OrderEnermyEntity | 共同点 |
|------|-----------------|-------------------|--------|
| init() 缺失 | ✗ 完全缺失 | ✗ 完全缺失 | 都无法初始化 |
| 数据加载 | ✗ 缺失 | ✗ 缺失 | 都无法加载数据 |
| 属性/BuffId | ✗ 缺失 | ✗ 缺失 | 都无法加载属性 |
| UI初始化 | ✗ 缺失 | ✗ 缺失 | 都无法显示UI |
| 删除比例 | 75% | 76% | 几乎相同 |
| 迁移完整度 | 25% | 10% | 都是极度简化 |
| 影响程度 | 战斗启动失效 | 战斗执行失效 | 都导致战斗系统失效 |

**结论**: 两个单位类的缺失模式**几乎完全相同**，都是完全删除了init()方法。

---

### 总体评价

**❌ 严重削弱 - OrderSelfEntity.js**

| 指标 | 数值 |
|------|------|
| **代码行数削减** | 99 → 35 (65% 删除) |
| **迁移完整度** | 仅 25% |
| **严重缺失项** | 8 项 |
| **游戏影响** | 🔴 战斗启动失效 |

该文件删除了：
- ✗ init(data) 初始化方法 (完全无法初始化)
- ✗ BuffId 属性加载 (无法获得属性)
- ✗ 存档Buff恢复 (无法恢复状态)
- ✗ UI 初始化 (无法显示)
- ✗ 点击交互 (无法选择角色)
- ✗ 战斗启动逻辑 (无法启动战斗)

**OrderSelfEntity 是己方战斗单位，删除这些方法意味着整个己方战斗系统无法工作。**

---

## 📋 6️⃣ ShopEntity.js 对照报告 (缺失 50%)

### 文件位置
- **JS**: clearRoguelike/base/entity/ShopEntity.js (28 行)
- **GD**: gdRoguelike/core/entity/shop_entity.gd (17 行)
- **迁移完整度**: 仅 50%

---

### 核心差异 - 缺失的初始化和资源管理

#### ❌ 1. 构造参数改变 (行 6-14)

| 参数 | JS 代码 | GD 代码 | 状态 | 备注 |
|------|--------|--------|------|------|
| **shopId** | 第1个参数 | 无此参数 | ⚠️ **改变** | GD从data中获取 |
| **uiItem** | 第2个参数 | 无 | ❌ **完全删除** | 无法保存UI引用 |
| **data** (新) | 无 | 新增第1个参数 | ✅ **新增** | GD传入完整数据 |

**影响**: 
- JS 版本通过构造参数保存 uiItem 引用
- GD 版本无法保存 uiItem，且通过 data 参数获取 shopId

---

#### ❌ 2. uiItem 引用完全删除

| 功能 | JS 行号 | GD 代码 | 状态 | 备注 |
|------|--------|--------|------|------|
| **this.uiItem 属性** | 12 | 无 | ❌ **完全删除** | 无法保存UI节点引用 |
| **uiItem 清理** | 26 | 无 | ❌ **缺失** | 资源清理不完整 |

**影响**: 无法保持对UI项目的引用，UI操作可能失效 🔴 **严重**

---

#### ❌ 3. init() 方法签名改变 (行 16-22)

| 方面 | JS 代码 | GD 代码 | 状态 | 备注 |
|------|--------|--------|------|------|
| **参数** | shopData | data | ⚠️ 改变 | 参数名改变 |
| **DataComponent 初始化** | 行 17-18 | 无 | ⚠️ **简化** | GD 在 _init() 中初始化 |
| **ShopComponent 初始化** | 行 20-21 | 无 | ❌ **缺失** | ShopComponent 初始化缺失 |

**影响**: ShopComponent 无法被正确初始化

---

#### ❌ 4. ShopComponent 初始化缺失 (行 20-21)

| 功能 | JS 行号 | GD 代码 | 状态 | 备注 |
|------|--------|--------|------|------|
| **shopComponent.init() 调用** | 21 | 无 | ❌ **完全缺失** | 商店数据无法初始化 |

**影响**: 商店功能无法初始化 ⚠️ **重要**

---

#### ❌ 5. dispose() 方法简化 (行 24-27)

| 功能 | JS 行号 | GD 代码 | 状态 | 备注 |
|------|--------|--------|------|------|
| **uiItem 清理** | 26 | 无 | ❌ **缺失** | UI引用无法释放 |
| **super.dispose() 调用** | 25 | 无 | 无法验证 | GD中不明确 |

**影响**: 资源泄漏风险 ⚠️ **重要**

---

### GD 版本实现差异

**JS 版本**:
```javascript
constructor(shopId, uiItem) {
    this.addComponent(new DataComponent());
    this.addComponent(new ShopComponent());
    this.uiItem = uiItem;        // 保存UI引用
    this.shopId = shopId;
}

init(shopData) {
    const dataComponent = this.getComponent("Data");
    dataComponent.data = shopData;
    const shopComponent = this.getComponent("Shop");
    shopComponent.init(shopData);  // 初始化商店数据
}
```

**GD 版本**:
```gdscript
func _init(data: Dictionary = {}):
    var data_comp = DataComponent.new(data)
    add_component(data_comp)
    
    var shop_comp = ShopComponent.new(data.get("shopId", 0), data.get("shopType", 0))
    add_component(shop_comp)
    # 无后续初始化
```

**差异**:
- GD在_init()中直接创建ShopComponent，无init()方法调用
- JS有单独的init()方法，用于后续初始化数据
- GD无法保存uiItem引用
- ShopComponent的初始化逻辑改变

---

### 缺失内容清单

| 序号 | 缺失内容 | JS 位置 | 重要性 | 影响范围 |
|------|---------|--------|--------|---------|
| 1 | uiItem 属性 | 12 | **严重** | UI引用管理 |
| 2 | init() 方法 | 16-22 | 中等 | 后续初始化 |
| 3 | ShopComponent.init() 调用 | 21 | 中等 | 商店初始化 |
| 4 | uiItem 清理 | 26 | 中等 | 资源清理 |

**统计**: 4 项缺失，其中 1 项 **严重** ❌

---

### GD 版本保留内容

| 保留的方法 | GD 行号 | 功能 | 完整性 |
|-----------|--------|------|--------|
| get_entity_type() | 9-10 | 获取实体类型 | ✅ 完整 |
| _init(data) | 12-17 | 数据+商店初始化 | ⚠️ **改变签名** |
| 无 init() | - | 缺少后续初始化方法 | ❌ 缺失 |

**评价**: 签名改变，缺少init()方法，但ShopComponent初始化逻辑被移到_init()中

---

### 总体评价

**⚠️ 中等削弱 - ShopEntity.js**

| 指标 | 数值 |
|------|------|
| **代码行数削减** | 28 → 17 (39% 删除) |
| **迁移完整度** | 仅 50% |
| **缺失项** | 4 项 |
| **游戏影响** | ⚠️ 商店UI引用管理失效 |

该文件的主要问题：
- ✗ uiItem 引用无法保存 (导致UI管理失效)
- ✗ init() 方法删除 (但逻辑被挪到_init)
- ✗ 资源清理逻辑简化 (泄漏风险)

**相比其他实体类，ShopEntity 的缺失情况较轻，但 uiItem 引用的丢失可能导致UI操作失效。**

---

## 📋 7️⃣ ShotElementEntity.js 对照报告 (缺失 85%)

### 文件位置
- **JS**: clearRoguelike/base/entity/ShotElementEntity.js (113 行)
- **GD**: gdRoguelike/core/entity/shot_element_entity.gd (17 行)
- **迁移完整度**: 仅 15%

---

### 核心差异 - 缺失的坐标、UI和攻击逻辑

#### ❌ 1. 组件创建系统大幅简化 (行 18-38)

| 组件 | JS 行号 | GD 代码 | 状态 | 备注 |
|------|--------|--------|------|------|
| **CoordComponent** | 19-21 | 无 | ❌ **完全删除** | 攻击位置无法追踪 |
| **UIComponent** | 23-28 | 无 | ❌ **完全删除** | UI交互无法进行 |
| **DataComponent** | 30-31 | 有 | ✅ 保留 | 数据保留 |
| **BuffComponent** | 33-34 | 有 | ✅ 保留 | Buff保留 |
| **MetaComponent** | 36-37 | 无 | ❌ **完全删除** | 元数据无法管理 |

**关键发现**: 
- JS 创建 5 个组件
- GD 仅创建 2 个组件
- 删除了 3 个关键组件

**可能影响**: 攻击位置无法追踪，UI无法交互 🔴 **严重**

---

#### ❌ 2. UI初始化和交互完全删除 (行 23-28)

| 功能 | JS 行号 | GD 代码 | 状态 | 备注 |
|------|--------|--------|------|------|
| **UIComponent 创建** | 23 | 无 | ❌ **完全删除** | UI组件无法创建 |
| **ShotElementUI 创建** | 24 | 无 | ❌ **完全删除** | 攻击位UI无法显示 |
| **拖拽处理器绑定** | 25 | 无 | ❌ **完全删除** | 拖拽事件无法响应 |
| **点击处理器绑定** | 26 | 无 | ❌ **完全删除** | 点击事件无法响应 |
| **UIComponent 初始化** | 27 | 无 | ❌ **完全删除** | UI初始化无法进行 |

**影响范围**: 攻击位UI完全无法显示，玩家无法看到攻击位 🔴 **严重**

---

#### ❌ 3. init() 方法完全删除 (行 40-44)

| 功能 | JS 行号 | GD 代码 | 状态 | 备注 |
|------|--------|--------|------|------|
| **init() 方法** | 40-44 | 无 | ❌ **完全删除** | UI初始化缺失 |
| UI初始化调用 | 43 | 无 | ❌ 缺失 | UI.init()无法调用 |

**影响范围**: 攻击位UI无法初始化 ⚠️ **重要**

---

#### ❌ 4. 拖拽处理方法存在但功能缺失 (行 46-49)

| 功能 | JS 行号 | GD 代码 | 状态 | 备注 |
|------|--------|--------|------|------|
| **onDropCompleteHandler() 存在** | 46-49 | 无 | ❌ **完全删除** | 虽然返回false (不处理拖拽) |

**说明**: JS中此方法仅返回false，不实现拖拽逻辑，GD中完全删除无影响

---

#### ❌ 5. 点击处理系统完全删除 (行 51-52)

| 功能 | JS 行号 | GD 代码 | 状态 | 备注 |
|------|--------|--------|------|------|
| **onClickHandler() 方法** | 51-52 | 无 | ❌ **完全删除** | 点击事件无法处理 |
| 核心逻辑调用 | 52 | 无 | ❌ 缺失 | _clickEntityData()无法调用 |

**影响范围**: 玩家无法点击攻击位进行攻击 🔴 **严重**

---

#### ❌ 6. 攻击执行核心逻辑完全删除 (行 55-100)

这是整个文件最关键的方法，控制整个攻击流程！

| 功能 | JS 行号 | GD 代码 | 状态 | 备注 |
|------|--------|--------|------|------|
| **_clickEntityData() 整个方法** | 55-100 | 无 | ❌ **完全删除** | 攻击流程无法执行 |

**该方法包含**:

| 子功能 | 行号 | 说明 |
|--------|------|------|
| 1. 收集子弹 | 57-73 | 从listShot中收集所有子弹 |
| 2. 清空子弹位置 | 68 | entity._updateData(null) |
| 3. 更新子弹UI | 71 | eui.updateUIIcon() |
| 4. 获取己方单位 | 77 | getOrderSelfEntities() |
| 5. 设置攻击标记 | 84 | data["isAtker"] = 1 |
| 6. 设置子弹数据 | 85 | data["bullets"] = bullets |
| 7. 更新步数 | 88 | updateStep() |
| 8. 发送UI更新事件 | 91 | EventManager.post("event.ui.update.step") |
| 9. 启动战斗阶段 | 94 | addStage(StageSelfBattle) |
| 10. 触发UI更新 | 97 | EventManager.post("event.ui.update.orderSelf.atk") |

**所有这些逻辑全部删除！**

**可能影响**: 
- ❌ 无法收集子弹
- ❌ 无法清空子弹位置
- ❌ 无法获取己方单位
- ❌ 无法标记攻击者
- ❌ 无法传递子弹数据
- ❌ 无法更新进度
- ❌ 无法启动战斗
- ❌ UI无法更新

**这是导致整个攻击系统失效的核心原因！** 🔴 **最严重**

---

#### ❌ 7. 数据更新方法删除 (行 102-105)

| 功能 | JS 行号 | GD 代码 | 状态 | 备注 |
|------|--------|--------|------|------|
| **_updateData() 方法** | 102-105 | 无 | ❌ **完全删除** | 数据更新无法工作 |

**影响**: 子弹位置无法清除

---

#### ❌ 8. 资源清理逻辑删除 (行 107-112)

| 功能 | JS 行号 | GD 代码 | 状态 | 备注 |
|------|--------|--------|------|------|
| **dispose() 方法** | 107-112 | 无 | ❌ **完全删除** | UI销毁逻辑缺失 |
| UI销毁动画 | 110 | 无 | ❌ 缺失 | 销毁动画无法播放 |

**影响范围**: 资源泄漏风险，UI销毁不完整 ⚠️ **重要**

---

#### ❌ 9. WorldDataManager 集成完全缺失

| 调用点 | JS 行号 | GD 代码 | 状态 | 用途 |
|--------|--------|--------|------|------|
| 获取子弹 | 57 | 无 | ❌ 缺失 | getBulletEntities() |
| 获取己方单位 | 77 | 无 | ❌ 缺失 | getOrderSelfEntities() |
| 更新步数 | 88 | 无 | ❌ 缺失 | updateStep() |
| 获取进度 | 91 | 无 | ❌ 缺失 | getStepProgress() |
| 启动战斗 | 94 | 无 | ❌ 缺失 | addStage() |

**影响范围**: 所有游戏管理器集成缺失

---

#### ❌ 10. EventManager 事件通信缺失

| 事件 | JS 行号 | GD 代码 | 状态 | 用途 |
|------|--------|--------|------|------|
| event.ui.update.step | 91 | 无 | ❌ 缺失 | 步数更新通知 |
| event.ui.update.orderSelf.atk | 97 | 无 | ❌ 缺失 | 攻击状态通知 |

**影响范围**: UI无法获得更新通知

---

### 缺失内容清单

| 序号 | 缺失内容 | JS 位置 | 重要性 | 游戏影响 |
|------|---------|--------|--------|---------|
| 1 | CoordComponent | 19-21 | 中等 | 坐标管理 |
| 2 | UIComponent | 23-28 | **严重** | UI显示 |
| 3 | ShotElementUI | 24 | **严重** | UI交互 |
| 4 | 拖拽处理器绑定 | 25 | 中等 | 拖拽事件 |
| 5 | 点击处理器绑定 | 26 | **严重** | 点击事件 |
| 6 | MetaComponent | 36-37 | 中等 | 元数据 |
| 7 | init() 方法 | 40-44 | 中等 | UI初始化 |
| 8 | onClickHandler() | 51-52 | **严重** | 点击处理 |
| 9 | _clickEntityData() 整个方法 | 55-100 | **最严重** | 攻击流程 |
| 10 | _updateData() | 102-105 | 中等 | 数据更新 |
| 11 | dispose() | 107-112 | 中等 | 资源清理 |
| 12 | WorldDataManager 集成 | 全文 | **严重** | 游戏流程 |
| 13 | EventManager 集成 | 全文 | **严重** | UI通信 |

**统计**: 13 项缺失，其中 7 项 **严重** + 1 项 **最严重** ❌

---

### GD 版本保留内容（仅）

| 保留的方法 | GD 行号 | 功能 | 完整性 |
|-----------|--------|------|--------|
| get_entity_type() | 9-10 | 获取实体类型 | ✅ 完整 |
| _init(data) | 12-17 | 基础初始化 | ⚠️ **极度简化** |

**评价**: 仅保留了骨架，核心逻辑全部删除

---

### 核心游戏流程缺失分析

#### 🔴 完整的攻击流程 (全部缺失)

```
JS 攻击流程：
1. 玩家点击攻击位
   ↓ onClickHandler()
2. 收集所有子弹 (getBulletEntities)
   ↓ 循环遍历，过滤type==1
3. 清空子弹位置 (_updateData(null))
   ↓ 更新UI (updateUIIcon)
4. 获取己方单位 (getOrderSelfEntities)
   ↓ 取第一个单位
5. 标记攻击者 (isAtker = 1)
   ↓ 设置子弹 (bullets = [...])
6. 更新步数 (updateStep)
   ↓ 获取进度 (getStepProgress)
7. 发送UI更新事件
   ↓ 启动战斗阶段 (addStage(StageSelfBattle))
8. 触发攻击UI更新事件
   ↓ 战斗开始

GD 攻击流程：
→ 无任何功能 → 攻击无法进行
```

**每一步都缺失！**

---

### 可能影响分析

#### 🔴 攻击系统完全失效
- ❌ 无法点击攻击位 (缺 onClickHandler)
- ❌ 无法收集子弹 (缺 _clickEntityData)
- ❌ 无法清空子弹 (缺 _updateData)
- ❌ 无法启动攻击 (缺 addStage)

#### 🔴 UI 完全无法显示
- ❌ 无攻击位UI (缺 ShotElementUI)
- ❌ 无点击事件处理
- ❌ 无UI更新通知

#### 🔴  游戏数据无法管理
- ❌ 无WorldDataManager集成
- ❌ 无法管理子弹
- ❌ 无法管理己方单位
- ❌ 无法更新进度

#### 🔴 UI通信断裂
- ❌ 无事件通知
- ❌ 步数无法更新
- ❌ 攻击状态无法同步

---

### 与 ElementEntity 的对比

| 方面 | ElementEntity | ShotElementEntity | 共同点 |
|------|---------------|-------------------|--------|
| UI交互 | 拖拽 + 点击 | 点击 | 都删除UI交互 |
| 核心方法缺失 | onDropCompleteHandler + onClickHandler | onClickHandler | 都缺onClickHandler |
| WorldDataManager | 5处调用 | 5处调用 | 都完全缺失集成 |
| EventManager | 4处调用 | 2处调用 | 都缺少事件通知 |
| 删除比例 | 80% | 85% | 都是极度删除 |

**结论**: 两个都涉及UI交互的实体，缺失模式**完全相同**。

---

### 与 OrderSelfEntity 的对比

| 方面 | OrderSelfEntity | ShotElementEntity | 共同点 |
|------|-----------------|-------------------|--------|
| init() 缺失 | ✓ 完全缺失 | ✓ 完全缺失 | 都无init方法 |
| 点击处理 | 缺 onClickHandler | 缺 onClickHandler | 都无点击处理 |
| 核心逻辑 | 缺 _clickEntityData | 缺 _clickEntityData | 都缺核心逻辑 |
| UI初始化 | 缺 | 缺 | 都无UI初始化 |
| 删除比例 | 65% | 85% | ShotElementEntity更严重 |

**结论**: 都是删除了**点击处理和核心逻辑**，模式相同。

---

### 与其他攻击相关文件的上下文

这个文件是攻击系统的关键一环：

```
棋盘系统 (ElementEntity) ←→ 子弹系统 (ShotElementEntity)
                               ↓
                            攻击流程 (_clickEntityData)
                               ↓
                          己方单位 (OrderSelfEntity)
                               ↓
                            敌方单位 (OrderEnermyEntity)
                               ↓
                            战斗系统

整个链条都缺失关键方法：
- ElementEntity: 无拖拽、点击、合成
- ShotElementEntity: 无点击、无攻击流程
- OrderSelfEntity: 无初始化、无UI、无选择
- OrderEnermyEntity: 无初始化、无Boss系统、无伤害计算
```

**整个战斗系统的所有关键环节都被削弱！**

---

### 总体评价

**❌ 最严重的削弱 - ShotElementEntity.js**

| 指标 | 数值 |
|------|------|
| **代码行数削减** | 113 → 17 (85% 删除) |
| **迁移完整度** | 仅 15% |
| **缺失项** | 13 项 |
| **严重缺失** | 7 项 **严重** + 1 项 **最严重** |
| **游戏影响** | 🔴 攻击系统完全失效 |

该文件删除了：
- ✗ 坐标管理 (无法追踪位置)
- ✗ UI系统 (无法显示攻击位)
- ✗ UI交互 (无法点击)
- ✗ 攻击流程 (无法执行攻击)
- ✗ 子弹管理 (无法清空子弹)
- ✗ 游戏管理集成 (无法驱动流程)
- ✗ UI通信 (无法更新显示)

**ShotElementEntity 控制了整个攻击流程的核心逻辑 _clickEntityData()，删除它意味着玩家无法发起任何攻击。**

---

## **BaseSkill.js 迁移对比分析**

### 📋 **文件信息**
| 项目 | JS版本 | GD版本 | 行数差异 |
|------|--------|--------|---------|
| **文件路径** | clearRoguelike/base/skills/BaseSkill.js | gdRoguelike/core/skills/base_skill.gd | 65行 vs 52行 |
| **迁移完整度** | ✅ **70% 迁移** | ✅ 基础功能完整 | **事件系统改变** |

### 核心差异与对标

| JS 实现 | GD 实现 | 差异说明 | 影响评估 |
|--------|--------|---------|---------|
| **constructor(skillData)** (L9-15) | **_init(p_skill_data)** (L14-15) | 初始化逻辑一致 | ✅ 一致 |
| **skillData/entityId/isActive** (L10-12) | **同名变量** (L10-12) | 属性定义完全对应 | ✅ 一致 |
| **_registerEventListener()** (L21-23) | **_register_event_listener()** (L27-28) | 命名转换，都是虚方法 | ✅ 一致 |
| **onEvent(event, args)** (L28-32) | **on_event(event_name, args)** (L31-34) | 参数差异：event vs event_name | ⚠️ 参数变化 |
| **execute(context)** (L38-41) | **execute(context)** (L17-18) | 日志调用改为推送错误，功能简化 | ✅ 改进：去除日志 |
| **onExecute(context)虚方法** (L47-49) | **on_execute(context)虚方法** (L20-21) | 错误处理改为push_error | ✅ 改进 |
| **bindEntity(entityId)** (L54-56) | **bind_entity(p_entity_id)** (L23-24) | 命名转换，功能一致 | ✅ 一致 |
| **dispose()方法** (L61-64) | **dispose()方法** (L47-52) | GD版本尝试断开所有连接 | ⚠️ 差异 |
| **新增方法** | **connect_to_bus(signal_name)** (L37-39) | GD新增，连接到GlobalEventBus | ✅ 增强 |
| **新增方法** | **_on_bus_event(args, signal_name)** (L42-45) | GD新增，总线事件适配器 | ✅ 增强 |
| **EventManager.unregisterAll()** (L63) | **使用GlobalEventBus** | 事件系统架构完全不同 | ⚠️ **架构变更** |

### 🔍 **关键架构差异**

| 方面 | JS版本 | GD版本 | 影响 |
|------|--------|--------|------|
| **事件系统** | EventManager.register/unregister | GlobalEventBus 信号连接 | ⚠️ 完全不同的事件模式 |
| **事件监听方式** | 子类重写_registerEventListener()并调用register | 子类调用connect_to_bus()连接信号 | ⚠️ 大幅改变 |
| **事件处理流程** | EventManager主动调用onEvent | GlobalEventBus信号驱动调用_on_bus_event | ⚠️ 被动→主动模式 |
| **dispose处理** | 简单unregisterAll | 尝试中止树内连接 | ⚠️ 处理复杂化 |

### ⚠️ **缺失/变化的功能**

| 序号 | 功能 | JS实现 | GD实现 | 影响 |
|------|------|--------|--------|------|
| 1 | **_registerEventListener()调用** | constructor中调用 | 没有自动调用，需子类手动调用connect_to_bus() | ⚠️ 初始化流程改变 |
| 2 | **EventManager依赖** | 导入EventManager使用 | 不需要，使用GlobalEventBus | ✅ 改进：解耦 |
| 3 | **日志记录** | execute中有日志 | 删除日志 | ✅ 改进：性能 |
| 4 | **事件参数验证** | onEvent中检查entityId | on_event和_on_bus_event中双重检查 | ⚠️ 重复验证 |
| 5 | **disconnect处理** | 不存在 | dispose中处理树内连接断开 | ⚠️ 新增复杂逻辑 |

### 📊 **迁移评估**

| 维度 | 评分 | 说明 |
|------|------|------|
| 功能完整性 | ✅ 80% | 核心方法都有，初始化方式改变 |
| 事件系统兼容性 | ⚠️ 差 | 从EventManager→GlobalEventBus，子类需要适配 |
| 事件处理正确性 | ⚠️ 部分 | 双重检查entityId可能造成冗余 |
| dispose完整性 | ⚠️ 部分 | GD版本处理复杂但可能不完整 |
| **总体结论** | ⚠️ **70% 迁移** | 核心骨架完整，但事件系统架构完全改变，**子类实现需大幅调整** |

### 🔴 **关键问题**

1. **事件系统完全改架** - JS的EventManager → GD的GlobalEventBus，这是根本性的架构变更
2. **子类初始化流程改变** - JS自动调用_registerEventListener() → GD需手动调用connect_to_bus()
3. **_on_bus_event适配器引入复杂性** - 需要处理args可能是Dictionary或其他类型的情况
4. **子类实现必须改变** - 所有技能子类都需要重写事件连接逻辑

---
