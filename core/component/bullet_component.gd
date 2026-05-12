extends BaseComponent

# ============================================================
# 子弹组件（替代 BulletComponent.js）
# 存储子弹相关数据
# ============================================================

class_name BulletComponent

var bullet_data: Dictionary = {}

func _init(p_data: Dictionary = {}):
	comp_name = "Bullet"
	bullet_data = p_data