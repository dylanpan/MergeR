extends BaseComponent

# ============================================================
# Meta 配置组件（替代 MetaComponent.js）
# 存储实体的 Meta 配置引用
# ============================================================

class_name MetaComponent

var meta_data: Dictionary = {}

func _init(p_meta: Dictionary = {}):
	comp_name = "Meta"
	meta_data = p_meta