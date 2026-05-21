extends Node

# ============================================================
# Buff 类型定义与注册中心（替代 BuffTypes.js）
# ============================================================
class_name BuffEnums

enum BuffTypes {
	# 基本属性
	ATK_UP = 0,
	DEF_UP = 1,
	ATK_MULTI = 2,
	DEF_MULTI = 3,
	ELEM_DMG = 4,
	DMG_REDUCE = 5,
	STEP_PER_ROUND = 6,
	DOUBLE_ACT = 7,
	
	# 防御/恢复
	SHIELD = 10,
	HEAL = 11,
	
	# 子弹相关
	ELEM_BULLET_DMG = 20,
	ELEM_BULLET_SPEED = 21,
	ELEM_BULLET_PIERCE = 22,
	BULLET_COUNT = 23,
	
	# 暴击
	CRIT_RATE = 30,
	CRIT_DMG = 31,
	
	# 控制/效果
	SLOW = 40,
	COMBO_RATE = 41,
	AREA_DMG = 42,
	FULL_ELEM = 43,
	DEF_IGNORE = 44,
	RANDOM_ELEM = 45,
	
	# 特殊
	STEP_BONUS = 50,
	ELEM_RESIST = 51,
	WEAKNESS_BONUS = 52,
	REVIVE = 53,
	ALL_STATS = 54,
	NEUTRAL_DMG_BONUS = 55,
	ALL_ELEM_BONUS = 56,
	ADD_ELEM_SLOT = 57,
	FULL_ELEM_SUPPORT = 58,
	
	# 空
	NONE = 99,
}

enum BuffCategory {
	ATTRIBUTE_MODIFIER = 0,
	STATE_FLAG = 1,
	VALUE_CACHE = 2,
	INSTANT_EFFECT = 3,
	TRIGGER_EFFECT = 4,
	EMPTY = 5,
}

enum BuffTriggerTiming {
	ON_APPLY = 0,
	ON_REMOVE = 1,
	ROUND_START = 2,
	ROUND_END = 3,
	ACTION_PHASE = 4,
	ATTACK_CHECK = 5,
	DAMAGE_CALCULATE = 6,
	CRIT_SETTLE = 7,
	HURT = 8,
	BULLET_CREATE = 9,
	MOVE_CALCULATE = 10,
	ATTACK_END = 11,
	DAMAGE_SETTLE = 12,
	ELEMENT_CHECK = 13,
}

# Buff 类型名称字符串映射（用于注册）
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