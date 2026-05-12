extends Node

# ============================================================
# Buff 统一导入入口（替代 BuffIndex.js）
# 注册所有 Buff 类型到注册器
# ============================================================

static func init_all() -> void:
	# Batch 12: 基础属性
	BuffRegistry.register_buff("atk_up", "res://core/buffs/types/atk_up_buff.gd")
	BuffRegistry.register_buff("def_up", "res://core/buffs/types/def_up_buff.gd")
	BuffRegistry.register_buff("atk_multi", "res://core/buffs/types/atk_multi_buff.gd")
	BuffRegistry.register_buff("def_multi", "res://core/buffs/types/def_multi_buff.gd")
	BuffRegistry.register_buff("elem_dmg", "res://core/buffs/types/elem_dmg_buff.gd")
	BuffRegistry.register_buff("dmg_reduce", "res://core/buffs/types/dmg_reduce_buff.gd")
	BuffRegistry.register_buff("step_per_round", "res://core/buffs/types/step_per_round_buff.gd")
	BuffRegistry.register_buff("double_act", "res://core/buffs/types/double_act_buff.gd")
	
	# Batch 13: 防御/恢复 + 子弹
	BuffRegistry.register_buff("shield", "res://core/buffs/types/shield_buff.gd")
	BuffRegistry.register_buff("heal", "res://core/buffs/types/heal_buff.gd")
	BuffRegistry.register_buff("elem_bullet_dmg", "res://core/buffs/types/elem_bullet_dmg_buff.gd")
	BuffRegistry.register_buff("elem_bullet_speed", "res://core/buffs/types/elem_bullet_speed_buff.gd")
	BuffRegistry.register_buff("elem_bullet_pierce", "res://core/buffs/types/elem_bullet_pierce_buff.gd")
	BuffRegistry.register_buff("crit_rate", "res://core/buffs/types/crit_rate_buff.gd")
	BuffRegistry.register_buff("crit_dmg", "res://core/buffs/types/crit_dmg_buff.gd")
	BuffRegistry.register_buff("slow", "res://core/buffs/types/slow_buff.gd")
	
	# Batch 14
	BuffRegistry.register_buff("combo_rate", "res://core/buffs/types/combo_rate_buff.gd")
	BuffRegistry.register_buff("area_dmg", "res://core/buffs/types/area_dmg_buff.gd")
	BuffRegistry.register_buff("full_elem", "res://core/buffs/types/full_elem_buff.gd")
	BuffRegistry.register_buff("def_ignore", "res://core/buffs/types/def_ignore_buff.gd")
	BuffRegistry.register_buff("random_elem", "res://core/buffs/types/random_elem_buff.gd")
	BuffRegistry.register_buff("step_bonus", "res://core/buffs/types/step_bonus_buff.gd")
	BuffRegistry.register_buff("elem_resist", "res://core/buffs/types/element_resist_buff.gd")
	BuffRegistry.register_buff("bullet_count", "res://core/buffs/types/bullet_count_buff.gd")
	
	# Batch 15
	BuffRegistry.register_buff("weakness_bonus", "res://core/buffs/types/weakness_bonus_buff.gd")
	BuffRegistry.register_buff("revive", "res://core/buffs/types/revive_buff.gd")
	BuffRegistry.register_buff("all_stats", "res://core/buffs/types/all_stats_buff.gd")
	BuffRegistry.register_buff("neutral_dmg_bonus", "res://core/buffs/types/neutral_dmg_bonus_buff.gd")
	BuffRegistry.register_buff("all_elem_bonus", "res://core/buffs/types/all_element_bonus_buff.gd")
	BuffRegistry.register_buff("add_elem_slot", "res://core/buffs/types/add_element_slot_buff.gd")
	BuffRegistry.register_buff("full_elem_support", "res://core/buffs/types/full_elem_support_buff.gd")
	BuffRegistry.register_buff("none", "res://core/buffs/types/none_buff.gd")