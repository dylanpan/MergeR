class_name UIRootManager

# ============================================================
# UI 根节点管理器
# 管理5个层级的 UI 根节点引用
# ============================================================

var _element_ui_root = null
var _launcher_ui_root = null
var _bullet_ui_root = null
var _order_ui_root = null
var _attack_ui_root = null

# ==================== Setters ====================

func add_element_ui_root(root) -> void:
	_element_ui_root = root

func add_launcher_ui_root(root) -> void:
	_launcher_ui_root = root

func add_bullet_ui_root(root) -> void:
	_bullet_ui_root = root

func add_order_ui_root(root) -> void:
	_order_ui_root = root

func add_attack_ui_root(root) -> void:
	_attack_ui_root = root

# ==================== Getters ====================

func get_element_ui_root():
	return _element_ui_root

func get_launcher_ui_root():
	return _launcher_ui_root

func get_bullet_ui_root():
	return _bullet_ui_root

func get_order_ui_root():
	return _order_ui_root

func get_attack_ui_root():
	return _attack_ui_root

# ==================== Lifecycle ====================

func clear_all() -> void:
	_element_ui_root = null
	_launcher_ui_root = null
	_bullet_ui_root = null
	_order_ui_root = null
	_attack_ui_root = null

func setup_from_node(node) -> void:
	if not node:
		return
	if node.has_method("get_element_ui_root"):
		add_element_ui_root(node.get_element_ui_root())
	if node.has_method("get_launcher_ui_root"):
		add_launcher_ui_root(node.get_launcher_ui_root())
	if node.has_method("get_bullet_ui_root"):
		add_bullet_ui_root(node.get_bullet_ui_root())
	if node.has_method("get_order_ui_root"):
		add_order_ui_root(node.get_order_ui_root())
	if node.has_method("get_attack_ui_root"):
		add_attack_ui_root(node.get_attack_ui_root())