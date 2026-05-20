extends BaseSystem

# ============================================================
# Buff 系统（替代 BuffSystem.js）
# 全局单例，负责所有 Buff 的生命周期管理、事件分发、数值计算
# 使用 ECS 架构：通过 BuffRegistry 动态创建 BaseBuff 类实例
# ============================================================

class_name BuffSystem

static var _instance: BuffSystem = null
var _entity_buffs: Dictionary = {}  # entity_id -> Array<BaseBuff>
var _initialized: bool = false

func _init():
	if _instance == null:
		_instance = self

static func get_instance() -> BuffSystem:
	if _instance == null:
		_instance = BuffSystem.new()
	return _instance

func init() -> void:
	if _initialized:
		return
	_initialized = true

func dispose() -> void:
	_entity_buffs.clear()
	_initialized = false
	_instance = null
	super.dispose()

func update(dt: float) -> void:
	super.update(dt)

# ============================================
# 为实体添加 Buff
# 通过 BuffRegistry 动态创建 BaseBuff 类实例
# ============================================
func add_buff(entity, buff_type_name: String, value: float = 0.0, duration: int = -1, source = null):
	if not entity or buff_type_name.is_empty():
		return null
	
	# 通过 BuffRegistry 获取 Buff 类的路径并动态实例化
	var class_path = BuffRegistry.get_buff_class(buff_type_name)
	if class_path == null:
		return null
	
	var buff_type_enum = BUFF_TYPE_STRINGS.get(buff_type_name, BuffTypes.NONE)
	
	# 获取或创建实体 Buff 列表
	var entity_id = entity.get_id() if entity.has_method("get_id") else str(entity.get_instance_id())
	if not _entity_buffs.has(entity_id):
		_entity_buffs[entity_id] = []
	
	var buff_list: Array = _entity_buffs[entity_id]
	
	# 检查是否已有同类型 Buff，处理叠加逻辑
	for existing in buff_list:
		if existing is BaseBuff and existing.type == buff_type_enum:
			existing.add_stacks(1)
			return existing
	
	# 动态创建 Buff 实例
	var BuffClass = load(class_path)
	var buff = BuffClass.new({
		"value": value,
		"duration": duration,
		"source": source,
	})
	if not buff is BaseBuff:
		return null
	
	buff_list.append(buff)
	
	# 触发 apply 回调
	var context = BuffContext.new(entity, source, {})
	buff.apply(context)
	
	return buff

# ============================================
# 移除实体上的指定类型 Buff
# ============================================
func remove_buff(entity, buff_type_name: String) -> void:
	if not entity:
		return
	var entity_id = entity.get_id() if entity.has_method("get_id") else str(entity.get_instance_id())
	var buff_list: Array = _entity_buffs.get(entity_id, [])
	
	var buff_type_enum = BUFF_TYPE_STRINGS.get(buff_type_name, BuffTypes.NONE)
	
	var context = BuffContext.new(entity, null, {})
	for i in range(buff_list.size() - 1, -1, -1):
		var buff = buff_list[i]
		if buff is BaseBuff and buff.type == buff_type_enum:
			buff.remove(context)
			buff_list.remove_at(i)
			break

# ============================================
# 通过ID移除实体上的指定 Buff
# ============================================
func remove_buff_by_id(entity, buff_id: String) -> void:
	if not entity:
		return
	var entity_id = entity.get_id() if entity.has_method("get_id") else str(entity.get_instance_id())
	var buff_list: Array = _entity_buffs.get(entity_id, [])
	
	var context = BuffContext.new(entity, null, {})
	for i in range(buff_list.size() - 1, -1, -1):
		var buff = buff_list[i]
		if buff is BaseBuff and buff.id == buff_id:
			buff.remove(context)
			buff_list.remove_at(i)
			break

# ============================================
# 获取实体上的所有 Buff（可按类型过滤）
# ============================================
func get_buffs(entity, buff_type_name: String = "") -> Array:
	if not entity:
		return []
	var entity_id = entity.get_id() if entity.has_method("get_id") else str(entity.get_instance_id())
	var buff_list: Array = _entity_buffs.get(entity_id, [])
	
	if not buff_type_name.is_empty():
		var buff_type_enum = BUFF_TYPE_STRINGS.get(buff_type_name, BuffTypes.NONE)
		var filtered = []
		for buff in buff_list:
			if buff is BaseBuff and buff.type == buff_type_enum:
				filtered.append(buff)
		return filtered
	
	return buff_list.duplicate()

# ============================================
# 检查实体是否拥有指定 Buff
# ============================================
func has_buff(entity, buff_type_name: String) -> bool:
	var buff_type_enum = BUFF_TYPE_STRINGS.get(buff_type_name, BuffTypes.NONE)
	if not entity:
		return false
	var entity_id = entity.get_id() if entity.has_method("get_id") else str(entity.get_instance_id())
	var buff_list: Array = _entity_buffs.get(entity_id, [])
	for buff in buff_list:
		if buff is BaseBuff and buff.type == buff_type_enum and not buff.is_expired and buff.is_active:
			return true
	return false

# ============================================
# 计算修正后数值（乘法修正）
# ============================================
func calculate_modifier(entity, buff_type_name: String, base_value: float) -> float:
	var buffs = get_buffs(entity, buff_type_name)
	if buffs.is_empty():
		return base_value
	
	var final_value = base_value
	for buff in buffs:
		if buff.is_expired or not buff.is_active:
			continue
		final_value *= (1.0 + buff.get_buff_value())
	return final_value

# ============================================
# 清除实体上的所有 Buff
# ============================================
func clear_buffs(entity) -> void:
	if not entity:
		return
	var entity_id = entity.get_id() if entity.has_method("get_id") else str(entity.get_instance_id())
	var buff_list: Array = _entity_buffs.get(entity_id, [])
	
	var context = BuffContext.new(entity, null, {})
	for buff in buff_list:
		if buff is BaseBuff:
			buff.remove(context)
	
	_entity_buffs.erase(entity_id)

# ============================================
# 触发指定时机的事件
# ============================================
func trigger_timing(timing: int, context: BuffContext = null) -> void:
	if context == null:
		context = BuffContext.new()
	context.trigger_timing = timing
	
	for entity_id in _entity_buffs.keys():
		var buff_list: Array = _entity_buffs[entity_id]
		
		# 过滤需要当前时机触发的 Buff
		var buffs_to_trigger = []
		for buff in buff_list:
			if buff is BaseBuff and not buff.is_expired and buff.is_active:
				if buff.trigger_timing.has(timing):
					buffs_to_trigger.append(buff)
		
		for buff in buffs_to_trigger:
			# 短路检查：若上下文已被取消，则跳过后续 Buff
			if context.is_cancelled():
				break
			
			match timing:
				BuffTriggerTiming.ON_APPLY:
					buff.apply(context)
				BuffTriggerTiming.ON_REMOVE:
					buff.remove(context)
				BuffTriggerTiming.ROUND_START:
					buff.on_round_start(context)
				BuffTriggerTiming.ROUND_END:
					buff.on_round_end(context)
				BuffTriggerTiming.ATTACK_CHECK:
					buff.on_attack_check(context)
				BuffTriggerTiming.DAMAGE_CALCULATE:
					buff.on_damage_calculate(context)
				BuffTriggerTiming.CRIT_SETTLE:
					buff.on_crit_settle(context)
				BuffTriggerTiming.HURT:
					buff.on_hurt(context)
				BuffTriggerTiming.BULLET_CREATE:
					buff.on_bullet_create(context)
				BuffTriggerTiming.MOVE_CALCULATE:
					buff.on_move_calculate(context)
				BuffTriggerTiming.ATTACK_END:
					buff.on_attack_end(context)
				BuffTriggerTiming.DAMAGE_SETTLE:
					buff.on_damage_settle(context)
				BuffTriggerTiming.ACTION_PHASE:
					buff.on_action_phase(context)
				BuffTriggerTiming.ELEMENT_CHECK:
					buff.on_element_check(context)
		
		# 移除已过期的 Buff
		var active_buffs = []
		for buff in buff_list:
			if buff is BaseBuff and not buff.is_expired:
				active_buffs.append(buff)
		if active_buffs.size() != buff_list.size():
			_entity_buffs[entity_id] = active_buffs

# ============================================
# 回合开始事件
# ============================================
func on_round_start() -> void:
	var context = BuffContext.new()
	trigger_timing(BuffTriggerTiming.ROUND_START, context)

# ============================================
# 回合结束事件
# ============================================
func on_round_end() -> void:
	var context = BuffContext.new()
	trigger_timing(BuffTriggerTiming.ROUND_END, context)

# ============================================
# 获取调试信息
# ============================================
func get_debug_info() -> Dictionary:
	var result = {}
	for entity_id in _entity_buffs.keys():
		var buff_list: Array = _entity_buffs[entity_id]
		var json_list = []
		for buff in buff_list:
			if buff is BaseBuff:
				json_list.append(buff.to_json())
		result[entity_id] = json_list
	return result

# ============================================
# Buff 类型名称到枚举的映射（便捷引用）
# ============================================
const BUFF_TYPE_STRINGS: Dictionary = {
	"atk_up": BuffTypes.ATK_UP,
	"def_up": BuffTypes.DEF_UP,
	"atk_multi": BuffTypes.ATK_MULTI,
	"def_multi": BuffTypes.DEF_MULTI,
	"elem_dmg": BuffTypes.ELEM_DMG,
	"dmg_reduce": BuffTypes.DMG_REDUCE,
	"step_per_round": BuffTypes.STEP_PER_ROUND,
	"double_act": BuffTypes.DOUBLE_ACT,
	"shield": BuffTypes.SHIELD,
	"heal": BuffTypes.HEAL,
	"elem_bullet_dmg": BuffTypes.ELEM_BULLET_DMG,
	"elem_bullet_speed": BuffTypes.ELEM_BULLET_SPEED,
	"elem_bullet_pierce": BuffTypes.ELEM_BULLET_PIERCE,
	"bullet_count": BuffTypes.BULLET_COUNT,
	"crit_rate": BuffTypes.CRIT_RATE,
	"crit_dmg": BuffTypes.CRIT_DMG,
	"slow": BuffTypes.SLOW,
	"combo_rate": BuffTypes.COMBO_RATE,
	"area_dmg": BuffTypes.AREA_DMG,
	"full_elem": BuffTypes.FULL_ELEM,
	"def_ignore": BuffTypes.DEF_IGNORE,
	"random_elem": BuffTypes.RANDOM_ELEM,
	"step_bonus": BuffTypes.STEP_BONUS,
	"elem_resist": BuffTypes.ELEM_RESIST,
	"weakness_bonus": BuffTypes.WEAKNESS_BONUS,
	"revive": BuffTypes.REVIVE,
	"all_stats": BuffTypes.ALL_STATS,
	"neutral_dmg_bonus": BuffTypes.NEUTRAL_DMG_BONUS,
	"all_elem_bonus": BuffTypes.ALL_ELEM_BONUS,
	"add_elem_slot": BuffTypes.ADD_ELEM_SLOT,
	"full_elem_support": BuffTypes.FULL_ELEM_SUPPORT,
	"none": BuffTypes.NONE,
}