class_name UIRootService

# ============================================================
# UI 根节点服务
# 管理各 UI 系统的根节点引用
# ============================================================

var element_ui_root = null
var launcher_ui_root = null
var bullet_ui_root = null
var order_ui_root = null
var attack_ui_root = null

func _init():
	pass

func set_element_ui_root(root) -> void:
	element_ui_root = root

func get_element_ui_root():
	return element_ui_root

func set_launcher_ui_root(root) -> void:
	launcher_ui_root = root

func get_launcher_ui_root():
	return launcher_ui_root

func set_bullet_ui_root(root) -> void:
	bullet_ui_root = root

func get_bullet_ui_root():
	return bullet_ui_root

func set_order_ui_root(root) -> void:
	order_ui_root = root

func get_order_ui_root():
	return order_ui_root

func set_attack_ui_root(root) -> void:
	attack_ui_root = root

func get_attack_ui_root():
	return attack_ui_root

func reset() -> void:
	element_ui_root = null
	launcher_ui_root = null
	bullet_ui_root = null
	order_ui_root = null
	attack_ui_root = null