Created 0 todos

下面给出逐文件、逐行要点对照报告（JS 原实现 = clearRoguelike，GD 实现 = gdRoguelike）。对每个文件列出：JS 的关键逻辑/行号、GD 中对应实现位置/行号、缺失或差异点，以及可能影响。若要把每处差异展开为代码片段或完整行级 diff，可再要求导出单文件详细 diff。

总体说明（方法）：已并行读取并比对下列文件对。报告按文件组分节，每节首行列出对照文件路径和关键行号范围（基于已读取内容）。

— map/prng —
- clearRoguelike/map/Prng.js
  - 12-22 createPRNG(seed) 返回闭包（Mulberry32）；31-33 randomInt；41-43 randomChoice；52-64 weightedRandomChoice；72-79 shuffle。
- gdRoguelike/map/prng.gd
  - 11-16 _init/set_seed；17-23 next_float 实现 Mulberry32 core；25-26 next_int(min,max)。
- 差异/遗漏
  - GD 缺少 randomChoice(array)、weightedRandomChoice(items,weights)、shuffle(array)（JS: 41-79）。影响：上层使用这些工具（按权重抽样、数组洗牌）在 GD 中无法直接重用，导致随机策略简化或重复实现。
  - JS 的 createPRNG 返回独立可闭包化函数（可替换 seed instance）；GD 以对象状态持有 seed（实例方法 next_float/next_int）。影响：API/用法差异可能导致调用端种子管理不一致（可复现性边界变化）。

— map/MapModel —
- clearRoguelike/map/MapModel.js
  - 39-48 createEmptyMap(difficulty,seed)；55-86 validateMapModel(map)（含引用检查：MetaConsts.gameRounds/shop/enemies）；93-112 validateMapNode(node)；119-137 serialize/deserialize。
- gdRoguelike/map/map_model.gd
  - 18-26 create_empty_map(); 28-35 validate_map_node(node)（非常轻量）；37-46 serialize() 返回 Dictionary；缺少 deserialize/validateMapModel 对等实现；game_rounds 字段存在但 JS 的引用一致性检查（验证 roundId/shopId/enemies 存在）缺失。
- 差异/遗漏
  - GD 缺少 MapModel.validate_map_model 的严格性：未校验 map.version、seed 范围、difficulty 范围、layers 数组完整性、首末节点类型、以及对 MetaConsts.gameRounds/MetaConsts.gameShops/MetaConsts.orderEnermy 的引用存在性（JS 55-74,78-86）。影响：序列化/反序列化、地图合法性校验在 GD 侧更宽松，运行时可能接受不合法地图或产生错误在运行阶段才暴露。
  - GD serialize() 返回结构（37-46）但无对应 deserialize/validate 对称流程（JS 119-137），影响保存/加载一致性与错误提示。

— map/MapGenerator（概要） —
- clearRoguelike/map/MapGenerator.js 与 gdRoguelike/map/map_generator.gd 均实现轮次与节点生成。
- 差异/遗漏（概括）
  - GD 版本有 generate_game_rounds 与生成节点的阈值流程（gd 文件 10-68 与 70-113），但与 JS 实现相比存在概率/权重/软着陆逻辑可能差异（例如 JS 可能用不同常数或更复杂的 enemy pool 筛选与权重）。影响：生成结果的分布、敌人强度和 shop/rest/event 出现率可能不同，进而改变难度曲线。
  - 具体行级差异需对照 MapGenerator.js 的完整内容（若需要，可导出逐行 diff）。

— events/EventFactory —
- clearRoguelike/events/EventFactory.js
  - 15-19 EventClassMap 使用动态 import，为每 eventId 返回模块加载器；27-47 createEventEntity(eventId,node)：读取 MetaConsts.gameEvents[eventId]，校验、加载模块、实例化、eventEntity.init(eventMeta)，完整的日志和异常捕获（40-50）。
  - registerEventEntity(eventId, loader) 58-60 支持外部注册。
- gdRoguelike/events/event_factory.gd
  - 8-16 静态注册表 _event_registry 初始化（70001/70002/70003），create_event_entity(event_id) 17-26 直接创建实例（无 meta 注入、无 node 传参）；register_event_entity(event_id,class_ref) 28-37 接收类引用，注册时用 class_ref.new(id)。
- 差异/遗漏
  - GD 工厂没有读取并注入 MetaConsts.gameEvents[eventId] 到事件实例（JS 在创建后调用 eventEntity.init(eventMeta)），GD 只是 new(id)。影响：事件元数据（显示文本、rewardPool、buffPool、healPercent 等）未被注入，事件行为可能使用硬编码或默认值，导致配置不可控与不一致（见事件实现差异）。
  - JS 使用动态 import 异步加载模块并有错误日志（40-50）；GD 以静态注册或 class 引用方式同步/本地加载，缺少 JS 的懒加载模式和更丰富的日志/异常信息。

— events/单个事件：TreasureChest / HealFountain / RandomBuff —
- clearRoguelike/events/TreasureChestEvent.js
  - 14-17 onInit() 随机抽奖励 via _rollReward()（46-62 实现：读取 this._meta.rewardPool，基于 reward.chance 加权随机）；onSelectOption 19-33: 1=open 调用 _giveReward(wdm)（64-68 使用 WorldDataManager.addItem）；getUIData 35-40 返回 meta + rewardPreview。
- gdRoguelike/events/treasure_chest_event.gd
  - on_enter() 返回基本 UI 数据（8-10）；on_option_select(option_id) 11-16 若选打开，用 ClearRoguelikeManager.get_world().inventory_service.add_item(60000001, randi()%3+1) 硬编码实现（13-16）。
- 差异/遗漏
  - GD 用硬编码 itemId 60000001 与数量 randi()%3+1（gd 13-15），缺少 JS 的 this._meta.rewardPool + 加权抽取（JS 46-62），且没有 rewardPreview 显示。影响：宝箱奖励的多样性、权重与配置驱动性被移除；UI 预览和可配置行为缺失。
- clearRoguelike/events/HealFountainEvent.js
  - onInit 14-20: 读取 WorldDataManager.getOrderSelfData() 计算 healAmount = floor(maxHp * this._meta.healPercent)；onSelectOption 22-36: option 1 调用 _healPlayer(wdm)（49-57 最终修改 orderSelfData.hp = min(orderSelfData.hp + this._healAmount, orderSelfData.hp) — 注意：这里 JS 存在疑似 bug：min(..., orderSelfData.hp) 用错上限，应为 maxHp）。
- gdRoguelike/events/heal_fountain_event.gd
  - on_enter UI and on_option_select: 若选恢复，遍历 self_entities 并 data_comp.data["hp"]=min(current+30,max_hp)（gd 18-19 uses fixed +30）。
- 差异/遗漏
  - JS 原实现使用 meta.healPercent 计算（配置驱动），GD 使用固定 +30 或 50% depending on rest implementation (see RestHealCamp). GD 未完全保留 JS 的百分比配置。影响：治疗量一致性受影响；注意 JS 实现可能包含 bug（min 的第二参数应为 maxHp）——GD 修正为 cap by maxHp but uses magic number 30.
- clearRoguelike/events/RandomBuffEvent.js
  - onInit 16-19: this._selectedBuff = _rollBuff()（52-68 加权抽取 buffPool）；_applyBuff -> BuffSystem.addBuff(orderSelfEntity, buffData.type, buffData.bonus.value, buffData.bonus.duration, "event_random_buff")（70-80）。
- gdRoguelike/events/random_buff_event.gd
  - on_enter returns UI; on_option_select(option_id==1) picks selected from hardcoded buff_types list using randi() and applies BuffSystem.get_instance().add_buff(self_entity, selected, 5.0, 5)（gd 12-18）。
- 差异/遗漏
  - GD 使用硬编码 buff 名称表和固定数值 (5.0 value, duration 5)；JS 使用 MetaConsts.resolveBuff(this._selectedBuff.buffId) 读取 buffData（配置驱动），并将来源标记为 "event_random_buff"。影响：buff 类型、数值、来源标记、可扩展性与可配置性被弱化；Buff 应用参数不一致可能影响数值平衡与 buff 互作用。

— rests/RestFactory & Rest 类型 —
- clearRoguelike/rests/RestFactory.js
  - 16-20 RestClassMap uses dynamic import and IDs mapping; createRestEntity loads MetaConsts.gameRests[restId], instantiates RestClass, restEntity.init(restMeta)（28-47），完整日志与异常处理。
- gdRoguelike/rests/rest_factory.gd
  - create_rest_entity(rest_id) match -> returns RestX.new(rest_id) (simple factory), no meta injection.
- 差异/遗漏
  - 同 EventFactory 问题：缺少 meta 注入，缺少 dynamic loader/logging。影响：rest 行为失去配置驱动。
- RestUpgradeStation
  - JS (clear) onConfirm 增加 launcher level, atkBonus etc（lines 22-45）：逐个 launcherEntities 获取 Data component 并修改 data["level"]、data["atkBonus"] += 0.05，并记录日志（明确每项变动）。
  - GD on_confirm (gd 11-18) 操作：针对单个 self_entity 增加 data_comp.data["atk"] += 3（不同属性，永久性写法）。
- 差异/遗漏
  - GD 的升级逻辑与 JS 不同字段和值；JS 对所有 launcherEntities 生效且有 atkBonus 增幅 +5%，GD 对单体 self_entity 的 atk 值直接 +3。影响：效果范围与数值差异，系统一致性被破坏。
- RestRewardChest
  - JS 使用 MetaConsts.rewardPool 或自定义池 + PRNG 可选 1-2 items，且会调用 wdm.addItem(itemId,1)（clear lines 28-54）。
  - GD 使用 smaller item_ids list [60000001,60000002,60000003,60000004] 并 add one selected item (gd 11-16).
- 差异/遗漏
  - GD 简化池与数量选择；JS 的随机 count (1-2) 与 item 池更丰富且使用 MetaConsts 元数据（名字日志）。影响：道具掉落多样性与权重消失。
- RestHealCamp
  - clearRoguelike onConfirm: 遍历 playerEntities，依据 this.meta.healPercent 计算 healAmount 并 cap by maxHp（lines 30-33）。
  - GD on_confirm: healing by 50% hardcoded (gd 17-19 uses max_hp * 0.5).
- 差异/遗漏
  - Hardcoding vs meta 配置差异；GD 固定百分比可能或未与 meta 保持一致。

— data/BuffContext —
- clearRoguelike/data/BuffContext.js
  - 6-32 constructor sets source,target,timing,baseValue,modifiedValue,attackData,damageData,bulletData,extra,_cancelled; methods: cancel(), isCancelled(), setValue(), multiplyValue(), addValue(), toJSON()（34-86）。
- gdRoguelike/data/buff_context.gd
  - class_name BuffContext: properties entity, source, buff_data, trigger_timing, extra; _init(p_entity,p_source,p_buff_data) sets buffs; accessor helpers get_value/get_stack/get_remaining_turns (27-36).
- 差异/遗漏
  - GD 缺少 modifiedValue、baseValue、attackData/damageData/bulletData、cancel()、setValue()/multiplyValue()/addValue()、isCancelled()、toJSON()（JS 30-86）。影响：Buff 执行链中对“取消后续 Buff”、累计/逐步修正值、战斗数据透传等功能不可用或需重写，可能导致复杂 Buff 逻辑失效（例如链式修改、短路取消）。

— buff/BuffSystem —
- clearRoguelike/base/system/BuffSystem.js
  - 完整 singleton 实现：_entityBuffs Map（16-18）；getInstance init/dispose/update（23-45）；addBuff(entity,buffType,value,duration,source) — 包含 BuffRegistry.getBuffClass、创建实例、合并同类 buff(addStacks)、apply 回调与日志（56-103）；removeBuff by id/type（110-131）；getBuffs/hasBuff/calculateModifier/clearBuffs/triggerTiming/onRoundStart/onRoundEnd/getDebugInfo（139-299）。触发时机分支（216-261）覆盖详尽枚举（ROUND_START,ATTACK_CHECK,...）。
- gdRoguelike/core/system/buff_system.gd
  - singleton-like static _instance; _entity_buffs Dictionary; get_instance/init/dispose/update；add_buff(entity,buff_type_name,value,duration,source) uses BuffRegistry.get_buff_class(type), BUFF_TYPE_STRINGS mapping to enum, dynamic load(class_path) (40-80). remove_buff/remove_buff_by_id/get_buffs/has_buff/calculate_modifier/clear_buffs/trigger_timing/on_round_start/on_round_end/get_debug_info implemented (40-266). trigger_timing includes more match cases and ACTION_PHASE (lines 201-230).
- 差异/遗漏（实现与行为）
  - API 名称与参数形态存在差别（addBuff vs add_buff; buff_type string vs enum mapping）；GD 侧将 BuffRegistry 存储路径/类引用（line 65-70）并用 load(class_path) 创建实例，JS 侧直接由 BuffRegistry 返回 class。两侧实现总体等价但：
    - GD 侧依赖 BUFF_TYPE_STRINGS 映射（lines 270-303）——需确保映射完备，否则运行时找不到对应枚举转换。
    - JS addBuff 在已有同类 buff 时调用 existing.addStacks() 并返回 existing（84-88）；GD 同样搜索并 add_stacks(1)（58-63） —— 功能相似。
    - 日志与错误处理：JS 有更明显的日志（ClearRoguelikeLogger.log/warn），GD 多用 silent return/null 或 print（不同的调试能见度）。
  - 关键缺陷/注意点：
    - GD 的 add_buff 将 class_path = BuffRegistry.get_buff_class(buff_type_name)；若 registry 存储的是 class_ref 而非资源路径，load(class_path) 可能错误（lines 45-66）。实现细节需核实：gd 的 BuffRegistry.get_buff_class 返回 class_path 字符串还是直接 class 引用（在 buff_registry.gd 我们看到 register_buff(type_str,class_ref) 存 class_ref 直接）。GD add_buff 第65行 load(class_path) 会在 class_ref 不是路径时失败。影响：动态实例化可能出错。
    - trigger_timing 的枚举常量与 JS 对应需一致；GD 添加 ACTION_PHASE，但 JS 使用不同命名（两边存在映射差异）。
  - 小结：核心生命周期逻辑存在，但实现细节（注册返回值类型、日志、映射表完整性）需验证以确保与 JS 运行时行为一致。

— buff/BaseBuff & BuffRegistry —
- clearRoguelike/base/buffs/BaseBuff.js
  - 构造赋 id/type/value/duration/remainingDuration/stacks/maxStacks/source/isExpired/isActive/category/triggerTiming；实现了 apply/remove/onRoundEnd（reduce remainingDuration 并置 isExpired）、多种 onXXX 钩子、addStacks/removeStacks/getBuffValue/toJSON（lines 8-201）。
- gdRoguelike/core/buffs/base_buff.gd
  - 属性与方法相似（_init 构造lines35-48），on_round_end 减少 remaining_duration 并 set is_expired（58-63），增加 on_action_phase 但方法命名风格为 snake_case；to_json 返回字段名 mapping (105-117)。
- 差异/遗漏
  - 命名/风格差异（camelCase vs snake_case）需要上层调用适配，但功能大体有对等实现。
  - 注意 JS BaseBuff.toJSON 返回键名 remainingDuration，但 GD to_json uses "remainingDuration" too — OK.
  - 无明显功能缺失，但需留意触发方法名匹配 BuffSystem 的 trigger 时机（gd 与 js 的枚举常量需一致）。

— data/GameData —
- clearRoguelike/data/GameData.js
  - load(json) 合并 defaults（16-40）并赋值到类字段；toJSON() 输出完整可存储对象（72-100）；isValid(json) 校验格式版本（107-111）。
- gdRoguelike/data/game_data.gd
  - load(json_data) 合并 defaults（46-71），to_json() 返回对象（91-112），is_valid(json_data) 做版本验证（114-120）。属性与 getter/setter 实现（122-189）。
- 差异/遗漏
  - 两侧实现功能等价，GD 侧在合并和 duplicate 使用 Godot 数据结构方法（duplicate），行为上相似。注意字段命名一致性（orderEnermy / order_enermy 等需在调用端一致），GD 使用 snake case properties for engine code but to_json returns camelCase keys — GD implementation already maps keys correctly.

— systems: EventSystem / RestSystem —
- clearRoguelike/base/system/EventSystem.js
  - 使用 EventFactory.createEventEntity(eventId) async, add eventEntity.open(), WorldDataManager.addEventEntity(eventEntity), on option select uses _curEventEntity.selectOption(data.optionId) and clear currentEvent if result true (lines 42-61,72-84).
- gdRoguelike/core/system/event_system.gd
  - open_event(event_id) uses EventFactory.create_event_entity(event_id) synchronous, event_entity.open(), world.entity_manager.register_entity(event_entity) (lines 22-36), resolve_option(entity, option_id) calls entity.on_option_select(option_id) and emits GlobalEventBus close. Also has trigger_event(entity) for existing entity.
- 差异/遗漏
  - GD 没有 WorldDataManager.addEventEntity 对等调用（使用 world.entity_manager.register_entity），接口差异需检查一致性.
  - JS has eventManager registration/unregistration via EventManager; GD uses GlobalEventBus events — integration points differ, may affect event propagation.

- RestSystem
  - clearRoguelike RestSystem registers EventManager listeners and manages _currentRest entity lifecycle with openRest(restId,node) awaiting RestFactory.createRestEntity(restId,node) (52-70) and handles confirm/skip/close events (75-101).
  - gdRoguelike core/system/rest_system.gd is much simpler: open_rest(entity) emits event_rest_open; confirm_rest(entity) calls entity.on_confirm() and emits confirm/close; skip_rest similar (lines 17-33).
- 差异/遗漏
  - GD RestSystem delegates on_confirm to entity directly and emits events; JS flow uses async factory creation and keeps a _currentRest handle with explicit disposal — GD lacks central currentRest storage/guarding and listener registration (可能以其他方式存在). 影响：并发调用与生命周期干净关闭的行为不同。

— 其它注意点（跨文件/集成）
- 配置驱动 vs 硬编码：JS 多处依赖 MetaConsts / Meta driven pools（events.rewardPool、rest.meta.healPercent、buffPool 等），GD 实现倾向于硬编码常量或简化随机表（导致可配置性丢失）。
- 随机数 API 不一致：JS 的 createPRNG 返回函数供局部重现使用，GD 多为对象方法，且缺少高阶随机工具（shuffle/weightedChoice）——会影响 Map/Reward/Buff 的复现性与等价性。
- BuffContext 功能缺失（cancel、modifiedValue 等）将阻断较复杂 Buff 的“短路/链式修改/累加/乘法”策略，进而影响计算流程（BuffSystem.triggerTiming 中传递上下文的预期行为与 GD BuffContext 不对齐）。
- 日志与错误处理：JS 侧广泛使用 ClearRoguelikeLogger.warn/error/log 捕获与记录创建/加载失败；GD 更依赖 push_warning/print 或无日志。缺少细粒度日志会降低运行时诊断能力。
- 注册/动态加载 语义不一致：JS 的 Event/Rest factories 使用动态 import，并在 create 时注入 meta；GD 多为静态注册或 class 引用注册，且 factory.create_event_entity/create_rest_entity API 返回实例时未注入配置对象。
- 名称与字段命名需注意：JS 使用 camelCase（e.g., remainingDuration, orderEnermy），GD 在内部多为 snake_case 属性，但 to_json/serialize 做映射；仍需在调用链核对一致性以防静默错误。
