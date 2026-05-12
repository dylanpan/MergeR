extends BaseComponent

# ============================================================
# UI 组件（替代 UIComponent.js）
# 存储实体的 UI 节点引用
# ============================================================

class_name UIComponent

var ui_node = null

func _init(p_ui_node = null):
	comp_name = "UI"
	ui_node = p_ui_node

func dispose():
	ui_node = null
	super.dispose()